# 管理员



|              |                                                              |                                                              |
| ------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| MPP架构      | 多处理器协同执行一个操作、使用系统所有资源并行处理一个查询   |                                                              |
| 追加优化     |                                                              |                                                              |
| interconnect | B默认情况下，Interconnect使用带流控制的用户数据包协议（UDPIFC）在网络上发送消息。 Greenplum软件在UDP之上执行包验证。这意味着其可靠性等效于传输控制协议（TCP）且性能和可扩展性要超过TCP。 如果Interconnect被改为TCP，Greenplum数据库会有1000个Segment实例的可扩展性限制。对于Interconnect的默认协议UDPIFC则不存在这种限制。 | postgresql.conf<br>gp_interconnect_type=udpifc --> gp_interconnect_type=tcp |
| 扩容         | 每个表或分区在扩容期间是无法进行读写操作的                   |                                                              |





| greenplum 对比 | postgres |      |
| -------------- | -------- | ---- |
|                |          |      |
|                |          |      |
|                |          |      |





```
fcopy
```

