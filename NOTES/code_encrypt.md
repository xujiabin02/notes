- sourcedefender

- 对照组

- 参考: [https://pyarmor.readthedocs.io/zh/stable/tutorial/getting-started.html](https://pyarmor.readthedocs.io/zh/stable/tutorial/getting-started.html)

- ```shell
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

  -