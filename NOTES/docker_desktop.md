## Windows Docker配置镜像源的两种方法

更新时间 2022.04.14
通过**Docker-Desktop**界面操作和修改**daemon.json**两种方法配置国内镜像源

### 方法一：通过Docker-Desktop配置

- 点击**设置**

![在这里插入图片描述](https://img-blog.csdnimg.cn/c2038aef9ffe43819e8e3100fbdc9119.png?x-oss-process=image/watermark,type_d3F5LXplbmhlaQ,shadow_50,text_Q1NETiBA54Gs5YCq5YWI5qOuXw==,size_20,color_FFFFFF,t_70,g_se,x_16)



选择 **Docker Engine**

![在这里插入图片描述](https://img-blog.csdnimg.cn/db8a54f8027044aab11aa01a820fc833.png?x-oss-process=image/watermark,type_d3F5LXplbmhlaQ,shadow_50,text_Q1NETiBA54Gs5YCq5YWI5qOuXw==,size_20,color_FFFFFF,t_70,g_se,x_16)



- 添加以下源地址

	"registry-mirrors": [
	    "https://docker.chenby.cn",
	    "docker.awsl9527.cn"
	]

![在这里插入图片描述](https://img-blog.csdnimg.cn/d1a48e3e6d52489f8a90d72e4e968377.png?x-oss-process=image/watermark,type_d3F5LXplbmhlaQ,shadow_50,text_Q1NETiBA54Gs5YCq5YWI5qOuXw==,size_20,color_FFFFFF,t_70,g_se,x_16)