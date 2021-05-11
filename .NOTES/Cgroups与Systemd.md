# Cgroups 与 Systemd

Cgroups 是 linux 内核提供的一种机制，如果你还不了解 cgroups，请参考前文《Linux cgroups 简介》先了解 cgroups。当 Linux 的 init 系统发展到 systemd 之后，systemd 与 cgroups 发生了融合(或者说 systemd 提供了 cgroups 的使用和管理接口，systemd 管的东西越来越多啊！)。本文将简单的介绍 cgroups 与 systemd 的关系以及如何通过 systemd 来配置和使用 cgroups。

## Systemd 依赖 cgroups

要理解 systemd 与 cgroups 的关系，我们需要先区分 cgroups 的两个方面：**层级结构(A)和资源控制(B)**。首先 cgroups 是以层级结构组织并标识进程的一种方式，同时它也是在该层级结构上执行资源限制的一种方式。我们简单的把 cgroups 的层级结构称为 A，把 cgrpups 的资源控制能力称为 B。
对于 systemd 来说，A 是必须的，如果没有 A，systemd 将不能很好的工作。而 B 则是可选的，如果你不需要对资源进行控制，那么在编译 Linux 内核时完全可以去掉 B 相关的编译选项。

## Systemd 默认挂载的 cgroups 系统

在系统的开机阶段，systemd 会把支持的 controllers (subsystem 子系统)挂载到默认的 /sys/fs/cgroup/ 目录下面：

![img](.img_Cgroups%E4%B8%8ESystemd/952033-20180823130743557-1997390453.png)

除了 systemd 目录外，其它目录都是对应的 subsystem。
/sys/fs/cgroup/systemd 目录是 systemd 维护的自己使用的非 subsystem 的 cgroups 层级结构。这玩意儿是 systemd 自己使用的，换句话说就是，并不允许其它的程序动这个目录下的内容。其实 /sys/fs/cgroup/systemd 目录对应的 cgroups 层级结构就是 systemd 用来使用 cgoups 中 feature A 的。

## Cgroup 的默认层级

***\*通过将 cgroup 层级系统与 systemd unit 树绑定，systemd 可以把资源管理的设置从进程级别移至应用程序级别。因此，我们可以使用 systemctl 指令，或者通过修改 systemd unit 的配置文件来管理 unit 相关的资源。\****

默认情况下，systemd 会自动创建 **slice、scope 和 service** unit 的层级(slice、scope 和 service 都是 systemd 的 unit 类型，参考《初识 systemd》)，来为 cgroup 树提供统一的层级结构。

系统中运行的所有进程，都是 systemd init 进程的子进程。在资源管控方面，systemd 提供了三种 unit 类型：

* **service**： 一个或一组进程，由 systemd 依据 unit 配置文件启动。service 对指定进程进行封装，这样进程可以作为一个整体被启动或终止。
* **scope**：一组外部创建的进程。由进程通过 fork() 函数启动和终止、之后被 systemd 在运行时注册的进程，scope 会将其封装。例如：用户会话、 容器和虚拟机被认为是 scope。
* **slice**： 一组按层级排列的 unit。slice 并不包含进程，但会组建一个层级，并将 scope 和 service 都放置其中。真正的进程包含在 scope 或 service 中。在这一被划分层级的树中，每一个 slice 单位的名字对应通向层级中一个位置的路径。

我们可以通过 systemd-cgls 命令来查看 cgroups 的层级结构：

![img](.img_Cgroups%E4%B8%8ESystemd/952033-20180823131017742-1678068928.png)

service、scope 和 slice unit 被直接映射到 cgroup 树中的对象。当这些 unit 被激活时，它们会直接一一映射到由 unit 名建立的 cgroup 路径中。例如，cron.service 属于 system.slice，会直接映射到 cgroup system.slice/cron.service/ 中。
注意，所有的用户会话、虚拟机和容器进程会被自动放置在一个单独的 scope 单元中。

默认情况下，系统会创建四种 slice：

* **-.slice**：根 slice
* **system.slice**：所有系统 service 的默认位置
* **user.slice**：所有用户会话的默认位置
* **machine.slice**：所有虚拟机和 Linux 容器的默认位置

![img](.img_Cgroups%E4%B8%8ESystemd/952033-20180823131113206-221768286.png)

## 创建临时的 cgroup

对资源管理的设置可以是 transient(临时的)，也可以是 persistent (永久的)。我们先来介绍如何创建临时的 cgroup。
需要使用 **systemd-run** 命令创建临时的 cgroup，它可以创建并启动临时的 service 或 scope unit，并在此 unit 中运行程序。systemd-run 命令默认创建 service 类型的 unit，比如我们创建名称为 toptest 的 service 运行 top 命令：

```
$ sudo systemd-run --unit=toptest --slice=test top -b
```

![img](.img_Cgroups%E4%B8%8ESystemd/952033-20180823131159461-1892745094.png)

然后查看一下 test.slice 的状态：

![img](.img_Cgroups%E4%B8%8ESystemd/952033-20180823131228961-1237320192.png)

创建了一个 test.slice/toptest.service cgroup 层级关系。再看看 toptest.service 的状态：

![img](.img_Cgroups%E4%B8%8ESystemd/952033-20180823131304063-341445145.png)

top 命令被包装成一个 service 运行在后台了！

接下来我们就可以通过 systemctl 命令来限制 toptest.service 的资源了。在限制前让我们先来看一看 top 进程的 cgroup 信息：

```sh
$ vim /proc/2850/cgroup           # 2850 为 top 进程的 PID
```

![img](.img_Cgroups%E4%B8%8ESystemd/952033-20180823131342379-1555108521.png)

比如我们限制 toptest.service 的 CPUShares 为 600，可用内存的上限为 550M：

```sh
$ sudo systemctl set-property toptest.service CPUShares=600 MemoryLimit=500M
```

再次检查 top 进程的 cgroup 信息：

![img](.img_Cgroups%E4%B8%8ESystemd/952033-20180823131411569-937500515.png)

在 CPU 和 memory 子系统中都出现了 toptest.service 的名字。同时去查看 **/sys/fs/cgroup/memory/test.slice** 和 **/sys/fs/cgroup/cpu/test.slice** 目录，这两个目录下都多出了一个 toptest.service 目录。我们设置的 CPUShares=600 MemoryLimit=500M 被分别写入了这些目录下的对应文件中。

**临时 cgroup 的特征是，所包含的进程一旦结束，临时 cgroup 就会被自动释放。**比如我们 kill 掉 top 进程，然后再查看 /sys/fs/cgroup/memory/test.slice 和 /sys/fs/cgroup/cpu/test.slice 目录，刚才的 toptest.service 目录已经不见了。

# 通过配置文件修改 cgroup

所有被 systemd 监管的 persistent cgroup(持久的 cgroup)都在 /usr/lib/systemd/system/ 目录中有一个 unit 配置文件。比如我们常见的 service 类型 unit 的配置文件。我们可以通过设置 unit 配置文件来控制应用程序的资源，persistent cgroup 的特点是即便系统重启，相关配置也会被保留。需要注意的是，scope unit 不能以此方式创建。下面让我们为 cron.service 添加 CPU 和内存相关的一些限制，编辑 /lib/systemd/system/cron.service 文件：

```sh
$ sudo vim  /lib/systemd/system/cron.service
```

![img](.img_Cgroups%E4%B8%8ESystemd/952033-20180823131520767-1889089953.png)

添加红框中的行，然后重新加载配置文件并重启 cron.service：

```sh
$ sudo systemctl daemon-reload
$ sudo systemctl restart cron.service
```

现在去查看 /sys/fs/cgroup/memory/system.slice/cron.service/memory.limit_in_bytes 和 /sys/fs/cgroup/cpu/system.slice/cron.service/cpu.shares 文件，是不是已经包含我们配置的内容了！

## 通过 systemctl 命令修改 cgroup

除了编辑 unit 的配置文件，还可以通过 systemctl set-property 命令来修改 cgroup，这种方式修该的配置也会在重启系统时保存下来。现在我们把 cron.service 的 CPUShares 改为 700：

```sh
$ sudo systemctl set-property cron.service CPUShares=700
```

查看 /sys/fs/cgroup/cpu/system.slice/cron.service/cpu.shares 文件的内容应该是 700，重启系统后该文件的内容还是 700。

## Systemd-cgtop 命令

类似于 top 命令，systemd-cgtop 命令显示 cgoups 的实时资源消耗情况：

![img](.img_Cgroups%E4%B8%8ESystemd/952033-20180823131633738-438950908.png)

通过它我们就可以分析应用使用资源的情况。

## 总结

Systemd 是一个强大的 init 系统，它甚至为我们使用 cgorups 提供了便利！Systemd 提供的内在机制、默认设置和相关的操控命令降低了配置和使用 cgroups 的难度，即便是 Linux 新手，也能轻松的使用 cgroups 了。

***\*参考：\****
The New Control Group Interfaces
systemd for Administrators, Part XVIII
Control Groups vs. Control Groups
RedHat Cgroups doc
Systemd-cgls
Systemd-cgtop





https://fuckcloudnative.io/posts/understanding-cgroups-part-3-memory/

# Linux Cgroup 入门教程：内存

### 通过 cgroup 控制内存的使用

📅 2019年07月25日 · ☕ 5 分钟 · ✍️ 米开朗基杨· 👀1,074 阅读

* 🏷️

* [#linux](https://fuckcloudnative.io/tags/linux/)
* [#cgroup](https://fuckcloudnative.io/tags/cgroup/)

该系列文章总共分为三篇：

* [Linux Cgroup 入门教程：基本概念](https://fuckcloudnative.io/posts/understanding-cgroups-part-1-basics/)
* [Linux Cgroup 入门教程：CPU](https://fuckcloudnative.io/posts/understanding-cgroups-part-2-cpu/)
* [Linux Cgroup 入门教程：内存](https://fuckcloudnative.io/posts/understanding-cgroups-part-3-memory/)

通过[上篇文章](https://fuckcloudnative.io/posts/understanding-cgroups-part-2-cpu/)的学习，我们学会了如何查看当前 cgroup 的信息，如何通过操作 `/sys/fs/cgroup` 目录来动态设置 cgroup，也学会了如何设置 CPU shares 和 CPU quota 来控制 `slice` 内部以及不同 `slice` 之间的 CPU 使用时间。本文将把重心转移到内存上，通过具体的示例来演示如何通过 cgroup 来限制内存的使用。

## 1. 寻找走失内存

------

上篇文章告诉我们，CPU controller 提供了两种方法来限制 CPU 使用时间，其中 `CPUShares` 用来设置相对权重，`CPUQuota` 用来限制 user、service 或 VM 的 CPU 使用时间百分比。例如：如果一个 user 同时设置了 CPUShares 和 CPUQuota，假设 CPUQuota 设置成 `50%`，那么在该 user 的 CPU 使用量达到 50% 之前，可以一直按照 CPUShares 的设置来使用 CPU。

对于内存而言，在 CentOS 7 中，systemd 已经帮我们将 memory 绑定到了 /sys/fs/cgroup/memory。`systemd` 只提供了一个参数 `MemoryLimit` 来对其进行控制，该参数表示某个 user 或 service 所能使用的物理内存总量。拿之前的用户 tom 举例， 它的 UID 是 1000，可以通过以下命令来设置：

```bash
$ systemctl set-property user-1000.slice MemoryLimit=200M
```



现在使用用户 `tom` 登录该系统，通过 `stress` 命令产生 8 个子进程，每个进程分配 256M 内存：

```bash
$ stress --vm 8 --vm-bytes 256M
```



按照预想，stress 进程的内存使用量已经超出了限制，此时应该会触发 `oom-killer`，但实际上进程仍在运行，这是为什么呢？我们来看一下目前占用的内存：

```bash
$ cd /sys/fs/cgroup/memory/user.slice/user-1000.slice

$ cat memory.usage_in_bytes
209661952
```



奇怪，占用的内存还不到 200M，剩下的内存都跑哪去了呢？别慌，你是否还记得 linux 系统中的内存使用除了包括物理内存，还包括交换分区，也就是 swap，我们来看看是不是 swap 搞的鬼。先停止刚刚的 stress 进程，稍等 30 秒，观察一下 swap 空间的占用情况：

```bash
$ free -h
              total        used        free      shared  buff/cache   available
Mem:           3.7G        180M        3.2G        8.9M        318M        3.3G
Swap:          3.9G        512K        3.9G
```



重新运行 stress 进程：

```bash
$ stress --vm 8 --vm-bytes 256M
```



查看内存使用情况：

```bash
$ cat memory.usage_in_bytes
209637376
```



发现内存占用刚好在 200M 以内。再看 swap 空间占用情况：

```bash
$ free
              total        used        free      shared  buff/cache   available
Mem:        3880876      407464     3145260        9164      328152     3220164
Swap:       4063228     2031360     2031868
```



和刚刚相比，多了 `2031360-512=2030848k`，现在基本上可以确定当进程的使用量达到限制时，内核会尝试将物理内存中的数据移动到 swap 空间中，从而让内存分配成功。我们可以精确计算出 tom 用户使用的物理内存+交换空间总量，首先需要分别查看 tom 用户的物理内存和交换空间使用量：

```bash
$ egrep "swap|rss" memory.stat
rss 209637376
rss_huge 0
swap 1938804736
total_rss 209637376
total_rss_huge 0
total_swap 1938804736
```



可以看到物理内存使用量为 `209637376` 字节，swap 空间使用量为 `1938804736` 字节，总量为 `(209637376+1938804736)/1024/1024=2048` M。而 stress 进程需要的内存总量为 `256*8=2048` M，两者相等。

这个时候如果你每隔几秒就查看一次 `memory.failcnt` 文件，就会发现这个文件里面的数值一直在增长：

```bash
$ cat memory.failcnt
59390293
```



从上面的结果可以看出，当物理内存不够时，就会触发 memory.failcnt 里面的数量加 1，但此时进程不一定会被杀死，内核会尽量将物理内存中的数据移动到 swap 空间中。

## 2. 关闭 swap

------

为了更好地观察 cgroup 对内存的控制，我们可以用户 tom 不使用 swap 空间，实现方法有以下几种：

1. 将 `memory.swappiness` 文件的值修改为 0：

   ```bash
   $ echo 0 > /sys/fs/cgroup/memory/user.slice/user-1000.slice/memory.swappiness
   ```

   

   这样设置完成之后，即使系统开启了交换空间，当前 cgroup 也不会使用交换空间。

2. 直接关闭系统的交换空间：

   ```bash
   $ swapoff -a
   ```

   如果想永久生效，还要注释掉 `/etc/fstab` 文件中的 swap。

如果你既不想关闭系统的交换空间，又想让 tom 不使用 swap 空间，上面给出的第一个方法是有问题的：

* 你只能在 tom 用户登录的时候修改 `memory.swappiness` 文件的值，因为如果 tom 用户没有登录，当前的 cgroup 就会消失。
* 即使你修改了 `memory.swappiness` 文件的值，也会在重新登录后失效

如果按照常规思路去解决这个问题，可能会非常棘手，我们可以另辟蹊径，从 PAM 入手。

Linux PAM([Pluggable Authentication Modules](http://www.linux-pam.org/)) 是一个系统级用户认证框架，PAM 将程序开发与认证方式进行分离，程序在运行时调用附加的“认证”模块完成自己的工作。本地系统管理员通过配置选择要使用哪些认证模块，其中 `/etc/pam.d/` 目录专门用于存放 PAM 配置，用于为具体的应用程序设置独立的认证方式。例如，在用户通过 ssh 登录时，将会加载 `/etc/pam.d/sshd` 里面的策略。

从 `/etc/pam.d/sshd` 入手，我们可以先创建一个 shell 脚本：

```bash
$ cat /usr/local/bin/tom-noswap.sh
#!/bin/bash

if [ $PAM_USER == 'tom' ]
  then
    echo 0 > /sys/fs/cgroup/memory/user.slice/user-1000.slice/memory.swappiness
fi
```



然后在 `/etc/pam.d/sshd` 中通过 pam_exec 调用该脚本，在 `/etc/pam.d/sshd` 的末尾添加一行，内容如下：

```bash
$ session optional pam_exec.so seteuid /usr/local/bin/tom-noswap.sh
```



现在再使用 tom 用户登录，就会发现 `memory.swappiness` 的值变成了 0。

这里需要注意一个前提：至少有一个用户 tom 的登录会话，且通过 `systemctl set-property user-1000.slice MemoryLimit=200M` 命令设置了 limit，`/sys/fs/cgroup/memory/user.slice/user-1000.slice` 目录才会存在。所以上面的所有操作，一定要保证至少保留一个用户 tom 的登录会话。

## 3. 控制内存使用

------

关闭了 swap 之后，我们就可以严格控制进程的内存使用量了。还是使用开头提到的例子，使用用户 tom 登录该系统，先在第一个 shell 窗口运行以下命令：

```bash
$ journalctl -f
```



打开第二个 shell 窗口（还是 tom 用户），通过 stress 命令产生 8 个子进程，每个进程分配 256M 内存：

```bash
$ stress --vm 8 --vm-bytes 256M
stress: info: [30150] dispatching hogs: 0 cpu, 0 io, 8 vm, 0 hdd
stress: FAIL: [30150] (415) <-- worker 30152 got signal 9
stress: WARN: [30150] (417) stress: FAIL: [30150] (415) <-- worker 30151 got signal 9
stress: WARN: [30150] (417) now reaping child worker processes
stress: FAIL: [30150] (415) <-- worker 30154 got signal 9
stress: WARN: [30150] (417) now reaping child worker processes
stress: FAIL: [30150] (415) <-- worker 30157 got signal 9
stress: WARN: [30150] (417) now reaping child worker processes
stress: FAIL: [30150] (415) <-- worker 30158 got signal 9
stress: WARN: [30150] (417) now reaping child worker processes
stress: FAIL: [30150] (451) failed run completed in 0s
```



现在可以看到 stress 进程很快被 kill 掉了，回到第一个 shell 窗口，会输出以下信息：

![img](.img_Cgroups%E4%B8%8ESystemd/20200723163244.png)

由此可见 cgroup 对内存的限制奏效了，stress 进程的内存使用量超出了限制，触发了 oom-killer，进而杀死进程。

## 4. 更多文档

------

加个小插曲，如果你想获取更多关于 cgroup 的文档，可以通过 yum 安装 `kernel-doc` 包。安装完成后，你就可以进入 `/usr/share/docs` 的子目录，查看每个 cgroup controller 的详细文档。

```bash
$ cd /usr/share/doc/kernel-doc-3.10.0/Documentation/cgroups
$ ll
总用量 172
 4 -r--r--r-- 1 root root   918 6月  14 02:29 00-INDEX
16 -r--r--r-- 1 root root 16355 6月  14 02:29 blkio-controller.txt
28 -r--r--r-- 1 root root 27027 6月  14 02:29 cgroups.txt
 4 -r--r--r-- 1 root root  1972 6月  14 02:29 cpuacct.txt
40 -r--r--r-- 1 root root 37225 6月  14 02:29 cpusets.txt
 8 -r--r--r-- 1 root root  4370 6月  14 02:29 devices.txt
 8 -r--r--r-- 1 root root  4908 6月  14 02:29 freezer-subsystem.txt
 4 -r--r--r-- 1 root root  1714 6月  14 02:29 hugetlb.txt
16 -r--r--r-- 1 root root 14124 6月  14 02:29 memcg_test.txt
36 -r--r--r-- 1 root root 36415 6月  14 02:29 memory.txt
 4 -r--r--r-- 1 root root  1267 6月  14 02:29 net_cls.txt
 4 -r--r--r-- 1 root root  2513 6月  14 02:29 net_prio.txt
```

