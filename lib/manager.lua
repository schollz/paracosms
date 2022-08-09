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
  table.insert(self.outputs,{
    name="smpl-pos",
    note_on=function(id,note,vel,ch)
      -- make sure it is in oneshot mode
      if params:get("edit_mode")==2 then
        show_manager=false
      end
      if params:get(id.."output")<3 and params:get(id.."oneshot")==1 then
        params:set(id.."oneshot",2)
      end
      params:set(id.."sampleStart",(note%params:get(id.."tracker_slices"))/params:get(id.."tracker_slices"))
      params:set(id.."play",1)
    end,
    note_off=function(id,note)
      params:set(id.."play",0)
    end,
    mono=true,
  })
  table.insert(self.outputs,{
    name="smpl-pitch",
    note_on=function(id,note,vel,ch)
      -- make sure it is in oneshot mode
      if params:get("edit_mode")==2 then
        show_manager=false
      end
      local new_rate=musicutil_.note_num_to_freq(note)/musicutil_.note_num_to_freq(params:get(id.."source_note"))
      params:set(id.."rate",new_rate)
      params:set(id.."play",1)
    end,
    note_off=function(id,note)
      params:set(id.."play",0)
    end,
    mono=true,
  })
  -- TODO: do similar for sample pitch?
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
      note_on=function(id_,note,vel,ch)
        print("crow note_on",note)
        crow.output[(i-1)*2+1].volts=(note-24)/12
        crow.output[(i-1)*2+2](true)
      end,
      note_off=function(id_,note,vel,ch)
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
      note_on=function(id,note) self:note_on(id,note) end,
    note_off=function(id,note) self:note_off(id,note) end})
  end

  params:add_option("edit_mode","edit_mode",{"EDIT","PERF","EDRF"},1)
  params:hide("edit_mode")
end

function Manager:note_off(id,note)
  if self.last_note[id]==nil and note==nil then
    do return end
  end
  if note==nil then
    note=self.last_note[id]
  end
  local device_id=params:get(id.."output")
  print(string.format("[%d:%s] note_off %d",id,self.outputs[device_id].name,note))
  self.outputs[device_id].note_off(id,note)
  self.last_note[id]=nil
end

function Manager:note_on(id,note)
  local device_id=params:get(id.."output")
  print(id,device_id,note)
  if self.outputs[device_id].mono==true and self.last_note[id]~=nil then
    self.outputs[device_id].note_off(id)
  end
  print(string.format("[%d:%s] note_on %d",id,self.outputs[device_id].name,note))
  self.outputs[device_id].note_on(id,note)
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
  print("manager: loading",filename)
  local f=io.open(filename,"rb")
  local lines=f:lines()
  local dumps={}
  local dump={}
  for line in lines do
    line=(line:gsub("^%s*(.-)%s*$","%1"))
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
