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
    self.vw=viewwave_:new{id=self.id,path=self.path}
    self.ready=true
  end
end

function Turntable:init()
  self.ready=false
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
