# MySQL开启general_log查看执行的SQL语句

[![img](https://uimg.majing.io/default/avatar/default.png)](https://devnote.pro/users/1184/posts)

[新生](https://devnote.pro/users/1184/posts) 

更新于2021.12.09 阅读 5556

[今日荐书：【2019年诺贝尔经济学奖】贫穷的本质：我们为什么摆脱不了贫穷](https://union-click.jd.com/jdc?e=&p=AyIGZRprFQEXB1caXBUyVlgNRQQlW1dCFFlQCxxKQgFHRE5XDVULR0UVARcHVxpcFR1LQglGa0EAVXkRWR1zYGxhNVMbZ1lbchZ9PWUOHjdQGF8SBBcGVB5rFQMTBlQcUhABEDdlG1olVHwHVBpaFAMXBFcfaxABFgBSE1gVBCIHURJZFgoXBFYZWhQKIgBVEmtHX0BXHktrJQIRAlUZWhICIgRlK2sVMhE3F3UOQgETDlYbC0IAGwFQHQlCURUPAR5dHQQRA1NIXxRRGzdXGloRCw%3D%3D)

general log会记录下发送给MySQL服务器的所有SQL记录，因为SQL的量大，默认是不开启的。一些特殊情况（如排除故障）可能需要临时开启一下。

### 开启MySQL的general log

MySQL有三个参数用于设置general log：

* general_log：用于开启general log。ON表示开启，OFF表示关闭。
* log_output：日志输出的模式。FILE表示输出到文件，TABLE表示输出到mysq库的general_log表，NONE表示不记录general_log。
* general_log_file：日记输出文件的路径，这是log_output=FILE时才会输出到此文件。

1、查看先是否开启了general log

```plaintext
mysql> show variables where Variable_name="general_log";
+---------------+-------+
| Variable_name | Value |
+---------------+-------+
| general_log  | OFF  |
+---------------+-------+
1 row in set (0.00 sec)
```

2、查看日志输出模式

```plaintext
mysql> show variables where Variable_name="log_output"; 
+---------------+-------+
| Variable_name | Value |
+---------------+-------+
| log_output  | FILE |
+---------------+-------+
1 row in set (0.00 sec)
```

3、查看日志输出路径

```plaintext
mysql> show variables where Variable_name="general_log_file";
+------------------+----------------------------+
| Variable_name  | Value           |
+------------------+----------------------------+
| general_log_file | /var/run/mysqld/mysqld.log |
+------------------+----------------------------+
1 row in set (0.00 sec)
```

4、设置日志模式为TABLE，FILE双模式

```plaintext
mysql> set global log_output='TABLE,FILE';    
Query OK, 0 rows affected (0.00 sec)
```

5、开启general log

```plaintext
set global general_log=ON;
```

6、关闭general log

大多数情况是临时开启general log，需要记得关闭，并把日志的输出模式恢复为FILE。

```plaintext
set global general_log=OFF;
set global log_output='FILE'
```

### general_log表

现在在mysql库的general_log表就可以查看到开启general log那段时间的SQL记录。

查看general_log的表结构：

```plaintext
mysql> show create table mysql.general_log\G
*************************** 1. row ***************************
    Table: general_log
Create Table: CREATE TABLE `general_log` (
 `event_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
 `user_host` mediumtext NOT NULL,
 `thread_id` int(11) NOT NULL,
 `server_id` int(10) unsigned NOT NULL,
 `command_type` varchar(64) NOT NULL,
 `argument` mediumtext NOT NULL
) ENGINE=CSV DEFAULT CHARSET=utf8 COMMENT='General log'
1 row in set (0.00 sec)
```

查询得到

```plaintext
$select * from mysql.general_log limit 1 \G
*************************** 1. row ***************************
 event_time: 2018-01-05 17:35:45
  user_host: root[root] @ localhost []
  thread_id: 89429
  server_id: 2
command_type: Query
  argument: select * from mysql.general_log
1 row in set (0.00 sec)
```

**版权声明：**著作权归作者所有。







```
create table unii_app_info_20220314 like unii_app_info;
insert into unii_app_info_20220314  select * from  unii_app_info;

ocean_app_info
create table ocean_app_info_20220314 like ocean_app_info;
insert into ocean_app_info_20220314  select * from  ocean_app_info;
```
