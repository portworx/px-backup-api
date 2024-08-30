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

RUN go get -u \
	        google.golang.org/protobuf \
	        github.com/grpc-ecosystem/grpc-gateway/protoc-gen-grpc-gateway \
			github.com/grpc-ecosystem/grpc-gateway/protoc-gen-swagger
