local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local Window = Rayfield:CreateWindow({
   Name = "Driving Empire Ultimate",
   LoadingTitle = "Sistem Derleniyor...",
   LoadingSubtitle = "Hatasız Sürüm Aga",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "DrivingEmpireUlt",
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
-- OUTLAW (MAHKUM) SEKMESİ
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

               local targetATM = nil
               local shortestDist = math.huge
               local myPos = char:GetPivot().Position

               -- Haritadaki ATM'leri güvenli şekilde (GetPivot ile) tara
               for _, obj in ipairs(game.Workspace:GetDescendants()) do
                   if obj:IsA("ProximityPrompt") then
                       -- Kanka burası kritik: Ekran görüntüsündeki "Bust" kelimesini ekledik!
                       local nameMatch = string.find(string.lower(obj.Name), "atm") or (obj.Parent and string.find(string.lower(obj.Parent.Name), "atm"))
                       local textMatch = string.find(string.lower(obj.ActionText), "rob") or string.find(string.lower(obj.ActionText), "hack") or string.find(string.lower(obj.ActionText), "bust") or string.find(string.lower(obj.ObjectText), "atm")
                       
                       if (nameMatch or textMatch) and obj.Enabled and obj.Parent then
                           local atmPos = obj.Parent:GetPivot().Position
                           
                           -- Okyanus dibi (0,0,0) koruması: Yüklenmemiş objeleri yoksay
                           if atmPos.Magnitude > 300 then 
                               local dist = (myPos - atmPos).Magnitude
                               if dist < shortestDist then
                                   shortestDist = dist
                                   targetATM = obj
                               end
                           end
                       end
                   end
               end

               if targetATM and targetATM.Parent then
                   -- ATM'nin önüne güvenli ışınlanma
                   char:PivotTo(targetATM.Parent:GetPivot() * CFrame.new(0, 2, 3))
                   task.wait(0.5) 
                   fireproximityprompt(targetATM)
                   task.wait(targetATM.HoldDuration + 0.5)
               else
                   Rayfield:Notify({
                       Title = "ATM Aranıyor", 
                       Content = "Yakında aktif ATM yok, haritayı biraz dolaş ki yenileri yüklensin.", 
                       Duration = 3
                   })
               end
            end
         end)
      end
   end,
})

-- ==========================================
-- SECURITY (POLİS) SEKMESİ (Burası Kusursuz, Ellenmedi)
-- ==========================================
local SecurityTab = Window:CreateTab("Security (Polis)", 4483362458)

SecurityTab:CreateToggle({
   Name = "Auto Arrest",
   CurrentValue = false,
   Flag = "AutoArrest",
   Callback = function(Value)
      if Value and not (checkTeam(LocalPlayer, "security") or checkTeam(LocalPlayer, "police")) then
          Rayfield:Notify({
              Title = "Erişim Reddedildi!",
              Content = "Bu özelliği açmak için Security takımında olman lazım.",
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
                          if tPos.Magnitude > 300 then 
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
