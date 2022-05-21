.PHONY: up
up: or-up init
	$(DASH)
	# access xqerl in the pods internal network
	#podman run --rm --name req1 --pod $(POD) $(W3M) -dump http://localhost:8081/xqerl
	podman ps --all --pod
	echo && $(DASH)
	if grep -oP '$(DNS_DOMAIN)' /etc/hosts &>/dev/null
	then
	$(call Dump,'http',$(DNS_DOMAIN),$(ROUTE))
	echo && $(DASH)
	$(call Dump,'http',localhost,$(ROUTE))
	else
	$(call Dump,'http',localhost,$(ROUTE))
	fi
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
	@podman volume exists proxy-conf || podman volume create proxy-conf
	@podman volume exists letsencrypt || podman volume create letsencrypt

.PHONY: volumes-clean
volumes-clean: volumes-remove-static-assets volumes-remove-xqerl-code
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


.PHONY: volumes-import
volumes-import:
	echo "##[ $(@) ]##"
	if [ -f _deploy/proxy-conf.tar ] ; then podman volume import proxy-conf _deploy/proxy-conf.tar ;fi
	if [ -f _deploy/static-assets.tar ] ; then podman volume import static-assets _deploy/static-assets.tar ;fi

.PHONY: podx
podx: volumes # --publish 80:80 --publish 443:443
	echo "##[ $(@) ##]"
	podman pod exists $(POD) || \
		podman pod create \
		--publish $(POD_HTTP_PORT):80 \
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
clean: down init-clean
	echo "##[ $(@) ]##" 
	# rm artefacts from 'build' target
	rm -fr _build
	# rm artefacts from 'init' target
	rm -v src/data/$(DNS_DOMAIN)/*  || true
	rm -v src/code/restXQ/$(DNS_DOMAIN).xqm  || true
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
		--tz=$(TIMEZONE) \
		--detach $(XQ)
	sleep 2
	podman ps -a --pod | grep -oP '$(XQ)(.+)$$'
	sleep 2 # add bigger delay
	podman exec xq xqerl eval 'application:ensure_all_started(xqerl).'
	fi

.PHONY: or-up # 
or-up: xq-up
	echo "##[ $(@) ]##"
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
	podman stop or || true
	podman rm or || true

.PHONY: xq-down
xq-down: #TODO use systemd instead
	echo "##[ $(@) ]##"
	podman stop xq || true
	podman rm xq || true

