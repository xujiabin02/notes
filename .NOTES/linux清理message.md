# linux删除日志: -bash: /var/log/messages 禁止操作

[centos7](https://www.bestyii.com/?tag=centos7) [运维](https://www.bestyii.com/?node=ops) · [best](https://www.bestyii.com/member/best/show) · 于 1年前 发布 · 817 次阅读

https://www.bestyii.com/member/best/show



```bash
systemctl stop rsyslog
```

大家想必都遇到系统盘满了，导致服务不正常的情况。 今天就遇到这种事。 系统日志占了40多G，当然这是一个意外导致有很多垃圾日志。 果断清理日志

```sh
> /var/log/messages
-bash: /var/log/messages: Operation not permitted
```

居然提示没有权限。

可能有a属性,用下面命令看看

```
lsattr /var/log/messages
```

确实存在那就去掉他，

```sh
sudo chattr -a  /var/log/messages
sudo chattr -i /var/log/messages
```

继续执行清理日志命令，顺利完成。

# 文件属性及相关命令

文件属性在文件系统的安全管理方面起很重要的作用，linux下lsattr命令用于查看文件属性信息。

## linux lsattr命令

**语法:** `lsattr [-adRvV] [文件或目录...]`

**选项介绍:**

* -a: 显示所有文件和目录，包括隐藏文件;
* -d: 显示目录名称，而非其内容;
* -R: 递归处理，将指定目录下的所有文件及子目录一并处理;
* -v: 显示文件或目录版本;
* -V: 显示版本信息;

**执行范例:**

```
$ chattr +ai text
$ lsattr
 ----ia------- text
```

**扩展阅读:**

chattr命令用于修改文件属性，chattr命令需要root权限。

## 文件属性

* a: append only; 系统只允许在这个文件之后追加数据，不允许任何进程覆盖或截断这个文件。如果目录具有这个属性，系统将只允许在这个目录下建立和修改文件，而不允许删除任何文件。
* c: compressed; 系统以透明的方式压缩这个文件。从这个文件读取时，返回的是解压之后的数据；而向这个文件中写入数据时，数据首先被压缩之后才写入磁盘。
* d: no dump; 在进行文件系统备份时，dump程序将忽略这个文件。
* i: immutable; 系统不允许对这个文件进行任何的修改。如果目录具有这个属性，那么任何的进程只能修改目录之下的文件，不允许建立和删除文件。
* j: data journalling; 如果一个文件设置了该属性，那么它所有的数据在写入文件本身之前，写入到ext3文件系统日志中，如果该文件系统挂载的时候使用了”data=ordered” 或”data=writeback”选项。当文件系统采用”data=journal”选项挂载时，所有文件数据已经记录日志，因此这个属性不起作用。仅仅超级用户或者拥有CAP_SYS_RESOURCE能力的进程可以设置和删除该属性。
* s: secure deletion; 让系统在删除这个文件时，使用0填充文件所在的区域。
* t: no tail-merging; 和其他文件合并时，该文件的末尾不会有部分块碎片(为支持尾部合并的文件系统使用)。
* u: undeletable; 当一个应用程序请求删除这个文件，系统会保留其数据块以便以后能够恢复删除这个文件。
* A: no atime updates; 告诉系统不要修改对这个文件的最后访问时间
* D: synchronous directory updates; 任何改变将同步到磁盘；这等价于mount命令中的dirsync选项：
* S: synchronous updates; 一旦应用程序对这个文件执行了写操作，使系统立刻把修改的结果写到磁盘。
* T: top of directory hierarchy; 如果一个目录设置了该属性，它将被视为目录结构的顶极目录







![img](.img_linux%E6%B8%85%E7%90%86message/artType01%5B1%5D.jpg) 在Linux中让echo命令显示带颜色的字。

2011-04-16 19:23:51

标签：[linux](http://blog.51cto.com/tag-linux.html) [echo](http://blog.51cto.com/tag-echo.html) [休闲](http://blog.51cto.com/tag-休闲.html) [onlyzq](http://blog.51cto.com/tag-onlyzq.html) [职场](http://blog.51cto.com/tag-职场.html)

原创作品，允许转载，转载时请务必以超链接形式标明文章 [原始出处](http://onlyzq.blog.51cto.com/1228/546459) 、作者信息和本声明。否则将追究法律责任。http://onlyzq.blog.51cto.com/1228/546459

echo显示带颜色，需要使用参数-e
格式如下:
echo -e "\033[字背景颜色;文字颜色m字符串\033[0m"
例如: 
echo -e "\033[41;37m TonyZhang \033[0m"
其中41的位置代表底色, 37的位置是代表字的颜色

 注：
1、字背景颜色和文字颜色之间是英文的“""”
2、文字颜色后面有个m
3、字符串前后可以没有空格，如果有的话，输出也是同样有空格

### 下面看几个例子：

echo -e "\033[30m 黑色字 \033[0m"
echo -e "\033[31m 红色字 \033[0m"
echo -e "\033[32m 绿色字 \033[0m"
echo -e "\033[33m 黄色字 \033[0m"
echo -e "\033[34m 蓝色字 \033[0m"
echo -e "\033[35m 紫色字 \033[0m"
echo -e "\033[36m 天蓝字 \033[0m"
echo -e "\033[37m 白色字 \033[0m"
 

echo -e "\033[40;37m 黑底白字 \033[0m"
echo -e "\033[41;37m 红底白字 \033[0m"
echo -e "\033[42;37m 绿底白字 \033[0m"
echo -e "\033[43;37m 黄底白字 \033[0m"
echo -e "\033[44;37m 蓝底白字 \033[0m"
echo -e "\033[45;37m 紫底白字 \033[0m"
echo -e "\033[46;37m 天蓝底白字 \033[0m"
echo -e "\033[47;30m 白底黑字 \033[0m"

**控制选项说明 ：**

\33[0m 关闭所有属性 
\33[1m 设置高亮度 
\33[4m 下划线 
\33[5m 闪烁 
\33[7m 反显 
\33[8m 消隐 
\33[30m -- \33[37m 设置前景色 
\33[40m -- \33[47m 设置背景色 
\33[nA 光标上移n行 
\33[nB 光标下移n行 
\33[nC 光标右移n行 
\33[nD 光标左移n行 
\33[y;xH设置光标位置 
\33[2J 清屏 
\33[K 清除从光标到行尾的内容 
\33[s 保存光标位置 
\33[u 恢复光标位置 
\33[?25l 隐藏光标 
\33[?25h 显示光标 

系统字体配色方案

export LS_COLORS='no=00:fi=00:di=44;37:ln=01;36:pi=40;33:so=01;35:bd=40;33;01:cd=40;33;01:or=01;05;37;41:mi=01;05;37;41:ex=01;32:*.cmd=01;32:*.exe=01;32:*.com=01;32:*.btm=01;32:*.bat=01;32:*.sh=01;32:*.csh=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.gz=01;31:*.bz2=01;31:*.bz=01;31:*.tz=01;31:*.rpm=01;31:*.cpio=01;31:*.jpg=01;35:*.gif=01;35:*.bmp=01;35:*.xbm=01;35:*.xpm=01;35:*.png=01;35:*.tif=01;35:'