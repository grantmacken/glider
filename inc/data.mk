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

.PHONY: data
data: $(mdBuild) $(xmlBuild) $(xqBuild)	## from src store XDM data items in db

.PHONY: data-clean
data-clean: ## clean "data" build artefacts
	echo '##[ $@ ]##'
	rm -f $(mdBuild) $(xmlBuild) $(xqBuild) _deploy/xqerl-database.tar

.PHONY: data-domain-list
data-domain-list:
	echo '##[ $@ ]##' #&#10
	podman exec xq xqerl eval "binary_to_list(xqerl:run(\"'http://$(DEV_DOMAIN)' => uri-collection() => string-join('&#10;')\"))." | jq -r '.'

.PHONY: data-in-pod-list
data-in-pod-list:
	podman run  --rm --pod $(POD) $(CURL) \
		--silent --show-error --connect-timeout 1 --max-time 2 \
		http://$(DEV_DOMAIN)/db

.PHONY: data-list
data-list:
	$(call Dump,db)

_build/data/%.md.headers: src/data/%.md
	[ -d $(dir $@) ] || mkdir -p $(dir $@)
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
	[ -d $(dir $@) ] || mkdir -p $(dir $@)
	echo '##[ $(basename $(notdir $<)) ]##'
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
	[ -d $(dir $@) ] || mkdir -p $(dir $@)
	echo " xqerl database: xquery function"
	echo 'collection: http://$(dir $(*))'
	echo 'resource: $(basename $(notdir $<))'
	File=/home/$(shell echo $(*) | sed 's%/%_%' ).xq
	if podman ps -a | grep -q $(XQ)
	then
	echo '##[ $(notdir $<) ]##'
	podman cp $< xq:/home/
	podman exec xq xqerl eval '
	case xqerl:compile("/home/$(notdir $<)") of
		Err when is_tuple(Err), element(1, Err) == xqError -> 
			["$<:",integer_to_list(element(2,element(5,Err))),":E: ",binary_to_list(element(3,Err))];
		Mod when is_atom(Mod) -> 
			["$<:1:I: compiled ok! "];
			_ -> 
			io:format(["$<:1:E: unknown error"])
	end.' | jq -r '.[]'
	podman cp src/code/db-store.xq xq:/home/
	echo -n ' - db function item stored: '
	podman exec xq xqerl eval '
	Arg1 = list_to_binary("/home/$(notdir $<)"),
	Arg2 = list_to_binary("http://$(dir $(*))$(basename $(notdir $<))"),
	Args = #{<<"src">> => Arg1, <<"uri">> => Arg2},
	case xqerl:compile("/home/db-store.xq") of
		Mod when is_atom(Mod) -> 
		case Mod:main(Args) of
			Bin when is_binary(Bin) -> 
			  File = "/home/$(shell echo $(*) | sed 's%/%_%' ).xq",
				file:write_file(File,binary_to_list(Bin)),
				xqerl:run(xqerl:compile(File))
				;
			_ -> false
		end;
		_ -> false
		end.'
	fi
	podman exec xq cat /home/$(shell echo $(*) | sed 's%/%_%' ).xq > $@
	echo -n ' - db identifier: '
	podman exec xq xqerl eval "binary_to_list(xqerl:run(\"'http://$(dir $(*))' => uri-collection() => string-join('&#10;')\"))." | 
	jq -r '.' | grep -oP 'http://$(dir $(*))$(basename $(notdir $<))'
	


