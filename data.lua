require("config")
if override_normal_spawn then
  require("prototypes/base")
  require("prototypes/mods")
end

if debug_enabled then
data.raw["car"]["car"].max_health = 0x8000000
data.raw["ammo"]["basic-bullet-magazine"].magazine_size = 1000
data.raw["ammo"]["basic-bullet-magazine"].ammo_type.action[1].action_delivery[1].target_effects[2].damage.amount = 5000
end