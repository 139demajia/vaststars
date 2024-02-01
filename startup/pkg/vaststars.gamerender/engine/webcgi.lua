local ecs = ...
local world = ecs.world
local w = world.w

local ltask = require "ltask"

-- todo: more info
local function register_command()
	local S = ltask.dispatch()

    local COMMAND = {}
    COMMAND.ping = function(q)
        return {COMMAND = q}
    end

	function S.world_command(what, ...)
        world:pub {"web_cgi_cmd", what, ...}
        return "SUCCESS"
    end

    function S.command(what, ...)
        local c = assert(COMMAND[what])
		return c(what, ...)
	end
end

return function ()
	local webserver = import_package "vaststars.webcgi"
	register_command()

	if __ANT_RUNTIME__ then
		webserver.start "redirect"
	else
		webserver.start "direct"
	end
end