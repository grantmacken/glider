
##  The Development Build Cycle
<!--
Although the end goal is for us to have a websites running under our own domains, 
the glider project generates some base boilerplate files for the 'example.com' domain 
 when you initially run `make up`. 
 -->

A local development build cycle will consists of:
 1. **editing** source files located in the src directory
 2. **building** by running `make` which stores build-target results into appropiate container volumes
 3. **checking** the build which is site reachable at your development dns domain e.g. http://example.com.

A tree view of the src folder reflects what gets stored into the respective container volumes.

```
src
├── assets => docker static-assets volume
├── code   => docker xqerl-code volume
├── data   => docker xqerl-database volume
└── proxy
    └── conf => docker proxy-conf volume

The source files are not directly copied into their respective volumes.
 They are *build sources* which are *piped* through a input-output build process stages,
 and the end result then stored into a container volume.  
 To trigger the build process we just run the default make target `make`.
 The **build artifacts** are the docker volumes exported as tar files. 
 These build result artifacts tars are in the _deploy directory.

```
├── proxy-conf.tar
├── static-assets.tar
├── xqerl-code.tar
└── xqerl-database.tar
```

It is important to note that is these tars that are deployed on our remote (GCE) host. 
The key takeaway point what we build, run and serve locally in our development environment 
will be the same as what runs and serves on the remote cloud instance

 Initial `make` source files use 'example.com' domain.
 After experimenting, you are expected to switch to developing using your own DNS domains 
and using HTTPS. To do this letsencrypt certs are obtained independently of a remote running site,
and stored in a remote 'letsencrypt' volume. This volume is imported into the local development envronment.
After a couple of changes to the nginx configuration, the locally developed and remote sites will be serving only HTTPS, 
and HTTP port 80 requests will be routed to the secure HTTPS port 443.

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

## A Site Domain Is Always Being Served

When the pod is running, the nginx proxy passes request to the xqerl XQuery application server.
Since the pod is always running locally, when developing, if a build succeeds then you get *live web view*, of your current build.
You do not have to stop and start your pod, to see the changes you have made.


