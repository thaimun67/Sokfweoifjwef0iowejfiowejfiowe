return function(State, Services, Theme, GameStateModule)
    local CoreGui = Services.CoreGui
    local RunService = Services.RunService
    local Players = Services.Players
    local LocalPlayer = Services.LocalPlayer
    local module = {}

    -- Clean up any residual drawing/instance visual elements from previous run failures
    function module.cleanupOldESP()
        local parent = RunService:IsStudio() and game.Players.LocalPlayer:WaitForChild("PlayerGui") or CoreGui
        for _, child in ipairs(parent:GetChildren()) do
            if child.Name == "AbyssHighlight" or child.Name == "AbyssBillboard" or child.Name == "AbyssFOV" or child.Name == "QuantixWatermark" or child.Name == "QuantixKeybinds" or child.Name == "QuantixActiveFeatures" or child.Name == "AbyssSelectionBox" or child.Name == "QuantixHighlight" or child.Name == "QuantixBillboard" or child.Name == "QuantixFOV" or child.Name == "QuantixUI" or child.Name == "AbyssUI" or child.Name == "QuantixSilentAimFOV" then
                pcall(function() child:Destroy() end)
            end
        end
        for _, player in ipairs(Players:GetPlayers()) do
            local char = player.Character
            if char then
                local hl = char:FindFirstChild("QuantixHighlight") or char:FindFirstChild("AbyssHighlight")
                if hl then pcall(function() hl:Destroy() end) end
            end
        end
        local NPCS = workspace:FindFirstChild("NPCS")
        if NPCS then
            for _, mob in ipairs(NPCS:GetChildren()) do
                local hl = mob:FindFirstChild("QuantixHighlight") or mob:FindFirstChild("AbyssHighlight")
                if hl then pcall(function() hl:Destroy() end) end
            end
        end
    end


    -- Helper to safely clean up visual components and connections of a single entity
    function module.removeESP(entity)
        local data = State.EspElements[entity]
        if data then
            if data.Highlight then pcall(function() data.Highlight:Destroy() end) end
            if data.Billboard then pcall(function() data.Billboard:Destroy() end) end
            if data.Box2D then pcall(function() data.Box2D:Remove() end) end
            if data.Connections then
                for _, conn in ipairs(data.Connections) do
                    pcall(function() conn:Disconnect() end)
                end
            end
            State.EspElements[entity] = nil
        end
        local char = entity:IsA("Player") and entity.Character or (entity:IsA("Model") and entity)
        if char then
            local hl = char:FindFirstChild("QuantixHighlight") or char:FindFirstChild("AbyssHighlight")
            if hl then pcall(function() hl:Destroy() end) end
        end
    end

    -- Create visual components for a single player character
    function module.setupCharacterESP(player, char)
        module.removeESP(player)
        if player == LocalPlayer then return end

        local isTeammateVal = State.TeamCheck and GameStateModule.getCachedTeammateStatus(player)

        for _, child in ipairs(char:GetChildren()) do
            if child:IsA("Highlight") and child.Name ~= "QuantixHighlight" then
                pcall(function() child:Destroy() end)
            end
        end

        local highlight = char:FindFirstChild("QuantixHighlight")
        if not highlight then
            highlight = Instance.new("Highlight")
            highlight.Name = "QuantixHighlight"
            highlight.FillTransparency = State.ChamsFillTrans
            highlight.FillColor = Color3.fromRGB(State.ChamsFillR, State.ChamsFillG, State.ChamsFillB)
            highlight.OutlineColor = Color3.fromRGB(State.ChamsOutlineR, State.ChamsOutlineG, State.ChamsOutlineB)
            highlight.OutlineTransparency = State.ChamsOutlineTrans
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.Adornee = char
            highlight.Parent = char
        end
        highlight.Enabled = State.ESPEnabled and State.BoxESP and not isTeammateVal

        local billboard = Instance.new("BillboardGui")
        billboard.Name = "QuantixBillboard"
        billboard.AlwaysOnTop = true
        billboard.Size = UDim2.new(0, 200, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.Adornee = char:WaitForChild("Head", 5) or char.PrimaryPart
        billboard.Enabled = State.ESPEnabled and State.NameESP and not isTeammateVal
        pcall(function()
            billboard.Parent = RunService:IsStudio() and game.Players.LocalPlayer:WaitForChild("PlayerGui") or CoreGui
        end)

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, 0, 1, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.TextStrokeTransparency = 0
        nameLabel.Font = Theme.Font
        nameLabel.TextSize = 12
        nameLabel.Text = player.DisplayName or player.Name
        nameLabel.Parent = billboard

        local box2D = nil
        if Drawing and Drawing.new then
            pcall(function()
                box2D = Drawing.new("Square")
                box2D.Thickness = State.Box2DThickness
                box2D.Filled = false
                box2D.Color = Color3.fromRGB(State.Box2DR, State.Box2DG, State.Box2DB)
                box2D.Visible = false
            end)
        end

        local charConns = {}
        local ancestryConn
        ancestryConn = char.AncestryChanged:Connect(function(_, parent)
            if not parent then
                module.removeESP(player)
            end
        end)
        table.insert(charConns, ancestryConn)

        State.EspElements[player] = {
            Highlight = highlight,
            Billboard = billboard,
            Box2D = box2D,
            Connections = charConns
        }
    end

    -- Track player Added/Removing connections
    function module.trackPlayer(player)
        if player == LocalPlayer then return end

        if State.PlayerConnections[player] then
            for _, conn in ipairs(State.PlayerConnections[player]) do
                pcall(function() conn:Disconnect() end)
            end
        end

        local conns = {}
        local addedConn = player.CharacterAdded:Connect(function(char)
            module.setupCharacterESP(player, char)
        end)
        table.insert(conns, addedConn)

        State.PlayerConnections[player] = conns

        if player.Character then
            module.setupCharacterESP(player, player.Character)
        end
    end

    function module.untrackPlayer(player)
        if State.PlayerConnections[player] then
            for _, conn in ipairs(State.PlayerConnections[player]) do
                pcall(function() conn:Disconnect() end)
            end
            State.PlayerConnections[player] = nil
        end
        module.removeESP(player)
    end

    -- Create visual components for an NPC/Mob
    function module.setupMobESP(mob)
        module.removeESP(mob)

        local isTeammateMob = State.TeamCheck and GameStateModule.getCachedTeammateStatus(mob)

        for _, child in ipairs(mob:GetChildren()) do
            if child:IsA("Highlight") and child.Name ~= "QuantixHighlight" then
                pcall(function() child:Destroy() end)
            end
        end

        local highlight = mob:FindFirstChild("QuantixHighlight")
        if not highlight then
            highlight = Instance.new("Highlight")
            highlight.Name = "QuantixHighlight"
            highlight.FillTransparency = State.ChamsFillTrans
            highlight.FillColor = Color3.fromRGB(State.ChamsFillR, State.ChamsFillG, State.ChamsFillB)
            highlight.OutlineColor = Color3.fromRGB(State.ChamsOutlineR, State.ChamsOutlineG, State.ChamsOutlineB)
            highlight.OutlineTransparency = State.ChamsOutlineTrans
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.Adornee = mob
            highlight.Parent = mob
        end
        highlight.Enabled = State.ESPEnabled and State.BoxESP and not isTeammateMob

        local billboard = Instance.new("BillboardGui")
        billboard.Name = "QuantixBillboard"
        billboard.AlwaysOnTop = true
        billboard.Size = UDim2.new(0, 200, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.Adornee = mob:WaitForChild("Head", 5) or mob.PrimaryPart
        billboard.Enabled = State.ESPEnabled and State.NameESP and not isTeammateMob
        pcall(function()
            billboard.Parent = RunService:IsStudio() and game.Players.LocalPlayer:WaitForChild("PlayerGui") or CoreGui
        end)

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, 0, 1, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.TextStrokeTransparency = 0
        nameLabel.Font = Theme.Font
        nameLabel.TextSize = 12
        nameLabel.Text = mob.Name
        nameLabel.Parent = billboard

        local box2D = nil
        if Drawing and Drawing.new then
            pcall(function()
                box2D = Drawing.new("Square")
                box2D.Thickness = State.Box2DThickness
                box2D.Filled = false
                box2D.Color = Color3.fromRGB(State.Box2DR, State.Box2DG, State.Box2DB)
                box2D.Visible = false
            end)
        end

        local mobConns = {}
        local ancestryConn
        ancestryConn = mob.AncestryChanged:Connect(function(_, parent)
            if not parent then
                module.removeESP(mob)
            end
        end)
        table.insert(mobConns, ancestryConn)

        State.EspElements[mob] = {
            Highlight = highlight,
            Billboard = billboard,
            Box2D = box2D,
            Connections = mobConns
        }
    end

    -- Centralized ESP Update Loop
    function module.updateESPObjects()
        local activeCam = workspace.CurrentCamera
        if not activeCam then return end

        local fillC = Color3.fromRGB(State.ChamsFillR, State.ChamsFillG, State.ChamsFillB)
        local outC = Color3.fromRGB(State.ChamsOutlineR, State.ChamsOutlineG, State.ChamsOutlineB)
        local boxC = Color3.fromRGB(State.Box2DR, State.Box2DG, State.Box2DB)

        for entity, data in pairs(State.EspElements) do
            local isTeammateVal = State.TeamCheck and GameStateModule.getCachedTeammateStatus(entity)
            local char = entity:IsA("Player") and entity.Character or entity
            local isAlive = false
            local root = nil

            if char and char.Parent then
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
                isAlive = humanoid and humanoid.Health > 0 and root
            end

            local showESP = State.ESPEnabled and not isTeammateVal and isAlive

            if data.Highlight then
                data.Highlight.Enabled = showESP and State.BoxESP
                data.Highlight.FillTransparency = State.ChamsFillTrans
                data.Highlight.OutlineTransparency = State.ChamsOutlineTrans
                data.Highlight.FillColor = fillC
                data.Highlight.OutlineColor = outC
            end

            if data.Billboard then
                data.Billboard.Enabled = showESP and State.NameESP
            end

            if data.Box2D then
                local box = data.Box2D
                if showESP and State.Box2DESP and root then
                    local pos, onScreen = activeCam:WorldToViewportPoint(root.Position)
                    if onScreen then
                        local sizeY = (activeCam:WorldToViewportPoint(root.Position + Vector3.new(0, 3, 0)).Y - activeCam:WorldToViewportPoint(root.Position - Vector3.new(0, 3.5, 0)).Y)
                        local sizeX = sizeY / 2
                        box.Size = Vector2.new(math.abs(sizeX), math.abs(sizeY))
                        box.Position = Vector2.new(pos.X - (box.Size.X / 2), pos.Y - (box.Size.Y / 2))
                        box.Thickness = State.Box2DThickness
                        box.Color = boxC
                        box.Visible = true
                    else
                        box.Visible = false
                    end
                else
                    box.Visible = false
                end
            end
        end
    end

    function module.updateESP()
        pcall(module.updateESPObjects)
    end

    return module
end
