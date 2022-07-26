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

  -- setup crow
  params:add_group("CROW",8)
  for j=1,2 do
    local i=(j-1)*2+2
    params:add_control(i.."crow_attack",string.format("crow %d attack",i),controlspec.new(0.01,4,'lin',0.01,0.2,'s',0.01/3.99))
    params:add_control(i.."crow_sustain",string.format("crow %d sustain",i),controlspec.new(0,10,'lin',0.1,7,'volts',0.1/10))
    params:add_control(i.."crow_decay",string.format("crow %d decay",i),controlspec.new(0.01,4,'lin',0.01,0.5,'s',0.01/3.99))
    params:add_control(i.."crow_release",string.format("crow %d release",i),controlspec.new(0.01,4,'lin',0.01,0.2,'s',0.01/3.99))
    for _,v in ipairs({"attack","sustain","decay","release"}) do
      params:set_action(i..v,function(x)
        debounce_fn[i.."crow"]={
          5,function()
            crow.output[i].action=string.format("adsr(%3.3f,%3.3f,%3.3f,%3.3f,'linear')",
            params:get(i.."crow_attack"),params:get(i.."crow_sustain"),params:get(i.."crow_decay"),params:get(i.."crow_release"))
          end,
        }
      end)
    end
  end

  -- setup outputs
  self.outputs={}
  for _,v in ipairs(midi_devices) do
    table.insert(self.outputs,{
      name=v.name,
      note_on=v.note_on,
      note_off=v.note_off,
    })
  end
  for i=1,2 do
    table.insert(self.outputs,{
      name=string.format("crow %d+%d",(i-1)*2+1,(i-1)*2+2),
      note_on=function(note,vel,ch)
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

  -- setup trackers
  for i=1,self.num_tracks do
    table.insert(self.tracks,tracker_:new{id=i,output_list=self.output_list,
      note_on=function(note) self:note_on(i,j,note) end,
    note_off=function() self:note_off(i,j) end})
  end

end

function Manager:note_off(id,device_id,note)
  if self.last_note[id]==nil and note==nil then
    do return end
  end
  if note==nil then
    note=self.last_note[id]
  end
  print(string.format("[%d:%s] note_off %d",id,self.outputs[device_id].name,note))
  self.outputs[device_id]:note_off(note)
  self.last_note[id]=nil
end

function Manager:note_on(id,device_id,note)
  if self.outputs[device_id].mono and self.last_note[id]~=nil then
    self.outputs[device_id]:note_off()
  end
  print(string.format("[%d:%s] note_on %d",id,self.outputs[device_id].name,note))
  self.outputs[device_id]:note_on(note)
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
