###########################
### XQUERY CODE ###
# 1. main modules: on write, compiled
# 2. library modules: on write, compiled, registered lib
# The modules are in a flat directory structure: src/code/{name}.{xq or xqm}
# xq for main modules 
# xqm for library modules
###########################
libraryModulesBuild := $(patsubst src/%.xqm,_build/%.xqm.txt,$(wildcard src/code/*.xqm))
mainModulesBuild := $(patsubst src/%.xq,_build/%.xq.txt,$(wildcard src/code/*.xq))

# xquery constructors that can be stored as XDM items the xqerl db
# these can be functions, maps or arrays we build here to do a compile check
xqDataBuild := $(patsubst src/%.xq,_build/%.xq.txt,$(shell fd . -e xq src/data))

PHONY: code 
code:  $(libraryModulesBuild) $(mainModulesBuild) $(xqDataBuild)  ## from 'src/code' compile xQuery modules
 
 #$(mainModulesBuild) $(xqDataBuild)
.phony: code-clean
code-clean: ## remove `make code` build artifacts
	@echo '## $(@) ##'
	@rm -v  $(libraryModulesBuild)  $(mainModulesBuild) $(xqDataBuild) || true

.PHONY: watch-code
watch-code:
	@while true; do \
        clear && $(MAKE) --silent code 2>/dev/null || true; \
        inotifywait -qre close_write ./src/code || true; \
    done

.PHONY: code-library-list
code-library-list: ## list availaiable library modules
	@echo '## $(@) ##'
	@if podman ps -a | grep -q $(XQ)
	then
	@podman exec xq xqerl eval '[binary_to_list(X) || X <- xqerl_code_server:library_namespaces()].' | jq -r '.[]'
	fi

_build/code/%.xqm.txt: src/code/%.xqm
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo '##[ $(notdir $<) ]##'
	@if podman ps -a | grep -q $(XQ)
	then
	@bin/compile $< | tee $@
	@echo
	@grep -q :I: $@
	fi

_build/code/%.xq.txt: src/code/%.xq
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo '##[ $(notdir $<) ]##'
	@if podman ps -a | grep -q $(XQ)
	then
	@bin/compile $< | tee $@
	@echo
	@grep -q :I: $@
	fi

_build/data/%.xq.txt: src/data/%.xq
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo '##[ $(notdir $<) ]##'
	@if podman ps -a | grep -q $(XQ)
	then
	@bin/compile $< | tee $@
	@echo
	@grep -q :I: $@
	fi


