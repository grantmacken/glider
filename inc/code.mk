## XQUERY CODE ##
# 1. main modules: on write, compiled
# 2. library modules: on write, compiled, registered lib
# Except for restXQ modules,  modules are in a flat directory structure: src/code/{name}.{xq or xqm}
# xq for main modules 
# xqm for library modules
# restXQ modules are the src/routes directory
# The naming convention is to name the restXQ modules after dns domains
# The restXQ module for a domain will define website dispatch routes for the domain
# 
# ----------------------------------------
libraryModulesBuild := $(patsubst src/%,_build/%.txt,$(wildcard src/code/*.xqm) $(wildcard src/code/routes/*.xqm)) 
mainModulesBuild := $(patsubst src/%,_build/%.txt,$(wildcard src/code/*.xq))
# restXQBuild := $(patsubst src/%,_build/%.txt,$(wildcard src/code/restXQ/*.xqm)) 
# xquery constructors that can be stored as XDM items the xqerl db
# these can be functions, maps or arrays we build here to do a compile check
xqDataBuild := $(patsubst src/%.xq,_build/%.xq.txt,$(call rwildcard,src/data,*.xq))
# $(mainModulesBuild) $(xqDataBuild)

.PHONY: code 
code: _deploy/xqerl-code.tar ## XQuery modules: register library modules

_deploy/xqerl-code.tar: $(libraryModulesBuild) $(mainModulesBuild) $(xqDataBuild)
	[ -d $(dir $@) ] || mkdir -p $(dir $@)
	podman pause xq
	podman volume export xqerl-code > $@
	podman unpause xq

.PHONY: code-deploy
code-deploy: $(patsubst _build/code/%,_deploy/code/%,$(libraryModulesBuild)) ## XQuery modules: register library modules on remote xq container

.PHONY: code-clean
code-clean: # remove: `make code` build artifacts
	echo '##[ $@ ]##'
	rm -fv  $(libraryModulesBuild) $(mainModulesBuild) $(xqDataBuild) _deploy/xqerl-code.tar

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
	podman exec xq xqerl eval '[binary_to_list(X) || X <- xqerl_code_server:library_namespaces()].' | 
	jq -r '.[]'
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
	echo '##[ $< ]##'
	podman cp $< xq:/home/
	podman exec xq xqerl eval '
	Res = try
	 Mod = xqerl:compile("/home/$(notdir $<)")
	 of
		D -> lists:concat(["$(<):1:Info: compiled ok! ", Mod])
	 catch
	 _:E -> lists:concat(["$(<):", integer_to_list(element(2,element(5,E))), ":Error: ",binary_to_list(element(3,E))])
	 end.' | tee $@
	grep -q :Info: $@
	sleep 1
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

_build/code/%.xq.txt: src/code/%.xq
	[ -d $(dir $@) ] || mkdir -p $(dir $@)
	echo '##[  $<  ]##'
	if podman ps -a | grep -q $(XQ)
	then
	podman cp $< xq:/home/
	podman exec xq xqerl eval '
	Res = try
	 Mod = xqerl:compile("/home/$(notdir $<)")
	 of
		D -> lists:concat(["$(<):1:Info: compiled ok! ", Mod])
	 catch
	 _:E -> lists:concat(["$(<):", integer_to_list(element(2,element(5,E))), ":Error: ",binary_to_list(element(3,E))])
	 end.' | tee $@
	grep -q :Info: $@
	fi

_build/data/%.xq.txt: src/data/%.xq
	[ -d $(dir $@) ] || mkdir -p $(dir $@)
	if podman ps -a | grep -q $(XQ)
	then
	echo '##[ $< ]##'
	podman cp $< xq:/home/
		podman exec xq xqerl eval '
		case xqerl:compile("/home/$(notdir $<)") of
			Err when is_tuple(Err), element(1, Err) == xqError -> 
				["$<:",integer_to_list(element(2,element(5,Err))),":E: ",binary_to_list(element(3,Err))];
			Info when is_atom(Info) -> 
				["$(<):1:I: compiled ok! "];
				_ -> 
				io:format(["$<:1:E: unknown error"])
		end.' | jq -r '.[]' | tee $@
	fi


