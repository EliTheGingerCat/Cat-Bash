-- Type checking is goofy here, but it allows for best user experience when using Lunition.

local net = require("@lune/net")

local Lunit = require("lunit")

--[=[
	@class Application
	An Application is the main object that
	handles serving the website.
]=]
local Application = {
	className = "Application"
}
Application.__index = Application
do setmetatable(Application, Lunit) end -- the `do` block matters for some reason 😭

export type Application = Lunit.Lunit & typeof(setmetatable({} :: {
	_handle: net.ServeHandle?
}, Application))

--[=[
	@return Application
	Constructs an Application object.

	```lua
	local app = Application.new()
	```
]=]
function Application.new(): (Application)
	local self = Lunit.new() :: any
	setmetatable(self, Application)
	return self
end

--[=[
	@within Application
	@param port -- The port to be served to.
	Starts serving the application.

	```lua
	app:start(8080)
	```
]=]
function Application.start(self: Application, port: number): ()
	if self._handle then
		error("Application is already running.")
	end

	self._handle = net.serve(port, function(request)
		local success, results = pcall(self.run, self, request)
		if success then
			return results.response
		else
			-- a little bit repetitive
			-- but I think this copy-and-paste is acceptable
			if self.errorHandlerLuau then
				return self.errorHandlerLuau(results :: any)
			else
				-- error can no longer be bubbled up
				return {
					status = 500,
					body = "Something went wrong."
				}
			end
		end
	end)
end

--[=[
	@within Application
	Stops serving the application.

	```lua
	app:stop()
	```
]=]
function Application.stop(self: Application): ()
	if self._handle then
		self._handle.stop()
		self._handle = nil
	else
		error("Application is not running.")
	end
end

return Application