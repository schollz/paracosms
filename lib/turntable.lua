local Turntable={}

function Turntable:new(o)
  o=o or {}
  setmetatable(o,self)
  self.__index=self
  o:init()
  return o
end

function Turntable:oscdata(datatype,data)
  if datatype=="cursor" then
    if self.ready then
      self.vw:cursor(data)
    end
  elseif datatype=="ready" then
    self.vw=viewwave_:new{id=self.id,path=self.path}
    self.ready=true
  end
end

function Turntable:init()
  self.ready=false
  params:add_group("table "..self.id,2)
  params:add{type='binary',name='play',id=self.id..'play',behavior='toggle',action=function(v)
    engine.set(self.id,"amp",v==1 and 1.0 or 0,params:get(self.id.."fadetime"))
  end}
  params:add_control(self.id.."fadetime","fade time",controlspec.new(0,64,'lin',0.01,1,'seconds',0.01/64))
  local bpm=clock.get_tempo()
  for word in string.gmatch(self.path,'([^_]+)') do
    if string.find(word,"bpm") then
      bpm=tonumber(word:match("%d+"))
    end
  end
  engine.add(self.id,self.path,bpm,clock.get_tempo())
end

function Turntable:redraw()
  if self.ready then
    self.vw:redraw()
  end
end

return Turntable
