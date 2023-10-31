local guide = require "guide"
local mountain = require "mountain"

local entities = {}
local road = {}

local mineral = {
  ["115,129"] = "碎石",
  ["120,129"] = "铁矿石",
  ["125,129"] = "地热气",
  ["130,129"] = "铝矿石",
  ["135,129"] = "砂岩",
}

return {
  name = "矿区测试",
  entities = entities,
  road = road,
  mineral = mineral,
  mountain = mountain,
  order = 2,
  guide = guide,
  mode = "free",
  start_tech = "迫降火星",
}