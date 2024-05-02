--!strict

local net = require("@lune/net")

local Moonprint = require("moonprint")

local Application = {
    className = "Application"
}
Application.__index = Application
setmetatable(Application, Moonprint)

export type Application = typeof(setmetatable({} :: {
    _handle: net.ServeHandle?
}, Application))

function Application.new(): (Application)
    local self = Moonprint.new()
    setmetatable(self, Application)
    return self
end

function Application.start(self: Application, port: number): ()
    if self._handle then
        error("Application is already running.")
    end

    self._handle = net.serve(port, function(request)
        return self:run(request)
        --[[local Codes = require("codes")
            if response.status and response.status >= 400 and router.errorHandler then
            return router.errorHandler(response.status, Codes[response.status], response.body or "")
        end]]
    end)
end

function Application.stop(self: Application): ()
    if self._handle then
        self._handle.stop()
        self._handle = nil
    else
        error("Application is not running.")
    end
end

return Application