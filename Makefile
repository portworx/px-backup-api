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

all: centos proto pretest

centos:
    # Installation is specific for centos based distribution
	yum install -y centos-release-scl && yum install -y llvm-toolset-7 && yum makecache && yum install -y unzip 
	curl -OL https://github.com/protocolbuffers/protobuf/releases/download/v3.14.0/$(PROTOC_ZIP) 
	unzip -o $(PROTOC_ZIP) -d /usr bin/protoc
	rm -f $(PROTOC_ZIP)

proto:
	rm -rf ${GOPATH}/src/github.com/grpc-ecosystem/grpc-gateway/
	mkdir -p ${GOPATH}/src/github.com/grpc-ecosystem/grpc-gateway/
	curl -OL https://github.com/grpc-ecosystem/grpc-gateway/archive/refs/tags/v2.2.0.tar.gz
	tar -xvf v2.2.0.tar.gz -C ${GOPATH}/src/github.com/grpc-ecosystem/grpc-gateway/ --strip-components=1
	rm -f v2.2.0.tar.gz

	rm -rf ${GOPATH}/src/github.com/gogo/protobuf/
	mkdir -p ${GOPATH}/src/github.com/gogo/protobuf/
	git clone git@github.com:gogo/protobuf.git ${GOPATH}/src/github.com/gogo/protobuf

	scl enable llvm-toolset-7 "clang-format -i $(PROTOC_FILES)"
	go get -u \
	        github.com/gogo/protobuf/protoc-gen-gogo \
	        github.com/grpc-ecosystem/grpc-gateway/protoc-gen-grpc-gateway \
	        github.com/gogo/protobuf/protoc-gen-gogofaster \
		github.com/grpc-ecosystem/grpc-gateway/protoc-gen-swagger
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
	GOFLAGS="" go install honnef.co/go/tools/cmd/staticcheck@v0.2.2
	staticcheck $(PKGS)

errcheck:
	go get -u github.com/kisielk/errcheck
	errcheck -ignoregenerated -verbose -blank $(PKGS)

