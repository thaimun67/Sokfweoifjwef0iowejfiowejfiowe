return function(State, Services, GameStateModule)
    local module = {}
    local Players = Services.Players
    local LocalPlayer = Services.LocalPlayer

    -- Track original sizes of parts so we can restore them
    local originalSizes = {}

    function module.update()
        if not State.HitboxExpanderEnabled then
            -- Restore original sizes
            for part, orig in pairs(originalSizes) do
                pcall(function()
                    if part and part.Parent then
                        part.Size = orig.Size
                        part.CanCollide = orig.CanCollide
                        part.Transparency = orig.Transparency
                    end
                end)
            end
            table.clear(originalSizes)
            return
        end

        local sizeValue = State.HitboxSize or 10
        local transparencyValue = State.HitboxTransparency or 0.5
        local targetPartName = State.HitboxTargetPart or "Head"

        local function processCharacter(char, isNPC)
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health <= 0 then return end

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
                local part = char:FindFirstChild(targetPartName)
                if part and part:IsA("BasePart") then
                    if not originalSizes[part] then
                        originalSizes[part] = {
                            Size = part.Size,
                            CanCollide = part.CanCollide,
                            Transparency = part.Transparency
                        }
                    end
                    pcall(function()
                        part.Size = Vector3.new(sizeValue, sizeValue, sizeValue)
                        part.CanCollide = false
                        part.Transparency = transparencyValue
                    end)
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
    end

    function module.cleanup()
        -- Restore all modified hitboxes
        for part, orig in pairs(originalSizes) do
            pcall(function()
                if part and part.Parent then
                    part.Size = orig.Size
                    part.CanCollide = orig.CanCollide
                    part.Transparency = orig.Transparency
                end
            end)
        end
        table.clear(originalSizes)
    end

    return module
end
