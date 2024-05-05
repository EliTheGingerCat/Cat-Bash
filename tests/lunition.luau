local fs = require("@lune/fs")
local net = require("@lune/net")

local Lunition = require("../src/Lunition")
local Application = Lunition.Application
local Lunit = Lunition.Lunit

local URL_ROOT = "http://localhost:8080"
local TEXT = "hello"
local RESPONSE = {
	body = TEXT
}

local website = Application.new()
website:route("/", function()
	return RESPONSE
end)
website:route("/hello/cat", function()
	return RESPONSE
end)
website:route("/data", "../tests/data.txt")

local blog = Lunit.new()
blog:route("/one", function()
	return RESPONSE
end)
website:route("/blog", blog)

website:start(8080)

local paths = {
	["/"] = TEXT,
	["/hello/cat"] = TEXT,
	["/blog/one"] = TEXT,
	["/data"] = fs.readFile("../tests/data.txt")
} :: {[string]: string}
for path, body in paths do
	local response = net.request({
		url = URL_ROOT .. path
	})
	assert(response.statusCode == 200, "Status code must be 200.")
	assert(response.body == body, "Body does not match.")
end

website:stop()

local success, _ = pcall(net.request, {
	url = URL_ROOT .. "/"
})
assert(not success, "Website should be shut down.")

return nil