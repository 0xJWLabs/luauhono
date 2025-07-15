# 🐈 LuauHono

LuauHono is a simple and fast Luau web framework for Lune. LuauHono is inspired by [Hono](https://github.com/honojs/hono) and shares a similar API.

```luau
local app = LuauHono.new()

app:get('/', function(req, res)
	return res:text('LuauHono!')
end)

app:serve()
```

## Features

- 🧩 **Simple API** - Convenient methods for creating routes and generating a response
- ⚡️ **Fast Routing** - Efficient routing using a radix tree
- 📦 **Intuitive Middleware** - Extend request handling easily

## Documentation

Coming Soon
