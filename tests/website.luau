local net = require("@lune/net")

local URL_ROOT = "http://localhost:8080"

local website = require("../src/main")

local notFound = {"/none", "/eli/progress/none", "//"}
for _, url in notFound do
	local response = net.request({
		url = URL_ROOT .. url,
		method = "GET"
	})
	assert(response.statusCode == 404, "Status code must be 404.")
	assert(string.find(response.body, "Not Found"), "Body must contain error name.")
end

local html = {
	["/"] = "Index",
	["/credits"] = "Credits",
	["/bridge-duel"] = "Coming Soon™️",
	["/cat-bash"] = "Coming Soon™️",
	["/eli"] = "Eli",
	["/eli/progress"] = "Programming Progress",
	["/games"] = "Coming Soon™️"
} :: {[string]: string}
for path, heading in html do
	local response = net.request({
		url = URL_ROOT .. path,
		method = "GET"
	})
	assert(response.statusCode == 200, "Status code must be 200.")
	assert(string.find(response.body, `<h1>{heading}</h1>`), "Unexpected heading.")
end

local static = {
	css = {
		"main.css"
	},
	images = {
		"favicon.ico"
	},
	js = {
		"main.js"
	}
} :: {[string]: {string}}
for category, items in static do
	for _, name in items do
		local response = net.request({
			url = URL_ROOT .. `/static/{category}/{name}`,
			method = "GET"
		})
		assert(response.statusCode == 200, "Status code must be 200.")
	end
end

website:stop()

return nil