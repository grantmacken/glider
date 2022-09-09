
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
