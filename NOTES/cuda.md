# cuda

```shell
NVIDIA-SMI 460.91.03    Driver Version: 460.91.03    CUDA Version: 11.2 
```



## tensorflow-gpu安装

https://www.cnblogs.com/LandWind/p/win11-cuda-cudnn-Tensorflow-GPU-env-start.html

```shell
**
driver决定了CUDA的版本

CUDA决定了cuDNN的版本

CUDA决定了tensorflow-gpu的版本

tensorflow-gpu决定了python的版本
**
```



```sh
pip install tensorflow-gpu=1.15.5 -i https://pypi.tuna.tsinghua.edu.cn/simple/
pip install scikit-learn -i https://pypi.tuna.tsinghua.edu.cn/simple/
```



## pytorch

```shell
pip install torch==1.9.1+cu111 torchvision==0.10.1+cu111 torchaudio==0.9.1 -f https://download.pytorch.org/whl/torch_stable.html -i https://pypi.tuna.tsinghua.edu.cn/simple/
```



![image](https://img2022.cnblogs.com/blog/630623/202210/630623-20221022174515833-1009957278.png)
