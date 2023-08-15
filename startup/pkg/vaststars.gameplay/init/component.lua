local def = ...

local type = def.type
local component = def.component
local tag = function (what)
    component(what) {}
end
local mainkey = component

type "roadnet::straightid" ("uint16")
type "enum roadnet::lorry_status" ("uint8")

mainkey "building" {
    "uint16 prototype",
    "uint8 x",
    "uint8 y",
    "uint8 direction",	-- 0:North 1:East 2:South 3:West
}

mainkey "backpack" {
    "uint16 prototype",
    "uint16 amount",
}

component "chest" {
    "uint16 chest",
}

component "station_producer" {
    "uint8 weights",
}

component "station_consumer" {
    "uint8 maxlorry",
}

tag "lorry_factory"

component "starting" {
    "roadnet::straightid neighbor",
}

component "endpoint" {
    "roadnet::straightid neighbor",
    "roadnet::straightid rev_neighbor",
    "uint8 lorry",
}

mainkey "lorry" {
    "uint16 prototype",
    "roadnet::straightid ending",
    "uint16 item_prototype",
    "uint16 item_amount",
    "uint8 progress",
    "uint8 maxprogress",
    "uint8 time",
    "enum roadnet::lorry_status status",
    "uint8 x",
    "uint8 y",
    "uint8 z",
    "uint8 prev_x",
    "uint8 prev_y",
    "uint8 prev_z",
}

tag "lorry_changed"
tag "lorry_free"
tag "lorry_removed"
tag "lorry_willremove"

component "hub" {
    "uint16 id",
    "uint16 chest",
}

--
-- prev/next/mov2
-- | unused(5bit) | type(2bit) | chest(4bit) | unused(3bit) | y(8bit) | x(8bit) |
-- 32            27           25            21             16         8         0
--
mainkey "drone" {
    "uint16 prototype",
    "uint16 item",
    "uint32 home",
    "uint32 prev",
    "uint32 next",
    "uint32 mov2",
    "uint16 maxprogress",
    "uint16 progress",
    "uint8 status",
}
tag "drone_changed"

component "assembling" {
    "int32 progress",
    "uint16 recipe",
    "uint16 speed",
    "uint16 fluidbox_in",
    "uint16 fluidbox_out",
    "uint8 status",
}

component "laboratory" {
    "int32 progress",
    "uint16 tech",
    "uint16 speed",
    "uint8 status",
}

component "capacitance" {
    "uint32 shortage",
    "int32 delta",
    "uint8 network"
}

component "chimney" {
    "int32 progress",
    "uint16 recipe",
    "uint16 speed",
    "uint8 status",
}

tag "consumer"
tag "generator"
tag "accumulator"

component "fluidbox" {
    "uint16 fluid",
    "uint16 id",
}

component "fluidboxes" {
    "fluidbox in[4]",
    "fluidbox out[3]",
}

tag "pump"
tag "mining"
tag "road"

component "save_fluidflow" {
	"uint16 fluid",
	"uint16 id",
	"uint32 volume"
}

component "solar_panel" {
    "uint8 efficiency"
}

tag "wind_turbine"
tag "base"
tag "fluidbox_changed"

--
tag "base_changed"
tag "station_changed"
tag "building_new"
tag "building_changed"
tag "auto_set_recipe"
tag "power_check"
