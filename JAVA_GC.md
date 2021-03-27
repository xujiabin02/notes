```sh
gc优化
   使用g1收集器
   主要参数:
    -XX:-UseBiasedLocking      去除偏向锁防止因为偏向锁导致Stopping threads took时间过长
    -XX:InitiatingHeapOccupancyPercent=65    当old区占用heap的65%时开始进行mixgc，主要根据blockcache+memstore+staticindex大小设定
    -XX:ParallelGCThreads=8    并行收集器的线程数，同时有多少个线程一起进行垃圾回收
    -XX:ConcGCThreads=2        并发GC使用的线程数
    -XX:G1NewSizePercent=5     eden区达到最小占用heap空间的大小
    -XX:G1MaxNewSizePercent=15 eden区达到最大占用heap空间的大小，默认值为60，防止每次young gc时回收内存过大
    -XX:MaxTenuringThreshold=1 （regionserver）young在Survivor区转换几次后到达old区，由于regionserver的old区的内存主要由blockcache+memstore+staticindex组成，需要将对象尽快添加到old区减少在Survivor区停留时间
    -XX:MaxTenuringThreshold=15 hmaster，thriftserver old占用很小对象调大也可以很快清理掉没有引用的对象

  hmaster配置参数
-Xmx4g -Xms4g
-XX:+UseG1GC
-XX:+UnlockExperimentalVMOptions
-XX:-OmitStackTraceInFastThrow
-XX:+ParallelRefProcEnabled
-XX:-ResizePLAB
-XX:-UseBiasedLocking
-XX:+SafepointTimeout
-XX:SafepointTimeoutDelay=2000
-XX:G1NewSizePercent=5
-XX:G1MaxNewSizePercent=15
-XX:MaxTenuringThreshold=15
-XX:G1MixedGCCountTarget=16
-XX:MaxGCPauseMillis=200
-XX:ParallelGCThreads=4
-XX:ConcGCThreads=2
-XX:InitiatingHeapOccupancyPercent=45
-XX:G1MixedGCLiveThresholdPercent=65
-XX:G1HeapWastePercent=10
-XX:G1OldCSetRegionThresholdPercent=9
-XX:G1ReservePercent=10

  regionserver配置参数
-Xms16g -Xmx16g
-XX:+UseG1GC
-XX:+UnlockExperimentalVMOptions
-XX:-OmitStackTraceInFastThrow
-XX:+ParallelRefProcEnabled
-XX:-ResizePLAB
-XX:-UseBiasedLocking
-XX:+SafepointTimeout
-XX:SafepointTimeoutDelay=2000
-XX:G1NewSizePercent=5
-XX:G1MaxNewSizePercent=15
-XX:MaxTenuringThreshold=1
-XX:G1HeapRegionSize=8M
-XX:G1MixedGCCountTarget=16
-XX:MaxGCPauseMillis=200
-XX:ParallelGCThreads=8
-XX:ConcGCThreads=2
-XX:InitiatingHeapOccupancyPercent=65
-XX:G1MixedGCLiveThresholdPercent=65
-XX:G1HeapWastePercent=10
-XX:G1OldCSetRegionThresholdPercent=9
-XX:G1ReservePercent=10

  thriftserver配置参数
-Xmx2g -Xms2g
-XX:+UseG1GC
-XX:+UnlockExperimentalVMOptions
-XX:-OmitStackTraceInFastThrow
-XX:+ParallelRefProcEnabled
-XX:-ResizePLAB
-XX:-UseBiasedLocking
-XX:+SafepointTimeout
-XX:SafepointTimeoutDelay=2000
-XX:G1NewSizePercent=5
-XX:G1MaxNewSizePercent=15
-XX:MaxTenuringThreshold=15
-XX:G1MixedGCCountTarget=16
-XX:MaxGCPauseMillis=200
-XX:ParallelGCThreads=2
-XX:ConcGCThreads=1
-XX:InitiatingHeapOccupancyPercent=45
-XX:G1MixedGCLiveThresholdPercent=65
-XX:G1HeapWastePercent=10
-XX:G1OldCSetRegionThresholdPercent=9
-XX:G1ReservePercent=10

配置文件更改
    hbase.hregion.majorcompaction              major compact 周期默认是7天，一般调成0挑选hbase相对空闲时段然后自己写脚本做合并
    hbase.hstore.blockingStoreFiles            hfile文件数量这里设置成100，如果hfile数量超过这个值的时候写入会受到阻塞    hbase.regionserver.handler.count      regionserver上用于等待响应用户表级请求的线程数
    hbase.hregion.memstore.flush.size 128M     Memstore级别限制：一个region的一个列族memstore大小达到128M促使这个region flush
    hbase.hregion.memstore.block.multiplier 4  Region级别限制：当一个region的所有列族的memstore大小占用128×4的时候促使这个region flush
    hbase.regionserver.global.memstore.size 0.45 regionserver级别flush：当regionserver中所有region的memstore大小占用heap的45%时会根据占用memstore占用region的大小排序，进行flush
    hbase.regionserver.global.memstore.size.lower.limit 0.4    当触发regionserver级别flush时，memstore占用内存小于40%时停止regionserver级别flush
    hbase.hregion.max.filesize 15g             当一个hfile的大小大于15g时会触发split
    hfile.block.cache.size 0.3                 regionserver的读缓存占用heap的30%
```

