local fs = require "filesystem"
local archiving = import_package "vaststars.gamerender" "archiving"

return function (window)
    local templates = {}
    for _, v in ipairs(archiving.list()) do
        templates[#templates+1] = {
            name = fs.path(v):filename():string(),
            filename = v,
        }
    end
    local model = window.createModel {
        templates = templates,
    }
    function model.open(filename)
        window.callMessage("reboot", "restore", filename)
        window.close()
    end
    function model.clickClose()
        window.close()
    end
end
