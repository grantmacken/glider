## XQUERY CODE ##
# 1. main modules: on write, compiled to beam files located at './code/ebin'
# 2. library modules: on write, compiled, registered lib
# 3. restXQ modules: on write, compiled, registered lib
# 4. escripts: on write, copy to ./priv/bin/  -  the priv-bin volume
# Except for restXQ modules,  modules are in a flat directory structure: src/code/{name}.{xq or xqm}
# xq for main modules 
# xqm for library modules
# restXQ modules located src/code/routes directory
# The naming convention is to name the restXQ modules after domains
# The restXQ module for a domain will define website dispatch routes for the domain
# 
# ----------------------------------------

restxqModulesBuild := $(patsubst src/code/routes/%,_build/priv/modules/%,$(wildcard src/code/routes/*.xqm)) 
libModulesBuild := $(patsubst src/code/library_modules/%,_build/priv/modules/%,$(wildcard src/code/library_modules/*.xqm))
mainModulesBuild := $(patsubst src/code/main_modules/%,_build/priv/modules/%,$(wildcard src/code/main_modules/*.xq))
mainModulesClean := $(patsubst src/code/main_modules/%,./priv/modules/%,$(wildcard src/code/main_modules/*.xq))
escriptsBuild := $(patsubst src/%,_build/%,$(wildcard src/code/escripts/*))
escriptsClean := $(patsubst src/code/escripts/%,./priv/bin/%,$(wildcard src/code/escripts/*))
# xquery constructors that can be stored as XDM items the xqerl db
# these can be functions, maps or arrays we build here to do a compile check
# $(mainModulesBuild) $(xqDataBuild)
#
###########
## CODE ##
##########
# restXQ modules are compiled last
# After all files are compile we tar the xqerl-code volume.
# There might be running procceses so the
# pod is paused first, then the volume exported, after this the pod is unpaused


.PHONY: code 
code: _deploy/xqerl-code.tar ## XQuery modules: register library modules

.PHONY: code-clean
code-clean: # remove `make code` build artifacts
	echo '##[ $@ ]##'
	rm -fv $(escriptsBuild) $(restxqModulesBuild) $(libModulesBuild) $(mainModulesBuild)

_deploy/xqerl-code.tar: escripts main-modules lib-modules routes
	[ -d $(dir $@) ] || mkdir -p $(dir $@) 
	podman pause xq &>/dev/null
	podman volume export xqerl-code > $@
	podman unpause xq &>/dev/null


##############
## ESCRIPTS ##
##############

.PHONY: escripts 
escripts: $(escriptsBuild)  ## xqerl code: put runnable escripts into xqerl-code volume

.PHONY: escript-run
escript-run:
	$(ESCRIPT) priv/bin/xdm $$( echo 'function(){()}' | base64 )

.PHONY: escripts-clean
escripts-clean: ## xqerl code: remove escripts in xqerl-code volume
	echo ' - clean build escripts and associated escripts in priv-bin volume'
	rm -v $(escriptsBuild) || true
	podman run --rm --mount $(MountPriv) --entrypoint "sh" $(XQ) -c 'rm -v $(escriptsClean)' || true
	# podman run --rm --mount $(MountPriv) --entrypoint "sh" $(XQ) -c 'rm -v ./priv/bin/*' || true

.PHONY: escripts-pull
escripts-pull: ## escripts: pull down escripts located on server into src/code/escripts
	echo '##[ $(@) ]##'
	podman cp xq:/usr/local/xqerl/priv/bin/. src/code/escripts/

.PHONY: escripts-list
escripts-list: ## xqerl code: list escripts in xqerl-code volume
	podman run --rm --mount $(MountPriv) --entrypoint "sh" $(XQ) -c 'ls -l ./priv/bin/'

_build/code/escripts/%: src/code/escripts/%
	echo '##[ $(<) ]##'
	[ -d $(dir $@) ] || mkdir -p $(dir $@)
	cat $< | 
	podman run --rm --interactive --mount $(MountPriv) --entrypoint "sh" $(XQ) \
		-c 'cat - | 
	tee ./priv/bin/$(notdir $<)' > $@

##################
## MAIN MODULES ##
##################

.PHONY: main-modules 
main-modules: $(mainModulesBuild) ## xqerl-code: compile main modules

_build/priv/modules/%: src/code/main_modules/%
	[ -d $(dir $@) ] || mkdir -p $(dir $@)
	echo '##[ $(<) ]##'
	cat $< | podman run --rm --interactive --mount  $(MountPriv) --entrypoint "sh" $(XQ) \
		-c 'cat - > ./priv/modules/$*'
	$(ESCRIPT) priv/bin/compile ./priv/modules/$* | tee $@
	grep -q :Info: $@ 


.PHONY: main-modules-clean 
main-modules-clean:  ## main-modules: remove build main modules and from container'
	echo ' - remove build files'
	rm -fv $(mainModulesBuild)
	echo ' - remove xquery main module files in container'
	podman run --rm --mount $(MountPriv) --entrypoint "sh" $(XQ) -c 'rm -v $(mainModulesClean)' || true

.PHONY: main-modules-list 
main-modules-list: ## xqerl-code: list beam compiled main module files'
	echo ' list beam compiled main module files'
	podman run --rm --mount $(MountCode) --entrypoint "sh" $(XQ) \
		-c 'ls ./code/ebin' | grep -oP 'file____usr_local_xqerl_priv_modules.+'

#####################
## LIBRARY MODULES ##
#####################

.PHONY: lib-modules 
lib-modules: $(libModulesBuild) ## xqerl-code: compile main modules

.PHONY: lib-modules-list
lib-modules-list: ## XQuery modules: list registered XQuery library modules
	# echo "##[ $(@) ##]"
	$(ESCRIPT) priv/bin/list-libs

.PHONY: lib-modules-clean 
lib-modules-clean:
	echo '#[ $@ ]#'
	rm -fv $(libModulesBuild)

_build/priv/modules/%: src/code/library_modules/%
	[ -d $(dir $@) ] || mkdir -p $(dir $@)
	echo "##[ $(@) ##]"
	cat $< | podman run --rm --interactive --mount  $(MountPriv) --entrypoint "sh" $(XQ) \
		-c 'cat - > ./priv/modules/$*'
	$(ESCRIPT) priv/bin/compile ./priv/modules/$* | tee $@
	grep -q :Info: $@
	# clean up
	podman run --rm --interactive --mount  $(MountPriv) --entrypoint "sh" $(XQ) \
		-c 'rm ./priv/modules/$*'

####################
## RESTXQ MODULES ##
####################

.PHONY: routes 
routes: $(restxqModulesBuild) ## xqerl-code: compile restXQ routes

.PHONY: routes-clean 
routes-clean: ## xqerl-code: clean restXQ build
	echo '#[ $@ ]#'
	rm -fv $(restxqModulesBuild)

_build/priv/modules/%: src/code/routes/%
	[ -d $(dir $@) ] || mkdir -p $(dir $@)
	echo "##[ $(@) ##]"
	cat $< | podman run --rm --interactive --mount  $(MountPriv) --entrypoint "sh" $(XQ) \
		-c 'cat - > ./priv/modules/$*'
	$(ESCRIPT) priv/bin/compile ./priv/modules/$* | tee $@
	grep -q :Info: $@
	# clean up
	#podman run --rm --interactive --mount  $(MountPriv) --entrypoint "sh" $(XQ) -c 'rm ./priv/modules/$*'



.PHONY: code-deploy
code-deploy: $(patsubst _build/code/%,_deploy/code/%,$(libModulesBuild) $(restxqModulesBuild)) ## XQuery modules: register library modules on remote xq container

.PHONY: code-volume-import
code-volume-import: down
	echo "##[ $(@) ]##"
	podman volume import xqerl-code  _deploy/xqerl-code.tar

.PHONY: code-reset
code-reset: service-stop volumes-remove-xqerl-code volumes code-clean service-start

.PHONY: code-deployed-library-list
code-deployed-library-list:## XQuery modules: list registered XQuery library modules on remote xq container
	echo "##[ $(@) ##]"
	$(Gcmd) 'podman exec xq xqerl eval "[binary_to_list(X) || X <- xqerl_code_server:library_namespaces()]."' | 
	jq -r '.[]'

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


