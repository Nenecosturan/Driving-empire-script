local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local Window = Rayfield:CreateWindow({
   Name = "Driving Empire Elite",
   LoadingTitle = "Mekanikler Taranıyor...",
   LoadingSubtitle = "Güvenli Işınlanma Aktif",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "DrivingEmpire",
      FileName = "Config"
   }
})

-- Takım Kontrolü (Mahkum veya Polis mi?)
local function isTeam(teamNamePart)
    if LocalPlayer.Team and string.find(string.lower(LocalPlayer.Team.Name), string.lower(teamNamePart)) then
        return true
    end
    return false
end

local autoFarmATM = false
local autoArrest = false
local currentTarget = nil
local arrestConnection = nil

-- Mahkum Sekmesi
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
               task.wait(1) -- Sistemi yormamak için 1 saniye bekleme
               
               local char = LocalPlayer.Character
               if not char or not char:FindFirstChild("HumanoidRootPart") then continue end

               local targetATM = nil
               local shortest = math.huge
               local myPos = char:GetPivot().Position

               -- Gelişmiş ATM Tarayıcı (Haritadaki tüm E tuşlarını tarar)
               for _, obj in ipairs(game.Workspace:GetDescendants()) do
                   if obj:IsA("ProximityPrompt") then
                       -- Adında veya ekrandaki yazısında ATM, Rob, Cash kelimeleri geçiyorsa algıla
                       local nameMatch = string.find(string.lower(obj.Name), "atm") or string.find(string.lower(obj.Parent.Name), "atm")
                       local textMatch = string.find(string.lower(obj.ActionText), "rob") or string.find(string.lower(obj.ObjectText), "atm") or string.find(string.lower(obj.ActionText), "hack")
                       
                       if (nameMatch or textMatch) and obj.Enabled then
                           local dist = (myPos - obj.Parent.Position).Magnitude
                           -- Eğer ATM okyanusun dibinde (0,0,0) değilse kabul et
                           if obj.Parent.Position.Magnitude > 50 and dist < shortest then
                               shortest = dist
                               targetATM = obj
                           end
                       end
                   end
               end

               if targetATM then
                   -- Anti-Cheat'i tetiklememek için biraz yukarıdan ışınlanıyoruz
                   char:PivotTo(targetATM.Parent.CFrame * CFrame.new(0, 2, 3))
                   task.wait(0.5) -- Haritanın o kısmının yüklenmesi için kesinlikle beklenmeli
                   fireproximityprompt(targetATM)
                   task.wait(targetATM.HoldDuration + 1)
               else
                   print("Şu an etrafta aktif/yüklü bir ATM bulunamadı.")
               end
            end
         end)
      end
   end,
})

-- Polis Sekmesi
local SecurityTab = Window:CreateTab("Security (Polis)", 4483362458)

SecurityTab:CreateToggle({
   Name = "Auto Arrest",
   CurrentValue = false,
   Flag = "AutoArrest",
   Callback = function(Value)
      -- Polis değilse anında uyar ve engelle
      if Value and not isTeam("Security") and not isTeam("Police") then
          Rayfield:Notify({
              Title = "Hop Aga Dur!",
              Content = "Bu otomatik ışınlanmayı kullanmak için Security/Polis takımında olmalısın.",
              Duration = 4,
              Image = 4483362458,
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

      -- RunService ile FPS düşürmeyen mükemmel takip
      arrestConnection = RunService.Heartbeat:Connect(function()
          local char = LocalPlayer.Character
          if not char or not char.PrimaryPart then return end

          -- Yeni Hedef Bulma
          if not currentTarget or not currentTarget.Character or not currentTarget.Character.PrimaryPart or currentTarget.Team.Name ~= "Outlaws" then
              local closestDist = math.huge
              for _, p in ipairs(Players:GetPlayers()) do
                  if p ~= LocalPlayer and p.Team and string.find(string.lower(p.Team.Name), "outlaw") then
                      if p.Character and p.Character.PrimaryPart then
                          local targetPos = p.Character.PrimaryPart.Position
                          -- KRİTİK ÇÖZÜM: Hedefin koordinatı denizin dibi (0,0,0) ise onu yoksay
                          if targetPos.Magnitude > 50 then 
                              local d = (char.PrimaryPart.Position - targetPos).Magnitude
                              if d < closestDist then
                                  closestDist = d
                                  currentTarget = p
                              end
                          end
                      end
                  end
              end
          end

          -- Hedefe Yapışma
          if currentTarget and currentTarget.Character and currentTarget.Character.PrimaryPart then
              -- Işınlanmayı güvenli bir mesafeye yapıyoruz ki anti-cheat "ne oluyoruz" demesin
              char:PivotTo(currentTarget.Character:GetPivot() * CFrame.new(0, 0, 3))
              
              local p = currentTarget.Character:FindFirstChildWhichIsA("ProximityPrompt", true)
              if p then fireproximityprompt(p) end
          end
      end)
   end,
})
