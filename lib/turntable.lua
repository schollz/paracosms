local Turntable={}
include("lib/utils")
function Turntable:new(o)
  o=o or {}
  setmetatable(o,self)
  self.__index=self
  o:init()
  return o
end

function Turntable:oscdata(datatype,data)
  if datatype=="cursor" and self.ready then
    self.vw:cursor(data)
  elseif datatype=="ready" then
    self.vw=viewwave_:new{id=self.id,path=self.path,cache=self.cache}
    self.ready=true
  end
end

function Turntable:init()
  local file_exists=function(name)
    local f=io.open(name,"r")
    if f~=nil then io.close(f) return true else return false end
  end

  -- initialize cache
  self.cache=self.cache or _path.data.."paracosms/cache/"
  -- not ready until file is loaded
  self.ready=false
  self.last_tune=0

  -- recording stuff
  self.recording=false
  self.recording_primed=false

  -- setup params
  local id=self.id
  -- TODO: add pan and amp lfos
  local params_menu={
    {id="amp",name="amp",min=0,max=5,exp=false,div=0.01,default=1,response=1},
    {id="amp_period",name="amp lfo period",min=0.1,max=60,exp=false,div=0.05,default=math.random(100,300)/10,response=1,unit="s"},
    {id="amp_strength",name="amp lfo strength",min=0,max=2,exp=false,div=0.01,default=0,response=1},
    {id="pan",name="pan",min=-1,max=1,exp=false,div=0.05,default=0,response=1},
    {id="pan_period",name="pan lfo period",min=0.1,max=60,exp=false,div=0.05,default=math.random(100,300)/10,response=1,unit="s"},
    {id="pan_strength",name="pan lfo strength",min=0,max=2,exp=false,div=0.01,default=0,response=1},
    {id="rate",name="rate",min=-2,max=2,exp=false,div=0.01,default=1,response=1,formatter=function(param) return param:get().."x" end},
    {id="attack",name="attack",dontsend=true,min=0.001,max=10,exp=false,div=0.005,default=clock.get_beat_sec(),response=1,unit="s"},
    {id="release",name="release",dontsend=true,min=0.01,max=30,exp=false,div=0.01,default=clock.get_beat_sec()*4,response=1,unit="s"},
    {id="lpf",name="lpf",min=100,max=20000,exp=true,div=100,default=20000,unit="Hz",response=1},
    {id="lpfqr",name="lpf qr",min=0.01,max=1.0,exp=false,div=0.01,default=0.707,response=1},
    {id="hpf",name="hpf",min=10,max=20000,exp=true,div=10,default=10,unit="Hz",response=1},
    {id="hpfqr",name="hpf qr",min=0.01,max=1.0,exp=false,div=0.01,default=0.707,response=1},
    {id="ts",name="timestretch",min=0,max=1,exp=false,div=1,default=0,response=1,formatter=function(param) return param:get()==1 and "on" or "off" end},
    {id="tsSlow",name="timestretch slow",min=1,max=100,div=0.1,exp=false,default=1,response=1,unit="x"},
    {id="tsSeconds",name="timestretch window",min=clock.get_beat_sec()/64,max=20,exp=false,response=1,div=clock.get_beat_sec()/64,default=clock.get_beat_sec()/8,unit="s"},
    {id="sampleStart",name="sample start",min=0,max=1,exp=false,div=1/64,default=0,response=1,formatter=function(param) return string.format("%3.2f s",param:get()*self:duration()) end},
    {id="sampleEnd",name="sample end",min=0,max=1,exp=false,div=1/64,default=1,response=1,formatter=function(param) return string.format("%3.2f s",param:get()*self:duration()) end},
    {id="offset",name="sample offset",min=-1,max=1,exp=false,div=0.002,default=0,response=1,formatter=function(param) return string.format("%2.0f ms",param:get()*1000) end},
    {id="send1",name="main send",min=0,max=1,exp=false,div=0.01,default=1.0,response=1,formatter=function(param) return string.format("%2.0f%%",param:get()*100) end},
    {id="send2",name="tapedeck send",min=0,max=1,exp=false,div=0.01,default=0.0,response=1,formatter=function(param) return string.format("%2.0f%%",param:get()*100) end},
    {id="send3",name="clouds send",min=0,max=1,exp=false,div=0.01,default=0.0,response=1,formatter=function(param) return string.format("%2.0f%%",param:get()*100) end},
    {id="send4",name="greyhole send",min=0,max=1,exp=false,div=0.01,default=0.0,response=1,formatter=function(param) return string.format("%2.0f%%",param:get()*100) end},
  }
  self.all_params={"file","release","play","oneshot","amp","attack","sequencer","n","k","w","guess","type","tune","source_bpm","record_on"}
  params:add_file(id.."file","file",_path.audio)
  params:set_action(id.."file",function(x)
    if file_exists(x) and string.sub(x,-1)~="/" then
      -- print("loading files "..x)
      self:load_file(x)
    end
  end)
  self.last_play=0
  params:add{type="binary",name="play",id=id.."play",behavior="toggle",action=function(v)
    if v~=self.last_play then
      engine[v==1 and "play" or "stop"](id,params:get(id..(v==1 and "attack" or "release")))
      self.last_play=v
      if params:get(id.."oneshot")==1 then
        -- check all playing loops and get the lcm_beat
        if v==1 then
          dat.playing[id]=true
        else
          dat.playing[id]=nil
        end
        local beats={}
        for vid,_ in pairs(dat.playing) do
          table.insert(beats,math.floor(dat.tt[vid]:beats()*4))
        end
        dat.lcm_beat=utils.lcm(beats)
        print("turntable: new lcm beat ",dat.lcm_beat)
      end
    end
  end}
  params:add_option(id.."oneshot","mode",{"loop","oneshot"})
  params:set_action(id.."oneshot",function(v)
    engine.stop(id,params:get(id.."release"))
    engine.set(id,"oneshot",v-1)
  end)
  for _,pram in ipairs(params_menu) do
    table.insert(self.all_params,pram.id)
    params:add{
      type="control",
      id=id..pram.id,
      name=pram.name,
      controlspec=controlspec.new(pram.min,pram.max,pram.exp and "exp" or "lin",pram.div,pram.default,pram.unit or "",pram.div/(pram.max-pram.min)),
      formatter=pram.formatter,
    }
    params:set_action(id..pram.id,function(v)
      if pram.dontsend~=nil then
        do return end
      end
      for _,vv in ipairs({{"send2","tapedeck"},{"send3","clouds"},{"send4","greyhole"}}) do
        if pram.id==vv[1] then
          if v>0 then
            if params:get(vv[2].."_activate")==1 then
              print("activating")
              params:set(vv[2].."_activate",2)
            end
          else
            -- check to see whether all of them should be turned off
            local all_off=true
            for i=1,112 do
              if params:get(i..vv[1])>0 then
                all_off=false
                break
              end
            end
            if all_off then
              params:set(vv[2].."_activate",1)
            end
          end
        end
      end

      debounce_fn[id..pram.id]={
        pram.response or 3,function()
          engine.set(id,pram.id,params:get(id..pram.id))
        end,
      }
    end)
  end

  params:add_option(id.."sequencer","sequencer",{"off","euclidean"})
  params:add_number(id.."n","n",1,128,16)
  params:add_number(id.."k","k",0,128,math.random(1,4))
  params:add_number(id.."w","w",0,128,0)
  for _,pram in ipairs({"sequencer","n","k","w"}) do
    params:set_action(self.id..pram,function(v)
      if pram=="sequencer" then
        dat.sequencing[self.id]=v==2 and true or nil
      end
      self.sequence=er.gen(params:get(self.id.."k"),params:get(self.id.."n"),params:get(self.id.."w"))
    end)
  end
  params:add_option(id.."guess","guess bpm?",{"no","yes"},1)
  params:add_option(id.."type","type",{"melodic","drums"},1)
  params:add_number(id.."tune","tune (notes)",-24,24,0)
  params:add_number(id.."source_bpm","sample bpm",20,320,clock.get_tempo())
  for _,pram in ipairs({"type","tune","source_bpm"}) do
    params:set_action(id..pram,function(v)
      if global_startup then
        do return end
      end
      debounce_fn[id.."updatesource"]={
        10,function()
          self:retune()
        end,
      }
    end)
  end

  params:add_binary(id.."record_on","record on","trigger")
  params:set_action(id.."record_on",function(x)
    if self.recording then
      do return end
    end
    if self.recording_primed then
      engine.record_start()
      do return end
    end
    self.recording_primed=true
    print("record_on",id)
    show_message("ready to record "..id)
    local datetime=util.os_capture("date +%Y%m%d%H%m%S")
    local filename=string.format("%s_bpm%d.wav",datetime,clock.get_tempo())
    filename=_path.audio.."paracosms/recordings/"..filename
    local seconds=params:get("record_beats")*clock.get_beat_sec()
    local crossfade=params:get("record_crossfade")/16*clock.get_beat_sec()
    if crossfade>seconds then
      crossfade=seconds*0.15
    end
    local latency=params:get("record_predelay")/1000
    engine.record(id,filename,seconds,crossfade,params:get("record_threshold"),latency)
  end)
  params:add_number(id.."normalize","normalize",0,1,0)
  params:hide(id.."normalize")
end

function Turntable:hide()
  if self.hidden==true then
    do return end
  end
  self.hidden=true
  for _,pram in ipairs(self.all_params) do
    params:hide(self.id..pram)
  end
end

function Turntable:show()
  if self.hidden==true then
    for _,pram in ipairs(self.all_params) do
      params:show(self.id..pram)
    end
    self.hidden=false
  end
end

function Turntable:recording_finish(filename)
  self.play_on_load=true
  self.recording=false
  self.recording_primed=false
  params:set(self.id.."file",filename)
  params:set(self.id.."play",1,true)
  self.last_play=true
end

function Turntable:beats()
  return self:duration()/clock.get_beat_sec()
end

function Turntable:duration()
  local duration=0
  if self.vw~=nil and self.vw.duration~=nil then
    duration=self.vw.duration
  end
  return duration
end

function Turntable:load_file(path)
  -- print(string.format("[%d] turntable: loading %s",self.id,path))
  self.path_original=path
  self.path=path
  local pathname,filename,ext=string.match(self.path_original,"(.-)([^\\/]-%.?([^%.\\/]*))$")
  local bpm=nil
  for word in string.gmatch(self.path,'([^_]+)') do
    if string.find(word,"bpm") then
      bpm=tonumber(word:match("%d+"))
    end
  end
  if bpm==nil and params:get(self.id.."guess")==2 then
    bpm=self:guess_bpm(path)
  end
  if bpm==nil then
    bpm=clock.get_tempo()
  end
  params:set(self.id.."source_bpm",bpm,true)
  params:set(self.id.."type",string.find(self.path,"drum") and 2 or 1,true)
  params:set(self.id.."oneshot",string.find(self.path,"oneshot") and 2 or 1)
  self:retune()
  local ch,samples,samplerate=audio.file_info(self.path)
  if samples==nil or samples<10 then
    print("ERROR PROCESSING FILE: "..self.path)
    do return end
  end
  local duration=samples/samplerate
  --params:set("record_beats",util.round(duration/clock.get_beat_sec(),1/4))
  self.loaded_file=true
end

function Turntable:guess_bpm(fname)
  local ch,samples,samplerate=audio.file_info(fname)
  if samples==nil or samples<10 then
    print("ERROR PROCESSING FILE: "..self.path)
    do return end
  end
  local duration=samples/samplerate
  local closest={1,1000000}
  for bpm=90,179 do
    local beats=duration/(60/bpm)
    local beats_round=util.round(beats)
    -- only consider even numbers of beats
    if beats_round%4==0 then
      local dif=math.abs(beats-beats_round)/beats
      if dif<closest[2] then
        closest={bpm,dif,beats}
      end
    end
  end
  print("bpm guessing for",fname)
  tab.print(closest)
  return closest[1]
end

function Turntable:retune()
  if self.path_original==nil then
    do return end
  end
  -- print(string.format("[%d] turntable: retune",self.id))
  -- convert the file
  local bpm=params:get(self.id.."source_bpm")
  local tune=params:get(self.id.."tune")
  local clock_tempo=clock.get_tempo()
  self.path=self.path_original
  if bpm~=clock_tempo or tune~=self.last_tune or params:get(self.id.."normalize")==1 then
    local pathname,filename,ext=string.match(self.path_original,"(.-)([^\\/]-%.?([^%.\\/]*))$")
    local newpath=string.format("%s%s_%d_pitch%d_%d_bpm%d.flac",self.cache,filename,params:get(self.id.."type"),params:get(self.id.."tune"),params:get(self.id.."source_bpm"),math.floor(clock.get_tempo()))
    if not util.file_exists(newpath) then
      print(string.format("turntable%d: retuning %s",self.id,self.path_original))
      local cmd=string.format("sox %s %s ",self.path,newpath)
      if bpm~=clock_tempo then
        if params:get(self.id.."type")==2 then
          cmd=string.format("%s speed %2.6f ",cmd,clock_tempo/bpm)
        else
          cmd=string.format("%s tempo -m %2.6f",cmd,clock_tempo/bpm)
        end
      end
      if tune~=0 then
        cmd=string.format("%s pitch %d",cmd,tune*100)
      end
      cmd=cmd.." rate -v 48k"
      print(cmd)
      os.execute(cmd)
    else
      -- print(string.format("turntable%d: using cached retuned",self.id))
    end
    self.path=newpath
  end
  self.last_tune=tune
  self.retuned=true
  -- print(string.format("[%d] turntable: adding to engine %s",self.id,self.path))
  engine.add(self.id,self.path,self.play_on_load==true and 1 or 0)
  self.play_on_load=false
end

function Turntable:emit(beat)
  if params:get(self.id.."oneshot")==1 or params:get(self.id.."sequencer")==1 or self.sequence==nil or (not self.ready) then
    do return end
  end
  local i=((beat-1)%#self.sequence)+1
  if self.sequence[i] then
    self:play(true,true)
  end
end

function Turntable:is_playing()
  if not self.ready or self.vw==nil then
    do return false end
  end
  return self.vw:is_playing()
end

function Turntable:redraw()
  if self.ready then
    local info=self.vw:redraw()
    return info
  end
end

return Turntable
