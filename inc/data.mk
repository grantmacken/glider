###########################
## The data directory holds files 
## that will be stored in the xqerl db 
## the stored XDM item will be detirmined by the initial file extension 
# src/data/{domain}/{collection}/{filename}.{extension}
###########################
mdList  := $(call rwildcard,src/data,*.md)
jsonList  := $(call rwildcard,src/data,*.json)
xmlList  := $(call rwildcard,src/data,*.xml)
xqList  :=  $(call rwildcard,src/data,*.xq)

mdBuild := $(patsubst src/%.md,_build/%.xml,$(mdList))
jsonBuild := $(patsubst src/%.json,_build/%.json,$(jsonList))
xmlBuild := $(patsubst src/%,_build/%,$(xmlList))
xqBuild := $(patsubst src/%,_build/%,$(xqList))

.PHONY: data
data: _deploy/xqerl-database.tar

_deploy/xqerl-database.tar: $(mdBuild) $(xmlBuild) $(xqBuild) ## xqerl-db: store XDM data items into db
	[ -d $(dir $@) ] || mkdir -p $(dir $@)
	podman pause xq &>/dev/null
	podman volume export xqerl-database > $@
	podman unpause xq &>/dev/null

.PHONY: data-deploy
data-deploy: $(patsubst _build/data/%,_deploy/data/%,$(xqBuild) $(xqBuild)) ## xqerl-db: store xdm data items into db on remote xq container
.PHONY: data-list-remote
data-list-remote: ## xqerl-db: list db items on remote xq container
	$(Gcmd) '$(call Dump,$(SCHEME),$(DOMAIN),/db/)'

.PHONY: data-volume-export
data-volume-export:
	podman pause xq
	podman volume export xqerl-database > _deploy/xqerl-database.tar
	podman unpause xq

.PHONY: data-volume-import
data-volume-import: down
	echo "##[ $(@) ]##"
	podman volume import xqerl-database  _deploy/xqerl-database.tar

.PHONY: data-reset
data-reset: volumes-remove-xqerl-database volumes data-clean
	echo '##[ $@ ]##'

.PHONY: data-reset-service
data-reset-service: service-stop volumes-remove-xqerl-database volumes data-clean service-start
	echo '##[ $@ ]##'
	
.PHONY: data-clean
data-clean:
	echo '##[ $@ ]##'
	rm -fv $(jsonBuild) $(mdBuild) $(xmlBuild) $(xqBuild)  _deploy/xqerl-database.tar

.PHONY: data-list
data-list: ## xqerl-db: list all database collections and items
	$(ESCRIPT) priv/bin/list-db-uri

.PHONY: data-in-pod-list
data-in-pod-list:
	$(DASH)
	podman run --rm --pod $(POD) $(CURL) \
		--silent --show-error --connect-timeout 1 --max-time 2 \
		http://localhost:8081/db/$(DOMAIN)
	echo

###########################
## XQ  XDM items as data ##
###########################

.PHONY: data-xq
data-xq: $(xqBuild)

.PHONY: data-xq-clean
data-xq-clean: 
	rm -vf $(xqBuild)

_build/data/%.xq: src/data/%.xq
	[ -d $(dir $@) ] || mkdir -p $(dir $@)
	echo '##[ $< ]##'
	# first do a compile check
	cat $< | podman run --rm --interactive --mount  $(MountPriv) --entrypoint "sh" $(XQ) \
		-c 'cat - > ./priv/modules/$(notdir $*)'
	$(ESCRIPT) priv/bin/compile ./priv/modules/$(notdir $*) | grep -q :Info:
	# podman run --rm --mount  $(MountPriv) --entrypoint "sh" $(XQ) -c 'rm -f ./priv/modules/$(notdir $*)'
	bin/db-create $< | grep -q true
	cp $< $@


##########
## JSON ##
##########

.PHONY: data-json
data-json: $(jsonBuild)

.PHONY: data-json-clean
data-json-clean: 
	rm -vf $(jsonBuild)

_build/data/%.json: src/data/%.json
	[ -d $(dir $@) ] || mkdir -p $(dir $@)
	echo '##[ $(*) ]##'
	if bin/db-available $<
	then
	 bin/db-update $< | grep -q '204'
	else
	 bin/db-create $<  | grep -q '201'
	fi
	sleep 1
	bin/db-retrieve $< > $@

################
## COMMONMARK ##
##  MARKDOWN  ##
################

.PHONY: data-md
data-md: $(mdBuild)

.PHONY: data-md-clean
data-md-clean: 
	rm -vf $(mdBuild)

_build/data/%.xml: src/data/%.md
	[ -d $(dir $@) ] || mkdir -p $(dir $@)
	if bin/db-available $<
	then
	echo 'db update: $* '
	bin/db-update $< | grep -q '204'
	else
	echo 'db create: $* '
	bin/db-create $< | grep -q '201'
	fi
	bin/db-retrieve $< > $@

#########
## XML ##
#########

.PHONY: data-xml
data-xml: $(xmlBuild)

.PHONY: data-xml-clean
data-xml-clean: 
	rm -vf $(xmlBuild)

_build/data/%.xml: src/data/%.xml
	[ -d $(dir $@) ] || mkdir -p $(dir $@)
	echo '##[ $(<) ]##'
	if bin/db-available $<
	then
	bin/db-update $< | grep -q '204'
	else
	bin/db-create $< | grep -q '201'
	fi
	bin/db-retrieve $< > $@

_deploy/data/%.xml: _build/data/%.xml
	[ -d $(dir $@) ] || mkdir -p $(dir $@)
	echo '##[ $* ]##'
	if $(Gcmd) 'podman run  --rm --pod $(POD) $(CURL) \
		--silent --show-error --connect-timeout 1 --max-time 2 \
		--write-out '%{http_code}' --output /dev/null \
		-I --header "Accept: application/xml" \
		http://localhost:8081/db/$(*) '  | grep -q '200'
	then 
	echo "remote xqerl database: update cmark XML from markdown source"
	echo ' - db item [ http://$(*) ]'
	cat $< | $(Gcmd) 'cat - | podman run --rm  --pod $(POD) --interactive $(CURL) \
		--silent --show-error --connect-timeout 1 --max-time 2 \
		--write-out '%{http_code}' --output /dev/null \
    -X PUT \
		--header "Content-Type: application/xml" \
		--data-binary @- \
		http://localhost:8081/db/$(*)' | grep -q 204
	else
	echo ' - item not found'
	echo "xqerl database: cmark XML from markdown"
	echo 'collection: http://$(dir $(*))'
	echo 'resource: $(basename $(notdir $<))'
	cat $< | $(Gcmd) 'cat - | podman run --rm  --pod $(POD) --interactive $(CURL) \
		--silent --show-error --connect-timeout 1 --max-time 2 \
		--header "Content-Type: application/xml" \
		--header "Slug: $(basename $(notdir $<))" \
		--data-binary @- \
		--output /dev/null \
		--dump-header - \
		http://localhost:8081/db/$(dir $(*))' | grep -q 201
	fi
	$(Gcmd) 'podman run --rm  --pod $(POD) $(CURL) \
		--silent --show-error --connect-timeout 1 --max-time 2 \
		--header "Accept: application/xml" \
		http://localhost:8081/db/$(*)' > $@






_deploy/data/%.xq: _build/data/%.xq
	[ -d $(dir $@) ] || mkdir -p $(dir $@)
	echo '##[ $(notdir $<) ]##'
	echo " - db XDM item: function"
	echo ' - collection:  http://$(dir $(*))'
	echo ' - resource:    $(basename $(notdir $<))'
	cat $< | $(Gcmd) "cat - > $(notdir $<) \
		&& podman cp $(notdir $<) xq:/home \
		&& podman exec xq xqerl eval 'xqerl:run(xqerl:compile(\"/home/$(notdir $<)\")).'"
	#$(Gcmd) 'ls -l $(notdir $<)'

