return function(State, Services, GameStateModule)
    local Players = Services.Players
    local LocalPlayer = Services.LocalPlayer
    local UserInputService = Services.UserInputService
    local module = {}

    function module.getClosestPlayer()
        local Camera = workspace.CurrentCamera
        if not Camera then return nil end
        local mousePos = UserInputService:GetMouseLocation()

        local candidates = {}

        local function addCandidate(char)
            local head = char:FindFirstChild("Head")
            if not head then return end
            local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
            if not onScreen then return end
            local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
            if distance < State.FOVRadius then
                table.insert(candidates, {
                    Character = char,
                    Part = head,
                    Distance = distance
                })
            end
        end

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local char = player.Character
                local hum = char:FindFirstChildOfClass("Humanoid")
                local isAlive = hum and hum.Health > 0
                if isAlive and not (State.TeamCheck and GameStateModule.getCachedTeammateStatus(player)) then
                    addCandidate(char)
                end
            end
        end

        local NPCSFolder = workspace:FindFirstChild("NPCS")
        if NPCSFolder then
            for _, mob in ipairs(NPCSFolder:GetChildren()) do
                if mob:IsA("Model") then
                    local hum = mob:FindFirstChildOfClass("Humanoid")
                    local isAlive = hum and hum.Health > 0
                    if isAlive and not (State.TeamCheck and GameStateModule.getCachedTeammateStatus(mob)) then
                        addCandidate(mob)
                    end
                end
            end
        end

        if #candidates == 0 then return nil end

        table.sort(candidates, function(a, b)
            return a.Distance < b.Distance
        end)

        if not State.VisibleCheck then
            return candidates[1]
        end

        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude

        local ignoreList = {Camera, LocalPlayer.Character or workspace}
        local Effects = workspace:FindFirstChild("Effects")
        if Effects then table.insert(ignoreList, Effects) end
        local Ragdolls = workspace:FindFirstChild("Ragdolls")
        if Ragdolls then table.insert(ignoreList, Ragdolls) end
        for _, child in ipairs(Camera:GetChildren()) do
            table.insert(ignoreList, child)
        end

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                if GameStateModule.getCachedTeammateStatus(player) then
                    table.insert(ignoreList, player.Character)
                end
            end
        end
        if NPCSFolder then
            for _, mob in ipairs(NPCSFolder:GetChildren()) do
                if GameStateModule.getCachedTeammateStatus(mob) then
                    table.insert(ignoreList, mob)
                end
            end
        end

        raycastParams.FilterDescendantsInstances = ignoreList

        local origin = Camera.CFrame.Position
        for _, cand in ipairs(candidates) do
            local headPos = cand.Part.Position
            local direction = headPos - origin
            local raycastResult = workspace:Raycast(origin, direction, raycastParams)

            if not raycastResult then
                return cand
            else
                local hitInstance = raycastResult.Instance
                if hitInstance:IsDescendantOf(cand.Character) then
                    return cand
                end
            end
        end

        return nil
    end

    -- Run aimbot for one frame
    function module.runAimbot()
        if not (State.Aiming and State.AimbotEnabled) then return end
        pcall(function()
            local target = module.getClosestPlayer()
            local activeCam = workspace.CurrentCamera
            if target and activeCam then
                local targetPart = target.Part
                local targetPos = targetPart.Position

                if State.PredictionEnabled then
                    local rootPart = targetPart.Parent:FindFirstChild("HumanoidRootPart") or targetPart.Parent.PrimaryPart or targetPart
                    local velocity = rootPart.AssemblyLinearVelocity or rootPart.Velocity or Vector3.new()
                    targetPos = targetPos + (velocity * 0.135)
                end

                if State.AimbotMethod == "Mouse" and mousemoverel then
                    local screenPos, onScreen = activeCam:WorldToViewportPoint(targetPos)
                    if onScreen then
                        local mousePos = UserInputService:GetMouseLocation()
                        local deltaX = (screenPos.X - mousePos.X)
                        local deltaY = (screenPos.Y - mousePos.Y)
                        if State.Smoothing > 0 then
                            mousemoverel(deltaX / (State.Smoothing + 1), deltaY / (State.Smoothing + 1))
                        else
                            mousemoverel(deltaX, deltaY)
                        end
                    end
                else
                    local currentCF = activeCam.CFrame
                    local targetCF = CFrame.new(currentCF.Position, targetPos)
                    if State.Smoothing > 0 then
                        activeCam.CFrame = currentCF:Lerp(targetCF, 1 / (State.Smoothing + 1))
                    else
                        activeCam.CFrame = targetCF
                    end
                end
            end
        end)
    end

    return module
end
