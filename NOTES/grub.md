```diff
vi /etc/default/grub
#ubuntu
+ update-grub
如果找不到命令: apt-get install grub2-common
#centos
- grub2-mkconfig -o /boot/grub2/grub.cfg
```

