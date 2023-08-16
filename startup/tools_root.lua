dofile "/engine/bootstrap.lua"

local fs = require "bee.filesystem"
local cr = import_package "ant.compile_resource".fileserver()
local datalist  = require "datalist"

local function init_setting()
	local function sortpairs(t)
		local sort = {}
		for k in pairs(t) do
			sort[#sort+1] = k
		end
		table.sort(sort)
		local n = 1
		return function ()
			local k = sort[n]
			if k == nil then
				return
			end
			n = n + 1
			return k, t[k]
		end
	end
	local function stringify(t)
		local s = {}
		for k, v in sortpairs(t) do
			s[#s+1] = k.."="..tostring(v)
		end
		return table.concat(s, "&")
	end
	local OS <const> = "windows"
	local Renderer <const> = "direct3d11"
	local HomogeneousDepth <const> = true
	local OriginBottomLeft <const> = true
	local TextureExtensions <const> = {
		noop        = OS == "windows" and "dds" or "ktx",
		direct3d11 	= "dds",
		direct3d12  = "dds",
		metal       = "ktx",
		vulkan      = "ktx",
		opengl      = "ktx",
	}
	local BgfxOS <const> = {
		macos = "osx",
	}
	cr.init_setting()
	cr.set_setting("glb", stringify {
		os = OS,
		renderer = Renderer,
		hd = HomogeneousDepth,
		bl = OriginBottomLeft,
	})
	cr.set_setting("material", stringify {
		os = OS,
		renderer = Renderer,
		hd = HomogeneousDepth,
		obl = OriginBottomLeft,
	})
	cr.set_setting("texture", stringify {
		os = OS,
		ext = TextureExtensions[Renderer],
	})
end
init_setting()

local basedir = (fs.current_path() / "../../"):lexically_normal()
local path = basedir .. "startup/pkg/vaststars.resources/glb/stackeditems/"

local function dir(p)
	local t = {}
	for v in fs.pairs(p) do
		if fs.is_directory(v) then
			local tmp = dir(v)
			table.move(tmp, 1, #tmp, #t + 1, t)
		else
			t[#t+1] = v
		end
	end
	return t
end

local function readall(resource, relative)
	local f <close> = assert(io.open(cr.compile_file(resource:string()) .. relative, "rb"))
    return f:read "a"
end

local function get_material(prefab)
	for _, v in pairs(prefab) do
		if v.data and v.data.material then
			local t = v.data.material
			if #t > 1 then
				return t[2]
			else
				return t[1]
			end
		end
	end
end

for _, f in ipairs(dir(path)) do
	local prefab = datalist.parse(readall(f, "/mesh.prefab"))
	-- local material = datalist.parse(readall(f, get_material(prefab) .. "/main.cfg"))
end

print "ok"