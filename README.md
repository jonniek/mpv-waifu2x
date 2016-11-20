##MPV waifu2x
  
A mpv script to take screenshots and convert images with the waifu2x machinelearning upscale algorithm. Example below.

![alt text](https://i.imgur.com/A4rPNpm.jpg "preview image")  
###Requirements
-  [Waifu2x and all it's dependencies](https://github.com/nagadomi/waifu2x)

###How to use
-  open menu with waifu2x keybind
-  choose between screenshot(any kind of file that produces a screenshot) or image convert(safe for at least png/jpg for now)
-  choose upscale amount
-  choose noise reduction level
-  the image will be created in 1-10 seconds
-  I highly suggest using [easy crop](https://github.com/aidanholm/mpv-easycrop) if you want to take cropped screenshots
-  you can save one favorite setting to acces with a single keybind without opening the menu, check the config.favorite in lua for details. Default is Screenshot 2x noise-reduction 2.

###Keybindings
-  "waifu2x" - default CTRL+S
-  "waifu2x-favorite" - default CTRL+X  
-  "waifu2x-up" - default dynamic key UP
-  "waifu2x-down" - default dynamic key DOWN
-  "waifu2x-enter" - default dynamic key ENTER

Dynamic means that the keybind will be active and override that key only when the menu is visible. Change keybinds in input conf with `KEY script-binding waifu2x`


###TODO
-  Add a non local version that uses some web api
-  Port and test for windows
-  image convert tests for different filetypes
-  cudnn testing
-  clean the messy code
