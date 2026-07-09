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
    Title = 'BR Anime Astral PRO',
    SubTitle = "eujunioofc",
    TabWidth = 160,
    Size = UDim2.fromOffset(550, 450),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl,
})

local KeyPassed = false
local CorrectKey = "A200915E"

local Tabs = {
    Updates = Window:AddTab({ Title = "Updates", Icon = "info" }),
    Key = Window:AddTab({ Title = "Key", Icon = "key" }),
    Gamemodes = Window:AddTab({ Title = "Gamemodes", Icon = "circle" }),
    Misc = Window:AddTab({ Title = "Misc", Icon = "settings" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "sliders-horizontal" }),
}

-- Todos os modulos ficam dentro da aba Gamemodes
Tabs.Main = Tabs.Gamemodes
Tabs.Dungeon = Tabs.Gamemodes
Tabs.Defense = Tabs.Gamemodes
Tabs.Ball = Tabs.Gamemodes
Tabs.Gate = Tabs.Gamemodes
Tabs.Arise = Tabs.Gamemodes
Tabs.AutoJoin = Tabs.Gamemodes

-- Espaco visual entre os modulos
local function AddSpace(tab)
    return tab:AddParagraph({
        Title = " ",
        Content = " "
    })
end

-- Separador padrao dos modulos
local function AddSection(tab, title, desc)
    AddSpace(tab)

    return tab:AddParagraph({
        Title = "========== " .. title .. " ==========",
        Content = desc or ""
    })
end

-- Separadores prontos para cada modulo
local function AddGateSection()
    return AddSection(Tabs.Gate, "AUTO GATE", "[FORA DO MODO] Detecta notificacoes de Gate.")
end

local function AddAutoJoinSection()
    return AddSection(
        Tabs.AutoJoin,
        "AUTO JOIN / SERVER",
        "[FORA DO MODO] Procura botoes Join, Entrar ou Play. Nao aceita o YES do Gate."
    )
end

local function AddDungeonSection()
    return AddSection(Tabs.Main, "AUTO DUNGEON", "[DENTRO DO MODO] Sistema da Dungeon World9.")
end

local function AddAriseSection()
    return AddSection(Tabs.Arise, "AUTO ARISE", "[DENTRO DO MODO] Procura ArisePrompt dentro de RaidArenas.")
end

local function AddBallSection()
    return AddSection(Tabs.Ball, "AUTO BALL", "[FORA DO MODO] Sistema das bolas do World8.")
end

-- =================== Utils ===================
local function robustClickObject(obj)
    if not obj then return false end
    local ok = false

    -- firesignal em eventos comuns
    if (obj:IsA("TextButton") or obj:IsA("ImageButton")) and typeof(firesignal) == "function" then
        pcall(function() firesignal(obj.MouseButton1Click) ok = true end)
        pcall(function() firesignal(obj.Activated) ok = true end)
    end

    -- mouse virtual no centro do objeto
    if not ok and obj.AbsoluteSize and obj.AbsolutePosition then
        local inset = GuiService:GetGuiInset()
        local x = obj.AbsolutePosition.X + (obj.AbsoluteSize.X / 2)
        local y = obj.AbsolutePosition.Y + (obj.AbsoluteSize.Y / 2) + inset.Y
        pcall(function()
            VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
            task.wait(0.02)
            VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)
            ok = true
        end)
    end

    return ok
end

local function ensureCharacterAlive()
    local c = LocalPlayer.Character
    if not c or not c.Parent then return false end
    local h = c:FindFirstChildOfClass("Humanoid")
    return h and h.Health > 0
end

local function partCFrameOf(obj)
    if not obj then return nil end
    if typeof(obj) == "Instance" then
        if obj:IsA("BasePart") then return obj.CFrame end
        local primary = obj:IsA("Model") and obj.PrimaryPart
        if primary then return primary.CFrame end
        local bp = obj:FindFirstChildWhichIsA("BasePart", true)
        if bp then return bp.CFrame end
    end
    return nil
end

local function teleportCF(cf)
    if not cf or not ensureCharacterAlive() then return false end
    local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    pcall(function() hrp.CFrame = cf + Vector3.new(0,3,0) end)
    return true
end

local function safeTP(cframe)
    return teleportCF(cframe)
end

local function getByPath(path)
    local ok, result = pcall(function()
        local node = game
        for part in string.gmatch(path, "[^%.]+") do
            local name = part
            local bracket = part:match("%[(.+)%]")
            if bracket then
                name = part:match("^[^%[]+")
                local idx = bracket:gsub("[\"'%[%]]", "")
                node = node[name][idx]
            else
                node = node[part]
            end
        end
        return node
    end)
    if ok then return result end
    return nil
end

local function tryInteract(obj)
    if not obj then return false end
    -- ProximityPrompt
    local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt then
        local ok = pcall(function()
            if typeof(firesignal) == "function" then firesignal(prompt.Triggered) end
            fireproximityprompt(prompt)
        end)
        if ok then return true end
    end
    -- TouchInterest
    local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart", true)
    if part then
        local ti = part:FindFirstChildOfClass("TouchInterest")
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if ti and hrp then
            pcall(function()
                firetouchinterest(hrp, part, 0)
                task.wait(0.05)
                firetouchinterest(hrp, part, 1)
            end)
            return true
        end
    end
    -- Botões internos
    for _, d in ipairs(obj:GetDescendants()) do
        if d:IsA("TextButton") or d:IsA("ImageButton") then
            if robustClickObject(d) then return true end
        end
    end
    return false
end

local function enterByStation(stationPath)
    local station = getByPath(stationPath)
    if not station then return false end
    local cf = partCFrameOf(station)
    if cf then safeTP(cf) task.wait(0.25) end
    for _ = 1, 5 do
        if tryInteract(station) then return true end
        task.wait(0.25)
    end
    return false
end

local function gotoWorldSpawn(worldIndex)
    local spawnObj = getByPath(('workspace.Worlds["%s"].Spawn'):format(tostring(worldIndex)))
    if not spawnObj then return false end
    local cf = partCFrameOf(spawnObj)
    if not cf then return false end
    return safeTP(cf)
end

-- =================== Gate helpers (YES + Portal) ===================
local function isInAnyGate()
    local raidArenas = workspace:FindFirstChild("RaidArenas")
    if not raidArenas then return false end
    for _, world in ipairs(raidArenas:GetChildren()) do
        if (world:IsA("Folder") or world:IsA("Model")) and world:FindFirstChild("Enemies") then
            return true
        end
    end
    return false
end

local function getGateNotifyRoot()
    local pgui = LocalPlayer.PlayerGui
    local hud = pgui and pgui:FindFirstChild("HUD")
    local main = hud and hud:FindFirstChild("Main")
    local root = main and main:FindFirstChild("GamemodeNotify")
    return root
end

local function clickYesInCurrentGateNotify()
    local root = getGateNotifyRoot()
    if not root then return false end
    for _, card in ipairs(root:GetChildren()) do
        if card.Visible and tostring(card.Name):match("^Notify_Raid_") then
            local desc = card:FindFirstChild("Description")
            if desc and desc:IsA("TextLabel") and string.lower(desc.Text or ""):find("gate") then
                local actions = card:FindFirstChild("Actions")
                if not actions then continue end
                local candidates = {
                    actions:FindFirstChild("YES"),
                    actions:FindFirstChild("Yes"),
                    actions:FindFirstChild("CONFIRM"),
                    actions:FindFirstChild("Confirm")
                }
                for _, btn in ipairs(candidates) do
                    if btn and (btn:IsA("TextButton") or btn:IsA("ImageButton")) then
                        if robustClickObject(btn) then return true end
                    end
                end
                for _, d in ipairs(actions:GetDescendants()) do
                    if d:IsA("TextButton") or d:IsA("ImageButton") then
                        local n = (d.Name or ""):lower()
                        local t = (d.Text or ""):lower()
                        if n:find("yes") or t:find("yes") or n:find("confirm") or t:find("confirm") then
                            if robustClickObject(d) then return true end
                        end
                    end
                end
            end
        end
    end
    return false
end

-- Entra pelo portal físico ativo no mapa (World 5)
local function enterGateByPortal()
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    local tried = false
    local station = getByPath('workspace.Worlds["5"].Systems.RaidStation')
    if station then
        local cfs = partCFrameOf(station)
        if cfs then teleportCF(cfs) task.wait(0.25) end
        tried = tryInteract(station)
        if tried then return true end
    end

    local spawnGate = getByPath('workspace.Worlds["5"].SpawnGate')
    if spawnGate then
        local cfg = partCFrameOf(spawnGate)
        if cfg then teleportCF(cfg) task.wait(0.2) end
        tried = tryInteract(spawnGate)
        if tried then return true end
    end

    -- Varredura genérica perto: procura por modelos/parts com nomes relacionados a portal/gate
    local root = workspace
    local candidates = {}
    for _, inst in ipairs(root:GetDescendants()) do
        local n = string.lower(inst.Name or "")
        if inst:IsA("BasePart") or inst:IsA("Model") then
            if n:find("gate") or n:find("portal") or n:find("raid") then
                table.insert(candidates, inst)
            end
        end
    end

    table.sort(candidates, function(a,b)
        local ca = partCFrameOf(a)
        local cb = partCFrameOf(b)
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return false end
        local da = ca and (ca.Position - hrp.Position).Magnitude or math.huge
        local db = cb and (cb.Position - hrp.Position).Magnitude or math.huge
        return da < db
    end)

    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    for _, obj in ipairs(candidates) do
        if not hrp then break end
        local cf = partCFrameOf(obj)
        if cf and (cf.Position - hrp.Position).Magnitude <= 200 then
            teleportCF(cf) task.wait(0.2)
            if tryInteract(obj) then return true end
        end
    end
    return false
end

-- Estratégia completa: YES -> confirmação -> fallback Station/Portal
local function enterGateAutoFull()
    -- 1) Tenta clicar YES se a notificação estiver presente
    local clicked = clickYesInCurrentGateNotify()
    if clicked then
        -- aguarda confirmação de entrada (Enemies aparecerem)
        for _ = 1, 40 do
            if isInAnyGate() then return true end
            task.wait(0.15)
        end
    end

    -- 2) Fallback: Station principal
    if enterByStation('workspace.Worlds["5"].Systems.RaidStation') then
        for _ = 1, 40 do
            if isInAnyGate() then return true end
            task.wait(0.15)
        end
    end

    -- 3) Fallback secundário: SpawnGate
    if enterByStation('workspace.Worlds["5"].SpawnGate') then
        for _ = 1, 40 do
            if isInAnyGate() then return true end
            task.wait(0.15)
        end
    end

    -- 4) Fallback final: portal físico varrido
    if enterGateByPortal() then
        for _ = 1, 40 do
            if isInAnyGate() then return true end
            task.wait(0.15)
        end
    end

    return false
end

-- Wrappers específicos já existentes
local function enterDungeonByStation()
    local map = getByPath('workspace.Worlds["9"].Map')
    if map then
        local list = map:GetChildren()
        local anchor = list[8]
        local cfa = partCFrameOf(anchor)
        if cfa then safeTP(cfa) task.wait(0.25) end
    end
    return enterByStation('workspace.Worlds["9"].Systems.DungeonStation')
end

local function enterGateByStation()
    gotoWorldSpawn(5) task.wait(0.25)
    local ok = enterByStation('workspace.Worlds["5"].Systems.RaidStation')
    if not ok then ok = enterByStation('workspace.Worlds["5"].SpawnGate') end
    return ok
end

-- ========== VARIÁVEIS ==========
-- ARISE
local AutoAriseEnabled = false
local AutoAriseActivation = false
local AriseCheckInterval = 1.0
local AriseHoldDelay = 0.2
local AriseDetectionCount = 0
local LastAriseEnemies = {}
local ActiveAriseWorlds = {}
local NotifiedAriseKeys = {}
local AriseStatusMessage = "Sistema desativado"

-- GATE
local AutoGateEnabled = false
local SelectedGateRanks = { C = true }
local SelectedGateWorld = 5
local GateAutomationEnabled = false

-- AUTO JOIN
local AutoJoinEnabled = false
local JoinDetectionInterval = 1.0

-- DUNGEON
local AutoDungeonEnabled = false
local AutoLeaveEnabled = false
local LeaveRoom = 50

-- BALL
local AutoBallEnabled = false
local BallRadius = 600
local BallCooldown = 0.4
local ballsFolderName = "World8Balls"
local sphereName = "Sphere.004"
local promptName = "BallClaimPrompt"
local collectedCount = 0
local currentTarget = "Nenhum"

-- UI labels
local StatusArise, GateStatus, JoinStatus, BallStatus, StatusLabel

-- DISCORD
local DISCORD_URL = "https://discord.gg/czmYtNf8wf"

Tabs.Updates:AddButton({
    Title = "Join Discord Server",
    Description = "Copia o link do Discord para você ver updates, scripts e suporte.",
    Callback = function()
        if setclipboard then
            setclipboard(DISCORD_URL)
            Fluent:Notify({ Title = "Discord", Content = "Link copiado!", Duration = 3 })
        else
            Fluent:Notify({ Title = "Discord", Content = "Seu executor não suporta copiar link.", Duration = 3 })
        end
    end
})

Tabs.Updates:AddParagraph({ Title = "Version v1.1.0", Content = "[Gate] YES automático + fallback Portal/Station robusto" })
Tabs.Updates:AddParagraph({ Title = "Version v1.0.0", Content = "[PRO] Auto Gate, Auto Join e Auto Arise" })

-- SISTEMA DE KEY
local KeyStatus = Tabs.Key:AddParagraph({ Title = "Status", Content = "Digite a key para liberar o script" })
Tabs.Key:AddInput("KeyInput", {
    Title = "Sistema de Key",
    Placeholder = "Digite sua key aqui",
    Numeric = false,
    Finished = true,
    Callback = function(value)
        if value == CorrectKey then
            KeyPassed = true
            KeyStatus:SetDesc("Key correta! Script liberado.")
            Fluent:Notify({ Title = "Key correta", Content = "Acesso liberado!", Duration = 3 })
            Window:SelectTab(3)
        else
            KeyPassed = false
            KeyStatus:SetDesc("Key incorreta. Tente novamente.")
            Fluent:Notify({ Title = "Key errada", Content = "Verifique a key e tente de novo.", Duration = 3 })
        end
    end
})

-- ========== AUTO JOIN ==========
local function findJoinButtons()
    local joinButtons = {}
    local guiLocations = { LocalPlayer.PlayerGui, game:GetService("CoreGui") }
    for _, gui in ipairs(guiLocations) do
        pcall(function()
            for _, child in ipairs(gui:GetDescendants()) do
                if child:IsA("TextButton") or child:IsA("ImageButton") then
                    local text = child.Text or ""
                    local name = child.Name or ""
                    if text:lower():find("join") or name:lower():find("join")
                    or text:lower():find("entrar") or name:lower():find("entrar")
                    or text:lower():find("play") or name:lower():find("play") then
                        table.insert(joinButtons, child)
                    end
                end
            end
        end)
    end
    return joinButtons
end

local function autoJoinLoop()
    while task.wait(JoinDetectionInterval) do
        if not AutoJoinEnabled then
            if JoinStatus then JoinStatus:SetDesc("Auto Join desativado") end
            continue
        end
        if JoinStatus then JoinStatus:SetDesc("Procurando botões JOIN...") end
        local joinButtons = findJoinButtons()
        if #joinButtons > 0 then
            if JoinStatus then JoinStatus:SetDesc("✅ "..#joinButtons.." botões JOIN encontrados") end
            for _, b in ipairs(joinButtons) do
                if not AutoJoinEnabled then break end
                if JoinStatus then JoinStatus:SetDesc("Clicando no botão JOIN...") end
                if robustClickObject(b) then
                    Fluent:Notify({ Title = "✅ JOIN clicado", Content = "Entrando...", Duration = 3 })
                    if JoinStatus then JoinStatus:SetDesc("✅ JOIN realizado - aguardando") end
                    task.wait(3)
                    break
                end
            end
        else
            if JoinStatus then JoinStatus:SetDesc("❌ Nenhum botão JOIN encontrado") end
        end
    end
end

-- ========== GATE UI/Detector ==========
local function isGateRankSelected(rank)
    if not rank then return false end
    return SelectedGateRanks[rank] == true
end

local function selectedRanksText()
    local list = {}
    for _, r in ipairs({"E","D","C","B","A","S"}) do
        if SelectedGateRanks[r] then table.insert(list, r) end
    end
    return (#list==0) and "Nenhum" or table.concat(list, ", ")
end

local function scanCurrentGates()
    if not AutoGateEnabled then return end
    local root = getGateNotifyRoot()
    if not root then return end
    for _, card in ipairs(root:GetChildren()) do
        if card.Name:match("^Notify_Raid_") and card.Visible then
            local desc = card:FindFirstChild("Description")
            if not desc or not desc:IsA("TextLabel") then continue end
            local text = desc.Text or ""
            if not text:lower():find("gate") then continue end
            local rank = text:match("Rank%s+([SABCDEF])")
            local worldNum = text:match("World%s+(%d+)")
            if rank and worldNum then
                GateStatus:SetDesc("⚡ Gate: Rank "..rank.." | World "..worldNum)
                if isGateRankSelected(rank) and tonumber(worldNum) == SelectedGateWorld then
                    Fluent:Notify({ Title = "⚡ GATE ENCONTRADO", Content = "Rank "..rank.." | World "..worldNum, Duration = 5 })
                    if GateAutomationEnabled then
                        task.wait(0.4)
                        -- usa rotina completa (YES + fallback)
                        local ok = enterGateAutoFull()
                        if ok then
                            GateStatus:SetDesc("✅ Entrou no Gate automaticamente")
                        else
                            GateStatus:SetDesc("⚠️ Falha automática - tente manualmente")
                        end
                    else
                        GateStatus:SetDesc("⚠️ Gate encontrado - clique YES manualmente")
                    end
                else
                    GateStatus:SetDesc("✗ Gate Rank "..rank.." não selecionado")
                end
            end
        end
    end
end

local function setupGateDetector()
    local root = getGateNotifyRoot()
    if not root then return end
    root.ChildAdded:Connect(function(card)
        if tostring(card.Name):match("^Notify_Raid_") then
            task.spawn(function() task.wait(0.3) scanCurrentGates() end)
        end
    end)
    for _, card in ipairs(root:GetChildren()) do
        if tostring(card.Name):match("^Notify_Raid_") then
            card:GetPropertyChangedSignal("Visible"):Connect(function()
                if card.Visible then task.spawn(function() task.wait(0.3) scanCurrentGates() end) end
            end)
        end
    end
end

-- Interface Gate
AddGateSection()
GateStatus = Tabs.Gate:AddParagraph({ Title = "Status do Gate", Content = "Pronto para detectar" })

Tabs.Gate:AddDropdown("GateRank", {
    Title = "Ranks do Gate",
    Values = { "E", "D", "C", "B", "A", "S" },
    Multi = true,
    Default = { "C" },
    Callback = function(value)
        SelectedGateRanks = {}
        if type(value) == "table" then
            for k, v in pairs(value) do
                if type(k) == "string" and v == true then
                    SelectedGateRanks[k] = true
                elseif type(v) == "string" then
                    SelectedGateRanks[v] = true
                end
            end
        elseif type(value) == "string" then
            SelectedGateRanks[value] = true
        end
        GateStatus:SetDesc("Ranks escolhidos: " .. selectedRanksText())
    end
})

Tabs.Gate:AddToggle("AutoGateToggle", {
    Title = "Detectar Gate Automaticamente",
    Default = false,
    Callback = function(state)
        if not KeyPassed then
            AutoGateEnabled = false
            Fluent:Notify({ Title = "Key necessária", Content = "Digite a key primeiro.", Duration = 3 })
            return
        end
        AutoGateEnabled = state
        GateStatus:SetDesc(state and ("Procurando Gates: "..selectedRanksText()) or "Gate desativado")
        if state then
            Fluent:Notify({ Title = "Gate Detector Ativado", Content = "Monitorando notificações...", Duration = 3 })
            task.spawn(setupGateDetector)
            task.spawn(scanCurrentGates)
        end
    end
})

Tabs.Gate:AddToggle("GateAutomationToggle", {
    Title = "Clique Automático no YES + Portal Fallback",
    Default = false,
    Callback = function(state)
        GateAutomationEnabled = state
        if state then
            Fluent:Notify({ Title = "Automação Ativada", Content = "YES automático com fallback pelo portal", Duration = 3 })
        end
    end
})

Tabs.Gate:AddButton({
    Title = "Entrar no Gate (Forçar Agora)",
    Description = "Tenta YES e, se falhar, Station/Portal",
    Callback = function()
        local ok = enterGateAutoFull()
        GateStatus:SetDesc(ok and "✅ Entrou no Gate" or "❌ Falha ao entrar no Gate")
    end
})

Tabs.Gate:AddButton({
    Title = "Entrar pelo RaidStation (World 5)",
    Description = "Ignora o YES e usa a Station do mundo 5",
    Callback = function()
        local ok = enterGateByStation()
        GateStatus:SetDesc(ok and "✅ Entrou pelo RaidStation/SpawnGate" or "❌ Falha ao interagir com a Station do Gate")
    end
})

Tabs.Gate:AddButton({
    Title = "🖱️ Testar Click YES (Manual)",
    Description = "Clica no botão YES se a notificação estiver visível",
    Callback = function()
        local success = clickYesInCurrentGateNotify()
        GateStatus:SetDesc(success and "✅ YES clicado" or "❌ Não foi possível clicar no YES")
    end
})

Tabs.Gate:AddButton({
    Title = "🔄 Scanear Gates Agora",
    Description = "Força uma verificação imediata de Gates",
    Callback = function()
        if AutoGateEnabled then
            scanCurrentGates()
        else
            Fluent:Notify({ Title = "Atenção", Content = "Ative o detector de Gates primeiro", Duration = 3 })
        end
    end
})

-- ========== ARISE ==========
local function getFullPath(obj)
    if not obj then return "N/A" end
    local path = obj.Name
    local parent = obj.Parent
    local depth = 0
    while parent and depth < 10 do
        path = parent.Name .. "." .. path
        parent = parent.Parent
        depth = depth + 1
    end
    return path
end

local function scanAllArisePrompts(isManual)
    if not AutoAriseEnabled and not isManual then return {} end
    local foundPrompts = {}
    local worldCount = 0
    AriseDetectionCount = 0
    if not isManual then
        LastAriseEnemies = {}
        ActiveAriseWorlds = {}
    end
    local raidArenas = workspace:FindFirstChild("RaidArenas")
    if not raidArenas then
        if isManual then
            StatusArise:SetDesc("❌ Nenhuma RaidArenas encontrada")
        end
        return foundPrompts
    end
    for _, worldFolder in ipairs(raidArenas:GetChildren()) do
        if worldFolder:IsA("Folder") or worldFolder:IsA("Model") then
            local enemiesFolder = worldFolder:FindFirstChild("Enemies")
            if enemiesFolder then
                worldCount += 1
                ActiveAriseWorlds[worldFolder.Name] = true
                for _, enemy in ipairs(enemiesFolder:GetChildren()) do
                    if enemy:IsA("Model") then
                        local hrp = enemy:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            local arisePrompt = hrp:FindFirstChild("ArisePrompt")
                            if arisePrompt and arisePrompt:IsA("ProximityPrompt") then
                                local info = {
                                    enemyName = enemy.Name,
                                    worldName = worldFolder.Name,
                                    actionText = arisePrompt.ActionText or "ARISE",
                                    objectText = arisePrompt.ObjectText or "3 Chances",
                                    holdDuration = arisePrompt.HoldDuration or 1,
                                    fullPath = getFullPath(arisePrompt),
                                    promptObject = arisePrompt,
                                    enemyObject = enemy,
                                    hrpObject = hrp,
                                    activatedCount = 0,
                                    chances = 3
                                }
                                local ct = info.objectText
                                if ct then
                                    local n = tonumber(ct:match("%d+"))
                                    if n then info.chances = n end
                                end
                                if info.chances > 0 then
                                    table.insert(foundPrompts, info)
                                    AriseDetectionCount += 1
                                    LastAriseEnemies[enemy.Name] = info
                                    if isManual or AutoAriseEnabled then
                                        StatusArise:SetDesc(("✅ Arise: %s | %s | %s"):format(info.enemyName, info.worldName, info.objectText))
                                        local key = info.worldName.."|"..info.enemyName.."|"..info.objectText
                                        if not isManual and not NotifiedAriseKeys[key] then
                                            Fluent:Notify({ Title = "⚡ ARISE DETECTADO", Content = ("%s em %s (%s)"):format(info.enemyName, info.worldName, info.objectText), Duration = 5 })
                                            NotifiedAriseKeys[key] = true
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    if not isManual and AutoAriseEnabled then
        if AriseDetectionCount > 0 then
            local t = ("🔍 Procurando... | Encontrados: %d | Mundos ativos: %d"):format(AriseDetectionCount, worldCount)
            StatusArise:SetDesc(t) AriseStatusMessage = t
        else
            StatusArise:SetDesc("🔍 Procurando prompts ARISE... (nenhum encontrado)")
            AriseStatusMessage = "Procurando... (0 encontrados)"
        end
    end
    if isManual then
        StatusArise:SetDesc(AriseDetectionCount > 0 and ("✅ Verificação: "..AriseDetectionCount.." ARISE(s)") or "❌ Verificação: nenhum ARISE")
    end
    return foundPrompts
end

local function activateArisePrompt(promptInfo)
    if not promptInfo or not promptInfo.promptObject then return false end
    local prompt = promptInfo.promptObject
    if not prompt:IsA("ProximityPrompt") then return false end
    if not promptInfo.enemyObject or not promptInfo.enemyObject.Parent then return false end
    if not ensureCharacterAlive() then return false end
    local hrpPlayer = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrpPlayer then return false end
    local targetPosition = promptInfo.hrpObject.Position + Vector3.new(0, 3, 0)
    pcall(function() hrpPlayer.CFrame = CFrame.new(targetPosition) end)
    task.wait(0.1)
    local success = false
    pcall(function() if typeof(firesignal)=="function" then firesignal(prompt.Triggered) end success = true end)
    if not success then pcall(function() fireproximityprompt(prompt) success = true end) end
    if success then
        task.wait(0.3)
        if not prompt or not prompt.Parent then
            promptInfo.activatedCount = (promptInfo.activatedCount or 0) + 1
            Fluent:Notify({ Title = "✅ ARISE ATIVADO", Content = ("%s (%d/%d)"):format(promptInfo.enemyName, promptInfo.activatedCount, promptInfo.chances), Duration = 4 })
            StatusArise:SetDesc(("✅ ARISE ativado em %s | %d/%d"):format(promptInfo.enemyName, promptInfo.activatedCount, promptInfo.chances))
            return true
        end
    end
    return false
end

local function startAriseSystem()
    while task.wait(AriseCheckInterval) do
        if not AutoAriseEnabled then break end
        local raidArenas = workspace:FindFirstChild("RaidArenas")
        if not raidArenas then
            StatusArise:SetDesc("🔍 Aguardando modo Raid/Gate...")
            continue
        end
        local found = scanAllArisePrompts(false)
        if #found > 0 and AutoAriseActivation then
            for _, info in ipairs(found) do
                if not AutoAriseEnabled then break end
                if info.activatedCount < info.chances then
                    if activateArisePrompt(info) then task.wait(0.5) end
                end
            end
        end
    end
end

-- UI ARISE
AddAriseSection()
StatusArise = Tabs.Arise:AddParagraph({ Title = "Status do Arise", Content = "Sistema pronto" })
Tabs.Arise:AddButton({
    Title = "🔍 Verificar Arise (Manual)",
    Description = "Procura por prompts ARISE no momento atual",
    Callback = function()
        if not KeyPassed then
            Fluent:Notify({ Title = "Key necessária", Content = "Digite a key primeiro.", Duration = 3 })
            return
        end
        scanAllArisePrompts(true)
    end
})
Tabs.Arise:AddToggle("AutoAriseDetection", {
    Title = "Detectar Arise",
    Default = false,
    Callback = function(state)
        if not KeyPassed then
            AutoAriseEnabled = false
            Fluent:Notify({ Title = "Key necessária", Content = "Digite a key primeiro.", Duration = 3 })
            return
        end
        AutoAriseEnabled = state
        AriseStatusMessage = state and "Procurando ARISE..." or "Sistema desativado"
        StatusArise:SetDesc(AriseStatusMessage)
        if state then
            Fluent:Notify({ Title = "Auto Arise Ativado", Content = "Procurando por prompts ARISE...", Duration = 3 })
            task.spawn(startAriseSystem)
        end
    end
})
Tabs.Arise:AddToggle("AutoAriseActivation", {
    Title = "Ativar Automaticamente o Arise",
    Default = false,
    Callback = function(state)
        AutoAriseActivation = state
        if state then
            Fluent:Notify({ Title = "Ativação Automática", Content = "Vai clicar nos prompts ARISE automaticamente", Duration = 3 })
        end
    end
})
Tabs.Arise:AddSlider("AriseCheckInterval", { Title = "Intervalo de Verificação (segundos)", Min = 0.5, Max = 5, Default = 1.0, Rounding = 1, Callback = function(v) AriseCheckInterval = v end })
Tabs.Arise:AddSlider("AriseHoldDelay", { Title = "Delay Extra de Hold (segundos)", Min = 0.1, Max = 0.5, Default = 0.2, Rounding = 1, Callback = function(v) AriseHoldDelay = v end })

-- ========== DUNGEON ==========
AddDungeonSection()
StatusLabel = Tabs.Main:AddParagraph({ Title = "Status da Dungeon", Content = "Idle" })

Tabs.Main:AddToggle("AutoDungeon", {
    Title = "Auto Dungeon",
    Default = false,
    Callback = function(state)
        if not KeyPassed then
            AutoDungeonEnabled = false
            Fluent:Notify({ Title = "Key necessária", Content = "Digite a key primeiro.", Duration = 3 })
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
            Fluent:Notify({ Title = "Key necessária", Content = "Digite a key primeiro.", Duration = 3 })
            return
        end
        AutoLeaveEnabled = state
    end
})

Tabs.Main:AddSlider("LeaveRoom", { Title = "Leave Room", Min = 1, Max = 50, Default = 50, Rounding = 0.1, Callback = function(v) LeaveRoom = v end })

-- ========== BALL ==========
AddBallSection()
BallStatus = Tabs.Ball:AddParagraph({ Title = "Status", Content = "Auto Ball parado" })
Tabs.Ball:AddSlider("BallRadius", { Title = "Raio de busca", Min = 300, Max = 1000, Default = 650, Rounding = 0, Callback = function(v) BallRadius = v end })
Tabs.Ball:AddSlider("BallCooldown", { Title = "Cooldown", Min = 0.1, Max = 2, Default = 0.4, Rounding = 1, Callback = function(v) BallCooldown = v end })
Tabs.Ball:AddToggle("AutoBall", {
    Title = "Ativar Auto Ball",
    Default = false,
    Callback = function(state)
        if not KeyPassed then
            AutoBallEnabled = false
            Fluent:Notify({ Title = "Key necessária", Content = "Digite a key primeiro.", Duration = 3 })
            BallStatus:SetDesc("Digite a key primeiro")
            return
        end
        AutoBallEnabled = state
        BallStatus:SetDesc(state and "Auto Ball ligado" or "Auto Ball parado")
    end
})

local function findNearbyBalls()
    local out = {}
    if not ensureCharacterAlive() then return out end
    local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return out end
    local folder = workspace:FindFirstChild(ballsFolderName)
    if not folder then return out end
    local pos = hrp.Position
    for _, m in ipairs(folder:GetChildren()) do
        local s = m:FindFirstChild(sphereName)
        if s and s:IsA("BasePart") then
            local prompt = s:FindFirstChild(promptName)
            if prompt and prompt:IsA("ProximityPrompt") then
                local d = (s.Position - pos).Magnitude
                if d <= BallRadius then
                    table.insert(out, { model = m, sphere = s, prompt = prompt, distance = d })
                end
            end
        end
    end
    table.sort(out, function(a,b) return a.distance < b.distance end)
    return out
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
    if not ensureCharacterAlive() then return false end
    local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local sphere = ballData.sphere
    local prompt = ballData.prompt
    local model = ballData.model
    if (sphere.Position - hrp.Position).Magnitude > BallRadius then return false end
    currentTarget = model.Name
    BallStatus:SetDesc("Coletando: "..currentTarget)
    local target = sphere.Position + Vector3.new(0,2.5,0)
    local tween = TweenService:Create(hrp, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = CFrame.new(target) })
    tween:Play() tween.Completed:Wait()
    task.wait(0.15)
    local ok = holdPrompt(prompt)
    if ok then
        for _ = 1, 20 do
            if not model or not model.Parent then
                collectedCount += 1
                return true
            end
            task.wait(0.1)
        end
    end
    return false
end

local function collectionLoop()
    while task.wait(0.1) do
        if not AutoBallEnabled then
            currentTarget = "Nenhum"
            BallStatus:SetDesc("Auto Ball parado")
            continue
        end
        if not ensureCharacterAlive() then
            LocalPlayer.CharacterAdded:Wait()
            task.wait(1)
            continue
        end
        local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end
        local balls = findNearbyBalls()
        if #balls == 0 then
            currentTarget = "Nenhuma bola próxima"
            BallStatus:SetDesc("Procurando bolas...")
            task.wait(0.5)
            continue
        end
        for _, b in ipairs(balls) do
            if not AutoBallEnabled then break end
            if not ensureCharacterAlive() then break end
            if b and b.sphere and b.sphere.Parent then
                if collectBall(b) then task.wait(BallCooldown) else task.wait(0.15) end
            end
        end
    end
end

-- ========== LOOP PRINCIPAL DUNGEON ==========
task.spawn(function()
    while task.wait(0.03) do
        if not AutoDungeonEnabled then
            StatusLabel:SetDesc("Waiting (Disabled)")
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
                        StatusLabel:SetDesc("Dungeon notify detectada, esperando 0.5s...")
                        task.wait(0.5)
                        StatusLabel:SetDesc("Clicando YES da Dungeon...")
                        robustClickObject(yesBtn)
                        task.wait(1)
                    end
                end
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
            StatusLabel:SetDesc("Dungeon ativa - farmando...")
        else
            if AutoDungeonEnabled then
                StatusLabel:SetDesc("Waiting for Dungeon invite...")
            end
        end
    end
end)

-- ========== WATCHDOG (Gate/Dungeon) ==========
task.spawn(function()
    local lastGateSeen = tick()
    local lastDungeonSeen = tick()
    while task.wait(0.6) do
        local notify = getGateNotifyRoot()
        local gateVisible = false
        local dungeonVisible = false
        pcall(function()
            if notify then
                for _, card in ipairs(notify:GetChildren()) do
                    if card.Visible then
                        if tostring(card.Name):match("^Notify_Raid_") then
                            gateVisible = true
                        elseif tostring(card.Name):lower():find("dungeon") then
                            dungeonVisible = true
                        end
                    end
                end
            end
        end)
        if gateVisible then lastGateSeen = tick() end
        if dungeonVisible then lastDungeonSeen = tick() end

        -- Gate: se sem notify e não entrou, tenta rotina completa
        if AutoGateEnabled and GateAutomationEnabled then
            if (tick() - lastGateSeen > 4) and (not isInAnyGate()) then
                enterGateAutoFull()
                lastGateSeen = tick()
            end
        end

        -- Dungeon: se fora e sem notify, tenta Station
        if AutoDungeonEnabled then
            local inDungeon = false
            pcall(function()
                local dA = workspace:FindFirstChild("DungeonArenas")
                if dA then
                    for _, arena in ipairs(dA:GetChildren()) do
                        if arena:FindFirstChild("Enemies") then inDungeon = true break end
                    end
                end
            end)
            if (not inDungeon) and (tick() - lastDungeonSeen > 4) then
                enterDungeonByStation()
                lastDungeonSeen = tick()
            end
        end
    end
end)

-- ========== INICIALIZAÇÃO ==========
task.spawn(collectionLoop)
task.spawn(autoJoinLoop)
task.spawn(startAriseSystem)

Window:SelectTab(2)
Fluent:Notify({
    Title = "✅ Script Carregado",
    Content = "YES + Portal fallback adicionados. Módulos prontos.",
    Duration = 3
})
