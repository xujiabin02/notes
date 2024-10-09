[发散阅读](https://aijishu.com/a/1060000000225602)

# 软raid  mdadm

## 创建

```
mdadm -Cv /dev/md0  -a yes -n 3 -l 5  /dev/sdb /dev/sdc /dev/sdd
mdadm -Cv /dev/md0  -a yes -n 4 -l 10  /dev/nvme5n1 /dev/nvme6n1 /dev/nvme7n1 /dev/nvme8n1
```

-n 为设备数量

-l 为raid 等级

## 格式化

xfs格式

```
mkfs.xfs /dev/md0
```

ext4

```shell
mkfs.ext4 /dev/md0
mke2fs 1.45.5 (07-Jan-2020)
丢弃设备块： 完成                            
创建含有 2812680192 个块（每块 4k）和 351588352 个 inode 的文件系统
文件系统 UUID：e8ff06f1-7d73-46ee-ac0f-6faefe0e226e
超级块的备份存储于下列块： 
        32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632, 2654208, 
        4096000, 7962624, 11239424, 20480000, 23887872, 71663616, 78675968, 
        102400000, 214990848, 512000000, 550731776, 644972544, 1934917632, 
        2560000000

正在分配组表： 完成                            
正在写入 inode表： 完成                            
创建日志（262144 个块）：
```





## 查uuid

```
blkid
```

## 写入自动挂载 /etc/fstab

```sh
UUID=b0fa49de-aa9e-4b4f-902e-64e52455804b /data xfs defaults 0 0
```

查看状态

```sh
mdadm -D /dev/md<number>
cat /proc/mdstat
```

# 性能测试

```sh
sudo dd if=/dev/zero of=/minio/test.img bs=1M count=300000
```

nvme U.2 ssd , 4块 做 raid10 

![image-20231115152637068](.img_raid/image-20231115152637068.png)

# 手册

停止raid

```shell
mdadm --stop /dev/md0
```



添加磁盘

```
mdadm --manage /dev/md0 --add /dev/sdc1
```

1.
RAID1下/dev/sdc1将成为备用盘，在有故障发生时自动进行替换。

删除磁盘

```
mdadm --manage /dev/md0 --remove /dev/sdc1
```

1.
扩充磁盘

```
mdadm --grow /dev/md0 --raid-devices=3
```



# 模拟故障处理

```
mdadm --manage /dev/md0 --fail /dev/sdb
mdadm --manage /dev/md0 --add /dev/sdd
```



# Resync Status 速度慢

sysctl

```sh
dev.raid.speed_limit_min = 1000000
dev.raid.speed_limit_max = 2500000
```

生效

```sh
sysctl -p
```

