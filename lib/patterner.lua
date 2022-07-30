local Pattern={}

function Pattern:new(o)
  o=o or {}
  setmetatable(o,self)
  self.__index=self
  o:init()
  return o
end

function Pattern:init()
  self.recorded=false
  self.recording=false
  self.primed=false
  self.playing=false
  self.sixteenth_notes=16*4
  self.en_rec=0
  self.pattern={}
end

function Pattern:dump()
  local dump={pattern={},beats=self.beats}
  for i,p in ipairs(self.pattern) do
    table.insert(dump.pattern,{diff=p.diff,fn=p.fn})
  end
  return dump
end

function Pattern:load(dump)
  self.pattern={}
  for i,p in ipairs(dump.pattern) do
    table.insert(self.pattern,{diff=p.diff,played=false,fn=p.fn})
  end
  if #self.pattern>0 then
    self.recorded=true
    self.beats=dump.beats
  end
end

function Pattern:add(fn)
  if not self.recording and not self.primed then
    do return end
  end
  if self.primed then
    self.primed=false
    self.recording=true
    self.pattern={}
    self.rec_start=clock.get_beats()
    self.beats=params:get("record_beats")
  end
  local beat_diff=clock.get_beats()-self.rec_start
  print("adding",beat_diff,fn)
  table.insert(self.pattern,{diff=beat_diff,fn=fn,played=false})
  self.recorded=true
end

function Pattern:record()
  print("patterner: record")
  self.primed=true
  self.playing=false
  self.recording=false
end

function Pattern:toggle()
  self.recording=false
  self.primed=false
  if not self.recorded then
    do return end
  end
  print("patterner: toggle")
  self.playing=not self.playing
  global_reset_needed=global_reset_needed+(self.playing and 1 or-1)
end

function Pattern:emit(global_beat)
  if self.recording then
    if clock.get_beats()-self.rec_start>self.beats then
      print("recording stopped")
      self:toggle()
    end
  elseif self.playing then
    local beat=((global_beat-1)%(self.beats*4))/4 -- [0,total)
    if beat==0 then
      -- reset
      for i,_ in ipairs(self.pattern) do
        self.pattern[i].played=false
      end
    end
    for i,v in ipairs(self.pattern) do
      if not v.played and math.abs(v.diff-beat)<0.125 then
        -- print(i,beat,v.diff,v.fn)
        load(v.fn)()
        self.pattern[i].played=true
      end
    end
  end
end

return Pattern
