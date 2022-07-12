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

function Turntable:redraw()
  if self.ready then
    return self.vw:redraw()
  end
end

return Turntable
