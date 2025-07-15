local net = require("@lune/net")
local Router = require("@luauhono/router")
local Request = require("@luauhono/request")
local Context = require("@luauhono/context")
local static = require("@luauhono/static")
local Types = require("@luauhono/types")

type Router = Router.Router
export type Request = Request.Request
export type Context = Context.Context
export type Handler = Types.Handler
export type ErrorHandler = Types.ErrorHandler
export type Middleware = Types.Middleware
export type MatchResponse = Types.MatchResponse

type MixedHandler = Middleware

local LuauHono = {}
LuauHono.__index = LuauHono

type LuauHonoData = {
	router: Router,
	routes: { { method: string, path: string, handler: Handler | Middleware } },
	notFoundHandler: Handler,
	errorHandler: ErrorHandler,
	server: net.ServeHandle?,
}

export type LuauHono = typeof(setmetatable({} :: LuauHonoData, LuauHono))

export type LuauHonoConfig = {
	port: number?,
	address: string?,
}

local defaultNotFound: Handler = function(c: Context): net.ServeResponse
	c:status(404)
	return c:text("Not Found")
end

local defaultErrorHandler: ErrorHandler = function(c: Context, error: string): net.ServeResponse
	print("Error:", error)
	c:status(500)
	return c:text("Internal Server Error")
end

function LuauHono.new(): LuauHono
	local self = {}
	self.router = Router.new()
	self.routes = {}
	self.notFoundHandler = defaultNotFound
	self.errorHandler = defaultErrorHandler
	self.server = nil :: net.ServeHandle?
	return setmetatable(self, LuauHono)
end

function LuauHono.route(self: LuauHono, path: string, app: LuauHono)
	for _, route in app.routes do
		self:addRoute(route.method, path .. route.path, route.handler)
	end
	return self
end

function LuauHono.addRoute(self: LuauHono, method: string, path: string, handler: Handler | Middleware)
	method = method:upper()
	self.router:add(method, path, handler)
	table.insert(self.routes, { method = method, path = path, handler = handler })
	return self
end

function LuauHono.use(self: LuauHono, path: string | Middleware, handler: Middleware?, ...: Middleware)
	local realPath = path
	if handler == nil then
		if type(path) == "string" then
			error("Handler must be provided when using a path")
		end
		handler = path
		realPath = "*"
	end

	assert(typeof(realPath) == "string", "Path must be a string")
	assert(typeof(handler) == "function", "Handler must be a function")
	self.router:add("ALL", realPath, handler)
	for _, h in { ... } do
		self.router:add("ALL", realPath, h)
	end
	return self
end

function LuauHono.on(self: LuauHono, method: string, path: string, handler: MixedHandler, ...: MixedHandler)
	self:addRoute(method, path, handler)
	for _, h in { ... } do
		self:addRoute(method, path, h)
	end
	return self
end

function LuauHono.all(self: LuauHono, path: string, handler: MixedHandler, ...: MixedHandler)
	return self:on("ALL", path, handler, ...)
end

function LuauHono.get(self: LuauHono, path: string, handler: MixedHandler, ...: MixedHandler)
	return self:on("GET", path, handler, ...)
end

function LuauHono.post(self: LuauHono, path: string, handler: MixedHandler, ...: MixedHandler)
	return self:on("POST", path, handler, ...)
end

function LuauHono.put(self: LuauHono, path: string, handler: MixedHandler, ...: MixedHandler)
	return self:on("PUT", path, handler, ...)
end

function LuauHono.delete(self: LuauHono, path: string, handler: MixedHandler, ...: MixedHandler)
	return self:on("DELETE", path, handler, ...)
end

function LuauHono.patch(self: LuauHono, path: string, handler: MixedHandler, ...: MixedHandler)
	return self:on("PATCH", path, handler, ...)
end

function LuauHono.static(self: LuauHono, path: string, directory: string)
	return self:get(path:gsub("/$", "") .. "/*", static(path, directory))
end

function LuauHono.notFound(self: LuauHono, handler: Handler)
	self.notFoundHandler = handler
	return self
end

function LuauHono.onError(self: LuauHono, handler: ErrorHandler)
	self.errorHandler = handler
	return self
end

function LuauHono.dispatch(self: LuauHono, request: net.ServeRequest): net.ServeResponse
	local match: MatchResponse? = Router.match(self.router, request.method, request.path)

	local req = Request.new(request)
	local context = Context.new(req, self.notFoundHandler)

	if not match then
		return self.notFoundHandler(context)
	end

	if #match == 1 then
		local handler = match[1].handler
		req.params = match[1].params or {}
		local success, result = pcall(handler, context, function()
			return self.notFoundHandler(context) -- If the single handler is a middleware, it must be not found
		end)

		if success then
			return result or context.res
		else
			return self.errorHandler(context, result)
		end
	end

	local function dispatch(i): net.ServeResponse?
		if i > #match then
			return self.notFoundHandler(context)
		end

		req.params = match[i].params or {}

		local handler = match[i].handler

		return (handler :: Middleware)(context, function()
			dispatch(i + 1)
		end)
	end

	local success, result = pcall(dispatch, 1)

	if not success then
		return self.errorHandler(context, result)
	elseif context.finalized then
		return context.res
	else
		return self.notFoundHandler(context)
	end
end

function LuauHono.request(self: LuauHono, request: string | net.ServeRequest): net.ServeResponse
	if typeof(request) == "string" then
		return self:dispatch({
			method = "GET",
			path = request,
			body = "",
			headers = {},
			query = {},
		})
	end
	return self:dispatch(request)
end

function LuauHono.serve(self: LuauHono, config: LuauHonoConfig?)
	local c: LuauHonoConfig = config or {}
	self.server = net.serve(c.port or 3000, {
		address = c.address or "http://0.0.0.0",
		handleRequest = function(req)
			return LuauHono.dispatch(self, req)
		end,
	})
	return self
end

return LuauHono
