# Getting Started

1. clone this repo and cd into the cloned dir
2. enable rootless to operate on port 80 and above
3. bring the pod up with two running containers
 - 'or' container: nginx as a reverse proxy
 - 'xq' container: the xqerl application
5. view localhost site 

```
gh repo clone grantmacken/glider
cd glider
make rootless
make up
```

If you see the 'You are now flying xqerl' 
you know the pod is running and in the pod nginx is acting as a 
reverse proxy for the xqerl XQuery application server.

## On Rootlessness

In both our local development environment, and on our remote internet facing cloud instance, 
we are going to run a podman pod without root privileges.  
Good security reasons why we should run our containers this way are outlined in the Steven Ellis [rootless containers with Podman](https://www.youtube.com/watch?v=Emt4rpjHdz0) video on youtube, so I won't repeat them here.

A [shortcoming of rootless podman](https://github.com/containers/podman/blob/main/rootless.md) 
is that podman can not create containers that bind to ports < 1024,
unless you explictly tell your system to to so.

Since our published pod ports will be on port 80 and port 433, 
we need to implement the suggested workaround. The same workaround is also used if
you want to expose a privileged port in a [rootless docker setup](https://docs.docker.com/engine/security/rootless/#exposing-privileged-ports)

I have created a Make target `make rootless` which will enable the pod to bind to port 80 and above.
Note: The target requires us to use super do `sudo` .
The `make rootless` target is an alias for following shell script.

```shell
grep -q 'net.ipv4.ip_unprivileged_port_start=80' /etc/sysctl.conf || \
	echo 'net.ipv4.ip_unprivileged_port_start=80' | \
	sudo tee -a /etc/sysctl.conf
sudo sysctl -w net.ipv4.ip_unprivileged_port_start=80
```

## Podman Status Commands 

We can use podman commands check to see if everything booted ok.

```
podman ps --all --pod 
# check the xqerl container log 'xq'
podman logs xq
# display the running processes of the container xq
podman top xq
# see what host resource are being used in our pod
podman stats --no-stream
# view the greater in the browser
firefox http://localhost/xqerl
```

## Up and Down With the .env file

We bring the pod up by running `make up` 
and conversely by running `make down` we stop the the running containers.

When running `make up` **make** will read from the `.env` file where it will pick up
container *runtime* variables.

 **TIMEZONE**: XQuery has rich set of functions and operators for 
dates, times and durations. This needs to be adjusted to your timezone, otherwise 
some of these XQuery functions and operators will not work as expected.

**Image Versions**:  These can be adjusted to the latest image versions
 
**DNS_DOMAIN**: The intial dns domain in the environment file is `example.com`.







