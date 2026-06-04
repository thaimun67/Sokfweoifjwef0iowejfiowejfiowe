return function(State, Services)
    local Lighting = game:GetService("Lighting")
    local module = {}

    -- Camera FOV
    if State.CustomFOVEnabled == nil then State.CustomFOVEnabled = false end
    if State.CustomFOVValue == nil then State.CustomFOVValue = 90 end

    function module.applyFOV()
        pcall(function()
            local activeCam = workspace.CurrentCamera
            if activeCam then
                activeCam.FieldOfView = State.CustomFOVValue
            end
        end)
        pcall(function()
            if State.CamControllerInst then
                State.CamControllerInst.baseFOV = State.CustomFOVValue
                if rawget(State.CamControllerInst, "_apply") then
                    State.CamControllerInst:_apply()
                elseif getmetatable(State.CamControllerInst) and getmetatable(State.CamControllerInst)._apply then
                    getmetatable(State.CamControllerInst)._apply(State.CamControllerInst)
                end
            end
        end)
    end

    function module.restoreFOV()
        pcall(function()
            if State.CamControllerInst then
                local ReplicatedStorage = game:GetService("ReplicatedStorage")
                local SettingsManager = require(ReplicatedStorage.Classes.Utility.SettingsManager)
                local defaultFOV = SettingsManager and SettingsManager:get("video", "fov") or 80
                State.CamControllerInst.baseFOV = defaultFOV
                if rawget(State.CamControllerInst, "_apply") then
                    State.CamControllerInst:_apply()
                elseif getmetatable(State.CamControllerInst) and getmetatable(State.CamControllerInst)._apply then
                    getmetatable(State.CamControllerInst)._apply(State.CamControllerInst)
                end
            else
                local activeCam = workspace.CurrentCamera
                if activeCam then
                    activeCam.FieldOfView = 80
                end
            end
        end)
    end

    -- Custom Skybox
    if State.CustomSkyboxEnabled == nil then State.CustomSkyboxEnabled = false end
    if State.CurrentSkyboxName == nil then State.CurrentSkyboxName = "space" end
    local OriginalSkybox = nil
    local CurrentSky = nil

    local SkyboxPresets = {
        ["space"] = {
            Bk = "rbxassetid://159454299", Dn = "rbxassetid://159454296",
            Ft = "rbxassetid://159454293", Lf = "rbxassetid://159454286",
            Rt = "rbxassetid://159454300", Up = "rbxassetid://159454288",
        },
        ["sunset"] = {
            Bk = "rbxassetid://372310881", Dn = "rbxassetid://372310881",
            Ft = "rbxassetid://372310881", Lf = "rbxassetid://372310881",
            Rt = "rbxassetid://372310881", Up = "rbxassetid://372310881",
        },
        ["night"] = {
            Bk = "rbxassetid://6444884337", Dn = "rbxassetid://6444884337",
            Ft = "rbxassetid://6444884337", Lf = "rbxassetid://6444884337",
            Rt = "rbxassetid://6444884337", Up = "rbxassetid://6444884337",
        },
        ["neon city"] = {
            Bk = "rbxassetid://6197721980", Dn = "rbxassetid://6197721980",
            Ft = "rbxassetid://6197721980", Lf = "rbxassetid://6197721980",
            Rt = "rbxassetid://6197721980", Up = "rbxassetid://6197721980",
        },
        ["synthwave"] = {
            Bk = "rbxassetid://1417494030", Dn = "rbxassetid://1417494030",
            Ft = "rbxassetid://1417494030", Lf = "rbxassetid://1417494030",
            Rt = "rbxassetid://1417494030", Up = "rbxassetid://1417494030",
        },
        ["purple nebula"] = {
            Bk = "rbxassetid://1045964490", Dn = "rbxassetid://1045964490",
            Ft = "rbxassetid://1045964490", Lf = "rbxassetid://1045964490",
            Rt = "rbxassetid://1045964490", Up = "rbxassetid://1045964490",
        },
        ["blood moon"] = {
            Bk = "rbxassetid://1391515286", Dn = "rbxassetid://1391515286",
            Ft = "rbxassetid://1391515286", Lf = "rbxassetid://1391515286",
            Rt = "rbxassetid://1391515286", Up = "rbxassetid://1391515286",
        },
        ["daylight"] = {
            Bk = "rbxassetid://600886082", Dn = "rbxassetid://600886082",
            Ft = "rbxassetid://600886082", Lf = "rbxassetid://600886082",
            Rt = "rbxassetid://600886082", Up = "rbxassetid://600886082",
        },
    }

    local function saveOriginalSky()
        if OriginalSkybox then return end
        local existingSky = Lighting:FindFirstChildOfClass("Sky")
        if existingSky then
            OriginalSkybox = {
                Bk = existingSky.SkyboxBk, Dn = existingSky.SkyboxDn,
                Ft = existingSky.SkyboxFt, Lf = existingSky.SkyboxLf,
                Rt = existingSky.SkyboxRt, Up = existingSky.SkyboxUp,
            }
        else
            OriginalSkybox = false
        end
    end

    function module.applySkybox(name)
        local preset = SkyboxPresets[name]
        if not preset then return end
        pcall(function()
            saveOriginalSky()
            for _, child in ipairs(Lighting:GetChildren()) do
                if child:IsA("Sky") then child:Destroy() end
            end
            local sky = Instance.new("Sky")
            sky.SkyboxBk = preset.Bk
            sky.SkyboxDn = preset.Dn
            sky.SkyboxFt = preset.Ft
            sky.SkyboxLf = preset.Lf
            sky.SkyboxRt = preset.Rt
            sky.SkyboxUp = preset.Up
            sky.Parent = Lighting
            CurrentSky = sky
        end)
    end

    function module.restoreSkybox()
        pcall(function()
            if CurrentSky then CurrentSky:Destroy() end
            CurrentSky = nil
            if OriginalSkybox then
                local sky = Instance.new("Sky")
                sky.SkyboxBk = OriginalSkybox.Bk
                sky.SkyboxDn = OriginalSkybox.Dn
                sky.SkyboxFt = OriginalSkybox.Ft
                sky.SkyboxLf = OriginalSkybox.Lf
                sky.SkyboxRt = OriginalSkybox.Rt
                sky.SkyboxUp = OriginalSkybox.Up
                sky.Parent = Lighting
            end
            OriginalSkybox = nil
        end)
    end

    -- Bullet Traces
    if State.BulletTracesEnabled == nil then State.BulletTracesEnabled = false end
    if State.BulletTraceThickness == nil then State.BulletTraceThickness = 0.02 end
    if State.BulletTraceDuration == nil then State.BulletTraceDuration = 1.0 end
    if State.BulletTraceColorR == nil then State.BulletTraceColorR = 115; State.BulletTraceColorG = 120; State.BulletTraceColorB = 255 end

    local TweenService = Services.TweenService or game:GetService("TweenService")

    function module.drawTrace(pA, pB)
        if not State.BulletTracesEnabled then return end
        local distance = (pA - pB).Magnitude
        if distance < 0.1 then return end

        local traceColor = Color3.fromRGB(State.BulletTraceColorR, State.BulletTraceColorG, State.BulletTraceColorB)
        local thickness = State.BulletTraceThickness or 0.02

        local part = Instance.new("Part")
        part.Name = "QuantixBulletTrace"
        part.Material = Enum.Material.Neon
        part.Color = traceColor
        part.Size = Vector3.new(thickness, thickness, distance)
        part.CFrame = CFrame.lookAt(pA:Lerp(pB, 0.5), pB)
        part.Anchored = true
        part.CanCollide = false
        part.CanTouch = false
        part.CanQuery = false
        part.CastShadow = false
        part.Parent = workspace.CurrentCamera or workspace

        local tweenInfo = TweenInfo.new(State.BulletTraceDuration or 1, Enum.EasingStyle.Linear)
        local tween = TweenService:Create(part, tweenInfo, {Transparency = 1})
        tween:Play()
        tween.Completed:Connect(function()
            part:Destroy()
        end)
    end

    local hookStarted = false
    function module.startBulletTracesHook()
        if hookStarted then return end
        hookStarted = true

        task.spawn(function()
            pcall(function()
                local ReplicatedStorage = game:GetService("ReplicatedStorage")
                local Classes = ReplicatedStorage:WaitForChild("Classes", 5)
                if not Classes then return end
                local Effects = Classes:WaitForChild("Effects", 5)
                if not Effects then return end
                local TracerModule = Effects:WaitForChild("Tracer", 5)
                if not TracerModule then return end

                local TracerClass = require(TracerModule)
                if type(TracerClass) ~= "table" then return end

                -- Save the true original functions to prevent double wrapping / recursion when re-injecting
                local originalFireBulletTracer = TracerClass.__originalFireBulletTracer or TracerClass.fireBulletTracer
                TracerClass.__originalFireBulletTracer = originalFireBulletTracer

                local originalFireSniperTracer = TracerClass.__originalFireSniperTracer or TracerClass.fireSniperTracer
                TracerClass.__originalFireSniperTracer = originalFireSniperTracer

                local originalFire = TracerClass.__originalFire or TracerClass.fire
                TracerClass.__originalFire = originalFire

                -- Hook fireBulletTracer
                if originalFireBulletTracer then
                    TracerClass.fireBulletTracer = function(self, startPos, endPos, p4, color)
                        if State.BulletTracesEnabled then
                            task.spawn(function()
                                pcall(function()
                                    module.drawTrace(startPos, endPos)
                                end)
                            end)
                        end
                        return originalFireBulletTracer(self, startPos, endPos, p4, color)
                    end
                end

                -- Hook fireSniperTracer
                if originalFireSniperTracer then
                    TracerClass.fireSniperTracer = function(self, startPos, endPos, p4, color)
                        if State.BulletTracesEnabled then
                            task.spawn(function()
                                pcall(function()
                                    module.drawTrace(startPos, endPos)
                                end)
                            end)
                        end
                        return originalFireSniperTracer(self, startPos, endPos, p4, color)
                    end
                end

                -- Hook fire (lasers / beams)
                if originalFire then
                    TracerClass.fire = function(self, muzzlePart, endPos, p4)
                        if State.BulletTracesEnabled then
                            task.spawn(function()
                                pcall(function()
                                    local startPos = muzzlePart and muzzlePart.Position
                                    if startPos then
                                        module.drawTrace(startPos, endPos)
                                    end
                                end)
                            end)
                        end
                        return originalFire(self, muzzlePart, endPos, p4)
                    end
                end
            end)
        end)
    end

    return module
end
