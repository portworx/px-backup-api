package kubeauth

import (
	"context"

	api "github.com/portworx/px-backup-api/pkg/apis/v1"
	"github.com/sirupsen/logrus"
	"google.golang.org/grpc"
	"k8s.io/client-go/rest"
	clientcmd "k8s.io/client-go/tools/clientcmd/api"
)

// Plugin is the interface the plugins need to implement
type Plugin interface {
	UpdateClient(
		conn *grpc.ClientConn,
		ctx context.Context,
		cloudCredentialName string,
		orgID string,
		restConfig *rest.Config,
		clientConfig *clientcmd.Config,
	) (bool, string, error)

	UpdateClientByCredObject(
		cloudCred *api.CloudCredentialObject,
		restConfig *rest.Config,
		clientConfig *clientcmd.Config,
	) (bool, string, error)
}

var (
	plugins = make(map[string]Plugin)
)

// Register registers the given auth plugin
func Register(name string, p Plugin) error {
	logrus.Infof("Registering auth plugin: %v", name)
	plugins[name] = p
	return nil
}

// UpdateClient Updates the k8s client config with the required info
// from the cloud credential. It will return the new kubeconfig with
// which the client was updated
func UpdateClient(
	conn *grpc.ClientConn,
	ctx context.Context,
	cloudCredentialName string,
	orgID string,
	restConfig *rest.Config,
	clientConfig *clientcmd.Config,
) (string, error) {
	for _, plugin := range plugins {
		updated, kubeconfig, err := plugin.UpdateClient(conn, ctx, cloudCredentialName, orgID, restConfig, clientConfig)
		if err != nil {
			return "", err
		}
		if updated {
			return kubeconfig, nil
		}
	}
	return "", nil
}

// UpdateClientByCredObject Updates the k8s client config with the required info
// from the provided cloud credential object
func UpdateClientByCredObject(
	cloudCred *api.CloudCredentialObject,
	restConfig *rest.Config,
	clientConfig *clientcmd.Config,
) (string, error) {
	for _, plugin := range plugins {
		updated, kubeconfig, err := plugin.UpdateClientByCredObject(cloudCred, restConfig, clientConfig)
		if err != nil {
			return "", err
		}
		if updated {
			return kubeconfig, nil
		}
	}
	return "", nil
}
