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

data: $(mdBuild) $(xmlBuild) $(xqBuild) ## from src store XDM data items in db 
# 
# $(xmlBuild)  $(xqBuild)

# .PHONY: data-clean
# data-clean: ## remove data build artifacts
# 	@echo '## $(@) ##'
# 	@rm -v $(xqBuild) $(mdBuild) $(xmlBuild) || true

_build/data/%.md.headers: src/data/%.md
	@echo '## $(notdir $<) ##'
	mkdir -p $(dir $@)
	$(DASH)
	## bin/db-create $< | tee $@
	if bin/db-available $< &>/dev/null
	then
	echo " update cmark XML from markdown"
	bin/db-update $< | grep -qoP 'HTTP/1.1 204 No Content'
	touch $@ 
	else
	echo " create cmark XML from markdown"
	bin/db-create $< | tee $@
	fi
	sleep 1
	if [ -e tiny-lr.pid ]; then
	curl -s --ipv4  http://localhost:35729/changed?files=$*
	fi
	$(DASH)

_build/data/%.xml.headers: src/data/%.xml
	@echo '## $(notdir $<) ##'
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
	echo && $(DASH)
	echo 'updated: $(shell grep -oP 'location: \K(.+)' $@)'
	else
	bin/db-create $< | tee $@
	grep -qoP 'HTTP/1.1 201 Created' $@
	fi
	sleep 1
	curl --silent --show-error --connect-timeout 1 --max-time 2 \
    --header "Accept: application/xml" \
		$(shell grep -oP 'location: \K([^\s]+)' $@)
	sleep 1

_build/data/%.xq.stored: src/data/%.xq
	@echo '## $(notdir $<) ##'
	mkdir -p $(dir $@)
	$(DASH)
	bin/compile $<
	bin/db-store $<
	mv src/store.xq  $@
	sleep 1
	if [ -e tiny-lr.pid ]; then
	curl -s --ipv4  http://localhost:35729/changed?files=$*
	fi
	$(DASH)
