package ibm

import (
	"bytes"
	"context"
	"fmt"
	"io/ioutil"
	"net/url"
	"os"
	"strings"
	"sync"

	"github.com/IBM-Cloud/bluemix-go/api/mccp/mccpv2"
	"github.com/IBM-Cloud/bluemix-go/session"
	api "github.com/portworx/px-backup-api/pkg/apis/v1"
	"github.com/portworx/px-backup-api/pkg/kubeauth"
	"github.com/portworx/sched-ops/k8s/core"

	v1 "github.com/IBM-Cloud/bluemix-go/api/container/containerv1"

	"github.com/sirupsen/logrus"
	"google.golang.org/grpc"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/cli-runtime/pkg/printers"
	"k8s.io/client-go/rest"
	"k8s.io/client-go/tools/clientcmd"
	clientcmdapi "k8s.io/client-go/tools/clientcmd/api"
	"k8s.io/client-go/tools/clientcmd/api/latest"
)

const (
	pluginName            = "ibm"
	idpIssuerUrlKey       = "idp-issuer-url"
	ibmIssuerUrlSubstring = "iam.cloud.ibm.com"
)

type ibm struct {
	clusterMapLock map[string]*sync.Mutex
}

// Init initializes the gcp auth plugin
func (i *ibm) Init() error {
	return nil
}

func (i *ibm) UpdateClient(
	conn *grpc.ClientConn,
	ctx context.Context,
	cloudCredentialName string,
	orgID string,
	restConfig *rest.Config,
	clientConfig *clientcmdapi.Config,
) (bool, string, error) {
	if i.isIBMProvider(restConfig) {
		// Check if the provided config has expired
		coreInst, err := core.NewForConfig(restConfig)
		if err == nil {
			_, err = coreInst.GetVersion()
			if err == nil {
				// No need of updating the kubeconfig
				// Return true since we found that this
				// is a IBM config
				return true, "", nil
			}
		}
		// the config has expired
		// update the tokens
		cloudCredentialClient := api.NewCloudCredentialClient(conn)
		resp, err := cloudCredentialClient.Inspect(
			ctx,
			&api.CloudCredentialInspectRequest{
				Name:           cloudCredentialName,
				OrgId:          orgID,
				IncludeSecrets: true,
			},
		)
		if err != nil {
			return false, "", fmt.Errorf("failed to get credentials: %v", err)
		}
		cloudCredential := resp.GetCloudCredential()

		kubeconfig, err := i.updateClient(restConfig, clientConfig, cloudCredential)
		if err != nil {
			logrus.Errorf("Failed to update client: %v", err)
			return false, "", err
		}
		return true, kubeconfig, nil
	}
	return false, "", nil
}

func (i *ibm) UpdateClientByCredObject(
	cloudCredential *api.CloudCredentialObject,
	restConfig *rest.Config,
	clientConfig *clientcmdapi.Config,
) (bool, string, error) {
	if i.isIBMProvider(restConfig) {
		// Check if the provided config has expired
		coreInst, err := core.NewForConfig(restConfig)
		if err == nil {
			_, err = coreInst.GetVersion()
			if err == nil {
				// No need of updating the kubeconfig
				// Return true since we found that this
				// is a IBM config
				return true, "", nil
			}
		}
		kubeconfig, err := i.updateClient(restConfig, clientConfig, cloudCredential)
		if err != nil {
			logrus.Errorf("Failed to update client: %v", err)
			return false, "", err
		}
		return true, kubeconfig, nil
	}
	return false, "", nil
}

func (i *ibm) updateClient(restConfig *rest.Config, clientConfig *clientcmdapi.Config, cloudCredential *api.CloudCredentialObject) (string, error) {
	clusterName, region, err := parseConfig(clientConfig)
	if err != nil {
		return "", err
	}

	if cloudCredential.GetCloudCredentialInfo().GetType() != api.CloudCredentialInfo_IBM {
		return "", fmt.Errorf("need IBM CloudCredential for IBM clusters. Provided %v", cloudCredential.GetCloudCredentialInfo().GetType())
	}
	apiKey := cloudCredential.GetCloudCredentialInfo().GetIbmConfig().GetApiKey()
	sess, err := session.New()
	if err != nil {
		logrus.Errorf("InitSession: Failed to start a new session")
		return "", err
	}

	sess.Config.BluemixAPIKey = apiKey

	_, err = mccpv2.New(sess)
	if err != nil {
		return "", err
	}
	clusterClient, err := v1.New(sess)
	if err != nil {
		return "", fmt.Errorf("failed to create a cluster client: %v", err)
	}
	clusterAPI := clusterClient.Clusters()

	// IBM client library is not thread safe for the same cluster
	// It will error out if it finds that another kubeconfig
	// being generated under that directory. We don't want to keep
	// populating the /tmp directory with new kubeconfigs so after the
	// rest.Config is populated we will cleanup the directory
	lock, exists := i.clusterMapLock[clusterName]
	if !exists {
		i.clusterMapLock[clusterName] = &sync.Mutex{}
	}
	lock.Lock()
	defer lock.Unlock()

	configPath := "/tmp/kube/" + clusterName
	i.cleanupKubeconfigPath(configPath)
	// Create a path to save the new kubeconfig
	if err := os.MkdirAll(configPath, 0777); err != nil {
		logrus.Debugf("failed to create config path: %v", err)
	}
	defer func() {
		i.cleanupKubeconfigPath(configPath)
	}()

	target := v1.ClusterTargetHeader{
		Region: region,
	}
	clusterConfig, err := clusterAPI.GetClusterConfigDetail(clusterName, configPath, true, target)
	if err != nil {
		return "", fmt.Errorf("failed to get cluster config: %v", err)
	}

	logrus.Debugf("Updating rest config for cluster (%v): %v", clusterName, restConfig.String())

	kubeConfigPath := clusterConfig.FilePath
	kubeconfigBytes := i.getKubeconfig(kubeConfigPath)

	// First parse the config
	defClient, err := clientcmd.NewClientConfigFromBytes([]byte(kubeconfigBytes))
	if err != nil {
		return "", err
	}
	rawConfig, err := defClient.RawConfig()
	if err != nil {
		return "", err
	}

	// Then create a default client config with the default loading rules
	defClient = clientcmd.NewDefaultClientConfig(rawConfig, &clientcmd.ConfigOverrides{})
	if err != nil {
		return "", err
	}
	restConfigCopy, err := defClient.ClientConfig()
	if err != nil {
		return "", err
	}

	_, err = i.validateConfig(restConfigCopy)
	if err == nil {
		*restConfig = *restConfigCopy
	}
	return kubeconfigBytes, err
}

// getKubeconfig will read the kubeconfig from the provided path
// and return the flattened and minifed kubeconfig in string representation
// This function will return an empty string if it fails to read the file or parse it
// This function is inspired from "kubectl config view --minify --flatten" implementation
func (i *ibm) getKubeconfig(kubeConfigPath string) string {
	content, err := ioutil.ReadFile(kubeConfigPath)
	if err != nil {
		return ""
	}
	client, err := clientcmd.NewClientConfigFromBytes(content)
	if err != nil {
		return ""
	}
	rawConfig, err := client.RawConfig()
	if err != nil {
		return ""
	}
	// Set the location of origin to the kubeconfig path
	// This allows the minify and flatten functions to find
	// the certs
	for _, authInfos := range rawConfig.AuthInfos {
		authInfos.LocationOfOrigin = kubeConfigPath
	}
	for _, cluster := range rawConfig.Clusters {
		cluster.LocationOfOrigin = kubeConfigPath
	}
	if err := clientcmdapi.MinifyConfig(&rawConfig); err != nil {
		return ""
	}
	if err := clientcmdapi.FlattenConfig(&rawConfig); err != nil {
		return ""
	}
	convertedObj, err := latest.Scheme.ConvertToVersion(&rawConfig, latest.ExternalVersion)
	if err != nil {
		return ""
	}
	yamlPrinter := &printers.YAMLPrinter{}
	var b bytes.Buffer
	if err := yamlPrinter.PrintObj(runtime.Object(convertedObj), &b); err != nil {
		return ""
	}
	return b.String()
}

func (i *ibm) cleanupKubeconfigPath(configPath string) {
	// Cleanup old path
	if err := os.RemoveAll(configPath); err != nil {
		logrus.Debugf("failed to cleanup config path: %v", err)
	}
}

func (i *ibm) validateConfig(restConfig *rest.Config) (bool, error) {
	// Check if the provided config has expired
	coreInst, err := core.NewForConfig(restConfig)
	if err != nil {
		return false, err
	}
	_, err = coreInst.GetVersion()
	if err == nil {
		return true, nil
	}
	return false, err
}

func (i *ibm) isIBMProvider(client *rest.Config) bool {
	if client.AuthProvider != nil {
		if client.AuthProvider.Config != nil {
			if issuerUrl, exists := client.AuthProvider.Config[idpIssuerUrlKey]; exists {
				if strings.Contains(issuerUrl, ibmIssuerUrlSubstring) {
					return true
				}
			}
		}
	}
	return false
}

func parseIBMClusterName(clusterName string) string {
	// Sample IBM cluster name : px-backup-bill-test/c159d5hd0t0gcgt4lpcg
	return strings.Split(clusterName, "/")[0]
}

func parseConfig(clientConfig *clientcmdapi.Config) (string, string, error) {
	// We cannot handle multiple clusters in a single kubeconfig
	// This function will return the first name found in the clusters
	// map
	if len(clientConfig.Clusters) > 1 {
		return "", "", fmt.Errorf("cluster info not found in kubeconfig")
	}
	var (
		clusterName string
		region      string
	)
	for name, cluster := range clientConfig.Clusters {
		clusterName = parseIBMClusterName(name)
		// Parse the server url
		// Sample IBM urls for IKS and Openshift on IBM clusters
		// "https://c7.private.us-south.containers.cloud.ibm.com:29713"
		// "https://c113.us-south.containers.cloud.ibm.com:30044"
		u, err := url.Parse(cluster.Server)
		if err != nil {
			return "", "", fmt.Errorf("failed to parse server url: %v", err)
		}
		// endpoint = c7.private.us-south.containers.cloud.ibm.com:29713
		endpoint := strings.Split(u.Host, ":")
		tokens := strings.Split(endpoint[0], ".")
		// containers.cloud.ibm.com is constant string at the end of server endpoint
		if len(tokens) >= 7 {
			region = tokens[len(tokens)-5]
		} else {
			continue
		}
		break
	}
	return clusterName, region, nil

}

func init() {
	cMap := make(map[string]*sync.Mutex)
	if err := kubeauth.Register(pluginName, &ibm{cMap}); err != nil {
		logrus.Panicf("Error registering ibm auth plugin: %v", err)
	}
}
