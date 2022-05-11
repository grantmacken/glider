GCE_PROJECT_ID ?= glider-1
GCE_REGION ?= australia-southeast2
GCE_ZONE ?= australia-southeast2-c
GCE_INSTANCE_NAME ?= instance-3
GCE_MACHINE_TYPE ?= e2-small
GCE_IMAGE_FAMILY ?= fedora-coreos-next
GCE_NAME ?= core@$(GCE_INSTANCE_NAME)
GCE_DNS_ZONE ?= glider-zone
GCE_SERVICE_ACCOUNT_NAME ?= certbot
GCE_SERVICE_ACCOUNT ?= $(GCE_SERVICE_ACCOUNT_NAME)@$(GCE_PROJECT_ID).iam.gserviceaccount.com

# gce_ip := $(shell gcloud compute instances describe $(GCE_INSTANCE_NAME) --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

# comma separated list
GCE_DOMAINS ?= $(DNS_DOMAIN)

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
# https://cloud.google.com/dns/docs/migrating
# https://cloud.google.com/sdk/gcloud/reference/dns
# gcloud dns managed-zones describe glider-zone
# dig gmack.nz @ns-cloud-a4.googledomains.com.
# dig +short NS gmack.nz
# https://cloud.google.com/dns/docs/records
# gcloud dns record-sets transaction describe
# gcloud dns record-sets list --zone glider-zone
#gcloud dns record-sets list --zone glider-zone
# gcloud dns record-sets create gmack.nz \
#     --rrdatas=34.129.33.74 \
#     --ttl=300 \
#     --type=A \
#     --zone=glider-zone
# https://gist.github.com/tylrd/7beac28139489dae4b9e69c541d8f927
# https://russt.me/2018/04/wildcard-lets-encrypt-certificates-with-certbot/
# gcloud iam service-accounts list

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

# GCE CERTS

# after we have created volumes
# and after we have set up dns ... and obtained a gcpkey
# we can
# use docker.io/certbot/dns-google image to
# get certificates into our remote letsencrypt volume
# then import remote letsencrypt volume into local letsencrypt volume
# then run 'certbot certificates' and put output into local _deploy/certificates.txt 
.PHONY: gce-get-certs
gce-get-certs:
	cat .secrets/gcpkey.json | 
	$(Gcmd) 'cat - | tee | \
		sudo podman run --rm --name certbot --interactive --mount $(MountLetsencrypt) -e "GOOGLE_CLOUD_PROJECT=$(GCE_PROJECT_ID)"  \
		--entrypoint "[\"sh\",\"-c\"]" docker.io/certbot/dns-google \
		"cat - > /home/gcpkey.json && chmod go-rwx /home/gcpkey.json && ls -l /home/gcpkey.json && \
		certbot certonly \
		--non-interactive \
		--dns-google \
		--dns-google-credentials /home/gcpkey.json \
		--email $(shell git config user.email) \
		--agree-tos \
	  --expand \
		--domains $(GCE_DOMAINS) \
	  "'
	# once we have obtained certs we can import certs into local letsencrypt volume
	$(Gcmd) 'sudo podman volume export letsencrypt' |  podman volume import letsencrypt -

.PHONY: gce-certs-dry-run
gce-certs-dry-run:
	#$(Gcmd) 'ls -l gcpkey.json'
	$(Gcmd) 'cat .secrets/gcpkey.json | tee | \
		sudo podman run --rm --name certbot --interactive --mount $(MountLetsencrypt) -e "GOOGLE_CLOUD_PROJECT=$(GCE_PROJECT_ID)"  \
		--entrypoint "[\"sh\",\"-c\"]" docker.io/certbot/dns-google \
		"cat - > /home/gcpkey.json && chmod go-rwx /home/gcpkey.json && ls -l /home/gcpkey.json && \
		certbot certonly \
		--dry-run \
		--dns-google \
		--email $(shell git config user.email) \
		--dns-google-credentials /home/gcpkey.json \
	  --expand \
		--agree-tos \
		--domains $(DOMAINS) \
		&& ls -alR /etc/letsencrypt \
	  "'

# after we have our certs in the local letsencypt volume 
# then _deploy/certificates.txt will contain paths to the certs
# so we write these to src/proxy/conf/certificates.conf
# and adjust src/proxy/conf/proxy.conf so we only serve TLS
#
	# once we have obtained certs run 'certbot certificates' and put output into local _deploy/certificates.txt 
_deploy/certificates.txt:
	$(Gcmd) 'sudo podman run --rm --name certbot --mount $(MountLetsencrypt) docker.io/certbot/dns-google certificates' |
	tee _deploy/certificates.txt
 
.PHONY: proxy-after-certs
proxy-after-certs: _deploy/certificates.txt
	echo "ssl_certificate  $(shell grep -oP 'Certificate Path: \K.+' $<);" > src/proxy/conf/certificates.conf
	echo "ssl_certificate_key  $(shell grep -oP 'Private Key Path: \K.+' $<);" >> src/proxy/conf/certificates.conf
	$(DASH)
	cat src/proxy/conf/certificates.conf
	$(DASH)
	sed -i 's/ include basic.conf;/#include basic.conf;/' src/proxy/conf/proxy.conf
	sed -i 's/#include tls_server.conf;/include tls_server.conf;/' src/proxy/conf/proxy.conf
	sed -i 's/#include redirect.conf;/include redirect.conf;/' src/proxy/conf/proxy.conf
	$(DASH)
	cat src/proxy/conf/proxy.conf
	$(DASH)
	echo 'CHECK! "include basic.conf" is commented out'
	echo 'CHECK! "include redirect.conf" is NOT commented out'
	echo 'CHECK! "include tls_server.con" is NOT commented out'
	$(DASH)
	$(MAKE) confs
	echo 'NOTE! pod will now only serve HTTPS and HTTP will be redirected to HTTPS'
	$(DASH)
	echo ' - import local volumes into remote volumes'
	$(DASH)
	$(MAKE) gce-volumes-import

# echo "##[ $(@) ]##"
# $(MAKE) confs
# $(DASH)
# echo 'NOTE! pod will now only serve HTTPS and HTTP will be redirected to HTTPS'
# $(DASH)
# echo 'INFO! import local volumes into remote volumes'
# $(DASH)
# $(MAKE) gce-volumes-import

# src/proxy/conf/certificates.conf: _deploy/certificates.txt
# [ -d $(dir $@) ] || mkdir -p $(dir $@)
# @echo '## $(notdir $@) ##'
# echo "ssl_certificate  $(shell grep -oP 'Certificate Path: \K.+' $<);" > $@
# echo "ssl_certificate_key  $(shell grep -oP 'Private Key Path: \K.+' $<);" >> $@
# cat $@



# after we have our certs in the local letsencypt volume 
# then we can start using TLS in our proxy server

#  src/proxy/conf/proxy.conf: src/proxy/conf/certificates.conf

# $(DASH)
# cat $<
# $(DASH)
# echo 'CHECK! "include basic.conf" is commented out' 
# echo 'CHECK! "include redirect.conf" is NOT commented out' 
# echo 'CHECK! "include tls_server.con" is NOT commented out' 
# $(DASH)

##############################
## GCE DNS section
## prefix dns
##############################

.PHONY: gce-dns-info
gce-dns-info:
	ZONE_NAME=$(shell echo "$(DNS_DOMAIN)" | sed 's/\./-/')-zone
	gcloud dns managed-zones list
	$(DASH)
	gcloud dns managed-zones describe $${ZONE_NAME}
	$(DASH)
	# gcloud dns operations list --zones=$${ZONE_NAME}
	#$(DASH)
	#gcloud dns project-info describe $(GCE_PROJECT_ID)
	#$(DASH)
	#gcloud iam service-accounts list
	#gcloud iam service-accounts keys list --iam-account=certbot@glider-1.iam.gserviceaccount.com
	#$(DASH)
	#gcloud iam service-accounts keys list --iam-account=383401241092-compute@developer.gserviceaccount.com 

.PHONY: gce-dns-create-managed-zone
gce-dns-create-managed-zone:
	ZONE_NAME=$(shell echo "$(DNS_DOMAIN)" | sed 's/\./-/')-zone
	gcloud dns managed-zones create $${ZONE_NAME} --dns-name='$(DNS_DOMAIN).' --description='managed zone for $(DNS_DOMAIN)'

gce-dns-type-a-record:
	# gcloud dns record-sets create $(DNS_DOMAIN) \
	# 		--rrdatas=$(call gce_ip) \
	# 		--ttl=300 \
	# 		--type=A \
	# 		--zone=glider-zone
	# gcloud dns record-sets create $(DNS_DOMAIN) \
	# 		--rrdatas='185.199.108.153,185.199.109.153,185.199.110.153,185.199.111.153' \
	# 		--ttl=300 \
	# 		--type=A \
	# 		--zone=markup-nz-zone

gce-dns-type-cname-record:
	gcloud dns record-sets create $(DNS_DOMAIN) \
			--rrdatas='185.199.108.153' \
			--ttl=300 \
			--type=CNAME \
			--zone=markup-nz-zone

.PHONY: gce-service-acc
gce-service-acc:
	if ! gcloud iam service-accounts list | grep -q $(GCE_SERVICE_ACCOUNT_NAME)
	then
	gcloud iam service-accounts create $(GCE_SERVICE_ACCOUNT_NAME) --display-name $(GCE_SERVICE_ACCOUNT)
	gcloud projects add-iam-policy-binding $(GCE_PROJECT_ID) \
		--member serviceAccount:$(GCE_SERVICE_ACCOUNT) \
		--role roles/dns.admin
	fi
	gcloud iam service-accounts list --format="value(email)" | tee .secrets/gcloud-iam-service.accounts

.PHONY: gce-service-acc-keys
gce-service-acc-keys:
	echo "$(GCE_SERVICE_ACCOUNT)"
	# gcloud iam service-accounts list --format="value(email)" | tee .secrets/gcloud-iam-service.accounts
	#gcloud iam service-accounts list
	if [ ! -f .secrets/gcpkey.json ]
	then
	gcloud iam service-accounts keys create .secrets/gcpkey.json --iam-account "$(GCE_SERVICE_ACCOUNT)"
	fi
	# gcloud compute scp .secrets/gcpkey.json $(GCE_NAME):/home/core/.secrets/gcpkey.json
	gcloud iam service-accounts keys list --iam-account=$(GCE_SERVICE_ACCOUNT)

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

