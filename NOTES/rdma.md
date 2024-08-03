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



