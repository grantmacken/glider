# [xqerl glider](https://en.wikipedia.org/wiki/Squirrel_glider)

>  Not to be confused with the Flying Squirrel.

xQuery 3.1 is the query language for building data driven web applications.

Xqerl pronounced 'squirrel',  is a xQuery 3.1 application server.

Xqerl is an erlang application that runs on top of the Erlang virtual machine [BEAM](https://en.wikipedia.org/wiki/BEAM_(Erlang_virtual_machine))
Web applications that run on the BEAM have a reputation for being long running, fault tolerant and reliable. 
The xqerl docker image has the erlang OTP builtin, so although xqerl is a erlang application that runs on the BEAM,
to use xqerl you do not need to locally install erlang or even know much about erlang.

The xqerl application has 2 aspects
1. a [xQuery](https://en.wikipedia.org/wiki/XQuery) 3.1 application engine:  
2. a database that stores [XDM](https://www.w3.org/TR/xpath-datamodel-31/) items

## Aims 

We will be setting up a **local** dockerized xQuery web application development environment.
<!--
The goal is **remote** deployment to a single Google Compute Engine instance.
This dockerized xQuery web application deployment will serve secure HTTPS web pages from your IP domain names
 By using [SNI](https://en.wikipedia.org/wiki/Server_Name_Indication), the setup is capable of serving multiple domains. --> 

### Prerequisites

* make, bash 
* to prettyfy cmd line output:  
  - jq: pipe to format JSON output `jq '.'
  - xmlint: pipe to format XML output `xmllint --format`
  - w3m: to screen dump http requests `w3m -dump http://localhost`
* [podman](https://podman.io/podman)  [getting-started](https://podman.io/getting-started/installation) 
>  Podman is a daemonless container engine for developing, managing, and running OCI Containers on your Linux System
  I am using the latest release v4 
* [gh](https://github.com/cli/cli) the GitHub CLI

<!--
**optional** for Cloud Compute Engine hosting

Sites will be hosted on single Google Cloud Compute Engine instance, 
so you will need a Google Cloud Account.

If you don't have a Google Cloud Account, 
then sign up to the [Google Cloud Free Trial Account](https://k21academy.com/google-cloud/create-google-cloud-free-tier-account/)
-->
<!-- For experimenting you can try the free tier [e2-micro VM instance](https://cloud.google.com/free) -->

<!--
If you don't have a the [gcloud](https://cloud.google.com/sdk/docs/install) cli the 
the install istructions are in the link.
-->

### Getting Started

```
# clone this repo
gh repo clone grantmacken/glider
cd glider
# enter super do
sudo -s 
# pull images
make-images
# bring container pod up
make-up
# see what is running in the pod
podman podman --pod
# exit super do
exit
# use w3m to make a request to 'http://localhost'
w3m -dump http://localhost
```

### xqerl as a service

Now we have a running xqerl instance, we can 
set the pod to run on boot. 

```
# enter super do
sudo -s 
make service
# reboot
reboot
```

After reboot we can check 
```
# enter super do
sudo -s
# check service status
make service-status
# check with podman
podman ps --pod -a
# stop the service
make service-stop
# 'xq' ond 'or' containers should now have exited
podman ps --pod --all
# restart the service
# 'xq' ond 'or' containers should now be up
podman ps --pod --all
# check the xqerl container log 'xq'
podman log xq
# use podman top
podman top xq
# exit super do
exit
```







