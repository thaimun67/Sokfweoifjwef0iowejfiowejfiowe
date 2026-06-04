return function(Window, State)
    local MainTab = Window:CreateTab("main")
    
    local LegitGroup = MainTab:CreateGroupbox("legit")
    LegitGroup:CreateToggle({ Name = "aimbot", Default = false, Callback = function(s) State.AimbotEnabled = s end })
    LegitGroup:CreateToggle({ Name = "use mousemoverel", Default = true, Callback = function(s) State.AimbotMethod = s and "Mouse" or "Camera" end })
    LegitGroup:CreateToggle({ Name = "visible check", Default = true, Callback = function(s) State.VisibleCheck = s end })
    LegitGroup:CreateToggle({ Name = "apply prediction", Default = false, Callback = function(s) State.PredictionEnabled = s end })
    LegitGroup:CreateSlider({ Name = "smoothing [mouse]", Min = 0, Max = 20, Default = 5, Callback = function(v) State.Smoothing = v end })
    LegitGroup:CreateKeybind({ Name = "aim keybind", Default = Enum.UserInputType.MouseButton2, Callback = function(k) State.AimKey = k; State.Aiming = false end })

    local FOVGroup = MainTab:CreateGroupbox("fov settings")
    FOVGroup:CreateToggle({ Name = "enable fov", Default = false, Callback = function(s) State.FOVEnabled = s end })
    FOVGroup:CreateSlider({ Name = "fov radius", Min = 10, Max = 350, Default = 150, Callback = function(v) State.FOVRadius = v end })
end
