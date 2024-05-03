--!strict
--!nolint LocalShadow

local fs = require("@lune/fs")
local net = require("@lune/net")

local Codes = require("codes")
local Render = require("render")

local Lunit = {
    className = "Lunit"
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
    errorHandled: boolean?,
    found: boolean?
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



local function routeStatic(pathStatic: string, pathRequest: string): (net.ServeResponse)
    if fs.isDir(pathStatic) then
        -- url path should lead to a file
        pathStatic ..= string.sub(pathRequest, assert(string.find(pathRequest, pathStatic)) + #pathStatic)
    end

    -- now it better not be a directory
    if fs.isDir(pathStatic) then
        return {
            status = 400,
            body = "Please specify a file."
        }
    end

    -- reading files can always go wrong
    local success, results = pcall(fs.readFile, pathStatic)
    if not success then
        -- lazy error message but it should work
        local errorMessage = string.match(tostring(results), "(.-)\n")
        return {
            status = 400,
            body = `fs error: {errorMessage}`
        }
    end

    -- automatically render HTML for easier static pages
    if string.find(pathStatic, ".html$") then
        results = Render(pathStatic)
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

local function handleRouter(router: router, request: net.ServeRequest, pathRouter: string, pathRequest: string, depth: number): (responseWrapped)
    local wrapped
    if type(router) == "string" then
        -- file or directory
        wrapped = {
            response = routeStatic(router, pathRequest)
        }
    elseif type(router) == "function" then
        -- custom function
        wrapped = {
            response = router(request)
        }
    elseif type(router) == "table" then
        -- lunit
        wrapped = routeLunit(router, request, depth)
    else
        error("Invalid router!")
    end
    -- ensure that the found attribute exists
    wrapped.found = wrapped.found or not wrapped.response.status or wrapped.response.status < 400
    return wrapped
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
    local wrapped = {} :: responseWrapped
    local depth = depth or 1
    local pathRequest = request.path
    local pathPiecesUrl = string.split(pathRequest, "/")
    
    if pathRequest ~= "/" then
        for pathRouter, router in self._routes do
            if pathRouter == "/" then
                continue
            end
            local pathPiecesRoute = string.split(pathRouter, "/")
            
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
                if not success then
                    continue
                end
                
                local success, results = pcall(handleRouter, router, request, pathRouter, pathRequest, depth)
                if not success then
                    continue
                end

                wrapped = results
                break
            end
        end 
    end
    
    -- try `/` as a last resort
    if not wrapped.response then
        local lastResort = self._routes["/"]
        if lastResort then
            local success, results = pcall(handleRouter, lastResort, request, "/", pathRequest, depth)
            -- checking `status < 400` might be troublesome
            if success and results.found then
                wrapped = results
            end
        end
    end

    -- if no response then this is a dead path
    local response = wrapped.response
    local found = response ~= nil
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
            found = found
        }
    end 
end

return Lunit