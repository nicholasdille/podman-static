docker build --tag nix github.com/NixOS/docker

docker run --name nix --detach nix sh -c 'while true; do sleep 10; done'

cat >install.sh <<EOF
# renovate: datasource=github-releases depName=containers/buildah
BUILDAH_VERSION=1.23.1
# renovate: datasource=github-releases depName=containers/conmon
CONMON_VERSION=2.0.30
# renovate: datasource=github-releases depName=containers/crun
CRUN_VERSION=1.3
# renovate: datasource=github-releases depName=containers/podman
PODMAN_VERSION=3.4.2
# renovate: datasource=github-releases depName=containers/skopeo
SKOPEO_VERSION=1.5.1

apk add --update-cache --no-cache \
    bash \
    git \
    go

date
git clone --recursive https://github.com/containers/buildah.git
(
    cd buildah
    git checkout "v${BUILDAH_VERSION}"

    nix build -f nix/
	  mkdir -p ./bin
	  cp -rfp ./result/bin/* /usr/local/bin/
)

date
git clone --recursive https://github.com/containers/conmon.git
(
    cd conmon
    git checkout "v${CONMON_VERSION}"

    nix build -f nix/
	  mkdir -p ./bin
	  cp -rfp ./result/bin/* /usr/local/bin/
)

date
git clone --recursive https://github.com/containers/crun.git
(
    cd crun
    git checkout "${CRUN_VERSION}"

    nix build -f nix/
	  mkdir -p ./bin
	  cp -rfp ./result/bin/* /usr/local/bin/
)

date
git clone --recursive https://github.com/containers/podman.git
(
    cd podman
    git checkout "v${PODMAN_VERSION}"

    nix build -f nix/
	  mkdir -p ./bin
	  cp -rfp ./result/bin/* /usr/local/bin/
)

date
git clone --recursive https://github.com/containers/skopeo.git
(
    cd skopeo
    git checkout "v${SKOPEO_VERSION}"

    # https://github.com/containers/skopeo/blob/main/install.md#building-a-static-binary
)
EOF

docker cp install.sh nix:/
docker exec -i nix apk add --update-cache --no-cache bash
docker exec -i nix bash /install.sh

mkdir ./bin
docker cp nix:/usr/local/bin/* ./bin/