
# Container Volumes

The running **xq** container has these named volume mounts
 - **xqerl-database** volume: holds '[XDM](https://www.w3.org/TR/xpath-datamodel-31/) data items' and 'link items' in the xqerl database
 - **xqerl-code** volume: holds user main and library XQuery modules which are compiled into beam files
 - **xqerl-priv** volume: holds binary and unparsed text files in the erlang application `./priv` directory. 
 The running **or** container has these volume mounts
 - **proxy** volume: holds nginx configuration files
 - **letsencrypt** volume: will hold TLS certs from letsencrypt

The proxy-conf, letsencrypt and static-assets volumes contain filesystem items
 The xqerl-code and xqerl-database are volumes which allow us to persist xqerl **application state** 
 across host reboots or stoping and and restarting the pod.

Xqerl XQuery web app development with a local running pod instance is a matter of getting stuff into the attached volumes.
 Volumes can be seen as deployable artifacts. Deployment is a matter of running a remote instance of our pod with attached volumes.
 To deploy we can export local volumes and export import these volumes on a remote hosts.
 This means, what we run and serve locally in our development environment can be the same as what runs and serves on a remote cloud instance






 

