-- paracosms
--
-- K2/K3 - switch between playing samples
-- E1 switch sample
-- E2 ?
-- E3 volume

viewwave_=include("lib/viewwave")
turntable_=include("lib/turntable")
grid_=include("lib/ggrid")

engine.name="Paracosms"
dat={percent_loaded=0,tt={},files_to_load={}}

dat.rows={
  "/home/we/dust/audio/seamlessloops/test",
}

function find_files(folder)
  local lines=util.os_capture("find "..folder.."* -print -type f -name '*.flac' -o -name '*.wav' | grep 'wav\\|flac' > /tmp/files")
  return lines_from("/tmp/files")
end

function lines_from(file)
  if not util.file_exists(file) then return {} end
  local lines={}
  for line in io.lines(file) do
    lines[#lines+1]=line
  end
  table.sort(lines)
  return lines
end

function shuffle(tbl)
  for i=#tbl,2,-1 do
    local j=math.random(i)
    tbl[i],tbl[j]=tbl[j],tbl[i]
  end
end

function initialize()
  dat.seed=18
  dat.ti=1
  dat.tt={}
  dat.percent_loaded=0
  math.randomseed(dat.seed)
  clock.run(function()
    for row,folder in ipairs(dat.rows) do
      local possible_files=find_files(folder)
      shuffle(possible_files)
      for col,file in ipairs(possible_files) do
        table.insert(dat.tt,turntable_:new{id=#dat.tt+1,path=file,row=row,col=col})
        for j=1,80 do
          clock.sleep(0.05)
          if dat.tt[#dat.tt].ready then
            break
          end
        end
      end
    end
  end)
end

function init()
  -- make sure cache directory exists
  os.execute("mkdir -p /home/we/dust/data/paracosms/cache")

  -- collect which files
  for row,folder in ipairs(dat.rows) do
    local possible_files=find_files(folder)
    for col,fname in ipairs(possible_files) do
      table.insert(dat.files_to_load,{fname=fname,id=(row-1)*16+col})
      if i==16 then
        break
      end
    end
  end

  -- parameters for each sample
  local debounce_fn={}
  for _,v in ipairs(dat.files_to_load) do
    local pathname,filename,ext=string.match(v.fname,"(.-)([^\\/]-%.?([^%.\\/]*))$")
    local id=v.id
    params:add_group(filename:sub(1,18),3)
    params:add{type='binary',name='play',id=id..'play',behavior='toggle',action=function(v)
      engine.set(id,"amp",v==1 and params:get(id.."amp") or 0,params:get(id.."fadetime"))
    end}
    params:add_control(id.."amp","amp",controlspec.new(0,4,'lin',0.01,1.0,'amp',0.01/4))
    params:set_action(id.."amp",function(v)
      debounce_fn[id]={
        3,function()
          if params:get(id.."play")==1 and params:get(id.."amp")==0 then
            params:set(id.."play",0)
          elseif params:get(id.."play")==1 then
            engine.set(id,"amp",params:get(id.."amp"),params:get(id.."fadetime"))
          end
        end,
      }
    end)
    params:add_control(id.."fadetime","fade time",controlspec.new(0,64,'lin',0.01,1,'seconds',0.01/64))
  end

  -- grid
  g_=grid_:new()

  -- osc
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
      if dat~=nil and dat.tt[id]~=nil and dat.tt[id].ready then
        g_:light_up(id,val)
      end
      do return end
    end
    if path=="ready" then
      datatype=path
    end
    if dat~=nil and dat.tt[id]~=nil then
      dat.tt[id]:oscdata(datatype,args[2])
    end
  end

  clock.run(function()
    while true do
      if #dat.files_to_load>1 and dat.percent_loaded<100 then
        local inc=100.0/#dat.files_to_load
        dat.percent_loaded=0
        for _,v in ipairs(dat.tt) do
          dat.percent_loaded=dat.percent_loaded+(v.ready and inc or 0)
        end
      end
      clock.sleep(1/10)
      redraw()
      for k,v in pairs(debounce_fn) do
        if v[1]>0 then
          debounce_fn[k][1]=debounce_fn[k][1]-1
          if debounce_fn[k][1]==0 then
            debounce_fn[k][2]()
            debounce_fn[k]=nil
          end
        end
      end
    end
  end)

  initialize()

end

function switch_view(id)
  if id>#dat.tt then
    do return end
  end
  dat.ti=id
  engine.watch(id)
end

function engine_reset()
  engine.reset()
end

local hold_beats=0
function key(k,z)
  if k==3 and z==1 then
    hold_beats=clock.get_beats()
  elseif k==3 and z==0 then
    params:set(dat.ti.."fadetime",3*clock.get_beat_sec()*(clock.get_beats()-hold_beats))
    params:set(dat.ti.."play",1-params:get(dat.ti.."play"))
  end
end

function enc(k,d)
  if k==1 then
    dat.ti=util.wrap(dat.ti+d,1,#dat.tt)
  elseif k==3 then
    params:delta(dat.ti.."amp",d)
  end
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
  local topleft=dat.tt[dat.ti]:redraw()
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

  -- top left corner
  screen.move(1,7)
  if dat.percent_loaded<99.0 then
    screen.text(string.format("loaded %2.1f%%",dat.percent_loaded))
  elseif topleft~=nil then
    screen.text(topleft:sub(1,24))
  end

  screen.move(128,7)
  screen.text_right(dat.ti)

  screen.move(128,64)
  screen.text_right(math.floor(params:get(dat.ti.."amp")*100))

  screen.update()
end
