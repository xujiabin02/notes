# NextCloud同步时显示错误423文件被lock解决方法

2019-01-14 263

登陆

```bash
docker exec -u www-data -ti 043cf4eb8c47 /bin/bash 
```

SSH到Server，并到NextCloud文件夹，执行如下命令：

```bash
occ ‘files:scan --all’
occ ‘files:cleanup’
occ ‘maintenance:mode --on’
mysql -u root -p’inheregoesyourpassword’ -D ocdb -e ‘delete from oc_file_locks where 1’
occ ‘maintenance:mode' --off
```



如果你的occ无法执行，那可能是由于PHP没有设置变量，可以通过手动指定PHP的运行变量来执行occ，例如：

```sh
sudo -u www /www/server/php/72/bin/php ./occ files:scan --all
```

重启你的Nextcloud webserver 并再次尝试，你的文件应该已经可以同步

