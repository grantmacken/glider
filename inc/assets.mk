###########################
### XQUERY ASSETS ###
# dealing directly with volume so 
# so xq container does not have to be running
## for svg cons use: https://icons.getbootstrap.com/
## pick icons 
## <img src="/assets/icons/bootstrap.svg" alt="Bootstrap" width="32" height="32">
###########################
stylesBuild := $(patsubst src/%.css,_build/%.css,$(call rwildcard, src/assets/styles, *.css))
stylesClean := $(patsubst src/%,./priv/static/%,$(call rwildcard, src/assets/styles, *.css))
fontsBuild := $(patsubst src/%,_build/%,$(call rwildcard, src/assets/fonts, *.woff2))
fontsClean := $(patsubst src/%,./priv/static/%,$(call rwildcard, src/assets/fonts,*))
castsBuild := $(patsubst src/%,_build/%,$(call rwildcard, src/assets/casts, *.cast))
castsClean := $(patsubst src/%,./priv/static/%,$(call rwildcard, src/assets/casts,*))
scriptsBuild := $(patsubst src/%,_build/%,$(call rwildcard, src/assets/scripts, *.js)) $(patsubst src/%,_build/%,$(call rwildcard, src/assets/scripts, *.js.gz))
scriptsClean := $(patsubst src/%,./priv/static/%,$(call rwildcard, src/assets/scripts,*))
imagesBuild := $(patsubst src/%,_build/%,$(call rwildcard, src/assets/images, *))
imagesClean := $(patsubst src/%,./priv/static/%,$(call rwildcard, src/assets/images,*))
iconsBuild := $(patsubst src/%,_build/%,$(call rwildcard, src/assets/icons, *.svg))

.PHONY: assets assets-deploy
assets: _deploy/xqerl-priv.tar ## static-assets: pre-process and store on container filesystem

_deploy/xqerl-priv.tar: $(stylesBuild) $(scriptsBuild) $(castsBuild) $(fontsBuild) $(imagesBuild) $(iconsBuild)
	[ -d $(dir $@) ] || mkdir -p $(dir $@)
	# echo '##[  $(notdir $@) ]##' TODO $(iconsBuild) $(imagesBuild) 
	podman volume export xqerl-priv > $@

assets-deploy: ## static-assets: deploy assets on remote container filesystem
	@echo '## $@ ##'
	cat _deploy/xqerl-priv.tar |
	$(Gcmd) ' cat - | podman volume import xqerl-priv - '

.PHONY: assets-reset
assets-reset: service-stop \
	volumes-remove-xqerl-priv \
	volumes \
	assets-clean \
	assets \
	service-start
	echo '##[ $@ ]##'

.PHONY: assets-list
assets-list:
	echo '##[ $@ ]##'
	podman run --rm  --mount $(MountPriv) --entrypoint "sh" $(XQ) \
		-c 'ls -R priv/static/assets'

.PHONY: assets-clean
assets-clean:
	echo '##[ $@ ]##'
	rm -fv $(stylesBuild) $(scriptsBuild) $(castsBuild) $(fontsBuild) $(iconsBuild) $(imagesBuild) 

#############
## STYLES ##
#############

.PHONY: styles 
styles: $(stylesBuild) ## static assets: cascading style sheets build chain

.PHONY: styles-clean
styles-clean:
	rm -v $(stylesBuild) || true
	podman run --rm --mount $(MountPriv) --entrypoint 'sh' $(XQ)  \
		-c 'rm -vf $(stylesClean)' || true

.PHONY: styles-list
styles-list: ## static assets:  list stored styles
	podman run --rm --interactive --mount $(MountPriv) --entrypoint "sh" $(XQ) \
		-c 'ls -R priv/static/assets/styles'

_build/assets/styles/%: src/assets/styles/%
	echo '#[ $* ]#'
	[ -d $(dir $@) ] || mkdir -p $(dir $@)
	podman run --rm --mount $(MountPriv) --entrypoint "sh" $(XQ) -c 'mkdir -p $(dir ./priv/static/assets/styles/$*)'
	cat $< |
	podman run --rm --interactive --mount $(MountPriv) --entrypoint "sh" $(XQ) \
		-c 'cat - | tee ./priv/static/assets/styles/$*' > $@

#############
## SCRIPTS ##
#############

.PHONY: scripts
scripts: $(scriptsBuild)

.PHONY: scripts-clean
scripts-clean:
	rm -v $(scriptsBuild) || true
	podman run --rm --mount $(MountPriv) --entrypoint 'sh' $(XQ)  \
		-c 'rm $(scriptsClean)' || true

.PHONY: scripts-list
scripts-list:
	podman run --rm --mount $(MountPriv) --entrypoint "sh" $(XQ) \
		-c 'ls -R priv/static/assets/scripts'

_build/assets/scripts/%: src/assets/scripts/%
	echo '#[ $* ]#'
	[ -d $(dir $@) ] || mkdir -p $(dir $@)
	podman run --rm --mount $(MountPriv) --entrypoint "sh" $(XQ) -c 'mkdir -p $(dir ./priv/static/assets/scripts/$*)'
	cat $< |
	podman run --rm --interactive --mount $(MountPriv) --entrypoint "sh" $(XQ) \
		-c 'cat - | tee ./priv/static/assets/scripts/$*' > $@

############
## CASTS  ##
############

.PHONY: casts 
casts: $(castsBuild)

.PHONY: casts-list
casts-list:
	podman run --rm --mount $(MountPriv) --entrypoint "sh" $(XQ) \
		-c 'ls -R priv/static/assets/casts'

.PHONY: casts-clean
casts-clean:
	rm -v $(castsBuild) || true
	podman run --rm --mount $(MountPriv) --entrypoint 'sh' $(XQ)  \
		-c 'rm $(castsClean)' || true

_build/assets/casts/%: src/assets/casts/%
	echo '#[ $* ]#'
	[ -d $(dir $@) ] || mkdir -p $(dir $@)
	podman run --rm --mount $(MountPriv) --entrypoint "sh" $(XQ) -c 'mkdir -p $(dir ./priv/static/assets/casts/$*)'
	cat $< |
	podman run --rm --interactive --mount $(MountPriv) --entrypoint "sh" $(XQ) \
		-c 'cat - | tee ./priv/static/assets/casts/$*' > $@

############
## FONTS  ##
############

.PHONY: fonts
fonts: $(fontsBuild)

.PHONY: fonts-list
fonts-list:
	podman run --rm --mount $(MountPriv) --entrypoint "sh" $(XQ) \
		-c 'ls -R priv/static/assets/casts'

.PHONY: fonts-clean
fonts-clean:
	rm -v $(fontsBuild) || true
	podman run --rm --mount $(MountPriv) --entrypoint 'sh' $(XQ)  \
		-c 'rm $(fontsClean)' || true

_build/assets/fonts/%: src/assets/fonts/%
	echo '#[ $* ]#'
	[ -d $(dir $@) ] || mkdir -p $(dir $@)
	podman run --rm --mount $(MountPriv) --entrypoint "sh" $(XQ) -c 'mkdir -p $(dir ./priv/static/assets/fonts/$*)'
	cat $< |
	podman run --rm --interactive --mount $(MountPriv) --entrypoint "sh" $(XQ) \
		-c 'cat - | tee ./priv/static/assets/fonts/$*' > $@

#############
## IMAGES  ##
#############

.PHONY: images
images: $(imagesBuild)

.PHONY: images-list
images-list:
	podman run --rm --mount $(MountPriv) --entrypoint "sh" $(XQ) \
		-c 'ls -R priv/static/assets/images'

.PHONY: images-clean
images-clean:
	rm -v $(imagesBuild) || true
	podman run --rm --mount $(MountPriv) --entrypoint 'sh' $(XQ)  \
		-c 'rm $(imagesClean)' || true

_build/assets/images/%: src/assets/images/%
	echo '#[ $* ]#'
	[ -d $(dir $@) ] || mkdir -p $(dir $@)
	podman run --rm --mount $(MountPriv) --entrypoint "sh" $(XQ) -c 'mkdir -p $(dir ./priv/static/assets/images/$*)'
	cat $< |
	podman run --rm --interactive --mount $(MountPriv) --entrypoint "sh" $(XQ) \
		-c 'cat - | tee ./priv/static/assets/images/$*' > $@

#############
## IMAGES  ##
#############

.PHONY: icons
icons: $(iconsBuild)

.PHONY: icons-list
icons-list:
	podman run --rm --mount $(MountPriv) --entrypoint "sh" $(XQ) \
		-c 'ls -R priv/static/assets/icons'

.PHONY: icons-clean
icons-clean:
	rm -v $(iconsBuild) || true
	podman run --rm --mount $(MountPriv) --entrypoint 'sh' $(XQ)  \
		-c 'rm $(iconsClean)' || true

_build/assets/icons/%: src/assets/icons/%
	echo '#[ $* ]#'
	[ -d $(dir $@) ] || mkdir -p $(dir $@)
	podman run --rm --mount $(MountPriv) --entrypoint "sh" $(XQ) -c 'mkdir -p $(dir ./priv/static/assets/icons/$*)'
	cat $< |
	podman run --rm --interactive --mount $(MountPriv) --entrypoint "sh" $(XQ) \
		-c 'cat - | tee ./priv/static/assets/icons/$*' > $@
