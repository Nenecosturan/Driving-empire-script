local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local Window = Rayfield:CreateWindow({
   Name = "Driving Empire Mobile Pro",
   LoadingTitle = "Hatalar Temizleniyor...",
   LoadingSubtitle = "Senin Tespitinle Düzeltildi Aga",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "DrivingEmpireMobile",
      FileName = "Config"
   }
})

local function checkTeam(player, keyword)
    if player and player.Team then
        return string.find(string.lower(player.Team.Name), string.lower(keyword)) ~= nil
    end
    return false
end

local autoFarmATM = false
local autoArrest = false
local currentTarget = nil
local arrestConnection = nil

-- ==========================================
-- OUTLAW (MAHKUM) SEKMESİ - KÖKTEN ÇÖZÜLMÜŞ ATM
-- ==========================================
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
               task.wait(1.5) 
               
               local char = LocalPlayer.Character
               if not char or not char.PrimaryPart then continue end

               local targetPrompt = nil
               local targetPhysicalPart = nil
               local shortestDist = math.huge
               local myPos = char:GetPivot().Position

               -- ATM Taraması
               for _, obj in ipairs(game.Workspace:GetDescendants()) do
                   if obj:IsA("ProximityPrompt") then
                       local actText = string.lower(obj.ActionText)
                       local objText = string.lower(obj.ObjectText)
                       local pName = string.lower(obj.Name)

                       -- Kelime kontrolü (Senin attığın fotoğrafa göre Bust ve ATM)
                       if string.find(actText, "bust") or string.find(actText, "rob") or string.find(objText, "atm") or string.find(pName, "atm") then
                           if obj.Enabled then
                               -- KRİTİK NOKTA: Objenin Attachment veya Part içinde olması fark etmeksizin asıl fiziksel bloğu bulur
                               local physicalPart = obj:FindFirstAncestorWhichIsA("BasePart")
                               
                               if physicalPart then
                                   local atmPos = physicalPart.Position
                                   
                                   -- Okyanus (0,0,0) koruması
                                   if atmPos.Magnitude > 10 then 
                                       local dist = (myPos - atmPos).Magnitude
                                       if dist < shortestDist then
                                           shortestDist = dist
                                           targetPrompt = obj
                                           targetPhysicalPart = physicalPart
                                       end
                                   end
                               end
                           end
                       end
                   end
               end

               -- Işınlanma ve Etkileşim
               if targetPrompt and targetPhysicalPart then
                   -- ATM'nin fiziksel parçasının tam önüne ışınlan
                   char:PivotTo(targetPhysicalPart.CFrame * CFrame.new(0, 1, 2.5))
                   
                   -- Haritanın yüklenmesi için kesin bekleme (Mobil cihazlar için önemli)
                   task.wait(0.5)
                   
                   -- Mobil exploitlerde ProximityPrompt'un %100 tetiklenmesi için garanti yöntem
                   if targetPrompt.Enabled then
                       fireproximityprompt(targetPrompt, 1) -- Bazı mobil executorlar için 1 parametresi tetiklemeyi zorlar
                       task.wait(targetPrompt.HoldDuration + 0.5)
                   end
               else
                   print("Aga etrafta yüklü ATM yok. Lütfen haritada biraz dolaş.")
               end
            end
         end)
      end
   end,
})

-- ==========================================
-- SECURITY (POLİS) SEKMESİ (Bozmadık, Aynen Kalıyor)
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
                          if tPos.Magnitude > 10 then 
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
