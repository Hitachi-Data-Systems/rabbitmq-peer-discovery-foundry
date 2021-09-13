# Building the RabbitMQ Foundry Discovery plugin

Use the erlangbuild container image to build the RabbitMQ Peer Discovery Plugin.

`docker-registry.repo.wal.eng.hitachivantara.com/com.hitachi.aspen/erlangbuild:v1`


These instructions assume they are being run with access to Waltham docker registry and from the git repository for the plugin, e.g. `~/git/rabbitmq-peer-discovery-foundry`.

## Non-Interative
This runs the make targets in the container, once complete the container exits and is cleaned up.

```
$ docker run -e DIST_AS_EZS=1 --network=host -w /build --rm -v `pwd`:/build docker-registry.repo.wal.eng.hitachivantara.com/com.hitachi.aspen/erlangbuild:v1 make clean dist
.
.
.
$ ls -l plugins/rabbitmq_peer_discovery_foundry*
-rw-r--r-- 1 root root 23039 Aug 17 07:13 plugins/rabbitmq_peer_discovery_foundry-74e098c.ez
```

## Interactive

This method starts a bash shell in the build container.  Once the bash shell is exited, the contaienr exits and cleaned up.



```
$ docker run -it --network=host -w /build --rm -v `pwd`:/build docker-registry.repo.wal.eng.hitachivantara.com/com.hitachi.aspen/erlangbuild:v1 /bin/bash
bash-5.0# DIST_AS_EZS=1 make clean dist
.
.
.
bash-5.0# exit
$ ls -l plugins/rabbitmq_peer_discovery_foundry*
-rw-r--r--    1 root     root         23039 Aug 14 17:21 plugins/rabbitmq_peer_discovery_foundry-74e098c.ez
```


## Plugin Version

By default, the version will be the short commit id.  If local changes haven't been committed, then the version will have "+dirty" appended to it.
To specify a version, set the environment variable `RABBITMQ_VERSION`, i.e. `docker run -e RABBITMQ_VERSION=1.7.0 ... make clean dist`

