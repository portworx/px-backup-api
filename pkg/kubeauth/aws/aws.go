package aws

import (
	"context"
	"fmt"

	api "github.com/portworx/px-backup-api/pkg/apis/v1"
	"github.com/portworx/px-backup-api/pkg/kubeauth"
	"github.com/sirupsen/logrus"
	"google.golang.org/grpc"
	"k8s.io/client-go/rest"
	clientcmdapi "k8s.io/client-go/tools/clientcmd/api"
)

const (
	pluginName = "aws"
)

type aws struct {
}

// Init initializes the gcp auth plugin
func (a *aws) Init() error {
	return nil
}

func (a *aws) UpdateClient(
	conn *grpc.ClientConn,
	ctx context.Context,
	cloudCredentialName string,
	cloudCredentialUID string,
	orgID string,
	client *rest.Config,
	clientConfig *clientcmdapi.Config,
) (bool, string, error) {
	// AWS does not support returning kubeconfigs
	var emptyKubeconfig string
	if client.ExecProvider != nil {
		if client.ExecProvider.Command == "aws-iam-authenticator" || client.ExecProvider.Command == "aws" {
			if cloudCredentialName == "" {
				return false, emptyKubeconfig, fmt.Errorf("CloudCredential not provided for EKS cluster")
			}

			cloudCredentialClient := api.NewCloudCredentialClient(conn)
			resp, err := cloudCredentialClient.Inspect(
				ctx,
				&api.CloudCredentialInspectRequest{
					Name:           cloudCredentialName,
					Uid: cloudCredentialUID,
					OrgId:          orgID,
					IncludeSecrets: true,
				},
			)
			if err != nil {
				return false, emptyKubeconfig, err
			}
			cloudCredential := resp.GetCloudCredential()
			if err := a.updateClient(cloudCredential, client); err != nil {
				return false, emptyKubeconfig, err
			}
			return true, emptyKubeconfig, nil
		} // else not an aws kubeauth provider
	}
	return false, emptyKubeconfig, nil
}

func (a *aws) UpdateClientByCredObject(
	cloudCred *api.CloudCredentialObject,
	client *rest.Config,
	clientConfig *clientcmdapi.Config,
) (bool, string, error) {
	// AWS does not support returning kubeconfigs
	var emptyKubeconfig string
	if client.ExecProvider != nil {
		if client.ExecProvider.Command == "aws-iam-authenticator" || client.ExecProvider.Command == "aws" {
			if err := a.updateClient(cloudCred, client); err != nil {
				return false, emptyKubeconfig, err
			}
			return true, emptyKubeconfig, nil
		} // else not an aws kubeauth provider
	}

	return false, emptyKubeconfig, nil
}

// updateClient assumes that the provided rest client is not nil
// and has the aws exec provider field set
func (a *aws) updateClient(
	cloudCredential *api.CloudCredentialObject,
	client *rest.Config,
) error {
	if cloudCredential == nil {
		return fmt.Errorf("CloudCredential not provided for EKS cluster")
	}
	if cloudCredential.GetCloudCredentialInfo().GetType() != api.CloudCredentialInfo_AWS {
		return fmt.Errorf("need AWS CloudCredential for EKS cluster. Provided %v", cloudCredential.GetCloudCredentialInfo().GetType())
	}

	if client.ExecProvider.Env == nil {
		client.ExecProvider.Env = make([]clientcmdapi.ExecEnvVar, 0)
	}
	client.ExecProvider.Env = append(client.ExecProvider.Env, clientcmdapi.ExecEnvVar{
		Name:  "AWS_ACCESS_KEY",
		Value: cloudCredential.GetCloudCredentialInfo().GetAwsConfig().GetAccessKey(),
	})
	client.ExecProvider.Env = append(client.ExecProvider.Env, clientcmdapi.ExecEnvVar{
		Name:  "AWS_ACCESS_KEY_ID",
		Value: cloudCredential.GetCloudCredentialInfo().GetAwsConfig().GetAccessKey(),
	})
	client.ExecProvider.Env = append(client.ExecProvider.Env, clientcmdapi.ExecEnvVar{
		Name:  "AWS_SECRET_KEY",
		Value: cloudCredential.GetCloudCredentialInfo().GetAwsConfig().GetSecretKey(),
	})
	client.ExecProvider.Env = append(client.ExecProvider.Env, clientcmdapi.ExecEnvVar{
		Name:  "AWS_SECRET_ACCESS_KEY",
		Value: cloudCredential.GetCloudCredentialInfo().GetAwsConfig().GetSecretKey(),
	})

	// Remove the profile env if present since we are passing in the creds through env
	tempEnv := make([]clientcmdapi.ExecEnvVar, 0)
	for _, env := range client.ExecProvider.Env {
		if env.Name == "AWS_PROFILE" {
			continue
		}
		tempEnv = append(tempEnv, env)
	}
	client.ExecProvider.Env = tempEnv
	return nil
}

func init() {
	if err := kubeauth.Register(pluginName, &aws{}); err != nil {
		logrus.Panicf("Error registering aws auth plugin: %v", err)
	}
}
