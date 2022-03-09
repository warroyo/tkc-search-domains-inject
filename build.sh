#!/bin/bash

docker build -t domains-inject:1.0.0 .
# docker save domains-inject:1.0.0 | gzip > domains-inject.tar.gz