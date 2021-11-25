





```sh
docker commit -a "vue ts python3.6" -m "打包测试成功" f8520479ba2b vue3-ts-python3.6:1.0.0

docker export  --output=vue3-ts-python36.tar  c7
cat vue3-ts-python36.tar|docker import - c8
```

