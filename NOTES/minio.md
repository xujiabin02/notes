待调研4节点  纠删码



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

