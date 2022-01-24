





```sh
docker commit -a "vue ts python3.6" -m "打包测试成功" f8520479ba2b vue3-ts-python3.6:1.0.0

docker export  --output=vue3-ts-python36.tar  c7
cat vue3-ts-python36.tar|docker import - c8
```



```bash
hr:centos7 hr$ docker port 4966d35fe0a3
22/tcp -> 0.0.0.0:10022
```

# docker swarm

![img](.img_docker/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3dlaXhpbl80MjUzMzg1Ng==,size_16,color_FFFFFF,t_70.png)





# 查看docker RestartPolicy

```sh
 docker inspect m1 | python3 -c 'import json,sys;print(json.load(sys.stdin)[0]["HostConfig"]["RestartPolicy"]["Name"])'
```

