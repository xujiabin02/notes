# <3.6不加协程

```python
import time
import asyncio


def now():
    return time.time()


codes = ['1', '2', '3', '4', '5']


def do_some_work(my_url, my_count):
    t = now() - start
    log_str = f'第{my_count}个URL是:{my_url}, 花了{t}秒'
    time.sleep(2)
    print(log_str)


start = now()
tasks = []
count = 0
for code in codes:
    url = 'http://baidu.com'
    count += 1
    do_some_work(url, count)

print(f'Time: {now() - start}')

```



# <3.6加协程

## 写法一

```python
import time
import asyncio

now = lambda: time.time()

codes = ['1', '2', '3', '4', '5']


async def do_some_work(url, count):
    t = now() - start
    str = f'第{count}个URL是:{url}, 花了{t}秒'
    await asyncio.sleep(2)
    print(str)


start = now()
tasks = []
count = 0
for code in codes:
    url = 'http://baidu.com'
    count += 1
    tasks.append(asyncio.ensure_future(do_some_work(url, count)))

loop = asyncio.get_event_loop()
loop.run_until_complete(asyncio.wait(tasks))

print(f'Time: {now() - start}')

```





## 写法二

> ```python
> 
> ```
>
> 





# \>3.6协程

```python
import time
import asyncio

now = lambda: time.time()

codes = ['1', '2', '3', '4', '5']


async def do_some_work(url, count):
    t = now() - start
    str = f'第{count}个URL是:{url}, 花了{t}秒'
    await asyncio.sleep(2)
    print(str)


start = now()
tasks = []
count = 0
for code in codes:
    url = 'http://baidu.com'
    count += 1
    tasks.append(asyncio.ensure_future(do_some_work(url, count)))

loop = asyncio.run(asyncio.wait(tasks))

print(f'Time: {now() - start}')

```

