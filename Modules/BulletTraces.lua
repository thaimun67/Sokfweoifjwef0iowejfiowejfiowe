return function(State, Services)
    local module = {}
    function module.startBulletTracesHook()
        task.spawn(function()
            local Events = game:GetService("ReplicatedStorage"):WaitForChild("Events", 10)
            if not Events then return end
            
            local ShootEvent = Events:WaitForChild("ShootEvent", 10)
            if ShootEvent and hookmetamethod then
                local oldNamecall
                oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
                    local method = getnamecallmethod()
                    if not checkcaller() and self == ShootEvent and method == "FireServer" then
                        local args = {...}
                        if State.BulletTracesEnabled and args[1] and type(args[1]) == "table" then
                            local shotData = args[1]
                            local origin = shotData.o
                            local hitPos = shotData.e
                            if origin and hitPos then
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
                                    local t1 = Services.TweenService:Create(beam, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Width0 = 0, Width1 = 0})
                                    t1:Play()
                                    
                                    task.delay(duration, function()
                                        attach0:Destroy()
                                        attach1:Destroy()
                                        beam:Destroy()
                                    end)
                                end)
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
