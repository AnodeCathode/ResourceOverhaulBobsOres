require("prototype_utils")
if is_partial() then
  -- Leave small patches there is and there

  data.raw["resource"]["iron-ore"].autoplace.max_probability = 0.08
  data.raw["resource"]["iron-ore"].autoplace.peaks = generate_basic_peaks("iron-ore")
  --change_ocataves(data.raw["resource"]["iron-ore"].autoplace, 1)
  --data.raw["resource"]["iron-ore"].autoplace.sharpness = 0

  data.raw["resource"]["copper-ore"].autoplace.max_probability = 0.08
  data.raw["resource"]["copper-ore"].autoplace.peaks = generate_basic_peaks("copper-ore")
  --change_ocataves(data.raw["resource"]["copper-ore"].autoplace, 1)
  --data.raw["resource"]["copper-ore"].autoplace.sharpness = 0

  data.raw["resource"]["stone"].autoplace.max_probability = 0.08
  data.raw["resource"]["stone"].autoplace.peaks = generate_basic_peaks("stone")
  --change_ocataves(data.raw["resource"]["stone"].autoplace, 1)
  --data.raw["resource"]["stone"].autoplace.sharpness = 0

  data.raw["resource"]["coal"].autoplace.max_probability = 0.08
  data.raw["resource"]["coal"].autoplace.peaks = generate_basic_peaks("coal")
  --change_ocataves(data.raw["resource"]["coal"].autoplace, 1)
  --data.raw["resource"]["coal"].autoplace.sharpness = 1
  
  data.raw["resource"]["crude-oil"].autoplace.max_probability = 0.005
  
else
  add_peak(data.raw["resource"]["iron-ore"],{influence=-1000})
  add_peak(data.raw["resource"]["copper-ore"],{influence=-1000})
  add_peak(data.raw["resource"]["coal"],{influence=-1000})
  add_peak(data.raw["resource"]["stone"],{influence=-1000})

  add_peak(data.raw["resource"]["crude-oil"],{influence=-1000})

end

-- disable spawners regardless
add_peak(data.raw["unit-spawner"]["biter-spawner"],{influence=-1000})
add_peak(data.raw["unit-spawner"]["spitter-spawner"],{influence=-1000})
add_peak(data.raw["turret"]["small-worm-turret"],{influence=-1000})
add_peak(data.raw["turret"]["medium-worm-turret"],{influence=-1000})
add_peak(data.raw["turret"]["big-worm-turret"],{influence=-1000})