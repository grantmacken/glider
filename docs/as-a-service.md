## Running xqerl as a service

On linux os you can set the pod to run as a systemd **user** service.
A systemd **user** service does not ran as root but under a login user.
This will mean the xqerl XQuery application server will be available 
to you when your operating system boots.

NOTE: This is for a modern linux OS only which 
will support linux kernel [Control Group v2](https://www.kernel.org/doc/html/latest/admin-guide/cgroup-v2.html)

```
make service
```

After reboot we can now use systemctl to 
 - check service status
 - stop the service
 - start the service

```
# check service status
make service-status
# list containers running in the pod
podman ps --pod --all
# stop the service
make service-stop
# list containers: 'xq' ond 'or' containers should now have exited
podman ps --pod --all
# restart the service
# 'xq' ond 'or' containers should now be up
podman ps --pod --all
# check the xqerl container log 'xq'
podman log xq
# display the running processes of the container xq
podman top xq
# see what resource are being used in our pod
podman stats --no-stream
```
