- 清理

- systemctl restart containerd

- 清理, vi /etc/crictl.yaml

- ```yaml
  runtime-endpoint: unix:///var/run/containerd/containerd.sock
  image-endpoint: unix:///var/run/containerd/containerd.sock
  timeout: 10
  ```

  - ```
    crictl img|grep none|awk '{print$3}'|xargs crictl rmi
      
    crictl ps -a | grep -v Running | awk '{print $1}' | xargs sudo crictl rm && crictl rmi --prune
     
    crictl images -q | xargs -n 1 crictl rmi 2>/dev/null
    ```

- ps: https://www.cnblogs.com/liugp/p/16633732.html