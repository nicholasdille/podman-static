FROM nix AS build
RUN apk add --update-cache --no-cache \
        make \
        go-md2man \
        bash
# renovate: datasource=github-releases depName=containers/podman
ARG PODMAN_VERSION=3.4.4
ARG PODMAN_BUILDTAGS='seccomp selinux apparmor exclude_graphdriver_devicemapper containers_image_openpgp'
WORKDIR $GOPATH/src/github.com/containers/podman
RUN test -n "${PODMAN_VERSION}" \
 && git clone --config advice.detachedHead=false --depth 1 --branch "v${PODMAN_VERSION}" \
        https://github.com/containers/podman .
ENV CGO_ENABLED=1 \
    GOOS=linux
RUN mkdir -p \
        /usr/local/share/man/man1 \
        /usr/local/share/bash-completion/completions \
        /usr/local/share/fish/vendor_completions.d \
        /usr/local/share/zsh/vendor-completions \
 && nix build -f nix \
 && cp -rfp ./result/bin/podman /usr/local/bin/ \
 && make docs GOMD2MAN=/usr/bin/go-md2man \
 && cp docs/build/man/*.1 /usr/local/share/man/man1 \
 && cp completions/bash/podman /usr/local/share/bash-completion/completions/podman \
 && cp completions/fish/podman.fish /usr/local/share/fish/vendor_completions.d/podman.fish \
 && cp completions/zsh/_podman /usr/local/share/zsh/vendor-completions/_podman

FROM scratch AS local
COPY --from=build /usr/local/bin/podman ./bin/
COPY --from=build /usr/local/share/man ./share/man/
COPY --from=build /usr/local/share/bash-completion ./share/bash-completion/
COPY --from=build /usr/local/share/fish ./share/fish/
COPY --from=build /usr/local/share/zsh ./share/zsh/
