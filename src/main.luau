--!strict

local App = require("application")
local Moonprint = require("moonprint")

local website = App.new()

local blog = Moonprint.new()
blog:route("hello", "html/blog/hello.html")

local secretBlog = Moonprint.new()
secretBlog:route("how", "html/blog/secret/how.html")

website:route("", "html/index.html")
website:route("cat", "html/cat.html")
website:route("kid", "html/kid.html")
website:route("static", "static")

blog:route("secret", secretBlog)
website:route("blog", blog)

website.errorHandler = Moonprint.defaultErrorHandler

website:start(8080)

print("Running on port 8080.")