return function(State, Services)
    local module = {}
    
    local function createCircle()
        local circle = Drawing.new("Circle")
        circle.Color = Color3.fromRGB(255, 255, 255)
        circle.Thickness = 1
        circle.Transparency = 1
        circle.NumSides = 64
        circle.Filled = false
        circle.Visible = false
        return circle
    end

    if not State.FOVCircle then State.FOVCircle = createCircle() end
    if not State.SilentAimFOVCircle then State.SilentAimFOVCircle = createCircle() end

    function module.update()
        local mousePos = Services.UserInputService:GetMouseLocation()
        
        local fovVisible = State.FOVEnabled and State.AimbotEnabled
        local fovC = Color3.fromRGB(State.FOVR or 115, State.FOVG or 120, State.FOVB or 255)
        if State.FOVCircle then
            State.FOVCircle.Position = mousePos
            State.FOVCircle.Radius = State.FOVRadius or 150
            State.FOVCircle.Color = fovC
            State.FOVCircle.Thickness = State.FOVThickness or 1
            State.FOVCircle.Visible = fovVisible
        end

        local silentFovVisible = State.SilentAimFOVEnabled and State.SilentAimEnabled
        local silentFovC = Color3.fromRGB(State.SilentAimFOVR or 255, State.SilentAimFOVG or 100, State.SilentAimFOVB or 100)
        if State.SilentAimFOVCircle then
            State.SilentAimFOVCircle.Position = mousePos
            State.SilentAimFOVCircle.Radius = State.SilentAimFOVRadius or 150
            State.SilentAimFOVCircle.Color = silentFovC
            State.SilentAimFOVCircle.Thickness = State.SilentAimFOVThickness or 1
            State.SilentAimFOVCircle.Visible = silentFovVisible
        end
    end
    
    function module.destroy()
        if State.FOVCircle then State.FOVCircle:Remove(); State.FOVCircle = nil end
        if State.SilentAimFOVCircle then State.SilentAimFOVCircle:Remove(); State.SilentAimFOVCircle = nil end
    end

    return module
end
