# vue修改标题title

[![米拉](.img_title_vue/1335e9437_xs.jpg)](https://www.zhihu.com/people/millia)

[米拉](https://www.zhihu.com/people/millia)

前端开发

1 人赞同了该文章

项目创建的会有一个默认的title就是创建项目的名称，修改不同组件的title可如下实现：

1、在router里每个组件下增加meta

```js
{
    path: '/', //用户登录默认页
    name: 'Login',
    component: Login,
    meta:{
      title:"登录"
    }
  },{
    path: '/Regist', //用户注册页
    name: 'Regist',
    component: Regist,
    meta:{
      title:"注册"
    }
  },{
    path: '/PassWord', //忘记密码页
    name: 'PassWord',
    component: PassWord,
    meta:{
      title:"忘记密码"
    }
  },{
  ……
  }
```

2、在main.js里添加如下代码

```text
router.beforeEach((to,from,next) =>{
  if(to.meta.title){
    document.title = to.meta.title
  }
  next();
})
```

