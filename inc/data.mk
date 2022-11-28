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

_deploy/xqerl-database.tar: $(mdBuild) $(jsonBuild) $(xmlBuild) $(xqBuild) ## xqerl-db: store XDM data items into db
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

.PHONY: db-list
db-list: ## xqerl-db: list all database collections and items
	$(ESCRIPT) priv/bin/list-db-uri

.PHONY: db-delete
db-delete: 
	for ITEM in $(shell $(ESCRIPT) priv/bin/list-db-uri)
	do 
	podman exec xq xqerl eval "xqerl:run(\"
	try {'$$ITEM' => db:delete() } catch * {false()}
	\")."
	sleep 1
	done


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
	echo ' - db put $*'
	cat $< | podman run --rm --interactive --mount  $(MountPriv) --entrypoint "sh" $(XQ) \
		-c 'cat - > ./priv/modules/$(notdir $*)'
	$(ESCRIPT) priv/bin/compile ./priv/modules/$(notdir $*) | grep -q :Info:
	echo ' => as XDM item compile check: OK!'
	cat <<-'EOF' | podman run --rm --interactive --mount  $(MountPriv) --entrypoint "sh" $(XQ) -c 'cat - > ./priv/modules/$(notdir $*)'
	try {
	let $$item := $(shell cat $<)
	return 
	if ( $$item instance of item() )
	then ( true(),db:put( $$item, 'http://$*' ))
	else false()
	} catch * {false()}
	EOF
	$(ESCRIPT) priv/bin/compile ./priv/modules/$(notdir $*) | grep -q :Info:
	echo ' => put XDM item compile check: OK!'
	echo -n ' => put success: '
	podman exec xq xqerl eval "xqerl:run(xqerl:compile(\"./priv/modules/$(notdir $*)\"))."
	podman run --rm --interactive --mount  $(MountPriv) --entrypoint "sh" $(XQ) -c 'cat ./priv/modules/$(notdir $*)' > $@
	#cp $< $@

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
	jq empty $< ## fail if can't parse
	if $(CRL) -I --header "Accept: application/json" $(DB)/$* | grep -q '200'
	then
	echo ' - db update: $*'
	cat $< |
	jq '.' | # pretty
	$(CRL) -X PUT --header "Content-Type: application/json" --data-binary @- $(DB)/$* |
	grep -q '204'
	else
	echo ' - db create: $*'
	cat $< |
	jq '.' | # pretty
	$(CRL) --header "Content-Type: application/json" --header "Slug: $(notdir $*)" --data-binary @- $(DB)/$(dir $*) |
	grep -q '201'
	fi
	sleep 1
	podman run --rm --pod podx $(CURL) --silent --header "Accept: application/json"  $(DB)/$* > $@

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
	if $(CRL) -I --header "accept: application/xml" $(DB)/$* | grep -q '200'
	then
	echo ' - db update: $*'
	cat $< |
	podman run --rm --interactive $(CMARK) \
		--to xml \
		--validate-utf8 \
		--safe \
		--smart 2>/dev/null |
	xmllint --dropdtd - |
	$(CRL) -X PUT --header "Content-Type: application/xml" --data-binary @- $(DB)/$* |
	grep -q '204'
	else
	echo ' - db create: $*'
	cat $< |
	podman run --rm --interactive $(CMARK) \
		--to xml \
		--validate-utf8 \
		--safe \
		--smart 2>/dev/null |
	xmllint --dropdtd - |
	$(CRL) --header "Content-Type: application/xml" --header "Slug: $(notdir $*)" --data-binary @- $(DB)/$(dir $*) |
	grep -q '201'
	fi
	sleep 1
	podman run --rm --pod podx $(CURL) --silent --header "Accept: application/xml"  $(DB)/$* > $@

#########
## XML ##
#########

.PHONY: data-xml
data-xml: $(xmlBuild)

.PHONY: data-xml-clean
data-xml-clean: 
	rm -vf $(xmlBuild)

_build/data/%.xml: src/data/%.xml
	# echo '##[  $< ]##'
	[ -d $(dir $@) ] || mkdir -p $(dir $@)
	if $(CRL) -I --header "accept: application/xml" $(DB)/$* | grep -q '200'
	then
	echo ' - db update: $*'
	cat $< |
	xmllint --dropdtd - |
	$(CRL) -X PUT --header "Content-Type: application/xml" --data-binary @- $(DB)/$* |
	grep -q '204'
	else
	echo '- db create: $*'
	cat $< |
	xmllint --dropdtd - |
	$(CRL) --header "Content-Type: application/xml" --header "Slug: $(notdir $*)" --data-binary @- $(DB)/$(dir $*) |
	grep -q '201'
	fi
	sleep 1
	podman run --rm --pod podx $(CURL) --silent --header "Accept: application/xml"  $(DB)/$* > $@
	
	
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

