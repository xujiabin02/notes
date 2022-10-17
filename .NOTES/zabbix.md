[toc]



# 表结构解析



| 表名                                                      |                      |      |
| --------------------------------------------------------- | -------------------- | ---- |
| hosts                                                     | hosts & template信息 |      |
| items                                                     | item & template      |      |
| triggers                                                  | trigger              |      |
| history,history_log,histroy_unit,history_str,history_text | history              |      |
| alerts                                                    | 报警                 |      |
| hstgrp                                                    | hostgroup            |      |
| configs                                                   | 配置信息             |      |
| interface                                                 | IP port信息          |      |
| events                                                    | 事件                 |      |
| problem                                                   | 问题                 |      |





| 3.4   | 6.0         |      |
| ----- | ----------- | ---- |
| items | items_rdata |      |
|       |             |      |
|       |             |      |



## Trigger with count and regular expression not working



10-05-2021, 13:35

OK, I found the problem myself - I was missing the "regex" in the operator:



Code:

```
{DB:db.checkprocesses["{$DBNAME}","{$DBAGENTPROCESSES}","{$DBUSER}"].count(#30,"CRIT.*",regex)}>=1
```

# 聚合

https://www.zabbix.com/documentation/6.0/en/manual/config/items/itemtypes/calculated/aggregate





# 抑制

https://www.yisu.com/zixun/15926.html



# 长文经验

https://www.infoq.cn/article/rbw25cwbpb3esadqu0gp













```sh
proc.num[<name>,<user>,<state>,<cmdline>]
```





