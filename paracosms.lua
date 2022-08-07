-- paracosms v1.0.0
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

--------------------
-- EDIT THIS FILE --
--------------------

-----------------------------------------------
-- OR, BETTER, COPY THIS FILE INTO A NEW ONE --
-----------------------------------------------

substance=function()
  -- things put here will run before startup is initiated
  -- useful for setting up a specific clock tempo, e.g.:
  -- params:set("clock_tempo",120)
  params:set("clock_tempo",120)
end

-- specify a folder for each block of 16 samples to load
blocks={
  {folder="/home/we/dust/audio/paracosms/row3",params={amp=2.0,amp_strength=0.25,pan_strength=0.5}},
  {folder="/home/we/dust/audio/paracosms/row3"},
  {folder="/home/we/dust/audio/paracosms/row3"},
  {folder="/home/we/dust/audio/paracosms/row3"},
  {folder="/home/we/dust/audio/paracosms/row5"},
  {folder="/home/we/dust/audio/paracosms/row6"},
  {folder="/home/we/dust/audio/paracosms/row7"},
}

style=function()
  -- things put here will run after startup is initiated
  -- useful to do things like load a specific save
  params:set("tracker_file","/home/we/dust/data/song3.txt")
  params:set("output_all",4)
  params:set("record_firstbeat",2)
end

---------------------------------
-- DO NOT EDIT BELOW THIS LINE --
---------------------------------

include("lib/paracosms")
