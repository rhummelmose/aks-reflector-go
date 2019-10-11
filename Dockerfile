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

RUN apk update
RUN apk add bash python3
RUN ln -sf /usr/bin/python3 /usr/bin/python
RUN apk add --virtual=build gcc libffi-dev musl-dev openssl-dev make python3-dev
RUN pip3 --no-cache-dir install -U pip
RUN pip3 --no-cache-dir install azure-cli
RUN apk del --purge build

COPY --from=builder /go/bin/aksreflector /go/bin/aksreflector

ENTRYPOINT ["/go/bin/aksreflector"]
