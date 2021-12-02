

hive数据同步

https://hadoop.apache.org/docs/r1.0.4/cn/distcp.html



# Cloudera [parcels](https://github.com/cloudera/cm_ext/wiki/The-parcel-format)

## [Parcels](https://github.com/cloudera/cm_ext/wiki/The-parcel-format)

[参考](https://github.com/cloudera/cm_ext/wiki#parcels-deploying-services)

parcels 是cloudera 4.5中引入的一种包管理格式，与linux平台上的deb包、rpm包类似但是也有一些区别，parcels特点如下：

* 可以打包成单个parcels
  * 这样有助于包的分发管理，例如在4.5没有引入parcels之前CDH是好多个包，多个集群分发明显比一个包蛮烦很多。
  * 多个服务集群到一起有助于见效多个不通服务版本之前的问题。
* parcels 可以安装到系统中的任何位置
  * 在某些环节下安装cdh的客户并没有安装系统软件的权限，所以以前只能手动一个一个tar包而使用parcels可以安装到系统的任何位置。
  * 安装parcels不用需要系统的sudo环境，因为cloudera agent是通过root启动的所以通过agent安装不需要sudo
* side-by-side的安装方式，不同的服务在安装地址下存在不同版本的安装路径
  * 多个版本安装不冲突使得对于服务升级很容易，先安装升级parcels包后切换版本就好了.(使得服务时间大大缩短了，只有在切换这段时间需要终端服务)
  * 滚动升级的支持，由于不同版本切换很容易所以CDH多个版本之前切换也就是客户端启动更新之后的目录下的程序而已。
  * 降低版本支持，agent切换到低版本运行即可。

parcels的提出使得cloudera 对于包的管理生命周期化了，例如如下列出了parcels不同阶段,以及不同阶段的转化操作。

* activate 阶段

parcels包发送到各个节点后，最后一个动作是激活parcels包，这个步骤是建立一个目录链接，执行脚本(主要是一些环境变量，通过环境变量更新后续csd服务启动时就可以运行程序了)

*parcels包格式*

parcels 等效于tar安装包加上一些描述文件metadata，除过metadata与tar安装包没有任何差别，parcels就是一个包含一堆文件的jar包，里面文件其实没有什么特殊的规则。
名字规范为 `[name]-[version]-[distro suffix].parcel`
例如 `tar zcvf GPLEXTRAS-5.0.0-gplextras5b2.p0.32-el6.parcel GPLEXTRAS-5.0.0-gplextras5b2.p0.32/ --owner=root --group=root`

distro suffix 参见如下：

*与现有系统交互方式*

parcel只有在激活时才能触发操作，让其它服务发现。

* parcel激活时创建全局的可执行文件(固定位置)。
* 设置环境变量

*文件夹metadata*

* parcel.json

  必须要有的，其它文件都是可选的, 下面是一个例子通过这个例子来说明下一些key字段的含义。

  ```
  {
  "schema_version": 1,    // 直接写1，没啥说的
  
  
  "name": "CDH",
  "version": "5.0.0",
                       /*
                          name 与 version 是 parcel 的基本信息，Parcel安装目录文件名称必须为'name-version' 格式。
                          cm会校验这个名称。另外这个名称也必须与parcel名称格式匹配
  
  
                       /*
  "setActiveSymlink": true,
  
  "depends": "",
  "replaces": "IMPALA, SOLR, SPARK",
  "conflicts": "",
  
                    /*
                       depends： 此parcel依赖的parcel名称
                      replaces：此parcel 会替代的parcel。
                      conflicts 冲突的parcel.
  
  
                    */
  
  "provides": [
  "cdh",
  "impala",
  "solr",
  "spark"
  ],
                    /*
                    provides 这里面是设置tags标签的，这里有一个tagging概念用来标明哪些进程服务需要访问parcel。
                    也就是说 parcel包里面通过 provides提供 标签，在服务里面注册parcel设置的标签(设置进程服务与parcel对应关系)
                    这样也就可以知道在删除、更新等管理parcel时哪些服务需要优先处理。
  
                    */
  
  "scripts": {
  "defines": "cdh_env.sh"
  },
  
                     /*
                        目前只能设置一个脚本，这个脚本是在服务进程启动(通过provides tags 关联进程服务)加载进环境变量的,这个文件必须有即使为空文件。
  
  
                     */
  
  "packages": [
  { "name"   : "hadoop",
    "version": "2.2.0+cdh5.0.0+609-0.cdh5b2.p0.386~precise-cdh5.0.0"
  },
  { "name"   : "hadoop-client",
    "version": "2.2.0+cdh5.0.0+609-0.cdh5b2.p0.386~precise-cdh5.0.0"
  },
  { "name"   : "hadoop-hdfs",
    "version": "2.2.0+cdh5.0.0+609-0.cdh5b2.p0.386~precise-cdh5.0.0"
  }
  ],
  
                     /*
                          这里cloudera manager 不直接使用，适用于包里有一系列的服务情况，例如CDH下的各种服务
  
  
                     */
  
  "components": [
  { "name"       : "hadoop",
    "version"    : "2.2.0-cdh5.0.0-SNAPSHOT",
    "pkg_version": "2.2.0+cdh5.0.0+609",
    "pkg_release": "0.cdh5.0.0.p0.386"
  },
  { "name"       : "hadoop-hdfs",
    "version"    : "2.2.0-cdh5.0.0-SNAPSHOT",
    "pkg_version": "2.2.0+cdh5.0.0+609",
    "pkg_release": "0.cdh5.0.0.p0.386"
  }
  ],
  
                          /*
  
  
  
                          */
  
  
  
  "users": {
  "hdfs": {
    "longname"    : "Hadoop HDFS",
    "home"        : "/var/lib/hadoop-hdfs",
    "shell"       : "/bin/bash",
    "extra_groups": [ "hadoop" ]
  },
  "impala": {
    "longname"    : "Impala",
    "home"        : "/var/run/impala",
    "shell"       : "/bin/bash",
    "extra_groups": [ "hive", "hdfs" ]
  }
  },
  
  "groups": [
  "hadoop"
  ]
  }   
  
              /*
                  这个描述涉及的用户、组信息
  
              */
  ```

* Environment Script

  在parcel.json中设置服务进程启动加载环境变量

  

* alternatives.json
  设置系统命令与parcel链接，当parcel激活时系统命令链接创建，当parcel删除时链接删除。当在不同parcel版本之间切换时系统命令也会切换。

  ```
  {
  "avro-tools": {    //名称
    "destination": "/usr/bin/avro-tools",  //创建链接的绝对路径
    "source": "bin/avro-tools",            // 链接指向parcel相对路径地址
    "priority": 10,                        // 多个链接指向时优先级高的胜
    "isDirectory": false                  // 是否是目录，目录与非目录处理方式不一致
  },
  "beeline": {
    "destination": "/usr/bin/beeline",
    "source": "bin/beeline",
    "priority": 10,
    "isDirectory": false
  },
  "hadoop": {
    "destination": "/usr/bin/hadoop",
    "source": "bin/hadoop",
    "priority": 10,
    "isDirectory": false
  },
  "hbase-conf": {
    "destination": "/etc/hbase/conf",
    "source": "etc/hbase/conf.dist",
    "priority": 10,
    "isDirectory": true
  },
  "hbase-solr-conf": {
    "destination": "/etc/hbase-solr/conf",
    "source": "etc/hbase-solr/conf.dist",
    "priority": 10,
    "isDirectory": true
  },
  "hive-conf": {
    "destination": "/etc/hive/conf",
    "source": "etc/hive/conf.dist",
    "priority": 10,
    "isDirectory": true
  }
  }
  ```

* permissions.json

  具体到压缩包里面的文件的每一个文件都可以设置权限、组、permissions。

  

  ```
  {
  "lib/hadoop-0.20-mapreduce/sbin/Linux/task-controller": {
  "user":  "root",
  "group": "mapred",
  "permissions": "4754"
  },
  "lib/hadoop-yarn/bin/container-executor": {
  "user":  "root",
  "group": "yarn",
  "permissions": "6050"
  },
  "lib/hue/desktop": {
  "user":  "hue",
  "group": "hue",
  "permissions": "0755"
  }
  }
  ```

* release-notes.txt

  release-notes文件中的内容会填充在 manifest.json 文件 releaseNotes中，用来显示在CM 界面中提示信息。

  

*压缩*

cloudera 只支持未压缩文件(仅仅tar打包)与gzip压缩格式

*Cloudera Manager限制要求*

cloudera manager 支持的parcel，对parcel有一些限制要求

1. parcel 解压后的包是不能修改的(parcel包升级后从其它文件夹启动服务老的修改就会丢失)、parcel里面的文件是与位置无关的(parcel安装位置是由用户选择的，parcel安装服务位置固定的话用户选择不一致就会有问题)。安装路径可以通过parcel environment 脚本获取。
2. 支持外部加载配置文件

*一些问题*

* 更新parcel格式，重新发布没有更新

我在实际使用过程中当修改了parcel包中的属性文件时重新发布时没有变化，搞了好久最后是删除
/opt/cloudera/parcels/.flood/ 目录下的parcel后在重新发布就可以了，至于flood目录的作用我在官方文档下也没有找到
