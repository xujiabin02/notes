# ubuntu22.04+3090驱动

先拔掉3090，再装驱动，要用命令安装（“软件和更新-程序-附加驱动更新”会出现问题），安装好驱动后，再装上显卡。

1.1 查看系统显卡型号

```sh
lspci | grep -i nvidia
```


1.2 卸载Ubuntu自带的驱动程序

```
sudo apt-get purge nvidia*
```


1.3 禁用自带的nouveau nvidia驱动

```
sudo vim /etc/modprobe.d/blacklist.conf 
```

在blacklist.conf文件中最后添加如下内容，

```
blacklist nouveau 
options nouveau modeset=0 
```


然后保存退出。

1.4 更新

```
sudo update-initramfs -u
1.5 重启电脑
1.6 查看是否将自带的驱动屏蔽
```

```
lsmod | grep nouveau
```


没有结果输出，则表示屏蔽成功。

1.7 下载驱动

```
sudo apt update 
sudo apt install nvidia-driver-535
```


1.8 安装完成，重启电脑， nvidia-smi
————————————————

                            版权声明：本文为博主原创文章，遵循 CC 4.0 BY-SA 版权协议，转载请附上原文出处链接和本声明。

原文链接：https://blog.csdn.net/zhangzhangzhangqqq/article/details/136977530