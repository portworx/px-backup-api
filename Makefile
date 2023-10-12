ifndef PROTOC
PROTOC = protoc
endif

ifndef PKGS
PKGS := $(shell go list ./... 2>&1 | grep -v 'github.com/portworx/px-backup-api/vendor' | grep -v versioned | grep -v 'pkg/apis/v1')
endif

ifndef PROTOC_FILES
PROTOC_FILES := pkg/apis/v1/api.proto
PROTOC_FILES += pkg/apis/v1/common.proto
endif

PROTOC_ZIP := protoc-3.14.0-linux-x86_64.zip

GO111MODULE := on

.DEFAULT_GOAL: all

all: docker-build-proto

docker-build-proto:
	docker build . -t px-backup-api-build
	docker run  --rm  -v ${PWD}:/go/portworx/px-backup-api  px-backup-api-build /bin/bash -c "make proto pretest"

start-build-container:
	docker run --rm -it -v ${PWD}:/go/portworx/px-backup-api px-backup-api-build /bin/bash

proto:
	$(PROTOC) -I/usr/local/include -I. \
		-I${GOPATH}/src \
		-I${GOPATH}/src/github.com/grpc-ecosystem/grpc-gateway/protoc-gen-openapiv2 \
		-I${GOPATH}/src/github.com/gogo/protobuf/protobuf \
		-I${GOPATH}/src/github.com/grpc-ecosystem/grpc-gateway/third_party/googleapis \
		-I${GOPATH}/src/github.com/grpc-ecosystem/grpc-gateway/ \
		--gogofaster_out=\
Mgogoproto/gogo.proto=github.com/gogo/protobuf/gogoproto,\
Mgoogle/protobuf/any.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/empty.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/duration.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/field_mask.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/struct.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/timestamp.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/wrappers.proto=github.com/gogo/protobuf/types,\
Mgoogle/api/annotations.proto=github.com/gogo/googleapis/google/api,\
Mgoogle/protobuf/field_mask.proto=github.com/gogo/protobuf/types,\
plugins=grpc:. \
		--grpc-gateway_out=allow_patch_feature=false,\
Mgogoproto/gogo.proto=github.com/gogo/protobuf/gogoproto,\
Mgoogle/protobuf/any.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/empty.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/duration.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/field_mask.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/struct.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/timestamp.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/wrappers.proto=github.com/gogo/protobuf/types,\
Mgoogle/api/annotations.proto=github.com/gogo/googleapis/google/api,\
Mgoogle/protobuf/field_mask.proto=github.com/gogo/protobuf/types:.\
		--swagger_out=logtostderr=true:. \
		$(PROTOC_FILES)
pretest: vet staticcheck errcheck

vet:
	go vet $(PKGS)

staticcheck:
	GOFLAGS="" go install honnef.co/go/tools/cmd/staticcheck@latest
	staticcheck $(PKGS)

errcheck:
	go install github.com/kisielk/errcheck@latest
	errcheck -ignoregenerated -verbose -blank $(PKGS)

