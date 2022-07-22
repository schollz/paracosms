local GGrid={}
local patterner=include("lib/patterner")

function GGrid:new(args)
  local m=setmetatable({},{__index=GGrid})
  local args=args==nil and {} or args

  m.apm=args.apm or {}
  m.grid_on=args.grid_on==nil and true or args.grid_on

  -- initiate the grid
  local midigrid=util.file_exists(_path.code.."midigrid")
  local grid=midigrid and include "midigrid/lib/mg_128" or grid
  m.g=grid.connect()
  m.g.key=function(x,y,z)
    if m.grid_on then
      m:grid_key(x,y,z)
    end
  end
  print("grid columns: "..m.g.cols)

  -- setup visual
  m.visual={}
  m.grid_width=16
  for i=1,8 do
    m.visual[i]={}
    for j=1,16 do
      m.visual[i][j]=0
    end
  end

  -- keep track of pressed buttons
  m.pressed_buttons={}

  -- grid refreshing
  m.grid_refresh=metro.init()
  m.grid_refresh.time=midigrid and 0.12 or 0.105
  m.grid_refresh.event=function()
    if m.grid_on then
      m:grid_redraw()
    end
  end
  m.grid_refresh:start()

  m.light_setting={}
  m.patterns={}
  table.insert(m.patterns,patterner:new())

  m:init()
  return m
end

function GGrid:init()
  self.blink=0
  self.page=1
  self.key_press_fn={}
  -- page 1, selection/toggling
  table.insert(self.key_press_fn,function(row,col,on,id,hold_time)
    if on then
      switch_view(id)
    end
    if params:get(id.."oneshot")==2 then
      if on then
        print("oneshot")
        dat.tt[id]:play(true,true)
      end
    elseif hold_time>0.25 then
      print("loop")
      params:set(id.."fadetime",hold_time*3)
      params:set(id.."play",3-params:get(id.."play"))
    end
  end)
  -- page 2, recording
  table.insert(self.key_press_fn,function(row,col,on,id,hold_time)
    if on then
      do return end
    end
    if hold_time<1 then
      -- set recording time
      params:set("record_beats",id/4)
    else
      -- select and do record
      params:set("sel",id)
      params:delta(id.."record_on",1)
    end
  end)
  -- page 3, pattern recorder
  table.insert(self.key_press_fn,function(row,col,on,id,hold_time)
    self.key_press_fn[1](row,col,on,id,hold_time)
    self.patterns[1]:add(function() g_.key_press_fn[1](row,col,on,id,hold_time) end)
  end)
end

function GGrid:grid_key(x,y,z)
  self:key_press(y,x,z==1)
  self:grid_redraw()
end

function GGrid:key_press(row,col,on)
  local ct=clock.get_beats()*clock.get_beat_sec()
  local hold_time=0
  if on then
    self.pressed_buttons[row..","..col]=ct
  else
    hold_time=ct-self.pressed_buttons[row..","..col]
    self.pressed_buttons[row..","..col]=nil
  end
  local id=(row-1)*16+col
  if row==8 then
    if on then
      local old_page=self.page
      self.page=(col<=#self.key_press_fn) and col or self.page
      self.page_switched=old_page==self.page
    elseif col==3 then
      if hold_time>0.5 then
        -- record a pattern
        self.patterns[1]:record()
      elseif not self.page_switched then
        self.patterns[1]:play()
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
  -- clear visual
  local id=0
  for row=1,7 do
    for col=1,self.grid_width do
      id=id+1
      if self.page==2 then
        if id/4<=params:get("record_beats") then
          self.visual[row][col]=10
        end
      else
        self.visual[row][col]=self.light_setting[id] or 0
        if self.light_setting[id]~=nil and self.light_setting[id]>0 then
          self.light_setting[id]=self.light_setting[id]-1
        end
        if dat.tt~=nil and dat.tt[id]~=nil and dat.tt[id].ready and self.visual[row][col]==0 then
          self.visual[row][col]=1
        end
      end
      -- always blink
      if id==dat.ti then
        self.blink=self.blink-1
        if self.blink<-0.5/self.grid_refresh.time then
          self.blink=0.5/self.grid_refresh.time
        end
        if self.blink>0 then
          self.visual[row][col]=15
        end
      end
    end
  end

  -- highlight available pages / current page
  for i,_ in ipairs(self.key_press_fn) do
    self.visual[8][i]=self.page==i and 15 or 5
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
