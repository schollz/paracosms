-- Tracker is the interface for viewing/editing notes

local Tracker={}

function Tracker:new(o)
  o=o or {}
  setmetatable(o,self)
  self.__index=self
  o:init()
  return o
end

function Tracker:init()
  self.playing=false
  self.recording=false
  self.cursor={1,1}
  self.view={0,0} -- row/col to offset
  self.notes={}
  self.octave=3
  self.beats_per_measure=4
  self.measure=#self.notes
  self.note_played=nil

  -- https://tutorials.renoise.com/wiki/Playing_Notes_with_the_Computer_Keyboard
  self.keyboard_notes={
    "Z","S","X","D","C","V","G","B","H","N","J","M","COMMA","L","DOT","SEMICOLON","SLASH",
    "Q","2","W","3","E","R","5","T","6","Y","7","U","I","9","O","0","P","LEFTBRACE","EQUAL","RIGHTBRACE"
  }

  local divisions={}
  for _,v in ipairs(global_divisions) do
    table.insert(divisions,"1/"..math.floor(1/v))
  end
  params:add_option(self.id.."division","tracker division",divisions)
  params:set_action(self.id.."division",function(x)
    self.beats_per_measure=1/global_divisions[x]
  end)

  params:add_option(self.id.."output","tracker output",self.output_list)
  self:recalculate()
end

function Tracker:hide()
  if self.hidden==true then
    do return end
  end
  self.hidden=true
  for _,pram in ipairs(self.all_params) do
    params:hide(self.id..pram)
  end
end

function Tracker:show()
  if self.hidden==true then
    for _,pram in ipairs(self.all_params) do
      params:show(self.id..pram)
    end
    self.hidden=false
  end
end
function Tracker:dump()
  local dump=""
  for row,_ in ipairs(self.notes) do
    for col,v in ipairs(self.notes[row]) do
      if v~=nil and v~=0 then
        local note_name=musicutil_.note_num_to_name(v,true)
        note_name=v==-1 and "." or note_name
        note_name=v==-2 and "-" or note_name
        dump=dump..note_name.." "
      end
    end
    dump=dump.."\n"
  end
  return dump
end

function Tracker:load(dump)
  -- dump is an table of tables
  local notes={}
  for row,v in ipairs(dump) do
    local notelist={}
    for w in v:gmatch("%S+") do
      table.insert(notelist,self:note_name_to_num(w))
    end
    table.insert(notes,notelist)
  end
  self.notes=notes
  self:recalculate()
end

function Tracker:note_name_to_num(note)
  local num=0
  if note=="." then
    num=-1
  elseif note=="-" then
    num=-2
  else
    for num2=1,127 do
      local note_name=musicutil_.note_num_to_name(num2,true)
      if note_name==note then
        num=num2
        break
      end
    end
  end
  return num
end

function Tracker:beat(beat_num,division)
  -- if self.id==1 then
  --   print(beat_num,division,params:get(self.id.."division"),(not self.playing and not self.recording_queued and not self.recording))
  -- end
  if params:get(self.id.."division")~=division or (not self.playing and not self.recording_queued and not self.recording) then
    do return end
  end
  local beat=beat_num%self.beats_per_measure+1
  self.measure=math.floor((beat_num)/self.beats_per_measure%#self.notes)+1
  if self.measure==#self.notes and beat==self.beats_per_measure then
    -- stop recording, if recording
    local next_rec=global_rec_queue[1]
    if next_rec~=nil and next_rec[1]==self.id and next_rec[2] then
      print(string.format("[%d]: recording dequeued",self.id))
      table.remove(global_rec_queue,1)
      self.recording=false
    end
    -- do transition if transition
    if params:get(self.id.."next")~=self.id and self.playing and self.started_from_beginning then
      self:play(false)
      manager.tracks[params:get(self.id.."next")]:play(true)
      if self.id==params:get("sel") then
        params:set("sel",params:get(self.id.."next"))
      end
    end
  elseif beat==1 and self.measure==1 then
    if self.playing then
      self.started_from_beginning=true
    end
    local next_rec=global_rec_queue[1]
    if next_rec~=nil and next_rec[1]==self.id then
      -- start recording
      print(string.format("[%d]: recording go",self.id))
      --params:set("sel",self.id)
      global_rec_queue[1][2]=true
      self.recording=true
      self.recording_queued=false
      params:set("record_firstbeat",2)
      params:set(self.id.."record_immediately",2)
      params:set("record_beats",#self.notes*4)
      params:set("record_crossfade",32)
      params:set("record_predelay",0)
      params:set(self.id.."record_on",1)
      -- reset it
      clock.run(function()
        clock.sleep(0.5)
        params:set(self.id.."record_immediately",1)
        params:set(self.id.."record_on",0)
      end)
    end
  end
  -- play a note if recording or playing
  if not (self.recording or self.playing or self.recording_queued) then
    do return end
  end
  if next(self.notes_in_row)==nil then
    do return end
  end
  if self.notes_in_row[self.measure]==nil then
    do return end
  end
  local beat_per_note=self.beats_per_measure/self.notes_in_row[self.measure]
  v=0
  for col,note in ipairs(self.notes[self.measure]) do
    if note~=0 then
      v=v+1
      if util.round(beat_per_note*(v-1)+1)==beat then
        -- print("measure",self.measure,"beat",beat,note,v)
        self.note_played={self.measure,col}
        if params:get("edit_mode")==3 then
          self.cursor={self.measure-1,col}
        end
        if self.recording or self.playing then
          if note>0 then
            self.note_off(self.id)
            self.note_on(self.id,note)
          elseif note==-1 then
            self.note_off(self.id)
          end
        end
      end
    end
  end
end

function Tracker:play(on)
  local total_notes=0
  for _,row in ipairs(self.notes) do
    for _,note in ipairs(row) do
      if note~="" then
        total_notes=total_notes+1
      end
    end
  end
  if total_notes==0 then
    do return end
  end
  if on==nil then
    on=not self.playing
  end
  self.playing=on
  if not self.playing then
    self.note_off(self.id)
    self.started_from_beginning=false
  end
  global_reset_needed=global_reset_needed+(self.playing and 1 or-1)
end

function Tracker:enc(k,d)

end

function Tracker:key(k,z)

end

function Tracker:keyboard(code,value)
  print(code,value)
  if code=="ESC" and value>0 then
    local val=util.wrap(params:get("edit_mode")+1,1,3)
    params:set("edit_mode",val)
  elseif code=="CTRL+RIGHTBRACE" and value>0 then
    self.octave=util.clamp(self.octave+1,1,8)
    show_message("octave "..self.octave,0.5)
  elseif code=="CTRL+LEFTBRACE" and value>0 then
    self.octave=util.clamp(self.octave-1,1,8)
    show_message("octave "..self.octave,0.5)
  elseif code=="DOWN" and value>0 then
    self:cursor_move(1,0)
  elseif code=="SPACE" and value>0 then
    self:play()
  elseif code=="UP" and value>0 then
    self:cursor_move(-1,0)
  elseif (code=="SHIFT+LEFT" or code=="SHIFT+RIGHT") and value>0 then
    params:delta("sel",string.find(code,"LEFT") and-1 or 1)
  elseif (code=="SHIFT+UP" or code=="SHIFT+DOWN") and value>0 then
    params:delta(self.id.."output",string.find(code,"DOWN") and-1 or 1)
  elseif code=="LEFT" and value>0 then
    self:cursor_move(0,-1)
  elseif code=="RIGHT" and value>0 then
    self:cursor_move(0,1)
  elseif code=="CTRL+C" and value>0 then
    self:copy()
  elseif code=="CTRL+B" and value>0 then
    self:make_blank()
    params:set("edit_mode",3)
    self:play(true)
  elseif code=="CTRL+V" and value>0 then
    self:paste()
  elseif code=="DELETE" and value>0 then
    self:note_change(0,false,true)
  elseif code=="CTRL+R" and value>0 then
    if #self.notes==0 then
      do return end
    end
    if self.recording_queued then
      -- queue all other recordings that aren't queued
      local queued={}
      for _,v in ipairs(global_rec_queue) do
        queued[v]=true
      end
      -- unpleasant but yes, I'm calling the global parent manager from the child
      for i,track in ipairs(manager.tracks) do
        if #track.notes>0 and queued[i]==nil and track.recording_queued~=true then
          print(string.format("%d: queueing recording",i))
          table.insert(global_rec_queue,{i,false})
          manager.tracks[i].recording_queued=true
        end
      end
    else
      print(string.format("%d: queueing recording",self.id))
      table.insert(global_rec_queue,{self.id,false})
      params:set("record_over",2)
      self.recording_queued=true
    end
  else
    for i=0,9 do
      local j=i==0 and 10 or i
      if code==string.format("CTRL+%d",j) then
        params:set("sel",j)
        do return end
      end
    end
    local p="SHIFT+"
    local insert=string.find(code,p)
    code=(code:sub(0,#p)==p) and code:sub(#p+1) or code
    -- FIND THE NOTE PLAYED
    local new_note=-3
    if code=="CAPSLOCK" then
      new_note=-1
    elseif code=="TAB" then
      new_note=-2
    else
      for i,note in ipairs(self.keyboard_notes) do
        if code==note then
          if i>17 then
            i=i-5
          end
          new_note=(i-1)+((self.octave+2)*12)
          break
        end
      end
    end
    -- check if we have a new note
    if new_note>-3 and value>0 and (params:get("edit_mode")==1 or params:get("edit_mode")==3) then
      if params:get("edit_mode")==3 and value==2 then
        new_note=-2
      end
      self:note_change(new_note,insert,false)
    end
    if new_note>0 and (params:get("edit_mode")>1) then
      -- do a perform
      if value==1 then
        show_message("NOTE ON: "..musicutil_.note_num_to_name(new_note,true))
        self.note_on(self.id,new_note)
      elseif value==0 then
        show_message("NOTE OFF: "..musicutil_.note_num_to_name(new_note,true))
        self.note_off(self.id,new_note)
      end
    end
  end
end

function Tracker:copy()
  local row=self.view[1]+self.cursor[1]+1
  self.copied={}
  for _,v in ipairs(self.notes[row]) do
    table.insert(self.copied,v)
  end
end

function Tracker:paste()
  if self.copied==nil then
    do return end
  end
  local copied={}
  for _,v in ipairs(self.copied) do
    table.insert(copied,v)
  end
  local row=self.view[1]+self.cursor[1]+1
  if row<=#self.notes+1 and row>0 then
    table.insert(self.notes,row,copied)
  end
  self:recalculate()
end

function Tracker:note_change(note,insert,delete)
  local row=self.view[1]+self.cursor[1]+1
  local col=self.view[2]+self.cursor[2]
  if row>=1 and row<=#self.notes then
    if col>=1 and col<=#self.notes[row] then
      if insert then
        table.insert(self.notes[row],col,note)
      elseif delete then
        table.remove(self.notes[row],col)
      else
        self.notes[row][col]=note
      end
    elseif col<1 then
      for i=col+1,0 do
        table.insert(self.notes[row],1,0)
      end
      table.insert(self.notes[row],1,note)
    else
      for i=1,col-1 do
        if self.notes[row][i]==nil then
          table.insert(self.notes[row],0)
        end
      end
      table.insert(self.notes[row],note)
    end
  else
    for i=1,row-1 do
      if self.notes[i]==nil then
        table.insert(self.notes,{0})
      end
    end
    table.insert(self.notes,{note})
  end

  self:recalculate()
end

function Tracker:make_blank()
  for i=1,4 do
    self.notes[i]={-1,-1,-1,-1,-1,-1,-1,-1}
  end
  self:recalculate()
end

function Tracker:recalculate()
  -- remove empty rows
  local notes={}
  for _,row in ipairs(self.notes) do
    local skip_row=true
    for _,v in ipairs(row) do
      if v~=0 then
        skip_row=false
        break
      end
    end
    if not skip_row then
      table.insert(notes,row)
    end
  end
  self.notes=notes

  -- recalculate note numbers
  self.notes_in_row={}
  for i,v in ipairs(self.notes) do
    local count=0
    for _,w in ipairs(v) do
      count=count+(w~=0 and 1 or 0)
    end
    self.notes_in_row[i]=count
  end
end

function Tracker:cursor_move(row_adj,col_adj)
  local cursor={self.cursor[1]+row_adj,self.cursor[2]+col_adj}
  if cursor[1]>7 then
    cursor[1]=7
    self.view[1]=self.view[1]+1
  elseif cursor[1]<0 then
    cursor[1]=0
    self.view[1]=self.view[1]-1
  end
  if cursor[2]>8 then
    cursor[2]=8
    self.view[2]=self.view[2]+1
  elseif cursor[2]<1 then
    cursor[2]=1
    self.view[2]=self.view[2]-1
  end
  self.cursor=cursor
end

function Tracker:redraw()
  for row,_ in ipairs(self.notes) do
    if row>self.view[1] then
      for col,v in ipairs(self.notes[row]) do
        if col>self.view[2] and v~=0 then
          local note_name=musicutil_.note_num_to_name(v,true)
          note_name=v==-1 and "." or note_name
          note_name=v==-2 and "-" or note_name
          screen.level(10)
          screen.move(1+(col-1-self.view[2])*16,14+(row-1-self.view[1])*7)
          screen.text(note_name)
        end
      end
    end
  end

  screen.level(15)
  screen.blend_mode(1)
  screen.rect((self.cursor[2]-1)*16,15+(self.cursor[1]-1)*7,16,7)
  screen.fill()
  screen.blend_mode(0)
  if self.note_played~=nil and (self.recording or self.recording_queued or self.playing) then
    screen.level(5)
    screen.blend_mode(2)
    screen.rect((self.note_played[2]-1-self.view[2])*16,15+(self.note_played[1]-2-self.view[1])*7,16,7)
    screen.fill()
    screen.blend_mode(0)
  end

  local playing_string=self.playing and "PLAY" or "STOP"
  playing_string=self.recording and "REC" or playing_string
  playing_string=self.recording_queued and "QUEUED" or playing_string
  return string.format("[%s] %s %s +%d",params:string(self.id.."output"),playing_string,params:string("edit_mode"),self.octave)
end

return Tracker
