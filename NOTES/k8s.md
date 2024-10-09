# k8s

|                             |      |      |
| --------------------------- | ---- | ---- |
| [CRD](./CRD.md)             |      |      |
| [operator](./operator.md)   |      |      |
| [多region](./region_k8s.md) |      |      |

## ulimit,  sysctl.conf

```shell
fs.file-max = 2097152
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 512
```



## calico更改首选网卡

```yaml
        - name: IP_AUTODETECTION_METHOD
          value: interface=eth0|en0|en2
```



# 链表添加白名单

在 Kubernetes 中，`iptables` 规则和链的优先级关系取决于它们的作用位置和调用顺序。不同的 `iptables` 链在流量进入节点、在节点间转发以及从节点发出时起作用。理解这些链之间的关系有助于确定流量通过防火墙规则时的路径和优先级。

### 核心`iptables`链

- **INPUT**：处理进入本地节点的流量。
- **FORWARD**：处理通过本地节点转发的流量。
- **OUTPUT**：处理从本地节点发出的流量。

### Kubernetes 特定链

- **KUBE-EXTERNAL-SERVICES**：主要处理通过 `LoadBalancer` 类型服务暴露的外部服务流量。
- **KUBE-FIREWALL**：用于防火墙规则，控制访问 Kubernetes 服务的流量。
- **KUBE-FORWARD**：确保转发的流量遵循 Kubernetes 网络策略。
- **KUBE-KUBELET-CANARY**：由 kubelet 用于检测和管理连接。
- **KUBE-NODEPORTS**：处理通过 `NodePort` 类型服务暴露的端口。
- **KUBE-PROXY-CANARY**：kube-proxy 用于检测和管理服务变化。
- **KUBE-PROXY-FIREWALL**：kube-proxy 用于配置防火墙规则，确保服务间的连接安全。
- **KUBE-SERVICES**：处理 Kubernetes 服务的流量，通过服务 IP 和端口映射到后端 Pod。

### Calico 相关链

Calico 是常用的 Kubernetes 网络插件，它在 `iptables` 中加入许多链来实施网络策略和安全功能。

- **cali-FORWARD**：处理由 Calico 管理的转发流量。
- **cali-INPUT**：处理由 Calico 管理的进入流量。
- **cali-OUTPUT**：处理由 Calico 管理的流出流量。
- 其他 `cali-` 前缀的链（例如 `cali-from-wl-dispatch`, `cali-to-host-endpoint` 等）用于特定的网络策略和安全规则。

### 链之间的优先级和关系

#### 核心链优先级

- 流量进入节点：`PREROUTING` -> `INPUT` 或 `FORWARD`（取决于流量的目标）。
- 流量离开节点：`OUTPUT` -> `POSTROUTING`。
- 节点间转发的流量：`FORWARD`。

#### Kubernetes 链优先级

- `KUBE-SERVICES` 和 `KUBE-NODEPORTS` 链常在 `PREROUTING` 和 `OUTPUT` 链中被调用，以处理服务的 DNAT 和 SNAT。
- `KUBE-FIREWALL` 和 `KUBE-PROXY-FIREWALL` 链用于防火墙规则，通常在 `FORWARD` 链中被调用。
- `KUBE-FORWARD` 确保转发的流量遵循 Kubernetes 网络策略，通常在 `FORWARD` 链中被调用。

#### Calico 链优先级

- `cali-INPUT` 和 `cali-OUTPUT` 链分别在 `INPUT` 和 `OUTPUT` 链中处理由 Calico 管理的流量。
- `cali-FORWARD` 链在 `FORWARD` 链中处理转发流量。
- 其他 Calico 链则在上述主链（`cali-INPUT`, `cali-OUTPUT`, `cali-FORWARD`）中被调用，用于具体的网络策略实现。

### 简化示例：流量进入 NodePort 服务

1. **流量进入本地节点**：首先，通过 `PREROUTING` 链，然后到 `INPUT` 链。
2. **经过 Kubernetes 链处理**：
   - 流量匹配到 NodePort 服务时，通过 `KUBE-NODEPORTS` 链。
   - 检查 Kubernetes 防火墙规则，通过 `KUBE-FIREWALL` 链。
3. **经过 Calico 链处理**（如果使用 Calico）：
   - 流量经过 `cali-INPUT` 链。
   - 根据具体策略，可能经过其他 `cali-` 链。

### 实际应用：添加白名单

为了控制对特定 NodePort 服务的访问，我们通常在 `INPUT` 链添加规则，因为这是处理进入本地节点流量的第一个链。

```sh
# 允许特定IP访问NodePort
sudo iptables -A INPUT -p tcp --dport 30001 -s 192.168.1.100 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 30001 -s 192.168.1.101 -j ACCEPT

# 拒绝所有其他IP访问NodePort
sudo iptables -A INPUT -p tcp --dport 30001 -j DROP

# 保存规则
sudo service iptables save  # 对于CentOS/RHEL
sudo sh -c "iptables-save > /etc/iptables/rules.v4"  # 对于Ubuntu/Debian
```

### 高级配置：考虑其他链

在某些情况下，您可能需要在 Calico 或 Kubernetes 链中添加规则。如果您使用 Calico，并且需要更复杂的网络策略控制，您可能会调整 `cali-INPUT`, `cali-FORWARD`, 或 `cali-OUTPUT` 链。

例如：

```sh
sudo iptables -A cali-INPUT -p tcp --dport 30001 -s 192.168.1.100 -j ACCEPT
sudo iptables -A cali-INPUT -p tcp --dport 30001 -s 192.168.1.101 -j ACCEPT
sudo iptables -A cali-INPUT -p tcp --dport 30001 -j DROP
```

总结来说，不同的 `iptables` 链在处理流量时的调用顺序和优先级对于流量控制至关重要。理解这些链的关系可以帮助您正确配置防火墙规则以实现安全访问控制。对于大多数 NodePort 访问控制需求，在 `INPUT` 链中添加白名单规则是最直接和有效的方式。

# cluster-api

https://zhuanlan.zhihu.com/p/450835027

https://kind.sigs.k8s.io/docs/user/quick-start/

# 批量查看image版本

```shell
kubectl get pods -n <namespace> -o=jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[*].image}{"\n"}'
```



# 清理失败的pods

1. **查看Evicted的Pod**： 使用以下命令列出所有Evicted状态的Pod：

   ```sh
   kubectl get pods --field-selector=status.phase=Failed
   ```

2. **删除Evicted的Pod**： 一旦确定了需要清理的Pod，你可以使用 `kubectl delete` 命令删除它们，例如：

   ```sh
   kubectl delete pod <pod_name>
   ```

   或者，如果你想删除所有Evicted状态的Pod，你可以使用：

   ```sh
   kubectl delete pods --field-selector=status.phase=Failed
   ```

3. **调整资源配置**： 如果你发现Pod频繁Evicted，可能是因为集群资源不足。你可以考虑调整Pod的资源请求和限制，或者调整集群的资源配置，以确保Pod有足够的资源来运行。

4. **排查原因**： 最后，要确保不断出现Evicted的问题得到解决，你可能需要排查造成Pod被终止的具体原因。这可能涉及查看事件、日志以及系统资源使用情况等方面的信息。

# storageclass

http://www.lishuai.fun/2021/12/31/k8s-pv-s3/#/安装

https://zjj2wry.github.io/post/kubes/storage-hostpath-nfs/

[k8s-s3](https://www.bboy.app/2023/05/11/使用k8s-csi-s3加minio作为你的k8s存储%2f)

# configmap

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "datamp.frontend.fullname" . }}
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "datamp.frontend.labels" . | nindent 4 }}
data:
  data-mp.conf: |-
    {{ range .Files.Lines "data-mp.conf" }}
    {{- . }}
    {{ end }}

```



# k8s pullPolicy

```

```



# volumes

subPath[为文件时](https://www.cnblogs.com/liugp/p/16651760.html)

```

```



# entrypoint

docker run

```
--entrypoint /bin/bash
```

k8s job container spec

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: command-demo
  labels:
    purpose: demonstrate-command
spec:
  containers:
  - name: command-demo-container
    image: debian
    command: ["printenv"]
    args: ["HOSTNAME", "KUBERNETES_PORT"]
  restartPolicy: OnFailure
```

**Note:** The `command` field corresponds to `entrypoint` in some container runtimes.

# storageClass NFS



# volumeClaimTemplates



# Charts



|                        |                             |                       |
| ---------------------- | --------------------------- | --------------------- |
| pv,                    | 存储资源,可以是本地或网络卷 | secret,configmap      |
| pvc                    |                             |                       |
| storageclass           |                             |                       |
| csi                    | 存储接口                    | rancher.io/local-path |
| local-path-provisioner |                             |                       |
| choose storageclass    |                             |                       |



# kubectl config

[kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-macos/)

[helm](https://github.com/helm/helm/releases)

```sh
mkdir -p ~/.kube
# vi ~/.kubeconfig
chmod o-r ~/.kube/config
chmod g-r ~/.kube/config
./helm list
```



# jfrog vs k8s

|                                                              |                                                              |                                              |
| ------------------------------------------------------------ | ------------------------------------------------------------ | -------------------------------------------- |
| Jenkins,Artifactory&kubernetes                               |                                                              |                                              |
| docker和虚拟机对比                                           |                                                              |                                              |
| 秒级交付                                                     | 开发效率                                                     | 提升部署频率                                 |
| 2016 OCI开源                                                 |                                                              |                                              |
| 2018 k8s                                                     |                                                              |                                              |
| Moby,Docker CE, Docker EE                                    | moby                                                         | tools                                        |
| k8s: CE                                                      |                                                              |                                              |
| docker底层                                                   | OCI                                                          |                                              |
| runC                                                         | 物理层交互                                                   |                                              |
| containerd                                                   |                                                              |                                              |
| 疑问:                                                        | 如何同时存在2个pid=1的进程                                   |                                              |
| 限定cpu,内存?                                                |                                                              |                                              |
| A,B容器的隔离                                                |                                                              |                                              |
| *: Namespace,Control Groups(Cgroup),Union Filesystem()       | NameSpace                                                    | uts                                          |
| ipc                                                          | 进程间通信                                                   |                                              |
| pid                                                          |                                                              |                                              |
| network                                                      |                                                              |                                              |
| mnt                                                          |                                                              |                                              |
| user                                                         |                                                              |                                              |
| 底层原理:Clone() pid=1                                       | Cgroups                                                      | C语言                                        |
| 对cpu,mem,net限制通过cgroups实现                             |                                                              |                                              |
| cpu时钟分配                                                  |                                                              |                                              |
| task绑定group分配相应资源                                    |                                                              |                                              |
| 250m, 1/4 Cpu                                                |                                                              |                                              |
| CPU 100%                                                     | while:;do:;done &                                            | 阻塞,cgroup可限制到20%                       |
| cd /sys/fs/cgroup/cpu;mkdir cgroups_test;echo 200000> /sys/fs/cgroup/cpu/cgroups_test/cpu.cfs_quota_us;echo 27358 > task | 1.13                                                         |                                              |
| docker run -it --cpus=".5 ubuntu /bin/bash                   |                                                              |                                              |
| 1.12                                                         |                                                              |                                              |
| docker run -it --cpu-period=100000 --cpu-quota=50000 ubuntu /bin/bash |                                                              |                                              |
| github.com                                                   | opencontainers/runc                                          |                                              |
| clone                                                        |                                                              |                                              |
| make install                                                 |                                                              |                                              |
| mkdir /root/mycontainer && cd                                |                                                              |                                              |
| mkdir rootfs                                                 |                                                              |                                              |
| docker export $(docker create busybox)                       | tar -C rootfs -xvf --                                        |                                              |
| run spec(generate spec.json)                                 |                                                              |                                              |
| runc run mycontainerid                                       |                                                              |                                              |
| runc list                                                    |                                                              |                                              |
| Unionfs                                                      | rootfs解决系统文件隔离,那么每次都要重复创建rootfs吗          |                                              |
| Layer                                                        | 分层,千层饼机制                                              |                                              |
| 用法                                                         | mount -t unionfs -o dirs=/home/fd1,/tmp/fd2  > none /mnt/merged-folder |                                              |
| -o 目录, none 不挂载驱动, megerd-folder目录包含 fd1,fd2      |                                                              |                                              |
| docker info 查看aufs                                         |                                                              |                                              |
| v1: 链式存储结构                                             |                                                              |                                              |
| v2:                                                          |                                                              |                                              |
| manifest                                                     |                                                              |                                              |
| .tar 形式文件存储                                            |                                                              |                                              |
| .json                                                        |                                                              |                                              |
| Artifactory                                                  | 管理情况完全                                                 |                                              |
| 可以查看每一层的操作 *                                       |                                                              |                                              |
| Container Network Model(CNM:xxx xxx Model) Drivers           | CNM对冲突有仲裁能力, 与CNI区别                               |                                              |
| k8s(CNI:xxx xxx Interface)                                   | 只有2个方法,创建和销毁                                       |                                              |
| CNI简单好实现, 与CNM区别                                     |                                                              |                                              |
| Network Namespace                                            | Network Interface,Loopbak Device,Route ,Iptables             |                                              |
| 思考:容器间如何通信                                          | brighe网桥                                                   |                                              |
| 云环境下如何通信                                             | flunel,vlan,大2层网络(overlay),Calico                        |                                              |
| 大2层网络实现: Mac in UDP                                    |                                                              |                                              |
| 封装内网IP和外网IP到UDP包                                    |                                                              |                                              |
| Calico                                                       |                                                              |                                              |
| route Reflector                                              |                                                              |                                              |
| Dockerfile                                                   | BUILD,Both,RUN                                               |                                              |
| ONBUILD命令如何使用                                          |                                                              |                                              |
| FROM 镜像源                                                  |                                                              |                                              |
| MAINTAINER 标签                                              |                                                              |                                              |
| EXPOSE                                                       |                                                              |                                              |
| 不建议sshd,直接通过docker接口进入容器,免除安全隐患           | 安全?                                                        |                                              |
| 可以用来描述一个镜像                                         |                                                              |                                              |
| Container Commit                                             |                                                              |                                              |
| Dockerfile结构很重要                                         | Layers层数                                                   | 一条命令一个layer, 合并多个命令              |
| 每层的大小                                                   |                                                              |                                              |
| 每层的变化                                                   |                                                              |                                              |
| 安全                                                         | 定义默认用户,not root                                        |                                              |
| root可操作宿主机?                                            |                                                              |                                              |
| contain的隔离和安全性                                        |                                                              |                                              |
| 虚拟机上的docker                                             |                                                              |                                              |
| 流水线反模式一                                               | Docker多次构建不做升级                                       | 你发布的不是你测试的                         |
| 一次构建                                                     |                                                              |                                              |
| 应用和配置分离                                               |                                                              |                                              |
| 三库分离                                                     | 防误删库                                                     |                                              |
| 构建效率低,构建资源消耗大                                    |                                                              |                                              |
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
| k8s日志事件监控                                              | events                                                       | get events                                   |
| logs                                                         |                                                              | heapster(早期),metrics Server                |
| metrics server                                               | top                                                          |                                              |
| nodeport,loadbalance,ingress                                 | ingress                                                      | nginx(4,7层),haproxy,traefik                 |
| RBAC(role-based access control)权限管理                      |                                                              | Rights                                       |
| Role                                                         |                                                              | prometheus 使用passwd或token调用 k8s监控数据 |
| prometheus 使用passwd或token调用 k8s监控数据                 |                                                              |                                              |
| [namespace<!--上-->](https://moelove.info/2021/12/10/%E6%90%9E%E6%87%82%E5%AE%B9%E5%99%A8%E6%8A%80%E6%9C%AF%E7%9A%84%E5%9F%BA%E7%9F%B3-namespace-%E4%B8%8A/) |                                                              |                                              |
| 容器                                                         | 资源隔离和限制,依赖是cgroup, namespace技术                   | docker,container容器化技术                   |
| namespace                                                    | [namespace_type](.detail_k8s/namespace_type)                 |                                              |
| namespace类型                                                |                                                              |                                              |
| [namespace<!--下-->](https://moelove.info/2021/12/13/%E6%90%9E%E6%87%82%E5%AE%B9%E5%99%A8%E6%8A%80%E6%9C%AF%E7%9A%84%E5%9F%BA%E7%9F%B3-namespace-%E4%B8%8B/) |                                                              |                                              |





---

zabbix host: 1896









# [慢调用](https://my.oschina.net/u/3874284/blog/5334851)