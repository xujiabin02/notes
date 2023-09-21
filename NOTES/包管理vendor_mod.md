# tips


> go 1.11 添加了go mod并且可以和vendor 互相切换

> CGO_ENABLED=0

```sh
# 启用 Go Modules 功能
export GO111MODULE=on
```

常用的go mod命令如下：



```excel
go mod download    下载依赖的module到本地cache（默认为$GOPATH/pkg/mod目录）
go mod edit        编辑go.mod文件
go mod graph       打印模块依赖图
go mod init        初始化当前文件夹, 创建go.mod文件
go mod tidy        增加缺少的module，删除无用的module
go mod vendor      将依赖复制到vendor下
go mod verify      校验依赖
go mod why         解释为什么需要依赖
```



# 网站

* [awesome-awesomeness](https://github.com/bayandin/awesome-awesomeness) **star:27602** 其他 awesome 系列的列表。![star > 2000](.img_golang%E5%8C%85%E7%AE%A1%E7%90%86vendor_mod/68747470733a2f2f63646e2e6a7364656c6976722e6e65742f67682f79696e6767616f7a68656e2f617765736f6d652d676f2d636e40312e342e312f646f63732f617765736f6d652e737667-20210508140319526)
* [CodinGame](https://www.codingame.com/) 以小游戏互动完成任务的形式来学习 Go。
* [Go Blog](http://blog.golang.org/) 官方 Go 博客。
* [Go Challenge](http://golang-challenge.org/) 通过解决问题并从 Go 专家那里得到反馈来学习 Go。
* [Go Code Club](https://www.youtube.com/watch?v=nvoIPQYdx9g&list=PLEcwzBXTPUE_YQR7R0BRtHBYJ0LN3Y0i3) 一群地鼠每周阅读和讨论一个不同的Go项目。
* [Go Community on Hashnode](https://hashnode.com/n/go) Hashnode上的Go社区。
* [Go Forum](https://forum.golangbridge.org/) 讨论 Go 的论坛。
* [Go In 5 Minutes](https://www.goin5minutes.com/) 5 minute screencasts focused on getting one thing done.
* [Go Projects](https://github.com/golang/go/wiki/Projects) wiki上的 Go 社区项目列表。
* [Go Report Card](https://goreportcard.com/) 为你的 Go 包生成一份报告单。
* [go.dev](https://go.dev/) 一个围棋开发者的中心。
* [Awesome Remote Job](https://github.com/lukasz-madon/awesome-remote-job) **star:20317** Curated list of awesome remote jobs. A lot of them are looking for Go hackers. [![star > 2000](.img_golang%E5%8C%85%E7%AE%A1%E7%90%86vendor_mod/68747470733a2f2f63646e2e6a7364656c6976722e6e65742f67682f79696e6767616f7a68656e2f617765736f6d652d676f2d636e40312e342e312f646f63732f617765736f6d652e737667)](https://github.com/lukasz-madon/awesome-remote-job) [![最近一周有更新](.img_golang%E5%8C%85%E7%AE%A1%E7%90%86vendor_mod/68747470733a2f2f63646e2e6a7364656c6976722e6e65742f67682f79696e6767616f7a68656e2f617765736f6d652d676f2d636e40312e312f646f63732f477265656e2e737667)](https://github.com/lukasz-madon/awesome-remote-job)
* [golang-graphics](https://github.com/mholt/golang-graphics) **star:140** 收藏的 Go 图像，图形和艺术作品。 [![最近一年没有更新](.img_golang%E5%8C%85%E7%AE%A1%E7%90%86vendor_mod/68747470733a2f2f63646e2e6a7364656c6976722e6e65742f67682f79696e6767616f7a68656e2f617765736f6d652d676f2d636e40312e312f646f63732f59656c6c6f772e737667)](https://github.com/mholt/golang-graphics) [![归档项目](.img_golang%E5%8C%85%E7%AE%A1%E7%90%86vendor_mod/68747470733a2f2f63646e2e6a7364656c6976722e6e65742f67682f79696e6767616f7a68656e2f617765736f6d652d676f2d636e40312e322e312f646f63732f61726368697665642e737667)](https://github.com/mholt/golang-graphics)
* [golang-nuts](https://groups.google.com/forum/#!forum/golang-nuts) Go 邮件列表。
* [Google Plus Community](https://plus.google.com/communities/114112804251407510571) Google+社区 golang爱好者聚集地。
* [Gopher Community Chat](https://invite.slack.golangbridge.org/) 加入我们为Gophers设立的全新Slack社区([了解它是如何产生的](https://blog.gopheracademy.com/gophers-slack-community/))。
* [Gophercises](https://gophercises.com/) 为 Go 初学者提供免费的代码训练。
* [gowalker.org](https://gowalker.org/) Go API 文档。
* [json2go](https://m-zajac.github.io/json2go) 高级JSON去结构转换-在线工具。
* [justforfunc](https://www.youtube.com/c/justforfunc) 致力于传授 Go 编程语言技巧和技巧的Youtube 频道，由Francesc Campoy [@francesc](https://twitter.com/francesc)主办。
* [Learn Go Programming](https://blog.learngoprogramming.com/) 学习Go概念与插图。
* [Lille Gophers](https://lille-gophers.loscrackitos.codes/) Golang在法国里尔谈论社区([@LilleGophers](https://twitter.com/LilleGophers))。
* [Awesome Go @LibHunt](https://go.libhunt.com/) 属于你的 Go 工具箱。
* [gocryforhelp](https://github.com/ninedraft/gocryforhelp) **star:38** 专门收集需要帮助的Go项目，这是你开启开源之路的好去处。 [![最近一年没有更新](.img_golang%E5%8C%85%E7%AE%A1%E7%90%86vendor_mod/68747470733a2f2f63646e2e6a7364656c6976722e6e65742f67682f79696e6767616f7a68656e2f617765736f6d652d676f2d636e40312e312f646f63732f59656c6c6f772e737667)](https://github.com/ninedraft/gocryforhelp)
* [godoc.org](https://godoc.org/) 开源 Go 包的文档。
* [Golang Developer Jobs](https://golangjob.xyz/) 开发人员的工作专为Golang相关的角色。
* [Golang Flow](https://golangflow.io/) 发布更新、新闻、包等等。
* [Golang News](https://golangnews.com/) 关于 Go 编程的链接和新闻。
* [Golang Resources](https://golangresources.com/) 一个最好的文章，练习，谈话和视频的策划学习围棋。
* [Made with Golang](https://madewithgolang.com/?ref=awesome-go)
* [r/Golang](https://www.reddit.com/r/golang) 与 Go 有关的新闻。
* [studygolang](https://studygolang.com/) Go语言中文网
* [Trending Go repositories on GitHub today](https://github.com/trending?l=go) 寻找最新的 Go库 的好地方。
* [TutorialEdge - Golang](https://tutorialedge.net/course/golang/)



# 教程

* [Build web application with Golang](https://github.com/astaxie/build-web-application-with-golang) **star:37607** Golang电子书，主要讲述如何用 Golang 建立一个web应用程序。 [![star > 2000](.img_golang%E5%8C%85%E7%AE%A1%E7%90%86vendor_mod/68747470733a2f2f63646e2e6a7364656c6976722e6e65742f67682f79696e6767616f7a68656e2f617765736f6d652d676f2d636e40312e342e312f646f63732f617765736f6d652e737667-20210508140559140)](https://github.com/astaxie/build-web-application-with-golang) [![最近一周有更新](.img_golang%E5%8C%85%E7%AE%A1%E7%90%86vendor_mod/68747470733a2f2f63646e2e6a7364656c6976722e6e65742f67682f79696e6767616f7a68656e2f617765736f6d652d676f2d636e40312e312f646f63732f477265656e2e737667-20210508140559956)](https://github.com/astaxie/build-web-application-with-golang) [![godoc](.img_golang%E5%8C%85%E7%AE%A1%E7%90%86vendor_mod/68747470733a2f2f63646e2e6a7364656c6976722e6e65742f67682f79696e6767616f7a68656e2f617765736f6d652d676f2d636e40312e332e302f646f63732f444f432e737667)](https://godoc.org/github.com/astaxie/build-web-application-with-golang) [![包含中文文档](.img_golang%E5%8C%85%E7%AE%A1%E7%90%86vendor_mod/68747470733a2f2f63646e2e6a7364656c6976722e6e65742f67682f79696e6767616f7a68656e2f617765736f6d652d676f2d636e40312e312f646f63732f436e2e737667)](https://github.com/astaxie/build-web-application-with-golang)
* [Building and Testing a REST API in Go with Gorilla Mux and PostgreSQL](https://semaphoreci.com/community/tutorials/building-and-testing-a-rest-api-in-go-with-gorilla-mux-and-postgresql) 我们会写一个API的帮助下强大的大猩猩Mux。
* [Building Go Web Applications and Microservices Using Gin](https://semaphoreci.com/community/tutorials/building-go-web-applications-and-microservices-using-gin) Get familiar with Gin and find out how it can help you reduce boilerplate code and build a request handling pipeline.
* [Caching Slow Database Queries](https://medium.com/@rocketlaunchr.cloud/caching-slow-database-queries-1085d308a0c9) 如何缓存数据库的慢查询。
* [Canceling MySQL](https://medium.com/@rocketlaunchr.cloud/canceling-mysql-in-go-827ed8f83b30) 如何取消MySQL查询。
* [Go Cheat Sheet](https://github.com/a8m/go-lang-cheat-sheet) **star:5414** Go's reference card。 [![star > 2000](.img_golang%E5%8C%85%E7%AE%A1%E7%90%86vendor_mod/68747470733a2f2f63646e2e6a7364656c6976722e6e65742f67682f79696e6767616f7a68656e2f617765736f6d652d676f2d636e40312e342e312f646f63732f617765736f6d652e737667-20210508140559140)](https://github.com/a8m/go-lang-cheat-sheet)
* [Go database/sql tutorial](http://go-database-sql.org/) 数据库概论/ sql。
* [Go Playground for iOS](https://codeplayground.app/) 在你的移动设备上编辑你编辑和运行你的 Go 代码。
* [Ethereum Development with Go](https://github.com/miguelmota/ethereum-development-with-go-book) **star:791** 一本讲述如何用 Go 进行以太开发的小册。 [![godoc](.img_golang%E5%8C%85%E7%AE%A1%E7%90%86vendor_mod/68747470733a2f2f63646e2e6a7364656c6976722e6e65742f67682f79696e6767616f7a68656e2f617765736f6d652d676f2d636e40312e332e302f646f63732f444f432e737667)](https://godoc.org/github.com/miguelmota/ethereum-development-with-go-book) [![包含中文文档](.img_golang%E5%8C%85%E7%AE%A1%E7%90%86vendor_mod/68747470733a2f2f63646e2e6a7364656c6976722e6e65742f67682f79696e6767616f7a68656e2f617765736f6d652d676f2d636e40312e312f646f63732f436e2e737667)](https://github.com/miguelmota/ethereum-development-with-go-book)
* [Games With Go](http://gameswithgo.org/) 关于编程和游戏开发系列教学视频。
* [Go By Example](https://gobyexample.com/) 手把手教你 如何在 Go 应用程序中使用注释。
* [50 Shades of Go](http://devs.cloudimmunity.com/gotchas-and-common-mistakes-in-go-golang/) Go 初学者经常遇到的陷阱、误区、错误
* [A Guide to Golang E-Commerce](https://snipcart.com/blog/golang-ecommerce-ponzu-cms-demo?utm_term=golang-ecommerce-ponzu-cms-demo) 教你如何用 Go 搭建一个电商平台 (包括demo)。
* [A Tour of Go](http://tour.golang.org/) 互动的 Go 之旅。
* [Design Patterns in Go](https://github.com/shubhamzanwar/design-patterns) **star:53** 在Go中实现的编程设计模式的集合。 [![godoc](.img_golang%E5%8C%85%E7%AE%A1%E7%90%86vendor_mod/68747470733a2f2f63646e2e6a7364656c6976722e6e65742f67682f79696e6767616f7a68656e2f617765736f6d652d676f2d636e40312e332e302f646f63732f444f432e737667)](https://godoc.org/github.com/shubhamzanwar/design-patterns)
* [Debugged.it Go patterns](https://github.com/haveyoudebuggedit/go-patterns) **star:6** 高级的Go模式和准备运行的示例。 [![godoc](.img_golang%E5%8C%85%E7%AE%A1%E7%90%86vendor_mod/68747470733a2f2f63646e2e6a7364656c6976722e6e65742f67682f79696e6767616f7a68656e2f617765736f6d652d676f2d636e40312e332e302f646f63732f444f432e737667)](https://godoc.org/github.com/haveyoudebuggedit/go-patterns)
* [Go WebAssembly Tutorial - Building a Simple Calculator](https://tutorialedge.net/golang/go-webassembly-tutorial/)
* [go-patterns](https://github.com/tmrts/go-patterns) **star:15106** 策划的清单去设计模式，食谱和习惯用法。 [![star > 2000](.img_golang%E5%8C%85%E7%AE%A1%E7%90%86vendor_mod/68747470733a2f2f63646e2e6a7364656c6976722e6e65742f67682f79696e6767616f7a68656e2f617765736f6d652d676f2d636e40312e342e312f646f63732f617765736f6d652e737667-20210508140559140)](https://github.com/tmrts/go-patterns) [![godoc](.img_golang%E5%8C%85%E7%AE%A1%E7%90%86vendor_mod/68747470733a2f2f63646e2e6a7364656c6976722e6e65742f67682f79696e6767616f7a68656e2f617765736f6d652d676f2d636e40312e332e302f646f63732f444f432e737667)](https://godoc.org/github.com/tmrts/go-patterns)
* [Learn Go with TDD](https://github.com/quii/learn-go-with-tests) **star:14211** 学习使用测试驱动开发。 [![star > 2000](.img_golang%E5%8C%85%E7%AE%A1%E7%90%86vendor_mod/68747470733a2f2f63646e2e6a7364656c6976722e6e65742f67682f79696e6767616f7a68656e2f617765736f6d652d676f2d636e40312e342e312f646f63732f617765736f6d652e737667-20210508140559140)](https://github.com/quii/learn-go-with-tests) [![最近一周有更新](.img_golang%E5%8C%85%E7%AE%A1%E7%90%86vendor_mod/68747470733a2f2f63646e2e6a7364656c6976722e6e65742f67682f79696e6767616f7a68656e2f617765736f6d652d676f2d636e40312e312f646f63732f477265656e2e737667-20210508140559956)](https://github.com/quii/learn-go-with-tests) [![godoc](.img_golang%E5%8C%85%E7%AE%A1%E7%90%86vendor_mod/68747470733a2f2f63646e2e6a7364656c6976722e6e65742f67682f79696e6767616f7a68656e2f617765736f6d652d676f2d636e40312e332e302f646f63732f444f432e737667)](https://godoc.org/github.com/quii/learn-go-with-tests) [![包含中文文档](.img_golang%E5%8C%85%E7%AE%A1%E7%90%86vendor_mod/68747470733a2f2f63646e2e6a7364656c6976722e6e65742f67682f79696e6767616f7a68656e2f617765736f6d652d676f2d636e40312e312f646f63732f436e2e737667)](https://github.com/quii/learn-go-with-tests)
* [Learning Golang - From zero to hero](https://milapneupane.com.np/2019/07/06/learning-golang-from-zero-to-hero/) 面向 Golang 初学者教程。
* [package main](https://www.youtube.com/packagemain) 关于 Go 编程的YouTube频道。
* [Programming with Google Go](https://www.coursera.org/specializations/google-golang) Coursera的专业学习可以从零开始。
* [Learn Go with 1000+ Exercises](https://github.com/inancgumus/learngo) **star:9383** 通过成千上万的例子、练习和测验来学习Go。 [![star > 2000](.img_golang%E5%8C%85%E7%AE%A1%E7%90%86vendor_mod/68747470733a2f2f63646e2e6a7364656c6976722e6e65742f67682f79696e6767616f7a68656e2f617765736f6d652d676f2d636e40312e342e312f646f63732f617765736f6d652e737667-20210508140559140)](https://github.com/inancgumus/learngo) [![最近一周有更新](.img_golang%E5%8C%85%E7%AE%A1%E7%90%86vendor_mod/68747470733a2f2f63646e2e6a7364656c6976722e6e65742f67682f79696e6767616f7a68656e2f617765736f6d652d676f2d636e40312e312f646f63732f477265656e2e737667-20210508140559956)](https://github.com/inancgumus/learngo) [![godoc](.img_golang%E5%8C%85%E7%AE%A1%E7%90%86vendor_mod/68747470733a2f2f63646e2e6a7364656c6976722e6e65742f67682f79696e6767616f7a68656e2f617765736f6d652d676f2d636e40312e332e302f646f63732f444f432e737667)](https://godoc.org/github.com/inancgumus/learngo)
* [Golang for Node.js Developers](https://github.com/miguelmota/golang-for-nodejs-developers) **star:2345** 引入示例讲述 Golang 与Node.js在学习上的差异。 [![star > 2000](.img_golang%E5%8C%85%E7%AE%A1%E7%90%86vendor_mod/68747470733a2f2f63646e2e6a7364656c6976722e6e65742f67682f79696e6767616f7a68656e2f617765736f6d652d676f2d636e40312e342e312f646f63732f617765736f6d652e737667-20210508140559140)](https://github.com/miguelmota/golang-for-nodejs-developers) [![godoc](.img_golang%E5%8C%85%E7%AE%A1%E7%90%86vendor_mod/68747470733a2f2f63646e2e6a7364656c6976722e6e65742f67682f79696e6767616f7a68656e2f617765736f6d652d676f2d636e40312e332e302f646f63732f444f432e737667)](https://godoc.org/github.com/miguelmota/golang-for-nodejs-developers)
* [Golangbot](https://golangbot.com/learn-golang-series/) Go 编程教程。
* [GolangCode](https://golangcode.com/) 收集代码片段和教程，以帮助处理日常问题。
* [GopherSnippets](https://gophersnippets.com/) 带有测试和可测试示例的代码片段，用于Go编程语言。
* [Hackr.io](https://hackr.io/tutorials/learn-golang) Go社区投票选举出来的最好的在线 Go 教程。
* [How to Benchmark: dbq vs sqlx vs GORM](https://medium.com/@rocketlaunchr.cloud/how-to-benchmark-dbq-vs-sqlx-vs-gorm-e814caacecb5) 学习如何在Golang中进行基准测试。作为案例研究，我们将对dbq、sqlx和GORM进行基准测试。
* [How To Deploy a Go Web Application with Docker](https://semaphoreci.com/community/tutorials/how-to-deploy-a-go-web-application-with-docker) 学习如何使用Docker进行Go开发，以及如何构建Docker生产镜像。
* [How to Use Godog for Behavior-driven Development in Go](https://semaphoreci.com/community/tutorials/how-to-use-godog-for-behavior-driven-development-in-go) 快速使用Godog —— 一个行为驱动开发的构建和测试应用程序框架。
* [goapp](https://github.com/bnkamalesh/goapp) **star:245** 关于构建和开发Go web应用/服务的指南。 [![godoc](.img_golang%E5%8C%85%E7%AE%A1%E7%90%86vendor_mod/68747470733a2f2f63646e2e6a7364656c6976722e6e65742f67682f79696e6767616f7a68656e2f617765736f6d652d676f2d636e40312e332e302f646f63732f444f432e737667)](https://godoc.org/github.com/bnkamalesh/goapp)
* [The world’s easiest introduction to WebAssembly with Golang](https://medium.com/@martinolsansky/webassembly-with-golang-is-fun-b243c0e34f02)
* [Working with Go](https://github.com/mkaz/working-with-go) **star:1162** 由一个经验丰富的Go程序员群体编写的一系列Go学习范例。 [![最近一年没有更新](.img_golang%E5%8C%85%E7%AE%A1%E7%90%86vendor_mod/68747470733a2f2f63646e2e6a7364656c6976722e6e65742f67682f79696e6767616f7a68656e2f617765736f6d652d676f2d636e40312e312f646f63732f59656c6c6f772e737667-20210508140600570)](https://github.com/mkaz/working-with-go) [![归档项目](.img_golang%E5%8C%85%E7%AE%A1%E7%90%86vendor_mod/68747470733a2f2f63646e2e6a7364656c6976722e6e65742f67682f79696e6767616f7a68656e2f617765736f6d652d676f2d636e40312e322e312f646f63732f61726368697665642e737667-20210508140600619)](https://github.com/mkaz/working-with-go)
* [Your basic Go](http://yourbasic.org/golang) 如何收集大量的教程。



# ---