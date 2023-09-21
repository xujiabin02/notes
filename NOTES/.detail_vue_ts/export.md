#  ts:export,import

```typescript
// foo.ts
const someVar = 123;
export { someVar as aDifferentName };
// bar.ts 
import {someVar, someType} from './foo'
```

# 相对路径查找

```typescript
import * as foo from '../foo'
```



# 动态查找

> - ../node_modules/foo
> - ../../node_modules/foo
> - ../../../node_modules/foo



# 声明全局模块

```typescript
declare module 'somePath'
```

