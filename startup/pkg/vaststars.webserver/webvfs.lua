local fs = require "filesystem"


local M = {}

local html_header = [[
<html>
<head><meta charset="utf-8"></head>
<body>
<ul>
]]
local html_footer = [[
</ul>
</body>
]]

local plaintext = "text/plain;charset=utf-8"

local content_text_types = {
    [".settings"] = plaintext,
    -- ecs
    [".prefab"] = plaintext,
    [".ecs"] = plaintext,
    -- script
    [".lua"] = plaintext,
    -- ui
    [".rcss"] = plaintext,
    [".rml"] = plaintext,
    -- animation
    [".event"] = plaintext,
    [".anim"] = plaintext,
    -- compiled resource
    [".cfg"] = plaintext,
    [".attr"] = plaintext,
    [".state"] = plaintext,
	-- for html
	[".html"] = "text/html",
	[".js"] = "text/html",
	[".gif"] = "image/gif",
	[".jpg"] = "image/jpeg",
	[".png"] = "image/png",
}

local function get_file(path)
	local ext = path:extension():string():lower()
	local localpath = path:localpath():string()
	local header = {
		["Content-Type"] = content_text_types[ext] or "application/octet-stream"
	}
	-- todo: use func for large file
	local f = assert(io.open(localpath, "rb"))
	local function reader()
		local bytes = f:read(4096)
		if bytes then
			return bytes
		else
			f:close()
		end
	end
	return reader, header
end

local function get_dir(path)
	local filelist = {}
	for file, file_status in fs.pairs(path) do
		local t = file_status:is_directory() and "d" or "f"
		table.insert(filelist, t .. file:filename():string())
	end
	table.sort(filelist)
	local list = { html_header }
	local pathname = path:string()
	if pathname ~= '/' then
		pathname = pathname .. "/"
	end
	for _, filename in ipairs(filelist) do
		local t , filename = filename:sub(1,1), filename:sub(2)
		local slash = t == "d" and "/" or ""
		table.insert(list, ('<li><a href="/vfs%s%s">%s%s</a></li>'):format(pathname, filename, filename, slash))
	end
	table.insert(list, html_footer)
	return table.concat(list, "\n")
end

local function get_path(path)
	if not fs.exists(path) then
		return
	end
	if fs.is_directory(path) then
		return get_dir(path)
	else
		return get_file(path)
	end
end

function M.get(path)
	if path == "" then
		path = "/"
	end
	local pathname = fs.path(path)
	local data, header = get_path(pathname)
	if data then
		return 200, data, header
	else
		return 403, "ERROR 403 : " ..  path .. " not found"
	end
end

return M