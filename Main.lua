local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local Window = Rayfield:CreateWindow({
   Name = "Driving Empire Elite Hub",
   LoadingTitle = "Mekanizmalar Kuruluyor...",
   LoadingSubtitle = "Kanka Bu Sefer Olacak",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "DrivingEmpireElite",
      FileName = "Config"
   }
})

-- Değişkenler
local autoFarmATM = false
local autoArrest = false
local currentTarget = nil
local arrestConnection = nil

-- Takım Kontrol Fonksiyonu (Esnek Tarama)
local function isTeam(teamNamePart)
    if LocalPlayer.Team and string.find(string.lower(LocalPlayer.Team.Name), string.lower(teamNamePart)) then
        return true
    end
    return false
end

-- Outlaw (Mahkum) Sekmesi
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
               task.wait(0.5)
               
               local char = LocalPlayer.Character
               if not char or not char:FindFirstChild("HumanoidRootPart") then continue end

               -- ATM Tarayıcı (Haritadaki aktif ATM'leri bulur)
               local targetATM = nil
               for _, obj in ipairs(game.Workspace:GetDescendants()) do
                   if obj:IsA("ProximityPrompt") and (string.find(string.lower(obj.Name), "atm") or string.find(string.lower(obj.Parent.Name), "atm")) then
                       if obj.Enabled then
                           targetATM = obj
                           break
                       end
                   end
               end

               if targetATM then
                   -- En yeni ışınlanma metodu (PivotTo)
                   char:PivotTo(targetATM.Parent.CFrame * CFrame.new(0, 0, 3))
                   task.wait(0.2) -- StreamingEnabled için bekleme
                   fireproximityprompt(targetATM)
                   task.wait(targetATM.HoldDuration + 0.5)
               end
            end
         end)
      end
   end,
})

-- Security (Polis) Sekmesi
local SecurityTab = Window:CreateTab("Security (Polis)", 4483362458)

local arrestToggle = SecurityTab:CreateToggle({
   Name = "Auto Arrest (Kilitlenme)",
   CurrentValue = false,
   Flag = "AutoArrest",
   Callback = function(Value)
      -- Kritik Koruma: Eğer polis (Security) değilse switch'i kapat
      if Value and not isTeam("Security") and not isTeam("Polis") then
          Rayfield:Notify({
              Title = "Erişim Reddedildi Aga!",
              Content = "Bu otomatik ışınlanma için Security (Polis) olmalısın!",
              Duration = 5,
              Image = 4483362458,
          })
          autoArrest = false
          -- Switch'i kodla geri kapatma (Flag üzerinden kapatılır)
          -- Not: Rayfield'da toggle'ı dışarıdan kapatmak bazen UI yenilemesi ister.
          return
      end

      autoArrest = Value

      -- Bağlantıyı Temizle
      if not autoArrest then
          if arrestConnection then arrestConnection:Disconnect() end
          currentTarget = nil
          return
      end

      -- Kusursuz Takip Döngüsü (Performans Odaklı)
      arrestConnection = RunService.Heartbeat:Connect(function()
          local char = LocalPlayer.Character
          if not char or not char.PrimaryPart then return end

          -- Hedef Kilitlenme Mantığı
          if not currentTarget or not currentTarget.Character or not currentTarget.Character.PrimaryPart or (currentTarget.Team and not string.find(string.lower(currentTarget.Team.Name), "outlaw")) then
              local closestDist = math.huge
              for _, p in ipairs(Players:GetPlayers()) do
                  if p ~= LocalPlayer and p.Team and string.find(string.lower(p.Team.Name), "outlaw") then
                      if p.Character and p.Character.PrimaryPart then
                          local d = (char.PrimaryPart.Position - p.Character.PrimaryPart.Position).Magnitude
                          if d < closestDist then
                              closestDist = d
                              currentTarget = p
                          end
                      end
                  end
              end
          end

          -- Seçili Hırsıza Işınlan ve Yapış (Loop Go-To)
          if currentTarget and currentTarget.Character and currentTarget.Character.PrimaryPart then
              -- Hırsızın arkasına milimetrik yapışma
              char:PivotTo(currentTarget.Character:GetPivot() * CFrame.new(0, 0, 2))
              
              -- Yakalarsa ProximityPrompt'u ateşle
              local p = currentTarget.Character:FindFirstChildWhichIsA("ProximityPrompt", true)
              if p then fireproximityprompt(p) end
          end
      end)
   end,
})
