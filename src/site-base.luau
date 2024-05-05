local Lunition = require("Lunition")
local Lunit = Lunition.Lunit

local lBase = Lunit.new()

lBase:route("/", "html/index.html")

lBase:route("/credits", "html/credits.html")

return lBase