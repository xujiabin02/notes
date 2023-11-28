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

