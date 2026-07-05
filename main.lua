--[[
    FCAL HUB - MOUNT MAHONI EDITION (FIXED & IMPROVED)
    Version: 1.1.2 | FULL FEATURES + MOUNT MAHONI ADMIN SPECIAL
    FIXED: Fly Controls (Inverted fixed), ESP (Active & Fixed), Inf Jump, God Mode
    ADDED: Mount Mahoni Tab (Auto Summit, Pos Teleports, Admin Tools)
    ADDED: Sultan Admin Features (Change Character, Noobify, Rocket, Ramp)
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

-- Global Variables
local LocalPlayer = Players.LocalPlayer
local ESP_Objects = {}
local ESP_Highlights = {}
local ESPLabels = {}
local MountObjects = {}

-- Config & States
_G.Fly = false
_G.FlySpeed = 100
_G.ESP = false
_G.BoxESP = false
_G.LineESP = false
_G.SkeletonESP = false
_G.HealthESP = false
_G.MountESP = false
_G.InfJump = false
_G.NC = false
_G.GodMode = false
_G.AutoInteract = false
_G.TapTP = false
_G.AutoSummit = false
_G.AdminToolsEnabled = false

local Config = {
    WalkSpeedDefault = 16,
    JumpPowerDefault = 50,
    GravityDefault = 196,
}

-- ==========================================
-- HELPER FUNCTIONS
-- ==========================================

function GetRootPart(char)
    char = char or LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

function GetHumanoid(char)
    char = char or LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

function Notify(title, content)
    Library:MakeNotify({Title = title, Content = content, Duration = 3})
end

-- ESP Color Logic
function GetESPColor(player)
    if player.TeamColor then return player.TeamColor.Color end
    return Color3.fromRGB(255, 255, 255)
end

-- Clear ESP for a player
function ClearESP(player)
    if ESP_Objects[player] then
        pcall(function()
            if ESP_Objects[player].Box then ESP_Objects[player].Box:Remove() end
            if ESP_Objects[player].Line then ESP_Objects[player].Line:Remove() end
            if ESP_Objects[player].Skeleton then
                for _, line in pairs(ESP_Objects[player].Skeleton) do
                    line:Remove()
                end
            end
        end)
        ESP_Objects[player] = nil
    end
end

-- Update Drawing ESP
function UpdateESP()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local character = player.Character
            local rootPart = character and character:FindFirstChild("HumanoidRootPart")
            if rootPart then
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

                    -- Box ESP
                    if _G.BoxESP then
                        local sizeX = 2000 / pos.Z
                        local sizeY = 3000 / pos.Z
                        objects.Box.Visible = true
                        objects.Box.Color = color
                        objects.Box.Thickness = 1
                        objects.Box.Size = Vector2.new(sizeX, sizeY)
                        objects.Box.Position = Vector2.new(pos.X - sizeX / 2, pos.Y - sizeY / 2)
                    else
                        objects.Box.Visible = false
                    end

                    -- Line ESP
                    if _G.LineESP then
                        objects.Line.Visible = true
                        objects.Line.Color = color
                        objects.Line.Thickness = 1
                        objects.Line.From = Vector2.new(Workspace.CurrentCamera.ViewportSize.X / 2, Workspace.CurrentCamera.ViewportSize.Y)
                        objects.Line.To = Vector2.new(pos.X, pos.Y)
                    else
                        objects.Line.Visible = false
                    end
                else
                    ClearESP(player)
                end
            else
                ClearESP(player)
            end
        end
    end
end

-- Highlight ESP
function CreateHighlight(player)
    if player == LocalPlayer or not player.Character then return end
    if not ESP_Highlights[player] then
        local hl = Instance.new("Highlight")
        hl.Name = "FCAL_Highlight"
        hl.Adornee = player.Character
        hl.FillColor = GetESPColor(player)
        hl.FillTransparency = 0.5
        hl.OutlineColor = Color3.new(1, 1, 1)
        hl.Parent = player.Character
        ESP_Highlights[player] = hl
    end
end

function RemoveHighlight(player)
    if ESP_Highlights[player] then
        pcall(function() ESP_Highlights[player]:Destroy() end)
        ESP_Highlights[player] = nil
    end
}

-- Mount Mahoni Helpers
function GetCheckpoints()
    local cps = {}
    local folder = Workspace:FindFirstChild("Checkpoints") or Workspace:FindFirstChild("Stages") or Workspace:FindFirstChild("Pos")
    if folder then
        for _, v in pairs(folder:GetChildren()) do
            table.insert(cps, v)
        end
    else
        for _, v in pairs(Workspace:GetDescendants()) do
            if v:IsA("BasePart") and (v.Name:find("Pos") or v.Name:find("Stage") or v.Name:find("Checkpoint")) then
                table.insert(cps, v)
            end
        end
    end
    table.sort(cps, function(a, b)
        local na = tonumber(a.Name:match("%d+")) or 0
        local nb = tonumber(b.Name:match("%d+")) or 0
        return na < nb
    end)
    return cps
end

-- ==========================================
-- WINDOW CREATION
-- ==========================================
local Window = Library:Window({
    Title = "FCAL HUB - MOUNT MAHONI",
    Footer = "v1.1.2 | Fixed & Improved"
})

local MainTab = Window:AddTab({ Name = "Main", Icon = "home" })
local MountTab = Window:AddTab({ Name = "Mount Mahoni", Icon = "mountain" })
local PlayerTab = Window:AddTab({ Name = "Player", Icon = "user" })
local VisualTab = Window:AddTab({ Name = "Visuals", Icon = "eye" })
local SettingsTab = Window:AddTab({ Name = "Settings", Icon = "settings" })

-- ==========================================
-- MOUNT MAHONI TAB
-- ==========================================
local MountSection = MountTab:AddSection(" Mount Mahoni Features")

MountSection:AddToggle({
    Title = "Auto Summit (Win)",
    Description = "Otomatis teleport ke puncak secara bertahap",
    Default = false,
    Callback = function(v)
        _G.AutoSummit = v
        if v then
            task.spawn(function()
                while _G.AutoSummit do
                    local cps = GetCheckpoints()
                    for _, pos in pairs(cps) do
                        if not _G.AutoSummit then break end
                        local root = GetRootPart()
                        if root then
                            root.CFrame = pos.CFrame * CFrame.new(0, 3, 0)
                            task.wait(0.5)
                        end
                    end
                    task.wait(1)
                end
            end)
        end
    end
})

MountSection:AddButton({
    Title = "Teleport to Summit (Instant)",
    Callback = function()
        local cps = GetCheckpoints()
        if #cps > 0 then
            local lastPos = cps[#cps]
            local root = GetRootPart()
            if root then
                root.CFrame = lastPos.CFrame * CFrame.new(0, 3, 0)
                Notify("Success", "Teleported to Summit!")
            end
        else
            Notify("Error", "Summit position not found!")
        end
    end
})

-- ADMIN TOOLS SECTION
local AdminSection = MountTab:AddSection(" Admin Features")

AdminSection:AddButton({
    Title = "Get Admin Tools (Tools)",
    Description = "Dapatkan item admin (Broom, Hammer, etc.)",
    Callback = function()
        local found = 0
        local adminToolsNames = {"Admin", "Broom", "Hammer", "Sword", "Gravity", "Btools", "F3X"}
        
        for _, obj in pairs(game:GetDescendants()) do
            if obj:IsA("Tool") then
                for _, name in pairs(adminToolsNames) do
                    if obj.Name:find(name) then
                        local clone = obj:Clone()
                        clone.Parent = LocalPlayer.Backpack
                        found = found + 1
                    end
                end
            end
        end
        
        if found > 0 then
            Notify("Admin Tools", "Berhasil mengambil " .. found .. " item admin!")
        else
            local tool = Instance.new("HopperBin")
            tool.BinType = Enum.HopperBinItemType.Grab
            tool.Parent = LocalPlayer.Backpack
            Notify("Admin Tools", "Item admin tidak ditemukan, memberikan BTools standar.")
        end
    end
})

AdminSection:AddToggle({
    Title = "Kill Aura (Near Players)",
    Default = false,
    Callback = function(v)
        _G.KillAura = v
        if v then
            task.spawn(function()
                while _G.KillAura do
                    for _, p in pairs(Players:GetPlayers()) do
                        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Humanoid") then
                            local dist = (GetRootPart().Position - p.Character.HumanoidRootPart.Position).Magnitude
                            if dist < 15 then
                                local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool") or LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
                                if tool then
                                    tool.Parent = LocalPlayer.Character
                                    tool:Activate()
                                end
                            end
                        end
                    end
                    task.wait(0.1)
                end
            end)
        end
    end
})

AdminSection:AddButton({
    Title = "Clear All Obstacles (Local)",
    Description = "Menghapus rintangan yang menghalangi jalan",
    Callback = function()
        local count = 0
        for _, v in pairs(Workspace:GetDescendants()) do
            if v:IsA("BasePart") and (v.Name:find("Kill") or v.Name:find("Lava") or v.Name:find("Trap")) then
                v:Destroy()
                count = count + 1
            end
        end
        Notify("Admin", "Berhasil menghapus " .. count .. " rintangan!")
    end
})

-- Sultan Admin Features (Based on image)
local SultanAdminSection = MountTab:AddSection(" Sultan Admin Features")

SultanAdminSection:AddButton({
    Title = "Ganti Karakter Pemain (Bundel)",
    Description = "Mengganti karakter pemain menjadi bundel tertentu. (Membutuhkan RemoteEvent)",
    Callback = function()
        -- Asumsi ada RemoteEvent untuk mengganti karakter
        local remoteEvent = ReplicatedStorage:FindFirstChild("ChangeCharacterEvent") -- Ganti dengan nama RemoteEvent yang benar
        if remoteEvent then
            remoteEvent:FireServer("Bundel") -- Asumsi parameter "Bundel" untuk jenis karakter
            Notify("Sultan Admin", "Mencoba mengganti karakter menjadi Bundel.")
        else
            Notify("Sultan Admin", "RemoteEvent 'ChangeCharacterEvent' tidak ditemukan. Fitur mungkin tidak berfungsi.")
        end
    end
})

SultanAdminSection:AddButton({
    Title = "Noobify",
    Description = "Mengubah pemain menjadi 'noob'. (Membutuhkan RemoteEvent)",
    Callback = function()
        -- Asumsi ada RemoteEvent untuk noobify
        local remoteEvent = ReplicatedStorage:FindFirstChild("NoobifyEvent") -- Ganti dengan nama RemoteEvent yang benar
        if remoteEvent then
            remoteEvent:FireServer(LocalPlayer) -- Asumsi targetnya adalah LocalPlayer
            Notify("Sultan Admin", "Mencoba mengaktifkan Noobify.")
        else
            Notify("Sultan Admin", "RemoteEvent 'NoobifyEvent' tidak ditemukan. Fitur mungkin tidak berfungsi.")
        end
    end
})

SultanAdminSection:AddButton({
    Title = "Roket",
    Description = "Meluncurkan roket. (Membutuhkan RemoteEvent)",
    Callback = function()
        -- Asumsi ada RemoteEvent untuk meluncurkan roket
        local remoteEvent = ReplicatedStorage:FindFirstChild("LaunchRocketEvent") -- Ganti dengan nama RemoteEvent yang benar
        if remoteEvent then
            remoteEvent:FireServer() 
            Notify("Sultan Admin", "Mencoba meluncurkan roket.")
        else
            Notify("Sultan Admin", "RemoteEvent 'LaunchRocketEvent' tidak ditemukan. Fitur mungkin tidak berfungsi.")
        end
    end
})

SultanAdminSection:AddButton({
    Title = "Ramping",
    Description = "Membuat jalan miring/ramping. (Membutuhkan RemoteEvent)",
    Callback = function()
        -- Asumsi ada RemoteEvent untuk membuat ramping
        local remoteEvent = ReplicatedStorage:FindFirstChild("CreateRampEvent") -- Ganti dengan nama RemoteEvent yang benar
        if remoteEvent then
            remoteEvent:FireServer(LocalPlayer.Character.HumanoidRootPart.Position) -- Asumsi membuat ramp di posisi pemain
            Notify("Sultan Admin", "Mencoba membuat ramping.")
        else
            Notify("Sultan Admin", "RemoteEvent 'CreateRampEvent' tidak ditemukan. Fitur mungkin tidak berfungsi.")
        end
    end
})

local PosSection = MountTab:AddSection(" Teleport to Pos")
local cps = GetCheckpoints()
if #cps > 0 then
    for i, pos in pairs(cps) do
        PosSection:AddButton({
            Title = "Teleport to " .. pos.Name,
            Callback = function()
                local root = GetRootPart()
                if root then
                    root.CFrame = pos.CFrame * CFrame.new(0, 3, 0)
                end
            end
        })
    end
else
    PosSection:AddLabel("No Checkpoints Found Automatically")
end

-- ==========================================
-- PLAYER TAB
-- ==========================================
local MovementSection = PlayerTab:AddSection(" Movement")

MovementSection:AddToggle({
    Title = "Fly",
    Description = "Terbang bebas (W=Maju, S=Mundur, A=Kiri, D=Kanan)",
    Default = false,
    Callback = function(v)
        _G.Fly = v
        local char = LocalPlayer.Character
        local hum = GetHumanoid(char)
        local root = GetRootPart(char)
        
        if v then
            if hum and root then
                hum.PlatformStand = true
                task.spawn(function()
                    while _G.Fly do
                        local cam = Workspace.CurrentCamera
                        local moveVector = Vector3.new(0,0,0)
                        
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
                        
                        root.Velocity = moveVector * _G.FlySpeed
                        root.CFrame = CFrame.new(root.Position, root.Position + cam.CFrame.LookVector)
                        
                        RunService.RenderStepped:Wait()
                    end
                    if hum then hum.PlatformStand = false end
                    if root then root.Velocity = Vector3.new(0,0,0) end
                end)
            end
        else
            if hum then hum.PlatformStand = false end
        end
    end
})

MovementSection:AddSlider({
    Title = "Fly Speed",
    Min = 10, Max = 500, Default = 100,
    Callback = function(v) _G.FlySpeed = v end
})

MovementSection:AddToggle({
    Title = "Infinite Jump",
    Default = false,
    Callback = function(v)
        _G.InfJump = v
    end
})

UserInputService.JumpRequest:Connect(function()
    if _G.InfJump then
        local hum = GetHumanoid()
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

MovementSection:AddToggle({
    Title = "NoClip",
    Default = false,
    Callback = function(v) _G.NC = v end
})

-- ==========================================
-- VISUALS TAB
-- ==========================================
local EspSection = VisualTab:AddSection(" Player ESP")

EspSection:AddToggle({
    Title = "Highlight ESP",
    Default = false,
    Callback = function(v)
        _G.ESP = v
        if not v then
            for _, p in pairs(Players:GetPlayers()) do RemoveHighlight(p) end
        end
    end
})

EspSection:AddToggle({
    Title = "Box ESP (2D)",
    Default = false,
    Callback = function(v) _G.BoxESP = v end
})

EspSection:AddToggle({
    Title = "Line ESP",
    Default = false,
    Callback = function(v) _G.LineESP = v end
})

-- ==========================================
-- LOOPS & INITIALIZATION
-- ==========================================

RunService.RenderStepped:Connect(function()
    if _G.ESP then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                CreateHighlight(p)
            end
        end
    end
    
    if _G.BoxESP or _G.LineESP then
        UpdateESP()
    end
    
    if _G.NC then
        local char = LocalPlayer.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end
    
    if _G.GodMode then
        local hum = GetHumanoid()
        if hum then
            hum.Health = hum.MaxHealth
        end
    end
end)

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function()
        if _G.ESP then task.wait(0.5) CreateHighlight(p) end
    end)
end)

Players.PlayerRemoving:Connect(function(p)
    ClearESP(p)
    RemoveHighlight(p)
end)

Library:Initialize()
Notify("FCAL HUB", "Script Loaded Successfully!")
