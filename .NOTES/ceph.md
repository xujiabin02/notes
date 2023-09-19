# 版本

选择 16.2.6

# ceph Numerical result out of range (this can be due to a pool or placement group misconfiguration

```sh
ceph config set global mon_max_pg_per_osd 1200
```



# upgrade



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

```sh
ceph mgr module disable dashboard
ceph mgr module enable dashboard
```

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