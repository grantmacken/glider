GCE_PROJECT_ID ?= glider-1
GCE_REGION ?= australia-southeast2
GCE_ZONE ?= australia-southeast2-c
GCE_INSTANCE_NAME ?= instance-3
GCE_MACHINE_TYPE ?= e2-small
GCE_IMAGE_FAMILY ?= fedora-coreos-next
GCE_NAME ?= core@$(GCE_INSTANCE_NAME)
GCE_DNS_ZONE ?= glider-zone
GCE_KEY := iam-service-account-key.json
FCOS_HOME := /var/home/core
CERT_COMMON_NAME ?= gmack.nz 
# comma separated list
CERT_DNS_DOMAINS ?= gmack.nz,markup.nz



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

.PHONY: remote-image-prune
remote-image-prune:
	echo "##[ $(@) ]##"
	$(Gcmd) 'podman rm --force --all'
	$(Gcmd) 'podman image prune --force --all'
	$(Gcmd) 'podman image ls'

.PHONY: remote-images ## gce pull docker images
remote-images:
	echo "##[ $(@) ]##"
	$(Gcmd) 'podman image ls' > _deploy/image.list
	grep -oP 'xqerl(.+)$(XQERL_VER)' _deploy/image.list || $(Gcmd) 'podman pull $(XQ)'
	grep -oP 'podx-openresty(.+)$(PROXY_VER)' _deploy/image.list || $(Gcmd) 'podman pull $(OR)'
	# grep -oP 'docker.io/certbot/dns-google' _deploy/image.list || $(Gcmd) 'podman pull docker.io/certbot/dns-google'
	$(Gcmd) 'podman image ls'
	$(DASH)

.PHONY: remote-clean
remote-clean:
	echo "##[ $(@) ]##"
	 $(Gcmd) 'podman pod stop --all' || true
	 $(Gcmd) 'podman pod prune --force' || true
	$(DASH)

# GCE VOLUMES
#
.PHONY: remote-volumes ## gce create docker volumes
remote-volumes:
	$(Gcmd) \
		'podman volume exists xqerl-code || podman volume create xqerl-code; \
		podman volume exists xqerl-database || podman volume create xqerl-database; \
		podman volume exists static-assets || podman volume create static-assets; \
		podman volume exists proxy ||  podman volume create proxy; \
		podman volume exists letsencrypt || podman volume create letsencrypt; \
		podman volume ls '

# after we have created volumes we can import from our local dev envronment
# 1. static-assets volume
# 2. proxy volumes
# 3. xqerl-database
# 3. xqerl-code


# 1. stop the pod: 
# 2. export the code volume
# 3. export the data volume
# 4. deploy the volumes on GCE
# 4. re service: 
# NOTE: code and data stuff might be written on kill so we stop the service first 
# NOTE: proxy and static-assets are file-system files that are already tarred 
.PHONY: deploy
deploy: service-stop data-volume-export code-volume-export deploy-volumes service-start

.PHONY: deploy-volumes
deploy-volumes: $(patsubst _deploy/%.tar,_deploy/status/%.txt,$(wildcard _deploy/*.tar))

_deploy/status/%.txt: _deploy/%.tar
	[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo '## $(basename $(notdir $<)) ##'
	gcloud compute scp $(<) $(GCE_NAME):/home/core/$(notdir $<)
	$(Gcmd) 'podman volume import $(basename $(notdir $<)) /home/core/$(notdir $<)' > $@

.PHONY: remote-pod-start
remote-pod-start: 
	echo "##[ $(@) ]##"
	echo -n ' - check pod-$(POD) : '
	if $(Gcmd) 'systemctl --user is-enabled pod-$(POD)'
	then
	# $(Gcmd) 'systemctl --user daemon-reload'
	$(Gcmd) 'systemctl --user restart pod-$(POD)'
	else
	$(Gcmd) 'podman pod start $(POD)' || true
	echo 'NOT enabled'
	fi
	$(Gcmd) 'podman ps --all --pod'

.PHONY: remote-pod-stop
remote-pod-stop:
	echo "##[ $(@) ]##"
	$(Gcmd) 'if systemctl --user is-enabled pod-$(POD); then \
		systemctl --user stop pod-$(POD); \
		else \
		podman pod stop $(POD);
		fi && podman ps --all --pod '

.PHONY: remote-pod-status
remote-pod-status:
	echo "##[ $(@) ]##"
	# $(Gcmd) 'loginctl show-user  core'
	# $(DASH)
	# $(Gcmd) 'systemctl --no-pager --user status pod-$(POD)'
	# $(DASH)
	# $(Gcmd) 'journalctl --no-pager  --user-unit=pod-$(POD)'
	# $(DASH)
	 $(Gcmd) 'journalctl --no-pager -n1 -r -o cat --user-unit=container-or'
	$(DASH)
	$(Gcmd) 'journalctl --no-pager -n3 -r -o cat --user-unit=container-xq'
	# $(Gcmd) 'journalctl --no-pager -r -n10 --since "1 hour ago" -o json --user-unit=container-xq' | jq '.MESSAGE'
	$(DASH)

##############################
## REMOTE UP
##############################

.PHONY: remote-up
remote-up: remote-or-up
	echo "##[ $(@) ]##"
	$(Gcmd) 'podman ps --all --pod' | tee _deploy/up.txt

.PHONY: remote-down
remote-down:
	echo "##[ $(@) ]##"
	$(Gcmd) 'podman pod stop $(POD)' || true
	# $(Gcmd) 'podman pod prune' || true
	# $(Gcmd) 'podman ps --all --pod' | tee _deploy/up.txt

.PHONY: remote-rootless
remote-rootless:
	$(Gcmd) 'grep -q "net.ipv4.ip_unprivileged_port_start=80" /etc/sysctl.conf || echo "net.ipv4.ip_unprivileged_port_start=80" | sudo tee -a /etc/sysctl.conf' 
	$(Gcmd) 'sudo sysctl -w net.ipv4.ip_unprivileged_port_start=80'
	# $(Gcmd) 'loginctl enable-linger core'

.PHONY: remote-pod-up
remote-pod-up: remote-rootless
	echo "##[ $(@) ]##"
	$(Gcmd) 'podman pod exists $(POD) || \
		podman pod create --name $(POD) -p 80:80 -p 443:443 --network podman'

.PHONY: remote-xq-up
remote-xq-up: remote-pod-up
	if ! $(Gcmd) 'podman ps -a' | grep -q $(XQ)
	then
	$(Gcmd) 'podman run --name xq --pod $(POD) \
		--mount $(MountCode) --mount $(MountData) --mount $(MountAssets) \
		--tz=$(TIMEZONE) \
		--detach $(XQ)'
	sleep 1
	$(Gcmd) 'podman ps -a --pod' | grep -oP '$(XQ)(.+)$$'
	sleep 1
	$(Gcmd) 'podman exec xq xqerl eval "application:ensure_all_started(xqerl)."'
	fi

.PHONY: remote-or-up
remote-or-up: remote-xq-up
	echo "##[ $(@) ]##"
	if ! $(Gcmd) 'podman ps -a' | grep -q $(OR)
	then
	$(Gcmd) 'podman run --name or --pod $(POD) \
		--mount $(MountLetsencrypt) \
		--mount $(MountProxy) \
		--tz=$(TIMEZONE) \
		--detach $(OR)'
	$(Gcmd) 'podman ps -a --pod' | grep -oP '$(OR)(.+)$$'
	fi

.PHONY: remote-service-enable
remote-service-enable: 
	echo "##[ $(@) ]##"
	$(Gcmd) 'loginctl enable-linger core'
	$(Gcmd) 'mkdir -v -p ./.config/systemd/user'
	$(Gcmd) 'podman generate systemd --files --name $(POD)'
	$(Gcmd) 'cat pod-podx.service > ./.config/systemd/user/pod-podx.service'
	$(Gcmd) 'cat container-xq.service > ./.config/systemd/user/container-xq.service'
	$(Gcmd) 'cat container-or.service |
	sed "s/After=pod-podx.service/After=pod-podx.service container-xq.service/g" | 
	sed "18 i ExecStartPre=/usr/bin/sleep 2" > ./.config/systemd/user/container-or.service'
	# $(Gcmd) 'systemctl --user daemon-reload'
	$(Gcmd) 'systemctl --user is-enabled container-xq.service &>/dev/null || systemctl --user enable container-xq.service'
	$(Gcmd) 'systemctl --user is-enabled container-or.service &>/dev/null || systemctl --user enable container-or.service'
	$(Gcmd) 'systemctl --user is-enabled pod-podx.service &>/dev/null || systemctl --user enable pod-podx.service'

.PHONY: remote-status
remote-status:
	echo "##[ $(@) ]##"
	$(Gcmd) 'systemctl --user --no-pager status pod-podx.service' || true
	$(DASH)
	echo -n 'container xq status: '
	$(Gcmd) 'podman inspect -f "{{.State.Status}}" xq' || true
	echo -n 'container or status: '
	$(Gcmd) 'podman inspect -f "{{.State.Status}}" or' || true
	$(DASH)

.PHONY: remote-start
remote-start:
	echo "##[ $(@) ]##"
	$(Gcmd) 'systemctl --user start  pod-podx.service ' || true
	$(DASH)
	sleep 2
	echo -n 'container xq status: '
	$(Gcmd) 'podman inspect -f "{{.State.Status}}" xq' || true
	sleep 2
	echo -n 'container or status: '
	$(Gcmd) 'podman inspect -f "{{.State.Status}}" or' || true
	$(DASH)

.PHONY: remote-stop
remote-stop:
	echo "##[ $(@) ]##"
	$(Gcmd) 'systemctl --user stop pod-podx.service ' || true
	$(DASH)
	sleep 2
	echo -n 'container xq status: '
	$(Gcmd) 'podman inspect -f "{{.State.Status}}" xq' || true
	sleep 2
	echo -n 'container or status: '
	$(Gcmd) 'podman inspect -f "{{.State.Status}}" or' || true
	$(DASH)

.PHONY: remote-restart
remote-restart:
	echo "##[ $(@) ]##"
	$(Gcmd) 'systemctl --user restart pod-podx.service ' || true
	$(DASH)
	sleep 2
	echo -n 'container xq status: '
	$(Gcmd) 'podman inspect -f "{{.State.Status}}" xq' || true
	sleep 2
	echo -n 'container or status: '
	$(Gcmd) 'podman inspect -f "{{.State.Status}}" or' || true
	$(DASH)
	
.PHONY: remote-service-disable
remote-service-clean: 
	$(Gcmd) 'systemctl --user stop pod-podx.service' || true
	$(Gcmd) 'systemctl --user disable container-xq.service' || true
	$(Gcmd) 'systemctl --user disable container-or.service' || true
	$(Gcmd) 'systemctl --user disable pod-podx.service' || true
	$(Gcmd) 'rm -f ./.config/systemd/user/container-or.service ./.config/systemd/user/container-xq.service ./.config/systemd/user/pod-podx.service'
	$(Gcmd) 'systemctl --user daemon-reload'

##############################
## GCE DNS section
## prefix dns
##############################
.PHONY: dns-info
dns-info: 
	echo "#[ $@  managed zones ]#"
	ZONE_NAME=$(shell echo "$(DOMAIN)" | sed 's/\./-/')-zone
	gcloud dns managed-zones list
	$(DASH)
	gcloud dns managed-zones describe $${ZONE_NAME}
	$(DASH)


dns-lookup:
ifneq '$(DOMAIN)' 'localhost'
	echo $(DOMAIN)
	echo "#[ $@  DOMAIN: $(DOMAIN) ]#"
	echo 'Lookup Name Servers:'
	dig +short NS $(DOMAIN)
	$(DASH)
	echo 'lookup via Name Server:'
	dig $(DOMAIN) @$$(dig +short NS $(DOMAIN) | head -1) +noall +answer 
	# dig $(DOMAIN) @$(shell dig +short NS $(DOMAIN) | tail -1)
	# dig $(DOMAIN) +nostats +nocomments +nocmd
	# $(DASH)
	echo -n 'IP Address: '
	dig $(DOMAIN) +short
	echo -n 'Reverse lookup: '
	host $$(dig $(DOMAIN) +short)
	$(DASH)
endif

.PHONY: dns-create-managed-zone
dns-create-managed-zone:
	ZONE_NAME=$(shell echo "$(DOMAIN)" | sed 's/\./-/')-zone
	gcloud dns managed-zones create $${ZONE_NAME} --dns-name='$(DOMAIN).' --description='managed zone for $(DOMAIN)'

.PHONY: dns-delete-managed-zone
dns-delete-managed-zone:
	ZONE_NAME=$(shell echo "$(DOMAIN)" | sed 's/\./-/')-zone
	gcloud dns managed-zones delete $${ZONE_NAME}

.PHONY: dns-record-sets-list
dns-record-sets-list:
	ZONE_NAME=$(shell echo "$(DOMAIN)" | sed 's/\./-/')-zone
	gcloud dns record-sets list --zone=$${ZONE_NAME}

.PHONY: dns-record-sets-create
dns-record-sets-create:
	ZONE_NAME=$(shell echo "$(DOMAIN)" | sed 's/\./-/')-zone
	if ! gcloud dns record-sets list --zone=$${ZONE_NAME} --format="value(type)" | grep -oP '^A$$'
	then
	echo 'create A record'
	# get the instance IP address
	GCE_IP=$$(gcloud compute instances describe $(GCE_INSTANCE_NAME) --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
	echo "instance IP address: $${GCE_IP}"
	gcloud dns record-sets create $(DOMAIN) \
			--rrdatas=$${GCE_IP} \
			--ttl=300 \
			--type=A \
			--zone=$${ZONE_NAME}
	fi
	if ! gcloud dns record-sets list --zone=$${ZONE_NAME} --format="value(type)" | grep -oP '^CNAME$$'
	then
	echo 'create CNAME record'
	gcloud dns record-sets create www.$(DOMAIN) \
			--rrdatas='$(DOMAIN).' \
			--ttl=300 \
			--type=CNAME \
			--zone=$${ZONE_NAME}
	fi

.PHONY: dns-record-sets-delete
dns-record-sets-delete:
	ZONE_NAME=$(shell echo "$(DOMAIN)" | sed 's/\./-/')-zone
	if gcloud dns record-sets list --zone=$${ZONE_NAME} --format="value(type)" | grep -oP '^A$$'
	then
	gcloud dns record-sets delete $(DOMAIN) --type=A --zone=$${ZONE_NAME}
	fi
	
##############################
## iam-service-account section
##############################

.PHONY: iam-service-account-info
iam-service-account-info:
	gcloud iam service-accounts list
	gcloud projects get-iam-policy $(GCE_PROJECT_ID)

.PHONY: iam-service-account-default
iam-service-account-default:
	gcloud iam service-accounts list --format="value(email)" | grep -oP '^.+@developer.+$$'

.PHONY: iam-service-account-dns-role
iam-service-account-dns-role:
	GCE_SERVICE_ACCOUNT=$$(gcloud iam service-accounts list --format="value(email)" | grep -oP '^.+@developer.+$$')
	echo $${GCE_SERVICE_ACCOUNT}
	gcloud projects add-iam-policy-binding $(GCE_PROJECT_ID) \
		--member serviceAccount:$${GCE_SERVICE_ACCOUNT} \
		--role roles/dns.admin

.PHONY: iam-service-account-remove-dns-role
iam-service-account-remove-dns-role:
	GCE_SERVICE_ACCOUNT=$$(gcloud iam service-accounts list --format="value(email)" | grep -oP '^.+@developer.+$$')
	gcloud projects add-iam-policy-binding $(GCE_PROJECT_ID) \
		--member serviceAccount:$${GCE_SERVICE_ACCOUNT} \
		--role roles/dns.admin


	# gcloud iam service-accounts list --format="value(email)" | tee .secrets/gcloud-iam-service.accounts

.PHONY: iam-service-account-key
iam-service-account-key:
	mkdir -p .secrets
	grep -oP '.secrets' .gitignore  # fail if secrets not in .gitgnore file.
	GCE_SERVICE_ACCOUNT=$$(gcloud iam service-accounts list --format="value(email)" | grep -oP '^.+@developer.+$$')
	if [ ! -f .secrets/$(GCE_KEY) ]
	then
	gcloud iam service-accounts keys create .secrets/$(GCE_KEY)--iam-account=$${GCE_SERVICE_ACCOUNT}
	fi
	# gcloud compute scp .secrets/gcpkey.json $(GCE_NAME):/home/core/.secrets/gcpkey.json
	# gcloud iam service-accounts keys list --iam-account=$${GCE_SERVICE_ACCOUNT}
	#
	#
##############################
## letencypt section
## certs section
##############################

.PHONY: certbot-dry-run
certbot-dry-run:
	cat .secrets/$(GCE_KEY) | 
	$(Gcmd) 'cat - | tee | \
		podman run --rm --name certbot --interactive --mount $(MountLetsencrypt) -e "GOOGLE_CLOUD_PROJECT=$(GCE_PROJECT_ID)"  \
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
.PHONY: certbot-renew
certbot-renew:
	cat .secrets/$(GCE_KEY) | 
	$(Gcmd) 'cat - | tee | \
		podman run --rm --name certbot --interactive --mount $(MountLetsencrypt) -e "GOOGLE_CLOUD_PROJECT=$(GCE_PROJECT_ID)"  \
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
	$(Gcmd) 'podman volume export letsencrypt' |  podman volume import letsencrypt -
	$(Gcmd) 'podman run --rm --name certbot --mount $(MountLetsencrypt) docker.io/certbot/dns-google certificates' |
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
	$(Gcmd) 'podman run --rm --name certbot --mount $(MountLetsencrypt) docker.io/certbot/dns-google certificates' |
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
	curl -v https://$(DOMAIN)/xqerl 2>&1 | grep -oP 'Host: .+'
	curl -v https://$(DOMAIN)/xqerl 2>&1 | grep -oP 'subject: .+'
	curl -v https://$(DOMAIN)/xqerl 2>&1 | grep -oP 'subjectAltName: .+'
	echo -n 'openssl connect: '
	openssl s_client -connect $(DOMAIN):443 </dev/null 2>/dev/null | 
	openssl x509 -inform pem -text | grep -oP 'DNS:.+'
	echo && $(DASH)

.PHONY: certs-volume-export
 certs-volume-export:
	 podman volume export letsencrypt > _deploy/letsencrypt.tar

