if not string.find(package.cpath,"/home/we/dust/code/paracosms/lib/") then
  package.cpath=package.cpath..";/home/we/dust/code/paracosms/lib/?.so"
end
json=require("cjson")
utils=include("lib/utils")
viewwave_=include("lib/viewwave")
turntable_=include("lib/turntable")
grid_=include("lib/ggrid")
lattice_=require("lattice")
er=require("er")
patterner=include("lib/patterner")
musicutil_=require("musicutil")
tracker_=include("lib/tracker")
manager_=include("lib/manager")
saying=include("lib/saying")

engine.name="Paracosms"
dat={percent_loaded=0,tt={},files_to_load={},playing={},recording=false,recording_primed=false,beat=0,sequencing={}}
dat.rows=blocks
local ignore_transport=0

global_startup=false
debounce_fn={}
local shift=false
local ui_page=1
local enc_func={}
-- page 1
table.insert(enc_func,{
  {function(d) delta_ti(d,true) end},
  {function(d) params:delta("metronome",d) end,function() return "metronome: "..(params:get("metronome")==0 and "off" or params:get("metronome")) end},
  {function(d) params:delta("record_beats",d)end,function() return string.format("%2.3f beats",params:get("record_beats")) end},
  {function(d) delta_ti(d) end},
  {function(d) params:delta(dat.ti.."offset",d)end,function() return "offset: "..params:string(dat.ti.."offset") end},
  {function(d) params:delta(dat.ti.."oneshot",d) end,function() return params:string(dat.ti.."oneshot") end},
})

table.insert(enc_func,{
  {function(d) delta_ti(d,true) end},
  {function(d) params:delta(dat.ti.."amp",d) end,function() return "volume: "..params:string(dat.ti.."amp") end},
  {function(d) params:delta(dat.ti.."amp",d) end},
  {function(d) delta_ti(d) end},
  {function(d) params:delta(dat.ti.."amp_strength",d) end,function()
    return "lfo: "..(params:get(dat.ti.."amp_strength")==0 and "off" or params:string(dat.ti.."amp_strength"))
  end},
  {function(d) params:delta(dat.ti.."amp_period",d) end,function()
    return "period: "..params:string(dat.ti.."amp_period")
  end},
})
-- page 1
table.insert(enc_func,{
  {function(d) delta_ti(d,true) end},
  {function(d) params:delta(dat.ti.."pan",d) end,function() return "pan: "..params:string(dat.ti.."pan") end},
  {function(d) params:delta(dat.ti.."pan",d) end},
  {function(d) delta_ti(d) end},
  {function(d) params:delta(dat.ti.."pan_strength",d) end,function()
    return "lfo: "..(params:get(dat.ti.."pan_strength")==0 and "off" or params:string(dat.ti.."pan_strength"))
  end},
  {function(d) params:delta(dat.ti.."pan_period",d) end,function()
    return "period: "..params:string(dat.ti.."pan_period")
  end},
})
-- page 3
table.insert(enc_func,{
  {function(d) delta_ti(d,true) end},
  {function(d) params:delta(dat.ti.."lpf",d) end,function() return "lpf: "..params:string(dat.ti.."lpf") end},
  {function(d) params:delta(dat.ti.."lpfqr",d) end,function() return "1/q: "..params:string(dat.ti.."lpfqr") end},
  {function(d) delta_ti(d) end},
  {function(d) params:delta(dat.ti.."hpf",d) end,function() return "hpf: "..params:string(dat.ti.."hpf") end},
  {function(d) params:delta(dat.ti.."hpfqr",d) end,function() return "1/q: "..params:string(dat.ti.."hpfqr") end},
})
-- page 3
table.insert(enc_func,{
  {function(d) delta_ti(d,true) end},
  {function(d) params:delta(dat.ti.."sampleStart",d) end,function() return "start: "..params:string(dat.ti.."sampleStart") end},
  {function(d) params:delta(dat.ti.."sampleEnd",d) end,function() return "end: "..params:string(dat.ti.."sampleEnd") end},
  {function(d) delta_ti(d) end},
  {function(d) params:delta(dat.ti.."oneshot",d) end,function() return "mode: "..params:string(dat.ti.."oneshot") end},
  {function(d) params:delta(dat.ti.."offset",d) end,function() return "offset:"..params:string(dat.ti.."offset") end},
})
-- page 2
table.insert(enc_func,{
  {function(d) delta_ti(d,true) end},
  {function(d) params:delta(dat.ti.."tsSeconds",d) end,function() return "window "..params:string(dat.ti.."tsSeconds") end},
  {function(d) params:delta(dat.ti.."tsSlow",d) end,function() return "slow "..params:string(dat.ti.."tsSlow") end},
  {function(d) delta_ti(d) end},
  {function(d) params:delta(dat.ti.."ts",d) end,function() return "timestretch "..(params:get(dat.ti.."ts")>0 and "on" or "off") end},
  {function(d) end},
})
-- page 2
table.insert(enc_func,{
  {function(d) delta_ti(d,true) end},
  {function(d) params:delta(dat.ti.."gating_amt",d) end,function() return "gate: "..(params:get(dat.ti.."gating_amt")==0 and "off" or params:string(dat.ti.."gating_amt")) end},
  {function(d) params:delta(dat.ti.."gating_option",d) end,function() return params:string(dat.ti.."gating_option") end},
  {function(d) delta_ti(d) end},
  {function(d) params:delta(dat.ti.."gating_strength",d) end,function()
    return "lfo: "..(params:get(dat.ti.."gating_strength")==0 and "off" or params:string(dat.ti.."gating_strength"))
  end},
  {function(d) params:delta(dat.ti.."gating_period",d) end,function()
    return "period: "..params:string(dat.ti.."gating_period")
  end},
})
-- page 2
table.insert(enc_func,{
  {function(d) delta_ti(d,true) end},
  {function(d) params:delta(dat.ti.."stutter_handle",d) end,function() return "stutter "..(params:get(dat.ti.."stutter_handle")>5 and "on" or "off") end},
  {function(d) end},
  {function(d) delta_ti(d) end},
  {function(d) params:delta(dat.ti.."stutter_length",d) end,function() return "length "..params:string(dat.ti.."stutter_length") end},
  {function(d) params:delta(dat.ti.."stutter_repeats",d) end,function() return "repeats "..params:string(dat.ti.."stutter_repeats") end},
})
-- page 5
table.insert(enc_func,{
  {function(d) delta_ti(d,true) end},
  {function(d) params:delta(dat.ti.."send_main",d) end,function() return "main: "..params:string(dat.ti.."send_main") end},
  {function(d) params:delta(dat.ti.."send_reverb",d) end,function() return "greyhole: "..params:string(dat.ti.."send_reverb") end},
  {function(d) delta_ti(d) end},
  {function(d) params:delta(dat.ti.."send_tape",d) end,function() return "tapedeck: "..params:string(dat.ti.."send_tape") end},
  {function(d) params:delta(dat.ti.."send_grains",d) end,function() return "grains: "..params:string(dat.ti.."send_grains") end},
})
-- page 4
table.insert(enc_func,{
  {function(d) delta_ti(d,true) end},
  {function(d) params:delta(dat.ti.."sequencer",d) end,function() return "sequencer: "..params:string(dat.ti.."sequencer") end},
  {function(d) params:delta(dat.ti.."k",d) end,function() return "k: "..params:string(dat.ti.."k") end},
  {function(d) delta_ti(d) end},
  {function(d) params:delta(dat.ti.."n",d) end,function() return "n: "..params:string(dat.ti.."n") end},
  {function(d) params:delta(dat.ti.."w",d) end,function() return "w: "..params:string(dat.ti.."w") end},
})

function find_files(folder)
  -- print(folder)
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
  return lines
end

function shuffle(tbl)
  for i=#tbl,2,-1 do
    local j=math.random(i)
    tbl[i],tbl[j]=tbl[j],tbl[i]
  end
end

function init()
  original_monitor_level=params:get("monitor_level")
  params:set("monitor_level",-96)
  norns.enc.sens(1,7)

  if substance~=nil then
    substance()
  end

  -- globals
  global_rec_queue={}
  global_divisions={1,1/2,1/3,1/4,1/6,1/8,1/12,1/16,1/24,1/32,1/48,1/64}
  global_divisions_string={"1","1/2","1/2T","1/4","1/4T","1/8","1/8T","1/16","1/16T","1/32","1/32T","1/64"}
  global_reset_needed=0

  -- grid options
  params:add_group("GRID",1)
  params:add_option("grid_touch","toggle press",{"short & long","only short"})
  -- crow
  params:add_group("CROW",8)
  for j=1,2 do
    local i=(j-1)*2+2
    params:add_control(i.."crow_attack",string.format("crow %d attack",i),controlspec.new(0.01,4,'lin',0.01,0.2,'s',0.01/3.99))
    params:add_control(i.."crow_sustain",string.format("crow %d sustain",i),controlspec.new(0,10,'lin',0.1,7,'volts',0.1/10))
    params:add_control(i.."crow_decay",string.format("crow %d decay",i),controlspec.new(0.01,4,'lin',0.01,0.5,'s',0.01/3.99))
    params:add_control(i.."crow_release",string.format("crow %d release",i),controlspec.new(0.01,4,'lin',0.01,0.2,'s',0.01/3.99))
    for _,v in ipairs({"attack","sustain","decay","release"}) do
      params:set_action(i.."crow_"..v,function(x)
        debounce_fn[i.."crow"]={
          5,function()
            crow.output[i].action=string.format("adsr(%3.3f,%3.3f,%3.3f,%3.3f,'linear')",
            params:get(i.."crow_attack"),params:get(i.."crow_sustain"),params:get(i.."crow_decay"),params:get(i.."crow_release"))
          end,
        }
      end)
    end
  end

  -- midi
  midi_device={}
  midi_device_list={}
  for i,dev in pairs(midi.devices) do
    if dev.port~=nil then
      local connection=midi.connect(dev.port)
      local name=string.lower(dev.name).." "..i
      print("adding "..name.." as midi device")
      table.insert(midi_device_list,name)
      table.insert(midi_device,{
        name=name,
        note_on=function(id_,note,vel,ch) connection:note_on(note,vel,ch) end,
        note_off=function(id_,note,vel,ch) connection:note_off(note,vel,ch) end,
      })
      connection.event=function(data)
        local msg=midi.to_msg(data)
        if msg.type=="clock" then
          do return end
        end
        if msg.type=='start' or msg.type=='continue' then
          -- OP-1 fix for transport
          reset()
        elseif msg.type=="stop" then
        elseif msg.type=="note_on" then
        end
      end
    end
  end

  -- make sure cache directory exists
  os.execute("mkdir -p /home/we/dust/data/paracosms/cache")
  os.execute("mkdir -p /home/we/dust/audio/paracosms/recordings")
  local first_time=not util.file_exists("/home/we/dust/audio/paracosms/row1")
  for i=1,8 do
    os.execute("mkdir -p /home/we/dust/audio/paracosms/row"..i)
  end
  if first_time then
    dat.rows={
      {folder="/home/we/dust/code/paracosms/lib/row1",params={amp=0.5,pan=math.random(-30,30)/100}},
      {folder="/home/we/dust/audio/x0x/909",params={oneshot=2,attack=0.002}},
      {folder="/home/we/dust/audio/paracosms/row3"},
      {folder="/home/we/dust/audio/paracosms/row4"},
      {folder="/home/we/dust/audio/paracosms/row5"},
      {folder="/home/we/dust/audio/paracosms/row6"},
      {folder="/home/we/dust/audio/paracosms/row7"},
    }
    params:set("clock_tempo",120)
    clock.run(function()
      show_message("WELCOME TO PARACOSMS",3)
      clock.sleep(3)
      show_message("E1 TO EXPLORE SAMPLES")
      clock.sleep(2)
      show_message("K3 TO PLAY")
      clock.sleep(2)
      show_message("K1+K3 TO RECORD")
      clock.sleep(2)
      show_message("K2/K1+K2 TO CYCLE PARAM")
      clock.sleep(2)
      show_message("(K1+)E2/E3 CHANGE PARAM")
    end)
  end

  -- setup effects parameters
  params_audioin()
  params_greyhole()
  params_grains()
  params_tapedeck()
  params_sidechain()

  -- setup parameters
  params:add_group("RECORDING",7)
  params:add_control("record_beats","recording length",controlspec.new(1/4,128,'lin',1/4,8.0,'beats',(1/4)/(128-0.25)))
  params:add_number("record_threshold","rec threshold (dB)",-96,0,-40)
  params:add_option("record_firstbeat","rec start to beat 1",{"no","yes"},2)
  params:add_number("record_crossfade","rec xfade (1/16th beat)",1,64,8)
  params:add_number("record_predelay","rec latency (ms)",0,100,10)
  params:add_option("record_over","record onto",{"new","existing"},2)
  params:add_number("metronome","metronome",0,100,0)
  params:set_action("metronome",function(x)
    engine.metronome(clock.get_tempo(),x,0.2)
  end)
  -- tracker options
  manager=manager_:new()
  params:add_group("TRACKER",2)
  params:add_file("tracker_file","tracker file",_path.data)
  params:set_action("tracker_file",function(x)
    print(x)
    if util.file_exists(x) and string.sub(x,-1)~="/" then
      manager:load(x)
    end
  end)
  params:add_option("output_all","output all",manager.output_list)
  params:set_action("output_all",function(x)
    for i,_ in ipairs(manager.tracks) do
      params:set(i.."output",x)
    end
  end)

  -- cut fade
  params:add_control("cut_fade","CUT XFADE",controlspec.new(0,500,'lin',1,100,'ms',1/500))
  params:set_action("cut_fade",function(x)
    engine.cut_fade(x/1000)
  end)

  params:add_separator("samples")
  params:add_number("sel","selected sample",1,112,1)
  params:set_action("sel",function(x)
    dat.ti=x
    for i=1,112 do
      if x==i then
        dat.tt[i]:show()
      else
        dat.tt[i]:hide()
      end
    end
    _menu.rebuild_params()
  end)

  -- collect which files
  for row,v in ipairs(dat.rows) do
    local folder=v.folder
    local possible_files=find_files(folder)
    for col,fname in ipairs(possible_files) do
      table.insert(dat.files_to_load,{fname=fname,id=(row-1)*16+col})
      if col==16 then
        break
      end
    end
  end

  -- grid
  g_=grid_:new()

  -- osc
  osc_fun={
    -- phase=function(args)
    --   local phase_seconds=tonumber(args[1])
    --   local total_time=params:get("record_beats")*clock.get_beat_sec()
    --   while phase_seconds>total_time do
    --     phase_seconds=phase_seconds-total_time
    --   end
    --   dat.phase=phase_seconds/total_time
    -- end,
    progress=function(args)
      local id=tonumber(args[1])
      show_message(string.format("recording cosm %d: %2.0f%%",id,tonumber(args[2])))
      show_progress(tonumber(args[2]))
    end,
    recorded=function(args)
      local id=tonumber(args[1])
      local filename=args[2]
      if id~=nil and filename~=nil then
        print("osc_fun: recorded",id,filename)
        show_progress(100)
        show_message("recorded cosm "..id)
        dat.tt[id]:recording_finish(filename)
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

  local sleep_time=clock.get_beat_sec()/16
  while sleep_time<0.1 do
    sleep_time=sleep_time+clock.get_beat_sec()/16
  end
  clock.run(function()
    while true do
      if #dat.files_to_load>1 and dat.percent_loaded<99.9 then
        local inc=100.0/(#dat.files_to_load*2)
        if inc~=nil then
          dat.percent_loaded=0
          for i=1,112 do
            v=dat.tt[i]
            if v~=nil and v.loaded_file~=nil then
              if v.retuned then
                dat.percent_loaded=dat.percent_loaded+inc
                if v.ready then
                  dat.percent_loaded=dat.percent_loaded+inc
                end
              end
            end
          end
          if dat.percent_loaded>=0 and dat.percent_loaded<=100 then
            if not first_time then
              show_message(string.format("%2.1f%% loaded... ",dat.percent_loaded),0.5)
            end
            show_progress(dat.percent_loaded)
          end
        end
      end
      clock.sleep(sleep_time)
      redraw()
      debounce_params()
    end
  end)

  -- initialize the dat turntables
  dat.seed=18
  params:set("sel",1)
  dat.tt={}
  dat.ti=1
  dat.percent_loaded=#dat.files_to_load==0 and 100 or 0
  math.randomseed(dat.seed)
  for i=1,112 do
    table.insert(dat.tt,turntable_:new{id=i})
  end

  -- setup keyboard manager
  manager:init()
  params.action_write=function(filename,name)
    print("write",filename,name)
    manager:save(filename..".txt")

    -- save all the patterns
    local data={patterns={},patterns_grid={}}
    for i,v in ipairs(dat.tt) do
      table.insert(data.patterns,v.sample_pattern:dump())
    end
    for i,v in ipairs(g_.patterns) do
      table.insert(data.patterns_grid,v:dump())
    end

    filename=filename..".json"
    local file=io.open(filename,"w+")
    io.output(file)
    io.write(json.encode(data))
    io.close(file)
  end

  params.action_read=function(filename,silent)
    print("read",filename,silent)
    manager:load(filename..".txt")
    -- turn off all the sounds
    for i=1,112 do
      params:set(i.."play",0)
    end

    -- load all the patterns
    filename=filename..".json"
    if not util.file_exists(filename) then
      do return end
    end
    local f=io.open(filename,"rb")
    local content=f:read("*all")
    f:close()
    if content==nil then
      do return end
    end
    local data=json.decode(content)
    for i,pattern in ipairs(data.patterns) do
      dat.tt[i].sample_pattern:load(pattern)
    end
    for i,pattern in ipairs(data.patterns_grid) do
      g_.patterns[i]:load(pattern)
    end
  end

  -- initialize hardcoded parameters
  for row=1,7 do
    for col=1,16 do
      if dat.rows[row].params~=nil then
        for pram,val in pairs(dat.rows[row].params) do
          local id=(row-1)*16+col
          --print("setting ",id,pram,val)
          params:set(id..pram,val)
        end
      end
    end
  end

  -- -- load in hardcoded files
  clock.run(function()
    for row,v in ipairs(dat.rows) do
      local folder=v.folder
      local possible_files=find_files(folder)
      for col,file in ipairs(possible_files) do
        local id=(row-1)*16+col
        params:set(id.."file",file)
        clock.sleep(0.01)
        if col==16 then
          break
        end
      end
    end
    clock.sleep(1)
    startup(true)
    -- params:default()
    params:bang()
    startup(false)

    -- re-initialize after-fx parameters
    for row=1,7 do
      for col=1,16 do
        if dat.rows[row].params~=nil then
          for pram,val in pairs(dat.rows[row].params) do
            local id=(row-1)*16+col
            if pram=="oneshot" then
              -- print("setting ",id,pram,val)
              params:set(id..pram,val)
            end
          end
        end
      end
    end
    -- make sure we are on the actual first if the first row has nothing
    show_message(saying.get(),2)
    -- enc(1,1)
    -- enc(1,-1)
    -- clock.sleep(0.2)
    clock.sleep(0.2)
    reset()
    global_reset_needed=0
    if style~=nil then
      clock.sleep(1)
      style()
    end
    print([[
 
 ____   ____  ____    ____    __   ___   _____ ___ ___  _____
|    \ /    ||    \  /    |  /  ] /   \ / ___/|   |   |/ ___/
|  o  )  o  ||  D  )|  o  | /  / |     (   \_ | _   _ (   \_ 
|   _/|     ||    / |     |/  /  |  O  |\__  ||  \_/  |\__  |
|  |  |  _  ||    \ |  _  /   \_ |     |/  \ ||   |   |/  \ |
|  |  |  |  ||  .  \|  |  \     ||     |\    ||   |   |\    |
|__|  |__|__||__|\_||__|__|\____| \___/  \___||___|___| \___|
                                                             
  ____     ___   ____  ___    __ __ 
|    \   /  _] /    ||   \  |  |  |
|  D  ) /  [_ |  o  ||    \ |  |  |
|    / |    _]|     ||  D  ||  ~  |
|    \ |   [_ |  _  ||     ||___, |
|  .  \|     ||  |  ||     ||     |
|__|\_||_____||__|__||_____||____/ 
                                   
]])
  end)

  -- initialize lattice
  lattice=lattice_:new()
  dat.beat=0
  pattern_qn=lattice:new_pattern{
    action=function(v)
      if ignore_transport>0 then
        ignore_transport=ignore_transport-1
      end
      dat.beat=dat.beat+1
      -- TODO: make option to change the probability of reset
      if dat.lcm_beat~=nil and dat.lcm_beat>0 then
        if (dat.beat-1)%dat.lcm_beat==0 and global_reset_needed>0 then
          print("resetPhase from lcm beat")
          engine.resetPhase()
        end
      end
      for id,_ in pairs(dat.sequencing) do
        dat.tt[id]:emit(dat.beat)
      end
      for _,v in ipairs(g_.patterns) do
        v:emit(dat.beat)
      end
      for _,v in ipairs(dat.tt) do
        v.sample_pattern:emit(dat.beat)
      end
    end,
    division=1/16,
  }
  -- setup sequencer tracker
  beat_num={}
  for divisioni,division in ipairs(global_divisions) do
    table.insert(beat_num,0)
    lattice:new_pattern{
      action=function(t)
        beat_num[divisioni]=beat_num[divisioni]+1 -- beat % 16 + 1 => [1,16]
        manager:beat(beat_num[divisioni],divisioni)
      end,
      division=division,
    }
  end

  lattice:start()
end

function cleanup()
  params:set("monitor_level",original_monitor_level)
end

function clock.transport.start()
  if ignore_transport>0 then
    do return end
  end
  reset()
end

function debounce_params()
  local count=0
  for k,v in pairs(debounce_fn) do
    if v~=nil and v[1]~=nil and v[1]>0 then
      count=count+1
      -- for some reason you can't do too many
      -- at once without triggering a clock error
      if count>100 then
        do return end
      end
      v[1]=v[1]-1
      if v[1]~=nil and v[1]==0 then
        if v[2]~=nil then
          local status,err=pcall(v[2])
          if err~=nil then
            print(status,err)
          end
        end
        debounce_fn[k]=nil
      else
        debounce_fn[k]=v
      end
    end
  end
end

function set_gate_sequence(id,numdash)
  local vals={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
  local isminus=false
  local i=1
  for c in numdash:gmatch"." do
    if c=="-" then
      isminus=true
    else
      if not isminus and i<33 then
        vals[i]=tonumber(c)*2
      end
      i=i+tonumber(c)
      isminus=false
    end
  end
  engine.set_gating_sequence(id,
    vals[1],vals[2],vals[3],vals[4],vals[5],vals[6],vals[7],vals[8],
    vals[9],vals[10],vals[11],vals[12],vals[13],vals[14],vals[15],vals[16],
    vals[17],vals[18],vals[19],vals[20],vals[21],vals[22],vals[23],vals[24],
  vals[25],vals[26],vals[27],vals[28],vals[29],vals[30],vals[31],vals[32])
end

function params_audioin()
  local params_menu={
    {id="amp",name="amp",min=0,max=2,exp=false,div=0.01,default=1.0},
    {id="pan",name="pan",min=-1,max=1,exp=false,div=0.01,default=-1,response=1},
    {id="hpf",name="hpf",min=10,max=2000,exp=true,div=5,default=10},
    {id="hpfqr",name="hpf qr",min=0.05,max=0.99,exp=false,div=0.01,default=0.61},
    {id="lpf",name="lpf",min=200,max=20000,exp=true,div=100,default=18000},
    {id="lpfqr",name="lpf qr",min=0.05,max=0.99,exp=false,div=0.01,default=0.61},
    {id="send_main",name="main send",min=0,max=1,exp=false,div=0.01,default=1.0,response=1,formatter=function(param) return string.format("%2.0f%%",param:get()*100) end},
    {id="send_tape",name="tapedeck send",min=0,max=1,exp=false,div=0.01,default=0.0,response=1,formatter=function(param) return string.format("%2.0f%%",param:get()*100) end},
    {id="send_grains",name="grains send",min=0,max=1,exp=false,div=0.01,default=0.0,response=1,formatter=function(param) return string.format("%2.0f%%",param:get()*100) end},
    {id="send_reverb",name="greyhole send",min=0,max=1,exp=false,div=0.01,default=0.0,response=1,formatter=function(param) return string.format("%2.0f%%",param:get()*100) end},
    {id="compressing",name="compressing",min=0,max=1,exp=false,div=1,default=0.0,response=1,formatter=function(param) return param:get()==1 and "yes" or "no" end},
    {id="compressible",name="compressible",min=0,max=1,exp=false,div=1,default=0.0,response=1,formatter=function(param) return param:get()==1 and "yes" or "no" end},
  }
  params:add_group("AUDIO IN",#params_menu*2+1)
  params:add_option("audioin_linked","audio in",{"mono+mono","stereo"},2)
  local lrs={"L","R"}
  for _,pram in ipairs(params_menu) do
    for lri,lr in ipairs(lrs) do
      params:add{
        type="control",
        id="audioin"..pram.id..lr,
        name=pram.name.." "..lr,
        controlspec=controlspec.new(pram.min,pram.max,pram.exp and "exp" or "lin",pram.div,pram.default,pram.unit or "",pram.div/(pram.max-pram.min)),
        formatter=pram.formatter,
      }
      params:set_action("audioin"..pram.id..lr,function(v)
        engine.audioin_set(lr,pram.id,v)
        if params:get("audioin_linked")==2 then
          if pram.id~="pan" then
            params:set("audioin"..pram.id..lrs[3-lri],v,true)
            engine.audioin_set(lrs[3-lri],pram.id,v)
          else
            params:set("audioin"..pram.id..lrs[3-lri],-v,true)
            engine.audioin_set(lrs[3-lri],pram.id,-1*v)
          end
        end
      end)
    end
  end
  params:set("audioinpanR",1)
end

function params_sidechain()
  local params_menu={
    {id="sidechain_mult",name="amount",min=0,max=8,exp=false,div=0.1,default=2.0},
    {id="compress_thresh",name="threshold",min=0,max=1,exp=false,div=0.01,default=0.1},
    {id="compress_level",name="level",min=0,max=1,exp=false,div=0.01,default=0.1},
    {id="compress_attack",name="attack",min=0,max=1,exp=false,div=0.001,default=0.01,formatter=function(param) return (param:get()*1000).." ms" end},
    {id="compress_release",name="release",min=0,max=2,exp=false,div=0.01,default=0.2,formatter=function(param) return (param:get()*1000).." ms" end},
  }
  params:add_group("SIDECHAIN",#params_menu)
  for _,pram in ipairs(params_menu) do
    params:add{
      type="control",
      id=pram.id,
      name=pram.name,
      controlspec=controlspec.new(pram.min,pram.max,pram.exp and "exp" or "lin",pram.div,pram.default,pram.unit or "",pram.div/(pram.max-pram.min)),
      formatter=pram.formatter,
    }
    params:set_action(pram.id,function(v)
      engine.main_set(pram.id,v)
      engine.tapedeck_set(pram.id,v)
      engine.grains_set(pram.id,v)
      engine.greyhole_set(pram.id,v)
    end)
  end
end

function params_tapedeck()
  local params_menu={
    {id="amp",name="amp",min=0,max=2,exp=false,div=0.01,default=1.0},
    {id="tape_wet",name="tape wet/dry",min=0,max=1,exp=false,div=0.01,default=0.8},
    {id="tape_bias",name="tape bias",min=0,max=1,exp=false,div=0.01,default=0.7},
    {id="saturation",name="tape saturation",min=0,max=1,exp=false,div=0.01,default=0.9},
    {id="drive",name="tape drive",min=0,max=1,exp=false,div=0.01,default=0.65},
    {id="dist_wet",name="dist wet/dry",min=0,max=1,exp=false,div=0.01,default=0.05},
    {id="drivegain",name="dist drive",min=0,max=1,exp=false,div=0.01,default=0.4},
    {id="dist_bias",name="dist bias",min=0,max=1,exp=false,div=0.01,default=0.2},
    {id="lowgain",name="dist low gain",min=0,max=1,exp=false,div=0.01,default=0.1},
    {id="highgain",name="dist high gain",min=0,max=1,exp=false,div=0.01,default=0.1},
    {id="shelvingfreq",name="dist shelf freq",min=50,max=2000,exp=true,div=5,default=600},
    {id="wowflu",name="wow&flu",min=0,max=1,exp=false,div=1,default=0.0,formatter=function(param) return param:get()>0 and "on" or "off" end},
    {id="wobble_rpm",name="wow rpm",min=1,max=120,exp=false,div=1,default=33},
    {id="wobble_amp",name="wow amp",min=0,max=1,exp=false,div=0.01,default=0.05},
    {id="flutter_amp",name="flutter amp",min=0,max=1,exp=false,div=0.01,default=0.03},
    {id="flutter_fixedfreq",name="flutter freq",min=0.1,max=12,exp=false,div=0.1,default=6},
    {id="flutter_variationfreq",name="flutter var freq",min=0.1,max=12,exp=false,div=0.1,default=2},
    {id="hpf",name="hpf",min=10,max=2000,exp=true,div=5,default=10},
    {id="hpfqr",name="hpf qr",min=0.05,max=0.99,exp=false,div=0.01,default=0.61},
    {id="lpf",name="lpf",min=200,max=20000,exp=true,div=100,default=18000},
    {id="lpfqr",name="lpf qr",min=0.05,max=0.99,exp=false,div=0.01,default=0.61},
  }
  params:add_group("TAPEDECK",1+#params_menu)
  params:add_option("tapedeck_activate","include effect",{"no","yes"},1)
  params:set_action("tapedeck_activate",function(v)
    engine.tapedeck_toggle(v-1)
  end)
  for _,pram in ipairs(params_menu) do
    params:add{
      type="control",
      id="tape_"..pram.id,
      name=pram.name,
      controlspec=controlspec.new(pram.min,pram.max,pram.exp and "exp" or "lin",pram.div,pram.default,pram.unit or "",pram.div/(pram.max-pram.min)),
      formatter=pram.formatter,
    }
    params:set_action("tape_"..pram.id,function(v)
      engine.tapedeck_set(pram.id,v)
    end)
  end
end

function params_greyhole()
  local params_menu={
    {id="amp",name="amp",min=0,max=2,exp=false,div=0.01,default=1.0},
    {id="delayTime",name="delay time",min=0.01,max=8,exp=false,div=0.01,default=2.0,unit="s"},
    {id="damp",name="damping",min=0,max=2,exp=false,div=0.01,default=0.0},
    {id="size",name="size",min=0,max=2,exp=false,div=0.01,default=1.0},
    {id="diff",name="diffuse",min=0,max=2,exp=false,div=0.01,default=0.707},
    {id="feedback",name="feedback",min=0,max=1.0,exp=false,div=0.01,default=0.4},
    {id="modDepth",name="mod depth",min=0,max=2,exp=false,div=0.01,default=0.1},
    {id="modFreq",name="mod freq",min=0.1,max=10,exp=false,div=0.1,default=2.0},
  }
  params:add_group("GREYHOLE",1+#params_menu)
  params:add_option("greyhole_activate","include effect",{"no","yes"},1)
  params:set_action("greyhole_activate",function(v)
    engine.greyhole_toggle(v-1)
  end)
  for _,pram in ipairs(params_menu) do
    params:add{
      type="control",
      id="greyhole_"..pram.id,
      name=pram.name,
      controlspec=controlspec.new(pram.min,pram.max,pram.exp and "exp" or "lin",pram.div,pram.default,pram.unit or "",pram.div/(pram.max-pram.min)),
      formatter=pram.formatter,
    }
    params:set_action("greyhole_"..pram.id,function(v)
      engine.greyhole_set(pram.id,v)
    end)
  end
end

function params_grains()
  local params_menu={
    {id="amp",name="amp",min=0,max=2,exp=false,div=0.01,default=1.0},
    {id="pitMin",name="pit min",min=-48,max=48,exp=false,div=0.1,default=-0.1},
    {id="pitMax",name="pit max",min=-48,max=48,exp=false,div=0.1,default=0.1},
    {id="pitPer",name="pit per",min=0.1,max=180,exp=true,div=0.1,default=math.random(5,30)},
    {id="posMin",name="pos min",min=0,max=1,exp=false,div=0.01,default=0},
    {id="posMax",name="pos max",min=0,max=1,exp=false,div=0.01,default=0.3},
    {id="posPer",name="pos per",min=0.1,max=180,exp=true,div=0.1,default=math.random(2,9)},
    {id="sizeMin",name="size min",min=0,max=1,exp=false,div=0.01,default=0.4},
    {id="sizeMax",name="size max",min=0,max=1,exp=false,div=0.01,default=0.9},
    {id="sizePer",name="size per",min=0.1,max=180,exp=true,div=0.1,default=math.random(300,600)/100},
    {id="densMin",name="dens min",min=0,max=1,exp=false,div=0.01,default=0.33},
    {id="densMax",name="dens max",min=0,max=1,exp=false,div=0.01,default=0.93},
    {id="densPer",name="dens per",min=0.1,max=180,exp=true,div=0.1,default=math.random(50,150)/100},
    {id="texMin",name="tex min",min=0,max=1,exp=false,div=0.01,default=0.3},
    {id="texMax",name="tex max",min=0,max=1,exp=false,div=0.01,default=0.8},
    {id="texPer",name="tex per",min=0.1,max=180,exp=true,div=0.1,default=math.random(100,900)/100},
    {id="drywetMin",name="drywet min",min=0,max=1,exp=false,div=0.01,default=0.5},
    {id="drywetMax",name="drywet max",min=0,max=1,exp=false,div=0.01,default=1.0},
    {id="drywetPer",name="drywet per",min=0.1,max=180,exp=true,div=0.1,default=math.random(5,30)},
    {id="in_gainMin",name="in_gain min",min=0.125,max=8,exp=false,div=0.125/2,default=0.8},
    {id="in_gainMax",name="in_gain max",min=0.125,max=8,exp=false,div=0.125/2,default=1.2},
    {id="in_gainPer",name="in_gain per",min=0.1,max=180,exp=true,div=0.1,default=math.random(5,30)},
    {id="spreadMin",name="spread min",min=0,max=1,exp=false,div=0.01,default=0.3},
    {id="spreadMax",name="spread max",min=0,max=1,exp=false,div=0.01,default=1.0},
    {id="spreadPer",name="spread per",min=0.1,max=180,exp=true,div=0.1,default=math.random(100,900)/100},
    {id="rvbMin",name="rvb min",min=0,max=1,exp=false,div=0.01,default=0.1},
    {id="rvbMax",name="rvb max",min=0,max=1,exp=false,div=0.01,default=0.6},
    {id="rvbPer",name="rvb per",min=0.1,max=180,exp=true,div=0.1,default=math.random(100,900)/100},
    {id="fbMin",name="fb min",min=0,max=1,exp=false,div=0.01,default=0.3},
    {id="fbMax",name="fb max",min=0,max=1,exp=false,div=0.01,default=0.8},
    {id="fbPer",name="fb per",min=0.1,max=180,exp=true,div=0.1,default=math.random(200,400)/100},
    {id="grainMin",name="grain freq min",min=0,max=60,exp=false,div=0.1,default=4},
    {id="grainMax",name="grain freq max",min=0,max=60,exp=false,div=0.1,default=12},
    {id="grainPer",name="grain freq per",min=0.1,max=180,exp=true,div=0.1,default=math.random(5,30)},
  }
  params:add_group("CLOUDS",1+#params_menu)
  params:add_option("grains_activate","include effect",{"no","yes"},1)
  params:set_action("grains_activate",function(v)
    engine.grains_toggle(v-1)
  end)
  for _,pram in ipairs(params_menu) do
    params:add{
      type="control",
      id="grains_"..pram.id,
      name=pram.name,
      controlspec=controlspec.new(pram.min,pram.max,pram.exp and "exp" or "lin",pram.div,pram.default,pram.unit or "",pram.div/(pram.max-pram.min)),
      formatter=pram.formatter,
    }
    params:set_action("grains_"..pram.id,function(v)
      engine.grains_set(pram.id,v)
    end)
  end
end

function reset()
  print("paracosms: resetting")
  dat.beat=0
  for i,_ in ipairs(beat_num) do
    beat_num[i]=0
  end
  engine.resetPhase()
  ignore_transport=30
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
  params:set("sel",id)
  engine.watch(id)
end

function engine_reset()
  engine.reset()
end

function delta_page(d)
  ui_page=util.wrap(ui_page+d,1,#enc_func)
  if ui_page==#enc_func and params:get(dat.ti.."oneshot")==1 then
    -- skip one-shot sequencing menu for loops
    ui_page=util.wrap(ui_page+d,1,#enc_func)
  end
end

function delta_ti(d,is_ready)
  if is_ready then
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
    params:set("sel",available_ti[i])
  else
    params:set("sel",util.wrap(dat.ti+d,1,#dat.tt))
  end
end

local hold_beats=0

function key(k,z)
  if k==1 then
    shift=z==1
  elseif z==1 and k==2 then
    delta_page(shift and-1 or 1)
  elseif shift and k==3 then
    if z==1 then
      if params:get("record_over")==1 and dat.tt[dat.ti].loaded_file~=nil then
        -- try to find a track that is empty
        local j=0
        for i=1,112 do
          if dat.tt[i].loaded_file==nil then
            j=i
            break
          end
        end
        params:set("sel",j>0 and j or dat.ti)
      end
      params:delta(dat.ti.."record_on",1)
    end
  elseif k==3 then
    if z==1 then
      hold_beats=clock.get_beats()
    end

    if params:get(dat.ti.."oneshot")==2 then
      params:set(dat.ti.."play",z)
      if z==0 then
        local hold_time=(clock.get_beats()-hold_beats)*clock.get_beat_sec()
        if hold_time>2.5 then
          params:set(dat.ti.."sequencer",3-params:get(dat.ti.."sequencer"))
        end
      end
    elseif z==0 then
      local hold_time=math.pow((clock.get_beats()-hold_beats)*clock.get_beat_sec()*1.5,2)
      if hold_time<0 or hold_time>100 then
        hold_time=1
      end
      if params:get(dat.ti.."play")==1 then
        params:set(dat.ti.."release",hold_time)
      else
        params:set(dat.ti.."attack",hold_time)
      end
      print(string.format("[%d] %s over %3.2f sec",dat.ti,params:get(dat.ti.."play")==1 and "stop" or "play",hold_time))
      params:set(dat.ti.."play",1-params:get(dat.ti.."play"))
    end
  end
end

function enc(k,d)
  show_manager=false
  enc_func[ui_page][k+(shift and 3 or 0)][1](d)
end

local show_message_text=""
local show_message_progress=0
local show_message_clock=0

function show_progress(val)
  show_message_progress=util.clamp(val,0,100)
end

function show_message(message,seconds)
  seconds=seconds or 2
  show_message_clock=10*seconds
  show_message_text=message
end

show_manager=false
local ctl_code=false
local shift_code=false
function keyboard.code(code,value)
  if value==1 then
    show_manager=true
  end
  if string.find(code,"CTRL") then
    ctl_code=value>0
    do return end
  end
  if string.find(code,"SHIFT") then
    shift_code=value>0
    do return end
  end
  code=ctl_code and "CTRL+"..code or code
  code=shift_code and "SHIFT+"..code or code
  manager:keyboard(code,value)
end

function redraw()
  screen.clear()
  if dat.tt[dat.ti]==nil then
    do return end
  end
  if show_manager then
    manager:redraw()
    draw_message()
  else
    draw_paracosms()
  end
  screen.update()
end

function draw_message()
  if show_message_clock>0 and show_message_text~="" then
    show_message_clock=show_message_clock-1
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
    if show_message_clock==0 then
      show_message_text=""
      show_message_progress=0
    end
  end
end

function draw_paracosms()

  local topleft=dat.tt[dat.ti]:redraw()
  draw_message()
  -- top left corner
  screen.level(7)
  screen.move(1,7)
  if dat.percent_loaded<99.0 then
  elseif topleft~=nil then
    screen.text(topleft:sub(1,24))
  end

  screen.move(128,7)
  screen.text_right(dat.ti)

  if enc_func[ui_page][2][2]~=nil then
    screen.level(shift and 1 or 5)
    screen.move(0,63)
    screen.text(enc_func[ui_page][2][2]())
  end
  if enc_func[ui_page][5][2]~=nil then
    screen.level(shift and 5 or 1)
    screen.move(0,63-8)
    screen.text(enc_func[ui_page][5][2]())
  end

  if enc_func[ui_page][3][2]~=nil then
    screen.level(shift and 1 or 5)
    screen.move(128,63)
    screen.text_right(enc_func[ui_page][3][2]())
  end
  if enc_func[ui_page][6][2]~=nil then
    screen.level(shift and 5 or 1)
    screen.move(128,63-8)
    screen.text_right(enc_func[ui_page][6][2]())
  end

  if params:get("record_firstbeat")==1 then
    local beat=(dat.beat-1)%(params:get("record_beats")*4)
    local x=util.linlin(0,params:get("record_beats")*4,0,128,beat)
    screen.level(beat%4==0 and 15 or 5)
    screen.aa(1)
    local size=2
    if beat%16==0 then
      size=8
    elseif beat%4==0 then
      size=5
    end
    screen.rect(x,10,size,size)
    screen.aa(0)
    screen.fill()
  end
end
