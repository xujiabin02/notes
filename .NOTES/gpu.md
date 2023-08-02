



# Error 802: system not yet initialized

解决nvcc、驱动正常，但GPU无法正常使用问题

容器里使用cuda报错

```shell
root@13c785a7f060:/workspace/unet3d# python -c "import torch; print(torch.cuda.is_available())"
/opt/conda/lib/python3.8/site-packages/torch/cuda/__init__.py:52: UserWarning: CUDA initialization: Unexpected error from cudaGetDeviceCount(). Did you run some cuda functions before calling NumCudaDevices() that might have already set an error? Error 802: system not yet initialized (Triggered internally at  /opt/conda/conda-bld/pytorch_1607370172916/work/c10/cuda/CUDAFunctions.cpp:100.)
  return torch._C._cuda_getDeviceCount() > 0
False
```



https://blog.csdn.net/ZXF_1991/article/details/129855713

引言
在使用NVIDIA显卡(V100/A100/A30等)时，需要安装对应的驱动，但是有时还要安装与驱动版本对应的 nvidia-fabricmanager 服务，使 GPU 卡间能够通过NVSwitch互联。

问题
当报错信息为以下情况时需要安装nvidia-fabricmanager 服务

ubuntu安装nvidia-fabricmanager


```sh
version=470.103.01  #已经安装的驱动版本
main_version=$(echo $version | awk -F '.' '{print $1}')
apt-get update
apt-get -y install nvidia-fabricmanager-${main_version}=${version}-*

```

CentOS 安装nvidia-fabricmanager


```sh
version=470.103.01 #已经安装的驱动版本
yum -y install yum-utils
yum-config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel7/x86_64/cuda-rhel7.repo
yum install -y nvidia-fabric-manager-${version}-1
```


查验安装结果
启动服务

```sh
sudo systemctl start nvidia-fabricmanager
```


查看状态

```sh
sudo systemctl status nvidia-fabricmanager
```

添加开机启动

```sh
sudo systemctl enable nvidia-fabricmanager
```



查看 cuda 

```sh
python -c "import torch; print(torch.cuda.is_available())"
python -c "import torch; print(torch.version.cuda)"
```



# cuda和驱动版本

https://docs.nvidia.com/cuda/cuda-toolkit-release-notes/index.html



# [安装GPU驱动](ubuntu.md)





| 虚拟化   | 显卡        | 系统         |
| -------- | ----------- | ------------ |
| EXSI 6.7 | RTX 2080 Ti | Ubuntu 20.04 |
|          |             |              |
|          |             |              |

## 物理机显卡直通

物理机配置
首先开机进入bios，提前修改物理机bios设置：

Above 4G decoding - Enable
Intel Virtualization Technology for Directed I/O (VT-d) - Enable
MMIO High Base - 默认56T（若为ESXi 6.5以下版本注意修改为4G-16T之间的值，如4T）



GPU 切换直通模式
 安装完ESXi软件后，首先需要将GPU切换为直通模式，切换方法为：导航界面选择管理—>硬件—>PCI设备，搜索框输入nvidia筛选出GPU设备，勾选后，点击切换直通。

![ESXi GPU 直通_直通_05](.img_gpu/resize,m_fixed,w_1184)

GPU切换直通后，需要重新引导主机使配置生效：

![ESXi GPU 直通_vmware_06](.img_gpu/resize,m_fixed,w_1184-20230410104140815)

重新引导主机后，GPU直通变为活动状态，表示GPU切换直通成功。

![ESXi GPU 直通_vmware_07](.img_gpu/resize,m_fixed,w_1184-20230410104150014)



如图，添加两块GPU，分别为Tesla V100和Tesla V100S，并在新PCI设备选项下点击预留所有内存。

![ESXi GPU 直通_ESXi_15](.img_gpu/resize,m_fixed,w_1184-20230410104231275)



![ESXi GPU 直通_直通_16](.img_gpu/resize,m_fixed,w_1184-20230410104243225)



修改虚拟机内存

 虚拟硬件—>内存，建议设置最小内存为虚拟机所分配GPU显存总大小的1.5倍。确保已勾选预留所有客户机内存(全部锁定)



![ESXi GPU 直通_GPU直通_17](.img_gpu/resize,m_fixed,w_1184-20230410104255959)



编辑虚拟机选项、高级、配置参数，添加如下参数

```
hypervisor.cpuid.v0 = "FALSE"
```



![ESXi GPU 直通_vmware_19](.img_gpu/resize,m_fixed,w_1184-20230410104318998)





修改虚拟机引导选项

编辑虚拟机，修改虚拟机选项—>引导选项为EFI, 关闭UEFI安全引导

![ESXi GPU 直通_vmware_20](.img_gpu/resize,m_fixed,w_1184-20230410104351244)



安装系统



```
sudo apt-get update   #更新软件列表
sudo apt-get install -y g++
sudo apt-get install -y gcc 
sudo apt-get install  -y  make


```





```
lsmod |grep -i nouveau
```



关闭nouveau

> sudo vim /etc/modprobe.d/blacklist.conf

```
blacklist nouveau
blacklist lbm-nouveau
options nouveau modeset=0
alias nouveau off
alias lbm-nouveau off

```





```sh
sudo update-initramfs -u
```



```sh
reboot
```



```sh
lsmod | grep nouveau
```



下载460包

https://http.download.nvidia.com/XFree86/Linux-x86_64/460.91.03/

```sh
sudo ./NVIDIA-Linux-x86_64-460.91.03.run -no-x-check -no-nouveau-check -no-opengl-files
```





---

> ```shell
> appuser@newkn1:~$ sudo ubuntu-drivers devices
> ERROR:root:could not open aplay -l
> Traceback (most recent call last):
> File "/usr/share/ubuntu-drivers-common/detect/sl-modem.py", line 35, in detect
>  aplay = subprocess.Popen(
> File "/usr/lib/python3.8/subprocess.py", line 858, in __init__
>  self._execute_child(args, executable, preexec_fn, close_fds,
> File "/usr/lib/python3.8/subprocess.py", line 1704, in _execute_child
>  raise child_exception_type(errno_num, err_msg, err_filename)
> FileNotFoundError: [Errno 2] No such file or directory: 'aplay'
> ```
>
> 



```
sudo apt install alsa-base
```



找驱动 https://www.nvidia.com/Download/Find.aspx?lang=en-us



```sh
sudo apt install libgtk-3-0
```



```
sudo update-pciids
```



```
apt install ubuntu-drivers-common
```

完全卸载NAVIDIA驱动
如果想卸载NAVIDIA驱动，使用附加驱动的方式只能切换驱动，但卸载不了驱动，只能通过命令的方式卸载：

```
sudo apt-get -y --purge remove nvidia*
sudo apt-get y --purge remove "*nvidia*"
sudo apt-get -y --purge remove "*cublas*" 
sudo apt-get -y --purge remove "cuda*"

sudo apt-get -y --purge nvidia*

sudo update-initramfs -u
```



```
sudo apt-get remove nvidia-*
```







下载460包

https://http.download.nvidia.com/XFree86/Linux-x86_64/460.91.03/



PS:





https://blog.csdn.net/qq_34525916/article/details/110953980

https://blog.csdn.net/qq_46107892/article/details/122616172

https://yukihane.work/li-gong/nvidia-ubuntu-laptop

https://blog.51cto.com/zaa47/2596875



https://hslxy.top/index.php/2022/07/21/esxi6-7ubuntu20-043080直通配置/



https://www.zhangfangzhou.cn/esxi-2080ti-passthrough.html ESXi7u1设置NVIDIA GEFORCE RTX 2080TI显卡直通（passthrough）





https://github.com/OrangeSpatial/documents/blob/main/Ubuntu安装rtx%202080ti%20显卡.md







# CUDA

https://blog.csdn.net/ziqibit/article/details/129935737

```
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-ubuntu2004.pin
sudo mv cuda-ubuntu2004.pin /etc/apt/preferences.d/cuda-repository-pin-600
wget https://developer.download.nvidia.com/compute/cuda/12.1.0/local_installers/cuda-repo-ubuntu2004-12-1-local_12.1.0-530.30.02-1_amd64.deb
sudo dpkg -i cuda-repo-ubuntu2004-12-1-local_12.1.0-530.30.02-1_amd64.deb
sudo cp /var/cuda-repo-ubuntu2004-12-1-local/cuda-*-keyring.gpg /usr/share/keyrings/
sudo apt-get update
sudo apt-get -y install cuda
```



cuda会装 530驱动，要手动卸载装460

# [安装GPU驱动](ubuntu.md)



# gpu k8s

Nvidia  device plugin    [github](https://github.com/NVIDIA/k8s-device-plugin)

gpu-operator  [github](https://github.com/NVIDIA/gpu-operator)

|          | OrionX                                                       | [Nvidia](https://developer.nvidia.com/zh-cn/blog/nvidia-gpu-operator-simplifying-gpu-management-in-kubernetes/) | KubeSphere                                            | [TKG](https://www.chimsen.com/?p=1695) | [ Elastic GPU](https://www.cnblogs.com/tencent-cloud-native/p/16168666.html) |
| -------- | ------------------------------------------------------------ | ------------------------------------------------------------ | ----------------------------------------------------- | -------------------------------------- | ------------------------------------------------------------ |
| K8S      | [Y](https://virtaitech.com/development/index?doc=4r4gnqv5j9qgw70njj2a2jnzma) | [Y](https://github.com/NVIDIA/k8s-device-plugin)             | [Y](https://www.kubesphere.io/zh/blogs/gpu-operator/) |                                        | Y                                                            |
| 灵活度   | Y                                                            | N                                                            | N                                                     |                                        | Y                                                            |
| vgpu     | 最小资源单位为vgpu/gmem                                      | pod独占最小资源单位为一张卡                                  |                                                       |                                        | 最小资源单位为vgpu/gmem                                      |
| 远程调用 | 支持                                                         | 不支持,pod必须在gpu机器上                                    |                                                       |                                        | 不支持                                                       |

概念:  vGPU, GPU池化

需求: GPU 细粒度算力与显存分配调度

技术: qGPU 虚拟化、vCUDA、或是 GPU 远端池化



![img](.img_gpu/image.png)

## OrionX

### 已知问题

下面列出当前版本不支持的CUDA库、工具以及使用模式

- 不支持CUDA应用程序使用 Unified Memory
- 不支持 nvidia-smi 工具
- 不支持OpenGL相关接口，不支持图形渲染相关接口
- 有限支持CUDA IPC，对部分程序可能不支持。
- 部分应用需要从源码重新编译以保证动态链接 CUDA 库





## Nvidia (灵活性不好)

> *   GPU 资源只能在 limits 中指定，即：
>     *   您可以只指定 GPU limits 而不指定 requests，因为 Kubernetes 会默认使用 GPU limits 的值作为 GPU requests 的值；
>     *   您可以同时指定 GPU limits 和 requests，但是两者必须相等；
>     *   您不能只指定 GPU requests 而不指定 GPU limits；
> *   容器（容器组）不能共享 GPU。GPU 也不能超售（GPU limits 的总和不能超过实际 GPU 资源的总和）；
> *   每个容器可以请求一个或多个 GPU，不能请求一个 GPU 的一部分（例如 0.5 个 GPU）。

*   GPU 资源只能在 limits 中指定，即：
    *   您可以只指定 GPU limits 而不指定 requests，因为 Kubernetes 会默认使用 GPU limits 的值作为 GPU requests 的值；
    *   您可以同时指定 GPU limits 和 requests，但是两者必须相等；
    *   您不能只指定 GPU requests 而不指定 GPU limits；
*   容器（容器组）不能共享 GPU。GPU 也不能超售（GPU limits 的总和不能超过实际 GPU 资源的总和）；
*   每个容器可以请求一个或多个 GPU，不能请求一个 GPU 的一部分（例如 0.5 个 GPU）。





# [阿里\腾讯\华为,三家对比](https://www.flftuu.com/2020/11/14/k8s集群GPU调研报告%2f)

| 厂商   | nvidia runtime依赖 | 内存共享 | 内存隔离 | 算力隔离 | 采用技术                                                 | 优点                                                         | 缺点                                                   |
| :----- | :----------------- | :------- | :------- | :------- | :------------------------------------------------------- | :----------------------------------------------------------- | :----------------------------------------------------- |
| 阿里云 | 依赖               | 支持     | 支持     | 支持     | cGPU（自研内核驱动）+ device plugin + scheduler extender | 优点：无需重编译AI应用，无需替换CUDA库，升级CUDA、cuDNN的版本后无需重新配置；且基本无性能损耗（官方宣称） | 缺点：开发难度相对较高                                 |
| 腾讯云 | 不依赖             | 支持     | 支持     | 支持     | cuda调用封装 + device plugin + scheduler extender        | 优点：开发难度相对较低                                       | 缺点：驱动和加速库的兼容性依赖于厂商存在约5%的性能损耗 |
| 华为云 | 依赖               | 支持     | 不支持   | 不支持   | device plugin                                            |                                                              |                                                        |

腾讯qGPU: https://cloud.tencent.com/document/product/560/66232

阿里cGPU: https://help.aliyun.com/document_detail/203715.html?spm=a2c4g.155040.0.0.2d484cbcT67uD6





https://blog.csdn.net/ikanaide/article/details/120864852

https://www.shouxicto.com/article/4459.html

https://kubernetes.io/docs/tasks/manage-gpus/scheduling-gpus/