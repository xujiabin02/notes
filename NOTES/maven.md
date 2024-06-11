# mvn client push

```shell
mvn -s settings.xml deploy:deploy-file -DgroupId=pentaho-kettle -DartifactId=kettle-core -Dversion=9.0.0.0-423 -Dpackaging=jar -Dfile=9.0.0.0-423/kettle-core-9.0.0.0-423.jar -Durl=http://x.x.x.x:8888/repository/3rd/ -DrepositoryId=3rd-nexus
```

