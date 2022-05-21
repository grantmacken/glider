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
# comma separated list
GCE_DOMAINS ?= 

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
	$(Gcmd) 'podman image ls' > _deploy/image.list
	grep -oP 'xqerl(.+)$(XQERL_VER)' _deploy/image.list || $(Gcmd) 'podman pull $(XQ)'
	grep -oP 'podx-openresty(.+)$(PROXY_VER)' _deploy/image.list || $(Gcmd) 'podman pull $(OR)'
	grep -oP 'docker.io/certbot/dns-google' _deploy/image.list || $(Gcmd) 'podman pull docker.io/certbot/dns-google'
	$(Gcmd) 'sudo podman image ls'
	$(DASH)

.PHONY: gce-clean
gce-clean:
	echo "##[ $(@) ]##"
	 $(Gcmd) 'podman pod stop --all' || true
	 $(Gcmd) 'podman pod prune --force' || true
	$(DASH)

# GCE VOLUMES
#
.PHONY: gce-volumes ## gce create docker volumes
gce-volumes:
	$(Gcmd) \
		'podman volume exists xqerl-code || podman volume create xqerl-code; \
		podman volume exists xqerl-database || podman volume create xqerl-database; \
		podman volume exists static-assets || podman volume create static-assets; \
		podman volume exists proxy-conf ||  podman volume create proxy-conf; \
		podman volume exists letsencrypt || podman volume create letsencrypt; \
		podman volume ls '

# after we have created volumes we can import from our local dev envronment
# 1. static-assets volume
# 2. proxy-config volumes
# 3. xqerl-database
# 3. xqerl-code


# 1. stop the pod: 
# 2. export the code volume
# 3. export the data volume
# 4. deploy the volumes on GCE
# 4. re service: 
# NOTE: code and data stuff might be written on kill so we stop the service first 
# NOTE: proxy-conf and static-assets are file-system files that are already tarred 
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
	$(Gcmd) 'podman pod prune' || true
	$(Gcmd) 'podman ps --all --pod' | tee _deploy/up.txt

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
		--mount $(MountProxyConf) \
		--tz=$(TIMEZONE) \
		--detach $(OR)'
	$(Gcmd) 'podman ps -a --pod' | grep -oP '$(OR)(.+)$$'
	fi

.PHONY: remote-service
remote-service: 
	echo "##[ $(@) ]##"
	$(Gcmd) 'loginctl enable-linger core'
	$(Gcmd) 'mkdir -v -p ./.config/systemd/user'
	$(Gcmd) 'podman generate systemd --files --name $(POD)'
	$(Gcmd) 'cat pod-podx.service > ./.config/systemd/user/pod-podx.service'
	$(Gcmd) 'cat container-xq.service > ./.config/systemd/user/container-xq.service'
	$(Gcmd) 'cat container-or.service |
	sed "s/After=pod-podx.service/After=pod-podx.service container-xq.service/g" | \
		sed "18 i ExecStartPre=/usr/bin/sleep 2" > ./.config/systemd/user/container-or.service'
	$(Gcmd) 'systemctl --user daemon-reload'
	$(Gcmd) 'systemctl --user is-enabled container-xq.service &>/dev/null || systemctl --user enable container-xq.service'
	$(Gcmd) 'systemctl --user is-enabled container-or.service &>/dev/null || systemctl --user enable container-or.service'
	$(Gcmd) 'systemctl --user is-enabled pod-podx.service &>/dev/null || systemctl --user enable pod-podx.service'
	
	.PHONY: remote-service-clean
remote-service-clean: 
	$(Gcmd) 'systemctl --user stop pod-podx.service' || true
	$(Gcmd) 'systemctl --user disable container-xq.service' || true
	$(Gcmd) 'systemctl --user disable container-or.service' || true
	$(Gcmd) 'systemctl --user disable pod-podx.service' || true
	$(Gcmd) 'rm -f ./.config/systemd/user/container-or.service ./.config/systemd/user/container-xq.service ./.config/systemd/user/pod-podx.service'
	$(Gcmd) 'systemctl --user daemon-reload'


