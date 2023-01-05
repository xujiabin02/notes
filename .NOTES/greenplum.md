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





[rpm下载](https://network.pivotal.io/products/vmware-tanzu-greenplum#/releases/1193700/file_groups/10395)



```
fcopy
```



# best_practices



A newer version of this documentation is available. Use the version menu above to view the most up-to-date release of the Greenplum 6.x documentation.

# System Configuration

Requirements and best practices for system administrators who are configuring Greenplum Database cluster hosts.

Configuration of the Greenplum Database cluster is usually performed as root.

## Configuring the Timezone

Greenplum Database selects a timezone to use from a set of internally stored PostgreSQL timezones. The available PostgreSQL timezones are taken from the Internet Assigned Numbers Authority (IANA) Time Zone Database, and Greenplum Database updates its list of available timezones as necessary when the IANA database changes for PostgreSQL.

Greenplum selects the timezone by matching a PostgreSQL timezone with the user specified time zone, or the host system time zone if no time zone is configured. For example, when selecting a default timezone, Greenplum uses an algorithm to select a PostgreSQL timezone based on the host system timezone files. If the system timezone includes leap second information, Greenplum Database cannot match the system timezone with a PostgreSQL timezone. In this case, Greenplum Database calculates a "best match" with a PostgreSQL timezone based on information from the host system.

As a best practice, configure Greenplum Database and the host systems to use a known, supported timezone. This sets the timezone for the Greenplum Database master and segment instances, and prevents Greenplum Database from recalculating a "best match" timezone each time the cluster is restarted, using the current system timezone and Greenplum timezone files (which may have been updated from the IANA database since the last restart). Use the gpconfig utility to show and set the Greenplum Database timezone. For example, these commands show the Greenplum Database timezone and set the timezone to US/Pacific.

```
# gpconfig -s TimeZone
# gpconfig -c TimeZone -v 'US/Pacific'
```

You must restart Greenplum Database after changing the timezone. The command gpstop -ra restarts Greenplum Database. The catalog view pg_timezone_names provides Greenplum Database timezone information.

## File System

XFS is the file system used for Greenplum Database data directories. On RHEL/CentOS systems, mount XFS volumes with the following mount options:

```
rw,nodev,noatime,nobarrier,inode64
```

The nobarrier option is not supported on Ubuntu systems. Use only the options:

```
rw,nodev,noatime,inode64
```

## Port Configuration

See the [recommended OS parameter settings](https://gpdb.docs.pivotal.io/6-3/install_guide/prep_os.html#topic3) in the Greenplum Database Installation Guide for further details.

Set up ip_local_port_range so it does not conflict with the Greenplum Database port ranges. For example, setting this range in /etc/sysctl.conf:

```
net.ipv4.ip_local_port_range = 10000  65535
```

you could set the Greenplum Database base port numbers to these values.

```
PORT_BASE = 6000
MIRROR_PORT_BASE = 7000
```

See the [Recommended OS Parameters Settings](https://gpdb.docs.pivotal.io/6-3/install_guide/prep_os.html#topic3) in the Greenplum Database Installation Guide for further details.

## I/O Configuration

Set the blockdev read-ahead size to 16384 on the devices that contain data directories. This command sets the read-ahead size for /dev/sdb.

```
# /sbin/blockdev --setra 16384 /dev/sdb
```

This command returns the read-ahead size for /dev/sdb.

```
# /sbin/blockdev --getra /dev/sdb
16384
```

See the [Recommended OS Parameters Settings](https://gpdb.docs.pivotal.io/6-3/install_guide/prep_os.html#topic3) in the Greenplum Database Installation Guide for further details.

The deadline IO scheduler should be set for all data directory devices.

```
 # cat /sys/block/sdb/queue/scheduler
 noop anticipatory [deadline] cfq 
```

The maximum number of OS files and processes should be increased in the /etc/security/limits.conf file.

```
* soft  nofile 524288
* hard  nofile 524288
* soft  nproc 131072
* hard  nproc 131072
```

Enable core files output to a known location and make sure limits.conf allows core files.

```
kernel.core_pattern = /var/core/core.%h.%t
# grep core /etc/security/limits.conf  
* soft  core unlimited
```

## OS Memory Configuration

The Linux sysctl vm.overcommit_memory and vm.overcommit_ratio variables affect how the operating system manages memory allocation. See the [/etc/sysctl.conf](https://gpdb.docs.pivotal.io/6-3/install_guide/prep_os.html#topic3__sysctl_file) file parameters guidelines in the Greenplum Datatabase Installation Guide for further details.

vm.overcommit_memory determines the method the OS uses for determining how much memory can be allocated to processes. This should be always set to 2, which is the only safe setting for the database.

Note: For information on configuration of overcommit memory, refer to:

- [https://en.wikipedia.org/wiki/Memory_overcommitment](https://www.google.com/url?q=https://en.wikipedia.org/wiki/Memory_overcommitment&sa=D&ust=1499719618717000&usg=AFQjCNErcHO7vErv4pn9fIhCxrR0XRiknA)
- [https://www.kernel.org/doc/Documentation/vm/overcommit-accounting](https://www.google.com/url?q=https://www.kernel.org/doc/Documentation/vm/overcommit-accounting&sa=D&ust=1499719618717000&usg=AFQjCNEmu5tZutAaN1KCSlIwz4hwqihkOQ)

vm.overcommit_ratio is the percent of RAM that is used for application processes. The default is 50 on Red Hat Enterprise Linux. See [Resource Queue Segment Memory Configuration](https://gpdb.docs.pivotal.io/6-3/best_practices/sysconfig.html#topic_dt3_fkv_r4__segment_mem_config) for a formula to calculate an optimal value.

Do not enable huge pages in the operating system.

See also [Memory and Resource Management with Resource Queues](https://gpdb.docs.pivotal.io/6-3/best_practices/workloads.html#topic_hhc_z5w_r4).

## Shared Memory Settings

Greenplum Database uses shared memory to communicate between postgres processes that are part of the same postgres instance. The following shared memory settings should be set in sysctl and are rarely modified. See the [sysctl.conf ](https://gpdb.docs.pivotal.io/6-3/install_guide/prep_os.html#topic3__sysctl_file)file parameters in the Greenplum Database Installation Guide for further details.

```
kernel.shmmax = 500000000
kernel.shmmni = 4096
kernel.shmall = 4000000000
```

## Number of Segments per Host

Determining the number of segments to execute on each segment host has immense impact on overall system performance. The segments share the host's CPU cores, memory, and NICs with each other and with other processes running on the host. Over-estimating the number of segments a server can accommodate is a common cause of suboptimal performance.

The factors that must be considered when choosing how many segments to run per host include the following:

- Number of cores
- Amount of physical RAM installed in the server
- Number of NICs
- Amount of storage attached to server
- Mixture of primary and mirror segments
- ETL processes that will run on the hosts
- Non-Greenplum processes running on the hosts

## Resource Queue Segment Memory Configuration

The gp_vmem_protect_limit server configuration parameter specifies the amount of memory that all active postgres processes for a single segment can consume at any given time. Queries that exceed this amount will fail. Use the following calculations to estimate a safe value for gp_vmem_protect_limit.

1. Calculate

    

   gp_vmem

   , the host memory available to Greenplum Database, using this formula:

   ```
   gp_vmem = ((SWAP + RAM) – (7.5GB + 0.05 * RAM)) / 1.7
   ```

   where

    

   SWAP

    

   is the host's swap space in GB and

    

   RAM

    

   is the RAM installed on the host in GB.

2. Calculate max_acting_primary_segments. This is the maximum number of primary segments that can be running on a host when mirror segments are activated due to a segment or host failure on another host in the cluster. With mirrors arranged in a 4-host block with 8 primary segments per host, for example, a single segment host failure would activate two or three mirror segments on each remaining host in the failed host's block. The max_acting_primary_segments value for this configuration is 11 (8 primary segments plus 3 mirrors activated on failure).

3. Calculate

    

   gp_vmem_protect_limit

    

   by dividing the total Greenplum Database memory by the maximum number of acting primaries:

   ```
   gp_vmem_protect_limit = gp_vmem / max_acting_primary_segments
   ```

   Convert to megabytes to find the value to set for the

    

   gp_vmem_protect_limit

    

   system configuration parameter.

For scenarios where a large number of workfiles are generated, adjust the calculation for gp_vmem to account for the workfiles:

```
gp_vmem = ((SWAP + RAM) – (7.5GB + 0.05 * RAM - (300KB * total_#_workfiles))) / 1.7
```

For information about monitoring and managing workfile usage, see the *Greenplum Database Administrator Guide*.

You can calculate the value of the vm.overcommit_ratio operating system parameter from the value of gp_vmem:

```
vm.overcommit_ratio = (RAM - 0.026 * gp_vmem) / RAM
```

See [OS Memory Configuration](https://gpdb.docs.pivotal.io/6-3/best_practices/sysconfig.html#topic_dt3_fkv_r4__os_mem_config) for more about about vm.overcommit_ratio.

See also [Memory and Resource Management with Resource Queues](https://gpdb.docs.pivotal.io/6-3/best_practices/workloads.html#topic_hhc_z5w_r4).

## Resource Queue Statement Memory Configuration

The statement_mem server configuration parameter is the amount of memory to be allocated to any single query in a segment database. If a statement requires additional memory it will spill to disk. Calculate the value for statement_mem with the following formula:

(gp_vmem_protect_limit * .9) / max_expected_concurrent_queries

For example, for 40 concurrent queries with gp_vmem_protect_limit set to 8GB (8192MB), the calculation for statement_mem would be:

(8192MB * .9) / 40 = 184MB

Each query would be allowed 184MB of memory before it must spill to disk.

To increase statement_mem safely you must either increase gp_vmem_protect_limit or reduce the number of concurrent queries. To increase gp_vmem_protect_limit, you must add physical RAM and/or swap space, or reduce the number of segments per host.

Note that adding segment hosts to the cluster cannot help out-of-memory errors unless you use the additional hosts to decrease the number of segments per host.

Spill files are created when there is not enough memory to fit all the mapper output, usually when 80% of the buffer space is occupied.

Also, see [Resource Management](https://gpdb.docs.pivotal.io/6-3/best_practices/workloads.html#topic_hhc_z5w_r4) for best practices for managing query memory using resource queues.

## Resource Queue Spill File Configuration

Greenplum Database creates *spill files* (also called *workfiles*) on disk if a query is allocated insufficient memory to execute in memory. A single query can create no more than 100,000 spill files, by default, which is sufficient for the majority of queries.

You can control the maximum number of spill files created per query and per segment with the configuration parameter gp_workfile_limit_files_per_query. Set the parameter to 0 to allow queries to create an unlimited number of spill files. Limiting the number of spill files permitted prevents run-away queries from disrupting the system.

A query could generate a large number of spill files if not enough memory is allocated to it or if data skew is present in the queried data. If a query creates more than the specified number of spill files, Greenplum Database returns this error:

ERROR: number of workfiles per query limit exceeded

Before raising the gp_workfile_limit_files_per_query, try reducing the number of spill files by changing the query, changing the data distribution, or changing the memory configuration.

The gp_toolkit schema includes views that allow you to see information about all the queries that are currently using spill files. This information can be used for troubleshooting and for tuning queries:

- The gp_workfile_entries view contains one row for each operator using disk space for workfiles on a segment at the current time. See [How to Read Explain Plans](https://gpdb.docs.pivotal.io/6-3/best_practices/tuning_queries.html#reading_explain_plan)for information about operators.
- The gp_workfile_usage_per_query view contains one row for each query using disk space for workfiles on a segment at the current time.
- The gp_workfile_usage_per_segment view contains one row for each segment. Each row displays the total amount of disk space used for workfiles on the segment at the current time.

See the *Greenplum Database Reference Guide* for descriptions of the columns in these views.

The gp_workfile_compression configuration parameter specifies whether the spill files are compressed. It is off by default. Enabling compression can improve performance when spill files are used.

**Parent topic:** [Greenplum Database Best Practices](https://gpdb.docs.pivotal.io/6-3/best_practices/intro.html)







https://blog.csdn.net/Explorren/article/details/103636287

https://blog.51cto.com/michaelkang/2170608

https://www.cnblogs.com/zsql/p/14602612.html





# 监控



https://cloud.tencent.com/developer/article/1822708



