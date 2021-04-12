ASSETS := $(shell yq e '.assets.[].src' manifest.yaml)
ASSET_PATHS := $(addprefix assets/,$(ASSETS))
VERSION_TAG := $(shell git --git-dir=ohmyform/.git describe --tags --abbrev=0)
VERSION := $(VERSION_TAG:v%=%)
OMF_GIT_REF := $(shell cat .git/modules/ohmyform/HEAD)
OMF_GIT_FILE := $(addprefix .git/modules/ohmyform/,$(if $(filter ref:%,$(OMF_GIT_REF)),$(lastword $(OMF_GIT_REF)),HEAD))
# CONFIGURATOR_SRC := $(shell find ./configurator/src) configurator/Cargo.toml configurator/Cargo.lock

.DELETE_ON_ERROR:

all: ohmyform.s9pk

install: ohmyform.s9pk
	appmgr install ohmyform.s9pk

ohmyform.s9pk: manifest.yaml config_spec.yaml config_rules.yaml image.tar instructions.md $(ASSET_PATHS)
	appmgr -vv pack $(shell pwd) -o ohmyform.s9pk
	appmgr -vv verify ohmyform.s9pk

image.tar: Dockerfile docker_entrypoint.sh $(OMF_GIT_FILE)
	DOCKER_CLI_EXPERIMENTAL=enabled docker buildx build --tag start9/ohmyform --build-arg --platform=linux/arm/v7 -o type=docker,dest=image.tar .

# configurator/target/armv7-unknown-linux-musleabihf/release/configurator: $(CONFIGURATOR_SRC)
# 	docker run --rm -v ~/.cargo/registry:/root/.cargo/registry -v "$(shell pwd)"/configurator:/home/rust/src start9/rust-musl-cross:armv7-musleabihf cargo +beta build --release
# 	docker run --rm -v ~/.cargo/registry:/root/.cargo/registry -v "$(shell pwd)"/configurator:/home/rust/src start9/rust-musl-cross:armv7-musleabihf musl-strip target/armv7-unknown-linux-musleabihf/release/configurator

manifest.yaml: $(OMF_GIT_FILE)
	yq eval -i ".version = \"$(VERSION)\"" manifest.yaml
	yq eval -i ".release-notes = \"https://github.com/ohmyform/ohmyform/releases/tag/$(VERSION_TAG)\"" manifest.yaml 
