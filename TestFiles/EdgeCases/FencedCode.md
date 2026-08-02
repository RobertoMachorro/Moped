# FencedCode.md

Exercises the Markdown tokenizer's fenced-code handling: contents inside the
fence should render as literal text, not Markdown syntax.

```
# This looks like a heading but it's inside a fence, so it must stay literal.
*This looks like emphasis but it's inside a fence too.*
[This looks like a link](https://example.com)
```

Back to normal Markdown text after the fence — **this** should highlight again.

```python
def inside_fence():
    # A ``` triple-backtick sequence never appears inside this fence's body,
    # so the parser only needs to find the closing fence below.
    return "still literal"
```

Done.
