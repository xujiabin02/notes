

# delele remote branch

```sh
git push origin --delete feature/login
```



# git cherry-pick 教程





```yml
hosts: 'cdp_deploy_composer'
tasks:
  - name: "find {{ gio_pkg_dir }} dirs"
    find:
      file_type: file
      age: 1d
      paths: "{{ gio_pkg_dir }}"
      patterns: 'id-service-*.tar.gz'
    register: artifacts
    become: yes
  - debug:
      msg: "{{ artifacts.files }}"
```



# Git 工具 - 搜索

## 搜索

无论仓库里的代码量有多少，你经常需要查找一个函数是在哪里调用或者定义的，或者显示一个方法的变更历史。 Git 提供了两个有用的工具来快速地从它的数据库中浏览代码和提交。 我们来简单的看一下。

### Git Grep

Git 提供了一个 `grep` 命令，你可以很方便地从提交历史、工作目录、甚至索引中查找一个字符串或者正则表达式。 我们用 Git 本身源代码的查找作为例子。

默认情况下 `git grep` 会查找你工作目录的文件。 第一种变体是，你可以传递 `-n` 或 `--line-number` 选项数来输出 Git 找到的匹配行的行号。

```console
$ git grep -n gmtime_r
compat/gmtime.c:3:#undef gmtime_r
compat/gmtime.c:8:      return git_gmtime_r(timep, &result);
compat/gmtime.c:11:struct tm *git_gmtime_r(const time_t *timep, struct tm *result)
compat/gmtime.c:16:     ret = gmtime_r(timep, result);
compat/mingw.c:826:struct tm *gmtime_r(const time_t *timep, struct tm *result)
compat/mingw.h:206:struct tm *gmtime_r(const time_t *timep, struct tm *result);
date.c:482:             if (gmtime_r(&now, &now_tm))
date.c:545:             if (gmtime_r(&time, tm)) {
date.c:758:             /* gmtime_r() in match_digit() may have clobbered it */
git-compat-util.h:1138:struct tm *git_gmtime_r(const time_t *, struct tm *);
git-compat-util.h:1140:#define gmtime_r git_gmtime_r
```

除了上面的基本搜索命令外，`git grep` 还支持大量其它有趣的选项。

例如，若不想打印所有匹配的项，你可以使用 `-c` 或 `--count` 选项来让 `git grep` 输出概述的信息， 其中仅包括那些包含匹配字符串的文件，以及每个文件中包含了多少个匹配。

```console
$ git grep --count gmtime_r
compat/gmtime.c:4
compat/mingw.c:1
compat/mingw.h:1
date.c:3
git-compat-util.h:2
```

如果你还关心搜索字符串的 **上下文**，那么可以传入 `-p` 或 `--show-function` 选项来显示每一个匹配的字符串所在的方法或函数：

```console
$ git grep -p gmtime_r *.c
date.c=static int match_multi_number(timestamp_t num, char c, const char *date,
date.c:         if (gmtime_r(&now, &now_tm))
date.c=static int match_digit(const char *date, struct tm *tm, int *offset, int *tm_gmt)
date.c:         if (gmtime_r(&time, tm)) {
date.c=int parse_date_basic(const char *date, timestamp_t *timestamp, int *offset)
date.c:         /* gmtime_r() in match_digit() may have clobbered it */
```

如你所见，date.c 文件中的 `match_multi_number` 和 `match_digit` 两个函数都调用了 `gmtime_r` 例程 （第三个显示的匹配只是注释中的字符串）。

你还可以使用 `--and` 标志来查看复杂的字符串组合，它确保了多个匹配出现在同一文本行中。 比如，我们要查看在旧版本 1.8.0 的 Git 代码库中定义了常量名包含 “LINK” 或者 “BUF_MAX” 这两个字符串的行 （这里也用到了 `--break` 和 `--heading` 选项来使输出更加容易阅读）。

```console
$ git grep --break --heading \
    -n -e '#define' --and \( -e LINK -e BUF_MAX \) v1.8.0
v1.8.0:builtin/index-pack.c
62:#define FLAG_LINK (1u<<20)

v1.8.0:cache.h
73:#define S_IFGITLINK  0160000
74:#define S_ISGITLINK(m)       (((m) & S_IFMT) == S_IFGITLINK)

v1.8.0:environment.c
54:#define OBJECT_CREATION_MODE OBJECT_CREATION_USES_HARDLINKS

v1.8.0:strbuf.c
326:#define STRBUF_MAXLINK (2*PATH_MAX)

v1.8.0:symlinks.c
53:#define FL_SYMLINK  (1 << 2)

v1.8.0:zlib.c
30:/* #define ZLIB_BUF_MAX ((uInt)-1) */
31:#define ZLIB_BUF_MAX ((uInt) 1024 * 1024 * 1024) /* 1GB */
```

相比于一些常用的搜索命令比如 `grep` 和 `ack`，`git grep` 命令有一些的优点。 第一就是速度非常快，第二是你不仅仅可以可以搜索工作目录，还可以搜索任意的 Git 树。 在上一个例子中，我们在一个旧版本的 Git 源代码中查找，而不是当前检出的版本。

### Git 日志搜索

或许你不想知道某一项在 **哪里** ，而是想知道是什么 **时候** 存在或者引入的。 `git log` 命令有许多强大的工具可以通过提交信息甚至是 diff 的内容来找到某个特定的提交。

例如，如果我们想找到 `ZLIB_BUF_MAX` 常量是什么时候引入的，我们可以使用 `-S` 选项 （在 Git 中俗称“鹤嘴锄（pickaxe）”选项）来显示新增和删除该字符串的提交。

```console
$ git log -S ZLIB_BUF_MAX --oneline
e01503b zlib: allow feeding more than 4GB in one go
ef49a7a zlib: zlib can only process 4GB at a time
```

如果我们查看这些提交的 diff，我们可以看到在 `ef49a7a` 这个提交引入了常量，并且在 `e01503b` 这个提交中被修改了。

如果你希望得到更精确的结果，你可以使用 `-G` 选项来使用正则表达式搜索。

#### 行日志搜索

行日志搜索是另一个相当高级并且有用的日志搜索功能。 在 `git log` 后加上 `-L` 选项即可调用，它可以展示代码中一行或者一个函数的历史。

例如，假设我们想查看 `zlib.c` 文件中`git_deflate_bound` 函数的每一次变更， 我们可以执行 `git log -L :git_deflate_bound:zlib.c`。 Git 会尝试找出这个函数的范围，然后查找历史记录，并且显示从函数创建之后一系列变更对应的补丁。

```console
$ git log -L :git_deflate_bound:zlib.c
commit ef49a7a0126d64359c974b4b3b71d7ad42ee3bca
Author: Junio C Hamano <gitster@pobox.com>
Date:   Fri Jun 10 11:52:15 2011 -0700

    zlib: zlib can only process 4GB at a time

diff --git a/zlib.c b/zlib.c
--- a/zlib.c
+++ b/zlib.c
@@ -85,5 +130,5 @@
-unsigned long git_deflate_bound(z_streamp strm, unsigned long size)
+unsigned long git_deflate_bound(git_zstream *strm, unsigned long size)
 {
-       return deflateBound(strm, size);
+       return deflateBound(&strm->z, size);
 }


commit 225a6f1068f71723a910e8565db4e252b3ca21fa
Author: Junio C Hamano <gitster@pobox.com>
Date:   Fri Jun 10 11:18:17 2011 -0700

    zlib: wrap deflateBound() too

diff --git a/zlib.c b/zlib.c
--- a/zlib.c
+++ b/zlib.c
@@ -81,0 +85,5 @@
+unsigned long git_deflate_bound(z_streamp strm, unsigned long size)
+{
+       return deflateBound(strm, size);
+}
+
```

如果 Git 无法计算出如何匹配你代码中的函数或者方法，你可以提供一个正则表达式。 例如，这个命令和上面的是等同的：`git log -L '/unsigned long git_deflate_bound/',/^}/:zlib.c`。 你也可以提供单行或者一个范围的行号来获得相同的输出。	



[PS](https://git-scm.com/book/zh/v2/Git-%E5%B7%A5%E5%85%B7-%E6%90%9C%E7%B4%A2)



# git 如何所有分支里边搜索代码片段

git grep "are you ok" $(git rev-list --all)`

\1. 谷歌大法好：
https://www.google.com/search?q=git+grep+all+branches&oq=git+grep+all&aqs=chrome.0.0i20i263i512j0i512l3j69i57j0i512j0i22i30l4.3117j0j7&sourceid=chrome&ie=UTF-8

\2. 面对 stackoverflow 编程：
https://stackoverflow.com/questions/15292391/is-it-possible-to-perform-a-grep-search-in-all-the-branches-of-a-git-project





```sh
搜索所有的 commit 的 code diff(最快)

git log -p --all -S 'search string'
git log -p --all -G 'match regular expression'

搜索所有 local branch

git branch | tr -d \* | sed '/->/d' | xargs git grep <regexp>

搜索所有的 commit

git grep -F "keyword" $(git rev-list --all)
git grep <regexp> $(git rev-list --all)
git rev-list --all | (while read rev; do git grep -e <regexp> $rev; done)

```

你这个需求用 github 网友的 pickaxe-diff 是最简洁舒适的 结合了 pickaxe-all 但是又不会 print 所有 log -p 无关的 diff  具体参考这里： https://gist.github.com/phil-blain/2a1cf81a0030001d33158e44a35ceda6 显示 Gist 代码 #limiting-diff-output





# tag

```sh
git tag -a v1.4 -m "my version 1.4"
```



```yml
推送代码: ggpush
推送tags: gpoat

```

## 删除tag

git  删除本地标签：



```css
git tag -d 标签名  

例如：git tag -d v3.1.0
```

git  删除远程标签：



```ruby
git push origin :refs/tags/标签名  

例如：git push origin :refs/tags/v3.1.0
```



### gomod命令小结

| **命令**             | **说明**                                                     |
| :------------------- | :----------------------------------------------------------- |
| `go mod download`    | 下载 go.mod 文件中指明的所有依赖                             |
| `go mod tidy`        | 整理现有的依赖，删除未使用的依赖                             |
| `go mod graph`       | 查看现有的依赖结构                                           |
| `go mod init`        | 生成 go.mod 文件 (Go 1.13 中唯一一个可以生成 go.mod 文件的子命令) |
| `go mod edit`        | 编辑 go.mod 文件                                             |
| `go mod vendor`      | 导出现有的所有依赖 (事实上 Go modules 正在淡化 Vendor 的概念) |
| `go mod verify`      | 校验一个模块是否被篡改过                                     |
| `go clean -modcache` | 清理所有已缓存的模块版本数据                                 |
| `go mod`             | 查看所有 go mod的使用命令                                    |



# gitlab-runner



```sh
$ sudo gitlab-runner register
Runtime platform                                    arch=amd64 os=linux pid=1757391 revision=ece86343 version=13.5.0
Running in system-mode.

Please enter the gitlab-ci coordinator URL (e.g. https://gitlab.com/):
https://gitlab.example.com/
Please enter the gitlab-ci token for this runner:
8LX6mbaPGYxxxxxxxxxx
Please enter the gitlab-ci description for this runner:
[hostname]: runner2
Please enter the gitlab-ci tags for this runner (comma separated):

Registering runner... succeeded                     runner=8LX6xxxx
Please enter the executor: parallels, shell, ssh, virtualbox, kubernetes, custom, docker, docker-ssh, docker+machine, docker-ssh+machine:
shell
Runner registered successfully. Feel free to start it, but if it's running already the config should be automatically reloaded!
```



# 使用代码仓库管理 GitLab CI 变量







> rules
>
> #### Complex rule clauses
>
> To conjoin `if`, `changes`, and `exists` clauses with an `AND`, use them in the same rule.
>
> In the following example:
>
> * If the `Dockerfile` file or any file in `/docker/scripts` has changed, and `$VAR` == "string value", then the job runs manually
> * Otherwise, the job isn't included in the pipeline.
>
> ```yml
> docker build:
>   script: docker build -t my-image:$CI_COMMIT_REF_SLUG .
>   rules:
>     - if: '$VAR == "string value"'
>       changes:  # Include the job and set to when:manual if any of the follow paths match a modified file.
>         - Dockerfile
>         - docker/scripts/*
>       when: manual
>       # - "when: never" would be redundant here. It is implied any time rules are listed.
> 	
> ```
>
> 





# Docker容器日志清理

 Docker容器日志清理

 原创

[品鉴初心](https://blog.51cto.com/wutengfei)2019-02-16 15:52:13博主文章分类：[Docker实战文档](https://blog.51cto.com/wutengfei/category20)©著作权

*文章标签*[docker](https://blog.51cto.com/topic/docker.html)[docker日志清理](https://blog.51cto.com/topic/docker-log-cleanup-1.html)[/var/lib/docker](https://blog.51cto.com/topic/varlibdocker.html)[linux](https://blog.51cto.com/topic/linux-2.html)[Docker](https://blog.51cto.com/topic/docker.html)*文章分类*[Docker](https://blog.51cto.com/nav/docker)[云计算](https://blog.51cto.com/nav/cloud)*阅读数*7066

# 前言

最近发现公司Gitlab服务器磁盘满了，经排查发现是docker容器日志占用了几十个G容量，那么这些日志怎么去查看和清理呢？

本节主要讲到的知识点如下：

* （1）Docker容器日志路径
* （2）如何清理Docker容器日志
* （3）如何从根本上解决Docker容器日志占用空间问题

# Docker容器日志路径

在linux上，容器日志一般存放在/var/lib/docker/containers/container_id/下面，以json.log结尾的文件（业务日志）。如下：

![Docker容器日志清理_docker](https://ws2.sinaimg.cn/large/006tKfTcgy1g08as7pq6jj31vu04q424.jpg)

# 如何清理Docker容器日志

使用命令：

```html
cat /dev/null  >  *-json.log 
```

当然你也可以使用`rm -rf`方式删除日志。但是对于正在运行的docker容器而言，你执行`rm -rf`命令后，通过df -h会发现磁盘空间并没有释放。

原因是在Linux或者Unix系统中，通过rm -rf或者文件管理器删除文件，将会从文件系统的目录结构上解除链接（unlink）。如果文件是被打开的（有一个进程正在使用），那么进程将仍然可以读取该文件，磁盘空间也一直被占用。

当然你也可以通过rm -rf删除后重启docker。

上面两种清除 docker 日志的方式，只是临时上将磁盘空间释放出来了，但是，这样清理之后，随着时间的推移，容器日志总有一天还会积累的很大。下面我们就从根本上解决这个问题～

# 如何从根本上解决Docker容器日志占用空间问题

* （1）方法一：设置一个容器服务的日志大小上限

我们要从根本上解决问题，一种方法是限制容器服务的日志大小上限。这个通过配置容器docker-compose的max-size选项来实现，如下：

```html
nginx: 
  image: nginx:1.12.1 
  restart: always 
  logging: 
    driver: “json-file” 
    options: 
      max-size: “5g” 

```

重启nginx容器之后，其日志文件的大小就被限制在5GB，再也不用担心了。

* （2）方法二：全局设置

新建/etc/docker/daemon.json，若有就不用新建了。添加log-dirver和log-opts参数，样例如下：

```html
# vim /etc/docker/daemon.json

{
  "log-driver":"json-file",
  "log-opts": {"max-size":"500m", "max-file":"3"}
}

```

说明⚠️：

设置的日志大小，只对新建的容器有效。

`max-size=500m`，意味着一个容器日志大小上限是500M

`max-file=3`，意味着一个容器有三个日志，分别是id+.json、id+1.json、id+2.json

```html
// 重启docker守护进程

# systemctl daemon-reload

# systemctl restart docker

```

> **参考文档**
>
>  Docker[容器日志查看与清理](https://blog.csdn.net/yjk13703623757/article/details/80283729)





## 提权

可以直接使用 Docker 官方镜像仓库中的 docker:dind 镜像, 但是在运行时， 需要指定 `--privileged` 选项



https://zhuanlan.zhihu.com/p/41330476





