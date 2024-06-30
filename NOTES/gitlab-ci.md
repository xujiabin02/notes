# gitlab-runner

`注意: git版本要升级到2.0+`

```sh
curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.rpm.sh | sudo bash
```

docker

```sh
   docker run -d --name gitlab-runner --restart always \
     -v /data/gitlab-runner/config:/etc/gitlab-runner \
     -v /var/run/docker.sock:/var/run/docker.sock \
     gitlab/gitlab-runner:v15.10.1
```





```sh
docker exec -ti gitlab-runner gitlab-runner register
```

register

```sh
docker exec -ti gitlab-runner gitlab-runner register --name my-runner --url https://gitlab.xinluex.com --registration-token xx --docker-privileged --docker-volumes /var/run/docker.sock:/var/run/docker.sock --docker-image docker-hub.xinluex.com/unii-centos:8  --env xx --executor docker
```

unregister

```sh
docker exec -ti gitlab-runner gitlab-runner unregister --name test-01
```



手动register

```sh
$ sudo gitlab-runner register
Runtime platform                                    arch=amd64 os=linux pid=1757391 revision=ece86343 version=13.5.0
Running in system-mode.

Please enter the gitlab-ci coordinator URL (e.g. https://gitlab.com/):
https://gitlab.example.com/
Please enter the gitlab-ci token for this runner:
8LX6mbaPGYxxxxxxxxxx
Please enter the gitlab-ci description for this runner:
[hostname]: runner2
Please enter the gitlab-ci tags for this runner (comma separated):

Registering runner... succeeded                     runner=8LX6xxxx
Please enter the executor: parallels, shell, ssh, virtualbox, kubernetes, custom, docker, docker-ssh, docker+machine, docker-ssh+machine:
shell
Runner registered successfully. Feel free to start it, but if it's running already the config should be automatically reloaded!
```



# 添加hosts

```toml
  [runners.docker]
    extra_hosts = ["harbor:1.1.1.1"]
```





制作gitlab-runner image

```sh
docker run --name tool-dc -ti -d --privileged --cap-add SYS_ADMIN -v /sys/fs/cgroup:/sys/fs/cgroup:ro -v /var/run/docker.sock:/var/run/docker.sock 10.1.198.114:5010/tool-centos:8.0 /bin/bash

```



# rules:changes

- Paths to files. In GitLab 13.6 and later, [file paths can include variables](https://docs.gitlab.com/16.6/ee/ci/jobs/job_control.html#variables-in-ruleschanges). A file path array can also be in [`rules:changes:paths`](https://docs.gitlab.com/16.6/ee/ci/yaml/index.html#ruleschangespaths).

