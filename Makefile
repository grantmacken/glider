SHELL := /bin/bash
.ONESHELL:
.SHELLFLAGS := -O globstar -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules
MAKEFLAGS += --silent
include .env
URI := http://localhost:8081
URI2 := http://192.168.1.102:8080
URI_GREET := $(URI)/xqerl
URI_REST := $(URI)/db/
URI_ASSETS := $(URI)/assets/
# images
XQ        := $(XQERL_IMAGE):$(XQERL_VER)
OR        := $(PROXY_IMAGE):$(PROXY_VER)
CERTBOT   := docker.io/certbot/dns-google
CMARK     := ghcr.io/grantmacken/podx-cmark:$(GHPKG_CMARK_VER)
MAGICK    := ghcr.io/grantmacken/podx-magick:$(GHPKG_MAGICK_VER)
W3M       := ghcr.io/grantmacken/podx-w3m:$(W3M_VER)
ZOPFLI    := ghcr.io/grantmacken/podx-zopfli:$(GHPKG_ZOPFLI_VER)
CSSNANO   := ghcr.io/grantmacken/podx-cssnano:$(GHPKG_CSSNANO_VER)
# xqerl volume mounts
MountCode := type=volume,target=/usr/local/xqerl/code,source=xqerl-code
MountData := type=volume,target=/usr/local/xqerl/data,source=xqerl-database
MountAssets := type=volume,target=/usr/local/xqerl/priv/static/assets,source=static-assets
# proxy volume mounts
MountCerts       := type=volume,target=/opt/proxy/certs,source=certs
MountProxyConf   := type=volume,target=/opt/proxy/conf,source=proxy-conf
MountLetsencrypt := type=volume,target=/etc/letsencrypt,source=letsencrypt
DASH = printf %60s | tr ' ' '-' && echo

.help: help
help: 
	echo 'help'

include inc/*
#
.PHONY: up
up: or-up

.PHONY: podx
podx: volumes # --publish 80:80 --publish 443:443
	echo "##[ $(@) ##]"
	whoami | grep -q root
	podman pod exists $(POD) || \
		podman pod create \
		--publish 80:80 \
	  --publish 443:443 \
		--network podman \
		--name $(@)
	# podman pod list
	# podman pod inspect $(POD) | jq '.'

.PHONY: down
down:
	echo "##[ $(@) ]##" 
	whoami | grep -q root
	@podman pod list
	@podman ps -a --pod
	@podman pod stop -a || true
	@podman pod rm $(POD) || true
	@podman rm --all
	@podman ps -a --pod

.PHONY: xq-up # in podx listens on port 8081/tcp 
xq-up: podx
	echo "##[ $(@) ]##" 
	whoami | grep -q root
	if ! podman ps -a | grep -q $(XQ)
	then
	podman run --name xq --pod $(POD) \
		--mount $(MountCode) --mount $(MountData) --mount $(MountAssets) \
	  --mount type=bind,destination=/usr/local/xqerl/src,source=$(CURDIR)/src,relabel=shared \
		--tz=$(TIMEZONE) \
		--detach $(XQ)
	sleep 1
	podman ps -a --pod | grep -oP '$(XQ)(.+)$$'
	sleep 1
	podman exec xq xqerl eval 'application:ensure_all_started(xqerl).'
	fi

#certs confs confs-check

.PHONY: or-up # 
or-up: xq-up
	echo "##[ $(@) ]##"
	whoami | grep -q root
	if ! podman ps -a | grep -q $(OR)
	then
	podman run --pod $(POD) \
		--name or \
		--tz=$(TIMEZONE) \
		--detach $(OR)
	podman ps -a --pod | grep -oP '$(OR)(.+)$$'
	fi

.PHONY: or-down
or-down: #TODO use systemd instead
	echo "##[ $(@) ]##"
	whoami | grep -q root
	podman stop or || true
	podman rm or || true

.PHONY: xq-down
xq-down: #TODO use systemd instead
	echo "##[ $(@) ]##"
	whoami | grep -q root
	echo "##[ $(@) ]##"
	podman stop xq || true
	podman rm xq || true

.PHONY: images ## pull docker images
images:
	echo "##[ $(@) ]##"
	whoami | grep -q root
	podman pull $(XQ)
	podman pull $(OR)
	podman pull $(W3M)

.PHONY: volumes
volumes:
	echo "##[ $(@) ]##"
	whoami | grep -q root
	@podman volume exists xqerl-code || podman volume create xqerl-code
	@podman volume exists xqerl-database || podman volume create xqerl-database
	@podman volume exists static-assets || podman volume create static-assets
	@podman volume exists proxy-conf || podman volume create proxy-conf
	@podman volume exists letsencrypt || podman volume create letsencrypt
	@# podman volume exists lualib || podman volume create lualib
	@#podman volume ls

.PHONY: volumes-clean
volumes-clean:
	echo "##[ $(@) ]##"
	whoami | grep -q root
	podman volume remove xqerl-code || true
	podman volume remove xqerl-database || true
	podman volume remove static-assets || true
	podman volume remove static-assets || true
	podman volume remove proxy-conf || true
	podman volume remove letsencrypt || true

.PHONY: service
service: 
	echo "##[ $(@) ]##"
	whoami | grep -q root
	# mkdir -p $(HOME)/.config/systemd/user
	rm -f *.service
	podman generate systemd --files --name $(POD) 
	cat container-or.service | 
	sed 's/After=pod-podx.service/After=pod-podx.service container-xq.service/g' |
	sed '18 i ExecStartPre=/bin/sleep 2' | sudo tee /etc/systemd/system/container-or.service
	cat pod-podx.service| sudo tee /etc/systemd/system/pod-podx.service
	cat container-xq.service | sudo tee /etc/systemd/system/container-xq.service
	systemctl daemon-reload
	systemctl is-enabled container-xq.service &>/dev/null || systemctl enable container-xq.service 
	systemctl is-enabled container-or.service &>/dev/null || systemctl enable container-or.service 
	systemctl is-enabled pod-podx.service &>/dev/null || systemctl enable pod-podx.service
	rm -f *.service
	#reboot


# Note systemctl should only be used on the pod unit and one should not start 

.PHONY: service-start
service-start: 
	@systemctl start  pod-podx.service
	@podman pod list
	@podman ps -a --pod
	@podman top xq

.PHONY: service-stop
service-stop:
	@systemctl stop  pod-podx.service

.PHONY: service-status
service-status:
	echo "##[ $(@) ]##"
	whoami | grep -q root
	systemctl --no-pager status pod-podx.service
	$(DASH)
	# journalctl --no-pager -b CONTAINER_NAME=or
	$(DASH)

.PHONY: journal
journal:
	journalctl --no-pager -b CONTAINER_NAME=xq
