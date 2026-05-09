local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local Window = Rayfield:CreateWindow({
   Name = "Driving Empire Elite V4",
   LoadingTitle = "ATM Üstü Operasyon...",
   LoadingSubtitle = "Hatasız Etkileşim Aktif",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "DrivingEmpireV4",
      FileName = "Config"
   }
})

local function checkTeam(player, keyword)
    if player and player.Team then
        return string.find(string.lower(player.Team.Name), string.lower(keyword)) ~= nil
    end
    return false
end

local function isPoliceNear(targetPosition, safeRadius)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and (checkTeam(p, "security") or checkTeam(p, "police")) then
            if p.Character and p.Character.PrimaryPart then
                local dist = (p.Character:GetPivot().Position - targetPosition).Magnitude
                if dist < safeRadius then return true end
            end
        end
    end
    return false
end

local autoFarmATM = false
local autoArrest = false
local currentTarget = nil
local arrestConnection = nil

-- ==========================================
-- OUTLAW (MAHKUM) SEKMESİ - ATM ÜSTÜ SİSTEMİ
-- ==========================================
local OutlawTab = Window:CreateTab("Outlaw (Mahkum)", 4483362458) 

OutlawTab:CreateToggle({
   Name = "Auto ATM Farm (Üstten Soygun)",
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

               -- 1. ATM ve Buton Tarama
               for _, obj in ipairs(game.Workspace:GetDescendants()) do
                   if obj:IsA("ProximityPrompt") then
                       local content = string.lower(obj.ActionText .. obj.ObjectText .. obj.Name)
                       if string.find(content, "bust") or string.find(content, "atm") or string.find(content, "rob") then
                           local part = obj.Parent:IsA("BasePart") and obj.Parent or obj:FindFirstAncestorWhichIsA("BasePart")
                           if part and part.Position.Y > -100 then
                               if not isPoliceNear(part.Position, 200) then
                                   local dist = (root.Position - part.Position).Magnitude
                                   if dist < shortestDist then
                                       shortestDist = dist
                                       targetPrompt = obj
                                       targetPart = part
                                   end
                               end
                           end
                       end
                   end
               end

               -- 2. Işınlanma ve "Zorlamalı" Soygun
               if targetPrompt and targetPart then
                   -- Kankam tam dediğin gibi: ATM'nin tam üstüne ışınlanıyoruz (3.5 stüd yukarısı)
                   root.CFrame = targetPart.CFrame * CFrame.new(0, 3.5, 0) * CFrame.Angles(math.rad(-90), 0, 0)
                   
                   -- Karakteri dondur (Menzil hatası almamak için)
                   root.Anchored = true
                   task.wait(0.4) -- Harita yüklemesi için kısa bir es
                   
                   -- MOBİL FIX: Tuşa basma komutunu 3 kez hızlıca yolluyoruz ki kesin algılasın
                   if targetPrompt.Enabled then
                       fireproximityprompt(targetPrompt)
                       task.wait(0.1)
                       fireproximityprompt(targetPrompt)
                       
                       -- Soygun süresi boyunca bekle
                       local robTime = targetPrompt.HoldDuration > 0 and targetPrompt.HoldDuration or 2.5
                       local elapsed = 0
                       while elapsed < robTime + 0.5 and autoFarmATM do
                           task.wait(0.5)
                           elapsed = elapsed + 0.5
                           -- Polis gelirse kaç
                           if isPoliceNear(root.Position, 150) then break end
                       end
                   end
                   
                   root.Anchored = false
               else
                   print("Şu an güvenli/yüklü ATM yok kanka.")
               end
            end
         end)
      else
          if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
              LocalPlayer.Character.HumanoidRootPart.Anchored = false
          end
      end
   end,
})

-- ==========================================
-- SECURITY (POLİS) SEKMESİ (Burası Zaten Efsane)
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
                          if tPos.Y > -100 then 
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
                  fireproximityprompt(prompt, 1) 
              end
          end
      end)
   end,
})
