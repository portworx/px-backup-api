#
# Do not use directly, use `make docker-build-proto` instead
#

FROM golang:1.24
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

RUN go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.34.2 && \
    go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.5.1 && \
    go install github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-grpc-gateway@v2.20.0 && \
    go install github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-openapiv2@v2.20.0
