local Lunition = require("../Lunition")
local Lunit = Lunition.Lunit

local lCatBash = Lunit.new()

lCatBash:route("/", "html/soon.html")

return lCatBash