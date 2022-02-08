





```sh
docker commit -a "vue ts python3.6" -m "打包测试成功" f8520479ba2b vue3-ts-python3.6:1.0.0

docker export  --output=vue3-ts-python36.tar  c7
cat vue3-ts-python36.tar|docker import - c8
```



```bash
hr:centos7 hr$ docker port 4966d35fe0a3
22/tcp -> 0.0.0.0:10022
```

# docker swarm

![img](.img_docker/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3dlaXhpbl80MjUzMzg1Ng==,size_16,color_FFFFFF,t_70.png)





# 查看docker RestartPolicy

```sh
 docker inspect m1 | python3 -c 'import json,sys;print(json.load(sys.stdin)[0]["HostConfig"]["RestartPolicy"]["Name"])'
```





```sh
docker run -d --name portainer1.2.1 -p 9000:9000 -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer
```



# [Docker使用pipework配置本地网络](https://www.coonote.com/docker-note/docker-pipework-netword.html)

## 需求

在使用Docker的过程中，有时候我们会有将Docker容器配置到和主机同一网段的需求。要实现这个需求，我们只要将Docker容器和主机的网卡桥接起来，再给Docker容器配上IP就可以了。

下面我们就使用pipework工具来实现这一需求。

## 1、pipework的安装

Pipework是一个Docker配置工具，是一个开源项目，由200多行[shell](https://www.coonote.com/shell/shell-tutorial.html)实现。

Pipework是一个集成工具，需要配合使用的两个工具是OpenvSwitch和Bridge-utils。

```
$ git clone https://github.com/jpetazzo/pipework.git $ sudo cp pipework/pipework /usr/local/bin/
```

## 2、pipework配置Docker的三个简单场景

### 2.1　　pipework+linux bridge：配置Docker单主机容器

```
#主机A：192.168.187.143 #主机A上创建两个容器con1、con2 docker run -itd --name con1 --net=none ubuntu:14.04 bash docker run -itd --name con2 --net=none ubuntu:14.04 bash #使用pipework建立网桥br0，为容器con1和con2添加新的网卡，并将它们连接到br0上 pipework br0 con1 10.0.0.2/24 pipework br0 con2 10.0.0.3/24 #在容器con1和con2内部可以看到有一个网卡地址分别如上，可以ping通
```

### 2.2　　pipework+OVS：单主机Docker容器VLAN划分

pipework不仅可以使用Linux bridge连接Docker容器，还可以与OpenVswitch结合，实现Docker容器的VLAN划分。

```
 1 #主机A的IP地址为:192.168.187.147
 2 #在主机A上创建4个Docker容器，test1、test2、test3、test4  3 
 4 docker run -itd --name test1 --net=none busybox sh  5 docker run -itd --name test2 --net=none busybox sh  6 docker run -itd --name test3 --net=none busybox sh  7 docker run -itd --name test4 --net=none busybox sh  8 
 9 #将test1，test2划分到一个vlan中，vlan在mac地址后加@指定，此处mac地址省略 10 pipework ovs0 test1 192.168.0.1/24 @100
11 pipework ovs0 test2 192.168.0.2/24 @100
12 
13 #将test3，test4划分到另一个vlan中 14 pipework ovs0 test3 192.168.0.3/24 @200
15 pipework ovs0 test4 192.168.0.4/24 @200
16 
17 #此时进入容器test1 18 ping 10.0.0.2 #可以通信 19 ping 10.0.0.3    #不可以通信
```

这个功能其实是由于OpenVSwitch本身支持VLAN功能，在将veth pair的一端加入ovs0网桥时，指定了tag。底层的操作是

```
ovs-vsctl add-port ovs0 veth* tag=100
```

 

### 2.3　　pipework+OVS：多主机Docker容器VLAN划分

```
 1 #主机A：192.168.187.147
 2 #主机B：192.168.187.148
 3 
 4 #主机A上  5 docker run -itd --net=none --name con1 busybox sh  6 docker run -itd --net=none --name con2 busybox sh  7 
 8 #划分vlan  9 pipework ovs con1 10.0.0.1/24 @100
10 pipework ovs con2 10.0.0.2/24 @200
11 
12 #将eth0连接到ovs上 13 ovs-vsctl add-port ovs eth0 14 
15 #同理在主机B上进行操作 16 docker run -itd --net=none --name con3 busybox sh 17 docker run -itd --net=none --name con4 busybox sh 18 
19 #划分vlan 20 pipework ovs con3 10.0.0.3/24 @100
21 pipework ovs con4 10.0.0.4/24 @200
22 
23 #将eth0连接到ovs上 24 ovs-vsctl add-port ovs eth0
```

遇到问题：

1）进入容器con3，我们期望的结果是可以ping通con1，但是不能ping通con2.但是实验发现都不能ping通。感觉跨主机划分vlan还是存在问题。

注：看到将eth0连接到ovs上另一种实现方式如下，但是试过了还是不能ping通

```
1 #主机A的IP地址为:192.168.187.147
2 ip addr add 192.168.187.147/24 dev ovs0 3 ip addr del 192.168.187.147/24 dev eth0 4 ovs-vsctl add-port ovs0 eth0 5 route del default
6 route add default gw 192.168.187.254 dev ovs0
```

2）如果不划分vlan的话，是可以跨主机通信的。