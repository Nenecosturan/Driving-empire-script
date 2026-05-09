local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local Window = Rayfield:CreateWindow({
   Name = "Driving Empire - Global Arrest",
   LoadingTitle = "Sınırlar Kaldırılıyor...",
   LoadingSubtitle = "Dünyalar Arası Işınlanma Aktif",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "DE_GlobalSecurity",
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
local autoArrest = false
local currentTarget = nil
local arrestConnection = nil
local noclipConnection = nil

-- ==========================================
-- NO-CLIP MEKANİZMASI (Hayalet Modu)
-- ==========================================
local function toggleNoclip(state)
    if state then
        noclipConnection = RunService.Stepped:Connect(function()
            if LocalPlayer.Character then
                for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    else
        if noclipConnection then
            noclipConnection:Disconnect()
            noclipConnection = nil
        end
        if LocalPlayer.Character then
            for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
end

-- ==========================================
-- SECURITY (POLİS) SEKMESİ - SINIRSIZ SÜRÜM
-- ==========================================
local SecurityTab = Window:CreateTab("Security (Polis)", 4483362458)

SecurityTab:CreateToggle({
   Name = "Auto Arrest (Sınırsız Global Takip)",
   CurrentValue = false,
   Flag = "AutoArrest",
   Callback = function(Value)
      -- Polis Değilse Engelle
      if Value and not (checkTeam(LocalPlayer, "security") or checkTeam(LocalPlayer, "police")) then
          Rayfield:Notify({
              Title = "Yetki Reddedildi!",
              Content = "Kanka bu global modu açmak için Security veya Polis olman lazım.",
              Duration = 4
          })
          autoArrest = false
          return
      end

      autoArrest = Value
      toggleNoclip(Value) -- No-Clip her zaman aktif

      if not autoArrest then
          if arrestConnection then arrestConnection:Disconnect() end
          currentTarget = nil
          return
      end

      -- KUSURSUZ VE SINIRSIZ TAKİP DÖNGÜSÜ
      arrestConnection = RunService.Heartbeat:Connect(function()
          local char = LocalPlayer.Character
          if not char or not char.PrimaryPart then return end

          -- 1. Hedef Belirleme: Filtrelerin hepsi kaldırıldı!
          if not currentTarget or not currentTarget.Character or not (checkTeam(currentTarget, "outlaw") or checkTeam(currentTarget, "criminal")) then
              local closestDist = math.huge
              local newTarget = nil
              
              for _, p in ipairs(Players:GetPlayers()) do
                  if p ~= LocalPlayer and (checkTeam(p, "outlaw") or checkTeam(p, "criminal")) then
                      if p.Character then
                          -- PrimaryPart'ı beklemeden direkt GetPivot kullanıyoruz (Yüklenmemiş oyuncuları bile bulur)
                          local targetPos = p.Character:GetPivot().Position
                          local d = (char:GetPivot().Position - targetPos).Magnitude
                          
                          if d < closestDist then
                              closestDist = d
                              newTarget = p
                          end
                      end
                  end
              end
              
              -- Yeni hedef bulduğunda sağ altta sana haber versin
              if newTarget and newTarget ~= currentTarget then
                  Rayfield:Notify({
                      Title = "Hedef Kilitlendi!",
                      Content = newTarget.Name .. " adlı oyuncuya gidiliyor (Mesafe: " .. math.floor(closestDist) .. " stud)",
                      Duration = 2
                  })
                  currentTarget = newTarget
              end
          end

          -- 2. Işınlanma ve Yakalama (Deniz altı, duvar içi fark etmez)
          if currentTarget and currentTarget.Character then
              -- Hedefin direkt 2.5 stüd arkasına yapış (Menzil sıkıntısı olmaması için)
              local tCFrame = currentTarget.Character:GetPivot()
              char:PivotTo(tCFrame * CFrame.new(0, 0, 2.5))
              
              -- Yakalama butonu taraması (Zorla tetikleme)
              local prompt = currentTarget.Character:FindFirstChildWhichIsA("ProximityPrompt", true)
              if prompt then 
                  fireproximityprompt(prompt, 1) 
              end
          end
      end)
   end,
})
