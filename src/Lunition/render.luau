--!strict
--!nolint LocalShadow

local fs = require("@lune/fs")

export type block = {
    name: string,
    start: number,
    stop: number
}
export type blockData = {[string]: string}
export type blockStack = {block}

local function stringInject(s: string, start: number, stop: number, replacement: string)
    return string.sub(s, 1, start - 1) .. replacement .. string.sub(s, stop + 1)
end

local function render(path: string, arguments: {[string]: string}?, data: blockData?): (string)
    local arguments = arguments or {} :: {[string]: string}
    local data = data or {} :: blockData
    local content = fs.readFile(path)
    -- replace variables
    content = string.gsub(content, "{{%s*(%a+)%s*}}", function(variable)
        return arguments[variable] or error(`Variable {variable} not found in {arguments}.`)
    end)
    -- execute keywords
    local init = 1
    local blockStack: blockStack = {}
    local blockData: blockData = {}
    local template
    while true do
        local start, stop, keyword, value = string.find(content, "{%%%s*(%S+)%s+(%S*)%s*%%}", init)
        if not start then
            break
        end
        assert(stop, value)
        init = stop + 1
        if keyword == "block" then
            local replacement = data[value]
            if replacement then
                content = stringInject(content, start, stop, replacement)
            else
                assert(not blockData[value], `Block with name {value} was already used.`)
                blockData[value] = "" -- placeholder for TC
                table.insert(blockStack, {
                    name = value,
                    start = start,
                    stop = stop
                })
            end
        elseif keyword == "endblock" then
            local last = table.remove(blockStack, #blockStack)
            assert(last, `Too many endblock commands.`)
            local dataReplacement = data[last.name]
            if dataReplacement then
                content = string.sub(content, 1, last.start - 1) .. dataReplacement .. string.sub(content, stop + 1)
            else
                blockData[last.name] = string.sub(content, last.stop + 1, start - 1)
            end
        elseif keyword == "extends" then
            assert(not template, "Maximum one ancestor.")
            template = value
        elseif keyword == "include" then
            local newContent = render(value, arguments)
            content = string.sub(content, 1, start - 1) .. newContent .. string.sub(content, stop + 1)
        end
    end
    if template then
        return render(template, arguments, blockData)
    else
        return content
    end
end

return render