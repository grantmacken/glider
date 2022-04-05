###########################
### NGINX CONFIGURATION ###
###########################
# files for the proxy-conf volume
#
ConfList   := $(filter-out src/proxy/conf/reverse_proxy.conf , $(wildcard src/proxy/conf/*.conf)) src/proxy/conf/reverse_proxy.conf
BuildConfs := _build/proxy/conf/mime.types $(patsubst src/%.conf,_build/%.conf,$(ConfList))
CheckConfs := $(patsubst src/%.conf,_checks/%.conf,$(filter-out src/proxy/conf/self_signed.conf, $(ConfList)))
SiteConfs := $(patsubst src/%.conf,/opt/%.conf,$(ConfList))

.PHONY: confs confs-check confs-deploy
confs: confs-check confs-deploy
confs-check: $(CheckConfs)
confs-deploy: _deploy/proxy-conf.tar #  after confs-check

.PHONY: watch-confs
watch-confs:
	@while true; do \
        clear && $(MAKE) --silent confs; \
        inotifywait -qre close_write . || true; \
    done

_deploy/proxy-conf.tar: $(BuildConfs) $(CheckConfs)
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	echo '##[  $(notdir $@) ]##'
	podman volume export  $(basename $(notdir $@)) > $@
	chown -R $(USER) $(dir $@)
	

.PHONY: confs-clean
confs-clean:
	@echo '## $(@) ##'
	@rm -fv $(BuildConfs) deploy/proxy-conf.tar
	@rm -fv deploy/proxy-conf.tar
	@#podman run --rm  --mount $(MountProxyConf) --entrypoint '["sh", "-c"]' $(OR) 'rm -fv $(SiteConfs)' || true
	@#podman run --rm  --mount $(MountProxyConf) --entrypoint '["sh", "-c"]' $(OR) 'ls /opt/proxy/confs ' || true

.PHONY: confs-list
confs-list:
	@echo '## $(@) ##'
	@podman run  --rm --mount $(MountProxyConf) --entrypoint '["sh", "-c"]' $(OR) \
		'ls -al /opt/proxy/conf' || true
	@$(DASH)
	@echo ' - check the self_signed.conf'
	@podman run --rm --mount $(MountProxyConf) --entrypoint '["sh", "-c"]' $(OR) \
		'cat /opt/proxy/conf/self_signed.conf' || true
	@$(DASH)
	@podman run --rm --mount $(MountCerts) --entrypoint  '["sh", "-c"]' $(OR) \
		'ls -al /opt/proxy/certs' || true

_build/proxy/conf/%.conf: src/proxy/conf/%.conf
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo '##[ $(notdir $@) ]##'
	@cat $< | podman run --interactive --rm  --mount $(MountProxyConf) --entrypoint '["sh", "-c"]' $(OR) \
		 'cat - > /opt/proxy/conf/$(notdir $<) && ls /opt/proxy/conf/$(notdir $<)' > $@
	@if podman ps -a | grep -q $(OR)
	then
	  if podman exec or ls /opt/proxy/conf/reverse_proxy.conf &>/dev/null
	  then
		echo " - test and reload reverse_proxy.conf "
	  podman exec or openresty -p /opt/proxy/ -c /opt/proxy/conf/reverse_proxy.conf -t
	  podman exec or openresty -p /opt/proxy/ -c /opt/proxy/conf/reverse_proxy.conf -s reload
		fi
	fi

_checks/proxy/conf/%.conf: _build/proxy/conf/%.conf
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo '##[ $@ ]##'
	@podman run --interactive --rm  \
		--mount $(MountProxyConf) \
		--mount $(MountCerts) \
		--entrypoint '["sh", "-c"]' $(OR) \
		'openresty -p /opt/proxy/ -c /opt/proxy/conf/reverse_proxy.conf -t'

_build/proxy/conf/mime.types: src/proxy/conf/mime.types
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo '##[ $(notdir $@) ]##'
	@cat $< | podman run  --interactive --rm  --mount $(MountProxyConf)  --entrypoint '["sh", "-c"]' $(OR) \
		 'cat - > /opt/proxy/conf/$(notdir $<) && ls -l /opt/proxy/conf/$(notdir $<)' > $@

