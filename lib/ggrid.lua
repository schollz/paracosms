-- local pattern_time = require("pattern")
local GGrid={}

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
    for j=1,m.grid_width do
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
  return m
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
  print(row,col,hold_time)
  local id=(row-1)*16+col
  if on then
    switch_view(id)
  end
  if hold_time>0.25 then
    params:set(id.."fadetime",hold_time*3)
    params:set(id.."play",1-params:get(id.."play"))
  end
end

function GGrid:light_up(id,val)
  self.light_setting[id]=val
end

function GGrid:get_visual()
  -- clear visual
  local id=0
  for row=1,8 do
    for col=1,self.grid_width do
      id=id+1
      self.visual[row][col]=self.light_setting[id] or 0
      if self.light_setting[id]~=nil and self.light_setting[id]>0 then
        self.light_setting[id]=self.light_setting[id]-1
      end
      if dat.tt~=nil and dat.tt[id]~=nil and dat.tt[id].ready and self.visual[row][col]==0 then
        self.visual[row][col]=1
      end
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
      if gd[row][col]~=0 then
        self.g:led(col+adj,row,gd[row][col])
      end
    end
  end
  self.g:refresh()
end

function GGrid:redraw()

end

return GGrid
