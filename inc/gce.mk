GCE_PROJECT_ID=glider-1
GCE_REGION=australia-southeast2
GCE_ZONE=australia-southeast2-c
GCE_INSTANCE_NAME=instance-3
GCE_MACHINE_TYPE=e2-small
GCE_IMAGE_FAMILY=fedora-coreos-next
GCE_NAME=core@$(GCE_INSTANCE_NAME)
GCE_DNS_ZONE=glider-zone
GCE_SERVICE_ACCOUNT_NAME=certbot
GCE_SERVICE_ACCOUNT="$(GCE_SERVICE_ACCOUNT_NAME)@$(GCE_PROJECT_ID).iam.gserviceaccount.com"

# gce_ip := $(shell gcloud compute instances describe $(GCE_INSTANCE_NAME) --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

TLS_COMMON_NAME=gmack.nz
DOMAINS=gmack.nz,markup.nz

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
# IP != gcloud compute instances describe $(GCE_INSTANCE_NAME) --format='get(networkInterfaces[0].accessConfigs[0].natIP)'

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
	$(Gcmd) 'sudo podman pull $(XQ)'
	$(Gcmd) 'sudo podman pull $(OR)'
	$(Gcmd) 'sudo podman pull $(W3M)'
	$(Gcmd) 'sudo podman pull docker.io/certbot/dns-google'
	$(DASH)
	$(Gcmd) 'sudo podman image ls'
	$(DASH)

.PHONY: gce-up
gce-up:
	echo "##[ $(@) ]##" 

.PHONY: gce-down
gce-down:
	echo "##[ $(@) ]##" 
	$(Gcmd) 'sudo podman pod stop -a || true'
	$(Gcmd) 'sudo podman stop -a || true'
	$(Gcmd) 'sudo podman ps -a --pod'

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


.PHONY: gce-podx
gce-podx: # --publish 80:80 --publish 443:443
	echo "##[ $(@) ]##"
	$(Gcmd) 'sudo podman pod exists $(POD) || sudo podman pod create --name $(POD) -p 80:80 -p 443:443 --network podman'
	$(DASH)
	$(Gcmd) 'sudo podman pod list'
	$(DASH)

.PHONY: gce-xq-up
gce-xq-up:
	$(Gcmd) 'sudo podman run --rm --name xq --pod $(POD) \
		--mount $(MountCode) --mount $(MountData) --mount $(MountAssets) \
		--tz=$(TIMEZONE) \
		--detach $(XQ)'

.PHONY: gce-or-up
gce-or-up:
	$(Gcmd) 'sudo podman run --rm --name or --pod $(POD) \
		--mount $(MountLetsencrypt) \
		--mount $(MountProxyConf) \
		--tz=$(TIMEZONE) \
		--detach $(OR)'
	$(Gcmd) 'sudo podman ps -a --pod | grep -oP "$(XQ)(.+)$$"'

.PHONY: gce-or-basic-up
gce-or-basic-up:
	$(Gcmd) 'sudo podman run --rm --name or --pod $(POD) \
		--mount $(MountProxyConf) \
		--tz=$(TIMEZONE) \
		--detach $(OR)'

.PHONY: gce-check
gce-check: 
	echo "##[ $(@) ]##"
	$(Gcmd) 'sudo podman ps -a --pod '

.PHONY: gce-check-flying
gce-check-flying: 
	echo "##[ $(@) ]##"
	$(DASH)
	echo ' - outside the pod only port 80 and port 443 is exposed'
	echo ' - so a request on xqerls port 8081 will fail'
	$(DASH)
	$(Gcmd) 'sudo podman run --rm $(W3M) -dump http://localhost:8081/xqerl'
	echo && $(DASH)
	echo ' - however by joining pod we can reach xqerl on port 8081'
	$(DASH)
	$(Gcmd) 'sudo podman run --rm --pod $(POD) $(W3M) -dump http://localhost:8081/xqerl'
	echo && $(DASH)
	echo ' - the "or" container can reverse proxy requests to the "xq" container '
	echo ' - so a request will serve content delivered by xqerl '
	IP=$$( gcloud compute instances describe $(GCE_INSTANCE_NAME) --format='get(networkInterfaces[0].accessConfigs[0].natIP)' )
	echo "- gce instance comes with an external external IP address: $$IP
	echo ' - with the IP address we can make world wide web requests '
	podman run --rm $(W3M) -dump http://$${IP}
	$(DASH)
	echo ' - once we have our domain resolved by dns nameservers then ... '
	echo ' - can dump the IP address and use out domain name'
	podman run --rm $(W3M) -dump http://gmack.nz
	echo && $(DASH)

.PHONY: gce-check-site-resolve
gce-check-site-resolve: 
	echo "##[ $(@) ]##"
	$(DASH)
	$(Gcmd) "curl -v --resolve example.com:80:$(gce_ip) http://example.com"
	gcloud compute scp src/proxy/certs/example.com.pem $(GCE_NAME):/home/core/example.com.pem
	$(DASH)
	$(Gcmd) "curl -v --resolve example.com:443:$(gce_ip) --cacert ~/example.com.pem https://example.com"
	echo && $(DASH)

.PHONY: gce-info
gce-info: 
	echo "##[ $(@) ]##"
	#$(Gcmd) 'sudo podman ps -a'
	curl -v http://34.87.221.233

gce-import-proxy-conf: 
	@echo '## $(@) ##'
	gcloud compute scp _deploy/proxy-conf.tar $(GCE_NAME):/home/core/proxy-conf.tar
	$(Gcmd) 'sudo podman volume import proxy-conf /home/core/proxy-conf.tar'
	$(Gcmd) 'sudo podman run --rm --mount $(MountProxyConf) \
		--entrypoint "[\"sh\",\"-c\"]" $(OR) "cat /opt/proxy/conf/reverse_proxy.conf"'

gce-import-certs: 
	@echo '## $(@) ##'
	gcloud compute scp _deploy/certs.tar $(GCE_NAME):/home/core/certs.tar
	$(Gcmd) 'sudo podman volume import certs /home/core/certs.tar'
	$(Gcmd) 'sudo podman run --rm --mount $(MountCerts) \
		--entrypoint "[\"sh\",\"-c\"]" $(OR) "ls -l /opt/proxy/certs"'


##############################
## CERTBOT section
## prefix cb
##############################

.PHONY: gce-dns-info
gce-dns-info:
	gcloud iam service-accounts list
	gcloud iam service-accounts keys list --iam-account=certbot@glider-1.iam.gserviceaccount.com
	$(DASH)
	gcloud iam service-accounts keys list --iam-account=383401241092-compute@developer.gserviceaccount.com 


gce-dns-type-a-record:
	gcloud dns record-sets create gmack.nz \
			--rrdatas=$(call gce_ip) \
			--ttl=300 \
			--type=A \
			--zone=glider-zone

.PHONY: gce-service-acc
gce-service-acc:
	if ! gcloud iam service-accounts list | grep -q $(GCE_SERVICE_ACCOUNT_NAME)
	then
	gcloud iam service-accounts create $(GCE_SERVICE_ACCOUNT_NAME) --display-name $(GCE_SERVICE_ACCOUNT)
	gcloud projects add-iam-policy-binding $(GCE_PROJECT_ID) \
		--member serviceAccount:$(GCE_SERVICE_ACCOUNT) \
		--role roles/dns.admin
	fi
	#gcloud iam service-accounts list
	if [ ! -f .secrets/gcpkey.json ]
	then
	gcloud iam service-accounts keys create .secrets/gcpkey.json --iam-account "$(GCE_SERVICE_ACCOUNT)"
	fi
	gcloud compute scp .secrets/gcpkey.json $(GCE_NAME):/home/core/.secrets/gcpkey.json

# https://russt.me/2018/04/wildcard-lets-encrypt-certificates-with-certbot/
#
PHONY: certs-import
certs-import: 
	$(Gcmd) 'sudo podman volume export letsencrypt' |  podman volume import letsencrypt -

PHONY: certs-proxy-mod # after certs import
certs-proxy-mod: src/proxy/conf/proxy.conf
	sed -i 's/ include basic.conf;/#include basic.conf;/' $<
	sed -i 's/# include tls_server.conf;/include tls_server.conf;/' $<
	sed -i 's/# include redirect.conf;/include redirect.conf;/' $<
	$(make)
	

PHONY: certs-inspect
certs-inspect: 
	podman exec or ls -R /etc/letsencrypt


.PHONY: cb-certs
cb-certs: src/proxy/conf/certificates.conf

src/proxy/certificates.txt:
	[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo '## $(notdir $@) ##'
	$(Gcmd) 'sudo podman run --rm --name certbot --mount $(MountLetsencrypt) docker.io/certbot/dns-google certificates' |
	tee  $@

src/proxy/conf/certificates.conf: src/proxy/certificates.txt
	[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo '## $(notdir $@) ##'
	echo "ssl_certificate  $(shell grep -oP 'Certificate Path: \K.+' $<);" > $@
	echo "ssl_certificate_key  $(shell grep -oP 'Private Key Path: \K.+' $<);" >> $@
	cat $@

.PHONY: cb-certonly
cb-certonly:
	$(Gcmd) 'cat .secrets/gcpkey.json | tee | \
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
		--domains gmack.nz \
		&& ls -alR /etc/letsencrypt \
	  "'
	# once we have obtained certs we can import locally
	$(Gcmd) 'sudo podman volume export letsencrypt' |  podman volume import letsencrypt -

.PHONY: cb-dry-run
cb-dry-run:
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
		--domains gmack.nz \
		&& ls -alR /etc/letsencrypt \
	  "'
