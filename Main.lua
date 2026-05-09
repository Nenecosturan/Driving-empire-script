local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Window = Rayfield:CreateWindow({
   Name = "Driving Empire Special Hub",
   LoadingTitle = "Sistem Yükleniyor...",
   LoadingSubtitle = "Sorunsuz Sürüm",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "DrivingEmpireScript",
      FileName = "Config"
   }
})

-- Değişkenler
local autoFarmATM = false
local autoArrest = false
local maxMoney = 500000

-- Güvenli Bölge (Polis gelince buraya kaçacak - Harita dışı veya yüksek bir yer)
local safeZoneCFrame = CFrame.new(0, 1000, 0) 
-- Para bırakma noktası (Oyun içindeki gerçek lokasyona göre değiştirilecek)
local dropOffCFrame = CFrame.new(500, 50, -500) 

local OutlawTab = Window:CreateTab("Outlaw (Mahkum)", 4483362458) 

OutlawTab:CreateToggle({
   Name = "Auto ATM Farm",
   CurrentValue = false,
   Flag = "ATMFarm", 
   Callback = function(Value)
      autoFarmATM = Value
      if autoFarmATM then
         task.spawn(function()
            while autoFarmATM do
               task.wait(0.2)
               
               -- Liderlik tablosundan anlık parayı çekme (Oyundaki isim "Cash" veya "Money" olabilir)
               local currentMoney = 0
               if LocalPlayer:FindFirstChild("leaderstats") and LocalPlayer.leaderstats:FindFirstChild("Cash") then
                   currentMoney = LocalPlayer.leaderstats.Cash.Value
               end

               -- 1. Para 500.000'e ulaştıysa teslimata git
               if currentMoney >= maxMoney then
                   if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                       LocalPlayer.Character.HumanoidRootPart.CFrame = dropOffCFrame
                       task.wait(3) -- Parayı bırakması için zaman tanı
                   end
               else
                   -- 2. Polis Kontrolü
                   local policeNear = false
                   for _, player in ipairs(Players:GetPlayers()) do
                       -- Polis takımı rengi (Oyun içindeki tam renge göre ayarlanmalı)
                       if player.TeamColor == BrickColor.new("Bright blue") and player ~= LocalPlayer then
                           if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                               local dist = (LocalPlayer.Character.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude
                               if dist < 150 then
                                   policeNear = true
                                   break
                               end
                           end
                       end
                   end

                   -- 3. Kaçış veya Soygun
                   if policeNear then
                       LocalPlayer.Character.HumanoidRootPart.CFrame = safeZoneCFrame
                       task.wait(2) -- Güvenli bölgede bekle
                   else
                       -- Workspace'teki ATM'leri bulma
                       local atmsFolder = game.Workspace:FindFirstChild("ATMs") -- Oyunun klasör ismine göre düzelt
                       if atmsFolder then
                           for _, atm in ipairs(atmsFolder:GetChildren()) do
                               -- ATM sağlam mı kontrolü
                               if atm:FindFirstChild("Broken") and atm.Broken.Value == false then
                                   LocalPlayer.Character.HumanoidRootPart.CFrame = atm.PrimaryPart.CFrame
                                   task.wait(0.5)
                                   
                                   -- ProximityPrompt (E tuşu) etkileşimi
                                   local prompt = atm:FindFirstChildWhichIsA("ProximityPrompt", true)
                                   if prompt then
                                       fireproximityprompt(prompt)
                                       task.wait(prompt.HoldDuration + 0.1) -- Soyulma süresi kadar bekle
                                   end
                                   break -- Sadece bir ATM'de işlem yapıp döngüyü başa sar
                               end
                           end
                       end
                   end
               end
            end
         end)
      end
   end,
})

local SecurityTab = Window:CreateTab("Security (Polis)", 4483362458)

SecurityTab:CreateToggle({
   Name = "Auto Arrest",
   CurrentValue = false,
   Flag = "AutoArrest",
   Callback = function(Value)
      autoArrest = Value
      if autoArrest then
         task.spawn(function()
            while autoArrest do
               task.wait(0.1)
               
               local closestTarget = nil
               local shortestDistance = math.huge
               local myPos = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.Position

               if myPos then
                   -- En yakın hırsızı bulma mantığı
                   for _, target in ipairs(Players:GetPlayers()) do
                       if target.TeamColor == BrickColor.new("Bright red") and target ~= LocalPlayer then
                           if target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                               local dist = (myPos - target.Character.HumanoidRootPart.Position).Magnitude
                               if dist < shortestDistance then
                                   shortestDistance = dist
                                   closestTarget = target
                               end
                           end
                       end
                   end

                   -- Bulunan en yakın hedefe ışınlan
                   if closestTarget then
                       LocalPlayer.Character.HumanoidRootPart.CFrame = closestTarget.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
                       -- Arrest etkileşimi (Eğer polis oyunda "E" ile tutukluyorsa buraya fireproximityprompt eklenebilir)
                   end
               end
            end
         end)
      end
   end,
})
