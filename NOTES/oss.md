对象存储s3

|                   |      |      |
| ----------------- | ---- | ---- |
| [ceph](ceph.md)   |      |      |
| [minio](minio.md) |      |      |
|                   |      |      |



# client signurl

```shell
# linux
day=`date -d 'now + 1 year' +%s`
echo $day
s3cmd signurl s3://dml_demo/example.yaml $day
```

```shell
# macos
day=date -v25y "+%s" 
echo $day
s3cmd signurl s3://dml_demo/example.yaml $day
```

