local net = require("@lune/net")

local website = require("../src/main") -- get the server running

local url = "http://localhost:8080"

local response = net.request({
	url = url,
	method = "GET"
})

assert(string.find(response, "Hi, I like cats."), "Index page does not work!")

website:stop()