-- paracosms[boros]
--
--
-- llllllll.co/t/?
--
--
--
--    ▼ instructions below ▼
-- K3 start/stops sample
-- (hold length = fade)
-- K1+K3 primes recording
-- (when primed, starts)
--
-- E1 select sample
-- K1+E1 select running sample
--
-- K2/K1+K2 selects parameters
-- E2/E3 modulate parameter
-- K1+E2/E3 modulate more
--
--
--
--


substance=function()
  params:set("clock_tempo",110)
end


style=function()
  params:set("tracker_file","/home/we/dust/data/everything.txt")
  params:set("output_all",2)
  --global_reset_needed=1
end

blocks={
  {folder="/home/we/dust/audio/paracosms/row3",params={amp_strength=0.1,amp=1.0,pan_strength=0.2,send1=0.5,send2=0.5}},
  {folder="/home/we/dust/audio/paracosms/row3",params={amp=1.0,send1=0,send2=1}},
  {folder="/home/we/dust/audio/paracosms/row3"},
  {folder="/home/we/dust/audio/paracosms/row4"},
  {folder="/home/we/dust/audio/paracosms/row5"},
  {folder="/home/we/dust/audio/paracosms/row6"},
  {folder="/home/we/dust/audio/paracosms/row7"},
}

-- do not edit this
include("lib/paracosms")
