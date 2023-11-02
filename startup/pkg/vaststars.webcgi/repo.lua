local lfs = require "bee.filesystem"
local directory = require "directory"
local REPO_PATH = directory.app_path():string() .. "/.repo/"

local M = {}

local hash_index = [[
<html>
<head>
  <meta charset="UTF-8">
  <title>Repository</title>
</head>
<body>
<pre>
{ROOT}
</pre>
<p>{TOTAL} files</p>
</body>
]]

local function count_files(path)
	local n = 0
	for path in lfs.pairs(path) do
		if not path:string():find "%.resource$" then
			n = n + 1
		end
	end
	return n
end

local function invalid_path(path)
	path = path:lower()
	if path:find "[^%da-f]" then
		return true
	end
end

local plaintext = {	["Content-Type"] = "text/plain;charset=utf-8" }
local htmltext = { ["Content-Type"] = "text/html" }
local blob = { ["Content-Type"] = "application/octet-stream" }

local content_temp_header = [[
<html>
<head><meta charset="utf-8"></head>
<body>
<pre>
]]

local content_temp_footer = [[

</pre>
</body>
]]

local SHA1 = ("[0-9a-f]"):rep(40)

local function link_sha1(s)
	return ('<a href="/repo/%s">%s</a>'):format(s,s)
end

local function add_links(content)
	local n = content:find(SHA1)
	if n then
		return content_temp_header .. content:gsub(SHA1, link_sha1) .. content_temp_footer, htmltext
	else
		return content, plaintext
	end
end

local function list_prefix(files)
	return add_links(table.concat(files, "\n"))
end

local function view_file(fullpath)
	local f = assert(io.open(fullpath, "rb"))
	local c = f:read "a"
	f:close()
	if c:find "\0" then
		-- binary files
		return c, blob
	elseif c:find "[<>]" then
		return c, plaintext
	else
		return add_links(c)
	end
end

local function get_hash_prefix(prefix)
	local path = REPO_PATH
	local files = {}
	local n = #prefix
	for file in lfs.pairs(path) do
		local name = file:filename():string()
		if name:sub(1,n) == prefix then
			if not name:find "%.resource$" then
				table.insert(files, name)
			end
		end
	end
	local count = #files
	if count == 0 then
		return 404, "Not found : " .. prefix
	elseif count == 1 then
		local fullname = files[1]
		if fullname ~= prefix then
			return 302, "Found", { Location = "/repo/" .. fullname }
		else
			return 200, view_file(path .. "/" .. fullname)
		end
	else
		return 200, list_prefix(files)
	end
end

local function link_sha1_resource(s)
	return ('<a href="/repo/%s">%s</a> (<a href="/repo/resource/%s">RESOURCE</a>)'):format(s,s,s)
end

local function roots()
	local f = io.open(REPO_PATH .. "root", "rb")
	if not f then
		return "No ROOT"
	end
	local content = f:read "a"
	f:close()
	return content
end

local function get_root()
	local f = io.open(REPO_PATH .. "root", "rb")
	if not f then
		return "No ROOT"
	end
	local content = roots()
	return content:gsub(SHA1, link_sha1_resource)
end

local function get_hash_index()
	local total = 0
	local count = {}
	local n = count_files(REPO_PATH)
	count.TOTAL = n
	count.ROOT = get_root()
	return (hash_index:gsub ("{(.-)}", count))
end

local function get_resource(hash)
	local path = REPO_PATH .. "/" .. hash .. ".resource"
	local f = io.open(path, "rb")
	if not f then
		return
	end
	local content = f:read "a"
	f:close()
	return content
end

local function get_dir_resource(root)
	local c = get_resource(root)
	if c then
		local map = {}
		for hash, path in c:gmatch "(%w+) (%S+)" do
			map[path] = hash
		end
		return map
	else
		return {}
	end
end

local function open_hash_file(hash)
	local fullpath = REPO_PATH .. "/" .. hash
	return io.open(fullpath, "rb")
end

local function insert_file(item, name, path)
	local f = open_hash_file(path)
	if f then
		f:close()
	end
	local r = { name, f ~= nil, path }
	table.insert(item, r )
	return r
end

local function get_dir_file(hash, resource)
	local f = open_hash_file(hash)
	if not f then
		return
	end
	local content = f:read "a"
	f:close()
	local item = {}
	for t, name, path in content:gmatch "(%a) (%S+) (%S+)" do
		if t == "f" then
			insert_file(item, name, path)
		elseif t == "r" then
			local h = resource[path]
			if h then
				local r = insert_file(item, name, h)
				r.resource = true
			else
				-- unknown
				table.insert(item, { name } )
			end
		elseif t == "d" then
			local r = insert_file(item, name, path)
			if r[2] then
				r.dir = get_dir_file(path, resource)
			else
				r.dir = false
			end
		else
			error ("Invalid dir file " .. hash)
		end
	end
	return item
end

local function expand_tree(r, root, tree, resource, ident)
	for _, item in ipairs(tree) do
		local name = item[1]
		local exist = item[2]
		local hash = item[3]
		if exist then
			if item.dir then
				table.insert(r, ('%s<span style="color:blue">%s</span> <a href="/repo/tree/%s">%s</a>'):format(ident, name, hash, hash))
				expand_tree(r, root, item.dir, resource, ident .. "  ")
			elseif item.resource then
				table.insert(r, ('%s<span style="color:green">%s</span> <a href="/repo/tree/%s">%s</a>'):format(ident, name, hash, hash))
			else
				table.insert(r, ('%s%s <a href="/repo/%s">%s</a>'):format(ident, name, hash, hash))
			end
		elseif exist == nil then
			table.insert(r, ident .. name .. " UNKNOWN")
		else
			if item.dir == false then
				table.insert(r, ('%s<span style="color:red">%s</span> %s'):format(ident, name, hash))
			elseif item.resource then
				table.insert(r, ('%s<span style="color:green">%s</span> %s'):format(ident, name, hash))
			else
				table.insert(r, ident .. name .. " " .. hash)
			end
		end
	end
end


local content_temp_header_title = [[
<html>
<head><meta charset="utf-8"></head>
<title>%s</title>
<body>
<pre>
]]

local function get_tree_from(root, subroot)
	local resource = get_dir_resource(root)
	local tree = get_dir_file(subroot, resource)
	if not tree then
		return 403, "No hash : " .. subroot
	end
	local r = { content_temp_header_title:format(subroot) }
	expand_tree(r, root, tree, resource, "")
	table.insert(r, content_temp_footer)
	return 200, table.concat(r, "\n"),  htmltext
end

local function get_tree(subroot)
	local r = roots()
	local hash = r:match(SHA1)
	return get_tree_from(hash, subroot or hash)
end

function M.get(path)
	if path == "" then
		return 200, get_hash_index()
	else
		local t, subpath = path:match "^(%a+)/(.*)"
		if t == nil then
			if path == "tree" then
				return get_tree()
			elseif invalid_path(path) then
				return 404, "Invalid " ..  tostring(path)
			else
				return get_hash_prefix(path)
			end
		elseif t == "resource" then
			local r = get_resource(subpath)
			if r then
				return 200, add_links(r)
			else
				return 404, "Not Found RESOURCE " .. subpath
			end
		elseif t == "tree" then
			return get_tree(subpath)
		end
	end
end

return M
