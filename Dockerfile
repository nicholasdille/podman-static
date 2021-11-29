FROM golang:1.16-alpine3.14 AS base
RUN apk add --update-cache --no-cache \
        git \
        make \
        gcc \
        pkgconf \
        musl-dev \
	    btrfs-progs \
        btrfs-progs-dev \
        libassuan-dev \
        lvm2-dev \
        device-mapper \
	    glib-static \
        libc-dev \
        gpgme-dev \
        protobuf-dev \
        protobuf-c-dev \
	    libseccomp-dev \
        libseccomp-static \
        libselinux-dev \
        ostree-dev \
        openssl \
        iptables \
	    bash \
        go-md2man

FROM base AS podman
RUN apk add --update-cache --no-cache \
        tzdata \
        curl
# renovate: datasource=github-releases depName=containers/podman
ARG PODMAN_VERSION=3.4.2
ARG PODMAN_BUILDTAGS='seccomp selinux apparmor exclude_graphdriver_devicemapper containers_image_openpgp'
WORKDIR $GOPATH/src/github.com/containers/podman
RUN git clone --config advice.detachedHead=false --depth 1 --branch "v${PODMAN_VERSION}" \
        https://github.com/containers/podman .
ENV CGO_ENABLED=1
RUN make bin/podman LDFLAGS_PODMAN="-s -w -extldflags '-static'" BUILDTAGS='${PODMAN_BUILDTAGS}' \
 && mv bin/podman /usr/local/bin/podman

FROM scratch AS local
COPY --from=podman /usr/local/bin/podman .