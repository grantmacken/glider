
# NOTE: 

This project is under development.
 The basic ideas are there but I am still changing stuff. 
 When I think it is ready I will tag a release version.


# [xqerl glider](https://en.wikipedia.org/wiki/Squirrel_glider)

>  Not to be confused with the Flying Squirrel.

[![asciicast](https://asciinema.org/a/487137.svg)](https://asciinema.org/a/487137)

[Xqerl](https://github.com/zadean/xqerl) pronounced 'squirrel',  is a XQuery 3.1 application server and database.
 The xqerl database provides a conveniant store for hierarchical collections of [XDM](https://www.w3.org/TR/xpath-datamodel-31/) items. 
[XQuery 3.1](https://www.w3.org/TR/xquery-31/) is the query language used for building data driven web applications 
from the data stored in the xqerl database.

Xqerl is an erlang application that runs on top of the Erlang virtual machine [BEAM](https://en.wikipedia.org/wiki/BEAM_(Erlang_virtual_machine))
[Erlang](https://en.wikipedia.org/wiki/Erlang_(programming_language)) applications have a reputation for being long running, fault tolerant and reliable.
This project uses a xqerl container image, so you do not need to locally install erlang or even know much about erlang.

## Project Aims

We will be setting up a [XQuery](https://en.wikipedia.org/wiki/XQuery) web application server and provide
a local XQuery web application development environment.
The XQuery web applications will run in a [Podman](https://podman.io/) pod name podx.
Our pod  name podx will consist of 2 named containers
 1. 'or' container: a nginx reverse proxy server based on [openresty](https://openresty.org/en/)
 2. 'xq' container: running the xqerl application.

 

<!--
The XQuery web applications will serve HTTPS pages and  
can be remotely **deployed** using a single [Google Compute Engine](https://cloud.google.com/compute) instance.
By using [SNI](https://en.wikipedia.org/wiki/Server_Name_Indication), 
our pod will be capable capable of serving multiple dns domains from one cloud instance.
-->

## Requirements

 For this project you will need 
  - a modern Linux OS which supports the Linux kernel [cgroup2 component](https://facebookmicrosites.github.io/cgroup2/docs/overview).

  - [Podman](https://podman.io/podman): the pod manager for our containers.
  >  Podman is a daemonless container engine for developing, managing, and running OCI Containers on your Linux System
  Version 4 or later is required
  To install see [Podman install instructions](https://podman.io/getting-started/installation)

  - Make: used as a build tool and a task runner.
  > Makefiles are machine-readable documentation that make your workflow reproducible
  cited from [Why Use Make](https://bost.ocks.org/mike/make/)

  - [mkcert](https://github.com/FiloSottile/mkcert)
  > mkcert is a simple tool for making locally-trusted development certificates. It requires no configuration
Our web application server will deliver secure HTTPS pages from the get go so we need certificates. 
You can generate your own self signed certs, but using [mkcert](https://github.com/FiloSottile/mkcert) is the way to go.
Later on for your own DNS domains we will use 'letsencrypt' to obtain your certs.

  <!--

  - A [Google Cloud Platform](https://cloud.google.com/free) account: 
  To demonstrate how to deploy to the cloud, we use the Google Cloud Platform(GCP)
  GCP has a [Free Tier](https://cloud.google.com/free) compute engine which won't cost you anything.
  On the free tier, you can deploy on the compute engine instance then scale up as required.

  - [gcloud cli](https://cloud.google.com/sdk/gcloud): the command line cli is 
used to create and manage our Compute Engine virtual machine instance, manage 
DNS managed zones and record sets and executing Podman commands on the Compute 
Engine virtual machine instance

-->

## Getting Started

1. clone this repo and cd into the cloned dir
2. [enable rootless](./articles/on_rootlessness.md) in order to sever on port 80 and above
3. bring the [Podman pod](https://docs.podman.io/en/latest/markdown/podman-pod.1.html) up with two running containers
 1. 'or' container: nginx as a reverse-proxy <!--[reverse proxy](https://docs.nginx.com/nginx/admin-guide/web-server/reverse-proxy) -->
 2. 'xq' container: the xqerl application

```shell
gh repo clone grantmacken/glider
cd glider
make rootless
make up
```

In the terminal, if you see the 'You are now flying xqerl' 
you know the pod is running and in the pod, nginx is acting as a 
reverse proxy for the xqerl XQuery application server.

## Podman Status Commands 

We can use podman commands check to see if everything booted ok.

```shell
podman ps --all --pod 
# check the xqerl container log 'xq'
podman logs xq
# display the running processes of the container xq
podman top xq
# see what host resource are being used in our pod
podman stats --no-stream
```

## The Podx Pod

In our [podman pod](https://developers.redhat.com/blog/2019/01/15/podman-managing-containers-pods#podman_pods__what_you_need_to_know) which we have named `podx`,  we have two running containers

1. **xq:** this is a running instance of the xqerl XQuery application server
2. **or:** this is the running nginx instance which is based on openresty
   and is acting as a reverse proxy for xqerl.
   Later we will set up the reverse proxy to serve our own DNS domains. 
   With our own DNS domains nginx will also be the
    - proxy TLS termination point
    - proxy cache server

### Runtime Container Volume Mounts

The podx pod has the following volume mounts:

The container named **xq** has these volume mounts
 - The **xqerl-database** volume holds '[XDM](https://www.w3.org/TR/xpath-datamodel-31/) data items' and 'link items' in the xqerl database
 - The **xqerl-code** volume holds user main and library XQuery modules which are compiled into beam files
 - The **xqerl-priv** volume holds binary and unparsed text files in the container file system that accessible to the xqerl XQuery application server.

 The container named **or** has these volume mounts
 -  The **proxy** volume holds nginx/openresty configuration files
 -  The **letsencrypt** volume will hold TLS certs from letsencrypt

The proxy, letsencrypt and static-assets xqerl-priv volumes contain filesystem items.
 The xqerl-code and xqerl-database are volumes which allow us to persist xqerl **application state** 
 across host reboots or stoping and and restarting the pod.

### The Central Importance of Container Volumes

After we have developed a web app based on our DNS domains, 
deployment is simply a matter of running a remote instance of our pod with mounted volumes.

 To **deploy** we can export local volumes and import these volumes on a remote host.
 The reverse is also true, we can export volumes on a remote host and import these volumes on a local host.

 This means, what we run and serve locally in our development environment 
 can be the same as what runs and serves on a remote cloud instance.

The development of web apps with a local running pod instance,
 is a matter of getting stuff into the attached volumes.

##  Domain Based Development

This repo contains a dot env file which contains key value pairs.
This file is sourced by the Makefile every time we run a Make target.

```
# current in development domain
DOMAIN=example.com
XQERL_VER=v0.1.15
CURL_VER=v7.83.1
CMARK_VER=v0.30.2
```

At the top of the file is the DOMAIN key and a value which we have set to 
`example.com`. This is the domain we want host and serve our web pages from.

Since we don't own this domain, we need to initialize our local development 
environment so we can host can serve `example.com` HTTPS pages.

 For the DOMAIN specified in .env file, `example.com` we set up DNS resolution via '/etc/hosts'
  This is simply adds the line  `127.0.0.1   example.com`  to /etc/hosts. This is done with sudo permissions

```shell
> make hosts
[sudo] password for gmack: 
127.0.0.1   example.com
------------------------------------------------------------
# Loopback entries; do not change.
# For historical reasons, localhost precedes localhost.localdomain:
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
# See hosts(5) for proper format and other examples:
127.0.0.1   example.com
------------------------------------------------------------

```

 To obtain certs for the DOMAIN specified in .env file,`example.com` 
 and add these cert files to our proxy server.

```
> make proxy-mkcert
##[ proxy-mkcert ]##
Created a new certificate valid for the following names 📜
 - "example.com"
The certificate is at "src/proxy/certs/example.com.pem" and the key at "src/proxy/certs/example.com.key.pem" ✅
It will expire on 1 March 2025 🗓
```

 Note: this is only for a pseudo play domain you do not control and only in our local development environment
 If you own your own DNS domain use 'letsencypt' to obtain your certs and import these into the letencypt volume (more on this later) 

Now we have set up our xqerl XQuery application development environment we can start building...


##  The Development Build Cycle

Our local development build cycle will consists of:
 1. **editing** source files located in the src directory
 2. **building** invoking Makefile targets that will store build-chain result items into appropriate container volumes 
 then creating a **build artefact** tar of the respective volume.
 3. **checking** the build which is site reachable at your development DNS domain e.g. http://example.com

```shell
src
├── assets -> into xqerl-priv volume -> export as xqerl-priv.tar
├── code   -> into xqerl-code volume -> export as xqerl-code.tar
├── data   -> into xqerl-database volume -> export as xqerl-database.tar
└── proxy -> into proxy volume -> export as proxy.tar
```

Build artifact tars are in the `_deploy` directory.

When the pod is running, after editing a source file you can build by running `make`
When you invoke a subsequent `make`, only edited files will be built.

The source files are not directly copied into their respective volumes.
 They are *build sources* which are *piped* through a input-output build chain
 with resulting items stored in a container volume.

 - `make code`: 
    - compiles XQuery main and library modules into beam files, 
    - registers library modules and 
    - sets web app routes from restXQ libraries.
 - `make data`:  data pipeline preprocessing (munging|wrangling) to create XDM items for xqerl database. 
 - `make assets`: preprocessing asset pipeline to store binary and unparsed text files.
 - `make proxy`: copy over modified configuration files for reverse proxy

The `inc` include directory contains make files named after the above targets.
Here you can add or adjust the declarative targets and the consequent pipelined lines of shell script 
that will be executed when the build chain runs.

<!--
For example since targets can have sub targets, e.g.
the `make assets` target will have sub target declarations with their own build chains
for getting stuff into the static-assets volume. 

With
 - `make styles`:  you might want build chain that use postcss
 - `make scripts`: you might want a build chain to compile typescript files
-->

Most targets will have a corresponding `clean` and `list` target
 
 ```shell
 make styles       # build chain to put CSS into the static-assets volume
 make styles-list  # list styles stored in the static-assets volume
 make styles-clean # remove styles stored in the static-assets volume
 ```

You can run `make help` to list the targets.
 
### A Site Domain Is Always Being Served

When developing by editing and building from source files the pod should always be running. 
If a build succeeds, it means the changes have already been implemented on the running pod instance.
You do not have to stop and start your pod, after a build.

All you have to do is refresh you browser to see changes.

## Running xqerl as a service

[![asciicast](https://asciinema.org/a/515367.svg)](https://asciinema.org/a/515367)

On linux os you can set the pod to run as a systemd **user** service.
A systemd **user** service does not run as root but under a login user.
This will mean the xqerl XQuery application server will automatically be available 
to you when your operating system boots.

NOTE: This is for a modern linux OS only which supports linux kernel [Control Group v2](https://www.kernel.org/doc/html/latest/admin-guide/cgroup-v2.html). 

```
make service-enable
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



<!-- ## Scaffold a project based on a domain -->
<!---->
<!-- A simple project scaffolding can be built using the domain name as the projects dir. -->
<!---->
<!-- ``` -->
<!-- bin/init -->
<!-- # This will prompt you for a domain name you wish to use. -->
<!-- # e.g. example.com -->
<!-- # cd into the directory -->
<!-- cd ../example.com -->
<!-- # run make -->
<!-- #  add 'example.com' to the /etc/hosts file, -->
<!-- # so 'example.com can resolve locally -->
<!-- make hosts -->
<!-- ``` -->
<!---->
<!-- The nginx reverse proxy configuration is set up redirect  -->
<!-- request to HTTP port 80 to the sercure TLS port 433. -->
<!-- This is true for any domain except the `localhost` domain or -->
<!-- localhost subdomain like `erwhon.localhost`.  -->
<!-- Any other domain will redirect to the TLS port 433 -->
<!---->
<!-- ``` -->
<!-- #  HTTP server with redirect to port 433 -->
<!-- ######################################### -->
<!---->
<!-- server { -->
<!--   root html; -->
<!--   index index.html; -->
<!--   listen 80 default_server; -->
<!--   listen [::]:80 default_server; -->
<!--   server_name ~^(www\.)?(?<domain>.+)$; -->
<!--   location = /favicon.ico { -->
<!--     log_not_found off; -->
<!--   } -->
<!--   # Redirect all HTTP requests to HTTPS with a 301 Moved Permanently response. -->
<!--   location / { -->
<!--     return 301 https://$http_host$request_uri; -->
<!--   } -->
<!-- } -->
<!-- ``` -->
<!---->
<!-- It is preferable to use dns domains under your control. -->
<!-- You can to obtain letsencrypt certs by using the letsecypt bot  -->
<!-- and store these certs in our letsencrypt container volume. -->
<!-- Your site does not have to be running to do this. Full instructions later.  -->
<!---->
<!-- In the meantime, you can treat something like 'example.com' as a testing playground domain. -->
<!-- To use 'example.com' as a testing playground domain you will need self-signed certs. -->
<!---->
<!-- The easiest way to do this is via [mkcert](https://github.com/FiloSottile/mkcert) -->
<!-- The install instructions are on the [mkcert repo](https://github.com/FiloSottile/mkcert) -->
<!-- After you have installed mkcert  -->
<!---->
<!-- ``` -->
<!-- # cd into the 'example.com' dir created via `bin/init` -->
<!-- # to create the self signed certs for 'example.com' run ... -->
<!-- make mkcert -->
<!-- # the certs will now be in the src/proxy/certs dir -->
<!-- # along with the nginx conf file -->
<!-- # src/proxy/conf/self_signed.conf that points to these certs  -->
<!-- # To upload src files into the container run ... -->
<!-- make proxy -->
<!-- ``` -->
<!---->
<!-- Now you will have HTTP requests on the example.com domain served over the secure TLS port. -->
<!---->
<!-- ``` -->
<!-- curl -Lv http://example.com # with -L flag follows redirects -->
<!-- w3m -dump http://example.com # redirects automatically -->
<!-- w3m -dump_extra http://example.com #  to see redirects -->
<!-- ``` -->
<!---->
<!---->
<!-- ## tared volume backups and restoring volumes -->
<!---->
<!-- ## removing podx and build and deploy artefacts -->





