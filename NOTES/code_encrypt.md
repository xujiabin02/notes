- sourcedefender

- 对照组

- # python代码安全保护

  ## 需求分析

  银行、国企的代码逆向安全扫描

  > **敏感信息**    明文用户名、密码、邮箱、网址

  我们对代码、专利的保护

  > **代码保护**    核心代码、算法、敏感信息等

  ## 3种解决方案: 打包成二进制执行程序, 代码加密, 代码混淆

  ### 打包成二进制执行程序

  | **打包部署**                                    | **实践**                                                     | **安全性**   |
  | ----------------------------------------------- | ------------------------------------------------------------ | ------------ |
  | [pex](https://github.com/pantsbuild/pex)        | [使用pex生成自包含的python程序](https://yami.github.io/2018/08/11/%E4%BD%BF%E7%94%A8Pex%E7%94%9F%E6%88%90%E8%87%AA%E5%8C%85%E5%90%AB%E7%9A%84Python%E7%A8%8B%E5%BA%8F.html) | 可过安全扫描 |
  | [xar](https://github.com/facebookincubator/xar) | [python打包的解决方案 pex 竞品 facebookincubator/xar: executable archive format](https://github.com/facebookincubator/xar) | 可过安全扫描 |
  | .so                                             | cpython打包成.c, 再转成.so                                   | 可过安全扫描 |

  ---

  | **对比** | **pex**                           | **xar**                  | **.so**      |
  | -------- | --------------------------------- | ------------------------ | ------------ |
  | 出品     | twitter                           | facebook                 | cpython      |
  | 核心技术 | zip/execute                       | zip/mounted/squashfs     | .so          |
  | 安全性   | 可过安全扫描                      | 可过安全扫描             | 可过安全扫描 |
  | 启动速度 | 较慢,也可手动挂载/dev/shm提高速度 | 较快，因为挂载到/dev/shm | 较快         |

  #### pex

  twitter出品

  打包后程序为二进制可执行程序

  **打包方法**:

  ```plaintext
  pex -r req.txt --no-pypi -i https://pypi.doubanio.com/simple/ -o ansible.pex
  ```

  ```plaintext
  [root@linux10A63A80A108 ~]# file ansible.pex 
  ansible.pex: Zip archive data
  ```

  #### xar

  facebook去年开源

  打包后为二进制

  **打包方法**：

  ```plaintext
  make_xar --raw myxar --raw-executable echo --output echo
  ```

  ```plaintext
  [root@linux10A63A80A108 ~]# file echo 
  echo: a /usr/bin/env xarexec_fuse script executable (binary data)
  ```

  #### 使用 Cython

  ##### 4.1 思路

  虽说 `Cython` 的主要目的是带来性能的提升，但是基于它的原理：将 `.py`/`.pyx` 编译为 `.c` 文件，再将 `.c` 文件编译为 `.so`(Unix) 或 `.pyd`(Windows)，其带来的另一个好处就是难以破解。

  ##### 4.2 方法

  使用 `Cython` 进行开发的步骤也不复杂。

  1）编写文件 `hello.pyx` 或 `hello.py`：

  ```python
  def hello():
      print('hello')
  ```

  2）编写 `setup.py`：

  ```python
  from distutils.core import setup
  from Cython.Build import cythonize
  
  setup(name='Hello World app',
       ext_modules=cythonize('hello.pyx'))
  ```

  3）编译为 `.c`，再进一步编译为 `.so` 或 `.pyd`：

  ```bash
  python setup.py build_ext --inplace
  ```

  执行 `python -c "from hello import hello;hello()"` 即可直接引用生成的二进制文件中的 `hello()` 函数。

  ##### 4.3 优点

  *   生成的二进制 .so 或 .pyd 文件难以破解

  *   同时带来了性能提升

  ##### 4.4 不足

  *   兼容性稍差，对于不同版本的操作系统，可能需要重新编译

  *   虽然支持大多数 Python 代码，但如果一旦发现部分代码不支持，完善成本较高

  ### 对文件加密

  #### pyarmor 

  参考: [https://pyarmor.readthedocs.io/zh/stable/tutorial/getting-started.html](https://pyarmor.readthedocs.io/zh/stable/tutorial/getting-started.html)

  支持的平台: [https://pyarmor.readthedocs.io/zh/stable/reference/environments.html](https://pyarmor.readthedocs.io/zh/stable/reference/environments.html)

  license硬件信息通过  python -m pyarmor.cli.hdinfo 获取

  ```shell
  pip install pyarmor
  pyarmor gen -O dist -r src
  cd dist/
  mv pyarmor_runtime_000000 src/
  #python dist/src/hello.py
  # 使用选项 -e 可以方便的设置加密脚本的有效期。例如，设置加密脚本有效期为30天:
  pyarmor gen -O dist -e 30 -r src
  # 也可以使用另外一种格式 YYYY-MM-DD 来设置有效期
  pyarmor gen -O dist -e 2020-11-21 -r src
  # 使用 Pyarmor 8.4.6+ 可以通过命令 python -m pyarmor.cli.hdinfo 直接得到:term:客户设备 的硬件信息
  
  #组合多种硬件信息使用下面的格式
  pyarmor gen -O dist5 -b "00:16:3e:35:19:3d HXS2000CN2A" foo.py
  ```

  #### sourcedefender

  参考：[https://pypi.org/project/sourcedefender/](https://pypi.org/project/sourcedefender/)

  ```plaintext
  $ pip3 install sourcedefender
  ```

  ```text/x-sh
  $ sourcedefender encrypt --remove --ttl=1h /home/ubuntu/helloworld.py
  SOURCEdefender v7.1.14
  Processing:
  /home/ubuntu/helloworld.py
  $
  ```

  ```text/x-sh
  $ cat /home/ubuntu/helloworld.pye
  -----BEGIN SOURCEDEFENDER FILE-----
  GhP6+FOEA;qsm6NrRnXHnlU5E!(pT(E<#t=
  GhN0L!7UrbN"Am#(8iPPAG;nm-_4d!F9"*7
  T1q4VZdj>uLBghNY)[;Ber^L=*a-I[MA.-4
  ------END SOURCEDEFENDER FILE------
  $
  ```

  ```text/x-sh
  $ cd /home/ubuntu
  $ ls
  helloworld.pye
  $ python3
  >>> import sourcedefender
  >>> import helloworld
  Hello World!
  >>> exit()
  $
  ```

  #### vault

  (vault)，对敏感文本文件(代码或密码)加密

  加密前

  ```text/x-python
  #!/usr/bin/env python
  #encoding: utf-8
  print("hello world")
  ```

  加密后

  ```plaintext
  $ANSIBLE_VAULT;1.1;AES256
  39363832383934356237386265303133333630326365626236343965316265306263383530343630
  6565323537613637616637666562633438633230363038320a343261656664336362373036326533
  66626365616339656338663439666432333862393139303966663635656266343461626336343239
  3738393737656464390a323637636438643765316233323561643165643430626238643862333161
  38396362633466623061323139396131336461663830313731363766653737653563343166346137
  6262636633393732333831353061313937643139613338623363
  ```

  ### 代码混淆

  就是通过一系列的转换，让代码逐渐不让人那么容易明白，那就可以这样下手： 

  *   移除注释和文档。没有这些说明，在一些关键逻辑上就没那么容易明白了。 

  *   改变缩进。完美的缩进看着才舒服，如果缩进忽长忽短，看着也一定闹心。 

  *   在tokens中间加入一定空格。这就和改变缩进的效果差不多。 

  *   重命名函数、类、变量。命名直接影响了可读性，乱七八糟的名字可是阅读理解的一大障碍。 

  *   在空白行插入无效代码。这就是障眼法，用无关代码来打乱阅读节奏。

  #### 方法一：使用 oxyry 进行混淆

  [http://pyob.oxyry.com/](https://link.zhihu.com/?target=http%3A//pyob.oxyry.com/) 是一个在线混淆 Python 代码的网站，使用它可以方便地进行混淆。

  假定我们有这样一段 Python 代码，涉及到了类、函数、参数等内容：

  ```python
  # coding: utf-8
  
  class A(object):
      """
      Description
      """
  
      def __init__(self, x, y, default=None):
          self.z = x + y
          self.default = default
  
      def name(self):
          return 'No Name'
  
  
  def always():
      return True
  
  
  num = 1
  a = A(num, 999, 100)
  a.name()
  always()
  ```

  经过 `Oxyry` 的混淆，得到如下代码：

  ```python
  class A (object ):#line:4
      ""#line:7
      def __init__ (O0O0O0OO00OO000O0 ,OO0O0OOOO0000O0OO ,OO0OO00O00OO00OOO ,OO000OOO0O000OOO0 =None ):#line:9
          O0O0O0OO00OO000O0 .z =OO0O0OOOO0000O0OO +OO0OO00O00OO00OOO #line:10
          O0O0O0OO00OO000O0 .default =OO000OOO0O000OOO0 #line:11
      def name (O000O0O0O00O0O0OO ):#line:13
          return 'No Name'#line:14
  def always ():#line:17
      return True #line:18
  num =1 #line:21
  a =A (num ,999 ,100 )#line:22
  a .name ()#line:23
  always ()
  ```

  混淆后的代码主要在注释、参数名称和空格上做了些调整，稍微带来了点阅读上的障碍。

  #### 方法二：使用 pyobfuscate 库进行混淆

  [pyobfuscate](https://link.zhihu.com/?target=https%3A//github.com/astrand/pyobfuscate) 算是一个颇具年头的 Python 代码混淆库了，但却是“老当益壮”了。

  对上述同样一段 Python 代码，经 `pyobfuscate` 混淆后效果如下：

  ```python
  # coding: utf-8
  if 64 - 64: i11iIiiIii
  if 65 - 65: O0 / iIii1I11I1II1 % OoooooooOO - i1IIi
  class o0OO00 ( object ) :
   if 78 - 78: i11i . oOooOoO0Oo0O
   if 10 - 10: IIiI1I11i11
   if 54 - 54: i11iIi1 - oOo0O0Ooo
   if 2 - 2: o0 * i1 * ii1IiI1i % OOooOOo / I11i / Ii1I
   def __init__ ( self , x , y , default = None ) :
    self . z = x + y
    self . default = default
    if 48 - 48: iII111i % IiII + I1Ii111 / ooOoO0o * Ii1I
   def name ( self ) :
    return 'No Name'
    if 46 - 46: ooOoO0o * I11i - OoooooooOO
    if 30 - 30: o0 - O0 % o0 - OoooooooOO * O0 * OoooooooOO
  def Oo0o ( ) :
   return True
   if 60 - 60: i1 + I1Ii111 - I11i / i1IIi
   if 40 - 40: oOooOoO0Oo0O / O0 % ooOoO0o + O0 * i1IIi
  I1Ii11I1Ii1i = 1
  Ooo = o0OO00 ( I1Ii11I1Ii1i , 999 , 100 )
  Ooo . name ( )
  Oo0o ( ) # dd678faae9ac167bc83abf78e5cb2f3f0688d3a3
  ```

  相比于方法一，方法二的效果看起来更好些。除了类和函数进行了重命名、加入了一些空格，最明显的是插入了若干段无关的代码，变得更加难读了。

  # 优点缺点对比

  ## 打包成执行程序

  *   优点：不需要预装Python三方库；打包完成后仅一个文件。

  *   缺点：

      *   跨平台不一定支持

      *   对python版本有要求，比如Pyinstaller在高版本（Python3.5）以后支持性差

      *   对代码撰写有要求，尤其是在绝对路径、相对路径等使用场景

      *   因为依赖的环境也打包其中，文件体积大

      *   反编译难度一般

  ## 加密代码文件

  *   优点

      *   AES-256加密

      *   多平台支持

      *   支持有效期

  *   缺点:

  *   很多库仅能加密单个文件，而不能加密整个工程文件夹

  ## 代码混淆

  *   优点

  *   简单方便，提高了一点源码破解门槛

  *   兼容性好，只要源码逻辑能做到兼容，混淆代码亦能

  *   不足

  *   只能对单个文件混淆，无法做到多个互相有联系的源码文件的联动混淆

  *   代码结构未发生变化，也能获取字节码，破解难度不大