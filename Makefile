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

.DEFAULT_GOAL: all

all: proto pretest

proto:
	clang-format -i $(PROTOC_FILES)
	go get -u github.com/gogo/protobuf/...
	go get -u github.com/grpc-ecosystem/grpc-gateway/...
	$(PROTOC) -I/usr/local/include -I. \
		-I${GOPATH}/src \
		-I${GOPATH}/src/github.com/gogo/protobuf/protobuf \
		-I${GOPATH}/src/github.com/grpc-ecosystem/grpc-gateway/third_party/googleapis \
		--gogofaster_out=\
Mgogoproto/gogo.proto=github.com/gogo/protobuf/gogoproto,\
Mgoogle/protobuf/any.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/empty.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/duration.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/field_mask.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/struct.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/timestamp.proto=github.com/gogo/protobuf/types,\
Mgoogle/protobuf/wrappers.proto=github.com/gogo/protobuf/types,\
plugins=grpc:. \
	    $(PROTOC_FILES)
	$(PROTOC) -I/usr/local/include -I. \
		-I${GOPATH}/src \
		-I${GOPATH}/src/github.com/grpc-ecosystem/grpc-gateway/third_party/googleapis \
		--grpc-gateway_out=logtostderr=true:. \
		$(PROTOC_FILES)
	$(PROTOC) -I/usr/local/include -I. \
		-I${GOPATH}/src \
		-I${GOPATH}/src/github.com/grpc-ecosystem/grpc-gateway/third_party/googleapis \
		--swagger_out=logtostderr=true:. \
		$(PROTOC_FILES)

pretest: vet staticcheck errcheck 

vet:
	go vet $(PKGS)

staticcheck:
	go get -u honnef.co/go/tools/cmd/staticcheck
	staticcheck $(PKGS)

errcheck:
	go get -u github.com/kisielk/errcheck
	errcheck -ignoregenerated -verbose -blank $(PKGS)

