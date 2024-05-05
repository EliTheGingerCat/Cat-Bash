local Lunition = require("../Lunition")
local Lunit = Lunition.Lunit

local lBridgeDuel = Lunit.new()

lBridgeDuel:route("/", "html/soon.html")

return lBridgeDuel