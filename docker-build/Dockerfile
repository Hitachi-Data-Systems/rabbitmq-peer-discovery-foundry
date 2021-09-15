# A container for building erlang projects (specifically
# https://github.com/Hitachi-Data-Systems/rabbitmq-peer-discovery-foundry).
# 
# The expectation is that the code resides on an external volume which the container
# can mount and build.
#
# Interactive example:
# docker run -it --rm --network=host -v /local_src_path:/img_src_path\
# com.hitachi.aspen/erlangbuild:v1 bash
# $ cd /img_src_path
# $ make dist
#
# Command example:
# docker run -it --rm --network=host -v /local_src_path:/img_src_path -w /img_src_path\
# -e LANG=C.UTF-8 -e LC_ALL=C.UTF-8 com.hitachi.aspen/erlangbuild:v1 make dist
#
# Build:
# docker build --network=host --file Dockerfile.alpine -t com.hitachi.aspen/erlangbuild:v1 .

FROM alpine:3.10.3

RUN apk update && apk add bash gawk curl git make automake python2\
 rsync zip pcre2 libxslt erlang-tools erlang-et erlang-kernel\
 erlang-compiler erlang-dev erlang-erts erlang-common-test erlang-eunit\
 elixir
