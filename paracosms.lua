-- paracosms
-- installation
--
-- llllllll.co/t/paracosms
--
--

has_installed=false
please_wait=false
install_message=""

function os_capture(cmd,raw)
  local f=assert(io.popen(cmd,'r'))
  local s=assert(f:read('*a'))
  f:close()
  if raw then return s end
  s=string.gsub(s,'^%s+','')
  s=string.gsub(s,'%s+$','')
  s=string.gsub(s,'[\n\r]+',' ')
  return s
end

function split_path(path)
  -- https://stackoverflow.com/questions/5243179/what-is-the-neatest-way-to-split-out-a-path-name-into-its-components-in-lua
  -- /home/zns/1.txt returns
  -- /home/zns/   1.txt   txt
  pathname,filename,ext=string.match(path,"(.-)([^\\/]-%.?([^%.\\/]*))$")
  return pathname,filename,ext
end

function list_folders(directory)
  local i,t,popen=0,{},io.popen
  local pfile=popen('ls -pL --group-directories-first "'..directory..'"')
  for filename in pfile:lines() do
    i=i+1
    t[i]=filename
  end
  pfile:close()
  return t
end

function reinstall()
  os.execute("rm -rf /home/we/.local/share/SuperCollider/Extensions/supercollider-plugins")
end

function install()
  please_wait=true
  redraw()

  -- install sox if not already
  print("checking sox...")
  install_message="checking sox..."
  redraw()
  os.execute("sudo apt-get install -y sox")

  -- switch branch to paracosms
  print("checking out paracosms...")
  install_message="updating paracosms..."
  redraw()
  os.execute("git -C /home/we/dust/code/paracosms checkout paracosms")

  -- download the 3rd part supercollider plugins
  install_message="installing sc plugins..."
  redraw()
  print("downloading 3rd party supercollider plugins...")
  os.execute("wget -q -O /home/we/dust/code/paracosms/ignore.zip https://github.com/schollz/supercollider-plugins/releases/download/plugins/ignore.zip")
  os.execute("cd /home/we/dust/code/paracosms && unzip ignore.zip")

  -- find the supercollider plugins to install
  os.execute("mkdir -p /home/we/.local/share/SuperCollider/Extensions/supercollider-plugins")
  local installed_files=os_capture("find /home/we/.local/share/SuperCollider/Extensions -name '*.sc'")
  installed_files=installed_files.."\n"..os_capture("find /home/we/dust/code -name '*.sc' -not -path '/home/we/dust/code/paracosms/*'")
  installed_files=installed_files.."\n"..os_capture("find /usr/share/SuperCollider/Extensions -name '*.sc'")
  for _,folder in ipairs(list_folders("/home/we/dust/code/paracosms/ignore")) do
    local one_file=os_capture("find /home/we/dust/code/paracosms/ignore/"..folder.." -name '*.sc' | head -n1")
    pathname,filename,ext=split_path(one_file)
    -- check if file exists
    if string.find(installed_files,filename) then
      print("already have "..folder.." not installing.")
    else
      print("installing "..folder..".")
      os.execute("cp -r /home/we/dust/code/paracosms/ignore/"..folder.." /home/we/.local/share/SuperCollider/Extensions/supercollider-plugins/")
    end
  end

  print("downloading audiowaveform (3MB)...")
  install_message="downloading audiowaveform..."
  redraw()

  os.execute("wget -q -O /home/we/dust/code/paracosms/lib/extra.zip https://github.com/schollz/paracosms/releases/download/release/extra.zip")
  os.execute("cd /home/we/dust/code/paracosms/lib && unzip extra.zip")
  os.execute("chmod +x /home/we/dust/code/paracosms/lib/audiowaveform")
  os.execute("chmod +x /home/we/dust/code/paracosms/lib/seamlessloop")

  print("downloading starting audio (19MB)...")
  install_message="downloading samples..."
  redraw()
  os.execute("wget -q -O /home/we/dust/code/paracosms/lib/row1.zip https://github.com/schollz/paracosms/releases/download/release/row1.zip")
  os.execute("cd /home/we/dust/code/paracosms/lib && unzip row1.zip")

  please_wait=false
  has_installed=true
end

function init()
  clock.run(function()
    while true do
      clock.sleep(1/10)
      redraw()
    end
  end)
end

function key(k,z)
  if k==3 and z==1 then
    if not has_installed and not please_wait then
      install()
    end
  end
end

function redraw()
  screen.clear()
  screen.level(15)
  if please_wait then
    screen.move(64,32)
    screen.text_center("please wait...")
    screen.move(64,52)
    screen.level(2)
    screen.text_center(install_message)
  elseif has_installed then
    screen.move(64,32)
    screen.text_center("paracosms is now")
    screen.move(64,42)
    screen.text_center("installed.")
    screen.move(64,52)
    screen.level(2)
    screen.text_center("please restart norns.")
  else
    screen.move(64,32)
    screen.text_center("paracosms awaits")
    screen.move(64,42)
    screen.text_center("press K3 to install")
    screen.move(64,52)
    screen.level(2)
    screen.text_center("(requires ~120 MB of disk)")
  end
  screen.update()
end
