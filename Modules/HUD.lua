return function(State, Services, Theme)
    local CoreGui = Services.CoreGui
    local UserInputService = Services.UserInputService
    local RunService = Services.RunService
    local LocalPlayer = Services.LocalPlayer
    local module = {}

    -- // Draggable HUD Elements
    local function makeHUDElementDraggable(frame, gui)
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

    -- // Watermark
    local WatermarkEnabled = false
    if State.WatermarkGui == nil then State.WatermarkGui = nil end
    local watermarkThread  = nil

    local function toggleWatermark(state)
        WatermarkEnabled = state
        if State.WatermarkGui then
            pcall(function() State.WatermarkGui:Destroy() end)
            State.WatermarkGui = nil
        end
        if watermarkThread then
            pcall(function() task.cancel(watermarkThread) end)
            watermarkThread = nil
        end

        if not state then return end

        local parent = RunService:IsStudio() and game.Players.LocalPlayer:WaitForChild("PlayerGui") or CoreGui

        local gui = Instance.new("ScreenGui")
        gui.Name = "QuantixWatermark"
        gui.ResetOnSpawn = false
        pcall(function() gui.Interactable = State.GlobalWindow and State.GlobalWindow.Main.Visible or false end)

        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 180, 0, 24)
        frame.Position = UDim2.new(1, -30, 1, -85)
        frame.AnchorPoint = Vector2.new(1, 1)
        frame.BackgroundColor3 = Theme.Background
        frame.BackgroundTransparency = 0.2
        frame.BorderSizePixel = 0
        frame.Parent = gui

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 4)
        corner.Parent = frame

        -- Premium accent line at the top
        local accentLine = Instance.new("Frame")
        accentLine.Size = UDim2.new(1, 0, 0, 2)
        accentLine.Position = UDim2.new(0, 0, 0, 0)
        accentLine.BorderSizePixel = 0
        accentLine.Parent = frame

        local lineGradient = Instance.new("UIGradient")
        lineGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Theme.AccentStart),
            ColorSequenceKeypoint.new(1, Theme.AccentEnd)
        })
        lineGradient.Parent = accentLine

        local stroke = Instance.new("UIStroke")
        stroke.Thickness = 1
        stroke.Color = Theme.DarkOutline
        stroke.Parent = frame

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -12, 1, -2)
        label.Position = UDim2.new(0, 6, 0, 2)
        label.BackgroundTransparency = 1
        label.Text = "quantix | fps: -- | ping: --ms"
        label.TextColor3 = Theme.Text
        label.Font = Theme.Font
        label.TextSize = 11
        label.TextXAlignment = Enum.TextXAlignment.Center
        label.Parent = frame

        makeHUDElementDraggable(frame, gui)

        gui.Parent = parent
        State.WatermarkGui = gui

        -- Dynamic stat calculator
        local fpsCount = 0
        local lastTick = tick()
        local connection
        connection = RunService.RenderStepped:Connect(function()
            fpsCount = fpsCount + 1
        end)

        watermarkThread = task.spawn(function()
            while WatermarkEnabled and State.WatermarkGui do
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
                    local textBounds = game:GetService("TextService"):GetTextSize(statText, 11, Theme.Font, Vector2.new(999, 20))
                    frame.Size = UDim2.new(0, textBounds.X + 16, 0, 24)
                end)
            end
            if connection then connection:Disconnect() end
        end)
    end
    module.toggleWatermark = toggleWatermark

    -- // Keybinds List
    if State.KeybindsGui == nil then State.KeybindsGui = nil end
    local AimKeyLabel = nil
    local MenuKeyLabel = nil
    local AimKeyIndicator = nil
    local MenuKeyIndicator = nil

    local function toggleKeybindsList(state)
        if State.KeybindsGui then
            pcall(function() State.KeybindsGui:Destroy() end)
            State.KeybindsGui = nil
            AimKeyLabel = nil
            MenuKeyLabel = nil
            AimKeyIndicator = nil
            MenuKeyIndicator = nil
        end

        if not state then return end

        local parent = RunService:IsStudio() and game.Players.LocalPlayer:WaitForChild("PlayerGui") or CoreGui

        local gui = Instance.new("ScreenGui")
        gui.Name = "QuantixKeybinds"
        gui.ResetOnSpawn = false
        pcall(function() gui.Interactable = State.GlobalWindow and State.GlobalWindow.Main.Visible or false end)

        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 140, 0, 60)
        frame.Position = UDim2.new(0, 15, 0, 60) -- below topbar buttons
        frame.BackgroundColor3 = Theme.Background
        frame.BackgroundTransparency = 0.2
        frame.BorderSizePixel = 0
        frame.Parent = gui

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 4)
        corner.Parent = frame

        -- Sleek top accent line
        local accentLine = Instance.new("Frame")
        accentLine.Size = UDim2.new(1, 0, 0, 2)
        accentLine.Position = UDim2.new(0, 0, 0, 0)
        accentLine.BorderSizePixel = 0
        accentLine.Parent = frame

        local lineGradient = Instance.new("UIGradient")
        lineGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Theme.AccentStart),
            ColorSequenceKeypoint.new(1, Theme.AccentEnd)
        })
        lineGradient.Parent = accentLine

        local stroke = Instance.new("UIStroke")
        stroke.Thickness = 1
        stroke.Color = Theme.DarkOutline
        stroke.Parent = frame

        -- Header text
        local header = Instance.new("TextLabel")
        header.Size = UDim2.new(1, -10, 0, 18)
        header.Position = UDim2.new(0, 8, 0, 3)
        header.BackgroundTransparency = 1
        header.Text = "keybinds"
        header.TextColor3 = Theme.Text
        header.Font = Theme.Font
        header.TextSize = 11
        header.TextXAlignment = Enum.TextXAlignment.Left
        header.Parent = frame

        local separator = Instance.new("Frame")
        separator.Size = UDim2.new(1, -16, 0, 1)
        separator.Position = UDim2.new(0, 8, 0, 21)
        separator.BackgroundColor3 = Theme.DarkOutline
        separator.BorderSizePixel = 0
        separator.Parent = frame

        -- Aim Keybind Container
        local aimRow = Instance.new("Frame")
        aimRow.Size = UDim2.new(1, -16, 0, 15)
        aimRow.Position = UDim2.new(0, 8, 0, 23)
        aimRow.BackgroundTransparency = 1
        aimRow.Parent = frame

        local aimInd = Instance.new("Frame")
        aimInd.Size = UDim2.new(0, 5, 0, 5)
        aimInd.Position = UDim2.new(0, 0, 0.5, -2)
        aimInd.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        aimInd.BorderSizePixel = 0
        aimInd.Parent = aimRow

        local aimCorner = Instance.new("UICorner")
        aimCorner.CornerRadius = UDim.new(0.5, 0)
        aimCorner.Parent = aimInd

        local aimLabel = Instance.new("TextLabel")
        aimLabel.Size = UDim2.new(1, -12, 1, 0)
        aimLabel.Position = UDim2.new(0, 12, 0, 0)
        aimLabel.BackgroundTransparency = 1
        aimLabel.Text = "aimbot  [M2]"
        aimLabel.TextColor3 = Theme.TextDark
        aimLabel.Font = Theme.Font
        aimLabel.TextSize = 10
        aimLabel.TextXAlignment = Enum.TextXAlignment.Left
        aimLabel.Parent = aimRow

        -- Menu Keybind Container
        local menuRow = Instance.new("Frame")
        menuRow.Size = UDim2.new(1, -16, 0, 15)
        menuRow.Position = UDim2.new(0, 8, 0, 38)
        menuRow.BackgroundTransparency = 1
        menuRow.Parent = frame

        local menuInd = Instance.new("Frame")
        menuInd.Size = UDim2.new(0, 5, 0, 5)
        menuInd.Position = UDim2.new(0, 0, 0.5, -2)
        menuInd.BackgroundColor3 = Color3.fromRGB(0, 255, 120) -- Menu is active/loaded
        menuInd.BorderSizePixel = 0
        menuInd.Parent = menuRow

        local menuCorner = Instance.new("UICorner")
        menuCorner.CornerRadius = UDim.new(0.5, 0)
        menuCorner.Parent = menuInd

        local menuLabel = Instance.new("TextLabel")
        menuLabel.Size = UDim2.new(1, -12, 1, 0)
        menuLabel.Position = UDim2.new(0, 12, 0, 0)
        menuLabel.BackgroundTransparency = 1
        menuLabel.Text = "menu    [Insert]"
        menuLabel.TextColor3 = Theme.TextDark
        menuLabel.Font = Theme.Font
        menuLabel.TextSize = 10
        menuLabel.TextXAlignment = Enum.TextXAlignment.Left
        menuLabel.Parent = menuRow

        makeHUDElementDraggable(frame, gui)

        gui.Parent = parent
        State.KeybindsGui = gui
        AimKeyLabel = aimLabel
        MenuKeyLabel = menuLabel
        AimKeyIndicator = aimInd
        MenuKeyIndicator = menuInd
    end
    module.toggleKeybindsList = toggleKeybindsList

    local function getKeyName(key)
        if not key then return "None" end
        local name = tostring(key)
        name = name:gsub("Enum.KeyCode.", ""):gsub("Enum.UserInputType.", "")
        if name == "MouseButton1" then return "M1" end
        if name == "MouseButton2" then return "M2" end
        return name
    end
    module.getKeyName = getKeyName

    local function updateKeybindsListText()
        if not State.KeybindsGui then return end
        pcall(function()
            local isAimActive = State.Aiming and State.AimbotEnabled
            if AimKeyIndicator then
                AimKeyIndicator.BackgroundColor3 = isAimActive and Color3.fromRGB(0, 255, 120) or Color3.fromRGB(60, 60, 60)
            end

            local aimText = "aimbot  [" .. getKeyName(State.AimKey) .. "]"
            if AimKeyLabel then
                AimKeyLabel.Text = aimText
                AimKeyLabel.TextColor3 = isAimActive and Theme.Text or Theme.TextDark
            end

            local menuText = "menu    [" .. getKeyName(State.MenuToggleKey) .. "]"
            if MenuKeyLabel and MenuKeyLabel.Text ~= menuText then
                MenuKeyLabel.Text = menuText
            end
        end)
    end
    module.updateKeybindsListText = updateKeybindsListText

    -- // Active Features HUD
    local ActiveFeaturesListEnabled = false
    if State.ActiveFeaturesGui == nil then State.ActiveFeaturesGui = nil end
    local ActiveFeaturesFrame = nil
    local lastActiveHash = ""

    local function updateActiveFeaturesHUD()
        if not State.ActiveFeaturesGui or not ActiveFeaturesFrame then return end

        local active = {}
        if State.AimbotEnabled then table.insert(active, "aimbot") end
        if State.ESPEnabled then table.insert(active, "esp") end
        if State.NoRecoilEnabled then table.insert(active, "no recoil") end
        if State.CustomFOVEnabled then table.insert(active, "custom fov") end
        if State.CustomSkyboxEnabled then table.insert(active, "custom skybox") end

        local hash = table.concat(active, ",")
        if hash == lastActiveHash then return end
        lastActiveHash = hash

        local success, err = pcall(function()
            -- Clear previous rows
            for _, child in ipairs(ActiveFeaturesFrame:GetChildren()) do
                if child:IsA("Frame") and child.Name == "FeatureRow" then
                    child:Destroy()
                end
            end

            -- Re-create active rows
            local yOffset = 23
            for _, name in ipairs(active) do
                local row = Instance.new("Frame")
                row.Name = "FeatureRow"
                row.Size = UDim2.new(1, -16, 0, 15)
                row.Position = UDim2.new(0, 8, 0, yOffset)
                row.BackgroundTransparency = 1
                row.Parent = ActiveFeaturesFrame

                local ind = Instance.new("Frame")
                ind.Size = UDim2.new(0, 5, 0, 5)
                ind.Position = UDim2.new(0, 0, 0.5, -2)
                ind.BackgroundColor3 = Color3.fromRGB(0, 255, 120) -- Green glowing dot
                ind.BorderSizePixel = 0
                ind.Parent = row

                local indCorner = Instance.new("UICorner")
                indCorner.CornerRadius = UDim.new(0.5, 0)
                indCorner.Parent = ind

                local label = Instance.new("TextLabel")
                label.Size = UDim2.new(1, -12, 1, 0)
                label.Position = UDim2.new(0, 12, 0, 0)
                label.BackgroundTransparency = 1
                label.Text = name
                label.TextColor3 = Theme.Text
                label.Font = Theme.Font
                label.TextSize = 10
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.Parent = row

                yOffset = yOffset + 15
            end

            -- Resize frame dynamically
            ActiveFeaturesFrame.Size = UDim2.new(0, 140, 0, math.max(30, yOffset + 5))
        end)
        if not success then
            warn("Quantix ActiveFeaturesHUD Error: " .. tostring(err))
        end
    end
    module.updateActiveFeaturesHUD = updateActiveFeaturesHUD

    local function toggleActiveFeaturesHUD(state)
        ActiveFeaturesListEnabled = state
        if State.ActiveFeaturesGui then
            pcall(function() State.ActiveFeaturesGui:Destroy() end)
            State.ActiveFeaturesGui = nil
            ActiveFeaturesFrame = nil
        end

        lastActiveHash = ""
        if not state then return end

        local parent = RunService:IsStudio() and game.Players.LocalPlayer:WaitForChild("PlayerGui") or CoreGui

        local gui = Instance.new("ScreenGui")
        gui.Name = "QuantixActiveFeatures"
        gui.ResetOnSpawn = false
        pcall(function() gui.Interactable = State.GlobalWindow and State.GlobalWindow.Main.Visible or false end)

        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 140, 0, 30)
        frame.Position = UDim2.new(0, 15, 0, 130) -- Align directly below the keybinds list
        frame.BackgroundColor3 = Theme.Background
        frame.BackgroundTransparency = 0.2
        frame.BorderSizePixel = 0
        frame.Parent = gui

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 4)
        corner.Parent = frame

        -- Top accent line
        local accentLine = Instance.new("Frame")
        accentLine.Size = UDim2.new(1, 0, 0, 2)
        accentLine.Position = UDim2.new(0, 0, 0, 0)
        accentLine.BorderSizePixel = 0
        accentLine.Parent = frame

        local lineGradient = Instance.new("UIGradient")
        lineGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Theme.AccentStart),
            ColorSequenceKeypoint.new(1, Theme.AccentEnd)
        })
        lineGradient.Parent = accentLine

        local stroke = Instance.new("UIStroke")
        stroke.Thickness = 1
        stroke.Color = Theme.DarkOutline
        stroke.Parent = frame

        local header = Instance.new("TextLabel")
        header.Size = UDim2.new(1, -10, 0, 18)
        header.Position = UDim2.new(0, 8, 0, 3)
        header.BackgroundTransparency = 1
        header.Text = "active features"
        header.TextColor3 = Theme.Text
        header.Font = Theme.Font
        header.TextSize = 11
        header.TextXAlignment = Enum.TextXAlignment.Left
        header.Parent = frame

        local separator = Instance.new("Frame")
        separator.Size = UDim2.new(1, -16, 0, 1)
        separator.Position = UDim2.new(0, 8, 0, 21)
        separator.BackgroundColor3 = Theme.DarkOutline
        separator.BorderSizePixel = 0
        separator.Parent = frame

        makeHUDElementDraggable(frame, gui)

        gui.Parent = parent
        State.ActiveFeaturesGui = gui
        ActiveFeaturesFrame = frame

        updateActiveFeaturesHUD()
    end
    module.toggleActiveFeaturesHUD = toggleActiveFeaturesHUD

    return module
end
