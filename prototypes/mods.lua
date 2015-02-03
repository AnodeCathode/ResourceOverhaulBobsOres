require("prototype_utils")


--Road works
if data.raw["resource"]["RW_limestone"] then
  if is_partial() then
    data.raw["resource"]["RW_limestone"].autoplace.max_probability = 0.03
  else
    add_peak(data.raw["resource"]["RW_limestone"],{influence=-1000})
  end
end

-- BobOres

if data.raw["resource"]["quartz"] then
  if is_partial() then
    data.raw["resource"]["lead-ore"].autoplace = {max_probability = 0.005}
    data.raw["resource"]["silver-ore"].autoplace = {max_probability = 0.005}
    data.raw["resource"]["gold-ore"].autoplace = {max_probability = 0.005}
    data.raw["resource"]["tin-ore"].autoplace = {max_probability = 0.005}
    data.raw["resource"]["tungsten-ore"].autoplace = {max_probability = 0.005}
    data.raw["resource"]["zinc-ore"].autoplace = {max_probability = 0.005}
    data.raw["resource"]["bauxite-ore"].autoplace = {max_probability = 0.005}
    data.raw["resource"]["quartz"].autoplace = {max_probability = 0.005}  
    data.raw["resource"]["rutile-ore"].autoplace = {max_probability = 0.005}  
  else
    add_peak(data.raw["resource"]["lead-ore"],{influence=-1000})
    add_peak(data.raw["resource"]["silver-ore"],{influence=-1000})
    add_peak(data.raw["resource"]["gold-ore"],{influence=-1000})
    add_peak(data.raw["resource"]["tin-ore"],{influence=-1000})
    add_peak(data.raw["resource"]["tungsten-ore"],{influence=-1000})
    add_peak(data.raw["resource"]["bauxite-ore"],{influence=-1000})
    add_peak(data.raw["resource"]["quartz"],{influence=-1000})
    add_peak(data.raw["resource"]["rutile-ore"],{influence=-1000})
    add_peak(data.raw["resource"]["zinc-ore"],{influence=-1000})
  
  end
end
-- DyTech
if data.raw["resource"]["gems"] then
  if is_partial() then
    data.raw["resource"]["gems"].autoplace.max_probability = 0.001
  else
    add_peak(data.raw["resource"]["gems"],{influence=-1000})
  end
end

if data.raw["resource"]["lava-600"] then
  if is_partial() then
    data.raw["resource"]["lava-600"].autoplace = {max_probability = 0.005}
    data.raw["resource"]["lava-1400"].autoplace = {max_probability = 0.005}
    data.raw["resource"]["lava-2800"].autoplace = {max_probability = 0.005}
    
    data.raw["resource"]["lead-ore"].autoplace = {max_probability = 0.005}
    data.raw["resource"]["silver-ore"].autoplace = {max_probability = 0.005}
    data.raw["resource"]["gold-ore"].autoplace = {max_probability = 0.005}
    data.raw["resource"]["tin-ore"].autoplace = {max_probability = 0.005}
    data.raw["resource"]["tungsten-ore"].autoplace = {max_probability = 0.005}
    data.raw["resource"]["zinc-ore"].autoplace = {max_probability = 0.005}
  else
    add_peak(data.raw["resource"]["lava-600"],{influence=-1000})
    add_peak(data.raw["resource"]["lava-1400"],{influence=-1000})
    add_peak(data.raw["resource"]["lava-2800"],{influence=-1000})
    
    add_peak(data.raw["resource"]["lead-ore"],{influence=-1000})
    add_peak(data.raw["resource"]["silver-ore"],{influence=-1000})
    add_peak(data.raw["resource"]["gold-ore"],{influence=-1000})
    add_peak(data.raw["resource"]["tin-ore"],{influence=-1000})
    add_peak(data.raw["resource"]["tungsten-ore"],{influence=-1000})
    add_peak(data.raw["resource"]["zinc-ore"],{influence=-1000})

    --add_peak(data.raw["resource"]["sand"],{influence=-20})
  end
end

-- F-Mod
if data.raw["resource"]["geyser"] then
  --add_peak(data.raw["resource"]["gems"],{influence=-20})
end