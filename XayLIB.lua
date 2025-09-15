local runService = game:GetService("RunService")
local userInput = game:GetService("UserInputService")
local tweenService = game:GetService("TweenService")
local coreGui = game:GetService("CoreGui")
local plrs = game:GetService("Players")
local lp = plrs.LocalPlayer

-- =========================
-- Config via getgenv()
-- =========================
local G = getgenv and getgenv() or {}
local CFG = {
    SnowEnabled = (G.XAY_SNOW_ENABLED ~= nil) and G.XAY_SNOW_ENABLED or true,
    SnowCount   = tonumber(G.XAY_SNOW_COUNT) or 80,
    SnowSpeed   = tonumber(G.XAY_SNOW_SPEED) or 60,
    SnowSize    = tonumber(G.XAY_SNOW_SIZE) or 3,
    SnowOpacity = tonumber(G.XAY_SNOW_OPACITY) or 0.7,
    Theme       = G.XAY_THEME or "Xay",
    ToggleKey   = G.XAY_KEYBIND or Enum.KeyCode.RightControl,
}
-- =========================

-- Utility
local function new(inst, props)
    local o = Instance.new(inst)
    for k,v in pairs(props or {}) do
        o[k] = v
    end
    return o
end

local function round(n, decimals)
    local m = 10 ^ (decimals or 0)
    return math.floor(n * m + 0.5) / m
end

local function safeParent(gui)
    pcall(function()
        gui.Parent = coreGui
    end)
    if not gui.Parent then
        gui.Parent = lp:FindFirstChildOfClass("PlayerGui") or lp:WaitForChild("PlayerGui")
    end
end

-- Themes
local Themes = {
    Dark = {
        WindowBg = Color3.fromRGB(18,18,22),
        PanelBg  = Color3.fromRGB(25,25,32),
        Stroke   = Color3.fromRGB(60,60,70),
        Accent   = Color3.fromRGB(62,126,255),
        Text     = Color3.fromRGB(230,230,235)
        SubText  = Color3.fromRGB(170,170,180),
        Hot      = Color3.fromRGB(255,86,86),
        Good     = Color3.fromRGB(86,255,145),
        Shadow   = Color3.fromRGB(10,10,14),
    },
    Midnight = {
        WindowBg = Color3.fromRGB(12,14,24),
        PanelBg  = Color3.fromRGB(20,22,34),
        Stroke   = Color3.fromRGB(54,60,94),
        Accent   = Color3.fromRGB(120,84,255),
        Text     = Color3.fromRGB(236,239,244),
        SubText  = Color3.fromRGB(164,170,184),
        Hot      = Color3.fromRGB(255,105,97),
        Good     = Color3.fromRGB(97,255,176),
        Shadow   = Color3.fromRGB(6,7,12),
    },
    Neon = {
        WindowBg = Color3.fromRGB(12,12,14),
        PanelBg  = Color3.fromRGB(18,18,20),
        Stroke   = Color3.fromRGB(40,40,42),
        Accent   = Color3.fromRGB(0,255,191),
        Text     = Color3.fromRGB(245,255,255),
        SubText  = Color3.fromRGB(150,190,190),
        Hot      = Color3.fromRGB(255,64,129),
        Good     = Color3.fromRGB(0,230,118),
        Shadow   = Color3.fromRGB(8,8,10),
    },
    Purple = {
        WindowBg = Color3.fromRGB(22,16,29),
        PanelBg  = Color3.fromRGB(32,22,44),
        Stroke   = Color3.fromRGB(86,62,110),
        Accent   = Color3.fromRGB(176,110,255),
        Text     = Color3.fromRGB(245,240,255),
        SubText  = Color3.fromRGB(189,170,220),
        Hot      = Color3.fromRGB(255,138,128),
        Good     = Color3.fromRGB(128,255,170),
        Shadow   = Color3.fromRGB(14,10,18),
    },
    Xay = {
        WindowBg = Color3.fromRGB(16,16,18),
        PanelBg  = Color3.fromRGB(24,24,30),
        Stroke   = Color3.fromRGB(90,90,110),
        Accent   = Color3.fromRGB(72,134,255),
        Text     = Color3.fromRGB(238,240,255),
        SubText  = Color3.fromRGB(165,170,190),
        Hot      = Color3.fromRGB(255,88,120),
        Good     = Color3.fromRGB(90,255,170),
        Shadow   = Color3.fromRGB(6,6,8),
    }
}

local ActiveTheme = Themes[CFG.Theme] or Themes.Xay

-- Main library table
local XayLIB = {
    _windows = {},
    _connections = {},
    _snowflakes = {},
    _aboutInjected = false,
    Version = "1.0.0",
    Theme = ActiveTheme,
}

-- Clean up
function XayLIB:Destroy()
    for _,c in ipairs(self._connections) do
        pcall(function() c:Disconnect() end)
    end
    for _,w in ipairs(self._windows) do
        pcall(function() w._gui:Destroy() end)
    end
    self._windows = {}
    self._connections = {}
    self._snowflakes = {}
end

-- Snow system
local function createSnowLayer(parent, theme)
    local snowFolder = new("Folder", {Name = "Xay_SnowLayer", Parent = parent})
    local absoluteFrame = new("Frame", {
        Name = "SnowCanvas",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1,1),
        Position = UDim2.fromScale(0,0),
        Parent = snowFolder
    })
    local flakes = {}
    local lastTick = tick()

    local function spawnFlake()
        local size = math.random(math.max(1, CFG.SnowSize - 1), CFG.SnowSize + 2)
        local x = math.random(0, absoluteFrame.AbsoluteSize.X)
        local y = -math.random(20, 120)
        local f = new("Frame", {
            BackgroundColor3 = Color3.fromRGB(255,255,255),
            BackgroundTransparency = 1 - math.clamp(CFG.SnowOpacity,0,1),
            Size = UDim2.fromOffset(size, size),
            Position = UDim2.fromOffset(x, y),
            Parent = absoluteFrame
        })
        local corner = new("UICorner", {CornerRadius = UDim.new(1,0), Parent = f})
        table.insert(flakes, {inst = f, drift = (math.random() > 0.5 and 1 or -1) * math.random(), speed = CFG.SnowSpeed})
    end

    for i=1, CFG.SnowCount do
        spawnFlake()
    end

    local conn = runService.RenderStepped:Connect(function(dt)
        if not absoluteFrame or not absoluteFrame.Parent then return end
        local s = absoluteFrame.AbsoluteSize
        for i=#flakes,1,-1 do
            local fl = flakes[i]
            if fl.inst and fl.inst.Parent then
                local p = fl.inst.Position
                local nx = p.X.Offset + fl.drift
                local ny = p.Y.Offset + (fl.speed * dt)
                if ny > s.Y + 40 then
                    nx = math.random(0, s.X)
                    ny = -math.random(20, 120)
                end
                fl.inst.Position = UDim2.fromOffset(nx, ny)
            else
                table.remove(flakes, i)
            end
        end
        -- respawn if count dips
        if #flakes < CFG.SnowCount and (tick() - lastTick) > 0.05 then
            spawnFlake()
            lastTick = tick()
        end
    end)

    return snowFolder, conn
end

-- Dragging
local function makeDraggable(topbar, dragTarget)
    local dragging, dragStart, startPos
    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = dragTarget.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    topbar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
            local delta = input.Position - dragStart
            dragTarget.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- UI primitives
local function stroke(parent, col, thickness)
    return new("UIStroke", {
        Parent = parent,
        Color = col,
        Thickness = thickness or 1,
        Transparency = 0.25,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    })
end

local function shadow(parent, theme)
    local s = new("ImageLabel", {
        Name = "Shadow",
        BackgroundTransparency = 1,
        Image = "rbxassetid://5028857084",
        ImageTransparency = 0.5,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(24,24,276,276),
        Size = UDim2.fromScale(1,1),
        Position = UDim2.fromScale(0,0),
        ZIndex = 0,
        Parent = parent
    })
    s.ImageColor3 = theme.Shadow
    return s
end

local function makeButton(parent, theme, text, callback)
    local btn = new("TextButton", {
        BackgroundColor3 = theme.PanelBg,
        TextColor3 = theme.Text,
        Font = Enum.Font.GothamMedium,
        TextSize = 14,
        Text = text or "Button",
        AutoButtonColor = false,
        Size = UDim2.new(1,0,0,28),
        Parent = parent
    })
    stroke(btn, theme.Stroke, 1)
    local corner = new("UICorner", {CornerRadius = UDim.new(0,6), Parent = btn})
    btn.MouseEnter:Connect(function()
        tweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = theme.Accent}):Play()
    end)
    btn.MouseLeave:Connect(function()
        tweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = theme.PanelBg}):Play()
    end)
    btn.MouseButton1Click:Connect(function()
        if callback then
            task.spawn(callback)
        end
    end)
    return btn
end

-- Window construction
function XayLIB:CreateWindow(opts)
    opts = opts or {}
    local theme = self.Theme
    local title = opts.Title or "XAYWARE"
    local size = opts.Size or UDim2.fromOffset(720, 420)

    local Screen = new("ScreenGui", {Name = "XayLIB_UI_"..tostring(math.random(1000,9999)), ZIndexBehavior = Enum.ZIndexBehavior.Global})
    safeParent(Screen)

    local Holder = new("Frame", {
        Name = "Window",
        Size = size,
        Position = UDim2.new(0.5, -size.X.Offset/2, 0.5, -size.Y.Offset/2),
        BackgroundColor3 = theme.WindowBg,
        Parent = Screen
    })
    new("UICorner", {CornerRadius = UDim.new(0,10), Parent = Holder})
    stroke(Holder, theme.Stroke, 1)
    shadow(Holder, theme)

    local Top = new("Frame", {
        Name = "Topbar",
        Size = UDim2.new(1,0,0,36),
        BackgroundColor3 = theme.PanelBg,
        Parent = Holder
    })
    new("UICorner", {CornerRadius = UDim.new(0,10), Parent = Top})
    stroke(Top, theme.Stroke, 1)

    local Title = new("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        Text = title,
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextColor3 = theme.Text,
        Position = UDim2.fromOffset(12, 0),
        Size = UDim2.new(1, -24, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Top
    })

    local HideBtn = new("TextButton", {
        Name = "Hide",
        BackgroundTransparency = 1,
        Text = "—",
        Font = Enum.Font.GothamBold,
        TextSize = 20,
        TextColor3 = theme.SubText,
        Size = UDim2.fromOffset(36,36),
        Position = UDim2.new(1,-36,0,0),
        Parent = Top
    })

    local Body = new("Frame", {
        Name = "Body",
        Size = UDim2.new(1, -12, 1, -48),
        Position = UDim2.fromOffset(6, 42),
        BackgroundTransparency = 1,
        Parent = Holder
    })

    local TabsLeft = new("Frame", {
        Name = "Tabs",
        Size = UDim2.new(0, 160, 1, 0),
        BackgroundColor3 = theme.PanelBg,
        Parent = Body
    })
    new("UICorner", {CornerRadius = UDim.new(0,8), Parent = TabsLeft})
    stroke(TabsLeft, theme.Stroke, 1)

    local TabButtons = new("ScrollingFrame", {
        Name = "TabButtons",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1,0,1,0),
        CanvasSize = UDim2.new(0,0,0,0),
        ScrollBarThickness = 2,
        Parent = TabsLeft
    })
    new("UIListLayout", {Parent = TabButtons, Padding = UDim.new(0,6)})
    new("UIPadding", {Parent = TabButtons, PaddingTop = UDim.new(0,8), PaddingLeft = UDim.new(0,8), PaddingRight = UDim.new(0,8), PaddingBottom = UDim.new(0,8)})

    local Content = new("Frame", {
        Name = "Content",
        Size = UDim2.new(1, -172, 1, 0),
        Position = UDim2.fromOffset(172, 0),
        BackgroundColor3 = theme.PanelBg,
        Parent = Body
    })
    new("UICorner", {CornerRadius = UDim.new(0,8), Parent = Content})
    stroke(Content, theme.Stroke, 1)

    local Pages = new("Folder", {Name = "Pages", Parent = Content})

    makeDraggable(Top, Holder)

    local WindowObj = {
        _gui = Screen,
        _holder = Holder,
        _theme = theme,
        _tabButtons = TabButtons,
        _pages = Pages,
        _tabs = {},
        _visible = true,
        _snow = nil,
        _snowConn = nil,
    }

    -- toggle visibility
    table.insert(self._connections, userInput.InputBegan:Connect(function(input, gpe)
        if not gpe and input.KeyCode == CFG.ToggleKey then
            WindowObj._visible = not WindowObj._visible
            Holder.Visible = WindowObj._visible
        end
    end))
    HideBtn.MouseButton1Click:Connect(function()
        WindowObj._visible = not WindowObj._visible
        Holder.Visible = WindowObj._visible
    end)

    -- Snow
    if CFG.SnowEnabled then
        local snow, conn = createSnowLayer(Content, theme)
        WindowObj._snow = snow
        WindowObj._snowConn = conn
        table.insert(self._connections, conn)
    end

    -- Tab API
    function WindowObj:AddTab(tabOpts)
        tabOpts = tabOpts or {}
        local name = tabOpts.Name or "Tab"
        local icon = tabOpts.Icon

        local btn = new("TextButton", {
            BackgroundColor3 = self._theme.PanelBg,
            TextColor3 = self._theme.SubText,
            Font = Enum.Font.GothamSemibold,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            AutoButtonColor = false,
            Size = UDim2.new(1,0,0,30),
            Text = name,
            Parent = self._tabButtons
        })
        stroke(btn, self._theme.Stroke, 1)
        new("UICorner", {CornerRadius = UDim.new(0,6), Parent = btn})
        local pad = new("UIPadding", {Parent = btn, PaddingLeft = UDim.new(0,10)})

        local page = new("ScrollingFrame", {
            Name = name,
            Size = UDim2.new(1, -12, 1, -12),
            Position = UDim2.fromOffset(6,6),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            CanvasSize = UDim2.fromOffset(0,0),
            ScrollBarThickness = 2,
            Visible = false,
            Parent = self._pages
        })
        local list = new("UIListLayout", {Parent = page, Padding = UDim.new(0,8)})

        local TabObj = {
            _btn = btn,
            _page = page,
            _sections = {},
            Name = name
        }

        local function selectThisTab()
            for _,t in pairs(self._tabs) do
                t._btn.TextColor3 = self._theme.SubText
                t._btn.BackgroundColor3 = self._theme.PanelBg
                t._page.Visible = false
            end
            btn.TextColor3 = self._theme.Text
            btn.BackgroundColor3 = self._theme.Accent
            page.Visible = true
        end

        btn.MouseButton1Click:Connect(selectThisTab)

        function TabObj:AddSection(secOpts)
            secOpts = secOpts or {}
            local title = secOpts.Title or "Section"
            local box = new("Frame", {
                BackgroundColor3 = self._page.Parent.Parent.Parent.Parent._theme.PanelBg,
                Size = UDim2.new(1, 0, 0, 56),
                Parent = page
            })
            new("UICorner", {CornerRadius = UDim.new(0,8), Parent = box})
            stroke(box, self._page.Parent.Parent.Parent.Parent._theme.Stroke, 1)
            local vlist = new("UIListLayout", {
                Parent = box,
                Padding = UDim.new(0,6),
                FillDirection = Enum.FillDirection.Vertical,
                HorizontalAlignment = Enum.HorizontalAlignment.Left,
                VerticalAlignment = Enum.VerticalAlignment.Top,
                SortOrder = Enum.SortOrder.LayoutOrder
            })
            local pad = new("UIPadding", {Parent = box, PaddingTop = UDim.new(0,8), PaddingLeft = UDim.new(0,8), PaddingRight = UDim.new(0,8), PaddingBottom = UDim.new(0,8)})

            local titleLbl = new("TextLabel", {
                BackgroundTransparency = 1,
                Text = title,
                Font = Enum.Font.GothamBold,
                TextSize = 14,
                TextColor3 = self._page.Parent.Parent.Parent.Parent._theme.Text,
                Size = UDim2.new(1,0,0,16),
                Parent = box
            })

            -- Autosize section as children added
            local function resize()
                task.defer(function()
                    local h = 16 + 8 -- title + padding
                    for _,child in ipairs(box:GetChildren()) do
                        if child:IsA("GuiObject") and child ~= titleLbl then
                            h += child.AbsoluteSize.Y + 6
                        end
                    end
                    box.Size = UDim2.new(1,0,0, math.max(56, h + 8))
                end)
            end

            local SecObj = {
                _box = box,
                _title = titleLbl,
                _resize = resize
            }

            -- Controls
            function SecObj:AddToggle(opts)
                opts = opts or {}
                local text = opts.Text or "Toggle"
                local default = opts.Default or false
                local callback = opts.Callback

                local row = new("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1,0,0,28), Parent = box})
                local lbl = new("TextLabel", {
                    BackgroundTransparency = 1,
                    Text = text,
                    Font = Enum.Font.Gotham,
                    TextSize = 14,
                    TextColor3 = XayLIB.Theme.Text,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Size = UDim2.new(1,-36,1,0),
                    Parent = row
                })
                local btn = new("TextButton", {
                    BackgroundColor3 = default and XayLIB.Theme.Accent or XayLIB.Theme.PanelBg,
                    Text = "",
                    AutoButtonColor = false,
                    Size = UDim2.fromOffset(24,24),
                    Position = UDim2.new(1,-24,0.5,-12),
                    Parent = row
                })
                new("UICorner", {CornerRadius = UDim.new(0,6), Parent = btn})
                stroke(btn, XayLIB.Theme.Stroke, 1)

                local state = default
                local function set(v)
                    state = not not v
                    tweenService:Create(btn, TweenInfo.new(0.12), {
                        BackgroundColor3 = state and XayLIB.Theme.Accent or XayLIB.Theme.PanelBg
                    }):Play()
                    if callback then task.spawn(callback, state) end
                end
                btn.MouseButton1Click:Connect(function() set(not state) end)
                resize()
                return {Get = function() return state end, Set = set}
            end

            function SecObj:AddSlider(opts)
                opts = opts or {}
                local text = opts.Text or "Slider"
                local min = tonumber(opts.Min) or 0
                local max = tonumber(opts.Max) or 100
                local default = tonumber(opts.Default) or min
                local decimals = tonumber(opts.Decimals) or 0
                local callback = opts.Callback

                local row = new("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1,0,0,40), Parent = box})
                local lbl = new("TextLabel", {
                    BackgroundTransparency = 1,
                    Text = string.format("%s: %s", text, tostring(default)),
                    Font = Enum.Font.Gotham,
                    TextSize = 14,
                    TextColor3 = XayLIB.Theme.Text,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Size = UDim2.new(1,0,0,18),
                    Parent = row
                })
                local bar = new("Frame", {
                    BackgroundColor3 = XayLIB.Theme.PanelBg,
                    Size = UDim2.new(1,0,0,10),
                    Position = UDim2.fromOffset(0,22),
                    Parent = row
                })
                new("UICorner", {CornerRadius = UDim.new(0,6), Parent = bar})
                stroke(bar, XayLIB.Theme.Stroke, 1)
                local fill = new("Frame", {
                    BackgroundColor3 = XayLIB.Theme.Accent,
                    Size = UDim2.new((default - min)/(max-min),0,1,0),
                    Parent = bar
                })
                new("UICorner", {CornerRadius = UDim.new(0,6), Parent = fill})

                local dragging = false
                local value = default

                local function setFromX(x)
                    local rel = math.clamp((x - bar.AbsolutePosition.X)/math.max(1, bar.AbsoluteSize.X), 0, 1)
                    local val = round(min + (max - min) * rel, decimals)
                    value = val
                    fill.Size = UDim2.new((val - min)/(max - min),0,1,0)
                    lbl.Text = string.format("%s: %s", text, tostring(val))
                    if callback then task.spawn(callback, val) end
                end

                bar.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true
                        setFromX(input.Position.X)
                    end
                end)
                bar.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = false
                    end
                end)
                userInput.InputChanged:Connect(function(input)
                    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        setFromX(input.Position.X)
                    end
                end)

                resize()
                return {Get = function() return value end, Set = function(v) setFromX(bar.AbsolutePosition.X + (math.clamp((v-min)/(max-min),0,1) * bar.AbsoluteSize.X)) end}
            end

            function SecObj:AddDropdown(opts)
                opts = opts or {}
                local text = opts.Text or "Dropdown"
                local list = opts.List or {"Option A","Option B"}
                local default = opts.Default or list[1]
                local callback = opts.Callback

                local row = new("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1,0,0,32), Parent = box})
                local btn = new("TextButton", {
                    BackgroundColor3 = XayLIB.Theme.PanelBg,
                    AutoButtonColor = false,
                    Text = "",
                    Size = UDim2.new(1,0,1,0),
                    Parent = row
                })
                new("UICorner", {CornerRadius = UDim.new(0,6), Parent = btn})
                stroke(btn, XayLIB.Theme.Stroke, 1)
                local title = new("TextLabel", {
                    BackgroundTransparency = 1,
                    Text = string.format("%s: %s", text, tostring(default)),
                    Font = Enum.Font.Gotham,
                    TextSize = 14,
                    TextColor3 = XayLIB.Theme.Text,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Size = UDim2.new(1,-28,1,0),
                    Position = UDim2.fromOffset(8,0),
                    Parent = btn
                })
                local caret = new("TextLabel", {
                    BackgroundTransparency = 1,
                    Text = "▾",
                    Font = Enum.Font.GothamBold,
                    TextSize = 16,
                    TextColor3 = XayLIB.Theme.SubText,
                    Size = UDim2.fromOffset(24,24),
                    Position = UDim2.new(1,-24,0.5,-12),
                    Parent = btn
                })

                local open = false
                local menu = new("Frame", {
                    BackgroundColor3 = XayLIB.Theme.PanelBg,
                    Size = UDim2.new(1,0,0, math.min(160, (#list * 26) + 8)),
                    Position = UDim2.new(0,0,1,4),
                    Visible = false,
                    Parent = row
                })
                new("UICorner",{CornerRadius = UDim.new(0,6), Parent = menu})
                stroke(menu, XayLIB.Theme.Stroke, 1)
                local sf = new("ScrollingFrame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1,0,1,0),
                    CanvasSize = UDim2.new(0,0,0, (#list * 26)),
                    ScrollBarThickness = 2,
                    Parent = menu
                })
                new("UIListLayout", {Parent = sf, Padding = UDim.new(0,4)})
                new("UIPadding", {Parent = sf, PaddingTop = UDim.new(0,4), PaddingLeft = UDim.new(0,4), PaddingRight = UDim.new(0,4), PaddingBottom = UDim.new(0,4)})

                local current = default
                local function choose(val)
                    current = val
                    title.Text = string.format("%s: %s", text, tostring(val))
                    if callback then task.spawn(callback, val) end
                end

                for _,opt in ipairs(list) do
                    local ob = new("TextButton", {
                        BackgroundColor3 = XayLIB.Theme.PanelBg,
                        TextColor3 = XayLIB.Theme.Text,
                        Text = tostring(opt),
                        Font = Enum.Font.Gotham,
                        TextSize = 14,
                        AutoButtonColor = false,
                        Size = UDim2.new(1, -8, 0, 22),
                        Parent = sf
                    })
                    new("UICorner",{CornerRadius = UDim.new(0,4), Parent = ob})
                    stroke(ob, XayLIB.Theme.Stroke, 1)
                    ob.MouseButton1Click:Connect(function()
                        choose(opt)
                        open = false
                        menu.Visible = false
                    end)
                end

                btn.MouseButton1Click:Connect(function()
                    open = not open
                    menu.Visible = open
                end)

                resize()
                return {
                    Get = function() return current end,
                    Set = function(v) choose(v) end,
                    Refresh = function(newList)
                        list = newList
                        for _,c in ipairs(sf:GetChildren()) do
                            if c:IsA("TextButton") then c:Destroy() end
                        end
                        for _,opt in ipairs(list) do
                            local ob = new("TextButton", {
                                BackgroundColor3 = XayLIB.Theme.PanelBg,
                                TextColor3 = XayLIB.Theme.Text,
                                Text = tostring(opt),
                                Font = Enum.Font.Gotham,
                                TextSize = 14,
                                AutoButtonColor = false,
                                Size = UDim2.new(1, -8, 0, 22),
                                Parent = sf
                            })
                            new("UICorner",{CornerRadius = UDim.new(0,4), Parent = ob})
                            stroke(ob, XayLIB.Theme.Stroke, 1)
                            ob.MouseButton1Click:Connect(function()
                                choose(opt)
                                open = false
                                menu.Visible = false
                            end)
                        end
                    end
                }
            end

            function SecObj:AddButton(opts)
                opts = opts or {}
                local text = opts.Text or "Click"
                local callback = opts.Callback
                local row = new("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1,0,0,28), Parent = box})
                makeButton(row, XayLIB.Theme, text, callback)
                resize()
            end

            function SecObj:AddTextbox(opts)
                opts = opts or {}
                local text = opts.Text or "Input"
                local placeholder = opts.Placeholder or ""
                local default = opts.Default or ""
                local callback = opts.Callback

                local row = new("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1,0,0,32), Parent = box})
                local lbl = new("TextLabel", {
                    BackgroundTransparency = 1,
                    Text = text,
                    Font = Enum.Font.Gotham,
                    TextSize = 14,
                    TextColor3 = XayLIB.Theme.Text,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Size = UDim2.new(0.35,0,1,0),
                    Parent = row
                })
                local input = new("TextBox", {
                    BackgroundColor3 = XayLIB.Theme.PanelBg,
                    TextColor3 = XayLIB.Theme.Text,
                    PlaceholderText = placeholder,
                    Text = default,
                    Font = Enum.Font.Gotham,
                    TextSize = 14,
                    ClearTextOnFocus = false,
                    Size = UDim2.new(0.65,-6,1,0),
                    Position = UDim2.new(0.35,6,0,0),
                    Parent = row
                })
                new("UICorner",{CornerRadius = UDim.new(0,6), Parent = input})
                stroke(input, XayLIB.Theme.Stroke, 1)
                input.FocusLost:Connect(function(enter)
                    if callback then task.spawn(callback, input.Text) end
                end)
                resize()
                return input
            end

            function SecObj:AddKeybind(opts)
                opts = opts or {}
                local text = opts.Text or "Keybind"
                local key = opts.Default or Enum.KeyCode.F
                local callback = opts.Callback

                local row = new("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1,0,0,28), Parent = box})
                local lbl = new("TextLabel", {
                    BackgroundTransparency = 1,
                    Text = text,
                    Font = Enum.Font.Gotham,
                    TextSize = 14,
                    TextColor3 = XayLIB.Theme.Text,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Size = UDim2.new(1,-120,1,0),
                    Parent = row
                })
                local bindBtn = new("TextButton", {
                    BackgroundColor3 = XayLIB.Theme.PanelBg,
                    TextColor3 = XayLIB.Theme.SubText,
                    Text = key.Name,
                    Font = Enum.Font.Gotham,
                    TextSize = 14,
                    AutoButtonColor = false,
                    Size = UDim2.fromOffset(100,24),
                    Position = UDim2.new(1,-100,0.5,-12),
                    Parent = row
                })
                new("UICorner",{CornerRadius = UDim.new(0,6), Parent = bindBtn})
                stroke(bindBtn, XayLIB.Theme.Stroke, 1)

                local binding = false
                bindBtn.MouseButton1Click:Connect(function()
                    binding = true
                    bindBtn.Text = "Press..."
                    bindBtn.TextColor3 = XayLIB.Theme.Text
                end)

                local conn = userInput.InputBegan:Connect(function(input, gpe)
                    if binding and not gpe and input.KeyCode ~= Enum.KeyCode.Unknown then
                        key = input.KeyCode
                        binding = false
                        bindBtn.Text = key.Name
                        bindBtn.TextColor3 = XayLIB.Theme.SubText
                        if callback then task.spawn(callback, key) end
                    end
                end)
                table.insert(XayLIB._connections, conn)

                resize()
                return {Get = function() return key end, Set = function(k) key = k; bindBtn.Text = k.Name end}
            end

            function SecObj:AddColorPicker(opts)
                opts = opts or {}
                local text = opts.Text or "Color"
                local default = opts.Default or Color3.fromRGB(255,255,255)
                local callback = opts.Callback

                local row = new("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1,0,0,32), Parent = box})
                local lbl = new("TextLabel", {
                    BackgroundTransparency = 1,
                    Text = text,
                    Font = Enum.Font.Gotham,
                    TextSize = 14,
                    TextColor3 = XayLIB.Theme.Text,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Size = UDim2.new(1,-40,1,0),
                    Parent = row
                })
                local colorBtn = new("TextButton", {
                    BackgroundColor3 = default,
                    AutoButtonColor = false,
                    Text = "",
                    Size = UDim2.fromOffset(28,28),
                    Position = UDim2.new(1,-28,0,0),
                    Parent = row
                })
                new("UICorner",{CornerRadius = UDim.new(0,6), Parent = colorBtn})
                stroke(colorBtn, XayLIB.Theme.Stroke, 1)

                local open = false
                local picker = new("Frame", {
                    BackgroundColor3 = XayLIB.Theme.PanelBg,
                    Size = UDim2.fromOffset(180, 140),
                    Position = UDim2.new(1, 8, 0, 0),
                    Visible = false,
                    Parent = row
                })
                new("UICorner",{CornerRadius = UDim.new(0,8), Parent = picker})
                stroke(picker, XayLIB.Theme.Stroke, 1)

                local hue = 0
                local sat = 0
                local val = 1
                local function hsvToRgb(h,s,v)
                    return Color3.fromHSV(h,s,v)
                end
                local function setColor(c3)
                    colorBtn.BackgroundColor3 = c3
                    if callback then task.spawn(callback, c3) end
                end

                local hueBar = new("Frame", {BackgroundColor3 = Color3.fromRGB(255,0,0), Size = UDim2.new(0, 16, 1, -12), Position = UDim2.fromOffset(8,6), Parent = picker})
                new("UICorner",{CornerRadius = UDim.new(0,4), Parent = hueBar})
                local satVal = new("Frame", {BackgroundColor3 = Color3.fromRGB(255,255,255), Size = UDim2.new(1,-36,1,-12), Position = UDim2.fromOffset(28,6), Parent = picker})
                new("UICorner",{CornerRadius = UDim.new(0,6), Parent = satVal})
                -- simple gradients via UIGradients
                local hueGrad = new("UIGradient", {
                    Rotation = 90,
                    Color = ColorSequence.new{
                        ColorSequenceKeypoint.new(0, Color3.fromHSV(0,1,1)),
                        ColorSequenceKeypoint.new(0.17, Color3.fromHSV(1/6,1,1)),
                        ColorSequenceKeypoint.new(0.33, Color3.fromHSV(2/6,1,1)),
                        ColorSequenceKeypoint.new(0.5, Color3.fromHSV(3/6,1,1)),
                        ColorSequenceKeypoint.new(0.67, Color3.fromHSV(4/6,1,1)),
                        ColorSequenceKeypoint.new(0.83, Color3.fromHSV(5/6,1,1)),
                        ColorSequenceKeypoint.new(1, Color3.fromHSV(1,1,1)),
                    },
                    Parent = hueBar
                })
                local satGrad = new("UIGradient", {
                    Color = ColorSequence.new(Color3.new(1,1,1), Color3.new(1,1,1)),
                    Transparency = NumberSequence.new{
                        NumberSequenceKeypoint.new(0,0),
                        NumberSequenceKeypoint.new(1,1)
                    },
                    Parent = satVal
                })
                local valGrad = new("UIGradient", {
                    Rotation = 90,
                    Color = ColorSequence.new(Color3.new(1,1,1), Color3.new(0,0,0)),
                    Parent = satVal
                })

                local pickingHue, pickingSV = false, false
                hueBar.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then
                        pickingHue = true
                    end
                end)
                hueBar.InputEnded:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then
                        pickingHue = false
                    end
                end)
                satVal.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then
                        pickingSV = true
                    end
                end)
                satVal.InputEnded:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then
                        pickingSV = false
                    end
                end)

                userInput.InputChanged:Connect(function(i)
                    if pickingHue and i.UserInputType == Enum.UserInputType.MouseMovement then
                        local rel = math.clamp((i.Position.Y - hueBar.AbsolutePosition.Y)/math.max(1, hueBar.AbsoluteSize.Y), 0, 1)
                        hue = rel
                        setColor(hsvToRgb(hue, sat, val))
                    end
                    if pickingSV and i.UserInputType == Enum.UserInputType.MouseMovement then
                        local rx = math.clamp((i.Position.X - satVal.AbsolutePosition.X)/math.max(1, satVal.AbsoluteSize.X), 0, 1)
                        local ry = math.clamp((i.Position.Y - satVal.AbsolutePosition.Y)/math.max(1, satVal.AbsoluteSize.Y), 0, 1)
                        sat = rx
                        val = 1 - ry
                        setColor(hsvToRgb(hue, sat, val))
                    end
                end)

                colorBtn.MouseButton1Click:Connect(function()
                    open = not open
                    picker.Visible = open
                end)

                setColor(default)
                resize()
                return {Get = function() return colorBtn.BackgroundColor3 end, Set = setColor}
            end

            -- finalize
            resize()
            return SecObj
        end

        -- activate first tab by default
        if #self._tabs == 0 then
            task.defer(selectThisTab)
        end
        table.insert(self._tabs, TabObj)
        return TabObj
    end

    -- Inject About tab once per window
    local function injectAbout(w)
        if XayLIB._aboutInjected then return end
        XayLIB._aboutInjected = true
        local t = w:AddTab({Name = "About"})
        local s = t:AddSection({Title = "Info"})
        s:AddTextbox({
            Text = "Note",
            Default = "XayLIB was used",
            Callback = function() end
        })
        s:AddButton({
            Text = "Copy library info",
            Callback = function()
                setclipboard("XayLIB was used — version "..XayLIB.Version)
            end
        })
    end

    injectAbout(WindowObj)
    table.insert(self._windows, WindowObj)
    return WindowObj
end

-- Public: change theme at runtime
function XayLIB:SetTheme(name)
    local th = Themes[name]
    if not th then return end
    self.Theme = th
    -- Just updates theme for future windows; existing windows are not live-rethemed for simplicity.
end

return XayLIB
