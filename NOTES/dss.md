# DSS+Linkis

# [DSS+Linkis Ansible 单机一键安装脚本](https://github.com/wubolive/dss-linkis-ansible)

## 一、简介

为解决繁琐的部署流程，简化安装步骤，本脚本提供一键安装最新版本的DSS+Linkis环境；部署包中的软件采用我自己编译的安装包，并且为最新版本：`DSS1.1.1` + `Linkis1.3.0`。

### 1.1 版本介绍

以下版本及配置信息可参考安装程序`hosts`文件中的`[all:vars]`字段。

| 软件名称         | 软件版本     | 应用路径              | 测试/连接命令                            |
| ---------------- | ------------ | --------------------- | ---------------------------------------- |
| MySQL            | mysql-5.6    | /usr/local/mysql      | mysql -h 127.0.0.1 -uroot -p123456       |
| JDK              | jdk1.8.0_171 | /usr/local/java       | java -version                            |
| Python           | python 2.7.5 | /usr/lib64/python2.7  | python -V                                |
| Nginx            | nginx/1.20.1 | /etc/nginx            | nginx -t                                 |
| Hadoop           | hadoop-2.7.2 | /opt/hadoop           | hdfs dfs -ls /                           |
| Hive             | hive-2.3.3   | /opt/hive             | hive -e "show databases"                 |
| Spark            | spark-2.4.3  | /opt/spark            | spark-sql -e "show databases"            |
| dss              | dss-1.1.1    | /home/hadoop/dss      | http://<服务器IP>:8085                   |
| links            | linkis-1.3.0 | /home/hadoop/linkis   | http://<服务器IP>:8188                   |
| zookeeper        | 3.4.6        | /usr/local/zookeeper  | 无                                       |
| DolphinScheduler | 1.3.9        | /opt/dolphinscheduler | http://<服务器IP>:12345/dolphinscheduler |
| Visualis         | 1.0.0        | /opt/visualis-server  | http://<服务器IP>:9088                   |
| Qualitis         | 0.9.2        | /opt/qualitis         | http://<服务器IP>:8090                   |
| Streamis         | 0.2.0        | /opt/streamis         | http://<服务器IP>:9188                   |
| Sqoop            | 1.4.6        | /opt/sqoop            | sqoop                                    |
| Exchangis        | 1.0.0        | /opt/exchangis        | http://<服务器IP>:8028                   |

## 二、部署前注意事项

**要求**：

- 本脚本仅在`CentOS 7`系统上测试过，请确保安装的服务器为`CentOS 7`。
- 仅安装DSS+Linkis服务器内存至少16G，安装全部服务内存至少32G。
- 安装前请关闭服务器防火墙及SElinux，并使用`root`用户进行操作。
- 安装服务器必须通畅的访问互联网，脚本需要yum下载一些基础软件。
- 保证服务器未安装任何软件，包括不限于`java`、`mysql`、`nginx`等，最好是全新系统。
- 必须保证服务器除`lo:127.0.0.1`回环地址外，仅只有一个IP地址，可使用`echo $(hostname -I)`命令测试。

## 三、部署方法

本案例部署主机IP为`192.168.1.52`，以下步骤请按照自己实际情况更改。

### 3.1 安装前设置

```
### 安装ansible
$ yum -y install epel-release
$ yum -y install ansible

### 配置免密
$ ssh-keygen -t rsa
$ ssh-copy-id root@192.168.1.52

### 关闭防火墙及SELinux
$ systemctl stop firewalld.service && systemctl disable firewalld.service
$ sed -i 's/^SELINUX=enforcing$/SELINUX=disabled/' /etc/selinux/config && setenforce 0
```



### 3.2 部署linkis+dss

```
### 获取安装包
$ git clone https://github.com/wubolive/dss-linkis-ansible.git
$ cd dss-linkis-ansible

### 目录说明
dss-linkis-ansible
├── ansible.cfg    # ansible 配置文件
├── hosts          # hosts主机及变量配置
├── playbooks      # playbooks剧本
├── README.md      # 说明文档
└── roles          # 角色配置

### 配置部署主机（注：ansible_ssh_host的值不能设置127.0.0.1）
$ vim hosts
[deploy]
dss-service ansible_ssh_host=192.168.1.52 ansible_ssh_port=22

### 下载安装包到download目录(如果下载失败，可以手动下载放到该目录)
$ ansible-playbook playbooks/download.yml

### 一键安装Linkis+DSS
$ ansible-playbook playbooks/all.yml
......
TASK [dss : 打印访问信息] *****************************************************************************************
ok: [dss-service] => {
    "msg": [
        "*****************************************************************", 
        "              访问 http://192.168.1.52 查看访问信息                 ", 
        "*****************************************************************"
    ]
}
```



执行结束后，即可访问：[http://192.168.1.52](http://192.168.1.52/) 查看信息页面，上面记录了所有服务的访问地址及账号密码。

[![image](https://user-images.githubusercontent.com/31678260/209619054-b776a4e6-2044-4855-8185-e57a269d2306.png)](https://user-images.githubusercontent.com/31678260/209619054-b776a4e6-2044-4855-8185-e57a269d2306.png)

### 3.3 部署其它服务

```
# 安装dolphinscheduler
$ ansible-playbook playbooks/dolphinscheduler.yml
### 注: 安装以下服务必须优先安装dolphinscheduler调度系统
# 安装visualis
$ ansible-playbook playbooks/visualis.yml 
# 安装qualitis
$ ansible-playbook playbooks/qualitis.yml
# 安装streamis
$ ansible-playbook playbooks/streamis.yml
# 安装exchangis
$ ansible-playbook playbooks/exchangis.yml
```



### 3.4 维护指南

```
### 查看实时日志
$ su - hadoop
$ tail -f ~/linkis/logs/*.log ~/dss/logs/*.log

### 启动服务（如服务器重启可使用此命令一建启动）
$ ansible-playbook playbooks/all.yml -t restart
# 启动其它服务
$ sh /usr/local/zookeeper/bin/zkServer.sh start
$ su - hadoop
$ cd /opt/dolphinscheduler/bin &&  sh start-all.sh 
$ cd /opt/visualis-server/bin && sh start-visualis-server.sh
$ cd /opt/qualitis/bin/ && sh start.sh
$ cd /opt/streamis/streamis-server/bin/ && sh start-streamis-server.sh
$ cd /opt/exchangis/sbin/ && ./daemon.sh start server
```



使用问题请访问官方QA文档：https://docs.qq.com/doc/DSGZhdnpMV3lTUUxq