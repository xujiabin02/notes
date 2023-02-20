



# 挂载NTFS



先卸载



挂载

```
sudo mkdir /Volumes/mnt
sudo mount_ntfs -o rw,auto,nobrowse /dev/disk3s1 /Volumes/mnt
```





# Mac 移动硬盘未挂载-解决办法

[![img](.img_mac/webp)](https://www.jianshu.com/u/ebc48958a2c3)

[乌和兔](https://www.jianshu.com/u/ebc48958a2c3)关注IP属地: 江苏

12019.09.29 10:16:09字数 507阅读 50,055

西部数据的移动硬盘，没有点推出，而直接热插拔，再插上电脑不显示文件夹。
打开 Mac 的 磁盘工具，上面会显示当前插入的硬盘名称，并显示状态为未挂载。

网上主要有3种解决办法：

**方法1:格式化**
最傻逼的一种方法，西部数据客服说慢慢插入，实在没办法直接格式化为fat，之后就可以使用了，可我特么里面的数据不要了吗？

**方法2:使用命令挂载**

- 命令1: `diskutil list`，查看当前的硬盘信息，找到移动硬盘在系统内的名称；
- 命令2: `sudo diskutil mount /dev/disk2`，直接挂载对应名称的硬盘。
- 命令3: `sudo fsck_hfs -fy /dev/disk2`，如果命令2无效，则执行命令3之后再执行命令2。

> 但这种方法不适合我的硬盘，使用后显示`volume on disk2 timed out waiting to mount`，超时无法挂载。

**方法3:在系统内修复**

- Windows 下: 不要用磁盘修复，会提示必须先格式化。管理员身份打开命令行（Cmd），输入以下代码：`chkdsk {drive}: /f`
  例如：`chkdsk E: /f` 表示修复E 盘
- Mac 下: 过程略复杂，首先尝试用自带的磁盘工具（Disk Utility）修复，如果不成功再执行下面的步骤。打开终端，输入：`sudo fsck_exfat -d diskXsX`
  这里 diskXsX 表示要修复的分区，比如disk0s4，会出现一大堆文件列表，最后提示：`Main boot region needs to be updated. Yes/No?`输入Yes 即可。
  最后再回到 Disk Utility 去重新修复分区，这次就会成功了。

> 最后把硬盘插在 Windows 电脑上用命令修复了，十几分钟之后修复完毕，就可以正常在 Mac 电脑上使用了。







# mac远程桌面出现自动输入字母c是什么原因？

快乐小运维

于 2021-06-22 16:00:50 发布

1754
 收藏 2
文章标签： mac
版权
最近一个蛋疼的问题困扰了我，每次远程windows服务器的时候自动输入一个字母c

![数据库](.img_mac/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3dlaXhpbl80NTI5MDczNA==,size_16,color_FFFFFF,t_70.png)

当我打开navicat双击数据库的时候自动帮我输入一个c
这个问题是因为我打开了翻译软件有道翻译，导致热键冲突

当我把这个程序关闭之后再远程桌面就不会出现这个情况！

![在这里插入图片描述](https://img-blog.csdnimg.cn/20210622155930353.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3dlaXhpbl80NTI5MDczNA==,size_16,color_FFFFFF,t_70#pic_center)————————————————
版权声明：本文为CSDN博主「快乐小运维」的原创文章，遵循CC 4.0 BY-SA版权协议，转载请附上原文出处链接及本声明。
原文链接：https://blog.csdn.net/weixin_45290734/article/details/118109141
