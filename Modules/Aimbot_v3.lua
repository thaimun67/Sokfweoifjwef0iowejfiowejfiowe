return function(State, Services, GameStateModule)
    local Players = Services.Players
    local LocalPlayer = Services.LocalPlayer
    local UserInputService = Services.UserInputService
    local module = {}

    function module.getClosestPlayer(isSilentAim)
        local Camera = workspace.CurrentCamera
        if not Camera then return nil end
        local mousePos = UserInputService:GetMouseLocation()

        local candidates = {}

        local fovRadius = isSilentAim and State.SilentAimFOVRadius or State.FOVRadius
        local targetPartName = isSilentAim and State.SilentAimTargetPart or "Head"

        local function addCandidate(char)
            local targetPart = nil
            if targetPartName == "Head" then
                targetPart = char:FindFirstChild("Head")
            elseif targetPartName == "Torso" then
                targetPart = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
            elseif targetPartName == "Random" then
                local parts = {}
                local head = char:FindFirstChild("Head")
                if head then table.insert(parts, head) end
                local torso = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
                if torso then table.insert(parts, torso) end
                targetPart = #parts > 0 and parts[math.random(1, #parts)] or nil
            else
                targetPart = char:FindFirstChild("Head")
            end

            if not targetPart then return end
            local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
            if not onScreen then return end
            local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
            if distance < fovRadius then
                table.insert(candidates, {
                    Character = char,
                    Part = targetPart,
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

        local charIgnore = LocalPlayer.Character
        local ignoreList = {Camera}
        if charIgnore then table.insert(ignoreList, charIgnore) end

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

        local origin = Camera.CFrame.Position
        for _, cand in ipairs(candidates) do
            local headPos = cand.Part.Position
            local direction = headPos - origin
            
            local tempIgnore = {unpack(ignoreList)}
            local visible = false
            
            for i = 1, 10 do
                raycastParams.FilterDescendantsInstances = tempIgnore
                local raycastResult = workspace:Raycast(origin, direction, raycastParams)
                if not raycastResult then
                    visible = true
                    break
                else
                    local hitInstance = raycastResult.Instance
                    if hitInstance:IsDescendantOf(cand.Character) then
                        visible = true
                        break
                    elseif hitInstance.Transparency == 1 or not hitInstance.CanCollide then
                        table.insert(tempIgnore, hitInstance)
                    else
                        break
                    end
                end
            end

            if visible then
                return cand
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

    State.GetClosestPlayer = module.getClosestPlayer

    local silentAimHooked = false
    function module.startSilentAimHook()
        if silentAimHooked then return end
        silentAimHooked = true

        task.spawn(function()
            local ok, err = pcall(function()
                local HandlerClass = nil
                local targetFunc = nil
                local originalFireHitscanShot = nil

                local function getFunctionName(f)
                    local okName, name = pcall(function()
                        return debug.info(f, "n")
                    end)
                    if okName and name and name ~= "" then return name end
                    
                    local okInfo, info = pcall(function()
                        return debug.getinfo(f)
                    end)
                    if okInfo and info and info.name and info.name ~= "" then
                        return info.name
                    end
                    return nil
                end

                -- Scan GC for function first (most robust on modern executors)
                if getgc then
                    for _, v in ipairs(getgc(true)) do
                        if type(v) == "function" then
                            if getFunctionName(v) == "fireHitscanShot" then
                                targetFunc = v
                                break
                            end
                        end
                    end
                end

                -- Scan GC for table as fallback
                if getgc then
                    for _, v in ipairs(getgc(true)) do
                        if type(v) == "table" then
                            local ok, match = pcall(function()
                                return rawget(v, "fireHitscanShot") and rawget(v, "equip") and rawget(v, "new")
                            end)
                            if ok and match then
                                HandlerClass = v
                                break
                            end
                        end
                    end
                end

                if not targetFunc and not HandlerClass then
                    warn("[Quantix] Silent Aim: target function and Handler class not found in memory")
                    return
                end

                local function hookedFireHitscanShot(self, gunModule)
                    local shouldRedirect = false
                    if State.SilentAimEnabled then
                        local chance = State.SilentAimHitChance or 100
                        if chance >= 100 or math.random(1, 100) <= chance then
                            shouldRedirect = true
                        end
                    end

                    -- Print debug info when shooting
                    print("[Quantix] fireHitscanShot called | SilentAimEnabled:", State.SilentAimEnabled, "| shouldRedirect:", shouldRedirect)

                    if shouldRedirect then
                        local target = module.getClosestPlayer(true) -- Pass true for Silent Aim
                        if target and target.Part then
                            print("[Quantix] Silent Aim target found:", target.Character.Name, "| Part:", target.Part.Name)
                            local targetPos = target.Part.Position
                            if State.PredictionEnabled then
                                local rootPart = target.Part.Parent:FindFirstChild("HumanoidRootPart") or target.Part.Parent.PrimaryPart or target.Part
                                -- Ensure compatibility with all executors
                                local velocity = rootPart.AssemblyLinearVelocity or rootPart.Velocity or Vector3.new()
                                targetPos = targetPos + (velocity * 0.135)
                            end

                            local activeCam = workspace.CurrentCamera
                            if activeCam then
                                local oldCF = activeCam.CFrame
                                activeCam.CFrame = CFrame.lookAt(oldCF.Position, targetPos)
                                
                                local result = originalFireHitscanShot(self, gunModule)
                                
                                activeCam.CFrame = oldCF
                                return result
                            end
                        else
                            print("[Quantix] Silent Aim target is nil (none in FOV or visible)")
                        end
                    end
                    return originalFireHitscanShot(self, gunModule)
                end

                if targetFunc and hookfunction then
                    print("[Quantix] Silent Aim: Found fireHitscanShot function, detouring via hookfunction")
                    local success, ret = pcall(function()
                        return hookfunction(targetFunc, hookedFireHitscanShot)
                    end)
                    if success and ret then
                        originalFireHitscanShot = ret
                        print("[Quantix] Silent Aim: Detoured fireHitscanShot successfully")
                    else
                        warn("[Quantix] Silent Aim: hookfunction detour failed:", tostring(ret))
                    end
                end

                -- Fallback to table hook if hookfunction failed or was not available
                if not originalFireHitscanShot and HandlerClass then
                    print("[Quantix] Silent Aim: Hooking via class table method replacement")
                    originalFireHitscanShot = HandlerClass.__originalFireHitscanShot or HandlerClass.fireHitscanShot
                    HandlerClass.__originalFireHitscanShot = originalFireHitscanShot
                    
                    if originalFireHitscanShot then
                        HandlerClass.fireHitscanShot = hookedFireHitscanShot
                        print("[Quantix] Silent Aim: Hooked fireHitscanShot table method successfully")
                    else
                        warn("[Quantix] Silent Aim: fireHitscanShot function is nil in class table")
                    end
                end

                if not originalFireHitscanShot then
                    warn("[Quantix] Silent Aim Hooking failed completely")
                end
            end)
            if not ok then
                warn("[Quantix] Silent Aim Hook execution failed: " .. tostring(err))
            end
        end)
    end

    return module
end
