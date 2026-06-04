return function(Window, State)
    local ChangelogTab = Window:CreateTab("changelog")
    
    local InfoGroup = ChangelogTab:CreateGroupbox("v2.1 update")
    InfoGroup:CreateLabel({ Text = "- Fully modularized architecture" })
    InfoGroup:CreateLabel({ Text = "- Scripts load directly from GitHub" })
    InfoGroup:CreateLabel({ Text = "- Improved UI Library structure" })
    InfoGroup:CreateLabel({ Text = "- Fixed GUI missing bugs" })
    InfoGroup:CreateLabel({ Text = "- Improved ESP scoping" })
end
