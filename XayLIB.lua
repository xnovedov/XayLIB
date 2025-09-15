-- XayLIB v1.0
-- A beautiful, feature-rich UI library for Roblox scripts
-- Menu opens on Right Ctrl, includes toggleable snow effect, tabs, sections, sliders, keybinds, color pickers, and an About tab that credits XayLIB.

local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")

local XayLIB = {}
XayLIB.__index = XayLIB

-- Default config
XayLIB.Config = {
    MenuKey       = Enum.KeyCode.RightControl,
    AccentColor   = Color3.fromRGB(  0, 255, 136),
    BGColor       = Color3.fromRGB( 30, 30, 48),
    PanelColor    = Color3.fromRGB( 31, 31, 48),
    TextColor     = Color3.fromRGB(224,224,224),
    Width         = 600,
    Height        = 400,
    SnowEnabled   = true,
    SnowCount     = 80,
    SnowColor     = Color3.fromRGB(255,255,255),
    SnowSizeRange = {2,5},
}

-- Internal utility
local function new(name, props)
    local inst = Instance.new(name)
    for k,v in pairs(props) do inst[k] = v end
    return inst
end

-- Create the main window
function XayLIB:CreateWindow(title)
    local self = setmetatable({}, XayLIB)
    self.Tabs      = {}
    self.Visible   = false
    self.ScreenGui = new("ScreenGui", {Name = "XayLIB_UI", ResetOnSpawn = false})
    self.MainFrame = new("Frame", {
        Name       = "MainFrame",
        Parent     = self.ScreenGui,
        Size       = UDim2.new(0, self.Config.Width, 0, self.Config.Height),
        Position   = UDim2.new(0.5, -self.Config.Width/2, 0.5, -self.Config.Height/2),
        BackgroundColor3 = self.Config.BGColor,
        Visible    = false,
    })

    -- Top bar
    self.TopBar = new("TextLabel", {
        Parent     = self.MainFrame,
        Size       = UDim2.new(1, 0, 0, 28),
        BackgroundColor3 = self.Config.PanelColor,
        Text       = "  "..title,
        TextColor3 = self.Config.TextColor,
        Font       = Enum.Font.GothamBold,
        TextSize   = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    -- Left tabs container
    self.TabList = new("ScrollingFrame", {
        Parent     = self.MainFrame,
        Name       = "TabList",
        BackgroundColor3 = self.Config.PanelColor,
        Size       = UDim2.new(0, 140, 1, -28),
        Position   = UDim2.new(0, 0, 0, 28),
        ScrollBarThickness = 0,
        CanvasSize  = UDim2.new(0, 0, 0, 0),
    })
    self.TabList.UIListLayout = new("UIListLayout", {
        Parent = self.TabList,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4),
    })

    -- Content area
    self.Content = new("Frame", {
        Parent     = self.MainFrame,
        Name       = "Content",
        BackgroundColor3 = self.Config.BGColor,
        Size       = UDim2.new(1, -140, 1, -28),
        Position   = UDim2.new(0, 140, 0, 28),
    })
    self.SectionUIList = new("UIListLayout", {
        Parent = self.Content,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding   = UDim.new(0, 8),
    })

    -- Snow container
    self.SnowFolder = new("Folder", {Parent = self.ScreenGui, Name = "SnowFolder"})
    if self.Config.SnowEnabled then
        self:_StartSnow()
    end

    -- About tab (forced)
    local about = self:AddTab("About")
    about:AddLabel("This menu uses XayLIB")

    -- Toggle menu keybind
    UserInputService.InputBegan:Connect(function(input, gp)
        if not gp and input.KeyCode == self.Config.MenuKey then
            self.Visible = not self.Visible
            self.MainFrame.Visible = self.Visible
        end
    end)

    -- Parent to PlayerGui
    self.ScreenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    return self
end

-- Create a new tab
function XayLIB:AddTab(name)
    local tab = {Name = name, Sections = {}, Button = nil}
    table.insert(self.Tabs, tab)

    -- Button in TabList
    tab.Button = new("TextButton", {
        Parent     = self.TabList,
        Name       = name.."Button",
        Size       = UDim2.new(1, -8, 0, 30),
        BackgroundColor3 = self.Config.PanelColor,
        Text       = name,
        TextColor3 = self.Config.TextColor,
        Font       = Enum.Font.Gotham,
        TextSize   = 14,
    })
    -- Update canvas size
    local layout  = self.TabList.UIListLayout
    local canvasY = #self.Tabs * (30 + layout.Padding.Offset)
    self.TabList.CanvasSize = UDim2.new(0, 0, 0, canvasY)

    -- Tab content container
    tab.Container = new("Frame", {
        Parent     = self.Content,
        Name       = name.."Container",
        Size       = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,
        Visible    = false,
    })
    tab.Container.UIListLayout = new("UIListLayout", {
        Parent    = tab.Container,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding   = UDim.new(0, 12),
    })

    -- Button logic
    tab.Button.MouseButton1Click:Connect(function()
        self:_SelectTab(tab)
    end)

    -- First tab selected by default
    if #self.Tabs == 1 then
        self:_SelectTab(tab)
    end

    -- Section factory
    function tab:AddSection(title)
        local sec = {Title = title, Elements = {}}
        table.insert(self.Sections, sec)

        sec.Frame = new("Frame", {
            Parent     = tab.Container,
            Name       = title.."Section",
            BackgroundColor3 = self.Config.PanelColor,
            Size       = UDim2.new(1, 0, 0, 24),
        })
        sec.Label = new("TextLabel", {
            Parent       = sec.Frame,
            Text          = title,
            TextColor3    = self.Config.TextColor,
            BackgroundTransparency = 1,
            Font          = Enum.Font.GothamBold,
            TextSize      = 14,
            Size          = UDim2.new(1, -12, 0, 24),
            Position      = UDim2.new(0, 6, 0, 0),
            TextXAlignment= Enum.TextXAlignment.Left,
        })

        -- Container for elements
        sec.Content = new("Frame", {
            Parent     = tab.Container,
            BackgroundTransparency = 1,
            Size       = UDim2.new(1, 0, 0, 0),
        })
        sec.Content.UIListLayout = new("UIListLayout", {
            Parent    = sec.Content,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding   = UDim.new(0, 6),
        })

        -- Adjust total height function
        local function updateSectionSize()
            local totalY = sec.Label.AbsoluteSize.Y + sec.Content.AbsoluteSize.Y + 8
            sec.Frame.Size = UDim2.new(1, 0, 0, totalY)
        end
        sec.Content:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateSectionSize)

        -- Element factories
        function sec:AddToggle(text, default, callback)
            local cb = new("TextButton", {
                Parent     = sec.Content,
                Name       = text.."Toggle",
                Size       = UDim2.new(1, 0, 0, 24),
                BackgroundColor3 = self.Config.PanelColor,
                Text       = text,
                TextColor3 = self.Config.TextColor,
                Font       = Enum.Font.Gotham,
                TextSize   = 14,
            })
            local mark = new("Frame", {
                Parent     = cb,
                Name       = "Mark",
                Size       = UDim2.new(0, 16, 0, 16),
                Position   = UDim2.new(1, -20, 0.5, -8),
                BackgroundColor3 = default and self.Config.AccentColor or Color3.new(0,0,0),
            })
            cb.MouseButton1Click:Connect(function()
                mark.BackgroundColor3 = mark.BackgroundColor3==Color3.new(0,0,0)
                    and self.Config.AccentColor or Color3.new(0,0,0)
                callback(mark.BackgroundColor3~=Color3.new(0,0,0))
            end)
            return sec
        end

        function sec:AddSlider(text, min, max, default, callback)
            local wrp = new("Frame", {
                Parent     = sec.Content,
                Name       = text.."Slider",
                Size       = UDim2.new(1, 0, 0, 28),
                BackgroundTransparency = 1,
            })
            local lbl = new("TextLabel", {
                Parent       = wrp,
                Text          = string.format("%s: %.1f", text, default),
                TextColor3    = self.Config.TextColor,
                BackgroundTransparency = 1,
                Font          = Enum.Font.Gotham,
                TextSize      = 14,
                Size          = UDim2.new(1, -12, 0, 18),
                Position      = UDim2.new(0, 6, 0, 0),
                TextXAlignment= Enum.TextXAlignment.Left,
            })
            local bar = new("Frame", {
                Parent     = wrp,
                Name       = "BarBG",
                BackgroundColor3 = Color3.fromRGB(50,50,60),
                Size       = UDim2.new(1, -12, 0, 8),
                Position   = UDim2.new(0, 6, 0, 20),
            })
            local fill = new("Frame", {
                Parent     = bar,
                Name       = "Fill",
                BackgroundColor3 = self.Config.AccentColor,
                Size       = UDim2.new((default-min)/(max-min), 0, 1, 0),
            })
            local dragging = false
            bar.InputBegan:Connect(function(i)
                if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true end
            end)
            bar.InputEnded:Connect(function(i)
                if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
            end)
            RunService.RenderStepped:Connect(function()
                if dragging then
                    local mx = UserInputService:GetMouseLocation().X - bar.AbsolutePosition.X
                    local frac = math.clamp(mx/bar.AbsoluteSize.X,0,1)
                    fill.Size = UDim2.new(frac,0,1,0)
                    local val = min + frac*(max-min)
                    lbl.Text = string.format("%s: %.1f", text, val)
                    callback(val)
                end
            end)
            return sec
        end

        function sec:AddButton(text, callback)
            local btn = new("TextButton", {
                Parent     = sec.Content,
                Name       = text.."Button",
                Size       = UDim2.new(1, 0, 0, 28),
                BackgroundColor3 = self.Config.PanelColor,
                Text       = text,
                TextColor3 = self.Config.TextColor,
                Font       = Enum.Font.Gotham,
                TextSize   = 14,
            })
            btn.MouseButton1Click:Connect(callback)
            return sec
        end

        return sec
    end

    return tab
end

-- Internal: switch tabs
function XayLIB:_SelectTab(tab)
    for _,t in ipairs(self.Tabs) do
        t.Button.BackgroundColor3   = self.Config.PanelColor
        t.Container.Visible         = false
    end
    tab.Button.BackgroundColor3     = self.Config.AccentColor
    tab.Container.Visible           = true
end

-- Snow logic
function XayLIB:_StartSnow()
    local flakes = {}
    local screenW = XayLIB.Config.Width
    local screenH = XayLIB.Config.Height

    for i=1, self.Config.SnowCount do
        local size = math.random(self.Config.SnowSizeRange[1], self.Config.SnowSizeRange[2])
        local flake = new("Frame", {
            Parent     = self.SnowFolder,
            Size       = UDim2.new(0, size, 0, size),
            Position   = UDim2.new(math.random(),0,0, math.random(-screenH,0)),
            BackgroundColor3 = self.Config.SnowColor,
            BorderSizePixel   = 0,
            BackgroundTransparency = 0.2,
        })
        flakes[#flakes+1] = {inst = flake, speed = math.random(20,60)/100}
    end

    RunService.RenderStepped:Connect(function(dt)
        if not self.Config.SnowEnabled then return end
        for _,f in ipairs(flakes) do
            local p = f.inst.Position
            local y = p.Y.Offset + f.speed*dt*100
            local x = p.X.Scale + p.X.Offset/self.Config.Width + math.sin(y/50)*0.002
            if y > self.Config.Height then
                y = math.random(-self.Config.Height/2,0)
            end
            f.inst.Position = UDim2.new(x, 0, 0, y)
        end
    end)
end

return XayLIB
