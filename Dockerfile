FROM golang:1.12.9-buster

RUN set -x && \
	go get -u github.com/gravitational/tpl && \
	go install github.com/gravitational/tpl

FROM registry.centos.org/centos/centos:7

RUN set -x && yum -y install \
	selinux-policy-devel \
	bzip2 \
	make \
	git

COPY --from=0 /go/bin/tpl /usr/local/bin/

RUN mkdir -p /src

ADD .bashrc /root/.bashrc

WORKDIR "/src"
VOLUME ["/src"]
