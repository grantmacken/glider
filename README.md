# [xqerl glider](https://en.wikipedia.org/wiki/Squirrel_glider)

>  Not to be confused with the Flying Squirrel.

xQuery 3.1 is the query language for building data driven web applications.

Xqerl pronounced 'squirrel',  is a xQuery 3.1 application server.

Xqerl is an erlang application that runs on top of Erlang virtual machine [BEAM](https://en.wikipedia.org/wiki/BEAM_(Erlang_virtual_machine)
Applications running on the BEAM are known to be suited or long running, fault tolerant, reliable web applications. 
(Erlang virtual machine) Although xqerl is a erlang applications running on the BEAM, the xqerl docker image, has the erlang OTP builtin,
so to use xqerl you do not need to locally install erlang or even know much about erlang.

The xqerl application has 2 aspects
1. a [xQuery](https://en.wikipedia.org/wiki/XQuery) 3.1 application engine:  
2. a database that stores [XDM](https://www.w3.org/TR/xpath-datamodel-31/) items

## Aims 

We will be setting up a **local** dockerized xQuery web application development environment.
The goal is **remote** deployment to a single Google Compute Engine instance.
This dockerized xQuery web application deployment will serve secure HTTPS web pages from your IP domain names
By using [SNI](https://en.wikipedia.org/wiki/Server_Name_Indication), the setup is capable of serving multiple domains. 

### Prerequisites

* podman is used in this repo. An alternative is docker. 
* make, bash, and jq
* [gh](https://github.com/cli/cli) the GitHub CLI

**optional** for Cloud Compute Engine hosting

Sites will be hosted on single Google Cloud Compute Engine instance, 
so you will need a Google Cloud Account.

If you don't have a Google Cloud Account, 
then sign up to the [Google Cloud Free Trial Account](https://k21academy.com/google-cloud/create-google-cloud-free-tier-account/)
<!-- For experimenting you can try the free tier [e2-micro VM instance](https://cloud.google.com/free) -->

If you don't have a the [gcloud](https://cloud.google.com/sdk/docs/install) cli the 
the install istructions are in the link.

### Getting Started

```
# clone this repo
gh repo clone grantmacken/glider
cd glider
# pull images
sudo make-images
# bring container pod up
sudo make-up
# use w3m to make a request to 'http://localhost'
w3m -dump http://localhost
```





