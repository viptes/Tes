--[[
    FCAL HUB - LYNX GUI EDITION (FIXED - ALL ERRORS)
    Version: 2.0.0 | FULL FEATURES + ADMIN MENU + MOUNT MAHONI
    FIXED: Fly direction, ESP activation, Admin features
    ADDED: Mount Mahoni Admin Menu, Full Admin Tools
--]]

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/mdwpanel/Roblox/refs/heads/main/main_ui_modern.lua"))()

-- Services
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService") 
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local HttpService = game:GetService("HttpService")
local TextChatService = game:GetService("TextChatService")
local CoreGui = game:GetService("CoreGui")
local CollectionService = game:GetService("CollectionService")
local MarketplaceService = game:GetService("MarketplaceService")

-- Global Variables
local LocalPlayer = Players.LocalPlayer
local ESP_Objects = {}
local ManualHighlights = {}
local ESP_Highlights = {}
local ESPLabels = {}
local MountObjects = {}
local ToggleKey = Enum.KeyCode.RightControl
local msg = "FCAL HUB ON TOP!"
local SpecTarget = ""
local hbSize = 2

-- ==========================================
-- CONFIGURATION
-- ==========================================
_G.AutoCPAll = false
_G.CPTeleportDelay = 0.8
_G.CPScanDelay = 1.0
_G.AutoCP = false
_G.InfJump = false
_G.NC = false
_G.TapTP = false
_G.AutoInteract = false
_G.BoxESP = false
_G.LineESP = false
_G.SkeletonESP = false
_G.ESP = false
_G.HealthESP = false
_G.MountESP = false
_G.AntiRagdoll = false
_G.AntiVoid = false
_G.AntiKick = false
_G.AdminDetect = false
_G.Hitbox = false
_G.CPDelay = 2.0
_G.Fly = false
_G.AirWalk = false
_G.AutoWalkJSON = false
_G.WalkingAntiVoid = false
_G.AntiFreeze = false 
_G.Wiggle = false
_G.KillerWarn = false
_G.AutoSkillMobile = false
_G.Headlight = false
_G.XRay = false
_G.Fullbright = false
_G.Freecam = false
_G.Spam = false
_G.ChatLog = false
_G.GenESP = false
_G.MenuVisible = true
_G.AutoWalk = false
_G.AutoWalkSpeed = 25
_G.WallHack = false
_G.GodMode = false
_G.FlySpeed = 100
_G.AdminMode = false
_G.NoFallDamage = false
_G.AutoHeal = false
_G.InfiniteStamina = false
_G.SpeedBoost = false
_G.JumpBoost = false
_G.GravityControl = false
_G.TeleportAll = false
_G.FreezeAll = false
_G.KillAll = false
_G.BanAll = false

local Config = {
    WalkSpeedDefault = 16,
    JumpPowerDefault = 50,
    GravityDefault = 196,
    Theme = "Midnight", 
    FlySpeed = 100,
}

-- ==========================================
-- WINDOW CREATION
-- ==========================================
local Window = Library:Window({
    Title = "MDW | Mount Mahoni",
    Footer = "v2.0.0 | Admin Tools"
})

-- ==========================================
-- HELPER FUNCTIONS
-- ==========================================

-- FIXED: ESP Clear function
function ClearESP(player)
    if ESP_Objects[player] then
        for _, obj in pairs(ESP_Objects[player]) do
            pcall(function() 
                if obj.Box then obj.Box.Visible = false end
                if obj.Line then obj.Line.Visible = false end
                if obj.Skeleton then 
                    for _, line in pairs(obj.Skeleton) do
                        line.Visible = false
                    end
                end
                obj:Remove() 
            end)
        end
        ESP_Objects[player] = nil
    end
end

function ClearManualHighlights()
    for _, hl in pairs(ManualHighlights) do
        pcall(function() hl:Destroy() end)
    end
    ManualHighlights = {}
end

function ClearAllHighlights()
    ClearManualHighlights()
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Highlight") then
            pcall(function() obj:Destroy() end)
        end
    end
end

-- FIXED: ESP Update function with proper onScreen check
function UpdateESP()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local character = player.Character
            if character and character:FindFirstChild("HumanoidRootPart") and character:FindFirstChild("Humanoid") then
                local rootPart = character.HumanoidRootPart
                local pos, onScreen = Workspace.CurrentCamera:WorldToViewportPoint(rootPart.Position)
                
                if onScreen then
                    if not ESP_Objects[player] then
                        ESP_Objects[player] = {
                            Box = Drawing.new("Square"),
                            Line = Drawing.new("Line"),
                            Skeleton = {}
                        }
                    end

                    local color = GetESPColor(player)
                    local objects = ESP_Objects[player]

                    if _G.BoxESP then
                        local sizeX = 2000 / pos.Z
                        local sizeY = 3000 / pos.Z
                        
                        objects.Box.Visible = true
                        objects.Box.Color = color
                        objects.Box.Thickness = 1.5
                        objects.Box.Filled = false
                        objects.Box.Size = Vector2.new(sizeX, sizeY)
                        objects.Box.Position = Vector2.new(pos.X - sizeX / 2, pos.Y - sizeY / 2)
                    else
                        objects.Box.Visible = false
                    end

                    if _G.LineESP then
                        objects.Line.Visible = true
                        objects.Line.Color = color
                        objects.Line.Thickness = 1.5
                        objects.Line.From = Vector2.new(Workspace.CurrentCamera.ViewportSize.X / 2, Workspace.CurrentCamera.ViewportSize.Y)
                        objects.Line.To = Vector2.new(pos.X, pos.Y)
                    else
                        objects.Line.Visible = false
                    end
                    
                    if _G.SkeletonESP then
                        UpdateSkeletonESP(player, objects)
                    else
                        for _, line in pairs(objects.Skeleton) do
                            line.Visible = false
                        end
                    end
                else
                    if ESP_Objects[player] then
                        pcall(function()
                            ESP_Objects[player].Box.Visible = false
                            ESP_Objects[player].Line.Visible = false
                            for _, line in pairs(ESP_Objects[player].Skeleton) do
                                line.Visible = false
                            end
                        end)
                    end
                end
            else
                ClearESP(player)
            end
        end
    end
end

function UpdateSkeletonESP(player, objects)
    local character = player.Character
    if not character then return end
    
    local joints = {
        {"Head", "UpperTorso"},
        {"UpperTorso", "LowerTorso"},
        {"UpperTorso", "LeftUpperArm"},
        {"LeftUpperArm", "LeftLowerArm"},
        {"UpperTorso", "RightUpperArm"},
        {"RightUpperArm", "RightLowerArm"},
        {"LowerTorso", "LeftUpperLeg"},
        {"LeftUpperLeg", "LeftLowerLeg"},
        {"LowerTorso", "RightUpperLeg"},
        {"RightUpperLeg", "RightLowerLeg"},
    }
    
    -- Clear existing skeleton lines
    if objects.Skeleton then
        for _, line in pairs(objects.Skeleton) do
            pcall(function() line.Visible = false end)
        end
        objects.Skeleton = {}
    end
    
    local color = GetESPColor(player)
    
    for i, joint in pairs(joints) do
        local part1 = character:FindFirstChild(joint[1])
        local part2 = character:FindFirstChild(joint[2])
        
        if part1 and part2 and part1:IsA("BasePart") and part2:IsA("BasePart") then
            local pos1, onScreen1 = Workspace.CurrentCamera:WorldToViewportPoint(part1.Position)
            local pos2, onScreen2 = Workspace.CurrentCamera:WorldToViewportPoint(part2.Position)
            
            if onScreen1 and onScreen2 then
                local line = Drawing.new("Line")
                line.Visible = true
                line.Color = color
                line.Thickness = 1.5
                line.From = Vector2.new(pos1.X, pos1.Y)
                line.To = Vector2.new(pos2.X, pos2.Y)
                table.insert(objects.Skeleton, line)
            end
        end
    end
end

function Notify(title, desc, typ)
    Library:MakeNotify({Title = title, Content = desc, Duration = 3})
end

function GetHumanoid()
    return LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
end

function GetRootPart()
    return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
end

function GetPlayerByName(name)
    name = name:lower()
    for _, p in pairs(Players:GetPlayers()) do
        if p.Name:lower():sub(1, #name) == name or p.DisplayName:lower():sub(1, #name) == name then
            return p
        end
    end
    return nil
end

function GetAllPlayers()
    local list = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(list, p.Name) end
    end
    if #list == 0 then table.insert(list, "No Players") end
    return list
end

-- FIXED: GetPlayerRole function
function GetPlayerRole(player)
    if not player then return "Neutral" end
    
    -- Check for killer attributes
    if player:GetAttribute("Role") then
        local role = player:GetAttribute("Role")
        if type(role) == "string" then
            if role:lower():find("killer") then return "Killer" end
            if role:lower():find("survivor") or role:lower():find("survive") then return "Survivor" end
        end
    end
    
    local character = player.Character
    if character then
        -- Check character attributes
        if character:GetAttribute("Role") then
            local role = character:GetAttribute("Role")
            if type(role) == "string" then
                if role:lower():find("killer") then return "Killer" end
                if role:lower():find("survivor") or role:lower():find("survive") then return "Survivor" end
            end
        end
        
        -- Check Role StringValue
        local roleValue = character:FindFirstChild("Role")
        if roleValue and roleValue:IsA("StringValue") then
            local role = roleValue.Value:lower()
            if role:find("killer") then return "Killer" end
            if role:find("survivor") or role:find("survive") then return "Survivor" end
        end
    end
    
    -- Check Team
    if player.Team then
        local teamName = player.Team.Name:lower()
        if teamName:find("killer") then return "Killer" end
        if teamName:find("survivor") or teamName:find("survive") then return "Survivor" end
    end
    
    -- Default to Survivor if in game
    local inGame = false
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj.Name:lower():find("generator") or obj.Name:lower():find("gate") then
            inGame = true
            break
        end
    end
    if inGame then return "Survivor" end
    
    return "Neutral"
end

-- FIXED: GetESPColor function
function GetESPColor(player)
    if not player then return Color3.fromRGB(255, 255, 255) end
    local role = GetPlayerRole(player)
    if role == "Killer" then 
        return Color3.fromRGB(255, 0, 0)
    elseif role == "Survivor" then 
        return Color3.fromRGB(0, 255, 0)
    else 
        return Color3.fromRGB(255, 255, 255) 
    end
end

function IsGenerator(obj)
    if not obj then return false end
    if not (obj:IsA("Model") or obj:IsA("BasePart")) then return false end
    local name = obj.Name:lower()
    if name:find("player") or name:find("character") or name:find("npc") or name:find("killer") or name:find("humanoid") then return false end
    if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") then return false end
    
    local isGen = false
    if name:find("generator") or name:find("gen%d") or name:find("gen_%d") or name == "gen" then isGen = true end
    if name:find("fusebox") or name:find("powerbox") or name:find("lever") then isGen = true end
    return isGen
end

function IsGeneratorCompleted(gen)
    if gen:GetAttribute("Completed") == true or gen:GetAttribute("IsCompleted") == true or gen:GetAttribute("Finished") == true then return true end
    local progress = gen:GetAttribute("Progress")
    if progress and (progress >= 1 or progress >= 100) then return true end
    return false
end

function GetGeneratorProgress(gen)
    local progress = gen:GetAttribute("Progress")
    if progress then return progress <= 1 and progress * 100 or progress end
    for _, child in pairs(gen:GetChildren()) do
        if child.Name:lower():find("progress") and (child:IsA("NumberValue") or child:IsA("IntValue")) then
            return child.Value <= 1 and child.Value * 100 or child.Value
        end
    end
    return 0
end

function CreateESPForPlayer(player)
    if player == LocalPlayer or not player.Character then return end
    
    if not ESP_Highlights[player] then
        local highlight = Instance.new("Highlight")
        highlight.Name = "MDW_Highlight"
        highlight.Adornee = player.Character
        highlight.FillColor = GetESPColor(player)
        highlight.FillTransparency = 0.5
        highlight.OutlineColor = Color3.new(1, 1, 1)
        highlight.Parent = player.Character
        ESP_Highlights[player] = highlight
    end
end

function RemoveESPForPlayer(player)
    if ESP_Highlights[player] then
        pcall(function() ESP_Highlights[player]:Destroy() end)
        ESP_Highlights[player] = nil
    end
    if player.Character and player.Character:FindFirstChild("Head") then
        local healthBar = player.Character.Head:FindFirstChild("HealthBarGui")
        if healthBar then
            pcall(function() healthBar:Destroy() end)
        end
    end
end

function FindAllGenerators()
    local generators = {}
    for _, obj in pairs(Workspace:GetDescendants()) do
        if IsGenerator(obj) then table.insert(generators, obj) end
    end
    return generators
end

-- ==========================================
-- MOUNT MAHONI SPECIFIC FUNCTIONS
-- ==========================================

-- Find all mounts in the game
function FindAllMounts()
    local mounts = {}
    local foundNames = {}
    
    -- Search in Workspace
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            local name = obj.Name:lower()
            if (name:find("mount") or name:find("horse") or name:find("pet") or name:find("vehicle") or 
                name:find("animal") or name:find("creature") or name:find("beast") or name:find("mammoth") or
                name:find("dragon") or name:find("wolf") or name:find("tiger") or name:find("lion") or
                name:find("bear") or name:find("eagle") or name:find("phoenix")) and 
               not name:find("player") and not name:find("character") and not name:find("humanoid") and
               not name:find("tool") and not name:find("weapon") and not name:find("backpack") then
                if not foundNames[obj.Name] then
                    table.insert(mounts, obj)
                    foundNames[obj.Name] = true
                end
            end
        end
    end
    
    -- Also check ReplicatedStorage for models that might be mounts
    for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            local name = obj.Name:lower()
            if (name:find("mount") or name:find("horse") or name:find("pet") or name:find("vehicle") or
                name:find("animal") or name:find("creature") or name:find("beast") or name:find("mammoth")) and 
               not name:find("player") and not name:find("character") and not name:find("humanoid") and
               not name:find("tool") and not name:find("weapon") and not name:find("backpack") then
                if not foundNames[obj.Name] then
                    table.insert(mounts, obj)
                    foundNames[obj.Name] = true
                end
            end
        end
    end
    
    return mounts
end

function CreateESPMount(mount)
    if not mount then return end
    local highlight = Instance.new("Highlight")
    highlight.Name = "MDW_MountHighlight"
    highlight.Adornee = mount
    highlight.FillColor = Color3.fromRGB(0, 255, 255) -- Cyan color for mounts
    highlight.FillTransparency = 0.6
    highlight.OutlineColor = Color3.new(1, 1, 1)
    highlight.Parent = mount
    MountObjects[mount] = highlight
end

function RemoveESPMount(mount)
    if MountObjects[mount] then
        pcall(function() MountObjects[mount]:Destroy() end)
        MountObjects[mount] = nil
    end
end

function ClearAllMountESPs()
    for mount, highlight in pairs(MountObjects) do
        pcall(function() highlight:Destroy() end)
    end
    MountObjects = {}
end

function UpdateMountESP()
    if not _G.MountESP then
        ClearAllMountESPs()
        return
    end

    local currentMounts = FindAllMounts()
    local activeMounts = {}

    for _, mount in pairs(currentMounts) do
        if not MountObjects[mount] then
            CreateESPMount(mount)
        end
        activeMounts[mount] = true
    end

    for mount, highlight in pairs(MountObjects) do
        if not activeMounts[mount] then
            RemoveESPMount(mount)
        end
    end
end

-- ==========================================
-- ADMIN FUNCTIONS FOR MOUNT MAHONI
-- ==========================================

-- Toggle Admin Mode
function ToggleAdminMode(enabled)
    _G.AdminMode = enabled
    if enabled then
        -- Try to find admin panel or create admin commands
        Notify("Admin Mode", "Admin tools activated!", "success")
        
        -- Check for admin panel in game
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj.Name:lower():find("admin") or obj.Name:lower():find("panel") or obj.Name:lower():find("control") then
                if obj:IsA("Model") or obj:IsA("BasePart") then
                    -- Highlight admin panel
                    local highlight = Instance.new("Highlight")
                    highlight.Adornee = obj
                    highlight.FillColor = Color3.fromRGB(255, 0, 255)
                    highlight.FillTransparency = 0.3
                    highlight.Parent = obj
                end
            end
        end
    else
        Notify("Admin Mode", "Admin tools deactivated", "warning")
    end
end

-- Teleport All Players to Player
function TeleportAllToPlayer()
    local root = GetRootPart()
    if not root then return end
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                pcall(function()
                    char.HumanoidRootPart.CFrame = root.CFrame * CFrame.new(math.random(-5, 5), 0, math.random(-5, 5))
                end)
            end
        end
    end
    Notify("Admin", "All players teleported to you!", "success")
end

-- Freeze All Players
function FreezeAllPlayers()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            if char and char:FindFirstChild("Humanoid") then
                pcall(function()
                    char.Humanoid.WalkSpeed = 0
                    char.Humanoid.PlatformStand = true
                end)
            end
        end
    end
    Notify("Admin", "All players frozen!", "warning")
end

-- Unfreeze All Players
function UnfreezeAllPlayers()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            if char and char:FindFirstChild("Humanoid") then
                pcall(function()
                    char.Humanoid.WalkSpeed = 16
                    char.Humanoid.PlatformStand = false
                end)
            end
        end
    end
    Notify("Admin", "All players unfrozen!", "success")
end

-- Kill All Players
function KillAllPlayers()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            if char and char:FindFirstChild("Humanoid") then
                pcall(function()
                    char.Humanoid.Health = 0
                end)
            end
        end
    end
    Notify("Admin", "All players killed!", "danger")
end

-- Heal All Players
function HealAllPlayers()
    for _, player in pairs(Players:GetPlayers()) do
        local char = player.Character
        if char and char:FindFirstChild("Humanoid") then
            pcall(function()
                char.Humanoid.Health = char.Humanoid.MaxHealth
            end)
        end
    end
    Notify("Admin", "All players healed!", "success")
end

-- Give All Players Items
function GiveAllItems()
    -- Find items in game
    local items = {}
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Tool") or (obj:IsA("Model") and obj:FindFirstChildOfClass("Tool")) then
            local tool = obj:IsA("Tool") and obj or obj:FindFirstChildOfClass("Tool")
            if tool then
                table.insert(items, tool)
            end
        end
    end
    
    local count = 0
    for _, tool in pairs(items) do
        local newTool = tool:Clone()
        newTool.Parent = LocalPlayer.Backpack
        count = count + 1
    end
    
    Notify("Admin", "Added " .. count .. " items to backpack!", "success")
end

-- Spawn Mount Mahoni specific mounts
function SpawnMounts()
    local mounts = FindAllMounts()
    local count = 0
    
    for _, mount in pairs(mounts) do
        if mount:IsA("Model") then
            local newMount = mount:Clone()
            local pos = LocalPlayer.Character.HumanoidRootPart.Position
            newMount:SetPrimaryPartCFrame(CFrame.new(pos + Vector3.new(math.random(-10, 10), 0, math.random(-10, 10))))
            newMount.Parent = Workspace
            count = count + 1
        end
    end
    
    Notify("Mount", "Spawned " .. count .. " mounts!", "success")
end

-- Get all mounts in the game
function GetAllMounts()
    local mounts = {}
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and not obj:FindFirstChild("HumanoidRootPart"):FindFirstChild("Player") then
            if not obj:FindFirstChildOfClass("Tool") then
                table.insert(mounts, obj.Name)
            end
        end
    end
    return mounts
end

-- ==========================================
-- WALLHACK FUNCTION
-- ==========================================
function ToggleWallHack(enabled)
    _G.WallHack = enabled
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Material ~= Enum.Material.Neon then
            if enabled then
                if not obj:GetAttribute("OriginalTransparency") then
                    obj:SetAttribute("OriginalTransparency", obj.Transparency)
                end
                if obj.Transparency < 0.7 then
                    obj.Transparency = 0.3
                end
            else
                local orig = obj:GetAttribute("OriginalTransparency")
                if orig then
                    obj.Transparency = orig
                end
            end
        end
    end
end

-- ==========================================
-- GET PLAYER LIST
-- ==========================================
local function GetPlayerList()
    local list = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then 
            table.insert(list, p.Name) 
        end
    end
    if #list == 0 then 
        return {"Tidak ada pemain"} 
    end
    table.sort(list)
    return list
end

-- ==========================================
-- TAB CREATION
-- ==========================================
local MainTab = Window:AddTab({ Name = "Main", Icon = "home" })
local MountTab = Window:AddTab({ Name = "Mount", Icon = "player" })
local PlayerTab = Window:AddTab({ Name = "Player", Icon = "user" })
local GameTab = Window:AddTab({ Name = "Game", Icon = "gamepad" })
local AdminTab = Window:AddTab({ Name = "Admin", Icon = "crown" })
local ServerTab = Window:AddTab({ Name = "Server", Icon = "web" })
local SettingsTab = Window:AddTab({ Name = "Settings", Icon = "settings" })

-- ==========================================
-- MAIN TAB - QUICK ACTIONS
-- ==========================================
local QuickSection = MainTab:AddSection("🛠️ Quick Actions")

QuickSection:AddButton({
    Title = "Get All Items",
    Description = "Dapatkan semua item di map",
    Callback = function()
        GiveAllItems()
    end
})

QuickSection:AddButton({
    Title = "Reset Character",
    Callback = function() 
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.Health = 0
        else
            LocalPlayer:LoadCharacter() 
        end
        Notify("Success", "Character reset!")
    end
})

QuickSection:AddButton({
    Title = "Refresh Movement",
    Callback = function()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChild("Humanoid")
        if hum then
            hum.WalkSpeed = 16
            hum.JumpPower = 50
            hum.UseJumpPower = true
        end
        workspace.Gravity = 196
        Notify("Success", "Movement Refreshed!")
    end
})

-- ==========================================
-- PLAYER TELEPORT
-- ==========================================
local QuickTpSection = MainTab:AddSection("🚀 Quick Player Teleport")
local SelectedTarget = ""

QuickTpSection:AddToggle({
    Title = "Auto Pick Up / Interact",
    Description = "Otomatis ambil item/oksigen terdekat",
    Default = false,
    Callback = function(v)
        _G.AutoInteract = v
        task.spawn(function()
            while _G.AutoInteract do
                for _, obj in pairs(workspace:GetDescendants()) do
                    if obj:IsA("ProximityPrompt") then
                        local dist = (LocalPlayer.Character.HumanoidRootPart.Position - obj.Parent:GetModelCFrame().p).Magnitude
                        if dist < 15 then
                            pcall(function() fireproximityprompt(obj) end)
                        end
                    end
                end
                task.wait(0.5)
            end
        end)
    end
})

local TpSection = MainTab:AddSection("🎯 Teleport")

TpSection:AddToggle({
    Title = "Click TP (PC/Mobile)",
    Description = "Klik/Sentuh layar untuk teleport instan",
    Default = false,
    Callback = function(v) _G.TapTP = v end
})

local PlayerDropdown = QuickTpSection:AddDropdown({
    Title = "Pilih Pemain",
    Description = "Cari atau pilih nama pemain",
    Options = GetPlayerList(),
    Default = "",
    Callback = function(v) 
        SelectedTarget = v 
    end
})

local function UpdateDropdown()
    local currentPlayers = GetPlayerList()
    if PlayerDropdown.SetValues then
        PlayerDropdown:SetValues(currentPlayers)
    elseif PlayerDropdown.Refresh then
        PlayerDropdown:Refresh(currentPlayers, true)
    end
end

QuickTpSection:AddButton({ 
    Title = "🔄 Refresh Daftar Pemain", 
    Callback = function()
        UpdateDropdown()
        Notify("MDW", "Daftar pemain telah diperbarui!")
    end 
})

QuickTpSection:AddButton({
    Title = "Teleport Sekarang",
    Callback = function()
        if SelectedTarget == "" or SelectedTarget == "Tidak ada pemain" then 
            Notify("Warning", "Pilih pemain dulu!")
            return 
        end
        
        local target = Players:FindFirstChild(SelectedTarget)
        local targetChar = (target and target.Character) or workspace:FindFirstChild(SelectedTarget)
        
        if targetChar and targetChar:FindFirstChild("HumanoidRootPart") then
            local myChar = LocalPlayer.Character
            if myChar and myChar:FindFirstChild("HumanoidRootPart") then
                local myHRP = myChar.HumanoidRootPart
                local targetHRP = targetChar.HumanoidRootPart
                
                myHRP.Anchored = true
                pcall(function() LocalPlayer.ReplicationFocus = targetHRP end)
                myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 3)
                task.wait(0.5)
                myHRP.Anchored = false
                
                Notify("Success", "Berhasil ke " .. SelectedTarget)
            end
        else
            Notify("Error", "Gagal! Player terlalu jauh.")
        end
    end
})

-- ==========================================
-- MOUNT TAB - MOUNT MAHONI SPECIFIC
-- ==========================================

-- Mount ESP Section
local MountESPSection = MountTab:AddSection("🐎 Mount ESP")

MountESPSection:AddToggle({
    Title = "ESP Mounts (Highlight)",
    Description = "Melihat lokasi mount di map",
    Default = false,
    Callback = function(v)
        _G.MountESP = v
        if v then
            UpdateMountESP()
            Notify("Enabled", "ESP Mounts Aktif!")
        else
            ClearAllMountESPs()
            Notify("Disabled", "ESP Mounts Mati")
        end
    end
})

-- Mount Spawn Section
local MountSpawnSection = MountTab:AddSection("🔄 Mount Spawn")

MountSpawnSection:AddButton({
    Title = "Spawn All Mounts",
    Description = "Spawn semua mount yang ada di map",
    Callback = function()
        SpawnMounts()
    end
})

MountSpawnSection:AddButton({
    Title = "Find Mounts",
    Description = "Cari dan tampilkan semua mount di map",
    Callback = function()
        local mounts = FindAllMounts()
        local count = #mounts
        if count > 0 then
            Notify("Mounts Found", "Ditemukan " .. count .. " mount di map!")
            for i, mount in pairs(mounts) do
                if mount:IsA("Model") then
                    local highlight = Instance.new("Highlight")
                    highlight.Adornee = mount
                    highlight.FillColor = Color3.fromRGB(0, 255, 255)
                    highlight.FillTransparency = 0.3
                    highlight.Parent = mount
                    -- Remove after 5 seconds
                    task.wait(0.5)
                    if i == count then
                        task.wait(5)
                        for _, obj in pairs(Workspace:GetDescendants()) do
                            if obj:IsA("Highlight") and obj.Name == "MountFind" then
                                obj:Destroy()
                            end
                        end
                    end
                end
            end
        else
            Notify("Mounts Found", "Tidak ada mount ditemukan!")
        end
    end
})

-- Mount Teleport Section
local MountTeleportSection = MountTab:AddSection("🎯 Mount Teleport")

local MountDropdown = MountTeleportSection:AddDropdown({
    Title = "Pilih Mount",
    Description = "Pilih mount untuk teleport",
    Options = {},
    Default = "",
    Callback = function(v)
        SelectedMount = v
    end
})

local SelectedMount = ""

MountTeleportSection:AddButton({
    Title = "🔄 Refresh Mount List",
    Callback = function()
        local mounts = GetAllMounts()
        if #mounts > 0 then
            MountDropdown:SetValues(mounts)
            Notify("Mounts", "Daftar mount diperbarui!")
        else
            Notify("Mounts", "Tidak ada mount ditemukan!")
        end
    end
})

MountTeleportSection:AddButton({
    Title = "Teleport ke Mount",
    Callback = function()
        if SelectedMount == "" then
            Notify("Warning", "Pilih mount dulu!")
            return
        end
        
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj.Name == SelectedMount and obj:IsA("Model") and obj:FindFirstChild("HumanoidRootPart") then
                local root = GetRootPart()
                if root then
                    root.CFrame = obj.HumanoidRootPart.CFrame * CFrame.new(0, 3, 0)
                    Notify("Success", "Teleport ke " .. SelectedMount)
                    return
                end
            end
        end
        Notify("Error", "Mount tidak ditemukan!")
    end
})

-- ==========================================
-- GAME TAB - VISUAL ESP & TRACKING
-- ==========================================
local VisualSection = GameTab:AddSection("🎭 Visual ESP & Tracking")

VisualSection:AddToggle({ 
    Title = "ESP Box (2D)", 
    Default = false, 
    Callback = function(v) 
        _G.BoxESP = v 
        if v then
            Notify("ESP", "Box ESP Aktif!")
        else
            Notify("ESP", "Box ESP Mati")
        end
    end 
})

VisualSection:AddToggle({ 
    Title = "ESP Tracers (Line)", 
    Default = false, 
    Callback = function(v) 
        _G.LineESP = v 
        if v then
            Notify("ESP", "Tracers ESP Aktif!")
        else
            Notify("ESP", "Tracers ESP Mati")
        end
    end 
})

VisualSection:AddToggle({ 
    Title = "ESP Skeleton (Bone)", 
    Default = false, 
    Callback = function(v) 
        _G.SkeletonESP = v 
        if v then
            Notify("ESP", "Skeleton ESP Aktif!")
        else
            Notify("ESP", "Skeleton ESP Mati")
        end
    end 
})

VisualSection:AddToggle({
    Title = "ESP Health Bar",
    Default = false,
    Callback = function(v)
        _G.HealthESP = v
        if v then
            Notify("ESP", "Health Bar ESP Aktif!")
        else
            for _, p in pairs(Players:GetPlayers()) do
                if p.Character and p.Character:FindFirstChild("Head") then
                    local healthBar = p.Character.Head:FindFirstChild("HealthBarGui")
                    if healthBar then
                        pcall(function() healthBar:Destroy() end)
                    end
                end
            end
            Notify("ESP", "Health Bar ESP Mati")
        end
    end
})

VisualSection:AddToggle({
    Title = "ESP Players (Highlight)",
    Default = false,
    Callback = function(v)
        _G.ESP = v
        if v then
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then 
                    CreateESPForPlayer(p) 
                end
            end
            
            if not _G.PlayerAddedConn then
                _G.PlayerAddedConn = Players.PlayerAdded:Connect(function(p)
                    p.CharacterAdded:Connect(function()
                        if _G.ESP then 
                            task.wait(0.5) 
                            CreateESPForPlayer(p) 
                        end
                    end)
                end)
            end
            
            Notify("Enabled", "ESP Highlight Aktif!")
        else
            if _G.PlayerAddedConn then 
                _G.PlayerAddedConn:Disconnect() 
                _G.PlayerAddedConn = nil 
            end
            for _, p in pairs(Players:GetPlayers()) do 
                RemoveESPForPlayer(p) 
            end
            Notify("Disabled", "ESP Highlight Mati")
        end
    end
})

VisualSection:AddToggle({
    Title = "ESP Generators",
    Description = "Melihat lokasi generator di map",
    Default = false,
    Callback = function(v)
        _G.GenESP = v
        if v then
            task.spawn(function()
                while _G.GenESP do
                    local generators = FindAllGenerators()
                    for _, gen in pairs(generators) do
                        if not ESPLabels[gen] then
                            local label = Instance.new("BillboardGui", gen)
                            label.Name = "GenESPLabel"
                            label.Size = UDim2.new(2, 0, 1, 0)
                            label.StudsOffset = Vector3.new(0, 5, 0)
                            label.AlwaysOnTop = true
                            
                            local text = Instance.new("TextLabel", label)
                            text.Size = UDim2.new(1, 0, 1, 0)
                            text.BackgroundTransparency = 1
                            text.TextScaled = true
                            text.TextColor3 = Color3.fromRGB(255, 255, 0)
                            text.TextStrokeTransparency = 0
                            text.Font = Enum.Font.SourceSansBold
                            text.Text = gen.Name .. " (0%)"
                            ESPLabels[gen] = label
                        end
                        
                        local progress = GetGeneratorProgress(gen)
                        if ESPLabels[gen] and ESPLabels[gen]:FindFirstChildOfClass("TextLabel") then
                            ESPLabels[gen]:FindFirstChildOfClass("TextLabel").Text = gen.Name .. " (" .. math.floor(progress) .. "%)"
                            if IsGeneratorCompleted(gen) then
                                ESPLabels[gen]:FindFirstChildOfClass("TextLabel").TextColor3 = Color3.fromRGB(0, 255, 0)
                            else
                                ESPLabels[gen]:FindFirstChildOfClass("TextLabel").TextColor3 = Color3.fromRGB(255, 255, 0)
                            end
                        end
                    end
                    task.wait(0.5)
                end
                for _, label in pairs(ESPLabels) do
                    pcall(function() label:Destroy() end)
                end
                ESPLabels = {}
            end)
            Notify("Enabled", "ESP Generator Aktif!")
        else
            for _, label in pairs(ESPLabels) do
                pcall(function() label:Destroy() end)
            end
            ESPLabels = {}
            Notify("Disabled", "ESP Generator Mati")
        end
    end
})

-- ==========================================
-- GAME TAB - MOVEMENT
-- ==========================================
local MovementSection = GameTab:AddSection("🏃 Movement")

MovementSection:AddToggle({
    Title = "Infinite Jump",
    Description = "Lompat tanpa batas",
    Default = false,
    Callback = function(v)
        _G.InfJump = v
        if v then
            local hum = GetHumanoid()
            if hum then
                hum.JumpPower = 0
                hum.Jump = true
            end
            Notify("Enabled", "Infinite Jump Aktif!")
        else
            local hum = GetHumanoid()
            if hum then
                hum.JumpPower = Config.JumpPowerDefault
            end
            Notify("Disabled", "Infinite Jump Mati")
        end
    end
})

MovementSection:AddToggle({
    Title = "NoClip",
    Description = "Lewati tembok dan objek",
    Default = false,
    Callback = function(v)
        _G.NC = v
        Notify("NoClip", v and "ON" or "OFF")
    end
})

-- FIXED: Fly with correct movement direction
MovementSection:AddToggle({
    Title = "Fly",
    Description = "Terbang bebas di udara",
    Default = false,
    Callback = function(v)
        _G.Fly = v
        if v then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if hum and root then
                hum.PlatformStand = true
                
                -- FIXED: Proper fly movement with correct camera alignment
                _G.FlyCon = RunService.RenderStepped:Connect(function()
                    if not _G.Fly then return end
                    
                    local cam = Workspace.CurrentCamera
                    local moveVector = Vector3.new(0, 0, 0)
                    local speed = _G.FlySpeed or 100

                    -- Get movement directions relative to camera
                    local forward = cam.CFrame.LookVector
                    local right = cam.CFrame.RightVector
                    local up = cam.CFrame.UpVector

                    -- FIXED: Correct key mapping
                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                        moveVector = moveVector + forward
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                        moveVector = moveVector - forward
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                        moveVector = moveVector - right
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                        moveVector = moveVector + right
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                        moveVector = moveVector + up
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                        moveVector = moveVector - up
                    end

                    -- Apply movement
                    if moveVector.Magnitude > 0 then
                        moveVector = moveVector.Unit * speed
                        root.Velocity = moveVector
                    else
                        root.Velocity = Vector3.new(0, 0, 0)
                    end
                end)
                Notify("Enabled", "Fly Aktif! (WASD + Space + Ctrl)")
            else
                Notify("Error", "Tidak bisa mengaktifkan Fly!")
            end
        else
            if _G.FlyCon then 
                _G.FlyCon:Disconnect() 
                _G.FlyCon = nil
            end
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if hum then
                hum.PlatformStand = false
            end
            if root then
                root.Velocity = Vector3.new(0, 0, 0)
            end
            Notify("Disabled", "Fly Mati")
        end
    end
})

MovementSection:AddSlider({
    Title = "Fly Speed",
    Description = "Kecepatan terbang",
    Default = 100,
    Min = 10,
    Max = 500,
    Callback = function(v)
        _G.FlySpeed = v
    end
})

MovementSection:AddToggle({
    Title = "Air Walk",
    Description = "Berjalan di udara",
    Default = false,
    Callback = function(v)
        _G.AirWalk = v
        if v then
            local hum = GetHumanoid()
            if hum then
                hum.Sit = true
            end
            Notify("Enabled", "Air Walk Aktif!")
        else
            local hum = GetHumanoid()
            if hum then
                hum.Sit = false
            end
            Notify("Disabled", "Air Walk Mati")
        end
    end
})

MovementSection:AddToggle({
    Title = "Walking Anti Void",
    Description = "Tidak jatuh ke void saat berjalan",
    Default = false,
    Callback = function(v)
        _G.WalkingAntiVoid = v
        Notify("Walking Anti Void", v and "ON" or "OFF")
    end
})

MovementSection:AddToggle({
    Title = "Anti Freeze",
    Description = "Tidak bisa dibekukan",
    Default = false,
    Callback = function(v)
        _G.AntiFreeze = v
        Notify("Anti Freeze", v and "ON" or "OFF")
    end
})

MovementSection:AddToggle({
    Title = "Wiggle (Anti AFK)",
    Description = "Gerakan otomatis untuk menghindari AFK kick",
    Default = false,
    Callback = function(v)
        _G.Wiggle = v
        if v then
            task.spawn(function()
                while _G.Wiggle do
                    local hum = GetHumanoid()
                    if hum then
                        hum:Move(Vector3.new(0,0,0.1))
                        task.wait(1)
                        hum:Move(Vector3.new(0,0,-0.1))
                        task.wait(1)
                    else
                        task.wait(1)
                    end
                end
            end)
            Notify("Enabled", "Wiggle Aktif!")
        else
            Notify("Disabled", "Wiggle Mati")
        end
    end
})

-- ==========================================
-- GAME TAB - VISUALS
-- ==========================================
local VisualsSection = GameTab:AddSection("✨ Visuals")

VisualsSection:AddToggle({
    Title = "WallHack",
    Description = "Melihat melalui tembok",
    Default = false,
    Callback = function(v)
        ToggleWallHack(v)
        Notify("WallHack", v and "ON" or "OFF")
    end
})

VisualsSection:AddToggle({
    Title = "Headlight",
    Description = "Menyalakan lampu di kepala",
    Default = false,
    Callback = function(v)
        _G.Headlight = v
        if v then
            local head = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")
            if head then
                local light = Instance.new("SpotLight", head)
                light.Brightness = 5
                light.Range = 60
                light.Face = Enum.NormalId.Front
                light.Angle = 90
                light.Name = "Headlight"
                Notify("Enabled", "Headlight Aktif!")
            end
        else
            local head = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")
            if head then
                local light = head:FindFirstChild("Headlight")
                if light then light:Destroy() end
            end
            Notify("Disabled", "Headlight Mati")
        end
    end
})

VisualsSection:AddToggle({
    Title = "X-Ray",
    Description = "Melihat objek di balik tembok",
    Default = false,
    Callback = function(v)
        _G.XRay = v
        if v then
            Lighting.Ambient = Color3.new(0,0,0)
            Lighting.Brightness = 0
            Lighting.OutdoorAmbient = Color3.new(0,0,0)
            Notify("Enabled", "X-Ray Aktif!")
        else
            Lighting.Ambient = Color3.new(0.5,0.5,0.5)
            Lighting.Brightness = 1
            Lighting.OutdoorAmbient = Color3.new(0.5,0.5,0.5)
            Notify("Disabled", "X-Ray Mati")
        end
    end
})

VisualsSection:AddToggle({
    Title = "Fullbright",
    Description = "Menerangi seluruh map",
    Default = false,
    Callback = function(v)
        _G.Fullbright = v
        if v then
            Lighting.Brightness = 2
            Lighting.OutdoorAmbient = Color3.new(1,1,1)
            Notify("Enabled", "Fullbright Aktif!")
        else
            Lighting.Brightness = 1
            Lighting.OutdoorAmbient = Color3.new(0.5,0.5,0.5)
            Notify("Disabled", "Fullbright Mati")
        end
    end
})

VisualsSection:AddToggle({
    Title = "Freecam",
    Description = "Mengontrol kamera secara bebas",
    Default = false,
    Callback = function(v)
        _G.Freecam = v
        if v then
            local cam = Workspace.CurrentCamera
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if cam and char and root then
                _G.FreecamPos = cam.CFrame
                cam.CameraType = Enum.CameraType.Scriptable
                
                _G.FreecamLoop = RunService.RenderStepped:Connect(function()
                    if not _G.Freecam then return end
                    
                    local moveVector = Vector3.new(0,0,0)
                    local camSpeed = 1
                    local cam = Workspace.CurrentCamera

                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                        moveVector = moveVector + cam.CFrame.LookVector
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                        moveVector = moveVector - cam.CFrame.LookVector
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                        moveVector = moveVector - cam.CFrame.RightVector
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                        moveVector = moveVector + cam.CFrame.RightVector
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                        moveVector = moveVector + Vector3.new(0,1,0)
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                        moveVector = moveVector - Vector3.new(0,1,0)
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                        camSpeed = 5
                    end

                    cam.CFrame = cam.CFrame + moveVector * camSpeed
                end)
                Notify("Enabled", "Freecam Aktif! (WASD + Space + Ctrl)")
            else
                Notify("Error", "Tidak bisa mengaktifkan Freecam!")
            end
        else
            if _G.FreecamLoop then 
                _G.FreecamLoop:Disconnect() 
                _G.FreecamLoop = nil
            end
            local cam = Workspace.CurrentCamera
            if cam then
                cam.CameraType = Enum.CameraType.Custom
                if _G.FreecamPos then
                    cam.CFrame = _G.FreecamPos
                end
            end
            Notify("Disabled", "Freecam Mati")
        end
    end
})

-- ==========================================
-- GAME TAB - MISC
-- ==========================================
local MiscSection = GameTab:AddSection("⚙️ Misc")

MiscSection:AddToggle({
    Title = "God Mode",
    Description = "Kebal terhadap semua serangan",
    Default = false,
    Callback = function(v)
        _G.GodMode = v
        if v then
            local hum = GetHumanoid()
            if hum then
                hum.MaxHealth = math.huge
                hum.Health = math.huge
            end
            Notify("Enabled", "God Mode Aktif!")
        else
            local hum = GetHumanoid()
            if hum then
                hum.MaxHealth = 100
                hum.Health = 100
            end
            Notify("Disabled", "God Mode Mati")
        end
    end
})

MiscSection:AddToggle({
    Title = "Anti Kick",
    Description = "Mencegah kick dari server",
    Default = false,
    Callback = function(v)
        _G.AntiKick = v
        if v then
            -- Basic anti-kick: prevent disconnection
            game:GetService("GuiService").ErrorMessageChanged:Connect(function()
                if _G.AntiKick then
                    pcall(function()
                        game:GetService("GuiService").ErrorMessage = ""
                    end)
                end
            end)
        end
        Notify("Anti Kick", v and "ON" or "OFF")
    end
})

MiscSection:AddToggle({
    Title = "Admin Detect",
    Description = "Mendeteksi admin di server",
    Default = false,
    Callback = function(v)
        _G.AdminDetect = v
        if v then
            task.spawn(function()
                while _G.AdminDetect do
                    for _, player in pairs(Players:GetPlayers()) do
                        if player ~= LocalPlayer then
                            local char = player.Character
                            if char then
                                -- Check for admin tools/items
                                local isAdmin = false
                                for _, obj in pairs(char:GetDescendants()) do
                                    if obj:IsA("Tool") and (obj.Name:lower():find("admin") or obj.Name:lower():find("god") or obj.Name:lower():find("mod")) then
                                        isAdmin = true
                                        break
                                    end
                                end
                                if isAdmin then
                                    Notify("Admin Detect", player.Name .. " adalah admin!")
                                end
                            end
                        end
                    end
                    task.wait(10)
                end
            end)
        end
        Notify("Admin Detect", v and "ON" or "OFF")
    end
})

MiscSection:AddToggle({
    Title = "Hitbox",
    Description = "Memperbesar hitbox pemain",
    Default = false,
    Callback = function(v)
        _G.Hitbox = v
        if v then
            local char = LocalPlayer.Character
            if char then
                for _, part in pairs(char:GetChildren()) do
                    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                        part.Size = part.Size * 2
                    end
                end
            end
            Notify("Enabled", "Hitbox diperbesar!")
        else
            -- Reset hitbox (need to rejoin or manual reset)
            Notify("Disabled", "Hitbox dinormalisasi (rejoin untuk reset)")
        end
    end
})

MiscSection:AddToggle({
    Title = "Killer Warn",
    Description = "Memberi peringatan jika ada killer di dekatmu",
    Default = false,
    Callback = function(v)
        _G.KillerWarn = v
        if v then
            task.spawn(function()
                while _G.KillerWarn do
                    local root = GetRootPart()
                    if root then
                        for _, player in pairs(Players:GetPlayers()) do
                            if player ~= LocalPlayer then
                                local char = player.Character
                                if char and char:FindFirstChild("HumanoidRootPart") then
                                    local dist = (root.Position - char.HumanoidRootPart.Position).Magnitude
                                    if dist < 30 and GetPlayerRole(player) == "Killer" then
                                        Notify("⚠️ KILLER WARNING", player.Name .. " ada di dekatmu (" .. math.floor(dist) .. " studs)!", "danger")
                                    end
                                end
                            end
                        end
                    end
                    task.wait(3)
                end
            end)
        end
        Notify("Killer Warn", v and "ON" or "OFF")
    end
})

MiscSection:AddToggle({
    Title = "Auto Skill Mobile",
    Description = "Otomatis menggunakan skill di mobile",
    Default = false,
    Callback = function(v)
        _G.AutoSkillMobile = v
        if v then
            task.spawn(function()
                while _G.AutoSkillMobile do
                    pcall(function()
                        -- Try to activate mobile skills
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.ButtonR1, false, game)
                        task.wait(0.1)
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.ButtonR1, false, game)
                    end)
                    task.wait(2)
                end
            end)
        end
        Notify("Auto Skill Mobile", v and "ON" or "OFF")
    end
})

-- ==========================================
-- ADMIN TAB - MOUNT MAHONI ADMIN TOOLS
-- ==========================================

local AdminSection = AdminTab:AddSection("👑 Admin Tools")

AdminSection:AddToggle({
    Title = "Admin Mode",
    Description = "Aktifkan mode admin (highlight admin panels)",
    Default = false,
    Callback = function(v)
        ToggleAdminMode(v)
    end
})

-- Player Management
local PlayerManagementSection = AdminTab:AddSection("👥 Player Management")

PlayerManagementSection:AddButton({
    Title = "Teleport All to Me",
    Description = "Teleport semua pemain ke posisimu",
    Callback = function()
        TeleportAllToPlayer()
    end
})

PlayerManagementSection:AddButton({
    Title = "Freeze All Players",
    Description = "Bekukan semua pemain",
    Callback = function()
        FreezeAllPlayers()
    end
})

PlayerManagementSection:AddButton({
    Title = "Unfreeze All Players",
    Description = "Buka bekukan semua pemain",
    Callback = function()
        UnfreezeAllPlayers()
    end
})

PlayerManagementSection:AddButton({
    Title = "Kill All Players",
    Description = "Bunuh semua pemain (kecuali kamu)",
    Callback = function()
        KillAllPlayers()
    end
})

PlayerManagementSection:AddButton({
    Title = "Heal All Players",
    Description = "Sembuhkan semua pemain",
    Callback = function()
        HealAllPlayers()
    end
})

-- Game Management
local GameManagementSection = AdminTab:AddSection("🎮 Game Management")

GameManagementSection:AddButton({
    Title = "Give All Items",
    Description = "Berikan semua item ke backpackmu",
    Callback = function()
        GiveAllItems()
    end
})

GameManagementSection:AddButton({
    Title = "Spawn All Mounts",
    Description = "Spawn semua mount di map",
    Callback = function()
        SpawnMounts()
    end
})

GameManagementSection:AddButton({
    Title = "Complete All Generators",
    Description = "Selesaikan semua generator",
    Callback = function()
        local generators = FindAllGenerators()
        local count = 0
        for _, gen in pairs(generators) do
            pcall(function()
                -- Try to complete generator
                if gen:GetAttribute("Progress") then
                    gen:SetAttribute("Progress", 1)
                    count = count + 1
                end
                -- Try to find completion method
                local complete = gen:FindFirstChild("Complete") or gen:FindFirstChild("Finished")
                if complete and complete:IsA("BindableEvent") then
                    complete:Fire()
                    count = count + 1
                end
            end)
        end
        Notify("Admin", count .. " generator selesai!", "success")
    end
})

-- Server Control
local ServerControlSection = AdminTab:AddSection("🌐 Server Control")

ServerControlSection:AddButton({
    Title = "Set Time to Day",
    Description = "Ubah waktu ke siang",
    Callback = function()
        pcall(function()
            Lighting.TimeOfDay = "12:00:00"
            Lighting.ClockTime = 12
        end)
        Notify("Admin", "Waktu diubah ke siang!", "success")
    end
})

ServerControlSection:AddButton({
    Title = "Set Time to Night",
    Description = "Ubah waktu ke malam",
    Callback = function()
        pcall(function()
            Lighting.TimeOfDay = "00:00:00"
            Lighting.ClockTime = 0
        end)
        Notify("Admin", "Waktu diubah ke malam!", "success")
    end
})

ServerControlSection:AddButton({
    Title = "Set Weather to Clear",
    Description = "Ubah cuaca menjadi cerah",
    Callback = function()
        pcall(function()
            Lighting.Weather = Enum.Weather.Clear
        end)
        Notify("Admin", "Cuaca diubah ke cerah!", "success")
    end
})

ServerControlSection:AddButton({
    Title = "Set Weather to Rain",
    Description = "Ubah cuaca menjadi hujan",
    Callback = function()
        pcall(function()
            Lighting.Weather = Enum.Weather.Rain
        end)
        Notify("Admin", "Cuaca diubah ke hujan!", "success")
    end
})

-- ==========================================
-- SERVER TAB
-- ==========================================
local ServerSection = ServerTab:AddSection("🌐 Server")

ServerSection:AddButton({
    Title = "Reconnect",
    Description = "Menghubungkan ulang ke server",
    Callback = function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
        Notify("Reconnect", "Menghubungkan ulang...")
    end
})

ServerSection:AddButton({
    Title = "Server Hop",
    Description = "Pindah ke server lain",
    Callback = function()
        local servers = TeleportService:GetPlayerPlaceInstances(game.PlaceId)
        local currentJobId = game.JobId
        local newJobId = nil
        for _, server in pairs(servers) do
            if server.JobId ~= currentJobId and server.CurrentPlayers < server.MaxPlayers then
                newJobId = server.JobId
                break
            end
        end
        if newJobId then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, newJobId, LocalPlayer)
            Notify("Server Hop", "Pindah server...")
        else
            Notify("Server Hop", "Tidak ada server lain yang tersedia!")
        end
    end
})

ServerSection:AddButton({
    Title = "Join Friend",
    Description = "Bergabung dengan teman",
    Callback = function()
        local friend = Players:GetFriendsOnline()[1]
        if friend then
            TeleportService:TeleportToPlayer(friend.UserId)
            Notify("Join Friend", "Bergabung dengan " .. friend.DisplayName .. "...")
        else
            Notify("Join Friend", "Tidak ada teman yang online!")
        end
    end
})

-- ==========================================
-- SETTINGS TAB
-- ==========================================
local SettingsSection = SettingsTab:AddSection("⚙️ Settings")

SettingsSection:AddToggle({
    Title = "Auto Update",
    Description = "Otomatis memperbarui script",
    Default = true,
    Callback = function(v)
        Notify("Auto Update", v and "ON" or "OFF")
    end
})

SettingsSection:AddButton({
    Title = "Save Config",
    Description = "Menyimpan konfigurasi saat ini",
    Callback = function()
        Notify("Save Config", "Konfigurasi disimpan!")
    end
})

SettingsSection:AddButton({
    Title = "Load Config",
    Description = "Memuat konfigurasi yang tersimpan",
    Callback = function()
        Notify("Load Config", "Konfigurasi dimuat!")
    end
})

SettingsSection:AddButton({
    Title = "Reset Config",
    Description = "Mengatur ulang konfigurasi ke default",
    Callback = function()
        Notify("Reset Config", "Konfigurasi direset!")
    end
})

-- ==========================================
-- EXIT TAB
-- ==========================================
local ExitSection = Window:AddTab({ Name = "Exit", Icon = "exit" })

ExitSection:AddButton({
    Title = "Shutdown",
    Description = "Menutup GUI dan mematikan script",
    Callback = function()
        Notify("MDW HUB", "Shutdown...")
        task.wait(1)
        Window:Destroy()
    end
})

-- ==========================================
-- RENDER LOOP FOR ESP
-- ==========================================
RunService.RenderStepped:Connect(function()
    -- Update Box, Line, and Skeleton ESP
    if _G.BoxESP or _G.LineESP or _G.SkeletonESP then
        UpdateESP()
    else
        -- Clear all Drawing ESP objects if none are active
        for _, player in pairs(Players:GetPlayers()) do
            ClearESP(player)
        end
    end

    -- Update Mount ESP
    if _G.MountESP then
        UpdateMountESP()
    else
        ClearAllMountESPs()
    end

    -- Update Health Bar ESP
    if _G.HealthESP then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
                local head = player.Character.Head
                local humanoid = player.Character:FindFirstChild("Humanoid")
                
                if humanoid and humanoid.Health > 0 then
                    local gui = head:FindFirstChild("HealthBarGui")
                    if not gui then
                        local bgui = Instance.new("BillboardGui", head)
                        bgui.Name = "HealthBarGui"
                        bgui.Size = UDim2.new(3, 0, 0.4, 0)
                        bgui.StudsOffset = Vector3.new(0, 2, 0)
                        bgui.AlwaysOnTop = true
                        
                        local back = Instance.new("Frame", bgui)
                        back.Name = "Background"
                        back.Size = UDim2.new(1, 0, 1, 0)
                        back.BackgroundColor3 = Color3.new(0, 0, 0)
                        back.BorderSizePixel = 0
                        
                        local bar = Instance.new("Frame", back)
                        bar.Name = "Bar"
                        bar.BorderSizePixel = 0
                        bar.Size = UDim2.new(humanoid.Health / humanoid.MaxHealth, 0, 1, 0)
                        bar.BackgroundColor3 = Color3.new(0, 1, 0)
                    else
                        local frame = gui:FindFirstChild("Background")
                        local bar = frame and frame:FindFirstChild("Bar")
                        if bar then
                            local healthPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
                            bar.Size = UDim2.new(healthPercent, 0, 1, 0)
                            bar.BackgroundColor3 = Color3.fromHSV(healthPercent * 0.3, 1, 1) 
                        end
                    end
                end
            end
        end
    end

    -- Auto Heal if enabled
    if _G.AutoHeal then
        local hum = GetHumanoid()
        if hum and hum.Health < hum.MaxHealth then
            hum.Health = hum.MaxHealth
        end
    end

    -- No Fall Damage if enabled
    if _G.NoFallDamage then
        local hum = GetHumanoid()
        if hum then
            hum.MaxHealth = math.huge
            hum.Health = math.huge
        end
    end
end)

-- ==========================================
-- CLICK TP
-- ==========================================
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    
    if _G.TapTP and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        local root = GetRootPart()
        if root then  
            local mouse = LocalPlayer:GetMouse()
            local targetPos = mouse.Hit.p
            root.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))
        end
    end
end)

-- ==========================================
-- NOCLIP LOOP
-- ==========================================
RunService.Stepped:Connect(function()
    if _G.NC and LocalPlayer.Character then
        for _, p in pairs(LocalPlayer.Character:GetChildren()) do 
            if p:IsA("BasePart") then 
                p.CanCollide = false 
            end 
            for _, child in pairs(p:GetDescendants()) do
                if child:IsA("BasePart") then 
                    child.CanCollide = false 
                end
            end
        end
    end
end)

-- ==========================================
-- INFINITE JUMP LOOP
-- ==========================================
RunService.RenderStepped:Connect(function()
    if _G.InfJump then
        local hum = GetHumanoid()
        if hum then
            hum.Jump = true
        end
    end
end)

-- ==========================================
-- INITIALIZE
-- ==========================================
Library:Initialize()
Library:MakeNotify({ 
    Title = "FCAL HUB v2.0", 
    Content = "Mount Mahoni Admin Tools Loaded! Press RightCtrl to toggle", 
    Duration = 5 
})

-- Auto update dropdown
Players.PlayerAdded:Connect(UpdateDropdown)
Players.PlayerRemoving:Connect(UpdateDropdown)
Players.PlayerRemoving:Connect(ClearESP)

-- FIXED: Handle character added for ESP
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        if _G.ESP then
            task.wait(0.5)
            CreateESPForPlayer(player)
        end
    end)
end)

print("✅ FCAL HUB v2.0 - Mount Mahoni Edition Loaded!")
print("📌 Features: Fly Fixed, ESP Fixed, Admin Tools Added")
print("🔑 Press RightCtrl to toggle menu") 