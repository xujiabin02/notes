- 自动化

- id:: 66f0e21f-629b-4482-8287-1adbe22ca196

  ```shell
  kubectl get crd -A
  ```

- 添加代理

- ```shell
  export proxy_ip=x.x.x.x:7890; export HTTP_PROXY=http://$proxy_ip;export HTTPS_PROXY=http://$proxy_ip;export NO_PROXY=localhost,192.168.1.0/24,127.0.0.1
  ```

- 然后启动,   #minikube

- ```shell
  minikube delete && minikube start --kubernetes-version=v1.23.0 --memory=6g --bootstrapper=kubeadm --extra-config=kubelet.authentication-token-webhook=true --extra-config=kubelet.authorization-mode=Webhook --extra-config=scheduler.bind-address=0.0.0.0 --extra-config=controller-manager.bind-address=0.0.0.0 --driver=docker
  ```

- registry mirror

- ```json
      "RegistryMirror": [
          "https://docker.m.daocloud.io"
      ]
    
  ```

- docker load

- ```shell
  eval $(minikube -p minikube docker-env)
  docker load < x.img
  ```

  