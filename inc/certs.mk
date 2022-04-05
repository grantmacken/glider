##############
# self signed certs for example.com
##############

certs: certs-volume certs-conf
certs-volume: src/proxy/certs/example.com.crt src/proxy/certs/dhparam.pem
certs-conf:  src/proxy/conf/self_signed.conf
certs-pem: src/proxy/certs/example.com.pem # or must be running locally
certs-deploy: _deploy/certs.tar #  after certs and certs-pem

certs-list: 
	podman run --rm  --mount $(MountCerts) --entrypoint '["sh", "-c"]' $(OR) \
		'ls certs'
	#podman run --rm  --mount $(MountCerts) --entrypoint '["sh", "-c"]' $(OR) 'ls -R /opt'

_deploy/certs.tar: src/proxy/certs/example.com.crt src/proxy/certs/dhparam.pem src/proxy/certs/example.com.pem
	@echo '## $(@) ##'
	podman volume export  $(basename $(notdir $@)) > $@
	@podman volume export certs > $@


.PHONY: certs-deploy-check
certs-deploy-check:
	@#$(Gcmd) 'ps -eZ | grep container_t'
	@$(Gcmd) 'sudo podman volume inspect certs' | jq '.'
	@$(Gcmd) 'sudo ls -ldZ /var/lib/containers/storage/volumes/certs/_data'
	@$(Gcmd) 'sudo ls -lRZ /var/lib/containers/storage/volumes/certs/_data'

.PHONY: certs-clean
certs-clean: 
	@rm -fv deploy/certs-volume.tar
	@rm -fv src/proxy/certs/* src/proxy/conf/self_signed.conf
	@#podman run --rm  --mount $(MountCerts) --entrypoint '["sh", "-c"]' $(OR) 'rm -fRv /opt/proxy/certs/*'
	@#podman run --rm  --mount $(MountProxyConf) --entrypoint '["sh", "-c"]' $(OR) 'rm -fv /opt/proxy/conf/self_signed.conf'
	@#podman run --rm --workdir /opt/proxy $(OR) ls certs
	@#podman run --rm --workdir /opt/proxy $(OR) ls conf

src/proxy/certs/example.com.key:
	[ -d $(dir $@) ] || mkdir -p $(dir $@)
	echo '##[ $(notdir $@) ]##'
	 @openssl genrsa -out $@ 2048
	cat $@ | \
		podman run --rm --interactive --mount $(MountCerts) --entrypoint '["sh", "-c"]' $(OR) \
		'cat - > /opt/proxy/certs/$(notdir $@)'

src/proxy/certs/example.com.csr: src/proxy/certs/example.com.key
	[ -d $(dir $@) ] || mkdir -p $(dir $@)
	echo '##[ $(notdir $@) ]##'
	openssl req -new -key $<  \
		-nodes \
		-subj '/C=NZ/CN=example.com' \
		-out $@ -sha512

src/proxy/certs/example.com.crt: src/proxy/certs/example.com.csr
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo '##[ $(notdir $@) ]##'
	@openssl x509 -req -days 365 -in $< -signkey src/proxy/certs/example.com.key -out $@ -sha512
	@cat $@ | \
		podman run --rm --interactive  --mount $(MountCerts) --entrypoint '["sh", "-c"]' $(OR) \
		'cat - > /opt/proxy/certs/$(notdir $@)'

src/proxy/conf/self_signed.conf:
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo '## $(notdir $@) ##'
	@echo "ssl_certificate /opt/proxy/certs/example.com.crt;" > $@
	@echo "ssl_certificate_key /opt/proxy/certs/example.com.key;" >> $@
	@echo "ssl_dhparam /opt/proxy/certs/dhparam.pem;" >> $@
	@cat $@ | \
		podman run --rm  --interactive --mount $(MountProxyConf) --entrypoint '["sh", "-c"]' $(OR) \
		'cat - > /opt/proxy/conf/$(notdir $@)'

src/proxy/certs/dhparam.pem:
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo '##[ $(notdir $@) ]##'
	@openssl dhparam -out $@ 2048
	@cat $@ | \
		podman run --rm --interactive --mount $(MountCerts) --entrypoint '["sh", "-c"]' $(OR) \
		'cat - > /opt/proxy/certs/$(notdir $@)'

src/proxy/certs/example.com.pem:
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo '## $(notdir $@) ##'
	@if podman ps -a | grep -q $(OR)
	then
	@openssl s_client -showcerts -connect example.com:443 </dev/null \
		| sed -n -e '/-.BEGIN/,/-.END/ p' > $@
	@cat $@ | \
		podman run --rm --interactive  --mount $(MountCerts) --entrypoint '["sh", "-c"]' $(OR) \
		'cat - > /opt/proxy/certs/$(notdir $@)'
	fi

