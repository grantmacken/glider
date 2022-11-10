
WHICH_LIST := podman curl timedatectl openssl
assert-command-present = $(if $(shell which $1),,$(error '$1' missing and needed for this project))
$(foreach src,$(WHICH_LIST),$(call assert-command-present,$(src)))

POD=podx
# image versions
PROXY_VER=v1.21.4.1
ALPINE_VER=v3.15.4
W3M_VER=v0.5.3

CMARK_VER ?= v0.30.2
CURL_VER ?= v7.83.1
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
CURL_OPTS := --silent --show-error --connect-timeout 2 --max-time 4 --write-out '%{http_code}' --output /dev/null 
CRL := podman run --interactive --pod $(POD) --rm  $(CURL) $(CURL_OPTS)
DB := http://localhost:8081/db

# xqerl volume mounts
MountCode := type=volume,target=/usr/local/xqerl/code,source=xqerl-code
MountData := type=volume,target=/usr/local/xqerl/data,source=xqerl-database
MountPriv := type=volume,target=/usr/local/xqerl/priv,source=xqerl-priv

# proxy volume mounts
MountProxy   := type=volume,target=/opt/proxy,source=proxy
MountLetsencrypt := type=volume,target=/etc/letsencrypt,source=letsencrypt
# expansion shortcut
DASH = printf %60s | tr ' ' '-' && echo
EXEC := podman exec xq
ESCRIPT := $(EXEC) xqerl escript
EVAL    := $(EXEC) xqerl eval

SCHEME ?= https
DOMAIN ?= $(DOMAIN)
ROUTE ?= /index
Dump = podman run --pod $(POD) --rm $(W3M) -dump $(1)://$(2)$(3)


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

.PHONY: build-clean ## clean build - removes item item in _build and tars
build-clean: proxy-clean code-clean data-clean assets-clean

.PHONY: build-wipe-out ## remove_build directory
build-wipe-out:
	echo "##[ $(@) ]##"
	rm -frv _build
	mkdir -p ../glider-archive/$(DOMAIN)
	tar -czvf  ../glider-archive/$(DOMAIN)/$(shell date --iso).tar.gz  _deploy
	rm -frv _deploy

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

.PHONY: rootless
rootless:
	grep -q 'net.ipv4.ip_unprivileged_port_start=80' /etc/sysctl.conf || 
	echo 'net.ipv4.ip_unprivileged_port_start=80' | 
	sudo tee -a /etc/sysctl.conf
	sudo sysctl -w net.ipv4.ip_unprivileged_port_start=80

.PHONY: up
up: or-up
	$(DASH)
	# access xqerl in the pods internal network
	#podman run --rm --name req1 --pod $(POD) $(W3M) -dump http://localhost:8081/xqerl
	$(DASH)
	sleep 1
	echo -n 'container xq status: '
	podman inspect -f '{{.State.Status}}' xq
	sleep 1
	echo -n 'container or status: '
	podman inspect -f '{{.State.Status}}' or
	$(DASH)
	sleep 1
	$(call Dump,'http',localhost,/xqerl)
	echo && $(DASH)

.PHONY: container-images 
container-images:  ## pull docker images
	echo "##[ $(@) ]##"
	podman images | grep -oP 'xqerl(.+)$(XQERL_VER)' || podman pull $(XQ)
	podman images | grep -oP 'podx-openresty(.+)$(PROXY_VER)' || podman pull $(OR)
	podman images | grep -oP 'podx-w3m(.+)$(W3M_VER)' || podman pull $(W3M)
	podman images | grep -oP 'podx-cmark(.+)$(CMARK_VER)' || podman pull $(CMARK)
	podman images | grep -oP 'podx-curl(.+)$(CURL_VER)' || podman pull $(CURL)

.PHONY: images-reset-xqerl
images-reset-xqerl:
	echo "##[ $(@) ]##"
	podman pod rm podx || true
	podman rmi ghcr.io/grantmacken/xqerl:v0.1.10 

.PHONY: volumes
volumes: container-images
	echo "##[ $(@) ]##"
	podman volume exists xqerl-code || podman volume create xqerl-code
	podman volume exists xqerl-database || podman volume create xqerl-database
	podman volume exists xqerl-priv || podman volume create xqerl-priv
	# podman volume exists static-assets || podman volume create static-assets
	# podman volume exists priv-bin || podman volume create priv-bin
	podman volume exists proxy || podman volume create proxy
	podman volume exists letsencrypt || podman volume create letsencrypt

.PHONY: volumes-clean
volumes-clean: volumes-remove-xqerl-code volumes-remove-xqerl-database volumes-remove-xqerl-priv volumes-remove-proxy 
	echo "##[ $(@) ]##"
	echo 'All podx volumes have been removed apart from the letsencypt volume'
	echo 'Restore volumes with `make volumes`'

# .PHONY: volumes-remove-static-assets
# volumes-remove-static-assets:
# 	echo '##[ $@ ]##'
# 	podman volume remove static-assets || true

.PHONY: volumes-remove-xqerl-code
volumes-remove-xqerl-code:
	echo '##[ $@ ]##'
	podman volume remove xqerl-code || true

.PHONY: volumes-remove-xqerl-database
volumes-remove-xqerl-database:
	echo '##[ $@ ]##'
	podman volume remove xqerl-database || true
	$(MAKE) data-clean

.PHONY: volumes-remove-xqerl-priv
	volumes-remove-xqerl-priv:
	echo '##[ $@ ]##'
	podman volume remove priv-bin || true


.PHONY: volumes-remove-proxy
volumes-remove-proxy:
	echo '##[ $@ ]##'
	podman volume remove proxy || true

.PHONY: volumes-import
volumes-import:
	echo "##[ $(@) ]##"
	if [ -f _deploy/proxy.tar ] ; then podman volume import proxy _deploy/proxy.tar ;fi
	if [ -f _deploy/static-assets.tar ] ; then podman volume import static-assets _deploy/static-assets.tar ;fi

.PHONY: podx
podx: volumes #
	echo "##[ $(@) ##]"
	podman pod exists $(POD) || \
		podman pod create \
		--publish 80:80 \
	  --publish 443:443 \
		--network podman \
		--name $(@)

.PHONY: down
down:
	echo "##[ $(@) ]##"
	podman pod rm --force $(POD) || true
	podman ps --all --pod

.PHONY: clean-archive
clean-archive: ## archive $(DOMAIN) tars then clean build
	echo "##[ $(@) ]##"
	mkdir -p ../archive/$(DOMAIN)/$$(date --iso)/
	mv _deploy/*  ../archive/$(DOMAIN)/$$(date --iso)/ &>/dev/null || true
	rm -fr _build

.PHONY: clean-service
clean-service: ## remove service
	echo "##[ $(@) ]##"
	rm -fr _build
	read -p "Remove service? (Y/N): " CONFIRM
	if [[ "$$CONFIRM" == [yY] ]]; then
	systemctl --user stop pod-podx.service || true
	systemctl --user disable container-xq.service || true
	systemctl --user disable container-or.service || true
	systemctl --user disable pod-podx.service || true
	pushd $(HOME)/.config/systemd/user/
	rm -f container-or.service container-xq.service pod-podx.service
	popd
	systemctl --user daemon-reload
	podman pod rm --force $(POD)
	fi

.PHONY: pod-clean
pod-clean: ## remove podx including containers 
	echo "##[ $(@) ]##"
	if podman pod exists $(POD)
	then
	podman pod rm --force $(POD)
	podman ps --pod -all
	fi


.PHONY: system-clean
system-clean: ## remove podx including containers 
	echo "##[ $(@) ]##"
	read -p "Remove unused pods, containers, images, network? (Y/N): " CONFIRM
	if [[ "$$CONFIRM" == [yY] ]]; then podman system prune --all --force; fi 
	read -p "Remove Unused Volumes? (Y/N): " CONFIRM
	if [[ "$$CONFIRM" == [yY] ]]; then podman system prune --volumes --force; fi 

.PHONY: xq-up # in podx listens on port 8081/tcp 
xq-up: podx
	echo "##[ $(@) ]##" 
	if ! podman ps --all | grep -q $(XQ)
	then
	podman run --name xq --pod $(POD) \
		--mount $(MountCode) \
		--mount $(MountData) \
    --mount $(MountPriv) \
		--tz=$(shell timedatectl | grep -oP 'Time zone: \K[\w/]+') \
		--detach $(XQ)
	sleep 3
	podman ps -a --pod | grep -oP '$(XQ)(.+)$$'
	sleep 3 # add bigger delay
	podman exec xq xqerl eval 'application:ensure_all_started(xqerl).'
	else
	STATUS=$$(podman inspect -f '{{.State.Status}}' xq)
	if [[ "$$STATUS" == "created" ]] || [[ "$$STATUS" == "exited" ]]
	then podman start xq
	fi
	if [[ "$$STATUS" == "paused" ]]
	then podman unpause xq
	fi
	fi
	podman inspect -f '{{.State.Status}}' xq

.PHONY: or-up # 
or-up: xq-up
	echo "##[ $(@) ]##"
	if ! podman ps --all | grep -q $(OR)
	then
	podman run --pod $(POD) \
		--name or \
		--mount $(MountProxy) \
		--mount $(MountLetsencrypt) \
		--tz=$(shell timedatectl | grep -oP 'Time zone: \K[\w/]+') \
		--detach $(OR)
	else
	STATUS=$$(podman inspect -f '{{.State.Status}}' or)
	if [[ "$$STATUS" == "created" ]] || [[ "$$STATUS" == "exited" ]]
	then podman start or
	fi
	if [[ "$$STATUS" == "paused" ]]
	then podman unpause or
	fi
	fi
	podman inspect -f '{{.State.Status}}' xq

.PHONY: or-down
or-down: #TODO use systemd instead
	echo "##[ $(@) ]##"
	podman stop or || true
	podman rm or || true

.PHONY: xq-down
xq-down: #TODO use systemd instead
	echo "##[ $(@) ]##"
	podman stop xq || true
	podman rm xq || true

.PHONY: service-enable
service-enable:
	echo "##[ $(@) ]##"
	if ! systemctl --user is-enabled pod-podx.service
	then
	which systemctl &>/dev/null || echo 'ERROR: For linux OS only: requires init systemd'
	loginctl enable-linger $(USER) || true
	mkdir -p $(HOME)/.config/systemd/user
	rm -f *.service
	podman generate systemd --files --name $(POD) 
	cat pod-podx.service > $(HOME)/.config/systemd/user/pod-podx.service
	cat container-xq.service > $(HOME)/.config/systemd/user/container-xq.service
	cat container-or.service | 
	sed 's/After=pod-podx.service/After=pod-podx.service container-xq.service/g' |
	sed '18 i ExecStartPre=/bin/sleep 2' | tee $(HOME)/.config/systemd/user/container-or.service
	# systemctl --user daemon-reload
	systemctl --user is-enabled container-xq.service &>/dev/null || systemctl --user enable container-xq.service
	systemctl --user is-enabled container-or.service &>/dev/null || systemctl --user enable container-or.service
	systemctl --user is-enabled pod-podx.service &>/dev/null || systemctl --user enable pod-podx.service
	$(DASH)
	echo -n 'pod-podx.service enabled: '
	systemctl --user is-enabled pod-podx.service || true
	$(DASH)
	# systemctl --user restart pod-podx.service &>/dev/null
	rm -f *.service
	podman pod stop $(POD)
	systemctl --user start pod-podx.service || true
	fi
	#reboot

.PHONY: service-disable
service-disable:  ## disable podx service
	if systemctl --user is-enabled pod-podx.service
	then
	systemctl --user stop pod-podx.service || true
	systemctl --user disable container-xq.service || true
	systemctl --user disable container-or.service || true
	systemctl --user disable pod-podx.service || true
	pushd $(HOME)/.config/systemd/user/
	rm -f container-or.service container-xq.service pod-podx.service
	popd
	systemctl --user daemon-reload
	fi


# Note systemctl should only be used on the pod unit and one should not start 

.PHONY: service-start
service-start: 
	if systemctl --user is-enabled pod-podx.service &>/dev/null
	then
	systemctl --user start pod-podx.service || true
	$(DASH)
	sleep 2
	echo -n 'container xq status: '
	podman inspect -f '{{.State.Status}}' xq
	sleep 2
	echo -n 'container or status: '
	podman inspect -f '{{.State.Status}}' or
	$(DASH)
	fi

.PHONY: service-stop
service-stop:
	systemctl --user stop  pod-podx.service || true
	$(DASH)
	echo -n 'container xq status: '
	podman inspect -f '{{.State.Status}}' xq
	echo -n 'container or status: '
	podman inspect -f '{{.State.Status}}' or
	$(DASH)

.PHONY: service-status
service-status:
	echo "##[ $(@) ]##"
	systemctl --user --no-pager status pod-podx.service || true
	$(DASH)
	echo -n 'container xq status: '
	podman inspect -f '{{.State.Status}}' xq
	echo -n 'container or status: '
	podman inspect -f '{{.State.Status}}' or
	$(DASH)

.PHONY: journal
journal:
	journalctl --user --no-pager -b CONTAINER_NAME=xq


