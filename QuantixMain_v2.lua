-- // ================================== \\ --
-- //       Quantix Main Orchestrator    \\ --
-- // ================================== \\ --

local State = getgenv().QuantixState or {}
getgenv().QuantixState = State

-- Cleanup previous instances
if getgenv then
    if getgenv().QuantixUnload then pcall(getgenv().QuantixUnload) end
    if getgenv().AbyssUnload then pcall(getgenv().AbyssUnload) end
end

-- Load UI Library
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/thaimun67/Sokfweoifjwef0iowejfiowejfiowe/main/QuantixLibrary_v2.lua?t=" .. tostring(tick())))()

-- Initialize core state
if State.Connections == nil then State.Connections = {} end
Library.Connections = State.Connections

if not game:IsLoaded() then game.Loaded:Wait() end
if State.GlobalWindow == nil then State.GlobalWindow = nil end
if State.Aiming == nil then State.Aiming = false end
if State.EspElements == nil then State.EspElements = {} end
if State.PlayerConnections == nil then State.PlayerConnections = {} end

-- Services
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local function tween(object, time, propertyTable)
    local tweenInfo = TweenInfo.new(time or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local t = TweenService:Create(object, tweenInfo, propertyTable)
    t:Play()
    return t
end

local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do
    task.wait()
    LocalPlayer = Players.LocalPlayer
end

local Camera = workspace.CurrentCamera

-- Services table passed to all modules
local Services = {
    CoreGui = CoreGui,
    UserInputService = UserInputService,
    RunService = RunService,
    Players = Players,
    TweenService = TweenService,
    Lighting = Lighting,
    LocalPlayer = LocalPlayer,
    Camera = Camera,
}

-- Configuration Colors (Theme)
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
if State.SilentAimEnabled == nil then State.SilentAimEnabled = false end
if State.InfiniteAmmoEnabled == nil then State.InfiniteAmmoEnabled = false end
if State.NoSpreadEnabled == nil then State.NoSpreadEnabled = false end
if State.VisibleCheck == nil then State.VisibleCheck = true end
if State.PredictionEnabled == nil then State.PredictionEnabled = false end
if State.TeamCheck == nil then State.TeamCheck = true end
if State.Smoothing == nil then State.Smoothing = 5 end
if State.AimKey == nil then State.AimKey = Enum.UserInputType.MouseButton2 end
if State.MenuToggleKey == nil then State.MenuToggleKey = Enum.KeyCode.Insert end

if State.ESPEnabled == nil then State.ESPEnabled = false end
if State.BoxESP == nil then State.BoxESP = false end
if State.Box2DESP == nil then State.Box2DESP = false end
if State.NameESP == nil then State.NameESP = false end
if State.FOVEnabled == nil then State.FOVEnabled = false end
if State.FOVRadius == nil then State.FOVRadius = 150 end
if State.AimbotMethod == nil then State.AimbotMethod = "Mouse" end
if State.CamControllerInst == nil then State.CamControllerInst = nil end

-- Visual Styling Customization States
if State.ChamsFillTrans == nil then State.ChamsFillTrans = 0.6 end
if State.ChamsOutlineTrans == nil then State.ChamsOutlineTrans = 0.2 end
if State.ChamsFillR == nil then State.ChamsFillR = 115; State.ChamsFillG = 120; State.ChamsFillB = 255 end
if State.ChamsOutlineR == nil then State.ChamsOutlineR = 150; State.ChamsOutlineG = 150; State.ChamsOutlineB = 255 end

if State.Box2DThickness == nil then State.Box2DThickness = 1 end
if State.Box2DR == nil then State.Box2DR = 115; State.Box2DG = 120; State.Box2DB = 255 end

if State.BulletTracesEnabled == nil then State.BulletTracesEnabled = false end
if State.BulletTraceThickness == nil then State.BulletTraceThickness = 0.02 end
if State.BulletTraceDuration == nil then State.BulletTraceDuration = 1.0 end
if State.BulletTraceColorR == nil then State.BulletTraceColorR = 115; State.BulletTraceColorG = 120; State.BulletTraceColorB = 255 end

if State.FOVThickness == nil then State.FOVThickness = 1 end
if State.FOVR == nil then State.FOVR = 115; State.FOVG = 120; State.FOVB = 255 end

if State.SilentAimHitChance == nil then State.SilentAimHitChance = 100 end
if State.SilentAimTargetPart == nil then State.SilentAimTargetPart = "Head" end
if State.SilentAimFOVRadius == nil then State.SilentAimFOVRadius = 150 end
if State.SilentAimFOVEnabled == nil then State.SilentAimFOVEnabled = false end
if State.SilentAimFOVR == nil then State.SilentAimFOVR = 255; State.SilentAimFOVG = 100; State.SilentAimFOVB = 100 end
if State.SilentAimFOVThickness == nil then State.SilentAimFOVThickness = 1 end

-- // ================================== \\ --
-- //         Load Feature Modules       \\ --
-- // ================================== \\ --

local BASE_URL = "https://raw.githubusercontent.com/thaimun67/Sokfweoifjwef0iowejfiowejfiowe/main/Modules/"

local function LoadModule(name)
    local url = BASE_URL .. name .. ".lua?t=" .. tostring(tick())
    local ok, result = pcall(function()
        local src = game:HttpGet(url)
        local fn, err = loadstring(src)
        if not fn then
            warn("[Quantix] Failed to compile " .. name .. ": " .. tostring(err))
            return nil
        end
        return fn()
    end)
    if not ok then
        warn("[Quantix] Failed to load " .. name .. ": " .. tostring(result))
        return nil
    end
    return result
end

-- Load modules (order matters: GameState first, then modules that depend on it)
local GameStateModule = LoadModule("GameState")(State, Services)
local VisualsModule = LoadModule("Visuals_v6")(State, Services)
local RecoilModule = LoadModule("Recoil")(State, Services)
local ESPModule = LoadModule("ESP_v6")(State, Services, Theme, GameStateModule)
local AimbotModule = LoadModule("Aimbot_v9")(State, Services, GameStateModule)
local HUDModule = LoadModule("HUD")(State, Services, Theme)

-- Cleanup old ESP elements from previous runs
ESPModule.cleanupOldESP()

-- Start background recoil/camera scanner
RecoilModule.startScanner()

-- Start bullet traces hook
pcall(function() VisualsModule.startBulletTracesHook() end)
pcall(function() AimbotModule.startSilentAimHook() end)

-- // ================================== \\ --
-- //          Start Feature Loops       \\ --
-- // ================================== \\ --

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

-- Unified RenderStepped loop
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
    RecoilModule.applyNoRecoil()

    -- 3. Aimbot
    AimbotModule.runAimbot()

    -- 4. ESP, FOV Circle, & Keybinds List updates
    local mousePos = UserInputService:GetMouseLocation()
    local fovVisible = State.FOVEnabled and State.AimbotEnabled
    local fovC = Color3.fromRGB(State.FOVR, State.FOVG, State.FOVB)
    pcall(function() State.FOVCircle:Update(mousePos, State.FOVRadius, fovVisible, fovC, State.FOVThickness) end)

    local silentFovVisible = State.SilentAimFOVEnabled and State.SilentAimEnabled
    local silentFovC = Color3.fromRGB(State.SilentAimFOVR or 255, State.SilentAimFOVG or 100, State.SilentAimFOVB or 100)
    pcall(function() State.SilentAimFOVCircle:Update(mousePos, State.SilentAimFOVRadius or 150, silentFovVisible, silentFovC, State.SilentAimFOVThickness or 1) end)

    pcall(ESPModule.updateESPObjects)
    pcall(HUDModule.updateKeybindsListText)
    pcall(HUDModule.updateActiveFeaturesHUD)
end))

-- Setup Player added/removing handlers
for _, p in ipairs(Players:GetPlayers()) do
    ESPModule.trackPlayer(p)
end
table.insert(State.Connections, Players.PlayerAdded:Connect(function(p) ESPModule.trackPlayer(p) end))
table.insert(State.Connections, Players.PlayerRemoving:Connect(function(p) ESPModule.untrackPlayer(p) end))

-- Setup NPC added handlers
local NPCSFolder = workspace:FindFirstChild("NPCS")
if NPCSFolder then
    for _, mob in ipairs(NPCSFolder:GetChildren()) do
        ESPModule.setupMobESP(mob)
    end
    table.insert(State.Connections, NPCSFolder.ChildAdded:Connect(function(mob) ESPModule.setupMobESP(mob) end))
end

-- // ================================== \\ --
-- //            UI Configuration        \\ --
-- // ================================== \\ --

local Window = Library:CreateWindow({ Title = "Quantix dev access | fps strafe" })
State.GlobalWindow = Window

getgenv().QuantixLibrary = Library
Library.ToggleKey = State.MenuToggleKey or Enum.KeyCode.Insert
Library.OnToggle = function(visible)
    if State.WatermarkGui then pcall(function() State.WatermarkGui.Interactable = visible end) end
    if State.KeybindsGui then pcall(function() State.KeybindsGui.Interactable = visible end) end
    if State.ActiveFeaturesGui then pcall(function() State.ActiveFeaturesGui.Interactable = visible end) end
end

-- // ====== Tab: Main (Legit) ====== \\ --
local MainTab = Window:CreateTab("main")

local LegitGroup = MainTab:CreateGroupbox("legit")
LegitGroup:CreateToggle({ Name = "aimbot", Default = false, Callback = function(s) State.AimbotEnabled = s end })
LegitGroup:CreateToggle({ Name = "use mousemoverel", Default = true, Callback = function(s) State.AimbotMethod = s and "Mouse" or "Camera" end })
LegitGroup:CreateToggle({ Name = "visible check", Default = true, Callback = function(s) State.VisibleCheck = s end })
LegitGroup:CreateToggle({ Name = "apply prediction", Default = false, Callback = function(s) State.PredictionEnabled = s end })
LegitGroup:CreateSlider({ Name = "smoothing [mouse]", Min = 0, Max = 20, Default = 5, Callback = function(v) State.Smoothing = v end })
LegitGroup:CreateKeybind({ Name = "aim keybind", Default = Enum.UserInputType.MouseButton2, Callback = function(k) State.AimKey = k; State.Aiming = false end })

local FOVGroup = MainTab:CreateGroupbox("fov settings")
FOVGroup:CreateToggle({ Name = "enable fov", Default = false, Callback = function(s) State.FOVEnabled = s end })
FOVGroup:CreateSlider({ Name = "fov radius", Min = 10, Max = 350, Default = 150, Callback = function(v) State.FOVRadius = v end })

-- // ====== Tab: Visuals ====== \\ --
local VisualsTab = Window:CreateTab("visuals")

local ESPGroup = VisualsTab:CreateGroupbox("esp")
ESPGroup:CreateToggle({ Name = "enabled", Default = false, Callback = function(s) State.ESPEnabled = s; pcall(ESPModule.updateESP) end })
ESPGroup:CreateToggle({ Name = "box esp (highlight)", Default = false, Callback = function(s) State.BoxESP = s; pcall(ESPModule.updateESP) end })
ESPGroup:CreateToggle({ Name = "2d box esp (drawing)", Default = false, Callback = function(s) State.Box2DESP = s; pcall(ESPModule.updateESP) end })
ESPGroup:CreateToggle({ Name = "name esp", Default = false, Callback = function(s) State.NameESP = s; pcall(ESPModule.updateESP) end })
ESPGroup:CreateToggle({ Name = "team check", Default = true, Callback = function(s) State.TeamCheck = s; pcall(ESPModule.updateESP) end })

local ChamsGroup = VisualsTab:CreateGroupbox("chams styling")
ChamsGroup:CreateSlider({ Name = "fill transparency", Min = 0, Max = 100, Default = 60, Callback = function(v) State.ChamsFillTrans = v / 100; pcall(ESPModule.updateESP) end })
ChamsGroup:CreateSlider({ Name = "outline transparency", Min = 0, Max = 100, Default = 20, Callback = function(v) State.ChamsOutlineTrans = v / 100; pcall(ESPModule.updateESP) end })
ChamsGroup:CreateColorpicker({ Name = "fill color", Default = Color3.fromRGB(115, 120, 255), Callback = function(c) State.ChamsFillR, State.ChamsFillG, State.ChamsFillB = math.round(c.R * 255), math.round(c.G * 255), math.round(c.B * 255); pcall(ESPModule.updateESP) end })
ChamsGroup:CreateColorpicker({ Name = "outline color", Default = Color3.fromRGB(255, 255, 255), Callback = function(c) State.ChamsOutlineR, State.ChamsOutlineG, State.ChamsOutlineB = math.round(c.R * 255), math.round(c.G * 255), math.round(c.B * 255); pcall(ESPModule.updateESP) end })

local CamGroup = VisualsTab:CreateGroupbox("camera")
CamGroup:CreateToggle({ Name = "custom fov", Default = false, Callback = function(s) State.CustomFOVEnabled = s; if not s then pcall(VisualsModule.restoreFOV) else pcall(VisualsModule.applyFOV) end end })
CamGroup:CreateSlider({ Name = "fov value", Min = 50, Max = 130, Default = 90, Callback = function(v) State.CustomFOVValue = v; if State.CustomFOVEnabled then pcall(VisualsModule.applyFOV) end end })

local SkyGroup = VisualsTab:CreateGroupbox("skybox")
SkyGroup:CreateToggle({ Name = "custom skybox", Default = false, Callback = function(s) State.CustomSkyboxEnabled = s; if s then pcall(VisualsModule.applySkybox, State.CurrentSkyboxName) else pcall(VisualsModule.restoreSkybox) end end })
local skyboxNames = { "space", "sunset", "night", "neon city", "synthwave", "purple nebula", "blood moon", "daylight" }
SkyGroup:CreateSlider({ Name = "Skybox Style (1-8)", Min = 1, Max = 8, Default = 1, Callback = function(v) State.CurrentSkyboxName = skyboxNames[math.floor(v)]; if State.CustomSkyboxEnabled then pcall(VisualsModule.applySkybox, State.CurrentSkyboxName) end end })

local FOVColorGroup = VisualsTab:CreateGroupbox("fov circle styling")
FOVColorGroup:CreateColorpicker({ Name = "circle color", Default = Color3.fromRGB(115, 120, 255), Callback = function(c) State.FOVR, State.FOVG, State.FOVB = math.round(c.R * 255), math.round(c.G * 255), math.round(c.B * 255) end })
FOVColorGroup:CreateSlider({ Name = "thickness", Min = 1, Max = 5, Default = 1, Callback = function(v) State.FOVThickness = v end })

local TracesGroup = VisualsTab:CreateGroupbox("bullet traces")
TracesGroup:CreateToggle({ Name = "enabled", Default = false, Callback = function(s) State.BulletTracesEnabled = s end })
TracesGroup:CreateSlider({ Name = "thickness (1-10)", Min = 1, Max = 10, Default = 2, Callback = function(v) State.BulletTraceThickness = v / 100 end })
TracesGroup:CreateSlider({ Name = "duration (1-5s)", Min = 1, Max = 5, Default = 1, Callback = function(v) State.BulletTraceDuration = v end })
TracesGroup:CreateColorpicker({ Name = "color", Default = Color3.fromRGB(115, 120, 255), Callback = function(c) State.BulletTraceColorR, State.BulletTraceColorG, State.BulletTraceColorB = math.round(c.R * 255), math.round(c.G * 255), math.round(c.B * 255) end })

-- // ====== Tab: Rage ====== \\ --
local RageTab = Window:CreateTab("rage")

local RageGroup = RageTab:CreateGroupbox("exploits")
RageGroup:CreateToggle({ Name = "no recoil", Default = false, Callback = function(s) State.NoRecoilEnabled = s end })
RageGroup:CreateToggle({ Name = "no spread", Default = false, Callback = function(s) State.NoSpreadEnabled = s end })
RageGroup:CreateToggle({ Name = "infinite ammo", Default = false, Callback = function(s) State.InfiniteAmmoEnabled = s end })

local SilentAimGroup = RageTab:CreateGroupbox("silent aim")
SilentAimGroup:CreateToggle({ Name = "enabled", Default = false, Callback = function(s) State.SilentAimEnabled = s end })
SilentAimGroup:CreateSlider({ Name = "hit chance", Min = 0, Max = 100, Default = 100, Callback = function(v) State.SilentAimHitChance = v end })
SilentAimGroup:CreateSlider({ Name = "target part (1:Head, 2:Torso, 3:Rand)", Min = 1, Max = 3, Default = 1, Callback = function(v)
            local parts = { "Head", "Torso", "Random" }
            State.SilentAimTargetPart = parts[math.floor(v + 0.5)] or "Head"
        end })
SilentAimGroup:CreateToggle({ Name = "show fov circle", Default = false, Callback = function(s) State.SilentAimFOVEnabled = s end })
SilentAimGroup:CreateSlider({ Name = "fov radius", Min = 10, Max = 350, Default = 150, Callback = function(v) State.SilentAimFOVRadius = v end })
SilentAimGroup:CreateColorpicker({ Name = "fov color", Default = Color3.fromRGB(255, 100, 100), Callback = function(c) State.SilentAimFOVR, State.SilentAimFOVG, State.SilentAimFOVB = math.round(c.R * 255), math.round(c.G * 255), math.round(c.B * 255) end })
SilentAimGroup:CreateSlider({ Name = "fov thickness", Min = 1, Max = 5, Default = 1, Callback = function(v) State.SilentAimFOVThickness = v end })

-- // ====== Tab: Settings ====== \\ --
local MenuTab = Window:CreateTab("settings")

local HUDGroup = MenuTab:CreateGroupbox("hud settings")
HUDGroup:CreateToggle({ Name = "watermark", Default = false, Callback = function(s) pcall(HUDModule.toggleWatermark, s) end })
HUDGroup:CreateToggle({ Name = "keybinds list", Default = false, Callback = function(s) pcall(HUDModule.toggleKeybindsList, s) end })
HUDGroup:CreateToggle({ Name = "active features list", Default = false, Callback = function(s) pcall(HUDModule.toggleActiveFeaturesHUD, s) end })

local MenuGroup = MenuTab:CreateGroupbox("menu")
MenuGroup:CreateKeybind({ Name = "menu keybind", Default = Enum.KeyCode.Insert, Callback = function(k)
    State.MenuToggleKey = k
    local lib = getgenv().QuantixLibrary
    if lib then lib.ToggleKey = k end
end })

MenuGroup:CreateButton({ Name = "unload script", Callback = function()
    if getgenv().AbyssUnload then pcall(getgenv().AbyssUnload) end
end })

-- // ====== Tab: Changelog ====== \\ --
local ChangelogTab = Window:CreateTab("changelog")

local InfoGroup = ChangelogTab:CreateGroupbox("v2.2 update")
InfoGroup:CreateLabel({ Text = "- Fully modularized architecture" })
InfoGroup:CreateLabel({ Text = "- Feature code split into Modules/" })
InfoGroup:CreateLabel({ Text = "- Scripts load directly from GitHub" })
InfoGroup:CreateLabel({ Text = "- Fixed GUI missing bugs" })
InfoGroup:CreateLabel({ Text = "- Improved ESP scoping" })
InfoGroup:CreateLabel({ Text = "- All 5 tabs now load reliably" })

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

-- Unload function
local function doUnload()
    -- Disconnect connections
    for _, conn in ipairs(State.Connections or {}) do
        pcall(function() conn:Disconnect() end)
    end
    State.Connections = {}

    -- Destroy FOV circles
    pcall(function() State.FOVCircle:Destroy() end)
    pcall(function() State.SilentAimFOVCircle:Destroy() end)

    -- Cleanup ESP elements
    pcall(ESPModule.cleanupOldESP)

    -- Destroy window
    if State.GlobalWindow then
        pcall(function() State.GlobalWindow:Destroy() end)
        State.GlobalWindow = nil
    end
end
getgenv().QuantixUnload = doUnload
getgenv().AbyssUnload = doUnload
