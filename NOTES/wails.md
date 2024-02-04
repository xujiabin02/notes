# install

```sh
go install github.com/wailsapp/wails/v2/cmd/wails@latest
```

# 生成vue-ts

```sh
wails init -n vueTsapp -t vue-ts
```

# 升级package.json里面的vue-tsc版本

```sh
sed -i .bak 's/\"vue\-tsc\"\: \"\^0.39.5\"\,/\"vue\-tsc\"\: \"\^1.8.27\"\,/g' frontend/package.json
```

