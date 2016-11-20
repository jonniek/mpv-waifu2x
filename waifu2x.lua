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
  linux_over_windows = true,  --linux windows toggle
  use_dynamic_keybinds = true, --waifu2x keybind will register dynamic keys for navigating that will temporarily override their original keybinding
  local_waifu = true, --false not implemented yet, looking for a good webapi for that
  osd_duration_seconds = 4,
  png = false, --jpg png toggle for screenshots, convert image tries to keep original
  waifupath = "/home/anon/software/waifu2x/", --path to dir where waifu2x.lua is, trail with /
  output = "~/Pictures/waifu2x/", --path to save screenshots to, image converts are saved to their original directory
  tmp = "/tmp/", --tmp folder where images
  convert_timestamp = false, --add a timestamp on convert, making sure no overrides happen

  --favorite shortcut
  --"0x"/"2x"   -scale 
  --"no"/"0"-"3"   -noise
  --"Screenshot"/"Image convert"   -screenshot or source image
  --use strings
  favorite = { [0]="2x", [1]="2", [3]="Screenshot"},

  force_cudnn = false, --untested, if it doesnt work its probably in the order of arguments in waifu2x function os.captures
}
read_options(conf, scriptoptions.name)

--global variables
local state = {
  listtype = { [0] = "Screenshot", [1] = "Image convert"},
  listsize = { [0] = "0x", [1] = "2x"},
  listnoise = { [0] = "no", [1] = "0", [2] = "1", [3] = "2", [4] = "3" },
  cursor = 0,
  selection ={},
  step=0,
  length=0,
  keybinds_active = false,
}

--cmd: list with configs, see conf.favorite for exampl
--silent: dont use osd messages - used with favorite()
function waifu2x(cmd, silent)
  --remove dynamic keybinds
  removekeybinds()

  --get a timestamp for possible filenames
  local timestamp = os.time()

  --representation for chaining commands
  local chain = " & "
  if conf.linux_over_windows then chain = " ; " end

  --parse the user inputted options
  local scale = ""
  local noise = ""
  if cmd[1] == "no" and cmd[0] == "0x" then
    if cmd[3] == "Screenshot" then
      mp.commandv("screenshot")
      mp.osd_message("No scale or noise, taking normal screenshot")
    else
      mp.osd_message("No scale or noise, not converting")
    end
    return
  elseif cmd[1] == "no" then
    scale = "scale"
  elseif cmd[1] ~= "no" and cmd[0] ~= "0x" then
    scale = "noise_scale"
  elseif cmd[1] ~= "no" and cmd[0] == "0x" then
    scale = "noise"
  end
  if cmd[1] ~= "no" then noise = "-noise_level "..cmd[1] end

  --check cudnn support
  local cudnn = ""
  if conf.force_cudnn then cudnn = "-force_cudnn 1" end

  --arguments for torch command
  local arguments = {}
  arguments[1] = cudnn
  arguments[2] = "-m "..scale
  arguments[3] = noise

  --initialize variable for additional commands
  local additional = ""

  --#### CODE FOR SCREEN SHOT CONVERT ####
  if cmd[3] == "Screenshot" then
    if not silent then mp.osd_message("Taking waifu2x screenshot!") end
    local subtitles = mp.get_property("sub-text")
    if subtitles == "" then subtitles = "video" else subtitles = "subtitles" end
    mp.commandv("screenshot-to-file", conf.tmp.."mpv-waifu2x-screenshot.png", subtitles)

    arguments[4] = "-i "..conf.tmp.."mpv-waifu2x-screenshot.png "
    if conf.png then
      arguments[5] = "-o "..conf.output..timestamp..".png"
    else
      arguments[5] = "-o "..conf.tmp.."mpv-waifu2x-screenshot.png"
      additional = chain.."convert "..conf.tmp.."mpv-waifu2x-screenshot.png "..conf.output..timestamp..".jpg"
    end
  else
    --#### CODE FOR IMAGE CONVERT ####
    if not silent then mp.osd_message("Converting to a waifu2x image!") end

    --use timestamp only if specified
    if not conf.convert_timestamp then timestamp = "" end

    local path = mp.get_property("path")
    --check if the path is absolute, if it isnt edit into one
    local check = mp.get_property("path"):sub(1,1)
    if check ~= "/" and check ~= "\\" then
      --combines pwd with the relative path, forming a absolute path
      --needed when files are opened like 'mpv folder/file'
      path = pwd().."/"..path
    end

    --get path and name without extension, so we can add suffix in between.
    local pathout = path:gsub("%..*$","")
    local ext = mp.get_property("filename"):match("%..*$")
    if not ext then ext = "" end

    local tmp = conf.tmp.."waifu2x-convert.png"
    arguments[4] = "-i "..path
    if ext == ".png" or ext == "" then
      --for a png just save it directly
      arguments[5] = " -o "..pathout.."-w2x"..timestamp..ext
    else
      --for a jpg save a tmp png file and convert it to the final one
      arguments[5] = " -o "..tmp
      additional = chain.."convert "..tmp.." "..pathout.."-w2x"..timestamp..ext
    end
  end

  --CD into the waifu2x directory. The script cannot be run from elsewhere.
  local output = "cd "..conf.waifupath..chain
  --start torch command
  output = output.."th waifu2x.lua"
  --loop through the arguments for torch command
  for k,value in ipairs(arguments) do
    output = output.." "..value
  end
  --add a additional convert command if needed
  output = output..additional

  --print(output) --for testing

  --execute command
  os.capture(output)
  mp.osd_message("Success")
end

--print working directory
function pwd()
  if conf.linux_over_windows then
    return os.capture("pwd")
  else
    return os.capture("echo %cd%")
  end
end

--capture command line output
function os.capture(cmd, raw)
  local f = assert(io.popen(cmd, 'r'))
  local s = assert(f:read('*a'))
  f:close()
  return string.sub(s, 0, -2)
end

--visual update function, called on navigation and init
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

--selects currently selected option and moves forward in state
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

--output the state on OSD
--has a lot of useless stuff because I copy pasted it
function output(list, settings)
  --init variables
  local header = ""
  if settings.header then header = settings.header end
  local cursorprefix = ">"
  local cursorsuffix = "<"
  local dur = conf.osd_duration_seconds
  local cursor = state.cursor

  --length of the currenly handled list, needed for cursor to work properly
  local length = 0
  for index, item in pairs(list) do
    length = length + 1
  end
  state.length=length

  --output loop
  local output = header
  local b = 0
  for a=b,10,1 do
    if a == length then break end
    if a == cursor then
      output = output..cursorprefix..list[a]..cursorsuffix.."\n"
    else
        output = output..list[a].."\n"
    end
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