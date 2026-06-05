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

    local activeElements = {}

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
                if child:IsA("Model") or child:IsA("Folder") or string.find(string.lower(child.Name), "viewmodel") or string.find(string.lower(child.Name), "vm") then
                    for _, desc in ipairs(child:GetDescendants()) do
                        if desc:IsA("BasePart") then
                            if isArmName(desc.Name) then
                                table.insert(armParts, desc)
                            else
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

    function module.cleanup()
        for part, obj in pairs(activeElements) do
            pcall(function() obj:Destroy() end)
        end
        activeElements = {}
    end

    function module.update()
        local character = LocalPlayer.Character
        if not character and not workspace.CurrentCamera then
            module.cleanup()
            return
        end

        local armParts, weaponParts = getParts()
        local partsSeenThisFrame = {}

        local function stylePart(part, isArm)
            partsSeenThisFrame[part] = true
            
            local enabled = isArm and State.HandChamsEnabled or State.WeaponChamsEnabled
            if not enabled then
                if activeElements[part] then
                    pcall(function() activeElements[part]:Destroy() end)
                    activeElements[part] = nil
                end
                return
            end

            local fillColor = isArm and Color3.fromRGB(State.HandChamsFillR, State.HandChamsFillG, State.HandChamsFillB) or Color3.fromRGB(State.WeaponChamsFillR, State.WeaponChamsFillG, State.WeaponChamsFillB)
            local outlineColor = isArm and Color3.fromRGB(State.HandChamsOutlineR, State.HandChamsOutlineG, State.HandChamsOutlineB) or Color3.fromRGB(State.WeaponChamsOutlineR, State.WeaponChamsOutlineG, State.WeaponChamsOutlineB)
            local fillTrans = isArm and State.HandChamsFillTrans or State.WeaponChamsFillTrans
            local outlineTrans = isArm and State.HandChamsOutlineTrans or State.WeaponChamsOutlineTrans
            local depth = State.WeaponChamsDepth
            local mode = State.WeaponChamsMode

            local existing = activeElements[part]
            
            if mode == 2 then -- Wireframe
                if existing and existing:IsA("Highlight") then
                    pcall(function() existing:Destroy() end)
                    existing = nil
                end
                
                local wf = existing
                if not wf or not wf.Parent then
                    wf = Instance.new("WireframeHandleAdornment")
                    wf.Name = "QuantixWireframe"
                    wf.Parent = part
                    activeElements[part] = wf
                end
                wf.Adornee = part
                wf.Color3 = fillColor
                wf.AlwaysOnTop = depth
                wf.Transparency = fillTrans
            else -- Normal or Outline
                if existing and existing:IsA("WireframeHandleAdornment") then
                    pcall(function() existing:Destroy() end)
                    existing = nil
                end
                
                local hl = existing
                if not hl or not hl.Parent then
                    hl = Instance.new("Highlight")
                    hl.Name = "QuantixCham"
                    hl.Parent = part
                    activeElements[part] = hl
                end
                hl.Adornee = part
                hl.FillColor = fillColor
                hl.OutlineColor = outlineColor
                hl.DepthMode = depth and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
                
                if mode == 1 then -- Normal
                    hl.FillTransparency = fillTrans
                    hl.OutlineTransparency = outlineTrans
                else -- Outline Only (mode == 3)
                    hl.FillTransparency = 1
                    hl.OutlineTransparency = outlineTrans
                end
                hl.Enabled = true
            end
        end

        for _, part in ipairs(weaponParts) do
            pcall(stylePart, part, false)
        end
        for _, part in ipairs(armParts) do
            pcall(stylePart, part, true)
        end

        for part, obj in pairs(activeElements) do
            if not partsSeenThisFrame[part] then
                pcall(function() obj:Destroy() end)
                activeElements[part] = nil
            end
        end
    end

    return module
end
