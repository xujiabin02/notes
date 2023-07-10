# 反常识

单节点情况下,  seqscan 比 index 要快

| 2800W数据 | seqscan | index |
| --------- | ------- | ----- |
| count(1)  | 39      | 398   |
|           | 7       |       |
|           |         |       |



# greenplum 物理存储对应



## 数据目录

greenplum 初始化时指定 segment 数据存储位置，查看 `gpinitsystem_config` 文件，假设内容如下：

```plaintext
...
SEG_PREFIX=udwseg
...

declare -a DATA_DIRECTORY=(/data/primary /data/primary)
...

declare -a MIRROR_DATA_DIRECTORY=(/data/mirror /data/mirror)
...
```

该配置文件指定了 2 个 primay 和 2 个 mirror，primary 的存储位置在 `/data/primary`，mirror 的存储位置在 `/data/mirror`

具体到每个 segment，存储位置在 `/data/primary/udwseg<id>/base`

## database 存储位置

在 `base` 目录中，会按照不同 database 分成不同的子目录，子目录名是 database 的 oid。运行以下 sql 可以查看不同 database 的 oid:

```sql
select oid, datname from pg_database;
```

假如有以下结果：

```plaintext
postgres=# select oid, datname from pg_database;
   oid   |      datname
---------+-------------------
   12025 | postgres
   16386 | dev
       1 | template1
   12024 | template0
```

则 `dev` database 的数据存储在各个节点的 `/data/[primary|mirror]/udwseg<id>/base/16386` 中

## table 存储文件

table 对应的数据文件在各节点的 `/data/[primary|mirror]/udwseg<id>/base/<db.oid>` 中，文件名是该 table 的 relfilenode

每个文件默认大小 1G，当 table 对应的内容超过 1G 时，对对文件进行切分，对应的文件列表为：

```
 /data/[primary|mirror]/udwseg/base// /data/[primary|mirror]/udwseg/base//.1 /data/[primary|mirror]/udwseg/base//.2 /data/[primary|mirror]/udwseg/base//.3 ... 
```

不同 segment 上查询相同的表，relfilenode (可能)不一致，可以在对应的节点上指定 segment 端口登录：

```plaintext
PGOPTIONS='-c gp_session_role=utility' psql -p 40001
```

切换到对应的 database, 查询 `dev` database 下的 `products` 表的 relfilenode

```sql
\c dev
select oid, relname, relfilenode from pg_class where relname='products';
 oid | relname | relfilenode ——-+———-+————- 16387 | products | 16384 
```

## 查看数据占用（检查数据倾斜）

### 数据库数据占用

根据数据库 `oid` 查看数据库占用大小：

```bash
du -b /data/primary/udwseg*/base/<oid>
```

查看不同节点下数据库数据占用大小

```bash
gpssh -f /usr/local/gpdb/conf/nodes -e "du -b /data/primary/udwseg*/base/16386" | grep -v "du -b"
```

进行统计：

```bash
gpssh -f /usr/local/gpdb/conf/nodes -e \
    "du -b /data/primary/udwseg*/base/<oid>" | \
    grep -v "du -b" | sort | awk -F" " '{ arr[$1] = arr[$1] + $2 ; tot = tot + $2 }; END \
    { for ( i in arr ) print "Segment node" i, arr[i], "bytes (" arr[i]/(1024**3)" GB)"; \
    print "Total", tot, "bytes (" tot/(1024**3)" GB)" }' -
```

### 表数据占用

运行以下命令，替换 `db.oid` 和 `relfilenode`，可以统计 `db.oid` 数据库下 `relfilenode` 表文件占用磁盘存储：

```bash
find /data/primary/udwseg*/base/<db.oid> -name '<relfilenode>*'  | xargs ls -al | awk 'BEGIN {sum=0} {sum+=$5} END {print sum}'
```

在所有节点上执行：

```shell
gpssh -f /usr/local/gpdb/conf/nodes

=> find /data/primary/udwseg*/base/16387 -name '24272176*'  | xargs ls -al | awk 'BEGIN {sum=0} {sum+=$5} END {print sum}'
```



# 免密登录

这篇文章记录一下使用PostgreSQL的psql客户端免密码登录的几种方法。

## 环境说明

环境设定详细可参看下文：

- https://liumiaocn.blog.csdn.net/article/details/108314226

## 现象

可以看到缺省情况下，是需要通过提示的方式让用户输入密码的。

```none
liumiaocn:postgres liumiao$ psql -h localhost -p 5432 postgres postgres
Password for user postgres: 
psql (12.4)
Type "help" for help.

postgres=# 
```

## 方法1：使用环境变量PGPASSWORD

可以通过设定环境变量PGPASSWORD，其中设定为密码，然后export出来之后，psql就会使用此环境变量的值了。

```shell
liumiaocn:postgres liumiao$ export PGPASSWORD=liumiaocn;psql -h localhost -p 5432 postgres postgres;
psql (12.4)
Type "help" for help.

postgres=# 
```

## 方法2: 客户端个人目录下的.pgpass文件

通过提供客户端个人目录下的.pgpass文件，在此文件中提供相关信息，从而使得psql在执行时能够找到密码不再提示输入，格式信息如下所示：

> 格式信息：主机名或者IP:端口:数据库名:用户名:密码

另外还需要注意权限必须是600，否则也不起作用，因为此密码明文保存，在文件访问时600权限能够保证Owner之外的用户无法查看内容，在操作系统层面上对密码的安全做了一定的控制，算是聊胜于无。如果不满足的话, 是不会起作用的，比如644的权限的情况下：

```sh
liumiaocn:~ liumiao$ ls -l ${HOME}/.pgpass
-rw-r--r--  1 liumiao  staff  43 Aug 31 07:20 /Users/liumiao/.pgpass
liumiaocn:~ liumiao$ cat ${HOME}/.pgpass
localhost:5432:postgres:postgres:liumiaocn
liumiaocn:~ liumiao$ psql -h localhost -p 5432 postgres postgres
WARNING: password file "/Users/liumiao/.pgpass" has group or world access; permissions should be u=rw (0600) or less
Password for user postgres: 
```



只修改一下权限为600，即可成功

```shell
liumiaocn:~ liumiao$ chmod 600 ${HOME}/.pgpass
liumiaocn:~ liumiao$ ls -l ${HOME}/.pgpass
-rw-------  1 liumiao  staff  43 Aug 31 07:20 /Users/liumiao/.pgpass
liumiaocn:~ liumiao$ psql -h localhost -p 5432 postgres postgres
psql (12.4)
Type "help" for help.

postgres=# 
```





# 部署GP7

https://docs.vmware.com/en/VMware-Tanzu-Greenplum/7/greenplum-database/GUID-install_guide-init_gpdb.html



# [Greenplum扩容详解](https://www.cnblogs.com/zsql/p/14602563.html)

------

随着收集额外数据并且现有数据的定期增长，数据仓库通常会随着时间的推移而不断增长。 有时，有必要增加数据库能力来联合不同的数据仓库到一个数据库中。 数据仓库也可能需要额外的计算能力（CPU）来适应新增加的分析项目。 在系统被初始定义时就留出增长的空间是很好的，但是即便用户预期到了高增长率，提前太多在资源上投资通常也不明智。 因此，用户应该寄望于定期地执行一次数据库扩容项目。Greenplum使用gpexpand工具进行扩容，所以本文首先会介绍下gpexpand工具。本文为博客园作者所写： [一寸HUI](https://home.cnblogs.com/u/zsql/)，个人博客地址：https://www.cnblogs.com/zsql/

## 一、gpexpand介绍

gpexpand是在阵列中的新主机上扩展现有的Greenplum数据库的一个工具，使用方法如下：



```
gpexpand [{-f|--hosts-file} hosts_file]
                | {-i|--input} input_file [-B batch_size]
                | [{-d | --duration} hh:mm:ss | {-e|--end} 'YYYY-MM-DD hh:mm:ss'] 
        [-a|-analyze] 
                  [-n  parallel_processes]
                | {-r|--rollback}
                | {-c|--clean}
        [-v|--verbose] [-s|--silent]
        [{-t|--tardir} directory ]
        [-S|--simple-progress ]
        
        gpexpand -? | -h | --help 
        
        gpexpand --version
```

参数详解:

```
-a | --analyze
    在扩展后运行ANALYZE更新表的统计信息，默认是不运行ANALYZE。
-B batch_size
    在暂停一秒钟之前发送给给定主机的远程命令的批量大小。默认值是16， 有效值是1-128。
    gpexpand工具会发出许多设置命令，这些命令可能会超出主机的已验证 连接的最大阈值（由SSH守护进程配置中的MaxStartups定义）。该一秒钟 的暂停允许在gpexpand发出更多命令之前完成认证。
    默认值通常不需要改变。但是，如果gpexpand由于连接错误 （例如'ssh_exchange_identification: Connection closed by remote host.'）而失败，则可能需要减少命令的最大数量。
-c | --clean
    删除扩展模式。
-d | --duration hh:mm:ss
    扩展会话的持续时间。
-e | --end 'YYYY-MM-DD hh:mm:ss'
    扩展会话的结束日期及时间。
-f | --hosts-file filename
    指定包含用于系统扩展的新主机列表的文件的名称。文件的每一行都必须包含一个主机名。
    该文件可以包含指定或不指定网络接口的主机名。gpexpand工具处理这两种情况， 如果原始节点配置了多个网络接口，则将接口号添加到主机名的末尾。
    Note: Greenplum数据库Segment主机的命名习惯是sdwN，其中sdw 是前缀并且N是数字。例如，sdw1、sdw2等等。 对于具有多个接口的主机，约定是在主机名后面添加破折号（-）和数字。例如sdw1-1 和sdw1-2是主机sdw1的两个接口名称。
-i | --input input_file
    指定扩展配置文件的名称，其中为每个要添加的Segment包含一行，格式为：
    hostname:address:port:datadir:dbid:content:preferred_role
-n parallel_processes
    要同时重新分布的表的数量。有效值是1 - 96。
    每个表重新分布过程都需要两个数据库连接：一个用于更改表，另一个用于在扩展方案中更新表的状态。 在增加-n之前，检查服务器配置参数max_connections的当前值， 并确保不超过最大连接限制。
-r | --rollback
    回滚失败的扩展设置操作。
-s | --silent
    以静默模式运行。在警告时，不提示确认就可继续。
-S | --simple-progress
    如果指定，gpexpand工具仅在Greenplum数据库表 gpexpand.expansion_progress中记录最少的进度信息。该工具不在表 gpexpand.status_detail中记录关系大小信息和状态信息。
    指定此选项可通过减少写入gpexpand表的进度信息量来提高性能。
[-t | --tardir] directory
    Segment主机上一个目录的完全限定directory，gpexpand 工具会在其中拷贝一个临时的tar文件。该文件包含用于创建Segment实例的Greenplum数据库文件。 默认目录是用户主目录。
-v | --verbose
    详细调试输出。使用此选项，该工具将输出用于扩展数据库的所有DDL和DML。
--version
    显示工具的版本号并退出。
-? | -h | --helpu
    显示在线帮助
```

[![复制代码](.img_greenplum/copycode.gif)](javascript:void(0);)

gpexpand的具体过程：

gpexpand工具分两个阶段执行系统扩展：Segment初始化和表重新分布

- 在初始化阶段，gpexpand用一个输入文件运行，该文件指定新Segment的数据目录、 dbid值和其他特征。用户可以手动创建输入文件，也可以在交互式对话中 按照提示进行操作。
- 在表数据重分布阶段，gpexpand会重分布表的数据，使数据在新旧segment 实例之间平衡

　　要开始重分布阶段，可以通过运行gpexpand并指定-d（运行时间周期） 或-e（结束时间）选项，或者不指定任何选项。如果客户指定了结束时间或运行周期，工具会在 扩展模式下重分布表，直到达到设定的结束时间或执行周期。如果没指定任何选项，工具会继续处理直到扩展模式的表 全部完成重分布。每张表都会通过ALTER TABLE命令来在所有的节点包括新增加的segment实例 上进行重分布，并设置表的分布策略为其原始策略。如果gpexpand完成所有表的重分布，它会 显示成功信息并退出。

[回到顶部](https://www.cnblogs.com/zsql/p/14602563.html#_labelTop)

## 二、扩容介绍

扩容可以分为纵向扩容和横向扩容，扩容的先决条件如下：

- 用户作为Greenplum数据库超级用户（gpadmin）登录。
- 新的Segment主机已被根据现有的Segment主机安装和配置。这包括：

1. 　　配置硬件和操作系统
2. 　　安装Greenplum软件
3. 　　创建gpadmin用户帐户
4. 　　交换SSH密钥

- 用户的Segment主机上有足够的磁盘空间来临时保存最大表的副本。
- 重新分布数据时，Greenplum数据库必须以生产模式运行。Greenplum数据库不能是受限模式或 Master模式。不能指定gpstart的选项-R或者-m 启动Greenplum数据库

扩容的基本步骤：

1. 创建扩容输入文件：gpexpand -f hosts_file
2. 初始化Segment并且创建扩容schema：gpexpand -i input_file，gpexpand会创建一个数据目录、从现有的数据库复制表到新的Segment上并且为扩容方案中的每个表捕捉元数据用于状态跟踪。 在这个处理完成后，扩容操作会被提交并且不可撤回。
3. 重新分布表数据：gpexpand -d duration
4. 移除扩容schema：gpexpand -c

[回到顶部](https://www.cnblogs.com/zsql/p/14602563.html#_labelTop)

## 三、纵向扩容



### 3.1、扩容前准备

首先看看现有的集群的状态：gpstate

[![复制代码](.img_greenplum/copycode.gif)](javascript:void(0);)

```
[gpadmin@lgh1 conf]$ gpstate
20210331:14:10:34:014725 gpstate:lgh1:gpadmin-[INFO]:-Starting gpstate with args:
20210331:14:10:34:014725 gpstate:lgh1:gpadmin-[INFO]:-local Greenplum Version: 'postgres (Greenplum Database) 6.14.1 build commit:5ef30dd4c9878abadc0124e0761e4b988455a4bd'
20210331:14:10:34:014725 gpstate:lgh1:gpadmin-[INFO]:-master Greenplum Version: 'PostgreSQL 9.4.24 (Greenplum Database 6.14.1 build commit:5ef30dd4c9878abadc0124e0761e4b988455a4bd) on x86_64-unknown-linux-gnu, compiled by gcc (GCC) 6.4.0, 64-bit compiled on Feb 22 2021 18:27:08'
20210331:14:10:34:014725 gpstate:lgh1:gpadmin-[INFO]:-Obtaining Segment details from master...
20210331:14:10:34:014725 gpstate:lgh1:gpadmin-[INFO]:-Gathering data from segments...
20210331:14:10:35:014725 gpstate:lgh1:gpadmin-[INFO]:-Greenplum instance status summary
20210331:14:10:35:014725 gpstate:lgh1:gpadmin-[INFO]:-----------------------------------------------------
20210331:14:10:35:014725 gpstate:lgh1:gpadmin-[INFO]:-   Master instance                                           = Active
20210331:14:10:35:014725 gpstate:lgh1:gpadmin-[INFO]:-   Master standby                                            = lgh2
20210331:14:10:35:014725 gpstate:lgh1:gpadmin-[INFO]:-   Standby master state                                      = Standby host passive
20210331:14:10:35:014725 gpstate:lgh1:gpadmin-[INFO]:-   Total segment instance count from metadata                = 4
20210331:14:10:35:014725 gpstate:lgh1:gpadmin-[INFO]:-----------------------------------------------------
20210331:14:10:35:014725 gpstate:lgh1:gpadmin-[INFO]:-   Primary Segment Status
20210331:14:10:35:014725 gpstate:lgh1:gpadmin-[INFO]:-----------------------------------------------------
20210331:14:10:35:014725 gpstate:lgh1:gpadmin-[INFO]:-   Total primary segments                                    = 2
20210331:14:10:35:014725 gpstate:lgh1:gpadmin-[INFO]:-   Total primary segment valid (at master)                   = 2
20210331:14:10:35:014725 gpstate:lgh1:gpadmin-[INFO]:-   Total primary segment failures (at master)                = 0
20210331:14:10:35:014725 gpstate:lgh1:gpadmin-[INFO]:-   Total number of postmaster.pid files missing              = 0
20210331:14:10:35:014725 gpstate:lgh1:gpadmin-[INFO]:-   Total number of postmaster.pid files found                = 2
20210331:14:10:35:014725 gpstate:lgh1:gpadmin-[INFO]:-   Total number of postmaster.pid PIDs missing               = 0
20210331:14:10:35:014725 gpstate:lgh1:gpadmin-[INFO]:-   Total number of postmaster.pid PIDs found                 = 2
20210331:14:10:35:014725 gpstate:lgh1:gpadmin-[INFO]:-   Total number of /tmp lock files missing                   = 0
20210331:14:10:35:014725 gpstate:lgh1:gpadmin-[INFO]:-   Total number of /tmp lock files found                     = 2
20210331:14:10:35:014725 gpstate:lgh1:gpadmin-[INFO]:-   Total number postmaster processes missing                 = 0
20210331:14:10:35:014725 gpstate:lgh1:gpadmin-[INFO]:-   Total number postmaster processes found                   = 2
20210331:14:10:35:014725 gpstate:lgh1:gpadmin-[INFO]:-----------------------------------------------------
20210331:14:10:35:014725 gpstate:lgh1:gpadmin-[INFO]:-   Mirror Segment Status
20210331:14:10:35:014725 gpstate:lgh1:gpadmin-[INFO]:-----------------------------------------------------
20210331:14:10:35:014725 gpstate:lgh1:gpadmin-[INFO]:-   Total mirror segments                                     = 2
20210331:14:10:35:014725 gpstate:lgh1:gpadmin-[INFO]:-   Total mirror segment valid (at master)                    = 2
20210331:14:10:35:014725 gpstate:lgh1:gpadmin-[INFO]:-   Total mirror segment failures (at master)                 = 0
20210331:14:10:35:014725 gpstate:lgh1:gpadmin-[INFO]:-   Total number of postmaster.pid files missing              = 0
20210331:14:10:35:014725 gpstate:lgh1:gpadmin-[INFO]:-   Total number of postmaster.pid files found                = 2
20210331:14:10:35:014725 gpstate:lgh1:gpadmin-[INFO]:-   Total number of postmaster.pid PIDs missing               = 0
20210331:14:10:35:014725 gpstate:lgh1:gpadmin-[INFO]:-   Total number of postmaster.pid PIDs found                 = 2
20210331:14:10:35:014725 gpstate:lgh1:gpadmin-[INFO]:-   Total number of /tmp lock files missing                   = 0
20210331:14:10:35:014725 gpstate:lgh1:gpadmin-[INFO]:-   Total number of /tmp lock files found                     = 2
20210331:14:10:35:014725 gpstate:lgh1:gpadmin-[INFO]:-   Total number postmaster processes missing                 = 0
20210331:14:10:35:014725 gpstate:lgh1:gpadmin-[INFO]:-   Total number postmaster processes found                   = 2
20210331:14:10:35:014725 gpstate:lgh1:gpadmin-[INFO]:-   Total number mirror segments acting as primary segments   = 0
20210331:14:10:35:014725 gpstate:lgh1:gpadmin-[INFO]:-   Total number mirror segments acting as mirror segments    = 2
20210331:14:10:35:014725 gpstate:lgh1:gpadmin-[INFO]:-----------------------------------------------------
```

[![复制代码](.img_greenplum/copycode.gif)](javascript:void(0);)

现在的状态是有3台主机，一个是master节点，还有两个segment的机器，每个segment的机器上都有一个primary和mirror的segment，现在计划在现有的集群上进行segment的扩容，在每台机器上的segment的数量翻倍，
现在segment的目录为：

```
primary:/apps/data1/primary
mirror:/apps/data1/mirror
```

现在需要在两个segment的主机上创建新的目录如下：

```
primary:/apps/data2/primary
mirror:/apps/data2/mirror
```

上面的目录的所属组和用户均为gpadmin:gpamdin，这里创建目录可以使用gpssh创建也可以一个一个的创建



### 3.2、创建初始化文件

查看目前segment的主机：

```
[gpadmin@lgh1 conf]$ cat seg_hosts
lgh2
lgh3
```

执行：gpexpand -f seg_hosts

[![复制代码](.img_greenplum/copycode.gif)](javascript:void(0);)

```
[gpadmin@lgh1 conf]$ gpexpand -f seg_hosts
20210331:14:16:29:015453 gpexpand:lgh1:gpadmin-[INFO]:-local Greenplum Version: 'postgres (Greenplum Database) 6.14.1 build commit:5ef30dd4c9878abadc0124e0761e4b988455a4bd'
20210331:14:16:29:015453 gpexpand:lgh1:gpadmin-[INFO]:-master Greenplum Version: 'PostgreSQL 9.4.24 (Greenplum Database 6.14.1 build commit:5ef30dd4c9878abadc0124e0761e4b988455a4bd) on x86_64-unknown-linux-gnu, compiled by gcc (GCC) 6.4.0, 64-bit compiled on Feb 22 2021 18:27:08'
20210331:14:16:29:015453 gpexpand:lgh1:gpadmin-[INFO]:-Querying gpexpand schema for current expansion state

System Expansion is used to add segments to an existing GPDB array.
gpexpand did not detect a System Expansion that is in progress.

Before initiating a System Expansion, you need to provision and burn-in
the new hardware.  Please be sure to run gpcheckperf to make sure the
new hardware is working properly.

Please refer to the Admin Guide for more information.

Would you like to initiate a new System Expansion Yy|Nn (default=N):
> y

You must now specify a mirroring strategy for the new hosts.  Spread mirroring places
a given hosts mirrored segments each on a separate host.  You must be
adding more hosts than the number of segments per host to use this.
Grouped mirroring places all of a given hosts segments on a single
mirrored host.  You must be adding at least 2 hosts in order to use this.



What type of mirroring strategy would you like?
 spread|grouped (default=grouped): #默认的mirror方式
>

** No hostnames were given that do not already exist in the **
** array. Additional segments will be added existing hosts. **

    By default, new hosts are configured with the same number of primary
    segments as existing hosts.  Optionally, you can increase the number
    of segments per host.

    For example, if existing hosts have two primary segments, entering a value
    of 2 will initialize two additional segments on existing hosts, and four
    segments on new hosts.  In addition, mirror segments will be added for
    these new primary segments if mirroring is enabled.


How many new primary segments per host do you want to add? (default=0):
> 1
Enter new primary data directory 1:
> /apps/data2/primary
Enter new mirror data directory 1:
> /apps/data2/mirror

Generating configuration file...

20210331:14:17:05:015453 gpexpand:lgh1:gpadmin-[INFO]:-Generating input file...

Input configuration file was written to 'gpexpand_inputfile_20210331_141705'.

Please review the file and make sure that it is correct then re-run
with: gpexpand -i gpexpand_inputfile_20210331_141705  #生成的初始化文件

20210331:14:17:05:015453 gpexpand:lgh1:gpadmin-[INFO]:-Exiting...
```

[![复制代码](.img_greenplum/copycode.gif)](javascript:void(0);)

查看初始化文件：

```
[gpadmin@lgh1 conf]$ cat gpexpand_inputfile_20210331_141705
lgh3|lgh3|6001|/apps/data2/primary/gpseg2|7|2|p
lgh2|lgh2|7001|/apps/data2/mirror/gpseg2|10|2|m
lgh2|lgh2|6001|/apps/data2/primary/gpseg3|8|3|p
lgh3|lgh3|7001|/apps/data2/mirror/gpseg3|9|3|m
```



### 3.3、初始化Segment并且创建扩容schema

执行命令：gpexpand -i gpexpand_inputfile_20210331_141705

[![复制代码](.img_greenplum/copycode.gif)](javascript:void(0);)

```
[gpadmin@lgh1 conf]$ gpexpand  -i gpexpand_inputfile_20210331_141705
20210331:14:21:40:016004 gpexpand:lgh1:gpadmin-[INFO]:-local Greenplum Version: 'postgres (Greenplum Database) 6.14.1 build commit:5ef30dd4c9878abadc0124e0761e4b988455a4bd'
20210331:14:21:40:016004 gpexpand:lgh1:gpadmin-[INFO]:-master Greenplum Version: 'PostgreSQL 9.4.24 (Greenplum Database 6.14.1 build commit:5ef30dd4c9878abadc0124e0761e4b988455a4bd) on x86_64-unknown-linux-gnu, compiled by gcc (GCC) 6.4.0, 64-bit compiled on Feb 22 2021 18:27:08'
20210331:14:21:40:016004 gpexpand:lgh1:gpadmin-[INFO]:-Querying gpexpand schema for current expansion state
20210331:14:21:40:016004 gpexpand:lgh1:gpadmin-[INFO]:-Heap checksum setting consistent across cluster
20210331:14:21:40:016004 gpexpand:lgh1:gpadmin-[INFO]:-Syncing Greenplum Database extensions
20210331:14:21:40:016004 gpexpand:lgh1:gpadmin-[INFO]:-The packages on lgh2 are consistent.
20210331:14:21:41:016004 gpexpand:lgh1:gpadmin-[INFO]:-The packages on lgh3 are consistent.
20210331:14:21:41:016004 gpexpand:lgh1:gpadmin-[INFO]:-Locking catalog
20210331:14:21:41:016004 gpexpand:lgh1:gpadmin-[INFO]:-Locked catalog
20210331:14:21:42:016004 gpexpand:lgh1:gpadmin-[INFO]:-Creating segment template
20210331:14:21:42:016004 gpexpand:lgh1:gpadmin-[INFO]:-Copying postgresql.conf from existing segment into template
20210331:14:21:43:016004 gpexpand:lgh1:gpadmin-[INFO]:-Copying pg_hba.conf from existing segment into template
20210331:14:21:43:016004 gpexpand:lgh1:gpadmin-[INFO]:-Creating schema tar file
20210331:14:21:43:016004 gpexpand:lgh1:gpadmin-[INFO]:-Distributing template tar file to new hosts
20210331:14:21:44:016004 gpexpand:lgh1:gpadmin-[INFO]:-Configuring new segments (primary)
20210331:14:21:44:016004 gpexpand:lgh1:gpadmin-[INFO]:-{'lgh2': '/apps/data2/primary/gpseg3:6001:true:false:8:3::-1:', 'lgh3': '/apps/data2/primary/gpseg2:6001:true:false:7:2::-1:'}
20210331:14:21:47:016004 gpexpand:lgh1:gpadmin-[INFO]:-Cleaning up temporary template files
20210331:14:21:48:016004 gpexpand:lgh1:gpadmin-[INFO]:-Cleaning up databases in new segments.
20210331:14:21:49:016004 gpexpand:lgh1:gpadmin-[INFO]:-Unlocking catalog
20210331:14:21:49:016004 gpexpand:lgh1:gpadmin-[INFO]:-Unlocked catalog
20210331:14:21:49:016004 gpexpand:lgh1:gpadmin-[INFO]:-Creating expansion schema
20210331:14:21:49:016004 gpexpand:lgh1:gpadmin-[INFO]:-Populating gpexpand.status_detail with data from database template1
20210331:14:21:50:016004 gpexpand:lgh1:gpadmin-[INFO]:-Populating gpexpand.status_detail with data from database postgres
20210331:14:21:50:016004 gpexpand:lgh1:gpadmin-[INFO]:-Populating gpexpand.status_detail with data from database gpebusiness
20210331:14:21:50:016004 gpexpand:lgh1:gpadmin-[INFO]:-Populating gpexpand.status_detail with data from database gpperfmon
20210331:14:21:50:016004 gpexpand:lgh1:gpadmin-[INFO]:-Starting new mirror segment synchronization
20210331:14:21:58:016004 gpexpand:lgh1:gpadmin-[INFO]:-************************************************
20210331:14:21:58:016004 gpexpand:lgh1:gpadmin-[INFO]:-Initialization of the system expansion complete.
20210331:14:21:58:016004 gpexpand:lgh1:gpadmin-[INFO]:-To begin table expansion onto the new segments
20210331:14:21:58:016004 gpexpand:lgh1:gpadmin-[INFO]:-rerun gpexpand
20210331:14:21:58:016004 gpexpand:lgh1:gpadmin-[INFO]:-************************************************
20210331:14:21:58:016004 gpexpand:lgh1:gpadmin-[INFO]:-Exiting...
```

[![复制代码](.img_greenplum/copycode.gif)](javascript:void(0);)

使用gpstate验证下：（segment为8了，成功）

[![复制代码](.img_greenplum/copycode.gif)](javascript:void(0);)

```
[gpadmin@lgh1 conf]$ gpstate
20210331:14:23:19:016384 gpstate:lgh1:gpadmin-[INFO]:-Starting gpstate with args:
20210331:14:23:19:016384 gpstate:lgh1:gpadmin-[INFO]:-local Greenplum Version: 'postgres (Greenplum Database) 6.14.1 build commit:5ef30dd4c9878abadc0124e0761e4b988455a4bd'
20210331:14:23:19:016384 gpstate:lgh1:gpadmin-[INFO]:-master Greenplum Version: 'PostgreSQL 9.4.24 (Greenplum Database 6.14.1 build commit:5ef30dd4c9878abadc0124e0761e4b988455a4bd) on x86_64-unknown-linux-gnu, compiled by gcc (GCC) 6.4.0, 64-bit compiled on Feb 22 2021 18:27:08'
20210331:14:23:19:016384 gpstate:lgh1:gpadmin-[INFO]:-Obtaining Segment details from master...
20210331:14:23:19:016384 gpstate:lgh1:gpadmin-[INFO]:-Gathering data from segments...
20210331:14:23:19:016384 gpstate:lgh1:gpadmin-[INFO]:-Greenplum instance status summary
20210331:14:23:19:016384 gpstate:lgh1:gpadmin-[INFO]:-----------------------------------------------------
20210331:14:23:19:016384 gpstate:lgh1:gpadmin-[INFO]:-   Master instance                                           = Active
20210331:14:23:19:016384 gpstate:lgh1:gpadmin-[INFO]:-   Master standby                                            = lgh2
20210331:14:23:19:016384 gpstate:lgh1:gpadmin-[INFO]:-   Standby master state                                      = Standby host passive
20210331:14:23:19:016384 gpstate:lgh1:gpadmin-[INFO]:-   Total segment instance count from metadata                = 8
20210331:14:23:19:016384 gpstate:lgh1:gpadmin-[INFO]:-----------------------------------------------------
20210331:14:23:19:016384 gpstate:lgh1:gpadmin-[INFO]:-   Primary Segment Status
20210331:14:23:19:016384 gpstate:lgh1:gpadmin-[INFO]:-----------------------------------------------------
20210331:14:23:19:016384 gpstate:lgh1:gpadmin-[INFO]:-   Total primary segments                                    = 4
20210331:14:23:19:016384 gpstate:lgh1:gpadmin-[INFO]:-   Total primary segment valid (at master)                   = 4
20210331:14:23:19:016384 gpstate:lgh1:gpadmin-[INFO]:-   Total primary segment failures (at master)                = 0
20210331:14:23:19:016384 gpstate:lgh1:gpadmin-[INFO]:-   Total number of postmaster.pid files missing              = 0
20210331:14:23:19:016384 gpstate:lgh1:gpadmin-[INFO]:-   Total number of postmaster.pid files found                = 4
20210331:14:23:19:016384 gpstate:lgh1:gpadmin-[INFO]:-   Total number of postmaster.pid PIDs missing               = 0
20210331:14:23:19:016384 gpstate:lgh1:gpadmin-[INFO]:-   Total number of postmaster.pid PIDs found                 = 4
20210331:14:23:19:016384 gpstate:lgh1:gpadmin-[INFO]:-   Total number of /tmp lock files missing                   = 0
20210331:14:23:19:016384 gpstate:lgh1:gpadmin-[INFO]:-   Total number of /tmp lock files found                     = 4
20210331:14:23:19:016384 gpstate:lgh1:gpadmin-[INFO]:-   Total number postmaster processes missing                 = 0
20210331:14:23:19:016384 gpstate:lgh1:gpadmin-[INFO]:-   Total number postmaster processes found                   = 4
20210331:14:23:19:016384 gpstate:lgh1:gpadmin-[INFO]:-----------------------------------------------------
20210331:14:23:19:016384 gpstate:lgh1:gpadmin-[INFO]:-   Mirror Segment Status
20210331:14:23:19:016384 gpstate:lgh1:gpadmin-[INFO]:-----------------------------------------------------
20210331:14:23:19:016384 gpstate:lgh1:gpadmin-[INFO]:-   Total mirror segments                                     = 4
20210331:14:23:19:016384 gpstate:lgh1:gpadmin-[INFO]:-   Total mirror segment valid (at master)                    = 4
20210331:14:23:19:016384 gpstate:lgh1:gpadmin-[INFO]:-   Total mirror segment failures (at master)                 = 0
20210331:14:23:19:016384 gpstate:lgh1:gpadmin-[INFO]:-   Total number of postmaster.pid files missing              = 0
20210331:14:23:19:016384 gpstate:lgh1:gpadmin-[INFO]:-   Total number of postmaster.pid files found                = 4
20210331:14:23:19:016384 gpstate:lgh1:gpadmin-[INFO]:-   Total number of postmaster.pid PIDs missing               = 0
20210331:14:23:19:016384 gpstate:lgh1:gpadmin-[INFO]:-   Total number of postmaster.pid PIDs found                 = 4
20210331:14:23:19:016384 gpstate:lgh1:gpadmin-[INFO]:-   Total number of /tmp lock files missing                   = 0
20210331:14:23:19:016384 gpstate:lgh1:gpadmin-[INFO]:-   Total number of /tmp lock files found                     = 4
20210331:14:23:19:016384 gpstate:lgh1:gpadmin-[INFO]:-   Total number postmaster processes missing                 = 0
20210331:14:23:19:016384 gpstate:lgh1:gpadmin-[INFO]:-   Total number postmaster processes found                   = 4
20210331:14:23:19:016384 gpstate:lgh1:gpadmin-[INFO]:-   Total number mirror segments acting as primary segments   = 0
20210331:14:23:19:016384 gpstate:lgh1:gpadmin-[INFO]:-   Total number mirror segments acting as mirror segments    = 4
20210331:14:23:19:016384 gpstate:lgh1:gpadmin-[INFO]:-----------------------------------------------------
20210331:14:23:19:016384 gpstate:lgh1:gpadmin-[INFO]:-   Cluster Expansion                                         = In Progress
20210331:14:23:19:016384 gpstate:lgh1:gpadmin-[INFO]:-----------------------------------------------------
```

[![复制代码](.img_greenplum/copycode.gif)](javascript:void(0);)



### 3.4、重分布数据

执行命令：gpexpand -d 1:00:00 #不动命令回去看gpexpand命令说明，这里没有业务表，所以很快就重分布完成了，如果数据量很大，可以增加线程

[![复制代码](.img_greenplum/copycode.gif)](javascript:void(0);)

```
20210331:14:28:45:016891 gpexpand:lgh1:gpadmin-[INFO]:-local Greenplum Version: 'postgres (Greenplum Database) 6.14.1 build commit:5ef30dd4c9878abadc0124e0761e4b988455a4bd'
20210331:14:28:45:016891 gpexpand:lgh1:gpadmin-[INFO]:-master Greenplum Version: 'PostgreSQL 9.4.24 (Greenplum Database 6.14.1 build commit:5ef30dd4c9878abadc0124e0761e4b988455a4bd) on x86_64-unknown-linux-gnu, compiled by gcc (GCC) 6.4.0, 64-bit compiled on Feb 22 2021 18:27:08'
20210331:14:28:45:016891 gpexpand:lgh1:gpadmin-[INFO]:-Querying gpexpand schema for current expansion state
20210331:14:28:45:016891 gpexpand:lgh1:gpadmin-[INFO]:-Expanding postgres.gpcc_schema.pghba_lock
20210331:14:28:46:016891 gpexpand:lgh1:gpadmin-[INFO]:-Finished expanding postgres.gpcc_schema.pghba_lock
20210331:14:28:46:016891 gpexpand:lgh1:gpadmin-[INFO]:-Expanding gpperfmon.gpmetrics.gpcc_schedule
20210331:14:28:46:016891 gpexpand:lgh1:gpadmin-[INFO]:-Finished expanding gpperfmon.gpmetrics.gpcc_schedule
20210331:14:28:46:016891 gpexpand:lgh1:gpadmin-[INFO]:-Expanding gpperfmon.gpmetrics.gpcc_scan_history
20210331:14:28:46:016891 gpexpand:lgh1:gpadmin-[INFO]:-Finished expanding gpperfmon.gpmetrics.gpcc_scan_history
20210331:14:28:46:016891 gpexpand:lgh1:gpadmin-[INFO]:-Expanding gpperfmon.gpmetrics.gpcc_wlm_rule
20210331:14:28:46:016891 gpexpand:lgh1:gpadmin-[INFO]:-Finished expanding gpperfmon.gpmetrics.gpcc_wlm_rule
20210331:14:28:46:016891 gpexpand:lgh1:gpadmin-[INFO]:-Expanding gpperfmon.gpmetrics.gpcc_export_log
20210331:14:28:46:016891 gpexpand:lgh1:gpadmin-[INFO]:-Finished expanding gpperfmon.gpmetrics.gpcc_export_log
20210331:14:28:47:016891 gpexpand:lgh1:gpadmin-[INFO]:-Expanding gpperfmon.gpmetrics.gpcc_table_info
20210331:14:28:47:016891 gpexpand:lgh1:gpadmin-[INFO]:-Finished expanding gpperfmon.gpmetrics.gpcc_table_info
20210331:14:28:47:016891 gpexpand:lgh1:gpadmin-[INFO]:-Expanding gpperfmon.gpmetrics._gpcc_plannode_history
20210331:14:28:47:016891 gpexpand:lgh1:gpadmin-[INFO]:-Finished expanding gpperfmon.gpmetrics._gpcc_plannode_history
20210331:14:28:47:016891 gpexpand:lgh1:gpadmin-[INFO]:-Expanding gpperfmon.gpcc_schema.pghba_lock
20210331:14:28:47:016891 gpexpand:lgh1:gpadmin-[INFO]:-Finished expanding gpperfmon.gpcc_schema.pghba_lock
20210331:14:28:47:016891 gpexpand:lgh1:gpadmin-[INFO]:-Expanding gpperfmon.gpmetrics.gpcc_alert_history
20210331:14:28:47:016891 gpexpand:lgh1:gpadmin-[INFO]:-Finished expanding gpperfmon.gpmetrics.gpcc_alert_history
20210331:14:28:47:016891 gpexpand:lgh1:gpadmin-[INFO]:-Expanding gpperfmon.gpmetrics.gpcc_database_history
20210331:14:28:48:016891 gpexpand:lgh1:gpadmin-[INFO]:-Finished expanding gpperfmon.gpmetrics.gpcc_database_history
20210331:14:28:48:016891 gpexpand:lgh1:gpadmin-[INFO]:-Expanding gpperfmon.gpmetrics.gpcc_disk_history
20210331:14:28:48:016891 gpexpand:lgh1:gpadmin-[INFO]:-Finished expanding gpperfmon.gpmetrics.gpcc_disk_history
20210331:14:28:48:016891 gpexpand:lgh1:gpadmin-[INFO]:-Expanding gpperfmon.gpmetrics.gpcc_pg_log_history
20210331:14:28:48:016891 gpexpand:lgh1:gpadmin-[INFO]:-Finished expanding gpperfmon.gpmetrics.gpcc_pg_log_history
20210331:14:28:48:016891 gpexpand:lgh1:gpadmin-[INFO]:-Expanding gpperfmon.gpmetrics.gpcc_plannode_history
20210331:14:28:49:016891 gpexpand:lgh1:gpadmin-[INFO]:-Finished expanding gpperfmon.gpmetrics.gpcc_plannode_history
20210331:14:28:49:016891 gpexpand:lgh1:gpadmin-[INFO]:-Expanding gpperfmon.gpmetrics.gpcc_queries_history
20210331:14:28:49:016891 gpexpand:lgh1:gpadmin-[INFO]:-Finished expanding gpperfmon.gpmetrics.gpcc_queries_history
20210331:14:28:49:016891 gpexpand:lgh1:gpadmin-[INFO]:-Expanding gpperfmon.gpmetrics.gpcc_system_history
20210331:14:28:49:016891 gpexpand:lgh1:gpadmin-[INFO]:-Finished expanding gpperfmon.gpmetrics.gpcc_system_history
20210331:14:28:50:016891 gpexpand:lgh1:gpadmin-[INFO]:-Expanding gpperfmon.gpmetrics.gpcc_table_info_history
20210331:14:28:50:016891 gpexpand:lgh1:gpadmin-[INFO]:-Finished expanding gpperfmon.gpmetrics.gpcc_table_info_history
20210331:14:28:50:016891 gpexpand:lgh1:gpadmin-[INFO]:-Expanding gpperfmon.gpmetrics.gpcc_wlm_log_history
20210331:14:28:50:016891 gpexpand:lgh1:gpadmin-[INFO]:-Finished expanding gpperfmon.gpmetrics.gpcc_wlm_log_history
20210331:14:28:50:016891 gpexpand:lgh1:gpadmin-[INFO]:-Expanding gpperfmon.gpmetrics._gpcc_pg_log_meta
20210331:14:28:50:016891 gpexpand:lgh1:gpadmin-[INFO]:-Finished expanding gpperfmon.gpmetrics._gpcc_pg_log_meta
20210331:14:28:50:016891 gpexpand:lgh1:gpadmin-[INFO]:-EXPANSION COMPLETED SUCCESSFULLY
20210331:14:28:50:016891 gpexpand:lgh1:gpadmin-[INFO]:-Exiting...
```

[![复制代码](.img_greenplum/copycode.gif)](javascript:void(0);)



### 3.5、移除扩容schema

执行命令：gpexpand -c

[![复制代码](.img_greenplum/copycode.gif)](javascript:void(0);)

```
[gpadmin@lgh1 conf]$ gpexpand -c
20210331:14:32:01:017244 gpexpand:lgh1:gpadmin-[INFO]:-local Greenplum Version: 'postgres (Greenplum Database) 6.14.1 build commit:5ef30dd4c9878abadc0124e0761e4b988455a4bd'
20210331:14:32:01:017244 gpexpand:lgh1:gpadmin-[INFO]:-master Greenplum Version: 'PostgreSQL 9.4.24 (Greenplum Database 6.14.1 build commit:5ef30dd4c9878abadc0124e0761e4b988455a4bd) on x86_64-unknown-linux-gnu, compiled by gcc (GCC) 6.4.0, 64-bit compiled on Feb 22 2021 18:27:08'
20210331:14:32:01:017244 gpexpand:lgh1:gpadmin-[INFO]:-Querying gpexpand schema for current expansion state


Do you want to dump the gpexpand.status_detail table to file? Yy|Nn (default=Y):
> y
20210331:14:32:05:017244 gpexpand:lgh1:gpadmin-[INFO]:-Dumping gpexpand.status_detail to /apps/data1/master/gpseg-1/gpexpand.status_detail
20210331:14:32:05:017244 gpexpand:lgh1:gpadmin-[INFO]:-Removing gpexpand schema
20210331:14:32:05:017244 gpexpand:lgh1:gpadmin-[INFO]:-Cleanup Finished.  exiting...
```

[![复制代码](.img_greenplum/copycode.gif)](javascript:void(0);)

这里为止纵向扩容就完成了，不出错都是傻瓜式的操作，出错多看日志，也不难。

**注意：如果在扩容的时候失败或者出错了，记得回滚：gpexpand -r ，还有就是扩容成功，数据重分布成功后记得使用analyze或者analyzedb进行分析**

[回到顶部](https://www.cnblogs.com/zsql/p/14602563.html#_labelTop)

## 四、横向扩容



### 4.1、安装前准备

参考：[greenplum6.14、GPCC6.4安装详解](https://www.cnblogs.com/zsql/p/14598098.html) 第一部分



### 4.2、基本配置和规划

规划，新增两台机器（红色粗体部分），由于配置了mirror，所以至少要新增两台机器扩容，不然会报错：

![img](.img_greenplum/1271254-20210331165456143-697136397.png)

 

 在新的两个机器进行如下操作：

[![复制代码](.img_greenplum/copycode.gif)](javascript:void(0);)

```
#创建gp用户和用户组
groupdel gpadmin
userdel gpadmin
groupadd gpadmin
useradd  -g gpadmin gpadmin

#创建segment目录
mkdir /apps/data1/primary
mkdir /apps/data2/primary
mkdir /apps/data1/mirror
mkdir /apps/data2/mirror
chown -R gpamdin:gpamdin /apps/data*

#拷贝master主机的安装目录
cd /usr/local &&  tar -cf /usr/local/gp6.tar greenplum-db-6.14.1 #master主机操作
scp gp6.tar root@lgh4:/usr/local/ #master主机操作
scp gp6.tar root@lgh5:/usr/local/ #master主机操作
cd /usr/local
tar -xf gp6.tar
ln -s greenplum-db-6.14.1 greenplum-db
chown -R gpadmin:gpadmin greenplum-db*

#ssh免密配置
ssh-copy-id lgh4  #master主机操作
ssh-copy-id lgh5  #master主机操作
```

[![复制代码](.img_greenplum/copycode.gif)](javascript:void(0);)

修改seg_hosts，all_hosts文件，添加新主机名进去：

```
[gpadmin@mvxl53201 conf]$ cat seg_hosts``lgh2``lgh3``lgh4 #``new``lgh5 #``new
```

[![复制代码](.img_greenplum/copycode.gif)](javascript:void(0);)

```
[gpadmin@mvxl53201 conf]$ cat all_hosts
lgh1
lgh2
lgh3
lgh4 #new
lgh5 #new
```

[![复制代码](.img_greenplum/copycode.gif)](javascript:void(0);)

执行：gpssh-exkeys -f all_hosts

[![复制代码](.img_greenplum/copycode.gif)](javascript:void(0);)

```
[gpadmin@lgh1 conf]$ gpssh-exkeys -f all_hosts
[STEP 1 of 5] create local ID and authorize on local host
  ... /apps/gpadmin/.ssh/id_rsa file exists ... key generation skipped

[STEP 2 of 5] keyscan all hosts and update known_hosts file

[STEP 3 of 5] retrieving credentials from remote hosts
  ... send to lgh2
  ... send to lgh3
  ... send to lgh4
  ... send to lgh5

[STEP 4 of 5] determine common authentication file content

[STEP 5 of 5] copy authentication files to all remote hosts
  ... finished key exchange with lgh2
  ... finished key exchange with lgh3
  ... finished key exchange with lgh4
  ... finished key exchange with lgh5

[INFO] completed successfully
```

[![复制代码](.img_greenplum/copycode.gif)](javascript:void(0);)



### 4.3、创建初始化文件

执行：gpexpand -f seg_hosts

[![复制代码](.img_greenplum/copycode.gif)](javascript:void(0);)

```
[gpadmin@lgh1 conf]$ gpexpand -f seg_hosts
20210331:15:00:52:020105 gpexpand:lgh1:gpadmin-[INFO]:-local Greenplum Version: 'postgres (Greenplum Database) 6.14.1 build commit:5ef30dd4c9878abadc0124e0761e4b988455a4bd'
20210331:15:00:52:020105 gpexpand:lgh1:gpadmin-[INFO]:-master Greenplum Version: 'PostgreSQL 9.4.24 (Greenplum Database 6.14.1 build commit:5ef30dd4c9878abadc0124e0761e4b988455a4bd) on x86_64-unknown-linux-gnu, compiled by gcc (GCC) 6.4.0, 64-bit compiled on Feb 22 2021 18:27:08'
20210331:15:00:52:020105 gpexpand:lgh1:gpadmin-[INFO]:-Querying gpexpand schema for current expansion state

System Expansion is used to add segments to an existing GPDB array.
gpexpand did not detect a System Expansion that is in progress.

Before initiating a System Expansion, you need to provision and burn-in
the new hardware.  Please be sure to run gpcheckperf to make sure the
new hardware is working properly.

Please refer to the Admin Guide for more information.

Would you like to initiate a new System Expansion Yy|Nn (default=N):
> y

You must now specify a mirroring strategy for the new hosts.  Spread mirroring places
a given hosts mirrored segments each on a separate host.  You must be
adding more hosts than the number of segments per host to use this.
Grouped mirroring places all of a given hosts segments on a single
mirrored host.  You must be adding at least 2 hosts in order to use this.



What type of mirroring strategy would you like?
 spread|grouped (default=grouped):
>

    By default, new hosts are configured with the same number of primary
    segments as existing hosts.  Optionally, you can increase the number
    of segments per host.

    For example, if existing hosts have two primary segments, entering a value
    of 2 will initialize two additional segments on existing hosts, and four
    segments on new hosts.  In addition, mirror segments will be added for
    these new primary segments if mirroring is enabled.


How many new primary segments per host do you want to add? (default=0):
>

Generating configuration file...

20210331:15:00:59:020105 gpexpand:lgh1:gpadmin-[INFO]:-Generating input file...

Input configuration file was written to 'gpexpand_inputfile_20210331_150059'.

Please review the file and make sure that it is correct then re-run
with: gpexpand -i gpexpand_inputfile_20210331_150059  #生成文件

20210331:15:00:59:020105 gpexpand:lgh1:gpadmin-[INFO]:-Exiting...
```

[![复制代码](.img_greenplum/copycode.gif)](javascript:void(0);)

查看初始化的文件：

[![复制代码](.img_greenplum/copycode.gif)](javascript:void(0);)

```
[gpadmin@lgh1 conf]$ cat gpexpand_inputfile_20210331_150059
lgh5|lgh5|6000|/apps/data1/primary/gpseg4|11|4|p
lgh4|lgh4|7000|/apps/data1/mirror/gpseg4|17|4|m
lgh5|lgh5|6001|/apps/data2/primary/gpseg5|12|5|p
lgh4|lgh4|7001|/apps/data2/mirror/gpseg5|18|5|m
lgh4|lgh4|6000|/apps/data1/primary/gpseg6|13|6|p
lgh5|lgh5|7000|/apps/data1/mirror/gpseg6|15|6|m
lgh4|lgh4|6001|/apps/data2/primary/gpseg7|14|7|p
lgh5|lgh5|7001|/apps/data2/mirror/gpseg7|16|7|m
```

[![复制代码](.img_greenplum/copycode.gif)](javascript:void(0);)



### 4.4、初始化Segment并且创建扩容schema

执行：gpexpand -i gpexpand_inputfile_20210331_150059

[![复制代码](.img_greenplum/copycode.gif)](javascript:void(0);)

```
[gpadmin@lgh1 conf]$ gpexpand -i gpexpand_inputfile_20210331_150059
20210331:15:04:06:020454 gpexpand:lgh1:gpadmin-[INFO]:-local Greenplum Version: 'postgres (Greenplum Database) 6.14.1 build commit:5ef30dd4c9878abadc0124e0761e4b988455a4bd'
20210331:15:04:06:020454 gpexpand:lgh1:gpadmin-[INFO]:-master Greenplum Version: 'PostgreSQL 9.4.24 (Greenplum Database 6.14.1 build commit:5ef30dd4c9878abadc0124e0761e4b988455a4bd) on x86_64-unknown-linux-gnu, compiled by gcc (GCC) 6.4.0, 64-bit compiled on Feb 22 2021 18:27:08'
20210331:15:04:06:020454 gpexpand:lgh1:gpadmin-[INFO]:-Querying gpexpand schema for current expansion state
20210331:15:04:06:020454 gpexpand:lgh1:gpadmin-[INFO]:-Heap checksum setting consistent across cluster
20210331:15:04:06:020454 gpexpand:lgh1:gpadmin-[INFO]:-Syncing Greenplum Database extensions
20210331:15:04:07:020454 gpexpand:lgh1:gpadmin-[INFO]:-The packages on lgh5 are consistent.
20210331:15:04:08:020454 gpexpand:lgh1:gpadmin-[INFO]:-The packages on lgh4 are consistent.
20210331:15:04:08:020454 gpexpand:lgh1:gpadmin-[INFO]:-Locking catalog
20210331:15:04:08:020454 gpexpand:lgh1:gpadmin-[INFO]:-Locked catalog
20210331:15:04:09:020454 gpexpand:lgh1:gpadmin-[INFO]:-Creating segment template
20210331:15:04:09:020454 gpexpand:lgh1:gpadmin-[INFO]:-Copying postgresql.conf from existing segment into template
20210331:15:04:09:020454 gpexpand:lgh1:gpadmin-[INFO]:-Copying pg_hba.conf from existing segment into template
20210331:15:04:10:020454 gpexpand:lgh1:gpadmin-[INFO]:-Creating schema tar file
20210331:15:04:10:020454 gpexpand:lgh1:gpadmin-[INFO]:-Distributing template tar file to new hosts
20210331:15:04:11:020454 gpexpand:lgh1:gpadmin-[INFO]:-Configuring new segments (primary)
20210331:15:04:11:020454 gpexpand:lgh1:gpadmin-[INFO]:-{'lgh5': '/apps/data1/primary/gpseg4:6000:true:false:11:4::-1:,/apps/data2/primary/gpseg5:6001:true:false:12:5::-1:', 'lgh4': '/apps/data1/primary/gpseg6:6000:true:false:13:6::-1:,/apps/data2/primary/gpseg7:6001:true:false:14:7::-1:'}
20210331:15:04:17:020454 gpexpand:lgh1:gpadmin-[INFO]:-Cleaning up temporary template files
20210331:15:04:17:020454 gpexpand:lgh1:gpadmin-[INFO]:-Cleaning up databases in new segments.
20210331:15:04:19:020454 gpexpand:lgh1:gpadmin-[INFO]:-Unlocking catalog
20210331:15:04:19:020454 gpexpand:lgh1:gpadmin-[INFO]:-Unlocked catalog
20210331:15:04:19:020454 gpexpand:lgh1:gpadmin-[INFO]:-Creating expansion schema
20210331:15:04:19:020454 gpexpand:lgh1:gpadmin-[INFO]:-Populating gpexpand.status_detail with data from database template1
20210331:15:04:19:020454 gpexpand:lgh1:gpadmin-[INFO]:-Populating gpexpand.status_detail with data from database postgres
20210331:15:04:19:020454 gpexpand:lgh1:gpadmin-[INFO]:-Populating gpexpand.status_detail with data from database gpebusiness
20210331:15:04:20:020454 gpexpand:lgh1:gpadmin-[INFO]:-Populating gpexpand.status_detail with data from database gpperfmon
20210331:15:04:20:020454 gpexpand:lgh1:gpadmin-[INFO]:-Starting new mirror segment synchronization
20210331:15:04:34:020454 gpexpand:lgh1:gpadmin-[INFO]:-************************************************
20210331:15:04:34:020454 gpexpand:lgh1:gpadmin-[INFO]:-Initialization of the system expansion complete.
20210331:15:04:34:020454 gpexpand:lgh1:gpadmin-[INFO]:-To begin table expansion onto the new segments
20210331:15:04:34:020454 gpexpand:lgh1:gpadmin-[INFO]:-rerun gpexpand
20210331:15:04:34:020454 gpexpand:lgh1:gpadmin-[INFO]:-************************************************
20210331:15:04:34:020454 gpexpand:lgh1:gpadmin-[INFO]:-Exiting...
```

[![复制代码](.img_greenplum/copycode.gif)](javascript:void(0);)



### 4.5、重分布数据

执行：gpexpand -d 1:00:00

[![复制代码](.img_greenplum/copycode.gif)](javascript:void(0);)

```
[gpadmin@lgh1 conf]$ gpexpand -d 1:00:00
20210331:15:06:46:021037 gpexpand:lgh1:gpadmin-[INFO]:-local Greenplum Version: 'postgres (Greenplum Database) 6.14.1 build commit:5ef30dd4c9878abadc0124e0761e4b988455a4bd'
20210331:15:06:46:021037 gpexpand:lgh1:gpadmin-[INFO]:-master Greenplum Version: 'PostgreSQL 9.4.24 (Greenplum Database 6.14.1 build commit:5ef30dd4c9878abadc0124e0761e4b988455a4bd) on x86_64-unknown-linux-gnu, compiled by gcc (GCC) 6.4.0, 64-bit compiled on Feb 22 2021 18:27:08'
20210331:15:06:46:021037 gpexpand:lgh1:gpadmin-[INFO]:-Querying gpexpand schema for current expansion state
20210331:15:06:46:021037 gpexpand:lgh1:gpadmin-[INFO]:-Expanding postgres.gpcc_schema.pghba_lock
20210331:15:06:46:021037 gpexpand:lgh1:gpadmin-[INFO]:-Finished expanding postgres.gpcc_schema.pghba_lock
20210331:15:06:46:021037 gpexpand:lgh1:gpadmin-[INFO]:-Expanding gpperfmon.gpmetrics.gpcc_export_log
20210331:15:06:46:021037 gpexpand:lgh1:gpadmin-[INFO]:-Finished expanding gpperfmon.gpmetrics.gpcc_export_log
20210331:15:06:47:021037 gpexpand:lgh1:gpadmin-[INFO]:-Expanding gpperfmon.gpmetrics.gpcc_schedule
20210331:15:06:47:021037 gpexpand:lgh1:gpadmin-[INFO]:-Finished expanding gpperfmon.gpmetrics.gpcc_schedule
20210331:15:06:47:021037 gpexpand:lgh1:gpadmin-[INFO]:-Expanding gpperfmon.gpmetrics.gpcc_wlm_rule
20210331:15:06:47:021037 gpexpand:lgh1:gpadmin-[INFO]:-Finished expanding gpperfmon.gpmetrics.gpcc_wlm_rule
20210331:15:06:47:021037 gpexpand:lgh1:gpadmin-[INFO]:-Expanding gpperfmon.gpmetrics.gpcc_table_info
20210331:15:06:47:021037 gpexpand:lgh1:gpadmin-[INFO]:-Finished expanding gpperfmon.gpmetrics.gpcc_table_info
20210331:15:06:47:021037 gpexpand:lgh1:gpadmin-[INFO]:-Expanding gpperfmon.gpmetrics._gpcc_pg_log_meta
20210331:15:06:47:021037 gpexpand:lgh1:gpadmin-[INFO]:-Finished expanding gpperfmon.gpmetrics._gpcc_pg_log_meta
20210331:15:06:48:021037 gpexpand:lgh1:gpadmin-[INFO]:-Expanding gpperfmon.gpmetrics._gpcc_plannode_history
20210331:15:06:48:021037 gpexpand:lgh1:gpadmin-[INFO]:-Finished expanding gpperfmon.gpmetrics._gpcc_plannode_history
20210331:15:06:48:021037 gpexpand:lgh1:gpadmin-[INFO]:-Expanding gpperfmon.gpcc_schema.pghba_lock
20210331:15:06:48:021037 gpexpand:lgh1:gpadmin-[INFO]:-Finished expanding gpperfmon.gpcc_schema.pghba_lock
20210331:15:06:48:021037 gpexpand:lgh1:gpadmin-[INFO]:-Expanding gpperfmon.gpmetrics.gpcc_alert_history
20210331:15:06:48:021037 gpexpand:lgh1:gpadmin-[INFO]:-Finished expanding gpperfmon.gpmetrics.gpcc_alert_history
20210331:15:06:48:021037 gpexpand:lgh1:gpadmin-[INFO]:-Expanding gpperfmon.gpmetrics.gpcc_database_history
20210331:15:06:48:021037 gpexpand:lgh1:gpadmin-[INFO]:-Finished expanding gpperfmon.gpmetrics.gpcc_database_history
20210331:15:06:49:021037 gpexpand:lgh1:gpadmin-[INFO]:-Expanding gpperfmon.gpmetrics.gpcc_disk_history
20210331:15:06:49:021037 gpexpand:lgh1:gpadmin-[INFO]:-Finished expanding gpperfmon.gpmetrics.gpcc_disk_history
20210331:15:06:49:021037 gpexpand:lgh1:gpadmin-[INFO]:-Expanding gpperfmon.gpmetrics.gpcc_pg_log_history
20210331:15:06:49:021037 gpexpand:lgh1:gpadmin-[INFO]:-Finished expanding gpperfmon.gpmetrics.gpcc_pg_log_history
20210331:15:06:50:021037 gpexpand:lgh1:gpadmin-[INFO]:-Expanding gpperfmon.gpmetrics.gpcc_plannode_history
20210331:15:06:50:021037 gpexpand:lgh1:gpadmin-[INFO]:-Finished expanding gpperfmon.gpmetrics.gpcc_plannode_history
20210331:15:06:50:021037 gpexpand:lgh1:gpadmin-[INFO]:-Expanding gpperfmon.gpmetrics.gpcc_queries_history
20210331:15:06:50:021037 gpexpand:lgh1:gpadmin-[INFO]:-Finished expanding gpperfmon.gpmetrics.gpcc_queries_history
20210331:15:06:50:021037 gpexpand:lgh1:gpadmin-[INFO]:-Expanding gpperfmon.gpmetrics.gpcc_system_history
20210331:15:06:51:021037 gpexpand:lgh1:gpadmin-[INFO]:-Finished expanding gpperfmon.gpmetrics.gpcc_system_history
20210331:15:06:51:021037 gpexpand:lgh1:gpadmin-[INFO]:-Expanding gpperfmon.gpmetrics.gpcc_table_info_history
20210331:15:06:51:021037 gpexpand:lgh1:gpadmin-[INFO]:-Finished expanding gpperfmon.gpmetrics.gpcc_table_info_history
20210331:15:06:51:021037 gpexpand:lgh1:gpadmin-[INFO]:-Expanding gpperfmon.gpmetrics.gpcc_wlm_log_history
20210331:15:06:51:021037 gpexpand:lgh1:gpadmin-[INFO]:-Finished expanding gpperfmon.gpmetrics.gpcc_wlm_log_history
20210331:15:06:52:021037 gpexpand:lgh1:gpadmin-[INFO]:-Expanding gpperfmon.gpmetrics.gpcc_scan_history
20210331:15:06:52:021037 gpexpand:lgh1:gpadmin-[INFO]:-Finished expanding gpperfmon.gpmetrics.gpcc_scan_history
20210331:15:06:56:021037 gpexpand:lgh1:gpadmin-[INFO]:-EXPANSION COMPLETED SUCCESSFULLY
20210331:15:06:56:021037 gpexpand:lgh1:gpadmin-[INFO]:-Exiting...
```

[![复制代码](.img_greenplum/copycode.gif)](javascript:void(0);)



### 4.6、移除扩容schema

执行命令：gpexpand -c

[![复制代码](.img_greenplum/copycode.gif)](javascript:void(0);)

```
[gpadmin@lgh1 conf]$ gpexpand -c
20210331:15:08:19:021264 gpexpand:lgh1:gpadmin-[INFO]:-local Greenplum Version: 'postgres (Greenplum Database) 6.14.1 build commit:5ef30dd4c9878abadc0124e0761e4b988455a4bd'
20210331:15:08:19:021264 gpexpand:lgh1:gpadmin-[INFO]:-master Greenplum Version: 'PostgreSQL 9.4.24 (Greenplum Database 6.14.1 build commit:5ef30dd4c9878abadc0124e0761e4b988455a4bd) on x86_64-unknown-linux-gnu, compiled by gcc (GCC) 6.4.0, 64-bit compiled on Feb 22 2021 18:27:08'
20210331:15:08:19:021264 gpexpand:lgh1:gpadmin-[INFO]:-Querying gpexpand schema for current expansion state


Do you want to dump the gpexpand.status_detail table to file? Yy|Nn (default=Y):
> y
20210331:15:08:21:021264 gpexpand:lgh1:gpadmin-[INFO]:-Dumping gpexpand.status_detail to /apps/data1/master/gpseg-1/gpexpand.status_detail
20210331:15:08:21:021264 gpexpand:lgh1:gpadmin-[INFO]:-Removing gpexpand schema
20210331:15:08:21:021264 gpexpand:lgh1:gpadmin-[INFO]:-Cleanup Finished.  exiting...
```

[![复制代码](.img_greenplum/copycode.gif)](javascript:void(0);)

查看扩容结果：gpstate

[![复制代码](.img_greenplum/copycode.gif)](javascript:void(0);)

```
[gpadmin@lgh1 conf]$ gpstate
20210331:15:10:11:021437 gpstate:lgh1:gpadmin-[INFO]:-Starting gpstate with args:
20210331:15:10:11:021437 gpstate:lgh1:gpadmin-[INFO]:-local Greenplum Version: 'postgres (Greenplum Database) 6.14.1 build commit:5ef30dd4c9878abadc0124e0761e4b988455a4bd'
20210331:15:10:11:021437 gpstate:lgh1:gpadmin-[INFO]:-master Greenplum Version: 'PostgreSQL 9.4.24 (Greenplum Database 6.14.1 build commit:5ef30dd4c9878abadc0124e0761e4b988455a4bd) on x86_64-unknown-linux-gnu, compiled by gcc (GCC) 6.4.0, 64-bit compiled on Feb 22 2021 18:27:08'
20210331:15:10:11:021437 gpstate:lgh1:gpadmin-[INFO]:-Obtaining Segment details from master...
20210331:15:10:11:021437 gpstate:lgh1:gpadmin-[INFO]:-Gathering data from segments...
20210331:15:10:11:021437 gpstate:lgh1:gpadmin-[INFO]:-Greenplum instance status summary
20210331:15:10:11:021437 gpstate:lgh1:gpadmin-[INFO]:-----------------------------------------------------
20210331:15:10:11:021437 gpstate:lgh1:gpadmin-[INFO]:-   Master instance                                           = Active
20210331:15:10:11:021437 gpstate:lgh1:gpadmin-[INFO]:-   Master standby                                            = lgh2
20210331:15:10:11:021437 gpstate:lgh1:gpadmin-[INFO]:-   Standby master state                                      = Standby host passive
20210331:15:10:11:021437 gpstate:lgh1:gpadmin-[INFO]:-   Total segment instance count from metadata                = 16
20210331:15:10:11:021437 gpstate:lgh1:gpadmin-[INFO]:-----------------------------------------------------
20210331:15:10:11:021437 gpstate:lgh1:gpadmin-[INFO]:-   Primary Segment Status
20210331:15:10:11:021437 gpstate:lgh1:gpadmin-[INFO]:-----------------------------------------------------
20210331:15:10:11:021437 gpstate:lgh1:gpadmin-[INFO]:-   Total primary segments                                    = 8
20210331:15:10:11:021437 gpstate:lgh1:gpadmin-[INFO]:-   Total primary segment valid (at master)                   = 8
20210331:15:10:11:021437 gpstate:lgh1:gpadmin-[INFO]:-   Total primary segment failures (at master)                = 0
20210331:15:10:11:021437 gpstate:lgh1:gpadmin-[INFO]:-   Total number of postmaster.pid files missing              = 0
20210331:15:10:11:021437 gpstate:lgh1:gpadmin-[INFO]:-   Total number of postmaster.pid files found                = 8
20210331:15:10:11:021437 gpstate:lgh1:gpadmin-[INFO]:-   Total number of postmaster.pid PIDs missing               = 0
20210331:15:10:11:021437 gpstate:lgh1:gpadmin-[INFO]:-   Total number of postmaster.pid PIDs found                 = 8
20210331:15:10:11:021437 gpstate:lgh1:gpadmin-[INFO]:-   Total number of /tmp lock files missing                   = 0
20210331:15:10:11:021437 gpstate:lgh1:gpadmin-[INFO]:-   Total number of /tmp lock files found                     = 8
20210331:15:10:11:021437 gpstate:lgh1:gpadmin-[INFO]:-   Total number postmaster processes missing                 = 0
20210331:15:10:11:021437 gpstate:lgh1:gpadmin-[INFO]:-   Total number postmaster processes found                   = 8
20210331:15:10:11:021437 gpstate:lgh1:gpadmin-[INFO]:-----------------------------------------------------
20210331:15:10:11:021437 gpstate:lgh1:gpadmin-[INFO]:-   Mirror Segment Status
20210331:15:10:11:021437 gpstate:lgh1:gpadmin-[INFO]:-----------------------------------------------------
20210331:15:10:11:021437 gpstate:lgh1:gpadmin-[INFO]:-   Total mirror segments                                     = 8
20210331:15:10:11:021437 gpstate:lgh1:gpadmin-[INFO]:-   Total mirror segment valid (at master)                    = 8
20210331:15:10:11:021437 gpstate:lgh1:gpadmin-[INFO]:-   Total mirror segment failures (at master)                 = 0
20210331:15:10:11:021437 gpstate:lgh1:gpadmin-[INFO]:-   Total number of postmaster.pid files missing              = 0
20210331:15:10:11:021437 gpstate:lgh1:gpadmin-[INFO]:-   Total number of postmaster.pid files found                = 8
20210331:15:10:11:021437 gpstate:lgh1:gpadmin-[INFO]:-   Total number of postmaster.pid PIDs missing               = 0
20210331:15:10:11:021437 gpstate:lgh1:gpadmin-[INFO]:-   Total number of postmaster.pid PIDs found                 = 8
20210331:15:10:11:021437 gpstate:lgh1:gpadmin-[INFO]:-   Total number of /tmp lock files missing                   = 0
20210331:15:10:11:021437 gpstate:lgh1:gpadmin-[INFO]:-   Total number of /tmp lock files found                     = 8
20210331:15:10:11:021437 gpstate:lgh1:gpadmin-[INFO]:-   Total number postmaster processes missing                 = 0
20210331:15:10:11:021437 gpstate:lgh1:gpadmin-[INFO]:-   Total number postmaster processes found                   = 8
20210331:15:10:11:021437 gpstate:lgh1:gpadmin-[INFO]:-   Total number mirror segments acting as primary segments   = 0
20210331:15:10:11:021437 gpstate:lgh1:gpadmin-[INFO]:-   Total number mirror segments acting as mirror segments    = 8
20210331:15:10:11:021437 gpstate:lgh1:gpadmin-[INFO]:-----------------------------------------------------
```

[![复制代码](.img_greenplum/copycode.gif)](javascript:void(0);)

**注意：如果在扩容的时候失败或者出错了，记得回滚：gpexpand -r ，还有就是扩容成功，数据重分布成功后记得使用analyze或者analyzedb进行分析**

 

[回到顶部](https://www.cnblogs.com/zsql/p/14602563.html#_labelTop)

## 参考网址：

http://docs-cn.greenplum.org/v6/admin_guide/expand/expand-main.html

http://docs-cn.greenplum.org/v6/utility_guide/admin_utilities/gpexpand.html#topic1

# 调优SQL查询

Greenplum数据库的基于代价的优化器会为执行一个查询计算很多策略并且选择代价最低的方法。和其他RDBMS的优化器类似，在计算可选执行计划的代价时，Greenplum的优化器会考虑诸如要连接的表中的行数、索引的可用性以及列数据的基数等因素。规划器还会考虑数据的位置、倾向于在Segment上做尽可能多的工作以及最小化完成查询必须在Segment之间传输的数据量。

当查询运行得比预期慢时，用户可以查看优化器选择的计划以及它为计划的每一步计算出的代价。这将帮助用户确定哪些步骤消耗了最多的资源，然后修改查询或者模式来为优化器提供更加有效的可选方法。用户可以使用SQL语句EXPLAIN来查看查询的计划。

优化器基于为表生成的统计信息产生计划。精确的统计信息对于产生最好的计划非常重要。有关更新统计信息的指南请见本指南中的[用ANALYZE更新统计信息](https://gp-docs-cn.github.io/docs/best_practices/analyze.html#analyze)。

**上级主题：** [最佳实践](https://gp-docs-cn.github.io/docs/best_practices/intro.html)

## 如何产生解释计划

EXPLAIN和EXPLAIN ANALYZE语句是发现改进查询性能机会的非常有用的工具。EXPLAIN会为查询显示其查询计划和估算的代价，但是不执行该查询。EXPLAIN ANALYZE除了显示查询的查询计划之外，还会执行该查询。EXPLAIN ANALYZE会丢掉任何来自SELECT语句的输出，但是该语句中的其他操作会被执行（例如INSERT、UPDATE或者DELETE）。要在DML语句上使用EXPLAIN ANALYZE却不让该命令影响数据，可以明确地把EXPLAIN ANALYZE用在一个事务中（BEGIN; EXPLAIN ANALYZE ...; ROLLBACK;）。

EXPLAIN ANALYZE运行语句后除了显示计划外，还有下列额外的信息：

- 运行该查询消耗的总时间（以毫秒计）
- 计划节点操作中涉及的工作者（Segment）数量
- 操作中产生最多行的Segment返回的最大行数（及其Segment ID）
- 操作所使用的内存
- 从产生最多行的Segment中检索到第一行所需的时间（以毫秒计），以及从该Segment中检索所有行花费的总时间。

## 如何阅读解释计划

解释计划是一份报告，它详细描述了Greenplum数据库优化器确定的执行查询要遵循的步骤。计划是一棵节点构成的树，应该从底向上阅读，每一个节点都会将其结果传递给其直接上层节点。每个节点表示计划中的一个步骤，每个节点对应的那一行标识了在该步骤中执行的操作——例如扫描、连接、聚集或者排序操作。节点还标识了用于执行该操作的方法。例如，扫描操作的方法可能是顺序扫描或者索引扫描。而连接操作可以执行哈希连接或者嵌套循环连接。

下面是一个简单查询的解释计划。该查询在存储于每一Segment中的分布表中查找行数。

```sql
gpacmin=# EXPLAIN SELECT gp_segment_id, count(*) 
                  FROM contributions 
                  GROUP BY gp_segment_id;
                                 QUERY PLAN 
-------------------------------------------------------------------------------- 
 Gather Motion 2:1  (slice2; segments: 2)  (cost=0.00..4.44 rows=4 width=16)
   ->  HashAggregate  (cost=0.00..3.38 rows=4 width=16)
         Group By: contributions.gp_segment_id
         ->  Redistribute Motion 2:2  (slice1; segments: 2)  
                 (cost=0.00..2.12 rows=4 width=8)
               Hash Key: contributions.gp_segment_id
               ->  Sequence  (cost=0.00..1.09 rows=4 width=8)
                     ->  Result  (cost=10.00..100.00 rows=50 width=4)
                           ->  Function Scan on gp_partition_expansion  
                                   (cost=10.00..100.00 rows=50 width=4)
                     ->  Dynamic Table Scan on contributions (partIndex: 0)
                             (cost=0.00..0.03 rows=4 width=8)
 Settings:  optimizer=on
(10 rows)
```

这个计划有七个节点——Dynamic Table Scan、Function Scan、Result、Sequence、Redistribute Motion、HashAggregate和最后的Gather Motion。每一个节点包含三个代价估计：代价cost（读取的顺序页面）、行数rows以及行宽度width。

代价cost由两部分构成。1.0的代价等于一次顺序磁盘页面读取。估计的第一部分是启动代价，它是得到第一行的代价。第二个不急是总代价，它是得到所有行的代价。

行数rows估计是由计划节点输出的行数。这个数字可能会小于计划节点实际处理或者扫描的行数，它反映了WHERE子句条件的选择度估计。总代价假设所有的行将被检索出来，但并非总是这样（例如，如果用户使用LIMIT子句）。

宽度width估计是计划节点输出的所有列的以字节计的总宽度。

节点中的代价估计包括了其所有子节点的代价，因此计划中最顶层节点（通常是一个Gather Motion）具有对计划总体执行代价的估计。这就是查询规划器想要最小化的数字。

扫描操作符扫描表中的行以寻找一个行的集合。对于不同种类的存储有不同的扫描操作符。它们包括：

- 对表上的Seq Scan — 扫描表中的所有行。

- Append-only Scan — 扫描行存追加优化表。

- Append-only Columnar Scan — 扫描列存追加优化表中的行。

- Index Scan — 遍历一个B-树索引以从表中取得行。

- Bitmap Append-only Row-oriented Scan — 从索引中收集仅追加表中行的指针并且按照磁盘上的位置进行排序。

- Dynamic Table Scan — 使用一个分区选择函数来选择分区。Function Scan节点包含分区选择函数的名称，可以是下列之一：

  - gp_partition_expansion — 选择表中的所有分区。不会有分区被消除。
  - gp_partition_selection — 基于一个等值表达式选择一个分区。
  - gp_partition_inversion — 基于一个范围表达式选择分区。

  Function Scan节点将动态选择的分区列表传递给Result节点，该节点又会被传递给Sequence节点。

Join操作符包括下列：

- Hash Join – 从较小的表构建一个哈希表，用连接列作为哈希键。然后扫描较大的表，为连接列计算哈希键并且探索哈希表寻找具有相同哈希键的行。哈希连接通常是Greenplum数据库中最快的连接。解释计划中的Hash Cond标识要被连接的列。
- Nested Loop – 在较大数据集的行上迭代，在每次迭代时于较小的数据集中扫描行。嵌套循环连接要求广播其中的一个表，这样一个表中的所有行才能与其他表中的所有行进行比较。它在较小的表或者通过使用索引约束的表上执行得不错。它还被用于笛卡尔积和范围连接。在使用Nested Loop连接大型表时会有性能影响。对于包含Nested Loop连接操作符的计划节点，应该验证SQL并且确保结果是想要的结果。设置服务器配置参数enable_nestloop为OFF（默认）能够让优化器更偏爱Hash Join。
- Merge Join – 排序两个数据集并且将它们合并起来。归并连接对预排序好的数据很快，但是在现实世界中很少见。为了更偏爱Merge Join，可把系统配置参数enable_mergejoin设置为ON。

一些查询计划节点指定移动操作。在处理查询需要时，移动操作在Segment之间移动行。该节点标识执行移动操作使用的方法。Motion操作符包括下列：

- Broadcast motion – 每一个Segment将自己的行发送给所有其他Segment，这样每一个Segment实例都有表的一份完整的本地拷贝。Broadcast motion可能不如Redistribute motion那么好，因此优化器通常只为小型表选择Broadcast motion。对大型表来说，Broadcast motion是不可接受的。在数据没有按照连接键分布的情况下，将把一个表中所需的行动态重分布到另一个Segment。
- Redistribute motion – 每一个Segment重新哈希数据并且把行发送到对应于哈希键的合适Segment上。
- Gather motion – 来自所有Segment的结果数据被组装成一个单一的流。对大部分查询计划来说这是最后的操作。

查询计划中出现的其他操作符包括：

- Materialize – 规划器将一个子查询物化一次，这样就不用为顶层行重复该工作。
- InitPlan – 一个预查询，被用在动态分区消除中，当执行时还不知道规划器需要用来标识要扫描分区的值时，会执行这个预查询。
- Sort – 为另一个要求排序数据的操作（例如Aggregation或者Merge Join）准备排序数据。
- Group By – 通过一个或者更多列分组行。
- Group/Hash Aggregate – 使用哈希聚集行。
- Append – 串接数据集，例如在整合从分区表中各分区扫描的行时会用到。
- Filter – 使用来自于一个WHERE子句的条件选择行。
- Limit – 限制返回的行数。

## 优化Greenplum查询

这个主题描述可以用来在某些情况下提高系统性能的Greenplum数据库特性和编程实践。

为了分析查询计划，首先找出估计代价非常高的计划节点。判断估计的行数和代价是不是和该操作执行的行数相关。

如果使用分区，验证是否实现了分区消除。要实现分区消除，查询谓词（WHERE子句）必须与分区条件相同。还有，WHERE子句不能包含显式值且不能含有子查询。

审查查询计划树的执行顺序。审查估计的行数。用户想要执行顺序构建在较小的表或者哈希连接结果上并且用较大的表来探查。最优情况下，最大的表被用于最后的连接或者探查以减少传递到树最顶层计划节点的行数。如果分析结果显示构建或探查的执行顺序不是最优的，应确保数据库统计信息为最新。运行ANALYZE将能更新数据库统计信息，进而产生一个最优的查询计划。

查找计算性倾斜的迹象。当Hash Aggregate和Hash Join之类的操作符的执行导致Segment上的不平均执行时，查询执行中会发生计算性倾斜。在一些Segment上会使用比其他更多的CPU和内存，导致非最优的执行。原因可能是在具有低基数或者非一致分布的列上的连接、排序或者聚集。用户可以在查询的EXPLAIN ANALYZE语句中检测计算性倾斜。每个节点包括任一Segment所处理的最大行数以及所有Segment处理的平均行数。如果最大行数远大于平均数，那么至少有一个Segment执行了比其他更多的工作，因此应该怀疑该操作符出现了计算性倾斜。

确定执行Sort或者Aggregate操作的计划节点。Aggregate操作下隐藏的就是一个Sort。如果Sort或者Aggregate操作涉及到大量行，这就是改进查询性能的机会。在需要排序大量行时，HashAggregate操作是比Sor和Aggregate操作更好的操作。通常优化器会因为SQL结构（也就是由于编写SQL的方式）而选择Sort操作。在重写查询时，大部分的Sort操作可以用HashAggregate替换。要更偏爱HashAggregate操作而不是Sort和Aggregate，请确保服务器配置参数enable_groupagg被设置为ON。

当解释计划显示带有大量行的广播移动时，用户应该尝试消除广播移动。一种方法是使用服务器配置参数gp_segments_for_planner来增加这种移动的代价估计，这样优化器会偏向其他可替代的方案。gp_segments_for_planner变量告诉查询规划器在其计算中使用多少主Segment。默认值是零，这会告诉规划器在估算中使用实际的主Segment数量。增加主Segment的数量会增加移动的代价，因此会更加偏向重新分布移动。例如，设置gp_segments_for_planner = 100000会告诉规划器有100,000个Segment。反过来，要影响规划器广播表而不是重新分布它，可以把gp_segments_for_planner设置为一个较低的值，例如2。

### Greenplum分组扩展

Greenplum数据库对GROUP BY子句的聚集扩展可以让一些常见计算在数据库中执行得比在应用或者过程代码中更加高效：

- GROUP BY ROLLUP(*col1*, *col2*, *col3*)
- GROUP BY CUBE(*col1*, *col2*, *col3*)
- GROUP BY GROUPING SETS((*col1*, *col2*), (*col1*, *col3*))

ROLLUP分组创建从最详细层次上滚到总计的聚集小计，后面跟着分组列（或者表达式）列表。ROLLUP接收分组列的一个有序列表，计算GROUP BY子句中指定的标准聚集值，然后根据该列表从右至左渐进地创建更高层的小计。最后创建总计。

CUBE分组创建给定分组列（或者表达式）列表所有可能组合的小计。在多维分析术语中，CUBE产生一个数据立方体在指定维度可以被计算的所有小计。

用户可以用GROUPING SETS表达式选择性地指定想要创建的分组集。这允许在多个维度间进行精确的说明而无需计算整个ROLLUP或者CUBE.

这些子句的细节请参考*Greenplum数据库参考指南*。

### 窗口函数

窗口函数在结果集的划分上应用聚集或者排名函数——例如，sum(population) over (partition by city)。窗口函数很强大，因为它们的所有工作都在数据库内完成，它们比通过从数据库中检索细节行并且预处理它们来产生类似结果的前端工具具有性能优势。

- row_number()窗口函数为一个划分中的行产生行号，例如row_number() over (order by id)。
- 当查询计划表明一个表被多个操作扫描时，用户可以使用窗口函数来降低扫描次数。
- 经常可以通过使用窗口函数消除自连接。



# 结束进程

**结束进程两种方式：**

```
SELECT pg_cancel_backend(PID)
```

取消后台操作，回滚未提交事物 (select);

```
SELECT pg_terminate_backend(PID)
```

中断session，回滚未提交事物(select、update、delete、drop);

```
SELECT` `* ``FROM` `pg_stat_activity;
```

根据datid=10841

```
SELECT` `pg_terminate_backend (10841);
```

**补充：PostgreSQL无法在PL / pgSQL中开始/结束事务**

# 常见问题

本文链接：https://blog.csdn.net/q936889811/article/details/85612046

​        文章目录

1、错误：数据库初始化：gpinitsystem -c gpconfigs/gpinitsystem_config -h list

2、错误 ：执行检查：gpcheck -f list

3、错误：gpadmin-[CRITICAL]:-gpstate failed. (Reason='Environment Variable MASTER_DATA_DIRECTORY not set!') exiting...

4、错误： Reason='[Errno 12] Cannot allocate memory'

5、ERROR: permission denied: "gp_segment_configuration" is a system catalog

6、错误：FATAL","XX000","could not create shared memory segment: Cannot allocate memory (pg_shmem.c:183)"

7、修改shared_buffer，使无法启动数据库

8、

9、File "/home/gpadmin/greenplum-db/lib/python/gppylib/commands/base.py", line 243, in run

10、ould not create shared memory segment: Invalid argument (pg_shmem.c:136),Failed

11、"failed to acquire resources on one or more segments","connection pointer is NULL

12、

13、VM protect failed to allocate 131080 bytes from system, VM Protect 8098 MB available

14、psql: FATAL: DTM initialization: failure during startup recovery, retry failed, check segment status (cdbtm.c:1602)
1、错误：数据库初始化：gpinitsystem -c gpconfigs/gpinitsystem_config -h list
错误提示：
2018-08-29 16:51:01.338476 CST,,,p21229,th406714176,,,,0,,,seg-999,,,,,"FATAL","XX000","could not create semaphores: No space left on device (pg_sema.c:129)","Failed system call was semget(127, 17, 03600).","This error does *not* mean that you have run out of disk space.
It occurs when either the system limit for the maximum number of semaphore sets (SEMMNI), or the system wide maximum number of semaphores (SEMMNS), would be exceeded. You need to raise the respective kernel parameter. Alternatively, reduce PostgreSQL's consumption ofsemaphores by reducing its max_connections parameter (currently 753).
The PostgreSQL documentation contains more information about configuring your system for PostgreSQL.",,,,,,"InternalIpcSemaphoreCreate","pg_sema.c",129,1  0x95661b postgres errstart (elog.c:521)

解决办法：
[root@bj-ksy-g1-mongos-02 primary]# cat /proc/sys/kernel/sem
250 32000 32 128

修改kernel.sem为：
[root@bj-ksy-g1-mongos-02 primary]# cat /etc/sysctl.conf
kernel.sem = 250 512000 100 2048

12345678910111213
2、错误 ：执行检查：gpcheck -f list
错误提示：
XFS filesystem on device /dev/vdb1 is missing the recommended mount option 'allocsize=16m'

解决办法：
[gpadmin@bj-ksy-g1-mongos-01 ~]$ cat /etc/fstab
/dev/vdb1 /opt xfs defaults,allocsize=16348k,inode64,noatime    1 1

1234567
3、错误：gpadmin-[CRITICAL]:-gpstate failed. (Reason=‘Environment Variable MASTER_DATA_DIRECTORY not set!’) exiting…
错误提示：
[gpadmin@bj-ksy-g1-mongos-01 ~]$ gpstop
20180830:09:11:42:011904 gpstop:bj-ksy-g1-mongos-01:gpadmin-[INFO]:-Starting gpstop with args:
20180830:09:11:42:011904 gpstop:bj-ksy-g1-mongos-01:gpadmin-[INFO]:-Gathering information and validating the environment...
20180830:09:11:42:011904 gpstop:bj-ksy-g1-mongos-01:gpadmin-[CRITICAL]:-gpstop failed. (Reason='Environment Variable MASTER_DATA_DIRECTORY not set!') exiting...
[gpadmin@bj-ksy-g1-mongos-01 ~]$ gpstop -M fast
20180830:09:12:07:011962 gpstop:bj-ksy-g1-mongos-01:gpadmin-[INFO]:-Starting gpstop with args: -M fast
20180830:09:12:07:011962 gpstop:bj-ksy-g1-mongos-01:gpadmin-[INFO]:-Gathering information and validating the environment...
20180830:09:12:07:011962 gpstop:bj-ksy-g1-mongos-01:gpadmin-[CRITICAL]:-gpstop failed. (Reason='Environment Variable MASTER_DATA_DIRECTORY not set!') exiting...
[gpadmin@bj-ksy-g1-mongos-01 ~]$ gpstate
20180830:09:13:03:012093 gpstate:bj-ksy-g1-mongos-01:gpadmin-[INFO]:-Starting gpstate with args:
20180830:09:13:03:012093 gpstate:bj-ksy-g1-mongos-01:gpadmin-[CRITICAL]:-gpstate failed. (Reason='Environment Variable MASTER_DATA_DIRECTORY not set!') exiting...
1234567891011
解决方法：
[gpadmin@bj-ksy-g1-mongos-01 ~]$ vim ~/.bashrc
添加：
MASTER_DATA_DIRECTORY=/opt/data/master/gpseg-1
export MASTER_DATA_DIRECTORY
1234
4、错误： Reason=’[Errno 12] Cannot allocate memory’

gpstart、gpstate、gpstop操作会报同样的错误

错误提示：
[gpadmin@bj-ksy-g1-mongos-01 ~]$ gpstate -s
20180830:09:22:01:013309 gpstate:bj-ksy-g1-mongos-01:gpadmin-[INFO]:-Starting gpstate with args: -s
20180830:09:22:01:013309 gpstate:bj-ksy-g1-mongos-01:gpadmin-[CRITICAL]:-gpstate failed. (Reason='[Errno 12] Cannot allocate memory') exiting...
123
解决方法：
使用root用户

[root@bj-ksy-g1-mongos-01 ~]# swapon -s #查看swap情况
[root@bj-ksy-g1-mongos-01 ~]# dd if=/dev/zero of=/swapfile bs=1024 count=1024k
1048576+0 records in
1048576+0 records out
1073741824 bytes (1.1 GB) copied, 3.20053 s, 335 MB/s
[root@bj-ksy-g1-mongos-01 ~]# mkswap /swapfile
Setting up swapspace version 1, size = 1048572 KiB
no label, UUID=3e8ef2b3-5d9e-4e04-9718-36caefbfc21d
[root@bj-ksy-g1-mongos-01 ~]# swapon /swapfile
swapon: /swapfile: insecure permissions 0644, 0600 suggested.

[root@bj-ksy-g1-mongos-01 ~]#vim /etc/fstab #使swap持久化
添加：
/swapfile none swap sw 0 0

进入gpadmin
验证结果
[gpadmin@bj-ksy-g1-mongos-01 ~]$ gpstate -s
20180830:09:34:56:015816 gpstate:bj-ksy-g1-mongos-01:gpadmin-[INFO]:-Starting gpstate with args: -s
20180830:09:34:56:015816 gpstate:bj-ksy-g1-mongos-01:gpadmin-[INFO]:-local Greenplum Version: 'postgres (Greenplum Database) 5.4.0 build commit:1971b301f52979ac74fb3d0a141bbaae06b70857'
20180830:09:34:56:015816 gpstate:bj-ksy-g1-mongos-01:gpadmin-[INFO]:-master Greenplum Version: 'PostgreSQL 8.3.23 (Greenplum Database 5.4.0 build commit:1971b301f52979ac74fb3d0a141bbaae06b70857) on x86_64-pc-linux-gnu, compiled by GCC gcc (GCC) 6.2.0, 64-bit compiled on Jan 12 2018 21:15:36'
20180830:09:34:56:015816 gpstate:bj-ksy-g1-mongos-01:gpadmin-[INFO]:-Obtaining Segment details from master...
20180830:09:34:56:015816 gpstate:bj-ksy-g1-mongos-01:gpadmin-[INFO]:-Gathering data from segments...
20180830:09:34:57:015816 gpstate:bj-ksy-g1-mongos-01:gpadmin-[INFO]:-----------------------------------------------------
20180830:09:34:57:015816 gpstate:bj-ksy-g1-mongos-01:gpadmin-[INFO]:--Master Configuration & Status
123456789101112131415161718192021222324252627
5、ERROR: permission denied: “gp_segment_configuration” is a system catalog
错误：

ERROR: permission denied: “gp_segment_configuration” is a system catalog

解决：
postgres=# delete from gp_segment_configuration where role='m';
ERROR: permission denied: "gp_segment_configuration" is a system catalog
postgres=# set allow_system_table_mods='dml';
SET
postgres=# delete from gp_segment_configuration where role='m';
DELETE 9
postgres=#
1234567
6、错误：FATAL",“XX000”,“could not create shared memory segment: Cannot allocate memory (pg_shmem.c:183)”
2018-10-15 19:45:37.841672 CST,,,p10296,th624441152,,,,0,,,seg-1,,,,,"FATAL","XX000","could not create shared memory segment: Cannot allocate memory (pg_shmem.c:183)","Failed system call was shmget(key=40002001, size=267762784, 03600).","This error usually means that PostgreSQL's request for a shared memory segment exceeded available memory or swap space. To reduce the request size (currently 267762784 bytes), reduce PostgreSQL's shared_buffers parameter (currently 4000) and/or its max_connections parameter (currently 753).
The PostgreSQL documentation contains more information about shared memory configuration.",,,,,,"InternalIpcMemoryCreate","pg_shmem.c",183,1  0x95661b postgres errstart (elog.c:521)
2  0x7bc723 postgres <symbol not found> (pg_shmem.c:145)
3  0x7bc9ba postgres PGSharedMemoryCreate (pg_shmem.c:387)
4  0x812d69 postgres CreateSharedMemoryAndSemaphores (ipci.c:242)
5  0x7d47dc postgres PostmasterMain (postmaster.c:3996)
6  0x4c8af7 postgres main (main.c:206)
7  0x7f372083ab15 libc.so.6 __libc_start_main + 0xf5
8  0x4c904c postgres <symbol not found> + 0x4c904c

12345678910
解决方法：
使用root用户

[root@bj-ksy-g1-mongos-01 ~]# swapon -s #查看swap情况
[root@bj-ksy-g1-mongos-01 ~]# dd if=/dev/zero of=/swapfile bs=1024 count=1024k
1048576+0 records in
1048576+0 records out
1073741824 bytes (1.1 GB) copied, 3.20053 s, 335 MB/s
[root@bj-ksy-g1-mongos-01 ~]# mkswap /swapfile
Setting up swapspace version 1, size = 1048572 KiB
no label, UUID=3e8ef2b3-5d9e-4e04-9718-36caefbfc21d
[root@bj-ksy-g1-mongos-01 ~]# swapon /swapfile
swapon: /swapfile: insecure permissions 0644, 0600 suggested.

[root@bj-ksy-g1-mongos-01 ~]#vim /etc/fstab #使swap持久化
添加：
/swapfile none swap sw 0 0
12345678910111213141516
7、修改shared_buffer，使无法启动数据库
gpconfig -c shared_buffers -v "8192MB"
greenplum修改shared_buffer，使无法启动数据库。
原因：kernel.shmmax的值为500000000(476MB),shared_buffer大于476MB时，数据库就无法正常启动。kernel.shmmax参数设置过小。

解决办法：增加kernel.shmmax，最好把此参数设置为总内存的50%。

123456
8、
greenplum运行一段时间连接失败，并且pg_stat_activity的连接数没有达到设置的限制。
net.core.somaxconn=65535
net.core.rmem_max=16777216
net.core.wmem_max=16777216
net.core.somaxconn是Linux中的一个kernel参数，表示socket监听（listen）的backlog上限。什么是backlog呢？backlog就是socket的监听队列，当一个请求（request）尚未被处理或建立时，他会进入backlog。而socket server可以一次性处理backlog中的所有请求，处理后的请求不再位于监听队列中。当server处理请求较慢，以至于监听队列被填满后，新来的请求会被拒绝。
Linux的参数net.core.somaxconn默认值同样为128。当服务端繁忙时，如NameNode或JobTracker，128是远远不够的。这样就需要增大backlog，例如我们的3000台集群就将ipc.server.listen.queue.size设成了32768，为了使得整个参数达到预期效果，同样需要将kernel参数net.core.somaxconn设成一个大于等于32768的值。
9、File “/home/gpadmin/greenplum-db/lib/python/gppylib/commands/base.py”, line 243, in run
错误提示：
gpstate -s
所有的segment出现故障
开始停掉greenplum
gpstop -a
错误输出：
'
20181227:10:18:11:2243549 gpstop:hrdskf-k:gpadmin-[ERROR]:-ExecutionError: 'non-zero rc: 1' occured. Details: 'ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=60 hrdskf-k ". /home/gpadmin/greenplum-db/./greenplum_path.sh; $GPHOME/sbin/gpoperation.py"' cmd had rc=1 completed=True halted=False
 stdout=''
 stderr='\S
Kernel \r on an \m
Warm tips :Authorized for Haier Utility's Uses only. All activity may be monitored and reported.
If you have any questions,please contact us.
Mailbox:dts.jxjg@haier.com
Phone:68066686 / 1000 / 8173
WARNING: Your password has expired.
Password change required but no TTY available.
'
Traceback (most recent call last):
 File "/home/gpadmin/greenplum-db/lib/python/gppylib/commands/base.py", line 243, in run
  self.cmd.run()
 File "/home/gpadmin/greenplum-db/lib/python/gppylib/operations/__init__.py", line 53, in run
  self.ret = self.execute()
 File "/home/gpadmin/greenplum-db/lib/python/gppylib/operations/utils.py", line 48, in execute
  cmd.run(validateAfter=True)
 File "/home/gpadmin/greenplum-db/lib/python/gppylib/commands/base.py", line 717, in run
  self.validate()
 File "/home/gpadmin/greenplum-db/lib/python/gppylib/commands/base.py", line 764, in validate
  raise ExecutionError("non-zero rc: %d" % self.results.rc, self)
ExecutionError: ExecutionError: 'non-zero rc: 1' occured. Details: 'ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=60 hrdskf-k ". /home/gpadmin/greenplum-db/./greenplum_path.sh; $GPHOME/sbin/gpoperation.py"' cmd had rc=1 completed=True halted=False
 stdout=''
 stderr='\S
Kernel \r on an \m
Warm tips :Authorized for Haier Utility's Uses only. All activity may be monitored and reported.
If you have any questions,please contact us.
Mailbox:dts.jxjg@haier.com
Phone:68066686 / 1000 / 8173
WARNING: Your password has expired.
Password change required but no TTY available.
123456789101112131415161718192021222324252627282930313233
解决思路：
通过日志分析ssh问题
1、验证是否可以免密登陆
2、结果需要重新设置密码
3、ssh hostname 提示修改密码
服务器的普通设置，默认有实效时间
查看并修改密码有效时间
[root@hrdskf-m ~]# chage -l gpadmin
Last password change                  : Dec 27, 2018
Password expires                    : Feb 25, 2019
Password inactive                    : never
Account expires                     : never
Minimum number of days between password change     : 1
Maximum number of days between password change     : 60
Number of days of warning before password expires    : 14
[root@hrdskf-m ~]# chage -l root
Last password change                  : Dec 24, 2018
Password expires                    : never
Password inactive                    : never
Account expires                     : never
Minimum number of days between password change     : 0
Maximum number of days between password change     : 99999
Number of days of warning before password expires    : 7
[root@hrdskf-m ~]# chage -M 99999 gpadmin  #此设置永不过期
[root@hrdskf-m ~]# chage -l gpadmin
Last password change                  : Dec 27, 2018
Password expires                    : never
Password inactive                    : never
Account expires                     : never
Minimum number of days between password change     : 1
Maximum number of days between password change     : 99999
Number of days of warning before password expires    : 14
[root@hrdskf-m ~]#
1234567891011121314151617181920212223242526
10、ould not create shared memory segment: Invalid argument (pg_shmem.c:136),Failed
error:"could not create shared memory segment: Invalid argument (pg_shmem.c:136),Failed "
解决：You will need to reduce the value of the parameter max_connections.
11、“failed to acquire resources on one or more segments”,"connection pointer is NULL
错误：2018-11-09 10:08:13.279910 CST,"gpadmin","xn_report",p119553,th-1821042816,"172.23.0.74","16532",2018-11-09 10:08:13 CST,0,con10783,,seg-1,,dx2364872,,sx1,"ERROR","58M01","failed to acquire resources on one or more segments","connection pointer is NULL
1
这与Master上的Query Dispatcher（QD）进程有关。它显示连接到主服务器上的postmaster进程的主服务器上的QD进程连接问题。
可以将参数gp_reject_internal_tcp_connection更改为“off”。此参数的默认值为“on”。此参数用于允许与主服务器的内部TCP连接。理想情况下，应使用UNIX域套接字而不是TCP连接，这就是参数gp_reject_internal_tcp_connection的默认值为“on”的原因。
此参数是受限制的参数，在设置此参数时，您需要使用“–skipvalidation”值。要设置参数，您需要运行以下命令：
gpconfig -c gp_reject_internal_tcp_connection -v off --skipvalidation
注意 - 设置此参数后，需要重新启动数据库。
https://community.pivotal.io/s/article/Error-Failed-to-acquire-resources-on-one-or-more-segments-in-Pivotal-Greenplum
12、
max_connections 数据库服务器的最大并发连接数。在Greenplum系统中，用户客户端连接仅通过Greenplum主实例。段实例应该允许5-10倍的数量。增加此参数时，还必须增加max_prepared_transactions。
max_prepared_transactions：
设置可以同时处于准备状态的最大事务数。Greenplum在内部使用准备好的事务来确保各个段的数据完整性。该值必须至少与主服务器上的max_connections值一样大。段实例应设置为与主节点相同的值。
gpconfig -c max_prepared_transactions -v 500
gpconfig -c max_connections -v 2500 -m 500
13、VM protect failed to allocate 131080 bytes from system, VM Protect 8098 MB available
VM protect failed to allocate 131080 bytes from system, VM Protect 8098 MB available

```sh
gpconfig -c gp_max_plan_size -v "200MB"
```

1234
14、psql: FATAL: DTM initialization: failure during startup recovery, retry failed, check segment status (cdbtm.c:1602)
psql: FATAL: DTM initialization: failure during startup recovery, retry failed, check segment status (cdbtm.c:1602)

12
数据库启动节点都是up正常状态
解决办法：

```sh
GOPTIONS='-c gp_session_role=utility' psql -d postgres
```



# failed to acquire resources on one or more segments

11、“failed to acquire resources on one or more segments”,"connection pointer is NULL
错误：2018-11-09 10:08:13.279910 CST,"gpadmin","xn_report",p119553,th-1821042816,"172.23.0.74","16532",2018-11-09 10:08:13 CST,0,con10783,,seg-1,,dx2364872,,sx1,"ERROR","58M01","failed to acquire resources on one or more segments","connection pointer is NULL
1
这与Master上的Query Dispatcher（QD）进程有关。它显示连接到主服务器上的postmaster进程的主服务器上的QD进程连接问题。
可以将参数gp_reject_internal_tcp_connection更改为“off”。此参数的默认值为“on”。此参数用于允许与主服务器的内部TCP连接。理想情况下，应使用UNIX域套接字而不是TCP连接，这就是参数gp_reject_internal_tcp_connection的默认值为“on”的原因。
此参数是受限制的参数，在设置此参数时，您需要使用“–skipvalidation”值。要设置参数，您需要运行以下命令：
gpconfig -c gp_reject_internal_tcp_connection -v off --skipvalidation
注意 - 设置此参数后，需要重新启动数据库。
https://community.pivotal.io/s/article/Error-Failed-to-acquire-resources-on-one-or-more-segments-in-Pivotal-Greenplum



# 重置为默认的方法

gpconfig只能在系统启动的情况下调用，所以如果参数修改不合适，导致系统无法启动时，我们可以用下列方法处理:

- 1、先把master的参数修改成正常的值
- 2、gpstart -m 仅启动master进入管理模式
- 3、gpconfig -r <参数> -- 把参数重置成默认值
- 4、gpstop -a -r -M fast





```
failed to acquire resources on one or more segments,  timeout expired
```



# 压力测试



```
./bin/tclsh8.6: /lib64/libm.so.6: version `GLIBC_2.29' not found
```

改用docker 

改用 pgbench,注意： 直接通过编译postgresql安装包方式失效，原因是postgresql源码包中缺失相关编译需要的文件。

```sh
yum install -y postgresql-contrib
```





> `starting vacuum...ERROR:  relation "pgbench_branches" does not exist`

```

```



#### 2.2.1、集群参数优化（可选）

| **参数**                           | **参数值** | **说明**                                                     | **参数设置方式**                                     |
| ---------------------------------- | ---------- | ------------------------------------------------------------ | ---------------------------------------------------- |
| optimizer                          | off        | 关闭针对AP场景的orca优化器，对TP性能更友好。                 | gpconfig -c optimizer -v off                         |
| shared_buffers                     | 8GB        | 将数据共享缓存调大。修改该参数需要重启实例。                 | gpconfig -c shared_buffers -v 8GB                    |
| wal_buffers                        | 256MB      | 将WAL日志缓存调大。修改该参数需要重启实例。                  | gpconfig -c wal_buffers -v 256MB                     |
| log_statement                      | none       | 将日志输出关闭。                                             | gpconfig -c log_statement -v none                    |
| random_page_cost                   | 10         | 将随机访问代价开销调小，有利于查询走索引。                   | gpconfig -c random_page_cost -v 10                   |
| gp_resqueue_priority               | off        | 将resource queue关闭。需要重启实例                           | gpconfig -c gp_resqueue_priority -v off              |
| resource_scheduler                 | off        | 将resource queue关闭。需要重启实例                           | gpconfig -c resource_scheduler -v off                |
| gp_enable_global_deadlock_detector | on         | 控制是否开启全局死锁检测功能，打开它才可以支持并发更新/删除操作； | gpconfig -c gp_enable_global_deadlock_detector -v on |
| checkpoint_segments                | 2          | 影响checkpoint主动刷盘的频率，针对OLTP大量更新类语句适当调小此设置会增加刷盘频率，平均性能会有较明显提升； | gpconfig -c checkpoint_segments -v 2 –skipvalidation |

PS: [参考](https://www.jianshu.com/p/d0e3d66a94f4)



# 初始化密码

新安装PostgreSQL后，创建的postgre用户是没有密码的，
一般在pg_hba.conf中配置：

```
host all all 0.0.0.0/0 trust
```

将导致任何人都能访问数据库，
是非常危险的，
建议修改为：

```
host all all 0.0.0.0/0 md5
```



# Cancel query

在 Greenplum 中，停止一个正在运行的查询有多种方法，具体取决于你使用的工具和你拥有的权限。下面是几种通用的方法：

1. 使用pg_cancel_backend函数：该函数需要目标进程的pid作为参数，可以尝试优雅地取消正在运行的查询。首先，你需要查询正在运行的进程的pid，例如：

   ```sql
   
   SELECT pid, query FROM pg_stat_activity WHERE state = 'active';
   ```

   然后使用找到的pid调用pg_cancel_backend函数：

   ```sql
   
   SELECT pg_cancel_backend('pid');
   ```

2. 使用gp_cancel_query函数：该函数类似于pg_cancel_backend函数，但是在 Greenplum 中是更推荐的方法，因为它会检查并取消所有相关的进程，而不仅仅是目标进程。例如：

   ```sql
   select pg_terminate_backend('pid');
   SELECT gp_cancel_query(gp_session_id());
   ```

   这将取消当前会话中正在运行的所有查询。

3. 使用pgAdmin或psql工具：这些工具提供了一个直观的界面来列出所有活动进程和它们正在运行的查询，并允许你选择某个进程并中止它。

需要注意的是，强制停止一个查询可能会导致数据不一致或者其他问题，所以请谨慎使用。

# 实践

https://cn.greenplum.org/greenplumha/

https://www.hnbian.cn/posts/2138505f.html

# 管理员



|              |                                                              |                                                              |
| ------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| MPP架构      | 多处理器协同执行一个操作、使用系统所有资源并行处理一个查询   |                                                              |
| 追加优化     |                                                              |                                                              |
| interconnect | B默认情况下，Interconnect使用带流控制的用户数据包协议（UDPIFC）在网络上发送消息。 Greenplum软件在UDP之上执行包验证。这意味着其可靠性等效于传输控制协议（TCP）且性能和可扩展性要超过TCP。 如果Interconnect被改为TCP，Greenplum数据库会有1000个Segment实例的可扩展性限制。对于Interconnect的默认协议UDPIFC则不存在这种限制。 | postgresql.conf<br>gp_interconnect_type=udpifc --> gp_interconnect_type=tcp |
| 扩容         | 每个表或分区在扩容期间是无法进行读写操作的                   |                                                              |



```mermaid
flowchart TB
  subgraph 集群
  Master --> P1[Primary1 141.3.196.19]
  P1 --> S1(seg 4个)
  Master --> P2[Primary2 141.3.196.20]
    P2 --> S2(seg 4个)
  Master --> P3[Primary3 141.3.196.21]
    P3 --> S3(seg 4个)
  Master --> P4[Primary4 141.3.196.22]
    P4 --> S4(seg 4个)
  Master --> P5[Primary5 141.3.196.24]
    P5 --> S5(seg 4个)
  end
  subgraph 扩容
  P4 -->|2023-05-26| S6(seg 4个)
  Master --> P6[Primary6 141.3.196.27]
  P6 -->|2023-05-26| S7(seg 4个)
  end 

```



```mermaid
graph LR
A(开始) --> B(增加节点)
B --> C(增加节点)
C --> D(增加节点)
D --> E(增加节点)
E --> F(增加节点)
F --> G(结束)

B -->|2021-07-01| H[节点1]
C -->|2021-07-05| I[节点2]
D -->|2021-07-10| J[节点3]
E -->|2021-07-15| K[节点4]
F -->|2021-07-20| L[节点5]

style A fill:#6f9;color:#fff,stroke:#333,stroke-width:2px
style B-D fill:#9f6;color:#fff,stroke:#333,stroke-width:2px
style E-G fill:#f96;color:#fff,stroke:#333,stroke-width:2px
style H-L fill:#69c;color:#fff,stroke:#333,stroke-width:2px

```





```mermaid
graph LR;
    A[客户端] --> B(Greenplum Master);
    B -->|元数据| C(Greenplum Catalog);
    B -->|查询解析| D(Greenplum Dispatcher);
    D -->|查询计划| E(Greenplum Planner);
    E -->|查询优化| F(Greenplum Optimizer);
    B -->|数据切分| G(Greenplum Segment);
    G -->|存储数据| H(Greenplum Data Nodes);
    I[141.3.196.27新节点] -->|加入集群| J(Greenplum Master);
    J -->|元数据同步| C;
    J -->|数据切分| K(Greenplum Segment);
    K -->|存储数据| L(Greenplum Data Nodes);
    G -->|负载均衡| M(Greenplum Master);
    M -->|数据重分布| K;

```



| greenplum 对比 | postgres |      |
| -------------- | -------- | ---- |
|                |          |      |
|                |          |      |
|                |          |      |



![image-20230529120151167](.img_greenplum/image-20230529120151167.png)

[rpm下载](https://network.pivotal.io/products/vmware-tanzu-greenplum#/releases/1193700/file_groups/10395)



```
fcopy
```



# best_practices



A newer version of this documentation is available. Use the version menu above to view the most up-to-date release of the Greenplum 6.x documentation.

# System Configuration

Requirements and best practices for system administrators who are configuring Greenplum Database cluster hosts.

Configuration of the Greenplum Database cluster is usually performed as root.

## Configuring the Timezone

Greenplum Database selects a timezone to use from a set of internally stored PostgreSQL timezones. The available PostgreSQL timezones are taken from the Internet Assigned Numbers Authority (IANA) Time Zone Database, and Greenplum Database updates its list of available timezones as necessary when the IANA database changes for PostgreSQL.

Greenplum selects the timezone by matching a PostgreSQL timezone with the user specified time zone, or the host system time zone if no time zone is configured. For example, when selecting a default timezone, Greenplum uses an algorithm to select a PostgreSQL timezone based on the host system timezone files. If the system timezone includes leap second information, Greenplum Database cannot match the system timezone with a PostgreSQL timezone. In this case, Greenplum Database calculates a "best match" with a PostgreSQL timezone based on information from the host system.

As a best practice, configure Greenplum Database and the host systems to use a known, supported timezone. This sets the timezone for the Greenplum Database master and segment instances, and prevents Greenplum Database from recalculating a "best match" timezone each time the cluster is restarted, using the current system timezone and Greenplum timezone files (which may have been updated from the IANA database since the last restart). Use the gpconfig utility to show and set the Greenplum Database timezone. For example, these commands show the Greenplum Database timezone and set the timezone to US/Pacific.

```
# gpconfig -s TimeZone
# gpconfig -c TimeZone -v 'US/Pacific'
```

You must restart Greenplum Database after changing the timezone. The command gpstop -ra restarts Greenplum Database. The catalog view pg_timezone_names provides Greenplum Database timezone information.

## File System

XFS is the file system used for Greenplum Database data directories. On RHEL/CentOS systems, mount XFS volumes with the following mount options:

```
rw,nodev,noatime,nobarrier,inode64
```

The nobarrier option is not supported on Ubuntu systems. Use only the options:

```
rw,nodev,noatime,inode64
```

## Port Configuration

See the [recommended OS parameter settings](https://gpdb.docs.pivotal.io/6-3/install_guide/prep_os.html#topic3) in the Greenplum Database Installation Guide for further details.

Set up ip_local_port_range so it does not conflict with the Greenplum Database port ranges. For example, setting this range in /etc/sysctl.conf:

```
net.ipv4.ip_local_port_range = 10000  65535
```

you could set the Greenplum Database base port numbers to these values.

```
PORT_BASE = 6000
MIRROR_PORT_BASE = 7000
```

See the [Recommended OS Parameters Settings](https://gpdb.docs.pivotal.io/6-3/install_guide/prep_os.html#topic3) in the Greenplum Database Installation Guide for further details.

## I/O Configuration

Set the blockdev read-ahead size to 16384 on the devices that contain data directories. This command sets the read-ahead size for /dev/sdb.

```
# /sbin/blockdev --setra 16384 /dev/sdb
```

This command returns the read-ahead size for /dev/sdb.

```
# /sbin/blockdev --getra /dev/sdb
16384
```

See the [Recommended OS Parameters Settings](https://gpdb.docs.pivotal.io/6-3/install_guide/prep_os.html#topic3) in the Greenplum Database Installation Guide for further details.

The deadline IO scheduler should be set for all data directory devices.

```
 # cat /sys/block/sdb/queue/scheduler
 noop anticipatory [deadline] cfq 
```

The maximum number of OS files and processes should be increased in the /etc/security/limits.conf file.

```
* soft  nofile 524288
* hard  nofile 524288
* soft  nproc 131072
* hard  nproc 131072
```

Enable core files output to a known location and make sure limits.conf allows core files.

```
kernel.core_pattern = /var/core/core.%h.%t
# grep core /etc/security/limits.conf  
* soft  core unlimited
```

## OS Memory Configuration

The Linux sysctl vm.overcommit_memory and vm.overcommit_ratio variables affect how the operating system manages memory allocation. See the [/etc/sysctl.conf](https://gpdb.docs.pivotal.io/6-3/install_guide/prep_os.html#topic3__sysctl_file) file parameters guidelines in the Greenplum Datatabase Installation Guide for further details.

vm.overcommit_memory determines the method the OS uses for determining how much memory can be allocated to processes. This should be always set to 2, which is the only safe setting for the database.

Note: For information on configuration of overcommit memory, refer to:

- [https://en.wikipedia.org/wiki/Memory_overcommitment](https://www.google.com/url?q=https://en.wikipedia.org/wiki/Memory_overcommitment&sa=D&ust=1499719618717000&usg=AFQjCNErcHO7vErv4pn9fIhCxrR0XRiknA)
- [https://www.kernel.org/doc/Documentation/vm/overcommit-accounting](https://www.google.com/url?q=https://www.kernel.org/doc/Documentation/vm/overcommit-accounting&sa=D&ust=1499719618717000&usg=AFQjCNEmu5tZutAaN1KCSlIwz4hwqihkOQ)

vm.overcommit_ratio is the percent of RAM that is used for application processes. The default is 50 on Red Hat Enterprise Linux. See [Resource Queue Segment Memory Configuration](https://gpdb.docs.pivotal.io/6-3/best_practices/sysconfig.html#topic_dt3_fkv_r4__segment_mem_config) for a formula to calculate an optimal value.

Do not enable huge pages in the operating system.

See also [Memory and Resource Management with Resource Queues](https://gpdb.docs.pivotal.io/6-3/best_practices/workloads.html#topic_hhc_z5w_r4).

## Shared Memory Settings

Greenplum Database uses shared memory to communicate between postgres processes that are part of the same postgres instance. The following shared memory settings should be set in sysctl and are rarely modified. See the [sysctl.conf ](https://gpdb.docs.pivotal.io/6-3/install_guide/prep_os.html#topic3__sysctl_file)file parameters in the Greenplum Database Installation Guide for further details.

```
kernel.shmmax = 500000000
kernel.shmmni = 4096
kernel.shmall = 4000000000
```

## Number of Segments per Host

Determining the number of segments to execute on each segment host has immense impact on overall system performance. The segments share the host's CPU cores, memory, and NICs with each other and with other processes running on the host. Over-estimating the number of segments a server can accommodate is a common cause of suboptimal performance.

The factors that must be considered when choosing how many segments to run per host include the following:

- Number of cores
- Amount of physical RAM installed in the server
- Number of NICs
- Amount of storage attached to server
- Mixture of primary and mirror segments
- ETL processes that will run on the hosts
- Non-Greenplum processes running on the hosts

## Resource Queue Segment Memory Configuration

The gp_vmem_protect_limit server configuration parameter specifies the amount of memory that all active postgres processes for a single segment can consume at any given time. Queries that exceed this amount will fail. Use the following calculations to estimate a safe value for gp_vmem_protect_limit.

1. Calculate

    

   gp_vmem

   , the host memory available to Greenplum Database, using this formula:

   ```
   gp_vmem = ((SWAP + RAM) – (7.5GB + 0.05 * RAM)) / 1.7
   ```

   where

    

   SWAP

    

   is the host's swap space in GB and

    

   RAM

    

   is the RAM installed on the host in GB.

2. Calculate max_acting_primary_segments. This is the maximum number of primary segments that can be running on a host when mirror segments are activated due to a segment or host failure on another host in the cluster. With mirrors arranged in a 4-host block with 8 primary segments per host, for example, a single segment host failure would activate two or three mirror segments on each remaining host in the failed host's block. The max_acting_primary_segments value for this configuration is 11 (8 primary segments plus 3 mirrors activated on failure).

3. Calculate

    

   gp_vmem_protect_limit

    

   by dividing the total Greenplum Database memory by the maximum number of acting primaries:

   ```
   gp_vmem_protect_limit = gp_vmem / max_acting_primary_segments
   ```

   Convert to megabytes to find the value to set for the

    

   gp_vmem_protect_limit

    

   system configuration parameter.

For scenarios where a large number of workfiles are generated, adjust the calculation for gp_vmem to account for the workfiles:

```
gp_vmem = ((SWAP + RAM) – (7.5GB + 0.05 * RAM - (300KB * total_#_workfiles))) / 1.7
```

For information about monitoring and managing workfile usage, see the *Greenplum Database Administrator Guide*.

You can calculate the value of the vm.overcommit_ratio operating system parameter from the value of gp_vmem:

```
vm.overcommit_ratio = (RAM - 0.026 * gp_vmem) / RAM
```

See [OS Memory Configuration](https://gpdb.docs.pivotal.io/6-3/best_practices/sysconfig.html#topic_dt3_fkv_r4__os_mem_config) for more about about vm.overcommit_ratio.

See also [Memory and Resource Management with Resource Queues](https://gpdb.docs.pivotal.io/6-3/best_practices/workloads.html#topic_hhc_z5w_r4).

## Resource Queue Statement Memory Configuration

The statement_mem server configuration parameter is the amount of memory to be allocated to any single query in a segment database. If a statement requires additional memory it will spill to disk. Calculate the value for statement_mem with the following formula:

(gp_vmem_protect_limit * .9) / max_expected_concurrent_queries

For example, for 40 concurrent queries with gp_vmem_protect_limit set to 8GB (8192MB), the calculation for statement_mem would be:

(8192MB * .9) / 40 = 184MB

Each query would be allowed 184MB of memory before it must spill to disk.

To increase statement_mem safely you must either increase gp_vmem_protect_limit or reduce the number of concurrent queries. To increase gp_vmem_protect_limit, you must add physical RAM and/or swap space, or reduce the number of segments per host.

Note that adding segment hosts to the cluster cannot help out-of-memory errors unless you use the additional hosts to decrease the number of segments per host.

Spill files are created when there is not enough memory to fit all the mapper output, usually when 80% of the buffer space is occupied.

Also, see [Resource Management](https://gpdb.docs.pivotal.io/6-3/best_practices/workloads.html#topic_hhc_z5w_r4) for best practices for managing query memory using resource queues.

## Resource Queue Spill File Configuration

Greenplum Database creates *spill files* (also called *workfiles*) on disk if a query is allocated insufficient memory to execute in memory. A single query can create no more than 100,000 spill files, by default, which is sufficient for the majority of queries.

You can control the maximum number of spill files created per query and per segment with the configuration parameter gp_workfile_limit_files_per_query. Set the parameter to 0 to allow queries to create an unlimited number of spill files. Limiting the number of spill files permitted prevents run-away queries from disrupting the system.

A query could generate a large number of spill files if not enough memory is allocated to it or if data skew is present in the queried data. If a query creates more than the specified number of spill files, Greenplum Database returns this error:

ERROR: number of workfiles per query limit exceeded

Before raising the gp_workfile_limit_files_per_query, try reducing the number of spill files by changing the query, changing the data distribution, or changing the memory configuration.

The gp_toolkit schema includes views that allow you to see information about all the queries that are currently using spill files. This information can be used for troubleshooting and for tuning queries:

- The gp_workfile_entries view contains one row for each operator using disk space for workfiles on a segment at the current time. See [How to Read Explain Plans](https://gpdb.docs.pivotal.io/6-3/best_practices/tuning_queries.html#reading_explain_plan)for information about operators.
- The gp_workfile_usage_per_query view contains one row for each query using disk space for workfiles on a segment at the current time.
- The gp_workfile_usage_per_segment view contains one row for each segment. Each row displays the total amount of disk space used for workfiles on the segment at the current time.

See the *Greenplum Database Reference Guide* for descriptions of the columns in these views.

The gp_workfile_compression configuration parameter specifies whether the spill files are compressed. It is off by default. Enabling compression can improve performance when spill files are used.

**Parent topic:** [Greenplum Database Best Practices](https://gpdb.docs.pivotal.io/6-3/best_practices/intro.html)







https://blog.csdn.net/Explorren/article/details/103636287

https://blog.51cto.com/michaelkang/2170608

https://www.cnblogs.com/zsql/p/14602612.html





# 监控



https://cloud.tencent.com/developer/article/1822708



# 三罐可乐带你读懂Greenplum的interconnect



# explain

# EXPLAIN

显示语句的查询计划。

## 概要

```
EXPLAIN [ ( option [, ...] ) ] statement
EXPLAIN [ANALYZE] [VERBOSE] statement
```

其中option可以是以下之一：

```
    ANALYZE [ boolean ]
    VERBOSE [ boolean ]
    COSTS [ boolean ]
    BUFFERS [ boolean ]
    TIMING [ boolean ]
    FORMAT { TEXT | XML | JSON | YAML }
```

## 描述

EXPLAIN显示Greenplum或Postgres优化器为提供的语句生成的查询计划。 查询计划是节点的查询树计划。 计划中的每个节点代表一个单独的操作，例如表扫描，连接，聚合或排序。

应从下至上阅读计划，因为每个节点都会向其上方的节点中发送行。 计划的最底层节点通常是表扫描操作（顺序扫描，索引扫描或位图索引扫描）。 如果查询需要连接，聚集或排序（或原始行上的其他操作），则扫描节点上方将有其他节点来执行这些操作。 最顶层的计划节点通常是Greenplum数据库motion节点（重新分发，显式重新分发，广播或收集motion）。 这些操作负责在查询处理期间在segment实例之间移动行。

EXPLAIN的输出对于计划树中的每个节点都有一行， 显示基本节点类型以及计划者为执行该计划节点而进行的以下成本估算：

- **cost** — 优化器对运行该语句要花费多长时间的猜测（以任意成本单位衡量，但通常是指磁盘页获取）。 显示了两个成本编号：可以返回第一行之前的启动成本，以及返回所有行的总成本。 请注意，总成本假定将检索所有行，但并非总是如此（例如，如果使用LIMIT）。
- **rows** — 此计划节点输出的总行数。 这通常少于计划节点处理或扫描的实际行数，反映了任何WHERE子句条件的估计选择性。 理想情况下，顶级节点估计将近似查询实际返回，更新或删除的行数。
- **width** — 此计划节点输出的所有行的总字节数。

重要的是要注意，上级节点的成本包括其所有子节点的成本。 计划的最高节点具有该计划的估计总执行成本。 这是计划者要尽量减少的数字。 同样重要的是要意识到，成本只反映查询优化器关心的事情。 特别是，成本不考虑将结果行传输到客户端所花费的时间。

EXPLAIN ANALYZE导致语句实际执行，而不仅仅是做计划。 EXPLAIN ANALYZE优化器会显示实际结果以及计划者的估计。 这对于查看优化器的估计是否接近实际很有用。 除了EXPLAIN计划中显示的信息之外，EXPLAIN ANALYZE还将显示以下附加信息：

- 运行查询所花费的总时间（以毫秒为单位）。

- 计划节点操作中涉及的*workers*（segment）数。仅计算返回行的segment。

- 操作产生最多行的segment所返回的最大行数。 如果多个segment产生相等数量的行，则结束时间最长的一个就是选择的那个。

- 为一个操作生成最多行的segment的segment ID号。

- 对于相关操作，该操作使用的

  work_mem

  。 如果

  work_mem

  不足以在内存中执行该操作，则该计划将显示有多少数据溢出到磁盘， 以及最低性能segment需要多少次数据传递。 例如：

  ```
  Work_mem used: 64K bytes avg, 64K bytes max (seg0).
  Work_mem wanted: 90K bytes avg, 90K bytes max (seg0) to abate workfile 
  I/O affecting 2 workers.
  [seg0] pass 0: 488 groups made from 488 rows; 263 rows written to 
  workfile
  [seg0] pass 1: 263 groups made from 263 rows
  ```

- 从产生最多行的segment中检索第一行所花费的时间（以毫秒为单位），以及从该segment中检索所有行所花费的总时间。 如果*<time> to first row*与*<time> to end*相同，则可以省略。

Important: 请记住，使用ANALYZE时实际上会执行该语句。 尽管EXPLAIN ANALYZE将丢弃SELECT将返回的任何输出，但是该语句的其他副作用将照常发生。 如果希望在DML语句上使用EXPLAIN ANALYZE而不让命令影响您的数据，请使用以下方法：

```
BEGIN;
EXPLAIN ANALYZE ...;
ROLLBACK;
```

仅可以指定ANALYZE和VERBOSE选项，并且只能按该顺序指定，而不要在括号中包含选项列表。

## 参数

- ANALYZE

  执行命令并显示实际运行时间和其他统计信息。 如果省略此参数，则默认为FALSE。 指定ANALYZE true可以启用它。

- VERBOSE

  显示有关计划的其他信息。 具体来说，包括计划树中每个节点的输出列列表，模式限定表和函数名称， 始终在表达式中使用范围表别名标记变量，并始终打印要显示其统计信息的每个触发器的名称。 如果省略此参数，则默认为FALSE； 指定VERBOSE true启用它。

- COSTS

  包括有关每个计划节点的估计启动成本和总成本以及估计的行数和估计的每行宽度的信息。 如果省略此参数，则默认为TRUE； 指定COSTS false禁用它。

- BUFFERS

  包括有关缓冲区使用情况的信息。 具体来说，包括命中，读取，弄脏和写入的共享块的数量，命中，读取，弄脏和写入的局部块的数量以及读写的临时块的数量。 命中表示避免读取，因为在需要时已在高速缓存中找到该块。 共享块包含来自常规表和索引的数据；本地块包含来自临时表和索引的数据； 临时块包含用于排序，哈希，物化计划节点和类似情况的短期工作数据。 被弄脏的块数表示此查询已更改的先前未修改的块数； 而写入的块数则表示此后端在查询处理期间从缓存中逐出的先前处理的块数。 上级节点显示的块数包括其所有子节点使用的块数。 在文本格式中，仅打印非零值。 仅当还启用了ANALYZE时，才可以使用此参数。 如果省略此参数，则默认为FALSE； 指定BUFFERS true启用它。

- TIMING

  在输出中包括实际的启动时间和在每个节点上花费的时间。 重复读取系统时钟的开销可能会在某些系统上显着降低查询速度， 因此，当仅需要实际的行计数而不是确切的时间时，将此参数设置为FALSE可能会很有用。 即使使用此选项关闭了节点级计时，也始终会测量整个语句的运行时间。 仅当还启用了ANALYZE时，才可以使用此参数。 默认为TRUE。

- FORMAT

  指定输出格式，可以是TEXT，XML，JSON或YAML。 非文本输出包含与文本输出格式相同的信息，但程序更易于解析。 此参数默认为TEXT。

- boolean

  指定是打开还是关闭所选选项。 您可以写入TRUE，ON或1以启用该选项， 而可以写入FALSE，OFF或0以禁用该选项。 布尔值也可以省略，在这种情况下，假定为TRUE。

- statement

  您希望查看其执行计划的任何SELECT，INSERT，UPDATE， DELETE，VALUES，EXECUTE， DECLARE或CREATE TABLE AS语句。

## 注解

为了使查询优化器在优化查询时能够做出合理的决策，应运行ANALYZE语句以记录有关表内数据分布的统计信息。 如果您尚未执行此操作（或者自上次运行ANALYZE以来，表中数据的统计分布已发生重大变化）， 则估计成本不太可能符合查询的实际属性，因此可能会选一个较差的查询计划。

在执行EXPLAIN ANALYZE命令期间运行的SQL语句从Greenplum数据库资源队列中排除。

有关查询分析的更多信息，请参阅Greenplum数据库管理员指南中的“查询分析”。 有关资源队列的更多信息，请参阅Greenplum数据库管理员指南中的“使用资源队列进行资源管理”。

## 示例

为了说明如何读取EXPLAIN查询计划，请考虑一个非常简单的查询的示例：

```
EXPLAIN SELECT * FROM names WHERE name = 'Joelle';
                                  QUERY PLAN
-------------------------------------------------------------------------------
 Gather Motion 3:1  (slice1; segments: 3)  (cost=0.00..431.27 rows=1 width=58)
   ->  Seq Scan on names  (cost=0.00..431.27 rows=1 width=58)
         Filter: (name = 'Joelle'::text)
 Optimizer: Pivotal Optimizer (GPORCA) version 3.23.0
(4 rows)
```

如果我们自下而上阅读计划，则查询优化器将从对names表的顺序扫描开始。 请注意，WHERE子句被用作过滤条件。 这意味着扫描操作将检查其扫描的每一行的条件，并仅输出通过条件的行。

扫描操作的结果将传递到*gather motion*操作。 在Greenplum数据库中，*gather motion*是将segment行发送到master。 在这种情况下，我们有3个segment实例发送到1个master实例（3：1）。 该操作在并行查询执行计划的slice1上进行。 在Greenplum数据库中，查询计划分为多个切片，以便查询计划的各个部分可以由这些segment并行处理。

该计划的估计启动成本为00.00（无成本），总成本为431.27。 优化器估计此查询将返回一行。

这是相同的查询，但成本估算被抑制：

```
EXPLAIN (COSTS FALSE) SELECT * FROM names WHERE name = 'Joelle';
                QUERY PLAN
------------------------------------------
 Gather Motion 3:1  (slice1; segments: 3)
   ->  Seq Scan on names
         Filter: (name = 'Joelle'::text)
 Optimizer: Pivotal Optimizer (GPORCA) version 3.23.0
(4 rows)
```

这是使用JSON格式的相同查询：

```
EXPLAIN (FORMAT JSON) SELECT * FROM names WHERE name = 'Joelle';
                  QUERY PLAN
-----------------------------------------------
 [                                            +
   {                                          +
     "Plan": {                                +
       "Node Type": "Gather Motion",          +
       "Senders": 3,                          +
       "Receivers": 1,                        +
       "Slice": 1,                            +
       "Segments": 3,                         +
       "Gang Type": "primary reader",         +
       "Startup Cost": 0.00,                  +
       "Total Cost": 431.27,                  +
       "Plan Rows": 1,                        +
       "Plan Width": 58,                      +
       "Plans": [                             +
         {                                    +
           "Node Type": "Seq Scan",           +
           "Parent Relationship": "Outer",    +
           "Slice": 1,                        +
           "Segments": 3,                     +
           "Gang Type": "primary reader",     +
           "Relation Name": "names",          +
           "Alias": "names",                  +
           "Startup Cost": 0.00,              +
           "Total Cost": 431.27,              +
           "Plan Rows": 1,                    +
           "Plan Width": 58,                  +
           "Filter": "(name = 'Joelle'::text)"+
         }                                    +
       ]                                      +
     },                                       +
     "Settings": {                            +
       "Optimizer": "Pivotal Optimizer (GPORCA) version 3.23.0"      +
     }                                        +
   }                                          +
 ]
(1 row)
```

如果存在索引，并且我们使用带有可索引WHERE条件的查询，则EXPLAIN可能会显示不同的计划。 此查询使用YAML格式生成带有索引扫描的计划：

```
EXPLAIN (FORMAT YAML) SELECT * FROM NAMES WHERE LOCATION='Sydney, Australia';
                          QUERY PLAN
--------------------------------------------------------------
 - Plan:                                                     +
     Node Type: "Gather Motion"                              +
     Senders: 3                                              +
     Receivers: 1                                            +
     Slice: 1                                                +
     Segments: 3                                             +
     Gang Type: "primary reader"                             +
     Startup Cost: 0.00                                      +
     Total Cost: 10.81                                       +
     Plan Rows: 10000                                        +
     Plan Width: 70                                          +
     Plans:                                                  +
       - Node Type: "Index Scan"                             +
         Parent Relationship: "Outer"                        +
         Slice: 1                                            +
         Segments: 3                                         +
         Gang Type: "primary reader"                         +
         Scan Direction: "Forward"                           +
         Index Name: "names_idx_loc"                         +
         Relation Name: "names"                              +
         Alias: "names"                                      +
         Startup Cost: 0.00                                  +
         Total Cost: 7.77                                    +
         Plan Rows: 10000                                    +
         Plan Width: 70                                      +
         Index Cond: "(location = 'Sydney, Australia'::text)"+
   Settings:                                                 +
     Optimizer: "Pivotal Optimizer (GPORCA) version 3.23.0"
(1 row)
```

## 兼容性

在SQL标准中没有定义EXPLAIN语句。

## 另见

[ANALYZE](http://docs-cn.greenplum.org/v6/ref_guide/sql_commands/ANALYZE.html#topic1)

# Join on



默认为 inner join on







# 第二篇 日常运维最佳实践











第一篇介绍了GP实施前重点应该关注前期规划及模型设计，**其实实施完运维更重要，切忌运而不维**（只让其运行而不加以维护）！



想要一个数据库长久健康的运行，离不开一个称职的DBA。



从其他数据库的DBA转为Greenplum的DBA并不是一件很困难的事，成功转成Greenplum DBA的工程师越来越多。





**1**



日常维护关注这些







现在企业客户中搭建的Greenplum集群服务器数量是越来越大，在电信行业和银行业，搭建50台服务器以上的Greenplum集群越来越多。而集群服务器数量越多也就代表故障发生率越高。作为Greenplum的DBA和运维人员，不单只关注Greenplum本身，还要关注集群中各硬件的状况，及时发现及时处理。硬盘状态、阵列卡状态、硬件告警、操作系统告警、空间使用率等都是应关注的重点。这些都可通过厂商提供的工具，编写监控程序，SNMP协议对接企业监控平台等手段提升日常巡检和监控的效率。

**
**

**针对Greenplum，DBA需要关注的重点：**



（1）**Greenplum的状态**：Standby master的同步状态往往容易被忽略。通过监控平台或者脚本程序，能够及时告警则最好。



（2）**系统表**：日常系统表维护（vacuum analyze），在系统投产时就应该配置好每天执行维护。



（3）**统计信息收集**：统计信息的准确性影响到运行效率，用户表应该及时收集统计信息。在应用程序中增加收集统计信息的处理逻辑，通过脚本定时批量收集统计信息，或者两者相结合。针对分区表日常可按需收集子分区的统计信息，可节省时间提升效率。



（4）**表倾斜**：表倾斜情况应该DBA的关注点之一，但无需每天处理。



（5）**表膨胀**：基于postgresql的MVCC机制，表膨胀情况不能忽视。重点应该关注日常更新和删除操作的表。



（6）**报错信息**：在日志中错误信息多种多样，大部分不是DBA需要关注的。应该重点关注PANIC、OOM、Internal error等关键信息。





**2**



重点说说系统表的维护







Greenplum与其他所有关系型数据库一样，拥有一套管理数据库内部对象及关联关系的元数据表，我们称之为Greenplum系统表。Greenplum的产品内核是基于postgresql数据库基础上开发完成的，因此，Greenplum系统表很多继承于postgresql数据库。



**Greenplum的系统表大致可分为这几类：**



**（1）数据库内部对象的元数据**，如：pg_database、pg_namespace、pg_class、pg_attribute、pg_type、pg_exttable等。



这类系统表既涵盖了全局的对象定义，也涵盖了每个数据库内的各种对象定义。这类系统表的元数据不是分布式的存储，而是每一个数据库实例（不论是master实例还是segment实例）中都各有一份完整的元数据。但也有例外，如：gp_distribution_policy（分布键定义）表则只在master上才有元数据。



对于这类系统表，各个实例之间元数据保持一致十分重要。



**（2）维护Greenplum集群状态的元数据**，如：gp_segment_configuration、gp_configuration_history、pg_stat_replication等。



这类系统表主要由master实例负责维护，就如segment实例状态管理的两张表gp_segment_configuration和gp_configuration_history的数据是由master的专用进程fts负责维护的。



**（3）Persistent table**，如：gp_persistent_database_node、gp_persistent_filespace_node、gp_persistent_relation_node、gp_persistent_tablespace_node。



这类系统表同样是存在于每一个数据库实例中。在每个实例内，persistenttable与pg_class/pg_relation_node/pg_database等系统表有着严格的主外键关系。**这类系统表也是primary实例与mirror实例之间实现同步的重要参考数据。**



在Greenplum集群出现故障时，会有可能导致系统表数据有问题。系统表出现问题会导致很多种故障产生，如：某些数据库对象不可用，实例恢复不成功，实例启动不成功等。针对系统表相关的问题，我们应该结合各个实例的日志信息，系统表的检查结果一起定位问题，本文将介绍一些定位、分析及解决问题的方法和技巧。





**3**



检查工具







Greenplum提供了一个系统表检查工具gpcheckcat。该工具在$GPHOME/bin/lib目录下。该工具必须要在Greenplum数据库空闲的时候检查才最准确。若在大量任务运行时，检查结果将会受到干扰，不利于定位问题。因此，在使用gpcheckcat前建议使用限制模式启动数据库，确保没有其他应用任务干扰。





**4**



分析方法和处理技巧







**1、遇到临时schema的问题**，命名为pg_temp_XXXXX，可以直接删除。通过gpcheckcat检查后，会自动生成对临时schema的修复脚本。由于临时schema的问题会干扰检查结果，因此，处理完后，需要再次用gpcheckcat检查。



**2、如遇个别表对象元数据不一致的情况**，通常只会影响该对象的使用，不会影响到整个集群。如果只是个别实例中存在问题，可以通过Utility模式连接到问题实例中处理。处理原则是尽量不要直接更改系统表的数据，而是采用数据库的手段去解决，如：drop table/alter table等。



**3、persistent table问题**，这类问题往往比较棘手，影响也比较大。依据gpcheckcat的检查结果，**必须把persistent table以外的所有问题修复完之后，才可以着手处理persistent table的问题。**

**
**

**针对persistent table再展开讲述几种问题的处理技巧：**



**（1）报错的Segment实例日志中出现类似信息**

**
**

![图片](.img_greenplum/640-20230105164318214.png)



该错误可能会导致实例启动失败，数据库实例恢复失败等情况。**首先可在问题的实例（postgresql.conf）中设置参数gp_persistent_skip_free_list=true。**让出问题的实例先启动起来。再进行gpcheckcat检查。在gpcheckcat的结果中应该能找到类似的问题：



![图片](.img_greenplum/640-20230105164318277.png)



从上述检查结果可以看出persistent table的部分数据和其他系统表对应关系不正确。处理方法就是要修复persistent table数据。



![图片](.img_greenplum/640.png)



**（2）报错的实例日志中出现类似信息**



该问题可能会导致实例启动失败。可在问题的实例（postgresql.conf）中设置参数gp_persistent_repair_global_sequence=true，便可修复相应问题，让相应实例正常启动。



![图片](.img_greenplum/640-20230105164318180.png)



**（3）报错的实例日志中出现类似信息**



该问题会出现在AO表中，表示个别实例上的数据文件被损坏。问题可能会导致进程PANIC，实例启动失败。首先可在问题的实例（postgresql.conf）中设置参数gp_crash_recovery_suppress_ao_eof=true。让出问题的实例先启动起来。再进行gpcheckcat检查。确定问题所在并修复。**而通常出问题的AO表已经损坏，建议rename或者删除。**

**
**

![图片](.img_greenplum/640-20230105164318203.png)



**（4）在gpcheckcat的检查结果中如果出现如下信息**



检查结果表明文件系统中存在部分数据文件在系统表中没有对应的关系，也就是文件系统中有多余的数据文件。这种情况不会影响Greenplum集群的正常运作，可以暂时忽略不处理。



修复persistent table表的问题，不可手工修改，只能够使用Greenplum提供的修复工具gppersistentrebuild进行修复。工具提供了备份功能，**在操作修复之前必须要执行备份操作**。然后通过gppersistentrebuild，指定待修复的实例的contentid进行修复。



另外，如果primary实例与mirror实例之间是处于changetracking状态。一旦primary实例进行了persistent table的修复操作，primary实例与mirror实例之间**只能执行全量恢复操作（gprecoverseg -F）。**

**
**

上面所介绍的一些GUC参数，都是在修复系统表过程中临时增加的参数，待集群恢复正常之后，请将所修改过的GUC参数值恢复回原有默认状态。



Greenplum已经开源了，生态圈在迅速地壮大，Greenplum的爱好者、拥护者人数也在不断地壮大。在使用和探索Greenplum的路途中，我们通过一点经验介绍，希望让大家少走弯路。在产品实施过程中的关键阶段，还应该更多地寻求专业顾问的支持。



文章来源Pivotal订阅号，经作者同意由DBA+社群进行合并整理。



# [如何避免OOM？看Greenplum的最佳实践](https://mp.weixin.qq.com/s/UC-7gorTP-FbMzts1ea-cg)



# best practices

http://greenplum.org/docs/best_practices/workloads.html

# greenplum常用的gp_toolkit & pg_catalog监控语句

**目录**

[gp_toolkit 说明](https://blog.csdn.net/MyySophia/article/details/103226128#t0)

[1、表膨胀相关查询](https://blog.csdn.net/MyySophia/article/details/103226128#t1)

[2、表倾斜的相关信息](https://blog.csdn.net/MyySophia/article/details/103226128#t2)

[3、锁查询相关的信息](https://blog.csdn.net/MyySophia/article/details/103226128#t3)

[4、日志查询相关的信息](https://blog.csdn.net/MyySophia/article/details/103226128#t4)

[5、资源队列相关查询信息](https://blog.csdn.net/MyySophia/article/details/103226128#t5)

[6、查看磁盘上(database,schema,table,indexs,view)等的占用大小的相关信息](https://blog.csdn.net/MyySophia/article/details/103226128#t6)

[7、用户使用的工作空间大小信息](https://blog.csdn.net/MyySophia/article/details/103226128#t7)

[8、查看用户创建的信息(数据库,schema,表,索引,函数,视图)等信息](https://blog.csdn.net/MyySophia/article/details/103226128#t8)

[9、系统中维护的ID信息](https://blog.csdn.net/MyySophia/article/details/103226128#t9)

[10、系统查用的查询信息](https://blog.csdn.net/MyySophia/article/details/103226128#t10)

[11、系统中常用查询的函数](https://blog.csdn.net/MyySophia/article/details/103226128#t11)

[1、Greenplum 基本查询信息](https://blog.csdn.net/MyySophia/article/details/103226128#t12)

[1.1、Greenplum 常用查询](https://blog.csdn.net/MyySophia/article/details/103226128#t13)

[1.2、Greenplum 触发器,锁,类型等相关信息](https://blog.csdn.net/MyySophia/article/details/103226128#t14)

[1.3、Greenplum 故障检测相关的信息](https://blog.csdn.net/MyySophia/article/details/103226128#t15)

[1.4、Greenplum 分布式事务有关信息](https://blog.csdn.net/MyySophia/article/details/103226128#t16)

[1.5、Greenplum segment 有关信息](https://blog.csdn.net/MyySophia/article/details/103226128#t17)

[1.6、Greenplum 数据文件状态有关信息](https://blog.csdn.net/MyySophia/article/details/103226128#t18)

[1.7、Greenplum 有关储存的信息](https://blog.csdn.net/MyySophia/article/details/103226128#t19)

[2、Greenplum 插件相关信息](https://blog.csdn.net/MyySophia/article/details/103226128#t20)

[3、Greenplum 分区表的相关信息](https://blog.csdn.net/MyySophia/article/details/103226128#t21)

[4、Greenplum 资源队列相关信息](https://blog.csdn.net/MyySophia/article/details/103226128#t22)

[5、Greenplum 表,视图,索引等有关信息](https://blog.csdn.net/MyySophia/article/details/103226128#t23)

[5.1、Greenplum 中支持的索引](https://blog.csdn.net/MyySophia/article/details/103226128#t24)

[5.2、Greenplum 表的关系信息](https://blog.csdn.net/MyySophia/article/details/103226128#t25)

[6、Greenplum 系统目录存储基本信息](https://blog.csdn.net/MyySophia/article/details/103226128#t26)

[6.1、Greenplum 储存database,schema,table,view等的信息](https://blog.csdn.net/MyySophia/article/details/103226128#t27)

[7、以下只有在进入到gpexpand扩展时,才可以查询](https://blog.csdn.net/MyySophia/article/details/103226128#t28)

------

# gp_toolkit 说明

```
Greenplum数据库提供了一个名为gp_tooikit的管理schema,该schema下有关于查询系统目录,日志文件,
用户创建(databases,schema,table,indexs,view,function)等信息,也可以查询资源队列,表的膨胀表,表的倾斜,
系统自己维护的ID等的相关信息。注意不要在该schema下创建任何对象,否则会影响系统对元数据维护的错误问题,
同时再使用gpcrondump和gpdbrestore程序进行备份和恢复数据时,之前维护的元数据会发生更改。
```

## 1、表膨胀相关查询

```
-- 该视图显示了那些膨胀的（在磁盘上实际的页数超过了根据表统计信息得到预期的页数）正规的堆存储的表。
select * from gp_toolkit.gp_bloat_diag;

-- 所有对象的膨胀明细
select * from gp_toolkit.gp_bloat_expected_pages;
```

## 2、表倾斜的相关信息

```
-- 该视图通过计算存储在每个Segment上的数据的变异系数（CV）来显示数据分布倾斜。
select * from gp_toolkit.gp_skew_coefficients;

-- 该视图通过计算在表扫描过程中系统空闲的百分比来显示数据分布倾斜，这是一种数据处理倾斜的指示器。
select * from gp_toolkit.gp_skew_idle_fractions;
```

## 3、锁查询相关的信息

```
-- 该视图显示了当前所有表上持有锁，以及查询关联的锁的相关联的会话信息。
select * from gp_toolkit.gp_locks_on_relation;

-- 该视图显示当前被一个资源队列持有的所有的锁，以及查询关联的锁的相关联的会话信息。
select * from gp_toolkit.gp_locks_on_resqueue;
```

## 4、日志查询相关的信息

```
-- 该视图使用一个外部表来读取来自整个Greenplum（Master、Segment、镜像）的服务器日志文件并且列出所有的日志项。
select * from gp_toolkit.gp_log_system;

-- 该视图用一个外部表来读取在主机上的日志文件同时报告在数据库会话中SQL命令的执行时间
select * from gp_toolkit.gp_log_command_timings;

-- 该视图使用一个外部表来读取整个Greenplum系统（主机，段，镜像）的服务器日志文件和列出与当前数据库关联的日志的入口。
select * from gp_toolkit.gp_log_database;

-- 该视图使用一个外部表读取来自Master日志文件中日志域的一个子集。
select * from gp_toolkit.gp_log_master_concise;
```

## 5、资源队列相关查询信息

```
-- gp_toolkit.gp_resgroup_config视图允许管理员查看资源组的当前CPU、内存和并发限制
select * from gp_toolkit.gp_resgroup_config;

-- gp_toolkit.gp_resgroup_status视图允许管理员查看资源组的状态和活动
select * from gp_toolkit.gp_resgroup_status;

-- 该视图允许管理员查看到一个负载管理资源队列的状态和活动。
select * from gp_toolkit.gp_resqueue_status;

-- 对于那些有活动负载的资源队列，该视图为每一个通过资源队列提交的活动语句显示一行。
select * from gp_toolkit.gp_resq_activity;

-- 对于有活动负载的资源队列，该视图显示了队列活动的总览。
select * from gp_toolkit.gp_resq_activity_by_queue;

-- 资源队列的执行优先级
select * from gp_toolkit.gp_resq_priority_backend;

-- 该视图为当前运行在Greenplum数据库系统上的所有语句显示资源队列优先级、会话ID以及其他信息
select * from gp_toolkit.gp_resq_priority_statement;

-- 该视图显示与角色相关的资源队列。
select * from gp_toolkit.gp_resq_role;
```

## 6、查看磁盘上(database,[schema](https://so.csdn.net/so/search?q=schema&spm=1001.2101.3001.7020),table,indexs,view)等的占用大小的相关信息

```
-- 外部表在活动Segment主机上运行df（磁盘空闲）并且报告返回的结果
select * from gp_toolkit.gp_disk_free;

-- 该视图显示数据库的总大小。
select * from gp_toolkit.gp_size_of_database;

-- 该视图显示当前数据库中schema在数据中的大小
select * from gp_toolkit.gp_size_of_schema_disk;

-- 该视图显示一个表在磁盘上的大小。
select * from gp_toolkit.gp_size_of_table_disk;

-- 该视图查看表的索引
select * from gp_toolkit.gp_table_indexes;

-- 该视图显示了一个表上所有索引的总大小。
select * from gp_toolkit.gp_size_of_all_table_indexes;

-- 该视图显示分区子表及其索引在磁盘上的大小。
select * from gp_toolkit.gp_size_of_partition_and_indexes_disk;

-- 该视图显示表及其索引在磁盘上的大小。
select * from gp_toolkit.gp_size_of_table_and_indexes_disk;

-- 该视图显示表及其索引的总大小
select * from gp_toolkit.gp_size_of_table_and_indexes_licensing;

-- 该视图显示追加优化（AO）表没有压缩时的大小。
select * from gp_toolkit.gp_size_of_table_uncompressed;
```

## 7、用户使用的工作空间大小信息

```
-- 该视图为当前在Segment上使用磁盘空间作为工作文件的操作符包含一行。
select * from gp_toolkit.gp_workfile_entries;

-- GP工作文件管理器使用的磁盘空间
select * from gp_toolkit.gp_workfile_mgr_used_diskspace;

-- 每个查询的GP工作文件使用情况
select * from gp_toolkit.gp_workfile_usage_per_query;

-- 每个segment在GP工作文件中的使用量
select * from gp_toolkit.gp_workfile_usage_per_segment;
```

## 8、查看用户创建的信息(数据库,schema,表,索引,函数,视图)等信息

```
-- gp 中所有的名字(索引、表、视图、函数)等的名字
select * from gp_toolkit."__gp_fullname";

-- gp 中AO表的名字
select * from gp_toolkit."__gp_is_append_only";

-- gp 中segment的个数
select * from gp_toolkit."__gp_number_of_segments";

-- gp 中用户表的个数
select * from gp_toolkit."__gp_user_data_tables";

-- GP用户数据表可读
select * from gp_toolkit."__gp_user_data_tables_readable";

-- 用户自己创建的schema信息
select * from gp_toolkit."__gp_user_namespaces";

-- 用户自己创建的表信息
select * from gp_toolkit."__gp_user_tables";
```

## 9、系统中维护的ID信息

```
-- gp  本地维护的ID
select * from gp_toolkit."__gp_localid";

-- gp master外部的log信息
select * from gp_toolkit."__gp_log_master_ext";

-- gp segment外部的log信息
select * from gp_toolkit."__gp_log_segment_ext";

-- gp master 的id信息
select * from gp_toolkit."__gp_masterid";
```

## 10、系统查用的查询信息

```
-- 该视图显示那些没有统计信息的表，因此可能需要在表上执行ANALYZE命令。
select * from gp_toolkit.gp_stats_missing;

-- 该视图显示系统目录中被标记为down的Segment的信息。
select * from gp_toolkit.gp_pgdatabase_invalid;

-- 那些被分类为本地（local）（表示每个Segment从其自己的postgresql.conf文件中获取参数值）的服务器配置参数，应该在所有Segment上做相同的设置。
select * from gp_toolkit.gp_param_settings_seg_value_diffs;

-- 该视图显示系统中所有的角色以及指派给它们的成员（如果该角色同时也是一个组角色）。
select * from gp_toolkit.gp_roles_assigned;
```

## 11、系统中常用查询的函数

```
select * from gp_toolkit.gp_param_settings();
select * from gp_toolkit.gp_skew_details(oid);
select * from gp_toolkit."__gp_aocsseg"(IN  oid);
select * from gp_toolkit."__gp_aovisimap"(IN  oid);
select * from gp_toolkit.gp_param_setting(varchar);
select * from gp_toolkit."__gp_skew_coefficients"();
select * from gp_toolkit."__gp_workfile_entries_f"();
select * from gp_toolkit."__gp_skew_idle_fractions"();
select * from gp_toolkit."__gp_aocsseg_name"(IN  text);
select * from gp_toolkit."__gp_aovisimap_name"(IN  text);
select * from gp_toolkit."__gp_aocsseg_history"(IN  oid);
select * from gp_toolkit."__gp_aovisimap_entry"(IN  oid);
select * from gp_toolkit."__gp_aovisimap_hidden_typed"(oid);
select * from gp_toolkit."__gp_param_local_setting"(varchar);
select * from gp_toolkit."__gp_aovisimap_entry_name"(IN  text);
select * from gp_toolkit."__gp_aovisimap_hidden_info"(IN  oid);
select * from gp_toolkit."__gp_workfile_mgr_used_diskspace_f"();
select * from gp_toolkit."__gp_aovisimap_hidden_info_name"(IN  text);
select * from gp_toolkit.gp_skew_coefficient(IN targetoid oid, OUT skcoid oid, OUT skccoeff numeric);
select * from gp_toolkit.gp_skew_idle_fraction(IN targetoid oid, OUT sifoid oid, OUT siffraction numeric);
select * from gp_toolkit.gp_bloat_diag(IN btdrelpages int4, IN btdexppages numeric, IN aotable bool, OUT bltidx int4, OUT bltdiag text);
select * from gp_toolkit."__gp_aovisimap_compaction_info"(IN ao_oid oid, OUT content int4, OUT datafile int4, OUT compaction_possible bool, OUT hidden_tupcount int8, OUT total_tupcount int8, OUT percent_hidden numeric);
```

 

 

# 1、Greenplum 基本查询信息

## 1.1、Greenplum 常用查询

```
--  pg_constraint 对存储对表的检查,主键,唯一和外键约束。
select * from pg_catalog.pg_constraint;

--  pg_compression 描述了可用的压缩方法
select * from pg_catalog.pg_compression;

-- pg_class 目录表和大多数具有列或其他类似于表的所有其他表（也称为关系）。
select * from pg_catalog.pg_class;

--  pg_conversion 系统目录表描述了可用的编码转换过程create转换。
select * from pg_catalog.pg_conversion;

--  pg_operator 存储有关运算符的信息,包括内置和由其定义的运算符CREATE OPERATOR
select * from pg_catalog.pg_operator;

--  pg_partition 用于跟踪分区表及其继承级别关系。
select * from pg_catalog.pg_partition;

--  pg_pltemplate 存储过程语言的模板信息。
select * from pg_catalog.pg_pltemplate;

--  pg_proc 有关函数（或过程）的信息，包括内置函数和由函数定义的函数CREATE FUNCTION。
select * from pg_catalog.pg_proc;

--  pg_roles 提供对数据库角色信息的访问
select * from pg_catalog.pg_roles;

--  pg_shdepend 记录数据库对象和共享对象（如角色）之间的依赖关系。
select * from pg_catalog.pg_shdepend;

--  pg_shdescription 存储共享数据库对象的可选描述（注释）。
select * from pg_catalog.pg_shdescription;

--  pg_stat_activity每个服务器进程显示一行，并显示有关用户会话和查询的详细信息。
select * from pg_catalog.pg_stat_activity;

-- pg_stat_last_operation 包含有关数据库对象（表，视图等）的元数据跟踪信息。
select * from pg_catalog.pg_stat_last_operation;

-- pg_stat_last_shoperation 包含有关全局对象（角色，表空间等）的元数据跟踪信息。
select * from pg_catalog.pg_stat_last_shoperation;

--  pg_auth_members 显示角色之间的成员关系。
select * from pg_catalog.pg_auth_members;
```

## 1.2、Greenplum 触发器,锁,类型等相关信息

```
--  pg_trigger 触发器查询信息。
select * from pg_catalog.pg_trigger;

--  pg_type 数据库中数据类型的信息。
select * from pg_catalog.pg_type;

--  pg_locks 数据库中打开的事务所持有的锁的信息的访问。
select * from pg_catalog.pg_locks;

--  pg_user_mappingcatalog表存储从本地用户到远程用户的映射。
select * from pg_catalog.pg_user_mapping;

--  pg_window 表存储有关窗口函数的信息。
select * from pg_catalog.pg_window;
```

## 1.3、Greenplum 故障检测相关的信息

```
--  gp_configuration_history 包含有关故障检测和恢复操作的系统更改的信息。
select * from pg_catalog.gp_configuration_history order by time desc;

--  gp_fault_strategy 指定故障动作。
select * from pg_catalog.gp_fault_strategy;
```

## 1.4、Greenplum 分布式事务有关信息

```
--  gp_distributed_log 包含有关分布式事务及其关联的本地事务的状态信息。
select * from pg_catalog.gp_distributed_log;

--  gp_distributed_xacts 包含有关Greenplum Database分布式事务的信息。
select * from pg_catalog.gp_distributed_xacts;
```

## 1.5、Greenplum segment 有关信息

```
--  gp_distribution_policy 包含有关Greenplum数据库表及其segment分发表数据的策略的信息。
select * from pg_catalog.gp_distribution_policy;

--  gp_fastsequence 包含有关追加优化和面向列的表的信息
select * from pg_catalog.gp_fastsequence;

--  gp_global_sequence 包含事务日志中的日志序列号位置,文件复制过程使用位置来确定要从主段复制到镜像段的文件块。
select * from pg_catalog.gp_global_sequence;
```

## 1.6、Greenplum 数据文件状态有关信息

```
--  gp_persistent_database_node 跟踪与数据库对象的事务状态相关的文件系统对象的信息。
select * from pg_catalog.gp_persistent_database_node;

--  gp_persistent_filespace_node 跟踪文件系统对象与文件空间对象的事务状态相关的信息。
select * from pg_catalog.gp_persistent_filespace_node;

--  gp_persistent_tablespace_node 跟踪与表空间对象的事务状态相关的文件系统对象的信息。
select * from pg_catalog.gp_persistent_tablespace_node;

--  gp_pgdatabase 显示有关Greenplum segment实例的状态信息，以及它们是作为镜像还是主要实例。
select * from pg_catalog.gp_pgdatabase;
```

## 1.7、Greenplum 有关储存的信息

```
--  gp_transaction_log 包含有关特定segment本地事务的状态信息。
select * from pg_catalog.gp_transaction_log;

--  gp_version_at_initdb 在Greenplum数据库系统的主节点和每个segment上。
select * from pg_catalog.gp_version_at_initdb;

--  pg_appendonly 包含有关存储选项和附加优化表的其他特征的信息。
select * from pg_catalog.pg_appendonly;

--  pg_attrdef 存储列默认值。
select * from pg_catalog.pg_attrdef;

--  pg_attribute表存储有关表列的信息。
select * from pg_catalog.pg_attribute;

--  pg_authid表包含有关数据库授权标识符（角色）的信息。
select * from pg_catalog.pg_authid;

--  pg_cast里表存储数据类型转换路径，包括内置路径和使用的路径 创建CAST。
select * from pg_catalog.pg_cast;

--  pg_enum表包含将枚举类型与其关联值和标签匹配的条目。
select * from pg_catalog.pg_enum;

--  pg_exttable 系统目录表用于跟踪由中创建的外部表和Web表 创建外部表 命令。
select * from pg_catalog.pg_exttable;

--  pg_filespace表包含有关在Greenplum数据库系统中创建的文件空间的信息。
select * from pg_catalog.pg_filespace;

-- pg_filespace_entry 空间需要文件系统位置来存储其数据库文件。
select * from pg_catalog.pg_filespace_entry;

--  pg_inherits 系统目录表记录有关表继承层次结构的信息。
select * from pg_catalog.pg_inherits;

--  pg_largeobject系统目录表包含构成"large objects"的数据。
select * from pg_catalog.pg_largeobject;

--  pg_listener 系统目录表支持LISTENNOTIFY 通知命令。
select * from pg_catalog.pg_listener;

--  pg_max_external_files 显示使用外部表时每个段主机允许的最大外部表文件数file协议。
select * from pg_catalog.pg_max_external_files;
```

# 2、Greenplum 插件相关信息

```
-- pg_extension 有关已安装扩展的信息
select * from pg_catalog.pg_extension;

-- pg_available_extension_versions 列出了可用于安装的特定扩展版本。
select * from pg_catalog.pg_available_extension_versions;

-- pg_available_extensions 列出了可用于安装的扩展。
select * from pg_catalog.pg_available_extensions;

--  pg_language系统目录表注册可以编写函数或存储过程的语言。
select * from pg_catalog.pg_language;
```

# 3、Greenplum 分区表的相关信息

```
--  pg_partition_columns 系统视图用于显示分区表的分区键列。
select * from pg_catalog.pg_partition_columns;

--  pg_partition_columns 系统视图用于显示分区表的分区键列。
select * from pg_catalog.pg_partition_encoding;

--  pg_partition_rule系统目录表用于跟踪分区表，检查约束和数据包含规则。
select * from pg_catalog.pg_partition_rule;

--  pg_partition_templates 系统视图用于显示使用子分区模板创建的子分区。
select * from pg_catalog.pg_partition_templates;

--  pg_partitions 系统视图用于显示分区表的结构。
select * from pg_catalog.pg_partitions;
```

# 4、Greenplum 资源队列相关信息

```
--  pg_stat_partition_operations 视图显示有关在分区表上执行的上一个操作的详细信息
select * from pg_catalog.pg_stat_partition_operations;

--  pg_stat_replication 视图包含的元数据 walsender 用于Greenplum数据库主镜像的进程
select * from pg_catalog.pg_stat_replication;

--  pg_stat_resqueues 视图允许管理员随时查看有关资源队列工作负载的指标。
select * from pg_catalog.pg_stat_resqueues;

--  pg_resqueuecapability 包含有关现有Greenplum数据库资源队列的扩展属性或功能的信息
select * from pg_catalog.pg_resqueuecapability;

--  pg_resgroup 包含有关Greenplum数据库资源组的信息，这些资源组用于管理并发语句，CPU和内存资源。
select * from pg_catalog.pg_resgroup;

--  pg_resgroupcapability 包含有关已定义的Greenplum数据库资源组的功能和限制的信息
select * from pg_catalog.pg_resgroupcapability;

--  pg_resourcetype 包含有关可分配给Greenplum数据库资源队列的扩展属性的信息。
select * from pg_catalog.pg_resourcetype;

--  pg_resqueue 包含有关Greenplum数据库资源队列的信息，这些队列用于资源管理功能。
select * from pg_catalog.pg_resqueue;

--  pg_resqueue_attributes 视图允许管理员查看为资源队列设置的属性，例如其活动语句限制，查询成本限制和优先级。
select * from pg_catalog.pg_resqueue_attributes;
```

# 5、Greenplum 表,视图,索引等有关信息

## 5.1、Greenplum 中支持的索引

```
--  pg_am 有关索引方法的信息(btree,hash,gist,gin,bitmap索引)
select * from pg_catalog.pg_am;

--  pg_amop 有关与索引访问方法操作符类关联的运算符的信息
select * from pg_catalog.pg_amop;

--  pg_amproc 有关与索引访问方法操作符类关联的支持过程的信息。
select * from pg_catalog.pg_amproc;

--  pg_index 包含有关索引的部分信息。
select * from pg_catalog.pg_index;

--  pg_opclass记录系统目录表定义索引访问方法操作符类
select * from pg_catalog.pg_opclass;
```

## 5.2、Greenplum 表的关系信息

```
--  pg_tablespace系统目录表存储有关可用表空间的信息。
select * from pg_catalog.pg_tablespace;

-- gp_persistent_relation_node 表跟踪与关系对象(表,视图,索引等)的事务状态相关的文件系统对象的状态
select * from pg_catalog.gp_persistent_relation_node;

--  gp_relation_node 表包含有关系（表,视图,索引等）的文件系统对象的信息。
select * from pg_catalog.gp_relation_node;

--  pg_stat_operations 显示有关对数据库对象（例如表,索引,视图或数据库）或全局对象（例如角色）执行的上一个操作的详细信息。
select * from pg_catalog.pg_stat_operations;

--  gp_segment_configuration 表包含有关mirroring和segment配置的信息
select * from pg_catalog.gp_segment_configuration;

--  pg_aggregate里table存储有关聚合函数的信息。
select * from pg_catalog.pg_aggregate;
```

# 6、Greenplum 系统目录存储基本信息

## 6.1、Greenplum 储存database,schema,table,view等的信息

```
--  pg_database里系统目录表存储有关可用数据库的信息。
select * from pg_catalog.pg_database;

--  pg_statistic里系统目录表存储有关数据库内容的统计数据。
select * from pg_catalog.pg_statistic;

-- pg_description系统目录表存储每个数据库对象的可选描述（注释）。
select * from pg_catalog.pg_description;

--  pg_depend系统目录表记录数据库对象之间的依赖关系。
select * from pg_catalog.pg_depend;

--  pg_namespace系统目录表存储schema的名称。
select * from pg_catalog.pg_namespace;

--  gp_id系统目录表标识Greenplum数据库系统名称和系统的segment数
select * from pg_catalog.gp_id;

--  pg_rewrite 系统目录表存储表和视图的重写规则。
select * from pg_catalog.pg_rewrite;

--  pg_type_encoding 系统目录表包含列存储类型信息。
select * from pg_catalog.pg_type_encoding;

--  pg_attribute_encoding 系统目录表包含列存储信息。
select * from pg_catalog.pg_attribute_encoding;
```

# 7、以下只有在进入到gpexpand扩展时,才可以查询

```
select * from gpexpand.expansion_progress;
select * from gpexpand.status;
select * from gpexpand.status_detail;
```



# 压测记录

集群性能主要是针对集群的网络性能、磁盘I/O性能进行测试。

集群的网络性能测试：

```
gpcheckperf -f /data/opt/greenplum/all_hosts -r N -d /data/opt/greenplum/tmp
```

```sh
[gpadmin@dp01 ~]$ gpcheckperf -f /data/opt/greenplum/all_hosts -r N -d /data/opt/greenplum/tmp
/usr/local/greenplum-db-6.21.3/bin/gpcheckperf -f /data/opt/greenplum/all_hosts -r N -d /data/opt/greenplum/tmp

-------------------
--  NETPERF TEST
-------------------

====================
==  RESULT 2023-01-10T11:13:51.012689
====================
Netperf bisection bandwidth test
dp03 -> dp04 = 115.740000
dp05 -> dp03 = 75.540000
dp04 -> dp03 = 115.770000
dp03 -> dp05 = 115.770000

Summary:
sum = 422.82 MB/sec
min = 75.54 MB/sec
max = 115.77 MB/sec
avg = 105.70 MB/sec
median = 115.77 MB/sec

[Warning] connection between dp05 and dp03 is no good
```

另一块盘

```sh
[gpadmin@dp01 ~]$ gpcheckperf -f /data/opt/greenplum/all_hosts -r N -d /data1/opt/greenplum/tmp
/usr/local/greenplum-db-6.21.3/bin/gpcheckperf -f /data/opt/greenplum/all_hosts -r N -d /data1/opt/greenplum/tmp

-------------------
--  NETPERF TEST
-------------------

====================
==  RESULT 2023-01-10T11:16:31.069249
====================
Netperf bisection bandwidth test
dp03 -> dp04 = 115.720000
dp05 -> dp03 = 103.880000
dp04 -> dp03 = 48.580000
dp03 -> dp05 = 115.760000

Summary:
sum = 383.94 MB/sec
min = 48.58 MB/sec
max = 115.76 MB/sec
avg = 95.98 MB/sec
median = 115.72 MB/sec

[Warning] connection between dp05 and dp03 is no good
[Warning] connection between dp04 and dp03 is no good
```



磁盘I/O性能测试

```shell
[gpadmin@dp01 ~]$ gpcheckperf -f /data/opt/greenplum/all_hosts -r ds -D -v -d /data/opt/greenplum/tmp -d /data1/opt/greenplum/tmp 
[Info] sh -c 'cat /proc/meminfo | grep MemTotal'
MemTotal:       65804268 kB

/usr/local/greenplum-db-6.21.3/bin/gpcheckperf -f /data/opt/greenplum/all_hosts -r ds -D -v -d /data/opt/greenplum/tmp -d /data1/opt/greenplum/tmp
--------------------
  SETUP 2023-01-10T11:19:07.646581
--------------------
[Info] verify python interpreter exists
[Info] /usr/local/greenplum-db-6.21.3/bin/gpssh -f /data/opt/greenplum/all_hosts 'python -c print'
[Info] making gpcheckperf directory on all hosts ... 
[Info] /usr/local/greenplum-db-6.21.3/bin/gpssh -f /data/opt/greenplum/all_hosts 'rm -rf  /data/opt/greenplum/tmp/gpcheckperf_$USER /data1/opt/greenplum/tmp/gpcheckperf_$USER ; mkdir -p  /data/opt/greenplum/tmp/gpcheckperf_$USER /data1/opt/greenplum/tmp/gpcheckperf_$USER'
[Info] copy local /usr/local/greenplum-db-6.21.3/bin/lib/multidd to remote /data/opt/greenplum/tmp/gpcheckperf_$USER/multidd
[Info] /usr/local/greenplum-db-6.21.3/bin/gpscp -f /data/opt/greenplum/all_hosts /usr/local/greenplum-db-6.21.3/bin/lib/multidd =:/data/opt/greenplum/tmp/gpcheckperf_$USER/multidd
[Info] /usr/local/greenplum-db-6.21.3/bin/gpssh -f /data/opt/greenplum/all_hosts 'chmod a+rx /data/opt/greenplum/tmp/gpcheckperf_$USER/multidd'

--------------------
--  DISK WRITE TEST
--------------------
[Info] /usr/local/greenplum-db-6.21.3/bin/gpssh -f /data/opt/greenplum/all_hosts 'time -p /data/opt/greenplum/tmp/gpcheckperf_$USER/multidd -i /dev/zero -o /data/opt/greenplum/tmp/gpcheckperf_$USER/ddfile -i /dev/zero -o /data1/opt/greenplum/tmp/gpcheckperf_$USER/ddfile -B 32768'

```



写测试产生了126G数据, 16c配置load为4

```sh
[root@dp03 ~]# du -h --max-depth=1 /data/opt/greenplum/tmp/
126G    /data/opt/greenplum/tmp/gpcheckperf_gpadmin
[root@dp03 ~]# du -h --max-depth=1 /data1/opt/greenplum/tmp/
126G    /data1/opt/greenplum/tmp/gpcheckperf_gpadmin
```

读测试, load为2

```sh
[root@dp05 ~]# w
 11:27:15 up 24 days, 17:47,  2 users,  load average: 2.45, 2.66, 1.47
USER     TTY      FROM             LOGIN@   IDLE   JCPU   PCPU WHAT
root     pts/0    172.16.33.205    11:22    3.00s  0.03s  0.00s w
gpadmin  pts/1    dp01             11:25    2:07  38.05s 19.07s dd if=/data/opt/greenplum/tmp/gpcheckperf_gpadmin/ddfile of=/dev/null count=4112766 bs=32768
```



结束

```sh
[gpadmin@dp01 ~]$ gpcheckperf -f /data/opt/greenplum/all_hosts -r ds -D -v -d /data/opt/greenplum/tmp -d /data1/opt/greenplum/tmp 
[Info] sh -c 'cat /proc/meminfo | grep MemTotal'
MemTotal:       65804268 kB

/usr/local/greenplum-db-6.21.3/bin/gpcheckperf -f /data/opt/greenplum/all_hosts -r ds -D -v -d /data/opt/greenplum/tmp -d /data1/opt/greenplum/tmp
--------------------
  SETUP 2023-01-10T11:19:07.646581
--------------------
[Info] verify python interpreter exists
[Info] /usr/local/greenplum-db-6.21.3/bin/gpssh -f /data/opt/greenplum/all_hosts 'python -c print'
[Info] making gpcheckperf directory on all hosts ... 
[Info] /usr/local/greenplum-db-6.21.3/bin/gpssh -f /data/opt/greenplum/all_hosts 'rm -rf  /data/opt/greenplum/tmp/gpcheckperf_$USER /data1/opt/greenplum/tmp/gpcheckperf_$USER ; mkdir -p  /data/opt/greenplum/tmp/gpcheckperf_$USER /data1/opt/greenplum/tmp/gpcheckperf_$USER'
[Info] copy local /usr/local/greenplum-db-6.21.3/bin/lib/multidd to remote /data/opt/greenplum/tmp/gpcheckperf_$USER/multidd
[Info] /usr/local/greenplum-db-6.21.3/bin/gpscp -f /data/opt/greenplum/all_hosts /usr/local/greenplum-db-6.21.3/bin/lib/multidd =:/data/opt/greenplum/tmp/gpcheckperf_$USER/multidd
[Info] /usr/local/greenplum-db-6.21.3/bin/gpssh -f /data/opt/greenplum/all_hosts 'chmod a+rx /data/opt/greenplum/tmp/gpcheckperf_$USER/multidd'

--------------------
--  DISK WRITE TEST
--------------------
[Info] /usr/local/greenplum-db-6.21.3/bin/gpssh -f /data/opt/greenplum/all_hosts 'time -p /data/opt/greenplum/tmp/gpcheckperf_$USER/multidd -i /dev/zero -o /data/opt/greenplum/tmp/gpcheckperf_$USER/ddfile -i /dev/zero -o /data1/opt/greenplum/tmp/gpcheckperf_$USER/ddfile -B 32768'

--------------------
--  DISK READ TEST
--------------------
[Info] /usr/local/greenplum-db-6.21.3/bin/gpssh -f /data/opt/greenplum/all_hosts 'time -p /data/opt/greenplum/tmp/gpcheckperf_$USER/multidd -o /dev/null -i /data/opt/greenplum/tmp/gpcheckperf_$USER/ddfile -o /dev/null -i /data1/opt/greenplum/tmp/gpcheckperf_$USER/ddfile -B 32768'


--------------------
--  STREAM TEST
--------------------
[Info] copy local /usr/local/greenplum-db-6.21.3/bin/lib/stream to remote /data/opt/greenplum/tmp/gpcheckperf_$USER/stream
[Info] /usr/local/greenplum-db-6.21.3/bin/gpscp -f /data/opt/greenplum/all_hosts /usr/local/greenplum-db-6.21.3/bin/lib/stream =:/data/opt/greenplum/tmp/gpcheckperf_$USER/stream
[Info] /usr/local/greenplum-db-6.21.3/bin/gpssh -f /data/opt/greenplum/all_hosts 'chmod a+rx /data/opt/greenplum/tmp/gpcheckperf_$USER/stream'
[Info] /usr/local/greenplum-db-6.21.3/bin/gpssh -f /data/opt/greenplum/all_hosts /data/opt/greenplum/tmp/gpcheckperf_$USER/stream
--------------------
  TEARDOWN
--------------------
[Info] /usr/local/greenplum-db-6.21.3/bin/gpssh -f /data/opt/greenplum/all_hosts 'rm -rf  /data/opt/greenplum/tmp/gpcheckperf_$USER /data1/opt/greenplum/tmp/gpcheckperf_$USER'

====================
==  RESULT 2023-01-10T11:34:47.364279
====================

 disk write avg time (sec): 348.61
 disk write tot bytes: 808602697728
 disk write tot bandwidth (MB/s): 2212.16
 disk write min bandwidth (MB/s): 729.52 [dp03]
 disk write max bandwidth (MB/s): 741.71 [dp04]
 -- per host bandwidth --
    disk write bandwidth (MB/s): 729.52 [dp03]
    disk write bandwidth (MB/s): 741.71 [dp04]
    disk write bandwidth (MB/s): 740.92 [dp05]


 disk read avg time (sec): 475.13
 disk read tot bytes: 808602697728
 disk read tot bandwidth (MB/s): 1720.33
 disk read min bandwidth (MB/s): 462.72 [dp04]
 disk read max bandwidth (MB/s): 782.99 [dp03]
 -- per host bandwidth --
    disk read bandwidth (MB/s): 782.99 [dp03]
    disk read bandwidth (MB/s): 462.72 [dp04]
    disk read bandwidth (MB/s): 474.63 [dp05]


 stream tot bandwidth (MB/s): 28889.60
 stream min bandwidth (MB/s): 9613.60 [dp04]
 stream max bandwidth (MB/s): 9646.10 [dp03]
 -- per host bandwidth --
    stream bandwidth (MB/s): 9646.10 [dp03]
    stream bandwidth (MB/s): 9613.60 [dp04]
    stream bandwidth (MB/s): 9629.90 [dp05]

```



每台主机的磁盘文件预读统一设置为：16384

```sh
[root@dp03 ~]#   /sbin/blockdev --getra /dev/vda
8192
[root@dp03 ~]#   /sbin/blockdev --getra /dev/vdb
256
[root@dp03 ~]#   /sbin/blockdev --getra /dev/vdc
256
[root@dp03 ~]#   /sbin/blockdev --getra /dev/vdb
16384
[root@dp03 ~]#   /sbin/blockdev --getra /dev/vdc
16384
```





# --执行引擎--

https://www.modb.pro/db/430294



# --查看表分布--

https://blog.csdn.net/chuckchen1222/article/details/106899710



```sql
select gp_segment_id,count(*) from table_name group by gp_segment_id;
```



# 锁

https://blog.csdn.net/Explorren/article/details/105107672





来源：[Greenplum 运维脚本](https://mp.weixin.qq.com/s/jOhKsmNRE82x_vGkU2PHDw)

## 摘录内容 
Greenplum 运维脚本
==============

原创 gaoj [DCEGJ](javascript:void(0);)

**DCEGJ** 

微信号 gh_865591a6fb7b

功能介绍 SHARE

_2021-09-05 11:56_ _发表于_

收录于合集

  

SQL语法
-----

*   列转行
    

```sql
select unnest(string_to_array('111,222,333' , ',' ));
select array_remove(array[a,b,c],null);
select array[a,b,c,d] from xx;
```

SQL优化
-----

*   系统开关
    

| 参数名称                                           | 参数介绍 | 默认       |
| --- | --- | --- |
| optimizer | GPORCA优化器 | on |
| enable_bitmapscan | 位图扫描规划类型的使用 | on |
| enable_hashagg | hash聚集 | on |
| enable_hashjoin | hash连接 | on |
| enable_indexscan | 索引扫描 | on |
| enable_mergejoin | 融合连接 | on |
| enable_nestloop | 循环嵌套。我们不能完全消除明确的排序，但关闭这个参数可以让优化器在有其他方法的时候优先选择其他方法。 | on |
| enable_seqscan | 顺序扫描。我们不能完全消除明确的排序，但关闭这个参数可以让优化器在有其他方法的时候优先选择其他方法。 | on |
| enable_sort | 明确排序。我们不能完全消除明确的排序，但关闭这个参数可以让优化器在有其他方法的时候优先选择其他方法。 | on |
| enable_tidscan | TID扫描类型 | on |

打开/关闭命令：（会话级）

```sql
 set optimizer = off;
 set enable_bitmapscan = on;
 set enable_hashagg = on;
 set enable_hashjoin = on;
 set enable_indexscan = on;
 set enable_mergejoin = off;
 set enable_nestloop = off;
 set enable_seqscan = on;
 set enable_sort = on;
 set enable_tidscan = on;
```

psql
----

*   常用系统管理命令
    

```sql
 show search_path;
```

数据库管理
-----

*   常用伪列
    

```sql
 --分布的host主机id
 gp_segment_id
 --把oid和关系互转
 ::oid
 ::regclass --把oid和关系互转
```

*   常用系统函数
    

```sql
 --表大小
 select pg_size_pretty(pg_relation_size('table_name')); --表大小
 --杀进程
 select pg_terminate_backen(pid); --与pg_stat_activity联用
```

*   查看数据库对象
    

```sql
--查视图
 select * from pg_views;
 --查过程
 select * from pg_proc where proname like '%过程名%';
 --查字段
 select * from pg_catalog.pg_attribute;
 --查注释
 select * from pg_catalog.pg_description;
 
 --查用户、权限
 select * from pg_roles;
 select * from pg_authid;
 select * from information_schema.role_table_grants;
 
 --分区表
 select * from pg_partitions;
 
 --命名空间
 select * from pg_namespace;
```

  

*   资源管理
    

```sql
 --数据分布
 select gp_segment_id,count(*) from <table_name> group by gp_segment_id;
 --分部键（一对多）
 select * from pg_catalog.gp_distribution_policy;
 
 --资源管理
 select * from pg_roles,pg_resgroup where pg_roles.rolresgroup = pg_resgroup.oid;
 select t.localoid::regclass,t.* from gp_toolkit.gp_resgroup_config t;
```

  

*   连接数
    

```sql
 --连接统计
 select * from pg_stat_activity;
 select client_addr,count(1) from pg_stat_activity group by 1 order by 2;
 select pg_terminate_backend(pid) from pg_stat_activity where state = 'idle';
```

  

*   死锁
    

```sql
 select locks.pid, rolname, rsqname, granted, datnamek, query
   from gp_roles roles, gp_toolkit.gp_resqueue_status grs, pg_locks, pg_stat_activity state
  where roles.rolresqueue = locks.objid
    and locks.objid = grs.queueid
    and stat.pid = locks.pid;
```

  

*   备份恢复
    

```css
 pg_backup
 pg_restore -d postgres pg_backup.dat
```

  

模式管理 & 模式管理
-----------

```http
 create database gpdb with owner gpadmin lc_collate 'C' template template0;
 
 create extension pljava;
 create extension gpss;
 create extension pxf; --/dx查看
 create schema test_dwd;
 
 create role test_role login nosuperuser nocreatedb noinherit password 'test_role';
 
 alter role test_role with createexttable(type='readable');
 alter role test_role createexttable(typ'readable',protocol='gpfdist');
 alter role test_role set search_path to adw,test_dwd,pg_catalog,public;
 
 create resource group ods_group
 with (
 concurrency = 50,
 cpu_rate_limit = 10,
 memory_limit 20,
 memory_shared_quota = 50,
 memory_spill_ratio = 0
 );
 alter role test_role resource group ods_group;
 
 create sequence com.com_t_log_seq start with 10000000 increment by 1 no minvalue no maxvalue cache 1;
 
 grant all on schema test_dwd to test_role with grant option;
 grant usage on schema test_dwd to test_role;
 
 grant select on <table_name> in schema test_dwd to test_role;
 grant select on all tables in schema test_dwd to test_role;
 grant all on function com.fn_get_current_role() to test_role;
 grant all on <table_name> to test_role;
 
 --分裂分区
 alter table test_dwd.test_dwd_table_name split default pg_partition
 start ('20200123') inclusive end ('20220202') exclusive into (partition '20200123', default partition);
```

  

  

*   表所有者owner
    

```sql
 alter table test.test_table_name owner to usr_test;
 alter table test.test_table_name owner to usr_test;
```

  

*   权限查询
    

```sql
 1、查看某用户的表权限
 select * from information_schema.table_privileges where grantee='user_name';
 2、查看usage权限表
 select * from information_schema.usage_privileges where grantee='user_name';
 3、查看存储过程函数相关权限表
 select * from information_schema.routine_privileges where grantee='user_name';
```

  

*   pxf赋权
    

```sql
 ./pxf cluster init/reset/stop/start/gp_resqueue_status
 grant select on protocol pxf to usr_text;
 grant insert on protocol pxf to usr_text;
```

  

审计：gp_toolkit
-------------

*   数据库大小
    

```sql
select * from gp_toolkit.gp_size_of_database;
select t.*,pg_size_pretty(soddatasize) as size from gp_toolkit.gp_size_of_database t order by 2 desc;
```

*   执行log
    

```sql
 select * from gp_toolkit.__gp_log_master_ext t;
 select * from gp_toolkit.__gp_log_segment_ext t;
```

*   倾斜判断
    

```sql
--执行时间较长，数值越大越倾斜
select * from gp_toolkit.gp_skew_coefficients;
```


 通过计算表扫描过程中，系统闲置的百分比，帮助用户快速判断，是否存在分布键选择不合理，导致数据处理倾斜的问题。  
 变异系数CV:数值越低情况越好  
 在一次表扫描中系统空闲的百分比，0.1表示有10%的倾斜，超过0.1则要考虑其分布策略。  

```cs
select * from gp_toolkit.gp_skew_idlw_fractions;
```

  

*   检查失效的segment
    

```sql
select * from gp_toolkit.gp_pgdatabase_invalid;
```

  

审计：gpcc
-------

*   sql执行历史（重要）
    

```sql
 --只存住近5分钟的热数
 select * from gpmetrics.gpcc_pg_log_history;
```

```sql
 --重要
 select * from gpmetrics.gpcc_queries_history;
 select * from gpmetrics.queries_history; --对应gpcc_queries_history的视图
```

*   alert，对应gpcc中workload Mgmt里面对系统阈值的告警
    

```sql
 --规则制定表，历史表（为什么有历史表自行脑补）
 select * from gpmetrics.gpcc_alert_rule order by ctime desc;
 select * from gpmetrics.gpcc_alter_history order by transaction_time desc;
 
 --规则阈值触发日志
 select * from gpmetrics.gpcc_alter_log order by transaction_time desc;
```

  


alert执行结果，对应gpcc中触发history

```sql
 select * from gpmetrics.gpcc_wlm_rule;
 select * from gpmetrics.gpcc_wlm_log_history;
```
## 想法





# 追踪



```sh
yum install gdb strace -y
```







Strace是一个动态追踪进程系统调用的工具（进程跟操作系统内核的交互)，我们可以直接使用``strace -p` 这个命令直接查看，也可以用如下命令：

```sh
strace -T -f -ff -y -yy -p 
```



来源：[(7条消息) Greenplum概念学习——节点分布模式：grouped、spread_greenplum group spread_肥叔菌的博客-CSDN博客](https://blog.csdn.net/asmartkiller/article/details/112549887) 

## greenplum的两种节点分布模式 

------------------

(6台主机，每台4个segment，两两primary、mirror)   

①grouped mirror模式：(grouped模式，主机的mirror节点全部放在下一个主机上)   ![](.img_greenplum/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2FzbWFydGtpbGxlcg==,size_16,color_FFFFFF,t_70-20230306102121858.png)   ②spread mirror模式： (spread模式,主机的第一个mirror在下个主机,第二个mirror在次下个主机,第三mirror在次次下个主机…)   ![](.img_greenplum/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2FzbWFydGtpbGxlcg==,size_16,color_FFFFFF,t_70.png) ## 想法

# GPORCA



|         | off  | on   |
| ------- | ---- | ---- |
| join on | 90   | 90   |
| 分布    |      |      |
|         |      |      |



# end













