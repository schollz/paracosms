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

  -- setup params
  local id=self.id
  local params_menu={
    {id="lpf",name="lpf",min=10,max=20000,exp=true,div=100,default=20000,unit="Hz"},
    {id="ts",name="timestretch",min=0,max=1,exp=false,div=1,default=0},
    {id="tsSlow",name="timestretch slow",min=1,max=100,div=0.1,exp=false,default=1,unit="x"},
    {id="tsSeconds",name="timestretch window",min=clock.get_beat_sec()/64,max=20,exp=false,div=clock.get_beat_sec()/64,default=clock.get_beat_sec()/8,unit="s"},
    {id="sampleStart",name="sample start",min=0,max=1,exp=false,div=1/64,default=0},
    {id="sampleEnd",name="sample end",min=0,max=1,exp=false,div=1/64,default=1},
  }
  params:add_group("sample "..self.id,8+#params_menu)
  params:add_file(id.."file","file",_path.audio)
  params:set_action(id.."file",function(x)
    if file_exists(x) and string.sub(x,-1)~="/" then
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
    params:add_control(id..pram.id,pram.name,controlspec.new(pram.min,pram.max,
    pram.exp and "exp" or "lin",pram.div,pram.default,pram.unit or "",pram.div/(pram.max-pram.min)))
    params:set_action(id..pram.id,function(v)
      debounce_fn[id..pram.id]={
        3,function()
          engine.set(id,pram.id,params:get(id..pram.id),0.2)
        end,
      }
    end)

  end
  params:add_control(id.."fadetime","fade time",controlspec.new(0,64,'lin',0.01,1,'seconds',0.01/64))
  params:set_action(id.."fadetime",function(v)
    engine.set(id,"amp",params:get(id.."amp"),v)
  end)
  params:add_option(id.."type","type",{"melodic","drums"},1)
  params:add_number(id.."tune","tune (notes)",-24,24,0)
  params:add_number(id.."source_bpm","sample bpm",20,320,clock.get_tempo(),0)
  for _,pram in ipairs({"type","tune","source_bpm"}) do
    params:set_action(id..pram,function(v)
      debounce_fn[id.."updatesource"]={
        10,function()
          self:retune()
        end,
      }
    end)
  end
end

function Turntable:load_file(path)
  print(string.format("turntable%d: loading %s",self.id,path))
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
  self:retune()
end

function Turntable:retune()
  if self.path_original==nil then
    do return end
  end
  -- convert the file
  local bpm=params:get(self.id.."source_bpm")
  local tune=params:get(self.id.."tune")
  local clock_tempo=clock.get_tempo()
  if bpm~=clock_tempo or tune~=0 then
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
  print(string.format("turntable%d: adding to engine %s",self.id,self.path))
  engine.add(self.id,self.path)
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
