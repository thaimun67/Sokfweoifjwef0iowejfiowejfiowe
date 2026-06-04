-- // Custom "Quantix" UI Library with Fully Working Aimbot, ESP & Infinite Ammo \ --

if getgenv then
    if getgenv().QuantixUnload then pcall(getgenv().QuantixUnload) end
    if getgenv().AbyssUnload then pcall(getgenv().AbyssUnload) end
end

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/thaimun67/Sokfweoifjwef0iowejfiowejfiowe/main/QuantixLibrary.lua"))()

-- Storage for all runtime connections so they can be cleaned up
local Connections = {}
Library.Connections = Connections

-- Wait for game to load
if not game:IsLoaded() then game.Loaded:Wait() end
local GlobalWindow = nil
local Aiming = false
local EspElements = {}
local PlayerConnections = {}
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
local AimbotEnabled = false
local VisibleCheck = true
local PredictionEnabled = false
local TeamCheck = true
local Smoothing = 5
local AimKey = Enum.UserInputType.MouseButton2 -- Default aim key (Right click)
local MenuToggleKey = Enum.KeyCode.Insert      -- Default menu toggle key

local ESPEnabled = false
local BoxESP = false -- Native Highlight
local Box2DESP = false -- 2D Drawings
local NameESP = false
local FOVEnabled = false
local FOVRadius = 150
local AimbotMethod = "Mouse" -- "Mouse" (mousemoverel) or "Camera" (CFrame)
-- (InfiniteAmmoEnabled removed)

-- Visual Styling Customization States
local ChamsFillTrans = 0.6
local ChamsOutlineTrans = 0.2
local ChamsFillR, ChamsFillG, ChamsFillB = 115, 120, 255
local ChamsOutlineR, ChamsOutlineG, ChamsOutlineB = 150, 150, 255

local Box2DThickness = 1
local Box2DR, Box2DG, Box2DB = 115, 120, 255

local FOVThickness = 1
local FOVR, FOVG, FOVB = 115, 120, 255

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
local CustomFOVEnabled   = false
local CustomFOVValue     = 90
local CamControllerInst  = nil   -- resolved dynamically in background thread
local Lighting           = game:GetService("Lighting")

local function applyFOV()
    pcall(function()
        local activeCam = workspace.CurrentCamera
        if activeCam then
            activeCam.FieldOfView = CustomFOVValue
        end
    end)
    pcall(function()
        if CamControllerInst then
            CamControllerInst.baseFOV = CustomFOVValue
            if rawget(CamControllerInst, "_apply") then
                CamControllerInst:_apply()
            elseif getmetatable(CamControllerInst) and getmetatable(CamControllerInst)._apply then
                getmetatable(CamControllerInst)._apply(CamControllerInst)
            end
        end
    end)
end

local function restoreFOV()
    pcall(function()
        if CamControllerInst then
            local ReplicatedStorage = game:GetService("ReplicatedStorage")
            local SettingsManager = require(ReplicatedStorage.Classes.Utility.SettingsManager)
            local defaultFOV = SettingsManager and SettingsManager:get("video", "fov") or 80
            CamControllerInst.baseFOV = defaultFOV
            if rawget(CamControllerInst, "_apply") then
                CamControllerInst:_apply()
            elseif getmetatable(CamControllerInst) and getmetatable(CamControllerInst)._apply then
                getmetatable(CamControllerInst)._apply(CamControllerInst)
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
local CustomSkyboxEnabled = false
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
local CurrentSkyboxName = "space"

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
        if input.UserInputType == Enum.UserInputType.MouseButton1 and GlobalWindow and GlobalWindow.Main.Visible then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
    end)
    table.insert(Connections, UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end))
    table.insert(Connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end))
end

-- // Watermark
local WatermarkEnabled = false
local WatermarkGui     = nil
local watermarkThread  = nil

local function toggleWatermark(state)
    WatermarkEnabled = state
    if WatermarkGui then
        pcall(function() WatermarkGui:Destroy() end)
        WatermarkGui = nil
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
    pcall(function() gui.Interactable = GlobalWindow and GlobalWindow.Main.Visible or false end)
    
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
    
    WatermarkGui = gui
    
    -- Dynamic stat calculator
    local fpsCount = 0
    local lastTick = tick()
    local connection
    connection = RunService.RenderStepped:Connect(function()
        fpsCount = fpsCount + 1
    end)
    
    watermarkThread = task.spawn(function()
        while WatermarkEnabled and WatermarkGui do
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
local KeybindsGui = nil
local AimKeyLabel = nil
local MenuKeyLabel = nil
local AimKeyIndicator = nil
local MenuKeyIndicator = nil

local function toggleKeybindsList(state)
    if KeybindsGui then
        pcall(function() KeybindsGui:Destroy() end)
        KeybindsGui = nil
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
    pcall(function() gui.Interactable = GlobalWindow and GlobalWindow.Main.Visible or false end)
    
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
    KeybindsGui = gui
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
    if not KeybindsGui then return end
    pcall(function()
        local isAimActive = Aiming and AimbotEnabled
        if AimKeyIndicator then
            AimKeyIndicator.BackgroundColor3 = isAimActive and Color3.fromRGB(0, 255, 120) or Color3.fromRGB(60, 60, 60)
        end
        
        local aimText = "aimbot  [" .. getKeyName(AimKey) .. "]"
        if AimKeyLabel then
            AimKeyLabel.Text = aimText
            AimKeyLabel.TextColor3 = isAimActive and Theme.Text or Theme.TextDark
        end
        
        local menuText = "menu    [" .. getKeyName(MenuToggleKey) .. "]"
        if MenuKeyLabel and MenuKeyLabel.Text ~= menuText then
            MenuKeyLabel.Text = menuText
        end
    end)
end

-- // Active Features HUD
local ActiveFeaturesListEnabled = false
local ActiveFeaturesGui = nil
local ActiveFeaturesFrame = nil
local lastActiveHash = ""

local function updateActiveFeaturesHUD()
    if not ActiveFeaturesGui or not ActiveFeaturesFrame then return end
    
    local active = {}
    if AimbotEnabled then table.insert(active, "aimbot") end
    if ESPEnabled then table.insert(active, "esp") end
    if NoRecoilEnabled then table.insert(active, "no recoil") end
    if CustomFOVEnabled then table.insert(active, "custom fov") end
    if CustomSkyboxEnabled then table.insert(active, "custom skybox") end
    
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
    if ActiveFeaturesGui then
        pcall(function() ActiveFeaturesGui:Destroy() end)
        ActiveFeaturesGui = nil
        ActiveFeaturesFrame = nil
    end
    
    lastActiveHash = ""
    if not state then return end
    
    local parent = RunService:IsStudio() and game.Players.LocalPlayer:WaitForChild("PlayerGui") or CoreGui
    
    local gui = Instance.new("ScreenGui")
    gui.Name = "QuantixActiveFeatures"
    gui.ResetOnSpawn = false
    pcall(function() gui.Interactable = GlobalWindow and GlobalWindow.Main.Visible or false end)
    
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
    ActiveFeaturesGui = gui
    ActiveFeaturesFrame = frame
    
    updateActiveFeaturesHUD()
end

-- // No Recoil
local NoRecoilEnabled = false

-- Live instances of the recoil controllers (found via GC, cached)
-- RecoilController instance:       has gunRecoilSpring, rotationRecoilSpring, shotTwistSpring
-- CameraRecoilController instance: has spring (single), config, lastAppliedRecoil
local RecoilInstances    = {}
local CamRecoilInstances = {}
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
    RecoilInstances    = newRC
    CamRecoilInstances = newCR
    if #newRC + #newCR > 0 then
        print("[Abyss] Recoil: found " .. #newRC .. " RecoilController(s), " .. #newCR .. " CameraRecoilController(s)")
    end
end

local function scanCameraController()
    if CamControllerInst then return end
    if not getgc then return end
    for _, val in ipairs(getgc(true)) do
        if type(val) == "table"
            and rawget(val, "baseFOV") ~= nil
            and rawget(val, "baseSensitivity") ~= nil
            and rawget(val, "camera") ~= nil
        then
            CamControllerInst = val
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

-- Connections and updates are registered at the bottom after function declarations.


-- FOVCircle Wrapper supporting Drawing API and native Gui Fallback
local FOVCircle = {}
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

function FOVCircle:Update(pos, radius, visible, color, thickness)
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

function FOVCircle:Destroy()
    if drawingCircle then
        drawingCircle:Remove()
    elseif fallbackCircle then
        fallbackCircle.gui:Destroy()
    end
end

-- Helper to safely clean up visual components and connections of a single entity
local function removeESP(entity)
    local data = EspElements[entity]
    if data then
        if data.Highlight then pcall(function() data.Highlight:Destroy() end) end
        if data.Billboard then pcall(function() data.Billboard:Destroy() end) end
        if data.Box2D then pcall(function() data.Box2D:Remove() end) end
        if data.Connections then
            for _, conn in ipairs(data.Connections) do
                pcall(function() conn:Disconnect() end)
            end
        end
        EspElements[entity] = nil
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
    
    local isTeammateVal = TeamCheck and getCachedTeammateStatus(player)
    
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
        highlight.FillTransparency = ChamsFillTrans
        highlight.FillColor = Color3.fromRGB(ChamsFillR, ChamsFillG, ChamsFillB)
        highlight.OutlineColor = Color3.fromRGB(ChamsOutlineR, ChamsOutlineG, ChamsOutlineB)
        highlight.OutlineTransparency = ChamsOutlineTrans
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Adornee = char
        highlight.Parent = char
    end
    highlight.Enabled = ESPEnabled and BoxESP and not isTeammateVal
    
    -- Billboard GUI
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "QuantixBillboard"
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.Adornee = char:WaitForChild("Head", 5) or char.PrimaryPart
    billboard.Enabled = ESPEnabled and NameESP and not isTeammateVal
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
            box2D.Thickness = Box2DThickness
            box2D.Filled = false
            box2D.Color = Color3.fromRGB(Box2DR, Box2DG, Box2DB)
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
    
    EspElements[player] = {
        Highlight = highlight,
        Billboard = billboard,
        Box2D = box2D,
        Connections = charConns
    }
end

-- Track player Added/Removing connections
local function trackPlayer(player)
    if player == LocalPlayer then return end
    
    if PlayerConnections[player] then
        for _, conn in ipairs(PlayerConnections[player]) do
            pcall(function() conn:Disconnect() end)
        end
    end
    
    local conns = {}
    local addedConn = player.CharacterAdded:Connect(function(char)
        setupCharacterESP(player, char)
    end)
    table.insert(conns, addedConn)
    
    PlayerConnections[player] = conns
    
    if player.Character then
        setupCharacterESP(player, player.Character)
    end
end

local function untrackPlayer(player)
    if PlayerConnections[player] then
        for _, conn in ipairs(PlayerConnections[player]) do
            pcall(function() conn:Disconnect() end)
        end
        PlayerConnections[player] = nil
    end
    removeESP(player)
end

-- Create visual components for an NPC/Mob
local function setupMobESP(mob)
    removeESP(mob)
    
    local isTeammateMob = TeamCheck and getCachedTeammateStatus(mob)
    
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
        highlight.FillTransparency = ChamsFillTrans
        highlight.FillColor = Color3.fromRGB(ChamsFillR, ChamsFillG, ChamsFillB)
        highlight.OutlineColor = Color3.fromRGB(ChamsOutlineR, ChamsOutlineG, ChamsOutlineB)
        highlight.OutlineTransparency = ChamsOutlineTrans
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Adornee = mob
        highlight.Parent = mob
    end
    highlight.Enabled = ESPEnabled and BoxESP and not isTeammateMob
    
    -- Billboard GUI
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "QuantixBillboard"
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.Adornee = mob:WaitForChild("Head", 5) or mob.PrimaryPart
    billboard.Enabled = ESPEnabled and NameESP and not isTeammateMob
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
            box2D.Thickness = Box2DThickness
            box2D.Filled = false
            box2D.Color = Color3.fromRGB(Box2DR, Box2DG, Box2DB)
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
    
    EspElements[mob] = {
        Highlight = highlight,
        Billboard = billboard,
        Box2D = box2D,
        Connections = mobConns
    }
end

-- Centralized ESP Update Loop (updates all boxes, highlights, text, size in one thread)
local function updateESPObjects()
    local activeCam = workspace.CurrentCamera
    if not activeCam then return end
    
    local fillC = Color3.fromRGB(ChamsFillR, ChamsFillG, ChamsFillB)
    local outC = Color3.fromRGB(ChamsOutlineR, ChamsOutlineG, ChamsOutlineB)
    local boxC = Color3.fromRGB(Box2DR, Box2DG, Box2DB)
    
    for entity, data in pairs(EspElements) do
        local isTeammateVal = TeamCheck and getCachedTeammateStatus(entity)
        local char = entity:IsA("Player") and entity.Character or entity
        local isAlive = false
        local root = nil
        
        if char and char.Parent then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
            isAlive = humanoid and humanoid.Health > 0 and root
        end
        
        local showESP = ESPEnabled and not isTeammateVal and isAlive
        
        if data.Highlight then
            data.Highlight.Enabled = showESP and BoxESP
            data.Highlight.FillTransparency = ChamsFillTrans
            data.Highlight.OutlineTransparency = ChamsOutlineTrans
            data.Highlight.FillColor = fillC
            data.Highlight.OutlineColor = outC
        end
        
        if data.Billboard then
            data.Billboard.Enabled = showESP and NameESP
        end
        
        if data.Box2D then
            local box = data.Box2D
            if showESP and Box2DESP and root then
                local pos, onScreen = activeCam:WorldToViewportPoint(root.Position)
                if onScreen then
                    -- Project 3D bounding points onto viewport to calculate visual dimensions
                    local sizeY = (activeCam:WorldToViewportPoint(root.Position + Vector3.new(0, 3, 0)).Y - activeCam:WorldToViewportPoint(root.Position - Vector3.new(0, 3.5, 0)).Y)
                    local sizeX = sizeY / 2
                    
                    box.Size = Vector2.new(math.abs(sizeX), math.abs(sizeY))
                    box.Position = Vector2.new(pos.X - (box.Size.X / 2), pos.Y - (box.Size.Y / 2))
                    box.Thickness = Box2DThickness
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
        if distance < FOVRadius then
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
            if isAlive and not (TeamCheck and getCachedTeammateStatus(player)) then
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
                if isAlive and not (TeamCheck and getCachedTeammateStatus(mob)) then
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

    -- 3. Perform raycasts on sorted candidates until we find a visible one (or return the first if no VisibleCheck)
    if not VisibleCheck then
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

-- Trigger aimbot while custom AimKey is held down
table.insert(Connections, UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == AimKey or input.UserInputType == AimKey then
        Aiming = true
    end
end))

table.insert(Connections, UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == AimKey or input.UserInputType == AimKey then
        Aiming = false
    end
end))

-- Unified RenderStepped loop (runs after camera updates to ensure perfect FOV & zero ESP box lag)
table.insert(Connections, RunService.RenderStepped:Connect(function()
    -- 1. FOV Override
    if CustomFOVEnabled then
        pcall(function()
            local activeCam = workspace.CurrentCamera
            if activeCam then
                if CamControllerInst then
                    CamControllerInst.baseFOV = CustomFOVValue
                    if not CamControllerInst.fovOverride then
                        activeCam.FieldOfView = CustomFOVValue
                    end
                else
                    activeCam.FieldOfView = CustomFOVValue
                end
            end
        end)
    end
    
    -- 2. No Recoil
    if NoRecoilEnabled then
        for _, inst in ipairs(RecoilInstances) do
            pcall(function()
                zeroSpring(inst.gunRecoilSpring)
                zeroSpring(inst.rotationRecoilSpring)
                zeroSpring(inst.shotTwistSpring)
            end)
        end
        for _, inst in ipairs(CamRecoilInstances) do
            pcall(function()
                zeroSpring(inst.spring)
                inst.lastAppliedRecoil = Vector3.zero
            end)
        end
    end

    -- 3. Aimbot
    if Aiming and AimbotEnabled then
        pcall(function()
            local target = getClosestPlayer()
            local activeCam = workspace.CurrentCamera
            if target and activeCam then
                local targetPart = target.Part
                local targetPos = targetPart.Position
                
                if PredictionEnabled then
                    local rootPart = targetPart.Parent:FindFirstChild("HumanoidRootPart") or targetPart.Parent.PrimaryPart or targetPart
                    local velocity = rootPart.AssemblyLinearVelocity or rootPart.Velocity or Vector3.new()
                    targetPos = targetPos + (velocity * 0.135)
                end
                
                if AimbotMethod == "Mouse" and mousemoverel then
                    local screenPos, onScreen = activeCam:WorldToViewportPoint(targetPos)
                    if onScreen then
                        local mousePos = UserInputService:GetMouseLocation()
                        local deltaX = (screenPos.X - mousePos.X)
                        local deltaY = (screenPos.Y - mousePos.Y)
                        
                        if Smoothing > 0 then
                            mousemoverel(deltaX / (Smoothing + 1), deltaY / (Smoothing + 1))
                        else
                            mousemoverel(deltaX, deltaY)
                        end
                    end
                else
                    local currentCF = activeCam.CFrame
                    local targetCF = CFrame.new(currentCF.Position, targetPos)
                    
                    if Smoothing > 0 then
                        activeCam.CFrame = currentCF:Lerp(targetCF, 1 / (Smoothing + 1))
                    else
                        activeCam.CFrame = targetCF
                    end
                end
            end
        end)
    end

    -- 4. ESP, FOV Circle, & Keybinds List updates
    local mousePos = UserInputService:GetMouseLocation()
    local fovVisible = FOVEnabled and AimbotEnabled
    local fovC = Color3.fromRGB(FOVR, FOVG, FOVB)
    pcall(function() FOVCircle:Update(mousePos, FOVRadius, fovVisible, fovC, FOVThickness) end)
    pcall(updateESPObjects)
    pcall(updateKeybindsListText)
    pcall(updateActiveFeaturesHUD)
end))

-- Setup Player added/removing handlers
for _, p in ipairs(Players:GetPlayers()) do
    trackPlayer(p)
end
table.insert(Connections, Players.PlayerAdded:Connect(trackPlayer))
table.insert(Connections, Players.PlayerRemoving:Connect(untrackPlayer))

-- Setup NPC added handlers
local NPCSFolder = workspace:FindFirstChild("NPCS")
if NPCSFolder then
    for _, mob in ipairs(NPCSFolder:GetChildren()) do
        setupMobESP(mob)
    end
    table.insert(Connections, NPCSFolder.ChildAdded:Connect(setupMobESP))
end


-- // ================================== \ --
-- //            UI Configuration        \ --
-- // ================================== \ --

local Window = Library:CreateWindow({ Title = "Quantix dev access | fps strafe" })
GlobalWindow = Window

Library.ToggleKey = Enum.KeyCode.Insert
Library.OnToggle = function(visible)
    if WatermarkGui then pcall(function() WatermarkGui.Interactable = visible end) end
    if KeybindsGui then pcall(function() KeybindsGui.Interactable = visible end) end
    if ActiveFeaturesGui then pcall(function() ActiveFeaturesGui.Interactable = visible end) end
end

local MainTab     = Window:CreateTab("main")
local RageTab     = Window:CreateTab("rage")
local VisualsTab  = Window:CreateTab("visuals")
local ChangelogTab = Window:CreateTab("changelog")
local MenuTab     = Window:CreateTab("menu")


-- // [MAIN TAB - LEFT SIDE] Legit Aimbot Settings
local LegitGroup = MainTab:CreateGroupbox("legit")

LegitGroup:CreateToggle({
    Name = "aimbot",
    Default = false,
    Callback = function(state)
        AimbotEnabled = state
    end
})

LegitGroup:CreateToggle({
    Name = "use mousemoverel",
    Default = true,
    Callback = function(state)
        AimbotMethod = state and "Mouse" or "Camera"
    end
})

LegitGroup:CreateToggle({
    Name = "visible check",
    Default = true,
    Callback = function(state)
        VisibleCheck = state
    end
})

LegitGroup:CreateToggle({
    Name = "apply prediction",
    Default = false,
    Callback = function(state)
        PredictionEnabled = state
    end
})

LegitGroup:CreateSlider({
    Name = "smoothing [mouse]",
    Min = 0,
    Max = 20,
    Default = 5,
    Callback = function(value)
        Smoothing = value
    end
})

LegitGroup:CreateKeybind({
    Name = "aim keybind",
    Default = Enum.UserInputType.MouseButton2,
    Callback = function(key)
        AimKey = key
        Aiming = false
    end
})

-- // [MAIN TAB - LEFT SIDE] FOV Settings
local FOVGroup = MainTab:CreateGroupbox("fov settings")

FOVGroup:CreateToggle({
    Name = "enable fov",
    Default = false,
    Callback = function(state)
        FOVEnabled = state
    end
})

FOVGroup:CreateSlider({
    Name = "fov radius",
    Min = 10,
    Max = 350,
    Default = 150,
    Callback = function(value)
        FOVRadius = value
    end
})

-- // [MAIN TAB - RIGHT SIDE] Visual ESP Settings
local VisualsGroup = MainTab:CreateGroupbox("esp")

VisualsGroup:CreateToggle({
    Name = "enabled",
    Default = false,
    Callback = function(state)
        ESPEnabled = state
        updateESP()
    end
})

VisualsGroup:CreateToggle({
    Name = "box esp (highlight)",
    Default = false,
    Callback = function(state)
        BoxESP = state
        updateESP()
    end
})

VisualsGroup:CreateToggle({
    Name = "2d box esp (drawing)",
    Default = false,
    Callback = function(state)
        Box2DESP = state
        updateESP()
    end
})

VisualsGroup:CreateToggle({
    Name = "name esp",
    Default = false,
    Callback = function(state)
        NameESP = state
        updateESP()
    end
})

VisualsGroup:CreateToggle({
    Name = "team check",
    Default = true,
    Callback = function(state)
        TeamCheck = state
        updateESP()
    end
})

-- // [RAGE TAB] Exploits
local RageGroup = RageTab:CreateGroupbox("exploits")

RageGroup:CreateToggle({
    Name = "no recoil",
    Default = false,
    Callback = function(state)
        NoRecoilEnabled = state
    end
})

-- // [VISUALS TAB]
local FOVGroup2 = VisualsTab:CreateGroupbox("camera")

FOVGroup2:CreateToggle({
    Name = "custom fov",
    Default = false,
    Callback = function(state)
        CustomFOVEnabled = state
        if not state then
            restoreFOV()
        else
            applyFOV()
        end
    end
})

FOVGroup2:CreateSlider({
    Name = "fov value",
    Min = 50,
    Max = 130,
    Default = 90,
    Callback = function(value)
        CustomFOVValue = value
        if CustomFOVEnabled then applyFOV() end
    end
})

local SkyGroup = VisualsTab:CreateGroupbox("skybox")

SkyGroup:CreateToggle({
    Name = "custom skybox",
    Default = false,
    Callback = function(state)
        CustomSkyboxEnabled = state
        if state then
            applySkybox(CurrentSkyboxName)
        else
            restoreSkybox()
        end
    end
})

local skyboxNames = { "space", "sunset", "night", "neon city", "synthwave", "purple nebula", "blood moon", "daylight" }

SkyGroup:CreateSlider({
    Name = "Skybox Style (1-8)",
    Min = 1,
    Max = 8,
    Default = 1,
    Callback = function(value)
        CurrentSkyboxName = skyboxNames[math.floor(value)]
        if CustomSkyboxEnabled then
            applySkybox(CurrentSkyboxName)
        end
    end
})

local HUDGroup = VisualsTab:CreateGroupbox("hud settings")

HUDGroup:CreateToggle({
    Name = "watermark",
    Default = false,
    Callback = function(state)
        toggleWatermark(state)
    end
})

HUDGroup:CreateToggle({
    Name = "keybinds list",
    Default = false,
    Callback = function(state)
        toggleKeybindsList(state)
    end
})

HUDGroup:CreateToggle({
    Name = "active features list",
    Default = false,
    Callback = function(state)
        toggleActiveFeaturesHUD(state)
    end
})

local ChamsStyleGroup = VisualsTab:CreateGroupbox("chams styling")

ChamsStyleGroup:CreateSlider({
    Name = "fill transparency",
    Min = 0,
    Max = 100,
    Default = 60,
    Callback = function(value)
        ChamsFillTrans = value / 100
        updateESP()
    end
})

ChamsStyleGroup:CreateSlider({
    Name = "outline transparency",
    Min = 0,
    Max = 100,
    Default = 20,
    Callback = function(value)
        ChamsOutlineTrans = value / 100
        updateESP()
    end
})

ChamsStyleGroup:CreateColorpicker({
    Name = "fill color",
    Default = Color3.fromRGB(115, 120, 255),
    Callback = function(color)
        ChamsFillR, ChamsFillG, ChamsFillB = math.round(color.R * 255), math.round(color.G * 255), math.round(color.B * 255)
        updateESP()
    end
})

ChamsStyleGroup:CreateColorpicker({
    Name = "outline color",
    Default = Color3.fromRGB(150, 150, 255),
    Callback = function(color)
        ChamsOutlineR, ChamsOutlineG, ChamsOutlineB = math.round(color.R * 255), math.round(color.G * 255), math.round(color.B * 255)
        updateESP()
    end
})

local Box2DStyleGroup = VisualsTab:CreateGroupbox("2d box styling")

Box2DStyleGroup:CreateSlider({
    Name = "box thickness",
    Min = 1,
    Max = 5,
    Default = 1,
    Callback = function(value)
        Box2DThickness = value
        updateESP()
    end
})

Box2DStyleGroup:CreateColorpicker({
    Name = "box color",
    Default = Color3.fromRGB(115, 120, 255),
    Callback = function(color)
        Box2DR, Box2DG, Box2DB = math.round(color.R * 255), math.round(color.G * 255), math.round(color.B * 255)
        updateESP()
    end
})

local FovCircleStyleGroup = VisualsTab:CreateGroupbox("fov circle styling")

FovCircleStyleGroup:CreateSlider({
    Name = "fov thickness",
    Min = 1,
    Max = 5,
    Default = 1,
    Callback = function(value)
        FOVThickness = value
    end
})

FovCircleStyleGroup:CreateColorpicker({
    Name = "fov color",
    Default = Color3.fromRGB(115, 120, 255),
    Callback = function(color)
        FOVR, FOVG, FOVB = math.round(color.R * 255), math.round(color.G * 255), math.round(color.B * 255)
    end
})


-- // [CHANGELOG TAB]
local LogsGroup = ChangelogTab:CreateGroupbox("latest updates")
LogsGroup:CreateLabel({ Text = "[+] Added Color Pickers (spectrum dropdowns)" })
LogsGroup:CreateLabel({ Text = "[+] Added Features tab listing script capabilities" })
LogsGroup:CreateLabel({ Text = "[+] Added No Recoil (weapon & camera shake)" })
LogsGroup:CreateLabel({ Text = "[v2] Fixed Team check & visibility check delay" })
LogsGroup:CreateLabel({ Text = "[+] Added Custom FOV (50-130)" })
LogsGroup:CreateLabel({ Text = "[+] Added Custom Skybox (8 presets)" })
LogsGroup:CreateLabel({ Text = "[+] Diverted to FPS STRAFE game" })
LogsGroup:CreateLabel({ Text = "[+] Added support for players and NPCS/bots" })



-- // [MENU TAB] Settings & Unload
local SettingsGroup = MenuTab:CreateGroupbox("menu settings")

SettingsGroup:CreateKeybind({
    Name = "Toggle Keybind",
    Default = Enum.KeyCode.Insert,
    Callback = function(key)
        MenuToggleKey = key
    end
})

local function doUnload()
    -- Cancel the recoil background scan thread
    if hookThread then
        pcall(function() task.cancel(hookThread) end)
        hookThread = nil
    end

    -- Clear cached instances and disable
    NoRecoilEnabled    = false
    RecoilInstances    = {}
    CamRecoilInstances = {}


    -- Restore FOV
    CustomFOVEnabled = false
    restoreFOV()

    -- Restore skybox
    if CustomSkyboxEnabled then
        restoreSkybox()
    end
    CustomSkyboxEnabled = false

    -- Clean up watermark
    if WatermarkGui then
        pcall(function() WatermarkGui:Destroy() end)
        WatermarkGui = nil
    end
    if watermarkThread then
        pcall(function() task.cancel(watermarkThread) end)
        watermarkThread = nil
    end
    WatermarkEnabled = false

    -- Clean up keybinds list
    if KeybindsGui then
        pcall(function() KeybindsGui:Destroy() end)
        KeybindsGui = nil
        AimKeyLabel = nil
        MenuKeyLabel = nil
    end

    -- Clean up active features HUD
    toggleActiveFeaturesHUD(false)

    -- Unbind all steps (RenderStepped connections are disconnected in the connections loop below)

    -- 1. Stop all global execution loops and events
    for _, conn in ipairs(Connections) do
        if conn then
            pcall(function()
                if type(conn) == "table" and conn.Disconnect then
                    conn.Disconnect()
                else
                    conn:Disconnect()
                end
            end)
        end
    end
    Connections = {}
    
    -- 2. Stop all player tracking connections
    for player, conns in pairs(PlayerConnections) do
        for _, conn in ipairs(conns) do
            pcall(function() conn:Disconnect() end)
        end
    end
    PlayerConnections = {}
    
    -- 3. Clean up ESP drawings and entity connections from lookup table
    for entity, _ in pairs(EspElements) do
        removeESP(entity)
    end
    EspElements = {}
    
    -- 4. Destroy FOV Circle
    FOVCircle:Destroy()
    
    -- 5. Destroy GUI
    Window.Gui:Destroy()
    
    if getgenv then
        getgenv().QuantixUnload = nil
        getgenv().AbyssUnload = nil
    end
    print("Quantix UI completely unloaded.")
end

if getgenv then
    getgenv().QuantixUnload = doUnload
    getgenv().AbyssUnload = doUnload
end

SettingsGroup:CreateButton({
    Name = "Unload",
    Callback = doUnload
})
