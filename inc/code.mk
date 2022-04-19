###########################
### XQUERY CODE ###
# 1. main modules: on write, compiled
# 2. library modules: on write, compiled, registered lib
# The modules are in a flat directory structure: src/code/{name}.{xq or xqm}
# xq for main modules 
# xqm for library modules
# add restXQ routes library to compile last
###########################
restXQList  := $(wildcard src/code/restXQ/*.xqm)
libList := $(wildcard src/code/*.xqm)
libraryModulesBuild := $(patsubst src/%.xqm,_build/%.xqm.txt,$(libList)) 
mainModulesBuild := $(patsubst src/%.xq,_build/%.xq.txt,$(wildcard src/code/*.xq))
restXQBuild := $(patsubst src/%.xqm,_build/%.xqm.txt,$(restXQList)) 
# xquery constructors that can be stored as XDM items the xqerl db
# these can be functions, maps or arrays we build here to do a compile check
xqDataBuild := $(patsubst src/%.xq,_build/%.xq.txt,$(shell find src/data -type f  -name '*.xq'))

.PHONY: code
code: $(libraryModulesBuild) $(mainModulesBuild) $(xqDataBuild) $(restXQBuild)

.PHONY: code-clean
code-clean: ## remove `make code` build artifacts
	echo '##[ $@ ]##'
	rm -f  $(libraryModulesBuild)  $(mainModulesBuild) $(xqDataBuild) _deploy/xqerl-code.tar

.PHONY: code-library-list
code-library-list: ## list availaiable library modules
	echo "##[ $(@) ##]"
	if podman ps -a | grep -q $(XQ)
	then
	podman exec xq xqerl eval '[binary_to_list(X) || X <- xqerl_code_server:library_namespaces()].' | 
	jq -r '.[]'
	fi

_build/code/%.xqm.txt: src/code/%.xqm
	[ -d $(dir $@) ] || mkdir -p $(dir $@)
	echo '##[ $(notdir $<) ]##'
	if podman ps -a | grep -q $(XQ)
	then
	# podman exec xq xqerl eval 'xqerl:compile("$<").'
	bin/compile $< | tee $@
	echo
	grep -q :I: $@
	fi

_build/code/%.xq.txt: src/code/%.xq
	[ -d $(dir $@) ] || mkdir -p $(dir $@)
	echo '##[ $(notdir $<) ]##'
	if podman ps -a | grep -q $(XQ)
	then
	bin/compile $< | tee $@
	echo
	grep -q :I: $@
	fi

_build/data/%.xq.txt: src/data/%.xq
	[ -d $(dir $@) ] || mkdir -p $(dir $@)
	echo '##[ $(notdir $<) ]##'
	if podman ps -a | grep -q $(XQ)
	then
	bin/compile $< | tee $@
	echo
	grep -q :I: $@
	fi


