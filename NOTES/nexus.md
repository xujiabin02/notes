# helm上传

```shell
helm plugin install --version master https://github.com/sonatype-nexus-community/helm-nexus-push.git
helm nexus-push localrepo login -u name -p pass.123
helm nexus-push localrepo kettle-0.1.0.tgz
```



# npm publish支持

设置–Security–Realms–把npm Bearer Token [Realm](https://so.csdn.net/so/search?q=Realm&spm=1001.2101.3001.7020)添加到Active

![在这里插入图片描述](nexus.assets/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3dlaXhpbl80NDk1ODQ3Ng==,size_16,color_FFFFFF,t_70.png)
