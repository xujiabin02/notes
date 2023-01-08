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