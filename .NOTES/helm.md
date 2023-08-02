# Job database migration

search keyword `k8s job 迁移数据库`

https://learnku.com/articles/43850

# 只渲染不安装

```sh
helm install --debug --dry-run goodly-guppy ./mychart
```

使用`--dry-run`会让你变得更容易测试，但不能保证Kubernetes会接受你生成的模板。 最好不要仅仅因为`--dry-run`可以正常运行就觉得chart可以安装。





