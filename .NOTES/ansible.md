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

