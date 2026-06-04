return function(Window, State, updateESP, applyFOV, restoreFOV, applySkybox, restoreSkybox, toggleWatermark, toggleKeybindsList, toggleActiveFeaturesHUD)
    local VisualsTab = Window:CreateTab("visuals")
    
    local ESPGroup = VisualsTab:CreateGroupbox("esp")
    ESPGroup:CreateToggle({ Name = "enabled", Default = false, Callback = function(s) State.ESPEnabled = s; pcall(updateESP) end })
    ESPGroup:CreateToggle({ Name = "box esp (highlight)", Default = false, Callback = function(s) State.BoxESP = s; pcall(updateESP) end })
    ESPGroup:CreateToggle({ Name = "2d box esp (drawing)", Default = false, Callback = function(s) State.Box2DESP = s; pcall(updateESP) end })
    ESPGroup:CreateToggle({ Name = "name esp", Default = false, Callback = function(s) State.NameESP = s; pcall(updateESP) end })
    ESPGroup:CreateToggle({ Name = "team check", Default = true, Callback = function(s) State.TeamCheck = s; pcall(updateESP) end })

    local ChamsGroup = VisualsTab:CreateGroupbox("chams styling")
    ChamsGroup:CreateSlider({ Name = "fill transparency", Min = 0, Max = 100, Default = 60, Callback = function(v) State.ChamsFillTrans = v / 100; pcall(updateESP) end })
    ChamsGroup:CreateSlider({ Name = "outline transparency", Min = 0, Max = 100, Default = 20, Callback = function(v) State.ChamsOutlineTrans = v / 100; pcall(updateESP) end })
    ChamsGroup:CreateColorpicker({ Name = "fill color", Default = Color3.fromRGB(115, 120, 255), Callback = function(c) State.ChamsFillR, State.ChamsFillG, State.ChamsFillB = math.round(c.R * 255), math.round(c.G * 255), math.round(c.B * 255); pcall(updateESP) end })
    ChamsGroup:CreateColorpicker({ Name = "outline color", Default = Color3.fromRGB(255, 255, 255), Callback = function(c) State.ChamsOutlineR, State.ChamsOutlineG, State.ChamsOutlineB = math.round(c.R * 255), math.round(c.G * 255), math.round(c.B * 255); pcall(updateESP) end })

    local FOVGroup = VisualsTab:CreateGroupbox("camera")
    FOVGroup:CreateToggle({ Name = "custom fov", Default = false, Callback = function(s) State.CustomFOVEnabled = s; if not s then pcall(restoreFOV) else pcall(applyFOV) end end })
    FOVGroup:CreateSlider({ Name = "fov value", Min = 50, Max = 130, Default = 90, Callback = function(v) State.CustomFOVValue = v; if State.CustomFOVEnabled then pcall(applyFOV) end end })

    local SkyGroup = VisualsTab:CreateGroupbox("skybox")
    SkyGroup:CreateToggle({ Name = "custom skybox", Default = false, Callback = function(s) State.CustomSkyboxEnabled = s; if s then pcall(applySkybox, State.CurrentSkyboxName) else pcall(restoreSkybox) end end })
    local skyboxNames = { "space", "sunset", "night", "neon city", "synthwave", "purple nebula", "blood moon", "daylight" }
    SkyGroup:CreateSlider({ Name = "Skybox Style (1-8)", Min = 1, Max = 8, Default = 1, Callback = function(v) State.CurrentSkyboxName = skyboxNames[math.floor(v)]; if State.CustomSkyboxEnabled then pcall(applySkybox, State.CurrentSkyboxName) end end })

    local FOVColorGroup = VisualsTab:CreateGroupbox("fov circle styling")
    FOVColorGroup:CreateColorpicker({ Name = "circle color", Default = Color3.fromRGB(115, 120, 255), Callback = function(c) State.FOVR, State.FOVG, State.FOVB = math.round(c.R * 255), math.round(c.G * 255), math.round(c.B * 255) end })
    FOVColorGroup:CreateSlider({ Name = "thickness", Min = 1, Max = 5, Default = 1, Callback = function(v) State.FOVThickness = v end })
end
