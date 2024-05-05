-- https://www.iana.org/assignments/websocket/websocket.xhtml
-- This website sucks but apparently it is Official™️
-- 4000 to 4999 is "Reserved for Private Use"
-- Any code from 1000 to 3999 not listed here is "Unassigned"

return {
	[1000] = "Normal Closure",
	[1001] = "Going Away",
	[1002] = "Protocol error",
	[1003] = "Unsupported Data",
	[1004] = "Reserved",
	[1005] = "No Status Rcvd",
	[1006] = "Abnormal Closure",
	[1007] = "Invalid frame payload data",
	[1008] = "Policy Violation",
	[1009] = "Message Too Big",
	[1010] = "Mandatory Ext.",
	[1011] = "Internal Error",
	[1012] = "Service Restart",
	[1013] = "Try Again Later",
	[1014] = "The server was acting as a gateway or proxy and received an invalid response from the upstream server. This is similar to 502 HTTP Status Code.", -- best?
	[1015] = "TLS handshake",

	[3000] = "Unauthorized",
	[3003] = "Forbidden",
	[3008] = "Timeout" -- SCP-3008 reference?
}