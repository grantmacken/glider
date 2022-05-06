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

# glider: A template repo

This template provides ...
A XQuery web application development environment will enable you to locally 
produce, check and remotely deploy muiltiple secure sites for the domains you own.

This template contains ...
some boilerplate files in the src directory 
which are used to create an example website.

 

```
make up
make hosts
make
w3m -dump http://example.com
```

TODO
## WIP note

Code is a work in progress.
Some stuff is pulled from other projects, and needs to be rewritten for this project.
I try to take 'show not tell' approach,
so working code will be run on 'github actions'
and will be making some asciicast.

## Project Aims 

We will be setting up a **local** containerized XQuery web application development environment.

The XQuery web applications will run in a
 [podman pod](https://developers.redhat.com/blog/2019/01/15/podman-managing-containers-pods#podman_pods__what_you_need_to_know)
 and consist of 2 named containers.
 1. 'or' container: a nginx reverse proxy server based on openresty
 2. 'xq' container: the xqerl application

The local development build cycle:
 1. **editing** source files located in the src directory
 2. **building** by running `make` which stores build-target results into appropiate docker volumes
 3. **checking** the build which is site reachable at your development domain e.g. http://example.com.

A tree view of the src folder reflects what gets stored into the respective docker volumes.

```
src
├── assets => docker static-assets volume
├── code   => docker xqerl-code volume
├── data   => docker xqerl-database volume
└── proxy
    └── conf => docker proxy-conf volume
```

The source files are not directly copied into thier respective volumes.
 They are *build sources* which are *piped* through a input-output build process stages,
 and the end result then stored into a container volume.  
 To trigger the build process we just run the default make target `make`.
 The **build artifacts** are the docker volumes exported as tar files.

Initial `make` source files use 'example.com' domain.
 After exprimenting, you are expected to switch to developing using your own DNS domains 
and using HTTPS. Our letsencrypt certs will obtained independently of a remote site running,
and be used in or local development envronment.

The key takeaway point is this setup enables what we develop, run and serve locally 
will be the same as what runs and serves on the remote cloud instance.

Once this is set up can have running podman pod serving XQuery enabled, secure HTTPS web pages 
in our localhost machine and our remote Cloud machine instance. 
<!--
 Instead of using self signed certs, 
  you can use a cheap or free Google Compute Engine instance

 1. With your Google Gloud Account create a GCE (Google Compute Engine) fedora-coreos-next instance 
 2. Migrate your DNS domains to Googles [Cloud DNS](https://cloud.google.com/dns/docs/migrating)
 3. Setup your developer Google Gloud IAM service account to have a 'dns.admin' role, and obtain a project key.
 4. On the GCE instance create a letsencypt volume
 5. Use a 'docker.io/certbot/dns-google' container image instance to import certs into the letsencypt volume.
 6. Import the remote container letsencypt volume into your local letsencypt volume


Also by using [SNI](https://en.wikipedia.org/wiki/Server_Name_Indication), 
our pod will be capable capable of serving multiple domains from a single cloud instance.

-->




## Prerequisites

**Make**:

> Makefiles are machine-readable documentation that make your workflow reproducible.

cited from [Why Use Make](https://bost.ocks.org/mike/make/)

**Utilities**:
- jq: pipe to format JSON output `jq '.'`
- xmlint: pipe to format XML output `xmllint --format`
- w3m: to screen dump http requests `w3m -dump http://localhost`
- [gh](https://github.com/cli/cli). the GitHub CLI

**[podman](https://podman.io/podman)**: I am using the latest release v4. 
To install see [podman install instructions](https://podman.io/getting-started/installation) 

>  Podman is a daemonless container engine for developing, managing, and running OCI Containers on your Linux System

## Getting Started

```
# 1. clone this repo and cd into the cloned dir
gh repo clone grantmacken/glider
cd glider
# 2. enable rootless popdman to operate on port 80 and above 
make rootless 
# 3. bring the pod up with two running containers
#  - 'or' container: nginx as a reverse proxy
#  - 'xq' container: the xqerl application
make up
```
You can run `make down` to bring the pod and the 2 running containers run down.

### 2. Enabling rootless to operate on port 80 and above

In our local develpoment environment, with podman we are going to run a pod without root privileges.
A [shortcoming of rootless podman](https://github.com/containers/podman/blob/main/rootless.md) 
is that podman can not create containers that bind to ports < 1024,
unless you explictly tell your system to to so. 

Since our published pod ports will be on port 80 and port 433, 
we need to implement the suggested workaround. The same workaround is also used if
you want to expose a privileged port in a 
[rootless docker setup](https://docs.docker.com/engine/security/rootless/#exposing-privileged-ports)

The target `make rootless` invokes the following

```shell
sudo sysctl -w net.ipv4.ip_unprivileged_port_start=80
# make this change permanent. 
grep -q 'net.ipv4.ip_unprivileged_port_start=80' /etc/sysctl.conf || \
	echo 'net.ipv4.ip_unprivileged_port_start=80' | \
	sudo tee -a /etc/sysctl.conf
```

### The .env file

When running `make up` **make** will read from the `.env` file where it will pick up
*startup* variables like
 - image-version tags: default is the latest versions
 - what ports the pod will listen on: defaults are port 80 and 443 
 - timezone: adjust for your timezone 
 - development domain: default is 'example.com'

### An Example Domain

The default DNS domain value is **example.com** is specified in the .env file
 under the .env key 'DNS_DOMAIN'.

Since we do not own or control the 'example.com' DNS domain,
we can modify our '/etc/hosts' file, so 'example.com' will resolve to 'localhost'

If you run `make hosts` the make target will use the DOMAIN value in the .env to
create an entry to your '/etc/hosts' file,

To remove the entry use `make hosts-remove` 

After adjusting '/etc/host', a request to 'example.com' will resolve
in the same way a request to 'http://localhost' does.

You don't have to do this, but it makes life a bit easier

Our example site will use the classic 'example.com' domain


```shell
grep -q '127.0.0.1   example.com' /etc/hosts || \
echo '127.0.0.1   example.com' | \
sudo tee -a /etc/hosts
```

### Switching Domains

To switch development to a domain you control, change the DNS_DOMAIN to your domain then run
 the `make init` target.The target will create some some boilerplate src files for your domain.
Below we will use 'markup.nz' as an example domain.

`make init` his generates
 1. data files 
  - 'src/data/markup.nz/index.md': a markdown document
  - 'src/data/markup.nz/default_layout.xq': a XQuery main module
 2. a code file:  'src/code/restXQ/markup.nz.xqm', XQuery library module which will set the restXQ endpoints for the domain.

When we run `make` which is our *build* target,
 1. the *code* file will be compiled and set the restXQ endpoints
 2. the *data* files will be stored as XDM items in the xqerl database.

## Running xqerl as a service

You can set the pod to run as a systemd user service.
A systemd user service is not ran as root but under a login user.
This will mean the xqerl application server will be available 
to you when the operating system boots.

```
make service
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

### A Recap

In our pod we have two running containers

1. **xq**: this is a running instance of xqerl
2. **or** this is the running nginx instance which is based on openresty
   At the moment 'or' is acting as a reverse proxy for xqerl.
   Later we will set it up as a
    - proxy TLS termination point
    - proxy cache server

Our running containers have volume mounts:

**xq**: has these volume mounts
 - xqerl-database volume: holds 'XDM data items' and 'link items' in the xqerl database
 - xqerl-code volume: holds user main and library XQuery modules which are compiled into beam files
 - static-assets volume: holds binary and unparsed text files in the container filesystem. 

 **or**: has these volume mounts
 - proxy-conf volume: holds nginx configuration files
 - letsencrypt volume: will hold TLS certs from letsencrypt

The proxy-conf, letsencrypt and static-assets volumes can be seen as **deployment artefacts**.
These volumes contain files, which when exported an a tar archive can be imported to volumes
on our remote deployment host.

The xqerl-code and xqerl-database are volumes which allow us to persist xqerl application
state across host reboots or stoping and and restarting the xqerl application running in the container.

## On Pods, Ports and Belonging to a Network 

Our xqerl container named **xq** and nginx container named *or* are in a pod named 'podx'.
When we created our pod, we 
   - published ports: `8080:80` for HTTP requests and '8433:80' for HTTPS requests
   - set up network named **podman** that the running containers will join. Note: the podman network is the default network

xqerl which listens on port 8081, is running in the internal 'podman' network
so `http://example.com:8081` is not reachable outside the pod because port '8081'
is not an exposed published port for the pod.

Outside of the pod, to reach xqerl on the internet, all requests are via ngnix set up as a 
[reverse proxy](https://www.nginx.com/resources/glossary/reverse-proxy-server/)


Prior to deploying, we obtain certs for our domain.
 These certs will be in the letsencrypt volume.

In deployment 
1. all HTTP requests will be redirected to the secure HTTPS port
2. TLS termination occurs the reverse proxy


## Make Targets

When the pod is running, you can start editing the source files in the src dir.
After editing a source file you can build by running `make`
The default Make target is `make build` so `make` will run `make build`

When you invoke a subsequent `make`, only edited files will be built.

After the first `make` run you can set a watch target.
In another terminal window, cd into this repo directory 
and run `make watch`

This will watch for file writes in the src dir and  
run the `make build` target when file writes occur.

## A Site Domain Is Being Served

When the pod is running, it will be serving your in development XQuery web-app.
When developing, if a build succeeds then you get *live web view*, of your current build.
You do not have to stop and start your pod, to see the changes you have made.

TODO: livereload 

## xqerl-database volume: putting data into the xqerl database

 - Source structured markup data like XML and JSON can be parsed and stored in 
the xqerl database as XDM items as defined in the [XQuery and XPath Data Model](https://www.w3.org/TR/xpath-datamodel-31).
It is worth noting that the xqerl database can store any XDM item type. 
These XDM database items include document-nodes, maps, arrays, and even functions.
 - If the data source is not marked up then this data can be stored as unparsed text. 
 - If the data source is binary then a link item pointing to the file location can be stored in the database.

 It is worth reiterating that, structured markup data sources are parsed and loaded into 
 the xqerl database as [XDM](https://www.w3.org/TR/xpath-datamodel-31) items.

 - a XML text when parsed is stored as an `instance of document-node()`
 - JSON object when parsed stored as an `instance of map(*)`
 - JSON array when parsed stored as an `instance of array(*)`
 - CSV text when parsed stored as an `instance of array(*)`
 - XQuery main module function:  when compiled stored as an `instance of function(*)`

The URI of XDM items stored in the db can be retrieved by the XQuery function`fn:uri-collection()`

When items are stored as XDM items into the xqerl database the query power of XQuery 3.1 is amplified. 
XQuery was originally designed to work with structured data in the context of a XML database. With XQuery 3.1 the xPath 
XQuery data model is extended to include maps and arrays, so it is important that these items can be queried from the database.

Prior to storing, the data can be linted, checked and preprocessed.
Some examples:

 - **XML text**: well formed check (xmllint) then store as document-node item
 - **JSON** well formed check (jq) then store as map or array item
 - **markdown** text: preprocess with cmark then store as document-node
 - **XQuery main module function** compile check then store as function

 Our example data sources

```
src
  ├── data
  │   └── example.com
  │       ├── default_tpl.xq => into db - stored as XDM function item
  │       └── index.md       => into db - stored as XDM document-node
```

When the source file becomes a XDM item stored in the the database,
*by convention* the database item identifier(URI) will have no extension.  

```
src
  ├── data
  │   └── example.com
  │       ├── default_layout.xq => db identifier: http://example.com/default_layout
  │       └── index.md       => db identifier: http://example.com/index
```

Note: The `src/data/{DOMAIN}` directory structure is just a build process convenience. 
There other ways of getting data into the database and you don't have to follow 
the 'no extension' convention.

Once the data is in the database you can see what 
data is stored under our development domain.

The XQuery expression to get a list of URI in the database is

```
'http://example.com' => uri-collection() => string-join('&#10;')
```
This expression needs to run in the context of the runner docker instance
 using 'podman exec xq xqerl eval' ...

 The make alias shortcut to list database uri items for our domain is

```
make data-domain-list
```

## xqerl-code volume: compiled XQuery modules

The 'src/code' files contain XQuery modules.

```
src
└── code
    ├── cm_dispatch.xqm
    ├── db-store.xq
    └── restXQ
        ├── example.com.xqm
        └── markup.nz.xqm
```

XQuery defines two types of modules
 1. library modules: by convention we give these a `.xqm` extension
 2. main modules:  by convention we give these a `.xq` extension

### XQuery library modules

 When we invoke `make` the xQuery *library modules* with extension `.xqm` 
 in the src/code directory are compiled by xqerl into beam files to run on the 
 [BEAM](https://en.wikipedia.org/wiki/BEAM_(Erlang_virtual_machine)beam). 

 If the code does not compile, the beam file will NOT be created or updated.
 When you run `make` and a compile failure happens, 
 you should get a error line, showing the 
1. the error src file that failed to compile
2. the line number where the compile failed
3. the error line message

Compiled beam files are stored in the container xqerl-code volume.

 You can list your available compiled xQuery library modules.

```
make code-library-list
#  the above is an alias for 
podman exec xq xqerl eval \
'[binary_to_list(X) || X <- xqerl_code_server:library_namespaces()].'
```

#### restXQ library modules

Like [other](https://docs.basex.org/wiki/RESTXQ) XQuery application servers, the xqerl code server has a restXQ implemention.
By convention we place our restXQ XQuery library modules in the `src/code/restXQ` directory.

When we invoke `make` the restXQ modules will compile after other XQuery library modules.
We do this because the restXQ library will often import other libraries, 
so we need to compile these libraries first.

RestXQ library modules on a basic level associates HTTP requests with XQuery functions.
In our pod these HTTP requests are filtered via nginx acting as a reverse proxy.
Before the URI is poxy passed to the xqerl container we rewrite the location path 
so it includes the **domain name** in the request

```nginx
location ~* ^/(index|index.html)?$ {
  rewrite ^/?(.*)$ /$domain/index break;
  proxy_pass http://xq;
}

location / {
  rewrite ^/?(.*)$ /$domain/$1 break;
  proxy_pass http://xq;
}
```

1. `http://example.com/` will be proxy passed as `http://xq/example.com/index`
2. `http://markup.nz/`   will be proxy passed as `http://xq/markup.nz/index`

Note: the nginx rewrite is domain based, and no adjustment to the nginx conf files is need when we swap out domains. 

When we develop restXQ routes for our domains each domain gets its own restXQ library module.

1. `http://example.com` source module `src/code/restXQ/example.com.xqm`
2. `http://markup.nz` source module `src/code/restXQ/markup.nz.xqm`

In each domain based restXQ module the `rest:path` will start with the 'domain'

```
declare
  %rest:path("/example.com/{$ITEM}")
  %rest:GET
  %rest:produces("text/html")
  %output:method("html")
function _:erewhon($ITEM){
...
```
We can also associate a request with data contained in the xqerl database 
as Xqerl database indentifiers are also based on a similar uri scheme-domain-path pattern.
`http://{DOMAIN}/{COLLECTION_ITEM}`

```
nginx receives: https://example.com =>
rewrite proxy pass: http://xq/example.com/index =>
restXQ path: /example.com/{$ITEM} =>
XQerl function can utilize db identifier: http://example.com/index
```

### XQuery main modules

TODO!

## static-assets volume 

The xqerl(cowboy) server listening on port 8081,
provides a service which can serve files directly from the file system on the 'xq' container.

Binary and text assets that do not belong in the xqerl database, should be stored as files in the`static-assets` volume.
These assets may include images, icons, stylesheets, fonts, scripts etc.

Asset source file may be **preprocessed** before they are stored into the `static-assets` volume.
The preproccesing stages, aka *asset pipeline*, prior to storing the asset may consist of one stage feeding into another.

A preprocessing asset pipeline stage depends on the end result required for the asset type.
Images may need some form of file size optimisation, stylesheet may be gzipped etc.




<!--
```
src
  └── code
    ├── cm_dispatch.xqm =>  compiled xquery library module => stored in code-volume as beam file
    ├── db-store.xq     =>  compile check for xquery main module - not stored
    └── routes.xqm      =>  compiled restXQ library => cowboy routes stored in code-volume
```


```
# 4. use `make` to build the example.com website from sources in src dir.
make
# 7. view the example.com website
firefox http://example.com
```


We have `make init` target for the above code, so no need to type it in.
--> 
