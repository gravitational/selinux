MODULES?=${TARGETS:=.pp.bz2}
SHAREDIR?=/usr/share
AWSCLI?=aws
TARGETS?=$(OUTPUT)/container $(OUTPUT)/gravity
SOURCES=gravity.te gravity.if gravity.fc
CONTAINER_SOURCES=$(addprefix, container-selinux/, container.te container.if container.fc)
BUILDBOX?=selinux-dev:centos
BUILDBOX_INSTANCE?=selinux-dev
VERSION?=6.0.0
BUILD_BUCKET_URL?=s3://clientbuilds.gravitational.io
OUTPUT?=output
CONTAINER_RUNTIME:=$(shell command -v podman 2> /dev/null || echo docker)

all: build

$(OUTPUT)/%.pp.bz2: $(OUTPUT)/%.pp | $(OUTPUT)
	@echo Compressing $^ -\> $@
	bzip2 -f -9 -c $^ > $@

$(OUTPUT)/gravity.pp: $(SOURCES) | $(OUTPUT)
	make -f ${SHAREDIR}/selinux/devel/Makefile $(@F)
	mv $(@F) $@

$(OUTPUT)/container.pp: $(CONTAINER_SOURCES) | $(OUTPUT)
	make -f ${SHAREDIR}/selinux/devel/Makefile $(@F)
	install -D -m 644 container-selinux/container.if ${DESTDIR}${SHAREDIR}/selinux/devel/include/services/container.if
	mv $(@F) $@

.PHONY: clean
clean:
	rm -f *~ *.tc $(OUTPUT)/*.pp $(OUTPUT)/*.pp.bz2
	rm -f container-selinux/*~ container-selinux/*.tc
	rm -rf tmp *.tar.gz

.PHONY: man
man: install-policy
	sepolicy manpage --path . --domain ${TARGETS}_t

.PHONY: install-policy
install-policy: all
	semodule -i ${TARGETS}.pp.bz2

.PHONY: install
install: man
	install -D -m 644 ${TARGETS}.pp.bz2 ${DESTDIR}${SHAREDIR}/selinux/packages/
	install -D -m 644 container-selinux/container.if ${DESTDIR}${SHAREDIR}/selinux/devel/include/services/container.if
	install -D -m 644 gravity.if ${DESTDIR}${SHAREDIR}/selinux/devel/include/services/gravity.if
	install -D -m 644 container-selinux/container_selinux.8 ${DESTDIR}${SHAREDIR}/man/man8/

.PHONY: build
build: buildbox
	${CONTAINER_RUNTIME} run \
		--name=${BUILDBOX_INSTANCE} \
		--privileged \
		-v ${PWD}:/src \
		--rm ${BUILDBOX} \
		make ${TARGETS:=.pp.bz2}

.PHONY: buildbox
buildbox:
	${CONTAINER_RUNTIME} build -t ${BUILDBOX} -f Dockerfile .

.PHONY: publish
publish: build
	$(AWSCLI) s3 cp ${S3_OPTS} ${TARGETS:=.pp.bz2} ${BUILD_BUCKET_URL}/selinux-policy/centos/${VERSION}/

.PHONY: get-version
get-version:
	@echo ${VERSION}

$(OUTPUT):
	mkdir -p $@
