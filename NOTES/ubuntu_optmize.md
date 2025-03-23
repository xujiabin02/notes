- Ubuntu/Debian 

  镜像

   优化 

  


    以ubuntu-16.04.6-server-amd64.iso为例，介绍Ubuntu和Debian镜像的优化方法。Ubuntu系统安装完成后，默认使用普通权限用户。

- ssh服务优化，修改/etc/ssh/sshd_config文件，将PermitRootLogin属性修改为yes 将UseDNS属性修改为no，若没有上述属性，请添加属性。

  

  ```
    $ sudo vi /etc/ssh/sshd_config
    *# 分别找到PermitRootLogin属性和UseDNS属性*
    PermitRootLogin yes
    UseDNS no
  ```

- 在/etc/init.d/目录下创建一个名称为ssh-initkey的自启动脚本。

  

  ```
    $ sudo touch /etc/init.d/ssh-initkey
    $ sudo vi /etc/init.d/ssh-initkey
    *# 脚本内容如下：*
    *#! /bin/sh*
    *### BEGIN INIT INFO*
    *# Provides:          ssh-initkey*
    *# Required-Start:*
    *# Required-Stop:*
    *# X-Start-Before:    ssh*
    *# Default-Start:     2 3 4 5*
    *# Default-Stop:*
    *# Short-Description: Init ssh host keys*
    *### END INIT INFO*
    
    PATH=/sbin:/usr/sbin:/bin:/usr/bin
    . /lib/init/vars.sh
    . /lib/lsb/init-functions
    do_start() {
      ls /etc/ssh/ssh_host_* > /dev/null 2>&1
      if [ $? -ne 0 ]; then
          dpkg-reconfigure openssh-server
      fi
    }
    case "$1" in
      start)
      do_start
          ;;
      restart|reload|force-reload)
          echo "Error: argument '$1' not supported" >&2
          exit 3
          ;;
      stop)
          ;;
      *)
          echo "Usage: $0 start|stop" >&2
          exit 3
          ;;
    esac
  ```

- ssh-initkey脚本配置完成后，还需要增加可执行权限，并将脚本添加到系统启动脚本目录。

  

  ```
    $ sudo chmod +x /etc/init.d/ssh-initkey
  ```


    Ubuntu 20.04之前版本，请执行以下脚本启用脚本：

  

  ```
    $ sudo /usr/sbin/update-rc.d ssh-initkey defaults
    $ sudo /usr/sbin/update-rc.d ssh-initkey enable
  ```

  
    Ubuntu 20.04版本以及之后版本，请执行以下脚本启用脚本：

  

  ```
    $ sudo /lib/systemd/systemd-sysv-install enable ssh-initkey
  ```

- （Ubuntu 16.04以上版本设置）关闭网卡持久化功能，保证网卡名称为“eth0，eth1”形式。修改/etc/default/grub文件，在GRUB_CMDLINE_LINUX中添加"net.ifnames=0 biosdevname=0"参数。

  

  ```
    $ sudo vi /etc/default/grub
    *# 配置GRUB_CMDLINE_LINUX参数*
    GRUB_CMDLINE_LINUX="net.ifnames=0 biosdevname=0"
  ```

  

  ```
    *# 使配置生效*
    $ sudo /usr/sbin/update-grub
  ```

- (若Ubuntu未关闭自动更新)关闭自动更新需要修改/etc/apt/apt.conf.d/10periodic文件，将文件中的"Update-Package-Lists"参数设置为0。

  

  ```
    $ sudo vi /etc/apt/apt.conf.d/10periodic
    *# 配置修改*
    APT::Periodic::Update-Package-Lists "0";
  ```

- 至此，虚拟机优化完成。