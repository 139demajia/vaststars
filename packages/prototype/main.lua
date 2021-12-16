local gameplay = import_package "vaststars.gameplay"
local prototype = gameplay.prototype

prototype "chest" {
    type = {"entity", "chest"},
    area = "1x1",
    slots = 20,
    stack = 10,
}
prototype "inserter" {
    type = {"entity", "inserter", "consumer"},
    area = "1x1",
    speed = "1s",
    stack = 50,
    power = "13kW",
    priority = "primary",
}
prototype "assembling" {
    type = {"entity", "assembling", "consumer"},
    area = "3x3",
    speed = "100%",
    power = "75kW",
    priority = "primary",
}

prototype "iron plate" {
    type = {"item"},
    stack = 100,
}
prototype "copper plate" {
    type = {"item"},
    stack = 100,
}
prototype "copper cable" {
    type = {"item"},
    stack = 100,
}
prototype "electronic circuit" {
    type = {"item"},
    stack = 100,
}

prototype "copper cable" {
    type = { "recipe" },
    ingredients = {
        {"copper plate", 1}
    },
    results = {
        {"copper cable", 2}
    },
    time = "0.5s"
}

prototype "electronic circuit" {
    type = { "recipe" },
    ingredients = {
        {"copper cable", 3},
        {"iron plate", 1}
    },
    results = {
        {"electronic circuit", 1}
    },
    time = "0.5s"
}

prototype "uranium fuel cell" {
	type = { "item" },
	stack = 50,
}

prototype "used up uranium fuel cell" {
	type = { "item" },
	stack = 50,
}

prototype "uranium combustion" {
    type = { "recipe" },
    ingredients = {
        {"uranium fuel cell", 1},
    },
    results = {
        {"used up uranium fuel cell", 1}
    },
    time = "200s"
}

prototype "nuclear reactor" {
    type = {"entity", "generator", "burner"},
    area = "3x3",
    power = "40MW",
    priority = "primary",
}
