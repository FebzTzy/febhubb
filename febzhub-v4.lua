-- ============================================================
-- [v4 INJECT] Port penuh fitur W424 Violence District ke Febz
-- Inject PALING BAWAH febz-hub.lua
-- Semua toggle/button diawali "v4"
-- ============================================================
do
    local Players           = v3
    local LocalPlayer       = v4
    local RunService        = v5
    local UserInputService  = v6
    local VIM               = v7
    local ReplicatedStorage = v9
    local CoreGui           = v10
    local PlayerGui         = v11
    local Camera            = v12
    local TweenService      = v15
    local HttpService       = v14

    -- ---------- helpers ----------
    local function v4_Root()
        local c = LocalPlayer.Character
        return c and c:FindFirstChild("HumanoidRootPart")
    end
    local function v4_Hum()
        local c = LocalPlayer.Character
        return c and c:FindFirstChildOfClass("Humanoid")
    end
    local function v4_Killer()   return LocalPlayer.Team and LocalPlayer.Team.Name == "Killer" end
    local function v4_Survivor() return LocalPlayer.Team and LocalPlayer.Team.Name == "Survivors" end
    local function v4_Lobby()    return LocalPlayer.Team and LocalPlayer.Team.Name == "Spectator" end
    local function v4_Notif(t, d)
        pcall(function() v1:Notify({ Title = t, Description = d, Duration = 2 }) end)
    end
    local function v4_Rem(path)
        local cur = ReplicatedStorage
        for seg in string.gmatch(path, "[^%.]+") do
            if not cur then return nil end
            cur = cur:FindFirstChild(seg)
        end
        return cur
    end

    -- ============================================================
    -- TAB: v4 Info
    -- ============================================================
    local InfoTab  = v2:CreateTab("v4 Info", false, false)
    local InfoPage = InfoTab:CreatePage("v4 Info")
    local InfoSec  = InfoPage:CreateSection("v4 Server", "server")

    InfoSec:AddButton("v4 Return to Lobby", function()
        local ev = v4_Rem("Remotes.Game.loadcharevent")
        if ev then ev:FireServer() end
        v4_Notif("v4 Return To Lobby", "Back...")
    end)
    InfoSec:AddButton("v4 Rejoin Server", function()
        task.delay(1, function()
            pcall(function()
                game:GetService("TeleportService"):Teleport(game.PlaceId)
            end)
        end)
        v4_Notif("v4 Rejoin", "Rejoining...")
    end)
    InfoSec:AddButton("v4 Server Hop", function()
        local ok, body = pcall(function()
            return game:HttpGet(string.format(
                "https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Desc&limit=100&excludeFullGames=true",
                game.PlaceId))
        end)
        if not ok then return v4_Notif("v4 Server Hop", "API error") end
        local list = HttpService:JSONDecode(body)
        local servers = {}
        for _, s in ipairs(list.data or {}) do
            if s.id ~= game.JobId and s.playing < s.maxPlayers then
                table.insert(servers, s)
            end
        end
        if #servers == 0 then return v4_Notif("v4 Server Hop", "No servers") end
        local pick = servers[math.random(1, #servers)]
        pcall(function()
            game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, pick.id, LocalPlayer)
        end)
    end)
    InfoSec:AddButton("v4 Server Hop (Small Server)", function()
        local ok, body = pcall(function()
            return game:HttpGet(string.format(
                "https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Asc&limit=100",
                game.PlaceId))
        end)
        if not ok then return v4_Notif("v4 Server Hop Small", "API error") end
        local list = HttpService:JSONDecode(body)
        for _, s in ipairs(list.data or {}) do
            if s.id ~= game.JobId and s.playing < s.maxPlayers and s.playing <= 5 then
                pcall(function()
                    game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer)
                end)
                return v4_Notif("v4 Server Hop Small", string.format("Found (%d players)", s.playing))
            end
        end
        v4_Notif("v4 Server Hop Small", "No small servers")
    end)

    -- ============================================================
    -- TAB: v4 Survivor
    -- ============================================================
    local STab  = v2:CreateTab("v4 Survivor", false, false)
    local SPage = STab:CreatePage("v4 Survivor")

    -- ---- Movement section ----
    local S_Move = SPage:CreateSection("v4 Movement", "move")

    -- [1] v4 Speed Boost (BodyVelocity)
    local v4_SpeedBoost = { Enabled = false, Speed = 30, Conn = nil }
    S_Move:AddToggle("v4 Speed Boost (BV)", false, function(a)
        v4_SpeedBoost.Enabled = a
        if a then
            if v4_SpeedBoost.Conn then v4_SpeedBoost.Conn:Disconnect() end
            v4_SpeedBoost.Conn = RunService.Heartbeat:Connect(function()
                if not v4_SpeedBoost.Enabled then return end
                local c, hrp, hum = LocalPlayer.Character, nil, nil
                if c then hrp = c:FindFirstChild("HumanoidRootPart"); hum = c:FindFirstChildOfClass("Humanoid") end
                if not hrp or not hum then return end
                local bv = hrp:FindFirstChild("v4_SpeedBV")
                if not bv then
                    bv = Instance.new("BodyVelocity")
                    bv.Name = "v4_SpeedBV"
                    bv.MaxForce = Vector3.new(1e9, 0, 1e9)
                    bv.P = 1e6
                    bv.Parent = hrp
                end
                local md = hum.MoveDirection
                bv.Velocity = md.Magnitude > 0 and md * v4_SpeedBoost.Speed or Vector3.zero
            end)
        else
            if v4_SpeedBoost.Conn then v4_SpeedBoost.Conn:Disconnect() v4_SpeedBoost.Conn = nil end
            local hrp = v4_Root()
            if hrp then local bv = hrp:FindFirstChild("v4_SpeedBV"); if bv then bv:Destroy() end end
        end
        v4_Notif("v4 Speed Boost", a and "ON" or "OFF")
    end, { Flag = "v4_SpeedBoost" })
    S_Move:AddSlider("v4 Speed Value (studs/s)", 10, 100, 30, function(v)
        v4_SpeedBoost.Speed = v
    end, { Increment = 1, Flag = "v4_SpeedValue" })

    -- [2] v4 Flee Killer
    local v4_Flee = { Enabled = false, Dist = 40, Thread = nil }
    S_Move:AddToggle("v4 Flee Killer", false, function(a)
        v4_Flee.Enabled = a
        if a then
            if v4_Flee.Thread then task.cancel(v4_Flee.Thread) end
            v4_Flee.Thread = task.spawn(function()
                while v4_Flee.Enabled do
                    local hrp = v4_Root()
                    if hrp then
                        local best, bd = nil, math.huge
                        for _, p in ipairs(Players:GetPlayers()) do
                            if p ~= LocalPlayer and p.Team and p.Team.Name == "Killer" and p.Character then
                                local krp = p.Character:FindFirstChild("HumanoidRootPart")
                                if krp then
                                    local d = (krp.Position - hrp.Position).Magnitude
                                    if d < bd then bd = d best = krp end
                                end
                            end
                        end
                        if best and bd <= v4_Flee.Dist then
                            local dir = (hrp.Position - best.Position).Unit
                            hrp.CFrame = CFrame.new(hrp.Position + dir * v4_Flee.Dist + Vector3.new(0, 3, 0))
                            task.wait(0.5)
                        else task.wait(0.1) end
                    else task.wait(0.1) end
                end
            end)
        else
            if v4_Flee.Thread then task.cancel(v4_Flee.Thread) v4_Flee.Thread = nil end
        end
        v4_Notif("v4 Flee Killer", a and "ON" or "OFF")
    end, { Flag = "v4_Flee" })
    S_Move:AddSlider("v4 Flee Distance", 10, 200, 40, function(v)
        v4_Flee.Dist = v
    end, { Increment = 5, Flag = "v4_FleeDist" })

    -- [3] v4 Force Kick Killer
    local v4_ForceKick = { Enabled = false, Conn = nil }
    S_Move:AddToggle("v4 Force Kick Killer", false, function(a)
        v4_ForceKick.Enabled = a
        if a then
            if v4_ForceKick.Conn then v4_ForceKick.Conn:Disconnect() end
            v4_ForceKick.Conn = RunService.Heartbeat:Connect(function()
                if not v4_ForceKick.Enabled then return end
                local c = LocalPlayer.Character
                if not c or not c:GetAttribute("IsCarried") then return end
                local h = c:FindFirstChildOfClass("Humanoid")
                if h then pcall(function() h.Health = 0 end) end
            end)
        else
            if v4_ForceKick.Conn then v4_ForceKick.Conn:Disconnect() v4_ForceKick.Conn = nil end
        end
    end, { Flag = "v4_ForceKick" })

    -- [4] v4 Moonwalk
    local v4_Moon = { Enabled = false, Conn = nil }
    S_Move:AddToggle("v4 Moonwalk", false, function(a)
        v4_Moon.Enabled = a
        if a then
            if v4_Moon.Conn then v4_Moon.Conn:Disconnect() end
            local last, dir = 0, 1
            v4_Moon.Conn = RunService.RenderStepped:Connect(function()
                if not v4_Moon.Enabled then return end
                local c = LocalPlayer.Character
                local hrp = c and c:FindFirstChild("HumanoidRootPart")
                local hum = c and c:FindFirstChildOfClass("Humanoid")
                if not hrp or not hum or hum.Health <= 0 then return end
                local now = tick()
                if now - last >= 0.07 then dir = dir * -1 last = now end
                hum:Move(hrp.CFrame.LookVector * -1.2 + hrp.CFrame.RightVector * (dir * 0.9), false)
            end)
        else
            if v4_Moon.Conn then v4_Moon.Conn:Disconnect() v4_Moon.Conn = nil end
        end
    end, { Flag = "v4_Moonwalk" })

    -- [5] v4 Auto Run [Mobile]
    local v4_AutoRunMob = { Enabled = false, Thread = nil }
    local function v4_GetSprintBtn()
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        local mob = pg and pg:FindFirstChild("Survivor-mob")
        local ctl = mob and mob:FindFirstChild("Controls")
        local sp  = ctl and ctl:FindFirstChild("sprint")
        if not sp then return nil end
        if sp:IsA("GuiButton") then return sp end
        local ic = sp:FindFirstChild("icon")
        if ic and ic:IsA("GuiButton") then return ic end
        if ic and ic.Parent and ic.Parent:IsA("GuiButton") then return ic.Parent end
        return sp
    end
    local function v4_PressSprint()
        local btn = v4_GetSprintBtn()
        if not btn then return false end
        pcall(function()
            if type(firesignal) == "function" then
                firesignal(btn.MouseButton1Click)
                firesignal(btn.MouseButton1Down)
                task.wait(0.04)
                firesignal(btn.MouseButton1Up)
            end
        end)
        return true
    end
    S_Move:AddToggle("v4 Auto Run [Mobile]", false, function(a)
        v4_AutoRunMob.Enabled = a
        if a then
            if v4_AutoRunMob.Thread then return end
            v4_AutoRunMob.Thread = task.spawn(function()
                while v4_AutoRunMob.Enabled do
                    local c = LocalPlayer.Character
                    local hum = c and c:FindFirstChildOfClass("Humanoid")
                    if hum then
                        local isRun = c:GetAttribute("Sprinting") == true or c:GetAttribute("IsRunning") == true
                        local moving = hum.MoveDirection.Magnitude > 0.12
                        if moving ~= isRun then v4_PressSprint() end
                    end
                    task.wait(0.12)
                end
                v4_AutoRunMob.Thread = nil
            end)
        end
    end, { Flag = "v4_AutoRunMob" })

    -- [6] v4 Auto Run [PC]
    local v4_AutoRunPC = { Enabled = false }
    S_Move:AddToggle("v4 Auto Run [PC]", false, function(a)
        v4_AutoRunPC.Enabled = a
        if a then
            task.spawn(function()
                while v4_AutoRunPC.Enabled do
                    VIM:SendKeyEvent(true, Enum.KeyCode.LeftShift, false, LocalPlayer:GetMouse())
                    task.wait(0.1)
                end
            end)
        else
            VIM:SendKeyEvent(false, Enum.KeyCode.LeftShift, false, LocalPlayer:GetMouse())
        end
    end, { Flag = "v4_AutoRunPC" })

    -- [7] v4 Enable Run Speed (attr)
    local v4_RunSpd = { Enabled = false, Value = 20, Conn = nil, CharConn = nil }
    local function v4_HookRunSpd(char)
        if v4_RunSpd.Conn then v4_RunSpd.Conn:Disconnect() v4_RunSpd.Conn = nil end
        if not v4_RunSpd.Enabled or not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 10)
        if not hum then return end
        task.wait(0.5)
        if not v4_RunSpd.Enabled then return end
        v4_RunSpd.Conn = hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
            local c = LocalPlayer.Character
            if not c or not v4_RunSpd.Enabled then return end
            if c:GetAttribute("IsCarried") or c:GetAttribute("IsHooked") or
               c:GetAttribute("IsStunned") or c:GetAttribute("Immobile") or
               c:GetAttribute("MovementLocked") or c:GetAttribute("Crouching") or
               c:GetAttribute("Knocked") or c:GetAttribute("isHealing") then return end
            if hum.WalkSpeed ~= 0 and hum.WalkSpeed ~= v4_RunSpd.Value then
                pcall(function() hum.WalkSpeed = v4_RunSpd.Value end)
            end
        end)
        pcall(function() hum.WalkSpeed = v4_RunSpd.Value end)
    end
    S_Move:AddToggle("v4 Enable Run Speed", false, function(a)
        v4_RunSpd.Enabled = a
        if a then
            v4_HookRunSpd(LocalPlayer.Character)
            if v4_RunSpd.CharConn then v4_RunSpd.CharConn:Disconnect() end
            v4_RunSpd.CharConn = LocalPlayer.CharacterAdded:Connect(function(c)
                if v4_RunSpd.Enabled then v4_HookRunSpd(c) end
            end)
        else
            if v4_RunSpd.Conn then v4_RunSpd.Conn:Disconnect() v4_RunSpd.Conn = nil end
            if v4_RunSpd.CharConn then v4_RunSpd.CharConn:Disconnect() v4_RunSpd.CharConn = nil end
            local hum = v4_Hum()
            if hum then pcall(function() hum.WalkSpeed = 10 end) end
        end
    end, { Flag = "v4_EnableRunSpeed" })
    S_Move:AddSlider("v4 Run Speed Value", 16, 100, 20, function(v)
        v4_RunSpd.Value = v
        if v4_RunSpd.Enabled then
            local hum = v4_Hum()
            if hum then pcall(function() hum.WalkSpeed = v end) end
        end
    end, { Increment = 1, Flag = "v4_RunSpeedValue" })

    -- [8] v4 Auto Dodge Crouch
    local v4_Dodge = { Enabled = false, Thread = nil, Crouching = false }
    local function v4_GetCrouchBtn()
        local b = LocalPlayer:FindFirstChild("PlayerGui")
        for s in string.gmatch("Survivor-mob.Controls.crouch.icon", "[^%.]+") do
            if b then b = b:FindFirstChild(s) end
        end
        if b and b:IsA("GuiObject") and b.Visible and b.Parent and b.Parent:IsA("GuiButton") then return b.Parent end
        return nil
    end
    local function v4_FireCrouch(state)
        local btn = v4_GetCrouchBtn()
        if UserInputService.TouchEnabled and btn and type(firesignal) == "function" then
            pcall(function() firesignal(btn.MouseButton1Click) end)
            return
        end
        if state then VIM:SendKeyEvent(true, Enum.KeyCode.LeftControl, false, game)
        else VIM:SendKeyEvent(false, Enum.KeyCode.LeftControl, false, game) end
    end
    local function v4_AbyssActive()
        local hrp = v4_Root()
        if not hrp then return false end
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Team and p.Team.Name == "Killer" and p.Character then
                local krp = p.Character:FindFirstChild("HumanoidRootPart")
                if krp and (krp.Position - hrp.Position).Magnitude <= 25 then
                    local hum = p.Character:FindFirstChildOfClass("Humanoid")
                    local anim = hum and hum:FindFirstChildOfClass("Animator")
                    if anim then
                        for _, t in ipairs(anim:GetPlayingAnimationTracks()) do
                            if t.Animation and t.Animation.AnimationId == "rbxassetid://80411309607666" then
                                if (t.Length - t.TimePosition) <= 1.5 then return false end
                                return true
                            end
                        end
                    end
                end
            end
        end
        return false
    end
    S_Move:AddToggle("v4 Auto Dodge Crouch", false, function(a)
        v4_Dodge.Enabled = a
        if a then
            if v4_Dodge.Thread then task.cancel(v4_Dodge.Thread) end
            v4_Dodge.Thread = task.spawn(function()
                while v4_Dodge.Enabled do
                    local act = v4_AbyssActive()
                    if act and not v4_Dodge.Crouching then
                        v4_Dodge.Crouching = true
                        v4_FireCrouch(true)
                    elseif not act and v4_Dodge.Crouching then
                        v4_Dodge.Crouching = false
                        v4_FireCrouch(false)
                    end
                    task.wait(0.05)
                end
                if v4_Dodge.Crouching then v4_FireCrouch(false) end
            end)
        else
            if v4_Dodge.Thread then task.cancel(v4_Dodge.Thread) v4_Dodge.Thread = nil end
        end
    end, { Flag = "v4_DodgeCrouch" })

    -- ---- Utility section ----
    local S_Util = SPage:CreateSection("v4 Survivor Utility", "shield")

    -- [9] v4 Fast Vault
    local v4_FastVault = { Enabled = false, Mult = 1.3 }
    local function v4_ApplyFastVault(a)
        v4_FastVault.Enabled = a
        local c = LocalPlayer.Character
        if c then c:SetAttribute("vaultspeed", a and v4_FastVault.Mult or 1) end
    end
    S_Util:AddToggle("v4 Fast Vault", false, function(a)
        v4_ApplyFastVault(a)
        v4_Notif("v4 Fast Vault", a and "ON" or "OFF")
    end, { Flag = "v4_FastVault" })
    S_Util:AddSlider("v4 Fast Vault Multiplier", 10, 20, 13, function(v)
        v4_FastVault.Mult = v / 10
        if v4_FastVault.Enabled then
            local c = LocalPlayer.Character
            if c then c:SetAttribute("vaultspeed", v4_FastVault.Mult) end
        end
    end, { Increment = 1, Flag = "v4_FastVaultMult" })
    LocalPlayer.CharacterAdded:Connect(function(c)
        task.wait(0.5)
        if v4_FastVault.Enabled then c:SetAttribute("vaultspeed", v4_FastVault.Mult) end
    end)

    -- [10] v4 Self Heal (loop)
    local v4_SelfHeal = { Enabled = false, Interval = 0.5 }
    task.spawn(function()
        while _G.Ox.ScriptAlive do
            task.wait(v4_SelfHeal.Interval)
            if not v4_SelfHeal.Enabled then continue end
            if v4_Killer() then continue end
            local c = LocalPlayer.Character
            if not c then continue end
            local inter = c:FindFirstChild("CheckInterractable")
            local hrp = c:FindFirstChild("HumanoidRootPart")
            local hum = c:FindFirstChildOfClass("Humanoid")
            if not hrp or not hum then continue end
            local busy = false
            if inter then
                if inter:GetAttribute("isVaulting") or inter:GetAttribute("isRepairing") or
                   inter:GetAttribute("isUnhooking") or inter:GetAttribute("isHealing") or
                   inter:GetAttribute("isSliding") then busy = true end
            end
            if not busy and hum.Health < hum.MaxHealth then
                local hev = v4_Rem("Remotes.Healing.HealEvent")
                if hev then pcall(function() hev:FireServer(hrp, true) end) end
            end
        end
    end)
    S_Util:AddToggle("v4 Self Heal", false, function(a)
        if a and v4_Killer() then
            v4_Notif("v4 Self Heal", "Need Survivor")
            return
        end
        v4_SelfHeal.Enabled = a
        v4_Notif("v4 Self Heal", a and "ON" or "OFF")
    end, { Flag = "v4_SelfHeal" })
    S_Util:AddSlider("v4 Self Heal Interval (x100ms)", 1, 30, 5, function(v)
        v4_SelfHeal.Interval = v / 10
    end, { Increment = 1, Flag = "v4_SelfHealInt" })

    -- [11] v4 God Mode
    local v4_God = { Enabled = false, Conn = nil }
    S_Util:AddToggle("v4 God Mode", false, function(a)
        v4_God.Enabled = a
        if a then
            if v4_God.Conn then v4_God.Conn:Disconnect() end
            v4_God.Conn = RunService.Heartbeat:Connect(function()
                if not v4_God.Enabled then return end
                local hum = v4_Hum()
                if hum and hum.Health < hum.MaxHealth then
                    pcall(function() hum.Health = hum.MaxHealth end)
                end
            end)
        else
            if v4_God.Conn then v4_God.Conn:Disconnect() v4_God.Conn = nil end
        end
        v4_Notif("v4 God Mode", a and "ON" or "OFF")
    end, { Flag = "v4_GodMode" })

    -- [12] v4 No Fall Damage
    local v4_NoFall = { Enabled = false, Installed = false }
    if not v4_NoFall.Installed then
        local mt = getrawmetatable(game)
        local old = mt.__namecall
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if v4_NoFall.Enabled and (method == "FireServer" or method == "fireServer") then
                local fall = v4_Rem("Remotes.Mechanics.Fall")
                if self == fall then
                    local a = {...}
                    a[1] = 0
                    return old(self, unpack(a))
                end
            end
            return old(self, ...)
        end)
        setreadonly(mt, true)
        v4_NoFall.Installed = true
    end
    S_Util:AddToggle("v4 No Fall Damage", false, function(a)
        v4_NoFall.Enabled = a
        v4_Notif("v4 No Fall Damage", a and "ON" or "OFF")
    end, { Flag = "v4_NoFall" })

    -- [13] v4 Anti Slow Vault
    local v4_AntiSlowVault = { Enabled = false, Conn = nil }
    S_Util:AddToggle("v4 Anti Slow Vault", false, function(a)
        v4_AntiSlowVault.Enabled = a
        if a then
            if v4_AntiSlowVault.Conn then v4_AntiSlowVault.Conn:Disconnect() end
            for _, v in ipairs(v13:GetTagged("SlowVault")) do v13:RemoveTag(v, "SlowVault") end
            v4_AntiSlowVault.Conn = v13:GetInstanceAddedSignal("SlowVault"):Connect(function(inst)
                v13:RemoveTag(inst, "SlowVault")
            end)
        else
            if v4_AntiSlowVault.Conn then v4_AntiSlowVault.Conn:Disconnect() v4_AntiSlowVault.Conn = nil end
        end
    end, { Flag = "v4_AntiSlowVault" })

    -- [14] v4 Unlimited Vault
    local v4_UnlimVault = { Enabled = false, Conn = nil }
    S_Util:AddToggle("v4 Unlimited Vault", false, function(a)
        v4_UnlimVault.Enabled = a
        if a then
            if v4_UnlimVault.Conn then v4_UnlimVault.Conn:Disconnect() end
            for _, v in ipairs(v13:GetTagged("Blocked")) do v13:RemoveTag(v, "Blocked") end
            v4_UnlimVault.Conn = v13:GetInstanceAddedSignal("Blocked"):Connect(function(inst)
                v13:RemoveTag(inst, "Blocked")
            end)
        else
            if v4_UnlimVault.Conn then v4_UnlimVault.Conn:Disconnect() v4_UnlimVault.Conn = nil end
        end
    end, { Flag = "v4_UnlimVault" })

    -- [15] v4 Unblock All Vault (killer-side)
    S_Util:AddButton("v4 Unblock All Vault", function()
        local ev = v4_Rem("Remotes.Window.VaultCompleteEvent")
        local map = workspace:FindFirstChild("Map")
        if not ev or not map then return v4_Notif("v4 Unblock All Vault", "Missing") end
        local n = 0
        for _, t in ipairs(map:GetDescendants()) do
            if t.Name == "VaultPointInUse" and t.Parent then
                pcall(function() ev:FireServer(t.Parent, false) n = n + 1 end)
            end
        end
        v4_Notif("v4 Unblock All Vault", string.format("Unblocked %d", n))
    end)

    -- [16] v4 FOV Slider + Lock
    local v4_FOV = { Value = 70, Locked = false, Conn = nil }
    local function v4_SetFOV(v)
        local c = workspace.CurrentCamera
        if c then c.FieldOfView = v end
    end
    S_Util:AddSlider("v4 FOV", 40, 140, 70, function(v)
        v4_FOV.Value = v
        v4_SetFOV(v)
    end, { Increment = 1, Flag = "v4_FOV" })
    S_Util:AddToggle("v4 Lock FOV", false, function(a)
        v4_FOV.Locked = a
        if a then
            if v4_FOV.Conn then v4_FOV.Conn:Disconnect() end
            v4_SetFOV(v4_FOV.Value)
            v4_FOV.Conn = workspace.CurrentCamera:GetPropertyChangedSignal("FieldOfView"):Connect(function()
                if v4_FOV.Locked then v4_SetFOV(v4_FOV.Value) end
            end)
        else
            if v4_FOV.Conn then v4_FOV.Conn:Disconnect() v4_FOV.Conn = nil end
            v4_SetFOV(70)
        end
    end, { Flag = "v4_LockFOV" })

    -- [17] v4 Custom Cursor Toggle
    S_Util:AddToggle("v4 Custom Cursor", false, function(a)
        if v4_Lobby() then
            v4_Notif("v4 Cursor", "In lobby - skip")
            return
        end
        UserInputService.MouseIconEnabled = a
        UserInputService.MouseBehavior = a and Enum.MouseBehavior.Default or Enum.MouseBehavior.LockCenter
    end, { Flag = "v4_Cursor" })

    -- [18] v4 Max Zoom 1000
    S_Util:AddToggle("v4 Max Zoom 1000", false, function(a)
        if a then
            LocalPlayer.CameraMaxZoomDistance = 1000
            LocalPlayer.CameraMinZoomDistance = 0.5
        else
            LocalPlayer.CameraMaxZoomDistance = 128
            LocalPlayer.CameraMinZoomDistance = 0.5
        end
    end, { Flag = "v4_MaxZoom" })

    -- [19] v4 Camera Follow Body Movement
    local v4_CamFollow = { Enabled = false, Thread = nil }
    S_Util:AddToggle("v4 Camera Follow Body", false, function(a)
        v4_CamFollow.Enabled = a
        if a then
            local hum = v4_Hum()
            if hum then hum.AutoRotate = false end
            if v4_CamFollow.Thread then task.cancel(v4_CamFollow.Thread) end
            v4_CamFollow.Thread = task.spawn(function()
                while v4_CamFollow.Enabled do
                    local hrp = v4_Root()
                    if hrp then
                        local look = Camera.CFrame.LookVector
                        local ang = math.atan2(-look.X, -look.Z)
                        hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, ang, 0)
                    end
                    task.wait()
                end
            end)
        else
            if v4_CamFollow.Thread then task.cancel(v4_CamFollow.Thread) v4_CamFollow.Thread = nil end
            local hum = v4_Hum()
            if hum then hum.AutoRotate = true end
        end
    end, { Flag = "v4_CamFollow" })

    -- [20] v4 Manual Generator (No TP)
    local v4_ManualGen = { Enabled = false, Thread = nil, Point = nil }
    local function v4_GetAllGens()
        local out, map = {}, workspace:FindFirstChild("Map")
        if not map then return out end
        for _, m in ipairs(map:GetDescendants()) do
            if m:IsA("Model") and m.Name == "Generator" then
                if m:GetAttribute("RepairProgress") ~= nil or m:GetAttribute("ProgressRepair") ~= nil then
                    table.insert(out, m)
                end
            end
        end
        return out
    end
    local function v4_GenPoints(g)
        local pts = {}
        for _, o in ipairs(g:GetChildren()) do
            if o.Name:find("GeneratorPoint") and o:IsA("BasePart") then table.insert(pts, o) end
        end
        return pts
    end
    local function v4_KillerNear(pos, radius)
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Team and p.Team.Name == "Killer" and p.Character then
                local krp = p.Character:FindFirstChild("HumanoidRootPart")
                if krp and (krp.Position - pos).Magnitude <= radius then return true end
            end
        end
        return false
    end
    S_Util:AddToggle("v4 Manual Generator (No TP)", false, function(a)
        v4_ManualGen.Enabled = a
        local repair = v4_Rem("Remotes.Generator.RepairEvent")
        if not a then
            if v4_ManualGen.Thread then task.cancel(v4_ManualGen.Thread) v4_ManualGen.Thread = nil end
            if v4_ManualGen.Point and repair then
                pcall(function() repair:FireServer(v4_ManualGen.Point, false) end)
            end
            v4_ManualGen.Point = nil
            return
        end
        v4_ManualGen.Thread = task.spawn(function()
            local lastFire = 0
            while v4_ManualGen.Enabled do
                local hrp = v4_Root()
                if not hrp then task.wait(0.1) continue end
                if v4_KillerNear(hrp.Position, 30) then
                    if v4_ManualGen.Point and repair then
                        pcall(function() repair:FireServer(v4_ManualGen.Point, false) end)
                        v4_ManualGen.Point = nil
                    end
                    task.wait(0.3)
                    continue
                end
                local found = nil
                for _, g in ipairs(v4_GetAllGens()) do
                    for _, pt in ipairs(v4_GenPoints(g)) do
                        if (hrp.Position - pt.Position).Magnitude <= 5 then found = pt break end
                    end
                    if found then break end
                end
                if found then
                    v4_ManualGen.Point = found
                    if tick() - lastFire >= 0.5 and repair then
                        pcall(function() repair:FireServer(found, true) end)
                        lastFire = tick()
                    end
                elseif v4_ManualGen.Point and repair then
                    pcall(function() repair:FireServer(v4_ManualGen.Point, false) end)
                    v4_ManualGen.Point = nil
                end
                task.wait(0.1)
            end
        end)
    end, { Flag = "v4_ManualGen" })

    -- [21] v4 Auto Generator (With TP)
    local v4_AutoGenTP = { Enabled = false, Thread = nil, EscapeDist = 30 }
    local function v4_BestGen()
        local hrp = v4_Root()
        if not hrp then return nil end
        local best, bd = nil, math.huge
        for _, g in ipairs(v4_GetAllGens()) do
            local prog = g:GetAttribute("RepairProgress") or 0
            if prog < 100 then
                local pivot = g:GetPivot().Position
                if not v4_KillerNear(pivot, v4_AutoGenTP.EscapeDist) then
                    local d = (hrp.Position - pivot).Magnitude
                    if d < bd then bd = d best = g end
                end
            end
        end
        return best
    end
    local function v4_BestPoint(g)
        local hrp = v4_Root()
        if not hrp then return nil end
        local best, bd = nil, math.huge
        for _, pt in ipairs(v4_GenPoints(g)) do
            local d = (hrp.Position - pt.Position).Magnitude
            if d < bd then bd = d best = pt end
        end
        return best
    end
    S_Util:AddToggle("v4 Auto Generator (With TP)", false, function(a)
        v4_AutoGenTP.Enabled = a
        local repair = v4_Rem("Remotes.Generator.RepairEvent")
        if not a then
            if v4_AutoGenTP.Thread then task.cancel(v4_AutoGenTP.Thread) v4_AutoGenTP.Thread = nil end
            return
        end
        v4_AutoGenTP.Thread = task.spawn(function()
            local curPt, lastFire = nil, 0
            while v4_AutoGenTP.Enabled do
                local hrp = v4_Root()
                if not hrp or not repair then task.wait(0.1) continue end
                if v4_KillerNear(hrp.Position, v4_AutoGenTP.EscapeDist) then
                    if curPt then pcall(function() repair:FireServer(curPt, false) end) curPt = nil end
                    local g = v4_BestGen()
                    if g then
                        local pt = v4_BestPoint(g)
                        if pt then hrp.CFrame = CFrame.new(pt.Position + Vector3.new(0, 2, 0)) end
                    end
                    task.wait(0.15)
                    continue
                end
                local g = v4_BestGen()
                if g then
                    local pt = v4_BestPoint(g)
                    if pt and (hrp.Position - pt.Position).Magnitude > 5 then
                        hrp.CFrame = CFrame.new(pt.Position + Vector3.new(0, 2, 0))
                        task.wait(0.15)
                        continue
                    end
                    if pt then
                        curPt = pt
                        if tick() - lastFire >= 0.5 then
                            pcall(function() repair:FireServer(pt, true) end)
                            lastFire = tick()
                        end
                    end
                end
                task.wait(0.1)
            end
            if curPt and repair then pcall(function() repair:FireServer(curPt, false) end) end
        end)
    end, { Flag = "v4_AutoGenTP" })
    S_Util:AddSlider("v4 Auto Gen Escape Distance", 10, 100, 30, function(v)
        v4_AutoGenTP.EscapeDist = v
    end, { Increment = 5, Flag = "v4_AutoGenEscape" })

    -- [22] v4 Fake Parry (anim only)
    local v4_FakeParry = {
        Enabled = false,
        Anim = "Enten",
        Anims = {
            Enten       = "rbxassetid://127096285501517",
            Stopwatch   = "rbxassetid://81793464499285",
            Fih         = "rbxassetid://123307242865945",
            BloodShield = "rbxassetid://75939529748815",
        },
        Track = nil,
        Keybind = Enum.KeyCode.G,
    }
    local function v4_PlayFakeParry()
        local hum = v4_Hum()
        if not hum then return end
        local animator = hum:FindFirstChildOfClass("Animator")
        if not animator then animator = Instance.new("Animator", hum) end
        if v4_FakeParry.Track then pcall(function() v4_FakeParry.Track:Stop() end) end
        local a = Instance.new("Animation")
        a.AnimationId = v4_FakeParry.Anims[v4_FakeParry.Anim] or v4_FakeParry.Anims.Enten
        v4_FakeParry.Track = animator:LoadAnimation(a)
        v4_FakeParry.Track.Priority = Enum.AnimationPriority.Action
        v4_FakeParry.Track:Play()
    end
    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == v4_FakeParry.Keybind and v4_FakeParry.Enabled then
            v4_PlayFakeParry()
        end
    end)
    S_Util:AddToggle("v4 Fake Parry (Anim)", false, function(a)
        v4_FakeParry.Enabled = a
        v4_Notif("v4 Fake Parry", a and "ON" or "OFF")
    end, { Flag = "v4_FakeParry" })
    S_Util:AddDropdown("v4 Fake Parry Anim", {"Enten","Stopwatch","Fih","BloodShield"}, false, function(opt)
        v4_FakeParry.Anim = opt
    end, { Flag = "v4_FakeParryAnim" })
    S_Util:AddTextbox("v4 Fake Parry Keybind", "G", function(txt)
        txt = tostring(txt or ""):gsub("%s+", "")
        if txt == "" then return end
        local ok, kc = pcall(function()
            return Enum.KeyCode[txt:upper():sub(1,1) .. txt:lower():sub(2)]
        end)
        if ok and kc then v4_FakeParry.Keybind = kc end
    end)

    -- [23] v4 Auto Vault (PC + Mobile)
    local v4_AutoVault = { Enabled = false, Last = 0, CD = 1.5 }
    task.spawn(function()
        while _G.Ox.ScriptAlive do
            if v4_AutoVault.Enabled and not UserInputService.TouchEnabled then
                if tick() - v4_AutoVault.Last >= v4_AutoVault.CD then
                    local pg = PlayerGui:FindFirstChild("pcprompts")
                    local fr = pg and pg:FindFirstChild("Frame")
                    if fr then
                        local vp = fr:FindFirstChild("VaultPromptGui")
                        local pp = fr:FindFirstChild("PalletSlidePromptGui")
                        if (vp and vp.Visible) or (pp and pp.Visible) then
                            VIM:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                            task.wait(0.01)
                            VIM:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                            v4_AutoVault.Last = tick()
                        end
                    end
                end
            end
            task.wait(0.1)
        end
    end)
    S_Util:AddToggle("v4 Auto Vault", false, function(a)
        v4_AutoVault.Enabled = a
    end, { Flag = "v4_AutoVault" })

    -- ============================================================
    -- TAB: v4 Killer
    -- ============================================================
    local KTab  = v2:CreateTab("v4 Killer", false, false)
    local KPage = KTab:CreatePage("v4 Killer")

    -- ---- Abilities ----
    local K_Abil = KPage:CreateSection("v4 Killer Abilities", "sword")

    -- [24] v4 Infinite Frenzy
    local v4_InfFrenzy = { Enabled = false, Thread = nil }
    K_Abil:AddToggle("v4 Infinite Frenzy (Jeff)", false, function(a)
        v4_InfFrenzy.Enabled = a
        if a then
            if v4_InfFrenzy.Thread then return end
            v4_InfFrenzy.Thread = task.spawn(function()
                while v4_InfFrenzy.Enabled do
                    pcall(function()
                        local c = LocalPlayer.Character
                        if c and c:GetAttribute("Frenzy") ~= true then c:SetAttribute("Frenzy", true) end
                    end)
                    task.wait(0.1)
                end
                v4_InfFrenzy.Thread = nil
            end)
        else
            pcall(function()
                local c = LocalPlayer.Character
                if c and c:GetAttribute("Frenzy") == true then
                    c:SetAttribute("Frenzy", false)
                    local d = v4_Rem("Remotes.Killers.Killer.Deactivatefromclient")
                    if d then d:FireServer() end
                end
            end)
        end
    end, { Flag = "v4_InfFrenzy" })

    -- [25] v4 Infinite Pursuit
    local v4_InfPursuit = { Enabled = false, Thread = nil }
    K_Abil:AddToggle("v4 Infinite Pursuit (Jason)", false, function(a)
        v4_InfPursuit.Enabled = a
        if a then
            if v4_InfPursuit.Thread then return end
            v4_InfPursuit.Thread = task.spawn(function()
                while v4_InfPursuit.Enabled do
                    pcall(function()
                        local c = LocalPlayer.Character
                        if c and c:GetAttribute("Pursuit") ~= true then c:SetAttribute("Pursuit", true) end
                    end)
                    task.wait(0.1)
                end
                v4_InfPursuit.Thread = nil
            end)
        else
            pcall(function()
                local c = LocalPlayer.Character
                if c and c:GetAttribute("Pursuit") == true then
                    c:SetAttribute("Pursuit", false)
                    local d = v4_Rem("Remotes.Killers.Jason.Deactivatefromclient")
                    if d then d:FireServer() end
                end
            end)
        end
    end, { Flag = "v4_InfPursuit" })

    -- [26] v4 Infinite Lunge
    local v4_InfLunge = { Enabled = false, Conn = nil }
    K_Abil:AddToggle("v4 Infinite Lunge", false, function(a)
        v4_InfLunge.Enabled = a
        local c = LocalPlayer.Character
        if a then
            if c then
                c:SetAttribute("lungeboost", 999)
                if v4_InfLunge.Conn then v4_InfLunge.Conn:Disconnect() end
                v4_InfLunge.Conn = c:GetAttributeChangedSignal("lungeboost"):Connect(function()
                    if v4_InfLunge.Enabled and c:GetAttribute("lungeboost") ~= 999 then
                        c:SetAttribute("lungeboost", 999)
                    end
                end)
            end
        else
            if v4_InfLunge.Conn then v4_InfLunge.Conn:Disconnect() v4_InfLunge.Conn = nil end
            if c then c:SetAttribute("lungeboost", 1) end
        end
    end, { Flag = "v4_InfLunge" })
    LocalPlayer.CharacterAdded:Connect(function(c)
        task.wait(0.8)
        if v4_InfLunge.Enabled and c then c:SetAttribute("lungeboost", 999) end
    end)

    -- [27] v4 Bypass Cooldown (Abyss)
    local v4_BypassAbyss = { Enabled = false, Conn = nil, Func = nil }
    K_Abil:AddToggle("v4 Bypass Cooldown (Abyss)", false, function(a)
        v4_BypassAbyss.Enabled = a
        if a then
            if not v4_BypassAbyss.Func then
                for _, vv in pairs(getgc(true)) do
                    if type(vv) == "function" and islclosure(vv) then
                        local cs = debug.getconstants(vv)
                        if table.find(cs, "corrupt") and table.find(cs, "Immobile") then
                            v4_BypassAbyss.Func = vv
                            break
                        end
                    end
                end
            end
            if not v4_BypassAbyss.Func then
                v4_Notif("v4 Bypass Abyss", "corruptHandler missing")
                return
            end
            if v4_BypassAbyss.Conn then v4_BypassAbyss.Conn:Disconnect() end
            v4_BypassAbyss.Conn = RunService.Heartbeat:Connect(function()
                if not v4_BypassAbyss.Enabled then return end
                local ups = debug.getupvalues(v4_BypassAbyss.Func)
                for i, v in pairs(ups) do
                    if type(v) == "boolean" and v == false then
                        debug.setupvalue(v4_BypassAbyss.Func, i, true)
                    end
                end
            end)
        else
            if v4_BypassAbyss.Conn then v4_BypassAbyss.Conn:Disconnect() v4_BypassAbyss.Conn = nil end
        end
    end, { Flag = "v4_BypassAbyss" })

    -- [28] v4 Bypass Cooldown (Hidden)
    local v4_BypassHidden = { Enabled = false, Thread = nil }
    K_Abil:AddToggle("v4 Bypass Cooldown (Hidden)", false, function(a)
        v4_BypassHidden.Enabled = a
        if a then
            if v4_BypassHidden.Thread then task.cancel(v4_BypassHidden.Thread) end
            v4_BypassHidden.Thread = task.spawn(function()
                local leapF, m2F
                for _, vv in pairs(getgc(true)) do
                    if type(vv) == "function" and islclosure(vv) then
                        local info = debug.getinfo(vv)
                        if info.name == "tryActivate" then leapF = vv end
                        if info.name == "playM2Animation" then m2F = vv end
                    end
                end
                if not leapF and not m2F then
                    warn("[v4 Bypass Hidden] funcs not found")
                    return
                end
                while v4_BypassHidden.Enabled do
                    for _, fn in ipairs({ leapF, m2F }) do
                        if fn then
                            for i, val in pairs(debug.getupvalues(fn)) do
                                if type(val) == "boolean" and val == true then
                                    debug.setupvalue(fn, i, false)
                                end
                            end
                        end
                    end
                    task.wait(0.1)
                end
            end)
        end
    end, { Flag = "v4_BypassHidden" })

    -- [29] v4 Bypass Carry
    local v4_BypassCarry = { Enabled = false, Hooked = false }
    if not v4_BypassCarry.Hooked then
        local mt = getrawmetatable(game)
        local old = mt.__namecall
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            if v4_BypassCarry.Enabled and getnamecallmethod() == "GetAttribute" and not checkcaller() then
                if select(1, ...) == "IsCarrying" then return false end
            end
            return old(self, ...)
        end)
        setreadonly(mt, true)
        v4_BypassCarry.Hooked = true
    end
    K_Abil:AddToggle("v4 Bypass Carry", false, function(a)
        v4_BypassCarry.Enabled = a
        v4_Notif("v4 Bypass Carry", a and "ON" or "OFF")
    end, { Flag = "v4_BypassCarry" })

    -- [30] v4 No Slowdown Killer
    local v4_NoSlow = { Enabled = false, Conn = nil }
    K_Abil:AddToggle("v4 No Slowdown Killer", false, function(a)
        v4_NoSlow.Enabled = a
        if a then
            if v4_NoSlow.Conn then v4_NoSlow.Conn:Disconnect() end
            v4_NoSlow.Conn = RunService.Heartbeat:Connect(function()
                if not v4_NoSlow.Enabled then return end
                local hum = v4_Hum()
                if hum and v4_Killer() and hum.WalkSpeed < 16 then
                    pcall(function() hum.WalkSpeed = 16 end)
                end
            end)
        else
            if v4_NoSlow.Conn then v4_NoSlow.Conn:Disconnect() v4_NoSlow.Conn = nil end
        end
    end, { Flag = "v4_NoSlow" })

    -- [31] v4 Auto Stalk (Myers)
    local v4_AutoStalk = { Enabled = false, Conn = nil, Range = 150, Last = 0 }
    K_Abil:AddToggle("v4 Auto Stalk (Myers)", false, function(a)
        v4_AutoStalk.Enabled = a
        if a then
            if v4_AutoStalk.Conn then return end
            v4_AutoStalk.Conn = RunService.Heartbeat:Connect(function()
                if not v4_AutoStalk.Enabled or not v4_Killer() then return end
                if tick() - v4_AutoStalk.Last < 0.35 then return end
                local hrp = v4_Root()
                if not hrp then return end
                local best, bd = nil, v4_AutoStalk.Range
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character then
                        local hum = p.Character:FindFirstChildOfClass("Humanoid")
                        local tr = p.Character:FindFirstChild("HumanoidRootPart")
                        if hum and tr and hum.Health > 30 then
                            local d = (tr.Position - hrp.Position).Magnitude
                            if d <= bd then bd = d best = p end
                        end
                    end
                end
                if best then
                    local ev = v4_Rem("Remotes.Killers.Stalker.StartStalking")
                    if ev then
                        v4_AutoStalk.Last = tick()
                        pcall(function() ev:FireServer(best) end)
                    end
                end
            end)
        else
            if v4_AutoStalk.Conn then v4_AutoStalk.Conn:Disconnect() v4_AutoStalk.Conn = nil end
        end
    end, { Flag = "v4_AutoStalk" })

    -- [32] v4 Anti Blind
    local v4_AntiBlind = { Enabled = false, Remote = nil }
    task.spawn(function()
        local r = v4_Rem("Remotes.Items.Flashlight.GotBlinded")
        v4_AntiBlind.Remote = r
    end)
    local mt = getrawmetatable(game)
    local oldNC = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        if v4_AntiBlind.Enabled and v4_AntiBlind.Remote and self == v4_AntiBlind.Remote
           and v4_Killer() and not checkcaller() then
            return nil
        end
        return oldNC(self, ...)
    end)
    setreadonly(mt, true)
    K_Abil:AddToggle("v4 Anti Blind (Flashlight)", false, function(a)
        v4_AntiBlind.Enabled = a
    end, { Flag = "v4_AntiBlind" })

    -- [33] v4 Counter Auto Parry
    local v4_CounterParry = { Enabled = false, Thread = nil, Dist = 15, Track = nil }
    local v4_CounterParryAnim = "rbxassetid://117042998468241"
    K_Abil:AddToggle("v4 Counter Auto Parry", false, function(a)
        if a and not v4_Killer() then
            v4_Notif("v4 Counter Auto Parry", "Need Killer")
            return
        end
        v4_CounterParry.Enabled = a
        if a then
            if v4_CounterParry.Thread then task.cancel(v4_CounterParry.Thread) end
            v4_CounterParry.Thread = task.spawn(function()
                while v4_CounterParry.Enabled do
                    local c = LocalPlayer.Character
                    local hrp = c and c:FindFirstChild("HumanoidRootPart")
                    local hum = c and c:FindFirstChildOfClass("Humanoid")
                    local animator = hum and hum:FindFirstChildOfClass("Animator")
                    if hrp and animator then
                        local near = false
                        for _, p in ipairs(Players:GetPlayers()) do
                            if p ~= LocalPlayer and p.Team and p.Team.Name == "Survivors" and p.Character then
                                local tr = p.Character:FindFirstChild("HumanoidRootPart")
                                if tr and (tr.Position - hrp.Position).Magnitude <= v4_CounterParry.Dist then
                                    near = true break
                                end
                            end
                        end
                        if near then
                            if not v4_CounterParry.Track then
                                local a2 = Instance.new("Animation")
                                a2.AnimationId = v4_CounterParryAnim
                                v4_CounterParry.Track = animator:LoadAnimation(a2)
                            end
                            pcall(function()
                                v4_CounterParry.Track:Play()
                                v4_CounterParry.Track:AdjustWeight(0)
                            end)
                            task.wait(0.05)
                            pcall(function() v4_CounterParry.Track:Stop() end)
                        end
                    end
                    task.wait(0.3)
                end
            end)
        else
            if v4_CounterParry.Thread then task.cancel(v4_CounterParry.Thread) v4_CounterParry.Thread = nil end
        end
    end, { Flag = "v4_CounterParry" })

    -- [34] v4 Anti Break Pallet
    local v4_AntiPallet = { Enabled = false, Conn = nil }
    K_Abil:AddToggle("v4 Anti Break Pallet", false, function(a)
        v4_AntiPallet.Enabled = a
        if a then
            if v4_AntiPallet.Conn then v4_AntiPallet.Conn:Disconnect() end
            v4_AntiPallet.Conn = RunService.Heartbeat:Connect(function()
                if not v4_AntiPallet.Enabled then return end
                local c = LocalPlayer.Character
                local hum = c and c:FindFirstChildOfClass("Humanoid")
                if not c or not hum then return end
                if c:GetAttribute("IsStunned") or hum.WalkSpeed < 3 then
                    local so = v4_Rem("Remotes.Pallet.Jason.Stunover")
                    if so then pcall(function() so:FireServer() end) end
                    c:SetAttribute("Immobile", false)
                    c:SetAttribute("IsStunned", false)
                    hum.WalkSpeed = c:GetAttribute("Speed") or 16
                end
            end)
        else
            if v4_AntiPallet.Conn then v4_AntiPallet.Conn:Disconnect() v4_AntiPallet.Conn = nil end
        end
    end, { Flag = "v4_AntiPallet" })

    -- [35] v4 Block All Vault
    K_Abil:AddButton("v4 Block All Vault", function()
        local ev = v4_Rem("Remotes.Window.VaultEvent")
        local map = workspace:FindFirstChild("Map")
        if not ev or not map then return v4_Notif("v4 Block Vault", "Missing") end
        local n = 0
        for _, t in ipairs(map:GetDescendants()) do
            if t.Name == "VaultTrigger" then
                pcall(function() ev:FireServer(t, true) n = n + 1 end)
            end
        end
        v4_Notif("v4 Block Vault", string.format("Blocked %d", n))
    end)

    -- [36] v4 Unblock All Vault
    K_Abil:AddButton("v4 Unblock All Vault", function()
        local ev = v4_Rem("Remotes.Window.VaultCompleteEvent")
        local map = workspace:FindFirstChild("Map")
        if not ev or not map then return v4_Notif("v4 Unblock Vault", "Missing") end
        local n = 0
        for _, t in ipairs(map:GetDescendants()) do
            if t.Name == "VaultPointInUse" and t.Parent then
                pcall(function() ev:FireServer(t.Parent, false) n = n + 1 end)
            end
        end
        v4_Notif("v4 Unblock Vault", string.format("Unblocked %d", n))
    end)

    -- [37] v4 No Flashlight (Killer)
    local v4_NoFlash = { Enabled = false }
    K_Abil:AddToggle("v4 No Flashlight (Anti Blind)", false, function(a)
        v4_NoFlash.Enabled = a
        if a then
            task.spawn(function()
                while v4_NoFlash.Enabled do
                    local pg = LocalPlayer:FindFirstChild("PlayerGui")
                    if pg then
                        for _, d in ipairs(pg:GetDescendants()) do
                            if d:IsA("GuiObject") and d.Name == "Blind" then d:Destroy() end
                        end
                    end
                    task.wait(0.5)
                end
            end)
        end
    end, { Flag = "v4_NoFlash" })

    -- ---- Offensive ----
    local K_Off = KPage:CreateSection("v4 Offensive", "crosshair")

    -- [38] v4 Auto Attack (No Anim)
    local v4_AutoAtk = { Enabled = false, Range = 12, Thread = nil }
    K_Off:AddToggle("v4 Auto Attack (No Anim)", false, function(a)
        v4_AutoAtk.Enabled = a
        if a then
            if v4_AutoAtk.Thread then return end
            local r = v4_Rem("Remotes.Attacks.BasicAttack")
            v4_AutoAtk.Thread = task.spawn(function()
                while v4_AutoAtk.Enabled do
                    local root = v4_Root()
                    if root and r then
                        for _, p in ipairs(Players:GetPlayers()) do
                            if p ~= LocalPlayer and p.Character then
                                local tr = p.Character:FindFirstChild("HumanoidRootPart")
                                local h = p.Character:FindFirstChildOfClass("Humanoid")
                                if tr and h and h.Health > 0 and
                                   (tr.Position - root.Position).Magnitude <= v4_AutoAtk.Range then
                                    pcall(function() r:FireServer(false) end)
                                    break
                                end
                            end
                        end
                    end
                    task.wait(0.1)
                end
                v4_AutoAtk.Thread = nil
            end)
        end
    end, { Flag = "v4_AutoAtk" })
    K_Off:AddSlider("v4 Auto Attack Range", 5, 30, 12, function(v)
        v4_AutoAtk.Range = v
    end, { Increment = 1, Flag = "v4_AutoAtkRange" })

    -- [39] v4 Kill All Instant
    local v4_KillAll = { Enabled = false, Thread = nil }
    K_Off:AddToggle("v4 Kill All Instant", false, function(a)
        v4_KillAll.Enabled = a
        if a then
            if v4_KillAll.Thread then return end
            local r = v4_Rem("Remotes.Attacks.BasicAttack")
            v4_KillAll.Thread = task.spawn(function()
                while v4_KillAll.Enabled do
                    if v4_Lobby() then task.wait(0.5) continue end
                    local root = v4_Root()
                    if root and r then
                        for _, p in ipairs(Players:GetPlayers()) do
                            if p ~= LocalPlayer and p.Character and not (p.Team and p.Team.Name == "Spectator") then
                                local pc = p.Character
                                local tr = pc:FindFirstChild("HumanoidRootPart")
                                local knocked = pc:GetAttribute("Knocked") or pc:GetAttribute("IsKnocked")
                                if tr and not knocked then
                                    root.CFrame = tr.CFrame * CFrame.new(0, 0, 2)
                                    pcall(function() r:FireServer() end)
                                    task.wait(0.15)
                                end
                            end
                        end
                    end
                    task.wait(0.2)
                end
                v4_KillAll.Thread = nil
            end)
        end
    end, { Flag = "v4_KillAll" })

    -- [40] v4 Auto Hook
    local v4_AutoHook = { Enabled = false, Thread = nil, Busy = false }
    K_Off:AddToggle("v4 Auto Hook", false, function(a)
        v4_AutoHook.Enabled = a
        if a then
            if v4_AutoHook.Thread then return end
            v4_AutoHook.Thread = task.spawn(function()
                while v4_AutoHook.Enabled do
                    if not v4_AutoHook.Busy and v4_Killer() then
                        local root = v4_Root()
                        if root then
                            local hooks = {}
                            local map = workspace:FindFirstChild("Map") or workspace
                            for _, o in ipairs(map:GetDescendants()) do
                                if o.Name == "Hook" and o:IsA("Model") then
                                    local hp = o:FindFirstChild("HookPoint")
                                    if hp then table.insert(hooks, { model = o, part = hp }) end
                                end
                            end
                            local best, bd, bestChar = nil, math.huge, nil
                            for _, p in ipairs(Players:GetPlayers()) do
                                if p ~= LocalPlayer and p.Character and p.Team and p.Team.Name == "Survivors" then
                                    local tr = p.Character:FindFirstChild("HumanoidRootPart")
                                    local h = p.Character:FindFirstChildOfClass("Humanoid")
                                    if tr and h then
                                        local pct = h.MaxHealth > 0 and (h.Health / h.MaxHealth) or 0
                                        if pct > 0 and pct <= 0.25 and not p.Character:GetAttribute("IsCarried") then
                                            local d = (tr.Position - root.Position).Magnitude
                                            if d < bd then bd = d best = tr bestChar = p.Character end
                                        end
                                    end
                                end
                            end
                            if best and #hooks > 0 then
                                local nh, nd = nil, math.huge
                                for _, h in ipairs(hooks) do
                                    local d = (h.part.Position - best.Position).Magnitude
                                    if d < nd then nd = d nh = h end
                                end
                                if nh then
                                    v4_AutoHook.Busy = true
                                    task.spawn(function()
                                        local carry = v4_Rem("Remotes.Carry")
                                        if not carry then v4_AutoHook.Busy = false return end
                                        pcall(function() root.CFrame = CFrame.new(best.Position + Vector3.new(0, 3, 0), best.Position) end)
                                        task.wait(0.2)
                                        pcall(function() carry.CarrySurvivorEvent:FireServer(bestChar) end)
                                        task.wait(0.5)
                                        local r2 = v4_Root()
                                        if r2 then
                                            pcall(function() r2.CFrame = CFrame.new(nh.part.Position + Vector3.new(0, 3, 0)) end)
                                            task.wait(0.3)
                                            pcall(function()
                                                local hp = nh.model:FindFirstChild("HookPoint")
                                                    or nh.model:FindFirstChild("HookHitbox")
                                                    or nh.part
                                                carry.HookEvent:FireServer(hp)
                                            end)
                                            task.wait(1)
                                        end
                                        v4_AutoHook.Busy = false
                                    end)
                                end
                            end
                        end
                    end
                    task.wait(1)
                end
                v4_AutoHook.Thread = nil
            end)
        end
    end, { Flag = "v4_AutoHook" })

    -- ============================================================
    -- TAB: v4 Visual / Settings
    -- ============================================================
    local VTab  = v2:CreateTab("v4 Settings", false, false)
    local VPage = VTab:CreatePage("v4 Settings")

    local V_Perf = VPage:CreateSection("v4 Performance", "sliders-vertical")

    -- [41] v4 Potato Mode (aggressive)
    local v4_Potato = {
        Enabled = false,
        Conn = nil,
        Processed = setmetatable({}, { __mode = "k" }),
    }
    local function v4_OptimizeObj(obj)
        if v4_Potato.Processed[obj] then return end
        v4_Potato.Processed[obj] = true
        local cls = obj.ClassName
        if cls == "ParticleEmitter" or cls == "Trail" or cls == "Beam" or
           cls == "Fire" or cls == "Smoke" or cls == "Sparkles" or
           cls == "ForceField" or cls == "Explosion" or
           cls == "BloomEffect" or cls == "BlurEffect" or
           cls == "ColorCorrectionEffect" or cls == "SunRaysEffect" or
           cls == "DepthOfFieldEffect" or cls == "Atmosphere" or
           cls == "Decal" or cls == "Texture" or cls == "SurfaceAppearance" or
           cls == "PointLight" or cls == "SpotLight" or cls == "SurfaceLight" or
           cls == "Accessory" or cls == "Shirt" or cls == "Pants" or
           cls == "ShirtGraphic" or cls == "CharacterMesh" or cls == "BodyColors" then
            pcall(function() obj:Destroy() end)
            return
        end
        if obj:IsA("BasePart") then
            pcall(function()
                obj.Material = Enum.Material.SmoothPlastic
                obj.CastShadow = false
                obj.Reflectance = 0
            end)
        end
    end
    V_Perf:AddToggle("v4 Potato Mode", false, function(a)
        v4_Potato.Enabled = a
        if not a then
            if v4_Potato.Conn then v4_Potato.Conn:Disconnect() v4_Potato.Conn = nil end
            return
        end
        task.spawn(function()
            local all = workspace:GetDescendants()
            for i, o in ipairs(all) do
                if not v4_Potato.Enabled then break end
                v4_OptimizeObj(o)
                if i % 100 == 0 then task.wait() end
            end
        end)
        if v4_Potato.Conn then v4_Potato.Conn:Disconnect() end
        v4_Potato.Conn = workspace.DescendantAdded:Connect(function(o)
            if v4_Potato.Enabled then
                task.defer(function() v4_OptimizeObj(o) end)
            end
        end)
        v4_Notif("v4 Potato Mode", "ON")
    end, { Flag = "v4_Potato" })

    -- [42] v4 Max FPS
    V_Perf:AddToggle("v4 Max FPS (9999)", false, function(a)
        if a and setfpscap then
            pcall(function() setfpscap(9999) end)
        elseif setfpscap then
            pcall(function() setfpscap(240) end)
        end
    end, { Flag = "v4_MaxFPS" })

    -- [43] v4 Low Graphics Mode (attribute)
    V_Perf:AddToggle("v4 Low Graphics Mode", false, function(a)
        LocalPlayer:SetAttribute("lowGraphics", a)
    end, { Flag = "v4_LowGfx" })

    -- [44] v4 Remove Dynamic Shadow
    V_Perf:AddToggle("v4 Remove Dynamic Shadow", false, function(a)
        pcall(function()
            game:GetService("Lighting").GlobalShadows = not a
        end)
    end, { Flag = "v4_NoShadow2" })

    -- [45] v4 Full Bright
    V_Perf:AddToggle("v4 Full Bright", false, function(a)
        local L = game:GetService("Lighting")
        if a then
            L.Ambient = Color3.fromRGB(255, 255, 255)
            L.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
            L.Brightness = 3
            L.ClockTime = 14
        else
            L.Brightness = 1
            L.ClockTime = 14
        end
    end, { Flag = "v4_FullBright2" })

    -- [46] v4 No Fog
    V_Perf:AddToggle("v4 No Fog", false, function(a)
        local L = game:GetService("Lighting")
        if a then
            L.FogStart = 999999
            L.FogEnd = 999999
            local atm = L:FindFirstChildOfClass("Atmosphere")
            if atm then atm.Density = 0 end
        else
            L.FogStart = 0
            L.FogEnd = 1000
        end
    end, { Flag = "v4_NoFog2" })

    -- ============================================================
    -- TAB: v4 Visual / ESP Extras
    -- ============================================================
    local EExtra = VPage:CreateSection("v4 Extra Visual", "eye")

    -- [47] v4 Spectator Counter
    local v4_Spect = { Enabled = false, Gui = nil, Label = nil, Thread = nil }
    EExtra:AddToggle("v4 Spectator Counter", false, function(a)
        v4_Spect.Enabled = a
        if a then
            if v4_Spect.Gui then v4_Spect.Gui:Destroy() end
            v4_Spect.Gui = Instance.new("ScreenGui")
            v4_Spect.Gui.Name = "v4_SpectatorGui"
            v4_Spect.Gui.ResetOnSpawn = false
            v4_Spect.Gui.Parent = CoreGui
            local f = Instance.new("Frame", v4_Spect.Gui)
            f.Size = UDim2.new(0, 160, 0, 34)
            f.Position = UDim2.new(0.5, -80, 0, 10)
            f.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
            f.BackgroundTransparency = 0.2
            f.BorderSizePixel = 0
            Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)
            local st = Instance.new("UIStroke", f)
            st.Color = Color3.fromRGB(60, 150, 255)
            st.Thickness = 1.5
            local ic = Instance.new("ImageLabel", f)
            ic.Size = UDim2.new(0, 18, 0, 18)
            ic.Position = UDim2.new(0, 8, 0.5, -9)
            ic.BackgroundTransparency = 1
            ic.Image = "rbxassetid://13321848320"
            ic.ImageColor3 = Color3.fromRGB(220, 220, 240)
            v4_Spect.Label = Instance.new("TextLabel", f)
            v4_Spect.Label.Size = UDim2.new(1, -34, 1, 0)
            v4_Spect.Label.Position = UDim2.new(0, 28, 0, 0)
            v4_Spect.Label.BackgroundTransparency = 1
            v4_Spect.Label.Font = Enum.Font.GothamMedium
            v4_Spect.Label.TextSize = 12
            v4_Spect.Label.TextXAlignment = Enum.TextXAlignment.Left
            v4_Spect.Label.TextColor3 = Color3.fromRGB(230, 230, 240)
            v4_Spect.Label.Text = "Spectators: 0"
            if v4_Spect.Thread then task.cancel(v4_Spect.Thread) end
            v4_Spect.Thread = task.spawn(function()
                while v4_Spect.Enabled do
                    local n = 0
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p.Team and p.Team.Name == "Spectator" then n = n + 1 end
                    end
                    if v4_Spect.Label then v4_Spect.Label.Text = "Spectators: " .. n end
                    task.wait(1.2)
                end
            end)
        else
            if v4_Spect.Gui then v4_Spect.Gui:Destroy() v4_Spect.Gui = nil end
            v4_Spect.Label = nil
            if v4_Spect.Thread then task.cancel(v4_Spect.Thread) v4_Spect.Thread = nil end
        end
    end, { Flag = "v4_Spectator" })

    -- [48] v4 Next Killer Display
    local v4_NextK = { Enabled = false, Gui = nil, Label = nil }
    EExtra:AddToggle("v4 Next Killer Display", false, function(a)
        v4_NextK.Enabled = a
        if not a then
            if v4_NextK.Gui then v4_NextK.Gui:Destroy() v4_NextK.Gui = nil v4_NextK.Label = nil end
            return
        end
        v4_NextK.Gui = Instance.new("ScreenGui")
        v4_NextK.Gui.Name = "v4_NextKiller"
        v4_NextK.Gui.ResetOnSpawn = false
        v4_NextK.Gui.Parent = CoreGui
        local l = Instance.new("TextLabel", v4_NextK.Gui)
        l.Size = UDim2.new(0, 220, 0, 26)
        l.Position = UDim2.new(0.5, -110, 0, 48)
        l.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
        l.BackgroundTransparency = 0.15
        l.BorderSizePixel = 0
        l.Font = Enum.Font.GothamBold
        l.TextSize = 12
        l.TextColor3 = Color3.fromRGB(255, 220, 220)
        l.RichText = true
        l.Text = "Next Killer: <font color='#888888'>...</font>"
        Instance.new("UICorner", l).CornerRadius = UDim.new(0, 6)
        v4_NextK.Label = l
        task.spawn(function()
            while v4_NextK.Enabled do
                local best, bc = nil, -math.huge
                for _, p in ipairs(Players:GetPlayers()) do
                    local chance = p:GetAttribute("KillerChance") or 0
                    if chance > bc then bc = chance best = p end
                end
                if best and v4_NextK.Label then
                    local nm = best == LocalPlayer and "<font color='#ff5555'>YOU</font>" or best.Name
                    v4_NextK.Label.Text = "Next Killer: " .. nm
                end
                task.wait(1.5)
            end
        end)
    end, { Flag = "v4_NextKiller" })

    -- [49] v4 Next Map Prediction
    local v4_NextMap = { Enabled = false, Gui = nil, Label = nil }
    local function v4_DetectMap()
        local m = workspace:FindFirstChild("Map")
        if not m then return nil end
        if m:FindFirstChild("random shakes") or m:FindFirstChild("SCP-173 Room") or m:FindFirstChild("SCP-205 Room") then return "Site 68" end
        if m:FindFirstChild("HooksMeat") then return "BLOODBATH! Club" end
        if m:FindFirstChild("Gate") and m.Gate:FindFirstChild("vfx") then return "Firelink Shrine" end
        if m:FindFirstChild("Bldg_Addon_RooftopUnit_A") or m:FindFirstChild("Rooftop") then return "Mercy Hospital Rooftop" end
        if m:FindFirstChild("White Armored Car") then return "Mount Massive Asylum" end
        if m:FindFirstChild("Dumbster") then return "The Bay Harbor" end
        if m:FindFirstChild("water pump") then return "Valdelobos Village" end
        if m:FindFirstChild("LargeBoulder01") then return "Woodview Cabin" end
        return nil
    end
    EExtra:AddToggle("v4 Next Map Predict", false, function(a)
        v4_NextMap.Enabled = a
        if not a then
            if v4_NextMap.Gui then v4_NextMap.Gui:Destroy() v4_NextMap.Gui = nil v4_NextMap.Label = nil end
            return
        end
        v4_NextMap.Gui = Instance.new("ScreenGui")
        v4_NextMap.Gui.Name = "v4_NextMap"
        v4_NextMap.Gui.ResetOnSpawn = false
        v4_NextMap.Gui.Parent = CoreGui
        local l = Instance.new("TextLabel", v4_NextMap.Gui)
        l.Size = UDim2.new(0, 220, 0, 26)
        l.Position = UDim2.new(0.5, -110, 0, 78)
        l.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
        l.BackgroundTransparency = 0.15
        l.BorderSizePixel = 0
        l.Font = Enum.Font.GothamBold
        l.TextSize = 12
        l.TextColor3 = Color3.fromRGB(220, 240, 255)
        l.RichText = true
        l.Text = "Next Map: <font color='#888888'>...</font>"
        Instance.new("UICorner", l).CornerRadius = UDim.new(0, 6)
        v4_NextMap.Label = l
        task.spawn(function()
            local last, existed = nil, false
            while v4_NextMap.Enabled do
                local exists = workspace:FindFirstChild("Map") ~= nil
                local detected = v4_DetectMap()
                local isSpec = v4_Lobby()
                if v4_NextMap.Label then
                    if existed and not exists and last then
                        v4_NextMap.Label.Text = "Next Map: " .. last
                    elseif exists and detected then
                        last = detected
                        v4_NextMap.Label.Text = "Next Map: " .. detected
                    elseif exists then
                        v4_NextMap.Label.Text = "Next Map: Unknown"
                    else
                        v4_NextMap.Label.Text = "Next Map: <font color='#888888'>...</font>"
                    end
                end
                existed = exists
                task.wait(0.5)
            end
        end)
    end, { Flag = "v4_NextMap" })

    -- [50] v4 Killer Perks Display
    local v4_Perks = { Enabled = false, Gui = nil, Label = nil }
    EExtra:AddToggle("v4 Killer Perks Display", false, function(a)
        v4_Perks.Enabled = a
        if not a then
            if v4_Perks.Gui then v4_Perks.Gui:Destroy() v4_Perks.Gui = nil v4_Perks.Label = nil end
            return
        end
        v4_Perks.Gui = Instance.new("ScreenGui")
        v4_Perks.Gui.Name = "v4_KillerPerks"
        v4_Perks.Gui.ResetOnSpawn = false
        v4_Perks.Gui.Parent = CoreGui
        local f = Instance.new("Frame", v4_Perks.Gui)
        f.Size = UDim2.new(0, 190, 0, 100)
        f.Position = UDim2.new(0.02, 0, 0.28, 0)
        f.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
        f.BackgroundTransparency = 0.15
        f.BorderSizePixel = 0
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
        local l = Instance.new("TextLabel", f)
        l.Size = UDim2.new(1, -12, 1, -12)
        l.Position = UDim2.new(0, 6, 0, 6)
        l.BackgroundTransparency = 1
        l.Font = Enum.Font.GothamMedium
        l.TextSize = 11
        l.TextColor3 = Color3.fromRGB(225, 225, 235)
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.TextYAlignment = Enum.TextYAlignment.Top
        l.RichText = true
        l.TextWrapped = true
        v4_Perks.Label = l
        task.spawn(function()
            while v4_Perks.Enabled do
                local killer
                for _, p in ipairs(Players:GetPlayers()) do
                    if p.Team and p.Team.Name:lower():find("killer") then killer = p break end
                end
                if killer and killer.Character and v4_Perks.Label then
                    local perks = {}
                    for _, c in ipairs(killer.Character:GetChildren()) do
                        local nm, lv = c.Name:match("^(.+)%s+(%d+)$")
                        if nm then
                            nm = nm:gsub("^%s+", ""):gsub("%s+$", "")
                            if nm ~= "" then table.insert(perks, nm .. " lv" .. lv) end
                        end
                    end
                    table.sort(perks)
                    local lines = { "<b>Killer:</b> " .. killer.DisplayName }
                    if #perks == 0 then
                        table.insert(lines, "<font color='#888888'>Waiting for perk data...</font>")
                    else
                        for i = 1, math.min(#perks, 5) do
                            table.insert(lines, "• " .. perks[i])
                        end
                    end
                    v4_Perks.Label.Text = table.concat(lines, "\n")
                end
                task.wait(1)
            end
        end)
    end, { Flag = "v4_KillerPerks" })

    -- [51] v4 Ping & FPS Counter
    local v4_Stats = { Enabled = false, Gui = nil, Label = nil, Thread = nil }
    EExtra:AddToggle("v4 Ping & FPS Counter", false, function(a)
        v4_Stats.Enabled = a
        if not a then
            if v4_Stats.Gui then v4_Stats.Gui:Destroy() v4_Stats.Gui = nil v4_Stats.Label = nil end
            if v4_Stats.Thread then task.cancel(v4_Stats.Thread) v4_Stats.Thread = nil end
            return
        end
        v4_Stats.Gui = Instance.new("ScreenGui")
        v4_Stats.Gui.Name = "v4_Stats"
        v4_Stats.Gui.ResetOnSpawn = false
        v4_Stats.Gui.Parent = CoreGui
        local l = Instance.new("TextLabel", v4_Stats.Gui)
        l.Size = UDim2.new(0, 340, 0, 22)
        l.Position = UDim2.new(0.5, -170, 0, 4)
        l.BackgroundTransparency = 1
        l.Font = Enum.Font.GothamBold
        l.TextSize = 13
        l.RichText = true
        l.TextColor3 = Color3.fromRGB(255, 255, 255)
        l.Text = "-- FPS | -- ms"
        v4_Stats.Label = l
        local frames, lastT, fps = 0, os.clock(), 0
        local conn
        conn = RunService.RenderStepped:Connect(function()
            frames = frames + 1
            local now = os.clock()
            if now - lastT >= 1 then
                fps = math.floor(frames / (now - lastT))
                frames = 0
                lastT = now
            end
            if not v4_Stats.Enabled then conn:Disconnect() end
        end)
        local StatsSvc = game:GetService("Stats")
        v4_Stats.Thread = task.spawn(function()
            while v4_Stats.Enabled do
                local ping = 0
                pcall(function()
                    local net = StatsSvc:FindFirstChild("Network")
                    local ss = net and net:FindFirstChild("ServerStatsItem")
                    local dp = ss and ss:FindFirstChild("Data Ping")
                    if dp then ping = math.floor(dp:GetValue()) end
                    if ping <= 0 and net and net.GetPing then ping = math.floor(net:GetPing()) end
                end)
                if v4_Stats.Label then
                    v4_Stats.Label.Text = string.format("<font color='#00FF78'>%d FPS</font>  <font color='#555'>|</font>  <font color='#FF4B4B'>%d ms</font>", fps, ping)
                end
                task.wait(0.5)
            end
        end)
    end, { Flag = "v4_PingFPS" })

    -- [52] v4 Hide Player Icon
    local v4_HideIcon = { Enabled = false }
    local function v4_HideIconLoop()
        task.spawn(function()
            while v4_HideIcon.Enabled do
                local pg = LocalPlayer:FindFirstChild("PlayerGui")
                if pg then
                    local selName = LocalPlayer:GetAttribute("SelectedKiller")
                    for _, guiName in ipairs({ "Survivor", "Survivor-mob", selName and (selName .. "-mob") }) do
                        if guiName then
                            local g = pg:FindFirstChild(guiName)
                            local fr = g and g:FindFirstChild("Frame")
                            if fr then
                                for i = 1, 5 do
                                    local slot = fr:FindFirstChild("Survivor" .. i)
                                    if slot then
                                        local ic = slot:FindFirstChildOfClass("ImageLabel")
                                        if ic and ic.Visible then ic.Image = "rbxassetid://82799775499788" end
                                    end
                                end
                            end
                        end
                    end
                end
                task.wait(0.6)
            end
        end)
    end
    EExtra:AddToggle("v4 Hide Player Icon", false, function(a)
        v4_HideIcon.Enabled = a
        if a then v4_HideIconLoop() end
    end, { Flag = "v4_HideIcon" })

    -- [53] v4 Protect Name (self)
    local v4_ProtectName = { Enabled = false }
    local function v4_ProtectNameLoop()
        task.spawn(function()
            local myName = LocalPlayer.Name
            while v4_ProtectName.Enabled do
                local pg = LocalPlayer:FindFirstChild("PlayerGui")
                if pg then
                    for _, d in ipairs(pg:GetDescendants()) do
                        if d:IsA("TextLabel") and d.Text == myName then
                            if not (d.Parent and d.Parent.Name:match("^Survivor%d")) then
                                d.Text = "v4"
                            end
                        end
                    end
                end
                task.wait(0.5)
            end
        end)
    end
    EExtra:AddToggle("v4 Protect Name (self)", false, function(a)
        v4_ProtectName.Enabled = a
        if a then v4_ProtectNameLoop() end
    end, { Flag = "v4_ProtectName" })

    -- [54] v4 Header Title (billboard di atas kepala)
    local v4_Header = { Enabled = false, Text = "v4", Gui = nil, Conn = nil }
    local function v4_BuildHeader()
        if v4_Header.Gui then v4_Header.Gui:Destroy() end
        local c = LocalPlayer.Character
        local head = c and c:FindFirstChild("Head")
        if not head then return end
        local bb = Instance.new("BillboardGui")
        bb.Name = "v4_HeaderGui"
        bb.Adornee = head
        bb.Size = UDim2.new(0, 200, 0, 40)
        bb.StudsOffset = Vector3.new(0, 1.8, 0)
        bb.AlwaysOnTop = true
        bb.Parent = c
        local l = Instance.new("TextLabel", bb)
        l.Size = UDim2.new(1, 0, 1, 0)
        l.BackgroundTransparency = 1
        l.TextScaled = true
        l.Font = Enum.Font.GothamBold
        l.TextColor3 = Color3.fromRGB(60, 170, 255)
        l.TextStrokeTransparency = 0.5
        l.Text = v4_Header.Text
        v4_Header.Gui = bb
    end
    EExtra:AddToggle("v4 Header Title", false, function(a)
        v4_Header.Enabled = a
        if a then v4_BuildHeader()
        else if v4_Header.Gui then v4_Header.Gui:Destroy() v4_Header.Gui = nil end end
    end, { Flag = "v4_Header" })
    EExtra:AddTextbox("v4 Header Text", "v4", function(txt)
        v4_Header.Text = txt or "v4"
        if v4_Header.Gui then
            local l = v4_Header.Gui:FindFirstChildOfClass("TextLabel")
            if l then l.Text = v4_Header.Text end
        end
    end)
    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(1)
        if v4_Header.Enabled then v4_BuildHeader() end
    end)

    -- ============================================================
    -- Character respawn hooks
    -- ============================================================
    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(1.5)
        if v4_AutoRunMob.Enabled then v4_AutoRunMob.Thread = nil end
        if v4_RunSpd.Enabled then v4_HookRunSpd(LocalPlayer.Character) end
        if v4_InfLunge.Enabled then
            local c = LocalPlayer.Character
            if c then c:SetAttribute("lungeboost", 999) end
        end
    end)

    pcall(function()
        v1:Notify({ Title = "v4 Feature Port", Description = "Loaded. Check v4 tabs.", Duration = 4 })
    end)
end
-- ============================================================
-- END v4 INJECT
-- ============================================================
-- ============================================================
-- [v5 INJECT] Silent Aim port dari violence.lua
-- ToF (Twist of Fate) + Veil (Spear) + Flask (Cure)
-- Inject PALING BAWAH febzhub-v4.lua setelah END v4 INJECT
-- Semua nama toggle prefix "v5"
-- ============================================================
do
    local Players           = v3
    local LocalPlayer       = v4
    local RunService        = v5
    local UserInputService  = v6
    local VIM               = v7
    local ReplicatedStorage = v9
    local CoreGui           = v10
    local PlayerGui         = v11
    local Camera            = v12

    local function v5_Root()
        local c = LocalPlayer.Character
        return c and c:FindFirstChild("HumanoidRootPart")
    end
    local function v5_Hum()
        local c = LocalPlayer.Character
        return c and c:FindFirstChildOfClass("Humanoid")
    end
    local function v5_Killer() return LocalPlayer.Team and LocalPlayer.Team.Name == "Killer" end
    local function v5_Survivor() return LocalPlayer.Team and LocalPlayer.Team.Name == "Survivors" end
    local function v5_Notif(t, d)
        pcall(function() v1:Notify({ Title = t, Description = d, Duration = 2 }) end)
    end
    local function v5_Rem(path)
        local cur = ReplicatedStorage
        for seg in string.gmatch(path, "[^%.]+") do
            if not cur then return nil end
            cur = cur:FindFirstChild(seg)
        end
        return cur
    end

    -- ============================================================
    -- TAB: v5 Silent Aim
    -- ============================================================
    local v5_Tab  = v2:CreateTab("v5 Silent Aim", false, false)
    local v5_Page = v5_Tab:CreatePage("v5 Silent Aim")

    -- ============================================================
    -- SECTION 1: v5 Silent Aim (ToF / Twist of Fate)
    -- ============================================================
    local ToFSec = v5_Page:CreateSection("v5 Silent Aim (ToF)", "crosshair")

    local v5_ToF = {
        Enabled      = false,
        Laser        = true,
        WallCheck    = false,
        BlockKnocked = true,
        TargetMode   = "Killer",
    }
    local v5_ToF_State = {
        Connection  = nil,
        InputBegan  = nil,
        InputEnded  = nil,
        TouchInput  = nil,
        IsAiming    = false,
        Laser       = nil,
        ZombieCache = {},
        ZombieCacheTime = 0,
        InputStarted = false,
    }

    local function v5_ToF_GetRemote()
        local r = v5_Rem("Remotes.Items.Twist of Fate.Fire")
        if r and r:IsA("RemoteEvent") then return r end
        return nil
    end
    local function v5_ToF_GetGun()
        local char = LocalPlayer.Character
        if not char then return nil end
        local base = char:FindFirstChild("Twist of Fate", true)
        if not base then return nil end
        local ra = base:FindFirstChild("Right Arm")
        if ra then
            local g = ra:FindFirstChild("gun")
            if g then return g end
            local eg = ra:FindFirstChild("EmperorGun")
            if eg then return eg end
        end
        return base
    end
    local function v5_ToF_IsDowned(char)
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return true end
        local state = char:GetAttribute("State")
        return state == "Downed" or state == "Dead"
    end
    local function v5_ToF_GetShootButton()
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        local smob = pg and pg:FindFirstChild("Survivor-mob")
        local ctl  = smob and smob:FindFirstChild("Controls")
        local gmob = ctl and ctl:FindFirstChild("Gui-mob")
        if not gmob then return nil end
        for _, n in ipairs({ "attack","Attack","shoot","Shoot","fire","Fire" }) do
            local b = gmob:FindFirstChild(n, true)
            if b and b:IsA("GuiObject") then return b end
        end
        for _, o in ipairs(gmob:GetDescendants()) do
            if o:IsA("GuiButton") and o.Visible then return o end
        end
        if gmob:IsA("GuiObject") then return gmob end
        return nil
    end
    local function v5_ToF_IsTouchOnShoot(input)
        local b = v5_ToF_GetShootButton()
        if not (b and b.Visible) then return false end
        local p, a, s = input.Position, b.AbsolutePosition, b.AbsoluteSize
        return p.X >= a.X and p.X <= a.X + s.X and p.Y >= a.Y and p.Y <= a.Y + s.Y
    end
    local function v5_ToF_IsVisible(o, t, tc)
        local d = t - o
        local m = d.Magnitude
        if m < 0.1 then return true end
        local rp = RaycastParams.new()
        rp.FilterType = Enum.RaycastFilterType.Exclude
        local ex = {}
        local lc = LocalPlayer.Character
        if lc then table.insert(ex, lc) end
        if tc and tc ~= lc then table.insert(ex, tc) end
        if v5_ToF_State.Laser then table.insert(ex, v5_ToF_State.Laser) end
        rp.FilterDescendantsInstances = ex
        return workspace:Raycast(o, d.Unit * m, rp) == nil
    end
    local function v5_ToF_GetZombies()
        if tick() - v5_ToF_State.ZombieCacheTime < 0.5 then
            return v5_ToF_State.ZombieCache
        end
        local list = {}
        local map = workspace:FindFirstChild("Map")
        if map then
            for _, c in ipairs(map:GetDescendants()) do
                if c:IsA("Model") then
                    local attrs = c:GetAttributes()
                    if c:GetAttribute("CorpseCreated0492") or next(attrs) ~= nil then
                        local r = c:FindFirstChild("HumanoidRootPart")
                        if r then table.insert(list, r) end
                    end
                end
            end
        end
        v5_ToF_State.ZombieCache = list
        v5_ToF_State.ZombieCacheTime = tick()
        return list
    end
    local function v5_ToF_GetTarget()
        local gun = v5_ToF_GetGun()
        local char = LocalPlayer.Character
        if not (gun and char) then return nil, nil, nil, nil end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return nil, nil, nil, nil end
        local myPos = hrp.Position
        local originPos
        if char:GetAttribute("IsCarried") then
            originPos = hrp.Position + (hrp.CFrame.LookVector * 2)
        else
            pcall(function()
                if gun:IsA("BasePart") then originPos = gun.Position
                else
                    local bp = gun:FindFirstChildOfClass("BasePart")
                    if bp then originPos = bp.Position end
                end
            end)
            originPos = originPos or Vector3.new(myPos.X, myPos.Y + 1.5, myPos.Z)
        end
        local function predict(torso, tc)
            local tPos = torso.Position
            if v5_ToF.WallCheck and not v5_ToF_IsVisible(originPos, tPos, tc) then
                return nil, nil, nil, nil
            end
            local tVel = Vector3.new(0, 0, 0)
            local rp = tc and (tc:FindFirstChild("HumanoidRootPart") or torso)
            if rp then tVel = rp.Velocity end
            local d = tPos - originPos
            local dist = d.Magnitude
            if dist < 0.1 then return nil, nil, nil, nil end
            if dist < 5 then return d.Unit, gun, originPos, tPos end
            local tt = dist / 400
            local pred = tPos + tVel * tt
            for _ = 1, 2 do
                tt = (pred - originPos).Magnitude / 400
                pred = tPos + tVel * tt
            end
            local fd = pred - originPos
            if fd.Magnitude < 0.1 then return nil, nil, nil, nil end
            return fd.Unit, gun, originPos, pred
        end
        if v5_ToF.TargetMode == "Killer" then
            local bT, bC, bD = nil, nil, math.huge
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Team and p.Team.Name == "Killer" and p.Character then
                    local t = p.Character:FindFirstChild("Torso")
                        or p.Character:FindFirstChild("UpperTorso")
                        or p.Character:FindFirstChild("HumanoidRootPart")
                    if t then
                        local d = (myPos - t.Position).Magnitude
                        if d < bD then bD = d bT = t bC = p.Character end
                    end
                end
            end
            if not bT then return nil, nil, nil, nil end
            return predict(bT, bC)
        elseif v5_ToF.TargetMode == "Survivors" then
            local bT, bC, bDot = nil, nil, -math.huge
            local cam = workspace.CurrentCamera
            if not cam then return nil, nil, nil, nil end
            local cp, cl = cam.CFrame.Position, cam.CFrame.LookVector
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Team and p.Team.Name == "Survivors" and p.Character then
                    local t = p.Character:FindFirstChild("Torso")
                        or p.Character:FindFirstChild("UpperTorso")
                        or p.Character:FindFirstChild("HumanoidRootPart")
                    if t then
                        local dir = t.Position - cp
                        if dir.Magnitude > 0.1 then
                            local dot = cl:Dot(dir.Unit)
                            if dot > 0.5 and dot > bDot then bDot = dot bT = t bC = p.Character end
                        end
                    end
                end
            end
            if not bT then return nil, nil, nil, nil end
            return predict(bT, bC)
        elseif v5_ToF.TargetMode == "Zombie" then
            local bP, bDot = nil, -math.huge
            local cam = workspace.CurrentCamera
            if not cam then return nil, nil, nil, nil end
            local cp, cl = cam.CFrame.Position, cam.CFrame.LookVector
            for _, r in ipairs(v5_ToF_GetZombies()) do
                if r and r.Parent then
                    local dir = r.Position - cp
                    if dir.Magnitude > 0.1 then
                        local dot = cl:Dot(dir.Unit)
                        if dot > 0.5 and dot > bDot then bDot = dot bP = r end
                    end
                end
            end
            if not bP then return nil, nil, nil, nil end
            return predict(bP, bP.Parent)
        end
        return nil, nil, nil, nil
    end
    local function v5_ToF_UpdateLaser(o, t)
        if not v5_ToF_State.Laser then
            local l = Instance.new("Part")
            l.Name = "v5_ToFLaser"
            l.Anchored = true
            l.CanCollide = false
            l.CanTouch = false
            l.CastShadow = false
            l.Material = Enum.Material.Neon
            l.Color = Color3.fromRGB(255, 50, 50)
            l.Parent = workspace
            v5_ToF_State.Laser = l
        end
        local d = (t - o).Magnitude
        v5_ToF_State.Laser.Size = Vector3.new(0.05, 0.05, d)
        v5_ToF_State.Laser.CFrame = CFrame.new((o + t) / 2, t)
        v5_ToF_State.Laser.Transparency = 0
    end
    local function v5_ToF_ClearLaser()
        if v5_ToF_State.Laser then
            pcall(function() v5_ToF_State.Laser:Destroy() end)
            v5_ToF_State.Laser = nil
        end
    end
    local function v5_ToF_Shoot()
        if not v5_ToF.Enabled then return end
        local char = LocalPlayer.Character
        if char and v5_ToF.BlockKnocked and v5_ToF_IsDowned(char) then return end
        local dir, gun, o, t = v5_ToF_GetTarget()
        if not (dir and gun and t and o) then return end
        local ev = v5_ToF_GetRemote()
        if not ev then return end
        local fresh = t - o
        if fresh.Magnitude < 0.1 then return end
        pcall(function() ev:FireServer(gun, fresh.Unit) end)
    end
    local function v5_ToF_StopInput()
        if v5_ToF_State.InputBegan then v5_ToF_State.InputBegan:Disconnect() v5_ToF_State.InputBegan = nil end
        if v5_ToF_State.InputEnded then v5_ToF_State.InputEnded:Disconnect() v5_ToF_State.InputEnded = nil end
        v5_ToF_State.TouchInput = nil
        v5_ToF_State.IsAiming = false
        v5_ToF_State.InputStarted = false
        v5_ToF_ClearLaser()
    end
    local function v5_ToF_StartInput()
        v5_ToF_StopInput()
        v5_ToF_State.InputBegan = UserInputService.InputBegan:Connect(function(input, gp)
            if gp then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                v5_ToF_State.IsAiming = true
                v5_ToF_State.InputStarted = true
                return
            end
            if input.UserInputType == Enum.UserInputType.Touch then
                if v5_ToF_IsTouchOnShoot(input) then
                    v5_ToF_State.IsAiming = true
                    v5_ToF_State.TouchInput = input
                    v5_ToF_State.InputStarted = true
                end
            end
        end)
        v5_ToF_State.InputEnded = UserInputService.InputEnded:Connect(function(input)
            local isMouse = input.UserInputType == Enum.UserInputType.MouseButton1
            local isTouch = input.UserInputType == Enum.UserInputType.Touch and input == v5_ToF_State.TouchInput
            if not (isMouse or isTouch) then return end
            if not v5_ToF_State.InputStarted then return end
            v5_ToF_State.IsAiming = false
            v5_ToF_State.InputStarted = false
            v5_ToF_State.TouchInput = nil
            if v5_ToF.Enabled then v5_ToF_Shoot() end
            v5_ToF_ClearLaser()
        end)
    end
    local function v5_ToF_StopConn()
        if v5_ToF_State.Connection then
            v5_ToF_State.Connection:Disconnect()
            v5_ToF_State.Connection = nil
        end
        v5_ToF_ClearLaser()
    end
    local function v5_ToF_StartConn()
        v5_ToF_StopConn()
        v5_ToF_State.Connection = RunService.Heartbeat:Connect(function()
            if not v5_ToF.Enabled then
                if v5_ToF_State.IsAiming then v5_ToF_State.IsAiming = false end
                v5_ToF_ClearLaser()
                return
            end
            if not v5_ToF_State.IsAiming then
                v5_ToF_ClearLaser()
                return
            end
            local dir, gun, o, t = v5_ToF_GetTarget()
            if not (dir and gun and o and t) then
                v5_ToF_ClearLaser()
                return
            end
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp and not char:GetAttribute("IsCarried") then
                local look = Vector3.new(t.X, hrp.Position.Y, t.Z)
                if (look - hrp.Position).Magnitude > 0.1 then
                    hrp.CFrame = CFrame.lookAt(hrp.Position, look)
                end
            end
            if v5_ToF.Laser then v5_ToF_UpdateLaser(o, t) else v5_ToF_ClearLaser() end
        end)
    end
    local function v5_ToF_SetEnabled(value)
        v5_ToF.Enabled = value
        if value then
            v5_ToF_StartInput()
            v5_ToF_StartConn()
        else
            v5_ToF_StopInput()
            v5_ToF_StopConn()
        end
    end
    v5_ToF_StartInput()

    ToFSec:AddToggle("v5 ToF Silent Aim", false, function(a)
        v5_ToF_SetEnabled(a)
        v5_Notif("v5 ToF Silent Aim", a and "ON" or "OFF")
    end, { Flag = "v5_ToF_SilentAim" })
    ToFSec:AddToggle("v5 ToF Laser Beam", true, function(a)
        v5_ToF.Laser = a
        if not a then v5_ToF_ClearLaser() end
    end, { Flag = "v5_ToF_Laser" })
    ToFSec:AddToggle("v5 ToF Wall Check", false, function(a)
        v5_ToF.WallCheck = a
    end, { Flag = "v5_ToF_WallCheck" })
    ToFSec:AddToggle("v5 ToF Block When Knocked", true, function(a)
        v5_ToF.BlockKnocked = a
    end, { Flag = "v5_ToF_BlockKnocked" })
    ToFSec:AddDropdown("v5 ToF Target Mode", {"Killer", "Survivors", "Zombie"}, false, function(opt)
        if type(opt) == "table" then opt = opt[1] end
        if opt == "Killer" or opt == "Survivors" or opt == "Zombie" then
            v5_ToF.TargetMode = opt
        end
    end, { Flag = "v5_ToF_TargetMode" })

    -- ============================================================
    -- SECTION 2: v5 Silent Aim (Veil)
    -- ============================================================
    local VeilSec = v5_Page:CreateSection("v5 Silent Aim (Veil)", "sword")

    local v5_Veil = {
        Enabled                 = false,
        ShowFOV                 = true,
        ShowTargetLaser         = true,
        FOV                     = 150,
        SpearSpeed              = 165,
        Gravity                 = workspace.Gravity * 0.5,
        MaxDist                 = 200,
        AutoPredict             = false,
        TargetPart              = "Torso",
        HorizontalPredictFactor = 1.0,
    }
    local v5_VeilState = {
        chargingSpear    = false,
        touchInput       = nil,
        attackCooldown   = false,
        passiveCooldown  = false,
        remoteHooked     = false,
        lastPredictedPos = nil,
    }
    local v5_VeilVelocity = {}

    local function v5_Veil_NewDrawing(cls)
        if type(Drawing) == "table" and type(Drawing.new) == "function" then
            local ok, o = pcall(Drawing.new, cls)
            if ok and o then return o end
        end
        return setmetatable({}, { __newindex = function(t, k, val) rawset(t, k, val) end })
    end
    local v5_VeilDraw = {
        FOVCircle = v5_Veil_NewDrawing("Circle"),
        Highlight = Instance.new("Highlight"),
        Tracer    = v5_Veil_NewDrawing("Circle"),
    }
    v5_VeilDraw.FOVCircle.Color     = Color3.fromRGB(255, 0, 255)
    v5_VeilDraw.FOVCircle.Thickness = 1.5
    v5_VeilDraw.FOVCircle.Filled    = false
    v5_VeilDraw.FOVCircle.Visible   = false
    v5_VeilDraw.Highlight.Name                = "v5_VeilTarget"
    v5_VeilDraw.Highlight.FillColor           = Color3.fromRGB(255, 0, 0)
    v5_VeilDraw.Highlight.OutlineColor        = Color3.fromRGB(255, 255, 255)
    v5_VeilDraw.Highlight.FillTransparency    = 0.5
    v5_VeilDraw.Highlight.OutlineTransparency = 0
    v5_VeilDraw.Tracer.Thickness = 2
    v5_VeilDraw.Tracer.Radius    = 5
    v5_VeilDraw.Tracer.Color     = Color3.fromRGB(255, 0, 255)
    v5_VeilDraw.Tracer.Filled    = true
    v5_VeilDraw.Tracer.Visible   = false

    local function v5_Veil_RealVelocity(part, name)
        if not part then return Vector3.zero end
        local pos, now = part.Position, tick()
        if not v5_VeilVelocity[name] then
            v5_VeilVelocity[name] = { lastPos = pos, lastTime = now, velocity = Vector3.zero }
            return Vector3.zero
        end
        local cache = v5_VeilVelocity[name]
        local dt = now - cache.lastTime
        if dt > 0.01 then
            local raw = (pos - cache.lastPos) / dt
            if raw.Magnitude < 100 then
                cache.velocity = cache.velocity:Lerp(raw, 0.4)
            end
        end
        cache.lastPos = pos
        cache.lastTime = now
        return cache.velocity
    end
    local function v5_Veil_GetTargetPart(char)
        if v5_Veil.TargetPart == "Head" then return char:FindFirstChild("Head") end
        if v5_Veil.TargetPart == "Root" then return char:FindFirstChild("HumanoidRootPart") end
        return char:FindFirstChild("Torso")
            or char:FindFirstChild("UpperTorso")
            or char:FindFirstChild("HumanoidRootPart")
    end
    local function v5_Veil_GetClosestSurvivor()
        local myChar = LocalPlayer.Character
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myRoot then return nil end
        local cam = workspace.CurrentCamera
        local center = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
        local bestDist = v5_Veil.FOV
        local best = nil
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Team and p.Team.Name == "Survivors" and p.Character then
                local c = p.Character
                local hum = c:FindFirstChildOfClass("Humanoid")
                local part = v5_Veil_GetTargetPart(c)
                if hum and hum.Health > 0 and part then
                    local d3 = (part.Position - myRoot.Position).Magnitude
                    if d3 <= v5_Veil.MaxDist then
                        local sp, on = cam:WorldToViewportPoint(part.Position)
                        if on then
                            local d2 = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                            if d2 < bestDist then
                                bestDist = d2
                                best = { Player = p, Part = part }
                            end
                        end
                    end
                end
            end
        end
        return best
    end
    local function v5_Veil_SetupInterceptor()
        if v5_VeilState.remoteHooked then return end
        task.spawn(function()
            pcall(function()
                local old
                old = hookmetamethod(game, "__namecall", function(self, ...)
                    if not checkcaller() and getnamecallmethod() == "FireServer" then
                        if self.Name == "Spearthrow" and v5_Veil.Enabled then
                            return nil
                        end
                    end
                    return old(self, ...)
                end)
                v5_VeilState.remoteHooked = true
            end)
        end)
    end
    v5_Veil_SetupInterceptor()
    local function v5_Veil_Fire()
        if v5_VeilState.attackCooldown then return end
        v5_VeilState.attackCooldown = true
        task.delay(2, function() v5_VeilState.attackCooldown = false end)
        local myChar = LocalPlayer.Character
        local startPart = myChar and (myChar:FindFirstChild("Head") or myChar:FindFirstChild("HumanoidRootPart"))
        if not startPart then return end
        local startPos = startPart.Position
        local targetInfo = v5_Veil_GetClosestSurvivor()
        local aimDir
        if targetInfo and targetInfo.Part then
            local tPart, tPl = targetInfo.Part, targetInfo.Player
            local tPos = tPart.Position
            local vel = v5_Veil_RealVelocity(tPart, tPl.Name)
            local hVel = Vector3.new(vel.X, 0, vel.Z)
            local speed = hVel.Magnitude
            local dist = (tPos - startPos).Magnitude
            local tt = dist / v5_Veil.SpearSpeed
            local hPred = Vector3.zero
            if speed > 4 and v5_Veil.AutoPredict then
                hPred = hVel * tt * v5_Veil.HorizontalPredictFactor
            end
            local pred = tPos + hPred
            local autoG = math.max(0, dist - 8)
            local grav = v5_Veil.AutoPredict and autoG or v5_Veil.Gravity
            local drop = 0.5 * grav * (tt ^ 2)
            local finalPos = pred + Vector3.new(0, drop, 0)
            aimDir = (finalPos - startPos).Unit
            v5_VeilState.lastPredictedPos = finalPos
        else
            aimDir = workspace.CurrentCamera.CFrame.LookVector
            v5_VeilState.lastPredictedPos = nil
        end
        pcall(function()
            local r = v5_Rem("Remotes.Killers.Veil.Spearthrow")
            if r then r:FireServer(aimDir, v5_Veil.SpearSpeed, startPos) end
        end)
        v5_VeilDraw.FOVCircle.Color = Color3.fromRGB(255, 0, 255)
        if not v5_VeilState.passiveCooldown then
            v5_VeilState.passiveCooldown = true
            task.delay(30, function()
                v5_VeilDraw.FOVCircle.Color = Color3.fromRGB(255, 0, 255)
                v5_VeilState.passiveCooldown = false
            end)
        end
    end
    UserInputService.InputBegan:Connect(function(input, gp)
        local isTouch = input.UserInputType == Enum.UserInputType.Touch
        if gp and not isTouch then return end
        local char = LocalPlayer.Character
        local isSpearMode = char and char:GetAttribute("spearmode") == true
        if not v5_Veil.Enabled or not isSpearMode then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            v5_VeilState.chargingSpear = true
        elseif isTouch then
            local pg = LocalPlayer:FindFirstChild("PlayerGui")
            if pg then
                local sl = pg:FindFirstChild("Slasher-mob")
                if sl then
                    local c = sl:FindFirstChild("Controls")
                    if c then
                        local ab = c:FindFirstChild("attack")
                        if ab and ab.Visible then
                            local pos, ap, as_ = input.Position, ab.AbsolutePosition, ab.AbsoluteSize
                            if pos.X >= ap.X and pos.X <= ap.X + as_.X
                            and pos.Y >= ap.Y and pos.Y <= ap.Y + as_.Y then
                                v5_VeilState.chargingSpear = true
                                v5_VeilState.touchInput = input
                            end
                        end
                    end
                end
            end
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if v5_VeilState.chargingSpear
        and (input == v5_VeilState.touchInput or input.UserInputType == Enum.UserInputType.MouseButton1) then
            v5_VeilState.chargingSpear = false
            if v5_VeilState.touchInput == input then v5_VeilState.touchInput = nil end
            v5_Veil_Fire()
        end
    end)
    RunService.RenderStepped:Connect(function()
        local cam = workspace.CurrentCamera
        local myChar = LocalPlayer.Character
        local isSpearMode = myChar and myChar:GetAttribute("spearmode") == true
        if v5_Veil.Enabled and v5_Veil.ShowFOV and isSpearMode then
            v5_VeilDraw.FOVCircle.Visible  = true
            v5_VeilDraw.FOVCircle.Radius   = v5_Veil.FOV
            v5_VeilDraw.FOVCircle.Position = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
        else
            v5_VeilDraw.FOVCircle.Visible = false
        end
        if v5_VeilState.chargingSpear and v5_Veil.Enabled and isSpearMode then
            local target = v5_Veil_GetClosestSurvivor()
            if target and target.Part and target.Part.Parent then
                v5_VeilDraw.Highlight.Parent = target.Part.Parent
                if v5_Veil.ShowTargetLaser then
                    if not getgenv().v5_SpearLaserPart then
                        local l = Instance.new("Part")
                        l.Name = "v5_SpearLaser"
                        l.Anchored = true
                        l.CanCollide = false
                        l.CanTouch = false
                        l.CastShadow = false
                        l.Material = Enum.Material.Neon
                        l.Color = Color3.fromRGB(255, 50, 50)
                        l.Transparency = 0
                        l.Parent = workspace
                        getgenv().v5_SpearLaserPart = l
                    end
                    local originPart = myChar and (myChar:FindFirstChild("Head") or myChar:FindFirstChild("HumanoidRootPart"))
                    if originPart then
                        local o, t = originPart.Position, target.Part.Position
                        local d = (t - o).Magnitude
                        if d > 0.1 then
                            local l = getgenv().v5_SpearLaserPart
                            l.Size = Vector3.new(0.16, 0.16, d)
                            l.CFrame = CFrame.new((o + t) / 2, t)
                            l.Transparency = 0.5
                        end
                    end
                else
                    if getgenv().v5_SpearLaserPart then getgenv().v5_SpearLaserPart.Transparency = 1 end
                end
            else
                v5_VeilDraw.Highlight.Parent = nil
                if getgenv().v5_SpearLaserPart then getgenv().v5_SpearLaserPart.Transparency = 1 end
            end
        else
            v5_VeilDraw.Highlight.Parent = nil
            if getgenv().v5_SpearLaserPart then getgenv().v5_SpearLaserPart.Transparency = 1 end
        end
        if v5_Veil.Enabled and isSpearMode and v5_VeilState.lastPredictedPos then
            local sp, on = cam:WorldToViewportPoint(v5_VeilState.lastPredictedPos)
            local vp = cam.ViewportSize
            local center = Vector2.new(vp.X / 2, vp.Y / 2)
            if on then
                v5_VeilDraw.Tracer.Position = Vector2.new(sp.X, sp.Y)
            else
                local dx, dy = sp.X - center.X, sp.Y - center.Y
                if math.abs(dx) < 1 and math.abs(dy) < 1 then
                    v5_VeilDraw.Tracer.Position = center
                else
                    local maxX, maxY = vp.X / 2 - 10, vp.Y / 2 - 10
                    local sX = maxX / math.abs(dx)
                    local sY = maxY / math.abs(dy)
                    local s = math.min(sX, sY)
                    v5_VeilDraw.Tracer.Position = Vector2.new(center.X + dx * s, center.Y + dy * s)
                end
            end
            v5_VeilDraw.Tracer.Visible = true
        else
            v5_VeilDraw.Tracer.Visible = false
        end
    end)

    VeilSec:AddToggle("v5 Veil Silent Aim", false, function(a)
        v5_Veil.Enabled = a
        if not a then
            v5_VeilState.chargingSpear = false
            v5_VeilState.lastPredictedPos = nil
        end
        v5_Notif("v5 Veil Silent Aim", a and "ON" or "OFF")
    end, { Flag = "v5_Veil_Enabled" })
    VeilSec:AddToggle("v5 Veil Show FOV", true, function(a) v5_Veil.ShowFOV = a end, { Flag = "v5_Veil_ShowFOV" })
    VeilSec:AddToggle("v5 Veil Show Target Laser", true, function(a) v5_Veil.ShowTargetLaser = a end, { Flag = "v5_Veil_ShowLaser" })
    VeilSec:AddSlider("v5 Veil FOV", 1, 800, 150, function(v) v5_Veil.FOV = v end, { Increment = 1, Flag = "v5_Veil_FOV" })
    VeilSec:AddSlider("v5 Veil Spear Speed", 1, 500, 165, function(v) v5_Veil.SpearSpeed = v end, { Increment = 1, Flag = "v5_Veil_Speed" })
    VeilSec:AddSlider("v5 Veil Gravity", 0, 300, 103, function(v) v5_Veil.Gravity = v end, { Increment = 1, Flag = "v5_Veil_Gravity" })
    VeilSec:AddSlider("v5 Veil Max Distance", 1, 500, 200, function(v) v5_Veil.MaxDist = v end, { Increment = 1, Flag = "v5_Veil_MaxDist" })
    VeilSec:AddToggle("v5 Veil Auto Predict", false, function(a) v5_Veil.AutoPredict = a end, { Flag = "v5_Veil_AutoPredict" })
    VeilSec:AddDropdown("v5 Veil Target Part", {"Head", "Torso", "Root"}, false, function(opt)
        if type(opt) == "table" then opt = opt[1] end
        v5_Veil.TargetPart = opt
    end, { Flag = "v5_Veil_TargetPart" })
    VeilSec:AddSlider("v5 Veil Horizontal Predict Factor", 0, 3, 1.0, function(v)
        v5_Veil.HorizontalPredictFactor = v
    end, { Increment = 0.01, Flag = "v5_Veil_HorizPredict" })

    -- ============================================================
    -- SECTION 3: v5 Silent Aim Flask (Cure)
    -- ============================================================
    local FlaskSec = v5_Page:CreateSection("v5 Silent Aim Flask", "flask-conical")

    local v5_Flask = {
        SilentAim = false,
        Laser     = false,
    }
    local _genv = getgenv()
    _genv.v5_CureFlaskLaserThread = nil
    _genv.v5_CureFlaskLaserPart = nil

    local function v5_Flask_UpdateLaser()
        local char = LocalPlayer.Character
        if not char then return end
        local targetPos, originPos
        local closest, minDst = nil, math.huge
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local hand = char:FindFirstChild("LeftHand") or char:FindFirstChild("Left Arm")
            originPos = hand and hand.Position or hrp.Position
            for _, v in ipairs(Players:GetPlayers()) do
                if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
                    if not v.Character:GetAttribute("IsKiller") then
                        local d = (v.Character.HumanoidRootPart.Position - hrp.Position).Magnitude
                        if d < minDst then minDst = d closest = v end
                    end
                end
            end
        end
        if closest then targetPos = closest.Character.HumanoidRootPart.Position end
        local actionActive = false
        for _, ch in ipairs(char:GetChildren()) do
            if ch:IsA("LocalScript") and ch:GetAttribute("action") == true then
                actionActive = true
                break
            end
        end
        if originPos and targetPos and actionActive then
            if not _genv.v5_CureFlaskLaserPart then
                local l = Instance.new("Part")
                l.Name = "v5_FlaskLaser"
                l.Anchored = true
                l.CanCollide = false
                l.CanTouch = false
                l.CastShadow = false
                l.Material = Enum.Material.Neon
                l.Color = Color3.fromRGB(0, 100, 255)
                l.Transparency = 0
                l.Parent = workspace
                _genv.v5_CureFlaskLaserPart = l
            end
            local d = (targetPos - originPos).Magnitude
            if d > 0.1 then
                local l = _genv.v5_CureFlaskLaserPart
                l.Size = Vector3.new(0.16, 0.16, d)
                l.CFrame = CFrame.new((originPos + targetPos) / 2, targetPos)
                l.Transparency = 0
            end
        else
            if _genv.v5_CureFlaskLaserPart then _genv.v5_CureFlaskLaserPart.Transparency = 1 end
        end
    end
    local function v5_Flask_StartLaser()
        if _genv.v5_CureFlaskLaserThread then return end
        _genv.v5_CureFlaskLaserThread = RunService.RenderStepped:Connect(function()
            if not v5_Flask.Laser then
                if _genv.v5_CureFlaskLaserPart then
                    pcall(function() _genv.v5_CureFlaskLaserPart:Destroy() end)
                    _genv.v5_CureFlaskLaserPart = nil
                end
                if _genv.v5_CureFlaskLaserThread then
                    _genv.v5_CureFlaskLaserThread:Disconnect()
                    _genv.v5_CureFlaskLaserThread = nil
                end
                return
            end
            pcall(v5_Flask_UpdateLaser)
        end)
    end
    if not _genv.v5_FlaskHookInstalled then
        _genv.v5_FlaskHookInstalled = true
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            if v5_Flask.SilentAim and method == "FireServer" then
                local ok, name = pcall(function() return self.Name end)
                if ok and name == "ThrowFlask" then
                    local args = { ... }
                    local closest, minDst = nil, math.huge
                    local lp = LocalPlayer
                    local myPos = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") and lp.Character.HumanoidRootPart.Position
                    if myPos then
                        for _, v in ipairs(Players:GetPlayers()) do
                            if v ~= lp and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
                                if not v.Character:GetAttribute("IsKiller") then
                                    local d = (v.Character.HumanoidRootPart.Position - myPos).Magnitude
                                    if d < minDst then minDst = d closest = v end
                                end
                            end
                        end
                    end
                    if closest then
                        local tPos = closest.Character.HumanoidRootPart.Position
                        if args[2] and typeof(args[2]) == "Vector3" then
                            args[1] = (tPos - args[2]).Unit
                        end
                        setnamecallmethod(method)
                        return oldNamecall(self, unpack(args))
                    end
                end
            end
            return oldNamecall(self, ...)
        end)
    end

    FlaskSec:AddToggle("v5 Flask Silent Aim", false, function(a)
        v5_Flask.SilentAim = a
        v5_Notif("v5 Flask Silent Aim", a and "ON" or "OFF")
    end, { Flag = "v5_Flask_SilentAim" })
    FlaskSec:AddToggle("v5 Flask Laser", false, function(a)
        v5_Flask.Laser = a
        if a then
            pcall(v5_Flask_StartLaser)
            v5_Notif("v5 Flask Laser", "ON")
        else
            if _genv.v5_CureFlaskLaserThread then
                _genv.v5_CureFlaskLaserThread:Disconnect()
                _genv.v5_CureFlaskLaserThread = nil
            end
            if _genv.v5_CureFlaskLaserPart then
                pcall(function() _genv.v5_CureFlaskLaserPart:Destroy() end)
                _genv.v5_CureFlaskLaserPart = nil
            end
            v5_Notif("v5 Flask Laser", "OFF")
        end
    end, { Flag = "v5_Flask_Laser" })

    if v5_Flask.Laser then pcall(v5_Flask_StartLaser) end

    pcall(function()
        v1:Notify({ Title = "v5 Silent Aim Port", Description = "Loaded: ToF + Veil + Flask", Duration = 4 })
    end)
end
-- ============================================================
-- END v5 INJECT
-- ============================================================