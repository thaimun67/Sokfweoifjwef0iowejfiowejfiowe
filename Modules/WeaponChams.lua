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
    local activeAdornments = {}

    local function getChamsTargets()
        local camera = workspace.CurrentCamera
        if not camera then return nil, {} end

        local viewmodel = camera:FindFirstChild("Viewmodel")
        if not viewmodel then
            for _, child in ipairs(camera:GetChildren()) do
                if string.find(string.lower(child.Name), "viewmodel") or string.find(string.lower(child.Name), "vm") then
                    viewmodel = child
                    break
                end
            end
        end

        if not viewmodel then return nil, {} end

        local armsModel = viewmodel:FindFirstChild("Arms", true)
        local gunModels = {}

        for _, child in ipairs(viewmodel:GetChildren()) do
            if child:IsA("Model") and child.Name ~= "Arms" then
                local gunComponents = child:FindFirstChild("GunComponents")
                local parts = child:FindFirstChild("Parts")
                if gunComponents then table.insert(gunModels, gunComponents) end
                if parts then table.insert(gunModels, parts) end
                if not gunComponents and not parts then
                    table.insert(gunModels, child)
                end
            end
        end

        if not armsModel then
            for _, desc in ipairs(viewmodel:GetDescendants()) do
                if desc:IsA("Model") and (string.find(string.lower(desc.Name), "arm") or string.find(string.lower(desc.Name), "hand") or string.find(string.lower(desc.Name), "sleeve")) then
                    armsModel = desc
                    break
                end
            end
        end

        return armsModel, gunModels
    end

    function module.cleanup()
        for _, hl in pairs(activeHighlights) do
            pcall(function() hl:Destroy() end)
        end
        activeHighlights = {}

        for part, ad in pairs(activeAdornments) do
            pcall(function() ad:Destroy() end)
            pcall(function() part.LocalTransparencyModifier = 0 end)
        end
        activeAdornments = {}
    end

    function module.update()
        local camera = workspace.CurrentCamera
        if not camera then
            module.cleanup()
            return
        end

        local armsModel, gunModels = getChamsTargets()
        
        local mode = State.WeaponChamsMode
        local depth = State.WeaponChamsDepth
        
        local currentHighlights = {}
        local currentAdornments = {}

        local function applyHighlight(model, isArm)
            if not model then return end

            local hl = activeHighlights[model]
            if isArm then
                if State.HandChamsEnabled then
                    if not hl or not hl.Parent then
                        hl = Instance.new("Highlight")
                        hl.Name = "QuantixHandCham"
                        hl.Parent = model
                        activeHighlights[model] = hl
                    end
                    hl.Adornee = model
                    hl.FillColor = Color3.fromRGB(State.HandChamsFillR, State.HandChamsFillG, State.HandChamsFillB)
                    hl.OutlineColor = Color3.fromRGB(State.HandChamsOutlineR, State.HandChamsOutlineG, State.HandChamsOutlineB)
                    hl.DepthMode = depth and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
                    if mode == 1 then
                        hl.FillTransparency = State.HandChamsFillTrans
                        hl.OutlineTransparency = State.HandChamsOutlineTrans
                    else -- mode == 3 (Outline)
                        hl.FillTransparency = 1
                        hl.OutlineTransparency = State.HandChamsOutlineTrans
                    end
                    hl.Enabled = true
                    currentHighlights[model] = hl
                elseif State.WeaponChamsEnabled then
                    -- Dummy transparent highlight to override weapon highlight on arms
                    if not hl or not hl.Parent then
                        hl = Instance.new("Highlight")
                        hl.Name = "QuantixHandCham"
                        hl.Parent = model
                        activeHighlights[model] = hl
                    end
                    hl.Adornee = model
                    hl.FillColor = Color3.fromRGB(0, 0, 0)
                    hl.OutlineColor = Color3.fromRGB(0, 0, 0)
                    hl.FillTransparency = 1
                    hl.OutlineTransparency = 1
                    hl.DepthMode = Enum.HighlightDepthMode.Occluded
                    hl.Enabled = true
                    currentHighlights[model] = hl
                end
            else
                if State.WeaponChamsEnabled then
                    if not hl or not hl.Parent then
                        hl = Instance.new("Highlight")
                        hl.Name = "QuantixWeaponCham"
                        hl.Parent = model
                        activeHighlights[model] = hl
                    end
                    hl.Adornee = model
                    hl.FillColor = Color3.fromRGB(State.WeaponChamsFillR, State.WeaponChamsFillG, State.WeaponChamsFillB)
                    hl.OutlineColor = Color3.fromRGB(State.WeaponChamsOutlineR, State.WeaponChamsOutlineG, State.WeaponChamsOutlineB)
                    hl.DepthMode = depth and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
                    if mode == 1 then
                        hl.FillTransparency = State.WeaponChamsFillTrans
                        hl.OutlineTransparency = State.WeaponChamsOutlineTrans
                    else -- mode == 3 (Outline)
                        hl.FillTransparency = 1
                        hl.OutlineTransparency = State.WeaponChamsOutlineTrans
                    end
                    hl.Enabled = true
                    currentHighlights[model] = hl
                end
            end
        end

        local function applyWireframe(model, isArm)
            local enabled = isArm and State.HandChamsEnabled or State.WeaponChamsEnabled
            if not enabled or not model then return end

            local fillColor = isArm and Color3.fromRGB(State.HandChamsFillR, State.HandChamsFillG, State.HandChamsFillB) or Color3.fromRGB(State.WeaponChamsFillR, State.WeaponChamsFillG, State.WeaponChamsFillB)
            local fillTrans = isArm and State.HandChamsFillTrans or State.WeaponChamsFillTrans

            for _, part in ipairs(model:GetDescendants()) do
                if part:IsA("BasePart") then
                    if not isArm and armsModel and part:IsDescendantOf(armsModel) then
                        continue
                    end

                    -- Make original part mesh invisible so wireframe is visible
                    pcall(function() part.LocalTransparencyModifier = 1 end)

                    local ad = activeAdornments[part]
                    if not ad or not ad.Parent then
                        ad = Instance.new("WireframeHandleAdornment")
                        ad.Name = "QuantixWireframe"
                        ad.Parent = part
                        activeAdornments[part] = ad
                    end
                    ad.Adornee = part
                    ad.Color3 = fillColor
                    ad.AlwaysOnTop = depth
                    ad.Transparency = fillTrans
                    currentAdornments[part] = ad
                end
            end
        end

        if mode == 2 then -- Wireframe mode
            for m, hl in pairs(activeHighlights) do
                pcall(function() hl:Destroy() end)
            end
            activeHighlights = {}

            if armsModel then pcall(applyWireframe, armsModel, true) end
            for _, gunModel in ipairs(gunModels) do
                pcall(applyWireframe, gunModel, false)
            end
            
            -- Cleanup stale wireframes and restore their transparency
            for p, ad in pairs(activeAdornments) do
                if not currentAdornments[p] then
                    pcall(function() ad:Destroy() end)
                    pcall(function() p.LocalTransparencyModifier = 0 end)
                    activeAdornments[p] = nil
                end
            end
        else -- Normal or Outline mode
            -- Cleanup all wireframe adornments and restore original transparency
            for p, ad in pairs(activeAdornments) do
                pcall(function() ad:Destroy() end)
                pcall(function() p.LocalTransparencyModifier = 0 end)
            end
            activeAdornments = {}

            if armsModel then pcall(applyHighlight, armsModel, true) end
            for _, gunModel in ipairs(gunModels) do
                pcall(applyHighlight, gunModel, false)
            end
            
            -- Cleanup stale highlights
            for m, hl in pairs(activeHighlights) do
                if not currentHighlights[m] then
                    pcall(function() hl:Destroy() end)
                    activeHighlights[m] = nil
                end
            end
        end
    end

    return module
end
