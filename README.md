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
container *runtime* variables.

 **TIMEZONE**: XQuery has rich set of functions and operators for 
dates, times and durations. This needs to be adjusted to your timezone, otherwise 
some of these XQuery functions and operators will not work as expected.

**Image Versions**:  These can be adjusted to the latest image versions
 
**DNS_DOMAIN**: The intial domain in the environment file is `localhost`.

The `DNS_DOMAIN` key allows the [switching of dns domains](./docs/dns_domains.md)
in the development environment to a website domain you control.












<!--

1. [Getting Started](docs/getting-started.md): boot up the podman pod, 
 which will run the xqerl XQuery Application Server behind a nginx reverse proxy
2. [Runtime Environment](docs/runtime.md): setting the runtime environment
3. [As A Service](docs/as-a-service.md): turn the pod running the xqerl XQuery
 Application Server into a systemd service

4. [Container Volumes](docs/volumes.md): pod container volumes as build artifacts
5. [Build Cycle](docs/build.md): local development build cycle for building xqerl XQuery Application Server apps
6. [Xqerl Database](docs/xqerl-database.md): storing XDM data items in the xqerl database 
7. [Xqerl Code](docs/xqerl-code.md): compiling and registering XQuery library modules
7. [Static Assets](docs/static-assets.md): preprocessing and storing static assets
7. [Proxy Conf](docs/proxy.md): nginx reverse proxy configuration, rewrites and locations

-->


## WIP note

Code is a work in progress.
Some stuff is pulled from other projects, and needs to be rewritten for this project.
I try to take 'show not tell' approach,
so working code will be run on 'github actions'
and will be making some asciicast.



