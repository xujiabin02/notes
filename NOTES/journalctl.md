```shell
journalctl --since "2018-03-26" --until "2018-03-26 03:00"
journalctl --since yesterday
journalctl --since 09:00 --until "1 hour ago"
journalctl -u nginx.service --since today
journalctl -u nginx.service -u php-fpm.service --since today
journalctl -p err
# 不分页
journalctl --no-pager
# json格式
journalctl -u cron.service -n 1 --no-pager -o json
# 指定可执行文件过滤
journalctl /usr/lib/systemd/systemd
# 查看内核日志
journalctl -k
```

