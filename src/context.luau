local net = require("@lune/net")
local serde = require("@lune/serde")

local clean = require("./helper/clean")
local Request = require("./request")

type Request = Request.Request

local Context = {}
Context.__index = Context

type ContextProperties = {
	rawRequest: net.ServeRequest,
	req: Request.Request,
	notFoundHandler: (Context) -> net.ServeResponse,
	res: net.ServeResponse,
	finalized: boolean,
}

export type Data = buffer | string
export type Context = typeof(setmetatable({} :: ContextProperties, Context))

function Context.new(req: net.ServeRequest, notFoundHandler: (Context) -> net.ServeResponse)
	return setmetatable({
		rawRequest = req,
		req = Request.new(req),
		res = {
			headers = {},
		} :: net.ServeResponse,
		notFoundHandler = notFoundHandler,
		finalized = false,
	}, Context)
end

function Context.finalize(self: Context)
	self.finalized = true
	return self.res
end

function Context.header(self: Context, key: string, value: string?)
	self.res.headers = self.res.headers or {}
	(self.res.headers :: any)[key] = value

	return self
end

function Context.status(self: Context, status: number)
	self.res.status = status
	return self
end

function Context.body(self: Context, data: Data, status: number?, headers: { [string]: string }?)
	self.res.body = data
	self.res.status = status or 200

	if headers then
		for key, value in headers do
			self:header(key, value)
		end
	end

	return self:finalize()
end

function Context.text(self: Context, text: string, status: number?, headers: any?): net.ServeResponse
	self:header("Content-Type", "text/plain; charset=utf-8")
	return self:body(text, status, headers)
end

function Context.json(self: Context, json: any, status: number?, headers: any?): net.ServeResponse
	self:header("Content-Type", "application/json")
	local body = serde.encode("json", clean(json))

	return self:body(body, status, headers)
end

function Context.html(self: Context, html: string, status: number?, headers: any?): net.ServeResponse
	self:header("Content-Type", "text/html; charset=utf-8")
	return self:body(html, status, headers)
end

function Context.notFound(self: Context): net.ServeResponse
	return self.notFoundHandler(self)
end

function Context.redirect(self: Context, location, status: number?)
	self:header("Location", location)
	self:status(status or 302)
	return self:finalize()
end

return Context
