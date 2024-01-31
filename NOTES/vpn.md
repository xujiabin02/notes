# 解决openvp丢包问题

今天云上的服务器的tomcat应用突然启动卡住，没有任何报错信息，经过检查发现是数据库连不上

因为云上连接的是本地的数据库，所以走的是openvp，使用证书进行验证

在云上ping了一下本地的服务器， 延迟正常，丢包率接近百分之90

[tomcat@iZ2ze6p0co7ym5c66anoq1Z ~]$ ping 192.168.1.12
PING 192.168.1.12 (192.168.1.12) 56(84) bytes of data.
64 bytes from 192.168.1.12: icmp_seq=20 ttl=64 time=55.0 ms
64 bytes from 192.168.1.12: icmp_seq=21 ttl=64 time=55.0 ms
64 bytes from 192.168.1.12: icmp_seq=22 ttl=64 time=54.7 ms
^C
--- 192.168.1.12 ping statistics ---
24 packets transmitted, 3 received, 87% packet loss, time 23001ms
rtt min/avg/max/mdev = 54.784/54.932/55.011/0.218 ms
1
2
3
4
5
6
7
8
9
但是直接ping本地的外网ip连接正常

重启客户端，服务端还是一样

查看openvp日志，服务端将同一个ip分配给了不同的两台服务器，导致两台服务器的ip相同

而且两台服务器ping本地ip都在丢包，但是其他的云上服务器并没有这个情况

发现两台服务器用的是同一个证书进行连接，在服务端重新生成不同证书，重启客户端后问题解决
————————————————
版权声明：本文为CSDN博主「健康马m」的原创文章，遵循CC 4.0 BY-SA版权协议，转载请附上原文出处链接及本声明。
原文链接：https://blog.csdn.net/mayifan0/article/details/81206697

# client-template

```
client
proto udp
explicit-exit-notify
remote x.x.x.x 60319
dev tun
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
verify-x509-name server_Qw6aOQ4a51HhiANz name
auth SHA256
auth-nocache
cipher AES-128-GCM
tls-client
tls-version-min 1.2
tls-cipher TLS-ECDHE-ECDSA-WITH-AES-128-GCM-SHA256
ignore-unknown-option block-outside-dns
route-nopull
route 192.168.1.0 255.255.255.0 vpn_gateway
route 172.17.0.123 255.255.255.255 vpn_gateway
route 172.19.0.0 255.255.255.0 vpn_gateway
verb 3
```



# mtu

```
WARNING: 'link-mtu' is used inconsistently, local='link-mtu 1544', remote='link-mtu 1560'
```



# centos-8-vpn.sh安装

```sh
bash centos-8-vpn.sh
```

# EasyRSA-3.0.7.tgz

```
cp EasyRSA-3.0.7.tgz ~/easy-rsa.tgz
```



# Insufficient key material or header text not found in file” error

```
openvpn --genkey --secret /etc/openvpn/tls-crypt.key
```



# 配置

在`verb 3` 上一行插入以下配置

```objc
route-nopull
route 192.168.1.0 255.255.255.0 vpn_gateway
route 172.19.0.0 255.255.255.0 vpn_gateway
```



添加ovpn.service

```sh
[Unit]
Description=ovpn
After=syslog.target network.target
Wants=network.target

[Service]
Type=simple
User=root
LimitNOFILE=1000000
CPUQuota=200%
MemoryLimit=2G
ExecStart=openvpn --config /data/ovpn/devops.ovpn
Restart=always
RestartSec=30s
TimeoutSec=300

[Install]
WantedBy=multi-user.target
```



# windows client 安装

|             | https://blog.nineya.com/archives/102.html |
| ----------- | ----------------------------------------- |
|             |                                           |
|             | https://openvpn.net/community-downloads/  |
| tunnelblick |                                           |

