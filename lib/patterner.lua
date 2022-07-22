local Pattern={}

function Pattern:new(o)
  o=o or {}
  setmetatable(o,self)
  self.__index=self
  o:init()
  return o
end

function Pattern:init()
  self.loaded=false
  self.recording=false
  self.primed=false
  self.playing=false
  self.eigth_notes=8*4
  self.en_rec=0
  self.pattern={}
end

function Pattern:add(fn)
  if not self.recording and not self.primed then
    do return end
  end
  if self.primed then
    self.primed=false
    self.recording=true
    self.pattern={}
    self.en_rec=1
    self.eigth_notes=params:get("record_beats")*4
  end
  -- move to the next beat in case its closer
  if (self.last_en-clock.get_beats())>3/16 and self.en_rec>1 then
    self.en_rec=self.en_rec+1
  end
  table.insert(self.pattern,{en=self.en_rec,fn=fn})
end

function Pattern:record()
  self.primed=true
  self.playing=false
  self.recording=false
end

function Pattern:stop()
  self.playing=false
end

function Pattern:play()
  if self.recording or not self.loaded then
    do return end
  end
  self.playing=true
end

function Pattern:toggle()
  self.recording=false
  self.primed=false
  self.playing=not self.playing
end

function Pattern:emit(global_beat)
  if self.recording then
    self.last_en=clock.get_beats()
    self.en_rec=self.en_rec+1
    if self.en_rec>self.eigth_notes then
      self.en_rec=0
      self.recording=false
    end
  elseif self.playing then
    local en=(global_beat-1)%self.eigth_notes+1
    for _,v in ipairs(self.pattern) do
      if v.en==en then
        v.fn()
      end
    end
  end
end

return Pattern
