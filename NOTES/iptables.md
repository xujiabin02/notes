# docker添加iptable

```sh
iptables -I DOCKER-USER -p tcp --dport 3000 -m set ! --match-set office_ip src -j REJECT


```

https://262235.xyz/index.php/archives/438/





```shell
iptables -I INPUT -p tcp --dport 80 -m set ! --match-set office_ip src -j REJECTl
```

