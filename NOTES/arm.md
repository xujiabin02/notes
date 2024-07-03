# 国产化迁移

# 代码迁移到arm64踩的坑

https://aijishu.com/a/1060000000328354



## 将 Java 代码从 x86 迁移到 ARM64 主要涉及到确保代码可以在目标硬件平台上正确编译和运行。以下是可能需要考虑的一些步骤：

1. 确保使用的开发工具支持目标平台，例如使用能够编译和打包 ARM64 的 JDK、Gradle、Maven 等等。

2. 重新编译代码以生成 ARM64 体系结构支持的二进制文件，如果有使用本地库（如C/C++库）的话，还需要重新编译该库以支持 ARM64 体系结构。可以使用交叉编译工具进行编译，例如在 x86 计算机上使用 ARM64 工具链进行编译。

3. 如果使用了第三方库，需要确认该库是否支持 ARM64 体系结构，如果不支持需要找到可替代的库或自行进行修改。

4. 进行适当的测试以确保代码在目标硬件平台上运行良好并达到预期的功能和性能要求。

5. 如果代码中使用了硬件相关的操作系统 API，需要修改以适应 ARM64 体系结构和目标操作系统，还需要确保可用的硬件接口在目标平台上存在。

6. 迁移过程中需要注意一些细节问题，例如字节对齐、大小端等等，因为 x86 和 ARM64 的处理器在这些方面存在差异。

在进行代码迁移之前需要对硬件平台、编译工具、第三方库和测试等进行深入了解和调研，确保迁移过程顺利和结果满足预期。



## x86和arm64 的大小端是什么 

大小端（Endianness）是指在计算机内存中多字节的数据类型（如整型、浮点型）存储的字节序列顺序。

在 x86 架构中，采用小端模式（Little Endian），即最低字节存储在最低地址处，最高字节存储在最高地址处。

而在 ARM64 架构中，采用大端模式（Big Endian），即最高字节存储在最低地址处，最低字节存储在最高地址处。

两种不同的大小端方式在存储多字节数据时，数据的字节顺序会不同。如果在不同大小端的机器上传递数据，需要进行相应的转换处理以保证数据的正确性。

在 Java 中，基本类型和对象的序列化和反序列化默认采用的是网络字节序，即大端模式。可以通过设置 ByteOrder 来指定大小端模式。





# mysql问题

https://aijishu.com/a/1060000000321521



# arm docker

https://blog.csdn.net/LG_15011399296/article/details/126119349





| 软件                  | 版本          | 是否需要在arm系统重新编译 | 安装包下载                                                   |
| --------------------- | ------------- | ------------------------- | ------------------------------------------------------------ |
| jdk                   | 1.8.0_241     |                           | https://www.oracle.com/cn/java/technologies/javase/javase-jdk8-downloads.htm |
| golang                | 1.18          |                           | bin                                                          |
| python                | 3             |                           | yum                                                          |
| nodejs                | 10            |                           | bin                                                          |
| docker-ce             | 23.0.1        |                           | yum                                                          |
| chrony                | 4.2           |                           | yum                                                          |
| nfs-server,nfs-client | 1.3.0         |                           | yum                                                          |
| autofs                | 5.0.7         |                           | yum                                                          |
| datax                 |               |                           |                                                              |
| oracle                | 11.2          | 没有arm版本, 不支持       |                                                              |
| redis                 | 6.0           | 是                        |                                                              |
| nginx                 | 1.15.6        | 是                        | http://nginx.org/en/linux_packages.html                      |
| greenplum             | 6.21.3        | 需要自行编译              | https://www.modb.pro/db/45040<br />[doc](https://cn.greenplum.org/greenplum-on-arm/#:~:text=目前Greenplum的二进制发行,Greenplum的ARM发行版%E3%80%82) |
| mysql                 | 8.0           |                           | 官方有提供https://dev.mysql.com/downloads/mysql/             |
| anaconda              | 3             |                           |                                                              |
| zookeeper             | 3             |                           |                                                              |
| kafka                 | 3             |                           |                                                              |
| dolphinscheduler      | 3.1.0         |                           |                                                              |
| grafana               | 8.0           |                           |                                                              |
| prometheus            | 2.19          |                           |                                                              |
| node_exporter         | 1.0           |                           |                                                              |
| greenplum_exporter    |               | 是                        |                                                              |
| doris                 |               | 是                        | https://doris.apache.org/zh-CN/docs/install/source-install/compilation-arm/ |
| kettle                | WebSpoon9.0.0 | 是                        |                                                              |
| helm                  | 3             |                           |                                                              |
| k8s                   | 1.18          |                           |                                                              |
| kvm                   | 7.0           |                           |                                                              |

