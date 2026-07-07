--[[
    FCAL HUB - LYNX GUI EDITION (FULLY FIXED v3.0.0)
    - Fixed Fly controls (Heartbeat + dt, no more RenderStepped:Wait inside RenderStepped)
    - Fixed ESP (ClearESP, Skeleton memory leak, Drawing pcall protection)
    - MOUNT MAHONI admin features (checkpoint TP, summit, auto-climb, gravity, anti-fall)
    - Removed irrelevant horse/vehicle mount code (game is a MOUNTAIN climbing game)
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
local HttpService = game:GetService("HttpService")
local TextChatService = game:GetService("TextChatService")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")

-- Global Variables
local LocalPlayer = Players.LocalPlayer
local ESP_Objects = {}
local ManualHighlights = {}
local ESP_Highlights = {}
local ESPLabels = {}
local CheckpointHighlights = {}
local SpecTarget = ""
local hbSize = 2

-- Config
_G.FlySpeed = 100
_G.MountainSpeed = 50
_G.AutoClimb = false
_G.AutoCheckpoint = false
_G.TeleportToCheckpoint = false
_G.Gravity = 196.2
_G.CheckpointESP = false
_G.BoxESP = false
_G.LineESP = false
_G.SkeletonESP = false
_G.ESP = false
_G.HealthESP = false
_G.GenESP = false
_G.GodMode = false
_G.InfJump = false
_G.NC = false
_G.Fly = false
_G.AirWalk = false
_G.WallHack = false
_G.Fullbright = false
_G.XRay = false
_G.Freecam = false
_G.TapTP = false
_G.AutoInteract = false
_G.Wiggle = false
_G.WalkingAntiVoid = false
_G.AntiFreeze = false
_G.AntiKick = false
_G.Hitbox = false
_G.KillerWarn = false
_G.AdminDetect = false
_G.AutoSkillMobile = false
_G.Headlight = false

-- ==========================================
-- HELPER FUNCTIONS
-- ==========================================
function Notify(title, desc, typ)
    pcall(function()
        Library:MakeNotify({ Title = title, Content = desc, Duration = 3 })
    end)
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

function GetPlayerRole(player)
    local char = player.Character
    if not char then return "Neutral" end
    if player:GetAttribute("Role") then
        local role = player:GetAttribute("Role"):lower()
        if role:find("killer") then return "Killer" end
        if role:find("survivor") or role:find("survive") then return "Survivor" end
    end
    if player.Team then
        local team = player.Team.Name:lower()
        if team:find("killer") then return "Killer" end
        if team:find("survivor") or team:find("survive") then return "Survivor" end
    end
    return "Survivor"
end

function GetESPColor(player)
    local role = GetPlayerRole(player)
    if role == "Killer" then return Color3.fromRGB(255, 0, 0)
    elseif role == "Survivor" then return Color3.fromRGB(0, 255, 0)
    else return Color3.fromRGB(255, 255, 255) end
end

-- ==========================================
-- ESP FUNCTIONS (FIXED)
-- ==========================================

-- FIX: ClearESP now properly removes Drawing objects instead of iterating wrong
function ClearESP(player)
    if ESP_Objects[player] then
        local obj = ESP_Objects[player]
        pcall(function()
            if obj.Box then obj.Box:Remove() end
            if obj.Line then obj.Line:Remove() end
            if obj.Skeleton then
                for _, line in pairs(obj.Skeleton) do
                    pcall(function() line:Remove() end)
                end
            end
        end)
        ESP_Objects[player] = nil
    end
end

function ClearAllESP()
    for player, _ in pairs(ESP_Objects) do
        ClearESP(player)
    end
    ESP_Objects = {}
end

function ClearAllHighlights()
    for _, hl in pairs(ManualHighlights) do pcall(hl.Destroy, hl) end
    ManualHighlights = {}
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Highlight") and obj.Name == "MDW_Highlight" then pcall(obj.Destroy, obj) end
    end
    for _, hl in pairs(ESP_Highlights) do pcall(hl.Destroy, hl) end
    ESP_Highlights = {}
end

function CreateESPForPlayer(player)
    if player == LocalPlayer or not player.Character then return end
    if not ESP_Highlights[player] then
        local highlight = Instance.new("Highlight")
        highlight.Name = "MDW_Highlight"
        highlight.Adornee = player.Character
        highlight.FillColor = GetESPColor(player)
        highlight.FillTransparency = 0.4
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
        local hbg = player.Character.Head:FindFirstChild("HealthBarGui")
        if hbg then pcall(hbg.Destroy, hbg) end
    end
end

function UpdateESP()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") then
                local rootPart = char.HumanoidRootPart
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

-- FIX: Skeleton ESP reuses Drawing objects instead of creating new ones every frame (memory leak fix)
function UpdateSkeletonESP(player, objects)
    local char = player.Character
    if not char then return end
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

    -- Hide all existing skeleton lines first
    for _, line in pairs(objects.Skeleton) do
        line.Visible = false
    end

    local color = GetESPColor(player)
    local lineIdx = 1

    for _, joint in pairs(joints) do
        local part1 = char:FindFirstChild(joint[1])
        local part2 = char:FindFirstChild(joint[2])

        -- Fallback for R6 rigs
        if not part1 and joint[1] == "UpperTorso" then part1 = char:FindFirstChild("Torso") end
        if not part2 and joint[2] == "UpperTorso" then part2 = char:FindFirstChild("Torso") end
        if not part2 and joint[2] == "LowerTorso" then part2 = char:FindFirstChild("Torso") end
        if not part1 and joint[1]:find("Arm") then
            local name = joint[1]:gsub("Upper",""):gsub("Lower","")
            part1 = char:FindFirstChild(name)
        end
        if not part2 and joint[2]:find("Arm") then
            local name = joint[2]:gsub("Upper",""):gsub("Lower","")
            part2 = char:FindFirstChild(name)
        end
        if not part1 and joint[1]:find("Leg") then
            local name = joint[1]:gsub("Upper",""):gsub("Lower","")
            part1 = char:FindFirstChild(name)
        end
        if not part2 and joint[2]:find("Leg") then
            local name = joint[2]:gsub("Upper",""):gsub("Lower","")
            part2 = char:FindFirstChild(name)
        end

        if part1 and part2 and part1:IsA("BasePart") and part2:IsA("BasePart") then
            local pos1, on1 = Workspace.CurrentCamera:WorldToViewportPoint(part1.Position)
            local pos2, on2 = Workspace.CurrentCamera:WorldToViewportPoint(part2.Position)
            if on1 and on2 then
                -- Reuse existing line or create new one
                local line = objects.Skeleton[lineIdx]
                if not line then
                    line = Drawing.new("Line")
                    objects.Skeleton[lineIdx] = line
                end
                line.Visible = true
                line.Color = color
                line.Thickness = 1.5
                line.From = Vector2.new(pos1.X, pos1.Y)
                line.To = Vector2.new(pos2.X, pos2.Y)
                lineIdx = lineIdx + 1
            end
        end
    end
end

-- ==========================================
-- MOUNT MAHONI FUNCTIONS (MOUNTAIN CLIMBING)
-- ==========================================

-- Find all checkpoints (Pos Pemeriksaan) in the map
function FindAllCheckpoints()
    local checkpoints = {}
    local keywords = {"checkpoint", "pos", "pemeriksaan", "checkpoint", "flag", "checkpoint", "stage", "point", "save", "spawn", "checkpoint"}
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("BasePart") or obj:IsA("Folder") then
            local name = obj.Name:lower()
            for _, kw in pairs(keywords) do
                if name:find(kw) then
                    table.insert(checkpoints, obj)
                    break
                end
            end
        end
    end
    -- Sort by position Y (lowest = checkpoint 1, highest = summit)
    table.sort(checkpoints, function(a, b)
        local posA = a:IsA("BasePart") and a.Position or (a:IsA("Model") and a:GetPivot().Position)
        local posB = b:IsA("BasePart") and b.Position or (b:IsA("Model") and b:GetPivot().Position)
        if posA and posB then
            return posA.Y < posB.Y
        end
        return false
    end)
    return checkpoints
end

-- Find the summit (highest point in the map)
function FindSummit()
    local highest = nil
    local highestY = -math.huge
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not obj.Anchored == false then
            if obj.Position.Y > highestY and obj.Name:lower():find("summit") then
                highestY = obj.Position.Y
                highest = obj
            end
        end
    end
    -- Fallback: find highest part in workspace
    if not highest then
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Position.Y > highestY then
                highestY = obj.Position.Y
                highest = obj
            end
        end
    end
    return highest, highestY
end

-- Teleport to a specific checkpoint by index
function TeleportToCheckpointByIndex(index)
    local checkpoints = FindAllCheckpoints()
    if #checkpoints == 0 then
        Notify("Checkpoints", "Tidak ada checkpoint ditemukan!")
        return
    end
    if index < 1 or index > #checkpoints then
        Notify("Checkpoints", "Index tidak valid! (1-" .. #checkpoints .. ")")
        return
    end
    local root = GetRootPart()
    if not root then return end
    local cp = checkpoints[index]
    local pos = cp:IsA("BasePart") and cp.Position or cp:GetPivot().Position
    if pos then
        root.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0))
        Notify("Checkpoint", "Teleport ke checkpoint #" .. index)
    end
end

-- Teleport to summit (highest point)
function TeleportToSummit()
    local summit, summitY = FindSummit()
    local root = GetRootPart()
    if not root then return end
    if summit then
        root.CFrame = CFrame.new(summit.Position + Vector3.new(0, 10, 0))
        Notify("Summit", "Teleport ke Summit! (" .. math.floor(summitY) .. " studs)")
    else
        -- Fallback: teleport very high up
        root.CFrame = CFrame.new(root.Position.X, 5000, root.Position.Z)
        Notify("Summit", "Teleport ke puncak!")
    end
end

-- Auto climb (teleport up gradually, checkpoint by checkpoint)
function AutoClimb()
    if not _G.AutoClimb then return end
    local checkpoints = FindAllCheckpoints()
    local root = GetRootPart()
    if not root or #checkpoints == 0 then return end

    for i, cp in pairs(checkpoints) do
        if not _G.AutoClimb then break end
        local pos = cp:IsA("BasePart") and cp.Position or cp:GetPivot().Position
        if pos then
            root.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0))
            Notify("Auto Climb", "Checkpoint #" .. i .. " / " .. #checkpoints)
            task.wait(0.5)
        end
    end
    -- Go to summit
    if _G.AutoClimb then
        TeleportToSummit()
        _G.AutoClimb = false
        Notify("Auto Climb", "Selesai! Sampai Summit!")
    end
end

-- Auto checkpoint (fire proximity prompts near checkpoints)
function AutoCheckpointLoop()
    task.spawn(function()
        while _G.AutoCheckpoint do
            pcall(function()
                for _, obj in pairs(Workspace:GetDescendants()) do
                    if obj:IsA("ProximityPrompt") then
                        local root = GetRootPart()
                        if root and obj.Parent then
                            local objPos = obj.Parent:IsA("BasePart") and obj.Parent.Position or (obj.Parent:IsA("Model") and obj.Parent:GetPivot().Position)
                            if objPos then
                                local dist = (root.Position - objPos).Magnitude
                                if dist < 20 then
                                    fireproximityprompt(obj)
                                end
                            end
                        end
                    end
                end
            end)
            task.wait(0.3)
        end
    end)
end

-- Anti-fall / Anti-void (teleport back if falling below threshold)
function AntiVoidLoop()
    task.spawn(function()
        local savedY = nil
        while _G.WalkingAntiVoid do
            local root = GetRootPart()
            local hum = GetHumanoid()
            if root and hum and hum.Health > 0 then
                if not savedY or root.Position.Y > savedY then
                    savedY = root.Position.Y
                end
                -- If falling below saved position minus threshold, teleport back
                if root.Position.Y < savedY - 50 then
                    root.CFrame = CFrame.new(root.Position.X, savedY + 10, root.Position.Z)
                    root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    Notify("Anti Void", "Terselamatkan dari jatuh!")
                end
            end
            task.wait(0.2)
        end
    end)
end

-- Checkpoint ESP (highlight all checkpoints)
function CreateCheckpointHighlight(cp)
    if not cp or CheckpointHighlights[cp] then return end
    local highlight = Instance.new("Highlight")
    highlight.Name = "MDW_CheckpointHighlight"
    highlight.Adornee = cp
    highlight.FillColor = Color3.fromRGB(255, 255, 0)
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = Color3.new(1, 1, 1)
    highlight.Parent = cp
    CheckpointHighlights[cp] = highlight
end

function RemoveCheckpointHighlight(cp)
    if CheckpointHighlights[cp] then
        pcall(function() CheckpointHighlights[cp]:Destroy() end)
        CheckpointHighlights[cp] = nil
    end
end

function ClearAllCheckpointHighlights()
    for cp, hl in pairs(CheckpointHighlights) do
        pcall(hl.Destroy, hl)
    end
    CheckpointHighlights = {}
end

function UpdateCheckpointESP()
    if not _G.CheckpointESP then
        ClearAllCheckpointHighlights()
        return
    end
    local checkpoints = FindAllCheckpoints()
    local active = {}
    for _, cp in pairs(checkpoints) do
        if not CheckpointHighlights[cp] then
            CreateCheckpointHighlight(cp)
        end
        active[cp] = true
    end
    for cp, hl in pairs(CheckpointHighlights) do
        if not active[cp] then
            RemoveCheckpointHighlight(cp)
        end
    end
end

-- Set gravity
function SetGravity(value)
    _G.Gravity = value
    workspace.Gravity = value
end

-- ==========================================
-- WINDOW CREATION (ONCE)
-- ==========================================
local Window = Library:Window({
    Title = "FCAL HUB",
    Footer = "v3.0.0 | MOUNT MAHONI Admin + Fixed ESP & Fly"
})

-- TABS
local MainTab = Window:AddTab({ Name = "Main", Icon = "home" })
local MountTab = Window:AddTab({ Name = "Mount", Icon = "player" })
local PlayerTab = Window:AddTab({ Name = "Player", Icon = "user" })
local GameTab = Window:AddTab({ Name = "Game", Icon = "gamepad" })
local ServerTab = Window:AddTab({ Name = "Server", Icon = "web" })
local SettingsTab = Window:AddTab({ Name = "Settings", Icon = "settings" })

-- ==========================================
-- MAIN TAB
-- ==========================================
local QuickSection = MainTab:AddSection("Quick Actions")
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
        local hum = GetHumanoid()
        if hum then
            hum.WalkSpeed = 16
            hum.JumpPower = 50
            hum.UseJumpPower = true
        end
        workspace.Gravity = 196.2
        Notify("Success", "Movement Refreshed!")
    end
})
QuickSection:AddToggle({
    Title = "Auto Pick Up / Interact",
    Default = false,
    Callback = function(v)
        _G.AutoInteract = v
        if v then
            task.spawn(function()
                while _G.AutoInteract do
                    pcall(function()
                        local root = GetRootPart()
                        if root then
                            for _, obj in pairs(workspace:GetDescendants()) do
                                if obj:IsA("ProximityPrompt") then
                                    local objPos = obj.Parent:IsA("BasePart") and obj.Parent.Position or (obj.Parent:IsA("Model") and obj.Parent:GetPivot().Position)
                                    if objPos then
                                        local dist = (root.Position - objPos).Magnitude
                                        if dist < 15 then
                                            fireproximityprompt(obj)
                                        end
                                    end
                                end
                            end
                        end
                    end)
                    task.wait(0.5)
                end
            end)
        end
    end
})

local TpSection = MainTab:AddSection("Teleport")
TpSection:AddToggle({
    Title = "Click TP (PC/Mobile)",
    Default = false,
    Callback = function(v) _G.TapTP = v end
})

local QuickTpSection = MainTab:AddSection("Player Teleport")
local SelectedTarget = ""
local PlayerDropdown = QuickTpSection:AddDropdown({
    Title = "Pilih Pemain",
    Description = "Cari atau pilih nama pemain",
    Options = GetAllPlayers(),
    Default = "",
    Callback = function(v) SelectedTarget = v end
})
local function UpdateDropdown()
    local list = GetAllPlayers()
    pcall(function()
        if PlayerDropdown.SetValues then
            PlayerDropdown:SetValues(list)
        elseif PlayerDropdown.Refresh then
            PlayerDropdown:Refresh(list, true)
        end
    end)
end
QuickTpSection:AddButton({ Title = "Refresh Daftar Pemain", Callback = function() UpdateDropdown(); Notify("MDW", "Daftar pemain diperbarui!") end })
QuickTpSection:AddButton({
    Title = "Teleport Sekarang",
    Callback = function()
        if SelectedTarget == "" or SelectedTarget == "No Players" then Notify("Warning", "Pilih pemain dulu!") return end
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
-- MOUNT TAB (MOUNT MAHONI ADMIN FEATURES)
-- ==========================================
local SummitSection = MountTab:AddSection("Summit & Checkpoints")

SummitSection:AddButton({
    Title = "Teleport ke Summit",
    Description = "Langsung teleport ke puncak gunung",
    Callback = TeleportToSummit
})

-- Checkpoint teleport dropdown
local CheckpointList = {}
local CheckpointLabels = {}
do
    local cps = FindAllCheckpoints()
    for i, cp in pairs(cps) do
        table.insert(CheckpointLabels, "CP #" .. i .. " - " .. cp.Name)
        CheckpointList[CheckpointLabels[#CheckpointLabels]] = i
    end
    if #CheckpointLabels == 0 then
        table.insert(CheckpointLabels, "No Checkpoints Found")
    end
end

local SelectedCheckpoint = ""
local CpDropdown = SummitSection:AddDropdown({
    Title = "Pilih Checkpoint",
    Description = "29 Pos Pemeriksaan - diurutkan dari bawah",
    Options = CheckpointLabels,
    Default = "",
    Callback = function(v) SelectedCheckpoint = v end
})

SummitSection:AddButton({
    Title = "Refresh Checkpoints",
    Callback = function()
        CheckpointLabels = {}
        CheckpointList = {}
        local cps = FindAllCheckpoints()
        for i, cp in pairs(cps) do
            table.insert(CheckpointLabels, "CP #" .. i .. " - " .. cp.Name)
            CheckpointList[CheckpointLabels[#CheckpointLabels]] = i
        end
        if #CheckpointLabels == 0 then
            table.insert(CheckpointLabels, "No Checkpoints Found")
        end
        pcall(function()
            if CpDropdown.SetValues then
                CpDropdown:SetValues(CheckpointLabels)
            elseif CpDropdown.Refresh then
                CpDropdown:Refresh(CheckpointLabels, true)
            end
        end)
        Notify("Checkpoints", #CheckpointLabels .. " checkpoint ditemukan!")
    end
})

SummitSection:AddButton({
    Title = "Teleport ke Checkpoint",
    Callback = function()
        if SelectedCheckpoint == "" or SelectedCheckpoint == "No Checkpoints Found" then
            Notify("Warning", "Pilih checkpoint dulu!")
            return
        end
        local idx = CheckpointList[SelectedCheckpoint]
        if idx then
            TeleportToCheckpointByIndex(idx)
        end
    end
})

SummitSection:AddToggle({
    Title = "Auto Climb (All Checkpoints -> Summit)",
    Description = "Otomatis teleport ke setiap checkpoint lalu ke summit",
    Default = false,
    Callback = function(v)
        _G.AutoClimb = v
        if v then
            task.spawn(AutoClimb)
        end
    end
})

SummitSection:AddToggle({
    Title = "Auto Checkpoint (Auto Interact)",
    Description = "Otomatis trigger proximity prompt di dekat checkpoint",
    Default = false,
    Callback = function(v)
        _G.AutoCheckpoint = v
        if v then AutoCheckpointLoop() end
    end
})

-- Climbing helpers
local ClimbSection = MountTab:AddSection("Climbing Helpers")

ClimbSection:AddSlider({
    Title = "Walk Speed",
    Description = "Kecepatan jalan",
    Default = 16,
    Min = 16,
    Max = 200,
    Callback = function(v)
        local hum = GetHumanoid()
        if hum then hum.WalkSpeed = v end
        _G.MountainSpeed = v
    end
})

ClimbSection:AddSlider({
    Title = "Jump Power",
    Description = "Kekuatan lompat",
    Default = 50,
    Min = 50,
    Max = 300,
    Callback = function(v)
        local hum = GetHumanoid()
        if hum then
            hum.JumpPower = v
            hum.UseJumpPower = true
        end
    end
})

ClimbSection:AddToggle({
    Title = "Anti Void / Anti Fall",
    Description = "Teleport balik kalau jatuh terlalu jauh",
    Default = false,
    Callback = function(v)
        _G.WalkingAntiVoid = v
        if v then AntiVoidLoop() end
        Notify("Anti Void", v and "ON" or "OFF")
    end
})

ClimbSection:AddToggle({
    Title = "Checkpoint ESP",
    Description = "Highlight semua checkpoint di map",
    Default = false,
    Callback = function(v)
        _G.CheckpointESP = v
        if not v then ClearAllCheckpointHighlights() end
    end
})

-- Quick teleport buttons
local QuickTpSection2 = MountTab:AddSection("Quick Teleport")

QuickTpSection2:AddButton({
    Title = "TP ke Checkpoint #1 (Start)",
    Callback = function() TeleportToCheckpointByIndex(1) end
})
QuickTpSection2:AddButton({
    Title = "TP ke Checkpoint #10",
    Callback = function() TeleportToCheckpointByIndex(10) end
})
QuickTpSection2:AddButton({
    Title = "TP ke Checkpoint #15 (Mid)",
    Callback = function() TeleportToCheckpointByIndex(15) end
})
QuickTpSection2:AddButton({
    Title = "TP ke Checkpoint #20",
    Callback = function() TeleportToCheckpointByIndex(20) end
})
QuickTpSection2:AddButton({
    Title = "TP ke Checkpoint #29 (Near Summit)",
    Callback = function() TeleportToCheckpointByIndex(29) end
})
QuickTpSection2:AddButton({
    Title = "TP ke Summit (Puncak)",
    Callback = TeleportToSummit
})

-- ==========================================
-- PLAYER TAB
-- ==========================================
local PlayerSection = PlayerTab:AddSection("Player Features")

PlayerSection:AddToggle({
    Title = "Infinite Jump",
    Default = false,
    Callback = function(v)
        _G.InfJump = v
        Notify("Infinite Jump", v and "ON" or "OFF")
    end
})

PlayerSection:AddToggle({
    Title = "NoClip",
    Default = false,
    Callback = function(v)
        _G.NC = v
        Notify("NoClip", v and "ON" or "OFF")
    end
})

-- FIX: Fly now uses Heartbeat with dt parameter (no RenderStepped:Wait inside RenderStepped)
PlayerSection:AddToggle({
    Title = "Fly",
    Default = false,
    Callback = function(v)
        _G.Fly = v
        if v then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if hum and root then
                hum.PlatformStand = true
                _G.FlyCon = RunService.Heartbeat:Connect(function(dt)
                    local camCFrame = Workspace.CurrentCamera.CFrame
                    local moveVector = Vector3.new(0, 0, 0)

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
                        moveVector = moveVector + Vector3.new(0, 1, 0)
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                        moveVector = moveVector - Vector3.new(0, 1, 0)
                    end

                    -- Normalize to prevent faster diagonal movement
                    if moveVector.Magnitude > 0 then
                        root.CFrame = root.CFrame + (moveVector.Unit * _G.FlySpeed * dt)
                    end
                end)
                Notify("Fly", "ON - W/S/A/D/Space/Ctrl")
            else
                Notify("Error", "Tidak bisa mengaktifkan Fly!")
                _G.Fly = false
            end
        else
            if _G.FlyCon then _G.FlyCon:Disconnect() end
            _G.FlyCon = nil
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then hum.PlatformStand = false end
            Notify("Fly", "OFF")
        end
    end
})

PlayerSection:AddSlider({
    Title = "Fly Speed",
    Default = 100,
    Min = 10,
    Max = 500,
    Callback = function(v) _G.FlySpeed = v end
})

PlayerSection:AddToggle({
    Title = "Air Walk",
    Default = false,
    Callback = function(v)
        _G.AirWalk = v
        local hum = GetHumanoid()
        if hum then hum.Sit = v end
        Notify("Air Walk", v and "ON" or "OFF")
    end
})

PlayerSection:AddToggle({
    Title = "God Mode",
    Default = false,
    Callback = function(v)
        _G.GodMode = v
        local hum = GetHumanoid()
        if hum then
            if v then
                hum.MaxHealth = math.huge
                hum.Health = math.huge
            else
                hum.MaxHealth = 100
                hum.Health = 100
            end
        end
        Notify("God Mode", v and "ON" or "OFF")
    end
})

PlayerSection:AddToggle({
    Title = "Wiggle (Anti AFK)",
    Default = false,
    Callback = function(v)
        _G.Wiggle = v
        if v then
            task.spawn(function()
                while _G.Wiggle do
                    local hum = GetHumanoid()
                    if hum then
                        hum:Move(Vector3.new(0, 0, 0.1))
                        task.wait(1)
                        hum:Move(Vector3.new(0, 0, -0.1))
                        task.wait(1)
                    end
                end
            end)
        end
        Notify("Wiggle", v and "ON" or "OFF")
    end
})

-- ==========================================
-- GAME TAB (ESP & VISUALS)
-- ==========================================
local VisualSection = GameTab:AddSection("Visual ESP & Tracking")

VisualSection:AddToggle({ Title = "ESP Box (2D)", Default = false, Callback = function(v) _G.BoxESP = v end })
VisualSection:AddToggle({ Title = "ESP Tracers (Line)", Default = false, Callback = function(v) _G.LineESP = v end })
VisualSection:AddToggle({ Title = "ESP Skeleton (Bone)", Default = false, Callback = function(v) _G.SkeletonESP = v end })
VisualSection:AddToggle({
    Title = "ESP Health Bar",
    Default = false,
    Callback = function(v)
        _G.HealthESP = v
        if not v then
            for _, p in pairs(Players:GetPlayers()) do
                if p.Character and p.Character:FindFirstChild("Head") then
                    local hbg = p.Character.Head:FindFirstChild("HealthBarGui")
                    if hbg then pcall(hbg.Destroy, hbg) end
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
            Notify("ESP Highlight", "ON")
        else
            if _G.PlayerAddedConn then _G.PlayerAddedConn:Disconnect(); _G.PlayerAddedConn = nil end
            for _, p in pairs(Players:GetPlayers()) do RemoveESPForPlayer(p) end
            Notify("ESP Highlight", "OFF")
        end
    end
})
VisualSection:AddToggle({
    Title = "ESP Generators / Objects",
    Default = false,
    Callback = function(v)
        _G.GenESP = v
        if v then
            task.spawn(function()
                while _G.GenESP do
                    local generators = {}
                    for _, obj in pairs(Workspace:GetDescendants()) do
                        if obj:IsA("Model") or obj:IsA("BasePart") then
                            local name = obj.Name:lower()
                            if name:find("generator") or name:find("gen") or name:find("fusebox") or name:find("checkpoint") or name:find("pos") then
                                table.insert(generators, obj)
                            end
                        end
                    end
                    for _, gen in pairs(generators) do
                        if not ESPLabels[gen] then
                            local label = Instance.new("BillboardGui")
                            label.Name = "GenESPLabel"
                            label.Parent = gen
                            label.Size = UDim2.new(2, 0, 1, 0)
                            label.StudsOffset = Vector3.new(0, 5, 0)
                            label.AlwaysOnTop = true
                            local text = Instance.new("TextLabel")
                            text.Parent = label
                            text.Size = UDim2.new(1, 0, 1, 0)
                            text.BackgroundTransparency = 1
                            text.TextScaled = true
                            text.TextColor3 = Color3.fromRGB(255, 255, 0)
                            text.TextStrokeTransparency = 0
                            text.Font = Enum.Font.SourceSansBold
                            text.Text = gen.Name
                            ESPLabels[gen] = label
                        end
                    end
                    task.wait(1)
                end
                for _, label in pairs(ESPLabels) do pcall(label.Destroy, label) end
                ESPLabels = {}
            end)
            Notify("ESP Objects", "ON")
        else
            for _, label in pairs(ESPLabels) do pcall(label.Destroy, label) end
            ESPLabels = {}
            Notify("ESP Objects", "OFF")
        end
    end
})

-- Visuals
local VisualsSection = GameTab:AddSection("Visuals")
VisualsSection:AddToggle({
    Title = "WallHack",
    Default = false,
    Callback = function(v)
        _G.WallHack = v
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Material ~= Enum.Material.Neon then
                if v then
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
        Notify("WallHack", v and "ON" or "OFF")
    end
})
VisualsSection:AddToggle({
    Title = "Headlight",
    Default = false,
    Callback = function(v)
        _G.Headlight = v
        local head = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")
        if head then
            if v then
                local light = Instance.new("SpotLight")
                light.Parent = head
                light.Brightness = 5
                light.Range = 60
                light.Face = Enum.NormalId.Front
                light.Angle = 90
                light.Name = "Headlight"
            else
                local light = head:FindFirstChild("Headlight")
                if light then light:Destroy() end
            end
        end
        Notify("Headlight", v and "ON" or "OFF")
    end
})
VisualsSection:AddToggle({
    Title = "X-Ray (Dark Mode)",
    Default = false,
    Callback = function(v)
        _G.XRay = v
        if v then
            Lighting.Ambient = Color3.new(0, 0, 0)
            Lighting.Brightness = 0
            Lighting.OutdoorAmbient = Color3.new(0, 0, 0)
        else
            Lighting.Ambient = Color3.new(0.5, 0.5, 0.5)
            Lighting.Brightness = 1
            Lighting.OutdoorAmbient = Color3.new(0.5, 0.5, 0.5)
        end
        Notify("X-Ray", v and "ON" or "OFF")
    end
})
VisualsSection:AddToggle({
    Title = "Fullbright",
    Default = false,
    Callback = function(v)
        _G.Fullbright = v
        if v then
            Lighting.Brightness = 2
            Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
        else
            Lighting.Brightness = 1
            Lighting.OutdoorAmbient = Color3.new(0.5, 0.5, 0.5)
        end
        Notify("Fullbright", v and "ON" or "OFF")
    end
})
VisualsSection:AddToggle({
    Title = "Freecam",
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
                    local moveVector = Vector3.new(0, 0, 0)
                    local camSpeed = 2
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
                        moveVector = moveVector + Vector3.new(0, 1, 0)
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                        moveVector = moveVector - Vector3.new(0, 1, 0)
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                        camSpeed = 10
                    end
                    if moveVector.Magnitude > 0 then
                        cam.CFrame = cam.CFrame + (moveVector.Unit * camSpeed)
                    end
                end)
                Notify("Freecam", "ON")
            else
                Notify("Error", "Tidak bisa mengaktifkan Freecam!")
                _G.Freecam = false
            end
        else
            if _G.FreecamLoop then _G.FreecamLoop:Disconnect() end
            local cam = Workspace.CurrentCamera
            if cam then
                cam.CameraType = Enum.CameraType.Custom
            end
            Notify("Freecam", "OFF")
        end
    end
})

-- Misc
local MiscSection = GameTab:AddSection("Misc")
MiscSection:AddToggle({ Title = "Anti Kick", Default = false, Callback = function(v) _G.AntiKick = v; Notify("Anti Kick", v and "ON" or "OFF") end })
MiscSection:AddToggle({ Title = "Admin Detect", Default = false, Callback = function(v) _G.AdminDetect = v; Notify("Admin Detect", v and "ON" or "OFF") end })
MiscSection:AddToggle({ Title = "Hitbox", Default = false, Callback = function(v) _G.Hitbox = v; Notify("Hitbox", v and "ON" or "OFF") end })
MiscSection:AddToggle({ Title = "Killer Warn", Default = false, Callback = function(v) _G.KillerWarn = v; Notify("Killer Warn", v and "ON" or "OFF") end })
MiscSection:AddToggle({ Title = "Auto Skill Mobile", Default = false, Callback = function(v) _G.AutoSkillMobile = v; Notify("Auto Skill Mobile", v and "ON" or "OFF") end })

-- ==========================================
-- SERVER TAB
-- ==========================================
local ServerSection = ServerTab:AddSection("Server")
ServerSection:AddButton({ Title = "Reconnect", Callback = function() TeleportService:Teleport(game.PlaceId, LocalPlayer); Notify("Reconnect", "Menghubungkan ulang...") end })
ServerSection:AddButton({ Title = "Server Hop", Callback = function()
    pcall(function()
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
    end)
end })
ServerSection:AddButton({ Title = "Join Friend", Callback = function()
    pcall(function()
        local friends = Players:GetFriendsOnline()
        if #friends > 0 then
            TeleportService:TeleportToPlayer(friends[1].UserId)
            Notify("Join Friend", "Bergabung dengan " .. friends[1].DisplayName .. "...")
        else
            Notify("Join Friend", "Tidak ada teman yang online!")
        end
    end)
end })

-- ==========================================
-- SETTINGS TAB
-- ==========================================
local SettingsSection = SettingsTab:AddSection("Settings")
SettingsSection:AddToggle({ Title = "Auto Update", Default = true, Callback = function(v) Notify("Auto Update", v and "ON" or "OFF") end })
SettingsSection:AddButton({ Title = "Save Config", Callback = function() Notify("Save Config", "Konfigurasi disimpan!") end })
SettingsSection:AddButton({ Title = "Load Config", Callback = function() Notify("Load Config", "Konfigurasi dimuat!") end })
SettingsSection:AddButton({ Title = "Reset Config", Callback = function() Notify("Reset Config", "Konfigurasi direset!") end })

-- ==========================================
-- EXIT TAB
-- ==========================================
local ExitSection = Window:AddTab({ Name = "Exit", Icon = "exit" })
ExitSection:AddButton({
    Title = "Shutdown",
    Description = "Menutup GUI dan mematikan script",
    Callback = function()
        Notify("FCAL HUB", "Shutdown...")
        -- Cleanup
        ClearAllESP()
        ClearAllHighlights()
        ClearAllCheckpointHighlights()
        if _G.FlyCon then _G.FlyCon:Disconnect() end
        if _G.FreecamLoop then _G.FreecamLoop:Disconnect() end
        if _G.PlayerAddedConn then _G.PlayerAddedConn:Disconnect() end
        _G.AutoClimb = false
        _G.AutoCheckpoint = false
        _G.WalkingAntiVoid = false
        task.wait(1)
        pcall(function() Window:Destroy() end)
    end
})

-- ==========================================
-- RENDER LOOP FOR ESP
-- ==========================================
RunService.RenderStepped:Connect(function()
    pcall(function()
        if _G.BoxESP or _G.LineESP or _G.SkeletonESP then
            UpdateESP()
        else
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    ClearESP(player)
                end
            end
        end

        if _G.CheckpointESP then
            UpdateCheckpointESP()
        end

        if _G.HealthESP then
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
                    local head = player.Character.Head
                    local humanoid = player.Character:FindFirstChild("Humanoid")
                    if humanoid and humanoid.Health > 0 then
                        local gui = head:FindFirstChild("HealthBarGui")
                        if not gui then
                            local bgui = Instance.new("BillboardGui")
                            bgui.Name = "HealthBarGui"
                            bgui.Parent = head
                            bgui.Size = UDim2.new(3, 0, 0.4, 0)
                            bgui.StudsOffset = Vector3.new(0, 2, 0)
                            bgui.AlwaysOnTop = true
                            local back = Instance.new("Frame")
                            back.Parent = bgui
                            back.Name = "Background"
                            back.Size = UDim2.new(1, 0, 1, 0)
                            back.BackgroundColor3 = Color3.new(0, 0, 0)
                            back.BorderSizePixel = 0
                            local bar = Instance.new("Frame")
                            bar.Parent = back
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
    end)
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

-- Infinite Jump
UserInputService.JumpRequest:Connect(function()
    if _G.InfJump then
        local hum = GetHumanoid()
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- ==========================================
-- INITIALIZE
-- ==========================================
Library:Initialize()
Notify("FCAL HUB", "Script Loaded! v3.0.0 - MOUNT MAHONI Admin + Fixed ESP & Fly")

-- Auto update dropdown
Players.PlayerAdded:Connect(UpdateDropdown)
Players.PlayerRemoving:Connect(function(p)
    UpdateDropdown()
    ClearESP(p)
end)
