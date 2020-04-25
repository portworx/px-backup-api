package kubeauth

import (
	"context"

	"github.com/sirupsen/logrus"
	"google.golang.org/grpc"
	"k8s.io/client-go/rest"
)

// Plugin is the interface the plugins need to implement
type Plugin interface {
	UpdateClient(
		conn *grpc.ClientConn,
		ctx context.Context,
		cloudCredentialName string,
		orgID string,
		client *rest.Config,
	) (bool, error)
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
// from the cloud credential
func UpdateClient(
	conn *grpc.ClientConn,
	ctx context.Context,
	cloudCredentialName string,
	orgID string,
	client *rest.Config,
) error {
	for _, plugin := range plugins {
		updated, err := plugin.UpdateClient(conn, ctx, cloudCredentialName, orgID, client)
		if err != nil {
			return err
		}
		if updated {
			return nil
		}
	}
	return nil
}
