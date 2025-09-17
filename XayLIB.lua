local SkeetUI = {}
SkeetUI.__index = SkeetUI
local Windows = {}

function SkeetUI:CreateWindow(title, size)
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "SkeetUI_"..title
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = game:GetService("CoreGui")

    local Frame = Instance.new("Frame")
    Frame.Size = size or UDim2.new(0, 600, 0, 400)
    Frame.Position = UDim2.new(0.5, -300, 0.5, -200)
    Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    Frame.BorderSizePixel = 0
    Frame.Parent = ScreenGui

    local TitleBar = Instance.new("TextLabel")
    TitleBar.Text = "  "..title
    TitleBar.Font = Enum.Font.Code
    TitleBar.TextSize = 14
    TitleBar.TextColor3 = Color3.fromRGB(0, 255, 0)
    TitleBar.Size = UDim2.new(1, 0, 0, 24)
    TitleBar.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    TitleBar.BorderSizePixel = 0
    TitleBar.TextXAlignment = Enum.TextXAlignment.Left
    TitleBar.Parent = Frame

    local TabsFrame = Instance.new("Frame")
    TabsFrame.Size = UDim2.new(0, 120, 1, -24)
    TabsFrame.Position = UDim2.new(0, 0, 0, 24)
    TabsFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    TabsFrame.BorderSizePixel = 0
    TabsFrame.Parent = Frame

    local ContentFrame = Instance.new("Frame")
    ContentFrame.Size = UDim2.new(1, -120, 1, -24)
    ContentFrame.Position = UDim2.new(0, 120, 0, 24)
    ContentFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    ContentFrame.BorderSizePixel = 0
    ContentFrame.Parent = Frame

    local UI = setmetatable({
        Window = Frame,
        Tabs = {},
        ContentFrame = ContentFrame,
        TabsFrame = TabsFrame
    }, SkeetUI)

    table.insert(Windows, UI)
    return UI
end

function SkeetUI:AddTab(name)
    local TabBtn = Instance.new("TextButton")
    TabBtn.Size = UDim2.new(1, 0, 0, 28)
    TabBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    TabBtn.Text = name
    TabBtn.Font = Enum.Font.Code
    TabBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    TabBtn.TextSize = 14
    TabBtn.BorderSizePixel = 0
    TabBtn.Parent = self.TabsFrame

    local TabFrame = Instance.new("ScrollingFrame")
    TabFrame.Size = UDim2.new(1, 0, 1, 0)
    TabFrame.BackgroundTransparency = 1
    TabFrame.ScrollBarThickness = 4
    TabFrame.Visible = false
    TabFrame.Parent = self.ContentFrame

    TabBtn.MouseButton1Click:Connect(function()
        for _, t in pairs(self.Tabs) do
            t.Frame.Visible = false
        end
        TabFrame.Visible = true
    end)

    local Tab = {Name = name, Frame = TabFrame, Elements = {}}
    table.insert(self.Tabs, Tab)
    if #self.Tabs == 1 then TabFrame.Visible = true end
    return Tab
end

function SkeetUI:AddToggle(tab, data)
    local Toggle = Instance.new("TextButton")
    Toggle.Size = UDim2.new(1, -10, 0, 22)
    Toggle.Position = UDim2.new(0, 5, 0, #tab.Elements * 26)
    Toggle.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Toggle.Text = (data.Default and "[✔] " or "[ ] ")..data.Name
    Toggle.Font = Enum.Font.Code
    Toggle.TextSize = 14
    Toggle.TextColor3 = Color3.fromRGB(200, 200, 200)
    Toggle.TextXAlignment = Enum.TextXAlignment.Left
    Toggle.Parent = tab.Frame
    local state = data.Default or false
    Toggle.MouseButton1Click:Connect(function()
        state = not state
        Toggle.Text = (state and "[✔] " or "[ ] ")..data.Name
        if data.Callback then data.Callback(state) end
    end)
    table.insert(tab.Elements, Toggle)
    return Toggle
end

function SkeetUI:AddSlider(tab, data)
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -10, 0, 22)
    Label.Position = UDim2.new(0, 5, 0, #tab.Elements * 26)
    Label.Text = data.Name..": "..data.Default
    Label.Font = Enum.Font.Code
    Label.TextSize = 14
    Label.TextColor3 = Color3.fromRGB(200, 200, 200)
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.BackgroundTransparency = 1
    Label.Parent = tab.Frame

    local Slider = Instance.new("TextButton")
    Slider.Size = UDim2.new(1, -10, 0, 6)
    Slider.Position = UDim2.new(0, 5, 0, #tab.Elements * 26 + 18)
    Slider.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    Slider.BorderSizePixel = 0
    Slider.Parent = tab.Frame

    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new((data.Default - data.Min) / (data.Max - data.Min), 0, 1, 0)
    Fill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    Fill.BorderSizePixel = 0
    Fill.Parent = Slider

    local dragging = false
    Slider.MouseButton1Down:Connect(function() dragging = true end)
    game:GetService("UserInputService").InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)

    game:GetService("RunService").RenderStepped:Connect(function()
        if dragging then
            local mouse = game:GetService("UserInputService"):GetMouseLocation()
            local percent = math.clamp((mouse.X - Slider.AbsolutePosition.X) / Slider.AbsoluteSize.X, 0, 1)
            local value = math.floor(data.Min + (data.Max - data.Min) * percent)
            Fill.Size = UDim2.new(percent, 0, 1, 0)
            Label.Text = data.Name..": "..value
            if data.Callback then data.Callback(value) end
        end
    end)

    table.insert(tab.Elements, Slider)
    return Slider
end

function SkeetUI:AddButton(tab, data)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, -10, 0, 22)
    Btn.Position = UDim2.new(0, 5, 0, #tab.Elements * 26)
    Btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Btn.Text = data.Name
    Btn.Font = Enum.Font.Code
    Btn.TextSize = 14
    Btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    Btn.Parent = tab.Frame
    Btn.MouseButton1Click:Connect(function() if data.Callback then data.Callback() end end)
    table.insert(tab.Elements, Btn)
    return Btn
end

function SkeetUI:AddTextbox(tab, data)
    local Box = Instance.new("TextBox")
    Box.Size = UDim2.new(1, -10, 0, 22)
    Box.Position = UDim2.new(0, 5, 0, #tab.Elements * 26)
    Box.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Box.Text = data.Default or ""
    Box.Font = Enum.Font.Code
    Box.TextSize = 14
    Box.TextColor3 = Color3.fromRGB(200, 200, 200)
    Box.PlaceholderText = data.Name
    Box.Parent = tab.Frame
    Box.FocusLost:Connect(function() if data.Callback then data.Callback(Box.Text) end end)
    table.insert(tab.Elements, Box)
    return Box
end

function SkeetUI:AddDropdown(tab, data)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, -10, 0, 22)
    Btn.Position = UDim2.new(0, 5, 0, #tab.Elements * 26)
    Btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Btn.Text = data.Default or data.Name
    Btn.Font = Enum.Font.Code
    Btn.TextSize = 14
    Btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    Btn.Parent = tab.Frame

    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, -10, 0, #data.Options * 22)
    Frame.Position = UDim2.new(0, 5, 0, #tab.Elements * 26 + 22)
    Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    Frame.Visible = false
    Frame.Parent = tab.Frame

    for i, opt in pairs(data.Options) do
        local OptBtn = Instance.new("TextButton")
        OptBtn.Size = UDim2.new(1, 0, 0, 22)
        OptBtn.Position = UDim2.new(0, 0, 0, (i-1)*22)
        OptBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        OptBtn.Text = opt
        OptBtn.Font = Enum.Font.Code
        OptBtn.TextSize = 14
        OptBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
        OptBtn.Parent = Frame
        OptBtn.MouseButton1Click:Connect(function()
            Btn.Text = opt
            Frame.Visible = false
            if data.Callback then data.Callback(opt) end
        end)
    end

    Btn.MouseButton1Click:Connect(function() Frame.Visible = not Frame.Visible end)
    table.insert(tab.Elements, Btn)
    return Btn
end

return SkeetUI
