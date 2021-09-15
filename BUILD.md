# Building the RabbitMQ Foundry Discovery plugin
For Hitachi Vantara, use the erlangbuild container image of the appropriate version to build the RabbitMQ Peer Discovery Plugin.
`docker-registry.repo.wal.eng.hitachivantara.com/com.hitachi.aspen/erlangbuild:v1`

The following instructions assume access to the Hitachi Vantara Waltham docker registry and run from the git repository for the plugin, e.g. `~/git/rabbitmq-peer-discovery-foundry`.

See the Dockerfile section for instructions on building a Docker image suitable for building the plugin code.
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

# Dockerfile
The following provide an example Dockerfile which could be used to create a build image suitable for building the plugin code.

To build the image, use a command similar to:

    docker build --network=host -t erlangbuild/erlangbuild:v1 .

assuming Dockerfile in the current directory. Or. specify --file <dockerfile> to specify the location/name.

##  For RabbitMQ 3.8

    FROM alpine:3.10.3

    RUN apk update && apk add bash gawk curl git make automake python2\
     rsync zip pcre2 libxslt erlang-tools erlang-et erlang-kernel\
     erlang-compiler erlang-dev erlang-erts erlang-common-test erlang-eunit\
     elixir

An example based on Fedora-30:

    FROM fedora:30

    RUN dnf install -y findutils make automake git zip unzip python2\
     rsync libxslt erlang-erts elixir erlang-eunit erlang-common_test

## For RabbitMQ 3.9

    FROM alpine:3.13

    RUN apk update && apk add bash gawk curl git make automake python2\
     rsync zip pcre2 libxslt erlang erlang-dev elixir

See the docker-build folder in the repository for more information.

# Notes
If experiencing any encoding errors as part of the build, try explicitly setting UTF-8 environment variables when running the docker build image:

    -e LANG=C.UTF-8 -e LC_ALL=C.UTF-8
