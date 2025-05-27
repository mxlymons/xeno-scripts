-- Rayfield UI'yi yükle
local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Rayfield/main/source.lua"))()

-- Hizmetler
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

-- Değişkenler
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local TargetFolder = Workspace:WaitForChild("Targets") -- Düşmanlar burada

local Aiming = false
local ESPEnabled = false
local MaxDistance = 100
local FOV = math.rad(60)
local Smoothness = 0.08
local AimKey = Enum.KeyCode.E -- Aimbot için tuş
local ESPBoxColor = Color3.fromRGB(255, 0, 0) -- ESP kutu rengi

-- GUI (Rayfield Menüsü)
local Window = Rayfield:CreateWindow({
    Name = "Aimbot & ESP",
    LoadingTitle = "Yükleniyor...",
    LoadingSubtitle = "Lütfen bekleyin",
    ConfigurationSaving = {Enabled = true, FolderName = "Rayfield", FileName = "config"},
    Discord = {Enabled = false, Invite = "", RememberJoins = true},
    KeySystem = false, KeySettings = {Title = "Key sistemi", Subtitle = "Rayfield Key", Note = "Key notu"},
})

-- Sekme ve seçenekler
local MainTab = Window:CreateTab("Main", 4483362458)
local aimbotSection = MainTab:CreateSection("Aimbot", "left")
local espSection = MainTab:CreateSection("ESP", "left")

-- Aimbot
local aimbotToggle = aimbotSection:CreateToggle({
    Name = "Aimbot Aç/Kapat",
    CurrentValue = false,
    Flag = "aimbotToggle",
    Callback = function(Value)
        Aiming = Value
    end,
})

-- ESP
local espToggle = espSection:CreateToggle({
    Name = "ESP Aç/Kapat",
    CurrentValue = false,
    Flag = "espToggle",
    Callback = function(Value)
        ESPEnabled = Value
    end,
})

-- Yardımcı Fonksiyonlar
local function isInFOV(targetPos)
    local dirToTarget = (targetPos - Camera.CFrame.Position).Unit
    local camLook = Camera.CFrame.LookVector
    local angle = math.acos(dirToTarget:Dot(camLook))
    return angle <= FOV
end

local function isVisible(part)
    local origin = Camera.CFrame.Position
    local direction = (part.Position - origin).Unit * MaxDistance

    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.IgnoreWater = true

    local result = workspace:Raycast(origin, direction, rayParams)

    return result and result.Instance:IsDescendantOf(part.Parent)
end

local function getClosestTarget()
    local closest = nil
    local shortestDist = MaxDistance

    for _, target in pairs(TargetFolder:GetChildren()) do
        local hrp = target:FindFirstChild("HumanoidRootPart")
        if hrp then
            local dist = (hrp.Position - Camera.CFrame.Position).Magnitude
            if dist < shortestDist and isInFOV(hrp.Position) and isVisible(hrp) then
                shortestDist = dist
                closest = hrp
            end
        end
    end

    return closest
end

-- ESP Gösterme
local function drawESP(target)
    if ESPEnabled then
        local hrp = target:FindFirstChild("HumanoidRootPart")
        if hrp then
            local screenPos, onScreen = Camera:WorldToScreenPoint(hrp.Position)
            if onScreen then
                local box = Instance.new("Frame")
                box.Size = UDim2.new(0, 50, 0, 50)
                box.Position = UDim2.new(0, screenPos.X - 25, 0, screenPos.Y - 25)
                box.BackgroundColor3 = ESPBoxColor
                box.BorderSizePixel = 0
                box.Parent = game.CoreGui
                game:GetService("Debris"):AddItem(box, 1) -- 1 saniye sonra silinir
            end
        end
    end
end

-- Aimbot döngüsü
RunService.RenderStepped:Connect(function()
    if Aiming then
        local target = getClosestTarget()
        if target then
            local from = Camera.CFrame.Position
            local to = target.Position
            local newCFrame = CFrame.new(from, to)
            Camera.CFrame = Camera.CFrame:Lerp(newCFrame, Smoothness)
        end
    end

    -- ESP'yi sürekli güncelle
    if ESPEnabled then
        for _, target in pairs(TargetFolder:GetChildren()) do
            drawESP(target)
        end
    end
end)

-- Tuş Tespiti (Aimbot için E tuşu)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == AimKey then
        Aiming = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == AimKey then
        Aiming = false
    end
end)
