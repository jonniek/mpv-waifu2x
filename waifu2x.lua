require 'mp.options'

--below are keybind names, can be changed in input.conf with - KEY script-binding waifu2x
local scriptoptions = {
  --keybind names for your script navigation, needs to be unique, user can change in input.conf with this name

  --the name for your scripts .conf file in lua-settings 
  name = "waifu2x", --default CTRL+S

  favorite = "waifu2x-favorite", --default CTRL+X
  navup = "waifu2x-up", --default dynamic key UP
  navdown = "waifu2x-down", --default dynamic key DOWN
  naventer = "waifu2x-enter", --default dynamic key ENTER
}

--below are options available to change, can be overridden in lua-settings/waifu2x.conf
local conf = {
  use_dynamic_keybinds = true, --waifu2x keybind will register dynamic keys for navigating that will temporarily override their original keybinding
  local_waifu = true, --false not implemented yet, looking for a good webapi for that
  osd_duration_seconds = 4,
  png = false, --jpg png toggle for screenshots, convert image tries to keep original
  waifupath = "/home/anon/software/waifu2x/", --path to dir where waifu2x.lua is, trail with /
  output = "~/Pictures/waifu2x/", --path to save screenshots to, image converts are saved to same directory

  --favorite shortcut
  --"0x"/"2x"   -scale 
  --"no"/"0"-"3"   -noise
  --"Screenshot"/"Image convert"   -screenshot or source image
  --use strings
  favorite = { [0]="2x", [1]="2", [3]="Screenshot"},

  force_cudnn = false, --untested, if it doesnt work its probably in the order of arguments in waifu2x funtion os.captures
}
read_options(conf, scriptoptions.name)

--global variables
local state = {
  cursor = 0,
  
  listtype = { [0] = "Screenshot", [1] = "Image convert"},

  listsize = { [0] = "0x", [1] = "2x"},

  listnoise = { [0] = "no", [1] = "0", [2] = "1", [3] = "2", [4] = "3" },

  selection ={},
  step=0,
  length=0,
  keybinds_active = false,
}

function waifu2x(cmd, silent)
  removekeybinds()
  local cudnn = ""
  if conf.force_cudnn then cudnn = " -force_cudnn 1" end
  local scale = ""
  local noise = ""
  if cmd[1] == "no" and cmd[0] == "0x" then
    mp.commandv("screenshot")
    mp.osd_message("No scale or noise, taking normal screenshot")
    return
  elseif cmd[1] == "no" then
    scale = "scale "
  elseif cmd[1] ~= "no" and cmd[0] ~= "0x" then
    scale = "noise_scale "
  elseif cmd[1] ~= "no" and cmd[0] == "0x" then
    scale = "noise "
  end
  if cmd[1] ~= "no" then noise = "-noise_level "..cmd[1].." " end

  if cmd[3] == "Screenshot" then
    if not silent then mp.osd_message("Taking waifu2x screenshot!") end
    local subtitles = mp.get_property("sub-text")
    local timestamp = os.time()
    if subtitles == "" then subtitles = "video" else subtitles = "subtitles" end

    mp.commandv("screenshot-to-file", "/tmp/mpv-waifu2x-screenshot.png", subtitles)

    if conf.png then
      os.capture("cd "..conf.waifupath.."; th waifu2x.lua"..cudnn.." -m "..scale..noise.."-i /tmp/mpv-waifu2x-screenshot.png -o "..conf.output..timestamp..".png")
    else
      os.capture("cd "..conf.waifupath.."; th waifu2x.lua"..cudnn.." -m "..scale..noise.."-i /tmp/mpv-waifu2x-screenshot.png -o /tmp/mpv-waifu2x-screenshot.png; convert /tmp/mpv-waifu2x-screenshot.png "..conf.output..timestamp..".jpg")
    end
  else
    if not silent then mp.osd_message("Converting to a waifu2x image!") end
    local path = mp.get_property("path")
    local check = mp.get_property("path"):sub(1,1)
    local pwd = os.capture("pwd")
    if check ~= "/" then
      path = pwd.."/"..path
    end
    local pathout = path:gsub("%..*$","")
    local ext = mp.get_property("filename"):match("%..*$")
    local tmp = "/tmp/waifu2x-convert.png"
    if ext == ".png" then
      os.capture("cd "..conf.waifupath.."; th waifu2x.lua"..cudnn.." -m "..scale..noise.."-i "..path.." -o "..pathout.."-w2x"..".png")
    else
      os.capture("cd "..conf.waifupath.."; th waifu2x.lua"..cudnn.." -m "..scale..noise.."-i "..path.." -o "..tmp.."; convert "..tmp.." "..pathout.."-w2x"..ext)
    end
  end
end

function os.capture(cmd, raw)
  local f = assert(io.popen(cmd, 'r'))
  local s = assert(f:read('*a'))
  f:close()
  return string.sub(s, 0, -2)
end

function update()
  addkeybinds()
  timer:kill()
  timer:resume()
  if state.step == 0 then
    output(state.listtype, { header = "Waifu2x screenshot/convert?\n\n"})
  elseif state.step == 1 then
    output(state.listsize, { header = "Resize image\n\n"})
  elseif state.step == 2 then
    output(state.listnoise, { header = "Remove noise\n\n" })
  end
end

function enter()
  if state.step == 0 then
    state.selection[3] = state.listtype[state.cursor]
    state.step = 1
    state.cursor = 0
    update()
  elseif state.step == 1 then 
    state.selection[0] = state.listsize[state.cursor]
    state.step = 2
    state.cursor = 0
    update()
  elseif state.step == 2 then 
    state.selection[1] = state.listnoise[state.cursor]
    removekeybinds()
    waifu2x(state.selection)
    state.selection = {}
    state.step = 0
    state.cursor = 0
  end
end

function navup()
  if state.cursor~=0 then
    state.cursor = state.cursor-1
  else
    state.cursor = state.length-1
  end
  update()
end

function navdown()
  if state.cursor~=state.length-1 then
    state.cursor = state.cursor+1
  else
    state.cursor = 0
  end
  update()
end

function output(list, settings)
  --default to global stateiables and hardcoded ones, fiddle below if you want to use arguments or whatnot
  local header = "Header\n\n"
  local cursorprefix = ">"
  local cursorsuffix = "<"
  local concatstr = "..."
  local dur = conf.osd_duration_seconds
  local showamount = 10
  local cursor = state.cursor
  if settings.header then header = settings.header end

  local length = 0
  for index, item in pairs(list) do
    length = length + 1
  end
  state.length=length
  local output = header
  if length>0 then
    local b = cursor - math.floor(showamount/2)
    local showall, showrest = false, false
    if b<0 then b=0 end
    if length <= showamount then
      b=0
      showall=true
    end
    if b > math.max(length-showamount-1, 0) then 
      b=length-showamount
      showrest=true
    end
    if b > 0 and not showall then output=output..concatstr.."\n" end
    for a=b,b+showamount-1,1 do
      if a == length then break end
      if a == cursor then
        output = output..cursorprefix..list[a]..cursorsuffix.."\n"
      else
          output = output..list[a].."\n"
      end
      if a == b+showamount-1 and not showall and not showrest then
        output=output..concatstr
      end
    end
  else
      output = ""
  end
  mp.osd_message(output, dur)
end

function addkeybinds()
  if state.keybinds_active then return end
  mp.add_forced_key_binding("UP", scriptoptions.navup, navup)
  mp.add_forced_key_binding("DOWN", scriptoptions.navdown, navdown)
  mp.add_forced_key_binding("ENTER", scriptoptions.naventer, enter)
  state.keybinds_active = true
end

function removekeybinds()
  if not conf.use_dynamic_keybinds then return end
  state.keybinds_active = false
  mp.remove_key_binding(scriptoptions.navup)
  mp.remove_key_binding(scriptoptions.navdown)
  mp.remove_key_binding(scriptoptions.naventer)
end

if not conf.use_dynamic_keybinds then
  addkeybinds()
end

function reset()
  state.cursor=0
  state.step=0
  state.selection={}
  update()
end

function favorite()
  mp.osd_message("Waifu2x favorite shortcut\n\n"..conf.favorite[3].."\nscale: "..conf.favorite[0].."\nnoise-r: "..conf.favorite[1])
  waifu2x(conf.favorite, true)
end

--setup timer for keybindings
timer = mp.add_periodic_timer(conf.osd_duration_seconds, removekeybinds)
timer:kill()
 
mp.add_key_binding("CTRL+S", scriptoptions.name, reset)
mp.add_key_binding("CTRL+X", scriptoptions.favorite, favorite)