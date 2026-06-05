return function(State, Services)
    local module = {}
    local Lighting = game:GetService("Lighting")

    -- Defaults
    if State.Hitsound == nil then State.Hitsound = "Default" end

    local originalSoundId = nil
    pcall(function()
        if Lighting:FindFirstChild("Sounds") and Lighting.Sounds:FindFirstChild("Hitmarker") then
            originalSoundId = Lighting.Sounds.Hitmarker.SoundId
        end
    end)

    local soundIds = {
        Default = originalSoundId or "rbxassetid://7147954330",
        Click = "rbxassetid://7148560127",
        Skeet = "rbxassetid://5043530756",
        CS_Headshot = "rbxassetid://4456640693"
    }

    local hooked = false
    function module.start()
        if hooked then return end
        hooked = true

        task.spawn(function()
            -- Attempt to resolve default hitsound dynamically from Lighting
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
        end)

        -- Intercept SoundId changes globally to catch ReactUI hitsound plays
        pcall(function()
            if hookmetamethod then
                local oldNewIndex
                oldNewIndex = hookmetamethod(game, "__newindex", function(self, key, value)
                    if key == "SoundId" and self:IsA("Sound") then
                        -- Check if assigning a default game hit sound
                        if value == "rbxassetid://7147954330" or value == "rbxassetid://1347140027" or value == originalSoundId then
                            if State.Hitsound == "Click" then
                                value = soundIds.Click
                            elseif State.Hitsound == "Skeet" then
                                value = soundIds.Skeet
                            elseif State.Hitsound == "CS Headshot" then
                                value = soundIds.CS_Headshot
                            end
                        end
                    end
                    return oldNewIndex(self, key, value)
                end)
                getgenv()._oldHitmarkerNewIndex = oldNewIndex
                print("[Quantix Hitsounds] Global SoundId hook installed successfully!")
            end
        end)
    end

    function module.cleanup()
        State.Hitsound = "Default"
        pcall(function()
            if Lighting:FindFirstChild("Sounds") and Lighting.Sounds:FindFirstChild("Hitmarker") and originalSoundId then
                Lighting.Sounds.Hitmarker.SoundId = originalSoundId
            end
        end)
    end

    return module
end
