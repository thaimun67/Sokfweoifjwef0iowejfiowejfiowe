local Library = {
    Connections = {},
    ToggleKey = Enum.KeyCode.Insert,
    OnToggle = nil
}

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

local Theme = {
    Background = Color3.fromRGB(18, 18, 20),
    Darker = Color3.fromRGB(12, 12, 14),
    DarkOutline = Color3.fromRGB(35, 35, 40),
    LightOutline = Color3.fromRGB(50, 50, 55),
    AccentStart = Color3.fromRGB(115, 120, 255), 
    AccentEnd = Color3.fromRGB(150, 150, 255),
    Text = Color3.fromRGB(220, 220, 220),
    TextDark = Color3.fromRGB(150, 150, 150),
    ElementBackground = Color3.fromRGB(25, 25, 30),
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

function Library:CreateWindow(options)
    local titleText = options.Title or "Quantix dev access | fps strafe"
    
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "QuantixUI"
    ScreenGui.Parent = RunService:IsStudio() and game.Players.LocalPlayer:WaitForChild("PlayerGui") or CoreGui

    -- Glow frame (placed behind MainFrame to look like a shadow drop/outer glow)
    local GlowFrame = Instance.new("Frame")
    GlowFrame.Name = "Glow"
    GlowFrame.Size = UDim2.new(0, 562, 0, 462)
    GlowFrame.Position = UDim2.new(0.5, -281, 0.5, -231)
    GlowFrame.BackgroundColor3 = Theme.Background
    GlowFrame.BackgroundTransparency = 0.65
    GlowFrame.BorderSizePixel = 0
    GlowFrame.Parent = ScreenGui
    
    local GlowCorner = Instance.new("UICorner")
    GlowCorner.CornerRadius = UDim.new(0, 8)
    GlowCorner.Parent = GlowFrame
    
    local GlowStroke = Instance.new("UIStroke")
    GlowStroke.Thickness = 6
    GlowStroke.Color = Theme.AccentStart
    GlowStroke.Parent = GlowFrame
    
    local GlowGradient = Instance.new("UIGradient")
    GlowGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.AccentStart),
        ColorSequenceKeypoint.new(1, Theme.AccentEnd)
    })
    GlowGradient.Parent = GlowStroke

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "Main"
    MainFrame.Size = UDim2.new(0, 550, 0, 450)
    MainFrame.Position = UDim2.new(0.5, -275, 0.5, -225)
    MainFrame.BackgroundColor3 = Theme.Background
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui

    -- Sync glow position and visibility
    local function updateGlowPosition()
        GlowFrame.Position = UDim2.new(MainFrame.Position.X.Scale, MainFrame.Position.X.Offset - 6, MainFrame.Position.Y.Scale, MainFrame.Position.Y.Offset - 6)
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
    table.insert(Library.Connections, UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end))
    table.insert(Library.Connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end))

    -- Aesthetic Outer Border
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
    Library.Window = Window

    table.insert(Library.Connections, UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and (input.KeyCode == Library.ToggleKey or input.UserInputType == Library.ToggleKey) then
            Window.Main.Visible = not Window.Main.Visible
            if Library.OnToggle then pcall(function() Library.OnToggle(Window.Main.Visible) end) end
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
                
                Update()
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

                local SliderFill = Instance.new("Frame")
                SliderFill.Size = UDim2.new(0, 0, 1, 0)
                SliderFill.BackgroundColor3 = Theme.AccentStart
                SliderFill.BorderSizePixel = 0
                SliderFill.Parent = SliderBack

                local FillGradient = Instance.new("UIGradient")
                FillGradient.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Theme.AccentStart),
                    ColorSequenceKeypoint.new(1, Theme.AccentEnd)
                })
                FillGradient.Parent = SliderFill

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

                local function Update(input)
                    local percent = math.clamp((input.Position.X - SliderBack.AbsolutePosition.X) / SliderBack.AbsoluteSize.X, 0, 1)
                    current = math.floor(min + (max - min) * percent)
                    SliderFill.Size = UDim2.new(percent, 0, 1, 0)
                    ValueLabel.Text = current .. "/" .. max
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
                        Update(input)
                    end
                end)
                SliderBack.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end
                end)
                table.insert(Library.Connections, UserInputService.InputChanged:Connect(function(input)
                    if sliding and input.UserInputType == Enum.UserInputType.MouseMovement then
                        Update(input)
                    end
                end))

                local defaultPercent = (current - min) / (max - min)
                SliderFill.Size = UDim2.new(defaultPercent, 0, 1, 0)
                ValueLabel.Text = current .. "/" .. max
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
                
                local previewCorner = Instance.new("UICorner")
                previewCorner.CornerRadius = UDim.new(0, 2)
                previewCorner.Parent = PreviewButton

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

                local boxCorner = Instance.new("UICorner")
                boxCorner.CornerRadius = UDim.new(0, 4)
                boxCorner.Parent = CurrentColorBox

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

                local closeCorner = Instance.new("UICorner")
                closeCorner.CornerRadius = UDim.new(0, 4)
                closeCorner.Parent = CloseButton

                local Spectrum = Instance.new("ImageButton")
                Spectrum.Size = UDim2.new(1, -4, 0, 100)
                Spectrum.Position = UDim2.new(0, 2, 0, 5)
                Spectrum.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Spectrum.BackgroundTransparency = 0
                Spectrum.Image = ""
                Spectrum.BorderSizePixel = 0
                Spectrum.ZIndex = 10
                Spectrum.Parent = Drawer
                
                local spectrumCorner = Instance.new("UICorner")
                spectrumCorner.CornerRadius = UDim.new(0, 4)
                spectrumCorner.Parent = Spectrum

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
                
                local overlayCorner = Instance.new("UICorner")
                overlayCorner.CornerRadius = UDim.new(0, 4)
                overlayCorner.Parent = Overlay

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
                
                local indicatorCorner = Instance.new("UICorner")
                indicatorCorner.CornerRadius = UDim.new(0.5, 0)
                indicatorCorner.Parent = Indicator
                
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
            end

            return Group
        end
        
        return Tab
    end

    return Window
end

return Library
