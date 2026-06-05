return function(State, Services)
    local module = {}
    local UserInputService = Services.UserInputService
    local Players = Services.Players
    local Library = getgenv().QuantixLibrary

    -- Defaults
    if State.BhopEnabled == nil then State.BhopEnabled = false end
    if State.BhopKey == nil then State.BhopKey = Enum.KeyCode.Space end
    if State.BhopKeyMode == nil then State.BhopKeyMode = "Hold" end
    if State.BhopActive == nil then State.BhopActive = false end

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

    local wasKeyBegan = false

    function module.update()
        if not State.BhopEnabled then return end

        local localPlayer = Players.LocalPlayer
        if not localPlayer or not localPlayer.Character then return end

        local isPressed = false
        if State.BhopKeyMode == "Toggle" then
            local keyDown = false
            pcall(function()
                if State.BhopKey.EnumType == Enum.KeyCode then
                    keyDown = UserInputService:IsKeyDown(State.BhopKey)
                elseif State.BhopKey == Enum.UserInputType.MouseButton1 or State.BhopKey == Enum.UserInputType.MouseButton2 then
                    keyDown = UserInputService:IsMouseButtonPressed(State.BhopKey)
                end
            end)

            if keyDown then
                if not wasKeyBegan then
                    State.BhopActive = not State.BhopActive
                    wasKeyBegan = true
                    if Library and Library.Notify then
                        Library:Notify("Bhop", "Bhop auto-jump is now " .. (State.BhopActive and "Active" or "Inactive"), 1.5)
                    end
                end
            else
                wasKeyBegan = false
            end
            isPressed = State.BhopActive
        else
            -- Hold Mode
            pcall(function()
                if State.BhopKey.EnumType == Enum.KeyCode then
                    isPressed = UserInputService:IsKeyDown(State.BhopKey)
                elseif State.BhopKey == Enum.UserInputType.MouseButton1 or State.BhopKey == Enum.UserInputType.MouseButton2 then
                    isPressed = UserInputService:IsMouseButtonPressed(State.BhopKey)
                end
            end)

            -- Keyboard check fallback
            if not isPressed then
                local keys = UserInputService:GetKeysPressed()
                for _, key in ipairs(keys) do
                    if key.KeyCode == State.BhopKey then
                        isPressed = true
                        break
                    end
                end
            end
        end

        if not isPressed then return end

        local mc = getMovementController()
        if not mc then return end

        if mc.playerGrounded then
            mc.jumping = true
        end
    end

    return module
end
