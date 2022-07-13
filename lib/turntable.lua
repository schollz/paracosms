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
  local id=self.id
  local pathname,filename,ext=string.match(self.path,"(.-)([^\\/]-%.?([^%.\\/]*))$")

  -- setup params
  local params_menu={
    {id="lpf",name="lpf",min=10,max=20000,exp=true,div=10,default=20000,unit="Hz"},
    {id="ts",name="timestretch",min=0,max=1,exp=false,div=1,default=0},
    {id="tsSlow",name="timestretch slow",min=1,max=100,div=0.1,exp=false,default=1,unit="x"},
    {id="tsSeconds",name="timestretch window",min=0.01,max=20,exp=false,div=clock.get_beat_sec()/16,default=clock.get_beat_sec(),unit="s"},
    {id="sampleStart",name="sample start",min=0,max=1,exp=false,div=1/64,default=0},
    {id="sampleEnd",name="sample end",min=0,max=1,exp=false,div=1/64,default=1},
  }
  params:add_group(filename:sub(1,18),4+#params_menu)
  params:add_option(id.."play","play",{"stopped","playing"},1)
  params:set_action(id.."play",function(v)
    engine.set(id,"amp",v==2 and params:get(id.."amp") or 0,params:get(id.."fadetime"))
  end)
  -- params:add{type='binary',name='play',id=id..'play',behavior='toggle',action=function(v)
  --   engine.set(id,"amp",v==1 and params:get(id.."amp") or 0,params:get(id.."fadetime"))
  -- end}
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

  -- initialize with path
  self.cache=self.cache or _path.data.."paracosms/cache/"
  self.ready=false
  local bpm=clock.get_tempo()
  for word in string.gmatch(self.path,'([^_]+)') do
    if string.find(word,"bpm") then
      bpm=tonumber(word:match("%d+"))
    end
  end
  -- convert the file
  if bpm~=nil and bpm~=clock.get_tempo() and bpm>0.0 then
    local pathname,filename,ext=string.match(self.path,"(.-)([^\\/]-%.?([^%.\\/]*))$")
    local newpath=string.format("%s%s_bpm%d.flac",self.cache,filename,clock.get_tempo())
    if not util.file_exists(newpath) then
      local cmd=string.format("sox %s %s tempo -m %2.6f rate -v 48k",self.path,newpath,clock.get_tempo()/bpm)
      if string.find(self.path,"drum") then
        cmd=string.format("sox %s %s speed %2.6f rate -v 48k",self.path,newpath,clock.get_tempo()/bpm)
      end
      print(cmd)
      os.execute(cmd)
    end
    self.path=newpath
  end
  engine.add(self.id,self.path)
end

function Turntable:is_playing()
  return (not self.ready) and false or self.vw:is_playing()
end

function Turntable:redraw()
  if self.ready then
    local info=self.vw:redraw()
    return info
  end
end

return Turntable
