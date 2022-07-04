-- 108 turntables

viewwave_=include("lib/viewwave")
turntable_=include("lib/turntable")
grid_=include("lib/ggrid")

engine.name="Slinky"
dat={}

function init()
  dat.ti=1
  dat.tt={}
  table.insert(dat.tt,turntable_:new{id=1,path="/home/we/dust/audio/seamlessloops/LFH2_120_Dm_BasementEPiano_52_Full_keyDmin_bpm120_beats32_.flac"})
  table.insert(dat.tt,turntable_:new{id=2,path="/home/we/dust/audio/seamlessloops/019_Lead_Arp__With_FX_Trail__D_Minor_120bpm_-_ORGANICHOUSE_Zenhiser_keyDmin_bpm120_beats64_.flac"})
  table.insert(dat.tt,turntable_:new{id=3,path="/home/we/dust/audio/seamlessloops/ah_bs120_sublime_Dm_keyDmin_bpm120_beats8_.flac"})
  g_=grid_:new()

  osc.event=function(path,args,from)
    if args[1]==0 then
      do return end
    end
    local id=args[1]
    local datatype="cursor"
    if id>200 then
      id=id-200
      datatype="amplitude"
      local val=util.round(util.clamp(util.linlin(0,0.25,0,16,args[2]),2,15))
      --print(id,val)
      g_:light_up(id,val)
      do return end
    end
    if path=="ready" then
      datatype=path
    end
    if dat.tt[id]~=nil then
      dat.tt[id]:oscdata(datatype,args[2])
    end
  end
  clock.run(function()
    while true do
      clock.sleep(1/10)
      redraw()
    end
  end)
  clock.run(function()
    redraw()
    while true do
      local readied=0
      for _,tt in ipairs(dat.tt) do
        readied=readied+(tt.ready and 1 or 0)
      end
      print(readied)
      if readied==#dat.tt then
        break
      end
      show_message("loading...",1.0)
      show_progress(readied/#dat.tt*100)
      clock.sleep(0.2)
    end
    engine.watch(1)
  end)
end

function switch_view(id)
  if id>#dat.tt then
    do return end
  end
  dat.ti=id
  engine.watch(id)
end

function key(k,z)

end

function enc(k,d)

end

local show_message_text=""
local show_message_progress=0

function show_progress(val)
  show_message_progress=util.clamp(val,0,100)
end

function show_message(message,seconds)
  if show_message_clock~=nil then
    clock.cancel(show_message_clock)
  end
  show_message_clock=clock.run(function()
    show_message_text=message
    redraw()
    clock.sleep(seconds or 1.0)
    show_message_text=""
    show_message_progress=0
    redraw()
  end)
end

function redraw()
  screen.clear()
  dat.tt[dat.ti]:redraw()
  if show_message_text~="" then
    screen.blend_mode(0)
    local x=64
    local y=28
    local w=screen.text_extents(show_message_text)+8
    screen.rect(x-w/2,y,w,10)
    screen.level(0)
    screen.fill()
    screen.rect(x-w/2,y,w,10)
    screen.level(15)
    screen.stroke()
    screen.move(x,y+7)
    screen.level(10)
    screen.text_center(show_message_text)
    if show_message_progress>0 then
      screen.update()
      screen.blend_mode(13)
      screen.rect(x-w/2,y,w*(show_message_progress/100),9)
      screen.level(10)
      screen.fill()
      screen.blend_mode(0)
    end
  end
  screen.update()
end
