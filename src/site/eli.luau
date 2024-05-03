--!strict

local Lunition = require("../Lunition")
local Lunit = Lunition.Lunit

local lEli = Lunit.new()

lEli:route("", "html/eli/index.html")

lEli:route("progress", "html/eli/progress.html")

return lEli