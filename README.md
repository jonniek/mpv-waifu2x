## MPV waifu2x
  
A mpv script to take screenshots and convert images with the waifu2x machinelearning upscale algorithm. Windows version is untested temporarily, if you have issues/had to fix stuff open a ticket please. Example below.

![alt text](https://i.imgur.com/A4rPNpm.jpg "preview image")  
### Requirements
-  [Waifu2x and all it's dependencies](https://github.com/nagadomi/waifu2x)
-  The script uses the torch commands you can find in above link, test waifu2x out first with those
-  This requires imagemagicks `convert` command when using jpg output, test that `convert image.png image.jpg` works
-  The script uses standard output of `pwd` and `%cd%`(untested) for creating absolute paths if nececcary

### How to use
-  edit all the settings in conf variable in lua to match your system
-  open menu with waifu2x keybind
-  choose between screenshot(any kind of file that produces a screenshot) or image convert(safe for at least png/jpg for now)
-  choose upscale amount
-  choose noise reduction level
-  the image will be created in 1-10 seconds
-  I highly suggest using [easy crop by aidanholm](https://github.com/aidanholm/mpv-easycrop) if you want to take cropped screenshots
-  Screenshot will include subtitles if they are visible, hide subtitles(default v) to not capture them in the screenshot
-  you can bind your own keys for waifu2x if you do not want to use the osd-gui, ex. `alt+x script-message waifu2x-send screenshot 2x 2` in input.conf. Available options are image type, rezise, noise reduction and silent: [screenshot | image] [2x | 0x ] [no | 0 | 1 | 2 | 3] [true | false].

### Keybindings
-  "waifu2x" - default CTRL+S
-  "waifu2x-up" - default dynamic key UP
-  "waifu2x-down" - default dynamic key DOWN
-  "waifu2x-enter" - default dynamic key ENTER

Dynamic means that the keybind will be active and override that key only when the menu is visible. You can disable dynamic keys and force static ones in the conf variable in the lua. Change keybinds in input conf with `KEY script-binding waifu2x`


### TODO
-  Add a non local version that uses some web api
-  Port and test for windows
-  image convert tests for different filetypes
-  cudnn testing
-  refactor the messy code

#### My other mpv scripts
- [collection of scripts](https://github.com/donmaiq/mpv-scripts)
