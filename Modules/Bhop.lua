return function(State, Services)
    local module = {}
    local UserInputService = Services.UserInputService
    local Players = Services.Players

    -- Defaults
    if State.BhopEnabled == nil then State.BhopEnabled = false end
    if State.BhopKey == nil then State.BhopKey = Enum.KeyCode.Space end

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
        if not State.BhopEnabled then return end

        local localPlayer = Players.LocalPlayer
        if not localPlayer or not localPlayer.Character then return end

        -- Make sure bhop key is actively pressed
        local isPressed = false
        pcall(function()
            if State.BhopKey.EnumType == Enum.KeyCode then
                isPressed = UserInputService:IsKeyDown(State.BhopKey)
            elseif State.BhopKey.EnumType == Enum.UserInputType then
                isPressed = UserInputService:IsNavigationKeyPressed(State.BhopKey) or UserInputService:GetMouseLocation() ~= nil -- mouse buttons/inputs
            end
        end)

        -- Fallback check if user is holding the key bind (standard Keyboard check)
        if not isPressed then
            local keys = UserInputService:GetKeysPressed()
            for _, key in ipairs(keys) do
                if key.KeyCode == State.BhopKey then
                    isPressed = true
                    break
                end
            end
        end

        -- Handle mouse buttons which are UserInputType
        if not isPressed and (State.BhopKey == Enum.UserInputType.MouseButton1 or State.BhopKey == Enum.UserInputType.MouseButton2) then
            isPressed = UserInputService:IsMouseButtonPressed(State.BhopKey)
        end

        if not isPressed then return end

        local mc = getMovementController()
        if not mc then return end

        -- If grounded, force jump state immediately in the movement controller
        if mc.playerGrounded then
            mc.jumping = true
        end
    end

    return module
end
