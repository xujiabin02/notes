## Windows Docker配置镜像源的两种方法

更新时间 2022.04.14
通过**Docker-Desktop**界面操作和修改**daemon.json**两种方法配置国内镜像源

### 方法一：通过Docker-Desktop配置

- 点击**设置**

![在这里插入图片描述](docker_desktop.assets/watermark,type_d3F5LXplbmhlaQ,shadow_50,text_Q1NETiBA54Gs5YCq5YWI5qOuXw==,size_20,color_FFFFFF,t_70,g_se,x_16.png)



选择 **Docker Engine**

![在这里插入图片描述](docker_desktop.assets/watermark,type_d3F5LXplbmhlaQ,shadow_50,text_Q1NETiBA54Gs5YCq5YWI5qOuXw==,size_20,color_FFFFFF,t_70,g_se,x_16-20240705123325145.png)



- 添加以下源地址

	```json
	"registry-mirrors": [
	    "https://docker.chenby.cn",
	    "docker.awsl9527.cn"
	]
	```
	
	
	
	

![在这里插入图片描述](docker_desktop.assets/watermark,type_d3F5LXplbmhlaQ,shadow_50,text_Q1NETiBA54Gs5YCq5YWI5qOuXw==,size_20,color_FFFFFF,t_70,g_se,x_16-20240705123328064.png)