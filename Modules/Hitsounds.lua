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

        -- Hook Sound.Play method directly to redirect the sound ID before playback
        local success, err = pcall(function()
            local dummy = Instance.new("Sound")
            local oldPlay
            oldPlay = hookfunction(dummy.Play, function(self, ...)
                pcall(function()
                    local id = self.SoundId
                    if id == "rbxassetid://7147954330" or id == "rbxassetid://1347140027" or id == originalSoundId then
                        if State.Hitsound == "Click" then
                            self.SoundId = soundIds.Click
                        elseif State.Hitsound == "Skeet" then
                            self.SoundId = soundIds.Skeet
                        elseif State.Hitsound == "CS Headshot" then
                            self.SoundId = soundIds.CS_Headshot
                        elseif State.Hitsound == "Default" and originalSoundId then
                            if id == "rbxassetid://1347140027" then
                                self.SoundId = "rbxassetid://1347140027"
                            else
                                self.SoundId = originalSoundId
                            end
                        end
                    end
                end)
                return oldPlay(self, ...)
            end)
            getgenv()._oldSoundPlay = oldPlay
            print("[Quantix Hitsounds] Sound.Play successfully hooked!")
        end)

        if not success then
            warn("[Quantix Hitsounds] hookfunction Sound.Play failed: " .. tostring(err))
        end
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
