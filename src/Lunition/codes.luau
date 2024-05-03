-- https://en.wikipedia.org/wiki/List_of_HTTP_status_codes
-- https://http.cat/
-- Contains all codes from both websites
-- Wikipedia messages were written first
-- Any HTTP Cats deviations are noted
-- All unofficial and deprecated codes were not described on Wikipedia

return {
	[100] = "Continue",
	[101] = "Switching Protocols",
	[102] = "Processing",
	[103] = "Early Hints",

	[200] = "OK",
	[201] = "Created",
	[202] = "Accepted",
	[203] = "Non-Authoritative Information",
	[204] = "No Content",
	[205] = "Reset Content",
	[206] = "Partial Content",
	[207] = "Multi-Status",
	[208] = "Already Reported",
	[214] = "Transformation Applied", -- deprecated
	[226] = "IM Used",

	[300] = "Multiple Choices",
	[301] = "Moved Permanently",
	[302] = "Found",
	[303] = "See Other",
	[304] = "Not Modified",
	[305] = "Use Proxy",
	[306] = "Switch Proxy", -- HTTP Cats does not have
	[307] = "Temporary Redirect",
	[308] = "Permanent Redirect",

	[400] = "Bad Request",
	[401] = "Unauthorized",
	[402] = "Payment Required",
	[403] = "Forbidden",
	[404] = "Not Found",
	[405] = "Method Not Allowed",
	[406] = "Not Acceptable",
	[407] = "Proxy Authentication Required",
	[408] = "Request Timeout",
	[409] = "Conflict",
	[410] = "Gone",
	[411] = "Length Required",
	[412] = "Precondition Failed",
	[413] = "Payload Too Large",
	[414] = "URI Too Long", -- HTTP Cats says "Request-URI..."
	[415] = "Unsupported Media Type",
	[416] = "Range Not Satisfiable", -- HTTP Cats says "Request Range..."
	[417] = "Expectation Failed",
	[418] = "I'm a teapot", -- best
	[420] = "Enhance Your Calm", -- unofficial, Twitter
	[421] = "Misdirected Request",
	[422] = "Unprocessable Content", -- HTTP Cats says Unprocessable Entity
	[423] = "Locked",
	[424] = "Failed Dependency",
	[425] = "Too Early",
	[426] = "Upgrade Required",
	[428] = "Precondition Required",
	[429] = "Too Many Requests",
	[431] = "Request Header Fields Too Large",
	[444] = "No Response", -- unofficial, Nginx
	[450] = "Blocked by Windows Parental Controls", -- unofficial, Microsoft
	[451] = "Unavailable For Legal Reasons",
	[497] = "HTTP Request Sent to HTTPS Port", -- unofficial, Nginx
	[498] = "Token expired/invalid", -- unofficial, ArcGIS
	[499] = "Client Closed Request", -- unofficial, Nginx; ArcGIS has "Token Required"

	[500] = "Internal Server Error",
	[501] = "Not Implemented",
	[502] = "Bad Gateway",
	[503] = "Service Unavailable",
	[504] = "Gateway Timeout",
	[505] = "HTTP Version Not Supported", -- HTTP Cats does not have
	[506] = "Variant Also Negotiates",
	[507] = "Insufficient Storage",
	[508] = "Loop Detected",
	[509] = "Bandwidth Limit Exceeded", -- unofficial, Apache and cPanel
	[510] = "Not Extended",
	[511] = "Network Authentication Required",
	[521] = "Web Server Is Down", -- unofficial, Cloudflare
	[522] = "Connection Timed Out", -- unofficial, Cloudflare
	[523] = "Origin Is Unreachable", -- unofficial, Cloudflare
	[525] = "SSL Handshake Failed", -- unofficial, Cloudflare
	[530] = "Site Frozen", -- unofficial, Cloudflare and Pantheon
	[599] = "Network Connect Timeout Error" -- unofficial
}