return function(State, Services)
    local module = {}
    local Lighting = game:GetService("Lighting")

    -- Defaults
    if State.Hitsound == nil then State.Hitsound = "Default" end
    if State.HeadshotSound == nil then State.HeadshotSound = "None" end

    local originalSoundId = nil
    pcall(function()
        if Lighting:FindFirstChild("Sounds") and Lighting.Sounds:FindFirstChild("Hitmarker") then
            originalSoundId = Lighting.Sounds.Hitmarker.SoundId
        end
    end)

    local soundIds = {
        Default = originalSoundId,
        Click = "rbxassetid://7148560127",
        Skeet = "rbxassetid://5043530756",
        CS_Headshot = "rbxassetid://4456640693"
    }

    local function getCrosshairActions()
        if not getgc then return nil end
        for _, obj in ipairs(getgc(true)) do
            if type(obj) == "table" and rawget(obj, "Hitmarker") then
                return obj
            end
        end
        return nil
    end

    local hooked = false
    function module.start()
        if hooked then return end
        
        task.spawn(function()
            -- Wait for game load and sounds to exist
            local attempts = 0
            while attempts < 30 do
                pcall(function()
                    if Lighting:FindFirstChild("Sounds") and Lighting.Sounds:FindFirstChild("Hitmarker") then
                        originalSoundId = Lighting.Sounds.Hitmarker.SoundId
                        soundIds.Default = originalSoundId
                    end
                end)
                if originalSoundId then break end
                task.wait(1)
                attempts = attempts + 1
            end

            local crosshairActions = getCrosshairActions()
            local attemptsGC = 0
            while not crosshairActions and attemptsGC < 30 do
                task.wait(1)
                crosshairActions = getCrosshairActions()
                attemptsGC = attemptsGC + 1
            end

            if crosshairActions and type(crosshairActions.Hitmarker) == "function" then
                hooked = true
                local originalHitmarker = crosshairActions.Hitmarker
                crosshairActions.Hitmarker = function(self, isHeadshot, ...)
                    pcall(function()
                        if Lighting:FindFirstChild("Sounds") and Lighting.Sounds:FindFirstChild("Hitmarker") then
                            local soundObject = Lighting.Sounds.Hitmarker
                            if isHeadshot and State.HeadshotSound == "CS Headshot" then
                                soundObject.SoundId = soundIds.CS_Headshot
                            else
                                local chosenId = soundIds[State.Hitsound] or originalSoundId
                                soundObject.SoundId = chosenId
                            end
                        end
                    end)
                    return originalHitmarker(self, isHeadshot, ...)
                end
                print("[Quantix Hitsounds] Successfully hooked crosshair actions hitmarker sound!")
            else
                warn("[Quantix Hitsounds] Failed to find CrosshairActions in GC.")
            end
        end)
    end

    function module.cleanup()
        pcall(function()
            if Lighting:FindFirstChild("Sounds") and Lighting.Sounds:FindFirstChild("Hitmarker") and originalSoundId then
                Lighting.Sounds.Hitmarker.SoundId = originalSoundId
            end
        end)
    end

    return module
end
