# rdma

## IB网卡驱动

```shell
tar zxf MLNX_OFED_LINUX-24.04-0.7.0.0-ubuntu22.04-x86_64.tgz
cd MLNX_OFED_LINUX-24.04-0.7.0.0-ubuntu22.04-x86_64/
./mlnxofedinstall --force --with-nvmf
```



output:

```shell
Checking SW Requirements...
One or more required packages for installing MLNX_OFED_LINUX are missing.
Attempting to install the following missing packages:
gfortran
```



```shell
/etc/init.d/openibd restart
```





`````shell
sudo apt-get install openvswitch-switch-dpdk
`````



## 在 Ubuntu 20.04 上安装 Intel E810-C ICE 网卡驱动的步骤如下：

### 1. 更新系统
首先，确保你的系统是最新的：

```bash
sudo apt update
sudo apt upgrade -y
```

### 2. 安装必要的工具和依赖
安装构建驱动程序所需的工具和依赖：

```bash
sudo apt install build-essential linux-headers-$(uname -r) -y
```

### 3. 下载驱动程序
从 Intel 的官方网站下载适用于 E810-C 网卡的驱动程序。你可以访问以下链接查找和下载最新版本的驱动程序：

[Intel® Ethernet Network Adapter E810-C 系列驱动下载](https://www.intel.com/content/www/us/en/products/sku/192132/intel-ethernet-network-adapter-e810cqda2/downloads.html)

下载后，解压驱动程序包：

```bash
tar -xvf ice-<version>.tar.gz
cd ice-<version>
```

### 4. 编译和安装驱动程序
在解压后的驱动程序目录中，运行以下命令来编译和安装驱动程序：

```bash
sudo make install
```

### 5. 加载驱动模块
编译和安装完成后，加载驱动模块：

```bash
sudo modprobe ice
```

### 6. 验证驱动程序安装
你可以使用以下命令来验证驱动程序是否已正确安装并识别网卡：

```bash
sudo lshw -C network
```

你还可以检查网卡的状态：

```bash
ethtool -i <network-interface>
```

将 `<network-interface>` 替换为实际的网络接口名称，如 `eth0` 或 `enp0s31f6`。

### 7. 配置网络
根据需要，配置你的网络接口。你可以使用 `netplan` 或者 `ifconfig` 工具。例如，使用 `netplan` 进行配置：

编辑 `/etc/netplan/01-netcfg.yaml` 文件，添加或修改以下内容：

```yaml
network:
  version: 2
  ethernets:
    <network-interface>:
      dhcp4: true
```

将 `<network-interface>` 替换为实际的网络接口名称。

应用配置：

```bash
sudo netplan apply
```

### 8. 重启网络服务
最后，重启网络服务以确保配置生效：

```bash
sudo systemctl restart networking
```

### 9. 检查网络连接
使用 `ping` 或其他网络工具检查网络连接是否正常：

```bash
ping google.com
```

如果一切顺利，你的 Intel E810-C ICE 网卡应该已经在 Ubuntu 20.04 上正常工作了。
