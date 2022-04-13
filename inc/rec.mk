
.PHONY: rec1
rec1:
	echo '##[  $@  ]##'
	asciinema rec src/assets/casts/xqerl-up-and-flying.cast \
		--overwrite --title='xqerl up and flying' \
		--command="$(MAKE) rec-xqerl-up-and-flying"

.PHONY: rec-xqerl-up-and-flying
rec-xqerl-up-and-flying:
	echo '# Xqerl pronounced 'squirrel', is a xQuery 3.1 application server. ' | pv -qL 10
	echo '# 1. clone this repo and cd into the glider directory' | pv -qL 10
	echo '# 2. pull docker images' | pv -qL 10
	make images
	echo '# 3. bring the pod up with two running containers'
	echo '#  - 'or' container: nginx as a reverse proxy'
	echo '#  - 'xq' container: xqerl xQuery app server and database'
	$(DASH)
	make up && sleep 5

PHONY: play
play:
	@asciinema play src/assets/casts/xqerl-up-and-flying.cast

.PHONY: upload
upload:
	asciinema upload src/assets/casts/xqerl-up-and-flying.cast
