# Library for PX-Backup APIs

This repo contains the definition for the gRPC and REST APIs to communicate with
[PX-Backup](https://backup.docs.portworx.com/).

The proto definition for gRPC and REST gateway can be found
[here](https://github.com/portworx/px-backup-api/blob/master/pkg/apis/v1/api.proto).

The generated client code is present under
`github.com/portworx/px-backup-api/pkg/apis/v1`.

## Building

After updating the proto definitions, run `make` to regenerate the client libraries and swagger definitions.

## Usage

### Authentication 

All APIs to PX-Backup need to be authenticated using a token from an OIDC
provider. You can use the [oauth2](https://github.com/golang/oauth2) package to fetch
the token. Some examples to fetch the token can be found
[here](https://godoc.org/golang.org/x/oauth2#example-Config).

### Example to fetch a list of Clusters configured with PX-Backup

```
package cluster

import (
    "context"
    "fmt"

    "github.com/libopenstorage/openstorage/pkg/grpcserver"
    api "github.com/portworx/px-backup-api/pkg/apis/v1"
    "google.golang.org/grpc/metadata"
)

func getClusterList(addr string, token string, orgID string) (*api.ClusterEnumerateResponse, error) {

    // Connect to the PX-Backup server
    conn, err := grpcserver.Connect(addr, nil)
    if err != nil {
        return nil, fmt.Errorf("failed to connect to gRPC handler: %v", err)
    }
    
    // Create a context with the token
    md := metadata.New(map[string]string{
        "authorization": "bearer " + token,
    })
    ctx := metadata.NewOutgoingContext(context.Background(), md)
    
    // Create a client and make the gRPC API call
    cluster := api.NewClusterClient(conn)
    return cluster.Enumerate(
        ctx,
        &api.ClusterEnumerateRequest{
            OrgId: orgID,
        },
    )
}   
```

