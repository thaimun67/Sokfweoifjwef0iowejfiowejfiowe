local State = getgenv().QuantixState or {}
getgenv().QuantixState = State

-- Initialize default values if not present
-- // Custom "Quantix" UI Library with Fully Working Aimbot, ESP & Infinite Ammo \ --

if getgenv then
    if getgenv().QuantixUnload then pcall(getgenv().QuantixUnload) end
    if getgenv().AbyssUnload then pcall(getgenv().AbyssUnload) end
end

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/thaimun67/Sokfweoifjwef0iowejfiowejfiowe/main/QuantixLibrary.lua?t=" .. tostring(tick())))()

-- Storage for all runtime connections so they can be cleaned up
if State.Connections == nil then State.Connections = {} end
Library.Connections = State.Connections

-- Wait for game to load
if not game:IsLoaded() then game.Loaded:Wait() end
if State.GlobalWindow == nil then State.GlobalWindow = nil end
if State.Aiming == nil then State.Aiming = false end
if State.EspElements == nil then State.EspElements = {} end
if State.PlayerConnections == nil then State.PlayerConnections = {} end
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local function tween(object, time, propertyTable)
    local tweenInfo = TweenInfo.new(time or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local t = TweenService:Create(object, tweenInfo, propertyTable)
    t:Play()
    return t
end

-- Safely wait for LocalPlayer to load
local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do
    task.wait()
    LocalPlayer = Players.LocalPlayer
end

-- Safely wait for camera
local Camera = workspace.CurrentCamera

-- Clean up any residual drawing/instance visual elements from previous run failures
local function cleanupOldESP()
    local parent = RunService:IsStudio() and game.Players.LocalPlayer:WaitForChild("PlayerGui") or CoreGui
    for _, child in ipairs(parent:GetChildren()) do
        if child.Name == "AbyssHighlight" or child.Name == "AbyssBillboard" or child.Name == "AbyssFOV" or child.Name == "QuantixWatermark" or child.Name == "QuantixKeybinds" or child.Name == "QuantixActiveFeatures" or child.Name == "AbyssSelectionBox" or child.Name == "QuantixHighlight" or child.Name == "QuantixBillboard" or child.Name == "QuantixFOV" or child.Name == "QuantixUI" or child.Name == "AbyssUI" then
            pcall(function() child:Destroy() end)
        end
    end
    
    -- Clean up custom highlights inside characters/mobs to prevent leftovers
    for _, player in ipairs(Players:GetPlayers()) do
        local char = player.Character
        if char then
            local hl = char:FindFirstChild("QuantixHighlight") or char:FindFirstChild("AbyssHighlight")
            if hl then pcall(function() hl:Destroy() end) end
        end
    end
    local NPCS = workspace:FindFirstChild("NPCS")
    if NPCS then
        for _, mob in ipairs(NPCS:GetChildren()) do
            local hl = mob:FindFirstChild("QuantixHighlight") or mob:FindFirstChild("AbyssHighlight")
            if hl then pcall(function() hl:Destroy() end) end
        end
    end
end
cleanupOldESP()

-- Helper to safely require modules across execution contexts, prioritizing executor require
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

-- Helper to scan garbage collector for active game module tables (executor-agnostic)
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

-- Helper to search GC for any function upvalues referencing GameState (extremely robust fallback)
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

local function getGameStateModule()
    -- 1. Try upvalue scan (bypasses rawget-blocking/hidden tables)
    local fromUpvalue = findGameStateViaUpvalues()
    if fromUpvalue then return fromUpvalue end

    -- 2. Try direct GC scan
    local fromGC = findModuleViaGC({"subscribeAmmo", "setReload", "isTeammate"})
    if fromGC then return fromGC end

    return nil
end

-- Helper to search GC for any function upvalues referencing ReloadManager (extremely robust fallback)
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

local function getReloadManagerModule()
    -- 1. Try upvalue scan (most robust for loaded environments)
    local fromUpvalue = findReloadManagerViaUpvalues()
    if fromUpvalue then return fromUpvalue end

    -- 2. Try direct GC scan
    local fromGC = findModuleViaGC({"startReload", "cancelReload", "forceComplete"})
    if fromGC then return fromGC end

    return nil
end

-- Configuration Colors
local Theme = {
    Background = Color3.fromRGB(18, 18, 20),
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

-- Global Feature States
if State.AimbotEnabled == nil then State.AimbotEnabled = false end
if State.VisibleCheck == nil then State.VisibleCheck = true end
if State.PredictionEnabled == nil then State.PredictionEnabled = false end
if State.TeamCheck == nil then State.TeamCheck = true end
if State.Smoothing == nil then State.Smoothing = 5 end
if State.AimKey == nil then State.AimKey = Enum.UserInputType.MouseButton2 end -- Default aim key (Right click)
if State.MenuToggleKey == nil then State.MenuToggleKey = Enum.KeyCode.Insert end -- Default menu toggle key

if State.ESPEnabled == nil then State.ESPEnabled = false end
if State.BoxESP == nil then State.BoxESP = false end -- Native Highlight
if State.Box2DESP == nil then State.Box2DESP = false end -- 2D Drawings
if State.NameESP == nil then State.NameESP = false end
if State.FOVEnabled == nil then State.FOVEnabled = false end
if State.FOVRadius == nil then State.FOVRadius = 150 end
if State.AimbotMethod == nil then State.AimbotMethod = "Mouse" end -- "Mouse" (mousemoverel) or "Camera" (CFrame)
if State.CamControllerInst == nil then State.CamControllerInst = nil end

-- Visual Styling Customization States
if State.ChamsFillTrans == nil then State.ChamsFillTrans = 0.6 end
if State.ChamsOutlineTrans == nil then State.ChamsOutlineTrans = 0.2 end
if State.ChamsFillR == nil then State.ChamsFillR = 115; State.ChamsFillG = 120; State.ChamsFillB = 255 end
if State.ChamsOutlineR == nil then State.ChamsOutlineR = 150; State.ChamsOutlineG = 150; State.ChamsOutlineB = 255 end

if State.Box2DThickness == nil then State.Box2DThickness = 1 end
if State.Box2DR == nil then State.Box2DR = 115; State.Box2DG = 120; State.Box2DB = 255 end

if State.FOVThickness == nil then State.FOVThickness = 1 end
if State.FOVR == nil then State.FOVR = 115; State.FOVG = 120; State.FOVB = 255 end

-- Custom Game Modules for FPS STRAFE
local GameState = getGameStateModule()
print("[Abyss Debug] GameState found:", GameState ~= nil)
if GameState then
    pcall(function()
        local ts = GameState.getTeamState and GameState.getTeamState()
        if ts then
            print("[Abyss Debug] isTeamMode:", ts.isTeamMode, "localPlayerTeam:", ts.localPlayerTeam)
        else
            print("[Abyss Debug] getTeamState returned nil")
        end
    end)
end

local lastGameStateLookup = 0
local function lookupGameState()
    local now = tick()
    if now - lastGameStateLookup < 3 then return end
    lastGameStateLookup = now
    
    GameState = getGameStateModule()
    if GameState then
        print("[Abyss] GameState resolved dynamically!")
    end
end

local function isTeammate(entity)
    if not LocalPlayer or not entity then return false end
    
    local char = entity:IsA("Player") and entity.Character or entity
    if not char then return false end
    
    if char == LocalPlayer.Character then return true end
    
    -- 1. Check for teammate nametag billboard inside Head (game puts the billboard under Head)
    local head = char:FindFirstChild("Head")
    if head and head:FindFirstChild("TeammateNametag") then
        return true
    end
    
    -- 2. Check for game's native highlight color (Teammates are green Color3.fromRGB(0, 255, 100))
    local highlight = char:FindFirstChildOfClass("Highlight")
    if highlight and highlight.OutlineColor == Color3.fromRGB(0, 255, 100) then
        return true
    end
    
    -- 3. Fallback: Check if they are in the same Roblox Team
    local player = entity:IsA("Player") and entity or Players:GetPlayerFromCharacter(char)
    if player and player ~= LocalPlayer then
        if LocalPlayer.Team and player.Team and LocalPlayer.Team == player.Team then
            return true
        end
    end
    
    -- 4. GameState checks (with rate-limited dynamic lookup if it is nil)
    if not GameState then
        lookupGameState()
    end
    
    if GameState then
        local success, result = pcall(function()
            -- Check bots by BotUniqueId attribute
            local botId = char:GetAttribute("BotUniqueId")
            if botId then
                return GameState.isTeammate(botId)
            end
            
            -- Check players by UserId
            if player then
                return GameState.isTeammate(player.UserId)
            end
            return false
        end)
        if success then return result end
    end
    
    return false
end


-- Team Check caching — 0.25s TTL for snappy response
local TeamCache = {}
local lastCacheClear = 0
local TEAM_CACHE_TTL = 0.25
local function getCachedTeammateStatus(entity)
    local now = tick()
    if now - lastCacheClear > TEAM_CACHE_TTL then
        table.clear(TeamCache)
        lastCacheClear = now
    end
    
    if TeamCache[entity] ~= nil then
        return TeamCache[entity]
    end
    
    local status = isTeammate(entity)
    TeamCache[entity] = status
    return status
end

-- // Camera FOV
if State.CustomFOVEnabled == nil then State.CustomFOVEnabled = false end
if State.CustomFOVValue == nil then State.CustomFOVValue = 90 end
if State.CamControllerInst == nil then State.CamControllerInst = nil end -- resolved dynamically in background thread
local Lighting           = game:GetService("Lighting")

local function applyFOV()
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

local function restoreFOV()
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

-- // Custom Skybox
if State.CustomSkyboxEnabled == nil then State.CustomSkyboxEnabled = false end
local OriginalSkybox      = nil   -- saved copy of original sky properties
local CurrentSky          = nil   -- the Sky instance we inserted

-- Skybox presets: name -> { SkyboxBk, SkyboxDn, SkyboxFt, SkyboxLf, SkyboxRt, SkyboxUp }
local SkyboxPresets = {
    ["space"] = {
        Bk = "rbxassetid://159454299",
        Dn = "rbxassetid://159454296",
        Ft = "rbxassetid://159454293",
        Lf = "rbxassetid://159454286",
        Rt = "rbxassetid://159454300",
        Up = "rbxassetid://159454288",
    },
    ["sunset"] = {
        Bk = "rbxassetid://372310881",
        Dn = "rbxassetid://372310881",
        Ft = "rbxassetid://372310881",
        Lf = "rbxassetid://372310881",
        Rt = "rbxassetid://372310881",
        Up = "rbxassetid://372310881",
    },
    ["night"] = {
        Bk = "rbxassetid://6444884337",
        Dn = "rbxassetid://6444884337",
        Ft = "rbxassetid://6444884337",
        Lf = "rbxassetid://6444884337",
        Rt = "rbxassetid://6444884337",
        Up = "rbxassetid://6444884337",
    },
    ["neon city"] = {
        Bk = "rbxassetid://6197721980",
        Dn = "rbxassetid://6197721980",
        Ft = "rbxassetid://6197721980",
        Lf = "rbxassetid://6197721980",
        Rt = "rbxassetid://6197721980",
        Up = "rbxassetid://6197721980",
    },
    ["synthwave"] = {
        Bk = "rbxassetid://1417494030",
        Dn = "rbxassetid://1417494030",
        Ft = "rbxassetid://1417494030",
        Lf = "rbxassetid://1417494030",
        Rt = "rbxassetid://1417494030",
        Up = "rbxassetid://1417494030",
    },
    ["purple nebula"] = {
        Bk = "rbxassetid://1045964490",
        Dn = "rbxassetid://1045964490",
        Ft = "rbxassetid://1045964490",
        Lf = "rbxassetid://1045964490",
        Rt = "rbxassetid://1045964490",
        Up = "rbxassetid://1045964490",
    },
    ["blood moon"] = {
        Bk = "rbxassetid://1391515286",
        Dn = "rbxassetid://1391515286",
        Ft = "rbxassetid://1391515286",
        Lf = "rbxassetid://1391515286",
        Rt = "rbxassetid://1391515286",
        Up = "rbxassetid://1391515286",
    },
    ["daylight"] = {
        Bk = "rbxassetid://600886082",
        Dn = "rbxassetid://600886082",
        Ft = "rbxassetid://600886082",
        Lf = "rbxassetid://600886082",
        Rt = "rbxassetid://600886082",
        Up = "rbxassetid://600886082",
    },
}
if State.CurrentSkyboxName == nil then State.CurrentSkyboxName = "space" end

local function saveOriginalSky()
    if OriginalSkybox then return end
    local existingSky = Lighting:FindFirstChildOfClass("Sky")
    if existingSky then
        OriginalSkybox = {
            Bk = existingSky.SkyboxBk,
            Dn = existingSky.SkyboxDn,
            Ft = existingSky.SkyboxFt,
            Lf = existingSky.SkyboxLf,
            Rt = existingSky.SkyboxRt,
            Up = existingSky.SkyboxUp,
        }
    else
        -- No sky exists; remember that fact so we delete ours on restore
        OriginalSkybox = false
    end
end

local function applySkybox(name)
    local preset = SkyboxPresets[name]
    if not preset then return end
    pcall(function()
        saveOriginalSky()
        -- Remove any existing sky
        for _, child in ipairs(Lighting:GetChildren()) do
            if child:IsA("Sky") then child:Destroy() end
        end
        -- Create ours
        local sky = Instance.new("Sky")
        sky.SkyboxBk = preset.Bk
        sky.SkyboxDn = preset.Dn
        sky.SkyboxFt = preset.Ft
        sky.SkyboxLf = preset.Lf
        sky.SkyboxRt = preset.Rt
        sky.SkyboxUp = preset.Up
        sky.Parent   = Lighting
        CurrentSky   = sky
    end)
end

local function restoreSkybox()
    pcall(function()
        -- Remove ours
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
            sky.Parent   = Lighting
        end
        OriginalSkybox = nil
    end)
end

local function makeHUDElementDraggable(frame, gui)
    local dragging, dragInput, dragStart, startPos
    
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and State.GlobalWindow and State.GlobalWindow.Main.Visible then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
    end)
    table.insert(State.Connections, UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end))
    table.insert(State.Connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end))
end

-- // Watermark
local WatermarkEnabled = false
if State.WatermarkGui == nil then State.WatermarkGui = nil end
local watermarkThread  = nil

local function toggleWatermark(state)
    WatermarkEnabled = state
    if State.WatermarkGui then
        pcall(function() State.WatermarkGui:Destroy() end)
        State.WatermarkGui = nil
    end
    if watermarkThread then
        pcall(function() task.cancel(watermarkThread) end)
        watermarkThread = nil
    end
    
    if not state then return end
    
    local parent = RunService:IsStudio() and game.Players.LocalPlayer:WaitForChild("PlayerGui") or CoreGui
    
    local gui = Instance.new("ScreenGui")
    gui.Name = "QuantixWatermark"
    gui.ResetOnSpawn = false
    pcall(function() gui.Interactable = State.GlobalWindow and State.GlobalWindow.Main.Visible or false end)
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 180, 0, 24)
    frame.Position = UDim2.new(1, -30, 1, -85)
    frame.AnchorPoint = Vector2.new(1, 1)
    frame.BackgroundColor3 = Theme.Background
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.Parent = gui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = frame
    
    -- Premium accent line at the top
    local accentLine = Instance.new("Frame")
    accentLine.Size = UDim2.new(1, 0, 0, 2)
    accentLine.Position = UDim2.new(0, 0, 0, 0)
    accentLine.BorderSizePixel = 0
    accentLine.Parent = frame
    
    local lineGradient = Instance.new("UIGradient")
    lineGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.AccentStart),
        ColorSequenceKeypoint.new(1, Theme.AccentEnd)
    })
    lineGradient.Parent = accentLine
    
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1
    stroke.Color = Theme.DarkOutline
    stroke.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -12, 1, -2)
    label.Position = UDim2.new(0, 6, 0, 2)
    label.BackgroundTransparency = 1
    label.Text = "quantix | fps: -- | ping: --ms"
    label.TextColor3 = Theme.Text
    label.Font = Theme.Font
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.Parent = frame
    
    makeHUDElementDraggable(frame, gui)
    
    State.WatermarkGui = gui
    
    -- Dynamic stat calculator
    local fpsCount = 0
    local lastTick = tick()
    local connection
    connection = RunService.RenderStepped:Connect(function()
        fpsCount = fpsCount + 1
    end)
    
    watermarkThread = task.spawn(function()
        while WatermarkEnabled and State.WatermarkGui do
            task.wait(0.5)
            local currentTick = tick()
            local timeDiff = currentTick - lastTick
            local fps = math.round(fpsCount / timeDiff)
            fpsCount = 0
            lastTick = currentTick
            
            local ping = 0
            pcall(function()
                ping = math.round(LocalPlayer:GetNetworkPing() * 1000)
            end)
            
            pcall(function()
                local statText = string.format("quantix | fps: %d | ping: %dms", fps, ping)
                label.Text = statText
                local textBounds = game:GetService("TextService"):GetTextSize(statText, 11, Theme.Font, Vector2.new(999, 20))
                frame.Size = UDim2.new(0, textBounds.X + 16, 0, 24)
            end)
        end
        if connection then connection:Disconnect() end
    end)
end

-- // Keybinds List
if State.KeybindsGui == nil then State.KeybindsGui = nil end
if State.AimKey == nil then State.AimKey = nil endLabel = nil
local MenuKeyLabel = nil
if State.AimKey == nil then State.AimKey = nil endIndicator = nil
local MenuKeyIndicator = nil

local function toggleKeybindsList(state)
    if State.KeybindsGui then
        pcall(function() State.KeybindsGui:Destroy() end)
        State.KeybindsGui = nil
        AimKeyLabel = nil
        MenuKeyLabel = nil
        AimKeyIndicator = nil
        MenuKeyIndicator = nil
    end
    
    if not state then return end
    
    local parent = RunService:IsStudio() and game.Players.LocalPlayer:WaitForChild("PlayerGui") or CoreGui
    
    local gui = Instance.new("ScreenGui")
    gui.Name = "QuantixKeybinds"
    gui.ResetOnSpawn = false
    pcall(function() gui.Interactable = State.GlobalWindow and State.GlobalWindow.Main.Visible or false end)
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 140, 0, 60)
    frame.Position = UDim2.new(0, 15, 0, 60) -- below topbar buttons
    frame.BackgroundColor3 = Theme.Background
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.Parent = gui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = frame
    
    -- Sleek top accent line
    local accentLine = Instance.new("Frame")
    accentLine.Size = UDim2.new(1, 0, 0, 2)
    accentLine.Position = UDim2.new(0, 0, 0, 0)
    accentLine.BorderSizePixel = 0
    accentLine.Parent = frame
    
    local lineGradient = Instance.new("UIGradient")
    lineGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.AccentStart),
        ColorSequenceKeypoint.new(1, Theme.AccentEnd)
    })
    lineGradient.Parent = accentLine
    
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1
    stroke.Color = Theme.DarkOutline
    stroke.Parent = frame
    
    -- Header text
    local header = Instance.new("TextLabel")
    header.Size = UDim2.new(1, -10, 0, 18)
    header.Position = UDim2.new(0, 8, 0, 3)
    header.BackgroundTransparency = 1
    header.Text = "keybinds"
    header.TextColor3 = Theme.Text
    header.Font = Theme.Font
    header.TextSize = 11
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.Parent = frame
    
    local separator = Instance.new("Frame")
    separator.Size = UDim2.new(1, -16, 0, 1)
    separator.Position = UDim2.new(0, 8, 0, 21)
    separator.BackgroundColor3 = Theme.DarkOutline
    separator.BorderSizePixel = 0
    separator.Parent = frame
    
    -- Aim Keybind Container
    local aimRow = Instance.new("Frame")
    aimRow.Size = UDim2.new(1, -16, 0, 15)
    aimRow.Position = UDim2.new(0, 8, 0, 23)
    aimRow.BackgroundTransparency = 1
    aimRow.Parent = frame
    
    local aimInd = Instance.new("Frame")
    aimInd.Size = UDim2.new(0, 5, 0, 5)
    aimInd.Position = UDim2.new(0, 0, 0.5, -2)
    aimInd.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    aimInd.BorderSizePixel = 0
    aimInd.Parent = aimRow
    
    local aimCorner = Instance.new("UICorner")
    aimCorner.CornerRadius = UDim.new(0.5, 0)
    aimCorner.Parent = aimInd
    
    local aimLabel = Instance.new("TextLabel")
    aimLabel.Size = UDim2.new(1, -12, 1, 0)
    aimLabel.Position = UDim2.new(0, 12, 0, 0)
    aimLabel.BackgroundTransparency = 1
    aimLabel.Text = "aimbot  [M2]"
    aimLabel.TextColor3 = Theme.TextDark
    aimLabel.Font = Theme.Font
    aimLabel.TextSize = 10
    aimLabel.TextXAlignment = Enum.TextXAlignment.Left
    aimLabel.Parent = aimRow
    
    -- Menu Keybind Container
    local menuRow = Instance.new("Frame")
    menuRow.Size = UDim2.new(1, -16, 0, 15)
    menuRow.Position = UDim2.new(0, 8, 0, 38)
    menuRow.BackgroundTransparency = 1
    menuRow.Parent = frame
    
    local menuInd = Instance.new("Frame")
    menuInd.Size = UDim2.new(0, 5, 0, 5)
    menuInd.Position = UDim2.new(0, 0, 0.5, -2)
    menuInd.BackgroundColor3 = Color3.fromRGB(0, 255, 120) -- Menu is active/loaded
    menuInd.BorderSizePixel = 0
    menuInd.Parent = menuRow
    
    local menuCorner = Instance.new("UICorner")
    menuCorner.CornerRadius = UDim.new(0.5, 0)
    menuCorner.Parent = menuInd
    
    local menuLabel = Instance.new("TextLabel")
    menuLabel.Size = UDim2.new(1, -12, 1, 0)
    menuLabel.Position = UDim2.new(0, 12, 0, 0)
    menuLabel.BackgroundTransparency = 1
    menuLabel.Text = "menu    [Insert]"
    menuLabel.TextColor3 = Theme.TextDark
    menuLabel.Font = Theme.Font
    menuLabel.TextSize = 10
    menuLabel.TextXAlignment = Enum.TextXAlignment.Left
    menuLabel.Parent = menuRow
    
    makeHUDElementDraggable(frame, gui)
    
    gui.Parent = parent
    State.KeybindsGui = gui
    AimKeyLabel = aimLabel
    MenuKeyLabel = menuLabel
    AimKeyIndicator = aimInd
    MenuKeyIndicator = menuInd
end

local function getKeyName(key)
    if not key then return "None" end
    local name = tostring(key)
    name = name:gsub("Enum.KeyCode.", ""):gsub("Enum.UserInputType.", "")
    if name == "MouseButton1" then return "M1" end
    if name == "MouseButton2" then return "M2" end
    return name
end

local function updateKeybindsListText()
    if not State.KeybindsGui then return end
    pcall(function()
        local isAimActive = State.Aiming and State.AimbotEnabled
        if AimKeyIndicator then
            AimKeyIndicator.BackgroundColor3 = isAimActive and Color3.fromRGB(0, 255, 120) or Color3.fromRGB(60, 60, 60)
        end
        
        local aimText = "aimbot  [" .. getKeyName(State.AimKey) .. "]"
        if AimKeyLabel then
            AimKeyLabel.Text = aimText
            AimKeyLabel.TextColor3 = isAimActive and Theme.Text or Theme.TextDark
        end
        
        local menuText = "menu    [" .. getKeyName(State.MenuToggleKey) .. "]"
        if MenuKeyLabel and MenuKeyLabel.Text ~= menuText then
            MenuKeyLabel.Text = menuText
        end
    end)
end

-- // Active Features HUD
local ActiveFeaturesListEnabled = false
if State.ActiveFeaturesGui == nil then State.ActiveFeaturesGui = nil end
local ActiveFeaturesFrame = nil
local lastActiveHash = ""

local function updateActiveFeaturesHUD()
    if not State.ActiveFeaturesGui or not ActiveFeaturesFrame then return end
    
    local active = {}
    if State.AimbotEnabled then table.insert(active, "aimbot") end
    if State.ESPEnabled then table.insert(active, "esp") end
    if State.NoRecoilEnabled then table.insert(active, "no recoil") end
    if State.CustomFOVEnabled then table.insert(active, "custom fov") end
    if State.CustomSkyboxEnabled then table.insert(active, "custom skybox") end
    
    local hash = table.concat(active, ",")
    if hash == lastActiveHash then return end
    lastActiveHash = hash

    local success, err = pcall(function()
        -- Clear previous rows
        for _, child in ipairs(ActiveFeaturesFrame:GetChildren()) do
            if child:IsA("Frame") and child.Name == "FeatureRow" then
                child:Destroy()
            end
        end
        
        -- Re-create active rows
        local yOffset = 23
        for _, name in ipairs(active) do
            local row = Instance.new("Frame")
            row.Name = "FeatureRow"
            row.Size = UDim2.new(1, -16, 0, 15)
            row.Position = UDim2.new(0, 8, 0, yOffset)
            row.BackgroundTransparency = 1
            row.Parent = ActiveFeaturesFrame
            
            local ind = Instance.new("Frame")
            ind.Size = UDim2.new(0, 5, 0, 5)
            ind.Position = UDim2.new(0, 0, 0.5, -2)
            ind.BackgroundColor3 = Color3.fromRGB(0, 255, 120) -- Green glowing dot
            ind.BorderSizePixel = 0
            ind.Parent = row
            
            local indCorner = Instance.new("UICorner")
            indCorner.CornerRadius = UDim.new(0.5, 0)
            indCorner.Parent = ind
            
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -12, 1, 0)
            label.Position = UDim2.new(0, 12, 0, 0)
            label.BackgroundTransparency = 1
            label.Text = name
            label.TextColor3 = Theme.Text
            label.Font = Theme.Font
            label.TextSize = 10
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = row
            
            yOffset = yOffset + 15
        end
        
        -- Resize frame dynamically
        ActiveFeaturesFrame.Size = UDim2.new(0, 140, 0, math.max(30, yOffset + 5))
    end)
    if not success then
        warn("Quantix ActiveFeaturesHUD Error: " .. tostring(err))
    end
end

local function toggleActiveFeaturesHUD(state)
    ActiveFeaturesListEnabled = state
    if State.ActiveFeaturesGui then
        pcall(function() State.ActiveFeaturesGui:Destroy() end)
        State.ActiveFeaturesGui = nil
        ActiveFeaturesFrame = nil
    end
    
    lastActiveHash = ""
    if not state then return end
    
    local parent = RunService:IsStudio() and game.Players.LocalPlayer:WaitForChild("PlayerGui") or CoreGui
    
    local gui = Instance.new("ScreenGui")
    gui.Name = "QuantixActiveFeatures"
    gui.ResetOnSpawn = false
    pcall(function() gui.Interactable = State.GlobalWindow and State.GlobalWindow.Main.Visible or false end)
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 140, 0, 30)
    frame.Position = UDim2.new(0, 15, 0, 130) -- Align directly below the keybinds list
    frame.BackgroundColor3 = Theme.Background
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.Parent = gui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = frame
    
    -- Top accent line
    local accentLine = Instance.new("Frame")
    accentLine.Size = UDim2.new(1, 0, 0, 2)
    accentLine.Position = UDim2.new(0, 0, 0, 0)
    accentLine.BorderSizePixel = 0
    accentLine.Parent = frame
    
    local lineGradient = Instance.new("UIGradient")
    lineGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.AccentStart),
        ColorSequenceKeypoint.new(1, Theme.AccentEnd)
    })
    lineGradient.Parent = accentLine
    
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1
    stroke.Color = Theme.DarkOutline
    stroke.Parent = frame
    
    local header = Instance.new("TextLabel")
    header.Size = UDim2.new(1, -10, 0, 18)
    header.Position = UDim2.new(0, 8, 0, 3)
    header.BackgroundTransparency = 1
    header.Text = "active features"
    header.TextColor3 = Theme.Text
    header.Font = Theme.Font
    header.TextSize = 11
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.Parent = frame
    
    local separator = Instance.new("Frame")
    separator.Size = UDim2.new(1, -16, 0, 1)
    separator.Position = UDim2.new(0, 8, 0, 21)
    separator.BackgroundColor3 = Theme.DarkOutline
    separator.BorderSizePixel = 0
    separator.Parent = frame
    
    makeHUDElementDraggable(frame, gui)
    
    gui.Parent = parent
    State.ActiveFeaturesGui = gui
    ActiveFeaturesFrame = frame
    
    updateActiveFeaturesHUD()
end

-- // No Recoil
if State.NoRecoilEnabled == nil then State.NoRecoilEnabled = false end

-- Live instances of the recoil controllers (found via GC, cached)
-- RecoilController instance:       has gunRecoilSpring, rotationRecoilSpring, shotTwistSpring
-- CameraRecoilController instance: has spring (single), config, lastAppliedRecoil
if State.RecoilInstances == nil then State.RecoilInstances = {} end
if State.CamRecoilInstances == nil then State.CamRecoilInstances = {} end
local hookThread = nil

-- Zero out a spring so it produces no output on update()
local function zeroSpring(s)
    if not s then return end
    pcall(function()
        s.Position = Vector3.zero
        s.Velocity = Vector3.zero
        s.Target   = Vector3.zero
    end)
end

-- Scan GC for live recoil instances and cache them (runs in background thread only)
local function scanRecoilInstances()
    if not getgc then return end
    local newRC, newCR = {}, {}
    for _, val in ipairs(getgc(true)) do
        if type(val) == "table" then
            -- RecoilController instance: has all three named springs
            if rawget(val, "gunRecoilSpring") and rawget(val, "rotationRecoilSpring") and rawget(val, "shotTwistSpring") then
                table.insert(newRC, val)
            -- CameraRecoilController instance: has spring + config + lastAppliedRecoil
            elseif rawget(val, "spring") and rawget(val, "config") and rawget(val, "lastAppliedRecoil") then
                table.insert(newCR, val)
            end
        end
    end
    State.RecoilInstances    = newRC
    State.CamRecoilInstances = newCR
    if #newRC + #newCR > 0 then
        print("[Abyss] Recoil: found " .. #newRC .. " RecoilController(s), " .. #newCR .. " CameraRecoilController(s)")
    end
end

local function scanCameraController()
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

-- Background thread: re-scan every 3s to catch newly equipped weapons and camera controller
hookThread = task.spawn(function()
    while true do
        pcall(scanRecoilInstances)
        pcall(scanCameraController)
        task.wait(3)
    end
end)


-- Global States and Connection tables

-- State.Connections and updates are registered at the bottom after function declarations.


-- State.FOVCircle Wrapper supporting Drawing API and native Gui Fallback
if State.FOVCircle == nil then State.FOVCircle = {} end
local drawingCircle
local fallbackCircle

if pcall(function() Drawing.new("Circle") end) then
    drawingCircle = Drawing.new("Circle")
    drawingCircle.Thickness = 1
    drawingCircle.NumSides = 64
    drawingCircle.Radius = 150
    drawingCircle.Filled = false
    drawingCircle.Visible = false
    drawingCircle.Color = Theme.AccentStart
else
    local fovGui = Instance.new("ScreenGui")
    fovGui.Name = "QuantixFOV"
    fovGui.ResetOnSpawn = false
    pcall(function()
        fovGui.Interactable = false
    end)
    fovGui.Parent = RunService:IsStudio() and game.Players.LocalPlayer:WaitForChild("PlayerGui") or CoreGui
    
    local fovFrame = Instance.new("Frame")
    fovFrame.BackgroundTransparency = 1
    fovFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    fovFrame.Size = UDim2.new(0, 300, 0, 300)
    fovFrame.Visible = false
    fovFrame.Active = false
    fovFrame.Selectable = false
    pcall(function()
        fovFrame.Interactable = false
    end)
    fovFrame.Parent = fovGui
    
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1
    stroke.Color = Theme.AccentStart
    stroke.Parent = fovFrame
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.5, 0)
    corner.Parent = fovFrame
    
    fallbackCircle = { gui = fovGui, frame = fovFrame, stroke = stroke }
end

function State.FOVCircle:Update(pos, radius, visible, color, thickness)
    if drawingCircle then
        drawingCircle.Position = pos
        drawingCircle.Radius = radius
        drawingCircle.Visible = visible
        drawingCircle.Color = color
        drawingCircle.Thickness = thickness or 1
    elseif fallbackCircle then
        fallbackCircle.frame.Position = UDim2.new(0, pos.X, 0, pos.Y)
        fallbackCircle.frame.Size = UDim2.new(0, radius * 2, 0, radius * 2)
        fallbackCircle.frame.Visible = visible
        fallbackCircle.stroke.Color = color
        fallbackCircle.stroke.Thickness = thickness or 1
    end
end

function State.FOVCircle:Destroy()
    if drawingCircle then
        drawingCircle:Remove()
    elseif fallbackCircle then
        fallbackCircle.gui:Destroy()
    end
end

-- Helper to safely clean up visual components and connections of a single entity
local function removeESP(entity)
    local data = State.EspElements[entity]
    if data then
        if data.Highlight then pcall(function() data.Highlight:Destroy() end) end
        if data.Billboard then pcall(function() data.Billboard:Destroy() end) end
        if data.Box2D then pcall(function() data.Box2D:Remove() end) end
        if data.Connections then
            for _, conn in ipairs(data.Connections) do
                pcall(function() conn:Disconnect() end)
            end
        end
        State.EspElements[entity] = nil
    end
    
    -- Explicitly remove our highlight child from the character or mob if it exists
    local char = entity:IsA("Player") and entity.Character or (entity:IsA("Model") and entity)
    if char then
        local hl = char:FindFirstChild("QuantixHighlight") or char:FindFirstChild("AbyssHighlight")
        if hl then pcall(function() hl:Destroy() end) end
    end
end

-- Create visual components for a single player character
local function setupCharacterESP(player, char)
    removeESP(player)
    
    if player == LocalPlayer then return end
    
    local isTeammateVal = State.TeamCheck and getCachedTeammateStatus(player)
    
    -- Remove any existing native highlights first to prevent conflicts with Roblox rendering limitations
    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("Highlight") and child.Name ~= "QuantixHighlight" then
            pcall(function() child:Destroy() end)
        end
    end

    -- Native Highlight (Chams/Box outline) parented directly inside character to bypass 31 active highlights limit
    local highlight = char:FindFirstChild("QuantixHighlight")
    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.Name = "QuantixHighlight"
        highlight.FillTransparency = State.ChamsFillTrans
        highlight.FillColor = Color3.fromRGB(State.ChamsFillR, State.ChamsFillG, State.ChamsFillB)
        highlight.OutlineColor = Color3.fromRGB(State.ChamsOutlineR, State.ChamsOutlineG, State.ChamsOutlineB)
        highlight.OutlineTransparency = State.ChamsOutlineTrans
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Adornee = char
        highlight.Parent = char
    end
    highlight.Enabled = State.ESPEnabled and State.BoxESP and not isTeammateVal
    
    -- Billboard GUI
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "QuantixBillboard"
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.Adornee = char:WaitForChild("Head", 5) or char.PrimaryPart
    billboard.Enabled = State.ESPEnabled and State.NameESP and not isTeammateVal
    pcall(function()
        billboard.Parent = RunService:IsStudio() and game.Players.LocalPlayer:WaitForChild("PlayerGui") or CoreGui
    end)
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextStrokeTransparency = 0
    nameLabel.Font = Theme.Font
    nameLabel.TextSize = 12
    nameLabel.Text = player.DisplayName or player.Name
    nameLabel.Parent = billboard
    
    -- 2D Box Drawing
    local box2D = nil
    if Drawing and Drawing.new then
        pcall(function()
            box2D = Drawing.new("Square")
            box2D.Thickness = State.Box2DThickness
            box2D.Filled = false
            box2D.Color = Color3.fromRGB(State.Box2DR, State.Box2DG, State.Box2DB)
            box2D.Visible = false
        end)
    end
    
    local charConns = {}
    local ancestryConn
    ancestryConn = char.AncestryChanged:Connect(function(_, parent)
        if not parent then
            removeESP(player)
        end
    end)
    table.insert(charConns, ancestryConn)
    
    State.EspElements[player] = {
        Highlight = highlight,
        Billboard = billboard,
        Box2D = box2D,
        State.Connections = charConns
    }
end

-- Track player Added/Removing connections
local function trackPlayer(player)
    if player == LocalPlayer then return end
    
    if State.PlayerConnections[player] then
        for _, conn in ipairs(State.PlayerConnections[player]) do
            pcall(function() conn:Disconnect() end)
        end
    end
    
    local conns = {}
    local addedConn = player.CharacterAdded:Connect(function(char)
        setupCharacterESP(player, char)
    end)
    table.insert(conns, addedConn)
    
    State.PlayerConnections[player] = conns
    
    if player.Character then
        setupCharacterESP(player, player.Character)
    end
end

local function untrackPlayer(player)
    if State.PlayerConnections[player] then
        for _, conn in ipairs(State.PlayerConnections[player]) do
            pcall(function() conn:Disconnect() end)
        end
        State.PlayerConnections[player] = nil
    end
    removeESP(player)
end

-- Create visual components for an NPC/Mob
local function setupMobESP(mob)
    removeESP(mob)
    
    local isTeammateMob = State.TeamCheck and getCachedTeammateStatus(mob)
    
    -- Remove any existing native highlights first to prevent conflicts with Roblox rendering limitations
    for _, child in ipairs(mob:GetChildren()) do
        if child:IsA("Highlight") and child.Name ~= "QuantixHighlight" then
            pcall(function() child:Destroy() end)
        end
    end

    -- Native Highlight for NPCs parented directly inside mob to bypass 31 active highlights limit
    local highlight = mob:FindFirstChild("QuantixHighlight")
    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.Name = "QuantixHighlight"
        highlight.FillTransparency = State.ChamsFillTrans
        highlight.FillColor = Color3.fromRGB(State.ChamsFillR, State.ChamsFillG, State.ChamsFillB)
        highlight.OutlineColor = Color3.fromRGB(State.ChamsOutlineR, State.ChamsOutlineG, State.ChamsOutlineB)
        highlight.OutlineTransparency = State.ChamsOutlineTrans
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Adornee = mob
        highlight.Parent = mob
    end
    highlight.Enabled = State.ESPEnabled and State.BoxESP and not isTeammateMob
    
    -- Billboard GUI
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "QuantixBillboard"
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.Adornee = mob:WaitForChild("Head", 5) or mob.PrimaryPart
    billboard.Enabled = State.ESPEnabled and State.NameESP and not isTeammateMob
    pcall(function()
        billboard.Parent = RunService:IsStudio() and game.Players.LocalPlayer:WaitForChild("PlayerGui") or CoreGui
    end)
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextStrokeTransparency = 0
    nameLabel.Font = Theme.Font
    nameLabel.TextSize = 12
    nameLabel.Text = mob.Name
    nameLabel.Parent = billboard
    
    -- 2D Box Drawing
    local box2D = nil
    if Drawing and Drawing.new then
        pcall(function()
            box2D = Drawing.new("Square")
            box2D.Thickness = State.Box2DThickness
            box2D.Filled = false
            box2D.Color = Color3.fromRGB(State.Box2DR, State.Box2DG, State.Box2DB)
            box2D.Visible = false
        end)
    end
    
    local mobConns = {}
    local ancestryConn
    ancestryConn = mob.AncestryChanged:Connect(function(_, parent)
        if not parent then
            removeESP(mob)
        end
    end)
    table.insert(mobConns, ancestryConn)
    
    State.EspElements[mob] = {
        Highlight = highlight,
        Billboard = billboard,
        Box2D = box2D,
        State.Connections = mobConns
    }
end

-- Centralized ESP Update Loop (updates all boxes, highlights, text, size in one thread)
local function updateESPObjects()
    local activeCam = workspace.CurrentCamera
    if not activeCam then return end
    
    local fillC = Color3.fromRGB(State.ChamsFillR, State.ChamsFillG, State.ChamsFillB)
    local outC = Color3.fromRGB(State.ChamsOutlineR, State.ChamsOutlineG, State.ChamsOutlineB)
    local boxC = Color3.fromRGB(State.Box2DR, State.Box2DG, State.Box2DB)
    
    for entity, data in pairs(State.EspElements) do
        local isTeammateVal = State.TeamCheck and getCachedTeammateStatus(entity)
        local char = entity:IsA("Player") and entity.Character or entity
        local isAlive = false
        local root = nil
        
        if char and char.Parent then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
            isAlive = humanoid and humanoid.Health > 0 and root
        end
        
        local showESP = State.ESPEnabled and not isTeammateVal and isAlive
        
        if data.Highlight then
            data.Highlight.Enabled = showESP and State.BoxESP
            data.Highlight.FillTransparency = State.ChamsFillTrans
            data.Highlight.OutlineTransparency = State.ChamsOutlineTrans
            data.Highlight.FillColor = fillC
            data.Highlight.OutlineColor = outC
        end
        
        if data.Billboard then
            data.Billboard.Enabled = showESP and State.NameESP
        end
        
        if data.Box2D then
            local box = data.Box2D
            if showESP and State.Box2DESP and root then
                local pos, onScreen = activeCam:WorldToViewportPoint(root.Position)
                if onScreen then
                    -- Project 3D bounding points onto viewport to calculate visual dimensions
                    local sizeY = (activeCam:WorldToViewportPoint(root.Position + Vector3.new(0, 3, 0)).Y - activeCam:WorldToViewportPoint(root.Position - Vector3.new(0, 3.5, 0)).Y)
                    local sizeX = sizeY / 2
                    
                    box.Size = Vector2.new(math.abs(sizeX), math.abs(sizeY))
                    box.Position = Vector2.new(pos.X - (box.Size.X / 2), pos.Y - (box.Size.Y / 2))
                    box.Thickness = State.Box2DThickness
                    box.Color = boxC
                    box.Visible = true
                else
                    box.Visible = false
                end
            else
                box.Visible = false
            end
        end
    end
end

local function updateESP()
    pcall(updateESPObjects)
end

-- Optimized Aimbot Target Evaluation (Supports Players & NPCs, single-pass ignoreList creation)
local function getClosestPlayer()
    local Camera = workspace.CurrentCamera
    if not Camera then return nil end
    local mousePos = UserInputService:GetMouseLocation()

    -- 1. Gather all candidates within FOV that are alive
    local candidates = {}
    
    local function addCandidate(char)
        local head = char:FindFirstChild("Head")
        if not head then return end
        
        local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
        if not onScreen then return end
        
        local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
        if distance < State.FOVRadius then
            table.insert(candidates, {
                Character = char,
                Part = head,
                Distance = distance
            })
        end
    end

    -- Evaluate Players
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local char = player.Character
            local isAlive = false
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                isAlive = true
            end
            if isAlive and not (State.TeamCheck and getCachedTeammateStatus(player)) then
                addCandidate(char)
            end
        end
    end

    -- Evaluate NPCs
    local NPCSFolder = workspace:FindFirstChild("NPCS")
    if NPCSFolder then
        for _, mob in ipairs(NPCSFolder:GetChildren()) do
            if mob:IsA("Model") then
                local isAlive = false
                local hum = mob:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    isAlive = true
                end
                if isAlive and not (State.TeamCheck and getCachedTeammateStatus(mob)) then
                    addCandidate(mob)
                end
            end
        end
    end

    if #candidates == 0 then return nil end

    -- 2. Sort candidates by screen distance (closest to mouse first)
    table.sort(candidates, function(a, b)
        return a.Distance < b.Distance
    end)

    -- 3. Perform raycasts on sorted candidates until we find a visible one (or return the first if no State.VisibleCheck)
    if not State.VisibleCheck then
        return candidates[1]
    end

    -- Setup raycast parameters once
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    
    -- Build ignore list dynamically
    local ignoreList = {Camera, LocalPlayer.Character or workspace}
    local Effects = workspace:FindFirstChild("Effects")
    if Effects then table.insert(ignoreList, Effects) end
    local Ragdolls = workspace:FindFirstChild("Ragdolls")
    if Ragdolls then table.insert(ignoreList, Ragdolls) end
    for _, child in ipairs(Camera:GetChildren()) do
        table.insert(ignoreList, child)
    end
    
    -- Add all teammates to ignore list
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            if getCachedTeammateStatus(player) then
                table.insert(ignoreList, player.Character)
            end
        end
    end
    if NPCSFolder then
        for _, mob in ipairs(NPCSFolder:GetChildren()) do
            if getCachedTeammateStatus(mob) then
                table.insert(ignoreList, mob)
            end
        end
    end
    
    raycastParams.FilterDescendantsInstances = ignoreList

    local origin = Camera.CFrame.Position
    for _, cand in ipairs(candidates) do
        local headPos = cand.Part.Position
        local direction = headPos - origin
        local raycastResult = workspace:Raycast(origin, direction, raycastParams)
        
        if not raycastResult then
            -- Ray reached head without hitting anything, visible!
            return cand
        else
            local hitInstance = raycastResult.Instance
            -- If it hit a part of the candidate model, it's visible!
            if hitInstance:IsDescendantOf(cand.Character) then
                return cand
            end
        end
    end

    return nil
end

--- UI Window Builder logic has been moved to QuantixLibrary.lua
-- // ================================== \ --
-- //          Start Feature Loops       \ --
-- // ================================== \ --

-- Trigger aimbot while custom State.AimKey is held down
table.insert(State.Connections, UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == State.AimKey or input.UserInputType == State.AimKey then
        State.Aiming = true
    end
end))

table.insert(State.Connections, UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == State.AimKey or input.UserInputType == State.AimKey then
        State.Aiming = false
    end
end))

-- Unified RenderStepped loop (runs after camera updates to ensure perfect FOV & zero ESP box lag)
table.insert(State.Connections, RunService.RenderStepped:Connect(function()
    -- 1. FOV Override
    if State.CustomFOVEnabled then
        pcall(function()
            local activeCam = workspace.CurrentCamera
            if activeCam then
                if State.CamControllerInst then
                    State.CamControllerInst.baseFOV = State.CustomFOVValue
                    if not State.CamControllerInst.fovOverride then
                        activeCam.FieldOfView = State.CustomFOVValue
                    end
                else
                    activeCam.FieldOfView = State.CustomFOVValue
                end
            end
        end)
    end
    
    -- 2. No Recoil
    if State.NoRecoilEnabled then
        for _, inst in ipairs(State.RecoilInstances) do
            pcall(function()
                zeroSpring(inst.gunRecoilSpring)
                zeroSpring(inst.rotationRecoilSpring)
                zeroSpring(inst.shotTwistSpring)
            end)
        end
        for _, inst in ipairs(State.CamRecoilInstances) do
            pcall(function()
                zeroSpring(inst.spring)
                inst.lastAppliedRecoil = Vector3.zero
            end)
        end
    end

    -- 3. Aimbot
    if State.Aiming and State.AimbotEnabled then
        pcall(function()
            local target = getClosestPlayer()
            local activeCam = workspace.CurrentCamera
            if target and activeCam then
                local targetPart = target.Part
                local targetPos = targetPart.Position
                
                if State.PredictionEnabled then
                    local rootPart = targetPart.Parent:FindFirstChild("HumanoidRootPart") or targetPart.Parent.PrimaryPart or targetPart
                    local velocity = rootPart.AssemblyLinearVelocity or rootPart.Velocity or Vector3.new()
                    targetPos = targetPos + (velocity * 0.135)
                end
                
                if State.AimbotMethod == "Mouse" and mousemoverel then
                    local screenPos, onScreen = activeCam:WorldToViewportPoint(targetPos)
                    if onScreen then
                        local mousePos = UserInputService:GetMouseLocation()
                        local deltaX = (screenPos.X - mousePos.X)
                        local deltaY = (screenPos.Y - mousePos.Y)
                        
                        if State.Smoothing > 0 then
                            mousemoverel(deltaX / (State.Smoothing + 1), deltaY / (State.Smoothing + 1))
                        else
                            mousemoverel(deltaX, deltaY)
                        end
                    end
                else
                    local currentCF = activeCam.CFrame
                    local targetCF = CFrame.new(currentCF.Position, targetPos)
                    
                    if State.Smoothing > 0 then
                        activeCam.CFrame = currentCF:Lerp(targetCF, 1 / (State.Smoothing + 1))
                    else
                        activeCam.CFrame = targetCF
                    end
                end
            end
        end)
    end

    -- 4. ESP, FOV Circle, & Keybinds List updates
    local mousePos = UserInputService:GetMouseLocation()
    local fovVisible = State.FOVEnabled and State.AimbotEnabled
    local fovC = Color3.fromRGB(State.FOVR, State.FOVG, State.FOVB)
    pcall(function() State.FOVCircle:Update(mousePos, State.FOVRadius, fovVisible, fovC, State.FOVThickness) end)
    pcall(updateESPObjects)
    pcall(updateKeybindsListText)
    pcall(updateActiveFeaturesHUD)
end))

-- Setup Player added/removing handlers
for _, p in ipairs(Players:GetPlayers()) do
    trackPlayer(p)
end
table.insert(State.Connections, Players.PlayerAdded:Connect(trackPlayer))
table.insert(State.Connections, Players.PlayerRemoving:Connect(untrackPlayer))

-- Setup NPC added handlers
local NPCSFolder = workspace:FindFirstChild("NPCS")
if NPCSFolder then
    for _, mob in ipairs(NPCSFolder:GetChildren()) do
        setupMobESP(mob)
    end
    table.insert(State.Connections, NPCSFolder.ChildAdded:Connect(setupMobESP))
end


-- // ================================== \ --
-- //            UI Configuration        \ --
-- // ================================== \ --

local Window = Library:CreateWindow({ Title = "Quantix dev access | fps strafe" })
State.GlobalWindow = Window

getgenv().QuantixLibrary = Library
Library.ToggleKey = State.MenuToggleKey or Enum.KeyCode.Insert
Library.OnToggle = function(visible)
    if State.WatermarkGui then pcall(function() State.WatermarkGui.Interactable = visible end) end
    if State.KeybindsGui then pcall(function() State.KeybindsGui.Interactable = visible end) end
    if State.ActiveFeaturesGui then pcall(function() State.ActiveFeaturesGui.Interactable = visible end) end
end

local function LoadTab(name)
    local url = "https://raw.githubusercontent.com/thaimun67/Sokfweoifjwef0iowejfiowejfiowe/main/Tabs/" .. name .. ".lua?t=" .. tostring(tick())
    return loadstring(game:HttpGet(url))()
end

LoadTab("QuantixLegit")(Window, State)
LoadTab("QuantixVisuals")(Window, State, updateESP, applyFOV, restoreFOV, applySkybox, restoreSkybox, toggleWatermark, toggleKeybindsList, toggleActiveFeaturesHUD)
LoadTab("QuantixRage")(Window, State)
LoadTab("QuantixSettings")(Window, State, toggleWatermark, toggleKeybindsList, toggleActiveFeaturesHUD)
LoadTab("QuantixChangelog")(Window, State)

-- Make main tab active by default
Window.CurrentTab = "main"
for _, tab in pairs(Window.Tabs) do
    if tab.Button.Text == "main" then
        tab.Content.Visible = true
        tab.Button.TextColor3 = Library.Theme.Text
        tab.Button.BorderColor3 = Library.Theme.LightOutline
    else
        tab.Content.Visible = false
    end
end
