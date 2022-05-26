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

The XQuery web applications will serve HTTPS pages and  
can be remotely **deployed** using a single [Google Compute Engine](https://cloud.google.com/compute) instance.
By using [SNI](https://en.wikipedia.org/wiki/Server_Name_Indication), 
our pod will be capable capable of serving multiple dns domains from one cloud instance.

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

  - inotify-tools: used to watch for file changes in our src directory

  - A [Google Cloud Platform(https://cloud.google.com/free) account: 
  To demonstrate how to deploy to the cloud, we use the Google Cloud Platform(GCP)
  GCP has a [Free Tier](https://cloud.google.com/free) compute engine which won't cost you anything.
  On the free tier, you can deploy on the compute engine instance then scale up as required.

  - [gcloud cli](https://cloud.google.com/sdk/gcloud): the command line cli is 
used to create and manage our Compute Engine virtual machine instance, manage 
DNS managed zones and record sets and executing Podman commands on the Compute 
Engine virtual machine instance

## Project Documentation

1. [Getting Started](docs/getting-started.md): boot up the podman pod, 
 which will run the xqerl XQuery Application Server behind a nginx reverse proxy
2. [Runtime Environment](docs/startup-evironment.md): setting the runtime environment
3. [As A Service](docs/as-a-service.md): turn the pod running the xqerl XQuery
 Application Server into a systemd service
2. [Development Build Cycle](docs/build.md): setting the runtime environment

<!--
4. [Example Site](docs/example-site.md): playing with the example site `example.com`
-->

<!--
2. 
# glider: A template repo

This template provides ...
A XQuery web application development environment will enable you to locally 
produce, check and remotely deploy muiltiple secure sites for the domains you own.

This template contains ...
some boilerplate files in the src directory 
which are used to create an example website.

```
make up
make
w3m -dump http://example.com
```
-->

TODO
## WIP note

Code is a work in progress.
Some stuff is pulled from other projects, and needs to be rewritten for this project.
I try to take 'show not tell' approach,
so working code will be run on 'github actions'
and will be making some asciicast.



