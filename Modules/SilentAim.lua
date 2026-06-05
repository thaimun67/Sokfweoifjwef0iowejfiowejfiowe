return function(State, Services)
    local module = {}
    function module.process(gunModule)
        local shouldRedirect = false
        if State.SilentAimEnabled then
            local chance = State.SilentAimHitChance or 100
            if chance >= 100 or math.random(1, 100) <= chance then
                shouldRedirect = true
            end
        end

        if shouldRedirect and State.GetClosestPlayer then
            local target = State.GetClosestPlayer(true) -- Pass true for Silent Aim
            if target and target.Part then
                local targetPos = target.Part.Position
                if State.PredictionEnabled then
                    local rootPart = target.Part.Parent:FindFirstChild("HumanoidRootPart") or target.Part.Parent.PrimaryPart or target.Part
                    local velocity = rootPart.AssemblyLinearVelocity or rootPart.Velocity or Vector3.new()
                    targetPos = targetPos + (velocity * 0.135)
                end

                local activeCam = workspace.CurrentCamera
                if activeCam then
                    local targetCFrame = CFrame.lookAt(activeCam.CFrame.Position, targetPos)
                    local proxyCam = setmetatable({}, {
                        __index = function(t, k)
                            if k == "CFrame" then return targetCFrame end
                            local val = activeCam[k]
                            if type(val) == "function" then
                                return function(_, ...) return val(activeCam, ...) end
                            end
                            return val
                        end
                    })
                    return true, proxyCam
                end
            end
        end
        return false, nil
    end
    return module
end
