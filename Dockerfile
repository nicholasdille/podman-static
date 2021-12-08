FROM ubuntu:20.04 AS build
ARG DEBIAN_FRONTEND=noninteractive
RUN ln -fs /usr/share/zoneinfo/Europe/Berlin /etc/localtime \
 && apt-get update \
 && apt-get -y install --no-install-recommends \
        golang \
        git \
        make \
        gcc \
        pkgconf \
        libbtrfs-dev \
        libassuan-dev \
        liblvm2-dev \
        libdevmapper-dev \
        libgpgme-dev \
        libprotobuf-dev \
        libprotobuf-c-dev \
        libseccomp-dev \
        libselinux1-dev \
        ostree \
        openssl \
        iptables \
        bash \
        go-md2man \
        curl \
        ca-certificates

# renovate: datasource=github-releases depName=containers/podman
ARG PODMAN_VERSION=3.4.3
ARG PODMAN_BUILDTAGS='seccomp selinux apparmor exclude_graphdriver_devicemapper containers_image_openpgp'
WORKDIR $GOPATH/src/github.com/containers/podman
RUN test -n "${PODMAN_VERSION}" \
 && git clone --config advice.detachedHead=false --depth 1 --branch "v${PODMAN_VERSION}" \
        https://github.com/containers/podman .
ENV CGO_ENABLED=1
RUN mkdir -p /usr/local/share/man/man1 \
 && make bin/podman docs LDFLAGS_PODMAN="-s -w -extldflags '-static'" BUILDTAGS='${PODMAN_BUILDTAGS}' \
 && mv bin/podman /usr/local/bin/podman \
 && mv docs/build/man/*.1 /usr/local/share/man/man1

FROM scratch AS local
COPY --from=build /usr/local/bin/podman ./bin/
COPY --from=build /usr/local/share/man ./share/man/
