# gitlab iac 对接k8s

- 修改 /etc/gitlab/gitlab.rb 配置

  ```bash
  gitlab_kas['enable'] = true
  ```

- runner

  - helm pull gitlab/gitlab-runner --version=0.42.0

- agent

  - helm pull gitlab/gitlab-agent --version=1.2.0

  - ```toml
    # Example `config.toml` file 
    
    concurrent = 100 # A global setting for job concurrency that applies to all runner sections defined in this `config.toml` file
    log_level = "warning"
    log_format = "info"
    check_interval = 3 # Value in seconds
    
    [[runners]]
      name = "first"
      url = "Your Gitlab instance URL (for example, `https://gitlab.com`)"
      executor = "shell"
      (...)
    
    [[runners]]
      name = "second"
      url = "Your Gitlab instance URL (for example, `https://gitlab.com`)"
      executor = "docker"
      (...)
    
      [[runners]]
      name = "third"
      url = "Your Gitlab instance URL (for example, `https://gitlab.com`)"
      executor = "docker-autoscaler"
      (...)
    
    ```

- 添加时区(deployment)

  - ```yaml
    	env:
              - name: "TZ"
                value: "Asia/Shanghai"
    ```

- helm install

  - ```shell
    helm --kubeconfig ~/.kube/config.k8s upgrade --install agent1 ./gitlab-agent \
        --namespace test-hcptest \
        --create-namespace \
        --set image.tag=v15.10.0 \
        --set config.token=xxxxx \
        --set config.kasAddress=ws://x.x.x.x/-/kubernetes-agent/ \
        --set config.caCert=""
    ```

- 出现402问题
  collapsed:: true

  - ```
    {"level":"error","time":"2024-10-09T01:43:42.592Z","msg":"error checking security policies","mod_name":"starboard_vulnerability","error":"unexpected status code: 402","agent_id":2}
    ```

  - ```shell
    尝试添加role和rolebinding,未解决
    ```

- 添加role,rolebinding

  - ```yaml
    apiVersion: rbac.authorization.k8s.io/v1
    kind: Role
    metadata:
      namespace: test-hcptest
      name: gitlab-agent-role
    rules:
    - apiGroups: [""]
      resources: ["events"]
      verbs: ["create"]
    - apiGroups: ["coordination.k8s.io"]
      resources: ["leases"]
      verbs: ["get", "watch", "list", "update", "create"]
    ---
    apiVersion: rbac.authorization.k8s.io/v1
    kind: RoleBinding
    metadata:
      name: gitlab-agent-rolebinding
      namespace: test-hcptest
    subjects:
    - kind: ServiceAccount
      name: agent1-gitlab-agent
      namespace: test-hcptest
    roleRef:
      kind: Role
      name: gitlab-agent-role
      apiGroup: rbac.authorization.k8s.io
    ```

- 在project中添加kubenetes agent配置 .gitlab/agents/agent1/config.yaml

  - ```yaml
    gitops:
      manifest_projects:
      - id: "devops/cdp-deploy"
        ref:
          branch: develop
        paths:
        - glob: '/deployments/deploy.yaml'
        #- glob: '/deploymens/**/*.{yaml,json}'
    ```

- 在project中添加deployment文件/deployments/deploy.yaml
  -

  - ```yaml
    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: ms-1
      namespace: test-hcptest
    spec:
      selector:
        matchLabels:
          app: ms-1
      replicas: 1
      template:
        metadata:
          labels:
            app: ms-1
        spec:
          containers:
            - name: nginx-ms-1
              image: nginx:1.14.2
              ports:
                - containerPort: 80
                  protocol: TCP
                  name: http
    ```

- ```shell
  wget -q -O - http://x.x.x.x
  ```

  