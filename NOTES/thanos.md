# thanos

- 项目地址 https://github.com/thanos-io/kube-thanos , v0.29.0

  - example minio

    - 安装local-path插件

      - 离线导入docker.io/rancher/local-path-provisioner:v0.0.24

      - 修改配置并apply, (留意config.json中的paths对应node节点目录)

      - ```yaml
        ---
        apiVersion: storage.k8s.io/v1
        kind: StorageClass
        metadata:
          annotations:
            defaultVolumeType: local
          name: base-local-path
        provisioner: rancher.io/local-path
        reclaimPolicy: Retain
        volumeBindingMode: WaitForFirstConsumer
        ---
        apiVersion: v1
        data:
          config.json: |-
            {
              "nodePathMap":[
                {
                  "node":"DEFAULT_PATH_FOR_NON_LISTED_NODES",
                  "paths":["/data/local-path"] 
                }
              ]
            }
          helperPod.yaml: |-
            apiVersion: v1
            kind: Pod
            metadata:
              name: helper-pod
            spec:
              containers:
                - name: helper-pod
                  image: busybox
                  imagePullPolicy: IfNotPresent
          setup: |-
            #!/bin/sh
            set -eu
            mkdir -m 0777 -p "$VOL_DIR"
          teardown: |-
            #!/bin/sh
            set -eu
            rm -rf "$VOL_DIR"
        kind: ConfigMap
        metadata:
          name: local-path-config # 配置名字最好不动
          namespace: middleware
        ---
        apiVersion: v1
        kind: ServiceAccount
        metadata:
          name: local-path-provisioner-service-account
          namespace: middleware
        ---
        apiVersion: rbac.authorization.k8s.io/v1
        kind: ClusterRoleBinding
        metadata:
          name: local-path-provisioner-bind-bigdata
        roleRef:
          apiGroup: rbac.authorization.k8s.io
          kind: ClusterRole
          name: local-path-provisioner-role
        subjects:
          - kind: ServiceAccount
            name: local-path-provisioner-service-account
            namespace: middleware
        ---
        apiVersion: rbac.authorization.k8s.io/v1
        kind: ClusterRole
        metadata:
          name: local-path-provisioner-role
        rules:
          - apiGroups:
              - ""
            resources:
              - nodes
              - persistentvolumeclaims
              - configmaps
            verbs:
              - get
              - list
              - watch
          - apiGroups:
              - ""
            resources:
              - endpoints
              - persistentvolumes
              - pods
            verbs:
              - '*'
          - apiGroups:
              - ""
            resources:
              - events
            verbs:
              - create
              - patch
          - apiGroups:
              - storage.k8s.io
            resources:
              - storageclasses
            verbs:
              - get
              - list
              - watch
        ---
        apiVersion: apps/v1
        kind: Deployment
        metadata:
          name: local-path-provisioner
          namespace: middleware
        spec:
          progressDeadlineSeconds: 600
          replicas: 1
          revisionHistoryLimit: 10
          selector:
            matchLabels:
              app: local-path-provisioner
          strategy:
            rollingUpdate:
              maxSurge: 25%
              maxUnavailable: 25%
            type: RollingUpdate
          template:
            metadata:
              creationTimestamp: null
              labels:
                app: local-path-provisioner
            spec:
              containers:
                - command:
                    - local-path-provisioner
                    - --debug
                    - start
                    - --config
                    - /etc/config/config.json
                  env:
                    - name: POD_NAMESPACE
                      valueFrom:
                        fieldRef:
                          apiVersion: v1
                          fieldPath: metadata.namespace
                  image: rancher/local-path-provisioner:v0.0.24
                  imagePullPolicy: IfNotPresent
                  name: local-path-provisioner
                  resources: {}
                  terminationMessagePath: /dev/termination-log
                  terminationMessagePolicy: File
                  volumeMounts:
                    - mountPath: /etc/config/
                      name: config-volume
              dnsPolicy: ClusterFirst
              restartPolicy: Always
              schedulerName: default-scheduler
              securityContext: {}
              serviceAccount: local-path-provisioner-service-account
              serviceAccountName: local-path-provisioner-service-account
              terminationGracePeriodSeconds: 30
              volumes:
                - configMap:
                    defaultMode: 420
                    name: local-path-config
                  name: config-volume
        
        ```

  - thanos

    - 增加 nodePort 和 --store 指定 机房A的thanos-sidecar

      - ```yaml
            - --store=thanos-sidecar-ipaddress:10901
        ```

    - kubectl apply -f mainfest

- kube-prometheus, 项目地址 https://github.com/prometheus-operator/kube-prometheus.git, 版本v0.13.0

- 添加thanos.yaml  secret

  - ```yaml
    apiVersion: v1
    kind: Secret
    metadata:
      name: thanos-objectstorage
      namespace: monitoring
    stringData:
      thanos.yaml: |
        type: s3
        config:
          bucket: thanos
          endpoint: 172.19.0.230:30900
          insecure: true
          access_key: minio
          secret_key: minio123
    type: Opaque
    ```

- 修改prometheus-prometheus.yaml

  - ```yaml
    thanos:
      baseImage: quay.io/thanos/thanos:v0.30.2
      version: v0.30.2
      objectStorageConfig:
        key: thanos.yaml
        name: thanos-objectstorage
    # externalLabels: {} -> {cluster: A}
    externalLabels: {cluster: A}
    ```

- 修改prometheus-service.yaml

  - ````yaml
    - port: 10901
      name: thanos-sidecar
      targetPort: grpc
      nodePort: 31091
    ```
    -
    ````

    