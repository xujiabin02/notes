# 磁盘扩容

**注意先删除快照**

# VM虚拟机Ubuntu 20.04 LVM磁盘扩容

[![img](.img_ubuntu/webp)](https://www.jianshu.com/u/2d0b31ec226c)

[ANNION](https://www.jianshu.com/u/2d0b31ec226c)关注IP属地: 重庆

0.3062020.08.23 20:30:15字数 217阅读 7,192

## 1. 虚拟机增加硬盘容量

![img](.img_ubuntu/webp-20230407194438254)

vm设置

## 2. 查看ubuntu中当前硬盘信息

  输入命令 df -h

![img](.img_ubuntu/webp-20230407194439524)

df -h

输入命令 fdisk -l

![img](.img_ubuntu/webp-20230407194439097)

fdisk -l

解决：GPT PMBR size mismatch (62914559 != 83886079) will be corrected by write.

输入命令 parted -l 修复分区表

![img](.img_ubuntu/webp-20230407194439057)

parted -l

## 3. 使用 parted 追加容量到/dev/sda3

输入命令 parted /dev/sda 

输入命令 unit s 设置Size单位，方便追加输入

输入命令 p free 查看详情

输入命令 resizepart 3 追加容量到sda3

输入命令 83886046s 空闲容量区间Free Space结束位置

输入命令 q 退出

![img](.img_ubuntu/webp-20230407194438528)

parted /dev/sda

## 4.更新LVM中pv物理卷

输入命令 pvresize /dev/sda3 更新pv物理卷

输入命令 pvdisplay 查看状态

![img](.img_ubuntu/webp-20230407194438491)

pvresize /dev/sda3

## 5.LVM逻辑卷扩容

输入命令 lvdisplay

![img](.img_ubuntu/webp-20230407194438560)

lvdispaly

输入命令 lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv 逻辑卷扩容

![img](.img_ubuntu/webp-20230407194438644)

lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv

输入命令 resize2fs /dev/ubuntu-vg/ubuntu-lv 刷新逻辑卷

![img](.img_ubuntu/webp-20230407194438897)

resize2fs /dev/ubuntu-vg/ubuntu-lv





# 安装GPU

```
sudo apt-get update   #更新软件列表
 
sudo apt-get install -y g++
 
sudo apt-get install -y gcc
 
sudo apt-get install  -y  make
```







```
blacklist nouveau
blacklist lbm-nouveau
options nouveau modeset=0
alias nouveau off
alias lbm-nouveau off

```





```sh
sudo update-initramfs -u

```



```sh
reboot
```



```sh
lsmod | grep nouveau
```



> ```shell
> appuser@newkn1:~$ sudo ubuntu-drivers devices
> ERROR:root:could not open aplay -l
> Traceback (most recent call last):
>   File "/usr/share/ubuntu-drivers-common/detect/sl-modem.py", line 35, in detect
>     aplay = subprocess.Popen(
>   File "/usr/lib/python3.8/subprocess.py", line 858, in __init__
>     self._execute_child(args, executable, preexec_fn, close_fds,
>   File "/usr/lib/python3.8/subprocess.py", line 1704, in _execute_child
>     raise child_exception_type(errno_num, err_msg, err_filename)
> FileNotFoundError: [Errno 2] No such file or directory: 'aplay'
> ```
>
> 



```
sudo apt install alsa-base
```



找驱动 https://www.nvidia.com/Download/Find.aspx?lang=en-us



```sh
sudo apt install libgtk-3-0
```



```
sudo update-pciids
```



```
apt install ubuntu-drivers-common
```

完全卸载NAVIDIA驱动
如果想卸载NAVIDIA驱动，使用附加驱动的方式只能切换驱动，但卸载不了驱动，只能通过命令的方式卸载：

```
sudo apt-get -y --purge remove nvidia*
sudo apt-get y --purge remove "*nvidia*"
sudo apt-get -y --purge remove "*cublas*" 
sudo apt-get -y --purge remove "cuda*"

sudo apt-get -y --purge nvidia*

sudo update-initramfs -u
```



```
sudo apt-get remove nvidia-*
```







下载460包

https://http.download.nvidia.com/XFree86/Linux-x86_64/460.91.03/



PS:





https://blog.csdn.net/qq_34525916/article/details/110953980

https://blog.csdn.net/qq_46107892/article/details/122616172

https://yukihane.work/li-gong/nvidia-ubuntu-laptop

https://blog.51cto.com/zaa47/2596875



https://hslxy.top/index.php/2022/07/21/esxi6-7ubuntu20-043080直通配置/



https://www.zhangfangzhou.cn/esxi-2080ti-passthrough.html ESXi7u1设置NVIDIA GEFORCE RTX 2080TI显卡直通（passthrough）





https://github.com/OrangeSpatial/documents/blob/main/Ubuntu安装rtx%202080ti%20显卡.md





# CUDA

https://blog.csdn.net/ziqibit/article/details/129935737

```
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-ubuntu2004.pin
sudo mv cuda-ubuntu2004.pin /etc/apt/preferences.d/cuda-repository-pin-600
wget https://developer.download.nvidia.com/compute/cuda/12.1.0/local_installers/cuda-repo-ubuntu2004-12-1-local_12.1.0-530.30.02-1_amd64.deb
sudo dpkg -i cuda-repo-ubuntu2004-12-1-local_12.1.0-530.30.02-1_amd64.deb
sudo cp /var/cuda-repo-ubuntu2004-12-1-local/cuda-*-keyring.gpg /usr/share/keyrings/
sudo apt-get update
sudo apt-get -y install cuda
```



cuda会装 530驱动，要手动卸载装460