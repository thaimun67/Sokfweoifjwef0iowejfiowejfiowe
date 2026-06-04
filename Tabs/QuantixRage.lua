return function(Window, State)
    local RageTab = Window:CreateTab("rage")
    local RageGroup = RageTab:CreateGroupbox("exploits")
    
    RageGroup:CreateToggle({ Name = "no recoil", Default = false, Callback = function(s) State.NoRecoilEnabled = s end })
end
