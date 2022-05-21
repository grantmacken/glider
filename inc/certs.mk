GCE_PROJECT_ID ?= glider-1
GCE_REGION ?= australia-southeast2
GCE_ZONE ?= australia-southeast2-c
GCE_INSTANCE_NAME ?= instance-3
GCE_MACHINE_TYPE ?= e2-small
GCE_IMAGE_FAMILY ?= fedora-coreos-next
GCE_NAME ?= core@$(GCE_INSTANCE_NAME)

GCE_KEY := iam-service-account-key.json

CERT_COMMON_NAME ?= gmack.nz 
# comma separated list
CERT_DNS_DOMAINS ?= gmack.nz,markup.nz

Gssh := gcloud compute ssh $(GCE_NAME) --zone=$(GCE_ZONE) --project $(GCE_PROJECT_ID)
Gcmd := $(Gssh) --command

##############################
## GCE DNS section
## prefix dns
##############################
# https://cloud.google.com/dns/docs/migrating
# https://cloud.google.com/sdk/gcloud/reference/dns
# https://cloud.google.com/dns/docs/records
# https://gist.github.com/tylrd/7beac28139489dae4b9e69c541d8f927
# https://russt.me/2018/04/wildcard-lets-encrypt-certificates-with-certbot/
# gcloud iam service-accounts list

.PHONY: dns-info
dns-info:
	ZONE_NAME=$(shell echo "$(DNS_DOMAIN)" | sed 's/\./-/')-zone
	gcloud dns managed-zones list
	$(DASH)
	gcloud dns managed-zones describe $${ZONE_NAME}
	$(DASH)

.PHONY: dns-check-dig
dns-check-dig:
	dig +short NS $(DNS_DOMAIN)
	dig $(DNS_DOMAIN) @$(shell dig +short NS $(DNS_DOMAIN) | tail -1)
	# dig +trace $(DNS_DOMAIN)
	dig $(DNS_DOMAIN) +nostats +nocomments +nocmd

.PHONY: check-host
check-host:
	host $(DNS_DOMAIN)

.PHONY: dns-check
dns-check:
	$(DASH)
	#dig www.$(DNS_DOMAIN) +nostats +nocomments +nocmd
	$(DASH)
	#dig $(DNS_DOMAIN) @169.254.169.254
	$(DASH)
	# dig $(DNS_DOMAIN) @$(shell gcloud compute instances describe $(GCE_INSTANCE_NAME) --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
	$(DASH)
	# dig +trace $(DNS_DOMAIN)
	hosts $(DNS_DOMAIN)
	nslookup $(DNS_DOMAIN)


.PHONY: dns-create-managed-zone
dns-create-managed-zone:
	ZONE_NAME=$(shell echo "$(DNS_DOMAIN)" | sed 's/\./-/')-zone
	gcloud dns managed-zones create $${ZONE_NAME} --dns-name='$(DNS_DOMAIN).' --description='managed zone for $(DNS_DOMAIN)'

.PHONY: dns-delete-managed-zone
dns-delete-managed-zone:
	ZONE_NAME=$(shell echo "$(DNS_DOMAIN)" | sed 's/\./-/')-zone
	gcloud dns managed-zones delete $${ZONE_NAME}

.PHONY: dns-record-sets-list
dns-record-sets-list:
	ZONE_NAME=$(shell echo "$(DNS_DOMAIN)" | sed 's/\./-/')-zone
	gcloud dns record-sets list --zone=$${ZONE_NAME}

.PHONY: dns-record-sets-create
dns-record-sets-create:
	ZONE_NAME=$(shell echo "$(DNS_DOMAIN)" | sed 's/\./-/')-zone
	if ! gcloud dns record-sets list --zone=$${ZONE_NAME} --format="value(type)" | grep -oP '^A$$'
	then
	echo 'create A record'
	# get the instance IP address
	GCE_IP=$(shell gcloud compute instances describe $(GCE_INSTANCE_NAME) --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
	echo "instance IP address: $${GCE_IP}"
	gcloud dns record-sets create $(DNS_DOMAIN) \
			--rrdatas=$${GCE_IP} \
			--ttl=300 \
			--type=A \
			--zone=$${ZONE_NAME}
	fi
	if ! gcloud dns record-sets list --zone=$${ZONE_NAME} --format="value(type)" | grep -oP '^CNAME$$'
	then
	echo 'create CNAME record'
	gcloud dns record-sets create www.$(DNS_DOMAIN) \
			--rrdatas='$(DNS_DOMAIN).' \
			--ttl=300 \
			--type=CNAME \
			--zone=$${ZONE_NAME}
	fi

.PHONY: dns-record-sets-delete
dns-record-sets-delete:
	ZONE_NAME=$(shell echo "$(DNS_DOMAIN)" | sed 's/\./-/')-zone
	if gcloud dns record-sets list --zone=$${ZONE_NAME} --format="value(type)" | grep -oP '^A$$'
	then
	gcloud dns record-sets delete $(DNS_DOMAIN) --type=A --zone=$${ZONE_NAME}
	fi

.PHONY: iam-service-account-info
iam-service-account-info:
	gcloud iam service-accounts list
	gcloud projects get-iam-policy $(GCE_PROJECT_ID)

.PHONY: iam-service-account-default
iam-service-account-default:
	gcloud iam service-accounts list --format="value(email)" | grep -oP '^.+@developer.+$$'

.PHONY: iam-service-account-dns-role
iam-service-account-dns-role:
	GCE_SERVICE_ACCOUNT=$(shell gcloud iam service-accounts list --format="value(email)" | grep -oP '^.+@developer.+$$')
	echo $${GCE_SERVICE_ACCOUNT}
	gcloud projects add-iam-policy-binding $(GCE_PROJECT_ID) \
		--member serviceAccount:$${GCE_SERVICE_ACCOUNT} \
		--role roles/dns.admin

.PHONY: iam-service-account-remove-dns-role
iam-service-account-remove-dns-role:
	GCE_SERVICE_ACCOUNT=$(shell gcloud iam service-accounts list --format="value(email)" | grep -oP '^.+@developer.+$$')
	gcloud projects add-iam-policy-binding $(GCE_PROJECT_ID) \
		--member serviceAccount:$${GCE_SERVICE_ACCOUNT} \
		--role roles/dns.admin


	# gcloud iam service-accounts list --format="value(email)" | tee .secrets/gcloud-iam-service.accounts

.PHONY: iam-service-account-key
iam-service-account-key:
	mkdir -p .secrets
	grep -oP '.secrets' .gitignore  # fail if secrets not in .gitgnore file.
	GCE_SERVICE_ACCOUNT=$(shell gcloud iam service-accounts list --format="value(email)" | grep -oP '^.+@developer.+$$')
	if [ ! -f .secrets/$(GCE_KEY) ]
	then
	gcloud iam service-accounts keys create .secrets/$(GCE_KEY)--iam-account=$${GCE_SERVICE_ACCOUNT}
	fi
	# gcloud compute scp .secrets/gcpkey.json $(GCE_NAME):/home/core/.secrets/gcpkey.json
	# gcloud iam service-accounts keys list --iam-account=$${GCE_SERVICE_ACCOUNT}

.PHONY: certs-dry-run
certs-dry-run:
	cat .secrets/$(GCE_KEY) | 
	$(Gcmd) 'cat - | tee | \
		sudo podman run --rm --name certbot --interactive --mount $(MountLetsencrypt) -e "GOOGLE_CLOUD_PROJECT=$(GCE_PROJECT_ID)"  \
		--entrypoint "[\"sh\",\"-c\"]" docker.io/certbot/dns-google \
		"cat - > /home/$(GCE_KEY) && \
		chmod go-rwx /home/$(GCE_KEY) && \
		certbot certonly \
		--verbose \
		--cert-name $(CERT_COMMON_NAME) \
		--dry-run \
		--dns-google \
		--email $(shell git config user.email) \
		--dns-google-credentials /home/$(GCE_KEY) \
	  --force-renewal \
		--agree-tos \
		--domains $(CERT_DNS_DOMAINS) \
	  "'

# after we have created volumes
# and after we have set up dns ... and obtained a gcpkey
# we can
# use docker.io/certbot/dns-google image to
# get certificates into our remote letsencrypt volume
# then import remote letsencrypt volume into local letsencrypt volume
# then run 'certbot certificates' and put output into local _deploy/certificates.txt 
.PHONY: certs-renew
certs-renew:
	cat .secrets/$(GCE_KEY) | 
	$(Gcmd) 'cat - | tee | \
		sudo podman run --rm --name certbot --interactive --mount $(MountLetsencrypt) -e "GOOGLE_CLOUD_PROJECT=$(GCE_PROJECT_ID)"  \
		--entrypoint "[\"sh\",\"-c\"]" docker.io/certbot/dns-google \
		"cat - > /home/$(GCE_KEY) && \
		chmod go-rwx /home/$(GCE_KEY) && \
		certbot certonly \
		--cert-name $(CERT_COMMON_NAME) \
		--force-renew \
		--non-interactive \
		--dns-google \
		--dns-google-credentials /home/$(GCE_KEY) \
		--email $(shell git config user.email) \
		--agree-tos \
	  --expand \
		--domains $(CERT_DNS_DOMAINS) \
	  "'
	# once we have obtained certs we can import certs into local letsencrypt volume
	$(Gcmd) 'sudo podman volume export letsencrypt' |  podman volume import letsencrypt -
	$(Gcmd) 'sudo podman run --rm --name certbot --mount $(MountLetsencrypt) docker.io/certbot/dns-google certificates' |
	tee _deploy/certificates.txt

# GCE CERTS
# after we have created volumes
# and after we have set up dns ... and obtained a gcpkey
# we can
# use docker.io/certbot/dns-google image to
# get certificates into our remote letsencrypt volume
# then import remote letsencrypt volume into local letsencrypt volume
# then run 'certbot certificates' and put output into local _deploy/certificates.txt 
# after we have our certs in the local letsencypt volume 
# then _deploy/certificates.txt will contain paths to the certs
# so we write these to src/proxy/conf/certificates.conf
# and adjust src/proxy/conf/proxy.conf so we only serve TLS
# once we have obtained certs run 'certbot certificates' and put output into local _deploy/certificates.txt
.PHONY: _deploy/certificates.txt
_deploy/certificates.txt:
	$(Gcmd) 'sudo podman run --rm --name certbot --mount $(MountLetsencrypt) docker.io/certbot/dns-google certificates' |
	tee _deploy/certificates.txt
 
.PHONY: proxy-after-certs
proxy-after-certs:
	echo "ssl_certificate  $(shell grep -oP 'Certificate Path: \K.+' $<);" > src/proxy/conf/certificates.conf
	echo "ssl_certificate_key  $(shell grep -oP 'Private Key Path: \K.+' $<);" >> src/proxy/conf/certificates.conf
	$(DASH)
	cat src/proxy/conf/certificates.conf
	$(DASH)
	echo ' TASK: modify src/proxy/conf/proxy.conf '
	sed -i 's/ include basic.conf;/#include basic.conf;/' src/proxy/conf/proxy.conf
	sed -i 's/#include tls_server.conf;/include tls_server.conf;/' src/proxy/conf/proxy.conf
	sed -i 's/#include redirect.conf;/include redirect.conf;/' src/proxy/conf/proxy.conf
	$(DASH)
	cat src/proxy/conf/proxy.conf
	$(DASH)
	echo 'CHECK! "include basic.conf" is commented out'
	echo 'CHECK! "include redirect.conf" is NOT commented out'
	echo 'CHECK! "include tls_server.conf" is NOT commented out'
	echo 'FOLLOW UP TASK: run `make confs` to add the changed to the container proxy-conf volume'
	echo 'NOTE! pod will now only serve HTTPS and HTTP will be redirected to HTTPS'
	echo 'FOLLOW UP TASK: run `make gce-volumes-import` to import tarred _deploy volumes into remote volumes'

.PHONY: check-proxy-certs
check-proxy-certs:
	curl -v https://$(DNS_DOMAIN)/xqerl 2>&1 | grep -oP 'Host: .+'
	curl -v https://$(DNS_DOMAIN)/xqerl 2>&1 | grep -oP 'subject: .+'
	curl -v https://$(DNS_DOMAIN)/xqerl 2>&1 | grep -oP 'subjectAltName: .+'
	echo -n 'openssl connect: '
	openssl s_client -connect $(DNS_DOMAIN):443 </dev/null 2>/dev/null | 
	openssl x509 -inform pem -text | grep -oP 'DNS:.+'
	echo && $(DASH)

.PHONY: certs-volume-export
 certs-volume-export:
	podman volume export letsencrypt > _deploy/letsencrypt.tar

