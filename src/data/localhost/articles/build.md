#  The Development Build Cycle
<!--
Although the end goal is for us to have a websites running under our own domains, 
the glider project generates some base boilerplate files for the 'example.com' domain 
 when you initially run `make up`. 
 -->

A local development build cycle will consists of:
 1. **editing** source files located in the src directory
 2. **building** by running `make` which stores build-target results into appropriate container volumes
 3. **checking** the build which is site reachable at your development DNS domain e.g. http://example.com.

A tree view of the src folder reflects what gets stored into the respective container volumes.

```shell
src
├── assets => container xqerl-priv volume
├── code   => container xqerl-code volume
├── data   => container xqerl-database volume
└── proxy
    └── conf => container proxy-conf volume
```

The source files are not directly copied into their respective volumes. They are *build sources* which are *piped* 
through a input-output build process stages, and the end result then stored into a container volume. To trigger the 
build process we just run the default make target `make`. The **build artifacts** are the docker volumes exported as 
tar files. These build result artifacts tars are in the deploy directory.

```shell
├── proxy-conf.tar
├── xqerl-priv.tar
├── xqerl-code.tar
└── xqerl-database.tar
```

NOTE! It is these tars that are deployed on our remote (GCE) host. 

After experimenting, you are expected to switch to developing using your own domains 
and using HTTPS. To do this letsencrypt certs are obtained independently of a remote running site,
and stored in a remote 'letsencrypt' volume. This volume is imported into the local development environment.
After a couple of changes to the nginx configuration, the locally developed and remote sites will be serving only HTTPS, 
and HTTP port 80 requests will be routed to the secure HTTPS port 443.

## The Make Build Target

When the pod is running, after editing a source file you can build by running `make` The default Make target is `make 
build` so `make` will run `make build`.When you invoke a subsequent `make`, only edited files will be built.

After the first `make` run you can set a watch target. In another terminal window, cd into this repo directory and run `make watch`. This will watch for file writes in the src dir and run the `make build` target when file writes occur.

## A Site Domain Is Always Being Served

When developing by editing and building from source files the pod should always be running. 
You do not have to stop and start your pod, after a build.
If a build succeeds, it means the changes have already been implemented on the running pod instance.






