# yum 查询包版本与rpm包下载

# 查询版本号

某些场景下我们需要安装某些软件的特定版本，这个时候就需要在yum仓库中查询包版本号。例如查询 cri-tools 这个软件的版本如下：

```
yum -v list cri-tools --show-duplicates
yum --showduplicates list cri-tools
```

![image-20211127124046138](.img_centos/image-20211127124046138.png)

列出的版本信息具体内容是：

```
package_name.architecture  version_number–build_number  repository
```

# 下载rpm

在知道rpm包版本好后，我们希望将其下载下来，以供内网环境安装。用如下方法下载:

```
yum install --downloadonly --downloaddir=/tmp/ [package-name]-[version].[architecture]

# 例如：
yum install --downloadonly --downloaddir=/tmp/ cri-tools-1.0.0_beta.1-0
```



# 8.4  yum 源





```sh
sudo sed -e "s|^mirrorlist=|#mirrorlist=|g" \
         -e "s|^baseurl=http://mirrors.cloud.aliyuncs.com/\$contentdir/\$releasever|baseurl=https://mirrors.tuna.tsinghua.edu.cn/centos-vault/centos/8/$minorver|g" \
         -i.bak \
         /etc/yum.repos.d/CentOS-*.repo

sudo yum makecache

```



# netstat / ss





```

```



> CentOS Linux 8 - AppStream                       70  B/s |  38  B     00:00    
>
> **Error: Failed to download metadata for repo 'appstream': Cannot prepare internal mirrorlist: No URLs in mirrorlist**
>
> ==解决方法==
>
> 1. **IF** mirror.centos.org => vault.cetnos.org
>
> ```sh
> sed -e 's/mirrorlist/#mirrorlist/g' -e 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' -i.bak /etc/yum.repos.d/CentOS-*.repo 
> sudo yum makecache
> ```
>
> 2. **IF** aliyuncs => tuna
>
> ```sh
> sudo sed -e "s|^mirrorlist=|#mirrorlist=|g" \
>          -e "s|^baseurl=http://mirrors.cloud.aliyuncs.com/\$contentdir/\$releasever|baseurl=https://mirrors.tuna.tsinghua.edu.cn/centos-vault/centos/8/$minorver|g" \
>          -i.bak \
>          /etc/yum.repos.d/CentOS-*.repo
> 
> sudo yum makecache
> ```
>
> 







#   unbound variable



when

```sh
set -ue
if [ -n "$pasdwcfsf" ]
then
  echo OK
fi
```

Very close to what you posted, actually. You can use something called [Bash parameter expansion](https://www.gnu.org/software/bash/manual/html_node/Shell-Parameter-Expansion.html) to accomplish this.

To get the assigned value, or `default` if it's missing:

```sh
FOO="${VARIABLE:-default}"  # If variable not set or null, use default.
# If VARIABLE was unset or null, it still is after this (no assignment done).
```

Or to assign `default` to `VARIABLE` at the same time:

```sh
FOO="${VARIABLE:=default}"  # If variable not set or null, set it to default.
```



^PS:  [Default shell variables value](https://bash.cyberciti.biz/guide/Default_shell_variables_value)



# 阿里云linux[磁盘扩容](https://help.aliyun.com/document_detail/113316.html)



```sh
growpart /dev/vdb 1
resize2fs /dev/vdb1
```

