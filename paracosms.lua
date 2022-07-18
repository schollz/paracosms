-- paracosms
--
--
-- llllllll.co/t/?
--
--
--
--    ▼ instructions below ▼
-- K1+K3 start/stops sample
-- (hold length = fade)
-- K1+K2 primes recording
-- (when primed, starts)
--
-- E1 select sample
-- K1+E1 select running sample
--
-- K2/K3 selects parameters
-- E2/E3 modulate parameter
-- K1+E2/E3 modulate more
--
--
--
--

viewwave_=include("lib/viewwave")
turntable_=include("lib/turntable")
grid_=include("lib/ggrid")
lattice_=require("lattice")
er=require("er")

engine.name="Paracosms"
dat={percent_loaded=0,tt={},files_to_load={},recording=false,recording_primed=false,beat=0,sequencing={}}
dat.rows={
  {folder="/home/we/dust/audio/paracosms/row1"},
  {folder="/home/we/dust/audio/x0x/909",params={oneshot=2}},
  {folder="/home/we/dust/audio/paracosms/row3"},
  {folder="/home/we/dust/audio/paracosms/row4"},
  {folder="/home/we/dust/audio/paracosms/row5"},
  {folder="/home/we/dust/audio/paracosms/row6"},
  {folder="/home/we/dust/audio/paracosms/row7"},
}

global_startup=false
debounce_fn={}
local shift=false
local ui_page=1
local enc_func={}
-- page 1
table.insert(enc_func,{
  {function(d) delta_ti(d) end},
  {function(d) params:delta(dat.ti.."oneshot",d) end,function() return "K1+K3 to play" end},
  {function(d) params:delta(dat.ti.."oneshot",d) end,function() return params:string(dat.ti.."oneshot") end},
  {function(d) delta_ti(d,true) end},
  {function(d) params:delta(dat.ti.."record_beats",d)end,function() return "K1+K2 to record" end},
  {function(d) params:delta(dat.ti.."record_beats",d)end,function() return string.format("%2.3f beats",params:get(dat.ti.."record_beats")) end},
})

table.insert(enc_func,{
  {function(d) delta_ti(d) end},
  {function(d) params:delta(dat.ti.."amp",d) end,function() return params:string(dat.ti.."amp") end},
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
  {function(d) params:delta(dat.ti.."send2",d) end,function() return "tapedeck: "..params:string(dat.ti.."send2") end},
  {function(d) params:delta(dat.ti.."send3",d) end,function() return "clouds: "..params:string(dat.ti.."send3") end},
  {function(d) delta_ti(d,true) end},
  {function(d) params:delta(dat.ti.."send1",d) end,function() return "main: "..params:string(dat.ti.."send1") end},
  {function(d) end},
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
  print(folder)
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
      show_message("K1+K3 TO PLAY")
      clock.sleep(2)
      show_message("K1+K2 TO RECORD")
      clock.sleep(2)
      show_message("K2/K3 TO CYCLE PARAM")
      clock.sleep(2)
      show_message("(K1+)E2/E3 CHANGE PARAM")
    end)
  end

  -- setup effects parameters
  params_clouds()
  params_tapedeck()

  -- setup parameters
  params:add_separator("globals")
  params:add_number("record_threshold","rec threshold (dB)",-96,0,-50)
  params:add_number("record_crossfade","rec xfade (1/16th beat)",1,64,16)
  params:add_number("record_predelay","rec latency (ms)",0,100,2)
  params:add_separator("samples")

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
  dat.recording_id=0
  osc_fun={
    trigger=function(args)
      print("triggered "..args[1])
    end,
    recording=function(args)
      dat.recording=true
      dat.recording_id=tonumber(args[1])
      if dat.recording_id~=nil then show_message("recording track "..dat.recording_id) end
    end,
    progress=function(args)
      show_message(string.format("recording track %d: %2.0f%%",dat.recording_id,tonumber(args[1])))
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

  -- midi
  midi_device={}
  midi_device_list={"disabled"}
  for i,dev in pairs(midi.devices) do
    if dev.port~=nil then
      local name=string.lower(dev.name).." "..i
      table.insert(midi_device_list,name)
      print("adding "..name.." to port "..dev.port)
      midi_device[name]={
        name=name,
        port=dev.port,
        midi=midi.connect(dev.port),
      }
      midi_device[name].midi.event=function(data)
        local msg=midi.to_msg(data)
        if msg.type=="clock" then do return end end
-- OP-1 fix for transport
        if msg.type=='start' or msg.type=='continue' then
          reset()
        elseif msg.type=="stop" then
        elseif msg.type=="note_on" then
        end
      end
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

  -- initialize hardcoded parameters
  for row=1,7 do
    for col=1,16 do
      if dat.rows[row].params~=nil then
        for pram,val in pairs(dat.rows[row].params) do
          local id=(row-1)*16+col
          print("setting ",id,pram,val)
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
        clock.sleep(0.05)
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
              print("setting ",id,pram,val)
              params:set(id..pram,val)
            end
          end
        end
      end
    end
    -- make sure we are on the actual first if the first row has nothing
    enc(1,1);enc(1,-1)
  end)

  -- initialize lattice
  lattice=lattice_:new()
  dat.beat=0
  pattern_qn=lattice:new_pattern{
    action=function(v)
      dat.beat=dat.beat+1
      for id,_ in pairs(dat.sequencing) do
        dat.tt[id]:emit(dat.beat)
      end
    end,
    division=1/8,
  }
  lattice:start()
  reset()

  --TEST STUFF
  -- clock.run(function()
  --   clock.sleep(3)
  --   print("STARTING TEST")
  --   --engine.tapedeck_toggle(1)
  --   -- engine.set(1,"send1",0,0)
  --   -- engine.set(1,"send2",1,0)
  --   -- engine.set(2,"send1",0,0)
  --   -- engine.set(2,"send2",1,0)
  --   -- engine.tapedeck_set("amp",0)
  -- end)
end

local ignore_transport=false
function clock.transport.start()
  if ignore_transport then
    do return end
  end
  reset()
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
    {id="fbMin",name="fb min",min=0,max=1,exp=false,div=0.01,default=0.4},
    {id="fbMax",name="fb max",min=0,max=1,exp=false,div=0.01,default=0.9},
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
  dat.ti=id
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
  elseif (k==2 or k==3) and z==1 and not shift then
    delta_page(k==2 and-1 or 1)
  elseif shift and k==2 then
    if z==1 then
      params:delta(dat.ti.."record_on",1)
    end
  elseif shift and k==3 and z==1 then
    if params:get(dat.ti.."oneshot")==2 then
      dat.tt[dat.ti]:play()
    else
      hold_beats=clock.get_beats()
    end
  elseif shift and k==3 and z==0 then
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
local show_message_clock=0

function show_progress(val)
  show_message_progress=util.clamp(val,0,100)
end

function show_message(message,seconds)
  seconds=seconds or 2
  show_message_clock=10*seconds
  show_message_text=message
end

function redraw()
  screen.clear()
  if dat.tt[dat.ti]==nil then
    do return end
  end
  local topleft=dat.tt[dat.ti]:redraw()
  if show_message_clock>0 and show_message_text~="" then
    show_message_clock=show_message_clock-1
    if show_message_clock==0 then
      show_message_text=""
      show_message_progress=0
    end
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

  -- screen.level(5)
  -- screen.move(128,62)
  -- if enc_func[ui_page][3+(shift and 3 or 0)][2]~=nil then
  --   screen.text_right(enc_func[ui_page][3+(shift and 3 or 0)][2]())
  -- end

  -- screen.move(0,62)
  -- if enc_func[ui_page][2+(shift and 3 or 0)][2]~=nil then
  --   screen.text(enc_func[ui_page][2+(shift and 3 or 0)][2]())
  -- end
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

  screen.update()
end
