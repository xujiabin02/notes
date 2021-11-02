读书规划



# Vue note

学习笔记

## router

https://www.cnblogs.com/yuyujuan/p/9839705.html



新建src/router.config.js

```js
import Hello from '@/components/HelloWorld'
import Home from '@/components/Home'
export default {
  routes: [
    {path: '/home', component:Home},
    {path: '/', component:Hello},
    // {path: '*', redirect:'/home'}
  ]
}
```



main.js中引入

```js
import Vue from 'vue'
import App from './App.vue'
import ElementUI from 'element-ui'
import 'element-ui/lib/theme-chalk/index.css'
import axios from 'axios'
import VueRouter from 'vue-router'
import routerConfig from './router.config'

Vue.config.productionTip = false
Vue.use(ElementUI)
Vue.use(VueRouter)
const router = new VueRouter(routerConfig)
Vue.prototype.$axios = axios
// axios.defaults.baseURL = "http://localhost:18080"

new Vue({
  router,
  render: h => h(App),
}).$mount('#app')

```



App.vue

```js
<template>
  <div id="app">
  <el-container>
    <el-header>
      <router-link to ="/home">TEST</router-link>
      <router-link to ="/">project</router-link>
      Header</el-header>
    <el-container>
      <el-aside width="200px">Aside
        <img alt="Vue logo" src="./assets/logo.png">
      </el-aside>
      <el-container>
        <el-main>Main
          <div><router-view></router-view></div>
<!--        <HelloWorld msg="Welcome to Your Vue.js App" title="baby "/>-->
        </el-main>
        <el-footer>Footer
        </el-footer>
      </el-container>
    </el-container>
  </el-container>
  </div>
</template>

<script>
// import HelloWorld from './components/HelloWorld.vue'
export default {
  name: 'App',
  // components: {
  //   HelloWorld
  // }
}
</script>

<style>
#app {
  font-family: Avenir, Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-align: center;
  color: #2c3e50;
  margin-top: 60px;
}
</style>

```

参照

![img](.img_vue_ts/1304208-20181023213434893-456774824.png)





# vue打包后分离config配置文件

用vue-cli构建的项目通常是采用前后端分离的开发模式，也就是前端与后台完全分离，此时就需要将后台接口地址打包进项目中，此时如果只是改个接口地址也要重新打包那就太麻烦了，解决方法是直接加个config.js文件

1.首先我们在static文件下建立一个js文件，就叫config.js吧，内容为

```js
window.g = {
  AXIOS_TIMEOUT: 10000,
  ApiUrl: 'http://localhost:21021/api/services/app', // 配置服务器地址,
  ParentPage: {
    CrossDomainProxyUrl: '/Home/CrossDomainProxy',
    BtnsApi: '/api/services/app/Authorization/GetBtns',
    OrgsApi: '/api/services/app/authorization/GetOrgsByUserId'
  },
}
 

```

2.接下来我们只需要在index.html这个入口文件里引入该文件（注意路径就ok）

```js
<script type="text/javascript" src="/static/config.js"></script>
3.然后你就可以在你需要的地方随意获取就行了，比如

var baseURLStr = window.g.ApiUrl
// 创建axios实例
const service = axios.create({
  baseURL: baseURLStr, // api的base_url
  timeout: 5000 // 请求超时时间
})

```

4.最后在打包成功之后，config,js文件不会被打包，依然存在static文件夹下，如果需要修改只需要用记事本打开文件修改地址就OK了，而且该方法也不会影响开发模式。

# 打包关闭filenameHashing



>  vue.config.js
>
> ```js
> module.exports = {
>   filenameHashing: false,
> }
> 
> ```
>
> 



## WebSocket

# dashboard VUE改造

 项目信息管理

* [ ] ### hosts

* [ ] ### topology

* [ ] ### hardware resource info

* [ ] ### project info:  project id,key/pg con info/redis passwword/api info/auth info

* [ ] ### 项目版本管理、切换  时间线记录

## 服务管理

* [ ] ### 配置查看

* [ ] ### 配置批量修改

* [ ] ### 服务重启

## 部署管理





| word            | main                                                         | applications                                                 |
| --------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| bootstrap       | html,css,js框架                                              | 以前很火，现在的话比较简单重复的企业可能会用到它，它和JQuery一样已经不再是主流。 |
| 前端框架        | html,css,js的库和框架                                        | 提高前端生产效率                                             |
| vue             |                                                              | 你会我也会，工资不高,学习vue较react简单，算法看一看就好，主要是设计模式 |
| react           |                                                              | 你会我也会，工资不高                                         |
| 设计模式        | 指导软件设计开发过程中反复出现的某类问题的思想和解决方案，设计模式是方法论不是现成的代码 | 结构型模式（Structural Patterns）；创建型模式（Creational Patterns）；行为型模式（Behavioral Patterns）； |
| 结构型模式      |                                                              |                                                              |
| 创建型模式      |                                                              |                                                              |
| 行为型模式      |                                                              |                                                              |
| 外观模式/结构型 | 把多个子系统抽象成一个简洁易用的API                          | JQuery把复杂的原生DOM操作抽象和封装并消除了浏览器之间的兼容性问题 |
| 代理模式/结构型 | 降低访问时间或专业成本; 增加额外逻辑                         | 中间商，中介，律师，代理，proxy,缓存                         |
| 工厂模式/创建型 | 集中\统一方法和类,根据传入参数生成不同的对象                 | 构造函数过多,创建对象之间存在某些关联,使用工厂设计模式实现统一集中化管理,避免代码重复\灵活性差 |
| 单例模式/创建型 | 单个实例贯穿整个系统,保持唯一性,优点是: 减少资源占用; 防止重复; | 防止脑裂, 分布式锁保障                                       |
|                 |                                                              |                                                              |
|                 |                                                              |                                                              |



# Vue 3.0 + typescript + element-plus



```bash
npm uninstall  element-ui -S
yarn remove element-ui
```

then install the latest one :

```bash
npm i element-plus -S
#
yarn add element-plus
```

the `main.js` minimum content :

```javascript
import { createApp } from "vue";
import router from "./router";
import store from "./store";

import ElementPlus from "element-plus";
import "element-plus/lib/theme-chalk/index.css";

import App from "./App.vue";

createApp(App)
.use(ElementPlus)
.use(store)
.use(router)
.mount("#app");
```

在 main.js 中写入以下内容：

```javascript
import { createApp } from 'vue'
import ElementPlus from 'h';
import 'element-plus/lib/theme-chalk/index.css';
import App from './App.vue';

const app = createApp(App)
app.use(ElementPlus)
app.mount('#app')
```

以上代码便完成了 Element Plus 的引入。需要注意的是，样式文件需要单独引入。

## axios



# websoket

公共状态管理





![image-20210111112014420](.img_vue_ts/image-20210111112014420.png)



#    vue3 动画特效教程 [技术胖](https://jspang.com/detailed?id=71#toc21)

技术胖 https://jspang.com/detailed?id=68  

[技术胖vue3+ts](https://jspang.com/detailed?id=64) 23集

[技术胖typescript](https://jspang.com/detailed?id=63)

[offically docs typescript](https://typescript.bootcss.com/)

官方 https://www.vue3js.cn/docs/zh/guide/introduction.html#%E5%A3%B0%E6%98%8E%E5%BC%8F%E6%B8%B2%E6%9F%93   45小节 (或者本地起docs源码,看英文版)

https://v3.cn.vuejs.org/guide/introduction.html#vue-js-%E6%98%AF%E4%BB%80%E4%B9%88

google https://www.google.com/search?q=vue3+%E8%AF%AD%E6%B3%95&oq=vue3+%E8%AF%AD%E6%B3%95&aqs=chrome..69i57j0i30j0i8i30l2.2227j0j7&sourceid=chrome&ie=UTF-8



目标:   =>  VUE3+ts 

1. 能够搭建 devops运维平台
2. 实现webssh, axios动态加载







# 学习书签

| 学习进度                                                     |                                                              |                     |
| ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------- |
| Dom                                                          | [short_hands](.detail_vue_ts/short_hands)                    |                     |
| Musta                                                        |                                                              |                     |
| 应用 & 组件实例https://www.vue3js.cn/docs/zh/guide/instance.html | https://codepen.io/team/Vue/pen/KKpRVpx                      | 2021-07-15 09:48:43 |
| ![实例的生命周期](.img_vue_ts/lifecycle.png)                 | ![img](.img_vue_ts/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3dlaXhpbl80MzczNDQ5MA==,size_16,color_FFFFFF,t_70.png) |                     |
| [模板语法](https://www.vue3js.cn/docs/zh/guide/template-syntax.html#%E6%8F%92%E5%80%BC) |                                                              |                     |
| [data property](https://www.vue3js.cn/docs/zh/guide/data-methods.html#data-property) |                                                              |                     |
| [方法](https://www.vue3js.cn/docs/zh/guide/data-methods.html#%E6%96%B9%E6%B3%95) |                                                              |                     |
| [生命周期勾子](https://v3.cn.vuejs.org/guide/composition-api-lifecycle-hooks.html) => [方法](https://www.vue3js.cn/docs/zh/guide/data-methods.html#%E6%96%B9%E6%B3%95) |                                                              |                     |
| [防抖和节流](https://www.vue3js.cn/docs/zh/guide/data-methods.html#%E9%98%B2%E6%8A%96%E5%92%8C%E8%8A%82%E6%B5%81) |                                                              |                     |
| [计算属性和侦听器](https://www.vue3js.cn/docs/zh/guide/computed.html#%E8%AE%A1%E7%AE%97%E5%B1%9E%E6%80%A7) | [笔记](.detail_vue_ts/计算属性与侦听器.md)                   |                     |
| [绑定HTML Class](https://www.vue3js.cn/docs/zh/guide/class-and-style.html#%E7%BB%91%E5%AE%9A-html-class) |                                                              |                     |
| [条件渲染](https://www.vue3js.cn/docs/zh/guide/conditional.html#v-if) |                                                              |                     |
| [列表渲染](https://www.vue3js.cn/docs/zh/guide/list.html#%E7%94%A8-v-for-%E6%8A%8A%E4%B8%80%E4%B8%AA%E6%95%B0%E7%BB%84%E5%AF%B9%E5%BA%94%E4%B8%BA%E4%B8%80%E7%BB%84%E5%85%83%E7%B4%A0) | [笔记](.detail_vue_ts/列表渲染.md)                           |                     |
| [Event_Handle](http://localhost:8080/guide/events.html#listening-to-events) | [笔记](.detail_vue_ts/event_handing)                         |                     |
| [form_Input_binding](http://localhost:8080/guide/forms.html#basic-usage) |                                                              |                     |
| [Components](http://localhost:8080/guide/component-basics.html#base-example) | [笔记](.detail_vue_ts/components)                            |                     |
| [typescript](https://www.typescriptlang.org/docs/handbook/2/generics.html) |                                                              |                     |
| [变量声明](https://typescript.bootcss.com/variable-declarations.html) | [变量](.detail_vue_ts/变量)                                  |                     |
| [生命周期勾子](https://v3.cn.vuejs.org/guide/composition-api-lifecycle-hooks.html) |                                                              |                     |
| [refs](https://v3.cn.vuejs.org/guide/reactivity-fundamentals.html#%E5%A3%B0%E6%98%8E%E5%93%8D%E5%BA%94%E5%BC%8F%E7%8A%B6%E6%80%81) |                                                              |                     |
| [深入理解typescript](https://jkchao.github.io/typescript-book-chinese/) |                                                              |                     |
| export,import                                                | [笔记](.detail_vue_ts/export)                                |                     |
| [namespace](https://jkchao.github.io/typescript-book-chinese/project/namespaces.html) | [note](.detail_vue_ts/namespace)                             |                     |
| 泛型 <T>                                                     | `function reverse<T>(items: T[]): T[]{}`                     |                     |
| 联合类型 \|                                                  | `(command: string[] | string)`                               |                     |
|                                                              |                                                              |                     |





# Vue3 + TS [最佳实践](https://juejin.cn/post/7001897686567747598)



# el-icon

Element Plus 团队表示正在将原有组件内的 Font Icon 向 SVG Icon 迁移，正式版本Font Icon将被弃用，于是目标是对代码进行对应的更新，Font Icon换成SVG Icon。



> 文档： Icon 图标 | Element Plus (element-plus.org)  (2021.10.12更新替换连接地址，element-plus文档网址变动了)
>
> 注意：当前图标只适用于vue3。
>
> 首先更新 element-plus版本，指定安装@1.0.2-beta.69（2021.8.5时的最新版本）。安装图标包，npm install @element-plus/icons。



`npm install element-plus@1.0.2-beta.69`

`npm install @element-plus/icons`

 文档中表示，使用el-icon需要全局注册组件或者在要用到的组件中单独注册。看了一下源码，发现无统一导出，只能一个个注册。[ 已更新 el-icon 统一导入及注册方式，见最下方2021.10.12更新 ]



组件中注册：

```typescript
//组件script
import { Fold } from '@element-plus/icons'
import { Edit } from '@element-plus/icons'
export default {
    components: {
      Fold,
      Edit
    }
}
```



全局注册

```typescript
//main.js
import { Expand } from '@element-plus/icons'

const app=createApp(App)
app.component('expand', Expand)
app.mount('#app')
```



**经过实测:**

```vue
<template>
          <el-icon class="el-icon--upload" :size="150">
            <upload-filled/>
          </el-icon>
</template>
<script lang="ts">
import {Options, Vue} from 'vue-class-component';
import {UploadFilled} from '@element-plus/icons'
@Options({
    components: {
        UploadFilled,
        ReleasePublish
    }
})
```

**2021.10.12更新：el-icon 统一导入及注册方式**

用 import * as 统一模块对象 from '路径' 方式导入，并使用 for in 循环注册。代码如下：

```typescript
//main.js
// 统一导入 el-icon 图标
import * as ElIconModules from '@element-plus/icons'
// 导入转换图标名称的函数
import { transElIconName } from './utils/utils.js'
...
// 统一注册el-icon图标
for(let iconName in ElIconModules){
  app.component(transElIconName(iconName), ElIconModules[iconName])
}
// utils/utils.js
// 将el-icon的组件名称AbbbCddd转化为i-abbb-cddd形式
// 此前用switch做给组件名时因关键字重复报错, 所以格式统一加了前缀 
// 例: Switch转换为i-switch, ArrowDownBold转换为i-arrow-down-bold

export function transElIconName(iconName){
  return 'i'+iconName.replace(/[A-Z]/g), (match)=>'-'+match.toLowerCase())
}
```

注：此时使用的 @element-plus/icons 版本为0.0.11（2021.10.12时的最新版本）。

#  书签尾部









