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

--================================================================
-- LOAD RAYFIELD LIBRARY
--================================================================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Finz Script | Event Hub",
    LoadingTitle = "Auto Quest Hub",
    LoadingSubtitle = "By Finz",
    ConfigurationSaving = {
        Enabled = false
    },
    KeySystem = false, 
    Theme = "Default" -- Kamu bisa ganti ke 'Dark', 'Ocean', dll
})

--================================================================
-- UTILS / HELPER FUNCTIONS
--================================================================

local function getTargetPart(obj)
    if not obj then return nil end
    if obj:IsA("Model") then
        return obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
    elseif obj:IsA("BasePart") then
        return obj
    end
    return nil
end

local function getNearestAngpao()
    local eventFolder = workspace:FindFirstChild("Event")
    local angpaoFolder = eventFolder and eventFolder:FindFirstChild("AngpaoFolder")
    if not angpaoFolder then return nil end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    
    local nearest = nil
    local shortest = math.huge
    
    for _, obj in ipairs(angpaoFolder:GetChildren()) do
        if string.find(obj.Name, "Angpao") then
            local part = getTargetPart(obj)
            if part then
                local dist = (hrp.Position - part.Position).Magnitude
                if dist < shortest then
                    shortest = dist
                    nearest = obj
                end
            end
        end
    end
    return nearest
end

--================================================================
-- CORE LOGIC
--================================================================

local function startAutoFarm()
    if _G.LoopRunning then return end
    _G.LoopRunning = true

    while autoFarmActive do
        local target = getNearestAngpao()
        if target then
            local modelCFrame = target:GetPivot()
            character:PivotTo(modelCFrame + Vector3.new(0, SAFE_HEIGHT_OFFSET, 0))
            
            task.wait(RHYTHM_DELAY)
            
            if not autoFarmActive then break end
            if target and target.Parent then
                local prompt = target:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt then
                    prompt.HoldDuration = 0
                    prompt.RequiresLineOfSight = false
                    fireproximityprompt(prompt)
                end
            end
            task.wait(RHYTHM_DELAY)
        else
            task.wait(1)
        end
    end
    _G.LoopRunning = false
end

--================================================================
-- RAYFIELD TABS & ELEMENTS
--================================================================

local MainTab = Window:CreateTab("🏠 Main Farm")

MainTab:CreateSection("Event Automation")

local AutoFarmToggle = MainTab:CreateToggle({
    Name = "Auto Farm Angpao",
    CurrentValue = false,
    Flag = "AutoFarmFlag", 
    Callback = function(Value)
        autoFarmActive = Value
        if autoFarmActive then
            Rayfield:Notify({Title = "Auto Farm", Content = "Auto Farm AKTIF!", Duration = 3})
            task.spawn(startAutoFarm)
        else
            Rayfield:Notify({Title = "Auto Farm", Content = "Auto Farm NONAKTIF!", Duration = 3})
        end
    end,
})

MainTab:CreateSection("Teleports")

MainTab:CreateButton({
    Name = "TP Event NPC",
    Callback = function()
        local npc = workspace:FindFirstChild("Event") and workspace.Event:FindFirstChild("EventNPC")
        if npc then
            character:PivotTo(npc:GetPivot() * CFrame.new(0, SAFE_HEIGHT_OFFSET, 0))
        end
    end,
})

MainTab:CreateButton({
    Name = "TP KeyMaster NPC",
    Callback = function()
        local npc = workspace:FindFirstChild("Event") and workspace.Event:FindFirstChild("KeymasterNPC")
        if npc then
            character:PivotTo(npc:GetPivot() * CFrame.new(0, SAFE_HEIGHT_OFFSET, 0))
        end
    end,
})

MainTab:CreateButton({
    Name = "TP Nearest Angpao (Manual)",
    Callback = function()
        local target = getNearestAngpao()
        if target then
            character:PivotTo(target:GetPivot() + Vector3.new(0, SAFE_HEIGHT_OFFSET, 0))
        end
    end,
})

local MiscTab = Window:CreateTab("⚙️ Misc")

MiscTab:CreateButton({
    Name = "Load Infinite Yield",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
    end,
})

--================================================================
-- EXTRA UPDATES
--================================================================

-- Anti Void
RunService.Heartbeat:Connect(function()
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if hrp and hrp.Position.Y < VOID_Y_LIMIT then
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.CFrame = CFrame.new(0, 50, 0)
    end
end)

player.CharacterAdded:Connect(function(char)
    character = char
end)

Rayfield:Notify({
    Title = "Script Ready!",
    Content = "Tekan G untuk menyembunyikan menu.",
    Duration = 5
})
