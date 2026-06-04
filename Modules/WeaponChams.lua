return function(State, Services)
    local Players = Services.Players
    local LocalPlayer = Services.LocalPlayer
    local module = {}

    -- Defaults
    if State.WeaponChamsEnabled == nil then State.WeaponChamsEnabled = false end
    if State.HandChamsEnabled == nil then State.HandChamsEnabled = false end
    if State.WeaponChamsMode == nil then State.WeaponChamsMode = 1 end
    if State.WeaponChamsFillTrans == nil then State.WeaponChamsFillTrans = 0.3 end
    if State.WeaponChamsOutlineTrans == nil then State.WeaponChamsOutlineTrans = 0 end
    if State.WeaponChamsFillR == nil then State.WeaponChamsFillR = 115; State.WeaponChamsFillG = 120; State.WeaponChamsFillB = 255 end
    if State.WeaponChamsOutlineR == nil then State.WeaponChamsOutlineR = 180; State.WeaponChamsOutlineG = 180; State.WeaponChamsOutlineB = 255 end
    if State.HandChamsFillTrans == nil then State.HandChamsFillTrans = 0.5 end
    if State.HandChamsOutlineTrans == nil then State.HandChamsOutlineTrans = 0 end
    if State.HandChamsFillR == nil then State.HandChamsFillR = 200; State.HandChamsFillG = 130; State.HandChamsFillB = 255 end
    if State.HandChamsOutlineR == nil then State.HandChamsOutlineR = 220; State.HandChamsOutlineG = 180; State.HandChamsOutlineB = 255 end
    if State.WeaponChamsDepth == nil then State.WeaponChamsDepth = false end

    local activeHighlights = {}

    local function isArmName(name)
        name = string.lower(name)
        return string.find(name, "arm") or string.find(name, "hand") or string.find(name, "sleeve") or string.find(name, "glove") or string.find(name, "wrist")
    end

    local function getParts()
        local character = LocalPlayer.Character
        local armParts = {}
        local weaponParts = {}

        -- 1. Scan Camera for ViewModels (standard FPS approach)
        local camera = workspace.CurrentCamera
        if camera then
            for _, child in ipairs(camera:GetChildren()) do
                -- Often viewmodels are Models or Folders in the camera
                if child:IsA("Model") or child:IsA("Folder") or string.find(string.lower(child.Name), "viewmodel") or string.find(string.lower(child.Name), "vm") then
                    for _, desc in ipairs(child:GetDescendants()) do
                        if desc:IsA("BasePart") then
                            if isArmName(desc.Name) then
                                table.insert(armParts, desc)
                            else
                                -- Everything else in the viewmodel is likely the weapon
                                table.insert(weaponParts, desc)
                            end
                        end
                    end
                end
            end
        end

        -- 2. Scan Character for traditional tools and body parts
        if character then
            for _, child in ipairs(character:GetChildren()) do
                if child:IsA("BasePart") and isArmName(child.Name) then
                    table.insert(armParts, child)
                elseif child:IsA("Tool") then
                    for _, desc in ipairs(child:GetDescendants()) do
                        if desc:IsA("BasePart") then
                            table.insert(weaponParts, desc)
                        end
                    end
                elseif child:IsA("Model") and not isArmName(child.Name) then
                    -- Sometimes games put the gun model directly in the character
                    if string.find(string.lower(child.Name), "gun") or string.find(string.lower(child.Name), "weapon") or child:FindFirstChild("Handle") then
                        for _, desc in ipairs(child:GetDescendants()) do
                            if desc:IsA("BasePart") then
                                table.insert(weaponParts, desc)
                            end
                        end
                    end
                end
            end
        end

        return armParts, weaponParts
    end

    local function applyModeToHighlight(highlight, mode, fillTrans, outlineTrans)
        if mode == 1 then -- Normal
            highlight.FillTransparency = fillTrans
            highlight.OutlineTransparency = outlineTrans
        elseif mode == 2 then -- Wireframe
            highlight.FillTransparency = 1
            highlight.OutlineTransparency = 0
        elseif mode == 3 then -- Outline Only
            highlight.FillTransparency = 0.95
            highlight.OutlineTransparency = 0
        end
    end

    function module.cleanup()
        for _, hl in pairs(activeHighlights) do
            pcall(function() hl:Destroy() end)
        end
        activeHighlights = {}
    end

    function module.update()
        local character = LocalPlayer.Character
        if not character and not workspace.CurrentCamera then
            module.cleanup()
            return
        end

        local armParts, weaponParts = getParts()
        local partsSeenThisFrame = {}

        -- Process Weapon Parts
        if State.WeaponChamsEnabled then
            local fillColor = Color3.fromRGB(State.WeaponChamsFillR, State.WeaponChamsFillG, State.WeaponChamsFillB)
            local outlineColor = Color3.fromRGB(State.WeaponChamsOutlineR, State.WeaponChamsOutlineG, State.WeaponChamsOutlineB)
            
            for _, part in ipairs(weaponParts) do
                partsSeenThisFrame[part] = true
                
                if not activeHighlights[part] or not activeHighlights[part].Parent then
                    local hl = Instance.new("Highlight")
                    hl.Name = "QuantixWeaponChams"
                    hl.Adornee = part
                    hl.Parent = part
                    activeHighlights[part] = hl
                end

                local hl = activeHighlights[part]
                hl.FillColor = fillColor
                hl.OutlineColor = outlineColor
                hl.DepthMode = State.WeaponChamsDepth and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
                applyModeToHighlight(hl, State.WeaponChamsMode, State.WeaponChamsFillTrans, State.WeaponChamsOutlineTrans)
            end
        end

        -- Process Arm Parts
        if State.HandChamsEnabled then
            local fillColor = Color3.fromRGB(State.HandChamsFillR, State.HandChamsFillG, State.HandChamsFillB)
            local outlineColor = Color3.fromRGB(State.HandChamsOutlineR, State.HandChamsOutlineG, State.HandChamsOutlineB)
            
            for _, part in ipairs(armParts) do
                partsSeenThisFrame[part] = true
                
                if not activeHighlights[part] or not activeHighlights[part].Parent then
                    local hl = Instance.new("Highlight")
                    hl.Name = "QuantixHandChams"
                    hl.Adornee = part
                    hl.Parent = part
                    activeHighlights[part] = hl
                end

                local hl = activeHighlights[part]
                hl.FillColor = fillColor
                hl.OutlineColor = outlineColor
                hl.DepthMode = State.WeaponChamsDepth and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
                applyModeToHighlight(hl, State.WeaponChamsMode, State.HandChamsFillTrans, State.HandChamsOutlineTrans)
            end
        end

        -- Cleanup parts that no longer exist or are disabled
        for part, hl in pairs(activeHighlights) do
            if not partsSeenThisFrame[part] then
                pcall(function() hl:Destroy() end)
                activeHighlights[part] = nil
            end
        end
    end

    return module
end
