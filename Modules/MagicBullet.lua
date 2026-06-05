return function(State, Services)
    local module = {}
    function module.process(gunModule)
        if not State.MagicBulletEnabled then return false, nil end

        if State.GetClosestPlayer then
            -- Bypass visibility check since magic bullet shoots through walls
            local target = State.GetClosestPlayer(true)
            if target and target.Part then
                local targetPos = target.Part.Position
                if State.PredictionEnabled then
                    local rootPart = target.Part.Parent:FindFirstChild("HumanoidRootPart") or target.Part.Parent.PrimaryPart or target.Part
                    local velocity = rootPart.AssemblyLinearVelocity or rootPart.Velocity or Vector3.new()
                    targetPos = targetPos + (velocity * 0.135)
                end

                local activeCam = workspace.CurrentCamera
                if activeCam then
                    -- Teleport camera position locally to be right next to target head, looking at the head
                    -- This starts the raycast verification from the target head, bypassing all intervening walls
                    local targetCFrame = CFrame.lookAt(targetPos + Vector3.new(0, 0.1, 0.5), targetPos)
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
