# helm上传

```shell
helm plugin install --version master https://github.com/sonatype-nexus-community/helm-nexus-push.git
helm nexus-push localrepo login -u name -p pass.123
helm nexus-push localrepo kettle-0.1.0.tgz
```

