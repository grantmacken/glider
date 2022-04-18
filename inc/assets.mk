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
assets: assets-deploy
assets-deploy: _deploy/static-assets.tar 

_deploy/static-assets.tar: $(stylesBuild) $(scriptsBuild) $(castsBuild) $(fontsBuild) 
	[ -d $(dir $@) ] || mkdir -p $(dir $@)
	# echo '##[  $(notdir $@) ]##' TODO $(iconsBuild) $(imagesBuild) 
	podman volume export static-asset > $@

PHONY: assets-clean
assets-clean:
	echo '##[ $@ ]##'
	rm -f $(stylesBuild) $(scriptsBuild) $(castsBuild) $(fontsBuild) $(iconsBuild) $(imagesBuild) || true 

PHONY: styles 
styles: $(stylesBuild)

PHONY: styles-clean
styles-clean:
	rm -v $(stylesBuild) || true
	podman run --rm --mount $(MountAssets) --entrypoint 'sh' $(XQ)  \
		-c 'rm priv/static/assets/styles/*' || true

PHONY: styles-list
styles-list:
	podman run --rm --interactive --mount $(MountAssets) --entrypoint "sh" $(XQ) \
		-c 'ls priv/static/assets/styles'

_build/assets/%.css: src/assets/%.css
	[ -d $(dir $@) ] || mkdir -p $(dir $@)
	# echo '##[  $(patsubst src/%,%,$<) ]##'
	podman run --rm --mount $(MountAssets) --entrypoint "sh" $(XQ) -c 'mkdir -p $(patsubst src/%,priv/static/%,$(dir $<))'
	cat $< | 
	podman run --rm --interactive --mount $(MountAssets) --entrypoint "sh" $(XQ) \
		-c 'cat - > $(patsubst src/%,priv/static/%,$<) && ls $(patsubst src/%,priv/static/%,$<)' | \
		tee $@
	if [ -e tiny-lr.pid ]; then
	curl -s --ipv4  http://localhost:35729/changed?files=assets/$*.css
	fi

###############
## SCRIPTS
###############

PHONY: scripts
scripts: $(scriptsBuild)

PHONY: scripts-clean
scripts-clean:
	rm -v $(scriptsBuild) || true
	podman run --rm --mount $(MountAssets) --entrypoint 'sh' $(XQ)  \
		-c 'rm priv/static/assets/scripts/*' || true

PHONY: scripts-list
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

PHONY: casts 
casts: $(castsBuild)

PHONY: fonts
fonts: $(fontsBuild)

PHONY: casts-list
casts-list:
	podman run --rm --interactive --mount $(MountAssets) --entrypoint "sh" $(XQ) \
		-c 'ls priv/static/assets/casts'

PHONY: fonts-list
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

_build/assets/fonts/%: src/assets/fonts/%
	@echo "##[ $< ]##"
	[ -d $(dir $@) ] || mkdir -p $(dir $@)
	podman run --rm --mount $(MountAssets) --entrypoint "sh" $(XQ) -c 'mkdir -p  $(patsubst src/%,priv/static/%,$(dir $<))'
	cat $< | podman run --rm --interactive --mount $(MountAssets) --entrypoint "sh" $(XQ) \
		-c 'cat - > $(patsubst src/%,priv/static/%,$<) && ls $(patsubst src/%,priv/static/%,$<)' | \
		tee $@
