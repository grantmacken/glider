
.PHONY: rec1
rec1:
	echo '##[  $@  ]##'
	asciinema rec src/assets/casts/xqerl-up-and-flying.cast \
		--overwrite --title='xqerl up and flying' \
		--command="$(MAKE) rec-xqerl-up-and-flying"

.PHONY: rec2
rec2:
	echo '##[  $@  ]##'
	asciinema rec src/assets/casts/xqerl-as-a-service.cast \
		--overwrite --title='xqerl as a service' \
		--command="$(MAKE) rec-xqerl-as-a-service"

.PHONY: rec-xqerl-as-a-service
rec-xqerl-as-a-service:
	echo '# Xqerl pronounced 'squirrel', is a XQuery 3.1 application server. ' | pv -qL 7
	echo '# We run xqerl with nginx acting as a xqerl reverse proxy in a podman pod' | pv -qL 7
	echo '# which we have named "podx"' | pv -qL 7
	echo '# We can set "podx" to run as a systemd **user** service' | pv -qL 7
	echo '# Once the service is enabled on a reboot, the pod-podx.service' 
	echo '# will automatically be available' | pv -qL 7
	echo '# --------------------------------------------------------------------'
	echo '> make service-enable ' | pv -qL 7
	make service-enable
	echo '#  Once the pod-podx service is enabled we can reboot or' 
	echo '# - to manually start the sevice' | pv -qL 7
	echo '> make service-start' | pv -qL 7
	make service-start
	echo '# - to check the service status' | pv -qL 7
	echo '> make service-status' | pv -qL 7
	make service-status
	echo '# - to stop the service service' | pv -qL 7
	echo '> make service-stop' | pv -qL 7
	make service-stop
	echo '# Lets restart the service' | pv -qL 7
	echo '> make service-start' | pv -qL 7
	make service-start
	echo '# We can use the podman cli to ' | pv -qL 7
	echo '# - to list containers running in the pod' | pv -qL 7
	echo '> podman ps --pod --all' | pv -qL 7
	podman ps --pod --all
	echo '# - to see what resource are being used in our pod' | pv -qL 7
	echo '> podman ps --pod --all' | pv -qL 7
	podman stats --no-stream
	echo '# - to display the running processes of the container xq' | pv -qL 7
	echo '> podman top xq' | pv -qL 7
	podman top xq
	echo '# - to display log output for container xq' | pv -qL 7
	echo '> podman logs --tail 5 xq' | pv -qL 7
	podman logs --tail 5 xq
	echo '# -------------------------------------------------------------------- '



.PHONY: rec-xqerl-up-and-flying
rec-xqerl-up-and-flying:
	echo '# Xqerl pronounced 'squirrel', is a xQuery 3.1 application server. ' | pv -qL 7
	echo '# 1. clone this repo and cd into the glider directory' | pv -qL 7
	echo '# 2. pull docker images' | pv -qL 7
	make images
	echo '# 3. bring the pod up with two running containers'
	echo '#  - 'or' container: nginx as a reverse proxy'
	echo '#  - 'xq' container: xqerl xQuery app server and database'
	$(DASH)
	make up && sleep 5

PHONY: play
play:
	@asciinema play src/assets/casts/xqerl-as-a-service.cast

.PHONY: upload
upload:
	asciinema upload src/assets/casts/xqerl-as-a-service.cast
