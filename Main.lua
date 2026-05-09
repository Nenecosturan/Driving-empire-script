local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Window = Rayfield:CreateWindow({
   Name = "Driving Empire Pro",
   LoadingTitle = "Mekanikler Taranıyor...",
   LoadingSubtitle = "Araç Fiziği Sürümü",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "DrivingEmpire",
      FileName = "Config"
   }
})

-- Arabayı bulma fonksiyonu (Kritik nokta: Sadece yaya değil, araba ışınlanmalı)
local function getVehicle()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") and char.Humanoid.SeatPart then
        return char.Humanoid.SeatPart.Parent -- Karakterin oturduğu araba modelini çeker
    end
    return nil
end

-- Haritadaki gizli ATM'leri otomatik tarayan fonksiyon
local function getATMs()
    local atmList = {}
    -- Bütün Workspace'i tarayıp model adında ATM veya Vault geçenleri bulur
    for _, obj in ipairs(game.Workspace:GetDescendants()) do
        if obj:IsA("Model") and (string.find(string.lower(obj.Name), "atm") or string.find(string.lower(obj.Name), "vault")) then
            table.insert(atmList, obj)
        end
    end
    return atmList
end

local autoFarmATM = false
local autoArrest = false

local OutlawTab = Window:CreateTab("Outlaw (Mahkum)", 4483362458) 

OutlawTab:CreateToggle({
   Name = "Auto ATM Farm (Arabada Olmalısın)",
   CurrentValue = false,
   Flag = "ATMFarm", 
   Callback = function(Value)
      autoFarmATM = Value
      if autoFarmATM then
         task.spawn(function()
            local atms = getATMs() -- Script çalışınca ATM'leri hafızaya alır
            
            while autoFarmATM do
               task.wait(1)
               
               local vehicle = getVehicle()
               if not vehicle then
                   -- Eğer arabada değilsen script çalışmaz, bekler
                   task.wait(2)
                   continue
               end

               -- 1. Polis Yaklaşma Kontrolü
               local policeNear = false
               for _, player in ipairs(Players:GetPlayers()) do
                   -- Takım adından veya meslekten polisi algıla
                   if player.Team and player.Team.Name == "Security" and player ~= LocalPlayer then
                       if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                           local myPos = vehicle:GetPivot().Position
                           local dist = (myPos - player.Character.HumanoidRootPart.Position).Magnitude
                           if dist < 250 then -- 250 birim güvenli mesafe
                               policeNear = true
                               break
                           end
                       end
                   end
               end

               -- 2. Kaçış veya Işınlanma
               if policeNear then
                   -- Gökyüzüne, ulaşılamayacak bir yere arabayı ışınla
                   vehicle:PivotTo(CFrame.new(0, 5000, 0))
                   task.wait(3)
               else
                   if #atms > 0 then
                       -- Rastgele bir ATM seç
                       local targetATM = atms[math.random(1, #atms)]
                       if targetATM and targetATM.PrimaryPart then
                           -- Arabayı ATM'nin hemen yanına ışınla
                           vehicle:PivotTo(targetATM.PrimaryPart.CFrame * CFrame.new(0, 0, 15))
                           -- Oyunun kendi sayacının dolması veya paranın hesaba geçmesi için süre tanı
                           task.wait(6) 
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
   Name = "Auto Arrest (Kırmızı Çember Bekler)",
   CurrentValue = false,
   Flag = "AutoArrest",
   Callback = function(Value)
      autoArrest = Value
      if autoArrest then
         task.spawn(function()
            while autoArrest do
               task.wait(0.5)
               local myVehicle = getVehicle()
               
               -- Polisin de arabada olması şart
               if not myVehicle then continue end

               local closestTarget = nil
               local shortestDistance = math.huge
               local myPos = myVehicle:GetPivot().Position

               -- En yakın hırsızın ARABASINI bulma
               for _, target in ipairs(Players:GetPlayers()) do
                   if target.Team and target.Team.Name == "Outlaws" and target ~= LocalPlayer then
                       local targetChar = target.Character
                       if targetChar and targetChar:FindFirstChild("Humanoid") and targetChar.Humanoid.SeatPart then
                           local targetVeh = targetChar.Humanoid.SeatPart.Parent
                           if targetVeh then
                               local dist = (myPos - targetVeh:GetPivot().Position).Magnitude
                               if dist < shortestDistance then
                                   shortestDistance = dist
                                   closestTarget = targetVeh
                               end
                           end
                       end
                   end
               end

               -- Hedef arabaya yapış ve çember dolana kadar orada kal
               if closestTarget then
                   -- Arabanın hemen arkasına ışınlan (Kırmızı çember mesafesi)
                   myVehicle:PivotTo(closestTarget:GetPivot() * CFrame.new(0, 0, -12))
               end
            end
         end)
      end
   end,
})
