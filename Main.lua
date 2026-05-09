local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local Window = Rayfield:CreateWindow({
   Name = "Driving Empire Elite FINAL",
   LoadingTitle = "Sistem Derleniyor...",
   LoadingSubtitle = "ATM Fix ve Performans Sürümü",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "DrivingEmpireFinal",
      FileName = "Config"
   }
})

-- Takım Kontrol Fonksiyonu
local function checkTeam(player, keyword)
    if player and player.Team then
        return string.find(string.lower(player.Team.Name), string.lower(keyword)) ~= nil
    end
    return false
end

-- Değişkenler
local autoFarmATM = false
local autoArrest = false
local currentTarget = nil
local arrestConnection = nil

-- ==========================================
-- OUTLAW (MAHKUM) SEKMESİ - YENİLENEN ATM SİSTEMİ
-- ==========================================
local OutlawTab = Window:CreateTab("Outlaw (Mahkum)", 4483362458) 

OutlawTab:CreateToggle({
   Name = "Auto ATM Farm (Gelişmiş Tarayıcı)",
   CurrentValue = false,
   Flag = "ATMFarm", 
   Callback = function(Value)
      autoFarmATM = Value
      if autoFarmATM then
         task.spawn(function()
            while autoFarmATM do
               task.wait(1.2) -- Anti-cheat için dengeli bir süre
               
               local char = LocalPlayer.Character
               if not char or not char.PrimaryPart then continue end

               local targetPrompt = nil
               local shortestDist = math.huge
               local myPos = char:GetPivot().Position

               -- ATM TESPİT ETME OPERASYONU (Daha Geniş Kapsamlı)
               for _, obj in ipairs(game.Workspace:GetDescendants()) do
                   if obj:IsA("ProximityPrompt") then
                       -- Kanka sadece isme değil, her şeye bakıyoruz:
                       local nameCheck = string.find(string.lower(obj.Name), "atm") or (obj.Parent and string.find(string.lower(obj.Parent.Name), "atm"))
                       local textCheck = string.find(string.lower(obj.ActionText), "bust") or string.find(string.lower(obj.ActionText), "rob") or string.find(string.lower(obj.ObjectText), "atm")
                       
                       -- Eğer bunlardan biri tutuyorsa ve o an soyulabilirse (Enabled ise)
                       if (nameCheck or textCheck) and obj.Enabled then
                           local atmPart = obj.Parent:IsA("BasePart") and obj.Parent or obj.Parent:FindFirstChildWhichIsA("BasePart")
                           
                           if atmPart then
                               local atmPos = atmPart.Position
                               -- Okyanus (0,0,0) koruması
                               if atmPos.Magnitude > 1000 then 
                                   local dist = (myPos - atmPos).Magnitude
                                   if dist < shortestDist then
                                       shortestDist = dist
                                       targetPrompt = obj
                                   end
                               end
                           end
                       end
                   end
               end

               if targetPrompt then
                   local atmPart = targetPrompt.Parent
                   -- ATM'nin tam dibine ama biraz havada ışınlan (Yerin dibine girmemek için)
                   char:PivotTo(atmPart:GetPivot() * CFrame.new(0, 1.5, 2))
                   
                   -- Işınlandıktan hemen sonra bekleme (Çok önemli kanka)
                   task.wait(0.3)
                   
                   -- Eğer hala Enabled ise etkileşime gir
                   if targetPrompt.Enabled then
                       fireproximityprompt(targetPrompt)
                       -- Soygun bitene kadar karakteri orada sabitle
                       task.wait(targetPrompt.HoldDuration + 0.5)
                   end
               else
                   -- Eğer bulamazsa ufak bir uyarı (Bunu silebilirsin çok kalabalık yaparsa)
                   print("ATM aranıyor... Biraz dolaş ki harita yüklensin kanka.")
               end
            end
         end)
      end
   end,
})

-- ==========================================
-- SECURITY (POLİS) SEKMESİ (Zaten Mükemmel Çalışan Kısım)
-- ==========================================
local SecurityTab = Window:CreateTab("Security (Polis)", 4483362458)

SecurityTab:CreateToggle({
   Name = "Auto Arrest (Kilitlenme)",
   CurrentValue = false,
   Flag = "AutoArrest",
   Callback = function(Value)
      if Value and not (checkTeam(LocalPlayer, "security") or checkTeam(LocalPlayer, "police")) then
          Rayfield:Notify({
              Title = "Erişim Reddedildi!",
              Content = "Aga bu özelliği açmak için Security veya Polis takımında olman lazım.",
              Duration = 4
          })
          autoArrest = false
          return
      end

      autoArrest = Value

      if not autoArrest then
          if arrestConnection then arrestConnection:Disconnect() end
          currentTarget = nil
          return
      end

      arrestConnection = RunService.Heartbeat:Connect(function()
          local char = LocalPlayer.Character
          if not char or not char.PrimaryPart then return end

          if not currentTarget or not currentTarget.Character or not currentTarget.Character.PrimaryPart or not (checkTeam(currentTarget, "outlaw") or checkTeam(currentTarget, "criminal")) then
              local closestDist = math.huge
              local newTarget = nil
              
              for _, p in ipairs(Players:GetPlayers()) do
                  if p ~= LocalPlayer and (checkTeam(p, "outlaw") or checkTeam(p, "criminal")) then
                      if p.Character and p.Character.PrimaryPart then
                          local tPos = p.Character:GetPivot().Position
                          if tPos.Magnitude > 1000 then 
                              local d = (char:GetPivot().Position - tPos).Magnitude
                              if d < closestDist then
                                  closestDist = d
                                  newTarget = p
                              end
                          end
                      end
                  end
              end
              currentTarget = newTarget
          end

          if currentTarget and currentTarget.Character and currentTarget.Character.PrimaryPart then
              char:PivotTo(currentTarget.Character:GetPivot() * CFrame.new(0, 0, 3))
              
              local prompt = currentTarget.Character:FindFirstChildWhichIsA("ProximityPrompt", true)
              if prompt then 
                  fireproximityprompt(prompt) 
              end
          end
      end)
   end,
})
