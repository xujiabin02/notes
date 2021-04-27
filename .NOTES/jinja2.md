# 空白控制

## jinja2模板渲染移除空白[^ 空白控制]

默认配置中，模板引擎不会对空白做进一步修改，所以每个空白（空格、制表符、换行符 等等）都会原封不动返回。如果应用配置了 Jinja 的 trim_blocks ，模板标签后的 第一个换行符会被自动移除（像 PHP 中一样）。

此外，你也可以手动剥离模板中的空白。当你在块（比如一个 for 标签、一段注释或变 量表达式）的开始或结束放置一个减号（ - ），可以移除块前或块后的空白:

```jinja2
{% for item in seq -%}
    {{ item }}
{%- endfor %}
```

这会产出中间不带空白的所有元素。如果 seq 是 1 到 9 的数字的列表， 输出会是123456789 。

如果开启了 [*行语句*](http://docs.jinkan.org/docs/jinja2/templates.html#line-statements) ，它们会自动去除行首的空白。

提示

标签和减号之间不能有空白。

**有效的**:

```jinja2
{%- if foo -%}...{% endif %}
```

**无效的**:

```jinja2
{% - if foo - %}...{% endif %}
```

[中文文档](https://www.kancloud.cn/manual/jinja2/70455)

[^ 空白控制]: https://www.kancloud.cn/manual/jinja2/70455

