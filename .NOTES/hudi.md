# 安装

编译hudi

```sh
# git clone -b release-0.13.1 https://github.com/apache/hudi.git
cd hudi
mvn  clean package -Pintegration-tests -DskipTests=true
# 漫长的等待
```

hadoop 2.9x+,  /etc/profile

```sh
export HADOOP_HOME=/data/opt/hadoop
export HADOOP_CLASSPATH=`$HADOOP_HOME/bin/hadoop classpath`
export PATH=$HADOOP_HOME/bin:${PATH}
```

flink1.16

```sh
cd /data/opt/flink-1.16.0
cp /data/opt/hudi/hudi/packaging/hudi-flink-bundle/target/hudi-flink1.16-bundle-0.13.1.jar lib/
```

编辑 conf/flink-conf.yaml

```ts
taskmanager.numberOfTaskSlots: 1 => 4
```

编辑 conf/workers

```
localhost
```

=>

```
localhost
localhost
localhost
localhost
```



# 测试

启动flink cluster

```sh
# HADOOP_HOME is your hadoop root directory after unpack the binary package.
export HADOOP_CLASSPATH=`$HADOOP_HOME/bin/hadoop classpath`

# Start the Flink standalone cluster
./bin/start-cluster.sh
```

启动 flink  sql-client

```sh
cd /data/opt/flink
export HADOOP_CLASSPATH=`$HADOOP_HOME/bin/hadoop classpath`
bin/sql-client.sh embedded -j lib/hudi-flink1.16-bundle-0.13.1.jar shell
```

建表

```sql

set sql-client.execution.result-mode = tableau;

CREATE TABLE t1(
  uuid VARCHAR(20) PRIMARY KEY NOT ENFORCED,
  name VARCHAR(10),
  age INT,
  ts TIMESTAMP(3),
  `partition` VARCHAR(20)
)
PARTITIONED BY (`partition`)
WITH (
  'connector' = 'hudi',
  'path' = '/data/opt/hudi/data/',
  'table.type' = 'MERGE_ON_READ' -- this creates a MERGE_ON_READ table, by default is COPY_ON_WRITE
);
INSERT INTO t1 VALUES
  ('id1','Danny',23,TIMESTAMP '1970-01-01 00:00:01','par1'),
  ('id2','Stephen',33,TIMESTAMP '1970-01-01 00:00:02','par1'),
  ('id3','Julian',53,TIMESTAMP '1970-01-01 00:00:03','par2'),
  ('id4','Fabian',31,TIMESTAMP '1970-01-01 00:00:04','par2'),
  ('id5','Sophia',18,TIMESTAMP '1970-01-01 00:00:05','par3'),
  ('id6','Emma',20,TIMESTAMP '1970-01-01 00:00:06','par3'),
  ('id7','Bob',44,TIMESTAMP '1970-01-01 00:00:07','par4'),
  ('id8','Han',56,TIMESTAMP '1970-01-01 00:00:08','par4');
SET sql-client.execution.result-mode=changelog;
CREATE TABLE t2(
  uuid VARCHAR(20) PRIMARY KEY NOT ENFORCED,
  name VARCHAR(10),
  age INT,
  ts TIMESTAMP(3),
  `partition` VARCHAR(20)
)
PARTITIONED BY (`partition`)
WITH (
  'connector' = 'hudi',
  'path' = '/data/opt/hudi/data/t1',
  'table.type' = 'MERGE_ON_READ',
  'read.streaming.enabled' = 'true',  -- this option enable the streaming read
  'read.start-commit' = '20210316134557', -- specifies the start commit instant time
  'read.streaming.check-interval' = '4' -- specifies the check interval for finding new source commits, default 60s.
);
```

