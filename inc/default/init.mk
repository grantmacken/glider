
WHICH_LIST := podman curl timedatectl openssl
assert-command-present = $(if $(shell which $1),,$(error '$1' missing and needed for this project))
$(foreach src,$(WHICH_LIST),$(call assert-command-present,$(src)))


POD=podx
# image versions
XQERL_VER=v0.1.10
PROXY_VER=v1.21.4.1
ALPINE_VER=v3.15.4
W3M_VER=v0.5.3
CURL_VER=v7.83.1
CMARK_VER=v0.30.2
# CSSNANO_VER=5.0.8
# MAGICK_VER=7.0.11
# ZOPFLI_VER=1.0.3
# pod name
# images-
XQ        := ghcr.io/grantmacken/xqerl:$(XQERL_VER)
OR        := ghcr.io/grantmacken/podx-openresty:$(PROXY_VER)
CERTBOT   := docker.io/certbot/dns-google
CMARK     := ghcr.io/grantmacken/podx-cmark:$(CMARK_VER)
# MAGICK    := ghcr.io/grantmacken/podx-magick:$(GHPKG_MAGICK_VER)
# ZOPFLI    := ghcr.io/grantmacken/podx-zopfli:$(GHPKG_ZOPFLI_VER)
# CSSNANO   := ghcr.io/grantmacken/podx-cssnano:$(GHPKG_CSSNANO_VER)
W3M       := ghcr.io/grantmacken/podx-w3m:$(W3M_VER)
CURL      := ghcr.io/grantmacken/podx-curl:$(CURL_VER)
# xqerl volume mounts
MountCode := type=volume,target=/usr/local/xqerl/code,source=xqerl-code
MountData := type=volume,target=/usr/local/xqerl/data,source=xqerl-database
MountAssets := type=volume,target=/usr/local/xqerl/priv/static/assets,source=static-assets
# proxy volume mounts
MountProxy   := type=volume,target=/opt/proxy,source=proxy
MountLetsencrypt := type=volume,target=/etc/letsencrypt,source=letsencrypt
# expansion shortcut
DASH = printf %60s | tr ' ' '-' && echo
ESCRIPT := podman exec xq xqerl escript
EVAL    := podman exec xq xqerl eval

SCHEME ?= https
DOMAIN ?= $(DOMAIN)
ROUTE ?= /index
Dump = podman run --pod $(POD) --rm $(W3M) -dump $(1)://$(2)$(3)
CRL := podman run --pod $(POD) --rm  $(CURL)

rwildcard = $(foreach d,$(wildcard $(1:=/*)),$(call rwildcard,$d,$2) $(filter $(subst *,%,$2),$d))
ipAddress = podman inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(OR)

.PHONY: help
help: ## show this help 
	cat $(MAKEFILE_LIST) | 
	grep -oP '^[a-zA-Z_-]+:.*?## .*$$' |
	sort |
	awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: build
build: code data assets proxy ## default xqerl target

.PHONY: build-clean
build-clean: confs-clean code-clean data-clean assets-clean

.PHONY: watch
watch:
	while true; do \
        clear && $(MAKE) 2>/dev/null || true; \
        inotifywait -qre close_write ./src || true; \
    done

.PHONY: dump
dump:
	$(call Dump,$(SCHEME),$(DOMAIN),$(ROUTE))

curl: 
	$(DASH)
	curl --silent --show-error  \
		--connect-timeout 1 \
		--max-time 2 \
		$(SCHEME)://$(DOMAIN)$(ROUTE)
	echo && $(DASH)

.PHONY: hosts
hosts:
	grep -q '127.0.0.1   $(DOMAIN)' /etc/hosts || 
	echo '127.0.0.1   $(DOMAIN)' |
	sudo tee -a /etc/hosts
	$(DASH)
	cat  /etc/hosts
	$(DASH)

.PHONY: hosts-remove
hosts-remove:
	sudo sed -i '/127.0.0.1   $(DOMAIN)/d' /etc/hosts
	cat  /etc/hosts

