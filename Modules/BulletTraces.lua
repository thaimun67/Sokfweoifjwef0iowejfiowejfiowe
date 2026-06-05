return function(State, Services)
    local module = {}
    local LocalPlayer = Services.LocalPlayer
    local TweenService = Services.TweenService

    function module.createTrace(origin, hitPos)
        task.spawn(function()
            local attach0 = Instance.new("Attachment", workspace.Terrain)
            attach0.Position = origin
            local attach1 = Instance.new("Attachment", workspace.Terrain)
            attach1.Position = hitPos
            
            local beam = Instance.new("Beam")
            beam.Attachment0 = attach0
            beam.Attachment1 = attach1
            beam.FaceCamera = true
            beam.LightEmission = 1
            beam.LightInfluence = 0
            beam.Width0 = State.BulletTraceThickness or 0.02
            beam.Width1 = State.BulletTraceThickness or 0.02
            beam.Color = ColorSequence.new(Color3.fromRGB(State.BulletTraceColorR or 115, State.BulletTraceColorG or 120, State.BulletTraceColorB or 255))
            beam.Parent = workspace.Terrain
            
            local duration = State.BulletTraceDuration or 1.0
            local t1 = TweenService:Create(beam, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Width0 = 0, Width1 = 0})
            t1:Play()
            
            task.delay(duration, function()
                attach0:Destroy()
                attach1:Destroy()
                beam:Destroy()
            end)
        end)
    end

    function module.startBulletTracesHook()
        task.spawn(function()
            local Remotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes", 10)
            if not Remotes then return end
            
            if hookmetamethod then
                local oldNamecall
                oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
                    local method = getnamecallmethod()
                    if not checkcaller() and method == "FireServer" then
                        if self.Name == "ShootEvent" then
                            local args = {...}
                            if State.BulletTracesEnabled and args[1] then
                                local data = args[1]
                                if type(data) == "table" then
                                    local origin = data.o or data.origin
                                    local hitPos = data.e or data.endpoint or data.hit
                                    
                                    -- Check if nested inside table keys (in case of shotgun/burst formats)
                                    if not origin or not hitPos then
                                        for _, v in pairs(data) do
                                            if type(v) == "table" then
                                                origin = origin or v.o or v.origin
                                                hitPos = hitPos or v.e or v.endpoint or v.hit
                                            end
                                        end
                                    end
                                    
                                    if origin and hitPos then
                                        module.createTrace(origin, hitPos)
                                    end
                                end
                            end
                        elseif self.Name == "BlastEvent" then
                            local args = {...}
                            if State.BulletTracesEnabled and args[1] then
                                local hitPos = args[1]
                                local character = LocalPlayer.Character
                                local origin = character and character:FindFirstChild("Head") and character.Head.Position
                                if origin and hitPos and typeof(hitPos) == "Vector3" then
                                    module.createTrace(origin, hitPos)
                                end
                            end
                        end
                    end
                    return oldNamecall(self, ...)
                end)
            end
        end)
    end

    return module
end
