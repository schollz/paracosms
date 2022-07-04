-- 108 turntables

viewwave_=include("lib/viewwave")
turntable_=include("lib/turntable")
grid_=include("lib/ggrid")

engine.name="Paracosms"
dat={}

function lines_from(file)
  if not util.file_exists(file) then return {} end
  local lines={}
  for line in io.lines(file) do
    lines[#lines+1]=line
  end
  return lines
end

function shuffle(tbl)
  for i=#tbl,2,-1 do
    local j=math.random(i)
    tbl[i],tbl[j]=tbl[j],tbl[i]
  end
end

function init()
  dat.ti=1
  dat.tt={}
  local lines=lines_from("/home/we/dust/audio/seamlessloops/files.txt")
  local possible_files={}
  for i,line in pairs(lines) do
    if string.find(line,string.format("/%d/",clock.get_tempo())) then
      table.insert(possible_files,line)
    end
  end
  shuffle(possible_files)

  clock.run(function()
    local id=1
    for _,filetype in ipairs({"vocals","drums--ambient","synth--bass","pad--synth","chords--synth","synth--arp"}) do
      for _,file in ipairs(possible_files) do
        if string.find(file,filetype) then
          table.insert(dat.tt,turntable_:new{id=id,path=file})
          for j=1,40 do
            clock.sleep(0.05)
            if dat.tt[id].ready then
              break
            end
          end
          id=id+1
          if (id-1)%16==0 then
            break
          end
        end
      end
    end
  end)

  g_=grid_:new()

  osc.event=function(path,args,from)
    if args[1]==0 then
      do return end
    end
    local id=args[1]
    local datatype="cursor"
    if id>200 then
      id=id-200
      datatype="amplitude"
      local val=util.round(util.clamp(util.linlin(0,0.25,0,16,args[2]),2,15))
      if dat.tt[id]~=nil and dat.tt[id].ready then
        g_:light_up(id,val)
      end
      do return end
    end
    if path=="ready" then
      datatype=path
    end
    if dat.tt[id]~=nil then
      dat.tt[id]:oscdata(datatype,args[2])
    end
  end
  clock.run(function()
    while true do
      clock.sleep(1/10)
      redraw()
    end
  end)
end

function switch_view(id)
  if id>#dat.tt then
    do return end
  end
  dat.ti=id
  engine.watch(id)
end

function key(k,z)

end

function enc(k,d)

end

local show_message_text=""
local show_message_progress=0

function show_progress(val)
  show_message_progress=util.clamp(val,0,100)
end

function show_message(message,seconds)
  if show_message_clock~=nil then
    clock.cancel(show_message_clock)
  end
  show_message_clock=clock.run(function()
    show_message_text=message
    redraw()
    clock.sleep(seconds or 1.0)
    show_message_text=""
    show_message_progress=0
    redraw()
  end)
end

function redraw()
  screen.clear()
  if dat.tt[dat.ti]==nil then
    do return end
  end
  dat.tt[dat.ti]:redraw()
  if show_message_text~="" then
    screen.blend_mode(0)
    local x=64
    local y=28
    local w=screen.text_extents(show_message_text)+8
    screen.rect(x-w/2,y,w,10)
    screen.level(0)
    screen.fill()
    screen.rect(x-w/2,y,w,10)
    screen.level(15)
    screen.stroke()
    screen.move(x,y+7)
    screen.level(10)
    screen.text_center(show_message_text)
    if show_message_progress>0 then
      screen.update()
      screen.blend_mode(13)
      screen.rect(x-w/2,y,w*(show_message_progress/100),9)
      screen.level(10)
      screen.fill()
      screen.blend_mode(0)
    end
  end
  screen.update()
end
