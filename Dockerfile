#syntax=docker/dockerfile:1.4.3

FROM ubuntu:22.04@sha256:20fa2d7bb4de7723f542be5923b06c4d704370f0390e4ae9e1c833c8785644c1 AS clone
# renovate: datasource=github-releases depName=containers/podman
ARG PODMAN_VERSION=4.3.0
RUN apt-get update \
 && apt-get -y install --no-install-recommends \
        git \
        ca-certificates
WORKDIR /tmp/podman
RUN test -n "${PODMAN_VERSION}" \
 && git clone --config advice.detachedHead=false --depth 1 --branch "v${PODMAN_VERSION}" \
        https://github.com/containers/podman .

FROM clone AS build
RUN apt-get -y install --no-install-recommends \
        gcc \        
        make \
        btrfs-progs \
        golang-go \
        go-md2man \
        iptables \
        libassuan-dev \
        libbtrfs-dev \
        libc6-dev \
        libdevmapper-dev \
        libglib2.0-dev \
        libgpgme-dev \
        libgpg-error-dev \
        libprotobuf-dev \
        libprotobuf-c-dev \
        libseccomp-dev \
        libselinux1-dev \
        libsystemd-dev \
        pkg-config \
        uidmap
COPY --from=clone /tmp/podman /tmp/podman
WORKDIR /tmp/podman
RUN make EXTRA_LDFLAGS="-s -w -extldflags=-static"

FROM build AS install
RUN rm -f /usr/local/sbin/unminimize \
 && make install PREFIX=/usr/local \
 && mkdir -p \
        /usr/local/share/bash-completion/completions \
        /usr/local/share/fish/vendor_completions.d \
        /usr/local/share/zsh/vendor-completions \
 && cp completions/bash/podman /usr/local/share/bash-completion/completions/podman \
 && cp completions/fish/podman.fish /usr/local/share/fish/vendor_completions.d/podman.fish \
 && cp completions/zsh/_podman /usr/local/share/zsh/vendor-completions/_podman

FROM scratch AS local
COPY --from=install /usr/local/bin     ./bin
COPY --from=install /usr/local/share   ./share
COPY --from=install /usr/local/lib     ./lib
COPY --from=install /usr/local/libexec ./libexec
