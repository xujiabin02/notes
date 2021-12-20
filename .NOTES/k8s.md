|                                                              |                                                              |                                              |
| ------------------------------------------------------------ | ------------------------------------------------------------ | -------------------------------------------- |
| Jenkins,Artifactory&kubernetes                               |                                                              |                                              |
| docker和虚拟机对比                                           |                                                              |                                              |
| 秒级交付                                                     | \|开发效率                                                   | \|提升部署频率                               |
| 2016 OCI开源                                                 |                                                              |                                              |
| 2018 k8s                                                     |                                                              |                                              |
| Moby,Docker CE, Docker EE                                    | moby                                                         | \|tools                                      |
| \|k8s: CE                                                    |                                                              |                                              |
| docker底层                                                   | OCI                                                          |                                              |
| \|runC                                                       | 物理层交互                                                   |                                              |
| \|containerd                                                 |                                                              |                                              |
| 疑问:                                                        | \|如何同时存在2个pid=1的进程                                 |                                              |
| \|限定cpu,内存?                                              |                                                              |                                              |
| \|A,B容器的隔离                                              |                                                              |                                              |
| \|*: Namespace,Control Groups(Cgroup),Union Filesystem()     | NameSpace                                                    | \|uts                                        |
| \|ipc                                                        | 进程间通信                                                   |                                              |
| \|pid                                                        |                                                              |                                              |
| \|network                                                    |                                                              |                                              |
| \|mnt                                                        |                                                              |                                              |
| \|user                                                       |                                                              |                                              |
| 底层原理:Clone() pid=1                                       | Cgroups                                                      | C语言                                        |
| \|对cpu,mem,net限制通过cgroups实现                           |                                                              |                                              |
| \|cpu时钟分配                                                |                                                              |                                              |
| \|task绑定group分配相应资源                                  |                                                              |                                              |
| \|250m, 1/4 Cpu                                              |                                                              |                                              |
| \|CPU 100%                                                   | while:;do:;done &                                            | 阻塞,cgroup可限制到20%                       |
| \|\|cd /sys/fs/cgroup/cpu;mkdir cgroups_test;echo 200000> /sys/fs/cgroup/cpu/cgroups_test/cpu.cfs_quota_us;echo 27358 > task | \|1.13                                                       |                                              |
| \|\|docker run -it --cpus=".5 ubuntu /bin/bash               |                                                              |                                              |
| \|1.12                                                       |                                                              |                                              |
| \|\|docker run -it --cpu-period=100000 --cpu-quota=50000 ubuntu /bin/bash |                                                              |                                              |
| github.com                                                   | opencontainers/runc                                          |                                              |
| \|clone                                                      |                                                              |                                              |
| \|make install                                               |                                                              |                                              |
| \|mkdir /root/mycontainer && cd                              |                                                              |                                              |
| \|mkdir rootfs                                               |                                                              |                                              |
| \|docker export $(docker create busybox)                     | tar -C rootfs -xvf --                                        |                                              |
| \|run spec(generate spec.json)                               |                                                              |                                              |
| \|runc run mycontainerid                                     |                                                              |                                              |
| \|runc list                                                  |                                                              |                                              |
| Unionfs                                                      | rootfs解决系统文件隔离,那么每次都要重复创建rootfs吗          |                                              |
| \|Layer                                                      | 分层,千层饼机制                                              |                                              |
| \|用法                                                       | mount -t unionfs -o dirs=/home/fd1,/tmp/fd2 \ > none /mnt/merged-folder |                                              |
| \|\|-o 目录, none 不挂载驱动, megerd-folder目录包含 fd1,fd2  |                                                              |                                              |
| \|docker info 查看aufs                                       |                                                              |                                              |
| \|v1: 链式存储结构                                           |                                                              |                                              |
| \|v2:                                                        |                                                              |                                              |
| \|manifest                                                   |                                                              |                                              |
| \|.tar 形式文件存储                                          |                                                              |                                              |
| \|.json                                                      |                                                              |                                              |
| Artifactory                                                  | 管理情况完全                                                 |                                              |
| \|可以查看每一层的操作 *                                     |                                                              |                                              |
| Container Network Model(CNM:xxx xxx Model) Drivers           | \|CNM对冲突有仲裁能力, 与CNI区别                             |                                              |
| k8s(CNI:xxx xxx Interface)                                   | 只有2个方法,创建和销毁                                       |                                              |
| \|CNI简单好实现, 与CNM区别                                   |                                                              |                                              |
| Network Namespace                                            | Network Interface,Loopbak Device,Route ,Iptables             |                                              |
| \|思考:容器间如何通信                                        | brighe网桥                                                   |                                              |
| \|云环境下如何通信                                           | flunel,vlan,大2层网络(overlay),Calico                        |                                              |
| \|\|大2层网络实现: Mac in UDP                                |                                                              |                                              |
| \|\|\|封装内网IP和外网IP到UDP包                              |                                                              |                                              |
| \|\|Calico                                                   |                                                              |                                              |
| \|\|\|route Reflector                                        |                                                              |                                              |
| Dockerfile                                                   | BUILD,Both,RUN                                               |                                              |
| \|ONBUILD命令如何使用                                        |                                                              |                                              |
| \|FROM 镜像源                                                |                                                              |                                              |
| \|MAINTAINER 标签                                            |                                                              |                                              |
| \|EXPOSE                                                     |                                                              |                                              |
| \|不建议sshd,直接通过docker接口进入容器,免除安全隐患         | 安全?                                                        |                                              |
| \|可以用来描述一个镜像                                       |                                                              |                                              |
| \|Container Commit                                           |                                                              |                                              |
| Dockerfile结构很重要                                         | \|Layers层数                                                 | 一条命令一个layer, 合并多个命令              |
| \|每层的大小                                                 |                                                              |                                              |
| \|每层的变化                                                 |                                                              |                                              |
| \|安全                                                       | 定义默认用户,not root                                        |                                              |
| \|\|root可操作宿主机?                                        |                                                              |                                              |
| \|\|contain的隔离和安全性                                    |                                                              |                                              |
| \|\|虚拟机上的docker                                         |                                                              |                                              |
| 流水线反模式一                                               | \|Docker多次构建不做升级                                     | 你发布的不是你测试的                         |
| \|一次构建                                                   |                                                              |                                              |
| \|应用和配置分离                                             |                                                              |                                              |
| \|三库分离                                                   | 防误删库                                                     |                                              |
| \|构建效率低,构建资源消耗大                                  |                                                              |                                              |
| 流水线反模式二                                               | 质量关卡                                                     |                                              |
| 自动化测试                                                   | Source code version control                                  |                                              |
| Optimum branching                                            |                                                              |                                              |
| Static analysis                                              |                                                              |                                              |
| > 80% Code coverage                                          |                                                              |                                              |
| Vulnerablility                                               |                                                              |                                              |
| Open source scan                                             |                                                              |                                              |
| Artifact verion contorl                                      |                                                              |                                              |
| Auto provison                                                |                                                              |                                              |
| Immutable servers                                            |                                                              |                                              |
| Integration testing                                          |                                                              |                                              |
| Performance testing                                          |                                                              |                                              |
| Build,Deploy,Testing automated for every commit              |                                                              |                                              |
| Automated Rollback 自动回滚                                  |                                                              |                                              |
| Automated Change Order                                       |                                                              |                                              |
| 基于元数据建立流水线质量关卡                                 |                                                              |                                              |
| Artifact 自动扫描,测试通过率                                 | 安全扫描                                                     | 漏洞 30% Docker                              |
| 11%                                                          |                                                              |                                              |
| 59% maven                                                    |                                                              |                                              |
| 流水线反模式四                                               | 工具链信息碎片化                                             |                                              |
| 全系统记录                                                   |                                                              |                                              |
| 流水线反模式五                                               | 交付物或部署文件无版本化                                     |                                              |
| 基于二进制包交付模型                                         |                                                              |                                              |
| 容器交付                                                     | 痛点:交付多个容器, 没有一个统一环境的版本                    |                                              |
| helm-k8s 官方包管理                                          |                                                              |                                              |
| k8s                                                          | rancher                                                      |                                              |
| secret & configMap                                           | PV(logical)                                                  | 实际持久存储                                 |
| PVC(user)                                                    | 管理员维护storage Class                                      |                                              |
| NFS RBD Glusterfs Quobyte CephFS Cinder FC GCEPersistenteDisk |                                                              |                                              |
| 弹性扩容                                                     | HorizontalPodAutoscaler                                      |                                              |
| Metric Server +                                              |                                                              |                                              |
| docker-compose                                               | 容器编排                                                     |                                              |
| k8s                                                          | Helm Chart                                                   | 安装方式                                     |
| Kubeadm                                                      | 官方安装方式                                                 |                                              |
| swapoof -a                                                   |                                                              |                                              |
| 映射hosts                                                    |                                                              |                                              |
| Minikub                                                      | RKE                                                          | golang 编写的安装,极为简单易用               |
| Pod网络                                                      |                                                              | Calico                                       |
| Flannel                                                      |                                                              |                                              |
| SLB                                                          | 4层,7层转发                                                  |                                              |
| nginx-ingress                                                | 支持4层转发                                                  |                                              |
| haproxy-ingress                                              |                                                              | traefik-ingress                              |
| nodeselector                                                 | 标签/以后可能会废弃,使用 Nodeaffinity                        |                                              |
| Nodeaffinity                                                 | rquired(硬要求)                                              |                                              |
|                                                              | preferred(软)                                                |                                              |
|                                                              | 正则和语法表达式                                             |                                              |
|                                                              | 例: podaffinity(pod和pod交互频繁,调度在同一台主机上)         |                                              |
| k8s日志\事件\监控                                            | events                                                       | get events                                   |
| logs                                                         |                                                              | heapster(早期),metrics Server                |
| metrics server                                               | top                                                          |                                              |
| nodeport,loadbalance,ingress                                 | ingress                                                      | nginx(4,7层),haproxy,traefik                 |
| RBAC(role-based access control)权限管理                      |                                                              | Rights                                       |
| Role                                                         |                                                              | prometheus 使用passwd或token调用 k8s监控数据 |
| prometheus 使用passwd或token调用 k8s监控数据                 |                                                              |                                              |


