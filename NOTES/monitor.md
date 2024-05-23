# 大规模集群(监控,报警,日志分析查询)

| 日志文本         | 单元行   | 大小  |
| ---------------- | -------- | ----- |
| nginx日志        | 单行     | 283B  |
| spring cloud日志 | 多行堆栈 | 1~7KB |
| golang           | 多行     | 1~5KB |
| syslog,journal   | 单行     | 283B  |
|                  |          |       |





| 硬件配置 | 壁仞                                                         | A800                                                         |
| -------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| CPU：    | 数量 2、主频 2.6GHz、物理核数32C;                            | 2*Intel Xeon Platinum 8358P @2.60GHz 32核                    |
| 内存：   | 数量 16、类型 DDR4 RDIMM、频率3200MHz、容量32GB=1024GB       | 1024GB                                                       |
| ;硬盘：  | 数量 2、类型 SSD、转速、容量960GB;数量 4、类型 SSD、转速、容量3.84TB; | 2*SSD 960G+ 1\*7.68T NVME SSD                                |
| Raid卡： | 数量 1、缓存 2GB、Raid级别RAID 0,RAID 1,RAID 10,RAID 5,RAID 6,RAID 50,RAID 60; | Raid1                                                        |
| 电源     | 4 * 2000W交流&240V高压直流电源模块(GW-R2-白金-轻载高效);     | 4 * 2000W                                                    |
| 网卡     | 2 * 1端口100Gb Infiniband HDR/Ethernet适配卡(支持QSFP56光模块);2端口25Gb SFP28光接口MCX631432AN OCP3.0网卡;H3C服务器首次基础安装服务; | 4\*200Gbps IB计算+2\*200Gbps IB存储主备模式预留+2*10Gbps Eth NIC |
| RDMA     | Roce                                                         | IB                                                           |
| GPU      | 8 * BR BR104P 32GB GPU模块                                   | 8*Nvidia A800 80G SXM + Nvlink                               |



## 如何保证报警

- 及时性
- 有效性
- 可统一调度管理, 比如分组, 合并, 过滤, 抑制

## 如何保证高级查询

- 聚合, 分组, 分布, sla统计, 条件判断, <!--(调用链)-->

- 海量存储

- 周期归档(S3或其他存储)

- 自定义metrics

  

## 如何保障架构承压

- 稳定可扩展

- 高可用

---



# 方案A ||

在采集端计算, 分布存储,分散上报,统一将metrics上报给中心节点(高可用)

- 评估硬件瓶颈,  io, 网络, cpu

- 合理压测评估软件瓶颈
- 采集端/存储端/计算端选型
- 多机房部署, 统一管控



| log collector 分散压力的方案 |                                                              |      |
| ---------------------------- | ------------------------------------------------------------ | ---- |
| ilogtail                     | [性能](https://ilogtail.gitbook.io/ilogtail-docs/benchmark/performance-compare-with-filebeat) |      |
| promtail                     |                                                              |      |
| filebeat(beats家族)          |                                                              |      |
| fluntd                       |                                                              |      |



| 分担prometheus压力的方案                 |      |      |
| ---------------------------------------- | ---- | ---- |
| 维多利亚数据库(Victoria Metrics远程存储) |      |      |
| **thanos多群集(s3存储) operator**        |      |      |
| clickhouse graphite表存储                |      |      |
| 夜莺监控报警telegraf  滴滴团队           |      |      |
|                                          |      |      |



| 日志存储的方案         |      |      |
| ---------------------- | ---- | ---- |
| **clickhouse or tidb** |      |      |
| elasticsearch(graylog) |      |      |
| <!--loki-->            |      |      |
|                        |      |      |



|      | 方案                                                         |      |
| ---- | ------------------------------------------------------------ | ---- |
|      | filebeat graylog(es/mongodb) prometheus alertmanager         |      |
|      | promethues+graphana ,clickhouse + alertmanager,Victoria Metrics远程存储, ilogtail |      |
|      |                                                              |      |
|      |                                                              |      |



# 方案B

各集群独立? 好处是压力分散

坏处是管理麻烦

# 日志ilogtail+clickhouse



## ilogtail压力扩容

## clickhouse压力扩容

从我们测试的过程和结果来看，影响clickhouse写入性能的包括如下因素：

网卡带宽：在使用千兆网卡的情况下，网络很容易成为整个写入测试的瓶颈，一般到80MB/s左右；在换用万兆网卡后，速度可以测到150MB/s~200MB/s以上。
磁盘IO：如果clickhouse只配置了单块儿SATA盘做数据盘，那么磁盘IO也会是提升写入性能的瓶颈所在，建议使用多块儿盘做RAID。
CPU：我们测试使用了24核的服务器，当写入测试程序激励打到150MB/s以上的速度时，整个CPU的使用率会较长时间处于2000%以上。
物化视图：如果写入的表上有相关的物化视图逻辑，那么也会影响到最终的写入性能，因为CPU会将很多计算用在物化视图的处理上，具体影响大小取决于物化视图逻辑的复杂度以及物化视图的数量，从我们自己的项目来看，下降了至少一半的性能。

其它注意事项
对于分布式CH集群的写入，建议写本地表，而不是直接写分布式表，具体原因在于如果写入分布式表，那么写入的那个点容易成为单点故障或瓶颈；写入本地表的话则可以使用chproxy来做代理转发流量，或者自己实现流量的负载均衡。
通过JDBC接口进行写入时，要注意batchSize的调优，太小容易出现“too many parts”的问题，太大又会使整体的写入性能下降，具体的取值可根据实际的环境做调整。
副本的存在对整体写入性能的影响不大。

4. 总结
总体来看，在理想情况下，clickhouse的写入性能能够达到官方宣称的200MB/s左右（https://clickhouse.com/docs/zh/introduction/performance/#shu-ju-de-xie-ru-xing-neng），且总体写入性能还可以通过多分片的方式来进行扩展。这样的表现基本能够满足我们的使用需求。

原文链接：https://blog.csdn.net/weixin_40104766/article/details/121323882

# tidb调研

# 报警 exporter+ custom_metrics + prometheus+alertmanager

## prometheus压力扩容

<!--如何保障api可接自愈-->