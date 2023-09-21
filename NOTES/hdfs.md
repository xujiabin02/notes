# [hadoop namenode启动失败](https://www.cnblogs.com/yjt1993/p/10476933.html)

hadoop version=3.1.2

生产环境中，一台namenode节点突然挂掉了，，重新启动失败，日志如下：

```
Info=-64%3A1391355681%3A1545175191847%3ACID-9160c87b-3ab7-4372-98a1-536a59dd36ef&inProgressOk=``true``' to transaction ID 159168296``2019-03-05 14:38:06,460 INFO org.apache.hadoop.hdfs.server.namenode.RedundantEditLogInputStream: Fast-forwarding stream ``'http://xxx:8480/getJournal?jid=GD-AI&segmentTxId=162853718&storageInfo=-64%3A1391355681%3A1545175191847%3ACID-9160c87b-3ab7-4372-98a1-536a59dd36ef&inProgressOk=true'` `to transaction ID 159168296``2019-03-05 14:38:06,487 WARN org.apache.hadoop.hdfs.server.namenode.FSNamesystem: Encountered exception loading fsimage``java.io.IOException: There appears to be a gap ``in` `the edit log. We expected txid 159168296, but got txid 162853718.``    ``at org.apache.hadoop.hdfs.server.namenode.MetaRecoveryContext.editLogLoaderPrompt(MetaRecoveryContext.java:94)``    ``at org.apache.hadoop.hdfs.server.namenode.FSEditLogLoader.loadEditRecords(FSEditLogLoader.java:238)``    ``at org.apache.hadoop.hdfs.server.namenode.FSEditLogLoader.loadFSEdits(FSEditLogLoader.java:160)``    ``at org.apache.hadoop.hdfs.server.namenode.FSImage.loadEdits(FSImage.java:890)``    ``at org.apache.hadoop.hdfs.server.namenode.FSImage.loadFSImage(FSImage.java:745)``    ``at org.apache.hadoop.hdfs.server.namenode.FSImage.recoverTransitionRead(FSImage.java:323)``    ``at org.apache.hadoop.hdfs.server.namenode.FSNamesystem.loadFSImage(FSNamesystem.java:1097)``    ``at org.apache.hadoop.hdfs.server.namenode.FSNamesystem.loadFromDisk(FSNamesystem.java:714)``    ``at org.apache.hadoop.hdfs.server.namenode.NameNode.loadNamesystem(NameNode.java:632)``    ``at org.apache.hadoop.hdfs.server.namenode.NameNode.initialize(NameNode.java:694)``    ``at org.apache.hadoop.hdfs.server.namenode.NameNode.<init>(NameNode.java:937)``    ``at org.apache.hadoop.hdfs.server.namenode.NameNode.<init>(NameNode.java:910)``    ``at org.apache.hadoop.hdfs.server.namenode.NameNode.createNameNode(NameNode.java:1643)``    ``at org.apache.hadoop.hdfs.server.namenode.NameNode.main(NameNode.java:1710)``2019-03-05 14:38:06,490 INFO org.eclipse.jetty.server.handler.ContextHandler: Stopped o.e.j.w.WebAppContext@6950ed69{/,null,UNAVAILABLE}{``/hdfs``}``2019-03-05 14:38:06,494 INFO org.eclipse.jetty.server.AbstractConnector: Stopped ServerConnector@5f20155b{HTTP``/1``.1,[http``/1``.1]}{xxx:50070}``2019-03-05 14:38:06,494 INFO org.eclipse.jetty.server.handler.ContextHandler: Stopped o.e.j.s.ServletContextHandler@4722ef0c{``/static``,``file``:``///data1/hadoop/hadoop-3``.1.2``/share/hadoop/hdfs/webapps/static/``,UNAVAILABLE}``2019-03-05 14:38:06,494 INFO org.eclipse.jetty.server.handler.ContextHandler: Stopped o.e.j.s.ServletContextHandler@5b38c1ec{``/logs``,``file``:``///data1/hadoop/hadoop-3``.1.2``/logs/``,UNAVAILABLE}``2019-03-05 14:38:06,495 INFO org.apache.hadoop.metrics2.impl.MetricsSystemImpl: Stopping NameNode metrics system...``2019-03-05 14:38:06,496 INFO org.apache.hadoop.metrics2.impl.MetricsSystemImpl: NameNode metrics system stopped.``2019-03-05 14:38:06,496 INFO org.apache.hadoop.metrics2.impl.MetricsSystemImpl: NameNode metrics system ``shutdown` `complete.``2019-03-05 14:38:06,496 ERROR org.apache.hadoop.hdfs.server.namenode.NameNode: Failed to start namenode.``java.io.IOException: There appears to be a gap ``in` `the edit log. We expected txid 159168296, but got txid 162853718.``    ``at org.apache.hadoop.hdfs.server.namenode.MetaRecoveryContext.editLogLoaderPrompt(MetaRecoveryContext.java:94)``    ``at org.apache.hadoop.hdfs.server.namenode.FSEditLogLoader.loadEditRecords(FSEditLogLoader.java:238)``    ``at org.apache.hadoop.hdfs.server.namenode.FSEditLogLoader.loadFSEdits(FSEditLogLoader.java:160)``    ``at org.apache.hadoop.hdfs.server.namenode.FSImage.loadEdits(FSImage.java:890)``    ``at org.apache.hadoop.hdfs.server.namenode.FSImage.loadFSImage(FSImage.java:745)``    ``at org.apache.hadoop.hdfs.server.namenode.FSImage.recoverTransitionRead(FSImage.java:323)``    ``at org.apache.hadoop.hdfs.server.namenode.FSNamesystem.loadFSImage(FSNamesystem.java:1097)``    ``at org.apache.hadoop.hdfs.server.namenode.FSNamesystem.loadFromDisk(FSNamesystem.java:714)``    ``at org.apache.hadoop.hdfs.server.namenode.NameNode.loadNamesystem(NameNode.java:632)``    ``at org.apache.hadoop.hdfs.server.namenode.NameNode.initialize(NameNode.java:694)``    ``at org.apache.hadoop.hdfs.server.namenode.NameNode.<init>(NameNode.java:937)``    ``at org.apache.hadoop.hdfs.server.namenode.NameNode.<init>(NameNode.java:910)``    ``at org.apache.hadoop.hdfs.server.namenode.NameNode.createNameNode(NameNode.java:1643)``    ``at org.apache.hadoop.hdfs.server.namenode.NameNode.main(NameNode.java:1710)``2019-03-05 14:38:06,497 INFO org.apache.hadoop.util.ExitUtil: Exiting with status 1: java.io.IOException: There appears to be a gap ``in` `the edit log. We expected txid 159168296, but got txid 162853718.``2019-03-05 14:38:06,499 INFO org.apache.hadoop.hdfs.server.namenode.NameNode: SHUTDOWN_MSG:``/************************************************************c　
```

 

从报错来看，，是获取edit log日志出错。说白点，就是namenode元数据破坏了，需要修复。

解决：

（1）、在出错的机器执行如下命令，一路按c或者y

```
# hadoop namenode -recover
```

（2）、如果第一种没有解决，那么按如下的方法来解决

解决步骤与命令：
1） 确保另外一个active的nn是正常的且不要去关闭，如果此前提不保证，则寻找另外解决方法，底下忽略；
2） 然后检查active-nn的元数据目录下的fsimage是否是最新的，可根据当前机器时间来大致判断，如否则需要进入安全模式后savenamespace，操作如下：
du -sh /hadoop/journal/ 这个的大小也要确定下，太大则很会很慢

su hdfs
export HADOOP_CLIENT_OPTS="-D transwarp.maintenance.only.mode=true"
hdfs dfsadmin –safemode get
hdfs dfsadmin -safemode enter
hdfs dfsadmin –saveNamespace
hdfs dfsadmin -safemode leave

3） 然后把hive1(当前active) 的disk1的这current两个最新的标红色fsimge以及对应的md5的文件，scp到hive2（启动失败的nn）的disk1 的同样目录current目录下，当然一般dfs.namenode.name.dir配置的是两块磁盘，另外一个也需要scp过去，最后需要注意复制过去文件的权限，需要修改权限chown hdfs:hdfs xx文件

重启此前失败的standby-namenode;

 

 

借鉴：http://support.transwarp.cn/t/namenode/2242

 