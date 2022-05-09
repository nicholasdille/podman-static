FROM ubuntu:22.04@sha256:26c68657ccce2cb0a31b330cb0be2b5e108d467f641c62e13ab40cbec258c68d
# renovate: datasource=github-releases depName=containers/podman
ARG PODMAN_VERSION=3.4.4
RUN apt-get update \
 && apt-get -y install --no-install-recommends \
        git \
        ca-certificates
WORKDIR /tmp/podman
RUN test -n "${PODMAN_VERSION}" \
 && git clone --config advice.detachedHead=false --depth 1 --branch "v${PODMAN_VERSION}" \
        https://github.com/containers/podman .

FROM nixos/nix:2.8.0@sha256:cafda2d5f9de275ca0b6cf617d2664200fb96082a23c0ee070c130938f2e9197 AS binaries
COPY --from=clone /tmp/podman /tmp/podman
WORKDIR /tmp/podman
RUN nix build -f nix --extra-experimental-features nix-command \
 && cp -rfp ./result/bin/podman /usr/local/bin/ \

FROM alpine:3.15@sha256:4edbd2beb5f78b1014028f4fbb99f3237d9561100b6881aabbf5acce2c4f9454 AS manpages
RUN apk add --update-cache --no-cache \
        make \
        go-md2man
COPY --from=clone /tmp/podman /tmp/podman
WORKDIR /tmp/podman
ARG PODMAN_BUILDTAGS='seccomp selinux apparmor exclude_graphdriver_devicemapper containers_image_openpgp'
ENV CGO_ENABLED=1 \
    GOOS=linux
RUN mkdir -p \
        /usr/local/share/man/man1 \
        /usr/local/share/bash-completion/completions \
        /usr/local/share/fish/vendor_completions.d \
        /usr/local/share/zsh/vendor-completions \
 && make docs GOMD2MAN=/usr/bin/go-md2man \
 && cp docs/build/man/*.1 /usr/local/share/man/man1 \
 && cp completions/bash/podman /usr/local/share/bash-completion/completions/podman \
 && cp completions/fish/podman.fish /usr/local/share/fish/vendor_completions.d/podman.fish \
 && cp completions/zsh/_podman /usr/local/share/zsh/vendor-completions/_podman

FROM scratch AS local
COPY --from=build    /usr/local/bin/podman ./bin/
COPY --from=manpages /usr/local/share/man ./share/man/
COPY --from=manpages /usr/local/share/bash-completion ./share/bash-completion/
COPY --from=manpages /usr/local/share/fish ./share/fish/
COPY --from=manpages /usr/local/share/zsh ./share/zsh/
