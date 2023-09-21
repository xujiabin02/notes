

# if 

- -z 判断变量是否存在

**字符串判断：**

= 两个字符串相等。
!= 两个字符串不等。
-n 非空串。
-z  判断字符串是否为空。

**文件判断：**

-d  目录
-f   正规文件
-L  符号连接
-r  可读

-s  文件长度大于 0、非空
-w  可写
-u  文件有suid位设置
-x  可执行







# 命令行传参



```sh
#!/bin/bash
echo "$@"
while getopts ":a:bc:" opt; do #不打印错误信息, -a -c需要参数 -b 不需要传参  
  case $opt in
    a)
      echo "-a arg:$OPTARG index:$OPTIND" #$OPTIND指的下一个选项的index
      ;;
    b)
      echo "-b arg:$OPTARG index:$OPTIND"
      ;;
    c) 
      echo "-c arg:$OPTARG index:$OPTIND"
      ;;
    :)
      echo "Option -$OPTARG requires an argument." 
      exit 1
      ;;
    ?) #当有不认识的选项的时候arg为?
      echo "Invalid option: -$OPTARG index:$OPTIND"
      ;;
    
  esac
done
```

