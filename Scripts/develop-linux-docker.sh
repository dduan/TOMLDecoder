#!/usr/bin/env bash

command -v docker &> /dev/null || { echo >&2 "Install docker https://www.docker.com"; exit 1; }

IMAGE=norionomura/swift@sha256:3455f611208d110f04c2420717bf2a5cf1124b23c91690fee1bdc278b8838491
NAME=tomldeserializerdev
docker run -it -v "$PWD":/TOMLDecoder --name "$NAME" --rm "$IMAGE"
