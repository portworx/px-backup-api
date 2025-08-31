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
		-I${GOPATH}/src/github.com/grpc-ecosystem/grpc-gateway/third_party/googleapis \
		-I${GOPATH}/src/github.com/grpc-ecosystem/grpc-gateway/ \
		--go_out=. --go_opt=paths=source_relative \
		--go-grpc_out=. --go-grpc_opt=paths=source_relative \
		--grpc-gateway_out=logtostderr=true,generate_unbound_methods=true:. \
		--openapiv2_out=logtostderr=true:. \
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

