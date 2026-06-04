return function(Window, State, toggleWatermark, toggleKeybindsList, toggleActiveFeaturesHUD)
    local MenuTab = Window:CreateTab("settings")
    
    local HUDGroup = MenuTab:CreateGroupbox("hud settings")
    HUDGroup:CreateToggle({ Name = "watermark", Default = false, Callback = function(s) pcall(toggleWatermark, s) end })
    HUDGroup:CreateToggle({ Name = "keybinds list", Default = false, Callback = function(s) pcall(toggleKeybindsList, s) end })
    HUDGroup:CreateToggle({ Name = "active features list", Default = false, Callback = function(s) pcall(toggleActiveFeaturesHUD, s) end })

    local MenuGroup = MenuTab:CreateGroupbox("menu")
    MenuGroup:CreateKeybind({ Name = "menu keybind", Default = Enum.KeyCode.Insert, Callback = function(k) 
        State.MenuToggleKey = k 
        -- Update the library's toggle key if it exists
        local lib = getgenv().QuantixLibrary
        if lib then lib.ToggleKey = k end
    end })
    
    MenuGroup:CreateButton({ Name = "unload script", Callback = function() 
        if getgenv().AbyssUnload then pcall(getgenv().AbyssUnload) end
    end })
end
