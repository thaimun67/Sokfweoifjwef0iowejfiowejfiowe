return function(State, Services)
    local module = {}
    local RunService = Services.RunService

    -- Defaults
    if State.SpeedBoostEnabled == nil then State.SpeedBoostEnabled = false end
    if State.SpeedBoostValue == nil then State.SpeedBoostValue = 35 end

    local lastMC = nil
    local originalUpdate = nil

    local function getMovementController()
        -- Scan the garbage collector for the MovementController instance
        if not getgc then return nil end
        for _, obj in ipairs(getgc(true)) do
            if type(obj) == "table" and rawget(obj, "collider") and rawget(obj, "airAccelerate") then
                return obj
            end
        end
        return nil
    end

    function module.update()
        local mc = getMovementController()
        if not mc then return end

        if mc ~= lastMC then
            lastMC = mc
            originalUpdate = mc.update
            
            mc.update = function(self, dt)
                if originalUpdate then
                    local ok, err = pcall(originalUpdate, self, dt)
                    if not ok then
                        warn("[SpeedBoost] Error in original update: " .. tostring(err))
                    end
                end

                if State.SpeedBoostEnabled and self.collider then
                    local vel = self.collider.Velocity
                    local horiz = Vector3.new(vel.X, 0, vel.Z)
                    local mag = horiz.Magnitude
                    if mag > 3 then -- Only scale active movement velocity
                        local targetSpeed = State.SpeedBoostValue or 35
                        local newHoriz = horiz.Unit * targetSpeed
                        self.collider.Velocity = Vector3.new(newHoriz.X, vel.Y, newHoriz.Z)
                    end
                end
            end
        end

        if State.SpeedBoostEnabled then
            mc.sprintMaxVelocity = State.SpeedBoostValue or 35
            mc.groundMaxVelocity = State.SpeedBoostValue or 35
        else
            mc.sprintMaxVelocity = 30 -- Default game sprint speed
            mc.groundMaxVelocity = 20 -- Default game ground speed
        end
    end

    function module.cleanup()
        if lastMC and originalUpdate then
            lastMC.update = originalUpdate
        end
        local mc = getMovementController()
        if mc then
            mc.sprintMaxVelocity = 30
            mc.groundMaxVelocity = 20
        end
        lastMC = nil
        originalUpdate = nil
    end

    return module
end
