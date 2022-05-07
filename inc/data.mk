##########################
## The data directory holds files 
## that will be stored in the xqerl db 
## the stored XDM item will be detirmined by the initial file extension 
# src/data/{domain}/{collection}/{filename}.{extension}
###########################
mdList  := $(call rwildcard,src/data,*.md)
# jsonList  := $(call rwildcard,src/data,*.json)
# xmlList  := $(call rwildcard,src/data,*.xml)
xqList  :=  $(call rwildcard,src/data,*.xq)

mdBuild := $(patsubst src/%.md,_build/%.xml,$(mdList))
# TODO jsonBuild := $(patsubst src/%,_build/%.headers,$(jsonList))
# TODO xmlBuild := $(patsubst src/%,_build/%.headers,$(xmlList))
xqBuild := $(patsubst src/%,_build/%.stored,$(xqList))

.PHONY: data
data: $(mdBuild) #  $(xqBuild) ## from src store xdm data items in db

 #TODO $(xmlBuild) $(jsonBuild)

.PHONY: data-deploy
data-deploy: $(patsubst _build/data/%,_deploy/data/%,$(mdBuild))

.PHONY: data-volume-export
data-volume-export:
	podman volume export xqerl-database > _deploy/xqerl-database.tar

.PHONY: data-volume-import
data-volume-import: down
	echo "##[ $(@) ]##"
	podman volume import xqerl-database  _deploy/xqerl-database.tar

.PHONY: data-volume-reset
data-volume-reset: down
	podman volume remove xqerl-database --force || true
	podman volume create xqerl-database

	#podman volume remove xqerl-database
	
.PHONY: data-clean
data-clean: ## clean "data" build artefacts
	echo '##[ $@ ]##'
	rm -f $(mdBuild) $(xqBuild) _deploy/xqerl-database.tar

.PHONY: data-domain-list
data-domain-list:
	echo '##[ $@ ]##' #&#10
	podman exec xq xqerl eval "binary_to_list(xqerl:run(\"'http://$(DNS_DOMAIN)' => uri-collection() => string-join('&#10;')\"))." | jq -r '.'

.PHONY: data-in-pod-list
data-in-pod-list:
	podman run  --rm --pod $(POD) $(CURL) \
		--silent --show-error --connect-timeout 1 --max-time 2 \
		http://$(DNS_DOMAIN)/db

# .PHONY: data-list
# data-list:
# 	$(call Dump,$(DOMAIN),/db/$(DOMAIN))

_build/data/%.xml: src/data/%.md
	[ -d $(dir $@) ] || mkdir -p $(dir $@)
	echo '##[ $(*) ]##'
	if podman run --rm --pod $(POD) $(CURL) \
		--silent --show-error --connect-timeout 1 --max-time 2 \
		--write-out '%{http_code}' --output /dev/null \
		-I --header "Accept: application/xml" \
		http://localhost:8081/db/$(*) | grep -q '200'
	then
	echo "xqerl database: update cmark XML from markdown source"
	cat $< |
	podman run --rm --interactive $(CMARK) |
	sed -e '1,2d' > $@
	cat $@ |
	podman run --rm  --pod $(POD) --interactive $(CURL) \
		--silent --show-error --connect-timeout 1 --max-time 2 \
		--write-out '%{http_code}' --output /dev/null \
    -X PUT \
		--header "Content-Type: application/xml" \
		--data-binary @- \
		http://localhost:8081/db/$(*) | grep -q '204'
	else
	echo "xqerl database: new cmark XML from markdown source"
	echo 'collection: http://$(dir $(*))'
	echo 'resource: $(basename $(notdir $<))'
	 podman run --rm --pod $(POD) $(CURL) \
			--silent --show-error --connect-timeout 1 --max-time 2 \
			--write-out '%{http_code}' --output /dev/null \
			-I --header "Accept: application/xml" \
			http://localhost:8081/db/$(*)
	$(DASH)
	cat $< |
	podman run --rm --interactive $(CMARK) |
	sed -e '1,2d' | tee $@
	$(DASH)
	cat $@ |
	podman run --rm  --pod $(POD) --interactive $(CURL) \
		--silent --show-error --connect-timeout 1 --max-time 2 \
		--write-out '%{http_code}' --output /dev/null \
		--header "Content-Type: application/xml" \
		--header "Slug: $(basename $(notdir $<))" \
		--data-binary @- \
		http://localhost:8081/db/$(dir $(*)) | grep -q '201'
	fi
	$(DASH)

_deploy/data/%.xml: _build/data/%.xml
	[ -d $(dir $@) ] || mkdir -p $(dir $@)
	echo '##[ $* ]##'
	if $(Gcmd) 'sudo podman run  --rm --pod $(POD) $(CURL) \
		--silent --show-error --connect-timeout 1 --max-time 2 \
		--write-out '%{http_code}' --output /dev/null \
		-I --header "Accept: application/xml" \
		http://localhost:8081/db/$(*) '  | grep -q '200'
	then 
	echo "remote xqerl database: update cmark XML from markdown source"
	echo ' - db item [ http://$(*) ]'
	cat $< | $(Gcmd) 'cat - | tee | sudo podman run --rm  --pod $(POD) --interactive $(CURL) \
		--silent --show-error --connect-timeout 1 --max-time 2 \
		--write-out '%{http_code}' --output /dev/null \
    -X PUT \
		--header "Content-Type: application/xml" \
		--data-binary @- \
		http://localhost:8081/db/$(*)' | grep -q 204
	$(DASH)
	else 
	echo ' - item not found'
	echo "xqerl database: cmark XML from markdown"
	echo 'collection: http://$(dir $(*))'
	echo 'resource: $(basename $(notdir $<))'
	cat $< | $(Gcmd) 'cat - | tee | sudo podman run --rm  --pod $(POD) --interactive $(CURL) \
		--silent --show-error --connect-timeout 1 --max-time 2 \
		--header "Content-Type: application/xml" \
		--header "Slug: $(basename $(notdir $<))" \
		--data-binary @- \
		--output /dev/null \
		--dump-header - \
		http://localhost:8081/db/$(dir $(*))' | grep -q 201
	fi
	$(Gcmd) 'sudo podman run --rm  --pod $(POD) $(CURL) \
		--silent --show-error --connect-timeout 1 --max-time 2 \
		--header "Accept: application/xml" \
		http://localhost:8081/db/$(*)' > $@

# TODO
# _build/data/%.xml: src/data/%.xml
# [ -d $(dir $@) ] || mkdir -p $(dir $@)
# echo '##[ $(basename $(notdir $<)) ]##'
# $(DASH)
# if grep -qoP 'HTTP/1.1 201 Created' $@
# then
# echo " update:  $(shell grep -oP 'location: \K([^\s]+)' $@)"
# bin/db-update $< | grep -qoP '^HTTP/1.1 204 No Content'
# touch $@
# curl --silent --show-error --connect-timeout 1 --max-time 2 \
# 	--header "Accept: application/xml" \
# 	$(shell grep -oP 'location: \K([^\s]+)' $@)
# echo 'updated: $(shell grep -oP 'location: \K(.+)' $@)'
# else
# bin/db-create $< | tee $@
# grep -qoP 'HTTP/1.1 201 Created' $@
# fi

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
	


