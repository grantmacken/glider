# [xqerl glider](https://en.wikipedia.org/wiki/Squirrel_glider)

>  Not to be confused with the Flying Squirrel.

[![asciicast](https://asciinema.org/a/487137.svg)](https://asciinema.org/a/487137)


Xqerl pronounced 'squirrel',  is a xQuery 3.1 application server.

xQuery 3.1 is the query language for building data driven web applications.

Xqerl is an erlang application that runs on top of the Erlang virtual machine [BEAM](https://en.wikipedia.org/wiki/BEAM_(Erlang_virtual_machine))
Erlang applications have a reputation for being long running, fault tolerant and reliable.

This project uses a xqerl docker image, so you
do not need to locally install erlang or even know much about erlang.

## WIP note

Code is a work in progress.
Some stuff is pulled from other projects, and needs to be rewritten for this project.
I try to take 'show not tell' approach,
so work code will be run on 'github actions'
and will be making some asciicast.

## Aims 

We will be setting up a **local** dockerized xQuery web application development environment.

The  web application will run in a podman pod and consist of 2 named containers
 1. 'or' container: a nginx reverse proxy server based on openresty
 2. 'xq' container: the xqerl application

<!--
The goal is **remote** deployment to a single Google Compute Engine instance.
This dockerized xQuery web application deployment will serve secure HTTPS web pages from your IP domain names
 By using [SNI](https://en.wikipedia.org/wiki/Server_Name_Indication), the setup is capable of serving multiple domains. --> 

## Prerequisites

**Make**:

> Makefiles are machine-readable documentation that make your workflow reproducible.

cited from [Why Use Make](https://bost.ocks.org/mike/make/)

**Utilities**:
- jq: pipe to format JSON output `jq '.'`
- xmlint: pipe to format XML output `xmllint --format`
- w3m: to screen dump http requests `w3m -dump http://localhost`

**the GitHub CLI**: [gh](https://github.com/cli/cli). 

**[podman](https://podman.io/podman)**: I am using the latest release v4. 
To install see [podman install instructions](https://podman.io/getting-started/installation) 

>  Podman is a daemonless container engine for developing, managing, and running OCI Containers on your Linux System

## Getting Started

```
# 1. clone this repo and cd into the cloned dir
gh repo clone grantmacken/glider
cd glider
# 2. pull docker images
make images
# 3. bring the pod up with two running containers
#  - 'or' container: nginx as a reverse proxy
make up
```

You can run `make down` to bring the pod and the 2 running containers run down.

### The .env file

When running `make up` **make** will read from the `.env` file where it will pick up
*startup* variables like
 - image-version tags: default is the latest versions
 - what ports the pod will listen on: defaults are port 8080 and 8443 
 - timezone: adjust for your timezone
 - development domain: default is 'example.com'

Apart from the timezone you can leave the .env file as is.

## Running xqerl as a service

You can set the pod to run as a systemd user service.
A systemd user service is not ran as root but under a login user.
This will mean the xqerl application server will be available 
to you when the operating system boots.

```
make up
make service
# 
reboot
```

After reboot we can now use systemctl to 
 - check service status
 - stop the service
 - start the service

```
# check service status
make service-status
# list containers ruuning in the pod
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

## Building a web site based on a domain

Lets use **example.com** as our example domain.
Run `make hosts` to add  **example.com** to the '/etc/hosts' file

After adjusting '/etc/host', a request to 'example.com:8080' will resolve
in the same way a request to 'http://localhost:8080'

```
w3m -dump http://example.com:8080
```
### A Recap

In our pod we have two running containers

1. **xq**: this is a running instance of xqerl
2. **or** this is the running nginx instance which is based on openresty
   At the moment 'or' is acting as a reverse proxy for xqerl.
   Later we will set it up as a
    - proxy TLS termination point
    - proxy cache server

Our running containers have volume mounts:

 **or**: has these volume mounts
 - proxy-conf volume: holds nginx configuration files
 - letsencypt volume: will hold TLS certs from letsencrypt

**xq**: has these volume mounts
 - xqerl-database volume: holds 'XDM data items' and 'link items' in the xqerl database
 - xqerl-code volume: holds user main and library xQuery modules which are compiled into beam files
 - static-assets volume: holds binary and unparsed text files in the container filesystem. 

The above docker *mount* volumes can be seen as **deployment artefacts**.
Volumes are the deployable release bundle, not docker images nor running container instances.

When we develop xQuery applications with xqerl the **build process**
we simply move stuff from a source into a docker Volume.

### TODO! TO Be Continued


<!--



```
# 4. use `make` to build the example.com website from sources in src dir.
make
# 7. view the example.com website
firefox http://example.com
```

## set hosts and enable rootless to operate on port 80

In our local develpoment environment, with podman we are going to run a pod without root privileges.
A [shortcoming of rootless podman](https://github.com/containers/podman/blob/main/rootless.md) 
is that podman can not create containers that bind to ports < 1024,
unless you explictly tell your system to to so. 

Since our published pod ports will be on port 80 and port 433, 
we need to implement the suggested workaround. The same workaround is also used if
you want to expose a privalaged port in a 
[rootless docker setup](https://docs.docker.com/engine/security/rootless/#exposing-privileged-ports)

```shell
grep -q 'net.ipv4.ip_unprivileged_port_start=80' /etc/sysctl.conf || \
	echo 'net.ipv4.ip_unprivileged_port_start=80' | \
	sudo tee -a /etc/sysctl.conf
  sudo sudo sysctl --system
```

Our example site will use the classic 'example.com' domain
Since we do not own or control the 'example.com' domain,
we can modify our '/etc/hosts' file, so 'example.com' will resolve to 'localhost'

```shell
grep -q '127.0.0.1   example.com' /etc/hosts || \
echo '127.0.0.1   example.com' | \
sudo tee -a /etc/hosts
```

We have `make init` target for the above code, so no need to type it in.
--> 
