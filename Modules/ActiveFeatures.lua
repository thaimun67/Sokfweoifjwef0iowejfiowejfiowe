return function(State, Services, Theme)
    local module = {}
    local UserInputService = Services.UserInputService
    local CoreGui = Services.CoreGui
    
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

    local lastActiveHash = ""
    
    function module.toggle(enabled)
        lastActiveHash = ""
        if State.ActiveFeaturesGui then pcall(function() State.ActiveFeaturesGui:Destroy() end); State.ActiveFeaturesGui = nil end
        if not enabled then return end

        local sg = Instance.new("ScreenGui")
        sg.Name = "QuantixActiveFeatures"
        sg.ResetOnSpawn = false
        sg.ZIndexBehavior = Enum.ZIndexBehavior.Global
        pcall(function() sg.Interactable = State.GlobalWindow and State.GlobalWindow.Main.Visible or false end)
        sg.Parent = CoreGui

        local bg = Instance.new("Frame")
        bg.Name = "Background"
        bg.Size = UDim2.new(0, 150, 0, 25)
        bg.Position = UDim2.new(0, 10, 0, 180)
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

        local title = Instance.new("TextLabel")
        title.Name = "Title"
        title.Size = UDim2.new(1, 0, 0, 23)
        title.Position = UDim2.new(0, 0, 0, 2)
        title.BackgroundTransparency = 1
        title.Font = Theme.Font
        title.TextSize = Theme.TextSize - 1
        title.TextColor3 = Theme.Text
        title.Text = "active features"
        title.Parent = bg

        local listContainer = Instance.new("Frame")
        listContainer.Name = "List"
        listContainer.Size = UDim2.new(1, 0, 0, 0)
        listContainer.Position = UDim2.new(0, 0, 0, 25)
        listContainer.BackgroundTransparency = 1
        listContainer.Parent = bg

        local listLayout = Instance.new("UIListLayout")
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder
        listLayout.Padding = UDim.new(0, 2)
        listLayout.Parent = listContainer

        makeHUDElementDraggable(bg)

        State.ActiveFeaturesGui = sg
        State.ActiveFeaturesBg = bg
        State.ActiveFeaturesContainer = listContainer
    end

    function module.update()
        if not State.ActiveFeaturesGui or not State.ActiveFeaturesContainer then return end
        
        local active = {}
        if State.AimbotEnabled then table.insert(active, "aimbot") end
        if State.ESPEnabled then table.insert(active, "esp") end
        if State.NoRecoilEnabled then table.insert(active, "no recoil") end
        if State.NoSpreadEnabled then table.insert(active, "no spread") end
        if State.InfiniteAmmoEnabled then table.insert(active, "infinite ammo") end
        if State.SilentAimEnabled then table.insert(active, "silent aim") end
        if State.CustomFOVEnabled then table.insert(active, "custom fov") end
        if State.WeaponChamsEnabled then table.insert(active, "weapon chams") end

        local currentHash = table.concat(active, "|")
        if currentHash == lastActiveHash then
            return
        end
        lastActiveHash = currentHash

        for _, child in ipairs(State.ActiveFeaturesContainer:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end

        for i, text in ipairs(active) do
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, 18)
            row.BackgroundTransparency = 1
            row.LayoutOrder = i
            row.Parent = State.ActiveFeaturesContainer

            local dot = Instance.new("Frame")
            dot.Size = UDim2.new(0, 4, 0, 4)
            dot.Position = UDim2.new(0, 10, 0.5, -2)
            dot.BackgroundColor3 = Theme.AccentStart
            dot.BorderSizePixel = 0
            dot.Parent = row

            local dotCorner = Instance.new("UICorner")
            dotCorner.CornerRadius = UDim.new(0.5, 0)
            dotCorner.Parent = dot

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -22, 1, 0)
            lbl.Position = UDim2.new(0, 18, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Font = Theme.Font
            lbl.TextSize = Theme.TextSize - 3
            lbl.TextColor3 = Theme.Text
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.Text = text
            lbl.Parent = row
        end

        State.ActiveFeaturesBg.Size = UDim2.new(0, 150, 0, 28 + (#active * 18))
    end
    
    return module
end
