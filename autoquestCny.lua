--================================================================ 
-- CONFIGURATION (PENGATURAN)
--================================================================
local CONFIG = {
    useWhitelist = false, -- Ubah ke 'false' jika ingin mematikan sistem whitelist
    whitelistURL = "https://pastebin.com/raw/fSuaeaUp", -- Link Pastebin daftar UserID
    scriptTitle = "Boss Script | Event Hub",
    scriptSubTitle = "by BOSS",
    theme = "Dark"
}

--================================================================ 
-- WHITELIST LOADER (ONLINE CHECK)
--================================================================
local Players = game:GetService("Players")
local player = Players.LocalPlayer

if CONFIG.useWhitelist then
    local success, whitelist = pcall(function()
        return loadstring(game:HttpGet(CONFIG.whitelistURL))()
    end)

    if success and type(whitelist) == "table" then
        local hasAccess = false
        
        -- Cek jika UserId ada di dalam tabel (baik sebagai key maupun value)
        if whitelist[player.UserId] then
            hasAccess = true
        else
            for _, id in pairs(whitelist) do
                if id == player.UserId then
                    hasAccess = true
                    break
                end
            end
        end

        if not hasAccess then
            player:Kick("Kamu tidak terdaftar di database BOSS Script.")
            return
        end
    else
        warn("Gagal memproses whitelist. Pastikan link Pastebin benar dan formatnya tabel.")
        return
    end
else
    print("Whitelist dinonaktifkan. Memuat script...")
end

--================================================================ 
-- SETTINGS & VARIABLES
--================================================================
local RunService = game:GetService("RunService")
local workspace = game:GetService("Workspace")
local character = player.Character or player.CharacterAdded:Wait()

local SAFE_HEIGHT_OFFSET = 3
local VOID_Y_LIMIT = -50
local RHYTHM_DELAY = 1 
local autoFarmActive = false

--================================================================
-- LOAD FLUENT LIBRARY (ACRYLIC STYLE)
--================================================================
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Window = Fluent:CreateWindow({
    Title = CONFIG.scriptTitle,
    SubTitle = CONFIG.scriptSubTitle,
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true, 
    Theme = CONFIG.theme,
    MinimizeKey = Enum.KeyCode.LeftControl
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
    
    local nearest, shortest = nil, math.huge
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
            if prompt then
                prompt.HoldDuration = 0
                prompt.RequiresLineOfSight = false
                fireproximityprompt(prompt)
            end
            task.wait(RHYTHM_DELAY)
        else
            task.wait(1)
        end
    end
    _G.LoopRunning = false
end

--================================================================
-- TABS & ELEMENTS
--================================================================
local Tabs = {
    Main = Window:AddTab({ Title = "Main Farm", Icon = "home" }),
    Misc = Window:AddTab({ Title = "Misc", Icon = "settings" })
}

-- SECTION: EVENT
Tabs.Main:AddSection("Event Automation")

local AutoFarmToggle = Tabs.Main:AddToggle("AutoFarm", {Title = "Auto Farm Angpao", Default = false })

AutoFarmToggle:OnChanged(function()
    autoFarmActive = Fluent.Options.AutoFarm.Value
    if autoFarmActive then
        Fluent:Notify({Title = "Auto Farm", Content = "Aktif!", Duration = 3})
        task.spawn(startAutoFarm)
    else
        Fluent:Notify({Title = "Auto Farm", Content = "Nonaktif!", Duration = 3})
    end
end)

-- SECTION: TELEPORTS
Tabs.Main:AddSection("Teleports")

Tabs.Main:AddButton({
    Title = "TP Event NPC",
    Callback = function()
        local npc = workspace:FindFirstChild("Event") and workspace.Event:FindFirstChild("EventNPC")
        if npc then character:PivotTo(npc:GetPivot() * CFrame.new(0, SAFE_HEIGHT_OFFSET, 0)) end
    end
})

Tabs.Main:AddButton({
    Title = "TP KeyMaster NPC",
    Callback = function()
        local npc = workspace:FindFirstChild("Event") and workspace.Event:FindFirstChild("KeymasterNPC")
        if npc then character:PivotTo(npc:GetPivot() * CFrame.new(0, SAFE_HEIGHT_OFFSET, 0)) end
    end
})

-- MISC TAB
Tabs.Misc:AddButton({
    Title = "Load Infinite Yield",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
    end
})

--================================================================
-- EXTRA UPDATES & SAFEGUARDS
--================================================================
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

Window:SelectTab(1)
Fluent:Notify({
    Title = "Script Ready!",
    Content = "Menu berhasil dimuat dengan efek Acrylic.",
    Duration = 5
})
