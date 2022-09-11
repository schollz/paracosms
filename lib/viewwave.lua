local ViewWave={}

function ViewWave:new(o)
  o=o or {}
  setmetatable(o,self)
  self.__index=self
  o:init()
  return o
end

function ViewWave:cursor(data)
  self.show_pos=data
  self.show=1
end

function ViewWave:is_playing()
  return self.show~=nil and self.show>0
end

function ViewWave:init()
  self.audiowaveform="/home/we/dust/code/paracosms/lib/audiowaveform"
  local foo=util.os_capture(self.audiowaveform.." --help")
  if not string.find(foo,"Options") then
    self.audiowaveform="audiowaveform"
  end
  -- extract filename
  local pathname,filename,ext=string.match(self.path,"(.-)([^\\/]-%.?([^%.\\/]*))$")

  -- print(string.format("viewwave%d: init %s",self.id,filename))

  -- load file info
  local ch,samples,samplerate=audio.file_info(self.path)
  if samples==nil or samples<10 then
    print("ERROR PROCESSING FILE: "..self.path)
    do return end
  end
  self.duration=samples/samplerate

  -- init cache
  self.cache_dir=self.cache or _path.data.."paracosms/"

  -- name files
  self.dat_file=self.cache_dir..filename..".dat"
  self.png_file=self.cache_dir..filename..".png"
  self.filename=string.upper(filename)
  self.width=128
  self.height=64-24

  if not util.file_exists(self.png_file) then
    local resolution=2
    os.execute(string.format("%s -q -i '%s' -o %s -z %d -b 8",self.audiowaveform,self.path,self.dat_file,resolution))
    os.execute(string.format("%s -q -i '%s' -o %s -s %2.4f -e %2.4f -w %2.0f -h %2.0f --background-color 000000 --waveform-color aaaaaa --no-axis-labels --compression 0",self.audiowaveform,self.dat_file,self.png_file,0,self.duration,self.width,self.height))
    os.execute("rm "..self.dat_file)
  end
  self.loaded=true
end

function ViewWave:redraw(x,y,width,height)
  if self.duration==nil then
    do return end
  end
  x=x or 0
  y=y or 8
  if not util.file_exists(self.png_file) then
    do return end
  end
  screen.display_png(self.png_file,x,y)
  if self:is_playing() then
    self.show=self.show-1
    screen.level(15)
    local cursor=self.show_pos
    local pos=util.linlin(0,self.duration,1,128,cursor)
    screen.aa(0)
    screen.level(15)
    screen.move(pos,9)
    screen.line(pos,60-12)
    screen.stroke()
    screen.aa(0)
  end
  -- draw the start/stop positions
  for _,param in ipairs({"sampleStart","sampleEnd"}) do
    if params:get(self.id..param)~=0 and params:get(self.id..param)~=1 then
      local pos=util.linlin(0,1,1,128,params:get(self.id..param))
      screen.aa(0)
      screen.blend_mode(2)
      screen.level(15)
      screen.line_width(2)
      screen.line_cap("square")
      screen.move(pos,9)
      screen.line(pos,60-12)
      screen.stroke()
      screen.blend_mode(0)
      screen.aa(0)
    end
  end

  return self.filename
end

return ViewWave
