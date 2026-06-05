return function(State, Services)
    local module = {}
    local Lighting = game:GetService("Lighting")
    local Players = game:GetService("Players")

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
        Click = "rbxassetid://705502934",
        Skeet = "rbxassetid://12856925315",
        CS_Headshot = "rbxassetid://18315629371"
    }

    local childConn = nil
    local hooked = false

    function module.start()
        if hooked then return end
        hooked = true

        -- Resolve default hitsound dynamically from Lighting
        task.spawn(function()
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

        -- Monitor PlayerGui for newly spawned Sound instances (ReactUI hitmarkers)
        task.spawn(function()
            local LocalPlayer = Players.LocalPlayer
            while not LocalPlayer do
                task.wait(0.5)
                LocalPlayer = Players.LocalPlayer
            end
            
            local playerGui = LocalPlayer:WaitForChild("PlayerGui", 10)
            if playerGui then
                local function checkSound(sound)
                    if sound:IsA("Sound") then
                        local function update()
                            local id = sound.SoundId
                            if id == "rbxassetid://7147954330" or id == "rbxassetid://1347140027" or id == originalSoundId then
                                if State.Hitsound == "Click" then
                                    sound.SoundId = soundIds.Click
                                elseif State.Hitsound == "Skeet" then
                                    sound.SoundId = soundIds.Skeet
                                elseif State.Hitsound == "CS Headshot" then
                                    sound.SoundId = soundIds.CS_Headshot
                                elseif State.Hitsound == "Default" and originalSoundId then
                                    if id == "rbxassetid://1347140027" then
                                        sound.SoundId = "rbxassetid://1347140027"
                                    else
                                        sound.SoundId = originalSoundId
                                    end
                                end
                            end
                        end
                        update()
                        sound:GetPropertyChangedSignal("SoundId"):Connect(update)
                    end
                end

                -- Scan existing children
                for _, child in ipairs(playerGui:GetChildren()) do
                    checkSound(child)
                end
                
                childConn = playerGui.ChildAdded:Connect(checkSound)
                table.insert(State.Connections, childConn)
            end
        end)

        -- Hook SoundId changes globally for executors supporting hookmetamethod
        pcall(function()
            if hookmetamethod then
                local oldNewIndex
                oldNewIndex = hookmetamethod(game, "__newindex", function(self, key, value)
                    if key == "SoundId" and self:IsA("Sound") then
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
            end
        end)
    end

    function module.cleanup()
        State.Hitsound = "Default"
        if childConn then
            pcall(function() childConn:Disconnect() end)
            childConn = nil
        end
        pcall(function()
            if Lighting:FindFirstChild("Sounds") and Lighting.Sounds:FindFirstChild("Hitmarker") and originalSoundId then
                Lighting.Sounds.Hitmarker.SoundId = originalSoundId
            end
        end)
    end

    return module
end
