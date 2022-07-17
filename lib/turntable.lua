local Turntable={}

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

  -- setup params
  local id=self.id
  -- TODO: add pan and amp lfos
  local params_menu={
    {id="amp_period",name="amp lfo period",min=0.1,max=60,exp=false,div=0.05,default=math.random(100,300)/10,response=1},
    {id="amp_strength",name="amp lfo strength",min=0,max=2,exp=false,div=0.01,default=0,response=1},
    {id="pan",name="pan",min=-1,max=1,exp=false,div=0.05,default=0,response=1},
    {id="pan_period",name="pan lfo period",min=0.1,max=60,exp=false,div=0.05,default=math.random(100,300)/10,response=1},
    {id="pan_strength",name="pan lfo strength",min=0,max=2,exp=false,div=0.01,default=0,response=1},
    {id="rate",name="rate",min=-2,max=2,exp=false,div=0.01,default=1,response=3,formatter=function(param) return param:get().."x" end},
    {id="lpf",name="lpf",min=10,max=20000,exp=true,div=100,default=20000,unit="Hz",response=1},
    {id="ts",name="timestretch",min=0,max=1,exp=false,div=1,default=0,response=1,formatter=function(param) return param:get()==1 and "on" or "off" end},
    {id="tsSlow",name="timestretch slow",min=1,max=100,div=0.1,exp=false,default=1,response=1,unit="x"},
    {id="tsSeconds",name="timestretch window",min=clock.get_beat_sec()/64,max=20,exp=false,response=1,div=clock.get_beat_sec()/64,default=clock.get_beat_sec()/8,unit="s"},
    {id="sampleStart",name="sample start",min=0,max=1,exp=false,div=1/64,default=0,response=1,formatter=function(param) return string.format("%3.2f s",param:get()*self:duration()) end},
    {id="sampleEnd",name="sample end",min=0,max=1,exp=false,div=1/64,default=1,response=1,formatter=function(param) return string.format("%3.2f s",param:get()*self:duration()) end},
    {id="offset",name="sample offset",min=-1,max=1,exp=false,div=0.002,default=0,response=1,formatter=function(param) return string.format("%2.0f ms",param:get()*1000) end},
    {id="send1",name="main send",min=0,max=1,exp=false,div=0.01,default=1.0,response=1,formatter=function(param) return string.format("%2.0f%%",param:get()*100) end},
    {id="send2",name="tapedeck send",min=0,max=1,exp=false,div=0.01,default=0.0,response=1,formatter=function(param) return string.format("%2.0f%%",param:get()*100) end},
    {id="send3",name="clouds send",min=0,max=1,exp=false,div=0.01,default=0.0,response=1,formatter=function(param) return string.format("%2.0f%%",param:get()*100) end},
  }
  params:add_group("sample "..self.id,17+#params_menu)
  params:add_file(id.."file","file",_path.audio)
  params:set_action(id.."file",function(x)
    if file_exists(x) and string.sub(x,-1)~="/" then
      print("loading files "..x)
      self:load_file(x)
    end
  end)
  params:add_option(id.."play","play",{"stopped","playing"},1)
  params:set_action(id.."play",function(v)
    engine[v==1 and "stop" or "play"](id)
  end)
  params:add_option(id.."oneshot","mode",{"loop","oneshot"})
  params:set_action(id.."oneshot",function(v)
    engine.set(id,"oneshot",v-1,0)
  end)
  params:add_control(id.."amp","amp",controlspec.new(0,4,'lin',0.01,1.0,'amp',0.01/4))
  params:set_action(id.."amp",function(v)
    debounce_fn[id.."amp"]={
      3,function()
        if params:get(id.."play")==2 and params:get(id.."amp")==0 then
          params:set(id.."play",1)
        elseif params:get(id.."play")==2 then
          engine.set(id,"amp",params:get(id.."amp"),params:get(id.."fadetime"))
        end
      end,
    }
  end)
  for _,pram in ipairs(params_menu) do
    params:add{
      type="control",
      id=id..pram.id,
      name=pram.name,
      controlspec=controlspec.new(pram.min,pram.max,pram.exp and "exp" or "lin",pram.div,pram.default,pram.unit or "",pram.div/(pram.max-pram.min)),
      formatter=pram.formatter,
    }
    params:set_action(id..pram.id,function(v)
      debounce_fn[id..pram.id]={
        pram.response or 3,function()
          engine.set(id,pram.id,params:get(id..pram.id),0.2)
        end,
      }
    end)
  end
  params:add_control(id.."fadetime","fade time",controlspec.new(0,64,'lin',0.01,1,'seconds',0.01/64))
  params:set_action(id.."fadetime",function(v)
    engine.set(id,"amp",params:get(id.."amp"),v)
  end)

  params:add_separator("sequencer")
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

  params:add_separator("modify")
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

  params:add_separator("recording")
  params:add_control(id.."record_beats","recording length",controlspec.new(1/4,128,'lin',1/8,8.0,'beats',(1/8)/(128-0.25)))
  params:add_binary(id.."record_on","record on","trigger")
  params:set_action(id.."record_on",function(x)
    if dat.recording then
      do return end
    end
    if dat.recording_primed then
      engine.record_start()
      do return end
    end
    dat.recording_primed=true
    print("record_on",id)
    show_message("ready to record "..id)
    local datetime=util.os_capture("date +%Y%m%d%H%m%S")
    local filename=string.format("%s_bpm%d.wav",datetime,clock.get_tempo())
    filename=_path.audio.."paracosms/recordings/"..filename
    local seconds=params:get(id.."record_beats")*clock.get_beat_sec()
    local crossfade=params:get("record_crossfade")/16*clock.get_beat_sec()
    engine.record(id,filename,seconds,crossfade,params:get("record_threshold"))
  end)

end

function Turntable:play()
  engine.set(self.id,"oneshot",params:get(self.id.."oneshot")-1,0)
  if params:get(self.id.."oneshot")==2 then
    engine.set(self.id,"amp",params:get(self.id.."amp"),0)
  end
  engine.play(self.id)
end

function Turntable:duration()
  local duration=1
  if self.vw~=nil and self.vw.duration~=nil then
    duration=self.vw.duration
  end
  return duration
end

function Turntable:load_file(path)
  print(string.format("[%d] turntable: loading %s",self.id,path))
  self.path_original=path
  self.path=path
  local pathname,filename,ext=string.match(self.path_original,"(.-)([^\\/]-%.?([^%.\\/]*))$")
  local bpm=clock.get_tempo()
  for word in string.gmatch(self.path,'([^_]+)') do
    if string.find(word,"bpm") then
      bpm=tonumber(word:match("%d+"))
    end
  end
  params:set(self.id.."source_bpm",bpm,true)
  params:set(self.id.."type",string.find(self.path,"drum") and 2 or 1,true)
  params:set(self.id.."oneshot",string.find(self.path,"oneshot") and 2 or 1)
  self:retune()
  self.loaded_file=true
end

function Turntable:retune()
  if self.path_original==nil then
    do return end
  end
  print(string.format("[%d] turntable: retune",self.id))
  -- convert the file
  local bpm=params:get(self.id.."source_bpm")
  local tune=params:get(self.id.."tune")
  local clock_tempo=clock.get_tempo()
  self.path=self.path_original
  if bpm~=clock_tempo or tune~=self.last_tune then
    local pathname,filename,ext=string.match(self.path_original,"(.-)([^\\/]-%.?([^%.\\/]*))$")
    local newpath=string.format("%s%s_%d_pitch%d_%d_bpm%d.flac",self.cache,filename,params:get(self.id.."type"),params:get(self.id.."tune"),params:get(self.id.."source_bpm"),clock.get_tempo())
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
      print(string.format("turntable%d: using cached retuned",self.id))
    end
    self.path=newpath
  end
  self.last_tune=tune
  self.retuned=true
  print(string.format("[%d] turntable: adding to engine %s",self.id,self.path))
  engine.add(self.id,self.path)
end

function Turntable:emit(beat)
  if params:get(self.id.."oneshot")==1 or params:get(self.id.."sequencer")==1 or self.sequence==nil or (not self.ready) then
    do return end
  end
  local i=((beat-1)%#self.sequence)+1
  if self.sequence[i] then
    self:play()
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
