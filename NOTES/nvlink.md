# ?disable nvlink ?[?](https://stackoverflow.com/questions/53174224/nvlink-or-pcie-how-to-specify-the-interconnect)

The accepted answer -- from an NVIDIA employee -- was correct in 2018. But at some point, NVIDIA added an (undocumented?) option to the driver.

On Linux, you can now put this in /etc/modprobe.d/disable-nvlink.conf:

```undefined
options nvidia NVreg_NvLinkDisable=1
```

This will disable NVLink when the driver is next loaded, forcing GPU peer-to-peer communication to use the PCIe interconnect. This gadget exists in driver 515.65.01 (CUDA 11.7.1). I am not sure when it was added.

As for ["there is no reason to allow the end-user to choose the slower path"](https://stackoverflow.com/q/53174224/#comment93242873_53174224), the very existence of this SO question suggests otherwise. In my case, we buy not one server, but dozens... And in the process of choosing our configuration, it is nice to use a single prototype system to benchmark our application using either NVLink or PCIe.