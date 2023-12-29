# qemu-guest-agent安装,热修改密码



```diff
#ubuntu
+ apt-get install qemu-guest-agent
# centos
- yum install qemu-guest-agent
```

启动

```shell
systemctl start qemu-guest-agent
systemctl enable qemu-guest-agent
```



