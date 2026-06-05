return function(State, Services)
    local module = {}
    local RunService = Services.RunService

    -- Defaults
    if State.SpeedBoostEnabled == nil then State.SpeedBoostEnabled = false end
    if State.SpeedBoostValue == nil then State.SpeedBoostValue = 35 end

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

        if State.SpeedBoostEnabled then
            mc.sprintMaxVelocity = State.SpeedBoostValue or 35
            mc.groundMaxVelocity = State.SpeedBoostValue or 35
        else
            mc.sprintMaxVelocity = 30 -- Default game sprint speed
            mc.groundMaxVelocity = 20 -- Default game ground speed
        end
    end

    function module.cleanup()
        local mc = getMovementController()
        if mc then
            mc.sprintMaxVelocity = 30
            mc.groundMaxVelocity = 20
        end
    end

    return module
end
