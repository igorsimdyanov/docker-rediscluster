#!/bin/bash

# Кластер на локальной машине
DOCKER_IP='127.0.0.1'

echo "DOCKER IP : $DOCKER_IP"

# Создаем два redis-сервиса, которые на хост-машине будут
# доступны по 127.0.0.1:6379 и 127.0.0.1:6380, друг для друга
# они будут доступны по $REDIS_0_IP:6379 и REDIS_1_IP:6379
docker run --name redis_0 -t -d -i -p 6379:6379 redis:2.8
docker run --name redis_1 -t -d -i -p 6380:6379 redis:2.8

# Получаем IP-адреса redis-хостов
REDIS_0_IP=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' redis_0)
REDIS_1_IP=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' redis_1)

echo "REDIS_0_IP : $REDIS_0_IP"
echo "REDIS_1_IP : $REDIS_1_IP"

# Запускаем три sentinel-хоста
# 127.0.0.1:26379 <=> SENTINEL_0_IP:26379
# 127.0.0.1:26378 <=> SENTINEL_1_IP:26379
# 127.0.0.1:26377 <=> SENTINEL_2_IP:26379
docker run --name sentinel_0 -d -p 26379:26379 joshula/redis-sentinel --sentinel announce-ip $DOCKER_IP --sentinel announce-port 26379
docker run --name sentinel_1 -d -p 26378:26379 joshula/redis-sentinel --sentinel announce-ip $DOCKER_IP --sentinel announce-port 26378
docker run --name sentinel_2 -d -p 26377:26379 joshula/redis-sentinel --sentinel announce-ip $DOCKER_IP --sentinel announce-port 26377

# Получаем IP-адреса sentinel-хостов
SENTINEL_0_IP=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' sentinel_0)
SENTINEL_1_IP=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' sentinel_1)
SENTINEL_2_IP=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' sentinel_2)

echo "SENTINEL_0_IP : $SENTINEL_0_IP"
echo "SENTINEL_1_IP : $SENTINEL_1_IP"
echo "SENTINEL_2_IP : $SENTINEL_2_IP"

# Второй редис $REDIS_1_IP:6379 или с хост-машины 127.0.0.1:6380 делаем слевом
# или подчиненым первом редис-инстансу
redis-cli -h $DOCKER_IP -p 6380 slaveof $REDIS_0_IP 6379

redis-cli -p 26379 sentinel monitor testing $REDIS_0_IP 6379 2
redis-cli -p 26379 sentinel set testing down-after-milliseconds 1000
redis-cli -p 26379 sentinel set testing failover-timeout 1000
redis-cli -p 26379 sentinel set testing parallel-syncs 1

redis-cli -p 26378 sentinel monitor testing $REDIS_0_IP 6379 2
redis-cli -p 26378 sentinel set testing down-after-milliseconds 1000
redis-cli -p 26378 sentinel set testing failover-timeout 1000
redis-cli -p 26378 sentinel set testing parallel-syncs 1

redis-cli -p 26377 sentinel monitor testing $REDIS_0_IP 6379 2
redis-cli -p 26377 sentinel set testing down-after-milliseconds 1000
redis-cli -p 26377 sentinel set testing failover-timeout 1000
redis-cli -p 26377 sentinel set testing parallel-syncs 1