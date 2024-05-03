--!strict
--!nolint LocalShadow

local fs = require("@lune/fs")
local net = require("@lune/net")

local Codes = require("codes")
local Render = require("render")

local Lunit = {
    className = "Moonprint"
}
Lunit.__index = Lunit

export type Lunit = typeof(setmetatable({} :: {
    _routes: {
        [string]: router
    },
    errorHandler: errorHandler?
}, Lunit))
export type router = string | ((request: net.ServeRequest) -> (net.ServeResponse)) | Lunit
export type errorHandler = (code: number, name: string, description: string) -> (net.ServeResponse)
export type responseWrapped = {
    response: net.ServeResponse,
    errorHandled: boolean,
}

function Lunit.new(): (Lunit)
    return setmetatable({
        _routes = {}
    }, Lunit)
end

Lunit.defaultErrorHandler = (function(code, name, description)
    return {
        status = code,
        body = Render("html/error.html", {
            code = tostring(code),
            name = name,
            description = description
        })
    }
end) :: errorHandler



function Lunit.route(self: Lunit, urlPath: string, router: router): ()
    self._routes[urlPath] = router
end

function Lunit.run(self: Lunit, request: net.ServeRequest, depth: number?): (responseWrapped)
    -- setup for response wrapper
    local response: net.ServeResponse
    local depth = depth or 1
    local pathPiecesUrl = string.split(request.path, "/")
    table.remove(pathPiecesUrl, 1)
    
    for urlPath, router in self._routes do
        local pathPiecesRoute = string.split("/" .. urlPath, "/")
        table.remove(pathPiecesRoute, 1)

        if pathPiecesUrl[depth] == pathPiecesRoute[1] then
            -- see how far it goes
            local routeDepth = 1
            repeat
                depth += 1
                routeDepth += 1
            until pathPiecesUrl[depth] ~= pathPiecesRoute[routeDepth] or depth > #pathPiecesUrl
            depth -= 1 -- correct depth since it went over

            local success = true
            if type(router) == "function" or type(router) == "string" and not fs.isDir(router) then
                -- url needs to be exact for functions and files
                success = depth == #pathPiecesUrl
            end

            if success then
                if type(router) == "string" then
                    -- file or directory
                    if fs.isDir(router) then
                        -- url path should lead to a file
                        router ..= string.sub(request.path, assert(string.find(request.path, urlPath)) + #urlPath)
                    end

                    -- now it better not be a directory
                    if fs.isDir(router) then
                        response = {
                            status = 400,
                            body = "Please specify a file."
                        }
                        break
                    end

                    -- reading files can always go wrong
                    local success, results = pcall(fs.readFile, router)
                    if not success then
                        -- lazy error message but it should work
                        local errorFull = tostring(results)
                        local errorMessage = string.sub(errorFull, 1, (string.find(errorFull, "\n")))
                        response = {
                            status = 400,
                            body = `fs error: {errorMessage}`
                        }
                        break
                    end

                    -- automatically render HTML for easier static pages
                    if string.find(router, ".html$") then
                        results = Render(router)
                    end

                    -- success!
                    response = {
                        body = results
                    }
                elseif type(router) == "function" then
                    -- custom function
                    response = router(request)
                else
                    -- lunit
                    local wrapped = router:run(request, depth + 1)
                    response = wrapped.response
                    -- return if it is already good
                    if wrapped.errorHandled then
                        return wrapped
                    end
                end
            end
        end
    end

    -- if no response then this is a dead path
    response = response or {
        status = 404,
        body = `Unknown path {request.path}.`
    }

    -- handle error if necessary
    if response.status and response.status >= 400 and self.errorHandler then
        -- this will bubble up since the error was handled
        return {
            response = self.errorHandler(response.status, Codes[response.status], response.body or ""),
            errorHandled = true
        }
    else
        return {
            response = response,
            errorHandled = false
        }
    end 
end

return Lunit