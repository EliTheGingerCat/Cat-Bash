local fs = require("@lune/fs")

local Lunition = require("Lunition")
local App = Lunition.Application
local Lunit = Lunition.Lunit

local website = App.new()
website.errorHandlerLuau = Lunit.defaultHandlers.luau
website.errorHandlerHttp = Lunit.defaultHandlers.http

website:route("/static", "static")

-- This is the old way of displaying favicons - serving it at `/favicon.ico`. Maybe we should return to using
-- <link rel="icon" type="image/x-icon" href="/static/images/favicon.ico">
-- in base.html, though this seems to have better compatibility.
website:route("/favicon.ico", "static/images/favicon.ico")

website:route("/", require("site-base"))

for _, path in fs.readDir("site") do
	-- Catches everything before the extension and adds it as the urlPath for that lunit. Maybe we should switch to manually routing each lunit so TC is happy.
	website:route("/" .. assert(string.match(path, "(.+).luau")), require(`site/{path}`))
end

website:start(8080)

print("Running on port 8080.")

return website