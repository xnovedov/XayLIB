Sure! Here's a short, clear, and professional README for your XayLIB project:

---

```markdown
# XayLIB — Roblox UI Library

**XayLIB** is a customizable user interface library for Roblox scripts. It allows developers to create structured cheat menus with tabs, sections, and interactive controls. The design is inspired by XAYWARE and includes optional visual effects like falling snow.

## Features

- Tab-based layout with sections
- UI elements: Toggle, Slider, Dropdown, Button, Textbox, Keybind, Color Picker
- Built-in "About" tab with attribution
- Snow effect (can be enabled or disabled)
- Theme support: Dark, Neon, Midnight, Purple, Xay
- Menu toggle key (default: Right Control)

## Setup

```lua
getgenv().XAY_SNOW_ENABLED = true
getgenv().XAY_THEME = "Xay"
getgenv().XAY_KEYBIND = Enum.KeyCode.RightControl

local XayLIB = loadstring(game:HttpGet("https://your.cdn/XayLIB.lua"))()
```

## Usage Example

```lua
local win = XayLIB:CreateWindow({Title = "XAYWARE", Size = UDim2.fromOffset(720, 420)})
local tab = win:AddTab({Name = "Aimbot"})
local section = tab:AddSection({Title = "Ragebot"})

section:AddToggle({Text = "Enable Aimbot", Default = true, Callback = function(state) print(state) end})
section:AddSlider({Text = "FOV", Min = 0, Max = 20, Default = 3, Decimals = 1, Callback = function(val) print(val) end})
```

## Configuration Variables

| Name               | Type      | Description                          |
|--------------------|-----------|--------------------------------------|
| `XAY_SNOW_ENABLED` | `boolean` | Enables snow effect                  |
| `XAY_SNOW_COUNT`   | `number`  | Number of snowflakes (default: 80)  |
| `XAY_SNOW_SPEED`   | `number`  | Snow falling speed                   |
| `XAY_SNOW_SIZE`    | `number`  | Size of snowflakes                   |
| `XAY_SNOW_OPACITY` | `number`  | Opacity (0.0 to 1.0)                 |
| `XAY_THEME`        | `string`  | Theme name                           |
| `XAY_KEYBIND`      | `KeyCode` | Key to open/close the menu           |

## License

MIT — free to use and modify.
```

---

Let me know if you'd like a Russian version or want to include installation instructions for beginners.
