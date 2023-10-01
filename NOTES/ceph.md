# 调研

|                                                              |                                                              |      |
| ------------------------------------------------------------ | ------------------------------------------------------------ | ---- |
| [阿里盘古](https://polarisary.github.io/2018/04/13/pangu/)   |                                                              |      |
| [百度](https://blog.csdn.net/shudaqi2010/article/details/70766179) |                                                              |      |
| [网易云音乐](https://mp.weixin.qq.com/s/FZuWNIVPMX8L-w1PxwPZHA) | [github](https://github.com/opencurve/curve/blob/master/README_cn.md) |      |



# 实践经验

## 内核BUG导致的ceph IO缓慢

尽管上述的监控措施，理论上可以检测到 Ceph中的问题，但并不意味着运维变得简单。Ceph Mgr向外界传递的许多参数都是由系统中各个OSD的指标值生成的。这些值成千上万，即使是很有经验的Ceph开发人员，弄清楚这些值之间的关系也是一件费脑的事情：知道集群中存在缓慢的写入是一件事；但是，更紧要的任务是快速查找出故障根源。这个过程需要大量的实践经验，且相当困难。



以下是一个具有多年资深经验的Ceph运维工程师描述的例子，描述了如何使用监控细节来诊断Ceph中的性能问题的思路。遗憾的是，这个故障诊断过程并不能合理地自动化。

这是一个总容量约为2.5PB的Ceph集群，主要用于OpenStack。当用户启动一个使用Ceph 中的RBD映像作为根文件系统硬盘的虚拟机时，一个烦人的状态时常会发生：虚拟机在几分钟内遭受I/O停顿并且在一段时间内不可用，一段时间后情况恢复正常，但问题周期性地再次出现。在问题没有出现时，对VM卷的写入操作可达到1.5GB/每秒。



在监控系统也显示了前面描述的卡顿或缓慢写入，但无法辨别究竟与哪个OSD相关。相反，它们分布在系统中的所有OSD中。进一步排查发现，问题与OpenStack无关，因为不经过Openstack的本地RBD映像，也会出现类似的性能问题。



首先怀疑的是网络。然而，经过使用Iperf和类似工具进行的大量测试后，推翻了这种怀疑。在Ceph集群的clients之间，双25Gbit/s LACP链路在Iperf测试中可以达到25Gbit/s以上，且是可靠的。当所有涉及到的NIC和网络交换机上的错误计数器都保持在0时，事情开始变得毫无头绪。



从这里开始需要更深入的故障排查技巧，即开启OSDdebug来跟踪数据写入过程。一旦监控到缓慢的写入过程，就重点检查OSD的日志。事实上，每个OSD都保存着它执行的许多操作的内部记录，主OSD日志还包含单独的条目，显示该对象到辅助OSD的复制操作的开始和结束。使用dump_ops_in_flight命令可以显示OSD当前在Ceph中执行的所有操作，也可以使用dump_historic_slow_ops挖掘过去的慢操作。dump_historic_ops也可用于显示有关所有先前操作的日志消息。利用这些工具，更深入的监控成为可能：现在可以为单个慢速写入找到主OSD，然后所涉及的OSD揭示它计算了哪些辅助OSD的信息。例如，它们在同一写入过程的日志中的消息适用于提供有关有缺陷的HDD相关信息。

![图片](.img_ceph/640.png)

按照上述的排查发现，Primary OSD花在等Secondary  OSD响应的大部分时间里，请求到达Secondary OSD往往需要几分钟时间；一旦写入请求实际到达Secondray OSD，它们就会在几毫秒内完成。



由于已经排除了网络硬件故障的可能性，故障的源头指向Ceph的问题。经过大量试验和试错后，焦点落在了所涉及系统的数据包过滤器上。最后的结果出入意料，CentOS 8默认使用的Nftables（iptables 后继者）被证实是问题的根源。这不是配置错误：而是Linux内核中的一个Bug，导致数据包过滤器在某些情况下会因为不明确的模式阻止了数据的正常通信，几分钟中又能恢复通信。这解释了为什么Ceph中的问题出现的非常不稳定。更新到较新的内核最后解决了这个问题。



这个例子清楚地表明：Ceph中的自动化性能监控虽然很强大。但由于Ceph本身的复杂性，管理员通常会面临漫长的故障定位与排查过程。同时，这个例子也证实，使用专用存储厂商的Ceph发行版本非常重要，可以有效地排除各种软硬件与操作系统内核之前的兼容性问题。目前，市场上主流的Ceph厂家除了传统IT大厂如华为、浪潮、新华三，还有新兴的分布式存储专业厂家如道熵、Xsky、杉岩等。

# 概念

|                 |                                                              |      |
| --------------- | ------------------------------------------------------------ | ---- |
| *RGW*           | Ceph对象网关，提供了一个兼容S3和Swift的restful API接口。RGW还支持多租户和Openstack的keystone身份验证服务。 |      |
| **RADOS**       | *Reliable Autonomic Distributed Object Store, RADOS*是Ceph 存储集群的基础。Ceph 中的一切都以对象的形式存储，而RADOS 就负责存储这些对象，而不考虑它们的数据类型。RADOS 层确保数据一致性和可靠性。对于数据一致性，它执行数据复制、故障检测和恢复。还包括数据在集群节点间的recovery。 |      |
| **Librados**    | 基于rados对象在功能层和开发层进行的抽象和封装,提供给开发者   |      |
| **RadosGW API** | 通用、固定、易用的少数使用维度的接口, 提供给使用者           |      |
|                 |                                                              |      |

![img](.img_ceph/1cd90748cd554f4438eeaa3796417582.jpeg)

# No matching hosts for label _admin

`unable to calc client keyring client.admin placement PlacementSpec(label='_admin'): Cannot place : No matching hosts for label _admin`

```sh
ceph orch host label add dp01 _admin
```



# centos7/8安装

```
rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org

```

To install ELRepo for RHEL-**9**:





```
yum install https://www.elrepo.org/elrepo-release-9.el9.elrepo.noarch.rpm
```

To install ELRepo for RHEL-**8**:



```
yum install https://www.elrepo.org/elrepo-release-8.el8.elrepo.noarch.rpm
```

To install ELRepo for RHEL-**7**, SL-**7** or CentOS-**7**:



```
yum install https://www.elrepo.org/elrepo-release-7.el7.elrepo.noarch.rpm
```

To make use of our mirror system, **please also install yum-plugin-fastestmirror**.

# LVM

```sh
查看osd fsid
ceph-volume lvm list
```



## 移除方式

当部署异常的时候，可以使用下面的命令删除掉集群信息重新部署

```shell
ceph orch pause
ceph fsid
cephadm rm-cluster --force --zap-osds --fsid <fsid>
```

# 调整mon数量默认值

```sh
ceph orch apply mon 3
```

# already in use

```sh
ceph orch rm [service]
ceph orch apply [service]
```



# 版本

选择 16.2.6

# ceph Numerical result out of range (this can be due to a pool or placement group misconfiguration

```sh
ceph config set global mon_max_pg_per_osd 1200
```



# upgrade

https://www.cnblogs.com/varden/p/15966141.html

https://www.cnblogs.com/varden/p/15965326.html

```
docker pull quay.io/ceph/ceph:v16.2.6
ceph orch upgrade start --ceph-version 16.2.6
```



# chronyd

`ERROR: No time synchronization is active`

```shell
systemctl enable chroynd
systemctl start chroynd
```

# Ceph pg_num

> `placement groups，它是ceph的逻辑存储单元`数据存储到cesh时，先打散成一系列对象，再结合基于对象名的哈希操作、复制级别、PG数量，产生目标PG号。根据复制级别的不同，每个PG在不同的OSD上进行复制和分发。可以把PG想象成存储了多个对象的逻辑容器，这个容器映射到多个具体的OSD。PG存在的意义是提高ceph存储系统的性能和扩展性。
>
> 



```sh
rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
yum install https://www.elrepo.org/elrepo-release-7.el7.elrepo.noarch.rpm
yum install https://www.elrepo.org/elrepo-release-8.el8.elrepo.noarch.rpm
```

# crash

```
ceph crash ls
ceph crash info <id>
ceph crash rm <id>
```



# create user error

```
ceph osd pool get default-zone.rgw.control pg_num 
ceph osd pool set default-zone.rgw.control pg_num 16
ceph osd pool set default-zone.rgw.control pgp_num 16
ceph osd pool get cephfs_data pgp_num 
ceph osd pool set cephfs_data pgp_num 16
ceph osd pool set cephfs_data pg_num 16
ceph osd pool set cephfs_metadata pg_num 16
ceph osd pool set cephfs_metadata pgp_num 16
```

# RGW REST API failed request with status code 403 

15.2升级到16.2.6解决

# eph版本发行生命周期

2022年5月8日

[暂无评论](https://blog.whsir.com/post-6687.html#respond)

ceph从Nautilus版本（14.2.0）开始，每年都会有一个新的稳定版发行，预计是每年的3月份发布，每年的新版本都会起一个新的名称（例如，“Mimic”）和一个主版本号（例如，13 代表 Mimic，因为“M”是字母表的第 13 个字母）。



版本号的格式为x.y.z，x表示发布周期（例如，13 代表 Mimic，17代表Quincy），y表示发布版本类型，即

x.0.z - y等于0，表示开发版本
x.1.z - y等于1，表示发布候选版本（用于测试集群）
x.2.z - y等于2，表示稳定/错误修复版本（针对用户）

稳定版本的生命周期在第一个发布月份后，大约2年时间将停止该版本的更新维护，具体版本发布时间见下表。

在Octopus版本后使用cephadm来部署ceph集群，如果使用cephadm部署，在后期新的版本升级时，可以做到完全自动化，并可以通过ceph -W cephadm查看升级进度，升级完成后，无法降级，升级时请不要跨版本升级，例如：当前使用Octopus升级到Quincy，要先把Octopus升级到Pacific，然后在升级至Quincy，这是最稳妥的方式。

| 版本       | 主版本号 | 初始发行时间 | 停止维护时间 |
| :--------- | :------- | :----------- | :----------- |
| Quincy     | 17       | 2022-04-19   | 2024-06-01   |
| Pacific    | 16       | 2021-03-31   | 2023-06-01   |
| Octopus    | 15       | 2020-03-23   | 2022-06-01   |
| Nautilus   | 14       | 2019-03-19   | 2021-06-30   |
| Mimic      | 13       | 2018-06-01   | 2020-07-22   |
| Luminous   | 12       | 2017-08-01   | 2020-03-01   |
| Kraken     | 11       | 2017-01-01   | 2017-08-01   |
| Jewel      | 10       | 2016-04-01   | 2018-07-01   |
| Infernalis | 9        | 2015-11-01   | 2016-04-01   |
| Hammer     | 8        | 2015-04-01   | 2017-08-01   |
| Giant      | 7        | 2014-10-01   | 2015-04-01   |
| Firefly    | 6        | 2014-05-01   | 2016-04-01   |
| Emperor    | 5        | 2013-11-01   | 2014-05-01   |
| Dumpling   | 4        | 2013-08-01   | 2015-05-01   |

[主要参考](https://www.koenli.com/ef5921b8.html)