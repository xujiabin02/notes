# k8s

https://www.kubernetes.org.cn/4022.html

# ubuntu20

```sh
sudo apt install nfs-kernel-server
sudo cat /proc/fs/nfsd/versions
sudo mount --bind /data/m1/nfs/ /srv/nfs4/data
```

> /etc/fstab
>
> ```sh
> /opt/backups /srv/nfs4/backups  none   bind   0   0
> ```
>
> 



> /etc/exports
>
> ```sh
> /srv/nfs4  10.1.0.0/16(rw,sync,no_subtree_check,crossmnt,fsid=0)
> /srv/nfs4/data 10.1.0.0/16(rw,sync,no_subtree_check,no_root_squash) 
> ```
>
> 第一行包含`fsid=0`定义NFS根目录`/srv/nfs4`。仅允许来自`192.168.33.0/24`子网的客户端对此NFS访问权限。`crossmnt`选项是必需的，它用于共享目录和导出子目录。
>
> 第二行显示如何为一个文件系统指定多个导出规则。它导出`/srv/nfs4/backups`目录，只允许`192.168.33.0/24`网段的客户端有读的权限，并且仅允许IP地址是`192.168.33.3`的客户端具有读和写权限。`sync`选项告诉NFS在恢复之前将更改写入磁盘。
>
> 最后一行应该是不言自明的了。所有可用选项的更多信息，请在终端中输入`man exports`查看手册。
>
> 

保存文件并退出vim编辑器，然后运行命令导出目录`sudo exportfs -ra`。

```sh
sudo exportfs -ra
```

k8s的子节点上需要安装nfs client

```sh
mount -t nfs -o vers=4 10.1.198.115:/data /data/nfs
mount.nfs4  10.1.198.115:/data/demo /data/nfs
```



# centos nfs client

```
sudo yum install nfs-utils -y
```



# 开机启动

## rc.local 



1. 配置自动挂载。

   - 方案一（推荐使用）： 打开

      

     /etc/fstab

      

     配置文件，添加挂载命令。

     **说明** 如果您是在CentOS 6.x系统中配置自动挂载，您需先执行`chkconfig netfs on`命令，保证netfs开机自启动。

     - 如果您要挂载NFS v4文件系统，添加以下命令：

       ```javascript
       file-system-id.region.nas.aliyuncs.com:/ /mnt nfs vers=4,minorversion=0,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,_netdev,noresvport 0 0
       ```

     - 如果您要挂载NFS v3文件系统，添加以下命令：

       ```javascript
       file-system-id.region.nas.aliyuncs.com:/ /mnt nfs vers=3,nolock,proto=tcp,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,_netdev,noresvport 0 0
       ```

   - 方案二：打开

     /etc/rc.local

     配置文件，添加挂载命令。

     **说明** 在配置/etc/rc.local文件前，请确保用户对/etc/rc.local和/etc/rc.d/rc.local文件有可执行权限。例如：CentOS 7.x系统，用户默认无可执行权限，需添加权限后才能配置/etc/rc.local文件。

     - 如果您要挂载NFS v4文件系统，添加以下命令：

       ```javascript
       sudo mount -t nfs -o vers=4,minorversion=0,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,_netdev,noresvport file-system-id.region.nas.aliyuncs.com:/ /mnt
       ```

     - 如果您要挂载NFS v3文件系统，添加以下命令：

       ```javascript
       sudo mount -t nfs -o vers=3,nolock,proto=tcp,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,_netdev,noresvport file-system-id.region.nas.aliyuncs.com:/ /mnt
       ```

     命令中各参数说明如下表所示。

     | 参数                                          | 说明                                                         |
     | :-------------------------------------------- | :----------------------------------------------------------- |
     | file-system-id.region.nas.aliyuncs.com:/ /mnt | 表示<挂载点地址>：<NAS文件系统目录> <当前服务器上待挂载的本地路径>，请根据实际情况替换。 |
     | vers                                          | 文件系统版本，目前只支持nfs v3和nfs v4。                     |
     | _netdev                                       | 防止客户端在网络就绪之前开始挂载文件系统。                   |
     | 0（noresvport 后第一项）                      | 非零值表示文件系统应由dump备份。对于NAS，此值为0。           |
     | 0（noresvport 后第二项）                      | 该值表示fsck在启动时检查文件系统的顺序。对于NAS文件系统，此值应为0，表示 fsck不应在启动时运行。 |
     | 挂载选项                                      | 挂载文件系统时，可选择多种挂载选项，详情情参见下表。         |



## autofs