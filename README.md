<div align="center">
  <a href="https://luauhono.dev">
    <img src="https://raw.githubusercontent.com/0xjwlabs/luauhono/main/docs/images/luauhono-title.png" width="500" height="auto" alt="LuauHono"/>
  </a>
</div>

<hr />

<p align="center">
<a href="https://luauhono.dev"><b>Documentation 👉 luauhono.dev</b></a><br />
</p>

<hr />


LuauHono is a small, simple and fast web framework for Lune. It is inspired by [Hono](https://github.com/honojs/hono) and shares a similar API.

```luau
local app = LuauHono.new()

app:get('/', function(c)
	return c:text('LuauHono!')
end)

app:serve()
```

## Features

- 🧩 **Simple API** - Convenient methods for creating routes and generating a response
- ⚡️ **Fast Routing** - Efficient routing using a radix tree
- 📦 **Intuitive Middleware** - Extend request handling easily

## Documentation

Coming Soon
