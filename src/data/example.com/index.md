 <!--
 title: running xqerl in docker containers 
 layout: default_tpl
-->
## Setting Up Docker Volumes 

Docker containers are *ephemeral*.
All data and code running in a xqerl container will be lost when you stop the container.
Using docker volumes however will persit data across starting and stopping container instances.

For our xqerl applications we create three docker *mount* volumes.

1. xqerl-code: this will hold **beam** compiled xquery library modules
2. xqerl-database: This holds the **xqerl database** store of XDM data items and link items
3. static-assets: This holds supporting binary and unparsed text filesystem assets

```shell
docker volume create xqerl-code
docker volume create xqerl-database
docker volume create static-assets 
```

The above docker volumes can be seen as xqerl deployment artefacts.
They are the release product, when we develop xQuery applications with xqerl.

When developing there is a 4th mount we can have.
This is a bind mount to our source files in a src dir. 
This is only for local development of our xQuery application. 
This bind volume will not be used when we deploy to a remote server.

```docker
docker run --rm --name xq \
  --publish 8081:8081 \
  --mount type=volume,target=/usr/local/xqerl/code,source=xqerl-code \
  --mount type=volume,target=/usr/local/xqerl/data,source=xqerl-database \
  --mount type=volume,target=/usr/local/xqerl/priv/static/assets,source=static-assets \
  --mount type=bind,destination=/usr/local/xqerl/src,source=./src,relabel=shared \
  --detach ghcr.io/grantmacken/xqerl:v0.1.3
```
