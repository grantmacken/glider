## XQUERY CODE ##
# 1. main modules: on write, compiled to beam files located at './code/ebin'
# 2. library modules: on write, compiled, registered lib
# 3. restXQ modules: on write, compiled, registered lib
# 4. escripts: on write, copy to location ./code/escripts
# Except for restXQ modules,  modules are in a flat directory structure: src/code/{name}.{xq or xqm}
# xq for main modules 
# xqm for library modules
# restXQ modules located src/code/routes directory
# The naming convention is to name the restXQ modules after domains
# The restXQ module for a domain will define website dispatch routes for the domain
# 
# ----------------------------------------

restxqModulesBuild := $(patsubst src/%,_build/%.txt,$(wildcard src/code/routes/*.xqm)) 
libraryModulesBuild :=$(filter-out $(restxqModulesBuild), $(patsubst src/%,_build/%.txt,$(call rwildcard,src/code,*.xqm))) 
mainModulesBuild := $(patsubst src/%,_build/%.txt,$(call rwildcard,src/code,*.xq))
escriptsBuild := $(patsubst src/%,_build/%.txt,$(call rwildcard,src/code,*.escript))
xqDataBuild := $(patsubst src/%.xq,_build/%.xq.txt,$(call rwildcard,src/data,*.xq))
# xquery constructors that can be stored as XDM items the xqerl db
# these can be functions, maps or arrays we build here to do a compile check
# $(mainModulesBuild) $(xqDataBuild)
#
# $(info $(mainModulesBuild))

.PHONY: escripts 
escripts: $(escriptsBuild)

.PHONY: escripts-clean
escripts-clean:
	rm -fv $(escriptsBuild)

.PHONY: main-modules 
main-modules: $(mainModulesBuild)

.PHONY: main-modules-clean 
main-modules-clean: 
	rm -fv $(mainModulesBuild)

.PHONY: library-modules 
library-modules: $(libraryModulesBuild)


.PHONY: restxq-modules 
restxq-modules: $(restxqModulesBuild)

.PHONY: code-export 
code-export: _deploy/xqerl-code.tar



.PHONY: code 
code: escripts main-modules library-modules restxq-modules ## XQuery modules: register library modules

_deploy/xqerl-code.tar: code
	[ -d $(dir $@) ] || mkdir -p $(dir $@) 
	podman pause xq &>/dev/null
	podman volume export xqerl-code > $@
	podman unpause xq &>/dev/null

.PHONY: code-deploy
code-deploy: $(patsubst _build/code/%,_deploy/code/%,$(libraryModulesBuild) $(restxqModulesBuild)) ## XQuery modules: register library modules on remote xq container

.PHONY: code-clean
code-clean: # remove: `make code` build artifacts
	echo '##[ $@ ]##'
	rm -fv $(restxqModulesBuild) $(libraryModulesBuild) $(mainModulesBuild) $(xqDataBuild) _deploy/xqerl-code.tar

.PHONY: code-volume-import
code-volume-import: down
	echo "##[ $(@) ]##"
	podman volume import xqerl-code  _deploy/xqerl-code.tar

.PHONY: code-reset
code-reset: service-stop volumes-remove-xqerl-code volumes code-clean service-start

.PHONY: code-library-list
code-library-list: ## XQuery modules: list registered XQuery library modules
	echo "##[ $(@) ##]"
	if podman ps -a | grep -q $(XQ)
	then
	$(ESCRIPT) code/escripts/list-libs.escript
	fi

.PHONY: code-deployed-library-list
code-deployed-library-list:## XQuery modules: list registered XQuery library modules on remote xq container
	echo "##[ $(@) ##]"
	$(Gcmd) 'podman exec xq xqerl eval "[binary_to_list(X) || X <- xqerl_code_server:library_namespaces()]."' | 
	jq -r '.[]'

_build/code/%.xqm.txt: src/code/%.xqm
	[ -d $(dir $@) ] || mkdir -p $(dir $@)
	if podman ps -a | grep -q $(XQ)
	then
	cat $< | podman run --rm --interactive --mount $(MountCode) --entrypoint "sh" $(XQ) \
		-c 'cat - > /tmp/$(notdir $<);\
		mkdir -p $(dir $(patsubst src/%,%,$<));\
		mv /tmp/$(notdir $<) $(patsubst src/%,%,$<)' 
	$(ESCRIPT) code/escripts/compile.escript $(patsubst src/%,%,$<) |
	tee $@
	grep -q :Info: $@
	sleep .25
	fi

_build/code/%.xq.txt: src/code/%.xq
	[ -d $(dir $@) ] || mkdir -p $(dir $@)
	if podman ps -a | grep -q $(XQ)
	then
	cat $< | podman run --rm --interactive --mount $(MountCode) --entrypoint "sh" $(XQ) \
		-c 'cat - > /tmp/$(notdir $<);\
		mkdir -p $(dir $(patsubst src/%,%,$<));\
		mv /tmp/$(notdir $<) $(patsubst src/%,%,$<)' 
	$(ESCRIPT) code/escripts/compile.escript $(patsubst src/%,%,$<) |
	tee $@
	grep -q :Info: $@
	sleep .25
	fi

_deploy/code/%.txt: _build/code/%.txt
	[ -d $(dir $@) ] || mkdir -p $(dir $@)
	if podman ps -a | grep -q $(XQ)
	then
	echo '##[ $(*) ]##'
	echo '##[ $(notdir $(*)) ]##'
	cat src/code/$* | $(Gcmd) "cat - > $(notdir $(*))  \
		&& podman cp $(notdir $(*)) xq:/home \
	  && podman exec xq xqerl eval 'xqerl:compile(\"/home/$(notdir $(*))\").'" | tee $@
	fi

_build/data/%.xq.txt: src/data/%.xq
	[ -d $(dir $@) ] || mkdir -p $(dir $@)
	if podman ps -a | grep -q $(XQ)
	then
	echo '##[ $< ]##'
	podman cp $< xq:/home/
	podman exec xq xqerl eval '
	Res = try
	 Mod = xqerl:compile("/home/$(notdir $<)")
	 of
		D -> lists:concat(["$(<):1:Info: compiled ok! ", Mod])
	 catch
	 _:E -> lists:concat(["$(<):", integer_to_list(element(2,element(5,E))), ":Error: ",binary_to_list(element(3,E))])
	 end.' | sed 's/"//g' | tee $@
	grep -q :Info: $@
	fi

_build/code/escripts/%.txt: src/code/escripts/%
	[ -d $(dir $@) ] || mkdir -p $(dir $@)
	cat $< | podman run --rm --interactive --mount $(MountCode) --entrypoint "sh" $(XQ) \
		-c 'cat - > $(patsubst src/%,%,$<) && ls $(patsubst src/%,%,$<)' | 
	tee $@

