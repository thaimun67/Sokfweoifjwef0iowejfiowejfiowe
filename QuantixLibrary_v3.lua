local Library = {
    Connections = {},
    ToggleKey = Enum.KeyCode.Insert,
    OnToggle = nil,
    Registry = {},
    ThemeElements = {},
    Gradients = {},
    AccentStartGradients = {},
    AccentEndGradients = {},
    Window = nil
}

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = gethui and gethui() or game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local Theme = {
    Background = Color3.fromRGB(15, 15, 17),
    Darker = Color3.fromRGB(10, 10, 11),
    DarkOutline = Color3.fromRGB(30, 30, 35),
    LightOutline = Color3.fromRGB(45, 45, 50),
    AccentStart = Color3.fromRGB(115, 120, 255), 
    AccentEnd = Color3.fromRGB(150, 150, 255),
    Text = Color3.fromRGB(220, 220, 220),
    TextDark = Color3.fromRGB(150, 150, 150),
    ElementBackground = Color3.fromRGB(22, 22, 26),
    Font = Enum.Font.Code,
    TextSize = 13
}
Library.Theme = Theme

local function tween(object, time, propertyTable)
    local tweenInfo = TweenInfo.new(time or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local t = TweenService:Create(object, tweenInfo, propertyTable)
    t:Play()
    return t
end

-- Accent Theme Dynamic Repainter
function Library:SetAccentColors(startColor, endColor)
    Theme.AccentStart = startColor
    Theme.AccentEnd = endColor
    
    local sequence = ColorSequence.new({
        ColorSequenceKeypoint.new(0, startColor),
        ColorSequenceKeypoint.new(1, endColor)
    })
    
    for _, grad in ipairs(self.Gradients) do
        pcall(function() grad.Color = sequence end)
    end
    for _, elem in ipairs(self.ThemeElements) do
        pcall(function()
            if elem:IsA("Frame") or elem:IsA("TextButton") then
                elem.BackgroundColor3 = startColor
            elseif elem:IsA("UIStroke") then
                elem.Color = startColor
            elseif elem:IsA("TextLabel") or elem:IsA("TextBox") then
                elem.TextColor3 = startColor
            end
        end)
    end
    for _, grad in ipairs(self.AccentStartGradients) do
        pcall(function()
            grad.Color = ColorSequence.new(startColor)
        end)
    end
    for _, grad in ipairs(self.AccentEndGradients) do
        pcall(function()
            grad.Color = ColorSequence.new(endColor)
        end)
    end
end

-- Premium Slide-in Toast Notifications
local notificationQueue = {}
local activeNotifications = 0

function Library:Notify(title, message, duration)
    title = title or "Notification"
    message = message or ""
    duration = duration or 3.5

    local ScreenGui = ScreenGui or CoreGui:FindFirstChild("QuantixNotifications")
    if not ScreenGui then
        ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Name = "QuantixNotifications"
        ScreenGui.Parent = RunService:IsStudio() and game.Players.LocalPlayer:WaitForChild("PlayerGui") or CoreGui
    end

    local ToastFrame = Instance.new("Frame")
    ToastFrame.Size = UDim2.new(0, 240, 0, 50)
    ToastFrame.Position = UDim2.new(1, 260, 1, -60 - (activeNotifications * 60))
    ToastFrame.BackgroundColor3 = Theme.Background
    ToastFrame.BorderSizePixel = 0
    ToastFrame.Parent = ScreenGui

    -- Crisp Double Sharp Border
    local OuterBorder = Instance.new("UIStroke")
    OuterBorder.Color = Theme.DarkOutline
    OuterBorder.Thickness = 1
    OuterBorder.Parent = ToastFrame

    local LeftAccent = Instance.new("Frame")
    LeftAccent.Size = UDim2.new(0, 3, 1, 0)
    LeftAccent.Position = UDim2.new(0, 0, 0, 0)
    LeftAccent.BorderSizePixel = 0
    LeftAccent.Parent = ToastFrame

    local AccentGradient = Instance.new("UIGradient")
    AccentGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.AccentStart),
        ColorSequenceKeypoint.new(1, Theme.AccentEnd)
    })
    AccentGradient.Rotation = 90
    AccentGradient.Parent = LeftAccent
    table.insert(self.Gradients, AccentGradient)

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -15, 0, 18)
    TitleLabel.Position = UDim2.new(0, 10, 0, 4)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = title:upper()
    TitleLabel.TextColor3 = Theme.Text
    TitleLabel.Font = Theme.Font
    TitleLabel.TextSize = 11
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = ToastFrame

    local MessageLabel = Instance.new("TextLabel")
    MessageLabel.Size = UDim2.new(1, -15, 0, 24)
    MessageLabel.Position = UDim2.new(0, 10, 0, 20)
    MessageLabel.BackgroundTransparency = 1
    MessageLabel.Text = message
    MessageLabel.TextColor3 = Theme.TextDark
    MessageLabel.Font = Theme.Font
    MessageLabel.TextSize = 10
    MessageLabel.TextWrapped = true
    MessageLabel.TextXAlignment = Enum.TextXAlignment.Left
    MessageLabel.Parent = ToastFrame

    local ProgressBar = Instance.new("Frame")
    ProgressBar.Size = UDim2.new(1, 0, 0, 1)
    ProgressBar.Position = UDim2.new(0, 0, 1, -1)
    ProgressBar.BackgroundColor3 = Theme.AccentStart
    ProgressBar.BorderSizePixel = 0
    ProgressBar.Parent = ToastFrame
    table.insert(self.ThemeElements, ProgressBar)

    activeNotifications = activeNotifications + 1

    -- Animate in
    tween(ToastFrame, 0.25, { Position = UDim2.new(1, -250, 1, -60 - ((activeNotifications - 1) * 60)) })
    tween(ProgressBar, duration, { Size = UDim2.new(0, 0, 0, 1) })

    task.delay(duration, function()
        activeNotifications = activeNotifications - 1
        local outTween = tween(ToastFrame, 0.25, { Position = UDim2.new(1, 260, ToastFrame.Position.Y.Scale, ToastFrame.Position.Y.Offset) })
        outTween.Completed:Wait()
        ToastFrame:Destroy()
    end)
end

-- Serialization Config Files Save/Load Profile System
function Library:SaveConfig(profileName)
    if not profileName or profileName == "" then
        self:Notify("Config", "Please enter a valid config name", 3)
        return
    end

    local configData = {}
    for name, item in pairs(self.Registry) do
        pcall(function()
            local rawVal = item.Get()
            if typeof(rawVal) == "Color3" then
                configData[name] = { Type = "Color3", Value = { rawVal.R, rawVal.G, rawVal.B } }
            elseif typeof(rawVal) == "EnumItem" then
                configData[name] = { Type = "EnumItem", EnumType = tostring(rawVal.EnumType), Value = rawVal.Name }
            else
                configData[name] = { Type = "Primitive", Value = rawVal }
            end
        end)
    end

    local ok, json = pcall(HttpService.JSONEncode, HttpService, configData)
    if not ok then
        self:Notify("Config Error", "Failed to encode config to JSON", 4)
        return
    end

    local filePath = "Quantix_" .. profileName .. ".json"
    local writeOk, writeErr = pcall(function()
        if writefile then
            writefile(filePath, json)
        else
            error("writefile not supported by executor")
        end
    end)

    if writeOk then
        self:Notify("Config", "Saved config to " .. filePath, 3.5)
    else
        self:Notify("Config Warning", "Could not save file locally. Details: " .. tostring(writeErr), 5)
    end
end

function Library:LoadConfig(profileName)
    if not profileName or profileName == "" then
        self:Notify("Config", "Please enter a valid config name", 3)
        return
    end

    local filePath = "Quantix_" .. profileName .. ".json"
    local readOk, content = pcall(function()
        if readfile then
            return readfile(filePath)
        else
            error("readfile not supported by executor")
        end
    end)

    if not readOk then
        self:Notify("Config Warning", "Config file " .. filePath .. " not found or readfile unsupported", 4)
        return
    end

    local decodeOk, configData = pcall(HttpService.JSONDecode, HttpService, content)
    if not decodeOk then
        self:Notify("Config Error", "Failed to decode config JSON", 4)
        return
    end

    for name, item in pairs(configData) do
        local regItem = self.Registry[name]
        if regItem then
            pcall(function()
                if item.Type == "Color3" then
                    local c = Color3.new(item.Value[1], item.Value[2], item.Value[3])
                    regItem.Set(c)
                elseif item.Type == "EnumItem" then
                    local enumType = item.EnumType:gsub("Enum.", "")
                    local val = Enum[enumType][item.Value]
                    regItem.Set(val)
                else
                    regItem.Set(item.Value)
                end
            end)
        end
    end

    self:Notify("Config", "Successfully loaded config " .. filePath, 3.5)
end

function Library:CreateWindow(options)
    local titleText = options.Title or "Quantix dev access | fps strafe"
    
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "QuantixUI"
    task.defer(function()
        ScreenGui.Parent = RunService:IsStudio() and game.Players.LocalPlayer:WaitForChild("PlayerGui") or CoreGui
    end)

    -- Glow outline border behind main menu
    local GlowFrame = Instance.new("Frame")
    GlowFrame.Name = "Glow"
    GlowFrame.Size = UDim2.new(0, 554, 0, 454)
    GlowFrame.Position = UDim2.new(0.5, -277, 0.5, -227)
    GlowFrame.BackgroundColor3 = Theme.Background
    GlowFrame.BackgroundTransparency = 0.5
    GlowFrame.BorderSizePixel = 0
    GlowFrame.Parent = ScreenGui
    
    local GlowStroke = Instance.new("UIStroke")
    GlowStroke.Thickness = 2
    GlowStroke.Color = Theme.AccentStart
    GlowStroke.Parent = GlowFrame
    
    local GlowGradient = Instance.new("UIGradient")
    GlowGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.AccentStart),
        ColorSequenceKeypoint.new(1, Theme.AccentEnd)
    })
    GlowGradient.Parent = GlowStroke
    table.insert(self.Gradients, GlowGradient)

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "Main"
    MainFrame.Size = UDim2.new(0, 550, 0, 450)
    MainFrame.Position = UDim2.new(0.5, -275, 0.5, -225)
    MainFrame.BackgroundColor3 = Theme.Background
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui

    -- Sync glow position and visibility
    local function updateGlowPosition()
        GlowFrame.Position = UDim2.new(MainFrame.Position.X.Scale, MainFrame.Position.X.Offset - 2, MainFrame.Position.Y.Scale, MainFrame.Position.Y.Offset - 2)
    end
    MainFrame:GetPropertyChangedSignal("Position"):Connect(updateGlowPosition)
    MainFrame:GetPropertyChangedSignal("Visible"):Connect(function()
        GlowFrame.Visible = MainFrame.Visible
    end)

    -- Dragging Setup
    local dragging, dragInput, dragStart, startPos
    MainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
        end
    end)
    MainFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
    end)
    table.insert(self.Connections, UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end))
    table.insert(self.Connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end))

    -- Aesthetic Double Outer Border (1px Inner outline + 1px Accent Gradient frame)
    local OuterBorder = Instance.new("UIStroke")
    OuterBorder.Color = Color3.new(1, 1, 1)
    OuterBorder.Thickness = 1
    OuterBorder.Parent = MainFrame

    local BorderGradient = Instance.new("UIGradient")
    BorderGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.AccentStart),
        ColorSequenceKeypoint.new(1, Theme.AccentEnd)
    })
    BorderGradient.Parent = OuterBorder
    table.insert(self.Gradients, BorderGradient)

    -- Horizontal Accent Line under Title Bar
    local TopAccent = Instance.new("Frame")
    TopAccent.Size = UDim2.new(1, 0, 0, 2)
    TopAccent.Position = UDim2.new(0, 0, 0, 23)
    TopAccent.BorderSizePixel = 0
    TopAccent.Parent = MainFrame
    
    local TopAccentGradient = Instance.new("UIGradient")
    TopAccentGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.AccentStart),
        ColorSequenceKeypoint.new(1, Theme.AccentEnd)
    })
    TopAccentGradient.Parent = TopAccent
    table.insert(self.Gradients, TopAccentGradient)

    -- Title
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -20, 0, 25)
    Title.Position = UDim2.new(0, 10, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = titleText
    Title.TextColor3 = Theme.Text
    Title.Font = Theme.Font
    Title.TextSize = Theme.TextSize
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = MainFrame

    -- Tab Bar
    local TabContainer = Instance.new("Frame")
    TabContainer.Size = UDim2.new(1, -20, 0, 20)
    TabContainer.Position = UDim2.new(0, 10, 0, 25)
    TabContainer.BackgroundTransparency = 1
    TabContainer.Parent = MainFrame

    local TabListLayout = Instance.new("UIListLayout")
    TabListLayout.FillDirection = Enum.FillDirection.Horizontal
    TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabListLayout.Parent = TabContainer

    local ContentContainer = Instance.new("Frame")
    ContentContainer.Size = UDim2.new(1, -20, 1, -55)
    ContentContainer.Position = UDim2.new(0, 10, 0, 50)
    ContentContainer.BackgroundTransparency = 1
    ContentContainer.Parent = MainFrame

    local Window = { Tabs = {}, CurrentTab = nil, Gui = ScreenGui, Main = MainFrame, ToggleKey = Enum.KeyCode.Insert }
    self.Window = Window

    -- Smooth scale toggle menu transition
    local toggling = false
    local function ToggleMenu(visible)
        if toggling then return end
        toggling = true
        if visible then
            MainFrame.Size = UDim2.new(0, 0, 0, 0)
            MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
            MainFrame.Visible = true
            local tMain = tween(MainFrame, 0.25, { Size = UDim2.new(0, 550, 0, 450), Position = UDim2.new(0.5, -275, 0.5, -225) })
            tMain.Completed:Wait()
        else
            local tMain = tween(MainFrame, 0.25, { Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0) })
            tMain.Completed:Wait()
            MainFrame.Visible = false
        end
        toggling = false
    end

    table.insert(self.Connections, UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and (input.KeyCode == self.ToggleKey or input.UserInputType == self.ToggleKey) then
            local nextState = not MainFrame.Visible
            ToggleMenu(nextState)
            if self.OnToggle then pcall(function() self.OnToggle(nextState) end) end
        end
    end))

    function Window:CreateTab(tabName)
        local TabButton = Instance.new("TextButton")
        TabButton.BackgroundColor3 = Theme.Background
        TabButton.BorderColor3 = Theme.DarkOutline
        TabButton.Text = tabName
        TabButton.TextColor3 = Theme.TextDark
        TabButton.Font = Theme.Font
        TabButton.TextSize = Theme.TextSize
        TabButton.Parent = TabContainer
        
        local textBounds = game:GetService("TextService"):GetTextSize(tabName, Theme.TextSize, Theme.Font, Vector2.new(999, 20))
        TabButton.Size = UDim2.new(0, textBounds.X + 20, 1, 0)

        local TabContent = Instance.new("ScrollingFrame")
        TabContent.Size = UDim2.new(1, 0, 1, 0)
        TabContent.BackgroundTransparency = 1
        TabContent.ScrollBarThickness = 2
        TabContent.ScrollBarImageColor3 = Theme.AccentStart
        TabContent.Visible = false
        TabContent.Parent = ContentContainer
        table.insert(Library.ThemeElements, TabContent)

        local ContentLayout = Instance.new("UIListLayout")
        ContentLayout.Padding = UDim.new(0, 8)
        ContentLayout.FillDirection = Enum.FillDirection.Horizontal
        ContentLayout.Parent = TabContent

        local LeftSide = Instance.new("Frame")
        LeftSide.Size = UDim2.new(0.5, -4, 1, 0)
        LeftSide.BackgroundTransparency = 1
        LeftSide.Parent = TabContent
        local LeftLayout = Instance.new("UIListLayout")
        LeftLayout.Padding = UDim.new(0, 10)
        LeftLayout.Parent = LeftSide

        local RightSide = Instance.new("Frame")
        RightSide.Size = UDim2.new(0.5, -4, 1, 0)
        RightSide.BackgroundTransparency = 1
        RightSide.Parent = TabContent
        local RightLayout = Instance.new("UIListLayout")
        RightLayout.Padding = UDim.new(0, 10)
        RightLayout.Parent = RightSide

        TabButton.MouseEnter:Connect(function()
            if Window.CurrentTab ~= tabName then
                tween(TabButton, 0.15, { TextColor3 = Theme.Text })
            end
        end)
        TabButton.MouseLeave:Connect(function()
            if Window.CurrentTab ~= tabName then
                tween(TabButton, 0.15, { TextColor3 = Theme.TextDark })
            end
        end)

        TabButton.MouseButton1Click:Connect(function()
            for _, tab in pairs(Window.Tabs) do
                tab.Content.Visible = false
                tween(tab.Button, 0.15, { TextColor3 = Theme.TextDark, BorderColor3 = Theme.DarkOutline })
            end
            TabContent.Visible = true
            Window.CurrentTab = tabName
            tween(TabButton, 0.15, { TextColor3 = Theme.Text, BorderColor3 = Theme.LightOutline })
        end)

        if not Window.CurrentTab then
            Window.CurrentTab = tabName
            TabContent.Visible = true
            TabButton.TextColor3 = Theme.Text
            TabButton.BorderColor3 = Theme.LightOutline
        end

        table.insert(Window.Tabs, { Button = TabButton, Content = TabContent })
        
        local Tab = { SideToggle = true }
        
        function Tab:CreateGroupbox(name)
            local targetSide = self.SideToggle and LeftSide or RightSide
            self.SideToggle = not self.SideToggle

            local Groupbox = Instance.new("Frame")
            Groupbox.Size = UDim2.new(1, 0, 0, 20)
            Groupbox.BackgroundColor3 = Theme.Background
            Groupbox.BorderColor3 = Theme.DarkOutline
            Groupbox.Parent = targetSide

            -- 1px Inline accent highlights for header
            local GroupBorder = Instance.new("UIStroke")
            GroupBorder.Thickness = 1
            GroupBorder.Color = Theme.DarkOutline
            GroupBorder.Parent = Groupbox

            local GroupTitle = Instance.new("TextLabel")
            GroupTitle.Size = UDim2.new(1, -10, 0, 20)
            GroupTitle.Position = UDim2.new(0, 5, 0, 0)
            GroupTitle.BackgroundTransparency = 1
            GroupTitle.Text = name
            GroupTitle.TextColor3 = Theme.Text
            GroupTitle.Font = Theme.Font
            GroupTitle.TextSize = Theme.TextSize
            GroupTitle.TextXAlignment = Enum.TextXAlignment.Left
            GroupTitle.Parent = Groupbox

            local GroupLine = Instance.new("Frame")
            GroupLine.Size = UDim2.new(1, -10, 0, 1)
            GroupLine.Position = UDim2.new(0, 5, 0, 20)
            GroupLine.BackgroundColor3 = Theme.DarkOutline
            GroupLine.BorderSizePixel = 0
            GroupLine.Parent = Groupbox

            local GroupContainer = Instance.new("Frame")
            GroupContainer.Size = UDim2.new(1, -10, 1, -25)
            GroupContainer.Position = UDim2.new(0, 5, 0, 25)
            GroupContainer.BackgroundTransparency = 1
            GroupContainer.Parent = Groupbox

            local GroupLayout = Instance.new("UIListLayout")
            GroupLayout.Padding = UDim.new(0, 5)
            GroupLayout.Parent = GroupContainer

            GroupLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                Groupbox.Size = UDim2.new(1, 0, 0, GroupLayout.AbsoluteContentSize.Y + 30)
            end)

            local Group = {}

            function Group:CreateLabel(options)
                local LabelFrame = Instance.new("Frame")
                LabelFrame.Size = UDim2.new(1, 0, 0, 15)
                LabelFrame.BackgroundTransparency = 1
                LabelFrame.Parent = GroupContainer

                local Label = Instance.new("TextLabel")
                Label.Size = UDim2.new(1, -4, 1, 0)
                Label.Position = UDim2.new(0, 2, 0, 0)
                Label.BackgroundTransparency = 1
                Label.Text = options.Text
                Label.TextColor3 = Theme.TextDark
                Label.Font = Theme.Font
                Label.TextSize = Theme.TextSize
                Label.TextXAlignment = Enum.TextXAlignment.Left
                Label.Parent = LabelFrame
                
                local control = {}
                function control.Set(text) Label.Text = text end
                function control.Get() return Label.Text end
                return control
            end

            function Group:CreateTextBox(options)
                local BoxFrame = Instance.new("Frame")
                BoxFrame.Size = UDim2.new(1, 0, 0, 32)
                BoxFrame.BackgroundTransparency = 1
                BoxFrame.Parent = GroupContainer

                local Label = Instance.new("TextLabel")
                Label.Size = UDim2.new(1, 0, 0, 15)
                Label.Position = UDim2.new(0, 2, 0, 0)
                Label.BackgroundTransparency = 1
                Label.Text = options.Name
                Label.TextColor3 = Theme.TextDark
                Label.Font = Theme.Font
                Label.TextSize = Theme.TextSize
                Label.TextXAlignment = Enum.TextXAlignment.Left
                Label.Parent = BoxFrame

                local BoxInput = Instance.new("TextBox")
                BoxInput.Size = UDim2.new(1, -4, 0, 16)
                BoxInput.Position = UDim2.new(0, 2, 0, 15)
                BoxInput.BackgroundColor3 = Theme.ElementBackground
                BoxInput.BorderColor3 = Theme.LightOutline
                BoxInput.Text = options.Default or ""
                BoxInput.PlaceholderText = options.Placeholder or ""
                BoxInput.TextColor3 = Theme.Text
                BoxInput.PlaceholderColor3 = Theme.TextDark
                BoxInput.Font = Theme.Font
                BoxInput.TextSize = Theme.TextSize - 1
                BoxInput.TextXAlignment = Enum.TextXAlignment.Left
                BoxInput.ClearTextOnFocus = false
                BoxInput.Parent = BoxFrame

                local Stroke = Instance.new("UIStroke")
                Stroke.Thickness = 1
                Stroke.Color = Theme.DarkOutline
                Stroke.Parent = BoxInput

                BoxInput.FocusLost:Connect(function()
                    if options.Callback then options.Callback(BoxInput.Text) end
                end)

                local control = {}
                function control.Set(val) BoxInput.Text = val; if options.Callback then options.Callback(val) end end
                function control.Get() return BoxInput.Text end
                
                if options.Name then
                    Library.Registry[options.Name] = control
                end
                return control
            end

            function Group:CreateButton(options)
                local ButtonFrame = Instance.new("Frame")
                ButtonFrame.Size = UDim2.new(1, 0, 0, 20)
                ButtonFrame.BackgroundTransparency = 1
                ButtonFrame.Parent = GroupContainer

                local Button = Instance.new("TextButton")
                Button.Size = UDim2.new(1, -4, 1, 0)
                Button.Position = UDim2.new(0, 2, 0, 0)
                Button.BackgroundColor3 = Theme.ElementBackground
                Button.BorderColor3 = Theme.LightOutline
                Button.Text = options.Name
                Button.TextColor3 = Theme.Text
                Button.Font = Theme.Font
                Button.TextSize = Theme.TextSize
                Button.Parent = ButtonFrame

                local Stroke = Instance.new("UIStroke")
                Stroke.Thickness = 1
                Stroke.Color = Theme.DarkOutline
                Stroke.Parent = Button

                Button.MouseEnter:Connect(function()
                    tween(Button, 0.15, { BackgroundColor3 = Theme.DarkOutline, TextColor3 = Theme.AccentEnd })
                end)
                Button.MouseLeave:Connect(function()
                    tween(Button, 0.15, { BackgroundColor3 = Theme.ElementBackground, TextColor3 = Theme.Text })
                end)

                Button.MouseButton1Click:Connect(function()
                    if options.Callback then options.Callback() end
                end)
            end

            function Group:CreateToggle(options)
                local ToggleFrame = Instance.new("Frame")
                ToggleFrame.Size = UDim2.new(1, 0, 0, 15)
                ToggleFrame.BackgroundTransparency = 1
                ToggleFrame.Parent = GroupContainer

                local ToggleBox = Instance.new("TextButton")
                ToggleBox.Size = UDim2.new(0, 10, 0, 10)
                ToggleBox.Position = UDim2.new(0, 2, 0, 2)
                ToggleBox.BackgroundColor3 = Theme.ElementBackground
                ToggleBox.BorderColor3 = Theme.DarkOutline
                ToggleBox.Text = ""
                ToggleBox.Parent = ToggleFrame

                local Stroke = Instance.new("UIStroke")
                Stroke.Thickness = 1
                Stroke.Color = Theme.DarkOutline
                Stroke.Parent = ToggleBox

                local ToggleLabel = Instance.new("TextLabel")
                ToggleLabel.Size = UDim2.new(1, -20, 1, 0)
                ToggleLabel.Position = UDim2.new(0, 18, 0, 0)
                ToggleLabel.BackgroundTransparency = 1
                ToggleLabel.Text = options.Name
                ToggleLabel.TextColor3 = Theme.TextDark
                ToggleLabel.Font = Theme.Font
                ToggleLabel.TextSize = Theme.TextSize
                ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
                ToggleLabel.Parent = ToggleFrame

                local toggled = options.Default or false

                local function Update()
                    local targetColor = toggled and Theme.AccentStart or Theme.ElementBackground
                    local targetTextColor = toggled and Theme.Text or Theme.TextDark
                    tween(ToggleBox, 0.15, { BackgroundColor3 = targetColor })
                    tween(ToggleLabel, 0.15, { TextColor3 = targetTextColor })
                    if options.Callback then options.Callback(toggled) end
                end

                ToggleBox.MouseEnter:Connect(function()
                    tween(ToggleBox, 0.15, { BorderColor3 = Theme.AccentStart })
                end)
                ToggleBox.MouseLeave:Connect(function()
                    tween(ToggleBox, 0.15, { BorderColor3 = Theme.DarkOutline })
                end)

                ToggleBox.MouseButton1Click:Connect(function()
                    toggled = not toggled
                    Update()
                end)
                
                local control = {}
                function control.Set(state) toggled = state; Update() end
                function control.Get() return toggled end

                if options.Name then
                    Library.Registry[options.Name] = control
                end

                Update()
                return control
            end

            function Group:CreateSlider(options)
                local SliderFrame = Instance.new("Frame")
                SliderFrame.Size = UDim2.new(1, 0, 0, 30)
                SliderFrame.BackgroundTransparency = 1
                SliderFrame.Parent = GroupContainer

                local SliderLabel = Instance.new("TextLabel")
                SliderLabel.Size = UDim2.new(1, 0, 0, 15)
                SliderLabel.BackgroundTransparency = 1
                SliderLabel.Text = options.Name
                SliderLabel.TextColor3 = Theme.TextDark
                SliderLabel.Font = Theme.Font
                SliderLabel.TextSize = Theme.TextSize
                SliderLabel.TextXAlignment = Enum.TextXAlignment.Left
                SliderLabel.Parent = SliderFrame

                local SliderBack = Instance.new("TextButton")
                SliderBack.Size = UDim2.new(1, -4, 0, 10)
                SliderBack.Position = UDim2.new(0, 2, 0, 18)
                SliderBack.BackgroundColor3 = Theme.ElementBackground
                SliderBack.BorderColor3 = Theme.DarkOutline
                SliderBack.Text = ""
                SliderBack.Parent = SliderFrame

                local Stroke = Instance.new("UIStroke")
                Stroke.Thickness = 1
                Stroke.Color = Theme.DarkOutline
                Stroke.Parent = SliderBack

                local SliderFill = Instance.new("Frame")
                SliderFill.Size = UDim2.new(0, 0, 1, 0)
                SliderFill.BackgroundColor3 = Theme.AccentStart
                SliderFill.BorderSizePixel = 0
                SliderFill.Parent = SliderBack
                table.insert(Library.ThemeElements, SliderFill)

                local FillGradient = Instance.new("UIGradient")
                FillGradient.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Theme.AccentStart),
                    ColorSequenceKeypoint.new(1, Theme.AccentEnd)
                })
                FillGradient.Parent = SliderFill
                table.insert(Library.Gradients, FillGradient)

                local ValueLabel = Instance.new("TextLabel")
                ValueLabel.Size = UDim2.new(1, 0, 1, 0)
                ValueLabel.BackgroundTransparency = 1
                ValueLabel.Text = "0/" .. options.Max
                ValueLabel.TextColor3 = Theme.Text
                ValueLabel.Font = Theme.Font
                ValueLabel.TextSize = Theme.TextSize - 2
                ValueLabel.ZIndex = 2
                ValueLabel.Parent = SliderBack

                local min = options.Min or 0
                local max = options.Max or 100
                local current = options.Default or min
                local sliding = false

                local function UpdateVisuals()
                    local percent = math.clamp((current - min) / (max - min), 0, 1)
                    SliderFill.Size = UDim2.new(percent, 0, 1, 0)
                    ValueLabel.Text = current .. "/" .. max
                end

                local function UpdateInput(input)
                    local percent = math.clamp((input.Position.X - SliderBack.AbsolutePosition.X) / SliderBack.AbsoluteSize.X, 0, 1)
                    current = math.floor(min + (max - min) * percent)
                    UpdateVisuals()
                    if options.Callback then options.Callback(current) end
                end

                SliderBack.MouseEnter:Connect(function()
                    tween(SliderBack, 0.15, { BorderColor3 = Theme.AccentStart })
                end)
                SliderBack.MouseLeave:Connect(function()
                    tween(SliderBack, 0.15, { BorderColor3 = Theme.DarkOutline })
                end)

                SliderBack.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        sliding = true
                        UpdateInput(input)
                    end
                end)
                SliderBack.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end
                end)
                table.insert(Library.Connections, UserInputService.InputChanged:Connect(function(input)
                    if sliding and input.UserInputType == Enum.UserInputType.MouseMovement then
                        UpdateInput(input)
                    end
                end))

                local control = {}
                function control.Set(val) current = math.clamp(val, min, max); UpdateVisuals(); if options.Callback then options.Callback(current) end end
                function control.Get() return current end

                if options.Name then
                    Library.Registry[options.Name] = control
                end

                UpdateVisuals()
                return control
            end

            function Group:CreateKeybind(options)
                local KeybindFrame = Instance.new("Frame")
                KeybindFrame.Size = UDim2.new(1, 0, 0, 20)
                KeybindFrame.BackgroundTransparency = 1
                KeybindFrame.Parent = GroupContainer

                local KeybindLabel = Instance.new("TextLabel")
                KeybindLabel.Size = UDim2.new(1, -60, 1, 0)
                KeybindLabel.Position = UDim2.new(0, 2, 0, 0)
                KeybindLabel.BackgroundTransparency = 1
                KeybindLabel.Text = options.Name
                KeybindLabel.TextColor3 = Theme.TextDark
                KeybindLabel.Font = Theme.Font
                KeybindLabel.TextSize = Theme.TextSize
                KeybindLabel.TextXAlignment = Enum.TextXAlignment.Left
                KeybindLabel.Parent = KeybindFrame

                local KeybindButton = Instance.new("TextButton")
                KeybindButton.Size = UDim2.new(0, 50, 1, 0)
                KeybindButton.Position = UDim2.new(1, -52, 0, 0)
                KeybindButton.BackgroundColor3 = Theme.ElementBackground
                KeybindButton.BorderColor3 = Theme.LightOutline
                KeybindButton.Text = options.Default.Name or (tostring(options.Default):gsub("Enum.UserInputType.", ""):gsub("Enum.KeyCode.", ""))
                KeybindButton.TextColor3 = Theme.Text
                KeybindButton.Font = Theme.Font
                KeybindButton.TextSize = Theme.TextSize
                KeybindButton.Parent = KeybindFrame

                local Stroke = Instance.new("UIStroke")
                Stroke.Thickness = 1
                Stroke.Color = Theme.DarkOutline
                Stroke.Parent = KeybindButton

                local currentKey = options.Default
                local listening = false

                KeybindButton.MouseEnter:Connect(function()
                    tween(KeybindButton, 0.15, { BorderColor3 = Theme.AccentStart })
                end)
                KeybindButton.MouseLeave:Connect(function()
                    tween(KeybindButton, 0.15, { BorderColor3 = Theme.LightOutline })
                end)

                KeybindButton.MouseButton1Click:Connect(function()
                    listening = true
                    KeybindButton.Text = "..."
                end)

                table.insert(Library.Connections, UserInputService.InputBegan:Connect(function(input, processed)
                    if listening then
                        local newKey = nil
                        local newName = ""
                        
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            newKey = input.KeyCode
                            newName = newKey.Name
                        elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                            newKey = Enum.UserInputType.MouseButton1
                            newName = "M1"
                        elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                            newKey = Enum.UserInputType.MouseButton2
                            newName = "M2"
                        end
                        
                        if newKey then
                            currentKey = newKey
                            KeybindButton.Text = newName
                            listening = false
                            if options.Callback then options.Callback(currentKey) end
                        end
                    end
                end))

                local control = {}
                function control.Set(key)
                    currentKey = key
                    KeybindButton.Text = key.Name or tostring(key):gsub("Enum.UserInputType.", ""):gsub("Enum.KeyCode.", "")
                    if options.Callback then options.Callback(currentKey) end
                end
                function control.Get() return currentKey end

                if options.Name then
                    Library.Registry[options.Name] = control
                end

                return control
            end

            function Group:CreateColorpicker(options)
                local ColorpickerFrame = Instance.new("Frame")
                ColorpickerFrame.Size = UDim2.new(1, 0, 0, 20)
                ColorpickerFrame.BackgroundTransparency = 1
                ColorpickerFrame.Parent = GroupContainer

                local ColorpickerLabel = Instance.new("TextLabel")
                ColorpickerLabel.Size = UDim2.new(1, -30, 1, 0)
                ColorpickerLabel.Position = UDim2.new(0, 2, 0, 0)
                ColorpickerLabel.BackgroundTransparency = 1
                ColorpickerLabel.Text = options.Name
                ColorpickerLabel.TextColor3 = Theme.TextDark
                ColorpickerLabel.Font = Theme.Font
                ColorpickerLabel.TextSize = Theme.TextSize
                ColorpickerLabel.TextXAlignment = Enum.TextXAlignment.Left
                ColorpickerLabel.Parent = ColorpickerFrame

                local PreviewButton = Instance.new("TextButton")
                PreviewButton.Size = UDim2.new(0, 20, 0, 10)
                PreviewButton.Position = UDim2.new(1, -22, 0.5, -5)
                PreviewButton.BackgroundColor3 = options.Default or Color3.fromRGB(255, 255, 255)
                PreviewButton.BorderColor3 = Theme.LightOutline
                PreviewButton.Text = ""
                PreviewButton.Parent = ColorpickerFrame

                local Stroke = Instance.new("UIStroke")
                Stroke.Thickness = 1
                Stroke.Color = Theme.DarkOutline
                Stroke.Parent = PreviewButton

                -- Dropdown Drawer Frame
                local Drawer = Instance.new("Frame")
                Drawer.Size = UDim2.new(1, 0, 0, 0)
                Drawer.Position = UDim2.new(0, 0, 0, 20)
                Drawer.BackgroundTransparency = 1
                Drawer.ClipsDescendants = true
                Drawer.Visible = false
                Drawer.Parent = ColorpickerFrame

                -- Current Color Box in Drawer
                local CurrentColorBox = Instance.new("Frame")
                CurrentColorBox.Size = UDim2.new(1, -54, 0, 20)
                CurrentColorBox.Position = UDim2.new(0, 2, 0, 110)
                CurrentColorBox.BackgroundColor3 = options.Default or Color3.fromRGB(255, 255, 255)
                CurrentColorBox.BorderColor3 = Theme.LightOutline
                CurrentColorBox.Parent = Drawer

                local BoxStroke = Instance.new("UIStroke")
                BoxStroke.Thickness = 1
                BoxStroke.Color = Theme.DarkOutline
                BoxStroke.Parent = CurrentColorBox

                -- Close Button in Drawer
                local CloseButton = Instance.new("TextButton")
                CloseButton.Size = UDim2.new(0, 48, 0, 20)
                CloseButton.Position = UDim2.new(1, -50, 0, 110)
                CloseButton.BackgroundColor3 = Theme.Darker
                CloseButton.BorderColor3 = Theme.LightOutline
                CloseButton.Text = "Close"
                CloseButton.TextColor3 = Theme.Text
                CloseButton.Font = Theme.Font
                CloseButton.TextSize = 12
                CloseButton.Parent = Drawer

                local CloseStroke = Instance.new("UIStroke")
                CloseStroke.Thickness = 1
                CloseStroke.Color = Theme.DarkOutline
                CloseStroke.Parent = CloseButton

                local Spectrum = Instance.new("ImageButton")
                Spectrum.Size = UDim2.new(1, -4, 0, 100)
                Spectrum.Position = UDim2.new(0, 2, 0, 5)
                Spectrum.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Spectrum.BackgroundTransparency = 0
                Spectrum.Image = ""
                Spectrum.BorderSizePixel = 0
                Spectrum.ZIndex = 10
                Spectrum.Parent = Drawer

                local SpectrumStroke = Instance.new("UIStroke")
                SpectrumStroke.Thickness = 1
                SpectrumStroke.Color = Theme.DarkOutline
                SpectrumStroke.Parent = Spectrum

                local RainbowGradient = Instance.new("UIGradient")
                RainbowGradient.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                    ColorSequenceKeypoint.new(0.167, Color3.fromRGB(255, 255, 0)),
                    ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0, 255, 0)),
                    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
                    ColorSequenceKeypoint.new(0.667, Color3.fromRGB(0, 0, 255)),
                    ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255, 0, 255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
                })
                RainbowGradient.Parent = Spectrum
                
                local Overlay = Instance.new("Frame")
                Overlay.Size = UDim2.new(1, 0, 1, 0)
                Overlay.BackgroundTransparency = 0
                Overlay.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Overlay.BorderSizePixel = 0
                Overlay.Active = false
                Overlay.ZIndex = 11
                Overlay.Parent = Spectrum

                local OverlayGradient = Instance.new("UIGradient")
                OverlayGradient.Rotation = 90
                OverlayGradient.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                    ColorSequenceKeypoint.new(0.499, Color3.fromRGB(255, 255, 255)),
                    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 0, 0)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
                })
                OverlayGradient.Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(0.5, 1),
                    NumberSequenceKeypoint.new(1, 0)
                })
                OverlayGradient.Parent = Overlay

                local Indicator = Instance.new("Frame")
                Indicator.Size = UDim2.new(0, 6, 0, 6)
                Indicator.AnchorPoint = Vector2.new(0.5, 0.5)
                Indicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Indicator.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Indicator.ZIndex = 12
                Indicator.Parent = Spectrum
                
                local indicatorStroke = Instance.new("UIStroke")
                indicatorStroke.Thickness = 1
                indicatorStroke.Color = Color3.fromRGB(0, 0, 0)
                indicatorStroke.Parent = Indicator

                local toggled = false
                local activeColor = options.Default or Color3.fromRGB(255, 255, 255)

                -- Calculate initial indicator position from Default color
                local h, s, v = Color3.toHSV(activeColor)
                local initX = h
                local initY
                if s < 1 then
                    initY = s / 2
                else
                    initY = 0.5 + (1 - v) / 2
                end
                Indicator.Position = UDim2.new(initX, 0, initY, 0)

                local function UpdateVisuals()
                    PreviewButton.BackgroundColor3 = activeColor
                    CurrentColorBox.BackgroundColor3 = activeColor
                    local h, s, v = Color3.toHSV(activeColor)
                    local yVal = (s < 1) and (s / 2) or (0.5 + (1 - v) / 2)
                    Indicator.Position = UDim2.new(h, 0, yVal, 0)
                end

                local function updateColor(input)
                    local absPos = Spectrum.AbsolutePosition
                    local absSize = Spectrum.AbsoluteSize
                    local relX = math.clamp((input.Position.X - absPos.X) / absSize.X, 0, 1)
                    local relY = math.clamp((input.Position.Y - absPos.Y) / absSize.Y, 0, 1)

                    Indicator.Position = UDim2.new(relX, 0, relY, 0)

                    local hue = relX
                    local sat, val
                    if relY < 0.5 then
                        sat = relY * 2
                        val = 1
                    else
                        sat = 1
                        val = (1 - relY) * 2
                    end

                    activeColor = Color3.fromHSV(hue, sat, val)
                    PreviewButton.BackgroundColor3 = activeColor
                    CurrentColorBox.BackgroundColor3 = activeColor
                    if options.Callback then
                        options.Callback(activeColor)
                    end
                end

                local selecting = false
                Spectrum.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        selecting = true
                        updateColor(input)
                    end
                end)
                Spectrum.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        selecting = false
                    end
                end)
                table.insert(Library.Connections, UserInputService.InputChanged:Connect(function(input)
                    if selecting and input.UserInputType == Enum.UserInputType.MouseMovement then
                        updateColor(input)
                    end
                end))

                local function Toggle(state)
                    if state == toggled then return end
                    toggled = state
                    
                    local targetDrawerHeight = toggled and 135 or 0
                    local targetFrameHeight = toggled and 155 or 20
                    
                    if toggled then
                        Drawer.Visible = true
                    end
                    
                    tween(Drawer, 0.15, { Size = UDim2.new(1, 0, 0, targetDrawerHeight) })
                    tween(ColorpickerFrame, 0.15, { Size = UDim2.new(1, 0, 0, targetFrameHeight) })

                    if not toggled then
                        task.delay(0.15, function()
                            if not toggled then Drawer.Visible = false end
                        end)
                    end
                end

                PreviewButton.MouseEnter:Connect(function()
                    tween(PreviewButton, 0.15, { BorderColor3 = Theme.AccentStart })
                end)
                PreviewButton.MouseLeave:Connect(function()
                    tween(PreviewButton, 0.15, { BorderColor3 = Theme.LightOutline })
                end)

                PreviewButton.MouseButton1Click:Connect(function()
                    Toggle(not toggled)
                end)

                CloseButton.MouseButton1Click:Connect(function()
                    Toggle(false)
                end)

                local control = {}
                function control.Set(color) activeColor = color; UpdateVisuals(); if options.Callback then options.Callback(activeColor) end end
                function control.Get() return activeColor end

                if options.Name then
                    Library.Registry[options.Name] = control
                end

                return control
            end

            function Group:CreateDropdown(options)
                local DropdownFrame = Instance.new("Frame")
                DropdownFrame.Size = UDim2.new(1, 0, 0, 35)
                DropdownFrame.BackgroundTransparency = 1
                DropdownFrame.Parent = GroupContainer

                local DropdownLabel = Instance.new("TextLabel")
                DropdownLabel.Size = UDim2.new(1, 0, 0, 15)
                DropdownLabel.BackgroundTransparency = 1
                DropdownLabel.Text = options.Name
                DropdownLabel.TextColor3 = Theme.TextDark
                DropdownLabel.Font = Theme.Font
                DropdownLabel.TextSize = Theme.TextSize
                DropdownLabel.TextXAlignment = Enum.TextXAlignment.Left
                DropdownLabel.Parent = DropdownFrame

                local SelectorButton = Instance.new("TextButton")
                SelectorButton.Size = UDim2.new(1, -4, 0, 18)
                SelectorButton.Position = UDim2.new(0, 2, 0, 17)
                SelectorButton.BackgroundColor3 = Theme.ElementBackground
                SelectorButton.BorderColor3 = Theme.LightOutline
                SelectorButton.Text = "  " .. (options.Default or options.List[1] or "Select...")
                SelectorButton.TextColor3 = Theme.Text
                SelectorButton.Font = Theme.Font
                SelectorButton.TextSize = Theme.TextSize
                SelectorButton.TextXAlignment = Enum.TextXAlignment.Left
                SelectorButton.Parent = DropdownFrame

                local SelectorStroke = Instance.new("UIStroke")
                SelectorStroke.Thickness = 1
                SelectorStroke.Color = Theme.DarkOutline
                SelectorStroke.Parent = SelectorButton

                local ArrowLabel = Instance.new("TextLabel")
                ArrowLabel.Size = UDim2.new(0, 15, 1, 0)
                ArrowLabel.Position = UDim2.new(1, -18, 0, 0)
                ArrowLabel.BackgroundTransparency = 1
                ArrowLabel.Text = "▼"
                ArrowLabel.TextColor3 = Theme.TextDark
                ArrowLabel.Font = Theme.Font
                ArrowLabel.TextSize = 10
                ArrowLabel.TextXAlignment = Enum.TextXAlignment.Right
                ArrowLabel.Parent = SelectorButton

                local Drawer = Instance.new("ScrollingFrame")
                Drawer.Size = UDim2.new(1, -4, 0, 0)
                Drawer.Position = UDim2.new(0, 2, 0, 36)
                Drawer.BackgroundColor3 = Theme.Background
                Drawer.BorderColor3 = Theme.DarkOutline
                Drawer.ScrollBarThickness = 2
                Drawer.ScrollBarImageColor3 = Theme.AccentStart
                Drawer.ZIndex = 15
                Drawer.Visible = false
                Drawer.Parent = DropdownFrame
                table.insert(Library.ThemeElements, Drawer)

                local DrawerStroke = Instance.new("UIStroke")
                DrawerStroke.Thickness = 1
                DrawerStroke.Color = Theme.DarkOutline
                DrawerStroke.Parent = Drawer

                local DrawerLayout = Instance.new("UIListLayout")
                DrawerLayout.SortOrder = Enum.SortOrder.LayoutOrder
                DrawerLayout.Parent = Drawer

                local toggled = false
                local currentSelection = options.Default or options.List[1] or ""

                local function selectOption(val)
                    currentSelection = val
                    SelectorButton.Text = "  " .. val
                    if options.Callback then options.Callback(val) end
                    
                    toggled = false
                    tween(Drawer, 0.15, { Size = UDim2.new(1, -4, 0, 0) })
                    tween(DropdownFrame, 0.15, { Size = UDim2.new(1, 0, 0, 35) })
                    task.delay(0.15, function()
                        if not toggled then Drawer.Visible = false end
                    end)
                end

                for i, item in ipairs(options.List) do
                    local ItemBtn = Instance.new("TextButton")
                    ItemBtn.Size = UDim2.new(1, 0, 0, 18)
                    ItemBtn.BackgroundColor3 = Theme.ElementBackground
                    ItemBtn.BorderSizePixel = 0
                    ItemBtn.Text = "  " .. item
                    ItemBtn.TextColor3 = Theme.TextDark
                    ItemBtn.Font = Theme.Font
                    ItemBtn.TextSize = Theme.TextSize
                    ItemBtn.TextXAlignment = Enum.TextXAlignment.Left
                    ItemBtn.LayoutOrder = i
                    ItemBtn.ZIndex = 16
                    ItemBtn.Parent = Drawer

                    ItemBtn.MouseEnter:Connect(function()
                        tween(ItemBtn, 0.15, { BackgroundColor3 = Theme.DarkOutline, TextColor3 = Theme.AccentEnd })
                    end)
                    ItemBtn.MouseLeave:Connect(function()
                        tween(ItemBtn, 0.15, { BackgroundColor3 = Theme.ElementBackground, TextColor3 = Theme.TextDark })
                    end)
                    ItemBtn.MouseButton1Click:Connect(function()
                        selectOption(item)
                    end)
                end

                local function Toggle(state)
                    if state == toggled then return end
                    toggled = state
                    
                    local maxItemsVisible = math.min(6, #options.List)
                    local targetDrawerHeight = toggled and (maxItemsVisible * 18 + 2) or 0
                    local targetFrameHeight = toggled and (35 + targetDrawerHeight + 5) or 35
                    
                    if toggled then
                        Drawer.Size = UDim2.new(1, -4, 0, 0)
                        Drawer.CanvasSize = UDim2.new(0, 0, 0, #options.List * 18)
                        Drawer.Visible = true
                    end
                    
                    tween(Drawer, 0.15, { Size = UDim2.new(1, -4, 0, targetDrawerHeight) })
                    tween(DropdownFrame, 0.15, { Size = UDim2.new(1, 0, 0, targetFrameHeight) })

                    if not toggled then
                        task.delay(0.15, function()
                            if not toggled then Drawer.Visible = false end
                        end)
                    end
                end

                SelectorButton.MouseEnter:Connect(function()
                    tween(SelectorButton, 0.15, { BorderColor3 = Theme.AccentStart })
                end)
                SelectorButton.MouseLeave:Connect(function()
                    tween(SelectorButton, 0.15, { BorderColor3 = Theme.LightOutline })
                end)

                SelectorButton.MouseButton1Click:Connect(function()
                    Toggle(not toggled)
                end)

                local control = {}
                function control.Set(val) selectOption(val) end
                function control.Get() return currentSelection end

                if options.Name then
                    Library.Registry[options.Name] = control
                end

                return control
            end

            return Group
        end
        
        return Tab
    end

    return Window
end

return Library
