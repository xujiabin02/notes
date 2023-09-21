# 学习进展

|      |      |      |
| ---- | ---- | ---- |
|      |      |      |
|      |      |      |
|      |      |      |



# Nginx在URL末尾不加斜杠的重定向



问题描述：

> Nginx在访问带目录的URL时，如果末尾不加斜杠（“/”），Nginx默认会自动加上，其实是返回了一个301跳转，在新的Location中加了斜杠。但这个默认行为在Nginx前端有LB负载均衡器、且LB的端口与Nginx Server监听的端口不同时，可能会导致访问出错。比如域名所指向的LB对外监听端口80，转发到后端==Nginx 8080==端口，当Nginx进行上述自动重定向时，导致重定向到了域名的8080端口

 

解决方案:

> 1. 新版本nginx（≥1.11.8）可以通过设置 ==absolute_redirect off;== 来解决：
> 2. LB是80端口的，旧版本nginx（＜1.11.8）可以增加 ==port_in_redirect off;==参数来解决：

# http强制跳转到https的方法梳理

**-http访问强制跳转到https---------------------------------** 网站添加了https证书后，当http方式访问网站时就会报404错误，所以需要做http到https的强制跳转设置.

**---------------一、采用nginx的rewrite方法---------------------**

```javascript
1) 下面是将所有的http请求通过rewrite重写到https上。
    例如将所有的dev.wangshibo.com域名的http访问强制跳转到https。
    下面配置均可以实现：

配置1：
server {
    listen 80;
    server_name dev.wangshibo.com;
    index index.html index.php index.htm;
  
    access_log  /usr/local/nginx/logs/8080-access.log main;
    error_log  /usr/local/nginx/logs/8080-error.log;
    
    rewrite ^(.*)$  https://$host$1 permanent;        //这是ngixn早前的写法，现在还可以使用。
 
    location ~ / {
    root /var/www/html/8080;
    index index.html index.php index.htm;
    }
    }

-------------------------------------------------------
上面的跳转配置rewrite ^(.*)$  https://$host$1 permanent; 
也可以改为下面
rewrite ^/(.*)$ http://dev.wangshibo.com/$1 permanent;
或者
rewrite ^ http://dev.wangshibo.com$request_uri? permanent;
-------------------------------------------------------

配置2：
server {
    listen 80;
    server_name dev.wangshibo.com;
    index index.html index.php index.htm;
  
    access_log  /usr/local/nginx/logs/8080-access.log main;
    error_log  /usr/local/nginx/logs/8080-error.log;

    return      301 https://$server_name$request_uri;      //这是nginx最新支持的写法
 
    location ~ / {
    root /var/www/html/8080;
    index index.html index.php index.htm;
    }
    }


配置3：这种方式适用于多域名的时候，即访问wangshibo.com的http也会强制跳转到https://dev.wangshibo.com上面
server {
    listen 80;
    server_name dev.wangshibo.com wangshibo.com *.wangshibo.com;
    index index.html index.php index.htm;
  
    access_log  /usr/local/nginx/logs/8080-access.log main;
    error_log  /usr/local/nginx/logs/8080-error.log;
    
    if ($host ~* "^wangshibo.com$") {
    rewrite ^/(.*)$ https://dev.wangshibo.com/ permanent;
    }
 
    location ~ / {
    root /var/www/html/8080;
    index index.html index.php index.htm;
    }
    }


配置4：下面是最简单的一种配置
server {
    listen 80;
    server_name dev.wangshibo.com;
    index index.html index.php index.htm;
  
    access_log  /usr/local/nginx/logs/8080-access.log main;
    error_log  /usr/local/nginx/logs/8080-error.log;
    
    if ($host = "dev.wangshibo.com") {
       rewrite ^/(.*)$ http://dev.wangshibo.com permanent;
    }

    location ~ / {
    root /var/www/html/8080;
    index index.html index.php index.htm;
    }
    }
```

**---------------二、采用nginx的497状态码---------------------**

```javascript
497 - normal request was sent to HTTPS  
解释：当网站只允许https访问时，当用http访问时nginx会报出497错误码
 
思路：
利用error_page命令将497状态码的链接重定向到https://dev.wangshibo.com这个域名上

配置实例：
如下访问dev.wangshibo.com或者wangshibo.com的http都会被强制跳转到https
server {
    listen 80;
    server_name dev.wangshibo.com wangshibo.com *.wangshibo.com;
    index index.html index.php index.htm;
  
    access_log  /usr/local/nginx/logs/8080-access.log main;
    error_log  /usr/local/nginx/logs/8080-error.log;
    
    error_page 497  https://$host$uri?$args;  
 
    location ~ / {
    root /var/www/html/8080;
    index index.html index.php index.htm;
    }
    }


也可以将80和443的配置放在一起：
server {  
    listen       127.0.0.1:443;  #ssl端口  
    listen       127.0.0.1:80;   #用户习惯用http访问，加上80，后面通过497状态码让它自动跳到443端口  
    server_name  dev.wangshibo.com;  
    #为一个server{......}开启ssl支持  
    ssl                  on;  
    #指定PEM格式的证书文件   
    ssl_certificate      /etc/nginx/wangshibo.pem;   
    #指定PEM格式的私钥文件  
    ssl_certificate_key  /etc/nginx/wangshibo.key;  
      
    #让http请求重定向到https请求   
    error_page 497  https://$host$uri?$args;  

    location ~ / {
    root /var/www/html/8080;
    index index.html index.php index.htm;
    }
    }
```

**---------------三、利用meta的刷新作用将http跳转到https---------------------**

```javascript
上述的方法均会耗费服务器的资源，可以借鉴百度使用的方法：巧妙的利用meta的刷新作用，将http跳转到https
可以基于http://dev.wangshibo.com的虚拟主机路径下写一个index.html，内容就是http向https的跳转

将下面的内容追加到index.html首页文件内
[root@localhost ~]# cat /var/www/html/8080/index.html 
<html>  
<meta http-equiv="refresh" content="0;url=https://dev.wangshibo.com/">  
</html>

[root@localhost ~]# cat /usr/local/nginx/conf/vhosts/test.conf
server {
    listen 80;
    server_name dev.wangshibo.com wangshibo.com *.wangshibo.com;
    index index.html index.php index.htm;
  
    access_log  /usr/local/nginx/logs/8080-access.log main;
    error_log  /usr/local/nginx/logs/8080-error.log;
    
    #将404的页面重定向到https的首页  
    error_page  404 https://dev.wangshibo.com/;   
 
    location ~ / {
    root /var/www/html/8080;          
    index index.html index.php index.htm;
    }
    }
```

----------------------------------------------------------------------------------------------------------------------------- 下面是nginx反代tomcat，并且http强制跳转至https。 访问http://zrx.wangshibo.com和访问http://172.29.34.33:8080/zrx/结果是一样的

```javascript
[root@BJLX_34_33_V vhosts]# cat zrx.conf 
server {
    listen 80;
    server_name zrx.wangshibo.com;
    index index.html index.php index.htm;
   
    access_log  logs/access.log;
    error_log   logs/error.log;
 
    return      301 https://$server_name$request_uri;      
    
    location ~ / {
    root /data/nginx/html;
    index index.html index.php index.htm;
    }
    }


[root@BJLX_34_33_V vhosts]# cat ssl-zrx.conf 
upstream tomcat8 {
    server 172.29.34.33:8080 max_fails=3 fail_timeout=30s;
}

server {
   listen 443;
   server_name zrx.wangshibo.com;
   ssl on;

   ### SSL log files ### 
   access_log logs/ssl-access.log; 
   error_log logs/ssl-error.log; 

### SSL cert files ### 
   ssl_certificate ssl/wangshibo.cer;      
   ssl_certificate_key ssl/wangshibo.key;   
   ssl_session_timeout 5m;

   location / {
   proxy_pass http://tomcat8/zrx/;                                      
   proxy_next_upstream error timeout invalid_header http_500 http_502 http_503; 
   proxy_set_header Host $host; 
   proxy_set_header X-Real-IP $remote_addr; 
   proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for; 
   proxy_set_header X-Forwarded-Proto https; 
   proxy_redirect off; 
}
}
```

---------------四、通过proxy_redirec方式---------------------

```javascript
解决办法：
# re-write redirects to http as to https, example: /home
proxy_redirect http:// https://;
```

# Nginx的https配置

一、Nginx安装（略） 安装的时候需要注意加上 --with-http_ssl_module，因为http_ssl_module不属于Nginx的基本模块。 Nginx安装方法：

```javascript
# ./configure --user=www --group=www --prefix=/usr/local/nginx --with-http_stub_status_module --with-http_ssl_module
# make && make install
```

二、生成证书(略) 可以使用openssl生成证书： 可参考：[http://www.cnblogs.com/kevingrace/p/5865501.html](https://cloud.tencent.com/developer/article/1026357?from=10680) 比如生成如下两个证书文件（假设存放路径为/usr/local/nginx/cert/）： wangshibo.crt wangshibo.key

三、修改Nginx配置 

```ini
server {
          listen       443;
          server_name  www.wangshibo.com;
          root /var/www/vhosts/www.wangshibo.com/httpdocs/main/;      

          ssl on;
          ssl_certificate /usr/local/nginx/cert/wangshibo.crt;
          ssl_certificate_key /usr/local/nginx/cert/wangshibo.key;
          ssl_session_timeout  5m;
          ssl_protocols  SSLv2 SSLv3 TLSv1;
       ssl_ciphers  HIGH:!aNULL:!MD5; 
#或者是ssl_ciphers ALL:!ADH:!EXPORT56:RC4+RSA:+HIGH:+MEDIUM:+LOW:+SSLv2:+EXP;
  ssl_prefer_server_ciphers   on;

          access_log  /var/www/vhosts/www.wangshibo.com/logs/clickstream_ssl.log  main;
          error_log  /var/www/vhosts/www.wangshibo.com/logs/clickstream_error_ssl.log;

         if ($remote_addr !~ ^(124.165.97.144|133.110.186.128|133.110.186.88)) {           
         #对访问的来源ip做白名单限制
                rewrite ^.*$  /maintence.php last;
         }
 

         location ~ \.php$ {
              fastcgi_pass   127.0.0.1:9000;
              fastcgi_read_timeout 300;
              fastcgi_index  index.php;
              fastcgi_param  SCRIPT_FILENAME  /scripts$fastcgi_script_name;
             #include        fastcgi_params;
             include        fastcgi.conf;
         }
    }
```

# 多server_name的顺序问题



```
server {
	listen	80;
	server_name testserver1 127.0.0.1;
	location {
		...
	}
}
server {
	listen	80;
	server_name testserver2 127.0.0.1;
	location {
		...
	}
}

```

Nginx读取配置文件的时候是按照文件名顺序进行读取的，优先读取第一个文件名下的虚拟主机（IP端口相同）。
如server1.conf，server2.conf，那优先加载的配置是server1.conf下面的配置。

