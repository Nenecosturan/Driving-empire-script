local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local Window = Rayfield:CreateWindow({
   Name = "Driving Empire Mobile Ultra",
   LoadingTitle = "Streaming Bypass Devrede...",
   LoadingSubtitle = "Kanka Bu Sefer Kaçış Yok",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "DrivingEmpireUltra",
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
-- OUTLAW (MAHKUM) SEKMESİ - AGRESİF ATM SİSTEMİ
-- ==========================================
local OutlawTab = Window:CreateTab("Outlaw (Mahkum)", 4483362458) 

OutlawTab:CreateToggle({
   Name = "Auto ATM Farm (Agresif)",
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

               -- AGRESİF TARAMA: Sadece isme değil, her türlü etkileşime bakıyoruz
               for _, obj in ipairs(game.Workspace:GetDescendants()) do
                   if obj:IsA("ProximityPrompt") and obj.Enabled then
                       -- Fotoğraftaki "Bust" ve "ATM" yazılarını her ihtimale karşı tarıyoruz
                       local content = string.lower(obj.ActionText .. obj.ObjectText .. obj.Name)
                       if string.find(content, "bust") or string.find(content, "atm") then
                           local part = obj.Parent:IsA("BasePart") and obj.Parent or obj:FindFirstAncestorWhichIsA("BasePart")
                           
                           if part then
                               local dist = (root.Position - part.Position).Magnitude
                               -- Okyanus dibi (0,0,0) koruması ve mesafe filtresi
                               if part.Position.Magnitude > 10 and dist < shortestDist then
                                   shortestDist = dist
                                   targetPrompt = obj
                                   targetPart = part
                               end
                           end
                       end
                   end
               end

               -- IŞINLANMA VE MOBİL ETKİLEŞİM GARANTİSİ
               if targetPrompt and targetPart then
                   -- 1. Işınlan (Tam butonun önünde duracak şekilde)
                   root.CFrame = targetPart.CFrame * CFrame.new(0, 0, 2.5)
                   
                   -- 2. Harita ve Buton Yüklenmesi İçin Bekle
                   task.wait(0.4) 
                   
                   -- 3. Mobil Fix: Karakteri dondur ki etkileşim kopmasın
                   root.Anchored = true
                   
                   -- 4. Tetikleme (Mobil Executorlar için en sağlam yöntem)
                   fireproximityprompt(targetPrompt)
                   
                   -- 5. Bust süresi (HoldDuration) kadar bekle
                   if targetPrompt.HoldDuration > 0 then
                       task.wait(targetPrompt.HoldDuration + 0.3)
                   end
                   
                   -- 6. Serbest bırak ve devam et
                   root.Anchored = false
               else
                   -- Eğer ATM bulamazsa biraz haritayı dolaşması için bildirim ver
                   print("ATM yüklenmesi bekleniyor... Kanka biraz araçla gezmelisin.")
               end
            end
         end)
      else
          -- Toggle kapatıldığında karakter donuk kaldıysa çöz
          if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
              LocalPlayer.Character.HumanoidRootPart.Anchored = false
          end
      end
   end,
})

-- ==========================================
-- SECURITY (POLİS) SEKMESİ (Aynen Korundu)
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
                  fireproximityprompt(prompt) 
              end
          end
      end)
   end,
})
