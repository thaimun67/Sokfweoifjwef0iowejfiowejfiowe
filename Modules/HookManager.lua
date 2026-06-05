local BASE_URL = "https://raw.githubusercontent.com/thaimun67/Sokfweoifjwef0iowejfiowejfiowe/main/Modules/"
local function LoadModule(name)
    local url = BASE_URL .. name .. ".lua?t=" .. tostring(tick())
    local ok, src = pcall(function() return game:HttpGet(url) end)
    if ok and src then
        local fn = loadstring(src)
        if fn then return fn() end
    end
    return nil
end

return function(State, Services)
    local module = {}
    local InfiniteAmmo = LoadModule("InfiniteAmmo")(State, Services)
    local NoSpread = LoadModule("NoSpread")(State, Services)
    local SilentAim = LoadModule("SilentAim")(State, Services)
    
    local hooked = false
    function module.startHook()
        if hooked then return end
        hooked = true
        
        task.spawn(function()
            local HandlerClass = nil
            local targetFunc = nil
            local originalFireHitscanShot = nil

            local function getFunctionName(f)
                local okName, name = pcall(function() return debug.info(f, "n") end)
                if okName and name and name ~= "" then return name end
                local okInfo, info = pcall(function() return debug.getinfo(f) end)
                if okInfo and info and info.name and info.name ~= "" then return info.name end
                return nil
            end

            local success, res = pcall(function()
                return require(game:GetService("ReplicatedStorage"):WaitForChild("Classes"):WaitForChild("Handler"))
            end)
            if success and type(res) == "table" then
                HandlerClass = res
                targetFunc = res.fireHitscanShot
            end

            if (not targetFunc or not HandlerClass) and getgc then
                for _, v in ipairs(getgc(true)) do
                    if type(v) == "function" then
                        if getFunctionName(v) == "fireHitscanShot" then targetFunc = v break end
                    end
                end
            end

            if (not targetFunc or not HandlerClass) and getgc then
                for _, v in ipairs(getgc(true)) do
                    if type(v) == "table" then
                        local hasRaw = false
                        pcall(function() if rawget(v, "fireHitscanShot") or rawget(v, "shoot") then hasRaw = true end end)
                        local hasNormal = false
                        if not hasRaw then pcall(function() if v.fireHitscanShot and v.equip and v.new then hasNormal = true end end) end
                        if hasRaw or hasNormal then
                            HandlerClass = v
                            if not targetFunc then pcall(function() targetFunc = v.fireHitscanShot end) end
                            break
                        end
                    end
                end
            end

            if not targetFunc and not HandlerClass and getgc and debug.getupvalue then
                for _, obj in ipairs(getgc(true)) do
                    if type(obj) == "function" then
                        pcall(function()
                            local i = 1
                            while true do
                                local name, val = debug.getupvalue(obj, i)
                                if not name then break end
                                if type(val) == "table" and (rawget(val, "fireHitscanShot") or val.fireHitscanShot) then
                                    HandlerClass = val
                                    targetFunc = val.fireHitscanShot
                                    break
                                end
                                i = i + 1
                            end
                        end)
                        if HandlerClass then break end
                    end
                end
            end

            if not targetFunc and not HandlerClass then return end

            local function hookedFireHitscanShot(self, ...)
                local args = {...}
                local gunModule = args[1]
                
                if InfiniteAmmo then InfiniteAmmo.process(self, gunModule) end
                if NoSpread then NoSpread.process(gunModule) end
                
                local shouldRedirect, proxyCam = false, nil
                if SilentAim then
                    shouldRedirect, proxyCam = SilentAim.process(gunModule)
                end
                
                if shouldRedirect and proxyCam then
                    local oldCam = self.camera
                    self.camera = proxyCam
                    local result = originalFireHitscanShot(self, unpack(args))
                    self.camera = oldCam
                    return result
                end
                
                return originalFireHitscanShot(self, unpack(args))
            end

            if targetFunc and hookfunction then
                local success, ret = pcall(function() return hookfunction(targetFunc, hookedFireHitscanShot) end)
                if success and ret then originalFireHitscanShot = ret end
            end

            if not originalFireHitscanShot and HandlerClass then
                originalFireHitscanShot = HandlerClass.__originalFireHitscanShot or HandlerClass.fireHitscanShot
                HandlerClass.__originalFireHitscanShot = originalFireHitscanShot
                if originalFireHitscanShot then HandlerClass.fireHitscanShot = hookedFireHitscanShot end
            end
        end)
    end
    return module
end
