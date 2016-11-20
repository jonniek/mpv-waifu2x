##MPV waifu2x
  
A mpv script to take screenshots and convert images with the waifu2x machinelearning upscale algorithm. Example below.
![alt text](https://i.imgur.com/A4rPNpm.jpg "preview image")  
###Requirements
-  Waifu2x and all it's dependencies
  -  for now there is no option to use a website service
  -  [https://github.com/nagadomi/waifu2x](waifu2x installation instructions)

###How to use
-  open menu with waifu2x keybind
-  choose between screenshot(any kind of file that produces a screenshot) or image convert(safe for at least png/jpg for now)
-  choose upscale amount
-  choose noise reduction level
-  the image will be created in 1-10 seconds
-  I highly suggest using [https://github.com/aidanholm/mpv-easycrop](easy crop) if you want to take cropped waifu2x screenshots

###Keybindings
-  "waifu2x", --default CTRL+S
-  "waifu2x-favorite", --default CTRL+X

-  "waifu2x-up", --default dynamic key UP
-  "waifu2x-down", --default dynamic key DOWN
-  "waifu2x-enter", --default dynamic key ENTER

Dynamic means that the keybind will be active and override that key only when the menu is visible. Change keybinds in input conf with `KEY script-binding waifu2x`.


###TODO
-  Port and test for windows
-  image convert tests for different filetypes
-  cudnn testing
-  clean the messy code