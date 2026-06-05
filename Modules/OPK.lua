return function(State, Services, GameStateModule)
    local module = {}
    local Players = Services.Players
    local LocalPlayer = Services.LocalPlayer
    local RunService = Services.RunService

    -- Keep track of which characters we have modified so we can restore them if needed
    local modifiedCharacters = {}

    function module.update()
        if not State.OPKEnabled then
            -- Clean up and unanchor any previously modified characters
            for char, _ in pairs(modifiedCharacters) do
                pcall(function()
                    local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
                    if root then
                        root.Anchored = false
                    end
                end)
            end
            table.clear(modifiedCharacters)
            return
        end

        local localChar = LocalPlayer.Character
        if not localChar then return end
        local localRoot = localChar:FindFirstChild("HumanoidRootPart")
        if not localRoot then return end

        local opkDistance = State.OPKDistance or 6
        local targetCFrame = localRoot.CFrame * CFrame.new(0, 0, -opkDistance)

        -- Function to process a single character model
        local function processCharacter(char, isNPC)
            local hum = char:FindFirstChildOfClass("Humanoid")
            local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
            
            if hum and hum.Health > 0 and root then
                -- Determine teammate status
                local isTeammate = false
                if isNPC then
                    isTeammate = State.TeamCheck and GameStateModule.getCachedTeammateStatus(char)
                else
                    local player = Players:GetPlayerFromCharacter(char)
                    if player then
                        isTeammate = State.TeamCheck and GameStateModule.getCachedTeammateStatus(player)
                    end
                end

                if not isTeammate then
                    -- Bring them in front of us
                    pcall(function()
                        root.CFrame = targetCFrame
                        root.Anchored = true
                        if root:IsA("BasePart") then
                            root.AssemblyLinearVelocity = Vector3.zero
                            root.AssemblyAngularVelocity = Vector3.zero
                            root.Velocity = Vector3.zero
                            root.RotVelocity = Vector3.zero
                        end
                    end)
                    modifiedCharacters[char] = true
                else
                    -- If they are a teammate but were previously modified, restore them
                    if modifiedCharacters[char] then
                        pcall(function()
                            root.Anchored = false
                        end)
                        modifiedCharacters[char] = nil
                    end
                end
            else
                -- If they died or root is gone, clean them up from our tracking list
                if modifiedCharacters[char] then
                    pcall(function()
                        if root then
                            root.Anchored = false
                        end
                    end)
                    modifiedCharacters[char] = nil
                end
            end
        end

        -- Loop players
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                processCharacter(player.Character, false)
            end
        end

        -- Loop NPCs
        local NPCSFolder = workspace:FindFirstChild("NPCS")
        if NPCSFolder then
            for _, mob in ipairs(NPCSFolder:GetChildren()) do
                if mob:IsA("Model") then
                    processCharacter(mob, true)
                end
            end
        end
        
        -- Clean up dead/removed entities from tracking list that are no longer in game
        for char, _ in pairs(modifiedCharacters) do
            if not char.Parent or not char:FindFirstChildOfClass("Humanoid") or char:FindFirstChildOfClass("Humanoid").Health <= 0 then
                modifiedCharacters[char] = nil
            end
        end
    end

    function module.cleanup()
        -- Restore all anchored targets
        for char, _ in pairs(modifiedCharacters) do
            pcall(function()
                local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
                if root then
                    root.Anchored = false
                end
            end)
        end
        table.clear(modifiedCharacters)
    end

    return module
end
