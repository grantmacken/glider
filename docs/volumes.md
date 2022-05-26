#  Container Volumes

In our [podman pod]((https://developers.redhat.com/blog/2019/01/15/podman-managing-containers-pods#podman_pods__what_you_need_to_know)
 we have two running containers

1. **xq**: this is a running instance of the xqerl XQuery application server
2. **or** this is the running nginx instance which is based on openresty
   At the moment 'or' with our 'example.com' test site it acting as a reverse proxy for xqerl.
   Later we will set it up to serve our own dns domains nginx will be the
    - proxy TLS termination point
    - proxy cache server

Our running containers have volume mounts:

**xq**: has these volume mounts
 - **xqerl-database** volume: holds '[XDM](https://www.w3.org/TR/xpath-datamodel-31/) data items' and 'link items' in the xqerl database
 - **xqerl-code** volume: holds user main and library XQuery modules which are compiled into beam files
 - **static-assets** volume: holds binary and unparsed text files in the container filesystem. 

 **or**: has these volume mounts
 - **proxy-conf** volume: holds nginx configuration files
 - **letsencrypt** volume: will hold TLS certs from letsencrypt

The proxy-conf, letsencrypt and static-assets volumes contain filesystem items
 The xqerl-code and xqerl-database are volumes which allow us to persist xqerl **application state** 
 across host reboots or stoping and and restarting the pod.

Xqerl XQuery web app development with a local running pod instance is a matter of getting stuff into the attached volumes.
 Volumes can be seen as deployable artifacts. Deployment is a matter of running a remote instance of our pod with attached volumes.
 To deploy we can export local volumes and export import these volumes on a remote hosts.
 This means, what we run and serve locally in our development environment can the same as what runs and serves on a remote cloud instance







 

