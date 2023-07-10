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



