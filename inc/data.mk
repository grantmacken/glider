###########################
### The data directory holds files 
## that will be stored in the xqerl db 
## the stored XDM item will be detirmined by the initial file extension 
# src/data/{domain}/{collection}/{filename}.{extension}
###########################
mdList  :=  $(shell find src/data -type f  -name '*.md')
jsonList  := $(shell find src/data -type f  -name '*.json')
xmlList  :=  $(shell find src/data -type f  -name '*.xml')
xqList  :=  $(shell find src/data -type f  -name '*.xq')

mdBuild := $(patsubst src/%.md,_build/%.md.headers,$(mdList))
jsonBuild := $(patsubst src/%.json,_build/%.json.headers,$(jsonList))
xmlBuild := $(patsubst src/%.xml,_build/%.xml.headers,$(xmlList))
xqBuild := $(patsubst src/%.xq,_build/%.xq.stored,$(xqList))

.PHONY: data data-deploy
data: data-deploy ## from src store XDM data items in db
data-deploy: _deploy/xqerl-database.tar

.PHONY: data-clean
data-clean: ## clean "data" build artefacts
	echo '##[ $@ ]##'
	rm -f $(mdBuild) $(xmlBuild) $(xqBuild) _deploy/xqerl-database.tar

.PHONY: data-list
data-list:
	podman run  --rm --pod $(POD) $(CURL) \
		--silent --show-error --connect-timeout 1 --max-time 2 \
		http://example.com/db
	# echo '##[ $@ ]##'
	#podman exec xq xqerl eval "binary_to_list(xqerl:run(\"('http://example.com' => uri-collection()) => string-join(' ')\" ))."

_deploy/xqerl-database.tar: $(mdBuild) $(xmlBuild) $(xqBuild)	
	[ -d $(dir $@) ] || mkdir -p $(dir $@)
	# echo '##[  $(notdir $@) ]##'
	podman volume export  $(basename $(notdir $@)) > $@

_build/data/%.md.headers: src/data/%.md
	echo '##[ $(basename $(notdir $<)) ]##'
	if podman run  --rm --pod $(POD) $(CURL) \
		--silent --show-error --connect-timeout 1 --max-time 2 \
		--write-out '%{http_code}' --output /dev/null \
		-I --header "Accept: application/xml" \
		http://localhost:8081/db/$(*) | grep -q '200'
	then
	echo "xqerl database: update cmark XML from markdown"
	cat $< |
	podman run --rm --interactive $(CMARK) --to xml --validate-utf8 --safe --smart 2>/dev/null |
	sed -e '1,2d' 2>/dev/null |
	podman run --rm  --pod $(POD) --interactive $(CURL) \
		--silent --show-error --connect-timeout 1 --max-time 2 \
		--write-out '%{http_code}' --output /dev/null \
    -X PUT \
		--header "Content-Type: application/xml" \
		--data-binary @- \
		http://localhost:8081/db/$(*) | grep -q '204'
	touch $@ 
	else
	echo "xqerl database: cmark XML from markdown"
	echo 'collection: http://$(dir $(*))'
	echo 'resource: $(basename $(notdir $<))'
	cat $< |
	podman run --rm --interactive $(CMARK) --to xml --validate-utf8 --safe --smart 2>/dev/null |
	sed -e '1,2d' 2>/dev/null |
	podman run --rm  --pod $(POD) --interactive $(CURL) \
		--silent --show-error --connect-timeout 1 --max-time 2 \
		--header "Content-Type: application/xml" \
		--header "Slug: $(basename $(notdir $<))" \
		--data-binary @- \
		--output /dev/null \
		--dump-header - \
		http://localhost:8081/db/$(dir $(*)) | tee $@
	grep -q '201' $@
	fi
	# sleep 1
	# if [ -e tiny-lr.pid ]; then
	# curl -s --ipv4  http://localhost:35729/changed?files=$*
	# fi
	$(DASH)

_build/data/%.xml.headers: src/data/%.xml
	echo '##[ $(basename $(notdir $<)) ]##'
	mkdir -p $(dir $@)
	$(DASH)
	if grep -qoP 'HTTP/1.1 201 Created' $@
	then
	echo " update:  $(shell grep -oP 'location: \K([^\s]+)' $@)"
	bin/db-update $< | grep -qoP '^HTTP/1.1 204 No Content'
	touch $@
	curl --silent --show-error --connect-timeout 1 --max-time 2 \
    --header "Accept: application/xml" \
		$(shell grep -oP 'location: \K([^\s]+)' $@)
	echo 'updated: $(shell grep -oP 'location: \K(.+)' $@)'
	else
	bin/db-create $< | tee $@
	grep -qoP 'HTTP/1.1 201 Created' $@
	fi

_build/data/%.xq.stored: src/data/%.xq
	echo '##[ $(basename $(notdir $<)) ]##'
	echo " xqerl database: create/update xquery function"
	mkdir -p $(dir $@)
	bin/compile $< | grep -q 'compiled ok!'
	bin/db-store $< &>/dev/null
	mv src/store.xq  $@
	# echo && $(DASH)
