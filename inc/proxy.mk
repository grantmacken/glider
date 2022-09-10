###########################
### NGINX CONFIGURATION ###
###########################
# files for the proxy volume
#
# ConfList   := $(filter-out src/proxy/conf/proxy.conf , $(wildcard src/proxy/conf/*.conf)) src/proxy/conf/proxy.conf
BuildConfs := $(patsubst src/%.conf,_build/%.conf,$(wildcard src/proxy/conf/*.conf))
BuildSelfSigned := $(patsubst src/%.pem,_build/%.pem, $(wildcard src/proxy/certs/*.pem))

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

_deploy/proxy.tar: $(BuildConfs) $(BuildSelfSigned)
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
	tee $

.PHONY: mkcert
mkcert:
	mkdir -p src/proxy/conf/
	mkcert -install &>/dev/null
	mkcert \
		-key-file src/proxy/certs/$(DOMAIN).key.pem \
		-cert-file src/proxy/certs/$(DOMAIN).pem $(DOMAIN)
	touch src/proxy/conf/self_signed.conf
	echo 'ssl_certificate_key /opt/proxy/certs/$(DOMAIN).key.pem' > src/proxy/conf/self_signed.conf
	echo 'ssl_certificate /opt/proxy/certs/$(DOMAIN).pem' >> src/proxy/conf/self_signed.conf




_build/proxy/certs/%: src/proxy/certs/%
	[ -d $(dir $@) ] || mkdir -p $(dir $@)
	echo '## $(notdir $@) ##'
	if podman ps -a | grep -q $(OR)
	then
	cat $< | 
	podman run --interactive --rm  --mount $(MountProxy) --entrypoint '["sh", "-c"]' $(OR) \
		 'cat - > /opt/proxy/certs/$(notdir $<) && ls /opt/proxy/certs/$(notdir $<)' | tee $@
	fi




