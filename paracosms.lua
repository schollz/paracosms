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
end

-- specify a folder for each block of 16 samples to load
blocks={
  {folder="/home/we/dust/audio/paracosms/row7"},
  {folder="/home/we/dust/audio/paracosms/row7"},
  {folder="/home/we/dust/audio/paracosms/row7"},
  {folder="/home/we/dust/audio/paracosms/row7"},
  {folder="/home/we/dust/audio/paracosms/row7"},
  {folder="/home/we/dust/audio/paracosms/row7"},
  {folder="/home/we/dust/audio/paracosms/row7"},
}

-- -- uncommment these to get a demo from when you first start
-- blocks={
--   -- you can apply parameters to specific blocks, for example the amplitude, the pan, or the sends
--   {folder="/home/we/dust/code/paracosms/lib/row1",params={amp=0.5,pan=math.random(-30,30)/100,send_main=1,send_tape=0}},
--   -- or you can apply parameters to make a block a set of oneshots
--   {folder="/home/we/dust/audio/x0x/909",params={oneshot=2,attack=0.002}},
--   {folder="/home/we/dust/audio/paracosms/row3"},
--   {folder="/home/we/dust/audio/paracosms/row4"},
--   {folder="/home/we/dust/audio/paracosms/row5"},
--   {folder="/home/we/dust/audio/paracosms/row6"},
--   {folder="/home/we/dust/audio/paracosms/row7"},
-- }

style=function()
  -- things put here will run after startup is initiated
  -- useful to do things like load a specific save
end

---------------------------------
-- DO NOT EDIT BELOW THIS LINE --
---------------------------------

include("lib/paracosms")
