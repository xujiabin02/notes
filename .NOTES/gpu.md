

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