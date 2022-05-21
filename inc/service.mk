.PHONY: service
service: 
	echo "##[ $(@) ]##"
	#loginctl enable-linger $(USER) || true
	mkdir -p $(HOME)/.config/systemd/user
	rm -f *.service
	podman generate systemd --files --name $(POD) 
	@cat pod-podx.service > $(HOME)/.config/systemd/user/pod-podx.service
	cat container-xq.service > $(HOME)/.config/systemd/user/container-xq.service
	cat container-or.service | 
	sed 's/After=pod-podx.service/After=pod-podx.service container-xq.service/g' |
	sed '18 i ExecStartPre=/bin/sleep 2' | tee $(HOME)/.config/systemd/user/container-or.service
	@systemctl --user daemon-reload
	@systemctl --user is-enabled container-xq.service &>/dev/null || systemctl --user enable container-xq.service
	@systemctl --user is-enabled container-or.service &>/dev/null || systemctl --user enable container-or.service
	@systemctl --user is-enabled pod-podx.service &>/dev/null || systemctl --user enable pod-podx.service
	rm -f *.service
	#reboot

# Note systemctl should only be used on the pod unit and one should not start 

.PHONY: service-start
service-start: 
	systemctl --user start pod-podx.service
	$(DASH)
	systemctl --user --no-pager status pod-podx.service
	$(DASH)
	podman ps -a --pod
	$(DASH)

.PHONY: service-stop
service-stop:
	@systemctl --user stop  pod-podx.service || true

.PHONY: service-status
service-status:
	echo "##[ $(@) ]##"
	systemctl --user --no-pager status pod-podx.service
	$(DASH)
	# journalctl --no-pager -b CONTAINER_NAME=or
	$(DASH)

.PHONY: journal
journal:
	journalctl --user --no-pager -b CONTAINER_NAME=xq

.PHONY: service-clean
service-clean: 
	@systemctl --user stop pod-podx.service || true
	@systemctl --user disable container-xq.service || true
	@systemctl --user disable container-or.service || true
	@systemctl --user disable pod-podx.service || true
	pushd $(HOME)/.config/systemd/user/
	rm -f container-or.service container-xq.service pod-podx.service
	popd
	@systemctl --user daemon-reload
