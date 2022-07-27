
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

engine.name="Paracosms"
dat={percent_loaded=0,tt={},files_to_load={},playing={},recording=false,recording_primed=false,beat=0,sequencing={}}
dat.rows=blocks

global_startup=false
debounce_fn={}
local shift=false
local ui_page=1
local enc_func={}
-- page 1
table.insert(enc_func,{
  {function(d) delta_ti(d) end},
  {function(d) params:delta("metronome",d) end,function() return "metronome: "..(params:get("metronome")==0 and "off" or params:get("metronome")) end},
  {function(d) params:delta("record_beats",d)end,function() return string.format("%2.3f beats",params:get("record_beats")) end},
  {function(d) delta_ti(d,true) end},
  {function(d) params:delta("record_over",d)end,function() return "K1+K3 record "..params:string("record_over") end},
  {function(d) params:delta(dat.ti.."oneshot",d) end,function() return params:string(dat.ti.."oneshot") end},
})

table.insert(enc_func,{
  {function(d) delta_ti(d) end},
  {function(d) params:delta(dat.ti.."amp",d) end,function() return "volume: "..params:string(dat.ti.."amp") end},
  {function(d) params:delta(dat.ti.."amp",d) end},
  {function(d) delta_ti(d,true) end},
  {function(d) params:delta(dat.ti.."amp_strength",d) end,function()
    return "lfo: "..(params:get(dat.ti.."amp_strength")==0 and "off" or params:string(dat.ti.."amp_strength"))
  end},
  {function(d) params:delta(dat.ti.."amp_period",d) end,function()
    return "period: "..params:string(dat.ti.."amp_period")
  end},
})
-- page 1
table.insert(enc_func,{
  {function(d) delta_ti(d) end},
  {function(d) params:delta(dat.ti.."pan",d) end,function() return "pan: "..params:string(dat.ti.."pan") end},
  {function(d) params:delta(dat.ti.."pan",d) end},
  {function(d) delta_ti(d,true) end},
  {function(d) params:delta(dat.ti.."pan_strength",d) end,function()
    return "lfo: "..(params:get(dat.ti.."pan_strength")==0 and "off" or params:string(dat.ti.."pan_strength"))
  end},
  {function(d) params:delta(dat.ti.."pan_period",d) end,function()
    return "period: "..params:string(dat.ti.."pan_period")
  end},
})
-- page 3
table.insert(enc_func,{
  {function(d) delta_ti(d) end},
  {function(d) params:delta(dat.ti.."lpf",d) end,function() return "lpf: "..params:string(dat.ti.."lpf") end},
  {function(d) params:delta(dat.ti.."lpfqr",d) end,function() return "1/q: "..params:string(dat.ti.."lpfqr") end},
  {function(d) delta_ti(d,true) end},
  {function(d) params:delta(dat.ti.."hpf",d) end,function() return "hpf: "..params:string(dat.ti.."hpf") end},
  {function(d) params:delta(dat.ti.."hpfqr",d) end,function() return "1/q: "..params:string(dat.ti.."hpfqr") end},
})
-- page 3
table.insert(enc_func,{
  {function(d) delta_ti(d) end},
  {function(d) params:delta(dat.ti.."sampleStart",d) end,function() return "start: "..params:string(dat.ti.."sampleStart") end},
  {function(d) params:delta(dat.ti.."sampleEnd",d) end,function() return "end: "..params:string(dat.ti.."sampleEnd") end},
  {function(d) delta_ti(d,true) end},
  {function(d) params:delta(dat.ti.."oneshot",d) end,function() return "mode: "..params:string(dat.ti.."oneshot") end},
  {function(d) params:delta(dat.ti.."offset",d) end,function() return "offset:"..params:string(dat.ti.."offset") end},
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
-- page 5
table.insert(enc_func,{
  {function(d) delta_ti(d) end},
  {function(d) params:delta(dat.ti.."send1",d) end,function() return "main: "..params:string(dat.ti.."send1") end},
  {function(d) params:delta(dat.ti.."send4",d) end,function() return "greyhole: "..params:string(dat.ti.."send4") end},
  {function(d) delta_ti(d,true) end},
  {function(d) params:delta(dat.ti.."send2",d) end,function() return "tapedeck: "..params:string(dat.ti.."send2") end},
  {function(d) params:delta(dat.ti.."send3",d) end,function() return "clouds: "..params:string(dat.ti.."send3") end},
})
-- page 4
table.insert(enc_func,{
  {function(d) delta_ti(d) end},
  {function(d) params:delta(dat.ti.."sequencer",d) end,function() return "sequencer: "..params:string(dat.ti.."sequencer") end},
  {function(d) params:delta(dat.ti.."k",d) end,function() return "k: "..params:string(dat.ti.."k") end},
  {function(d) delta_ti(d,true) end},
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
  substance()

  -- globals
  global_rec_queue={}
  global_divisions={1/32}

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
  midi_device={{name="disabled",note_on=function(note,vel,ch) end,note_off=function(note,vel,ch) end}}
  midi_device_list={"disabled"}
  for i,dev in pairs(midi.devices) do
    if dev.port~=nil then
      local connection=midi.connect(dev.port)
      local name=string.lower(dev.name).." "..i
      print("adding "..name.." as midi device")
      table.insert(midi_device_list,name)
      table.insert(midi_device,{
        name=name,
        note_on=function(note,vel,ch) connection:note_on(note,vel,ch) end,
        note_off=function(note,vel,ch) connection:note_off(note,vel,ch) end,
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
    os.execute("cp /home/we/dust/code/paracosms/lib/row1/* /home/we/dust/audio/paracosms/row1/")
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
  params_greyhole()
  params_clouds()
  params_tapedeck()

  -- setup parameters
  params:add_group("RECORDING",6)
  params:add_control("record_beats","recording length",controlspec.new(1/4,128,'lin',1/4,8.0,'beats',(1/4)/(128-0.25)))
  params:add_number("record_threshold","rec threshold (dB)",-96,0,-50)
  params:add_number("record_crossfade","rec xfade (1/16th beat)",1,64,16)
  params:add_number("record_predelay","rec latency (ms)",0,100,2)
  params:add_option("record_over","record onto",{"new","existing"},1)
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

  params:add{type="binary",name="UPDATE PARACOSMS",id="update_paracosms",behavior="toggle",action=function(v)
    os.execute("git --git-dir /home/we/dust/code/paracosms fetch --all")
    os.execute("git --git-dir /home/we/dust/code/paracosms reset --hard origin/paracosms")
    os.execute("~/norns/stop.sh && sleep 1 && ~/norns/start.sh")
  end}
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
      if i==16 then
        break
      end
    end
  end

  -- grid
  g_=grid_:new()

  -- osc
  osc_fun={
    progress=function(args)
      local id=tonumber(args[1])
      show_message(string.format("recording cosm %d: %2.0f%%",id,tonumber(args[2])))
      show_progress(tonumber(args[2]))
    end,
    recorded=function(args)
      local id=tonumber(args[1])
      local filename=args[2]
      if id~=nil and filename~=nil then
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
      clock.sleep(1/10)
      redraw()
      debounce_params()

    end
  end)

  -- initialize the dat turntables
  dat.seed=18
  params:set("sel",1)
  dat.tt={}
  dat.ti=1
  dat.percent_loaded=0
  math.randomseed(dat.seed)
  for i=1,112 do
    table.insert(dat.tt,turntable_:new{id=i})
  end

  -- setup keyboard manager
  manager:init()
  params.action_write=function(filename,name)
    print("write",filename,name)
    manager:save(filename..".txt")
  end
  params.action_read=function(filename,silent)
    print("read",filename,silent)
    manager:load(filename..".txt")
    -- turn off all the sounds
    for i=1,112 do
      params:set(i.."play",0)
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
    enc(1,1);enc(1,-1)
    clock.sleep(0.1)
    reset()
    clock.sleep(1)
    style()
  end)

  -- initialize lattice
  lattice=lattice_:new()
  dat.beat=0
  pattern_qn=lattice:new_pattern{
    action=function(v)
      dat.beat=dat.beat+1
      -- TODO: make option to change the probability of reset
      if dat.lcm_beat~=nil and (dat.beat-1)%dat.lcm_beat==0 and math.random(1,100)<10 then
        print("resetPhase from lcm beat")
        engine.resetPhase()
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
    table.insert(beat_num,-1)
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

local ignore_transport=false
function clock.transport.start()
  if ignore_transport then
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
      if count>250 then
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
    {id="hpf",name="hpf",min=10,max=2000,exp=true,div=5,default=60},
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

function params_clouds()
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
  params:add_option("clouds_activate","include effect",{"no","yes"},1)
  params:set_action("clouds_activate",function(v)
    engine.clouds_toggle(v-1)
  end)
  for _,pram in ipairs(params_menu) do
    params:add{
      type="control",
      id="clouds_"..pram.id,
      name=pram.name,
      controlspec=controlspec.new(pram.min,pram.max,pram.exp and "exp" or "lin",pram.div,pram.default,pram.unit or "",pram.div/(pram.max-pram.min)),
      formatter=pram.formatter,
    }
    params:set_action("clouds_"..pram.id,function(v)
      engine.clouds_set(pram.id,v)
    end)
  end
end

function reset()
  print("paracosms: resetting")
  dat.beat=0
  engine.resetPhase()
  ignore_transport=true
  lattice:hard_restart()
  clock.run(function()
    clock.sleep(1)
    ignore_transport=false
  end)
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
    params:set("sel",available_ti[i])
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
    params:set("sel",available_ti[i])
    -- params:set("sel",util.wrap(dat.ti+d,1,#dat.tt))
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
    if params:get(dat.ti.."oneshot")==2 then
      params:set(dat.ti.."play",z)
    elseif z==1 then
      hold_beats=clock.get_beats()
    elseif z==0 then
      local hold_time=math.pow((hold_beats-clock.get_beats())*clock.get_beat_sec()*1.5,2)
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
  show_manager=true
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

end
