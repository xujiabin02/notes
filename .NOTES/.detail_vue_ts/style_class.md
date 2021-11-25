





```vue
<div :style="this.table_style"></div>
<div :class="{ active: isActive }"></div>
<div
  class="static"
  :class="{ active: isActive, 'text-danger': hasError }"
></div>
<script>
  table_style = {
  color: 'red',
  width: '100%',
}
  isActive: true,
  hasError: false
</script>

```

ps: https://v3.vuejs.org/guide/class-and-style.html#binding-html-classes

