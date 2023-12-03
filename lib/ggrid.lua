-- make using grid 64 nicer.
--    change sample slot layout to 7 rows of 8 samples, sample slots higher than 56 ignored on device
--    clamp sample loading to 8 samples per row
--    decrease time scale of sample start/end/duration to fit on 8x7 layout

-- nice-to-have:
--    detect changing grid device so proper layout maintained for 64 and 128 grids
--      (do this in lib/paracosms?)
--    samples then higher than 56 populate slots
--    affect on time-scale? TBD
   
local GGrid={}

function GGrid:new(args)
  local m=setmetatable({},{__index=GGrid})
  local args=args==nil and {} or args

  m.apm=args.apm or {}
  m.grid_on=args.grid_on==nil and true or args.grid_on

  -- initiate the grid
  local midigrid=util.file_exists(_path.code.."midigrid")
  local grid=midigrid and include "midigrid/lib/mg_128" or grid -- DONE allow for midigrid 64 - midigrid defaults to 64, so if the previous line evals we should be good
  
  m.g=grid.connect()
  m.g.key=function(x,y,z)
    if m.grid_on then
      m:grid_key(x,y,z)
    end
  end
  print("grid columns: "..m.g.cols)

  -- setup visual
  m.visual={}
  m.grid_width=m.g.cols   		-- DONE check m.g.cols for m.grid_width
  for i=1,8 do
    m.visual[i]={}
    for j=1,m.grid_width do		-- DONE iterate per width
      m.visual[i][j]=0
    end
  end

  -- keep track of pressed buttons
  m.pressed_buttons={}

  -- grid refreshing
  m.grid_refresh=metro.init()
  m.grid_refresh.time=midigrid and 0.12 or 0.07
  m.grid_refresh.event=function()
    if m.grid_on then
      m:grid_redraw()
    end
  end
  m.grid_refresh:start()

  m.light_setting={}
  m.patterns={}
  for i=3,m.grid_width do			-- DONE iterate per width
    table.insert(m.patterns,patterner:new())
  end

  m:init()
  return m
end

function GGrid:init()
  self.blink=0
  self.blink2=0
  self.fader={}
  for i=1,self.grid_width do			-- DONE iterate per width
    table.insert(self.fader,{0,0.75,3})
  end
  self.page=3
  self.pressed_ids={}
  self.key_press_fn={}
  -- page 1 recording
  table.insert(self.key_press_fn,function(row,col,on,id,hold_time)
		  params:set("record_beats",id/(self.grid_width/4)) -- DONE assuming id/4 was based on width of 16
  end)
  -- page 2 sample start/end
  table.insert(self.key_press_fn,function(row,col,on,id,hold_time,datti)
    if not on then
      do return end
    end
    local from_pattern=datti~=nil
    if datti==nil then
      datti=dat.ti
    end
    -- check to see if two notes are held down and set the start/end based on them
    if row<5 then
      -- set sample start position
      params:set(datti.."sampleStart",util.round(util.linlin(1,64,0,1,id),1/64)) --DONE safe to not change per https://github.com/schollz/paracosms/issues/16#issuecomment-1836432419
      params:set(datti.."sampleEnd",params:get(datti.."sampleStart")+params:get(datti.."sampleDuration"))
    elseif row>5 then
      -- set sample duration
       params:set(datti.."sampleDuration",util.linlin(1,32,1/64,1.0,id-(5*self.grid_width))) -- DONE assuming fifth arg originally was row*width
      params:set(datti.."sampleEnd",params:get(datti.."sampleStart")+params:get(datti.."sampleDuration"))
    end
    if not from_pattern then
      local ti=dat.ti
      dat.tt[dat.ti].sample_pattern:add(("g_.key_press_fn[2]("..row..","..col..","..(on and "true" or "false")..","..id..","..hold_time..","..ti..")"))
    end
  end)
  -- page 3 and beyond: playing
  for i=3,self.grid_width do			-- DONE iterate per width
    table.insert(self.key_press_fn,function(row,col,on,id,hold_time,from_pattern)
      if on and from_pattern==nil then
        switch_view(id)
      end
      if params:get(id.."oneshot")==2 then
        params:set(id.."play",on and 1 or 0)
        if not on and hold_time>0.5 then
          params:set(id.."sequencer",3-params:get(dat.ti.."sequencer"))
        end
      elseif hold_time>0.25 or (params:get("grid_touch")>1 and not on) then
        if hold_time<0.25 and params:get("grid_touch")==2 then
          hold_time=0.2
        else
          hold_time=math.pow(hold_time*1.5,2)
        end
        print("grid press hold",hold_time)
        if params:get(id.."play")==1 then
          params:set(id.."release",hold_time)
        else
          params:set(id.."attack",hold_time)
        end
        params:delta(id.."play",1)
      end
      if from_pattern==nil then
        self.patterns[i-2]:add("g_.key_press_fn["..i.."]("..row..","..col..","..(on and "true" or "false")..","..id..","..hold_time..",true)")
      end
    end)
  end
end

function GGrid:grid_key(x,y,z)
  self:key_press(y,x,z==1)
  self:grid_redraw()
end

function GGrid:key_press(row,col,on)
  local ct=clock.get_beats()*clock.get_beat_sec()
  local hold_time=0
  local id=(row-1)*self.grid_width+col	-- CHECK set per width, if ids persisted, a problem with reloading on grid device change?
  if on then
    self.pressed_buttons[row..","..col]=ct
    self.pressed_ids[id]=true
  else
    hold_time=ct-self.pressed_buttons[row..","..col]
    self.pressed_buttons[row..","..col]=nil
    self.pressed_ids[id]=nil
  end
  if row==8 then
    if on then
      local old_page=self.page
      self.page=(col<=#self.key_press_fn) and col or self.page
      self.page_switched=old_page~=self.page
    elseif col>1 then -- pattern start/stop
      if self.page_switched then
        do return end
      end
      if hold_time>0.5 then
        -- record a pattern
        if col>2 then
          print("ggrid: recording key pattern on",col-2)
          self.patterns[col-2]:record()
        else
          print("ggrid: recording edge pattern on",dat.ti)
          dat.tt[dat.ti].sample_pattern:record()
        end
      else
        -- toggle a pattern
        if col>2 then
          print("ggrid: toggling key pattern on",col-2)
          self.patterns[col-2]:toggle()
        else
          print("ggrid: toggling edge pattern on",dat.ti)
          dat.tt[dat.ti].sample_pattern:toggle()
        end
      end
    end
  else
    self.key_press_fn[self.page](row,col,on,id,hold_time)
  end
end

function GGrid:light_up(id,val)
  self.light_setting[id]=val
end

function GGrid:get_visual()
  if dat==nil or dat.ti==nil then
    do return end
  end
  -- clear visual
  local id=0
  local sampleSD={}
  if self.page==2 then
    sampleSD[1]=util.round(util.linlin(0,1,1,64,params:get(dat.ti.."sampleStart"))) -- DONE assuming safe as previous sampleStart
    sampleSD[2]=util.round(util.linlin(1/64,1,1,32,params:get(dat.ti.."sampleDuration"))) -- DONE supra
    sampleSD[3]=util.round(util.linlin(0,1,1,64,params:get(dat.ti.."sampleEnd"))) -- DONE supra
  end
  -- DONE modify following tests of ids based on range available per width; 
  for row=1,7 do
    for col=1,self.grid_width do
      id=id+1
      if self.page==2 then
        if id==sampleSD[1] then
          self.visual[row][col]=5
        elseif id>0 and id<=self.grid_width*4 and id<=sampleSD[3] and id>sampleSD[1] then
          self.visual[row][col]=3
        elseif id>self.grid_width*5 and id-(self.grid_width*5)<=sampleSD[2] then
          self.visual[row][col]=5
        elseif id>0 and id<=self.grid_width*4 then
          self.visual[row][col]=2
        elseif id>self.grid_width*5 and id<=self.grid_width*7 then
          self.visual[row][col]=2
        else
          self.visual[row][col]=0
        end
      elseif self.page==1 then
        -- recording
	 if id<=params:get("record_beats")*(self.grid_width/4) then -- DONE modify test related to duration per width as earlier
          self.visual[row][col]=dat.tt[dat.ti].recording and 10 or 3 -- TODO modify per width?
        else
          self.visual[row][col]=0
        end
      else
        self.visual[row][col]=self.light_setting[id] or 0
        if self.light_setting[id]~=nil and self.light_setting[id]>0 then
          self.light_setting[id]=self.light_setting[id]-1
        end
        if dat.tt~=nil and dat.tt[id]~=nil and dat.tt[id].ready and self.visual[row][col]==0 then
          self.visual[row][col]=2
        end
      end
      -- always blink
      if id==dat.ti then
        self.blink=self.blink-1
        if self.blink<-1 then
          self.blink=6
        end
        if self.blink>0 then
          self.visual[row][col]=5-self.visual[row][col]
          self.visual[row][col]=(self.visual[row][col]<0 and 0 or self.visual[row][col])
        end
      end
    end
  end

  -- highlight available pages / current page
  for i,_ in ipairs(self.key_press_fn) do
    self.visual[8][i]=self.page==i and 4 or 1
  end
  self.fader[1][1]=self.fader[1][1]+self.fader[1][2]
  if self.fader[1][1]>self.fader[1][3] or self.fader[1][1]<-1 then
    self.fader[1][2]=-1*self.fader[1][2]
  end
  self.visual[8][2]=self.visual[8][2]+(dat.tt[dat.ti].sample_pattern.playing and util.round(self.fader[1][1]) or 0)
  if dat.tt[dat.ti].sample_pattern.recording or dat.tt[dat.ti].sample_pattern.primed then
    self.blink2=self.blink2-1
    if self.blink2<-1 then
      self.blink2=1
    end
    self.visual[8][2]=self.blink2>0 and self.visual[8][2] or 0
  end
  for i,v in ipairs(self.patterns) do
    self.fader[i+1][1]=self.fader[i+1][1]+self.fader[i+1][2]
    if self.fader[i+1][1]>self.fader[i+1][3] or self.fader[i+1][1]<-1 then
      self.fader[i+1][2]=-1*self.fader[i+1][2]
    end
    self.visual[8][i+2]=self.visual[8][i+2]+(v.playing and util.round(self.fader[i+1][1]) or 0)
    if v.recording or v.primed then
      self.blink2=self.blink2-1
      if self.blink2<-1 then
        self.blink2=1
      end
      self.visual[8][i+2]=self.blink2>0 and self.visual[8][i+2] or 0
    end
  end

  return self.visual
end

function GGrid:grid_redraw()
  self.g:all(0)
  local gd=self:get_visual()
  local s=1
  local e=self.grid_width
  local adj=0
  for row=1,8 do
    for col=s,e do
      if gd~=nil and gd[row]~=nil and gd[row][col]~=0 then
        self.g:led(col+adj,row,gd[row][col])
      end
    end
  end
  self.g:refresh()
end

function GGrid:redraw()

end

return GGrid
