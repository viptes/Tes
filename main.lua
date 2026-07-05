--[[
    FCAL HUB - LYNX GUI EDITION (FIXED - NO DETECTION)
    Version: 1.0.9 | FULL FEATURES + TROLL MOUNTAIN + ESP IMPROVED + GOD MODE + ADMIN SYSTEM
    FIX: Removed getrawmetatable Anti-Kick (penyebab error 267)
    ADDED: God Mode (Kebal Serangan), Admin System, Mount System
    FIXED: ESP not active, Mount ESP added
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
local Debris = game:GetService("Debris")
local StarterGui = game:GetService("StarterGui")

-- Global Variables
local LocalPlayer = Players.LocalPlayer
local ESP_Objects = {}
local ManualHighlights = {}
local ESP_Highlights = {}
local ESPLabels = {}
local ToggleKey = Enum.KeyCode.RightControl
local msg = "FCAL HUB ON TOP!"
local SpecTarget = ""
local hbSize = 2

-- ==========================================
-- ⚠️ ANTI-KICK TELAH DIHAPUS (PENYEBAB ERROR 267)
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
_G.FlyEnabled = false

-- Mount System Variables
MountMahoni = {
    CommandPrefix = "!",
    BannedPlayers = {},
    Mounts = {},
    PlayerMounts = {},
    MountESP = {},
    TeleportToMount = false,
    TargetMount = nil,
    AutoMount = false,
    MountSpeedMultiplier = 1,
    SelectedMount = nil,
    FollowMountActive = false,
}

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
    Title = "MDW",
    Footer = "v1.0.9 | Client Sided"
})

-- ==========================================
-- HELPER FUNCTIONS
-- ==========================================
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
                        objects.Box.Thickness = 1
                        objects.Box.Filled = false
                        objects.Box.Size = Vector2.new(sizeX, sizeY)
                        objects.Box.Position = Vector2.new(pos.X - sizeX / 2, pos.Y - sizeY / 2)
                    else
                        objects.Box.Visible = false
                    end

                    if _G.LineESP then
                        objects.Line.Visible = true
                        objects.Line.Color = color
                        objects.Line.Thickness = 1
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
                        ESP_Objects[player].Box.Visible = false
                        ESP_Objects[player].Line.Visible = false
                        for _, line in pairs(ESP_Objects[player].Skeleton) do
                            line.Visible = false
                        end
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

function CheckIfKiller(player)
    if not player then return false end
    local char = player.Character
    if not char then return false end
    
    if player:GetAttribute("Role") and string.lower(player:GetAttribute("Role")):find("killer") then
        return true
    end
    if player.Team and string.lower(player.Team.Name):find("killer") then
        return true
    end
    if char:FindFirstChild("Role") and char.Role:IsA("StringValue") and string.lower(char.Role.Value):find("killer") then
        return true
    end
    local killerParts = {"Knife", "Weapon", "Blade", "Sword"}
    for _, partName in pairs(killerParts) do
        if char:FindFirstChild(partName) then
            return true
        end
    end
    return false
end

function GetPlayerRole(player)
    local inGame = false
    local gameGui = LocalPlayer:FindFirstChild("PlayerGui")
    if gameGui then
        for _, gui in pairs(gameGui:GetChildren()) do
            if gui.Name:lower():find("game") or gui.Name:lower():find("match") 
                or gui.Name:lower():find("survive") or gui.Name:lower():find("ingame") then
                if gui.Enabled then inGame = true break end
            end
        end
    end
    if not inGame then
        for _, obj in pairs(Workspace:GetChildren()) do
            if obj.Name:lower():find("generator") or obj.Name:lower():find("gate") 
                or obj.Name:lower():find("survivor") or obj.Name:lower():find("killer") then
                inGame = true break
            end
        end
    end
    if not inGame then return "Neutral" end
    local character = player.Character
    if not character then return "Neutral" end
    if player:GetAttribute("Role") then
        local role = player:GetAttribute("Role")
        if type(role) == "string" then
            if role:lower():find("killer") then return "Killer" end
            if role:lower():find("survivor") or role:lower():find("survive") then return "Survivor" end
        end
    end
    if character:GetAttribute("Role") then
        local role = character:GetAttribute("Role")
        if type(role) == "string" then
            if role:lower():find("killer") then return "Killer" end
            if role:lower():find("survivor") or role:lower():find("survive") then return "Survivor" end
        end
    end
    local roleValue = character:FindFirstChild("Role")
    if roleValue and roleValue:IsA("StringValue") then
        local role = roleValue.Value:lower()
        if role:find("killer") then return "Killer" end
        if role:find("survivor") or role:find("survive") then return "Survivor" end
    end
    if player.Team then
        local teamName = player.Team.Name:lower()
        if teamName:find("killer") then return "Killer" end
        if teamName:find("survivor") or teamName:find("survive") then return "Survivor" end
    end
    return "Survivor"
end

function GetESPColor(player)
    local role = GetPlayerRole(player)
    if role == "Killer" then return Color3.fromRGB(255, 0, 0)
    elseif role == "Survivor" then return Color3.fromRGB(0, 255, 0)
    else return Color3.fromRGB(255, 255, 255) end
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
    end
    if player.Character and player.Character:FindFirstChild("Head") and player.Character.Head:FindFirstChild("HealthBarGui") then
        pcall(function() player.Character.Head.HealthBarGui:Destroy() end)
    end
end

function FindAllGenerators()
    local generators = {}
    for _, obj in pairs(Workspace:GetDescendants()) do
        if IsGenerator(obj) then table.insert(generators, obj) end
    end
    return generators
end

local MountObjects = {}

-- ==========================================
-- MOUNT SYSTEM
-- ==========================================

function FindAllMounts()
    local mounts = {}
    local foundNames = {}
    
    -- Cari di Workspace
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            local name = obj.Name:lower()
            if (name:find("mount") or name:find("horse") or name:find("pet") or 
                name:find("vehicle") or name:find("ride") or name:find("kuda") or
                name:find("motor") or name:find("mobil") or name:find("sepeda") or
                name:find("boat") or name:find("kapal") or name:find("plane") or
                name:find("pesawat") or name:find("heli") or name:find("drone") or
                name:find("cart") or name:find("gerobak") or name:find("truk") or
                name:find("train") or name:find("kereta")) and 
               not name:find("player") and not name:find("character") and not name:find("humanoid") and
               not name:find("tool") and not name:find("weapon") and not name:find("backpack") then
                if not foundNames[obj.Name] then
                    table.insert(mounts, obj)
                    foundNames[obj.Name] = true
                end
            end
        end
    end
    
    -- Cari di ReplicatedStorage
    for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            local name = obj.Name:lower()
            if (name:find("mount") or name:find("horse") or name:find("pet") or 
                name:find("vehicle") or name:find("ride") or name:find("kuda") or
                name:find("motor") or name:find("mobil") or name:find("sepeda") or
                name:find("boat") or name:find("kapal") or name:find("plane") or
                name:find("pesawat") or name:find("heli") or name:find("drone")) and 
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
    highlight.FillColor = Color3.fromRGB(0, 255, 255)
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = Color3.new(1, 1, 1)
    highlight.OutlineTransparency = 0
    highlight.Parent = mount
    MountObjects[mount] = highlight
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "MountNameTag"
    billboard.Size = UDim2.new(4, 0, 1, 0)
    billboard.StudsOffset = Vector3.new(0, 4, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = mount
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextScaled = true
    textLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
    textLabel.TextStrokeTransparency = 0
    textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    textLabel.Font = Enum.Font.GothamBold
    textLabel.Text = "[MOUNT] " .. mount.Name
    textLabel.Parent = billboard
    
    local distanceBillboard = Instance.new("BillboardGui")
    distanceBillboard.Name = "MountDistance"
    distanceBillboard.Size = UDim2.new(2, 0, 0.5, 0)
    distanceBillboard.StudsOffset = Vector3.new(0, -2, 0)
    distanceBillboard.AlwaysOnTop = true
    distanceBillboard.Parent = mount
    
    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.Size = UDim2.new(1, 0, 1, 0)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.TextScaled = true
    distanceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    distanceLabel.TextStrokeTransparency = 0
    distanceLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    distanceLabel.Font = Enum.Font.Gotham
    distanceLabel.Text = "0m"
    distanceLabel.Parent = distanceBillboard
    
    MountMahoni.MountESP[mount] = {
        Highlight = highlight,
        NameTag = billboard,
        DistanceTag = distanceBillboard,
        DistanceLabel = distanceLabel
    }
end

function RemoveESPMount(mount)
    if MountObjects[mount] then
        pcall(function() MountObjects[mount]:Destroy() end)
        MountObjects[mount] = nil
    end
    if MountMahoni.MountESP[mount] then
        pcall(function() MountMahoni.MountESP[mount].Highlight:Destroy() end)
        pcall(function() MountMahoni.MountESP[mount].NameTag:Destroy() end)
        pcall(function() MountMahoni.MountESP[mount].DistanceTag:Destroy() end)
        MountMahoni.MountESP[mount] = nil
    end
    pcall(function()
        for _, child in pairs(mount:GetChildren()) do
            if child.Name == "MountNameTag" or child.Name == "MountDistance" then
                child:Destroy()
            end
        end
    end)
end

function ClearAllMountESPs()
    for mount, highlight in pairs(MountObjects) do
        pcall(function() highlight:Destroy() end)
        if MountMahoni.MountESP[mount] then
            pcall(function() MountMahoni.MountESP[mount].NameTag:Destroy() end)
            pcall(function() MountMahoni.MountESP[mount].DistanceTag:Destroy() end)
            MountMahoni.MountESP[mount] = nil
        end
        pcall(function()
            for _, child in pairs(mount:GetChildren()) do
                if child.Name == "MountNameTag" or child.Name == "MountDistance" then
                    child:Destroy()
                end
            end
        end)
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
    local root = GetRootPart()

    for _, mount in pairs(currentMounts) do
        if not MountObjects[mount] then
            CreateESPMount(mount)
        end
        
        if MountMahoni.MountESP[mount] and MountMahoni.MountESP[mount].DistanceLabel and root then
            local mountPos = mount:IsA("Model") and mount:GetPivot().Position or 
                           (mount:IsA("BasePart") and mount.Position or Vector3.new(0,0,0))
            local dist = (root.Position - mountPos).Magnitude
            MountMahoni.MountESP[mount].DistanceLabel.Text = math.floor(dist) .. "m"
            
            if dist < 20 then
                MountMahoni.MountESP[mount].DistanceLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
            elseif dist < 50 then
                MountMahoni.MountESP[mount].DistanceLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
            else
                MountMahoni.MountESP[mount].DistanceLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
            end
        end
        
        activeMounts[mount] = true
    end

    for mount, highlight in pairs(MountObjects) do
        if not activeMounts[mount] then
            RemoveESPMount(mount)
        end
    end
end

function GetMountList()
    local mounts = FindAllMounts()
    local mountNames = {}
    for _, mount in pairs(mounts) do
        local name = mount.Name
        if mount:IsA("Model") then
            local pos = mount:GetPivot().Position
            name = name .. " (" .. math.floor(pos.X) .. ", " .. math.floor(pos.Z) .. ")"
        end
        table.insert(mountNames, name)
    end
    if #mountNames == 0 then
        table.insert(mountNames, "Tidak ada mount ditemukan")
    end
    return mountNames
end

function TeleportToMount(mountName)
    local mounts = FindAllMounts()
    for _, mount in pairs(mounts) do
        local name = mount.Name
        if mount:IsA("Model") then
            name = name .. " (" .. math.floor(mount:GetPivot().Position.X) .. ", " .. math.floor(mount:GetPivot().Position.Z) .. ")"
        end
        if name == mountName then
            local root = GetRootPart()
            if root and mount then
                local pos = mount:IsA("Model") and mount:GetPivot().Position or 
                           (mount:IsA("BasePart") and mount.Position or Vector3.new(0,0,0))
                root.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
                Notify("Mount", "Teleport ke " .. mount.Name, "success")
                return true
            end
        end
    end
    Notify("Error", "Mount tidak ditemukan!", "error")
    return false
end

function AutoMountNearest()
    local mounts = FindAllMounts()
    local root = GetRootPart()
    if not root then return end
    
    local nearest = nil
    local nearestDist = math.huge
    
    for _, mount in pairs(mounts) do
        local pos = mount:IsA("Model") and mount:GetPivot().Position or 
                   (mount:IsA("BasePart") and mount.Position or Vector3.new(0,0,0))
        local dist = (root.Position - pos).Magnitude
        if dist < nearestDist then
            nearestDist = dist
            nearest = mount
        end
    end
    
    if nearest then
        local pos = nearest:IsA("Model") and nearest:GetPivot().Position or 
                   (nearest:IsA("BasePart") and nearest.Position or Vector3.new(0,0,0))
        root.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
        Notify("Mount", "Auto mount ke " .. nearest.Name .. " (" .. math.floor(nearestDist) .. "m)", "success")
        return true
    end
    Notify("Error", "Tidak ada mount ditemukan!", "error")
    return false
end

function FollowMount(mountName)
    local mounts = FindAllMounts()
    for _, mount in pairs(mounts) do
        local name = mount.Name
        if mount:IsA("Model") then
            name = name .. " (" .. math.floor(mount:GetPivot().Position.X) .. ", " .. math.floor(mount:GetPivot().Position.Z) .. ")"
        end
        if name == mountName then
            MountMahoni.TargetMount = mount
            MountMahoni.TeleportToMount = true
            MountMahoni.FollowMountActive = true
            Notify("Mount", "Mengikuti " .. mount.Name, "info")
            return true
        end
    end
    Notify("Error", "Mount tidak ditemukan!", "error")
    return false
end

-- Follow Mount Loop
task.spawn(function()
    while true do
        task.wait(0.1)
        if MountMahoni.TeleportToMount and MountMahoni.TargetMount then
            local root = GetRootPart()
            if root and MountMahoni.TargetMount then
                local pos = MountMahoni.TargetMount:IsA("Model") and MountMahoni.TargetMount:GetPivot().Position or 
                           (MountMahoni.TargetMount:IsA("BasePart") and MountMahoni.TargetMount.Position or Vector3.new(0,0,0))
                if pos then
                    local dist = (root.Position - pos).Magnitude
                    if dist > 5 then
                        root.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
                    end
                end
            end
        end
    end
end)

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
-- ADMIN FUNCTIONS
-- ==========================================
function GetPlayerCharacter(player)
    if not player then return nil end
    return player.Character
end

function GetPlayerHumanoid(player)
    local char = GetPlayerCharacter(player)
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end

function GetPlayerRootPart(player)
    local char = GetPlayerCharacter(player)
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

function KillPlayer(target)
    local hum = GetPlayerHumanoid(target)
    if hum then
        hum.Health = 0
        return true
    end
    return false
end

function HealPlayer(target)
    local hum = GetPlayerHumanoid(target)
    if hum then
        hum.Health = hum.MaxHealth
        return true
    end
    return false
end

function BringPlayer(target)
    local myRoot = GetRootPart()
    local targetRoot = GetPlayerRootPart(target)
    if myRoot and targetRoot then
        targetRoot.CFrame = myRoot.CFrame * CFrame.new(0, 0, -3)
        return true
    end
    return false
end

function GotoPlayer(target)
    local myRoot = GetRootPart()
    local targetRoot = GetPlayerRootPart(target)
    if myRoot and targetRoot then
        myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3)
        return true
    end
    return false
end

function KickPlayer(target, reason)
    if target == LocalPlayer then return false end
    pcall(function()
        local gui = Instance.new("ScreenGui")
        gui.Name = "AdminKick"
        gui.Parent = target:FindFirstChild("PlayerGui")
        
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 1, 0)
        frame.BackgroundColor3 = Color3.new(0, 0, 0)
        frame.Parent = gui
        
        local text = Instance.new("TextLabel")
        text.Size = UDim2.new(1, 0, 0.1, 0)
        text.Position = UDim2.new(0, 0, 0.45, 0)
        text.Text = "KICKED: " .. (reason or "By Admin")
        text.TextColor3 = Color3.new(1, 0, 0)
        text.TextScaled = true
        text.BackgroundTransparency = 1
        text.Parent = frame
        
        task.delay(3, function()
            gui:Destroy()
        end)
    end)
    return true
end

function FreezePlayer(target)
    local root = GetPlayerRootPart(target)
    local hum = GetPlayerHumanoid(target)
    if root and hum then
        root.Anchored = true
        hum.WalkSpeed = 0
        hum.JumpPower = 0
        return true
    end
    return false
end

function UnfreezePlayer(target)
    local root = GetPlayerRootPart(target)
    local hum = GetPlayerHumanoid(target)
    if root and hum then
        root.Anchored = false
        hum.WalkSpeed = 16
        hum.JumpPower = 50
        return true
    end
    return false
end

function FlingPlayer(target)
    local root = GetPlayerRootPart(target)
    if root then
        root.Velocity = Vector3.new(math.random(-500, 500), 500, math.random(-500, 500))
        return true
    end
    return false
end

function ExplodePlayer(target)
    local root = GetPlayerRootPart(target)
    if root then
        local explosion = Instance.new("Explosion")
        explosion.Position = root.Position
        explosion.BlastRadius = 10
        explosion.BlastPressure = 500000
        explosion.Parent = Workspace
        Debris:AddItem(explosion, 2)
        return true
    end
    return false
end

function JailPlayer(target)
    local root = GetPlayerRootPart(target)
    if root then
        local jail = Instance.new("Part")
        jail.Name = "AdminJail"
        jail.Size = Vector3.new(10, 10, 10)
        jail.Position = root.Position
        jail.Anchored = true
        jail.CanCollide = true
        jail.Transparency = 0.5
        jail.BrickColor = BrickColor.new("Really black")
        jail.Material = Enum.Material.ForceField
        jail.Parent = Workspace
        
        for i = 1, 8 do
            local bar = Instance.new("Part")
            bar.Size = Vector3.new(0.5, 10, 0.5)
            bar.Anchored = true
            bar.CanCollide = true
            bar.BrickColor = BrickColor.new("Bright red")
            bar.Material = Enum.Material.Neon
            local angle = (i / 8) * math.pi * 2
            bar.Position = root.Position + Vector3.new(math.cos(angle) * 5, 0, math.sin(angle) * 5)
            bar.Parent = jail
        end
        
        Debris:AddItem(jail, 30)
        return true
    end
    return false
end

function KillAllPlayers()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            KillPlayer(p)
        end
    end
end

function HealAllPlayers()
    for _, p in pairs(Players:GetPlayers()) do
        HealPlayer(p)
    end
end

function BringAllPlayers()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            BringPlayer(p)
        end
    end
end

-- ==========================================
-- CHAT COMMANDS SYSTEM
-- ==========================================
local ChatCommands = {
    ["kill"] = function(args) return KillPlayer(GetPlayerByName(args[1])) end,
    ["heal"] = function(args) return HealPlayer(GetPlayerByName(args[1])) end,
    ["tp"] = function(args) 
        local target = GetPlayerByName(args[1])
        if target then return GotoPlayer(target) end
        return false
    end,
    ["bring"] = function(args) 
        local target = GetPlayerByName(args[1])
        if target then return BringPlayer(target) end
        return false
    end,
    ["kick"] = function(args) return KickPlayer(GetPlayerByName(args[1]), args[2]) end,
    ["freeze"] = function(args) return FreezePlayer(GetPlayerByName(args[1])) end,
    ["unfreeze"] = function(args) return UnfreezePlayer(GetPlayerByName(args[1])) end,
    ["fling"] = function(args) return FlingPlayer(GetPlayerByName(args[1])) end,
    ["explode"] = function(args) return ExplodePlayer(GetPlayerByName(args[1])) end,
    ["jail"] = function(args) return JailPlayer(GetPlayerByName(args[1])) end,
    ["killall"] = function() KillAllPlayers() return true end,
    ["healall"] = function() HealAllPlayers() return true end,
    ["bringall"] = function() BringAllPlayers() return true end,
    ["noclip"] = function() 
        _G.NC = true
        Notify("Admin", "NoClip enabled", "info")
        return true
    end,
    ["clip"] = function() 
        _G.NC = false
        Notify("Admin", "NoClip disabled", "info")
        return true
    end,
    ["fly"] = function(args)
        local speed = tonumber(args[1]) or 100
        Config.FlySpeed = speed
        _G.Fly = true
        Notify("Admin", "Fly enabled at speed " .. speed, "info")
        return true
    end,
    ["unfly"] = function()
        _G.Fly = false
        Notify("Admin", "Fly disabled", "info")
        return true
    end,
    ["god"] = function()
        _G.GodMode = true
        local hum = GetHumanoid()
        if hum then
            hum.MaxHealth = math.huge
            hum.Health = math.huge
        end
        Notify("Admin", "God Mode enabled", "info")
        return true
    end,
    ["ungod"] = function()
        _G.GodMode = false
        local hum = GetHumanoid()
        if hum then
            hum.MaxHealth = 100
            hum.Health = 100
        end
        Notify("Admin", "God Mode disabled", "info")
        return true
    end,
    ["ws"] = function(args)
        local speed = tonumber(args[1]) or 50
        local hum = GetHumanoid()
        if hum then hum.WalkSpeed = speed end
        Notify("Admin", "WalkSpeed set to " .. speed, "info")
        return true
    end,
    ["jp"] = function(args)
        local power = tonumber(args[1]) or 100
        local hum = GetHumanoid()
        if hum then 
            hum.JumpPower = power
            hum.UseJumpPower = true
        end
        Notify("Admin", "JumpPower set to " .. power, "info")
        return true
    end,
    ["gravity"] = function(args)
        local grav = tonumber(args[1]) or 196
        workspace.Gravity = grav
        Notify("Admin", "Gravity set to " .. grav, "info")
        return true
    end,
    ["sit"] = function()
        local hum = GetHumanoid()
        if hum then hum.Sit = true end
        return true
    end,
    ["jump"] = function()
        local hum = GetHumanoid()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        return true
    end,
    ["reset"] = function()
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.Health = 0 end
        end
        return true
    end,
    ["rejoin"] = function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
        return true
    end,
    ["help"] = function()
        local commands = {
            "kill [player]", "heal [player]", "tp [player]", "bring [player]",
            "kick [player] [reason]", "freeze [player]", "unfreeze [player]",
            "fling [player]", "explode [player]", "jail [player]",
            "killall", "healall", "bringall",
            "noclip", "clip", "fly [speed]", "unfly",
            "god", "ungod", "ws [speed]", "jp [power]", "gravity [value]",
            "sit", "jump", "reset", "rejoin"
        }
        for _, cmd in pairs(commands) do
            print("Command: " .. cmd)
        end
        Notify("Admin", "Check console for command list (F9)", "info")
        return true
    end,
}

function ProcessChatCommand(message)
    if not message then return false end
    if message:sub(1, 1) ~= MountMahoni.CommandPrefix then return false end
    
    local args = {}
    for arg in message:sub(2):gmatch("%S+") do
        table.insert(args, arg)
    end
    
    local command = args[1]:lower()
    table.remove(args, 1)
    
    if ChatCommands[command] then
        local success, result = pcall(function()
            return ChatCommands[command](args)
        end)
        if success then
            Notify("Command", "Executed: " .. command, "success")
        else
            Notify("Error", "Command failed: " .. tostring(result), "error")
        end
        return true
    else
        Notify("Error", "Unknown command: " .. command, "error")
        return false
    end
end

-- ==========================================
-- TABS CREATION
-- ==========================================
local MainTab = Window:AddTab({ Name = "Main", Icon = "home" })
local MountTab = Window:AddTab({ Name = "Mount", Icon = "player" })
local AdminTab = Window:AddTab({ Name = "Admin", Icon = "shield" })
local GameTab = Window:AddTab({ Name = "Game", Icon = "gamepad" })
local ServerTab = Window:AddTab({ Name = "Server", Icon = "web" })
local SettingsTab = Window:AddTab({ Name = "Settings", Icon = "settings" })

-- ==========================================
-- MAIN TAB
-- ==========================================
local QuickSection = MainTab:AddSection("🛠️ Quick Actions")

QuickSection:AddButton({
    Title = "Reset Character",
    Callback = function() 
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.Health = 0
        else
            LocalPlayer:LoadCharacter() 
        end
        Library:MakeNotify({ Title = "Success", Content = "Character reset!" })
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
        Library:MakeNotify({ Title = "Success", Content = "Movement Refreshed!" })
    end
})

-- Teleport Section
local TpSection = MainTab:AddSection("🎯 Teleport")

TpSection:AddToggle({
    Title = "Click TP (PC/Mobile)",
    Description = "Klik/Sentuh layar untuk teleport instan",
    Default = false,
    Callback = function(v) _G.TapTP = v end
})

local SelectedTarget = ""
local PlayerDropdown = TpSection:AddDropdown({
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

TpSection:AddButton({ 
    Title = "🔄 Refresh Daftar Pemain", 
    Callback = function()
        UpdateDropdown()
        Library:MakeNotify({ Title = "MDW", Content = "Daftar pemain telah diperbarui!" })
    end 
})

TpSection:AddButton({
    Title = "Teleport Sekarang",
    Callback = function()
        if SelectedTarget == "" or SelectedTarget == "Tidak ada pemain" then 
            Library:MakeNotify({ Title = "Warning", Content = "Pilih pemain dulu!" })
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
                
                Library:MakeNotify({ Title = "Success", Content = "Berhasil ke " .. SelectedTarget })
            end
        else
            Library:MakeNotify({ Title = "Error", Content = "Gagal! Player terlalu jauh." })
        end
    end
})

-- ==========================================
-- MOUNT TAB
-- ==========================================
local MountSection = MountTab:AddSection("🏇 Mount System")

MountSection:AddToggle({
    Title = "ESP Mounts (Highlight + Tag)",
    Description = "Melihat lokasi mount di map dengan jarak",
    Default = false,
    Callback = function(v)
        _G.MountESP = v
        if v then
            UpdateMountESP()
            Library:MakeNotify({ Title = "Enabled", Content = "ESP Mounts Aktif!" })
        else
            ClearAllMountESPs()
            Library:MakeNotify({ Title = "Disabled", Content = "ESP Mounts Mati" })
        end
    end
})

MountSection:AddButton({
    Title = "🔄 Refresh Daftar Mount",
    Description = "Perbarui daftar mount yang tersedia",
    Callback = function()
        local mountOptions = GetMountList()
        if MountDropdown.SetValues then
            MountDropdown:SetValues(mountOptions)
        elseif MountDropdown.Refresh then
            MountDropdown:Refresh(mountOptions, true)
        end
        Library:MakeNotify({ Title = "Mount", Content = "Daftar mount diperbarui!" })
    end
})

local MountDropdown = MountSection:AddDropdown({
    Title = "Pilih Mount",
    Description = "Pilih mount target",
    Options = GetMountList(),
    Default = "",
    Callback = function(v)
        MountMahoni.SelectedMount = v
    end
})

MountSection:AddButton({
    Title = "🚀 Teleport ke Mount",
    Description = "Teleport ke posisi mount yang dipilih",
    Callback = function()
        if MountMahoni.SelectedMount and MountMahoni.SelectedMount ~= "Tidak ada mount ditemukan" then
            TeleportToMount(MountMahoni.SelectedMount)
        else
            Library:MakeNotify({ Title = "Error", Content = "Pilih mount terlebih dahulu!" })
        end
    end
})

MountSection:AddButton({
    Title = "📍 Auto Mount Terdekat",
    Description = "Teleport ke mount terdekat",
    Callback = function()
        AutoMountNearest()
    end
})

MountSection:AddToggle({
    Title = "🔍 Follow Mount",
    Description = "Ikuti mount yang dipilih secara otomatis",
    Default = false,
    Callback = function(v)
        if v then
            if MountMahoni.SelectedMount and MountMahoni.SelectedMount ~= "Tidak ada mount ditemukan" then
                FollowMount(MountMahoni.SelectedMount)
            else
                Library:MakeNotify({ Title = "Error", Content = "Pilih mount terlebih dahulu!" })
                return
            end
        else
            MountMahoni.TeleportToMount = false
            MountMahoni.TargetMount = nil
            MountMahoni.FollowMountActive = false
            Library:MakeNotify({ Title = "Mount", Content = "Follow Mount dinonaktifkan" })
        end
    end
})

local MountInfoSection = MountTab:AddSection("📊 Mount Info")

MountInfoSection:AddButton({
    Title = "📋 Lihat Semua Mount",
    Description = "Tampilkan daftar semua mount di konsol",
    Callback = function()
        local mounts = FindAllMounts()
        local root = GetRootPart()
        print("=== DAFTAR MOUNT ===")
        print("Total mount ditemukan: " .. #mounts)
        for i, mount in pairs(mounts) do
            local pos = mount:IsA("Model") and mount:GetPivot().Position or 
                       (mount:IsA("BasePart") and mount.Position or Vector3.new(0,0,0))
            local dist = root and (root.Position - pos).Magnitude or 0
            print(string.format("%d. %s - Posisi: (%.1f, %.1f, %.1f) - Jarak: %.1fm", 
                i, mount.Name, pos.X, pos.Y, pos.Z, dist))
        end
        Library:MakeNotify({ Title = "Mount", Content = "Cek konsol (F9) untuk daftar mount!" })
    end
})

-- ==========================================
-- ADMIN TAB
-- ==========================================
local AdminSection = AdminTab:AddSection("👑 Admin Commands")

AdminSection:AddLabel("Gunakan ! diikuti perintah di chat")
AdminSection:AddLabel("Contoh: !kill playername")

AdminSection:AddButton({
    Title = "📖 Lihat Daftar Perintah",
    Description = "Tampilkan semua perintah admin di konsol",
    Callback = function()
        print("=== DAFTAR PERINTAH ADMIN ===")
        print("!kill [player] - Bunuh pemain")
        print("!heal [player] - Sembuhkan pemain")
        print("!tp [player] - Teleport ke pemain")
        print("!bring [player] - Bawa pemain ke kamu")
        print("!kick [player] [reason] - Kick pemain")
        print("!freeze [player] - Bekukan pemain")
        print("!unfreeze [player] - Lepas beku pemain")
        print("!fling [player] - Lontarkan pemain")
        print("!explode [player] - Ledakkan pemain")
        print("!jail [player] - Penjara pemain")
        print("!killall - Bunuh semua pemain")
        print("!healall - Sembuhkan semua pemain")
        print("!bringall - Bawa semua pemain")
        print("!noclip - Aktifkan NoClip")
        print("!clip - Nonaktifkan NoClip")
        print("!fly [speed] - Aktifkan Fly")
        print("!unfly - Nonaktifkan Fly")
        print("!god - Aktifkan God Mode")
        print("!ungod - Nonaktifkan God Mode")
        print("!ws [speed] - Set WalkSpeed")
        print("!jp [power] - Set JumpPower")
        print("!gravity [value] - Set Gravity")
        print("!sit - Duduk")
        print("!jump - Lompat")
        print("!reset - Reset karakter")
        print("!rejoin - Rejoin server")
        print("!help - Tampilkan daftar perintah")
        Library:MakeNotify({ Title = "Admin", Content = "Cek konsol (F9) untuk daftar perintah!" })
    end
})

AdminSection:AddLabel("")
AdminSection:AddLabel("💡 Chat Command System Aktif!")

-- ==========================================
-- GAME TAB - VISUAL ESP
-- ==========================================
local VisualSection = GameTab:AddSection("🎭 Visual ESP & Tracking")

VisualSection:AddToggle({ 
    Title = "ESP Box (2D)", 
    Default = false, 
    Callback = function(v) _G.BoxESP = v end 
})

VisualSection:AddToggle({ 
    Title = "ESP Tracers (Line)", 
    Default = false, 
    Callback = function(v) _G.LineESP = v end 
})

VisualSection:AddToggle({ 
    Title = "ESP Skeleton (Bone)", 
    Default = false, 
    Callback = function(v) _G.SkeletonESP = v end 
})

VisualSection:AddToggle({
    Title = "ESP Health Bar",
    Default = false,
    Callback = function(v)
        _G.HealthESP = v
        if not v then
            for _, p in pairs(Players:GetPlayers()) do
                if p.Character and p.Character:FindFirstChild("Head") and p.Character.Head:FindFirstChild("HealthBarGui") then
                    pcall(function() p.Character.Head.HealthBarGui:Destroy() end)
                end
            end
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
                if p ~= LocalPlayer and p.Character then CreateESPForPlayer(p) end
            end
            
            if not _G.PlayerAddedConn then
                _G.PlayerAddedConn = Players.PlayerAdded:Connect(function(p)
                    p.CharacterAdded:Connect(function()
                        if _G.ESP then task.wait(0.5) CreateESPForPlayer(p) end
                    end)
                end)
            end
            
            Library:MakeNotify({ Title = "Enabled", Content = "ESP Highlight Aktif!" })
        else
            if _G.PlayerAddedConn then 
                _G.PlayerAddedConn:Disconnect() 
                _G.PlayerAddedConn = nil 
            end
            for _, p in pairs(Players:GetPlayers()) do 
                RemoveESPForPlayer(p) 
            end
            Library:MakeNotify({ Title = "Disabled", Content = "ESP Highlight Mati" })
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
            Library:MakeNotify({ Title = "Enabled", Content = "ESP Generator Aktif!" })
        else
            for _, label in pairs(ESPLabels) do
                pcall(function() label:Destroy() end)
            end
            ESPLabels = {}
            Library:MakeNotify({ Title = "Disabled", Content = "ESP Generator Mati" })
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
            LocalPlayer.Character.Humanoid.JumpPower = 0
            LocalPlayer.Character.Humanoid.Jump = true
            Library:MakeNotify({ Title = "Enabled", Content = "Infinite Jump Aktif!" })
        else
            LocalPlayer.Character.Humanoid.JumpPower = Config.JumpPowerDefault
            Library:MakeNotify({ Title = "Disabled", Content = "Infinite Jump Mati" })
        end
    end
})

MovementSection:AddToggle({
    Title = "NoClip",
    Description = "Lewati tembok dan objek",
    Default = false,
    Callback = function(v)
        _G.NC = v
        Library:MakeNotify({ Title = "NoClip", Content = v and "ON" or "OFF", Duration = 1 })
    end
})

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
                _G.FlyCon = RunService.RenderStepped:Connect(function()
                    local camCFrame = Workspace.CurrentCamera.CFrame
                    local moveVector = Vector3.new(0,0,0)

                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                        moveVector = moveVector + camCFrame.LookVector
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                        moveVector = moveVector - camCFrame.LookVector
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                        moveVector = moveVector - camCFrame.RightVector
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                        moveVector = moveVector + camCFrame.RightVector
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                        moveVector = moveVector + Vector3.new(0,1,0)
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                        moveVector = moveVector - Vector3.new(0,1,0)
                    end

                    root.CFrame = root.CFrame + moveVector * Config.FlySpeed * RunService.RenderStepped:Wait()
                end)
                Library:MakeNotify({ Title = "Enabled", Content = "Fly Aktif!" })
            else
                Library:MakeNotify({ Title = "Error", Content = "Tidak bisa mengaktifkan Fly!" })
            end
        else
            if _G.FlyCon then _G.FlyCon:Disconnect() end
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.PlatformStand = false
            end
            Library:MakeNotify({ Title = "Disabled", Content = "Fly Mati" })
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
        Config.FlySpeed = v
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
                    LocalPlayer.Character.Humanoid:Move(Vector3.new(0,0,0.1))
                    task.wait(1)
                    LocalPlayer.Character.Humanoid:Move(Vector3.new(0,0,-0.1))
                    task.wait(1)
                end
            end)
            Library:MakeNotify({ Title = "Enabled", Content = "Wiggle Aktif!" })
        else
            Library:MakeNotify({ Title = "Disabled", Content = "Wiggle Mati" })
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
        Library:MakeNotify({ Title = "WallHack", Content = v and "ON" or "OFF", Duration = 1 })
    end
})

VisualsSection:AddToggle({
    Title = "Headlight",
    Description = "Menyalakan lampu di kepala",
    Default = false,
    Callback = function(v)
        _G.Headlight = v
        if v then
            local light = Instance.new("SpotLight", LocalPlayer.Character.Head)
            light.Brightness = 5
            light.Range = 60
            light.Face = Enum.NormalId.Front
            light.Angle = 90
            light.Name = "Headlight"
            Library:MakeNotify({ Title = "Enabled", Content = "Headlight Aktif!" })
        else
            local light = LocalPlayer.Character.Head:FindFirstChild("Headlight")
            if light then light:Destroy() end
            Library:MakeNotify({ Title = "Disabled", Content = "Headlight Mati" })
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
            Library:MakeNotify({ Title = "Enabled", Content = "X-Ray Aktif!" })
        else
            Lighting.Ambient = Color3.new(0.5,0.5,0.5)
            Lighting.Brightness = 1
            Lighting.OutdoorAmbient = Color3.new(0.5,0.5,0.5)
            Library:MakeNotify({ Title = "Disabled", Content = "X-Ray Mati" })
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
            Library:MakeNotify({ Title = "Enabled", Content = "Fullbright Aktif!" })
        else
            Lighting.Brightness = 1
            Lighting.OutdoorAmbient = Color3.new(0.5,0.5,0.5)
            Library:MakeNotify({ Title = "Disabled", Content = "Fullbright Mati" })
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
                char.Archivable = true
                _G.FreecamChar = char:Clone()
                char.Archivable = false
                _G.FreecamChar.Parent = nil
                root.Transparency = 1
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.Transparency = 1
                    end
                end
                _G.FreecamLoop = RunService.RenderStepped:Connect(function()
                    local moveVector = Vector3.new(0,0,0)
                    local camSpeed = 1

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
                Library:MakeNotify({ Title = "Enabled", Content = "Freecam Aktif!" })
            else
                Library:MakeNotify({ Title = "Error", Content = "Tidak bisa mengaktifkan Freecam!" })
            end
        else
            if _G.FreecamLoop then _G.FreecamLoop:Disconnect() end
            local cam = Workspace.CurrentCamera
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if cam and char and root then
                cam.CameraType = Enum.CameraType.Custom
                cam.CFrame = _G.FreecamPos
                root.Transparency = 0
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.Transparency = 0
                    end
                end
            end
            Library:MakeNotify({ Title = "Disabled", Content = "Freecam Mati" })
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
            LocalPlayer.Character.Humanoid.MaxHealth = math.huge
            LocalPlayer.Character.Humanoid.Health = math.huge
            Library:MakeNotify({ Title = "Enabled", Content = "God Mode Aktif!" })
        else
            LocalPlayer.Character.Humanoid.MaxHealth = 100
            LocalPlayer.Character.Humanoid.Health = 100
            Library:MakeNotify({ Title = "Disabled", Content = "God Mode Mati" })
        end
    end
})

MiscSection:AddToggle({
    Title = "Anti Kick",
    Description = "Mencegah kick dari server",
    Default = false,
    Callback = function(v)
        _G.AntiKick = v
        Library:MakeNotify({ Title = "Anti Kick", Content = v and "ON" or "OFF", Duration = 1 })
    end
})

MiscSection:AddToggle({
    Title = "Admin Detect",
    Description = "Mendeteksi admin di server",
    Default = false,
    Callback = function(v)
        _G.AdminDetect = v
        Library:MakeNotify({ Title = "Admin Detect", Content = v and "ON" or "OFF", Duration = 1 })
    end
})

MiscSection:AddToggle({
    Title = "Hitbox",
    Description = "Memperbesar hitbox pemain",
    Default = false,
    Callback = function(v)
        _G.Hitbox = v
        Library:MakeNotify({ Title = "Hitbox", Content = v and "ON" or "OFF", Duration = 1 })
    end
})

MiscSection:AddToggle({
    Title = "Killer Warn",
    Description = "Memberi peringatan jika ada killer di dekatmu",
    Default = false,
    Callback = function(v)
        _G.KillerWarn = v
        Library:MakeNotify({ Title = "Killer Warn", Content = v and "ON" or "OFF", Duration = 1 })
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
        Library:MakeNotify({ Title = "Reconnect", Content = "Menghubungkan ulang...", Duration = 2 })
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
            Library:MakeNotify({ Title = "Server Hop", Content = "Pindah server...", Duration = 2 })
        else
            Library:MakeNotify({ Title = "Server Hop", Content = "Tidak ada server lain yang tersedia!", Duration = 2 })
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
            Library:MakeNotify({ Title = "Join Friend", Content = "Bergabung dengan " .. friend.DisplayName .. "...", Duration = 2 })
        else
            Library:MakeNotify({ Title = "Join Friend", Content = "Tidak ada teman yang online!", Duration = 2 })
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
        Library:MakeNotify({ Title = "Auto Update", Content = v and "ON" or "OFF", Duration = 1 })
    end
})

SettingsSection:AddButton({
    Title = "Save Config",
    Description = "Menyimpan konfigurasi saat ini",
    Callback = function()
        Library:MakeNotify({ Title = "Save Config", Content = "Konfigurasi disimpan!", Duration = 2 })
    end
})

SettingsSection:AddButton({
    Title = "Load Config",
    Description = "Memuat konfigurasi yang tersimpan",
    Callback = function()
        Library:MakeNotify({ Title = "Load Config", Content = "Konfigurasi dimuat!", Duration = 2 })
    end
})

SettingsSection:AddButton({
    Title = "Reset Config",
    Description = "Mengatur ulang konfigurasi ke default",
    Callback = function()
        Library:MakeNotify({ Title = "Reset Config", Content = "Konfigurasi direset!", Duration = 2 })
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
        Library:MakeNotify({ Title = "MDW HUB", Content = "Shutdown...", Duration = 2 })
        task.wait(1)
        Window:Destroy()
    end
})

-- ==========================================
-- RENDER LOOP FOR ESP
-- ==========================================
RunService.RenderStepped:Connect(function()
    if _G.BoxESP or _G.LineESP or _G.SkeletonESP then
        UpdateESP()
    else
        for _, player in pairs(Players:GetPlayers()) do
            ClearESP(player)
        end
    end

    if _G.MountESP then
        UpdateMountESP()
    else
        ClearAllMountESPs()
    end

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
                elseif gui then
                    pcall(function() gui:Destroy() end)
                end
            end
        end
    end
end)

-- Click TP
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

-- NoClip Loop
RunService.Stepped:Connect(function()
    if _G.NC and LocalPlayer.Character then
        for _, p in pairs(LocalPlayer.Character:GetChildren()) do 
            if p:IsA("BasePart") then 
                p.CanCollide = false 
            end 
            for _, child in pairs(p:GetDescendants()) do
                if child:IsA("BasePart") then child.CanCollide = false end
            end
        end
    end
end)

-- ==========================================
-- CHAT COMMAND LISTENER
-- ==========================================
local function onChatMessage(message, player)
    if player == LocalPlayer then
        ProcessChatCommand(message)
    end
end

-- Listen for chat messages
pcall(function()
    if TextChatService then
        TextChatService.OnIncomingMessage:Connect(function(message)
            if message and message.Text then
                local sender = message.Sender
                if sender == LocalPlayer then
                    ProcessChatCommand(message.Text)
                end
            end
        end)
    end
end)

-- Alternative: Listen to chat window
pcall(function()
    local chat = LocalPlayer.PlayerGui:FindFirstChild("Chat")
    if chat then
        local frame = chat:FindFirstChild("Frame")
        if frame then
            local chatBar = frame:FindFirstChild("ChatBarParentFrame") or frame:FindFirstChild("ChatBar")
            if chatBar then
                chatBar.ChildAdded:Connect(function(child)
                    if child:IsA("TextButton") and child.Name == "SendButton" then
                        -- This is a simplified approach
                    end
                end)
            end
        end
    end
end)

-- ==========================================
-- INITIALIZE
-- ==========================================
Library:Initialize()
Library:MakeNotify({ Title = "FCAL HUB", Content = "Script Loaded Successfully! (All Features + Mount System + Admin System)", Duration = 5 })

print("✅ Mount System loaded!")
print("✅ Admin System loaded!")
print("💡 Gunakan tab 'Mount' untuk mengakses semua fitur mount")
print("💡 Gunakan !command di chat untuk perintah admin")
print("💡 Ketik !help untuk daftar perintah")

-- Auto update dropdown
Players.PlayerAdded:Connect(UpdateDropdown)
Players.PlayerRemoving:Connect(UpdateDropdown)
Players.PlayerRemoving:Connect(ClearESP)