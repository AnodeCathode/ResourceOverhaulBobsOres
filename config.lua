require 'defines'
debug_enabled = false


region_size=8 -- alternative mean to control how further away resources would be, default - 256 tiles or 8 chunks
              -- each region is region_size*region_size chunks
              -- each chunk is 32*32 tiles

override_normal_spawn = true   -- if false then the standard spawner can also spawn full grown resources/entities, 
                               -- set resources you want to control through this config to "None" in worldgen "Size" settings when starting a new game
                               -- changing of this setting requires game restart, i.e. close game and start it again, not actally a new game
                               
override_type = 'partially'    -- 'full' - no spawns by game are allowed, 'partially' - very small patches are spawned by world gen
                               -- changing of this setting requires game restart

starting_area_size=1           -- starting area in regions, safe from random nonsense

absolute_resource_chance=0.30  -- chance to spawn an resource in a region
global_richness_mult = 1.0      -- multiply richness all resources

multi_resource_richness_factor=0.60 -- any additional resource is multiplied by this value times resources-1
multi_resource_size_factor=0.60
multi_resource_chance_diminish=0.8    -- diminishing effect factor on multi_resource_chance

min_amount=350 -- default value for minimum amount of resource in single pile

richness_distance_factor=1.030 -- 3.0 relative % per region distance ~ 2.1x mult @ 25 regions distance

deterministic = true           -- set to false to use system for all decisions  math.random

config={
  ["iron-ore"] = {
    type="resource-ore",

    -- general spawn params
    allotment=120, -- how common resource is
    spawns_per_region={min=1, max=2}, --number of chunks
    richness=7000,
    
    size={min=20, max=40}, -- rough radius of area, too high value can produce square shaped areas
    
    -- resource provided at starting location
    starting={richness=2000, size=17},
    
    multi_resource_chance=0.13, -- absolute value
    multi_resource={
      ["iron-ore"] = 2, -- ["resource_name"] = allotment
      ['copper-ore'] = 4, 
      ["coal"] = 8,
      ["stone"] = 8,
      ["crude-oil"] = 1,
    }
  },
  ["copper-ore"] = {
    type="resource-ore",

    allotment=120,
    spawns_per_region={min=1, max=2},
    richness=11000,
    size={min=15, max=30},

    starting={richness=1800, size=10},
    
    multi_resource_chance=0.13,
    multi_resource={
      ["iron-ore"] = 4,
      ['copper-ore'] = 2, 
      ["coal"] = 8,
      ["stone"] = 8,
      ["crude-oil"] = 1, 
    }
  },
  ["coal"] = {
    type="resource-ore",

    allotment=100,

    spawns_per_region={min=1, max=3},
    size={min=15, max=25},
    richness=14000,

    starting={richness=2500, size=12},
    
    multi_resource_chance=0.13,
    multi_resource={
      ["iron-ore"] = 2,
      ['copper-ore'] = 2, 
      ["coal"] = 8,
      ["stone"] = 8,
      ["crude-oil"] = 1, 
    }
  },
  ["stone"] = {
    type="resource-ore",

    allotment=80,
    spawns_per_region={min=1, max=2},
    richness=9000,
    size={min=15, max=25},

    starting={richness=1000, size=8},
    
    multi_resource_chance=0.13,
    multi_resource={
      ["iron-ore"] = 2,
      ['copper-ore'] = 2, 
      ["coal"] = 8,
      ["stone"] = 8,
      ["crude-oil"] = 3, 
    }
  },
  
  ["crude-oil"] = {
    type="resource-liquid",
    minimum_amount=750, 
    
    allotment=65,
    spawns_per_region={min=1, max=2},
    richness={min=20000, max=60000}, -- total richness of site 
    size={min=2, max=4}, -- richness devided by this number
    
    starting={richness=4000, size=1}
  },
  
  ["biter-spawner"] = {
    type="entity",
    force="enemy",
    clear_range = {3, 3},
    
    spawns_per_region={min=2,max=5},
    size={min=2,max=6},
    size_per_region_factor=1.05,
    richness=1,
    
    absolute_probability=0.15, -- chance to spawn in region
    probability_distance_factor=1.05, -- relative incress per region
    max_probability_distance_factor=3.0, -- absolute value

    along_resource_probability=0.40, -- chance to spawn in resource chunk anyway, absolute value. Can happen once per resource.
    
    sub_spawn_probability=0.5,     -- chance for this entity to spawn anything from sub_spawns table, absolute value
    sub_spawn_size={min=1, max=2}, -- in same chunk
    sub_spawn_distance_factor=1.02,
    sub_spawn_max_distance_factor=2,
    sub_spawns={
      ["small-worm-turret"]={
        min_distance=2,
        allotment=2000,
        allotment_distance_factor=0.9,
      },
      ["medium-worm-turret"]={
        min_distance=5,
        allotment=1000,
        allotment_distance_factor=1.05,
      },
      ["big-worm-turret"]={
        min_distance=7,
        allotment=1000,
        allotment_distance_factor=1.15,
      }
    }
  }
}

--[[ MODS SUPPORT ]]--

-- Roadworks mod
if remote and game then
if game.entityprototypes["RW-limestone"] then
  config["RW-limestone"] = {
    type="resource-ore",

    allotment=85,
    spawns_per_region={min=1, max=2},
    richness=11000,
    size={min=10, max=17},

    starting={richness=1000, size=4},
    
    multi_resource_chance=0.15,
    multi_resource={
      ["coal"] = 2,
      ["stone"] = 8,
      ["crude-oil"] = 1, 
    }
  }
  
  config["stone"].multi_resource["RW-limestone"] = 12
  config["iron-ore"].multi_resource["RW-limestone"] = 3
  config["copper-ore"].multi_resource["RW-limestone"] = 3
  config["coal"].multi_resource["RW-limestone"] = 3
end

-- DyTech

if remote.interfaces["DyTech-Core"] then
  config["stone"].allotment = 100
  config["stone"].richness = 25000
  config["stone"].starting.richness = 10000
end

if remote.interfaces["DyTech-Metallurgy"] then
-- exotic ores
  config["gold-ore"] = {
    type="resource-ore",

    allotment=25,
    spawns_per_region={min=2, max=5},
    richness=175,
    size={min=2, max=5},
    min_amount = 15,

    starting={richness=50, size=3},
    
    multi_resource_chance=0.60,
    multi_resource={
      ["lead-ore"] = 3,
      ["silver-ore"] = 3,
      ["tin-ore"] = 3,
      ["tungsten-ore"] = 3,
      ["zinc-ore"] = 3,
    }
  } 
  config["silver-ore"] = {
    type="resource-ore",

    allotment=25,
    spawns_per_region={min=2, max=5},
    richness=220,
    size={min=2, max=5},
    min_amount = 15,

    starting={richness=50, size=3},
    
    multi_resource_chance=0.60,
    multi_resource={
      ["lead-ore"] = 3,
      ["gold-ore"] = 3,
      ["tin-ore"] = 3,
      ["tungsten-ore"] = 3,
      ["zinc-ore"] = 3,
    }
  }
  
  config["lead-ore"] = {
    type="resource-ore",

    allotment=25,
    spawns_per_region={min=2, max=5},
    richness=220,
    size={min=2, max=5},
    min_amount = 15,

    starting={richness=50, size=3},
    
    multi_resource_chance=0.60,
    multi_resource={
      ["silver-ore"] = 3,
      ["gold-ore"] = 3,
      ["tin-ore"] = 3,
      ["tungsten-ore"] = 3,
      ["zinc-ore"] = 3,
    }
  }
  
  config["tin-ore"] = {
    type="resource-ore",

    allotment=25,
    spawns_per_region={min=2, max=5},
    richness=220,
    size={min=2, max=5},
    min_amount = 15,

    starting={richness=50, size=3},
    
    multi_resource_chance=0.60,
    multi_resource={
      ["lead-ore"] = 3,
      ["silver-ore"] = 3,
      ["gold-ore"] = 3,
      ["tungsten-ore"] = 3,
      ["zinc-ore"] = 3,
      ["copper-ore"] = 2,
    }
  }
  
  config["tungsten-ore"] = {
    type="resource-ore",

    allotment=25,
    spawns_per_region={min=2, max=5},
    richness=220,
    size={min=2, max=5},
    min_amount = 15,

    starting={richness=50, size=3},
    
    multi_resource_chance=0.60,
    multi_resource={
      ["lead-ore"] = 3,
      ["silver-ore"] = 3,
      ["gold-ore"] = 3,
      ["tin-ore"] = 3,
      ["zinc-ore"] = 3,
    }
  }
  
  config["zinc-ore"] = {
    type="resource-ore",

    allotment=25,
    spawns_per_region={min=2, max=5},
    richness=220,
    size={min=2, max=5},
    min_amount = 15,

    starting={richness=50, size=3},
    
    multi_resource_chance=0.60,
    multi_resource={
      ["lead-ore"] = 3,
      ["silver-ore"] = 3,
      ["gold-ore"] = 3,
      ["tin-ore"] = 3,
      ["tungsten-ore"] = 3,
    }
  }
  
-- moltensomethin
  config["lava-2800"] = {
    type="resource-liquid",
    minimum_amount=1000, 
    
    allotment=17,
    spawns_per_region={min=1, max=3},
    richness={min=40000, max=120000},
    size={min=2, max=7},
    
    absolute_probability=0.01,
    
    multi_resource_chance=0.25,
    multi_resource={
      ["lava-2800"] = 1,
      ["lava-1400"] = 2,
      ["lava-600"] = 4
    }
  } 
  config["lava-1400"] = {
    type="resource-liquid",
    minimum_amount=1000, 
    
    allotment=22,
    spawns_per_region={min=1, max=3},
    richness={min=40000, max=120000},
    size={min=2, max=7},
    
    absolute_probability=0.01,
    
    multi_resource_chance=0.25,
    multi_resource={
      ["lava-2800"] = 1,
      ["lava-1400"] = 2,
      ["lava-600"] = 4
    }
  } 
  config["lava-600"] = {
    type="resource-liquid",
    minimum_amount=1000, 
    
    allotment=25,
    spawns_per_region={min=1, max=3},
    richness={min=40000, max=120000}, -- total richness of site 
    size={min=2, max=7}, -- richness devided by this number
    
    absolute_probability=0.01,
    
    starting={richness=10500, size=3},
    multi_resource_chance=0.25,
    multi_resource={
      ["lava-2800"] = 1,
      ["lava-1400"] = 2,
      ["lava-600"] = 4
    }
  }
  
end

if remote.interfaces["DyTech-Warfare"] then
  config["gems"] = {
    type="resource-ore",

    allotment=50,
    spawns_per_region={min=2, max=5},
    richness=125,
    size={min=2, max=5},
    min_amount = 15,
    starting={richness=40, size=3},
    
    multi_resource_chance=0.20,
    multi_resource={
      ["stone"] = 1
    }
  }
  
  if config["zinc"] then
    config["gems"].multi_resource["lead-ore"] = 3
    config["gems"].multi_resource["silver-ore"] = 3
    config["gems"].multi_resource["gold-ore"] = 3
    config["gems"].multi_resource["tin-ore"] = 3
    config["gems"].multi_resource["tungsten-ore"] = 3
    config["gems"].multi_resource["zinc-ore"] = 3
    config["gems"].multi_resource_chance = 0.50
    
    config["lead-ore"].multi_resource["gems"] = 2
    config["silver-ore"].multi_resource["gems"] = 2
    config["gold-ore"].multi_resource["gems"] = 2
    config["tin-ore"].multi_resource["gems"] = 2
    config["tungsten-ore"].multi_resource["gems"] = 2
    config["zinc-ore"].multi_resource["gems"] = 2
  end
  
end


--[[ commented due to absence in current version of F-Mod
if remote.interfaces["F-Mod"] then
  -- geyser left as is for now
  config["geyser"] = {
    type="resource-liquid",
    minimum_amount=750000000, 
    
    allotment=0,
    spawns_per_region={min=1, max=2},
    richness={min=7500000000, max=7500000000}, -- total richness of site 
    size={min=1, max=2}, -- richness devided by this number
  }
  if config["lava-600"] then
    config["lava-600"].multi_resource["geyser"] = 8
    config["lava-1400"].multi_resource["geyser"] = 8
    config["lava-2000"].multi_resource["geyser"] = 8
  end
end
]]--
end