package.path = "engine/?.lua"
require "bootstrap"
import_package "ant.window".start {
    import = {
        "@vaststars.mod.test",
    },
    pipeline = {
        "init",
        "update",
        "exit",
    },
    feature = {
        "ant.animation",
        "ant.camera|camera_controller",
        "ant.efk",
        "ant.landform",
        "ant.objcontroller|pickup",
        "mod.printer",
    },
    system = {
        "vaststars.mod.test|init_system",
    },
    policy = {
        "ant.render|render",
        "ant.render|render_queue",
    }
}
