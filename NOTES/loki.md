# promtail 取springboot日志(参考)

```yml
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://loki:3100/loki/api/v1/push

scrape_configs:
- job_name: system
  static_configs:
  - targets:
      - localhost
    labels:
      __path__: /var/log/*/*.log
      host: 192.168.1.9
  pipeline_stages:
  - match:
      selector: '{host="192.168.1.9"}'
      stages:
      - multiline:
          firstline: '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}'
          max_wait_time: 3s
      - regex:
          expression: '^(?P<time>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}) (?P<traceId>\w*)-(?P<spanId>\w*)-(?P<PID>\w*) (?P<server>.+) (?P<LEVEL>\w+) (?P<class>[^ ]+) - (?P<message>[\s\S]+)$'
      - labels:
          LEVEL:
          server:
          traceId:
          spanId:
          PID:
      - timestamp:
          source: time
          format: '2006-01-02 15:04:05.999'
          location: "Asia/Shanghai"
      - output:
          source: msg
```

loki配置

```yml
auth_enabled: false
 
server:
  http_listen_port: 3100
  grpc_listen_port: 39095 #grpc监听端口，默认为9095
  grpc_server_max_recv_msg_size: 15728640  #grpc最大接收消息值，默认4m
  grpc_server_max_send_msg_size: 15728640  #grpc最大发送消息值，默认4m
 
ingester:
  lifecycler:
    address: 127.0.0.1
    ring:
      kvstore:
        store: inmemory
      replication_factor: 1
    final_sleep: 0s
  chunk_idle_period: 1h # 配置日志块的空闲时间为1小时。如果一个日志块在这段时间内没有收到新的日志数据，则会被刷新
  max_transfer_retries: 0  # 配置日志块传输的最大重试次数为0，即禁用日志块传输。
  max_chunk_age: 20m # 配置日志块的最大年龄为1小时。当一个日志块达到这个年龄时，所有的日志数据都会被刷新。
  chunk_target_size: 2048576 # 配置日志块的目标大小为2048576字节（约为1.5MB）。如果日志块的空闲时间或最大年龄先达到，Loki会首先尝试将日志块刷新到目标大小。
  chunk_retain_period: 30s # 配置日志块的保留时间为30秒。这个时间必须大于索引读取缓存的TTL（默认为5分钟）。
 
schema_config:   # 配置Loki的schema部分，用于管理索引和存储引擎。
  configs:     # 配置索引和存储引擎的信息。
    - from: 2020-10-24   # 配置索引和存储引擎的起始时间。
      store: boltdb-shipper   # 配置存储引擎为boltdb-shipper，即使用BoltDB存储引擎。
      object_store: filesystem   # 配置对象存储引擎为filesystem，即使用文件系统存储。
      schema: v11   # 配置schema版本号为v11。
      index:   # 配置索引相关的信息。
        prefix: index_   # 配置索引文件的前缀为index_。
        period: 24h   # 配置索引文件的周期为24小时。
 
storage_config:
  boltdb:
    directory: /loki/index
 
  filesystem:
    directory: /loki/chunks
 
limits_config:
  enforce_metric_name: false  
  reject_old_samples: true #是否拒绝旧样本
  reject_old_samples_max_age: 168h # 168小时之前的样本被拒绝
  ingestion_rate_mb: 64  # 配置日志数据的最大摄入速率为64MB/s。
  ingestion_burst_size_mb: 128 #配置日志数据的最大摄入突发大小为128MB。
  max_entries_limit_per_query: 9999 # 没有该配置添加即可，数值改为自己想要的最大查询行数
  max_streams_matchers_per_query: 100000 # 配置每个查询的最大流匹配器数量为100000。
  max_entries_limit_per_query: 50000 # 配置每个查询的最大条目限制为50000。
  
chunk_store_config:
  max_look_back_period: 168h #回看日志行的最大时间，适用于即时日志,为避免查询超过保留期的数据，必须小于或等于下方的时间值,另外这个时间必须是schema_config中的period的倍数，否则报错。(这里如果配置小了，grafana中看到的日志天数也就小了，建议和下面retention_period一致)
 
table_manager:
  retention_deletes_enabled: true #日志保留周期开关，默认为false
  retention_period: 168h #日志保留周期(这里应为周期表时间的倍数 大概意思是说period，默认情况下168小时一张表，日志保留时间应该是168的倍数，比如：168x4)超过168h的日志数据将被删除
```

nginx 转发访问loki

```nginx
server{
        listen  8080;
        server_name loki.shooter.com;
        location / {
                add_header Access-Control-Allow-Origin *;
                add_header Access-Control-Allow-Methods 'GET, POST, OPTIONS';
                add_header Access-Control-Allow-Headers 'DNT,X-Mx-ReqToken,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Authorization';
 
                proxy_pass http://172.18.10.22:3000;
                proxy_http_version 1.1;
                proxy_set_header Host loki.shooter.com;
                proxy_set_header Upgrade $http_upgrade;
                proxy_set_header Connection "upgrade";
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_connect_timeout 60;
                proxy_read_timeout 600;
                proxy_send_timeout 600;
        }
        location ^~/api/live {
                add_header Access-Control-Allow-Origin *;
                add_header Access-Control-Allow-Methods 'GET, POST, OPTIONS';
                add_header Access-Control-Allow-Headers 'DNT,X-Mx-ReqToken,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Authorization';
                proxy_http_version 1.1;
                log_not_found off;
                #proxy_set_header Host $http_host;
                proxy_set_header Host loki.shooter.com;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_redirect off;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
                proxy_set_header Upgrade $http_upgrade;
                proxy_set_header Connection "upgrade";
                proxy_connect_timeout 10000;
                proxy_read_timeout 10000;
                proxy_pass http://172.18.10.22:3000;
        }
    }
```



# **集容器日志**

docker安装loki驱动收

```sh
docker plugin install  grafana/loki-docker-driver:latest --alias loki --grant-all-permissions
```

当有新版本时, 更新plugins

```sh
docker plugin disable loki --force
docker plugin upgrade loki grafana/loki-docker-driver:latest --grant-all-permissions
docker plugin enable loki
systemctl restart docker
```

对于loki的docker plugin有两种使用方式。

- 配置daemon.json,收集此后创建的所有容器的日志(注意，是配置daemon.json后重启docker服务后创建的容器才会把日志输出到loki)。
- 新建容器时指定logging类型为loki，这样只有指定了logging的容器才会输出到loki

# **全局收集配置(推荐)**

`````sh
编辑daemon.json。linux下默认路径是/etc/docker/daemon.json (需要sudo)
`````

```json
{
  "log-driver": "loki",
  "log-opts": {
    "loki-url": "http://192.168.66.180:3100/loki/api/v1/push",
    "max-size": "50m",
    "max-file": "10",
    "loki-pipeline-stages": "- multiline:\n      firstline: '^\\[\\d{2}:\\d{2}:\\d{2} \\w{4}\\]'\n" #这一项可能会报错
  },
  "registry-mirrors": ["https://registry.docker-cn.com"]
}
```

>    注:记得把YOUR_IP换成loki所在主机的IP，一般都是本机的局域网地址，如果loki映射的端口换了记得这里也需要换。镜像仓库地址也可以换成自己云服务的。
>
>   其中max-size表示日志文件最大大小，max-file表示最多10个日志文件，都是对单个容器来说的,    multiline是配置多行识别(默认最多128行),转为单行, firstline表示单条日志的首行正则表达式,我的是 [03:00:32 INFO] 开头这种格式,所以对应正则是^\[\d{2}:\d{2}:\d{2} \w{4}\]  按照你自己的日志开头编写对应正则替换即可

```
以下这2个docker自身日志选项会和loki冲突,不要同时使用
  "log-driver":"json-file",
  "log-opts": {"max-size":"100m","max-file":"3"}
解析：max-size=100m，意味着一个容器日志大小上限是100M，max-file=3，意味着一个容器有三个日志，分别是id+.json、id+1.json、id+2.json
```

`````sh
systemctl restart docker
#在此之后创建的容器默认都会把日志发送到loki,且创建容器不需要做任何的配置,正常创建即可。
`````

```sh
version: "3"
services:
  xiaozi-base-server:
    container_name: xiaozi-base-server
    image: xiaozi-base-server:v1.0.0
    volumes:
      - /app/data:/data
    ports:
      - 1000:1000
    restart: always
```

help

```shell
label里有对应选项可以选择  
compose_project就是docker-compose的项目名  
compose_service就是docker-compose中的服务名   
container_name 就是容器名。
这几个基本就够我们定位到具体的某个容器了。

{compose_service="xiaozi-base-server"}
{container_name="xiaozi-base-server"}


```

logql速查

https://www.bookstack.cn/read/loki/logql.md

**如果不全局配置，而只想特定的容器进行日志收集，则根据启动容器的方式，有两种配置方法。**

1.docker run配置日志输出到loki

```shell
#通过docker run启动容器，可以通过--log-driver来指定为loki。示例如下

docker run -it -d -v /app/data:/data --name xiaozi-base-server --restart=always -p 11000:11000 --privileged=true --log-driver=loki --log-opt loki-url="http://192.168.66.180:3100/loki/api/v1/push" --log-opt max-size=50m --log-opt max-file=10 xiaozi-base-server:v1.0.0

--log-driver=loki指定日志驱动器为loki
--log-opt loki-url则指定了loki的url
--log-opt max-size日志最大大小
--log-opt max-file日志文件最大数量

--log-level LEVEL 定义日志等级(DEBUG, INFO, WARNING, ERROR, CRITICAL)

#测试用例:
docker run -d -p 8099:80 --name nginx_loki --restart=always --log-driver=loki --log-opt loki-url="http://192.168.66.180:3100/loki/api/v1/push" --log-opt max-size=50m --log-opt max-file=10 nginx
docker run -d -p 9909:80 --name nginx_test --restart=always --log-driver=loki --log-opt loki-url="http://192.168.66.180:3100/loki/api/v1/push" --log-opt max-size=50m --log-opt max-file=10 nginx
```

docker-compose 配置日志输出到loki

```yml
#docker-compose 小于3.4可以对需要日志输出的配置添加配置如下
logging:
  driver: loki
  options:
    loki-url: "http://YOUR_IP:3100/loki/api/v1/push"
    max-size: "50m"
    max-file: "10"
    loki-pipeline-stages: |
      - multiline:
          firstline: '^\[\d{2}:\d{2}:\d{2} \w{4}\]'
#          注意：max-size和max-file这里需要加引号  multiline已经在上文解释过了就不再赘述了
```

对于3.4极其以上版本可以通过定义模板来减少代码量

例:

```yaml
version: "3.7"

x-logging:
  &loki-logging
  driver: loki
  options:
    loki-url: "http://YOUR_IP:3100/loki/api/v1/push"
    max-size: "50m"
    max-file: "10"
    loki-pipeline-stages: |
      - multiline:
          firstline: '^\[\d{2}:\d{2}:\d{2} \w{4}\]'

services:
  xiaozi-base-server:
    container_name: xiaozi-base-server
    image: xiaozi-base-server:v1.0.0
    volumes:
      - /app/data:/data
    ports:
      - 1000:1000
    restart: always
    networks:
      - "loki_loki"
    logging: *loki-logging

networks:
  loki_loki:
    external: true
```



```yaml
&loki-logging表示定义模板

*loki-logging表示引用模板。对于多个服务就只需要对应加上一行 logging: *loki-logging 即可。相比之前的版本可谓是大大简化了
```

