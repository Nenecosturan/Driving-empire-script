local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local Window = Rayfield:CreateWindow({
   Name = "Driving Empire V-Optima",
   LoadingTitle = "Bypass ve Optimizasyon...",
   LoadingSubtitle = "StreamingEnabled Uyumlu",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "DrivingEmpireOptima",
      FileName = "Config"
   }
})

-- Değişkenler
local autoFarmATM = false
local autoArrest = false
local currentTarget = nil
local trackingConnection = nil -- Performanslı takip için
local maxMoney = 500000

-- Teslimat Noktası (Oyundaki gerçek koordinatla değiştir)
local dropOffLocation = CFrame.new(100, 20, -100)
-- Kaçış Noktası (Haritanın çok yukarısı)
local safeZone = CFrame.new(0, 5000, 0)

-- Yüklenmiş ve Soyulabilir ATM'leri Bulma (Performans Dostu Tarama)
local function getNearestActiveATM()
    local nearestATM = nil
    local shortestDist = math.huge
    local char = LocalPlayer.Character
    if not char or not char.PrimaryPart then return nil end

    local myPos = char:GetPivot().Position

    -- Sadece o an yüklenmiş olan nesneleri tarar
    for _, obj in ipairs(game.Workspace:GetDescendants()) do
        -- ProximityPrompt (E tuşu etkileşimi) arıyoruz
        if obj:IsA("ProximityPrompt") then
            -- Adında ATM geçenleri veya üst klasöründe ATM olanları bul
            if string.find(string.lower(obj.Name), "atm") or (obj.Parent and string.find(string.lower(obj.Parent.Name), "atm")) then
                -- Eğer etkileşim aktifse (yani daha yeni soyulmamışsa)
                if obj.Enabled then
                    local dist = (myPos - obj.Parent.Position).Magnitude
                    if dist < shortestDist then
                        shortestDist = dist
                        nearestATM = obj
                    end
                end
            end
        end
    end
    return nearestATM
end

local OutlawTab = Window:CreateTab("Outlaw (Mahkum)", 4483362458) 

OutlawTab:CreateToggle({
   Name = "Auto ATM Farm (Yaya & Güvenli)",
   CurrentValue = false,
   Flag = "ATMFarm", 
   Callback = function(Value)
      autoFarmATM = Value
      if autoFarmATM then
         task.spawn(function()
            while autoFarmATM do
               task.wait(0.5) -- Taramayı çok hızlı yapıp PC'yi yormamak için
               
               local char = LocalPlayer.Character
               if not char or not char.PrimaryPart then continue end

               -- 1. Polis Kontrolü (Güvenlik Önlemi)
               local policeNear = false
               for _, p in ipairs(Players:GetPlayers()) do
                   if p.Team and string.find(string.lower(p.Team.Name), "security") and p ~= LocalPlayer then
                       if p.Character and p.Character.PrimaryPart then
                           if (char:GetPivot().Position - p.Character:GetPivot().Position).Magnitude < 150 then
                               policeNear = true
                               break
                           end
                       end
                   end
               end

               if policeNear then
                   char:PivotTo(safeZone)
                   task.wait(2)
                   continue
               end

               -- 2. ATM Bulma ve Soyma
               local targetPrompt = getNearestActiveATM()
               
               if targetPrompt and targetPrompt.Parent then
                   -- ATM'nin önüne modern yöntemle ışınlan
                   char:PivotTo(targetPrompt.Parent.CFrame * CFrame.new(0, 0, 3))
                   
                   -- StreamingEnabled yüzünden haritanın o kısmının yüklenmesini bekle (ÇOK KRİTİK)
                   task.wait(0.3) 
                   
                   -- Soygun işlemini başlat
                   fireproximityprompt(targetPrompt)
                   
                   -- Soygun süresi kadar bekle ki kodu bozmasın
                   task.wait(targetPrompt.HoldDuration + 0.5)
               else
                   -- Etrafta yüklü ATM yoksa haritada rastgele bir noktaya ışınlanıp oranın yüklenmesini sağlayabilirsin
                   -- Şimdilik bekliyoruz
                   task.wait(1)
               end
            end
         end)
      end
   end,
})

local SecurityTab = Window:CreateTab("Security (Polis)", 4483362458)

SecurityTab:CreateToggle({
   Name = "Auto Arrest (Kusursuz Kilitlenme)",
   CurrentValue = false,
   Flag = "AutoArrest",
   Callback = function(Value)
      autoArrest = Value
      
      -- Eğer kapatıldıysa döngüyü temizle
      if not autoArrest then 
          if trackingConnection then
              trackingConnection:Disconnect()
              trackingConnection = nil
          end
          currentTarget = nil 
          return 
      end
      
      if autoArrest then
         -- Saniyede 60 kez (oyun motoruyla aynı hızda) çalışan kusursuz takip döngüsü
         trackingConnection = RunService.Heartbeat:Connect(function()
             local char = LocalPlayer.Character
             if not char or not char.PrimaryPart then return end

             -- Hedef yoksa veya öldüyse/tutuklandıysa yeni hedef bul
             if not currentTarget or not currentTarget.Character or not currentTarget.Character.PrimaryPart or currentTarget.Team.Name ~= "Outlaws" then
                 local closestDist = math.huge
                 local newTarget = nil
                 
                 for _, p in ipairs(Players:GetPlayers()) do
                     if p.Team and string.find(string.lower(p.Team.Name), "outlaw") and p ~= LocalPlayer then
                         if p.Character and p.Character.PrimaryPart then
                             local d = (char:GetPivot().Position - p.Character:GetPivot().Position).Magnitude
                             if d < closestDist then
                                 closestDist = d
                                 newTarget = p
                             end
                         end
                     end
                 end
                 currentTarget = newTarget
             end

             -- Hedef bulunduysa DİBİNE YAPIŞ
             if currentTarget and currentTarget.Character and currentTarget.Character.PrimaryPart then
                 -- PivotTo ile milimetrik takip (Hırsızın sırtına yapışır)
                 char:PivotTo(currentTarget.Character:GetPivot() * CFrame.new(0, 0, 2))
                 
                 -- Yaklaşınca E tuşunu (ProximityPrompt) otomatik tetikle
                 local prompt = currentTarget.Character:FindFirstChildWhichIsA("ProximityPrompt", true)
                 if prompt then
                     fireproximityprompt(prompt)
                 end
             end
         end)
      end
   end,
})
