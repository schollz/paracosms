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

debounce_fn={}
local shift=false
local ui_page=1
local enc_func={}
-- page 1
table.insert(enc_func,{
  {function(d) delta_ti(d) end},
  {function(d) params:delta(dat.ti.."lpf",d) end,function() return params:string(dat.ti.."lpf") end},
  {function(d) params:delta(dat.ti.."amp",d) end,function() return params:string(dat.ti.."amp") end},
  {function(d) delta_ti(d,true) end},
  {function(d) end},
  {function(d) end},
})
-- page 2
table.insert(enc_func,{
  {function(d) delta_ti(d) end},
  {function(d) params:delta(dat.ti.."tsSeconds",d) end,function() return "window "..params:string(dat.ti.."tsSeconds") end},
  {function(d) params:delta(dat.ti.."tsSlow",d) end,function() return "slow "..params:string(dat.ti.."tsSlow") end},
  {function(d) delta_ti(d,true) end},
  {function(d) params:delta(dat.ti.."ts",d) end,function() return "timestretch "..(params:get(dat.ti.."ts")>0 and "on" or "off") end},
  {function(d) end},
})
-- page 1
table.insert(enc_func,{
  {function(d) delta_ti(d) end},
  {function(d) params:delta(dat.ti.."sampleStart",d) end,function() return params:string(dat.ti.."sampleStart") end},
  {function(d) params:delta(dat.ti.."sampleEnd",d) end,function() return params:string(dat.ti.."sampleEnd") end},
  {function(d) delta_ti(d,true) end},
  {function(d) params:delta(dat.ti.."oneshot",d) end,function() return "mode: "..params:string(dat.ti.."oneshot") end},
  {function(d) end},
})
-- -- page 2
-- table.insert(enc_func,{
--   function(d) delta_ti(d) end,
--   function(d) params:delta(dat.ti.."tsSlow",d) end,
--   function(d) params:delta(dat.ti.."tsSeconds",d) end,
--   function(d) delta_ti(d,true) end,
--   function(d) end,
--   function(d) params:delta(dat.ti.."ts",d) end,
-- })
-- -- page 3
-- table.insert(enc_func,{
--   function(d) delta_ti(d) end,
--   function(d) params:delta(dat.ti.."sampleStart",d) end,
--   function(d) params:delta(dat.ti.."sampleEnd",d) end,
--   function(d) delta_ti(d,true) end,
--   function(d) end,
--   function(d) end,
-- })

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

function init()
  -- make sure cache directory exists
  os.execute("mkdir -p /home/we/dust/data/paracosms/cache")

  -- setup parameters
  params:add_separator("PARACOSMS")
  params:add_separator("recording")
  params:add_control("record_beats","recording length",controlspec.new(1/4,128,'lin',1/8,8.0,'beats',(1/8)/(128-0.25)))
  params:add_number("record_threshold","recording threshold (dB)",-96,0,-50)
  params:add_binary("record_on","record on","trigger")
  params:set_action("record_on",function(x)
    print("record_on",x)
  end)
  params:add_separator("samples")

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

  -- grid
  g_=grid_:new()

  -- osc
  osc_fun={
    recording=function(args)
      local id=tonubmer(args[1])
      if id~=nil then show_message("recording track "..id) end
    end,
    recorded=function(args)
      local id=tonumber(args[1])
      local filename=args[2] 
      if id~=nil and filename~=nil then 
        show_message("recorded track "..id)
        params:set(id.."file",filename)
      end
    end,
    data=function(args) -- data from the synth
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
  }
  osc.event=function(path,args,from)
    if osc_fun[path]~=nil then osc_fun[path]() else
      print("osc.event: "..path.."?")
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

  -- initialize the dat turntables
  dat.seed=18
  dat.ti=1
  dat.tt={}
  dat.percent_loaded=0
  math.randomseed(dat.seed)
  for i=1,112 do
    table.insert(dat.tt,turntable_:new{id=i})
  end

  -- load in hardcoded files
  clock.run(function()
    for row,folder in ipairs(dat.rows) do
      local possible_files=find_files(folder)
      shuffle(possible_files)
      for col,file in ipairs(possible_files) do
        local id=(row-1)*16+col
        params:set(id.."file",file)
        for j=1,80 do
          clock.sleep(0.05)
          if dat.tt[id].ready then
            break
          end
        end
      end
    end

    params:bang()
  end)

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

function delta_page(d)
  ui_page=util.wrap(ui_page+d,1,#enc_func)
end

function delta_ti(d,is_playing)
  if is_playing then
    local available_ti={}
    for i,v in ipairs(dat.tt) do
      if v:is_playing() then
        table.insert(available_ti,i)
      end
    end
    if next(available_ti)==nil then
      do return end
    end
    -- find the closest index for dat.ti
    local closest={1,10000}
    for i,ti in ipairs(available_ti) do
      if math.abs(ti-dat.ti)<closest[2] then
        closest={i,math.abs(ti-dat.ti)}
      end
    end
    local i=closest[1]
    i=util.wrap(i+d,1,#available_ti)
    dat.ti=available_ti[i]
  else
    -- find only the ones that are ready
    local available_ti={}
    for i,v in ipairs(dat.tt) do
      if v.ready then
        table.insert(available_ti,i)
      end
    end
    if next(available_ti)==nil then
      do return end
    end
    -- find the closest index for dat.ti
    local closest={1,10000}
    for i,ti in ipairs(available_ti) do
      if math.abs(ti-dat.ti)<closest[2] then
        closest={i,math.abs(ti-dat.ti)}
      end
    end
    local i=closest[1]
    i=util.wrap(i+d,1,#available_ti)
    dat.ti=available_ti[i]
    -- dat.ti=util.wrap(dat.ti+d,1,#dat.tt)
  end
end

local hold_beats=0

function key(k,z)
  if k==1 then
    shift=z==1
  elseif k==2 and z==1 then
    delta_page(1)
  elseif k==3 and z==1 then
    if params:get(dat.ti.."oneshot")==2 then
      params:set(dat.ti.."fadetime",0.001)
      params:set(dat.ti.."play",3-params:get(dat.ti.."play"))
    else
      hold_beats=clock.get_beats()
    end
  elseif k==3 and z==0 then
    if params:get(dat.ti.."oneshot")==1 then
      params:set(dat.ti.."fadetime",3*clock.get_beat_sec()*(clock.get_beats()-hold_beats))
      params:set(dat.ti.."play",3-params:get(dat.ti.."play"))
    end
  end
end

function enc(k,d)
  enc_func[ui_page][k+(shift and 3 or 0)][1](d)
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
  screen.level(7)
  screen.move(1,7)
  if dat.percent_loaded<99.0 then
    screen.text(string.format("loaded %2.1f%%",dat.percent_loaded))
  elseif topleft~=nil then
    screen.text(topleft:sub(1,24))
  end

  screen.move(128,7)
  screen.text_right(dat.ti)

  screen.level(5)
  screen.move(128,64)
  if enc_func[ui_page][3+(shift and 3 or 0)][2]~=nil then
    screen.text_right(enc_func[ui_page][3+(shift and 3 or 0)][2]())
  end

  screen.move(0,64)
  if enc_func[ui_page][2+(shift and 3 or 0)][2]~=nil then
    screen.text(enc_func[ui_page][2+(shift and 3 or 0)][2]())
  end

  screen.update()
end
