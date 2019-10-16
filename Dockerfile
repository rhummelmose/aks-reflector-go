############################
# STEP 1 build executable binary
############################

FROM golang:alpine AS builder
# Install git.
# Git is required for fetching the dependencies.
RUN apk update && apk add --no-cache git
WORKDIR $GOPATH/src/github.com/rhummelmose/aks-reflector
COPY . .
# Fetch dependencies.
# Using go get.
RUN go get -d -v
# Build the binary.
RUN go build -o /go/bin/aksreflector

############################
# STEP 2 build a small image
############################

FROM alpine:latest

ENV KUBE_LATEST_VERSION="v1.16.2"

RUN apk update \
 && apk add bash python3 \
 && ln -sf /usr/bin/python3 /usr/bin/python \
 && apk add --virtual=build gcc libffi-dev musl-dev openssl-dev make python3-dev \
 && pip3 --no-cache-dir install -U pip \
 && pip3 --no-cache-dir install azure-cli \
 && apk del --purge build

RUN apk add --update ca-certificates \
 && apk add --update -t deps curl \
 && curl -L https://storage.googleapis.com/kubernetes-release/release/${KUBE_LATEST_VERSION}/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl \
 && chmod +x /usr/local/bin/kubectl \
 && apk del --purge deps \
 && rm /var/cache/apk/*

COPY --from=builder /go/bin/aksreflector /go/bin/aksreflector

ENTRYPOINT ["/go/bin/aksreflector"]
