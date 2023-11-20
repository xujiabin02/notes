

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

