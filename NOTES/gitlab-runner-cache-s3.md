- Auto Devops

- runner

  - ```shell
    [runners.cache]
      Type = "s3"
      Path = "path/to/prefix"
      Shared = false
      [runners.cache.s3]
        ServerAddress = "s3.amazonaws.com"
        AccessKey = "AWS_S3_ACCESS_KEY"
        SecretKey = "AWS_S3_SECRET_KEY"
        BucketName = "runners-cache"
        BucketLocation = "eu-west-1"
        Insecure = false
        ServerSideEncryption = "KMS"
        ServerSideEncryptionKeyID = "alias/my-key"
    ```

- k8s-secret 给后边Gitlab Runner连接ceph s3使用。

  - ```yaml
    apiVersion: v1
    data:
      accesskey: N1NMT0hIRzYxddfsgxVzVssddfsdY=
      secretkey: d25Uc0NDQVdsfsdUkssCQ1VsdEwxeUsdsNwb2R4TnRzZDliTG1DTUN6cQ==
    kind: Secret
    metadata:
      name: gitlab-runner-s3
      namespace: gitlab-managed-apps
    type: Opaque
    ```

- values.yaml

  - ```yaml
    cache:
      ## General settings
      cacheType: s3
      cachePath: "devops" #指定ceph s3缓存路径，这里我们以部门来区分
      cacheShared: true
       
      ## S3 settings
      s3ServerAddress: "ops-rgw.test.cn"
      s3BucketName: "runners-cache"
      s3BucketLocation:
      s3CacheInsecure: true
      secretName: "gitlab-runner-s3"
     
    ```

- 配置gitlab Ci，修改.gitlab-ci.yaml，这里以前端项目构建为例：

  - ```yaml
    stages:
      - Build
       
    build-and-deploy:
      image: registry.test.cn/devops/node:latest
      stage: Build
      cache:
        key: devops-vue
        paths:
          - node_modules/
          - .yarn
      tags:
        - devopstest
      script:
        - yarn config set registry https://r.cnpmjs.org
        - yarn config set @test:registry https://npm.test.cn/
        - yarn --pure-lockfile --cache-folder .yarn --network-timeout 600000
        - yarn build
      when: always
    
    ```

    -