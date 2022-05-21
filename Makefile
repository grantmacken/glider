SHELL := /bin/bash
.ONESHELL:
.SHELLFLAGS := -O globstar -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules
MAKEFLAGS += --silent
.DEFAULT_GOAL := build

include .env
# images
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
MountProxyConf   := type=volume,target=/opt/proxy/conf,source=proxy-conf
MountLetsencrypt := type=volume,target=/etc/letsencrypt,source=letsencrypt
DASH = printf %60s | tr ' ' '-' && echo

SCHEME ?= https
DOMAIN ?= $(DNS_DOMAIN)
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

include inc/*

.PHONY: build
build: code data assets confs ## default target

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
		$(SCHEME)://$(DNS_DOMAIN)$(ROUTE)
	echo && $(DASH)

.PHONY: rootless
rootless:
	grep -q 'net.ipv4.ip_unprivileged_port_start=80' /etc/sysctl.conf || 
	echo 'net.ipv4.ip_unprivileged_port_start=80' | 
	sudo tee -a /etc/sysctl.conf
	sudo sysctl -w net.ipv4.ip_unprivileged_port_start=80

.PHONY: hosts
hosts:
	grep -q '127.0.0.1   $(DNS_DOMAIN)' /etc/hosts || 
	echo '127.0.0.1   $(DNS_DOMAIN)' |
	sudo tee -a /etc/hosts
	$(DASH)
	cat  /etc/hosts
	$(DASH)

.PHONY: hosts-remove
hosts-remove:
	sudo sed -i '/127.0.0.1   $(DNS_DOMAIN)/d' /etc/hosts
	cat  /etc/hosts

.PHONY: init
init: data-init code-init

data-init: src/data/$(DNS_DOMAIN)/index.md src/data/$(DNS_DOMAIN)/default_layout.xq
code-init: src/code/restXQ/$(DNS_DOMAIN).xqm

.PHONY: init-clean
init-clean:  data-init-clean code-init-clean

code-init-clean: 
	rm -v src/code/restXQ/$(DNS_DOMAIN).xqm || true

data-init-clean: 
	echo '##[ $@ ]##'
	rm -v src/data/$(DNS_DOMAIN)/index.md || true
	rm -v src/data/$(DNS_DOMAIN)/default_layout.xq || true

src/code/restXQ/$(DNS_DOMAIN).xqm: export restXQ_tpl:=$(restXQ_tpl)
src/code/restXQ/$(DNS_DOMAIN).xqm:
	[ -d $(dir $@) ] || mkdir -p $(dir $@)
	echo '##[ $(notdir $@) ]##'
	echo "$${restXQ_tpl}"  > $@
	ls -l $@

src/data/$(DNS_DOMAIN)/index.md: export index_md:=$(index_md)
src/data/$(DNS_DOMAIN)/index.md:
	[ -d $(dir $@) ] || mkdir -p $(dir $@)
	echo '##[ $(notdir $@) ]##'
	echo "$${index_md}"  > $@
	ls -l $@

src/data/$(DNS_DOMAIN)/default_layout.xq: export default_layout:=$(default_layout)
src/data/$(DNS_DOMAIN)/default_layout.xq:
	[ -d $(dir $@) ] || mkdir -p $(dir $@)
	echo '##[ $(notdir $@) ]##'
	echo "$${default_layout}"  > $@
	ls -l $@
