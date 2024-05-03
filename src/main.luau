--!strict

local fs = require("@lune/fs")

local Lunition = require("Lunition")
local App = Lunition.Application
local Lunit = Lunition.Lunit

local website = App.new()
website.errorHandlerLuau = Lunit.defaultHandlers.luau
website.errorHandlerHttp = Lunit.defaultHandlers.http

website:route("", "html/index.html")
website:route("static", "static")

for _, path in fs.readDir("site") do
	website:route(assert(string.match(path, "^[%a-]+")), require(`site/{path}`))
end

website:start(8080)

print("Running on port 8080.")