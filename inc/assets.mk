###########################
### XQUERY ASSETS ###
# dealing directly with volume so 
# so xq container does not have to be running
## for svg cons use: https://icons.getbootstrap.com/
## pick icons 
## <img src="/assets/icons/bootstrap.svg" alt="Bootstrap" width="32" height="32">
###########################
stylesBuild := $(patsubst src/%.css,_build/%.css,$(wildcard src/assets/styles/*.css))
fontsBuild := $(patsubst src/%,_build/%,$(wildcard src/assets/fonts/*))
castsBuild := $(patsubst src/%,_build/%,$(wildcard src/assets/casts/*.cast))
scriptsBuild := $(patsubst src/%,_build/%,$(wildcard src/assets/scripts/*.js))
iconsBuild := $(patsubst src/%,_build/%,$(wildcard src/assets/icons/*.svg))
imagesBuild := $(patsubst src/%,_build/%,$(wildcard src/assets/images/*.png))

.PHONY: assets assets-deploy
assets: _deploy/static-assets.tar ## static-assets: pre-process and store on container filesystem

_deploy/static-assets.tar: $(stylesBuild) $(scriptsBuild) $(castsBuild) $(fontsBuild) 
	[ -d $(dir $@) ] || mkdir -p $(dir $@)
	# echo '##[  $(notdir $@) ]##' TODO $(iconsBuild) $(imagesBuild) 
	podman volume export static-assets > $@

assets-deploy: ## static-assets: deploy assets on remote container filesystem
	@echo '## $@ ##'
	cat _deploy/static-assets.tar |
	$(Gcmd) ' cat - | podman volume import static-assets - '

.PHONY: assets-volume-reset
assets-volume-reset: service-stop \ ## static-assets: reset static-assets volume then rebuild asset files 
	volumes-remove-static-assets \
	volumes \
	assets-clean \
	assets \
	service-start
	echo '##[ $@ ]##'

.PHONY: assets-clean
assets-clean:
	echo '##[ $@ ]##'
	rm -f $(stylesBuild) $(scriptsBuild) $(castsBuild) $(fontsBuild) $(iconsBuild) $(imagesBuild) || true 

#############
## STYLES ##
#############

.PHONY: styles 
styles: $(stylesBuild)

.PHONY: styles-clean
styles-clean:
	rm -v $(stylesBuild) || true
	podman run --rm --mount $(MountAssets) --entrypoint 'sh' $(XQ)  \
		-c 'rm priv/static/assets/styles/*' || true

.PHONY: styles-list
styles-list:
	podman run --rm --interactive --mount $(MountAssets) --entrypoint "sh" $(XQ) \
		-c 'ls priv/static/assets/styles'

_build/assets/styles/%: src/assets/styles/%
	[ -d $(dir $@) ] || mkdir -p $(dir $@)
	echo '##[ $(patsubst src/%,priv/static/%,$<) ]##'
	cat $< |
	podman run --rm --interactive --mount $(MountAssets) --entrypoint "sh" $(XQ) \
		-c 'cat - > /home/$(notdir $<) \
		&& mkdir -v -p $(patsubst src/%,priv/static/%,$(dir $<)) \
		&& mv /home/$(notdir $<) $(patsubst src/%,priv/static/%,$(dir $<))  \
		&& ls $(patsubst src/%,priv/static/%,$<)' > $@
	sleep .5


#############
## SCRIPTS ##
#############

.PHONY: scripts
scripts: $(scriptsBuild)

.PHONY: scripts-clean
scripts-clean:
	rm -v $(scriptsBuild) || true
	podman run --rm --mount $(MountAssets) --entrypoint 'sh' $(XQ)  \
		-c 'rm priv/static/assets/scripts/*' || true

.PHONY: scripts-list
scripts-list:
	podman run --rm --interactive \
		--mount $(MountAssets) --entrypoint "sh" $(XQ) \
		-c 'ls priv/static/assets/scripts'

_build/assets/scripts/%: src/assets/scripts/%
	[ -d $(dir $@) ] || mkdir -p $(dir $@)
	# echo '##[  $(patsubst src/%,%,$<) ]##'
	podman run --rm --mount $(MountAssets) --entrypoint "sh" $(XQ) -c 'mkdir -p $(patsubst src/%,priv/static/%,$(dir $<))'
	cat $< | podman run --rm --interactive --mount $(MountAssets) --entrypoint "sh" $(XQ) \
		-c 'cat - > $(patsubst src/%,priv/static/%,$<) && ls $(patsubst src/%,priv/static/%,$<)' | \
		tee $@

.PHONY: casts 
casts: $(castsBuild)





.PHONY: casts-list
casts-list:
	podman run --rm --interactive --mount $(MountAssets) --entrypoint "sh" $(XQ) \
		-c 'ls priv/static/assets/casts'

.PHONY: fonts-list
fonts-list:
	podman run --rm --interactive --mount $(MountAssets) --entrypoint "sh" $(XQ) \
		-c 'ls priv/static/assets/fonts'

_build/assets/casts/%: src/assets/casts/%
	[ -d $(dir $@) ] || mkdir -p $(dir $@)
	echo '##[  $(patsubst src/%,%,$<) ]##'
	podman run --rm --mount $(MountAssets) --entrypoint "sh" $(XQ) -c 'mkdir -p $(patsubst src/%,priv/static/%,$(dir $<))'
	cat $< | podman run --rm --interactive --mount $(MountAssets) --entrypoint "sh" $(XQ) \
		-c 'cat - > $(patsubst src/%,priv/static/%,$<) && ls $(patsubst src/%,priv/static/%,$<)' | \
		tee $@

.PHONY: fonts
fonts: $(fontsBuild)

.PHONY: fonts-clean
fonts-clean:
	rm -v $(fontsBuild) || true
	podman run --rm --mount $(MountAssets) --entrypoint 'sh' $(XQ)  \
		-c 'rm priv/static/assets/fonts/*' || true

_build/assets/fonts/%: src/assets/fonts/%
	echo "##[ $(patsubst src/%,priv/static/%,$<) ]##"
	cat $< |
	podman run --rm --interactive --mount $(MountAssets) --entrypoint "sh" $(XQ) \
		-c 'cat - > /home/$(notdir $<) \
		&& mkdir -v -p $(patsubst src/%,priv/static/%,$(dir $<)) \
		&& mv /home/$(notdir $<) $(patsubst src/%,priv/static/%,$(dir $<))  \
		&& ls $(patsubst src/%,priv/static/%,$<)' > $@
	sleep .5

xxxx:
	[ -d $(dir $@) ] || mkdir -p $(dir $@)
	podman run --rm --mount $(MountAssets) --entrypoint "sh" $(XQ) -c 'mkdir -p  $(patsubst src/%,priv/static/%,$(dir $<))'
	cat $< | podman run --rm --interactive --mount $(MountAssets) --entrypoint "sh" $(XQ) \
		-c 'cat - > $(patsubst src/%,priv/static/%,$<) && ls $(patsubst src/%,priv/static/%,$<)' | \
		tee $@
