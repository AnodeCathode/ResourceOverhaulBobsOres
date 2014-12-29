require "defines"
require "config"
require "util"
local MB=require "libs/metaball"
local drand = require 'libs/drand'
local rng = drand.mwvc
if not deterministic then rng = drand.sys_rand end

local logger = require 'libs/logger'
local l = logger.new_logger()

-- math shortcuts
local floor = math.floor
local abs = math.abs
local cos = math.cos
local sin = math.sin
local pi = math.pi
local max = math.max


local function debug(str)
  if debug_enabled then
    l:log(str)
  end
end

-- constants
local CHUNK_SIZE = 32
local REGION_TILE_SIZE = CHUNK_SIZE*region_size
local MIN_BALL_DISTANCE = CHUNK_SIZE/6
local P_BALL_SIZE_FACTOR = 0.7
local N_BALL_SIZE_FACTOR = 0.95
local NEGATIVE_MODIFICATOR = 123456 
local meta_shapes = {MB.MetaEllipse, MB.MetaSquare}

-- local globals
local index_is_built = false
local assoc_config = {}
local max_allotment = 0
local rgen = nil
local distance = util.distance


--[[ HELPER METHODS ]]--

local function normalize(n) --keep numbers at (positive) 32 bits
  return floor(n) % 0x80000000
end

local function bearing(origin, dest)
  -- finds relative angle
  local xd = dest.x - origin.x
  local yd = dest.y - origin.y
  return math.atan2(xd, yd);
end

local function str2num(s)
  local num = 0
  for i=1,s:len() do
    num=num + (s:byte(i) - 33)*i
  end
  return num
end

local function mult_for_pos(pos)
  local num = 0
  local x = pos.x
  local y = pos.y

  if x == 0 then x = 0.5 end
  if y == 0 then y = 0.5 end
  if x < 0 then
    x = abs(x) + NEGATIVE_MODIFICATOR
  end
  if y < 0 then
    y = abs(y) + NEGATIVE_MODIFICATOR
  end

  return drand.lcg(y, 'mvc'):random(0)*drand.lcg(x, 'nr'):random(0)
end

local function rng_for_reg_pos(pos)
  local rgen = rng(normalize(glob.seed*mult_for_pos(pos)))
  rgen:random()
  rgen:random()
  rgen:random()
  return rgen
end

local function rng_restricted_angle(restrictions)
  local rng = rgen:random()
  local x_scale, y_scale
  local deform = rgen:random()

  if restrictions=='xy' then
    y_scale=1.0 - deform*0.5
    x_scale=1.0 + deform*0.5
    angle = rng*pi*2  
  elseif restrictions=='x' then
    y_scale=1.0 - deform*0.6
    x_scale=1.0 + deform*0.6
    angle = rng*pi/2 - pi/4
  elseif restrictions=='y' then
    y_scale=1.0 - deform*0.6
    x_scale=1.0 + deform*0.6
    angle = rng*pi/2 + pi/2
  else
    y_scale=1.0 - deform*0.3
    x_scale=1.0 + deform*0.3
    angle = rng*pi*2
  end

  return angle, x_scale, y_scale
end

local function vary_by_percentage(x, p)
  return x + (0.5 - rgen:random())*2*x*p
end


local function remove_trees(x, y, x_size, y_size )
  local bb={{x - x_size, y - y_size}, {x + x_size, y + y_size}}
  for _, entity in ipairs(game.findentitiesfiltered{area = bb, type="tree"}) do
    if entity.valid then
      entity.destroy()
    end
  end
end

local function find_intersection(x, y)
  -- try to get position in between of valid chunks by probing map
  -- this may breaks determinism of generation, but so far it returned on first if
  local gt = game.gettile
  local restriction = ''
  if gt(x + CHUNK_SIZE*2, y + CHUNK_SIZE*2).valid and gt(x - CHUNK_SIZE*2, y - CHUNK_SIZE*2).valid and gt(x + CHUNK_SIZE*2, y - CHUNK_SIZE*2).valid and gt(x - CHUNK_SIZE*2, y + CHUNK_SIZE*2).valid then
    restriction = 'xy'
  elseif gt(x + CHUNK_SIZE*2, y + CHUNK_SIZE*2).valid and gt(x + CHUNK_SIZE*2, y).valid and gt(x, y + CHUNK_SIZE*2).valid then
    x=x + CHUNK_SIZE/2
    y=y + CHUNK_SIZE/2
    restriction = 'xy'
  elseif gt(x + CHUNK_SIZE*2, y - CHUNK_SIZE*2).valid and gt(x + CHUNK_SIZE*2, y).valid and gt(x, y - CHUNK_SIZE*2).valid then
    x=x + CHUNK_SIZE/2
    y=y - CHUNK_SIZE/2
    restriction = 'xy'
  elseif gt(x - CHUNK_SIZE*2, y + CHUNK_SIZE*2).valid and gt(x - CHUNK_SIZE*2, y).valid and gt(x, y + CHUNK_SIZE*2).valid then
    x=x - CHUNK_SIZE/2
    y=y + CHUNK_SIZE/2
    restriction = 'xy'    
  elseif gt(x - CHUNK_SIZE*2, y - CHUNK_SIZE*2).valid and gt(x - CHUNK_SIZE*2, y).valid and gt(x, y - CHUNK_SIZE*2).valid then
    x=x - CHUNK_SIZE/2
    y=y - CHUNK_SIZE/2
    restriction = 'xy'
  elseif gt(x + CHUNK_SIZE*2, y).valid then
    x=x + CHUNK_SIZE/2
    restriction = 'x'
  elseif gt(x - CHUNK_SIZE*2, y).valid then
    x=x - CHUNK_SIZE/2
    restriction = 'x'
  elseif gt(x, y + CHUNK_SIZE*2).valid then
    y=y + CHUNK_SIZE/2
    restriction = 'y'
  elseif gt(x, y - CHUNK_SIZE*2).valid then
    y=y - CHUNK_SIZE/2
    restriction = 'y'
  end
  return x, y, restriction
end

local function find_random_chunk(r_x, r_y)
  local offset_x=rgen:random(region_size)-1
  local offset_y=rgen:random(region_size)-1
  local c_x=r_x*REGION_TILE_SIZE + offset_x*CHUNK_SIZE
  local c_y=r_y*REGION_TILE_SIZE + offset_y*CHUNK_SIZE
  return c_x, c_y
end

local function is_same_region(c_x1, c_y1, c_x2, c_y2)
  if not floor(c_x1/REGION_TILE_SIZE) == floor(c_x2/REGION_TILE_SIZE) then
    return false
  end
  if not floor(c_y1/REGION_TILE_SIZE) == floor(c_y2/REGION_TILE_SIZE) then
    return false
  end
  return false
end

local function find_random_neighbour_chunk(ocx, ocy)
  -- somewhat bruteforce and unoptimized
  local x_dir = rgen:random(-1,1)
  local y_dir = rgen:random(-1,1)
  local ncx = ocx + x_dir*CHUNK_SIZE
  local ncy = ocy + y_dir*CHUNK_SIZE
  if is_same_region(ncx, ncy, ocx, ocy) then
    return ncx, ncy
  end

  ncx = ocx - x_dir*CHUNK_SIZE
  ncy = ocy - y_dir*CHUNK_SIZE
  if is_same_region(ncx, ncy, ocx, ocy) then
    return ncx, ncy
  end

  ncx = ocx - x_dir*CHUNK_SIZE
  if is_same_region(ncx, ocy, ocx, ocy) then
    return ncx, ocy
  end

  ncy = ocy - y_dir*CHUNK_SIZE
  if is_same_region(ocx, ncy, ocx, ocy) then
    return ocx, ncy
  end
  
  return ocx, ocy
end

-- modifies the resource size - only used in endless_resource_mode
local function modify_resource_size(resourceSize)
	if not endless_resource_mode then return resourceSize end
	
	newResourceSize = resourceSize * endless_resource_mode_sizeModifier

	-- make sure it's still an integer
	newResourceSize = math.ceil(newResourceSize)
	-- make sure it's not 0
	if newResourceSize == 0 then newResourceSize = 1 end
	return newResourceSize
end

--[[ SPAWN METHODS ]]--

--[[ entity-field ]]--
local function spawn_resource_ore(rname, pos, size, richness, restrictions)
  -- blob generator, centered at pos, size controls blob diameter
  restrictions = restrictions or ''
  debug("Entering spawn_resource_ore "..rname.." "..pos.x..","..pos.y.." "..size.." "..richness.." "..restrictions)
  size = modify_resource_size(size)
  size = size/2 -- to radius
  local p_balls={}
  local n_balls={}
  local MIN_BALL_DISTANCE = math.min(MIN_BALL_DISTANCE, size/2)

  local function generate_p_ball()
    local angle, x_scale, y_scale, x, y, b_size, shape
    angle, x_scale, y_scale=rng_restricted_angle(restrictions)
    local dev = math.min(CHUNK_SIZE/3, size*1.5)
    local dev_x, dev_y = pos.x, pos.y
    x = rgen:random(-dev, dev)+dev_x
    y = rgen:random(-dev, dev)+dev_y
    if p_balls[#p_balls] and distance(p_balls[#p_balls], {x=x, y=y}) < MIN_BALL_DISTANCE then
      local new_angle = bearing(p_balls[#p_balls], {x=x, y=y})
      debug("Move ball old xy @ "..x..","..y)
      x=(cos(new_angle)*MIN_BALL_DISTANCE) + x
      y=(sin(new_angle)*MIN_BALL_DISTANCE) + y
      debug("Move ball new xy @ "..x..","..y)
    end
    b_size = (size + (rgen:random()-0.7)*size/8) * (P_BALL_SIZE_FACTOR^#p_balls)
    shape = meta_shapes[rgen:random(1,#meta_shapes)]
    p_balls[#p_balls+1] = shape:new(x, y, b_size, angle, x_scale, y_scale)
    debug("P+Ball "..shape.type.." @ "..x..","..y.." size: "..b_size.." angle: "..angle.." scale: "..x_scale..", "..y_scale)
  end

  local function generate_n_ball()
    local angle, x_scale, y_scale, x, y, b_size, shape
    angle, x_scale, y_scale=rng_restricted_angle('xy')
    if p_balls[i] then
      local new_angle = p_balls[i].angle + pi*rgen:random(0,1) + (rgen:random()-0.5)*pi/2
      local dist = p_balls[i].radius
      x=(cos(new_angle)*dist) + p_balls[i].x
      y=(sin(new_angle)*dist) + p_balls[i].y
      angle = p_balls[i].angle + pi/2 + (rgen:random()-0.5)*pi*2/3
    else
      x = rgen:random(-size, size)+pos.x
      y = rgen:random(-size, size)+pos.y
    end
    b_size = (size/2 + (rgen:random()-0.5)*size/4) * N_BALL_SIZE_FACTOR^#n_balls
    shape = meta_shapes[rgen:random(1,#meta_shapes)]
    n_balls[#n_balls+1] = shape:new(x, y, b_size, angle, x_scale, y_scale, 1.2)
    debug("N-Ball "..shape.type.." @ "..x..","..y.." size: "..b_size.." angle: "..angle.." scale: "..x_scale..", "..y_scale)
  end

  local function calculate_force(x,y)
    local p_force = 0
    local n_force = 0
    for _,ball in pairs(p_balls) do
      p_force = p_force + ball:force(x,y)
    end
    for _,ball in pairs(n_balls) do
      n_force = n_force + ball:force(x,y)
    end
    return (1 - 1/p_force) - n_force
  end  

  local max_p_balls = 2
  local min_amount = assoc_config[rname].min_amount or min_amount
  if restrictions == 'xy' then
    -- we have full 4 chunks
    size = math.min(size*1.5, CHUNK_SIZE/2)
    richness = richness*2/3
    min_amount = min_amount / 3
    max_p_balls=3
  end

  local force
  -- generate blobs
  for i=1,max_p_balls do
    generate_p_ball()
  end

  for i=1,rgen:random(1, #p_balls) do
    generate_n_ball()
  end

  local _a = {}
  local _total = 0
  -- fill the map
  for y=pos.y-CHUNK_SIZE*2, pos.y+CHUNK_SIZE*2-1 do
    local _b = {}
    _a[#_a+1] = _b
    for x=pos.x-CHUNK_SIZE*2, pos.x+CHUNK_SIZE*2-1 do
      if game.gettile(x,y).valid then
        force = calculate_force(x, y)
        if force > 0 then
          local amount=floor((richness*force*(0.8^#p_balls)) + min_amount)
          --debug("@ "..x..","..y.." force: "..force.." amount: "..amount)
          if not game.gettile(x,y).collideswith("water-tile") and game.canplaceentity{name = rname, position = {x,y}} then
            _b[#_b+1] = '#'
            _total = _total + amount
            game.createentity{name = rname,
              position = {x,y},
              force = game.forces.neutral,
              amount = amount*global_richness_mult,
              direction = rgen:random(4)} -- does not work on resources -_-
          else
            entities = game.findentitiesfiltered{area = {{x-2.75, y-2.75}, {x+2.75, y+2.75}}, name=rname}
            if entities and #entities > 0 then
              _b[#_b+1] = 'O'
              _total = _total + amount
              for k, ent in pairs(entities) do
                ent.amount = ent.amount + floor(amount/#entities)
              end
            else
              _b[#_b+1] = '.'
            end
          end
        else
          _b[#_b+1] = '<'
        end
      else
        _b[#_b+1] = 'x'
      end
    end
  end
  if debug_enabled then
    debug("Total amount: ".._total)
    for _,v in pairs(_a) do
      --output a nice ASCII map
      debug(table.concat(v))
    end
    debug("Leaving spawn_resource_ore")
  end
  return _total
end

--[[ entity-liquid ]]--
local function spawn_resource_liquid(rname, pos, size, richness, restrictions)
  restrictions = restrictions or ''
  debug("Entering spawn_resource_liquid "..rname.." "..pos.x..","..pos.y.." "..size.." "..richness.." "..restrictions)
  local _total = 0
  local max_radius = rgen:random()*CHUNK_SIZE/2 + CHUNK_SIZE
  --[[
  if restrictions == 'xy' then
    -- we have full 4 chunks
    max_radius = floor(max_radius*1.5)
    size = floor(size*1.2)
  end
  ]]--
  size = modify_resource_size(size)

  local total_share = 0
  local avg_share = 1/size
  local angle = rgen:random()*pi*2
  local saved = 0
  while total_share < 1 do
    local new_share = vary_by_percentage(avg_share, 0.25)
    if new_share + total_share > 1 then
      new_share = 1 - total_share
    end
    total_share = new_share + total_share
    if new_share < avg_share/10 then
      -- too small
      break 
    end
    local amount = floor(richness*new_share) + saved
    --if amount >= game.entityprototypes[rname].minimum then 
    if amount >= assoc_config[rname].minimum_amount then 
      saved = 0
      for try=1,5 do
        local dist = rgen:random()*(max_radius - max_radius*0.1)
        angle = angle + pi/4 + rgen:random()*pi/2
        local x, y = pos.x + cos(angle)*dist, pos.y + sin(angle)*dist
        if game.canplaceentity{name = rname, position = {x,y}} then
          debug("@ "..x..","..y.." amount: "..amount.." new_share: "..new_share.." try: "..try)
          _total = _total + amount
          game.createentity{name = rname,
            position = {x,y},
            force = game.forces.neutral,
            amount = amount*global_richness_mult,
            direction = rgen:random(4)}
          break
        else
          entities = game.findentitiesfiltered{area = {{x-2.75, y-2.75}, {x+2.75, y+2.75}}, name=rname}
          if entities and #entities > 0 then
            _total = _total + amount
            for k, ent in pairs(entities) do
              ent.amount = ent.amount + floor(amount/#entities)
            end
            break
          end
        end
      end
    else
      saved = amount
    end
  end
  debug("Total amount: ".._total)
  debug("Leaving spawn_resource_liquid")
  return _total
end

local function spawn_entity(ent, r_config, x, y)
  if disable_RSO_biter_spawning then return end
  local size=rgen:random(r_config.size.min, r_config.size.max)

  local _total = 0
  local r_distance = distance({x=0,y=0},{x=x/REGION_TILE_SIZE,y=x/REGION_TILE_SIZE})  
  
  if r_config.size_per_region_factor then
    size = size*math.min(r_config.size_per_region_factor^r_distance, 5)
  end
  debug("Entering spawn_entity "..ent.." "..x..","..y.." "..size)
  for i=1,size do
    local richness=r_config.richness*(richness_distance_factor^r_distance)
    local max_d = floor(CHUNK_SIZE*1.3)
    local s_x = x + rgen:random(0, floor(max_d - r_config.clear_range[1])) - max_d/2 + r_config.clear_range[1]
    local s_y = y + rgen:random(0, floor(max_d - r_config.clear_range[2])) - max_d/2 + r_config.clear_range[2]
              
    remove_trees(s_x, s_y, r_config.clear_range[1], r_config.clear_range[2])
    f=game.forces.enemy
    
    if game.gettile(s_x, s_y).valid and game.canplaceentity{name=ent, position={s_x, s_y}} then
      _total = _total + richness
      debug("@ "..s_x..","..s_y)
      game.createentity{name=ent, position={s_x, s_y}, force=game.forces[r_config.force], amount=richness, direction=rgen:random(4)}
    end
    if r_config.sub_spawn_probability then
      local sub_spawn_prob = r_config.sub_spawn_probability*math.min(r_config.sub_spawn_max_distance_factor, r_config.sub_spawn_distance_factor^r_distance)
      if rgen:random() < sub_spawn_prob then
        for i=1,rgen:random(r_config.sub_spawn_size.min, r_config.sub_spawn_size.max) do
          local allotment_max = 0
          -- build table
          for k,v in pairs(r_config.sub_spawns) do
            if not v.min_distance or r_distance > v.min_distance then
              local allotment = v.allotment
              if v.allotment_distance_factor then
                allotment = allotment * (v.allotment_distance_factor^r_distance)
              end
              v.allotment_range ={min = allotment_max, max = allotment_max + allotment}
              allotment_max = allotment_max + allotment
            else
              v.allotment_range = nil
            end 
          end
          local sub_type = rgen:random(0, allotment_max)
          for sub_spawn,v in pairs(r_config.sub_spawns) do
            if v.allotment_range and sub_type >= v.allotment_range.min and sub_type <= v.allotment_range.max then
              s_x = x + rgen:random(max_d) - max_d/2
              s_y = y + rgen:random(max_d) - max_d/2
              remove_trees(s_x, s_y, v.clear_range[1], v.clear_range[2])
              if game.gettile(s_x, s_y).valid and game.canplaceentity{name=sub_spawn, position={s_x, s_y}} then
                game.createentity{name=sub_spawn, position={s_x, s_y}, force=game.forces[r_config.force], direction=rgen:random(4)}
                debug("Rolled subspawn "..sub_spawn.." @ "..s_x..","..s_x)
              end
              break
            end
          end
        end
      end
    end
  end
  debug("Total amount: ".._total)
  debug("Leaving spawn_entity")
end

--[[ EVENT/INIT METHODS ]]--

local function spawn_starting_resources()
  if glob.start_resources_spawned or game.tick > 3600 then return end -- starting resources already there or game was started without mod
  rgen = rng_for_reg_pos({x=0,y=0})
  local status = true
  for index,v in pairs(config) do
    if v.starting then 
      local prob = rgen:random() -- probability that this resource is spawned
      debug("starting resource probability rolled "..prob)
      if v.starting.probability > 0 and prob <= v.starting.probability then
	      local total = 0
	      local radius = 10
	      local min_threshold = 0
	      if v.type == "resource-ore" then
	        min_threshold = v.starting.richness * modify_resource_size(v.starting.size)
	      elseif v.type == "resource-liquid" then
	        min_threshold = v.starting.richness*0.5
	      end
	      while (radius<100) and (total < min_threshold) do
	        local angle=rgen:random()*pi*2
	        local dist=rgen:random()*30+radius*2
	        local pos = {x=floor(cos(angle)*dist), y=floor(sin(angle)*dist)}
	        if v.type == "resource-ore" then
	          total = total + spawn_resource_ore(v.name, pos, v.starting.size, v.starting.richness)
	        elseif v.type == "resource-liquid" then
	          total = total + spawn_resource_liquid(v.name, pos, v.starting.size, v.starting.richness)
	        end
	        radius=radius+5
	      end
	      if total < min_threshold then
	        status = false
	      end
      end
    end
  end
  glob.start_resources_spawned = true
  l:dump('logs/start_'..glob.seed..'.log')
end

local function prebuild_config_data()
  if index_is_built then return false end
  assoc_config = config
  config = {}
  for res_name, res_conf in pairs(assoc_config) do
    res_conf.name = res_name
    config[#config+1] = res_conf
    if res_conf.multi_resource then
      local new_list = {}
      for sub_res_name, allotment in pairs(res_conf.multi_resource) do
        new_list[#new_list+1] = {name=sub_res_name, allotment=allotment}
      end
      table.sort(new_list, function(a, b) return a.name < b.name end)
      res_conf.multi_resource = new_list
    end
  end
  table.sort(config, function(a, b) return a.name < b.name end)
  
  local pr=0
  for index,v in pairs(config) do
    if v.along_resource_probability then
      v.along_resource_probability_range={min=pr, max=pr+v.along_resource_probability}
      pr=pr+v.along_resource_probability
    end
    if v.allotment and v.allotment > 0 then
      v.allotment_range={min=max_allotment, max=max_allotment+v.allotment}
      max_allotment=max_allotment+v.allotment
    end
  end
  index_is_built=true
  return true
end

local function generate_seed()
  if glob.seed then return end
  glob.seed = 0
  local entities=game.findentities({{-CHUNK_SIZE,-CHUNK_SIZE},{CHUNK_SIZE,CHUNK_SIZE}})
  for _,ent in pairs(entities) do
    glob.seed=normalize(glob.seed + str2num(ent.name)*mult_for_pos(ent.position))
  end
  for x=-CHUNK_SIZE,CHUNK_SIZE do
    for y=-CHUNK_SIZE,CHUNK_SIZE do
      glob.seed=normalize(glob.seed + str2num(game.gettile(x, y).name)*mult_for_pos({x=x, y=y}))
    end
  end
  --game.player.print("Initial seed: "..glob.seed)
end

local function init()
  if not glob.regions then glob.regions = {} end
  prebuild_config_data()
  generate_seed()
  spawn_starting_resources()
  
  if debug_enabled and not glob.debug_once then
    --game.player.character.insert{name = "coal", count = 1000}
    --game.player.character.insert{name = "car", count = 1}
    --game.player.character.insert{name = "car", count = 1}
    --game.player.character.insert{name = "car", count = 1}
    --game.player.character.insert{name = "resource-monitor", count = 1}
    glob.debug_once = true
  end
end

game.oninit(init)
game.onload(init)
game.onsave(function ()
    l:dump()
end)

local function roll_region(c_x, c_y)
  --in what region is this chunk?
  local r_x=floor(c_x/REGION_TILE_SIZE)
  local r_y=floor(c_y/REGION_TILE_SIZE)
  local r_data = nil
  --don't spawn stuff in starting area
  if ((abs(r_x+0.5)+abs(r_y+0.5))<=starting_area_size) then return false end

  if glob.regions[r_x] and glob.regions[r_x][r_y] then
    r_data = glob.regions[r_x][r_y]
  else
    --if this chunk is the first in its region to be generated
    if not glob.regions[r_x] then glob.regions[r_x] = {} end
    glob.regions[r_x][r_y]={}
    r_data = glob.regions[r_x][r_y]
    rgen = rng_for_reg_pos{x=r_x,y=r_y}

    --absolute chance to spawn resource
    local abct = rgen:random()
    debug("Rolling resource "..abct.." against "..absolute_resource_chance)
    if abct <= absolute_resource_chance then

      local res_type=rgen:random(1, max_allotment)
      for index,v in pairs(config) do
        if v.allotment_range and ((res_type >= v.allotment_range.min) and (res_type <= v.allotment_range.max)) then
          debug("Rolled primary resource "..v.name.." with res_type="..res_type.." @ "..r_x.."."..r_y)
          local num_spawns=rgen:random(v.spawns_per_region.min, v.spawns_per_region.max)
          local last_spawn_coords = {}
          local along_
          for i=1,num_spawns do
            local c_x, c_y = find_random_chunk(r_x, r_y)
            if not r_data[c_x] then r_data[c_x] = {} end
            if not r_data[c_x][c_y] then r_data[c_x][c_y] = {} end
            local c_data = r_data[c_x][c_y]
            c_data[#c_data+1]={v.name, 0}
            last_spawn_coords[#last_spawn_coords+1] = {c_x, c_y}
            debug("Rolled primary chunk "..v.name.." @ "..c_x.."."..c_y.." reg: "..r_x.."."..r_y)
            -- Along resource spawn, only once
            if i == 1 then
              local am_roll = rgen:random()
              for index,vv in pairs(config) do
                if vv.along_resource_probability_range and am_roll >= vv.along_resource_probability_range.min and am_roll <= vv.along_resource_probability_range.max then
                  c_data = r_data[c_x][c_y]
                  c_data[#c_data+1]={vv.name, 0}
                  debug("Rolled along "..vv.name.." @ "..c_x.."."..c_y.." reg: "..r_x.."."..r_y)
                end
              end
            end
          end
          -- roll multiple resources in same region
          local deep=0
          while v.multi_resource_chance and rgen:random() <= v.multi_resource_chance*(multi_resource_chance_diminish^deep) do
            deep = deep + 1
            local max_allotment = 0
            for index,sub_res in pairs(v.multi_resource) do max_allotment=max_allotment+sub_res.allotment end
            
            local res_type=rgen:random(1, max_allotment)
            local min=0
            for _, sub_res in pairs(v.multi_resource) do
              if (res_type >= min) and (res_type <= sub_res.allotment + min) then
                local last_coords = last_spawn_coords[rgen:random(1, #last_spawn_coords)]
                local c_x, c_y = find_random_neighbour_chunk(last_coords[1], last_coords[2]) -- in same as primary resource chunk
                local c_data = r_data[c_x][c_y]
                c_data[#c_data+1]={sub_res.name, deep}
                debug("Rolled multiple "..sub_res.name..":"..deep.." with res_type="..res_type.." @ "..c_x.."."..c_y.." reg: "..r_x.."."..r_y)
                break
              else
                min = min + sub_res.allotment
              end
            end
          end
          break
        end
      end
    
    end

    -- roll for absolute_probability 
    
    for index,v in pairs(config) do
      if v.absolute_probability then
        local prob_factor = 1 
        if v.probability_distance_factor then 
          prob_factor = math.min(v.max_probability_distance_factor, v.probability_distance_factor^distance({x=0,y=0},{x=r_x,y=r_y}))
        end 
        local abs_roll = rgen:random()
        if abs_roll<v.absolute_probability*prob_factor then
          local num_spawns=rgen:random(v.spawns_per_region.min, v.spawns_per_region.max)
          for i=1,num_spawns do
            local c_x, c_y = find_random_chunk(r_x, r_y)
            if not r_data[c_x] then r_data[c_x] = {} end
            if not r_data[c_x][c_y] then r_data[c_x][c_y] = {} end
            c_data = r_data[c_x][c_y]
            c_data[#c_data+1] = {v.name, 1}
            debug("Rolled absolute "..v.name.." with rt="..abs_roll.." @ "..c_x..","..c_y.." reg: "..r_x..","..r_y)
          end
        end
      end
    end
  end
end

local function roll_chunk(c_x, c_y)
  --handle spawn in chunks
  local r_x=floor(c_x/REGION_TILE_SIZE)
  local r_y=floor(c_y/REGION_TILE_SIZE)
  local r_data = nil
  --don't spawn stuff in starting area
  if ((abs(r_x+0.5)+abs(r_y+0.5))<=starting_area_size) then return false end

  local c_center_x=c_x + CHUNK_SIZE/2
  local c_center_y=c_y + CHUNK_SIZE/2
  if not (glob.regions[r_x] and glob.regions[r_x][r_y]) then
    return
  end
  r_data = glob.regions[r_x][r_y]
  if not (r_data[c_x] and r_data[c_x][c_y]) then
    return
  end
  if r_data[c_x] and r_data[c_x][c_y] then
    rgen = rng_for_reg_pos{x=c_center_x,y=c_center_y}
    
    debug("Stumbled upon "..c_x..","..c_y.." reg: "..r_x.."."..r_y)
    local resource_list = r_data[c_x][c_y]
    --for resource, deep in pairs(r_data[c_x][c_y]) do
    --  resource_list[#resource_list+1] = {resource, deep}
    --end
    table.sort(resource_list, function(a, b) return a[2] < b[2] end)
    for _, res_con in pairs(resource_list) do
      local resource = res_con[1]
      local deep = res_con[2]
      local r_config = assoc_config[resource]
      if r_config.type=="resource-ore" then
        local size=rgen:random(r_config.size.min, r_config.size.max) * (multi_resource_size_factor^deep)
        local richness = r_config.richness*(richness_distance_factor^distance({x=0,y=0},{x=r_x,y=r_y})) * (multi_resource_richness_factor^deep)
        local restriction = ''
        debug("Center @ "..c_center_x..","..c_center_y)
        c_center_x, c_center_y, restriction = find_intersection(c_center_x, c_center_y)
        debug("New Center @ "..c_center_x..","..c_center_y)
        spawn_resource_ore(resource, {x=c_center_x,y=c_center_y}, size, richness, restriction)
      elseif r_config.type=="resource-liquid" then
        local size=rgen:random(r_config.size.min, r_config.size.max)  * (multi_resource_size_factor^deep)
        local richness=rgen:random(r_config.richness.min, r_config.richness.max) * (richness_distance_factor^distance({x=0,y=0},{x=r_x,y=r_y})) * (multi_resource_richness_factor^deep)
        local restriction = ''
        c_center_x, c_center_y, restriction = find_intersection(c_center_x, c_center_y)
        spawn_resource_liquid(resource, {x=c_center_x,y=c_center_y}, size, richness, restriction)
      end
      if (r_config.type=="entity") then
        spawn_entity(resource, r_config, c_center_x, c_center_y)
      end
    end
    r_data[c_x][c_y]=nil
    --l:dump()
  end
end

local function clear_chunk(c_x, c_y)
  local ent_list = {}
  local _count = 0
  for _,v in pairs(config) do
    ent_list[v.name] = 1
    if v.sub_spawns then
      for ent,vv in pairs(v.sub_spawns) do
        ent_list[ent] = 1
      end
    end
  end
  
  for ent, _ in pairs(ent_list) do
    for _, obj in ipairs(game.findentitiesfiltered{area = {{c_x - CHUNK_SIZE/2, c_y - CHUNK_SIZE/2}, {c_x + CHUNK_SIZE/2, c_y + CHUNK_SIZE/2}}, name=ent}) do
      if obj.valid then
        obj.destroy()
        _count = _count + 1
      end
    end
  end
  
  -- remove biters
  for _, obj in ipairs(game.findentitiesfiltered{area = {{c_x - CHUNK_SIZE/2, c_y - CHUNK_SIZE/2}, {c_x + CHUNK_SIZE/2, c_y + CHUNK_SIZE/2}}, type="unit"}) do
    if obj.valid  and obj.force.name == "enemy"  and string.find(obj.name, "-biter", -6) then
      obj.destroy()
    end
  end
  
  if _count > 0 then debug("Destroyed - ".._count) end
end

local function regenerate_everything()
  -- step 1: clear the map and mark chunks for in place generation
  glob.regions = {}
  local valid_chunks = {}
  local i = 1 
  local status = true
  local iter_y_start, iter_y_end, iter_y_step, iter_x_start, iter_x_end, iter_x_step
  local function set_iterators(case) 
    if case == 1 then
      -- top_left -> bottom_left
      iter_y_start = i
      iter_y_end = -i + 1
      iter_y_step = -1
      iter_x_start = i
      iter_x_end = i
      iter_x_step = 1
    elseif case == 2 then
      -- bottom_left -> bottom_rigth
      iter_y_start = -i
      iter_y_end = -i
      iter_y_step = 1
      iter_x_start = i
      iter_x_end = -i + 1
      iter_x_step = -1
    elseif case == 3 then
      -- bottom_right -> top_right
      iter_y_start = -i
      iter_y_end = i - 1
      iter_y_step = 1
      iter_x_start = -i
      iter_x_end = -i
      iter_x_step = 1
    elseif case == 4 then
      -- top_right -> top_left
      iter_y_start = i
      iter_y_end = i
      iter_y_step = 1
      iter_x_start = -i
      iter_x_end = i - 1
      iter_x_step = 1
    end
  end
  
  while status do
    status = false
    for case=1,4 do
      set_iterators(case)
      for yi=iter_y_start, iter_y_end, iter_y_step  do
        for xi=iter_x_start, iter_x_end, iter_x_step  do
          local c_x = CHUNK_SIZE*xi
          local c_y = CHUNK_SIZE*yi
          if (abs(c_x)+abs(c_y))>starting_area_size*REGION_TILE_SIZE then -- don't touch safe zone
            local cen_x, cen_y = c_x + CHUNK_SIZE/2, c_y + CHUNK_SIZE/2
            local _x, _y, restriction = find_intersection(cen_x, cen_y)
            if restriction == 'xy' and c_x + CHUNK_SIZE/2 == _x  and  c_y + CHUNK_SIZE/2 == _y then
              valid_chunks[c_x] = valid_chunks[c_x] or {}
              valid_chunks[c_x][c_y] = true
              clear_chunk(cen_x, cen_y)
              debug("Added "..c_x..","..c_y.." center: "..cen_x..","..cen_y)
              status = true
            end
          else
            status = true
          end
        end
      end
    end
    i = i + 1
  end
  
  -- step 2: regenerate chunks again
  i = 1
  for k, v in pairs(assoc_config) do
    -- regenerate small patches
    game.regenerateentity(k)
  end
  -- regenerate RSO chunks
  status = true
  while status do
    status = false
    for case=1,4 do
      set_iterators(case)
      for yi=iter_y_start, iter_y_end, iter_y_step  do
        for xi=iter_x_start, iter_x_end, iter_x_step  do
          local c_x = CHUNK_SIZE*xi
          local c_y = CHUNK_SIZE*yi
          if (abs(c_x)+abs(c_y))<=starting_area_size*REGION_TILE_SIZE then
            status = true
          end
          if valid_chunks[c_x] and valid_chunks[c_x][c_y] then
            roll_region(c_x, c_y)
            roll_chunk(c_x, c_y)
            status = true
          end
        end
      end
    end
    i = i + 1
  end
  l:dump("logs/"..glob.seed..'regenerated.log')
  game.player.print('Done')
end

game.onevent(defines.events.onchunkgenerated, function(event)
  local c_x = event.area.lefttop.x
  local c_y = event.area.lefttop.y
  
  roll_region(c_x, c_y)
  roll_chunk(c_x, c_y)
end)

remote.addinterface("RSO", {
  -- remote.call("RSO", "regenerate", true/false)
  regenerate = function(new_seed)
    if new_seed then glob.seed = math.random(0x80000000) end
    regenerate_everything()
  end
})



