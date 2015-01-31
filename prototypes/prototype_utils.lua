require("../config")

function is_partial()
  return (override_type == 'partially')
end

function add_peak(ent, peak)
  if ent.autoplace then		-- peace mod sets autoplace to null for the spawners, prevent that we use it if this is the case.
    ent.autoplace.peaks[#ent.autoplace.peaks+1] = peak
	end
end

function change_ocataves(autoplace, octaves)
  for k,v in pairs(autoplace.peaks) do
    if v.noise_layer then
        v.noise_octaves_difference = (v.noise_octaves_difference or 0) + octaves
    end
  end
end

function generate_basic_peaks(noise_layer)
  return {
          {
            influence = 0.1
          },
          {
            influence = 0.67,
            noise_layer = noise_layer,
            noise_octaves_difference = -2.7,
            noise_persistence = 0.3
          }
        }

end

