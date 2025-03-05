# ubuntu



## 分区

在Ubuntu 22.04上使用`parted`工具进行磁盘分区可以按照以下步骤进行。请确保你有管理员权限，并备份重要数据以防操作失误导致数据丢失。

1. **安装`parted`工具**（如果未安装）：
    ```bash
    sudo apt update
    sudo apt install parted
    ```

2. **列出所有磁盘**：
    ```bash
    sudo parted -l
    ```
    这将列出系统中的所有磁盘及其分区信息。

3. **启动`parted`工具**：
    ```bash
    sudo parted /dev/sdX
    ```
    替换`/dev/sdX`为你要操作的磁盘名称，例如`/dev/sda`。

4. **创建新的分区表**（可选，如果你想清空磁盘）：
    ```bash
    (parted) mklabel gpt
    ```
    这里选择`gpt`分区表类型，你也可以选择`msdos`等其他类型。

5. **创建新分区**：
    ```bash
    (parted) mkpart primary ext4 0% 50%
    ```
    这将在磁盘上创建一个占用前50%空间的主分区，并格式化为`ext4`文件系统。你可以根据需要调整大小和文件系统类型。

6. **查看分区信息**：
    ```bash
    (parted) print
    ```
    这将显示当前磁盘上的所有分区信息。

7. **退出`parted`工具**：
    ```bash
    (parted) quit
    ```

8. **格式化分区**（如果尚未格式化）：
    ```bash
    sudo mkfs.ext4 /dev/sdX1
    ```
    替换`/dev/sdX1`为你创建的分区名称。

9. **挂载新分区**：
    创建挂载点并挂载分区：
    ```bash
    sudo mkdir -p /mnt/my_partition
    sudo mount /dev/sdX1 /mnt/my_partition
    ```

10. **设置开机自动挂载**：
    编辑`/etc/fstab`文件：
    ```bash
    sudo nano /etc/fstab
    ```
    添加以下内容：
    ```bash
    /dev/sdX1  /mnt/my_partition  ext4  defaults  0  2
    ```

以上是使用`parted`在Ubuntu 22.04上进行磁盘分区的基本步骤。请根据实际情况调整具体命令和参数。

# file连接数问题

/etc/sysctl.conf

```shell
fs.file-max = 100000
fs.inotify.max_user_watches=524288
fs.inotify.max_user_instances=512
```

```shell
sysctl -p
```



# 加固

https://pboyd.io/posts/securing-a-linux-vm/

# 不留痕迹

```sh
history -r
unset HISFILE
```



# 禁用内核更新

```shell
# 禁用内核更新
sudo apt-mark hold linux-generic linux-image-generic linux-headers-generic

# 恢复内核更新
sudo apt-mark unhold linux-generic linux-image-generic linux-headers-generic

```



# resolv问题

vim /etc/systemd/resolved.conf

```ini
[Resolve]
DNS=8.8.8.8 8.8.4.4
FallbackDNS=1.1.1.1 1.0.0.1
```

```shell
systemctl enable systemd-resolved
systemctl restart systemd-resolved
```



# ubuntu20.04密码的问题

/etc/ssh/sshd_config

```sh
Port 22
LoginGraceTime 100m
#PermitRootLogin prohibit-password
PermitRootLogin yes
StrictModes yes
PasswordAuthentication yes
```



# apt install 指定版本

```sh
apt-cache madison [package]
apt-get install [package]=[version]
```

将列出所有来源的版本。信息会比上面详细一点，如下输出所示：

```
apt-cache policy <<package name>>
```

# 重启

`Failed to start reboot.target`

```
reboot -f
```



# 换国内源

https://mirrors.tuna.tsinghua.edu.cn/help/ubuntu/

阿里

```sh
deb http://mirrors.aliyun.com/ubuntu/ jammy main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ jammy main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ jammy-security main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ jammy-security main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ jammy-updates main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ jammy-updates main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ jammy-proposed main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ jammy-proposed main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ jammy-backports main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ jammy-backports main restricted universe multiverse
```

**中科大源**

```
deb https://mirrors.ustc.edu.cn/ubuntu/ jammy main restricted universe multiverse
deb-src https://mirrors.ustc.edu.cn/ubuntu/ jammy main restricted universe multiverse
deb https://mirrors.ustc.edu.cn/ubuntu/ jammy-updates main restricted universe multiverse
deb-src https://mirrors.ustc.edu.cn/ubuntu/ jammy-updates main restricted universe multiverse
deb https://mirrors.ustc.edu.cn/ubuntu/ jammy-backports main restricted universe multiverse
deb-src https://mirrors.ustc.edu.cn/ubuntu/ jammy-backports main restricted universe multiverse
deb https://mirrors.ustc.edu.cn/ubuntu/ jammy-security main restricted universe multiverse
deb-src https://mirrors.ustc.edu.cn/ubuntu/ jammy-security main restricted universe multiverse
deb https://mirrors.ustc.edu.cn/ubuntu/ jammy-proposed main restricted universe multiverse
deb-src https://mirrors.ustc.edu.cn/ubuntu/ jammy-proposed main restricted universe multiverse
```

**网易163源**

```
deb http://mirrors.163.com/ubuntu/ jammy main restricted universe multiverse
deb http://mirrors.163.com/ubuntu/ jammy-security main restricted universe multiverse
deb http://mirrors.163.com/ubuntu/ jammy-updates main restricted universe multiverse
deb http://mirrors.163.com/ubuntu/ jammy-proposed main restricted universe multiverse
deb http://mirrors.163.com/ubuntu/ jammy-backports main restricted universe multiverse
deb-src http://mirrors.163.com/ubuntu/ jammy main restricted universe multiverse
deb-src http://mirrors.163.com/ubuntu/ jammy-security main restricted universe multiverse
deb-src http://mirrors.163.com/ubuntu/ jammy-updates main restricted universe multiverse
deb-src http://mirrors.163.com/ubuntu/ jammy-proposed main restricted universe multiverse
deb-src http://mirrors.163.com/ubuntu/ jammy-backports main restricted universe multiverse
```

# 磁盘读写测试

写入

```
dd if=/dev/zero of=./test bs=512k count=2048 oflag=direct
```



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



如果是xfs, 还需要执行  

xfs_growfs /
