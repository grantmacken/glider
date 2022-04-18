###########################
### NGINX CONFIGURATION ###
###########################
# files for the proxy-conf volume
#
ConfList   := $(filter-out src/proxy/conf/proxy.conf , $(wildcard src/proxy/conf/*.conf)) src/proxy/conf/proxy.conf
BuildConfs := _build/proxy/conf/mime.types $(patsubst src/%.conf,_build/%.conf,$(ConfList))
# CheckConfs := $(patsubst src/%.conf,_checks/%.conf, $(ConfList))
SiteConfs := $(patsubst src/%.conf,/opt/%.conf,$(ConfList))

.PHONY: confs 
confs: confs-deploy
# confs-check: $(CheckConfs)
confs-deploy: _deploy/proxy-conf.tar #  after confs-check

.PHONY: confs-clean
confs-clean:
	echo '##[ $(@) ]##'
	@rm -f $(BuildConfs) _deploy/proxy-conf.tar || true

_deploy/proxy-conf.tar: $(BuildConfs)
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	echo '##[  $(notdir $@) ]##'
	podman volume export proxy-conf > $@
	podman exec or openresty -p /opt/proxy/ -c /opt/proxy/conf/proxy.conf -s reload

.PHONY: confs-list
confs-list:
	@echo '## $(@) ##'
	@podman run  --rm --mount $(MountProxyConf) --entrypoint '["sh", "-c"]' $(OR) \
		'ls -al /opt/proxy/conf' || true
	@$(DASH)

_build/proxy/conf/%.conf: src/proxy/conf/%.conf
	[ -d $(dir $@) ] || mkdir -p $(dir $@)
	echo '##[ $(notdir $@) ]##'
	cat $< | 
	podman run --interactive --rm  --mount $(MountProxyConf)  --mount $(MountLetsencrypt) --entrypoint '["sh", "-c"]' $(OR) \
		 'cat - > /opt/proxy/conf/$(notdir $<) && openresty -p /opt/proxy/ -c /opt/proxy/conf/proxy.conf -t' | 
	tee $@


_build/proxy/conf/mime.types: src/proxy/conf/mime.types
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo '##[ $(notdir $@) ]##'
	@cat $< | podman run  --interactive --rm  --mount $(MountProxyConf)  --entrypoint '["sh", "-c"]' $(OR) \
		 'cat - > /opt/proxy/conf/$(notdir $<) && ls -l /opt/proxy/conf/$(notdir $<)' > $@

