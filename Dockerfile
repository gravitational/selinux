FROM golang:1.13.14-buster

RUN set -x && \
	go get -u github.com/gravitational/tpl && \
	go install github.com/gravitational/tpl

FROM registry.centos.org/centos/centos:8

RUN set -x && yum -y install \
	selinux-policy-targeted \
	selinux-policy-devel \
	bzip2 \
	make

COPY --from=0 /go/bin/tpl /usr/local/bin/

RUN mkdir -p /src

ADD .bashrc /root/.bashrc

WORKDIR "/src"
VOLUME ["/src"]
