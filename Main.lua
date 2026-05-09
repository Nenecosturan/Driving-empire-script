local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Window = Rayfield:CreateWindow({
   Name = "Driving Empire Ultra Hub",
   LoadingTitle = "Sistem Hazırlanıyor, Bekle Aga...",
   LoadingSubtitle = "Karakter ve Takip Odaklı",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "DrivingEmpireUltra",
      FileName = "Config"
   }
})

-- Değişkenler ve Kontrol Mekanizmaları
local autoFarmATM = false
local autoArrest = false
local currentTarget = nil -- Polisin kilitlendiği hırsız
local depositAmount = 500000 -- 500k limiti

-- ATM'leri ve Teslim Noktasını Tanımla (Oyunun Workspace yapısına göre gerekirse isimleri güncelle)
local function getATMs()
    local foundAtms = {}
    for _, obj in ipairs(game.Workspace:GetDescendants()) do
        if obj:IsA("Model") and string.find(string.lower(obj.Name), "atm") then
            table.insert(foundAtms, obj)
        end
    end
    return foundAtms
end

-- Mahkum (Outlaw) Sekmesi
local OutlawTab = Window:CreateTab("Outlaw (Mahkum)", 4483362458) 

OutlawTab:CreateToggle({
   Name = "Auto ATM Farm (Yaya)",
   CurrentValue = false,
   Flag = "ATMFarm", 
   Callback = function(Value)
      autoFarmATM = Value
      if autoFarmATM then
         task.spawn(function()
            while autoFarmATM do
               task.wait(0.1)
               local char = LocalPlayer.Character
               local root = char and char:FindFirstChild("HumanoidRootPart")
               if not root then continue end

               -- 1. Para Kontrolü (Leaderstats'tan Cash değerini okur)
               local cash = 0
               if LocalPlayer:FindFirstChild("leaderstats") and LocalPlayer.leaderstats:FindFirstChild("Cash") then
                   cash = LocalPlayer.leaderstats.Cash.Value
               end

               if cash >= depositAmount then
                   -- Para bırakma koordinatı (Örnek: 120, 10, -350 - Burayı oyunun gerçek teslim noktasına göre ayarla)
                   root.CFrame = CFrame.new(120, 10, -350)
                   task.wait(2)
               else
                   -- 2. Polis Kontrolü (Kaçış Mekanizması)
                   local isPoliceNear = false
                   for _, p in ipairs(Players:GetPlayers()) do
                       if p.Team and string.find(string.lower(p.Team.Name), "security") and p ~= LocalPlayer then
                           if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                               if (root.Position - p.Character.HumanoidRootPart.Position).Magnitude < 180 then
                                   isPoliceNear = true
                                   break
                               end
                           end
                       end
                   end

                   if isPoliceNear then
                       -- Havaya veya güvenli bölgeye ışınlan
                       root.CFrame = root.CFrame * CFrame.new(0, 1000, 0)
                       task.wait(3)
                   else
                       -- 3. ATM Soyma
                       local atms = getATMs()
                       for _, atm in ipairs(atms) do
                           -- Eğer ATM kırılmamışsa (Broken kontrolü oyuna göre değişebilir)
                           if atm:FindFirstChild("PrimaryPart") then
                               root.CFrame = atm.PrimaryPart.CFrame * CFrame.new(0, 0, 3)
                               task.wait(0.5)
                               
                               -- ProximityPrompt (E Tuşu) Tetikleme
                               local prompt = atm:FindFirstChildWhichIsA("ProximityPrompt", true)
                               if prompt then
                                   fireproximityprompt(prompt)
                                   task.wait(prompt.HoldDuration + 0.2)
                               end
                               break
                           end
                       end
                   end
               end
            end
         end)
      end
   end,
})

-- Polis (Security) Sekmesi
local SecurityTab = Window:CreateTab("Security (Polis)", 4483362458)

SecurityTab:CreateToggle({
   Name = "Auto Arrest (Kilitlenme Sistemi)",
   CurrentValue = false,
   Flag = "AutoArrest",
   Callback = function(Value)
      autoArrest = Value
      if not autoArrest then currentTarget = nil end
      
      if autoArrest then
         task.spawn(function()
            while autoArrest do
               task.wait(0.01) -- Çok hızlı tepki için düşük bekleme
               
               local char = LocalPlayer.Character
               local root = char and char:FindFirstChild("HumanoidRootPart")
               if not root then continue end

               -- Eğer şu an bir hedefimiz yoksa veya hedef oyundan çıktıysa/takım değiştirdiyse yeni hedef bul
               if not currentTarget or not currentTarget.Character or not currentTarget.Character:FindFirstChild("HumanoidRootPart") or currentTarget.Team.Name ~= "Outlaws" then
                   local closestDist = math.huge
                   for _, p in ipairs(Players:GetPlayers()) do
                       if p.Team and string.find(string.lower(p.Team.Name), "outlaw") and p ~= LocalPlayer then
                           if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                               local d = (root.Position - p.Character.HumanoidRootPart.Position).Magnitude
                               if d < closestDist then
                                   closestDist = d
                                   currentTarget = p
                               end
                           end
                       end
                   end
               end

               -- Hedef kilitlendiyse dibinden ayrılma (Loop Go-To)
               if currentTarget and currentTarget.Character and currentTarget.Character:FindFirstChild("HumanoidRootPart") then
                   -- Karakterin tam arkasına/dibine yapışır
                   root.CFrame = currentTarget.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 2)
                   
                   -- Eğer oyunda tutuklamak için 'E' gerekiyorsa otomatik tetikle
                   local tPrompt = currentTarget.Character:FindFirstChildWhichIsA("ProximityPrompt", true)
                   if tPrompt then
                       fireproximityprompt(tPrompt)
                   end
               end
            end
         end)
      end
   end,
})
