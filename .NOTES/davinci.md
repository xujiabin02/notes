







# selenium-chrom

## 1)

```
docker run -p 4444:4444 -d --name selenium-chrome --shm-size="2g" selenium/standalone-chrome
```

## 2)



下载google-chrome

```sh
curl https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm -O
dnf localinstall google-chrome-stable_current_x86_64.rpm
```



chromedriver少库libnss3

```sh
yum install -y libnss3*
```

