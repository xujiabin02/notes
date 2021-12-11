在ansible中foo_port是合法的变量名



```yml
include:
 c: playbook
 a: 
 - 
tags:
 c: 实现部分运行play-book的机制
 a: 
 - 打相同tags实现依赖? 
 - 重跑role
defaults:
 c: role中最低优先级,预设值
 a: 默认值
meta:
 c: '依赖,被多个role添加不会重复执行,allow_duplicates: yes可打开重复'
 a: 依赖
内置变量:
 c: hostvars,group_names,groups,environmen
 a: 负载均衡遍历host
分文件host和groups变量:
 c: playbook dir 覆盖inventory dir
 a:
 - playbook dir
 - inventory dir 
vault加密:
 c: password,keys,defaults,handlers加密,默认加密方式是AES
 a: 
 - 安全审计
{{ ansible_managed }}:
 c: |- 
 '默认设置可以哪个用户修改和修改时间: ansible_managed = Ansible managed: {file} modified on %Y-%m-%d %H:%M:%S by {uid} on {host}'
 a: 
 - 记录变更
 - 审计用户
handlers:
 c: 在发生改变时执行的操作, 多个改动只触发一次, 如果没有notify,handlers不会被执行, 不管有多少个通知进行了notify, 等到play 中的所有task执行完成,handlers也只会被执行一次
 a: 
 - 触发重启服务
```





```yml
production                # inventory file for production servers 关于生产环境服务器的清单文件
stage                     # inventory file for stage environment 关于 stage 环境的清单文件

group_vars/
   group1                 # here we assign variables to particular groups 这里我们给特定的组赋值
   group2                 # ""
host_vars/
   hostname1              # if systems need specific variables, put them here 如果系统需要特定的变量,把它们放置在这里.
   hostname2              # ""

library/                  # if any custom modules, put them here (optional) 如果有自定义的模块,放在这里(可选)
filter_plugins/           # if any custom filter plugins, put them here (optional) 如果有自定义的过滤插件,放在这里(可选)

site.yml                  # master playbook 主 playbook
webservers.yml            # playbook for webserver tier Web 服务器的 playbook
dbservers.yml             # playbook for dbserver tier 数据库服务器的 playbook

roles/
    common/               # this hierarchy represents a "role" 这里的结构代表了一个 "role"
        tasks/            #
            main.yml      #  <-- tasks file can include smaller files if warranted
        handlers/         #
            main.yml      #  <-- handlers file
        templates/        #  <-- files for use with the template resource
            ntp.conf.j2   #  <------- templates end in .j2
        files/            #
            bar.txt       #  <-- files for use with the copy resource
            foo.sh        #  <-- script files for use with the script resource
        vars/             #
            main.yml      #  <-- variables associated with this role
        defaults/         #
            main.yml      #  <-- default lower priority variables for this role
        meta/             #
            main.yml      #  <-- role dependencies

    webtier/              # same kind of structure as "common" was above, done for the webtier role
    monitoring/           # ""
    fooapp/               # ""
```

# ansible-vault

https://github.com/tomoh1r/ansible-vault/wiki/sample

https://github.com/jhaals/ansible-vault



# 常用builtin

https://docs.ansible.com/ansible/latest/collections/ansible/builtin/index.html

[goto](# 排序)



# 内置变量

## ansible-playbook内置变量

(https://www.jianshu.com/u/e714de66d8fd)

[绅士喵m](https://www.jianshu.com/u/e714de66d8fd)关注

2019.08.27 17:08:27字数 460阅读 2,516

我们可以使用ansible-playbook的内置变量实现主机相关的逻辑判断。本篇介绍7个常用的内置变量：

## 1.gourps和group_names

groups是一个全局变量，它会打印出Inventory文件里面的所有主机以及主机组信息，它返回的是一个JSON字符串，我们可以直接把它当作一个变量，使用{{ groups }}格式调用。当然也可以使用{{ groups['all'] }}引用其中一个的数据。变量会打印当前主机所在的groups名称，如果没有定义会返回ungrouped，它返回的组名是一个list列表。

## 2.hostvars

hostvars是用来调用指定的主机变量，需要传入主机信息，返回结果也是一个JSON字符串，同样，也可以直接引用JSON字符串内的指定信息。

## 3.inventory_hostname和inventory_hostname_short

inventory_hostname返回的是Inventory文件里面定义的主机名，inventory_hostname_short返回的是Inventory文件里面定义的主机名的第一部分。

## 4.play_hosts和inventory_dir

play_hosts变量时用来返回当前playbook运行的主机信息，返回格式是主机list结构，inventory_dir变量时返回当前playbook使用的Inventory目录。

# KMS

https://growingio.feishu.cn/docs/doccnpgUZAhEVAePkmRvSXJcaWc#



# ansible连接客户端selinux问题

文章来自 本末丶 's Blog // 道路千万条。。。

* [Home](http://blog.leanote.com/benmo)
*  

* [About Me](http://blog.leanote.com/single/benmo/About-Me)
*  

* [Tags](http://blog.leanote.com/tags/benmo)
*  

* [Archives](http://blog.leanote.com/archives/benmo)

我们在新增服务器后通常会执行以下操作来手动关闭客户端的selinux

```
sed -i 's/=enforcing/=disabled/' /etc/selinux/configsetenforce 0
```

在我们不重启客户端的情况下，服务器的selinux处于'Permissive'状态，不影响我们我实际操作。

 

此时我们用ansible测试到客户机的连通性

```
# ansible node04 -m ping -u root -kSSH password: node04 | SUCCESS => {    "changed": false,    "ping": "pong"}
```

看似一切正常，但我们使用部分模块操作时，却发现selinux检查并不通过：

```
ansible node04 -m copy -a 'src=app-info.log dest=/tmp/' -kSSH password: node04 | FAILED! => {    "changed": false,    "checksum": "a3bf6211a787d7a51122a2ff406ddd72b67c6701",    "msg": "Aborting, target uses selinux but python bindings (libselinux-python) aren't installed!"}
```

 

在不重启客户端的情况下，我们需要按照提示安装'libselinux-python'才能操作客户端，但是，此时不能通过yum/shell模块去操作，因为yum/shell模块依赖python,会得到如上一样的报错反馈，所以此时，我们使用不依赖python的raw去安装。

```
# ansible node04 -m raw -a 'yum -y install libselinux-python' -k -onode04 | CHANGED | rc=0 | (stdout) 已加载插件：fastestmirror\r\nLoading mirror speeds from cached hostfile\r\n * base: mirrors.aliyun.com\r\n * epel: mirrors.tongji.edu.cn\r\n * extras: mirrors.163.com\r\n * updates: mirrors.sohu.com\r\n正在解决依赖关系\r\n--> 正在检查事务\r\n---> 软件包 libselinux-python.x86_64.0.2.5-12.el7 将被 安装\r\n--> 解决依赖关系完成\r\n\r\n依赖关系解决\r\n\r\n================================================================================\r\n Package                   架构           版本               源            大小\r\n================================================================================\r\n正在安装:\r\n libselinux-python         x86_64         2.5-12.el7         base         235 k\r\n\r\n事务概要\r\n================================================================================\r\n安装  1 软件包\r\n\r\n总下载量：235 k\r\n安装大小：589 k\r\nDownloading packages:\r\n\rlibselinux-python-2.5-12.el7.x86_64.rpm                    | 235 kB   00:00     \r\nRunning transaction check\r\nRunning transaction test\r\nTransaction test succeeded\r\nRunning transaction\r\n\r  正在安装    : libselinux-python-2.5-12.el7 [                            ] 1/1\r  正在安装    : libselinux-python-2.5-12.el7 [##                          ] 1/1\r  正在安装    : libselinux-python-2.5-12.el7 [#####                       ] 1/1\r  正在安装    : libselinux-python-2.5-12.el7 [########                    ] 1/1\r  正在安装    : libselinux-python-2.5-12.el7 [###########                 ] 1/1\r  正在安装    : libselinux-python-2.5-12.el7 [#############               ] 1/1\r  正在安装    : libselinux-python-2.5-12.el7 [################            ] 1/1\r  正在安装    : libselinux-python-2.5-12.el7 [###################         ] 1/1\r  正在安装    : libselinux-python-2.5-12.el7 [######################      ] 1/1\r  正在安装    : libselinux-python-2.5-12.el7 [########################    ] 1/1\r  正在安装    : libselinux-python-2.5-12.el7 [########################### ] 1/1\r  正在安装    : libselinux-python-2.5-12.el7.x86_64                         1/1 \r\n\r  验证中      : libselinux-python-2.5-12.el7.x86_64                         1/1 \r\n\r\n已安装:\r\n  libselinux-python.x86_64 0:2.5-12.el7
```

之后，我们再次执行之前的copy操作，可以正常进行，且可以看到它多设置了一个secontext的上下文

```
# ansible node04 -m copy -a 'src=app-info.log dest=/tmp/' -kSSH password: node04 | SUCCESS => {    "changed": true,    "checksum": "57bbe08bca53bc6cb8c3ad4855730a64f158068e",    "dest": "/tmp/app-info.log",    "gid": 0,    "group": "root",    "md5sum": "9e04f215d41cf64fbf4280643c8e6f50",    "mode": "0644",    "owner": "root",    "secontext": "unconfined_u:object_r:user_home_t:s0",    "size": 23070,    "src": "/home/pengjk/.ansible/tmp/ansible-tmp-1529043022.9829628-60924778876197/source",    "state": "file",    "uid": 0}
```

 

另外，还有一种情况是，我们的客户机无法上网，也没有内部yum源，在运行的服务器也不能随便重启，此时我们只能通过修改源码来解决。

1).首先我们进入到ansible源码目录，通过报错提示关键字'libselinux-python',找出源代码文件'module_utils/basic.py'

```sh
### 我是linux Minit，CentOS7在/usr/lib/python2.7/site-packages/ansible下# cd /usr/local/lib/python3.5/dist-packages/ansible# grep '(libselinux-python)' -RBinary file module_utils/__pycache__/basic.cpython-35.pyc matchesmodule_utils/basic.py:                    self.fail_json(msg="Aborting, target uses selinux but python bindings (libselinux-python) aren't installed!")
```

 

2).vim打开'module_utils/basic.py'，搜索'libselinux-python'关键字，在1007行左右

```sh
1001     def selinux_enabled(self):1002         if not HAVE_SELINUX:1003             seenabled = self.get_bin_path('selinuxenabled')1004             if seenabled is not None:1005                 (rc, out, err) = self.run_command(seenabled)1006                 if rc == 0:1007                     self.fail_json(msg="Aborting, target uses selinux but python bindings (libselinux-python) aren't installed!")1008             return False1009         if selinux.is_selinux_enabled() == 1:1010             return True1011         else:1012             return False
```

 

我们可以看到，之所以手动关闭不生效是因为，ansible使用'selinuxenabled'命令的返回值来判断selinux是否开启，为了满足我们的需求，我们需要修改如下。

```sh
### 即：当getenforce 0的结果为'Disabled','Permissive'的任意一个，都认为selinux已经关闭### 注意: 更新或者重新安装后，修改的配置会被还原！1001     def selinux_enabled(self):1002         if not HAVE_SELINUX:1003             #seenabled = self.get_bin_path('selinuxenabled')1004             seenabled = self.get_bin_path('getenforce')1005             if seenabled is not None:1006                 (rc, out, err) = self.run_command(seenabled)1007                 #if rc == 0:1008                 if out not in ['Disabled','Permissive']:1009                     self.fail_json(msg="Aborting, target uses selinux but python bindings (libselinux-python) aren't installed!")1010             return False1011         if selinux.is_selinux_enabled() == 1:1012             return True1013         else:1014             return False
```

 

3).我们再次执行copy操作，可以正常进行，且发现没有'secontext'的上下文描述

```sh
# ansible node04 -m copy -a 'src=app-info.log dest=/tmp/' -kSSH password: node04 | SUCCESS => {    "changed": true,    "checksum": "7d5a15ba26b69709981698de261e06592bb283d5",    "dest": "/tmp/app-info.log",    "gid": 0,    "group": "root",    "md5sum": "ba709129a47ddfc61cc8ff2373846e31",    "mode": "0644",    "owner": "root",    "size": 103806,    "src": "/home/pengjk/.ansible/tmp/ansible-tmp-1529045191.0324137-179005958155180/source",    "state": "file",    "uid": 0}
```

# [并行和异步](http://www.ansible.com.cn/docs/playbooks_async.html)



[gosshtool](https://github.com/kggg/gosshtool)



11.11 第三方策略插件：[Mitogen for Ansible](https://mitogen.networkgenomics.com/ansible_detailed.html#installation)



```
$ wget 'https://networkgenomics.com/try/mitogen-0.2.9.tar.gz'
$ mkdir -p ~/.ansible/plugins
$ tar xf mitogen-0.2.9.tar.gz -C ~/.ansible/plugins/
```



# 速度

```ini
[defaults]
callback_whitelist = profile_tasks
```

# 排序

|          |                   |          |
| -------- | ----------------- | -------- |
| 冒泡排序 | [写法](#冒泡算法) | 稳定排序 |
| 选择排序 | [code](#选择排序) |          |
| 插入排序 | [code](#插入排序) |          |





# ansible-playbook的branch的实现



```yml
- name: "if else"
  include_tasks: "test{{ item }}.yml"
  with_items: "{{ my_list }}"
```





拼出dict

```yaml
- set_fact:
    genders: "{{ genders|default({}) | combine( {item.item.name: item.stdout} ) }}"
  with_items: "{{ people.results }}"
```

接出列表

```yml
- name: Register changed title
  set_fact:
    grafana_changed_title_list: "{{ grafana_changed_title_list|default([]) + [ (lookup('file', item.dest)|from_json).title ] }}"
  when: item.changed
  with_items: "{{ push_changed.results }}"
```

读json文件

```yml
version_file: "{{ lookup('file','/home/shasha/devOps/tests/packageFile.json') | from_json }}"
```











## 冒泡算法

```go
func bubbleSort(listPao []int) []int {
	//冒泡排序
	num := 0
	for i:=len(listPao)-1;i>0;i-- {
		for j:=0;j<i;j++{
			if listPao[j] > listPao[j+1]{
				num = listPao[j]
				listPao[j] = listPao[j+1]
				listPao[j+1] = num
			}
		}
	}
	return listPao

}
```

## 选择排序



## 插入排序

演示

![img](.img_ansible/v2-91b76e8e4dab9b0cad9a017d7dd431e2_b.webp)

```java
public static void insertionSort(int[] arr){
    for (int i=1; i<arr.length; ++i){
        int value = arr[i];
        int position=i;
        while (position>0 && arr[position-1]>value){
            arr[position] = arr[position-1];
            position--;
        }
        arr[position] = value;
    }//loop i
}
```



# ---

