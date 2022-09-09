###########################
### NGINX CONFIGURATION ###
###########################
# files for the proxy volume
#
# ConfList   := $(filter-out src/proxy/conf/proxy.conf , $(wildcard src/proxy/conf/*.conf)) src/proxy/conf/proxy.conf
ConfList   := $(wildcard src/proxy/conf/*.conf)
BuildConfs := $(patsubst src/%.conf,_build/%.conf,$(ConfList))

.PHONY: proxy 
proxy: _deploy/proxy.tar ## proxy: check and store src files in container 'or' filesystem

confs-deploy: #  
	@echo '## $@ ##'
	cat _deploy/proxy.tar |
	$(Gcmd) ' cat - | podman volume import proxy - '

.PHONY: confs-clean
confs-clean:
	echo '##[ $(@) ]##'
	@rm -f $(BuildConfs) _deploy/proxy.tar || true

_deploy/proxy.tar: $(BuildConfs)
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	echo '##[  $(notdir $@) ]##'
	podman volume export proxy > $@
	podman exec or openresty -p /opt/proxy/ -c /opt/proxy/conf/proxy.conf -s reload

.PHONY: confs-list
confs-list:
	@echo '## $(@) ##'
	@podman run  --rm --mount $(MountProxy) --entrypoint '["sh", "-c"]' $(OR) \
		'ls -al /opt/proxy/conf' || true
	@$(DASH)

_build/proxy/conf/%.conf: src/proxy/conf/%.conf
	[ -d $(dir $@) ] || mkdir -p $(dir $@)
	echo '##[ $(notdir $@) ]##'
	cat $< | 
	podman run --interactive --rm  --mount $(MountProxy)  --mount $(MountLetsencrypt) --entrypoint '["sh", "-c"]' $(OR) \
		 'cat - > /opt/proxy/conf/$(notdir $<) && openresty -p /opt/proxy/ -c /opt/proxy/conf/proxy.conf -t' | 
	tee $@


src/proxy/certs/example.com.pem:
	[ -d $(dir $@) ] || mkdir -p $(dir $@)
	echo '## $(notdir $@) ##'
	if podman ps -a | grep -q $(OR)
	then
	openssl s_client -showcerts -connect example.com:443 </dev/null | sed -n -e '/-.BEGIN/,/-.END/ p' > $@
	fi




