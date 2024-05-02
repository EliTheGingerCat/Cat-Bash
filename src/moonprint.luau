--!strict
--!nolint LocalShadow

local fs = require("@lune/fs")
local net = require("@lune/net")

local Render = require("render")

local Moonprint = {
    className = "Moonprint"
}
Moonprint.__index = Moonprint

export type Moonprint = typeof(setmetatable({} :: {
    _routes: {
        [string]: router
    },
    errorHandler: errorHandler?
}, Moonprint))
export type router = string | ((request: net.ServeRequest) -> (net.ServeResponse)) | Moonprint
export type errorHandler = (code: number, name: string, description: string) -> (net.ServeResponse)

function Moonprint.new(): (Moonprint)
    return setmetatable({
        _routes = {}
    }, Moonprint)
end

Moonprint.defaultErrorHandler = (function(code, name, description)
    return {
        status = code,
        body = Render("html/error.html", {
            code = tostring(code),
            message = name,
            description = description
        })
    }
end) :: errorHandler



function Moonprint.route(self: Moonprint, urlPath: string, router: router): ()
    self._routes[urlPath] = router
end

function Moonprint.run(self: Moonprint, request: net.ServeRequest, depth: number?): (net.ServeResponse)
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
                    if fs.isDir(router) then
                        -- url path should lead to a file
                        router ..= string.sub(request.path, assert(string.find(request.path, urlPath)) + #urlPath)
                    end

                    -- now it better not be a directory
                    if fs.isDir(router) then
                        return {
                            status = 400,
                            body = "Please specify a file."
                        }
                    end

                    -- reading files can always go wrong
                    local success, results = pcall(fs.readFile, router)
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
                    if string.find(router, ".html$") then
                        results = Render(router)
                    end

                    -- success!
                    return {
                        body = results
                    }
                elseif type(router) == "function" then
                    return router(request)
                else
                    -- moonprint
                    return router:run(request, depth + 1)
                end
            end
        end
    end

    return {
        status = 404,
        body = "Unknown path."
    }
end

return Moonprint