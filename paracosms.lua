-- paracosms
--
-- E1 select sample
-- K1+E1 select running sample
--
-- K2 selects parameters
-- E2/E3 modulate parameter
-- K1+E2/E3 modulate more
--
-- K3 start/stops sample
-- (hold length = fade)
-- K1+K3 primes recording
-- (when primed, starts)

viewwave_=include("lib/viewwave")
turntable_=include("lib/turntable")
grid_=include("lib/ggrid")
lattice_=require("lattice")

engine.name="Paracosms"
dat={percent_loaded=0,tt={},files_to_load={},recording=false,recording_primed=false}
dat.rows={
  "/home/we/dust/audio/paracosms/row1",
  "/home/we/dust/audio/paracosms/row2",
  "/home/we/dust/audio/paracosms/row3",
  "/home/we/dust/audio/paracosms/row4",
  "/home/we/dust/audio/paracosms/row5",
  "/home/we/dust/audio/paracosms/row6",
  "/home/we/dust/audio/paracosms/row7",
}

global_startup=false
debounce_fn={}
local shift=false
local ui_page=1
local enc_func={}
-- page 1
table.insert(enc_func,{
  {function(d) delta_ti(d) end},
  {function(d) params:delta(dat.ti.."rate",d) end,function() return "rate: "..params:string(dat.ti.."rate") end},
  {function(d) params:delta(dat.ti.."amp",d) end,function() return params:string(dat.ti.."amp") end},
  {function(d) delta_ti(d,true) end},
  {function(d) params:delta(dat.ti.."offset",d) end,function() return "offset:"..params:string(dat.ti.."offset") end},
  {function(d) params:delta(dat.ti.."amp",d) end,function() return params:string(dat.ti.."amp") end},
})
-- page 2
table.insert(enc_func,{
  {function(d) delta_ti(d) end},
  {function(d) params:delta(dat.ti.."tsSeconds",d) end,function() return "window "..params:string(dat.ti.."tsSeconds") end},
  {function(d) params:delta(dat.ti.."tsSlow",d) end,function() return "slow "..params:string(dat.ti.."tsSlow") end},
  {function(d) delta_ti(d,true) end},
  {function(d) params:delta(dat.ti.."ts",d) end,function() return "timestretch "..(params:get(dat.ti.."ts")>0 and "on" or "off") end},
  {function(d) end},
})
-- page 1
table.insert(enc_func,{
  {function(d) delta_ti(d) end},
  {function(d) params:delta(dat.ti.."sampleStart",d) end,function() return "start: "..params:string(dat.ti.."sampleStart") end},
  {function(d) params:delta(dat.ti.."sampleEnd",d) end,function() return "end: "..params:string(dat.ti.."sampleEnd") end},
  {function(d) delta_ti(d,true) end},
  {function(d) params:delta(dat.ti.."oneshot",d) end,function() return "mode: "..params:string(dat.ti.."oneshot") end},
  {function(d) end},
})

function find_files(folder)
  os.execute("find "..folder.."* -print -type f -name '*.flac' | grep 'wav\\|flac' > /tmp/foo")
  os.execute("find "..folder.."* -print -type f -name '*.wav' | grep 'wav\\|flac' >> /tmp/foo")
  os.execute("cat /tmp/foo | sort | uniq > /tmp/files")
  return lines_from("/tmp/files")
end

function lines_from(file)
  if not util.file_exists(file) then return {} end
  local lines={}
  for line in io.lines(file) do
    lines[#lines+1]=line
  end
  table.sort(lines)
  tab.print(lines)
  return lines
end

function shuffle(tbl)
  for i=#tbl,2,-1 do
    local j=math.random(i)
    tbl[i],tbl[j]=tbl[j],tbl[i]
  end
end

function init()
  -- make sure cache directory exists
  os.execute("mkdir -p /home/we/dust/data/paracosms/cache")
  os.execute("mkdir -p /home/we/dust/audio/paracosms/recordings")
  for i=1,8 do
    os.execute("mkdir -p /home/we/dust/audio/paracosms/row"..i)
  end
  -- setup parameters
  params:add_separator("globals")
  params:add_number("record_threshold","rec threshold (dB)",-96,0,-50)
  params:add_number("record_crossfade","rec xfade (1/16th beat)",1,64,16)
  params:add_separator("samples")

  -- collect which files
  for row,folder in ipairs(dat.rows) do
    local possible_files=find_files(folder)
    for col,fname in ipairs(possible_files) do
      table.insert(dat.files_to_load,{fname=fname,id=(row-1)*16+col})
      if i==16 then
        break
      end
    end
  end

  -- grid
  g_=grid_:new()

  -- osc
  local recording_id=0
  osc_fun={
    trigger=function(args)
      print("triggered "..args[1])
    end,
    recording=function(args)
      dat.recording=true
      local recording_id=tonumber(args[1])
      if recording_id~=nil then show_message("recording track "..recording_id) end
    end,
    progress=function(args)
      show_message(string.format("recording track %d: %2.0f%%",recording_id,tonumber(args[1])))
      show_progress(tonumber(args[1]))
    end,
    recorded=function(args)
      dat.recording=false
      dat.recording_primed=false
      local id=tonumber(args[1])
      local filename=args[2]
      if id~=nil and filename~=nil then
        show_progress(100)
        show_message("recorded track "..id)
        params:set(id.."file",filename)
        dat.ti=id
      end
    end,
    ready=function(args)
      local id=args[1]
      if dat~=nil and dat.tt[id]~=nil then
        dat.tt[id]:oscdata("ready",args[2])
      end
    end,
    data=function(args) -- data from the synth
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
  }
  osc.event=function(path,args,from)
    if osc_fun[path]~=nil then osc_fun[path](args) else
      print("osc.event: "..path.."?")
    end
  end

  clock.run(function()
    while true do
      if #dat.files_to_load>1 and dat.percent_loaded<99.9 then
        local inc=100.0/(#dat.files_to_load*2)
        dat.percent_loaded=0
        for i=1,112 do
          v=dat.tt[i]
          if v~=nil then
            dat.percent_loaded=dat.percent_loaded+((v.loaded_file and v.retuned) and inc or 0)
            dat.percent_loaded=dat.percent_loaded+((v.loaded_file and v.retuned and v.ready) and inc or 0)
          end
        end
        show_message(string.format("%2.1f%% loaded... ",dat.percent_loaded),0.5)
        show_progress(dat.percent_loaded)
      end
      clock.sleep(1/10)
      redraw()
      for k,v in pairs(debounce_fn) do
        if v[1]>0 then
          debounce_fn[k][1]=debounce_fn[k][1]-1
          if debounce_fn[k][1]==0 then
            debounce_fn[k][2]()
            debounce_fn[k]=nil
          end
        end
      end
    end
  end)

  -- initialize the dat turntables
  dat.seed=18
  dat.ti=1
  dat.tt={}
  dat.percent_loaded=0
  math.randomseed(dat.seed)
  for i=1,112 do
    table.insert(dat.tt,turntable_:new{id=i})
  end

  -- load in hardcoded files
  clock.run(function()
    for row,folder in ipairs(dat.rows) do
      local possible_files=find_files(folder)
      -- shuffle(possible_files)
      for col,file in ipairs(possible_files) do
        local id=(row-1)*16+col
        params:set(id.."file",file)
        clock.sleep(0.05)
      end
    end
    clock.sleep(1)
    startup(true)
    params:bang()
    startup(false)
  end)

  -- initialize lattice
  lattice=lattice_:new()
  local beat=0
  pattern_qn=lattice:new_pattern{
    action=function(v)
      beat=beat+1
    end,
    division=1/4,
  }
  lattice:start()
  reset()
end

function reset()
  engine.resetPhase()
  lattice:hard_restart()
end

function startup(on)
  engine.startup(on and 1 or 0)
  global_startup=on
end

function switch_view(id)
  if id>#dat.tt or id==dat.ti then
    do return end
  end
  dat.ti=id
  engine.watch(id)
end

function engine_reset()
  engine.reset()
end

function delta_page(d)
  ui_page=util.wrap(ui_page+d,1,#enc_func)
end

function delta_ti(d,is_playing)
  if is_playing then
    local available_ti={}
    for i,v in ipairs(dat.tt) do
      if v:is_playing() then
        table.insert(available_ti,i)
      end
    end
    if next(available_ti)==nil then
      do return end
    end
    -- find the closest index for dat.ti
    local closest={1,10000}
    for i,ti in ipairs(available_ti) do
      if math.abs(ti-dat.ti)<closest[2] then
        closest={i,math.abs(ti-dat.ti)}
      end
    end
    local i=closest[1]
    i=util.wrap(i+d,1,#available_ti)
    dat.ti=available_ti[i]
  else
    -- find only the ones that are ready
    local available_ti={}
    for i,v in ipairs(dat.tt) do
      if v.ready then
        table.insert(available_ti,i)
      end
    end
    if next(available_ti)==nil then
      do return end
    end
    -- find the closest index for dat.ti
    local closest={1,10000}
    for i,ti in ipairs(available_ti) do
      if math.abs(ti-dat.ti)<closest[2] then
        closest={i,math.abs(ti-dat.ti)}
      end
    end
    local i=closest[1]
    i=util.wrap(i+d,1,#available_ti)
    dat.ti=available_ti[i]
    -- dat.ti=util.wrap(dat.ti+d,1,#dat.tt)
  end
end

local hold_beats=0

function key(k,z)
  if k==1 then
    shift=z==1
  elseif k==2 and z==1 then
    delta_page(1)
  elseif shift and k==3 then
    if z==1 then
      params:delta(dat.ti.."record_on",1)
    end
  elseif k==3 and z==1 then
    if params:get(dat.ti.."oneshot")==2 then
      dat.tt[dat.ti]:play()
    else
      hold_beats=clock.get_beats()
    end
  elseif k==3 and z==0 then
    if params:get(dat.ti.."oneshot")==1 then
      params:set(dat.ti.."fadetime",3*clock.get_beat_sec()*(clock.get_beats()-hold_beats))
      params:set(dat.ti.."play",3-params:get(dat.ti.."play"))
    end
  end
end

function enc(k,d)
  enc_func[ui_page][k+(shift and 3 or 0)][1](d)
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
    clock.sleep(seconds or 2.0)
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
  local topleft=dat.tt[dat.ti]:redraw()
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
  -- top left corner
  screen.level(7)
  screen.move(1,7)
  if dat.percent_loaded<99.0 then
  elseif topleft~=nil then
    screen.text(topleft:sub(1,24))
  end

  screen.move(128,7)
  screen.text_right(dat.ti)

  screen.level(5)
  screen.move(128,64)
  if enc_func[ui_page][3+(shift and 3 or 0)][2]~=nil then
    screen.text_right(enc_func[ui_page][3+(shift and 3 or 0)][2]())
  end

  screen.move(0,64)
  if enc_func[ui_page][2+(shift and 3 or 0)][2]~=nil then
    screen.text(enc_func[ui_page][2+(shift and 3 or 0)][2]())
  end

  screen.update()
end
