

# apt-get install libwebkitgtk-1.0-0





如果您正在執行 Debian，請儘量使用像 [aptitude](https://packages.debian.org/stretch/aptitude) 或者 [synaptic](https://packages.debian.org/stretch/synaptic) 一樣的套件管理器，代替人工手動操作的方式從這個網頁下載並安裝套件。

您可以使用以下列表中的任何一個源映象只要往您的 /etc/apt/sources.list 檔案中像下面這樣新增一行：

```
deb http://ftp.de.debian.org/debian stretch main 
```

請使用最終確定的源映象替換 *ftp.de.debian.org/debian*。



# 国内源

### 常用安装源站点列表

**163镜像站** 

```javascript
deb http://mirrors.163.com/debian/ buster main non-free contrib
deb http://mirrors.163.com/debian/ buster-updates main non-free contrib
deb http://mirrors.163.com/debian/ buster-backports main non-free contrib
deb http://mirrors.163.com/debian-security/ buster/updates main non-free contrib

deb-src http://mirrors.163.com/debian/ buster main non-free contrib
deb-src http://mirrors.163.com/debian/ buster-updates main non-free contrib
deb-src http://mirrors.163.com/debian/ buster-backports main non-free contrib
deb-src http://mirrors.163.com/debian-security/ buster/updates main non-free contrib
```

复制

**华为云镜像站**

```javascript
deb https://mirrors.huaweicloud.com/debian/ buster main contrib non-free
deb https://mirrors.huaweicloud.com/debian/ buster-updates main contrib non-free
deb https://mirrors.huaweicloud.com/debian/ buster-backports main contrib non-free
deb https://mirrors.huaweicloud.com/debian-security/ buster/updates main contrib non-free

deb-src https://mirrors.huaweicloud.com/debian/ buster main contrib non-free
deb-src https://mirrors.huaweicloud.com/debian/ buster-updates main contrib non-free
deb-src https://mirrors.huaweicloud.com/debian/ buster-backports main contrib non-free 
```

复制

[**腾讯云**](https://s.debian.cn/qc11)**镜像站**

```javascript
deb http://mirrors.cloud.tencent.com/debian/ buster main non-free contrib
deb http://mirrors.cloud.tencent.com/debian-security buster/updates main
deb http://mirrors.cloud.tencent.com/debian/ buster-updates main non-free contrib
deb http://mirrors.cloud.tencent.com/debian/ buster-backports main non-free contrib

deb-src http://mirrors.cloud.tencent.com/debian-security buster/updates main
deb-src http://mirrors.cloud.tencent.com/debian/ buster main non-free contrib
deb-src http://mirrors.cloud.tencent.com/debian/ buster-updates main non-free contrib
deb-src http://mirrors.cloud.tencent.com/debian/ buster-backports main non-free contrib
```

复制

**中科大镜像站**

```javascript
deb https://mirrors.ustc.edu.cn/debian/ buster main contrib non-free
deb https://mirrors.ustc.edu.cn/debian/ buster-updates main contrib non-free
deb https://mirrors.ustc.edu.cn/debian/ buster-backports main contrib non-free
deb https://mirrors.ustc.edu.cn/debian-security/ buster/updates main contrib non-free

deb-src https://mirrors.ustc.edu.cn/debian/ buster main contrib non-free
deb-src https://mirrors.ustc.edu.cn/debian/ buster-updates main contrib non-free
deb-src https://mirrors.ustc.edu.cn/debian/ buster-backports main contrib non-free
deb-src https://mirrors.ustc.edu.cn/debian-security/ buster/updates main contrib non-free
```

复制

**阿里云镜像站**

```javascript
deb http://mirrors.aliyun.com/debian/ buster main non-free contrib
deb http://mirrors.aliyun.com/debian-security buster/updates main
deb http://mirrors.aliyun.com/debian/ buster-updates main non-free contrib
deb http://mirrors.aliyun.com/debian/ buster-backports main non-free contrib

deb-src http://mirrors.aliyun.com/debian-security buster/updates main
deb-src http://mirrors.aliyun.com/debian/ buster main non-free contrib
deb-src http://mirrors.aliyun.com/debian/ buster-updates main non-free contrib
deb-src http://mirrors.aliyun.com/debian/ buster-backports main non-free contrib
```

复制

**清华大学镜像站**

```javascript
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ buster main contrib non-free
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ buster-updates main contrib non-free
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ buster-backports main contrib non-free
deb https://mirrors.tuna.tsinghua.edu.cn/debian-security/ buster/updates main contrib non-free

deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ buster main contrib non-free
deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ buster-updates main contrib non-free
deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ buster-backports main contrib non-free
deb-src https://mirrors.tuna.tsinghua.edu.cn/debian-security/ buster/updates main contrib non-free
```

复制

**兰州大学镜像站**

```javascript
deb http://mirror.lzu.edu.cn/debian stable main contrib non-free
deb http://mirror.lzu.edu.cn/debian stable-updates main contrib non-free
deb http://mirror.lzu.edu.cn/debian/ buster-backports main contrib non-free
deb http://mirror.lzu.edu.cn/debian-security/ buster/updates main contrib non-free

deb-src http://mirror.lzu.edu.cn/debian stable main contrib non-free
deb-src http://mirror.lzu.edu.cn/debian stable-updates main contrib non-free
deb-src http://mirror.lzu.edu.cn/debian/ buster-backports main contrib non-free
deb-src http://mirror.lzu.edu.cn/debian-security/ buster/updates main contrib non-free
```

复制

**上海交大镜像站**

```javascript
deb https://mirror.sjtu.edu.cn/debian/ buster main contrib non-free
deb https://mirror.sjtu.edu.cn/debian/ buster-updates main contrib non-free
deb https://mirror.sjtu.edu.cn/debian/ buster-backports main contrib non-free
deb https://mirror.sjtu.edu.cn/debian-security/ buster/updates main contrib non-free

deb-src https://mirror.sjtu.edu.cn/debian/ buster-updates main contrib non-free
deb-src https://mirror.sjtu.edu.cn/debian/ buster-backports main contrib non-free
deb-src https://mirror.sjtu.edu.cn/debian/ buster main contrib non-free
deb-src https://mirror.sjtu.edu.cn/debian-security/ buster/updates main contrib non-free
```

复制

附上官方全球镜像站列表地址：https://www.debian.org/mirror/list