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
    errorHandlerLuau: errorLuauHandler?,
    errorHandlerHttp: errorHttpHandler?
}, Lunit))
export type router = string | ((request: net.ServeRequest) -> (net.ServeResponse)) | Lunit
export type errorLuauHandler = (message: string) -> (net.ServeResponse)
export type errorHttpHandler = (code: number, name: string, description: string) -> (net.ServeResponse)
export type responseWrapped = {
    response: net.ServeResponse,
    errorHandled: boolean,
}

Lunit.defaultHandlers = {}
Lunit.defaultHandlers.luau = (function(message)
    return {
        status = 500,
        body = Render("html/error/luau.html", {
            message = message
        })
    }
end) :: errorLuauHandler
Lunit.defaultHandlers.http = (function(code, name, description)
    return {
        status = code,
        body = Render("html/error/http.html", {
            code = tostring(code),
            name = name,
            description = description
        })
    }
end) :: errorHttpHandler



local function routeStatic(pathRouter: string, pathRequest: string): (net.ServeResponse)
    if fs.isDir(pathRouter) then
        -- url path should lead to a file
        pathRouter ..= string.sub(pathRequest, assert(string.find(pathRequest, pathRouter)) + #pathRouter)
    end

    -- now it better not be a directory
    if fs.isDir(pathRouter) then
        return {
            status = 400,
            body = "Please specify a file."
        }
    end

    -- reading files can always go wrong
    print(pathRouter)
    local success, results = pcall(fs.readFile, pathRouter)
    if not success then
        -- lazy error message but it should work
        local errorFull = tostring(results)
        local errorMessage = string.sub(errorFull, 1, (string.find(errorFull, "\n")))
        return {
            status = 400,
            body = `fs error: {errorMessage}`
        }
    end

    -- automatically render HTML for easier static pages
    if string.find(pathRouter, ".html$") then
        results = Render(pathRouter)
    end

    -- success!
    return {
        body = results
    }
end

local function routeLunit(lunit: Lunit, request: net.ServeRequest, depth: number): (responseWrapped)
    local success, results = pcall(lunit.run, lunit, request, depth + 1)
    if success then
        return results
    else
        -- Luau error
        if lunit.errorHandlerLuau then
            return {
                response = lunit.errorHandlerLuau(results :: any), -- TC is Wrong!,
                errorHandled = true
            }
        else
            -- bubble up the error
            error(results)
        end
    end
end



function Lunit.new(): (Lunit)
    return setmetatable({
        _routes = {},
    }, Lunit)
end

function Lunit.route(self: Lunit, pathRouter: string, router: router): ()
    self._routes[pathRouter] = router
end

function Lunit.run(self: Lunit, request: net.ServeRequest, depth: number?): (responseWrapped)
    print(self, depth)
    -- setup for response wrapper
    local response: net.ServeResponse
    local depth = depth or 1
    local pathRequest = request.path
    pathRequest = string.gsub(request.path, "^/$", "") -- remove lonely slashes
    local pathPiecesUrl = string.split(pathRequest, "/")
    table.remove(pathPiecesUrl, 1)
    
    for pathRouter, router in self._routes do
        pathRouter = string.gsub(pathRouter, "^/$", "")
        local pathPiecesRoute = string.split(pathRouter, "/")
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
                success = depth >= #pathPiecesUrl
            end

            if success then
                if type(router) == "string" then
                    -- file or directory
                    response = routeStatic(pathRouter, pathRequest)
                    break
                elseif type(router) == "function" then
                    -- custom function
                    response = router(request)
                    break
                else
                    -- lunit
                    local wrapped = routeLunit(router, request, depth)
                    if wrapped.errorHandled then
                        return wrapped
                    else
                        response = wrapped.response
                        break
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
    if response.status and response.status >= 400 and self.errorHandlerHttp then
        -- this will bubble up since the error was handled
        return {
            response = self.errorHandlerHttp(response.status, Codes[response.status], response.body or ""),
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