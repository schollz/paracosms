-- Manager manages the trakcs

local Manager={}

function Manager:new(o)
  o=o or {}
  setmetatable(o,self)
  self.__index=self
  o:init1()
  return o
end

function Manager:init1()
  self.tracks={}
  self.num_tracks=112
  self.last_note={}

  -- setup outputs
  self.outputs={}
  for _,v in ipairs(midi_device) do
    table.insert(self.outputs,{
      name=v.name,
      note_on=v.note_on,
      note_off=v.note_off,
      mono=false,
    })
  end
  for i=1,2 do
    table.insert(self.outputs,{
      name=string.format("crow %d+%d",(i-1)*2+1,(i-1)*2+2),
      note_on=function(note,vel,ch)
        print("crow note_on",note)
        crow.output[(i-1)*2+1].volts=(note-24)/12
        crow.output[(i-1)*2+2](true)
      end,
      note_off=function(note,vel,ch)
        crow.output[(i-1)*2+2](false)
      end,
      mono=true,
    })
  end

  self.output_list={}
  for _,v in ipairs(self.outputs) do
    table.insert(self.output_list,v.name)
  end

end

function Manager:init()
  -- setup trackers
  for i=1,self.num_tracks do
    table.insert(self.tracks,tracker_:new{id=i,output_list=self.output_list,
      note_on=function(id,device_id,note) self:note_on(id,device_id,note) end,
    note_off=function(id,device_id,note) self:note_off(id,device_id,note) end})
  end

  params:add_option("edit_mode","edit_mode",{"EDIT","PERF"},1)
  params:hide("edit_mode")
end

function Manager:note_off(id,device_id,note)
  if device_id==1 or device_id==nil then
    do return end
  end
  if self.last_note[id]==nil and note==nil then
    do return end
  end
  if note==nil then
    note=self.last_note[id]
  end
  print(string.format("[%d:%s] note_off %d",id,self.outputs[device_id].name,note))
  self.outputs[device_id].note_off(note)
  self.last_note[id]=nil
end

function Manager:note_on(id,device_id,note)
  if device_id==1 then
    do return end
  end
  print(id,device_id,note)
  if self.outputs[device_id].mono==true and self.last_note[id]~=nil then
    self.outputs[device_id].note_off()
  end
  print(string.format("[%d:%s] note_on %d",id,self.outputs[device_id].name,note))
  self.outputs[device_id].note_on(note)
  self.last_note[id]=note
end

function Manager:save(filename)
  local dump=""
  for _,track in ipairs(self.tracks) do
    dump=dump..track:dump()
    dump=dump.."---\n"
  end
  local file=io.open(filename,"w+")
  io.output(file)
  io.write(dump)
  io.close(file)
end

function Manager:load(filename)
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
  self.tracks[params:get("sel")]:keyboard(code,value)
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
