local luau = require("@lune/luau")
local serde = require("@lune/serde")

local Lunition = require("../Lunition")
local Lunit = Lunition.Lunit

local lAPI = Lunit.new()

lAPI:route("/", "html/api.html")
lAPI:route("/luau-bytecode", function(req)
	if req.method ~= "POST" then
		return {
			status = 400
		}
	end

	local body = serde.decode("json", req.body)

	if not body or not body.luau or typeof(body.luau) ~= "string" then
		return {
			status = 400
		}
	end

	local success, result = pcall(luau.compile, body.luau)
	
	if not success then
		return {
			status = 400
		}
	end

	return {
		body = serde.encode("json", {
			bytecode = result
		}),
		status = 200
	}
end)

return lAPI