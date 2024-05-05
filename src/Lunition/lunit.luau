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
export type handler = (request: net.ServeRequest) -> (net.ServeResponse)
export type router = string | handler | Lunit
export type errorLuauHandler = (message: string) -> (net.ServeResponse)
export type errorHttpHandler = (code: number, name: string, description: string) -> (net.ServeResponse)
export type responseWrapped = {
    response: net.ServeResponse,
    errorHandled: boolean?,
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

    -- it better be a file now
    local metadata = fs.metadata(pathStatic)
    if metadata.kind ~= "file" then
        return {
            status = 400,
            body = `Expected file, got {metadata.kind}.`
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

local runLunit -- routeLunit and runLunit depend on each other
local function routeLunit(lunit: Lunit, request: net.ServeRequest, pathPiecesUrl: {string}): (responseWrapped)
    local success, results = pcall(runLunit, lunit, request, pathPiecesUrl)
    if success then
        return results
    else
        -- Luau error
        if lunit.errorHandlerLuau then
            return {
                response = lunit.errorHandlerLuau(results :: any), -- TC is Wrong!
                errorHandled = true
            }
        else
            -- bubble up the error
            error(results)
        end
    end
end

local function handleRouter(router: router, request: net.ServeRequest, pathRouter: string, pathPiecesUrl: {string}): (responseWrapped)
    if type(router) == "string" then
        -- file or directory
        return {
            response = routeStatic(router, request.path)
        }
    elseif type(router) == "function" then
        -- handler
        return {
            response = router(request)
        }
    elseif type(router) == "table" then
        -- lunit
        return routeLunit(router, request, pathPiecesUrl)
    else
        error("Invalid router!")
    end
end

runLunit = function(self: Lunit, request: net.ServeRequest, pathPiecesUrl: {string}): (responseWrapped)
    local wrapped = {} :: responseWrapped

    if request.path ~= "/" then
        for pathRouter, router in self._routes do
            if pathRouter == "/" then
                continue
            end
            local pathPiecesRoute = string.split(pathRouter, "/")
            if pathPiecesRoute[1] == "" then
                -- started with a slash
                table.remove(pathPiecesRoute, 1)
            end
            if pathPiecesUrl[1] == pathPiecesRoute[1] then
                -- see how far it goes
                local depth = 1
                while depth < #pathPiecesUrl and pathPiecesUrl[depth + 1] == pathPiecesRoute[depth + 1] do
                    depth += 1
                end

                local success = true
                if type(router) == "function" or type(router) == "string" and fs.isFile(router) then
                    -- url needs to be exact for handlers and files
                    success = depth == #pathPiecesUrl or #pathPiecesUrl - depth == 1 and pathPiecesUrl[#pathPiecesUrl] == ""
                end
                if not success then
                    continue
                end
                
                -- clean up the URL's path pieces
                for _ = 1, depth do
                    table.remove(pathPiecesUrl, 1)
                end
                wrapped = handleRouter(router, request, pathRouter, pathPiecesUrl)
                break
            end
        end
    end
    
    if not wrapped.response then
        -- try `/` as a last resort
        local lastResort = self._routes["/"]
        local isExists = lastResort ~= nil
        local isHandler = type(lastResort) == "function"
        local isFile = type(lastResort) == "string" and fs.isFile(lastResort)
        local isEnd = #pathPiecesUrl == 0 or #pathPiecesUrl == 1 and pathPiecesUrl[1] == ""
        local isExactEnough = not isHandler and not isFile or isEnd
        if isExists and isExactEnough then
            wrapped = handleRouter(lastResort, request, "/", pathPiecesUrl)
        end
    end

    -- if no response then this is a dead path
    local response = wrapped.response
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
            response = response
        }
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

function Lunit.run(self: Lunit, request: net.ServeRequest): (responseWrapped)
    local pathPiecesUrl = string.split(request.path, "/")
    table.remove(pathPiecesUrl, 1) -- always starts with a slash
    return runLunit(self, request, pathPiecesUrl)
end

return Lunit