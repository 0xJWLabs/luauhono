type AnyTable = { [any]: any }

local function clean<T>(s: T, visited: { [any]: any }?): T
	visited = visited or {}

	if (visited :: AnyTable)[s] then
		return (visited :: AnyTable)[s]
	end

	local result: AnyTable = {}
	(visited :: AnyTable)[s] = result

	-- Use `next` instead of `pairs` to avoid `__pairs`
	for key, value in s :: any do
		if typeof(value) == "function" or typeof(value) == "thread" or type(value) == "userdata" then
			continue
		end

		if typeof(value) == "table" then
			result[key] = clean(value, visited)
		else
			result[key] = value
		end
	end

	return (result :: any) :: T
end

return clean
