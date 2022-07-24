-- Manager manages the trakcs

local Manager={}

function Manager:new(o)
  o=o or {}
  setmetatable(o,self)
  self.__index=self
  o:init()
  return o
end

function Manager:init()
  self.tracks={}
  self.num_tracks=112
  self.last_note={}
  crow.output[2].action="adsr(0.1,0.5,5,1,'linear')"
  self.voices={
    {name="crow",mono=true,
      on=function(note) print("crow",note);crow.output[1].volts=(note-24)/12;crow.output[2](true) end,
      off=function(note) print("crow off",note);crow.output[2](false) end,
    },

  }

  local voice_names={}
  for _,voice in ipairs(self.voices) do
    table.insert(voice_names,voice.name)
  end
  for i=1,self.num_tracks do
    table.insert(self.tracks,tracker_:new{id=i,
      voices=voice_names,
      note_on=function(note) self:note_on(i,note) end,
    note_off=function() self:note_off(i) end})
  end

end

function Manager:note_off(id)
  if self.last_note[id]==nil then
    do return end
  end
  local voice=self.voices[params:get(id.."voice")]
  local note=self.last_note[id]
  voice.off(note)
  print(string.format("[%d] note_off %d",id,note))
  self.last_note[id]=nil
end

function Manager:note_on(id,note)
  print(string.format("[%d] note_on %d",id,note))
  local voice=self.voices[params:get(id.."voice")]
  voice.on(note)
  self.last_note[id]=note
end

function Manager:save(filename)
  local dump=""
  for _,track in ipairs(self.tracks) do
    dump=dump..track:dump()
    dump=dump.."---\n"
  end
  filename=filename..".txt"
  local file=io.open(filename,"w+")
  io.output(file)
  io.write(dump)
  io.close(file)
end

function Manager:load(filename)
  filename=filename..".txt"
  local f=io.open(filename,"rb")
  local lines=f:lines()
  local dumps={}
  local dump={}
  for line in lines do
    if line=="---" then
      if #dump>1 then
        table.insert(dumps,dump)
      end
      dump={}
    else
      table.insert(dump,line)
    end
  end
  f:close()
  for i,dump in ipairs(dumps) do
    self.tracks[i]:load(dump)
  end
end

function Manager:enc(k,d)
  --self.tracks[params:get("sel")]:enc(k,d)
end

function Manager:key(k,z)
  --self.tracks[params:get("sel")]:key(k,z)
end

function Manager:beat(beat_num,division)
  for _,v in ipairs(self.tracks) do
    v:beat(beat_num,division)
  end
end

function Manager:keyboard(code,value)
  if code=="TAB" and value>0 then
    params:delta("sel",1)
  elseif code=="SHIFT+TAB" and value>0 then
    params:delta("sel",-1)
  else
    self.tracks[params:get("sel")]:keyboard(code,value)
  end
end

function Manager:redraw()
  local title=self.tracks[params:get("sel")]:redraw()
  if title~=nil then
    screen.level(15)
    screen.move(30,6)
    screen.text(title)
    screen.blend_mode(1)
    screen.level(9)
    screen.rect(0,0,128,7)
    screen.fill()
    screen.rect(0,0,29,7)
    screen.fill()
  end
  screen.level(15)
  screen.move(1,6)
  screen.text(string.format("%02d->%02d",params:get("sel"),params:string(params:get("sel").."next")))
end

return Manager
