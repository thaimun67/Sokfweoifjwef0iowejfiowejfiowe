return function(State, Services)
    local module = {}
    local Lighting = Services.Lighting
    local originalSkyProps = {}
    local customSkyBoxes = {
        ["space"] = { SkyboxBk = "rbxassetid://1587391993", SkyboxDn = "rbxassetid://1587391851", SkyboxFt = "rbxassetid://1587392150", SkyboxLf = "rbxassetid://1587391696", SkyboxRt = "rbxassetid://1587391483", SkyboxUp = "rbxassetid://1587392285" },
        ["sunset"] = { SkyboxBk = "rbxassetid://600886090", SkyboxDn = "rbxassetid://600886090", SkyboxFt = "rbxassetid://600886090", SkyboxLf = "rbxassetid://600886090", SkyboxRt = "rbxassetid://600886090", SkyboxUp = "rbxassetid://600886090" },
        ["night"] = { SkyboxBk = "rbxassetid://143764022", SkyboxDn = "rbxassetid://143764022", SkyboxFt = "rbxassetid://143764022", SkyboxLf = "rbxassetid://143764022", SkyboxRt = "rbxassetid://143764022", SkyboxUp = "rbxassetid://143764022" },
        ["neon city"] = { SkyboxBk = "rbxassetid://270054770", SkyboxDn = "rbxassetid://270054770", SkyboxFt = "rbxassetid://270054770", SkyboxLf = "rbxassetid://270054770", SkyboxRt = "rbxassetid://270054770", SkyboxUp = "rbxassetid://270054770" },
        ["synthwave"] = { SkyboxBk = "rbxassetid://1045964490", SkyboxDn = "rbxassetid://1045964490", SkyboxFt = "rbxassetid://1045964490", SkyboxLf = "rbxassetid://1045964490", SkyboxRt = "rbxassetid://1045964490", SkyboxUp = "rbxassetid://1045964490" },
        ["purple nebula"] = { SkyboxBk = "rbxassetid://159454286", SkyboxDn = "rbxassetid://159454286", SkyboxFt = "rbxassetid://159454286", SkyboxLf = "rbxassetid://159454286", SkyboxRt = "rbxassetid://159454286", SkyboxUp = "rbxassetid://159454286" },
        ["blood moon"] = { SkyboxBk = "rbxassetid://306014496", SkyboxDn = "rbxassetid://306014496", SkyboxFt = "rbxassetid://306014496", SkyboxLf = "rbxassetid://306014496", SkyboxRt = "rbxassetid://306014496", SkyboxUp = "rbxassetid://306014496" },
        ["daylight"] = { SkyboxBk = "rbxassetid://600886090", SkyboxDn = "rbxassetid://600886090", SkyboxFt = "rbxassetid://600886090", SkyboxLf = "rbxassetid://600886090", SkyboxRt = "rbxassetid://600886090", SkyboxUp = "rbxassetid://600886090" }
    }

    function module.applySkybox(name)
        if not State.CustomSkyboxEnabled then return end
        local sky = Lighting:FindFirstChildOfClass("Sky")
        if not sky then
            sky = Instance.new("Sky")
            sky.Parent = Lighting
        end

        local props = customSkyBoxes[name]
        if not props then return end

        if not originalSkyProps.Saved then
            originalSkyProps.Saved = true
            originalSkyProps.SkyboxBk = sky.SkyboxBk
            originalSkyProps.SkyboxDn = sky.SkyboxDn
            originalSkyProps.SkyboxFt = sky.SkyboxFt
            originalSkyProps.SkyboxLf = sky.SkyboxLf
            originalSkyProps.SkyboxRt = sky.SkyboxRt
            originalSkyProps.SkyboxUp = sky.SkyboxUp
        end

        for k, v in pairs(props) do sky[k] = v end
    end

    function module.restoreSkybox()
        local sky = Lighting:FindFirstChildOfClass("Sky")
        if sky and originalSkyProps.Saved then
            sky.SkyboxBk = originalSkyProps.SkyboxBk
            sky.SkyboxDn = originalSkyProps.SkyboxDn
            sky.SkyboxFt = originalSkyProps.SkyboxFt
            sky.SkyboxLf = originalSkyProps.SkyboxLf
            sky.SkyboxRt = originalSkyProps.SkyboxRt
            sky.SkyboxUp = originalSkyProps.SkyboxUp
            originalSkyProps.Saved = false
        end
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
