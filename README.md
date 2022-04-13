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
make service-status
```





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
