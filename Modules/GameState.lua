return function(State, Services)
    local Players = Services.Players
    local LocalPlayer = Services.LocalPlayer
    local module = {}

    -- Helper to safely require modules across execution contexts
    local function safeRequire(moduleInstance)
        local success, result = pcall(function()
            return require(moduleInstance)
        end)
        if success and result then return result end
        local success2, result2 = pcall(function()
            if getrenv and getrenv().require then
                return getrenv().require(moduleInstance)
            end
        end)
        if success2 and result2 then return result2 end
        return nil
    end
    module.safeRequire = safeRequire

    -- Helper to scan garbage collector for active game module tables
    local function findModuleViaGC(requiredMethods)
        if not getgc then return nil end
        for _, obj in ipairs(getgc(true)) do
            if type(obj) == "table" then
                local matches = true
                for _, method in ipairs(requiredMethods) do
                    if not rawget(obj, method) then
                        matches = false
                        break
                    end
                end
                if matches then
                    return obj
                end
            end
        end
        return nil
    end

    local function findGameStateViaUpvalues()
        if not getgc or not debug.getupvalue then return nil end
        for _, obj in ipairs(getgc(true)) do
            if type(obj) == "function" then
                local success, result = pcall(function()
                    local i = 1
                    while true do
                        local name, val = debug.getupvalue(obj, i)
                        if not name then break end
                        if type(val) == "table" and rawget(val, "isTeammate") and rawget(val, "subscribeTeamState") then
                            return val
                        end
                        i = i + 1
                    end
                end)
                if success and result then
                    return result
                end
            end
        end
        return nil
    end

    function module.getGameStateModule()
        local fromUpvalue = findGameStateViaUpvalues()
        if fromUpvalue then return fromUpvalue end
        local fromGC = findModuleViaGC({"subscribeAmmo", "setReload", "isTeammate"})
        if fromGC then return fromGC end
        return nil
    end

    local function findReloadManagerViaUpvalues()
        if not getgc or not debug.getupvalue then return nil end
        for _, obj in ipairs(getgc(true)) do
            if type(obj) == "function" then
                local success, result = pcall(function()
                    local i = 1
                    while true do
                        local name, val = debug.getupvalue(obj, i)
                        if not name then break end
                        if type(val) == "table" and rawget(val, "startReload") and rawget(val, "forceComplete") then
                            return val
                        end
                        i = i + 1
                    end
                end)
                if success and result then
                    return result
                end
            end
        end
        return nil
    end

    function module.getReloadManagerModule()
        local fromUpvalue = findReloadManagerViaUpvalues()
        if fromUpvalue then return fromUpvalue end
        local fromGC = findModuleViaGC({"startReload", "cancelReload", "forceComplete"})
        if fromGC then return fromGC end
        return nil
    end

    -- GameState instance (resolved dynamically)
    local GameState = module.getGameStateModule()
    print("[Quantix Debug] GameState found:", GameState ~= nil)
    if GameState then
        pcall(function()
            local ts = GameState.getTeamState and GameState.getTeamState()
            if ts then
                print("[Quantix Debug] isTeamMode:", ts.isTeamMode, "localPlayerTeam:", ts.localPlayerTeam)
            else
                print("[Quantix Debug] getTeamState returned nil")
            end
        end)
    end

    local lastGameStateLookup = 0
    local function lookupGameState()
        local now = tick()
        if now - lastGameStateLookup < 3 then return end
        lastGameStateLookup = now
        GameState = module.getGameStateModule()
        if GameState then
            print("[Quantix] GameState resolved dynamically!")
        end
    end

    function module.isTeammate(entity)
        if not LocalPlayer or not entity then return false end
        local char = entity:IsA("Player") and entity.Character or entity
        if not char then return false end
        if char == LocalPlayer.Character then return true end

        local head = char:FindFirstChild("Head")
        if head and head:FindFirstChild("TeammateNametag") then
            return true
        end

        local highlight = char:FindFirstChildOfClass("Highlight")
        if highlight and highlight.OutlineColor == Color3.fromRGB(0, 255, 100) then
            return true
        end

        local player = entity:IsA("Player") and entity or Players:GetPlayerFromCharacter(char)
        if player and player ~= LocalPlayer then
            if LocalPlayer.Team and player.Team and LocalPlayer.Team == player.Team then
                return true
            end
        end

        if not GameState then
            lookupGameState()
        end

        if GameState then
            local success, result = pcall(function()
                local botId = char:GetAttribute("BotUniqueId")
                if botId then
                    return GameState.isTeammate(botId)
                end
                if player then
                    return GameState.isTeammate(player.UserId)
                end
                return false
            end)
            if success then return result end
        end

        return false
    end

    -- Team Check caching
    local TeamCache = {}
    local lastCacheClear = 0
    local TEAM_CACHE_TTL = 0.25
    function module.getCachedTeammateStatus(entity)
        local now = tick()
        if now - lastCacheClear > TEAM_CACHE_TTL then
            table.clear(TeamCache)
            lastCacheClear = now
        end
        if TeamCache[entity] ~= nil then
            return TeamCache[entity]
        end
        local status = module.isTeammate(entity)
        TeamCache[entity] = status
        return status
    end

    return module
end
