module github.com/portworx/px-backup-api

go 1.19

require (
	github.com/IBM-Cloud/bluemix-go v0.0.0-20220329045155-d2a8118ac5c7
	github.com/aws/aws-sdk-go v1.44.45
	github.com/gogo/googleapis v1.4.1
	github.com/gogo/protobuf v1.3.2
	github.com/golang/protobuf v1.5.3
	github.com/grpc-ecosystem/grpc-gateway v1.16.0
	github.com/grpc-ecosystem/grpc-gateway/v2 v2.6.0
	github.com/libopenstorage/secrets v0.0.0-20220413195519-57d1c446c5e9
	github.com/portworx/sched-ops v1.20.4-rc1.0.20230207070155-2e0ef25efadd
	github.com/sirupsen/logrus v1.9.0
	go.uber.org/multierr v1.6.0
	golang.org/x/oauth2 v0.4.0
	google.golang.org/grpc v1.53.0
	k8s.io/apimachinery v0.25.4
	k8s.io/cli-runtime v0.25.2
	k8s.io/client-go v12.0.0+incompatible
	sigs.k8s.io/aws-iam-authenticator v0.5.5
)

require (
	cloud.google.com/go/compute v1.18.0 // indirect
	cloud.google.com/go/compute/metadata v0.2.3 // indirect
	github.com/PuerkitoBio/purell v1.1.1 // indirect
	github.com/PuerkitoBio/urlesc v0.0.0-20170810143723-de5bf2ad4578 // indirect
	github.com/beorn7/perks v1.0.1 // indirect
	github.com/cespare/xxhash/v2 v2.2.0 // indirect
	github.com/davecgh/go-spew v1.1.1 // indirect
	github.com/emicklei/go-restful/v3 v3.8.0 // indirect
	github.com/ghodss/yaml v1.0.1-0.20190212211648-25d852aebe32 // indirect
	github.com/go-logr/logr v1.2.3 // indirect
	github.com/go-openapi/jsonpointer v0.19.5 // indirect
	github.com/go-openapi/jsonreference v0.19.5 // indirect
	github.com/go-openapi/swag v0.19.14 // indirect
	github.com/gofrs/flock v0.8.1 // indirect
	github.com/golang/glog v1.1.0 // indirect
	github.com/golang/groupcache v0.0.0-20210331224755-41bb18bfe9da // indirect
	github.com/google/gnostic v0.5.7-v3refs // indirect
	github.com/google/gofuzz v1.2.0 // indirect
	github.com/imdario/mergo v0.3.12 // indirect
	github.com/jmespath/go-jmespath v0.4.0 // indirect
	github.com/josharian/intern v1.0.0 // indirect
	github.com/json-iterator/go v1.1.12 // indirect
	github.com/liggitt/tabwriter v0.0.0-20181228230101-89fcab3d43de // indirect
	github.com/mailru/easyjson v0.7.6 // indirect
	github.com/matttproud/golang_protobuf_extensions v1.0.2-0.20181231171920-c182affec369 // indirect
	github.com/moby/spdystream v0.2.0 // indirect
	github.com/modern-go/concurrent v0.0.0-20180306012644-bacd9c7ef1dd // indirect
	github.com/modern-go/reflect2 v1.0.2 // indirect
	github.com/munnerz/goautoneg v0.0.0-20191010083416-a7dc8b61c822 // indirect
	github.com/prometheus/client_golang v1.14.0 // indirect
	github.com/prometheus/client_model v0.3.0 // indirect
	github.com/prometheus/common v0.37.0 // indirect
	github.com/prometheus/procfs v0.8.0 // indirect
	github.com/spf13/pflag v1.0.5 // indirect
	go.uber.org/atomic v1.7.0 // indirect
	golang.org/x/net v0.7.0 // indirect
	golang.org/x/sys v0.5.0 // indirect
	golang.org/x/term v0.5.0 // indirect
	golang.org/x/text v0.7.0 // indirect
	golang.org/x/time v0.1.0 // indirect
	google.golang.org/appengine v1.6.7 // indirect
	google.golang.org/genproto v0.0.0-20230306155012-7f2fa6fef1f4 // indirect
	google.golang.org/protobuf v1.30.0 // indirect
	gopkg.in/inf.v0 v0.9.1 // indirect
	gopkg.in/yaml.v2 v2.4.0 // indirect
	gopkg.in/yaml.v3 v3.0.1 // indirect
	k8s.io/api v0.25.4 // indirect
	k8s.io/klog/v2 v2.80.1 // indirect
	k8s.io/kube-openapi v0.0.0-20220803162953-67bda5d908f1 // indirect
	k8s.io/utils v0.0.0-20220728103510-ee6ede2d64ed // indirect
	sigs.k8s.io/json v0.0.0-20220713155537-f223a00ba0e2 // indirect
	sigs.k8s.io/structured-merge-diff/v4 v4.2.3 // indirect
	sigs.k8s.io/yaml v1.3.0 // indirect
)

replace (
	github.com/kubernetes-incubator/external-storage => github.com/libopenstorage/external-storage v0.25.1-openstorage-rc1
	github.com/portworx/sched-ops => github.com/portworx/sched-ops v1.20.4-rc1.0.20230207070155-2e0ef25efadd
	k8s.io/api => k8s.io/api v0.25.1
	k8s.io/apiextensions-apiserver => k8s.io/apiextensions-apiserver v0.25.1
	k8s.io/apimachinery => k8s.io/apimachinery v0.25.1
	k8s.io/apiserver => k8s.io/apiserver v0.25.1
	k8s.io/cli-runtime => k8s.io/cli-runtime v0.25.1
	k8s.io/client-go => k8s.io/client-go v0.25.1
	k8s.io/cloud-provider => k8s.io/cloud-provider v0.25.1
	k8s.io/cluster-bootstrap => k8s.io/cluster-bootstrap v0.25.1
	k8s.io/code-generator => k8s.io/code-generator v0.25.1
	k8s.io/component-base => k8s.io/component-base v0.25.1
	k8s.io/component-helpers => k8s.io/component-helpers v0.25.1
	k8s.io/controller-manager => k8s.io/controller-manager v0.25.1
	k8s.io/cri-api => k8s.io/cri-api v0.25.1
	k8s.io/csi-translation-lib => k8s.io/csi-translation-lib v0.25.1
	k8s.io/kube-aggregator => k8s.io/kube-aggregator v0.25.1
	k8s.io/kube-controller-manager => k8s.io/kube-controller-manager v0.25.1
	k8s.io/kube-proxy => k8s.io/kube-proxy v0.25.1
	k8s.io/kube-scheduler => k8s.io/kube-scheduler v0.25.1
	k8s.io/kubectl => k8s.io/kubectl v0.25.1
	k8s.io/kubelet => k8s.io/kubelet v0.25.1
	k8s.io/kubernetes => k8s.io/kubernetes v1.25.1
	k8s.io/legacy-cloud-providers => k8s.io/legacy-cloud-providers v0.25.1
	k8s.io/metrics => k8s.io/metrics v0.25.1
	k8s.io/mount-utils => k8s.io/mount-utils v0.25.1
	k8s.io/pod-security-admission => k8s.io/pod-security-admission v0.25.1
	k8s.io/sample-apiserver => k8s.io/sample-apiserver v0.25.1
	sigs.k8s.io/controller-runtime => sigs.k8s.io/controller-runtime v0.13.0
	sigs.k8s.io/sig-storage-lib-external-provisioner/v6 => sigs.k8s.io/sig-storage-lib-external-provisioner/v6 v6.3.0
)
