return function(State, Services, Theme)
    local module = {}
    local RunService = Services.RunService
    local UserInputService = Services.UserInputService
    local LocalPlayer = Services.LocalPlayer
    local CoreGui = Services.CoreGui
    
    local connection = nil
    local updateThread = nil

    local function makeHUDElementDraggable(frame)
        local dragging, dragInput, dragStart, startPos
        
        frame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 and State.GlobalWindow and State.GlobalWindow.Main.Visible then
                dragging = true
                dragStart = input.Position
                startPos = frame.Position
            end
        end)
        frame.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
        end)
        table.insert(State.Connections, UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                local delta = input.Position - dragStart
                frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end))
        table.insert(State.Connections, UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
        end))
    end

    function module.toggle(enabled)
        if connection then connection:Disconnect(); connection = nil end
        if updateThread then pcall(function() task.cancel(updateThread) end); updateThread = nil end
        if State.WatermarkGui then pcall(function() State.WatermarkGui:Destroy() end); State.WatermarkGui = nil end

        if not enabled then return end

        local sg = Instance.new("ScreenGui")
        sg.Name = "QuantixWatermark"
        sg.ResetOnSpawn = false
        sg.ZIndexBehavior = Enum.ZIndexBehavior.Global
        pcall(function() sg.Interactable = State.GlobalWindow and State.GlobalWindow.Main.Visible or false end)
        sg.Parent = CoreGui

        local bg = Instance.new("Frame")
        bg.Name = "Background"
        bg.Size = UDim2.new(0, 200, 0, 24)
        bg.Position = UDim2.new(1, -210, 0, 10)
        bg.BackgroundColor3 = Theme.Background
        bg.BackgroundTransparency = 0.2
        bg.BorderSizePixel = 0
        bg.Parent = sg

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 4)
        corner.Parent = bg

        local outline = Instance.new("UIStroke")
        outline.Color = Theme.DarkOutline
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
        local shadow = Instance.new("TextLabel")

        label.Name = "Label"
        label.Size = UDim2.new(1, -12, 1, -2)
        label.Position = UDim2.new(0, 6, 0, 2)
        label.BackgroundTransparency = 1
        label.Font = Theme.Font
        label.TextSize = Theme.TextSize - 2
        label.TextColor3 = Theme.Text
        label.TextXAlignment = Enum.TextXAlignment.Center
        label.Text = "quantix | fps: -- | ping: --ms"
        label.ZIndex = 2
        label.Parent = bg

        shadow.Name = "Shadow"
        shadow.Size = label.Size
        shadow.Position = UDim2.new(0, 7, 0, 3)
        shadow.BackgroundTransparency = 1
        shadow.Font = Theme.Font
        shadow.TextSize = Theme.TextSize - 2
        shadow.TextColor3 = Color3.new(0, 0, 0)
        shadow.TextXAlignment = Enum.TextXAlignment.Center
        shadow.Text = label.Text
        shadow.ZIndex = 1
        shadow.Parent = bg

        makeHUDElementDraggable(bg)
        State.WatermarkGui = sg

        local fpsCount = 0
        local lastTick = tick()
        connection = RunService.RenderStepped:Connect(function()
            fpsCount = fpsCount + 1
        end)
        
        updateThread = task.spawn(function()
            while State.WatermarkEnabled and State.WatermarkGui do
                task.wait(0.5)
                local currentTick = tick()
                local timeDiff = currentTick - lastTick
                local fps = math.round(fpsCount / timeDiff)
                fpsCount = 0
                lastTick = currentTick
                
                local ping = 0
                pcall(function()
                    ping = math.round(LocalPlayer:GetNetworkPing() * 1000)
                end)
                
                pcall(function()
                    local statText = string.format("quantix | fps: %d | ping: %dms", fps, ping)
                    label.Text = statText
                    shadow.Text = statText
                    local textBounds = game:GetService("TextService"):GetTextSize(statText, Theme.TextSize - 2, Theme.Font, Vector2.new(999, 20))
                    bg.Size = UDim2.new(0, textBounds.X + 16, 0, 24)
                end)
            end
        end)
    end
    
    return module
end
