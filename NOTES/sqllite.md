# sqllite

## import csv

start db

```shell
sqlite3 my.db
```



```sql
CREATE TABLE t1 (id INTEGER,name TEXT);
.schema t1
.import --csv --skip 1 2.csv t1
select * from t1;
```

