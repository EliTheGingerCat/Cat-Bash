--!strict

local net = require("@lune/net")

local Lunit = require("lunit")

local Application = {
    className = "Application"
}
Application.__index = Application
setmetatable(Application, Lunit)

export type Application = Lunit.Lunit & typeof(setmetatable({} :: {
    _handle: net.ServeHandle?
}, Application))

function Application.new(): (Application)
    local self = Lunit.new() :: any
    setmetatable(self, Application)
    return self
end

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
                    body = `Luau error: {results}`
                }
            end
        end
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