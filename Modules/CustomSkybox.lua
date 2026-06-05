return function(State, Services)
    local module = {}
    local Lighting = Services.Lighting
    local originalSkyProps = {}
    local customSkyBoxes = {
        ["space"] = {
            SkyboxBk = "rbxassetid://159454299",
            SkyboxDn = "rbxassetid://159454296",
            SkyboxFt = "rbxassetid://159454293",
            SkyboxLf = "rbxassetid://159454286",
            SkyboxRt = "rbxassetid://159454300",
            SkyboxUp = "rbxassetid://159454288"
        },
        ["sunset"] = {
            SkyboxBk = "rbxassetid://372310881",
            SkyboxDn = "rbxassetid://372310881",
            SkyboxFt = "rbxassetid://372310881",
            SkyboxLf = "rbxassetid://372310881",
            SkyboxRt = "rbxassetid://372310881",
            SkyboxUp = "rbxassetid://372310881"
        },
        ["night"] = {
            SkyboxBk = "rbxassetid://6444884337",
            SkyboxDn = "rbxassetid://6444884337",
            SkyboxFt = "rbxassetid://6444884337",
            SkyboxLf = "rbxassetid://6444884337",
            SkyboxRt = "rbxassetid://6444884337",
            SkyboxUp = "rbxassetid://6444884337"
        },
        ["neon city"] = {
            SkyboxBk = "rbxassetid://6197721980",
            SkyboxDn = "rbxassetid://6197721980",
            SkyboxFt = "rbxassetid://6197721980",
            SkyboxLf = "rbxassetid://6197721980",
            SkyboxRt = "rbxassetid://6197721980",
            SkyboxUp = "rbxassetid://6197721980"
        },
        ["synthwave"] = {
            SkyboxBk = "rbxassetid://1417494030",
            SkyboxDn = "rbxassetid://1417494030",
            SkyboxFt = "rbxassetid://1417494030",
            SkyboxLf = "rbxassetid://1417494030",
            SkyboxRt = "rbxassetid://1417494030",
            SkyboxUp = "rbxassetid://1417494030"
        },
        ["purple nebula"] = {
            SkyboxBk = "rbxassetid://1045964490",
            SkyboxDn = "rbxassetid://1045964490",
            SkyboxFt = "rbxassetid://1045964490",
            SkyboxLf = "rbxassetid://1045964490",
            SkyboxRt = "rbxassetid://1045964490",
            SkyboxUp = "rbxassetid://1045964490"
        },
        ["blood moon"] = {
            SkyboxBk = "rbxassetid://1391515286",
            SkyboxDn = "rbxassetid://1391515286",
            SkyboxFt = "rbxassetid://1391515286",
            SkyboxLf = "rbxassetid://1391515286",
            SkyboxRt = "rbxassetid://1391515286",
            SkyboxUp = "rbxassetid://1391515286"
        },
        ["daylight"] = {
            SkyboxBk = "rbxassetid://600886082",
            SkyboxDn = "rbxassetid://600886082",
            SkyboxFt = "rbxassetid://600886082",
            SkyboxLf = "rbxassetid://600886082",
            SkyboxRt = "rbxassetid://600886082",
            SkyboxUp = "rbxassetid://600886082"
        }
    }

    local currentSky = nil

    function module.applySkybox(name)
        if not State.CustomSkyboxEnabled then return end
        local props = customSkyBoxes[name]
        if not props then return end

        if not originalSkyProps.Saved then
            local sky = Lighting:FindFirstChildOfClass("Sky")
            if sky then
                originalSkyProps.Saved = true
                originalSkyProps.SkyboxBk = sky.SkyboxBk
                originalSkyProps.SkyboxDn = sky.SkyboxDn
                originalSkyProps.SkyboxFt = sky.SkyboxFt
                originalSkyProps.SkyboxLf = sky.SkyboxLf
                originalSkyProps.SkyboxRt = sky.SkyboxRt
                originalSkyProps.SkyboxUp = sky.SkyboxUp
            else
                originalSkyProps.Saved = "None"
            end
        end

        for _, child in ipairs(Lighting:GetChildren()) do
            if child:IsA("Sky") then child:Destroy() end
        end

        local sky = Instance.new("Sky")
        sky.Name = "QuantixSkybox"
        sky.SkyboxBk = props.SkyboxBk
        sky.SkyboxDn = props.SkyboxDn
        sky.SkyboxFt = props.SkyboxFt
        sky.SkyboxLf = props.SkyboxLf
        sky.SkyboxRt = props.SkyboxRt
        sky.SkyboxUp = props.SkyboxUp
        sky.Parent = Lighting
        currentSky = sky
    end

    function module.restoreSkybox()
        if currentSky then currentSky:Destroy(); currentSky = nil end
        for _, child in ipairs(Lighting:GetChildren()) do
            if child.Name == "QuantixSkybox" then child:Destroy() end
        end

        if originalSkyProps.Saved and originalSkyProps.Saved ~= "None" then
            local sky = Instance.new("Sky")
            sky.SkyboxBk = originalSkyProps.SkyboxBk
            sky.SkyboxDn = originalSkyProps.SkyboxDn
            sky.SkyboxFt = originalSkyProps.SkyboxFt
            sky.SkyboxLf = originalSkyProps.SkyboxLf
            sky.SkyboxRt = originalSkyProps.SkyboxRt
            sky.SkyboxUp = originalSkyProps.SkyboxUp
            sky.Parent = Lighting
        end
        originalSkyProps.Saved = false
    end

    function module.update()
        if State.CustomSkyboxEnabled then
            pcall(module.applySkybox, State.CurrentSkyboxName)
        else
            pcall(module.restoreSkybox)
        end
    end

    return module
end
