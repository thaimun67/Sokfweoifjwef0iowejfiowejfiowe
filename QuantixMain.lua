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
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/thaimun67/Sokfweoifjwef0iowejfiowejfiowe/main/QuantixLibrary_v3.lua?t=" .. tostring(tick())))()

-- Initialize core state
if State.Connections == nil then State.Connections = {} end
Library.Connections = State.Connections

if not game:IsLoaded() then game.Loaded:Wait() end
if State.GlobalWindow == nil then State.GlobalWindow = nil end
if State.Aiming == nil then State.Aiming = false end
if State.EspElements == nil then State.EspElements = {} end
if State.PlayerConnections == nil then State.PlayerConnections = {} end

-- Reset HUD GUI and Background references to prevent dead/destroyed reference leaks
State.WatermarkGui = nil
State.WatermarkBg = nil
State.KeybindsGui = nil
State.KeybindsBg = nil
State.KeybindsListContainer = nil
State.ActiveFeaturesGui = nil
State.ActiveFeaturesBg = nil
State.ActiveFeaturesContainer = nil

-- Services
local CoreGui = gethui and gethui() or game:GetService("CoreGui")
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
    Background = Color3.fromRGB(20, 21, 26),
    DarkOutline = Color3.fromRGB(36, 37, 44),
    LightOutline = Color3.fromRGB(48, 50, 60),
    AccentStart = Color3.fromRGB(219, 29, 222),
    AccentEnd = Color3.fromRGB(150, 50, 255),
    Text = Color3.fromRGB(240, 240, 245),
    TextDark = Color3.fromRGB(130, 130, 160),
    ElementBackground = Color3.fromRGB(45, 47, 56),
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
if State.AimKeyMode == nil then State.AimKeyMode = "Hold" end
if State.BhopKeyMode == nil then State.BhopKeyMode = "Hold" end
if State.ThemeAccentStart == nil then State.ThemeAccentStart = Color3.fromRGB(219, 29, 222) end
if State.ThemeAccentEnd == nil then State.ThemeAccentEnd = Color3.fromRGB(150, 50, 255) end

if State.MagicBulletEnabled == nil then State.MagicBulletEnabled = false end

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
    print("[Quantix Loader] Fetching and compiling: " .. name)
    local ok, result = pcall(function()
        local src = game:HttpGet(url)
        local fn, err = loadstring(src)
        if not fn then
            error("Compile error: " .. tostring(err))
        end
        return fn()
    end)
    
    if not ok then
        warn("[Quantix] Failed to load/compile " .. name .. ": " .. tostring(result))
        return function()
            return setmetatable({}, {
                __index = function() return function() end end
            })
        end
    end
    
    return function(...)
        local args = {...}
        print("[Quantix Loader] Initializing: " .. name)
        local runOk, module = pcall(function()
            return result(unpack(args))
        end)
        if not runOk then
            warn("[Quantix] Failed to initialize " .. name .. ": " .. tostring(module))
            return setmetatable({}, {
                __index = function() return function() end end
            })
        end
        print("[Quantix Loader] Initialized: " .. name .. " successfully!")
        return module
    end
end

-- Load modules
local GameStateModule = LoadModule("GameState")(State, Services)
getgenv().QuantixMainIsTeammate = function(entity)
    return GameStateModule.isTeammate(entity)
end
local HookManagerModule = LoadModule("HookManager")(State, Services)
local BulletTracesModule = LoadModule("BulletTraces")(State, Services)
local CustomFOVModule = LoadModule("CustomFOV")(State, Services)
local CustomSkyboxModule = LoadModule("CustomSkybox")(State, Services)
local FOVCirclesModule = LoadModule("FOVCircles")(State, Services)
local WatermarkModule = LoadModule("Watermark")(State, Services, Theme)
local KeybindsListModule = LoadModule("KeybindsList")(State, Services, Theme)
local ActiveFeaturesModule = LoadModule("ActiveFeatures")(State, Services, Theme)
local RecoilModule = LoadModule("Recoil")(State, Services)
local ESPModule = LoadModule("ESP")(State, Services, Theme, GameStateModule)
local AimbotModule = LoadModule("Aimbot")(State, Services, GameStateModule)
local WeaponChamsModule = LoadModule("WeaponChams")(State, Services)
local SpeedBoostModule = LoadModule("SpeedBoost")(State, Services)
local BhopModule = LoadModule("Bhop")(State, Services)
local HitsoundsModule = LoadModule("Hitsounds")(State, Services)
local MagicBulletModule = LoadModule("MagicBullet")(State, Services)

-- Cleanup old ESP elements from previous runs
print("[Quantix Loader] Cleaning up old ESP elements...")
pcall(function() ESPModule.cleanupOldESP() end)

-- Start background recoil/camera scanner
print("[Quantix Loader] Starting recoil/camera scanner...")
pcall(function() RecoilModule.startScanner() end)

-- Start bullet traces and gun mod hooks
print("[Quantix Loader] Starting hooks...")
pcall(function() BulletTracesModule.startBulletTracesHook() end)
pcall(function() HookManagerModule.startHook() end)
pcall(function() HitsoundsModule.start() end)

-- // ================================== \\ --
-- //          Start Feature Loops       \\ --
-- // ================================== \\ --

-- Trigger aimbot while custom State.AimKey is held down (or toggled)
table.insert(State.Connections, UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == State.AimKey or input.UserInputType == State.AimKey then
        if State.AimKeyMode == "Toggle" then
            State.Aiming = not State.Aiming
            if Library and Library.Notify then
                Library:Notify("Aimbot", "Aimbot is now " .. (State.Aiming and "Active" or "Inactive"), 1.5)
            end
        else
            State.Aiming = true
        end
    end
end))

table.insert(State.Connections, UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == State.AimKey or input.UserInputType == State.AimKey then
        if State.AimKeyMode == "Hold" then
            State.Aiming = false
        end
    end
end))

-- Unified RenderStepped loop
table.insert(State.Connections, RunService.RenderStepped:Connect(function()
    pcall(function() CustomFOVModule.update() end)
    pcall(function() RecoilModule.applyNoRecoil() end)
    pcall(function() AimbotModule.update() end)
    pcall(function() FOVCirclesModule.update() end)
    pcall(function() CustomSkyboxModule.update() end)
    pcall(function() ESPModule.updateESPObjects() end)
    pcall(function() KeybindsListModule.update() end)
    pcall(function() ActiveFeaturesModule.update() end)
    pcall(function() WeaponChamsModule.update() end)
    pcall(function() SpeedBoostModule.update() end)
    pcall(function() BhopModule.update() end)
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

print("[Quantix Loader] Creating UI window...")
local Window = Library:CreateWindow({ Title = "Quantix dev access | fps strafe" })
State.GlobalWindow = Window
print("[Quantix Loader] UI window created successfully!")

-- Apply theme accent colors on load
pcall(function()
    Library:SetAccentColors(State.ThemeAccentStart, State.ThemeAccentEnd)
end)

getgenv().QuantixLibrary = Library
Library.ToggleKey = State.MenuToggleKey or Enum.KeyCode.Insert
Library.OnToggle = function(visible)
    if State.WatermarkBg then pcall(function() State.WatermarkBg.Active = visible; State.WatermarkBg.Interactable = visible end) end
    if State.KeybindsBg then pcall(function() State.KeybindsBg.Active = visible; State.KeybindsBg.Interactable = visible end) end
    if State.ActiveFeaturesBg then pcall(function() State.ActiveFeaturesBg.Active = visible; State.ActiveFeaturesBg.Interactable = visible end) end
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
LegitGroup:CreateDropdown({ Name = "aim key mode", List = { "Hold", "Toggle" }, Default = State.AimKeyMode, Callback = function(v) State.AimKeyMode = v; State.Aiming = false end })

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
ChamsGroup:CreateColorpicker({ Name = "fill color", Default = Color3.fromRGB(219, 29, 222), Callback = function(c) State.ChamsFillR, State.ChamsFillG, State.ChamsFillB = math.round(c.R * 255), math.round(c.G * 255), math.round(c.B * 255); pcall(ESPModule.updateESP) end })
ChamsGroup:CreateColorpicker({ Name = "outline color", Default = Color3.fromRGB(255, 255, 255), Callback = function(c) State.ChamsOutlineR, State.ChamsOutlineG, State.ChamsOutlineB = math.round(c.R * 255), math.round(c.G * 255), math.round(c.B * 255); pcall(ESPModule.updateESP) end })

local CamGroup = VisualsTab:CreateGroupbox("camera")
CamGroup:CreateToggle({ Name = "custom fov", Default = false, Callback = function(s) State.CustomFOVEnabled = s; if not s then pcall(CustomFOVModule.restoreFOV) else pcall(CustomFOVModule.applyFOV) end end })
CamGroup:CreateSlider({ Name = "fov value", Min = 50, Max = 130, Default = 90, Callback = function(v) State.CustomFOVValue = v; if State.CustomFOVEnabled then pcall(CustomFOVModule.applyFOV) end end })

local SkyGroup = VisualsTab:CreateGroupbox("skybox")
SkyGroup:CreateToggle({ Name = "custom skybox", Default = false, Callback = function(s) State.CustomSkyboxEnabled = s; if s then pcall(CustomSkyboxModule.applySkybox, State.CurrentSkyboxName) else pcall(CustomSkyboxModule.restoreSkybox) end end })
local skyboxNames = { "space", "sunset", "night", "neon city", "synthwave", "purple nebula", "blood moon", "daylight" }
if State.CurrentSkyboxName == nil then State.CurrentSkyboxName = "space" end
SkyGroup:CreateDropdown({ Name = "Skybox Style", List = skyboxNames, Default = "space", Callback = function(v) State.CurrentSkyboxName = v; if State.CustomSkyboxEnabled then pcall(CustomSkyboxModule.applySkybox, v) end end })

local FOVColorGroup = VisualsTab:CreateGroupbox("fov circle styling")
FOVColorGroup:CreateColorpicker({ Name = "circle color", Default = Color3.fromRGB(219, 29, 222), Callback = function(c) State.FOVR, State.FOVG, State.FOVB = math.round(c.R * 255), math.round(c.G * 255), math.round(c.B * 255) end })
FOVColorGroup:CreateSlider({ Name = "thickness", Min = 1, Max = 5, Default = 1, Callback = function(v) State.FOVThickness = v end })

local WeapChamsGroup = VisualsTab:CreateGroupbox("weapon chams")
WeapChamsGroup:CreateToggle({ Name = "weapon chams", Default = false, Callback = function(s) State.WeaponChamsEnabled = s end })
WeapChamsGroup:CreateToggle({ Name = "hand chams", Default = false, Callback = function(s) State.HandChamsEnabled = s end })
WeapChamsGroup:CreateDropdown({ Name = "cham mode", List = { "Normal", "Wireframe", "Outline" }, Default = "Normal", Callback = function(v)
    local modes = { ["Normal"] = 1, ["Wireframe"] = 2, ["Outline"] = 3 }
    State.WeaponChamsMode = modes[v] or 1
end })
WeapChamsGroup:CreateToggle({ Name = "always on top", Default = false, Callback = function(s) State.WeaponChamsDepth = s end })
WeapChamsGroup:CreateSlider({ Name = "weapon fill trans", Min = 0, Max = 100, Default = 30, Callback = function(v) State.WeaponChamsFillTrans = v / 100 end })
WeapChamsGroup:CreateSlider({ Name = "weapon outline trans", Min = 0, Max = 100, Default = 0, Callback = function(v) State.WeaponChamsOutlineTrans = v / 100 end })
WeapChamsGroup:CreateColorpicker({ Name = "weapon fill color", Default = Color3.fromRGB(219, 29, 222), Callback = function(c) State.WeaponChamsFillR, State.WeaponChamsFillG, State.WeaponChamsFillB = math.round(c.R * 255), math.round(c.G * 255), math.round(c.B * 255) end })
WeapChamsGroup:CreateColorpicker({ Name = "weapon outline color", Default = Color3.fromRGB(180, 180, 255), Callback = function(c) State.WeaponChamsOutlineR, State.WeaponChamsOutlineG, State.WeaponChamsOutlineB = math.round(c.R * 255), math.round(c.G * 255), math.round(c.B * 255) end })
WeapChamsGroup:CreateSlider({ Name = "hand fill trans", Min = 0, Max = 100, Default = 50, Callback = function(v) State.HandChamsFillTrans = v / 100 end })
WeapChamsGroup:CreateSlider({ Name = "hand outline trans", Min = 0, Max = 100, Default = 0, Callback = function(v) State.HandChamsOutlineTrans = v / 100 end })
WeapChamsGroup:CreateColorpicker({ Name = "hand fill color", Default = Color3.fromRGB(200, 130, 255), Callback = function(c) State.HandChamsFillR, State.HandChamsFillG, State.HandChamsFillB = math.round(c.R * 255), math.round(c.G * 255), math.round(c.B * 255) end })
WeapChamsGroup:CreateColorpicker({ Name = "hand outline color", Default = Color3.fromRGB(220, 180, 255), Callback = function(c) State.HandChamsOutlineR, State.HandChamsOutlineG, State.HandChamsOutlineB = math.round(c.R * 255), math.round(c.G * 255), math.round(c.B * 255) end })

local TracesGroup = VisualsTab:CreateGroupbox("bullet traces")
TracesGroup:CreateToggle({ Name = "enabled", Default = false, Callback = function(s) State.BulletTracesEnabled = s end })
TracesGroup:CreateSlider({ Name = "thickness (1-10)", Min = 1, Max = 10, Default = 2, Callback = function(v) State.BulletTraceThickness = v / 100 end })
TracesGroup:CreateSlider({ Name = "duration (1-5s)", Min = 1, Max = 5, Default = 1, Callback = function(v) State.BulletTraceDuration = v end })
TracesGroup:CreateColorpicker({ Name = "color", Default = Color3.fromRGB(219, 29, 222), Callback = function(c) State.BulletTraceColorR, State.BulletTraceColorG, State.BulletTraceColorB = math.round(c.R * 255), math.round(c.G * 255), math.round(c.B * 255) end })

local Hitgroup = VisualsTab:CreateGroupbox("hitsounds")
Hitgroup:CreateDropdown({ Name = "hitsound style", List = { "Default", "Click", "Skeet", "CS Headshot" }, Default = State.Hitsound or "Default", Callback = function(v) State.Hitsound = v end })

-- // ====== Tab: Rage ====== \\ --
local RageTab = Window:CreateTab("rage")

local RageGroup = RageTab:CreateGroupbox("exploits")
RageGroup:CreateToggle({ Name = "no recoil", Default = false, Callback = function(s) State.NoRecoilEnabled = s end })
RageGroup:CreateToggle({ Name = "no spread", Default = false, Callback = function(s) State.NoSpreadEnabled = s end })
RageGroup:CreateToggle({ Name = "infinite ammo", Default = false, Callback = function(s) State.InfiniteAmmoEnabled = s end })
RageGroup:CreateToggle({ Name = "speed boost (bypass)", Default = false, Callback = function(s) State.SpeedBoostEnabled = s end })
RageGroup:CreateSlider({ Name = "boost speed value", Min = 30, Max = 80, Default = 35, Callback = function(v) State.SpeedBoostValue = v end })
RageGroup:CreateToggle({ Name = "bhop", Default = false, Callback = function(s) State.BhopEnabled = s end })
RageGroup:CreateKeybind({ Name = "bhop keybind", Default = Enum.KeyCode.Space, Callback = function(k) State.BhopKey = k end })
RageGroup:CreateDropdown({ Name = "bhop key mode", List = { "Hold", "Toggle" }, Default = State.BhopKeyMode, Callback = function(v) State.BhopKeyMode = v; State.BhopActive = false end })
RageGroup:CreateToggle({ Name = "magic bullet (wallbang)", Default = false, Callback = function(s) State.MagicBulletEnabled = s end })

local SilentAimGroup = RageTab:CreateGroupbox("silent aim")
SilentAimGroup:CreateToggle({ Name = "enabled", Default = false, Callback = function(s) State.SilentAimEnabled = s end })
SilentAimGroup:CreateSlider({ Name = "hit chance", Min = 0, Max = 100, Default = 100, Callback = function(v) State.SilentAimHitChance = v end })
SilentAimGroup:CreateDropdown({ Name = "target part", List = { "Head", "Torso", "Random" }, Default = "Head", Callback = function(v)
            State.SilentAimTargetPart = v
        end })
SilentAimGroup:CreateToggle({ Name = "show fov circle", Default = false, Callback = function(s) State.SilentAimFOVEnabled = s end })
SilentAimGroup:CreateSlider({ Name = "fov radius", Min = 10, Max = 350, Default = 150, Callback = function(v) State.SilentAimFOVRadius = v end })
SilentAimGroup:CreateColorpicker({ Name = "fov color", Default = Color3.fromRGB(255, 100, 100), Callback = function(c) State.SilentAimFOVR, State.SilentAimFOVG, State.SilentAimFOVB = math.round(c.R * 255), math.round(c.G * 255), math.round(c.B * 255) end })
SilentAimGroup:CreateSlider({ Name = "fov thickness", Min = 1, Max = 5, Default = 1, Callback = function(v) State.SilentAimFOVThickness = v end })

-- // ====== Tab: Settings ====== \\ --
local MenuTab = Window:CreateTab("settings")

local HUDGroup = MenuTab:CreateGroupbox("hud settings")
HUDGroup:CreateToggle({ Name = "watermark", Default = false, Callback = function(s) State.WatermarkEnabled = s; pcall(WatermarkModule.toggle, s) end })
HUDGroup:CreateToggle({ Name = "keybinds list", Default = false, Callback = function(s) State.KeybindsEnabled = s; pcall(KeybindsListModule.toggle, s) end })
HUDGroup:CreateToggle({ Name = "active features list", Default = false, Callback = function(s) State.ActiveFeaturesEnabled = s; pcall(ActiveFeaturesModule.toggle, s) end })

local ConfigGroup = MenuTab:CreateGroupbox("configurations")
local configNameBox = ConfigGroup:CreateTextBox({ Name = "Profile Name", Default = "default", Placeholder = "Enter profile name..." })
ConfigGroup:CreateButton({ Name = "Save Profile", Callback = function()
    pcall(function() Library:SaveConfig(configNameBox.Get()) end)
end })
ConfigGroup:CreateButton({ Name = "Load Profile", Callback = function()
    pcall(function() Library:LoadConfig(configNameBox.Get()) end)
end })

local ThemeGroup = MenuTab:CreateGroupbox("theme customizer")
ThemeGroup:CreateColorpicker({ Name = "Accent Start Color", Default = State.ThemeAccentStart, Callback = function(c)
    State.ThemeAccentStart = c
    pcall(function() Library:SetAccentColors(State.ThemeAccentStart, State.ThemeAccentEnd) end)
end })
ThemeGroup:CreateColorpicker({ Name = "Accent End Color", Default = State.ThemeAccentEnd, Callback = function(c)
    State.ThemeAccentEnd = c
    pcall(function() Library:SetAccentColors(State.ThemeAccentStart, State.ThemeAccentEnd) end)
end })

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
    if tab.Button.Text:find("main") then
        tab.Content.Visible = true
        tab.UpdateVisuals(true)
    else
        tab.Content.Visible = false
        tab.UpdateVisuals(false)
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
    pcall(FOVCirclesModule.destroy)

    -- Cleanup ESP elements
    pcall(ESPModule.cleanupOldESP)

    -- Cleanup weapon/hand chams
    pcall(WeaponChamsModule.cleanup)

    -- Cleanup speed boost
    pcall(SpeedBoostModule.cleanup)

    -- Cleanup hitsounds
    pcall(HitsoundsModule.cleanup)

    -- Cleanup HUD elements and references
    if WatermarkModule and WatermarkModule.toggle then pcall(function() WatermarkModule.toggle(false) end) end
    if KeybindsListModule and KeybindsListModule.toggle then pcall(function() KeybindsListModule.toggle(false) end) end
    if ActiveFeaturesModule and ActiveFeaturesModule.toggle then pcall(function() ActiveFeaturesModule.toggle(false) end) end

    -- Destroy window
    if State.GlobalWindow then
        pcall(function() State.GlobalWindow:Destroy() end)
        State.GlobalWindow = nil
    end
end
getgenv().QuantixUnload = doUnload
getgenv().AbyssUnload = doUnload
