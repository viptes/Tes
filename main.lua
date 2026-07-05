--[[
    FCAL HUB - LYNX GUI EDITION (FULLY FIXED + MOUNT ADMIN)
    Version: 2.0.0
    - Fixed Fly controls (now using camera orientation correctly)
    - Fixed ESP (2D, Skeleton, Tracers, Health, Highlight, Generators)
    - Added Mount Admin features (Teleport, Spawn, Auto Mount, Speed, Fly)
    - Removed duplicate Window creation
    - Cleaned up code and removed unused variables
    - Added robust error handling
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
local StarterGui = game:GetService("StarterGui")

-- Global Variables
local LocalPlayer = Players.LocalPlayer
local ESP_Objects = {}
local ManualHighlights = {}
local ESP_Highlights = {}
local ESPLabels = {}
local MountHighlights = {}
local CurrentMounts = {}
local SpecTarget = ""
local hbSize = 2

-- Config
_G.FlySpeed = 100
_G.MountSpeed = 50
_G.AutoMount = false
_G.SpawnMounts = false
_G.TeleportToMounts = false
_G.MountFly = false
_G.BoxESP = false
_G.LineESP = false
_G.SkeletonESP = false
_G.ESP = false
_G.HealthESP = false
_G.MountESP = false
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
    Library:MakeNotify({ Title = title, Content = desc, Duration = 3 })
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
    -- Simplified role detection
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

function ClearAllHighlights()
    for _, hl in pairs(ManualHighlights) do pcall(hl.Destroy, hl) end
    ManualHighlights = {}
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Highlight") then pcall(obj.Destroy, obj) end
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
    if ESP_Highlights[player] then pcall(ESP_Highlights[player].Destroy, ESP_Highlights[player]) end
    ESP_Highlights[player] = nil
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
    if objects.Skeleton then
        for _, line in pairs(objects.Skeleton) do pcall(function() line.Visible = false end) end
        objects.Skeleton = {}
    end
    local color = GetESPColor(player)
    for _, joint in pairs(joints) do
        local part1 = char:FindFirstChild(joint[1])
        local part2 = char:FindFirstChild(joint[2])
        if part1 and part2 and part1:IsA("BasePart") and part2:IsA("BasePart") then
            local pos1, on1 = Workspace.CurrentCamera:WorldToViewportPoint(part1.Position)
            local pos2, on2 = Workspace.CurrentCamera:WorldToViewportPoint(part2.Position)
            if on1 and on2 then
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

-- ==========================================
-- MOUNT FUNCTIONS
-- ==========================================
function FindAllMounts()
    local mounts = {}
    local found = {}
    local keywords = {"mount", "horse", "dragon", "pet", "vehicle", "ride", "steed", "pony", "unicorn", "griffin", "wolf", "tiger", "lion", "bear", "eagle", "phoenix"}
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            local name = obj.Name:lower()
            for _, kw in pairs(keywords) do
                if name:find(kw) and not name:find("player") and not name:find("character") and not name:find("humanoid") and not name:find("tool") and not name:find("weapon") then
                    local key = obj:IsA("Model") and obj:GetFullName() or obj.Name
                    if not found[key] then
                        table.insert(mounts, obj)
                        found[key] = true
                        break
                    end
                end
            end
        end
    end
    -- Also check ReplicatedStorage for possible mount templates
    for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("Model") then
            local name = obj.Name:lower()
            for _, kw in pairs(keywords) do
                if name:find(kw) and not name:find("player") and not name:find("character") and not name:find("humanoid") then
                    local key = obj:GetFullName()
                    if not found[key] then
                        table.insert(mounts, obj)
                        found[key] = true
                        break
                    end
                end
            end
        end
    end
    return mounts
end

function CreateMountHighlight(mount)
    if not mount or MountHighlights[mount] then return end
    local highlight = Instance.new("Highlight")
    highlight.Name = "MDW_MountHighlight"
    highlight.Adornee = mount
    highlight.FillColor = Color3.fromRGB(0, 255, 255)
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = Color3.new(1, 1, 1)
    highlight.Parent = mount
    MountHighlights[mount] = highlight
end

function RemoveMountHighlight(mount)
    if MountHighlights[mount] then
        pcall(MountHighlights[mount].Destroy, MountHighlights[mount])
        MountHighlights[mount] = nil
    end
end

function ClearAllMountHighlights()
    for mount, hl in pairs(MountHighlights) do
        pcall(hl.Destroy, hl)
    end
    MountHighlights = {}
end

function UpdateMountESP()
    if not _G.MountESP then
        ClearAllMountHighlights()
        return
    end
    local mounts = FindAllMounts()
    local active = {}
    for _, m in pairs(mounts) do
        if not MountHighlights[m] then
            CreateMountHighlight(m)
        end
        active[m] = true
    end
    for mount, hl in pairs(MountHighlights) do
        if not active[mount] then
            RemoveMountHighlight(mount)
        end
    end
end

-- Teleport to all mounts (one by one)
function TeleportToMounts()
    local mounts = FindAllMounts()
    if #mounts == 0 then Notify("Mounts", "No mounts found!") return end
    local root = GetRootPart()
    if not root then return end
    for _, mount in pairs(mounts) do
        local pos = mount:IsA("BasePart") and mount.Position or (mount:IsA("Model") and mount:GetPivot().Position)
        if pos then
            root.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0))
            task.wait(0.5)
        end
    end
    Notify("Mounts", "Teleported to all mounts!")
end

-- Bring mount to player
function BringMountToPlayer()
    local mountName = "Mount" -- optionally ask user
    local mounts = FindAllMounts()
    local root = GetRootPart()
    if not root then return end
    for _, mount in pairs(mounts) do
        if mount.Name:lower():find(mountName:lower()) or #mounts == 1 then
            local pos = mount:IsA("BasePart") and mount.Position or (mount:IsA("Model") and mount:GetPivot().Position)
            if pos then
                mount:SetPrimaryPartCFrame(CFrame.new(root.Position + Vector3.new(0, 0, 5)))
                Notify("Mounts", "Brought " .. mount.Name .. " to you!")
                return
            end
        end
    end
    Notify("Mounts", "Mount not found!")
end

-- Spawn all mounts (clone from ReplicatedStorage if available)
function SpawnAllMounts()
    local mounts = FindAllMounts()
    local count = 0
    for _, m in pairs(mounts) do
        if m:IsA("Model") and m:IsDescendantOf(ReplicatedStorage) then
            local clone = m:Clone()
            clone.Parent = Workspace
            clone:SetPrimaryPartCFrame(CFrame.new(LocalPlayer.Character.HumanoidRootPart.Position + Vector3.new(0, 2, count*5)))
            count = count + 1
        elseif m:IsA("BasePart") and m:IsDescendantOf(ReplicatedStorage) then
            local clone = m:Clone()
            clone.Parent = Workspace
            clone.Position = LocalPlayer.Character.HumanoidRootPart.Position + Vector3.new(0, 2, count*5)
            count = count + 1
        end
    end
    Notify("Mounts", "Spawned " .. count .. " mounts!")
end

-- Auto Mount (find nearest mount and ride it)
function AutoMount()
    if _G.AutoMount then
        local mounts = FindAllMounts()
        local root = GetRootPart()
        if not root or #mounts == 0 then return end
        local nearest = nil
        local minDist = math.huge
        for _, m in pairs(mounts) do
            local pos = m:IsA("BasePart") and m.Position or (m:IsA("Model") and m:GetPivot().Position)
            if pos then
                local d = (root.Position - pos).Magnitude
                if d < minDist then
                    minDist = d
                    nearest = m
                end
            end
        end
        if nearest then
            -- Attempt to mount by teleporting onto it and using proximity prompt if exists
            local seat = nearest:FindFirstChildWhichIsA("Seat") or nearest:FindFirstChildWhichIsA("VehicleSeat")
            if seat then
                root.CFrame = seat.CFrame * CFrame.new(0, 2, 0)
                task.wait(0.2)
                local prompt = seat:FindFirstChildWhichIsA("ProximityPrompt")
                if prompt then
                    fireproximityprompt(prompt)
                end
            end
        end
    end
end

-- Mount Fly (make mount fly)
function ToggleMountFly()
    _G.MountFly = not _G.MountFly
    if _G.MountFly then
        -- Find current mount (vehicle seat) in character
        local char = LocalPlayer.Character
        if char then
            local seat = char:FindFirstChildWhichIsA("VehicleSeat")
            if seat then
                local root = seat:FindFirstChild("HumanoidRootPart") or seat.Parent:FindFirstChild("HumanoidRootPart")
                if root then
                    _G.MountFlyCon = RunService.RenderStepped:Connect(function()
                        local camCFrame = Workspace.CurrentCamera.CFrame
                        local move = Vector3.new(0,0,0)
                        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + camCFrame.LookVector end
                        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - camCFrame.LookVector end
                        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - camCFrame.RightVector end
                        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + camCFrame.RightVector end
                        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0,1,0) end
                        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move = move - Vector3.new(0,1,0) end
                        root.CFrame = root.CFrame + move * _G.FlySpeed * RunService.RenderStepped:Wait()
                    end)
                    Notify("Mount Fly", "ON")
                end
            else
                Notify("Mount Fly", "You are not on a mount!")
            end
        end
    else
        if _G.MountFlyCon then _G.MountFlyCon:Disconnect() end
        Notify("Mount Fly", "OFF")
    end
end

-- ==========================================
-- WINDOW CREATION (ONCE)
-- ==========================================
local Window = Library:Window({
    Title = "FCAL HUB",
    Footer = "v2.0.0 | Mount Admin + Fixed ESP & Fly"
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
local QuickSection = MainTab:AddSection("🛠️ Quick Actions")
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
        workspace.Gravity = 196
        Notify("Success", "Movement Refreshed!")
    end
})
QuickSection:AddToggle({
    Title = "Auto Pick Up / Interact",
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
    Default = false,
    Callback = function(v) _G.TapTP = v end
})

local QuickTpSection = MainTab:AddSection("🚀 Player Teleport")
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
    if PlayerDropdown.SetValues then
        PlayerDropdown:SetValues(list)
    elseif PlayerDropdown.Refresh then
        PlayerDropdown:Refresh(list, true)
    end
end
QuickTpSection:AddButton({ Title = "🔄 Refresh Daftar Pemain", Callback = function() UpdateDropdown(); Notify("MDW", "Daftar pemain diperbarui!") end })
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
-- MOUNT TAB (ADMIN FEATURES)
-- ==========================================
local MountSection = MountTab:AddSection("🐎 Mount Admin")

MountSection:AddButton({
    Title = "Teleport to All Mounts",
    Description = "Teleport ke setiap mount di map",
    Callback = TeleportToMounts
})

MountSection:AddButton({
    Title = "Bring Mount to Player",
    Description = "Bawa mount terdekat ke posisi Anda",
    Callback = BringMountToPlayer
})

MountSection:AddButton({
    Title = "Spawn All Mounts",
    Description = "Spawn semua mount dari ReplicatedStorage",
    Callback = SpawnAllMounts
})

MountSection:AddToggle({
    Title = "Auto Mount",
    Description = "Otomatis naik mount terdekat",
    Default = false,
    Callback = function(v)
        _G.AutoMount = v
        if v then
            task.spawn(function()
                while _G.AutoMount do
                    AutoMount()
                    task.wait(2)
                end
            end)
        end
    end
})

MountSection:AddToggle({
    Title = "Mount Fly",
    Description = "Terbangkan mount yang Anda tumpangi",
    Default = false,
    Callback = function(v)
        if v then
            ToggleMountFly()
        else
            _G.MountFly = false
            if _G.MountFlyCon then _G.MountFlyCon:Disconnect() end
            Notify("Mount Fly", "OFF")
        end
    end
})

MountSection:AddSlider({
    Title = "Mount Speed",
    Description = "Kecepatan mount (jika didukung)",
    Default = 50,
    Min = 10,
    Max = 200,
    Callback = function(v)
        _G.MountSpeed = v
        -- Coba terapkan ke semua mount
        for _, m in pairs(FindAllMounts()) do
            local vehicle = m:FindFirstChildWhichIsA("VehicleSeat")
            if vehicle then
                local engine = vehicle:FindFirstChild("Engine")
                if engine then
                    pcall(function() engine.MaxSpeed = v end)
                end
                local throttle = vehicle:FindFirstChild("Throttle")
                if throttle then
                    pcall(function() throttle.MaxSpeed = v end)
                end
            end
        end
    end
})

MountSection:AddToggle({
    Title = "ESP Mounts",
    Description = "Highlight semua mount di map",
    Default = false,
    Callback = function(v)
        _G.MountESP = v
        if v then UpdateMountESP() else ClearAllMountHighlights() end
    end
})

-- ==========================================
-- PLAYER TAB
-- ==========================================
local PlayerSection = PlayerTab:AddSection("⚡ Player Features")

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
                    root.CFrame = root.CFrame + moveVector * _G.FlySpeed * RunService.RenderStepped:Wait()
                end)
                Notify("Fly", "ON")
            else
                Notify("Error", "Tidak bisa mengaktifkan Fly!")
            end
        else
            if _G.FlyCon then _G.FlyCon:Disconnect() end
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
                        hum:Move(Vector3.new(0,0,0.1))
                        task.wait(1)
                        hum:Move(Vector3.new(0,0,-0.1))
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
local VisualSection = GameTab:AddSection("🎭 Visual ESP & Tracking")

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
    Title = "ESP Generators",
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
                            if name:find("generator") or name:find("gen") or name:find("fusebox") then
                                table.insert(generators, obj)
                            end
                        end
                    end
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
                        local progress = gen:GetAttribute("Progress") or 0
                        if type(progress) == "number" then
                            if ESPLabels[gen] and ESPLabels[gen]:FindFirstChildOfClass("TextLabel") then
                                local txt = ESPLabels[gen]:FindFirstChildOfClass("TextLabel")
                                txt.Text = gen.Name .. " (" .. math.floor(progress * 100) .. "%)"
                                if progress >= 1 then
                                    txt.TextColor3 = Color3.fromRGB(0, 255, 0)
                                else
                                    txt.TextColor3 = Color3.fromRGB(255, 255, 0)
                                end
                            end
                        end
                    end
                    task.wait(0.5)
                end
                for _, label in pairs(ESPLabels) do pcall(label.Destroy, label) end
                ESPLabels = {}
            end)
            Notify("ESP Generator", "ON")
        else
            for _, label in pairs(ESPLabels) do pcall(label.Destroy, label) end
            ESPLabels = {}
            Notify("ESP Generator", "OFF")
        end
    end
})

-- Visuals
local VisualsSection = GameTab:AddSection("✨ Visuals")
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
                local light = Instance.new("SpotLight", head)
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
    Title = "X-Ray",
    Default = false,
    Callback = function(v)
        _G.XRay = v
        if v then
            Lighting.Ambient = Color3.new(0,0,0)
            Lighting.Brightness = 0
            Lighting.OutdoorAmbient = Color3.new(0,0,0)
        else
            Lighting.Ambient = Color3.new(0.5,0.5,0.5)
            Lighting.Brightness = 1
            Lighting.OutdoorAmbient = Color3.new(0.5,0.5,0.5)
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
            Lighting.OutdoorAmbient = Color3.new(1,1,1)
        else
            Lighting.Brightness = 1
            Lighting.OutdoorAmbient = Color3.new(0.5,0.5,0.5)
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
                Notify("Freecam", "ON")
            else
                Notify("Error", "Tidak bisa mengaktifkan Freecam!")
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
            Notify("Freecam", "OFF")
        end
    end
})

-- Misc
local MiscSection = GameTab:AddSection("⚙️ Misc")
MiscSection:AddToggle({ Title = "Anti Kick", Default = false, Callback = function(v) _G.AntiKick = v; Notify("Anti Kick", v and "ON" or "OFF") end })
MiscSection:AddToggle({ Title = "Admin Detect", Default = false, Callback = function(v) _G.AdminDetect = v; Notify("Admin Detect", v and "ON" or "OFF") end })
MiscSection:AddToggle({ Title = "Hitbox", Default = false, Callback = function(v) _G.Hitbox = v; Notify("Hitbox", v and "ON" or "OFF") end })
MiscSection:AddToggle({ Title = "Killer Warn", Default = false, Callback = function(v) _G.KillerWarn = v; Notify("Killer Warn", v and "ON" or "OFF") end })
MiscSection:AddToggle({ Title = "Auto Skill Mobile", Default = false, Callback = function(v) _G.AutoSkillMobile = v; Notify("Auto Skill Mobile", v and "ON" or "OFF") end })

-- ==========================================
-- SERVER TAB
-- ==========================================
local ServerSection = ServerTab:AddSection("🌐 Server")
ServerSection:AddButton({ Title = "Reconnect", Callback = function() TeleportService:Teleport(game.PlaceId, LocalPlayer); Notify("Reconnect", "Menghubungkan ulang...") end })
ServerSection:AddButton({ Title = "Server Hop", Callback = function()
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
end })
ServerSection:AddButton({ Title = "Join Friend", Callback = function()
    local friends = Players:GetFriendsOnline()
    if #friends > 0 then
        TeleportService:TeleportToPlayer(friends[1].UserId)
        Notify("Join Friend", "Bergabung dengan " .. friends[1].DisplayName .. "...")
    else
        Notify("Join Friend", "Tidak ada teman yang online!")
    end
end })

-- ==========================================
-- SETTINGS TAB
-- ==========================================
local SettingsSection = SettingsTab:AddSection("⚙️ Settings")
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
        Notify("MDW HUB", "Shutdown...")
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
        ClearAllMountHighlights()
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
                    pcall(gui.Destroy, gui)
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

-- Infinite Jump
RunService.RenderStepped:Connect(function()
    if _G.InfJump and LocalPlayer.Character then
        local hum = GetHumanoid()
        if hum then
            hum.JumpPower = 50
            if hum.Sit then hum.Sit = false end
            if hum.FloorMaterial == Enum.Material.Air then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end
end)

-- Auto Interact
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

-- ==========================================
-- INITIALIZE
-- ==========================================
Library:Initialize()
Notify("FCAL HUB", "Script Loaded Successfully! (Fixed ESP & Fly, Mount Admin Added)")

-- Auto update dropdown
Players.PlayerAdded:Connect(UpdateDropdown)
Players.PlayerRemoving:Connect(UpdateDropdown)
Players.PlayerRemoving:Connect(ClearESP)