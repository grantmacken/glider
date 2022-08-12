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

We will be setting up a **local** dockerized XQuery web application development environment.

The XQuery web applications will run in a [podman](https://podman.io/) pod and consist of 2 named containers
 1. 'or' container: a nginx reverse proxy server based on [openresty](https://openresty.org/en/)
 2. 'xq' container: running the xqerl application

<!--
The XQuery web applications will serve HTTPS pages and  
can be remotely **deployed** using a single [Google Compute Engine](https://cloud.google.com/compute) instance.
By using [SNI](https://en.wikipedia.org/wiki/Server_Name_Indication), 
our pod will be capable capable of serving multiple dns domains from one cloud instance.
-->

## Requirements

 For this project you will need 
  - a modern linux OS which supports the linux kernel [cgroup2 component](https://facebookmicrosites.github.io/cgroup2/docs/overview).

  - [Podman](https://podman.io/podman): the pod manager for our containers.
  >  Podman is a daemonless container engine for developing, managing, and running OCI Containers on your Linux System
  Version 4 or later is required
  To install see [podman install instructions](https://podman.io/getting-started/installation)

  - Make: used as a build tool and a task runner.
  > Makefiles are machine-readable documentation that make your workflow reproducible
  cited from [Why Use Make](https://bost.ocks.org/mike/make/)

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
2. [enable rootless](./docs/on_rootlessness.md) in order to sever on port 80 and above
3. bring the [podman pod](https://docs.podman.io/en/latest/markdown/podman-pod.1.html) up with two running containers
 1. 'or' container: nginx as a [reverse proxy](https://docs.nginx.com/nginx/admin-guide/web-server/reverse-proxy)
 2. 'xq' container: the xqerl application

```shell
gh repo clone grantmacken/glider
cd glider
make rootless
make up
```

If you see the 'You are now flying xqerl' 
you know the pod is running and in the pod nginx is acting as a 
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

## Up and Down With the .env file

We bring the pod up by running `make up` 
and conversely by running `make down` we stop the the running containers.

When running `make up` **make** will read from the `.env` file where it will pick up
container *runtime* variables. The .env file contains these keys.

 **TIMEZONE**: XQuery has rich set of functions and operators for 
dates, times and durations. This needs to be adjusted to your timezone, otherwise 
some of these XQuery functions and operators will not work as expected.

**Image Versions**:  These can be adjusted to the latest container image versions
 
**DNS_DOMAIN**: The intial domain in the environment file is `localhost`.

The `DNS_DOMAIN` key allows the [switching of dns domains](./docs/dns_domains.md)
so you can work with a specific DNS domain in the development environment e.g. `example.com`

## The Podx Pod

In our [podman pod](https://developers.redhat.com/blog/2019/01/15/podman-managing-containers-pods#podman_pods__what_you_need_to_know) which we have named `podx`,  we have two running containers

1. **xq:** this is a running instance of the xqerl XQuery application server
2. **or:** this is the running nginx instance which is based on openresty
   and is acting as a reverse proxy for xqerl.
   Later we will set up the reverse proxy to serve our own dns domains. 
   With our own dns domains nginx will also be the
    - proxy TLS termination point
    - proxy cache server


### Runtime Container Volume Mounts

The podx pod has the following volume mounts:

The container named **xq** has these volume mounts
 - **xqerl-database** volume: holds '[XDM](https://www.w3.org/TR/xpath-datamodel-31/) data items' and 'link items' in the xqerl database
 - The **xqerl-code** volume holds user main and library XQuery modules which are compiled into beam files
 - The **static-assets** volume holds binary and unparsed text files in the container filesystem. 

 The container named **or** has these volume mounts
 -  The **proxy-conf** volume holds nginx configuration files
 -  The **letsencrypt** volume will hold TLS certs from letsencrypt

The proxy-conf, letsencrypt and static-assets volumes contain filesystem items
 The xqerl-code and xqerl-database are volumes which allow us to persist xqerl **application state** 
 across host reboots or stoping and and restarting the pod.

### The Central Importance of Container Volumes

After we have developed a web app based on our dns domain, 
deployment is simply a matter of running a remote instance of our pod with mounted volumes.

 To **deploy** we can export local volumes and import these volumes on a remote host.
 The reverse is also true, we can export volumes on a remote host and import these volumes on a local host.

 This means, what we run and serve locally in our development environment 
 can be the same as what runs and serves on a remote cloud instance.

The development of a web app with a local running pod instance,
 is a matter of getting stuff into the attached volumes.

##  The Development Build Cycle

Our local development build cycle will consists of:
 1. **editing** source files located in the src directory
 2. **building** storing build-chain result items into appropiate container volumes 
 then creating a build artefact tar of the respective volume.
 3. **checking** the build which is site reachable at your development dns domain e.g. http://example.com

```shell
src
├── assets -> into static-assets volume -> export as static-assets.tar
├── code   -> into xqerl-code volume -> export as xqerl-code.tar
├── data   -> into xqerl-database volume -> export as xqerl-database.tar
└── proxy
    └── conf -> into proxy-conf volume -> export as xqerl-database.tar
```

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
 - `make confs` nginx configuration files

The `inc` include directory contains make files named after the above targets.
Here you can add or adjust the declarative targets and the consequent pipelined lines of shell script 
that will be executed when the build chain runs.

<!--
For example since targets can have sub targets, e.g.
the `make assets` target will have sub target declarations with thier own build chains
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

If you want to automate this browser refresh, 
 you can use something like [tab-reloader](https://github.com/james-fray/tab-reloader) which is 
 available for most common browsers.

### Exported Volumes As Build Artefacts

Build artifact tars are in the `_deploy` directory.
These are exported tars of the container volumes.

Since the `proxy-conf` and `static-assets` volumes only contain files,
 we don't have to worry about running processes tied to the volumes.
These`proxy-conf` and `static-assets` tars are generated when running `make`.

However with the `xqerl-database` and `xqerl-code`, 
 since there might be running processes,
 we have extra targets `make code-volume-export` and `make data-volume-export`
 where we pause the container first, then export, then unpause.

```shell
_deploy
├─ proxy-conf.tar   
├─ static-assets.tar
├─ xqerl-code.tar     <- make code-volume-export
└─ xqerl-database.tar <- make data-volume-export

```
