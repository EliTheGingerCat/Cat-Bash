local success, message = pcall(function()
	require("lunition")
	require("website")
end)

if success then
	print("All tests successful! 😸")
else
	print(`Error! 😿\n{message}`)
end