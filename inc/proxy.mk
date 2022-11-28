###########################
### NGINX CONFIGURATION ###
###########################
# files for the proxy volume
ConfList   := $(filter-out src/proxy/conf/proxy.conf,$(wildcard src/proxy/conf/*.conf)) src/proxy/conf/proxy.conf
BuildConfs := $(patsubst src/%,_build/%,$(ConfList))
BuildCerts := $(patsubst src/%.pem,_build/%.pem, $(wildcard src/proxy/certs/*.pem))

.PHONY: proxy
proxy: _deploy/proxy.tar ## proxy: check and store src files in container 'or' filesystem

.PHONY: proxy-clean
proxy-clean: # clean out proxy build files
	echo '##[ $(@) ]##'
	rm -fv $(BuildCerts) $(BuildConfs) _deploy/proxy.tar || true

.PHONY: proxy-reset
proxy-reset: # clean out proxy source file
	echo '##[ $(@) ]##'
	mkdir -p .backup/src/proxy
	tar -zcvf .backup/src/proxy/$$(date --iso).tar.gz src/proxy
	rm -fv src/proxy/conf/*
	podman cp or:/opt/proxy/conf src/proxy/
	rm -fv src/proxy/certs/*
	podman cp or:/opt/proxy/certs src/proxy/

.PHONY: proxy-get-confs
proxy-get-confs:
	echo '##[ $(@) ]##'
	podman cp or:/opt/proxy/conf src/proxy/

_deploy/proxy.tar: $(BuildCerts) $(BuildConfs) 
	[ -d $(dir $@) ] || mkdir -p $(dir $@)
	echo '##[  $(notdir $@) ]##'
	podman volume export proxy > $@
	podman exec or openresty -p /opt/proxy/ -c /opt/proxy/conf/proxy.conf -s reload

confs-deploy: #  
	echo '## $@ ##'
	cat _deploy/proxy.tar |
	$(Gcmd) ' cat - | podman volume import proxy - '

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

.PHONY: proxy-mkcert
proxy-mkcert: ## use mkcert to certificate authority and create certs for DOMAIN specified in .env file
	echo '##[ $(notdir $@) ]##'
	mkdir -p src/proxy/conf/
	mkcert -install &>/dev/null
	mkcert \
		-key-file src/proxy/certs/$(DOMAIN).key.pem \
		-cert-file src/proxy/certs/$(DOMAIN).pem $(DOMAIN)
	touch src/proxy/conf/certs.conf
	echo 'ssl_certificate_key /opt/proxy/certs/$(DOMAIN).key.pem;' > src/proxy/conf/certs.conf
	echo 'ssl_certificate /opt/proxy/certs/$(DOMAIN).pem;' >> src/proxy/conf/certs.conf
	# cat src/proxy/conf/certs.conf


.PHONY: proxy-mkcert-clean
proxy-mkcert-clean:
	echo '##[ $@ ]##'
	rm -f src/proxy/certs/$(DOMAIN).key.pem 
	rm -f src/proxy/certs/$(DOMAIN).pem $(DOMAIN) 
	rm -f src/proxy/conf/certs.conf


_build/proxy/certs/%: src/proxy/certs/%
	[ -d $(dir $@) ] || mkdir -p $(dir $@)
	echo '## $(notdir $@) ##'
	if podman ps -a | grep -q $(OR)
	then
	cat $< | 
	podman run --interactive --rm  --mount $(MountProxy) --entrypoint '["sh", "-c"]' $(OR) \
		 'cat - > /opt/proxy/certs/$(notdir $<) && ls /opt/proxy/certs/$(notdir $<)' | tee $@
	fi
