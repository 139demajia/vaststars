local type = require "register.type"

type "item"
    .station_limit "integer"
    .backpack_limit "integer"
    .chest_limit "integer"
    .pile "volume"
    .item_model "path"
    .item_icon "path"