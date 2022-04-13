SHELL := /bin/bash
.ONESHELL:
.SHELLFLAGS := -O globstar -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules
MAKEFLAGS += --silent
.DEFAULT_GOAL := build

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
ZOPFLI    := ghcr.io/grantmacken/podx-zopfli:$(GHPKG_ZOPFLI_VER)
CSSNANO   := ghcr.io/grantmacken/podx-cssnano:$(GHPKG_CSSNANO_VER)
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

# ipAddress = podman inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(XQ)

.help: help
help: 
	echo 'help'

include inc/*

.PHONY: build
build: confs code data assets

#
.PHONY: up
up: or-up
	$(DASH)
	w3m -dump http://localhost:$(POD_PORT)
	echo && $(DASH)

.PHONY: podx
podx: volumes # --publish 80:80 --publish 443:443
	echo "##[ $(@) ##]"
	#whoami | grep -q root
	podman pod exists $(POD) || \
		podman pod create \
		--publish $(POD_PORT):80 \
	  --publish $(POD_TLS_PORT):443 \
		--network podman \
		--name $(@)

.PHONY: down
down:
	echo "##[ $(@) ]##" 
	podman pod list
	podman ps -a --pod
	podman pod stop -a || true
	podman pod rm $(POD) || true
	podman rm --all
	podman ps --all --pod

.PHONY: clean
clean: confs-clean data-clean code-clean assets-clean down
	echo "##[ $(@) ]##" 
	@systemctl --user stop pod-podx.service || true
	@systemctl --user disable container-xq.service || true
	@systemctl --user disable container-or.service || true
	@systemctl --user disable pod-podx.service || true
	pushd $(HOME)/.config/systemd/user/
	rm -f container-or.service container-xq.service pod-podx.service
	popd
	@systemctl --user daemon-reload
	podman system prune --all --force
	podman system prune --volumes --force

.PHONY: xq-up # in podx listens on port 8081/tcp 
xq-up: podx
	echo "##[ $(@) ]##" 
	if ! podman ps | grep -q $(XQ)
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

.PHONY: or-up # 
or-up: xq-up
	echo "##[ $(@) ]##"
	#whoami | grep -q root
	if ! podman ps | grep -q $(OR)
	then
	podman run --pod $(POD) \
		--name or \
		--mount $(MountProxyConf) \
		--mount $(MountLetsencrypt) \
		--tz=$(TIMEZONE) \
		--detach $(OR)
	podman ps -a --pod | grep -oP '$(OR)(.+)$$'
	fi

.PHONY: or-down
or-down: #TODO use systemd instead
	echo "##[ $(@) ]##"
	#whoami | grep -q root
	podman stop or || true
	podman rm or || true

.PHONY: xq-down
xq-down: #TODO use systemd instead
	echo "##[ $(@) ]##"
	#whoami | grep -q root
	echo "##[ $(@) ]##"
	podman stop xq || true
	podman rm xq || true

.PHONY: images ## pull docker images
images:
	echo "##[ $(@) ]##"
	#whoami | grep -q root
	podman pull $(XQ)
	podman pull $(OR)
	podman pull $(W3M)
	podman pull $(CURL)
	podman pull $(CMARK)

.PHONY: volumes
volumes:
	echo "##[ $(@) ]##"
	#whoami | grep -q root
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
	#whoami | grep -q root
	podman volume remove xqerl-code || true
	podman volume remove xqerl-database || true
	podman volume remove static-assets || true
	podman volume remove static-assets || true
	podman volume remove proxy-conf || true
	podman volume remove letsencrypt || true

.PHONY: service
service: 
	echo "##[ $(@) ]##"
	#whoami | grep -q root
	mkdir -p $(HOME)/.config/systemd/user
	rm -f *.service
	podman generate systemd --files --name $(POD) 
	@cat pod-podx.service > $(HOME)/.config/systemd/user/pod-podx.service
	cat container-xq.service > $(HOME)/.config/systemd/user/container-xq.service
	cat container-or.service | 
	sed 's/After=pod-podx.service/After=pod-podx.service container-xq.service/g' |
	sed '18 i ExecStartPre=/bin/sleep 2' | tee $(HOME)/.config/systemd/user/container-or.service
	@systemctl --user daemon-reload
	@systemctl --user is-enabled container-xq.service &>/dev/null || systemctl --user enable container-xq.service
	@systemctl --user is-enabled container-or.service &>/dev/null || systemctl --user enable container-or.service
	@systemctl --user is-enabled pod-podx.service &>/dev/null || systemctl --user enable pod-podx.service
	rm -f *.service
	#reboot

# Note systemctl should only be used on the pod unit and one should not start 

.PHONY: service-start
service-start: 
	@systemctl --user stop pod-podx.service
	@podman pod list
	@podman ps -a --pod
	@podman top xq

.PHONY: service-stop
service-stop:
	@systemctl --user stop  pod-podx.service

.PHONY: service-status
service-status:
	echo "##[ $(@) ]##"
	#whoami | grep -q root
	systemctl --user --no-pager status pod-podx.service
	$(DASH)
	# journalctl --no-pager -b CONTAINER_NAME=or
	$(DASH)

.PHONY: journal
journal:
	journalctl --user --no-pager -b CONTAINER_NAME=xq

.PHONY: service-clean
service-clean: 
	@systemctl --user stop pod-podx.service || true
	@systemctl --user disable container-xq.service || true
	@systemctl --user disable container-or.service || true
	@systemctl --user disable pod-podx.service || true
	pushd $(HOME)/.config/systemd/user/
	rm -f container-or.service container-xq.service pod-podx.service
	popd
	@systemctl --user daemon-reload

.PHONY: init
init:  rootless hosts

.PHONY: rootless
rootless:
	grep -q 'net.ipv4.ip_unprivileged_port_start=80' /etc/sysctl.conf || 
	echo 'net.ipv4.ip_unprivileged_port_start=80' | 
	sudo tee -a /etc/sysctl.conf
	sudo sudo sysctl --system

.PHONY: hosts
hosts:
	grep -q '127.0.0.1   example.com' /etc/hosts || 
	echo '127.0.0.1   example.com' | 
	sudo tee -a /etc/hosts
