GCE_PROJECT_ID ?= glider-1
GCE_REGION ?= australia-southeast2
GCE_ZONE ?= australia-southeast2-c
GCE_INSTANCE_NAME ?= instance-3
GCE_MACHINE_TYPE ?= e2-small
GCE_IMAGE_FAMILY ?= fedora-coreos-next
GCE_NAME ?= core@$(GCE_INSTANCE_NAME)
GCE_DNS_ZONE ?= glider-zone
GCE_KEY=iam-service-account-key.json
# comma separated list
GCE_DOMAINS ?= gmack.nz,markup.nz

######################
# https://cloud.google.com/dns/docs/migrating
# Create a new project
# gcloud config set project $(GCE_PROJECT_ID)
# gcloud auth login --project $(GCE_PROJECT_ID)
# gcloud auth application-default login
# gcloud auth application-default set-quota-project $(GCE_PROJECT_ID)
# gcloud config configurations list
# gcloud config list
# gcloud auth list
# gcloud compute project-info describe
# gcloud compute zones list
# gcloud compute regions list
# gcloud compute project-info add-metadata 
# gcloud config set compute/region
######################
######################


Gssh := gcloud compute ssh $(GCE_NAME) --zone=$(GCE_ZONE) --project $(GCE_PROJECT_ID)
Gcmd := $(Gssh) --command

PHONY: gce-ssh
gce-ssh:
	$(Gssh)

gce-config:
	# gcloud compute project-info add-metadata --metadata google-compute-default-region=$(GCE_REGION),google-compute-default-zone=$(GCE_ZONE) --project $(GCE_PROJECT_ID)
	gcloud config get-value compute/region
	gcloud config get-value compute/zone
	gcloud compute instances list
	gcloud compute disks list

.PHONY: gce-instance-create
gce-instance-create: 
		@gcloud compute instances create $(GCE_INSTANCE_NAME) \
			--image-project=fedora-coreos-cloud \
			--image-family=$(GCE_IMAGE_FAMILY) \
			--machine-type=$(GCE_MACHINE_TYPE)
		@gcloud compute instances list
		@#gcloud compute project-info describe

PHONY: gce-instance-info
gce-instance-info: 
		#gcloud compute  project-info describe 
		#gcloud compute instances describe $(GCE_INSTANCE_NAME) --format='get(networkInterfaces[0].networkIP)'
		# external IP
		#gcloud dns managed-zones describe $(GCE_INSTANCE_NAME)
		#gcloud compute addresses list
		#gcloud dns managed-zones describe glider-zone
		#$(DASH)
		#dig gmack.nz @ns-cloud-a1.googledomains.com.


PHONY: gce-instance-delete
gce-instance-delete: 
		@gcloud compute instances delete $(GCE_INSTANCE_NAME)
		@gcloud compute instances list

.PHONY: gce-images ## gce pull docker images
gce-images:
	echo "##[ $(@) ]##"
	$(Gcmd) 'sudo podman image ls' > _deploy/image.list
	grep -oP 'xqerl(.+)$(XQERL_VER)' _deploy/image.list || $(Gcmd) 'sudo podman pull $(XQ)'
	grep -oP 'podx-openresty(.+)$(PROXY_VER)' _deploy/image.list || $(Gcmd) 'sudo podman pull $(OR)'
	grep -oP 'docker.io/certbot/dns-google' _deploy/image.list || $(Gcmd) 'sudo podman pull docker.io/certbot/dns-google'
	grep -oP 'podx-w3m(.+)$(W3M_VER)' _deploy/image.list || $(Gcmd) 'sudo podman pull $(W3M)'
	grep -oP 'podx-curl(.+)$(CURL_VER)' _deploy/image.list || $(Gcmd) 'sudo podman pull $(CMARK)'
	$(Gcmd) 'sudo podman image ls'
	$(DASH)

# GCE VOLUMES

.PHONY: gce-volumes ## gce create docker volumes
gce-volumes:
	$(Gcmd) \
		'sudo podman volume exists xqerl-code || sudo podman volume create xqerl-code; \
		sudo podman volume exists xqerl-database || sudo podman volume create xqerl-database; \
		sudo podman volume exists static-assets || sudo podman volume create static-assets; \
		sudo podman volume exists proxy-conf || sudo podman volume create proxy-conf; \
		sudo podman volume exists letsencrypt || sudo podman volume create letsencrypt; \
		sudo podman volume ls '

.PHONY: gce-volumes-clean
gce-volumes-clean:
	echo "##[ $(@) ]##"
	$(Gcmd) \
		'sudo podman volume exists xqerl-code && sudo podman volume remove xqerl-code; \
		sudo podman volume exists xqerl-database && sudo podman volume remove xqerl-database; \
		sudo podman volume exists static-assets && sudo podman volume remove static-assets; \
		sudo podman volume exists proxy-conf && sudo podman volume remove proxy-conf; \
		sudo podman volume ls '

# after we have created volumes we can import from our local dev envronment
# 1. static-assets volume
# 2. proxy-config volumes
# 3. xqerl-database
# 3. xqerl-code

.PHONY: gce-volumes-import
gce-volumes-import: $(patsubst %.tar,%.txt,$(wildcard _deploy/*.tar))

_deploy/%.txt: _deploy/%.tar
	@echo '## $(basename $(notdir $<)) ##'
	gcloud compute scp $(<) $(GCE_NAME):/home/core/$(notdir $<)
	$(Gcmd) 'sudo podman volume import $(basename $(notdir $<)) /home/core/$(notdir $<)'

##############################
## GCE UP
##############################

.PHONY: gce-up
gce-up: gce-or-up
	echo "##[ $(@) ]##"
	$(Gcmd) 'sudo podman ps -a --pod' | tee _deploy/up.txt

.PHONY: gce-down
gce-down:
	echo "##[ $(@) ]##"
	$(Gcmd) 'sudo podman pod rm $(POD) --force' || true
	$(Gcmd) 'sudo podman ps --all --pod' | tee _deploy/up.txt
	$(Gcmd) 'sudo podman volume ls'

.PHONY: gce-podx
gce-podx: # --publish 80:80 --publish 443:443
	echo "##[ $(@) ]##"
	$(Gcmd) 'sudo podman pod exists $(POD) || sudo podman pod create --name $(POD) -p 80:80 -p 443:443 --network podman'
	$(DASH)
	$(Gcmd) 'sudo podman pod list'
	$(DASH)

.PHONY: gce-xq-up
gce-xq-up: gce-podx
	$(Gcmd) 'sudo podman run --rm --name xq --pod $(POD) \
		--mount $(MountCode) --mount $(MountData) --mount $(MountAssets) \
		--tz=$(TIMEZONE) \
		--detach $(XQ)'

.PHONY: gce-or-up
gce-or-up: gce-xq-up
	echo "##[ $(@) ]##" 
	$(Gcmd) 'sudo podman run --rm --name or --pod $(POD) \
		--mount $(MountLetsencrypt) \
		--mount $(MountProxyConf) \
		--tz=$(TIMEZONE) \
		--detach $(OR)'

# After we have the pod running 
# 1. xqerl-database volume
# 2. xqerl-code volume

.PHONY: gce-code-library-list
gce-code-library-list: ## gce list availaiable library modules
	echo "##[ $(@) ##]"
	$(Gcmd) "sudo podman exec xq xqerl eval '[binary_to_list(X) || X <- xqerl_code_server:library_namespaces()].'"  | 
	tee _deploy/code-library.list

.PHONY: gce-data-domain-list
gce-data-domain-list:
	echo '##[ $@ ]##'
	$(Gcmd) 'curl -s https://$(DNS_DOMAIN)/db' |
	tee _deploy/code-library.list

