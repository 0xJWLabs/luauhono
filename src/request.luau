local net = require("@lune/net")
local serde = require("@lune/serde")

local Request = {}
Request.__index = Request

export type RequestParamaters = {
	path: string,
	query: { [string]: string }?,
	method: RequestMethod,
	headers: { [string]: string },
	body: string,
	params: { [string]: string },
	validatedData: { [string]: any },
	json: (self: Request) -> any,
}

export type Request = typeof(setmetatable({} :: RequestParamaters, Request))
export type RequestMethod = "DELETE" | "GET" | "HEAD" | "OPTIONS" | "PATCH" | "POST" | "PUT"

local function RequestJson(self: Request)
	return serde.decode("json", self.body)
end

function Request.new(base: net.ServeRequest)
	return setmetatable({
		path = base.path,
		method = base.method,
		body = base.body,
		query = base.query,
		headers = base.headers or {},
		validatedData = {},
		params = {},
		json = RequestJson,
	}, Request)
end

return Request
