return function(State, Services)
    local module = {}
    local originalFOVs = {}

    function module.applyFOV()
        local activeCam = workspace.CurrentCamera
        if activeCam and State.CustomFOVEnabled then
            if State.CamControllerInst then
                if not originalFOVs.baseFOV then
                    originalFOVs.baseFOV = State.CamControllerInst.baseFOV
                end
                State.CamControllerInst.baseFOV = State.CustomFOVValue
                if not State.CamControllerInst.fovOverride then
                    activeCam.FieldOfView = State.CustomFOVValue
                end
            else
                if not originalFOVs.cameraFOV then
                    originalFOVs.cameraFOV = activeCam.FieldOfView
                end
                activeCam.FieldOfView = State.CustomFOVValue
            end
        end
    end

    function module.restoreFOV()
        local activeCam = workspace.CurrentCamera
        if activeCam then
            if State.CamControllerInst and originalFOVs.baseFOV then
                State.CamControllerInst.baseFOV = originalFOVs.baseFOV
                originalFOVs.baseFOV = nil
            elseif originalFOVs.cameraFOV then
                activeCam.FieldOfView = originalFOVs.cameraFOV
                originalFOVs.cameraFOV = nil
            end
        end
    end
    
    function module.update()
        if State.CustomFOVEnabled then
            pcall(module.applyFOV)
        end
    end

    return module
end
