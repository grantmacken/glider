
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
	podman ps --all --pod
	echo && $(DASH)
	$(call Dump,'http',localhost,/xqerl)
	echo && $(DASH)

.PHONY: images ## pull docker images
images: 
	echo "##[ $(@) ]##"
	podman images | grep -oP 'xqerl(.+)$(XQERL_VER)' || podman pull $(XQ)
	podman images | grep -oP 'podx-openresty(.+)$(PROXY_VER)' || podman pull $(OR)
	podman images | grep -oP 'podx-w3m(.+)$(W3M_VER)' || podman pull $(W3M)
	podman images | grep -oP 'podx-cmark(.+)$(CMARK_VER)' || podman pull $(CMARK)
	podman images | grep -oP 'podx-curl(.+)$(CURL_VER)' || podman pull $(CURL)

.PHONY: volumes
volumes: images
	echo "##[ $(@) ]##"
	@podman volume exists xqerl-code || podman volume create xqerl-code
	@podman volume exists xqerl-database || podman volume create xqerl-database
	@podman volume exists static-assets || podman volume create static-assets
	@podman volume exists proxy || podman volume create proxy
	@podman volume exists letsencrypt || podman volume create letsencrypt

.PHONY: volumes-clean
volumes-clean: volumes-remove-static-assets volumes-remove-xqerl-code volumes-remove-xqerl-database volumes-remove-proxy
	echo "##[ $(@) ]##"

.PHONY: volumes-remove-static-assets
volumes-remove-static-assets:
	echo '##[ $@ ]##'
	podman volume remove static-assets || true

.PHONY: volumes-remove-xqerl-code
volumes-remove-xqerl-code:
	echo '##[ $@ ]##'
	podman volume remove xqerl-code || true

.PHONY: volumes-remove-xqerl-database
volumes-remove-xqerl-database:
	echo '##[ $@ ]##'
	podman volume remove xqerl-database || true

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

.PHONY: clean
clean: down init-clean
	echo "##[ $(@) ]##" 
	# rm artefacts from 'build' target
	rm -fr _build
	# rm artefacts from 'init' target
	# rm -v src/data/$(DNS_DOMAIN)/*  || true
	# rm -v src/code/routes/$(DNS_DOMAIN).xqm  || true
	@systemctl --user stop pod-podx.service || true
	@systemctl --user disable container-xq.service || true
	@systemctl --user disable container-or.service || true
	@systemctl --user disable pod-podx.service || true
	pushd $(HOME)/.config/systemd/user/
	rm -f container-or.service container-xq.service pod-podx.service
	popd
	@systemctl --user daemon-reload
	podman pod rm --force $(POD)
	podman system prune --all --force
	podman system prune --volumes --force

.PHONY: xq-up # in podx listens on port 8081/tcp 
xq-up: podx
	echo "##[ $(@) ]##" 
	if ! podman ps --all | grep -q $(XQ)
	then
	podman run --name xq --pod $(POD) \
		--mount $(MountCode) --mount $(MountData) --mount $(MountAssets) \
		--tz=$(TIMEZONE) \
		--detach $(XQ)
	sleep 2
	podman ps -a --pod | grep -oP '$(XQ)(.+)$$'
	sleep 2 # add bigger delay
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
		--tz=$(TIMEZONE) \
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
	#reboot

.PHONY: service-disable
service-disable: 
	@systemctl --user stop pod-podx.service || true
	@systemctl --user disable container-xq.service || true
	@systemctl --user disable container-or.service || true
	@systemctl --user disable pod-podx.service || true
	pushd $(HOME)/.config/systemd/user/
	rm -f container-or.service container-xq.service pod-podx.service
	popd
	@systemctl --user daemon-reload


# Note systemctl should only be used on the pod unit and one should not start 

.PHONY: service-start
service-start: 
	systemctl --user start pod-podx.service
	$(DASH)
	sleep 2
	echo -n 'container xq status: '
	podman inspect -f '{{.State.Status}}' xq
	sleep 2
	echo -n 'container or status: '
	podman inspect -f '{{.State.Status}}' or
	$(DASH)

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

# PROJECT SCAFFOLD

# .PHONY: init
# init: init-$(SCAFFOLD)
#
# init-todo: src/code/routes/$(DOMAIN).xqm \
# 	src/data/$(DOMAIN)/default_layout.xq \
# 	src/assets/styles/$(SCAFFOLD)/base.css \
# 	src/assets/styles/$(SCAFFOLD)/index.css
#
# node_modules/todomvc-app-css/index.css:
# 	npm install todomvc-app-css
#
# node_modules/todomvc-common/base.css:
# 	npm install todomvc-common
#
# src/assets/styles/$(SCAFFOLD)/index.css: node_modules/todomvc-app-css/index.css
# 	[ -d $(dir $@) ] || mkdir -p $(dir $@)
# 	cp -v $< $@
#
# src/assets/styles/$(SCAFFOLD)/base.css: node_modules/todomvc-common/base.css
# 	[ -d $(dir $@) ] || mkdir -p $(dir $@)
# 	cp -v $< $@
#
# .PHONY: init-clean
# init-clean:  data-init-clean code-init-clean
#
# code-init-clean: 
# 	rm -v src/code/routes/$(DNS_DOMAIN).xqm || true
#
# data-init-clean: 
# 	echo '##[ $@ ]##'
# 	rm -v src/data/$(DNS_DOMAIN)/index.md || true
# 	rm -v src/data/$(DNS_DOMAIN)/default_layout.xq || true
#
# src/code/routes/$(DOMAIN).xqm: export routes:=$($(SCAFFOLD)_routes)
# src/code/routes/$(DOMAIN).xqm:
# 	echo '##[ $@ ]##'
# 	[ -d $(dir $@) ] || mkdir -p $(dir $@)
# 	echo "$${routes}" > $@
#
# src/data/$(DNS_DOMAIN)/index.md: export index_md:=$(index_md)
# src/data/$(DNS_DOMAIN)/index.md:
# 	[ -d $(dir $@) ] || mkdir -p $(dir $@)
# 	echo '##[ $(notdir $@) ]##'
# 	echo "$${index_md}"  > $@
# 	ls -l $@
#
# src/data/$(DOMAIN)/default_layout.xq: export layout:=$($(SCAFFOLD)_layout)
# src/data/$(DOMAIN)/default_layout.xq:
# 	[ -d $(dir $@) ] || mkdir -p $(dir $@)
# 	echo '##[  $@ ]##'
# 	echo "$${layout}"  > $@
