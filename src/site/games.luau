--!strict

local Lunition = require("../Lunition")
local Lunit = Lunition.Lunit

local lGames = Lunit.new()

lGames:route("/", "html/soon.html")

return lGames