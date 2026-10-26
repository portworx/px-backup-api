#
# Do not use directly, use `make docker-build-proto` instead
#

FROM golang:1.23
ENV GOPATH=/go
RUN mkdir -p portworx/px-backup-api
WORKDIR portworx/px-backup-api

RUN apt-get update && \
    apt-get install -y clang-format unzip golang-grpc-gateway gogoprotobuf && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN curl -LO https://github.com/protocolbuffers/protobuf/releases/download/v3.14.0/protoc-3.14.0-linux-x86_64.zip
RUN unzip protoc-3.14.0-linux-x86_64.zip -d /usr/local

RUN curl -OL https://github.com/grpc-ecosystem/grpc-gateway/archive/refs/tags/v2.2.0.tar.gz
RUN mkdir -p ${GOPATH}/src/github.com/grpc-ecosystem/grpc-gateway/ && tar -xvf v2.2.0.tar.gz -C ${GOPATH}/src/github.com/grpc-ecosystem/grpc-gateway/ --strip-components=1 && rm -f v2.2.0.tar.gz

RUN git clone https://github.com/gogo/protobuf.git ${GOPATH}/src/github.com/gogo/protobuf

COPY go.mod go.sum  ${WORKDIR}/

# Installing specific versions of Protobuf and gRPC Gateway plugins to ensure compatibility with the older gRPC Gateway v1 setup:
# - `protoc-gen-gogofaster`: Generates optimized Go code for Protobuf using gogo/protobuf (v1.3.2 is compatible with gRPC Gateway v1).
# - `protoc-gen-grpc-gateway`: Generates HTTP reverse proxy code for gRPC services (v1.16.0 is the last stable version for gRPC Gateway v1).
# - `protoc-gen-swagger`: Generates Swagger/OpenAPI specifications from Protobuf definitions (v1.16.0 matches gRPC Gateway v1).
RUN go install github.com/gogo/protobuf/protoc-gen-gogofaster@v1.3.2 && \
    go install github.com/grpc-ecosystem/grpc-gateway/protoc-gen-grpc-gateway@v1.16.0 && \
    go install github.com/grpc-ecosystem/grpc-gateway/protoc-gen-swagger@v1.16.0
