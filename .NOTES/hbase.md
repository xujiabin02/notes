# 平滑重启

```sh
滚动重启regionserver #待测试
./graceful_stop.sh --restart --reload --debug --maxthreads 10 {regionserverhost}

滚动重启master
主master：
./hbase-daemon.sh stop master
./hbase-daemon.sh start master

backup master:
./hbase-daemon.sh stop master
./hbase-daemon.sh start master
```

————————————————
版权声明：本文为CSDN博主「灰二和杉菜」的原创文章，遵循CC 4.0 BY-SA版权协议，转载请附上原文出处链接及本声明。
原文链接：https://blog.csdn.net/qq475781638/article/details/96152462

# oldWALs

hbase-1.1.2的oldWALs占用过大hdfs空间问题的解决

为什么会出现oldWALs？
【原因】

当/hbase/WALs中的HLog文件被持久化到存储文件中，且这些Hlog日志文件不再被需要时，就会被转移到{hbase.rootdir}/oldWALs目录下，该目录由HMaster上的定时任务负责定期清理。

HMaster在做定期清理的时候首先会检查zookeeper中/hbase/replication/rs下是否有对应的复制文件，如果有就放弃清理，如果没有就清理对应的hlog。在手动清理oldWALs目录数据的同时，如果没有删除对应的znode数据，就会导致HMaster不会自动清理oldWALs。
另附某网友的解答：

>  The folder gets cleaned regularly by a chore in master. When a WAL file is not needed any more for recovery purposes (when HBase can guaratee HBase has flushed all the data in the WAL file), it is moved to the oldWALs folder for archival. The log stays there until all other references to the WAL file are finished. There is currently two services which may keep the files in the archive dir. First is a TTL process, which ensures that the WAL files are kept at least for 10 min. This is mainly for debugging. You can reduce this time by setting hbase.master.logcleaner.ttl configuration property in master. It is by default 600000. The other one is replication. If you have replication setup, the replication processes will hang on to the WAL files until they are replicated. Even if you disabled the replication, the files are still referenced.



【解决】

(1) 进到zookeeper的节点下，删除相关节点，如截图所示

![img](img_hbase/SouthEast.jpeg)

(2) 确保hbase-site.xml中的属性hbase.replication=false和属性hbase.backup.enable=false 如果是true就改成false，如果没有那两个属性则添加上去后重启整个hbase集群。



(3) (我是在Ambari中)添加属性hbase.backup.enable=false到hbase-site.xml中去，再重启整个hbase集群，然后很快就能在hdfs中查看到{hbae.rootdir}/oldWALs目录大小为零了。所以说 hbase.backup.enable=false 属性是清除oldWALs文件的关键一步。

可以从截图中看到，原来1.6T的oldWALs，被hmaster清理掉了：

![img](.img_hbase/SouthEast-20210407091223831.jpeg)

————————————————
版权声明：本文为CSDN博主「小猫爱吃鱼^_^」的原创文章，遵循CC 4.0 BY-SA版权协议，转载请附上原文出处链接及本声明。
原文链接：https://blog.csdn.net/qq_31598113/article/details/79221608



# 概述

```yml
table:
 c: hbase表
 a: 包含多行数据
column:
 c: column family + qualifier => 列簇 + 列名
 a: 
column family:
 c: 
 a: 
cell:
 c: 
 a: 
compaction:
 c: 合并小HFile,减少文件数，清除无效数据，稳定随机读延迟，提高HFile本地化率
 a: minor,major
minor compaction:
 c: minor=>不重要的,region的一个Store中选取部分较小的、相邻小HFile合并
 a: 影响较小可以无须管理
major compaction:
 c: major=>较重要的,region的一个Store中所有的HFile合并成一个,并且清理（被删除、TTL过期、版本号超出设定）三类数据，特点是持续较长、消耗大量系统资源
 a: 关闭major改为手动触发
 
```



# major触发脚本

```sh
#!/bin/bash
time_start=`date "+%Y-%m-%d %H:%M:%S"`
echo "开始进行HBase的大合并.时间:${time_start}"
 
str=`echo list | hbase shell | sed -n '$p'`
#str="a,b,c"
str=${str//,/ }
arr=($str)
length=${#arr[@]}
current=1
echo "HBase中总共有${length}张表需要合并."
echo "balance_switch false" | hbase shell | > /dev/null
echo "HBase的负载均衡已经关闭"
 
for each in ${arr[*]}
do
        table=`echo $each | sed 's/]//g' | sed 's/\[//g'`
        echo "开始合并第${current}/${length}张表,表的名称为:${table}"
        echo "major_compact ${table}" | hbase shell | > /dev/null
        let current=current+1 
done
 
echo "balance_switch true" | hbase shell | > /dev/null
echo "HBase的负载均衡已经打开."
 
time_end=`date "+%Y-%m-%d %H:%M:%S"`
echo "HBase的大合并完成.时间:${time_end}"
duration=$($(date +%s -d "$finish_time")-$(date +%s -d "$start_time"))
echo "耗时:${duration}s"
```



# ---



[^ 1 ]: https://www.baidu.com

