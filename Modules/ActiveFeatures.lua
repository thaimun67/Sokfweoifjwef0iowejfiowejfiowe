return function(State, Services, Theme)
    local module = {}
    
    function module.toggle(enabled)
        if not State.ActiveFeaturesGui then
            local sg = Instance.new("ScreenGui")
            sg.Name = "QuantixActiveFeatures"
            sg.ResetOnSpawn = false
            sg.ZIndexBehavior = Enum.ZIndexBehavior.Global
            sg.Parent = Services.CoreGui

            local bg = Instance.new("Frame")
            bg.Name = "Background"
            bg.Size = UDim2.new(0, 200, 0, 25)
            bg.Position = UDim2.new(0, 10, 0, 80)
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

            local title = Instance.new("TextLabel")
            title.Name = "Title"
            title.Size = UDim2.new(1, 0, 1, 0)
            title.Position = UDim2.new(0, 0, 0, 0)
            title.BackgroundTransparency = 1
            title.Font = Theme.Font
            title.TextSize = Theme.TextSize
            title.TextColor3 = Theme.Text
            title.Text = "active features"
            title.Parent = bg

            local listContainer = Instance.new("Frame")
            listContainer.Name = "List"
            listContainer.Size = UDim2.new(1, 0, 0, 0)
            listContainer.Position = UDim2.new(0, 0, 1, 0)
            listContainer.BackgroundTransparency = 1
            listContainer.Parent = bg

            local listLayout = Instance.new("UIListLayout")
            listLayout.SortOrder = Enum.SortOrder.LayoutOrder
            listLayout.Parent = listContainer

            State.ActiveFeaturesGui = sg
            State.ActiveFeaturesBg = bg
            State.ActiveFeaturesContainer = listContainer
        end
        State.ActiveFeaturesGui.Enabled = enabled
    end

    function module.update()
        if not State.ActiveFeaturesGui or not State.ActiveFeaturesGui.Enabled then return end
        
        local active = {}
        if State.AimbotEnabled then table.insert(active, "aimbot") end
        if State.ESPEnabled then table.insert(active, "esp") end
        if State.NoRecoilEnabled then table.insert(active, "no recoil") end
        if State.NoSpreadEnabled then table.insert(active, "no spread") end
        if State.InfiniteAmmoEnabled then table.insert(active, "infinite ammo") end
        if State.SilentAimEnabled then table.insert(active, "silent aim") end
        if State.CustomFOVEnabled then table.insert(active, "custom fov") end
        if State.WeaponChamsEnabled then table.insert(active, "weapon chams") end

        for _, child in ipairs(State.ActiveFeaturesContainer:GetChildren()) do
            if child:IsA("TextLabel") then child:Destroy() end
        end

        for i, text in ipairs(active) do
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -10, 0, 20)
            lbl.Position = UDim2.new(0, 10, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Font = Theme.Font
            lbl.TextSize = Theme.TextSize
            lbl.TextColor3 = Theme.TextDark
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.Text = text
            lbl.LayoutOrder = i
            lbl.Parent = State.ActiveFeaturesContainer
        end

        State.ActiveFeaturesBg.Size = UDim2.new(0, 200, 0, 25 + (#active * 20))
    end
    
    return module
end
