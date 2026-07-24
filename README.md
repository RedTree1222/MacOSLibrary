# MacOSLibrary
ui library that looks like apple's macos and ipados. 

## what you need
you need an executor with `gethui()` or `syn.protect_gui`. tested on potassium and delta.

## how to use
load it directly from github:
```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/RedTree1222/MacOSLibrary/main/main.lua"))()
```

make a window:
```lua
local Window = Library:Init("title text", true, Enum.KeyCode.LeftControl, true)
```

check out the [example](example_test.lua) if you want to see everything in action.

# docs
## window stuff
holds everything.
```lua
local Window = Library:Init(titleText: string, splash: boolean, showHideKeybind: KeyCode, deletePreviousUI: boolean)
```

## notifications
- temp notify: pops up top-right, no buttons, leaves on its own.
```lua
Window:TempNotify(titleText: string, paragraphText: string, icon: string)
```
- notify 1: one button, pops up over the window.
```lua
Window:Notify(titleText: string, paragraphText: string, button1Text: string, icon: string)
```
- notify 2: two buttons, pops up over window.
```lua
Window:Notify2(titleText: string, paragraphText: string, button1Text: string, button2Text: string, icon: string)
```

## sidebar
- divider: just text to split things in the sidebar.
```lua
Window:Divider(text: string)
```
- section/tab: holds your elements. returns a section table.
  you can pass a second arg for the icon. The library now integrates all **1,747 official Lucide icons** dynamically!
  You can use any Lucide icon name.
  Check out [lucide.dev/icons](https://lucide.dev/icons) for the full list of supported names.
  
  If you want to use a custom image, you can still pass ANY direct Roblox asset ID as well!
  
  ```lua
  local section = Window:Section(text: string, icon: string)
  -- Example using built-in Lucide:
  local sec1 = Window:Section("Main", "swords")
  -- Example using custom asset ID:
  local sec2 = Window:Section("Custom", "rbxassetid://123456789")
  ```

## groupboxes
Groupboxes split your UI into left and right columns!
```lua
local LeftGroup = Section:AddLeftGroupbox(title: string)
local RightGroup = Section:AddRightGroupbox(title: string)
-- or legacy support:
local Groupbox = Section:Groupbox(title: string)

LeftGroup:AddToggle(name: string, default: boolean, callback: function)
LeftGroup:AddButton(name: string, callback: function)
LeftGroup:AddSlider(name: string, min: number, max: number, default: number, callback: function)
LeftGroup:AddDropdown(name: string, options: table, default: string, callback: function)
```

## tabboxes
Tabboxes are like Groupboxes, but they have multiple tabs inside them! Great for organizing lots of toggles.
```lua
local Tabbox = Section:AddLeftTabbox()
-- or
local Tabbox = Section:AddRightTabbox()

local CombatTab = Tabbox:AddTab("Combat")
CombatTab:AddToggle("Aimbot", false, function(state) end)

local VisualsTab = Tabbox:AddTab("Visuals")
VisualsTab:AddToggle("ESP", true, function(state) end)
```

## elements
Elements can be added to Sections, Groupboxes, or Tabbox Tabs!
- label: just text for notes.
```lua
Container:Label(text: string)
```
- paragraph: bigger text block.
```lua
Container:Paragraph(title: string, content: string)
```
- button: clicks and does stuff.
```lua
Container:Button(text: string, callback: function)
```
- switch/toggle: on/off toggle.
```lua
Container:Switch(text: string, default: boolean, callback: function)
```
- text field: type stuff in.
```lua
Container:TextField(text: string, placeholderText: string, callback: function)
```
- slider: slide to pick a number.
```lua
Container:Slider(text: string, min: number, max: number, default: number, callback: function)
```
- dropdown: pick one thing from a list.
```lua
Container:Dropdown(text: string, options: table, default: string, callback: function)
```
- multi dropdown: pick lots of things from a list.
```lua
Container:MultiDropdown(text: string, options: table, defaultOptions: table, callback: function)
```
- colorpicker: pick a color.
```lua
Container:ColorPicker(text: string, default: Color3, callback: function)
```
- keybind: press a key to set it.
```lua
Container:Keybind(text: string, default: KeyCode, callback: function)
```

## extra stuff
- hide/show:
```lua
Window:ToggleVisible()
```
- dynamic resize: You can click and drag the gap between the sidebar and the main workarea to dynamically scale the UI, just like native macOS!
- extra mode: click the green button top left to swap to the settings tab. 
- collapse: click the bottom left button to shrink the sidebar to just icons.

# images
![image](https://raw.githubusercontent.com/RedTree1222/MacOSLibrary/main/Assets/Screenshot%202026-07-18%20075132.png)
### window
![image](https://user-images.githubusercontent.com/82454201/221863995-7f86524a-c4ea-4123-8978-d57a99421b7c.png)
### splash
![image](https://raw.githubusercontent.com/RedTree1222/MacOSLibrary/main/Assets/Screenshot%202026-07-18%20075116.png)
### temp notif
![image](https://raw.githubusercontent.com/RedTree1222/MacOSLibrary/main/Assets/Screenshot%202026-07-18%20075056.png)

got questions? dm me on discord: external.py
