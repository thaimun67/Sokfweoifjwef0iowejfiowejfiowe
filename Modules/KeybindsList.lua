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
        if State.KeybindsGui then pcall(function() State.KeybindsGui:Destroy() end); State.KeybindsGui = nil end
        if not enabled then return end

        local sg = Instance.new("ScreenGui")
        sg.Name = "QuantixKeybinds"
        sg.ResetOnSpawn = false
        sg.ZIndexBehavior = Enum.ZIndexBehavior.Global
        pcall(function() sg.Interactable = State.GlobalWindow and State.GlobalWindow.Main.Visible or false end)
        sg.Parent = CoreGui

        local bg = Instance.new("Frame")
        bg.Name = "Background"
        bg.Size = UDim2.new(0, 150, 0, 25)
        bg.Position = UDim2.new(0, 10, 0, 80)
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
        title.Text = "keybinds"
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

        State.KeybindsGui = sg
        State.KeybindsBg = bg
        State.KeybindsListContainer = listContainer
    end

    local function getKeyName(key)
        if not key then return "None" end
        local name = tostring(key)
        name = name:gsub("Enum.KeyCode.", ""):gsub("Enum.UserInputType.", "")
        if name == "MouseButton1" then return "M1" end
        if name == "MouseButton2" then return "M2" end
        return name
    end

    function module.update()
        if not State.KeybindsGui or not State.KeybindsListContainer then return end
        
        local active = {}
        if State.AimbotEnabled then
            local aimKeyStr = getKeyName(State.AimKey)
            table.insert(active, { name = "aimbot", bind = "[" .. aimKeyStr .. "]", active = State.Aiming })
        end
        if State.SilentAimEnabled then
            table.insert(active, { name = "silent aim", bind = "[active]", active = true })
        end
        
        local menuKeyStr = getKeyName(State.MenuToggleKey or Enum.KeyCode.Insert)
        table.insert(active, { name = "menu", bind = "[" .. menuKeyStr .. "]", active = true })

        local hashParts = {}
        for _, kb in ipairs(active) do
            table.insert(hashParts, kb.name .. ":" .. kb.bind .. ":" .. tostring(kb.active))
        end
        local currentHash = table.concat(hashParts, "|")
        if currentHash == lastActiveHash then
            return
        end
        lastActiveHash = currentHash

        for _, child in ipairs(State.KeybindsListContainer:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end

        for i, kb in ipairs(active) do
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, 18)
            row.BackgroundTransparency = 1
            row.LayoutOrder = i
            row.Parent = State.KeybindsListContainer

            local nameLbl = Instance.new("TextLabel")
            nameLbl.Size = UDim2.new(0.6, -10, 1, 0)
            nameLbl.Position = UDim2.new(0, 10, 0, 0)
            nameLbl.BackgroundTransparency = 1
            nameLbl.Font = Theme.Font
            nameLbl.TextSize = Theme.TextSize - 3
            nameLbl.TextColor3 = kb.active and Theme.Text or Theme.TextDark
            nameLbl.TextXAlignment = Enum.TextXAlignment.Left
            nameLbl.Text = kb.name
            nameLbl.Parent = row

            local bindLbl = Instance.new("TextLabel")
            bindLbl.Size = UDim2.new(0.4, -10, 1, 0)
            bindLbl.Position = UDim2.new(0.6, 0, 0, 0)
            bindLbl.BackgroundTransparency = 1
            bindLbl.Font = Theme.Font
            bindLbl.TextSize = Theme.TextSize - 3
            bindLbl.TextColor3 = kb.active and Theme.AccentStart or Theme.TextDark
            bindLbl.TextXAlignment = Enum.TextXAlignment.Right
            bindLbl.Text = kb.bind
            bindLbl.Parent = row
        end

        State.KeybindsBg.Size = UDim2.new(0, 150, 0, 28 + (#active * 18))
    end
    
    return module
end
