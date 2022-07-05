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

function ViewWave:init()
  print("ViewWave:init",self.path)
  pathname,filename,ext=string.match(self.path,"(.-)([^\\/]-%.?([^%.\\/]*))$")
  self.path="/tmp/paracosms"..filename
  self.filename=string.upper(filename)
  local ch,samples,samplerate=audio.file_info(self.path)
  if samples<10 or samples==nil then
    print("ERROR PROCESSING FILE: "..self.path)
    do return end
  end
  self.duration=samples/samplerate
  if self.duration==nil then
    do return end
  end
  self.waveform_file=_path.data.."paracosms/"..self.id
  self.dat_file=_path.data.."paracosms/"..self.id..".dat"
  self.png_file="/dev/shm/"..self.id..".png"
  local resolution=120
  os.execute(string.format("/home/we/dust/code/paracosms/lib/audiowaveform -q -i %s -o %s -z %d -b 8",self.path,self.dat_file,resolution))
  self.width=0
  self.height=0
  self.loaded=true
end

function ViewWave:render()
  if self.duration==nil then
    do return end
  end
  print(self.dat_file,self.png_file,0,self.duration,self.width,self.height)
  os.execute(string.format("/home/we/dust/code/paracosms/lib/audiowaveform -q -i %s -o %s -s %2.4f -e %2.4f -w %2.0f -h %2.0f --background-color 000000 --waveform-color aaaaaa --no-axis-labels --compression 0",self.dat_file,self.png_file,0,self.duration,self.width,self.height))
end

function ViewWave:redraw(x,y,width,height)
  if self.duration==nil then
    do return end
  end
  x=x or 0
  y=y or 6
  width=width or 128
  height=height or 64
  if width~=self.width or height~=self.height then
    self.width=width
    self.height=height
    self:render()
  end
  if not util.file_exists(self.png_file) then
    do return end
  end
  screen.display_png(self.png_file,x,y)
  if self.show~=nil and self.show>0 then
    self.show=self.show-1
    screen.level(15)
    local cursor=self.show_pos
    local pos=util.linlin(0,self.duration,1,128,cursor)
    screen.aa(1)
    screen.level(15)
    screen.move(pos,64-self.height)
    screen.line(pos,64)
    screen.stroke()
    screen.aa(0)
  end
end

return ViewWave
