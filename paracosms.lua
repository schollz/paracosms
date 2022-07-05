-- paracosms

viewwave_=include("lib/viewwave")
turntable_=include("lib/turntable")
grid_=include("lib/ggrid")

engine.name="Paracosms"
dat={percent_loaded=0,tt={},files_to_load={}}

dat.folders={
  "/home/we/dust/audio/seamlessloops/pad-synth"
  "/home/we/dust/audio/seamlessloops/drums-ambient"
  "/home/we/dust/audio/seamlessloops/drums-dnb"
  "/home/we/dust/audio/seamlessloops/synth-bass"
  "/home/we/dust/audio/seamlessloops/chords-synth"
  "/home/we/dust/audio/seamlessloops/vocals"
}

function find_files(folder)
  local lines=util.os_capture("find "..folder.." -print -name '*.flac' -o -name '*.wav' | grep 'wav\\|flac' > /tmp/files")
  return lines_from("/tmp/files")
end

function lines_from(file)
  if not util.file_exists(file) then return {} end
  local lines={}
  for line in io.lines(file) do
    lines[#lines+1]=line
  end
  return lines
end

function shuffle(tbl)
  for i=#tbl,2,-1 do
    local j=math.random(i)
    tbl[i],tbl[j]=tbl[j],tbl[i]
  end
end

function initialize()
  dat.seed=1
  dat.ti=1
  dat.tt={}
  dat.percent_loaded=0

  dat.files_to_load={}
  clock.run(function()
    for _,folder in ipairs(dat.folders) do
      local possible_files=lines_from(folder)
      math.randomseed(dat.seed)
      shuffle(possible_files)
      local found=0
      for _,file in ipairs(possible_files) do
        for tempo=clock.get_tempo()-1,clock.get_tempo()+1 do
          if string.find(file,string.format("bpm%d",tempo)) then
            table.insert(dat.files_to_load,file)
            found=found+1
            if found==16 then
              break
            end
          end
        end
        if found==16 then
          break
        end
      end
    end

    for id,file in ipairs(dat.files_to_load) do
      table.insert(dat.tt,turntable_:new{id=id,path=file})
      for j=1,80 do
        clock.sleep(0.05)
        if dat.tt[id].ready then
          break
        end
      end
      -- if id==24 then
      --   break
      -- end
    end

  end)
end
function init()
  tab.print(find_files(dat.folders[1]))
  -- parameters
  for id=1,112 do
    params:add_group("table "..id,2)
    params:add{type='binary',name='play',id=id..'play',behavior='toggle',action=function(v)
      engine.set(id,"amp",v==1 and 1.0 or 0,params:get(id.."fadetime"))
    end}
    params:add_control(id.."fadetime","fade time",controlspec.new(0,64,'lin',0.01,1,'seconds',0.01/64))
  end

  -- grid
  g_=grid_:new()

  -- osc
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
      if dat~=nil and dat.tt[id]~=nil and dat.tt[id].ready then
        g_:light_up(id,val)
      end
      do return end
    end
    if path=="ready" then
      datatype=path
    end
    if dat~=nil and dat.tt[id]~=nil then
      dat.tt[id]:oscdata(datatype,args[2])
    end
  end

  clock.run(function()
    while true do
      if #dat.files_to_load>1 and dat.percent_loaded<100 then
        local inc=100.0/#dat.files_to_load
        dat.percent_loaded=0
        for _,v in ipairs(dat.tt) do
          dat.percent_loaded=dat.percent_loaded+(v.ready and inc or 0)
        end
      end
      clock.sleep(1/10)
      redraw()
    end
  end)

  --initialize()

end

function switch_view(id)
  if id>#dat.tt then
    do return end
  end
  dat.ti=id
  engine.watch(id)
end

function engine_reset()
  engine.reset()
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
  if dat.tt[dat.ti]==nil then
    do return end
  end
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

  if dat.percent_loaded<99.0 then
    screen.move(1,7)
    screen.text(string.format("loaded %2.1f%%",dat.percent_loaded))
  end

  screen.move(128,7)
  screen.text_right(dat.ti)
  screen.update()
end
