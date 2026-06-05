return function(State, Services)
    local module = {}
    function module.process(gunModule)
        if not State.MagicBulletEnabled then return false, nil end

        if State.GetClosestPlayer then
            -- Temporarily bypass visibility check so we can target players behind walls
            local oldVisibleCheck = State.VisibleCheck
            State.VisibleCheck = false
            local target = State.GetClosestPlayer(true) -- Pass true to use Silent Aim FOV
            State.VisibleCheck = oldVisibleCheck

            if target and target.Part then
                local targetPos = target.Part.Position
                if State.PredictionEnabled then
                    local rootPart = target.Part.Parent:FindFirstChild("HumanoidRootPart") or target.Part.Parent.PrimaryPart or target.Part
                    local velocity = rootPart.AssemblyLinearVelocity or rootPart.Velocity or Vector3.new()
                    targetPos = targetPos + (velocity * 0.135)
                end

                local activeCam = workspace.CurrentCamera
                if activeCam then
                    -- Position origin 1.5 studs behind the target relative to the camera view
                    -- This ensures the ray starts outside the target's hitbox but behind any walls in front of them
                    local dir = (targetPos - activeCam.CFrame.Position).Unit
                    local origin = targetPos + (dir * 1.5)
                    local targetCFrame = CFrame.lookAt(origin, targetPos)
                    
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
