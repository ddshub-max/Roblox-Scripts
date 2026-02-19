--================================================================ 
-- SETTINGS & VARIABLES
--================================================================

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

local SAFE_HEIGHT_OFFSET = 3
local VOID_Y_LIMIT = -50
local RHYTHM_DELAY = 1 
local autoFarmActive = false

-- Variabel untuk fungsi Fly
local flyActive = false
local flySpeed = 50
local bodyVelocity, bodyGyro

--================================================================
-- LOAD RAYFIELD LIBRARY
--================================================================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "BOSSCDID | Event Hub",
    LoadingTitle = "Auto Quest Hub",
    LoadingSubtitle = "By BOSSCDID",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false, 
    Theme = "Default" 
})

--================================================================
-- CORE LOGIC (FARM & FLY)
--================================================================

-- Fungsi Fly Logic
local function updateFly()
    if flyActive then
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then
            if not bodyVelocity then
                bodyVelocity = Instance.new("BodyVelocity", hrp)
                bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                
                bodyGyro = Instance.new("BodyGyro", hrp)
                bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
                bodyGyro.D = 100
                bodyGyro.P = 10000
            end
            
            local cam = workspace.CurrentCamera
            local moveDir = Vector3.new(0, 0, 0)
            
            -- Kontrol sederhana menggunakan Camera LookVector
            bodyVelocity.Velocity = cam.CFrame.LookVector * flySpeed
            bodyGyro.CFrame = cam.CFrame
        end
    else
        if bodyVelocity then bodyVelocity:Destroy() bodyVelocity = nil end
        if bodyGyro then bodyGyro:Destroy() bodyGyro = nil end
    end
end

RunService.RenderStepped:Connect(function()
    if flyActive then updateFly() end
end)

-- (Fungsi getNearestAngpao dan startAutoFarm tetap sama seperti sebelumnya)
local function getTargetPart(obj)
    if not obj then return nil end
    if obj:IsA("Model") then return obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
    elseif obj:IsA("BasePart") then return obj end
    return nil
end

local function getNearestAngpao()
    local eventFolder = workspace:FindFirstChild("Event")
    local angpaoFolder = eventFolder and eventFolder:FindFirstChild("AngpaoFolder")
    if not angpaoFolder then return nil end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local nearest, shortest = nil, math.huge
    for _, obj in ipairs(angpaoFolder:GetChildren()) do
        if string.find(obj.Name, "Angpao") then
            local part = getTargetPart(obj)
            if part then
                local dist = (hrp.Position - part.Position).Magnitude
                if dist < shortest then shortest = dist nearest = obj end
            end
        end
    end
    return nearest
end

local function startAutoFarm()
    if _G.LoopRunning then return end
    _G.LoopRunning = true
    while autoFarmActive do
        local target = getNearestAngpao()
        if target then
            character:PivotTo(target:GetPivot() + Vector3.new(0, SAFE_HEIGHT_OFFSET, 0))
            task.wait(RHYTHM_DELAY)
            if not autoFarmActive then break end
            local prompt = target:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt then fireproximityprompt(prompt) end
            task.wait(RHYTHM_DELAY)
        else task.wait(1) end
    end
    _G.LoopRunning = false
end

--================================================================
-- RAYFIELD TABS
--================================================================

local MainTab = Window:CreateTab("🏠 Main Farm")
local MoveTab = Window:CreateTab("🚀 Movement")
local MiscTab = Window:CreateTab("⚙️ Misc")

-- [ MAIN TAB ]
MainTab:CreateSection("Event Automation")
MainTab:CreateToggle({
    Name = "Auto Farm Angpao",
    CurrentValue = false,
    Callback = function(Value)
        autoFarmActive = Value
        if autoFarmActive then task.spawn(startAutoFarm) end
    end,
})

MainTab:CreateSection("Teleports")
MainTab:CreateButton({
    Name = "TP Event NPC",
    Callback = function()
        local npc = workspace:FindFirstChild("Event") and workspace.Event:FindFirstChild("EventNPC")
        if npc then character:PivotTo(npc:GetPivot() * CFrame.new(0, SAFE_HEIGHT_OFFSET, 0)) end
    end,
})

-- [ MOVEMENT TAB - NEW ]
MoveTab:CreateSection("Fly Controls")
MoveTab:CreateToggle({
    Name = "Enable Fly",
    CurrentValue = false,
    Callback = function(Value)
        flyActive = Value
        if not Value then
            -- Reset velocity saat dimatikan agar tidak meluncur
            local hrp = character:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.AssemblyLinearVelocity = Vector3.zero end
        end
    end,
})

MoveTab:CreateSlider({
    Name = "Fly Speed",
    Range = {10, 300},
    Increment = 10,
    Suffix = "Speed",
    CurrentValue = 50,
    Callback = function(Value)
        flySpeed = Value
    end,
})

-- [ MISC TAB ]
MiscTab:CreateButton({
    Name = "Load Infinite Yield",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
    end,
})

--================================================================
-- UPDATES
--================================================================

player.CharacterAdded:Connect(function(char)
    character = char
    flyActive = false -- Reset fly saat mati/respawn
end)

Rayfield:Notify({
    Title = "Script Loaded!",
    Content = "Tab Movement sekarang tersedia.",
    Duration = 5
})
