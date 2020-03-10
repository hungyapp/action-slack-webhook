FROM golang:1.11-alpine3.9@sha256:7a0bf914dd581a35afb054bc02c6b7a3fa31ed6398adf95ac88fb1efffe89cf6 AS builder

LABEL "com.github.actions.icon"="bell"
LABEL "com.github.actions.color"="yellow"
LABEL "com.github.actions.name"="Webhook Slack Notification"
LABEL "com.github.actions.description"="Slack Notification"


WORKDIR ${GOPATH}/src/github.com/hungyapp/action-slack-webhook
COPY main.go ${GOPATH}/src/github.com/hungyapp/action-slack-webhook

ENV CGO_ENABLED 0
ENV GOOS linux

RUN go get -v ./...
RUN go build -a -installsuffix cgo -ldflags '-w  -extldflags "-static"' -o /go/bin/slack-webhook .

# alpine:latest at 2019-01-04T21:27:39IST
FROM alpine@sha256:46e71df1e5191ab8b8034c5189e325258ec44ea739bba1e5645cff83c9048ff1

COPY --from=builder /go/bin/slack-webhook /usr/bin/slack-webhook

ENV VAULT_VERSION 1.0.2

RUN apk update \
	&& apk upgrade \
	&& apk add \
	bash \
	jq \
	ca-certificates \
	python \
	py2-pip && \
	pip install shyaml && \
	rm -rf /var/cache/apk/*

# Setup Vault
RUN wget https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip && \
	unzip vault_${VAULT_VERSION}_linux_amd64.zip && \
	rm vault_${VAULT_VERSION}_linux_amd64.zip && \
	mv vault /usr/local/bin/vault

# fix the missing dependency - https://stackoverflow.com/a/35613430
RUN mkdir /lib64 && ln -s /lib/libc.musl-x86_64.so.1 /lib64/ld-linux-x86-64.so.2

COPY *.sh /

RUN chmod +x /*.sh

ENTRYPOINT ["/entrypoint.sh"]
