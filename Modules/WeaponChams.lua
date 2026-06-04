return function(State, Services)
    local Players = Services.Players
    local LocalPlayer = Services.LocalPlayer
    local RunService = Services.RunService
    local module = {}

    -- Defaults
    if State.WeaponChamsEnabled == nil then State.WeaponChamsEnabled = false end
    if State.HandChamsEnabled == nil then State.HandChamsEnabled = false end
    if State.WeaponChamsMode == nil then State.WeaponChamsMode = 1 end -- 1=Normal, 2=Wireframe, 3=Outline Only
    if State.WeaponChamsFillTrans == nil then State.WeaponChamsFillTrans = 0.3 end
    if State.WeaponChamsOutlineTrans == nil then State.WeaponChamsOutlineTrans = 0 end
    if State.WeaponChamsFillR == nil then State.WeaponChamsFillR = 115; State.WeaponChamsFillG = 120; State.WeaponChamsFillB = 255 end
    if State.WeaponChamsOutlineR == nil then State.WeaponChamsOutlineR = 180; State.WeaponChamsOutlineG = 180; State.WeaponChamsOutlineB = 255 end
    if State.HandChamsFillTrans == nil then State.HandChamsFillTrans = 0.5 end
    if State.HandChamsOutlineTrans == nil then State.HandChamsOutlineTrans = 0 end
    if State.HandChamsFillR == nil then State.HandChamsFillR = 200; State.HandChamsFillG = 130; State.HandChamsFillB = 255 end
    if State.HandChamsOutlineR == nil then State.HandChamsOutlineR = 220; State.HandChamsOutlineG = 180; State.HandChamsOutlineB = 255 end
    if State.WeaponChamsDepth == nil then State.WeaponChamsDepth = false end -- AlwaysOnTop toggle

    local weaponHighlight = nil
    local handHighlights = {} -- table of Highlight instances for arm parts

    local ARM_NAMES_R15 = {
        "RightHand", "RightLowerArm", "RightUpperArm",
        "LeftHand", "LeftLowerArm", "LeftUpperArm"
    }
    local ARM_NAMES_R6 = {
        "Right Arm", "Left Arm"
    }

    local function getArmParts(character)
        if not character then return {} end
        local parts = {}
        -- Try R15 first
        for _, name in ipairs(ARM_NAMES_R15) do
            local part = character:FindFirstChild(name)
            if part then table.insert(parts, part) end
        end
        -- Fallback R6
        if #parts == 0 then
            for _, name in ipairs(ARM_NAMES_R6) do
                local part = character:FindFirstChild(name)
                if part then table.insert(parts, part) end
            end
        end
        return parts
    end

    local function getEquippedWeapon(character)
        if not character then return nil end
        -- Check for Tool in character (equipped tool gets parented to character)
        for _, child in ipairs(character:GetChildren()) do
            if child:IsA("Tool") or child:IsA("Model") then
                -- Check if it has a handle or gun-like parts
                if child:FindFirstChild("Handle") or child:FindFirstChild("Barrel") or child:FindFirstChild("Body") then
                    return child
                end
            end
        end
        -- Also check ViewModels in Camera
        local camera = workspace.CurrentCamera
        if camera then
            for _, child in ipairs(camera:GetChildren()) do
                if child:IsA("Model") then
                    return child
                end
            end
        end
        return nil
    end

    local function applyModeToHighlight(highlight, mode, fillTrans, outlineTrans)
        if mode == 1 then -- Normal
            highlight.FillTransparency = fillTrans
            highlight.OutlineTransparency = outlineTrans
        elseif mode == 2 then -- Wireframe
            highlight.FillTransparency = 1
            highlight.OutlineTransparency = 0
        elseif mode == 3 then -- Outline Only (thicker feel)
            highlight.FillTransparency = 0.95
            highlight.OutlineTransparency = 0
        end
    end

    local function cleanupWeaponHighlight()
        if weaponHighlight then
            pcall(function() weaponHighlight:Destroy() end)
            weaponHighlight = nil
        end
    end

    local function cleanupHandHighlights()
        for _, hl in pairs(handHighlights) do
            pcall(function() hl:Destroy() end)
        end
        handHighlights = {}
    end

    function module.cleanup()
        cleanupWeaponHighlight()
        cleanupHandHighlights()
    end

    function module.update()
        local character = LocalPlayer.Character
        if not character then
            module.cleanup()
            return
        end

        -- === WEAPON CHAMS ===
        if State.WeaponChamsEnabled then
            local weapon = getEquippedWeapon(character)
            if weapon then
                -- Create or reuse highlight
                if not weaponHighlight or weaponHighlight.Parent ~= weapon then
                    cleanupWeaponHighlight()
                    weaponHighlight = Instance.new("Highlight")
                    weaponHighlight.Name = "QuantixWeaponChams"
                    weaponHighlight.Adornee = weapon
                    weaponHighlight.Parent = weapon
                end

                local fillColor = Color3.fromRGB(State.WeaponChamsFillR, State.WeaponChamsFillG, State.WeaponChamsFillB)
                local outlineColor = Color3.fromRGB(State.WeaponChamsOutlineR, State.WeaponChamsOutlineG, State.WeaponChamsOutlineB)
                weaponHighlight.FillColor = fillColor
                weaponHighlight.OutlineColor = outlineColor
                weaponHighlight.DepthMode = State.WeaponChamsDepth and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded

                applyModeToHighlight(weaponHighlight, State.WeaponChamsMode, State.WeaponChamsFillTrans, State.WeaponChamsOutlineTrans)
            else
                cleanupWeaponHighlight()
            end
        else
            cleanupWeaponHighlight()
        end

        -- === HAND CHAMS ===
        if State.HandChamsEnabled then
            local armParts = getArmParts(character)
            -- Also grab arm parts from ViewModel in camera
            local camera = workspace.CurrentCamera
            if camera then
                for _, child in ipairs(camera:GetChildren()) do
                    if child:IsA("Model") then
                        for _, name in ipairs(ARM_NAMES_R15) do
                            local part = child:FindFirstChild(name)
                            if part then table.insert(armParts, part) end
                        end
                        for _, name in ipairs(ARM_NAMES_R6) do
                            local part = child:FindFirstChild(name)
                            if part then table.insert(armParts, part) end
                        end
                    end
                end
            end

            local fillColor = Color3.fromRGB(State.HandChamsFillR, State.HandChamsFillG, State.HandChamsFillB)
            local outlineColor = Color3.fromRGB(State.HandChamsOutlineR, State.HandChamsOutlineG, State.HandChamsOutlineB)

            -- Track which parts we've seen this frame
            local activeParts = {}

            for _, part in ipairs(armParts) do
                activeParts[part] = true
                if not handHighlights[part] or not handHighlights[part].Parent then
                    -- Create new highlight for this part
                    local hl = Instance.new("Highlight")
                    hl.Name = "QuantixHandChams"
                    hl.Adornee = part
                    hl.Parent = part
                    handHighlights[part] = hl
                end

                local hl = handHighlights[part]
                hl.FillColor = fillColor
                hl.OutlineColor = outlineColor
                hl.DepthMode = State.WeaponChamsDepth and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
                applyModeToHighlight(hl, State.WeaponChamsMode, State.HandChamsFillTrans, State.HandChamsOutlineTrans)
            end

            -- Cleanup highlights for parts that no longer exist
            for part, hl in pairs(handHighlights) do
                if not activeParts[part] then
                    pcall(function() hl:Destroy() end)
                    handHighlights[part] = nil
                end
            end
        else
            cleanupHandHighlights()
        end
    end

    return module
end
