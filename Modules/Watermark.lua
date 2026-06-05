return function(State, Services, Theme)
    local module = {}
    
    function module.toggle(enabled)
        if not State.WatermarkGui then
            local sg = Instance.new("ScreenGui")
            sg.Name = "QuantixWatermark"
            sg.ResetOnSpawn = false
            sg.ZIndexBehavior = Enum.ZIndexBehavior.Global
            sg.Parent = Services.CoreGui

            local bg = Instance.new("Frame")
            bg.Name = "Background"
            bg.Size = UDim2.new(0, 200, 0, 25)
            bg.Position = UDim2.new(0, 10, 0, 10)
            bg.BackgroundColor3 = Theme.Background
            bg.BorderColor3 = Theme.DarkOutline
            bg.Parent = sg

            local outline = Instance.new("UIStroke")
            outline.Color = Theme.LightOutline
            outline.Thickness = 1
            outline.Parent = bg

            local topBar = Instance.new("Frame")
            topBar.Name = "TopBar"
            topBar.Size = UDim2.new(1, 0, 0, 2)
            topBar.Position = UDim2.new(0, 0, 0, 0)
            topBar.BackgroundColor3 = Theme.AccentStart
            topBar.BorderSizePixel = 0
            topBar.Parent = bg

            local uigradient = Instance.new("UIGradient")
            uigradient.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Theme.AccentStart),
                ColorSequenceKeypoint.new(1, Theme.AccentEnd)
            }
            uigradient.Parent = topBar

            local label = Instance.new("TextLabel")
            label.Name = "Label"
            label.Size = UDim2.new(1, -10, 1, -2)
            label.Position = UDim2.new(0, 10, 0, 2)
            label.BackgroundTransparency = 1
            label.Font = Theme.Font
            label.TextSize = Theme.TextSize
            label.TextColor3 = Theme.Text
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Text = "quantix | fps strafe | " .. Services.LocalPlayer.Name
            label.Parent = bg

            local shadow = label:Clone()
            shadow.Name = "Shadow"
            shadow.TextColor3 = Color3.new(0, 0, 0)
            shadow.Position = UDim2.new(0, 11, 0, 3)
            shadow.ZIndex = label.ZIndex - 1
            shadow.Parent = bg

            State.WatermarkGui = sg
        end
        State.WatermarkGui.Enabled = enabled
    end
    
    return module
end
