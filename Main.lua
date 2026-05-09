local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local Window = Rayfield:CreateWindow({
   Name = "Driving Empire Mobile Elite",
   LoadingTitle = "Sistem Optimize Ediliyor...",
   LoadingSubtitle = "ATM Otomasyonu Aktif",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "DrivingEmpireMobileV3",
      FileName = "Config"
   }
})

-- Takım Kontrolü
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
-- OUTLAW (MAHKUM) SEKMESİ - FULL AUTO ATM
-- ==========================================
local OutlawTab = Window:CreateTab("Outlaw (Mahkum)", 4483362458) 

OutlawTab:CreateToggle({
   Name = "Auto ATM Farm (Full Auto)",
   CurrentValue = false,
   Flag = "ATMFarm", 
   Callback = function(Value)
      autoFarmATM = Value
      if autoFarmATM then
         task.spawn(function()
            while autoFarmATM do
               task.wait(1) 
               
               local char = LocalPlayer.Character
               local root = char and char:FindFirstChild("HumanoidRootPart")
               if not root then continue end

               local targetPrompt = nil
               local targetPart = nil
               local shortestDist = math.huge

               -- Çevredeki ATM'leri ve Bust yazılarını tara
               for _, obj in ipairs(game.Workspace:GetDescendants()) do
                   if obj:IsA("ProximityPrompt") and obj.Enabled then
                       local txt = string.lower(obj.ActionText) .. string.lower(obj.ObjectText) .. string.lower(obj.Name)
                       if string.find(txt, "bust") or string.find(txt, "atm") or string.find(txt, "rob") then
                           local part = obj:FindFirstAncestorWhichIsA("BasePart")
                           if part then
                               local dist = (root.Position - part.Position).Magnitude
                               if dist < shortestDist and part.Position.Magnitude > 500 then
                                   shortestDist = dist
                                   targetPrompt = obj
                                   targetPart = part
                               end
                           end
                       end
                   end
               end

               -- Işınlanma ve Otomatik Basma
               if targetPrompt and targetPart then
                   -- ATM'nin tam önüne ve doğru açıyla ışınlan
                   root.CFrame = targetPart.CFrame * CFrame.new(0, 0, 2.2)
                   task.wait(0.3) -- Karakterin yerleşmesi için bekle
                   
                   -- Gelişmiş Etkileşim (Mobil Executor Uyumluluğu)
                   if targetPrompt.Enabled then
                       -- 1. Yöntem: Standart Tetikleme
                       fireproximityprompt(targetPrompt)
                       
                       -- 2. Yöntem (Yedek): Eğer HoldDuration varsa manuel basılı tutma simülasyonu
                       if targetPrompt.HoldDuration > 0 then
                           task.wait(targetPrompt.HoldDuration + 0.2)
                       end
                   end
               end
            end
         end)
      end
   end,
})

-- ==========================================
-- SECURITY (POLİS) SEKMESİ (Mükemmel Çalışan Kısım)
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
