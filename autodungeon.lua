repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
-- Carregar Fluent UI
local Fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/0eujunioofc/eae/refs/heads/main/junio.lua"))()

local Window = Fluent:CreateWindow({
    Title = 'BR Anime Astral',
    SubTitle = "eujunioofc",
    TabWidth = 160,
    Size = UDim2.fromOffset(500, 400),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl,
})

local KeyPassed = false
local CorrectKey = "A200915E"

local Tabs = {
    Updates = Window:AddTab({ Title = "Updates", Icon = "info" }),
    Key = Window:AddTab({ Title = "Key", Icon = "key" }),
    Main = Window:AddTab({ Title = "Dungeon", Icon = "swords" }),
    Defense = Window:AddTab({ Title = "Defense", Icon = "shield" }),
    Ball = Window:AddTab({ Title = "Auto Ball", Icon = "circle" }),
    Gate = Window:AddTab({ Title = "Gate", Icon = "circle" }),
}

local DISCORD_URL = "https://discord.gg/czmYtNf8wf"

Tabs.Updates:AddButton({
    Title = "Join Discord Server",
    Description = "Copia o link do Discord para você ver updates, scripts e suporte.",
    Callback = function()
        if setclipboard then
            setclipboard(DISCORD_URL)
            Fluent:Notify({
                Title = "Discord",
                Content = "Link copiado!",
                Duration = 3
            })
        else
            Fluent:Notify({
                Title = "Discord",
                Content = "Seu executor não suporta copiar link.",
                Duration = 3
            })
        end
    end
})

Tabs.Updates:AddParagraph({ Title = "Version v0.1.5", Content = "[Gamemodes] Adicionado Detector de Gate" })
Tabs.Updates:AddParagraph({ Title = "Version v0.1.4", Content = "[Updates] Adicionado sistema de Updates/Changelog" })
Tabs.Updates:AddParagraph({ Title = "Version v0.1.3", Content = "[Gamemodes] Adicionado Auto Ball" })
Tabs.Updates:AddParagraph({ Title = "Version v0.1.2", Content = "[Gamemodes] Adicionado Auto Dungeon" })
Tabs.Updates:AddParagraph({ Title = "Version v0.1.1", Content = "[Main] Interface melhorada e sistema de Key" })

local KeyStatus = Tabs.Key:AddParagraph({ Title = "Status", Content = "Digite a key para liberar o script" })

Tabs.Key:AddInput("KeyInput", {
    Title = "Sistema de Key",
    Placeholder = "Digite sua key aqui",
    Numeric = false,
    Finished = true,
    Callback = function(value)
        if value == CorrectKey then
            KeyPassed = true
            if KeyStatus then
                KeyStatus:SetDesc("Key correta! Script liberado.")
            end
            Fluent:Notify({
                Title = "Key correta",
                Content = "Acesso liberado!",
                Duration = 3
            })
            Window:SelectTab(3)
        else
            KeyPassed = false
            if KeyStatus then
                KeyStatus:SetDesc("Key incorreta. Tente novamente.")
            end
            Fluent:Notify({
                Title = "Key errada",
                Content = "Verifique a key e tente de novo.",
                Duration = 3
            })
        end
    end
})

-- Variáveis do Auto Dungeon
local AutoDungeonEnabled = false
local AutoLeaveEnabled = false
local LeaveRoom = 50

Tabs.Main:AddToggle("AutoDungeon", {
    Title = "Auto Dungeon",
    Default = false,
    Callback = function(state)
        if not KeyPassed then
            AutoDungeonEnabled = false
            Fluent:Notify({
                Title = "Key necessária",
                Content = "Digite a key primeiro.",
                Duration = 3
            })
            return
        end
        AutoDungeonEnabled = state
    end
})

Tabs.Main:AddToggle("AutoLeave", {
    Title = "Auto Leave",
    Default = false,
    Callback = function(state)
        if not KeyPassed then
            AutoLeaveEnabled = false
            Fluent:Notify({
                Title = "Key necessária",
                Content = "Digite a key primeiro.",
                Duration = 3
            })
            return
        end
        AutoLeaveEnabled = state
    end
})

Tabs.Main:AddSlider("LeaveRoom", {
    Title = "Leave Room",
    Min = 1,
    Max = 50,
    Default = 50,
    Rounding = 0.1,
    Callback = function(Value)
        LeaveRoom = Value
    end
})

local StatusLabel = Tabs.Main:AddParagraph({ Title = "Status", Content = "Idle" })

-- Variáveis do Auto Ball
local AutoBallEnabled = false
local BallRadius = 600
local BallCooldown = 0.4
local ballsFolderName = "World8Balls"
local sphereName = "Sphere.004"
local promptName = "BallClaimPrompt"
local collectedCount = 0
local currentTarget = "Nenhum"

Tabs.Ball:AddSlider("BallRadius", {
    Title = "Raio de busca",
    Min = 300,
    Max = 1000,
    Default = 650,
    Rounding = 0,
    Callback = function(value)
        BallRadius = value
    end
})

Tabs.Ball:AddSlider("BallCooldown", {
    Title = "Cooldown",
    Min = 0.1,
    Max = 2,
    Default = 0.4,
    Rounding = 1,
    Callback = function(value)
        BallCooldown = value
    end
})

local BallStatus = Tabs.Ball:AddParagraph({ Title = "Status", Content = "Auto Ball parado" })

Tabs.Ball:AddToggle("AutoBall", {
    Title = "Ativar Auto Ball",
    Default = false,
    Callback = function(state)
        if not KeyPassed then
            AutoBallEnabled = false
            Fluent:Notify({
                Title = "Key necessária",
                Content = "Digite a key primeiro.",
                Duration = 3
            })
            if BallStatus then
                BallStatus:SetDesc("Digite a key primeiro")
            end
            return
        end
        AutoBallEnabled = state
        if BallStatus then
            BallStatus:SetDesc(state and "Auto Ball ligado" or "Auto Ball parado")
        end
    end
})

-- Variáveis do Auto Gate
local AutoGateEnabled = false
local SelectedGateRank = "C"
local SelectedGateWorld = 5

local GateStatus = Tabs.Gate:AddParagraph({
    Title = "Status",
    Content = "Gate parado"
})

local function readGateCard(card)
    if not AutoGateEnabled then return end
    if not card or not card.Name:match("^Notify_Raid_") then return end

    task.wait(0.15)

    local desc = card:FindFirstChild("Description")
    if not desc or not desc:IsA("TextLabel") then return end

    local text = desc.Text or ""
    local rank = text:match("Rank%s+([SABCDEF])")
    local worldNum = text:match("World%s+(%d+)")

    if GateStatus then
        GateStatus:SetDesc("Gate encontrado: Rank " .. tostring(rank) .. " | World " .. tostring(worldNum))
    end

    if rank == SelectedGateRank and tonumber(worldNum) == SelectedGateWorld then
        if GateStatus then
            GateStatus:SetDesc("Gate desejado encontrado: Rank " .. rank .. " | World " .. worldNum)
        end

        Fluent:Notify({
            Title = "Gate encontrado",
            Content = "Rank " .. rank .. " apareceu no World " .. worldNum,
            Duration = 5
        })

        print("Gate escolhido apareceu:", card.Name, text)
    else
        print("Gate ignorado:", card.Name, text)
    end
end

local function scanCurrentGates()
    local notifyRoot = LocalPlayer.PlayerGui
        :WaitForChild("HUD")
        :WaitForChild("Main")
        :WaitForChild("GamemodeNotify")

    for _, card in ipairs(notifyRoot:GetChildren()) do
        if card.Name:match("^Notify_Raid_") then
            task.spawn(function()
                readGateCard(card)
            end)
        end
    end
end

Tabs.Gate:AddDropdown("GateRank", {
    Title = "Rank do Gate",
    Values = { "E", "D", "C", "B", "A", "S" },
    Multi = false,
    Default = "C",
    Callback = function(value)
        SelectedGateRank = value

        if GateStatus then
            GateStatus:SetDesc("Rank escolhido: " .. tostring(value))
        end

        if AutoGateEnabled then
            task.spawn(scanCurrentGates)
        end
    end
})

Tabs.Gate:AddToggle("AutoGate", {
    Title = "Detectar Gate",
    Default = false,
    Callback = function(state)
        if not KeyPassed then
            AutoGateEnabled = false

            Fluent:Notify({
                Title = "Key necessária",
                Content = "Digite a key primeiro.",
                Duration = 3
            })

            return
        end

        AutoGateEnabled = state

        if GateStatus then
            GateStatus:SetDesc(state and ("Procurando Gate Rank " .. SelectedGateRank) or "Gate parado")
        end

        if AutoGateEnabled then
            task.spawn(scanCurrentGates)
        end
    end
})

-- Funções do Auto Dungeon
local function setStatus(text)
    if StatusLabel then
        pcall(function()
            StatusLabel:SetDesc(text)
        end)
    end
end

local function getCharacter()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function getRootPart()
    local char = getCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid(model)
    if not model then return nil end
    return model:FindFirstChildOfClass("Humanoid") or model:FindFirstChild("Humanoid", true)
end

local function getObjectCFrame(obj)
    if not obj then return nil end
    if obj:IsA("Model") then
        local ok, pivot = pcall(function() return obj:GetPivot() end)
        if ok then return pivot end
    end
    if obj:IsA("BasePart") then
        return obj.CFrame
    end
    local part = obj:FindFirstChild("HumanoidRootPart", true) or obj:FindFirstChildWhichIsA("BasePart", true)
    if part then
        return part.CFrame
    end
    return nil
end

local function isEnemyAlive(enemy)
    if not enemy or not enemy.Parent then return false end
    local dead = enemy:GetAttribute("EnemyDead")
    if dead == true then return false end
    local healthReal = enemy:GetAttribute("HealthReal")
    if type(healthReal) == "number" and healthReal <= 0 then return false end
    local hum = getHumanoid(enemy)
    if hum and hum.Health <= 0 then return false end
    return true
end

local function getPartRadius(part)
    if not part or not part:IsA("BasePart") then return nil end
    local sizes = {part.Size.X, part.Size.Y, part.Size.Z}
    table.sort(sizes)
    return sizes[3] / 2
end

local function getPlayerRange()
    local ok, radius = pcall(function()
        local range = workspace:FindFirstChild("RangeLv1")
        if not range then return 15 end
        local main = range:FindFirstChild("Main")
        if main then
            local circle = main:FindFirstChild("Circle")
            local r = getPartRadius(circle) or getPartRadius(main)
            if r then return r end
        end
        local r = getPartRadius(range:FindFirstChild("HitBox"))
        if r then return r end
        return 15
    end)
    return (ok and radius) or 15
end

local function robustClickObject(obj)
    if not obj then return false end
    if typeof(fireclick) == "function" then
        if pcall(fireclick, obj) then return true end
    end
    if typeof(firesignal) == "function" then
        local clicked = false
        pcall(function() firesignal(obj.MouseButton1Click); clicked = true end)
        pcall(function() firesignal(obj.Activated); clicked = true end)
        if clicked then return true end
    end
    if typeof(getconnections) == "function" then
        local fired = false
        pcall(function()
            for _, conn in ipairs(getconnections(obj.MouseButton1Click)) do
                conn:Fire(); fired = true
            end
            for _, conn in ipairs(getconnections(obj.Activated)) do
                conn:Fire(); fired = true
            end
        end)
        if fired then return true end
    end
    local vimSuccess = pcall(function()
        if obj.AbsoluteSize.X > 0 and obj.AbsoluteSize.Y > 0 then
            local inset = GuiService:GetGuiInset()
            local x = obj.AbsolutePosition.X + (obj.AbsoluteSize.X / 2)
            local y = obj.AbsolutePosition.Y + (obj.AbsoluteSize.Y / 2) + inset.Y
            VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
            task.wait(0.02)
            VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)
        end
    end)
    if vimSuccess then return true end
    if pcall(function() obj:Activate() end) then return true end
    return false
end

local function MovementGoTo(targetCFrame)
    local root = getRootPart()
    if not root then return false end
    pcall(function()
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        root.CFrame = targetCFrame
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end)
end

local function optimalFarmPosition(enemies)
    local positions3D = {}
    for _, e in ipairs(enemies) do
        local cf = getObjectCFrame(e)
        if cf then
            table.insert(positions3D, cf.Position)
        end
    end
    if #positions3D == 0 then return nil, 0 end
    if #positions3D == 1 then return CFrame.new(positions3D[1] + Vector3.new(0, 3, 0)), 1 end

    local range = getPlayerRange()
    local centroid = Vector3.zero
    for _, p in ipairs(positions3D) do centroid += p end
    centroid /= #positions3D
    local allFit = true
    for _, p in ipairs(positions3D) do
        local dist = (Vector2.new(p.X, p.Z) - Vector2.new(centroid.X, centroid.Z)).Magnitude
        if dist > range * 0.95 then
            allFit = false
            break
        end
    end
    if allFit then
        return CFrame.new(centroid + Vector3.new(0, 3, 0)), #positions3D
    end
    local candidates = {}
    for _, p in ipairs(positions3D) do table.insert(candidates, p) end
    for i = 1, #positions3D do
        for j = i + 1, #positions3D do
            table.insert(candidates, (positions3D[i] + positions3D[j]) / 2)
        end
    end
    table.insert(candidates, centroid)
    local bestPos = candidates[1]
    local bestCount = 0
    for _, candidate in ipairs(candidates) do
        local count = 0
        for _, p in ipairs(positions3D) do
            local dist = (Vector2.new(p.X, p.Z) - Vector2.new(candidate.X, candidate.Z)).Magnitude
            if dist <= range * 0.95 then
                count = count + 1
            end
        end
        if count > bestCount then
            bestCount = count
            bestPos = candidate
        elseif count == bestCount then
            if (candidate - centroid).Magnitude < (bestPos - centroid).Magnitude then
                bestPos = candidate
            end
        end
    end
    local clusterCenter = Vector3.zero
    local clusterCount = 0
    for _, p in ipairs(positions3D) do
        local dist = (Vector2.new(p.X, p.Z) - Vector2.new(bestPos.X, bestPos.Z)).Magnitude
        if dist <= range * 0.95 then
            clusterCenter += p
            clusterCount = clusterCount + 1
        end
    end
    if clusterCount > 0 then
        return CFrame.new(clusterCenter + Vector3.new(0, 3, 0)), clusterCount
    else
        return CFrame.new(bestPos + Vector3.new(0, 3, 0)), 1
    end
end

-- Funções do Auto Ball
local function ensureCharacterAlive()
    local character = LocalPlayer.Character
    if not character or not character.Parent then
        return false
    end

    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        return false
    end
    return true
end

local function findNearbyBalls()
    local nearbyBalls = {}

    if not ensureCharacterAlive() then
        return nearbyBalls
    end
    local humanoidRootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then
        return nearbyBalls
    end
    local ballsFolder = workspace:FindFirstChild(ballsFolderName)
    if not ballsFolder then
        return nearbyBalls
    end
    local characterPos = humanoidRootPart.Position
    for _, ballModel in ipairs(ballsFolder:GetChildren()) do
        local sphere = ballModel:FindFirstChild(sphereName)
        if sphere and sphere:IsA("BasePart") then
            local prompt = sphere:FindFirstChild(promptName)
            if prompt and prompt:IsA("ProximityPrompt") then
                local distance = (sphere.Position - characterPos).Magnitude
                if distance <= BallRadius then
                    table.insert(nearbyBalls, {
                        model = ballModel,
                        sphere = sphere,
                        prompt = prompt,
                        distance = distance
                    })
                end
            end
        end
    end
    table.sort(nearbyBalls, function(a, b)
        return a.distance < b.distance
    end)
    return nearbyBalls
end

local function holdPrompt(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") then return false end

    local holdTime = prompt.HoldDuration
    local success = pcall(function()
        prompt:InputHoldBegin()
        task.wait(holdTime + 0.15)
        prompt:InputHoldEnd()
    end)
    return success
end

local function collectBall(ballData)
    if not ballData or not ballData.sphere or not ballData.prompt then return false end

    if not ballData.sphere.Parent or not ballData.model.Parent then
        return false
    end
    if not ensureCharacterAlive() then
        return false
    end
    local humanoidRootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then
        return false
    end
    local sphere = ballData.sphere
    local prompt = ballData.prompt
    local ballModel = ballData.model
    local distance = (sphere.Position - humanoidRootPart.Position).Magnitude
    if distance > BallRadius then
        return false
    end
    currentTarget = ballModel.Name
    if BallStatus then
        BallStatus:SetDesc("Coletando: " .. currentTarget)
    end
    local targetPosition = sphere.Position + Vector3.new(0, 2.5, 0)
    local tweenInfo = TweenInfo.new(
        0.35,
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out
    )
    local tween = TweenService:Create(
        humanoidRootPart,
        tweenInfo,
        { CFrame = CFrame.new(targetPosition) }
    )
    tween:Play()
    tween.Completed:Wait()
    task.wait(0.15)
    local activated = holdPrompt(prompt)
    if activated then
        local removed = false
        for _ = 1, 20 do
            if not ballModel or not ballModel.Parent then
                removed = true
                break
            end
            task.wait(0.1)
        end
        if removed then
            collectedCount += 1
            return true
        end
    end
    return false
end

local function collectionLoop()
    while task.wait(0.1) do
        if not AutoBallEnabled then
            currentTarget = "Nenhum"
            if BallStatus then
                BallStatus:SetDesc("Auto Ball parado")
            end
            continue
        end

        if not ensureCharacterAlive() then
            LocalPlayer.CharacterAdded:Wait()
            task.wait(1)
            continue
        end
        local humanoidRootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then
            continue
        end
        local balls = findNearbyBalls()
        if #balls == 0 then
            currentTarget = "Nenhuma bola próxima"
            if BallStatus then
                BallStatus:SetDesc("Procurando bolas...")
            end
            task.wait(0.5)
            continue
        end
        for _, ballData in ipairs(balls) do
            if not AutoBallEnabled then
                break
            end
            if not ensureCharacterAlive() then
                break
            end
            if ballData and ballData.sphere and ballData.sphere.Parent then
                local success = collectBall(ballData)
                if success then
                    task.wait(BallCooldown)
                else
                    task.wait(0.15)
                end
            end
        end
    end
end

-- Funções do Auto Gate
local function setupGateDetector()
    local success, notifyRoot = pcall(function()
        return LocalPlayer.PlayerGui
            :WaitForChild("HUD")
            :WaitForChild("Main")
            :WaitForChild("GamemodeNotify")
    end)

    if not success or not notifyRoot then return end

    notifyRoot.ChildAdded:Connect(function(card)
        task.spawn(function()
            readGateCard(card)
        end)
    end)

    task.spawn(scanCurrentGates)
end

-- Loop principal do Auto Dungeon
local lastEmptyTime = tick()

task.spawn(function()
    while task.wait(0.03) do
        if not AutoDungeonEnabled then
            setStatus("Waiting (Disabled)")
            continue
        end

        pcall(function()
            local notifyGui = LocalPlayer.PlayerGui:FindFirstChild("HUD")
            if notifyGui then
                local notifyDungeon = notifyGui:FindFirstChild("Main")
                    and notifyGui.Main:FindFirstChild("GamemodeNotify")
                    and notifyGui.Main.GamemodeNotify:FindFirstChild("Notify_Dungeon_World9Dungeon")
                if notifyDungeon and notifyDungeon.Visible then
                    local yesBtn = notifyDungeon:FindFirstChild("Actions") and notifyDungeon.Actions:FindFirstChild("YES")
                    if yesBtn then
                        setStatus("Dungeon notification detected, waiting 0.5s...")
                        task.wait(0.5)
                        setStatus("Clicking YES...")
                        robustClickObject(yesBtn)
                        local tl
                        pcall(function()
                            local tlGui = LocalPlayer.PlayerGui:FindFirstChild("Windows")
                            tl = tlGui and tlGui:FindFirstChild("TeleportLoading")
                        end)
                        local waitStart = tick()
                        while tl and not tl.Visible and (tick() - waitStart < 4) do
                            task.wait(0.05)
                        end
                        if tl and tl.Visible then
                            setStatus("Waiting for loading screen...")
                            repeat task.wait(0.05) until not tl.Visible
                        end
                        setStatus("Loading complete, waiting 1s...")
                        task.wait(1)
                    end
                end
            end
        end)
        
        local currentRoom = 0
        pcall(function()
           local roomLabel = LocalPlayer.PlayerGui:FindFirstChild("DungeonGui")
                and LocalPlayer.PlayerGui.DungeonGui:FindFirstChild("Main")
                and LocalPlayer.PlayerGui.DungeonGui.Main:FindFirstChild("Room")
            if roomLabel and roomLabel:IsA("TextLabel") then
                currentRoom = tonumber(roomLabel.Text:match("(%d+)")) or 0
            end
        end)
        
        local inDungeon = false
        local dungeonEnemiesFolder = nil
        pcall(function()
            local dungeonArenas = workspace:FindFirstChild("DungeonArenas")
            if dungeonArenas then
                local w9 = dungeonArenas:FindFirstChild("World9Dungeon")
                local enemies = w9 and w9:FindFirstChild("Enemies")
                if enemies then
                    inDungeon = true
                    dungeonEnemiesFolder = enemies
                else
                    for _, arena in ipairs(dungeonArenas:GetChildren()) do
                        local enemiesFolder = arena:FindFirstChild("Enemies")
                        if enemiesFolder then
                            inDungeon = true
                            dungeonEnemiesFolder = enemiesFolder
                            break
                        end
                    end
                end
            end
        end)
        
        if inDungeon and dungeonEnemiesFolder then
            local teleportLoading
            pcall(function()
                local tl = LocalPlayer.PlayerGui:FindFirstChild("Windows")
                if tl then teleportLoading = tl:FindFirstChild("TeleportLoading") end
            end)
            if teleportLoading and teleportLoading.Visible then
                setStatus("Waiting for loading screen...")
                repeat task.wait(0.05) until not teleportLoading.Visible
                task.wait(1)
            end
            
            if AutoLeaveEnabled and currentRoom >= LeaveRoom and currentRoom > 0 then
                setStatus("Target Room Reached (Room " .. currentRoom .. "). Leaving...")
                pcall(function()
                    local leaveBtn = LocalPlayer.PlayerGui:FindFirstChild("DungeonGui")
                        and LocalPlayer.PlayerGui.DungeonGui:FindFirstChild("Main")
                        and LocalPlayer.PlayerGui.DungeonGui.Main:FindFirstChild("Leave")
                    if leaveBtn and (leaveBtn.Visible or leaveBtn.Parent.Visible) then
                        robustClickObject(leaveBtn)
                        task.wait(0.3)
                    end
                end)
                continue
            end
            
            local targets = {}
            for _, enemy in ipairs(dungeonEnemiesFolder:GetChildren()) do
                if isEnemyAlive(enemy) then
                    table.insert(targets, enemy)
                end
            end
            
            if #targets > 0 then
                lastEmptyTime = tick()
                local tcf, coveredCount = optimalFarmPosition(targets)
                if tcf then
                    local range = getPlayerRange()
                    local roomText = currentRoom > 0 and ("[Room " .. currentRoom .. "] ") or ""
                    setStatus(roomText .. "Farming (Perfect Position: " .. coveredCount .. "/" .. #targets .. " enemies)")
                    MovementGoTo(tcf)
                    local startTime = tick()
                    while tick() - startTime < 3 and AutoDungeonEnabled do
                        local anyCoveredAlive = false
                        for _, enemy in ipairs(targets) do
                            if isEnemyAlive(enemy) then
                                local ecf = getObjectCFrame(enemy)
                                if ecf then
                                    local dist = (Vector2.new(ecf.Position.X, ecf.Position.Z) - Vector2.new(tcf.Position.X, tcf.Position.Z)).Magnitude
                                    if dist <= range * 0.95 then
                                        anyCoveredAlive = true
                                        break
                                    end
                                end
                            end
                        end
                        if not anyCoveredAlive then break end
                        task.wait(0.03)
                    end
                end
            else
                setStatus("Waiting for enemies or dungeon finished...")
                if AutoLeaveEnabled and (tick() - lastEmptyTime > 4) then
                    pcall(function()
                        local leaveBtn = LocalPlayer.PlayerGui:FindFirstChild("DungeonGui")
                            and LocalPlayer.PlayerGui.DungeonGui:FindFirstChild("Main")
                            and LocalPlayer.PlayerGui.DungeonGui.Main:FindFirstChild("Leave")
                        if leaveBtn and (leaveBtn.Visible or leaveBtn.Parent.Visible) then
                            setStatus("Leaving Dungeon (Auto Leave)...")
                            robustClickObject(leaveBtn)
                            task.wait(0.3)
                        end
                    end)
                end
            end
        else
            if AutoDungeonEnabled then
                setStatus("Waiting for Dungeon invite...")
            end
        end
    end
end)

-- Iniciar os loops do Auto Ball e Gate Detector
task.spawn(collectionLoop)
task.spawn(setupGateDetector) 

Window:SelectTab(2)
Fluent:Notify({
    Title = "Script Carregado",
    Content = "Auto Dungeon, Auto Ball e Gate Detector prontos!",
    Duration = 3
})
