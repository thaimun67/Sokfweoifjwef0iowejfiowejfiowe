return function(State, Services)
    local module = {}
    local RunService = Services.RunService
    local CoreGui = Services.CoreGui

    local function createCircle(name)
        local circle = {}
        local drawingCircle
        local fallbackCircle

        local ok = pcall(function()
            if Drawing and Drawing.new then
                drawingCircle = Drawing.new("Circle")
                drawingCircle.Thickness = 1
                drawingCircle.NumSides = 64
                drawingCircle.Radius = 150
                drawingCircle.Filled = false
                drawingCircle.Visible = false
                drawingCircle.Color = Color3.fromRGB(255, 255, 255)
            end
        end)

        if ok and drawingCircle then
            circle.Type = "Drawing"
            circle.Obj = drawingCircle
        else
            -- GUI Fallback
            local fovGui = Instance.new("ScreenGui")
            fovGui.Name = "Quantix" .. name .. "FOV"
            fovGui.ResetOnSpawn = false
            pcall(function() fovGui.Interactable = false end)
            
            -- Parent safely
            fovGui.Parent = RunService:IsStudio() and game.Players.LocalPlayer:WaitForChild("PlayerGui") or CoreGui
            
            local fovFrame = Instance.new("Frame")
            fovFrame.BackgroundTransparency = 1
            fovFrame.AnchorPoint = Vector2.new(0.5, 0.5)
            fovFrame.Size = UDim2.new(0, 300, 0, 300)
            fovFrame.Visible = false
            fovFrame.Active = false
            fovFrame.Selectable = false
            pcall(function() fovFrame.Interactable = false end)
            fovFrame.Parent = fovGui
            
            local stroke = Instance.new("UIStroke")
            stroke.Thickness = 1
            stroke.Color = Color3.fromRGB(255, 255, 255)
            stroke.Parent = fovFrame
            
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0.5, 0)
            corner.Parent = fovFrame
            
            circle.Type = "Gui"
            circle.Gui = fovGui
            circle.Frame = fovFrame
            circle.Stroke = stroke
        end

        function circle:Update(pos, radius, visible, color, thickness)
            if self.Type == "Drawing" then
                self.Obj.Position = pos
                self.Obj.Radius = radius
                self.Obj.Visible = visible
                self.Obj.Color = color
                self.Obj.Thickness = thickness or 1
            else
                self.Frame.Position = UDim2.new(0, pos.X, 0, pos.Y)
                self.Frame.Size = UDim2.new(0, radius * 2, 0, radius * 2)
                self.Frame.Visible = visible
                self.Stroke.Color = color
                self.Stroke.Thickness = thickness or 1
            end
        end

        function circle:Destroy()
            if self.Type == "Drawing" then
                pcall(function() self.Obj:Remove() end)
            else
                pcall(function() self.Gui:Destroy() end)
            end
        end

        return circle
    end

    if not State.FOVCircle then
        State.FOVCircle = createCircle("Aimbot")
    end
    if not State.SilentAimFOVCircle then
        State.SilentAimFOVCircle = createCircle("SilentAim")
    end

    function module.update()
        local mousePos = Services.UserInputService:GetMouseLocation()
        
        local fovVisible = State.FOVEnabled and State.AimbotEnabled
        local fovC = Color3.fromRGB(State.FOVR or 115, State.FOVG or 120, State.FOVB or 255)
        if State.FOVCircle then
            pcall(function()
                State.FOVCircle:Update(mousePos, State.FOVRadius or 150, fovVisible, fovC, State.FOVThickness or 1)
            end)
        end

        local silentFovVisible = State.SilentAimFOVEnabled and State.SilentAimEnabled
        local silentFovC = Color3.fromRGB(State.SilentAimFOVR or 255, State.SilentAimFOVG or 100, State.SilentAimFOVB or 100)
        if State.SilentAimFOVCircle then
            pcall(function()
                State.SilentAimFOVCircle:Update(mousePos, State.SilentAimFOVRadius or 150, silentFovVisible, silentFovC, State.SilentAimFOVThickness or 1)
            end)
        end
    end
    
    function module.destroy()
        if State.FOVCircle then
            pcall(function() State.FOVCircle:Destroy() end)
            State.FOVCircle = nil
        end
        if State.SilentAimFOVCircle then
            pcall(function() State.SilentAimFOVCircle:Destroy() end)
            State.SilentAimFOVCircle = nil
        end
    end

    return module
end
