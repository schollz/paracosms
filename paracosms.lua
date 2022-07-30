-- paracosms
--
--
-- llllllll.co/t/paracosms
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
-- K1+E1 select loaded sample
--
-- K2/K1+K2 selects parameters
-- E2/E3 modulate parameter
-- K1+E2/E3 modulate more
--
--
--
--

substance=function()
  params:set("clock_tempo",120)
end

blocks={
  {folder="/home/we/dust/code/paracosms/lib/row1",params={amp=0.5,pan=math.random(-30,30)/100,send1=1,send2=0}},
  {folder="/home/we/dust/audio/x0x/909",params={oneshot=2,attack=0.002}},
  {folder="/home/we/dust/audio/paracosms/row3"},
  {folder="/home/we/dust/audio/paracosms/row4"},
  {folder="/home/we/dust/audio/paracosms/row5"},
  {folder="/home/we/dust/audio/paracosms/row6"},
  {folder="/home/we/dust/audio/paracosms/row7"},
}

style=function()
  params:set("record_beats",2)
end

-- do not edit this
include("lib/paracosms")
