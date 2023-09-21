

串行

```typescript
async publishPack(manifest: Manifest){
  for (let pack of manifest.packages) {
    const {data} = await publishPackage();
    let return_message: Message = data;
  }
}
```

