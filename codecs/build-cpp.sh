#!/bin/sh -e
docker build -t squoosh-cpp --platform=linux/amd64 - < ../cpp.Dockerfile
docker run -it --rm --platform=linux/amd64 -v $PWD:/src squoosh-cpp "$@"
