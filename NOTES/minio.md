待调研4节点  纠删码

docker 单点

```shell
docker run -d \
--name minio \
-p 9000:9000 \
-p 9001:9001 \
--privileged=true \
-e "MINIO_ROOT_USER=admin" \
-e "MINIO_ROOT_PASSWORD=admin123" \
-v ./data:/data \
-v ./config:/root/.minio \
minio/minio server \
--console-address ":9000" \
--address ":9001" /data
```





env

```shell
export MINIO_ACCESS_KEY=
export MINIO_SECRET_KEY=
export MINIO_PROMETHEUS_AUTH_TYPE=public
export MINIO_DOMAIN=xxx.com
```

