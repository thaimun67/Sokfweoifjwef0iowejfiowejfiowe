return function(State, Services)
    local module = {}

    if State.NoRecoilEnabled == nil then State.NoRecoilEnabled = false end
    if State.RecoilInstances == nil then State.RecoilInstances = {} end
    if State.CamRecoilInstances == nil then State.CamRecoilInstances = {} end

    function module.zeroSpring(s)
        if not s then return end
        pcall(function()
            s.Position = Vector3.zero
            s.Velocity = Vector3.zero
            s.Target = Vector3.zero
        end)
    end

    local recoilHooked = false
    local camRecoilHooked = false
    local oldRecoilApply
    local oldCamRecoilApply

    function module.scanRecoilInstances()
        if not getgc then return end
        local newRC, newCR = {}, {}
        for _, val in ipairs(getgc(true)) do
            if type(val) == "table" then
                if rawget(val, "gunRecoilSpring") and rawget(val, "rotationRecoilSpring") and rawget(val, "shotTwistSpring") then
                    table.insert(newRC, val)
                    if not recoilHooked and hookfunction and type(val.applyKick) == "function" then
                        pcall(function()
                            oldRecoilApply = hookfunction(val.applyKick, function(self, ...)
                                if State.NoRecoilEnabled then return end
                                return oldRecoilApply(self, ...)
                            end)
                            recoilHooked = true
                        end)
                    end
                elseif rawget(val, "spring") and rawget(val, "config") and rawget(val, "lastAppliedRecoil") then
                    table.insert(newCR, val)
                    if not camRecoilHooked and hookfunction and type(val.applyKick) == "function" then
                        pcall(function()
                            oldCamRecoilApply = hookfunction(val.applyKick, function(self, ...)
                                if State.NoRecoilEnabled then return end
                                return oldCamRecoilApply(self, ...)
                            end)
                            camRecoilHooked = true
                        end)
                    end
                end
            end
        end
        State.RecoilInstances = newRC
        State.CamRecoilInstances = newCR
        if #newRC + #newCR > 0 then
            -- print("[Quantix] Recoil: found " .. #newRC .. " RecoilController(s), " .. #newCR .. " CameraRecoilController(s)")
        end
    end

    function module.scanCameraController()
        if State.CamControllerInst then return end
        if not getgc then return end
        for _, val in ipairs(getgc(true)) do
            if type(val) == "table"
                and rawget(val, "baseFOV") ~= nil
                and rawget(val, "baseSensitivity") ~= nil
                and rawget(val, "camera") ~= nil
            then
                State.CamControllerInst = val
                break
            end
        end
    end

    -- Apply no-recoil on a single frame
    function module.applyNoRecoil()
        if not State.NoRecoilEnabled then return end
        for _, inst in ipairs(State.RecoilInstances) do
            pcall(function()
                module.zeroSpring(inst.gunRecoilSpring)
                module.zeroSpring(inst.rotationRecoilSpring)
                module.zeroSpring(inst.shotTwistSpring)
            end)
        end
        for _, inst in ipairs(State.CamRecoilInstances) do
            pcall(function()
                module.zeroSpring(inst.spring)
                inst.lastAppliedRecoil = Vector3.zero
            end)
        end
    end

    -- Start background scanner thread
    function module.startScanner()
        task.spawn(function()
            while true do
                pcall(module.scanRecoilInstances)
                pcall(module.scanCameraController)
                task.wait(3)
            end
        end)
    end

    return module
end
