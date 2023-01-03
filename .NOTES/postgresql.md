# 如何将postgresql数据库表内数据导出为excel格式

 原创

[瀚高实验室](https://blog.51cto.com/u_13646489)2021-05-28 16:27:11©著作权

*文章标签*[数据库](https://blog.51cto.com/topic/the-database-1.html)*文章分类*[PostgreSQL通用知识](https://blog.51cto.com/u_13646489/category1)*阅读数*272

作者：瀚高PG实验室 （Highgo PG Lab）- 禹晓

本文主要用于介绍如何使用copy或者\copy命令将postgresql数据库内表的数据导出为excel格式，方便用户查看编辑。

copy命令同\copy命令语法上相同，区别在于copy必须使用能够超级用户使用,copy … to file 中的文件都是数据库服务器所在的服务器上的文件，而\copy 一般用户即可执行且\copy 保存或者读取的文件是在客户端所在的服务器。本文主要以copy命令作为介绍重点，使用copy命令将表内数据倒为csv格式文件即为excel格式。
1、copy命令语法

```excel
COPY { 表名 [ ( 列名称 [, ...] ) ] | ( 查询 ) }    TO { '文件名' | PROGRAM '命令' | STDOUT }   
 [ [ WITH ] ( 选项 [, ...] ) ]选项可以是下列内容之一
 FORMAT 格式_名称    
 FREEZE [ 布尔 ]    
 DELIMITER '分隔字符'    
 NULL '空字符串'    
 HEADER [ 布尔 ]    
 QUOTE '引用字符'    
 ESCAPE '转义字符'    
 FORCE_QUOTE { ( 列名称 [, ...] ) | * }    
 FORCE_NOT_NULL ( 列名称 [, ...] )    
 FORCE_NULL ( 列名称 [, ...] )    
 ENCODING 'encoding_name(编码名)'1.2.3.4.5.6.7.8.9.10.11.12.13.
```

2、多场景使用介绍
①查看现有表数据

```sql
test=# select * from test;user_id |   user_name   | age | gender |                    remark                    
---------+---------------+-----+--------+----------------------------------------------       1 | Jackie Chan   |  45 | male   | "police story","project A","rush hour"
       3 | Brigitte Li   |  46 | female | 
       4 | Maggie Cheung |  39 | female | 
       5 | Jet Li        |  41 | male   | "Fist of Legend","Once Upon a Time in China"
       2 | Gong Li       |  38 | female | "Farewell My Concubine","Lifetimes Living"(5 行记录)1.2.3.4.5.6.
```

②带列名导出，默认情况下使用，作为分隔符

```sql
copy test to '/tmp/test1.csv' with csv header;
```

③带列名导出，指定使用|作为分隔符

```sql
copy test to '/tmp/test1.csv' with csv header DELIMITER '|';

```

④带列名导出，将空字符替换为指定值导出

```sql
copy test to '/tmp/test1.csv' with csv header null 'to be supplemented';
```



# 授权



```
CREATE USER src_user WITH PASSWORD '*****';
GRANT ALL PRIVILEGES ON DATABASE testDB TO testUser;
GRANT ALL PRIVILEGES ON all tables in schema public TO testUser;

```

