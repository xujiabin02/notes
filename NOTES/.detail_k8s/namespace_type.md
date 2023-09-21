

## [Namespace 类型](https://moelove.info/2021/12/10/搞懂容器技术的基石-namespace-上/#contents:namespace-类型)

| namespace名称 | 使用的标识 - Flag | 控制内容                                                     |
| ------------- | ----------------- | ------------------------------------------------------------ |
| Cgroup        | CLONE_NEWCGROUP   | Cgroup root directory cgroup 根目录                          |
| IPC           | CLONE_NEWIPC      | System V IPC, POSIX message queues信号量，消息队列           |
| Network       | CLONE_NEWNET      | Network devices, stacks, ports, etc.网络设备，协议栈，端口等等 |
| Mount         | CLONE_NEWNS       | Mount points挂载点                                           |
| PID           | CLONE_NEWPID      | Process IDs进程号                                            |
| Time          | CLONE_NEWTIME     | 时钟                                                         |
| User          | CLONE_NEWUSER     | 用户和组 ID                                                  |
| UTS           | CLONE_NEWUTS      | 系统主机名和 NIS(Network Information Service) 主机名（有时称为域名） |

### [ link](https://moelove.info/2021/12/10/搞懂容器技术的基石-namespace-上/#contents:cgroup-namespaces)



|                       |                                         |        |
| --------------------- | --------------------------------------- | ------ |
| cgroup Namespace      | 防止信息泄漏, 简化容器迁移,限制进程资源 | docker |
| IPC                   |                                         |        |
| 用户空间  user space  | 独立空间                                |        |
| 内核空间 kernel space | 共用空间寻址                            |        |

