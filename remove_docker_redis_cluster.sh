#!/bin/bash
docker rm -f redis_0
docker rm -f redis_1

docker rm -f sentinel_0
docker rm -f sentinel_1
docker rm -f sentinel_2
