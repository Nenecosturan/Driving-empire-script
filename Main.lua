local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local Window = Rayfield:CreateWindow({
   Name = "Driving Empire • A-S ",
   LoadingTitle = "Loading source...",
   LoadingSubtitle = "checking RADAR & players",
   Theme = "Amber"
      ConfigurationSaving = {
      Enabled = true,
      FolderName = "Security",
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
-- NO-CLIP MEKANİZMASI (Duvar ve Su İçin)
-- ==========================================
local function toggleNoclip(state)
    if state then
        -- Fizik motorunun her karesinde çarpışmaları kapatır
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
        -- Çarpışmaları geri aç
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
-- SECURITY (POLİS) SEKMESİ - GELİŞMİŞ SÜRÜM
-- ==========================================
local SecurityTab = Window:CreateTab("Security", 4483362458)

SecurityTab:CreateToggle({
   Name = "Auto Arrest",
   CurrentValue = false,
   Flag = "AutoArrest",
   Callback = function(Value)
      -- Polis Değilse Engelle
      if Value and not (checkTeam(LocalPlayer, "security") or checkTeam(LocalPlayer, "police")) then
          Rayfield:Notify({
              Title = "Denied!",
              Content = "Join to security team for this feature",
              Duration = 4
          })
          autoArrest = false
          return
      end

      autoArrest = Value
      toggleNoclip(Value) -- Takip açılınca No-Clip de açılır

      if not autoArrest then
          if arrestConnection then arrestConnection:Disconnect() end
          currentTarget = nil
          return
      end

      -- KUSURSUZ TAKİP DÖNGÜSÜ
      arrestConnection = RunService.Heartbeat:Connect(function()
          local char = LocalPlayer.Character
          if not char or not char.PrimaryPart then return end

          -- 1. Hedef Belirleme (Artık Denizin Altını Veya Void'i Umursamıyoruz)
          if not currentTarget or not currentTarget.Character or not currentTarget.Character.PrimaryPart or not (checkTeam(currentTarget, "outlaw") or checkTeam(currentTarget, "criminal")) then
              local closestDist = math.huge
              local newTarget = nil
              
              for _, p in ipairs(Players:GetPlayers()) do
                  if p ~= LocalPlayer and (checkTeam(p, "outlaw") or checkTeam(p, "criminal")) then
                      if p.Character and p.Character.PrimaryPart then
                          -- Kanka artık Magnitude > 10 kontrolünü sildik, denizin dibinde de olsa gidiyoruz
                          local d = (char.PrimaryPart.Position - p.Character.PrimaryPart.Position).Magnitude
                          if d < closestDist then
                              closestDist = d
                              newTarget = p
                          end
                      end
                  end
              end
              currentTarget = newTarget
          end

          -- 2. Enseden Takip ve Yakalama
          if currentTarget and currentTarget.Character and currentTarget.Character.PrimaryPart then
              -- No-Clip sayesinde duvarın içine ışınlanman sorun olmayacak
              char:PivotTo(currentTarget.Character:GetPivot() * CFrame.new(0, 0, 2.5))
              
              -- Yakalama butonu (ProximityPrompt)
              local prompt = currentTarget.Character:FindFirstChildWhichIsA("ProximityPrompt", true)
              if prompt then 
                  fireproximityprompt(prompt, 1) 
              end
          end
      end)
   end,
})
