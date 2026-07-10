local safeWait = (task and task.wait) or wait
repeat safeWait() until game:IsLoaded()

-- Anti-duplicacao: quando executar de novo, os loops desta versao antiga param.
local SCRIPT_TOKEN = tostring(os.clock()) .. "_" .. tostring(math.random(100000, 999999))
local function getScriptEnv()
    if typeof(getgenv) == "function" then
        return getgenv()
    end
    return _G
end
local SCRIPT_ENV = getScriptEnv()
SCRIPT_ENV.BR_ANIME_ASTRAL_ACTIVE_TOKEN = SCRIPT_TOKEN
local function scriptActive()
    local env = getScriptEnv()
    return not env or env.BR_ANIME_ASTRAL_ACTIVE_TOKEN == SCRIPT_TOKEN
end

local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Carregar Fluent UI
local FLUENT_URL = "https://raw.githubusercontent.com/0eujunioofc/eae/main/junio.lua"

local okHttp, source = pcall(function()
    return game:HttpGet(FLUENT_URL)
end)

if not okHttp or type(source) ~= "string" or source == "" then
    warn("Erro ao baixar Fluent:", source)
    return
end

local fluentFunc, loadErr = loadstring(source)

if not fluentFunc then
    warn("Erro no loadstring do Fluent:", loadErr)
    return
end

local okFluent, Fluent = pcall(fluentFunc)

if not okFluent or not Fluent then
    warn("Fluent não carregou:", Fluent)
    return
end

-- Anti-spam de notificacoes: evita varias mensagens iguais empilhadas.
local NotifyHistory = {}
local NOTIFY_COOLDOWN = 3
local RawFluentNotify = Fluent.Notify
function Fluent:Notify(data)
    if type(RawFluentNotify) ~= "function" then
        return nil
    end
    if type(data) ~= "table" then
        return RawFluentNotify(self, data)
    end

    local title = tostring(data.Title or "")
    local content = tostring(data.Content or "")
    local key = title .. "|" .. content
    local now = os.clock()

    if NotifyHistory[key] and (now - NotifyHistory[key]) < NOTIFY_COOLDOWN then
        return nil
    end

    NotifyHistory[key] = now
    return RawFluentNotify(self, data)
end

local Window = Fluent:CreateWindow({
    Title = 'BR Anime Astral PRO', 
    SubTitle = "eujunioofc", 
    TabWidth = 160, 
    Size = UDim2.fromOffset(550, 450), 
    Acrylic = false, 
    Theme = "Dark", 
    MinimizeKey = Enum.KeyCode.LeftControl
})

local KeyPassed = false
local CorrectKey = "A200915E"

local Tabs = { 
    Updates = Window:AddTab({ Title = "Updates", Icon = "info" }), 
    Key = Window:AddTab({ Title = "Key", Icon = "key" }), 
    Gamemodes = Window:AddTab({ Title = "Gamemodes", Icon = "circle" }), 
    Misc = Window:AddTab({ Title = "Misc", Icon = "settings" }), 
    Settings = Window:AddTab({ Title = "Settings", Icon = "sliders-horizontal" })
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
    return tab:AddParagraph({ Title = " ", Content = " " })
end

-- Separador padrao dos modulos
local function AddSection(tab, title, desc)
    AddSpace(tab)
    return tab:AddParagraph({ Title = "========== " .. title .. " ==========", Content = desc or "" })
end

-- Separadores prontos para cada modulo
local function AddGateSection()
    return AddSection(Tabs.Gate, "AUTO GATE", "[FORA DO MODO] Detecta notificacoes de Gate na hora e aceita 1 vez.")
end

local function AddAutoJoinSection()
    return AddSection(Tabs.AutoJoin, "AUTO JOIN / SERVER", "[FORA DO MODO] Procura botoes Join, Entrar ou Play. Nao aceita o YES do Gate.")
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

-- VARIÁVEIS DO AUTO ARISE
local AutoAriseEnabled = false
local AutoAriseActivation = false
local AriseCheckInterval = 1.0
local AriseHoldDelay = 0.2
local AriseDetectionCount = 0
local LastAriseEnemies = {}
local ActiveAriseWorlds = {}
local NotifiedAriseKeys = {}
local AriseStatusMessage = "Sistema desativado"

-- VARIÁVEIS DO AUTO GATE
local AutoGateEnabled = false
local SelectedGateRanks = { C = true }
local SelectedGateWorld = 5
local GateAutomationEnabled = false

-- VARIÁVEIS DO AUTO JOIN
local AutoJoinEnabled = false
local JoinDetectionInterval = 1.0

-- VARIÁVEIS DO AUTO DUNGEON
local AutoDungeonEnabled = false
local AutoLeaveEnabled = false
local LeaveRoom = 50

-- VARIÁVEIS DO SISTEMA DE PRIORIDADE V2
local PrioritySystemEnabled = false
local LeaveForHigherPriority = true
local Priority = {
    Gate = 1,
    Dungeon = 2,
    TimelessRaid = 3
}
-- Gate aparece a cada 10 minutos; Dungeon aparece a cada 15 minutos.
local ModeIntervalSeconds = {
    Gate = 10 * 60,
    Dungeon = 15 * 60
}
-- Janela depois do horário exato para considerar que o modo acabou de começar.
local START_WINDOW = 120
-- Quanto tempo antes de um modo prioritário começar o script tenta sair do modo atual.
local PREP_LEAVE_BEFORE = 90
local PRIORITY_LOOP_INTERVAL = 1
local PRIORITY_ACTION_COOLDOWN = 8
local CurrentPriorityMode = "Idle"
local PriorityGateDetectorStarted = false
local PriorityLastNotify = {}
local PriorityLastAction = {}
local PriorityLastLeaveAt = 0
local PriorityLastStatusText = ""
local PriorityLastStatusAt = 0
local PriorityDebugEnabled = true
local PriorityDebugLines = {}
local PriorityDebugLastLine = ""
local PriorityDebugLastAt = 0

-- VARIÁVEIS DO AUTO BALL
local AutoBallEnabled = false
local BallRadius = 600
local BallCooldown = 0.4
local ballsFolderName = "World8Balls"
local sphereName = "Sphere.004"
local promptName = "BallClaimPrompt"
local collectedCount = 0
local currentTarget = "Nenhum"

-- Elementos da interface
local StatusArise, GateStatus, JoinStatus, BallStatus, StatusLabel, LeaveInfo, PriorityStatus, PriorityDebugLog

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

Tabs.Updates:AddParagraph({ Title = "Version v1.0.0", Content = "[PRO] Sistema completo com Auto Gate, Auto Join e Auto Arise" })
Tabs.Updates:AddParagraph({ Title = "Version v0.2.0", Content = "[Gate] Sistema completo de automação com click YES automático" })
Tabs.Updates:AddParagraph({ Title = "Version v0.1.6", Content = "[Auto Arise] Sistema completo de detecção e ativação" })

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

-- FUNÇÕES COMPARTILHADAS
local function robustClickObject(obj)
    if not obj then return false end

    local methods = {
        function()
            if typeof(fireclick) == "function" then
                fireclick(obj)
                return true
            end
            return false
        end,
        function()
            if obj:IsA("TextButton") or obj:IsA("ImageButton") then
                if typeof(firesignal) == "function" then
                    pcall(function() firesignal(obj.MouseButton1Click) end)
                    pcall(function() firesignal(obj.Activated) end)
                    return true
                end
            end
            return false
        end,
        function()
            if obj.AbsoluteSize and obj.AbsoluteSize.X > 0 and obj.AbsoluteSize.Y > 0 then
                local inset = GuiService:GetGuiInset()
                local x = obj.AbsolutePosition.X + (obj.AbsoluteSize.X / 2)
                local y = obj.AbsolutePosition.Y + (obj.AbsoluteSize.Y / 2) + inset.Y
                VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
                task.wait(0.02)
                VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)
                return true
            end
            return false
        end
    }
    
    for _, method in ipairs(methods) do
        local ok, res = pcall(method)
        if ok and res then
            return true
        end
    end
    return false
end

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

local function teleportToPosition(position)
    if not ensureCharacterAlive() then
        return false
    end

    local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        return false
    end
    
    pcall(function() 
        hrp.CFrame = CFrame.new(position + Vector3.new(0, 3, 0)) 
    end)
    return true
end

-- ========== FUNÇÕES AUXILIARES PARA WORLDS ==========
local function getRaidStationForWorld(worldNumber)
    local worlds = workspace:FindFirstChild("Worlds")
    if not worlds then
        return nil
    end

    local worldFolder = worlds:FindFirstChild(tostring(worldNumber))
    if not worldFolder then
        return nil
    end

    local systems = worldFolder:FindFirstChild("Systems")
    if not systems then
        return nil
    end

    local raidStation = systems:FindFirstChild("RaidStation")
    return raidStation
end

local function getRaidStationPositionForWorld(worldNumber)
    local raidStation = getRaidStationForWorld(worldNumber)
    if not raidStation then return nil end
    
    local pos
    if raidStation:IsA("BasePart") then
        pos = raidStation.Position
    elseif raidStation:IsA("Model") and raidStation.PrimaryPart then
        pos = raidStation.PrimaryPart.Position
    else
        local bp = raidStation:FindFirstChildWhichIsA("BasePart", true)
        pos = bp and bp.Position or nil
    end
    return pos, raidStation
end

local function partCenter(inst)
    if inst:IsA("BasePart") then
        return inst.Position
    elseif inst:IsA("Model") and inst.PrimaryPart then
        return inst.PrimaryPart.Position
    elseif inst:IsA("Model") then
        local pp = inst:FindFirstChildWhichIsA("BasePart", true)
        return pp and pp.Position or nil
    end
    return nil
end

-- ========== VERIFY GATE ENTRY ==========
local function verifyGateEntry()
    local raidArenas = workspace:FindFirstChild("RaidArenas")
    if raidArenas then
        for _, world in ipairs(raidArenas:GetChildren()) do
            local enemies = world:FindFirstChild("Enemies")
            if enemies then
                return true
            end
        end
    end

    local raidStation = getRaidStationForWorld(SelectedGateWorld)
    if raidStation then
        local wFolder = workspace:FindFirstChild("Worlds")
        local curWorld = wFolder and wFolder:FindFirstChild(tostring(SelectedGateWorld))
        if curWorld and (curWorld:FindFirstChild("SpawnGate") or curWorld:FindFirstChild("Teleporter")) then
            return true
        end
    end
    return false
end

local function isGateRankSelected(rank)
    if not rank then return false end
    return SelectedGateRanks[rank] == true
end

local function selectedRanksText()
    local list = {}
    for _, rank in ipairs({ "E", "D", "C", "B", "A", "S" }) do
        if SelectedGateRanks[rank] then
            table.insert(list, rank)
        end
    end
    if #list == 0 then
        return "Nenhum"
    end
    return table.concat(list, ", ")
end

-- ========== FIND AND ACTIVATE SPAWN GATE (teleporte garantido) ==========
local function findAndActivateSpawnGate()
    local raidStation = getRaidStationForWorld(SelectedGateWorld)
    if not raidStation then
        return false
    end

    local pos = getRaidStationPositionForWorld(SelectedGateWorld)
    if not pos then
        return false
    end
    
    -- Teleporta até o RaidStation do mundo alvo
    if not teleportToPosition(pos + Vector3.new(0, 3, 0)) then
        return false
    end
    task.wait(0.25)
    
    -- Tenta tocar a peça para acionar TouchInterest
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local touchPart = raidStation:IsA("BasePart") and raidStation or raidStation:FindFirstChildWhichIsA("BasePart", true)
    
    if hrp and touchPart and touchPart:FindFirstChildOfClass("TouchInterest") then
        pcall(function()
            firetouchinterest(hrp, touchPart, 0)
            task.wait(0.05)
            firetouchinterest(hrp, touchPart, 1)
        end)
        task.wait(0.15)
    end
    
    -- ProximityPrompt direto no RaidStation (ou em BasePart filho)
    local prox = raidStation:FindFirstChildOfClass("ProximityPrompt") or (touchPart and touchPart:FindFirstChildOfClass("ProximityPrompt"))
    if prox then
        pcall(function()
            fireproximityprompt(prox)
        end)
        task.wait(0.1)
    end
    
    -- Se houver GUI de confirmação, clica YES/Confirm
    local guiObj = raidStation:FindFirstChild("Gui")
    if guiObj then
        for _, d in ipairs(guiObj:GetDescendants()) do
            if d:IsA("TextButton") or d:IsA("ImageButton") then
                local nm = (d.Name or ""):lower()
                local tx = (d.Text or ""):lower()
                if nm:find("yes") or nm:find("confirm") or tx:find("yes") or tx:find("confirm") then
                    if robustClickObject(d) then
                        return true
                    end
                end
            end
        end
    end
    return verifyGateEntry()
end

-- ========== SISTEMA DE AUTO JOIN ==========
local function findJoinButtons()
    local joinButtons = {}
    local guiLocations = { LocalPlayer.PlayerGui, game:GetService("CoreGui") }
    
    for _, gui in ipairs(guiLocations) do
        pcall(function()
            for _, child in ipairs(gui:GetDescendants()) do
                if child:IsA("TextButton") or child:IsA("ImageButton") then
                    local text = child.Text or ""
                    local name = child.Name or ""
                    if text:lower():find("join") or name:lower():find("join") or 
                       text:lower():find("entrar") or name:lower():find("entrar") or 
                       text:lower():find("play") or name:lower():find("play") then
                        table.insert(joinButtons, child)
                    end
                end
            end
        end)
    end
    return joinButtons
end

local function autoJoinLoop()
    while scriptActive() and task.wait(JoinDetectionInterval) do
        if not AutoJoinEnabled then
            if JoinStatus then
                JoinStatus:SetDesc("Auto Join desativado")
            end
            continue
        end
        
        if JoinStatus then
            JoinStatus:SetDesc("Procurando botões JOIN...")
        end

        local joinButtons = findJoinButtons()
        if #joinButtons > 0 then
            if JoinStatus then
                JoinStatus:SetDesc("✅ " .. #joinButtons .. " botões JOIN encontrados")
            end
            
            for _, button in ipairs(joinButtons) do
                if not AutoJoinEnabled then
                    break
                end
                
                if JoinStatus then
                    JoinStatus:SetDesc("Clicando no botão JOIN...")
                end

                local clicked = robustClickObject(button)
                if clicked then
                    Fluent:Notify({ Title = "✅ JOIN clicado", Content = "Entrando no servidor...", Duration = 3 })
                    if JoinStatus then
                        JoinStatus:SetDesc("✅ JOIN realizado - aguardando carregamento")
                    end
                    task.wait(3)
                    break
                end
            end
        else
            if JoinStatus then
                JoinStatus:SetDesc("❌ Nenhum botão JOIN encontrado")
            end
        end
    end
end

-- ========== CLICK YES NA NOTIFICAÇÃO ATUAL ==========
local function clickYesInCurrentGateNotify()
    if not ensureCharacterAlive() then return false end
    
    local notifyRoot = LocalPlayer.PlayerGui:FindFirstChild("HUD")
        and LocalPlayer.PlayerGui.HUD:FindFirstChild("Main")
        and LocalPlayer.PlayerGui.HUD.Main:FindFirstChild("GamemodeNotify")
    
    if not notifyRoot then return false end
    
    for _, card in ipairs(notifyRoot:GetChildren()) do
        if card:IsA("GuiObject") and card.Name:match("^Notify_Raid_") and card.Visible == true then
            local description = card:FindFirstChild("Description")
            if description and description:IsA("TextLabel") then
                local text = description.Text or ""
                if text:lower():find("gate") then
                    local actions = card:FindFirstChild("Actions")
                    if actions then
                        local yesButtons = {
                            actions:FindFirstChild("YES"),
                            actions:FindFirstChild("Yes"),
                            actions:FindFirstChild("CONFIRM"),
                            actions:FindFirstChild("Confirm")
                        }
                        
                        local function afterYes()
                            Fluent:Notify({ Title = "✅ YES clicado", Content = "Gate aceito. Indo ao RaidStation...", Duration = 3 })
                            -- Teleporte direto para o RaidStation
                            task.spawn(function()
                                task.wait(0.35)
                                local pos, rs = getRaidStationPositionForWorld(SelectedGateWorld)
                                if pos then
                                    teleportToPosition(pos + Vector3.new(0, 3, 0))
                                end
                                task.wait(0.25)
                                -- Aciona o Spawn/Gate via RaidStation
                                if not verifyGateEntry() then
                                    local ok = findAndActivateSpawnGate()
                                    if not ok then
                                        task.wait(0.5)
                                        findAndActivateSpawnGate()
                                    end
                                end
                            end)
                        end
                        
                        for _, btn in ipairs(yesButtons) do
                            if btn and (btn:IsA("TextButton") or btn:IsA("ImageButton")) then
                                if robustClickObject(btn) then
                                    afterYes()
                                    return true
                                end
                            end
                        end
                        
                        -- Percorre descendentes caso o botão não esteja nos nomes padrão
                        for _, child in ipairs(actions:GetDescendants()) do
                            if (child:IsA("TextButton") or child:IsA("ImageButton")) then
                                local childName = (child.Name or ""):lower()
                                local childText = (child.Text or ""):lower()
                                if childName:find("yes") or childText:find("yes") or
                                   childName:find("confirm") or childText:find("confirm") then
                                    if robustClickObject(child) then
                                        Fluent:Notify({ Title = "✅ Botão confirmado", Content = "Gate aceito. Indo ao RaidStation...", Duration = 3 })
                                        task.spawn(function()
                                            task.wait(0.35)
                                            local pos, rs = getRaidStationPositionForWorld(SelectedGateWorld)
                                            if pos then
                                                teleportToPosition(pos + Vector3.new(0, 3, 0))
                                            end
                                            task.wait(0.25)
                                            if not verifyGateEntry() then
                                                local ok = findAndActivateSpawnGate()
                                                if not ok then
                                                    task.wait(0.5)
                                                    findAndActivateSpawnGate()
                                                end
                                            end
                                        end)
                                        return true
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return false
end

-- FUNÇÃO QUE LÊ APENAS QUANDO A NOTIFICAÇÃO APARECER
local function scanCurrentGates()
    if not AutoGateEnabled then return end

    local success, notifyRoot = pcall(function()
        return LocalPlayer.PlayerGui:WaitForChild("HUD"):WaitForChild("Main"):WaitForChild("GamemodeNotify")
    end)
    
    if not success or not notifyRoot then return end
    
    for _, card in ipairs(notifyRoot:GetChildren()) do
        if card:IsA("GuiObject") and card.Name:match("^Notify_Raid_") and card.Visible then
            local desc = card:FindFirstChild("Description")
            if not (desc and desc:IsA("TextLabel")) then
                continue
            end

            local text = desc.Text or ""
            if not text:lower():find("gate") then
                continue
            end
            
            -- Extrair Rank e World da mensagem
            local rank = (text:match("[Rr]ank%s*([SABCDEF])"))
            local worldNum = text:match("[Ww]orld%s*(%d+)")
            
            if not rank or not worldNum then
                continue
            end
            
            GateStatus:SetDesc(("⚡ Gate encontrado: Rank %s | World %s"):format(rank, worldNum))
            local worldOk = (tonumber(worldNum) == tonumber(SelectedGateWorld))
            local rankOk = isGateRankSelected(rank)
            
            if not (rankOk and worldOk) then
                GateStatus:SetDesc(("✗ Ignorado (Rank %s / World %s) - Filtro: Ranks [%s] | World %d"):format(rank, worldNum, selectedRanksText(), SelectedGateWorld))
                continue
            end
            
            Fluent:Notify({
                Title = "⚡ GATE ELEGÍVEL",
                Content = ("Rank %s | World %s"):format(rank, worldNum),
                Duration = 5
            })
            
            if GateAutomationEnabled then
                task.wait(0.3)
                local clicked = clickYesInCurrentGateNotify()
                if clicked then
                    GateStatus:SetDesc(("✅ Gate Rank %s aceito automaticamente!"):format(rank))
                    return
                end
                
                -- Fallback: ativar o SpawnGate pelo RaidStation (com teleporte)
                local spawnActivated = findAndActivateSpawnGate()
                if spawnActivated then
                    GateStatus:SetDesc(("✅ SpawnGate ativado via RaidStation (Rank %s | World %s)"):format(rank, worldNum))
                else
                    GateStatus:SetDesc("⚠️ Falha ao ativar o gate através do spawn")
                end
            else
                GateStatus:SetDesc("⚠️ Gate elegível - clique YES manualmente (automação OFF)")
            end
        end
    end
end

-- Detector de novas notificações
local function setupGateDetector()
    local success, notifyRoot = pcall(function()
        return LocalPlayer.PlayerGui:WaitForChild("HUD"):WaitForChild("Main"):WaitForChild("GamemodeNotify")
    end)

    if success and notifyRoot then
        notifyRoot.ChildAdded:Connect(function(card)
            if not scriptActive() then return end
            if card.Name:match("^Notify_Raid_") then
                task.spawn(function()
                    task.wait(0.25)
                    if scriptActive() then
                        scanCurrentGates()
                    end
                end)
            end
        end)

        for _, card in ipairs(notifyRoot:GetChildren()) do
            if card.Name:match("^Notify_Raid_") then
                card:GetPropertyChangedSignal("Visible"):Connect(function()
                    if not scriptActive() then return end
                    if card:IsA("GuiObject") and card.Visible then
                        task.spawn(function()
                            task.wait(0.25)
                            if scriptActive() then
                                scanCurrentGates()
                            end
                        end)
                    end
                end)
            end
        end
    end
end

-- Interface do Gate
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

Tabs.Gate:AddSlider("GateWorld", {
    Title = "World alvo", 
    Min = 1, 
    Max = 12, 
    Default = 5, 
    Rounding = 0, 
    Callback = function(v) 
        SelectedGateWorld = math.floor(v) 
        GateStatus:SetDesc(("World alvo: %d | Ranks: %s"):format(SelectedGateWorld, selectedRanksText()))
    end
})

Tabs.Gate:AddToggle("AutoGateToggle", {
    Title = "Detectar Gate Automaticamente", 
    Default = false, 
    Callback = function(state) 
        if state and not KeyPassed then
            AutoGateEnabled = false
            Fluent:Notify({ Title = "Key necessária", Content = "Digite a key primeiro.", Duration = 3 })
            return
        end
        AutoGateEnabled = state
        GateStatus:SetDesc(state and ("Procurando Gates: " .. selectedRanksText()) or "Gate desativado")
        if state then
            Fluent:Notify({ Title = "Gate Detector Ativado", Content = "Aguardando o horário do spawn para notificação...", Duration = 3 })
            task.spawn(setupGateDetector)
            task.spawn(scanCurrentGates)
        end
    end
})

Tabs.Gate:AddToggle("GateAutomationToggle", {
    Title = "Clique Automático no YES", 
    Description = "Ao surgir a notificação no horário, clica YES 1 vez (com fallback).", 
    Default = false, 
    Callback = function(state) 
        GateAutomationEnabled = state
        if state then
            Fluent:Notify({ Title = "Automação Ativada", Content = "Aceitará o Gate somente quando notificado.", Duration = 3 })
        end
    end
})

-- ========== SISTEMA DE AUTO ARISE ==========
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
    if not AutoAriseEnabled and not isManual then
        return {}
    end

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
            local worldName = worldFolder.Name
            local enemiesFolder = worldFolder:FindFirstChild("Enemies")
            if enemiesFolder then
                worldCount = worldCount + 1
                ActiveAriseWorlds[worldName] = true
                
                for _, enemy in ipairs(enemiesFolder:GetChildren()) do
                    if enemy:IsA("Model") then
                        local hrp = enemy:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            local arisePrompt = hrp:FindFirstChild("ArisePrompt")
                            if arisePrompt and arisePrompt:IsA("ProximityPrompt") then
                                local promptInfo = {
                                    enemyName = enemy.Name,
                                    worldName = worldName,
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
                                
                                local chancesText = promptInfo.objectText
                                if chancesText then
                                    local chanceNumber = tonumber(chancesText:match("%d+"))
                                    if chanceNumber then
                                        promptInfo.chances = chanceNumber
                                    end
                                end
                                
                                if promptInfo.chances <= 0 then
                                    continue
                                end
                                
                                table.insert(foundPrompts, promptInfo)
                                AriseDetectionCount = AriseDetectionCount + 1
                                LastAriseEnemies[enemy.Name] = promptInfo
                                
                                if isManual or AutoAriseEnabled then
                                    local statusMsg = string.format("✅ Arise encontrado: %s | %s | %s", promptInfo.enemyName, promptInfo.worldName, promptInfo.objectText)
                                    StatusArise:SetDesc(statusMsg)
                                    
                                    local ariseKey = promptInfo.worldName .. "|" .. promptInfo.enemyName .. "|" .. promptInfo.objectText
                                    if not isManual and not NotifiedAriseKeys[ariseKey] then
                                        Fluent:Notify({ 
                                            Title = "⚡ ARISE DETECTADO", 
                                            Content = string.format("%s em %s (%s)", promptInfo.enemyName, promptInfo.worldName, promptInfo.objectText), 
                                            Duration = 5 
                                        })
                                        NotifiedAriseKeys[ariseKey] = true
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
            local statusText = string.format("🔍 Procurando... | Encontrados: %d | Mundos ativos: %d", AriseDetectionCount, worldCount)
            StatusArise:SetDesc(statusText)
            AriseStatusMessage = statusText
        else
            StatusArise:SetDesc("🔍 Procurando prompts ARISE... (nenhum encontrado)")
            AriseStatusMessage = "Procurando... (0 encontrados)"
        end
    end
    
    if isManual then
        if AriseDetectionCount > 0 then
            StatusArise:SetDesc(string.format("✅ Verificação manual: %d ARISE(s) encontrado(s)", AriseDetectionCount))
        else
            StatusArise:SetDesc("❌ Verificação manual: Nenhum ARISE encontrado")
        end
    end
    
    return foundPrompts
end

local function activateArisePrompt(promptInfo)
    if not promptInfo or not promptInfo.promptObject then
        return false
    end

    local prompt = promptInfo.promptObject
    if not prompt or not prompt:IsA("ProximityPrompt") then
        return false
    end
    
    if not promptInfo.enemyObject or not promptInfo.enemyObject.Parent then
        return false
    end

    local character = LocalPlayer.Character
    if not character then
        return false
    end

    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        return false
    end

    local hrpPlayer = character:FindFirstChild("HumanoidRootPart")
    if not hrpPlayer then
        return false
    end

    local targetPosition = promptInfo.hrpObject.Position + Vector3.new(0, 3, 0)
    pcall(function() 
        hrpPlayer.CFrame = CFrame.new(targetPosition) 
    end)
    task.wait(0.1)
    
    local success = false
    pcall(function() 
        firesignal(prompt.Triggered) 
        success = true 
    end)
    
    if not success then
        pcall(function() 
            fireproximityprompt(prompt) 
            success = true 
        end)
    end
    
    if success then
        task.wait(0.3)
        if not prompt or not prompt.Parent then
            promptInfo.activatedCount = (promptInfo.activatedCount or 0) + 1
            Fluent:Notify({ 
                Title = "✅ ARISE ATIVADO", 
                Content = string.format("%s (%d/%d chances)", promptInfo.enemyName, promptInfo.activatedCount, promptInfo.chances), 
                Duration = 4 
            })
            StatusArise:SetDesc(string.format("✅ ARISE ativado em %s | %d/%d chances", promptInfo.enemyName, promptInfo.activatedCount, promptInfo.chances))
            return true
        end
    end
    
    return false
end

local function startAriseSystem()
    while scriptActive() and task.wait(AriseCheckInterval) do
        if not AutoAriseEnabled then
            break
        end

        local raidArenas = workspace:FindFirstChild("RaidArenas")
        if not raidArenas then
            StatusArise:SetDesc("🔍 Aguardando modo Raid/Gate...")
            continue
        end

        local foundPrompts = scanAllArisePrompts(false)
        if #foundPrompts > 0 and AutoAriseActivation then
            for _, promptInfo in ipairs(foundPrompts) do
                if not AutoAriseEnabled then
                    break
                end
                
                if promptInfo.activatedCount < promptInfo.chances then
                    local success = activateArisePrompt(promptInfo)
                    if success then
                        task.wait(0.5)
                    end
                end
            end
        end
    end
end

-- Interface do Auto Arise
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
        if state and not KeyPassed then
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
            Fluent:Notify({ Title = "Ativação Automática", Content = "O sistema vai clicar nos prompts ARISE automaticamente", Duration = 3 })
        end
    end
})

Tabs.Arise:AddSlider("AriseCheckInterval", {
    Title = "Intervalo de Verificação (segundos)", 
    Min = 0.5, 
    Max = 5, 
    Default = 1.0, 
    Rounding = 1, 
    Callback = function(value) 
        AriseCheckInterval = value 
    end
})

Tabs.Arise:AddSlider("AriseHoldDelay", {
    Title = "Delay Extra de Hold (segundos)", 
    Min = 0.1, 
    Max = 0.5, 
    Default = 0.2, 
    Rounding = 1, 
    Callback = function(value) 
        AriseHoldDelay = value 
    end
})

-- ========== SISTEMA DE AUTO DUNGEON ==========
AddDungeonSection()
StatusLabel = Tabs.Main:AddParagraph({ Title = "Status da Dungeon", Content = "Idle" })

Tabs.Main:AddToggle("AutoDungeon", {
    Title = "Auto Dungeon", 
    Default = false, 
    Callback = function(state) 
        if state and not KeyPassed then
            AutoDungeonEnabled = false
            Fluent:Notify({ Title = "Key necessária", Content = "Digite a key primeiro.", Duration = 3 })
            return
        end
        AutoDungeonEnabled = state
    end
})

-- ========== FUNCOES DO AUTO LEAVE ==========
local function getCurrentDungeonRoom()
    local dungeonGui = LocalPlayer.PlayerGui:FindFirstChild("DungeonGui")
    if not dungeonGui then
        return 0
    end

    local main = dungeonGui:FindFirstChild("Main")
    if not main then
        return 0
    end

    local roomLabel = main:FindFirstChild("Room")
    if not roomLabel or not roomLabel:IsA("TextLabel") then
        return 0
    end

    local text = roomLabel.Text or ""
    local roomNumber = tonumber(text:match("%d+"))

    return roomNumber or 0
end

local function findLeaveButton()
    local dungeonGui = LocalPlayer.PlayerGui:FindFirstChild("DungeonGui")
    if not dungeonGui then
        return nil
    end

    local main = dungeonGui:FindFirstChild("Main")
    if not main then
        return nil
    end

    local leaveBtn = main:FindFirstChild("Leave")
    if leaveBtn and (leaveBtn:IsA("TextButton") or leaveBtn:IsA("ImageButton")) then
        return leaveBtn
    end

    for _, child in ipairs(main:GetDescendants()) do
        if child:IsA("TextButton") or child:IsA("ImageButton") then
            local name = (child.Name or ""):lower()
            local text = (child.Text or ""):lower()

            if name:find("leave") or text:find("leave") or name:find("sair") or text:find("sair") then
                return child
            end
        end
    end

    return nil
end

local function setLeaveInfo(text)
    if LeaveInfo then
        pcall(function()
            LeaveInfo:SetDesc(text)
        end)
    end
end

local leaveAlreadyClicked = false
local leaveClickedRoom = 0

local function autoLeaveLoop()
    while scriptActive() and task.wait(1) do
        if not AutoLeaveEnabled then
            leaveAlreadyClicked = false
            leaveClickedRoom = 0
            setLeaveInfo("Auto Leave desativado")
            continue
        end

        local currentRoom = getCurrentDungeonRoom()

        if currentRoom <= 0 then
            leaveAlreadyClicked = false
            leaveClickedRoom = 0
            setLeaveInfo("Fora da Dungeon (sala: 0)")
            continue
        end

        if currentRoom < LeaveRoom then
            leaveAlreadyClicked = false
            leaveClickedRoom = 0
            setLeaveInfo(("Dungeon ativo | Sala atual: %d | Limite: %d"):format(currentRoom, LeaveRoom))
            continue
        end

        if leaveAlreadyClicked then
            setLeaveInfo(("Leave ja clicado na sala %d. Aguardando sair da Dungeon..."):format(leaveClickedRoom))
            continue
        end

        local leaveButton = findLeaveButton()

        if leaveButton then
            setLeaveInfo(("Botao Leave encontrado. Saindo... (%d >= %d)"):format(currentRoom, LeaveRoom))

            local clicked = robustClickObject(leaveButton)

            if clicked then
                leaveAlreadyClicked = true
                leaveClickedRoom = currentRoom

                Fluent:Notify({
                    Title = "AUTO LEAVE",
                    Content = ("Saiu da Dungeon na sala %d (limite: %d)"):format(currentRoom, LeaveRoom),
                    Duration = 5
                })

                setLeaveInfo("Leave clicado uma vez. Aguardando nova Dungeon...")
                task.wait(5)
            else
                setLeaveInfo("Falha ao clicar no Leave")
                task.wait(2)
            end
        else
            setLeaveInfo(("Botao Leave nao encontrado | Sala: %d | Limite: %d"):format(currentRoom, LeaveRoom))
            task.wait(2)
        end
    end
end

-- ========== AUTO LEAVE ==========
AddSpace(Tabs.Main)

Tabs.Main:AddParagraph({
    Title = "========== AUTO LEAVE ==========",
    Content = "[DENTRO DO MODO] Sai automaticamente quando atinge sala especifica"
})

LeaveInfo = Tabs.Main:AddParagraph({
    Title = "Status do Auto Leave",
    Content = "Aguardando Dungeon...",
    Id = "LeaveInfo"
})

Tabs.Main:AddToggle("AutoLeaveToggle", {
    Title = "Ativar Auto Leave",
    Description = "Sai da Dungeon automaticamente na sala configurada",
    Default = false,
    Callback = function(state)
        if state and not KeyPassed then
            AutoLeaveEnabled = false
            Fluent:Notify({
                Title = "Key necessaria",
                Content = "Digite a key primeiro.",
                Duration = 3
            })
            return
        end

        AutoLeaveEnabled = state

        if state then
            LeaveInfo:SetDesc(("Auto Leave ativado | Sair na sala %d"):format(LeaveRoom))
            Fluent:Notify({
                Title = "Auto Leave ativado",
                Content = ("Saira automaticamente na sala %d."):format(LeaveRoom),
                Duration = 3
            })
        else
            LeaveInfo:SetDesc("Auto Leave desativado")
        end
    end
})

Tabs.Main:AddSlider("LeaveRoomSlider", {
    Title = "Sala para sair",
    Description = "Saira automaticamente quando atingir esta sala",
    Min = 1,
    Max = 50,
    Default = 50,
    Rounding = 0,
    Callback = function(value)
        LeaveRoom = math.floor(value)

        if LeaveInfo then
            LeaveInfo:SetDesc(("Limite ajustado para sala %d | Atual: %d"):format(LeaveRoom, getCurrentDungeonRoom()))
        end
    end
})

Tabs.Main:AddButton({
    Title = "Testar deteccao agora",
    Description = "Verifica sala atual e botao Leave",
    Callback = function()
        if not KeyPassed then
            Fluent:Notify({
                Title = "Key necessaria",
                Content = "Digite a key primeiro.",
                Duration = 3
            })
            return
        end

        local currentRoom = getCurrentDungeonRoom()
        local leaveButton = findLeaveButton()   

        LeaveInfo:SetDesc(
            ("Sala atual: %d | Limite: %d | Botao Leave: %s")
            :format(currentRoom, LeaveRoom, leaveButton and "SIM" or "NAO")
        )

        Fluent:Notify({
            Title = "Teste de deteccao",
            Content = ("Sala: %d | Botao: %s"):format(currentRoom, leaveButton and "Encontrado" or "Nao encontrado"),
            Duration = 4
        })
    end
})
-- ========== SISTEMA DE PRIORIDADE DE ENTRADA V3 ==========
local function setPriorityStatus(text, force)
    if not PriorityStatus then
        return
    end

    local now = os.clock()
    if not force and text == PriorityLastStatusText and (now - PriorityLastStatusAt) < 1 then
        return
    end

    PriorityLastStatusText = text
    PriorityLastStatusAt = now

    pcall(function()
        PriorityStatus:SetDesc(text)
    end)
end

local function priorityDebugAdd(text, force)
    if not PriorityDebugEnabled then
        return
    end

    local now = os.clock()
    text = tostring(text or "")

    if not force and text == PriorityDebugLastLine and (now - PriorityDebugLastAt) < 2 then
        return
    end

    PriorityDebugLastLine = text
    PriorityDebugLastAt = now

    local line = os.date("%H:%M:%S") .. " | " .. text
    table.insert(PriorityDebugLines, 1, line)

    while #PriorityDebugLines > 10 do
        table.remove(PriorityDebugLines)
    end

    pcall(function()
        print("[PRIORITY DEBUG] " .. line)
    end)

    if PriorityDebugLog then
        pcall(function()
            PriorityDebugLog:SetDesc(table.concat(PriorityDebugLines, "\n"))
        end)
    end
end

local function priorityBoolText(value)
    return value and "ON" or "OFF"
end

local function hasVisibleGateNotify()
    local notifyRoot = LocalPlayer.PlayerGui:FindFirstChild("HUD")
        and LocalPlayer.PlayerGui.HUD:FindFirstChild("Main")
        and LocalPlayer.PlayerGui.HUD.Main:FindFirstChild("GamemodeNotify")

    if not notifyRoot then
        return false
    end

    for _, card in ipairs(notifyRoot:GetChildren()) do
        if card:IsA("GuiObject") and card.Name:match("^Notify_Raid_") and card.Visible then
            return true
        end
    end

    return false
end

local function formatPrioritySeconds(seconds)
    seconds = math.max(0, math.floor(tonumber(seconds) or 0))
    local minutes = math.floor(seconds / 60)
    local rest = seconds % 60
    if minutes > 0 then
        return string.format("%dm%02ds", minutes, rest)
    end
    return tostring(rest) .. "s"
end

local function intervalTiming(intervalSeconds)
    intervalSeconds = math.max(1, tonumber(intervalSeconds) or 60)

    -- Usa horario real alinhado com o relogio:
    -- Gate 10min = :00, :10, :20, :30, :40, :50
    -- Dungeon 15min = :00, :15, :30, :45
    local now = os.time()
    local sinceLast = now % intervalSeconds
    local toNext = (intervalSeconds - sinceLast) % intervalSeconds

    return {
        sinceLast = sinceLast,
        toNext = toNext,
        active = sinceLast <= START_WINDOW,
        preparing = toNext > 0 and toNext <= PREP_LEAVE_BEFORE,
        eventIndex = math.floor(now / intervalSeconds)
    }
end

local function getModeTiming(modeName)
    local interval = ModeIntervalSeconds[modeName]
    if not interval then
        return nil
    end
    return intervalTiming(interval)
end

local function getModePriority(modeName)
    return Priority[modeName] or 99
end

local function getPriorityEventKey(modeName, timing)
    if not timing then
        return modeName .. "_none"
    end

    if timing.active then
        return modeName .. "_active_" .. tostring(timing.eventIndex)
    end

    return modeName .. "_next_" .. tostring(timing.eventIndex + 1)
end

local function priorityNotifyOnce(key, title, content, duration, cooldown)
    local now = os.clock()
    cooldown = cooldown or 10

    if PriorityLastNotify[key] and (now - PriorityLastNotify[key]) < cooldown then
        return false
    end

    PriorityLastNotify[key] = now
    Fluent:Notify({
        Title = title,
        Content = content,
        Duration = duration or 3
    })
    return true
end

local function priorityActionAllowed(key, cooldown)
    local now = os.clock()
    cooldown = cooldown or PRIORITY_ACTION_COOLDOWN

    if PriorityLastAction[key] and (now - PriorityLastAction[key]) < cooldown then
        return false
    end

    PriorityLastAction[key] = now
    return true
end

local function isGuiObjectVisible(obj)
    if not obj or not obj:IsA("GuiObject") then
        return false
    end

    local ok, visible = pcall(function()
        return obj.Visible
    end)

    return ok and visible == true
end

local function isPlayerInDungeonByGui()
    local room = 0
    pcall(function()
        room = getCurrentDungeonRoom and getCurrentDungeonRoom() or 0
    end)

    if type(room) == "number" and room > 0 then
        return true
    end

    local dungeonGui = LocalPlayer.PlayerGui:FindFirstChild("DungeonGui")
    local main = dungeonGui and dungeonGui:FindFirstChild("Main")
    local leaveButton = main and main:FindFirstChild("Leave")
    local roomLabel = main and main:FindFirstChild("Room")

    if isGuiObjectVisible(leaveButton) then
        return true
    end

    if isGuiObjectVisible(roomLabel) then
        return true
    end

    return false
end

local function hasChildrenFolderWithEnemies(rootName)
    local root = workspace:FindFirstChild(rootName)
    if not root then
        return false
    end

    for _, arena in ipairs(root:GetChildren()) do
        local enemies = arena:FindFirstChild("Enemies")
        if enemies then
            return true
        end
    end

    return false
end

local function detectCurrentPriorityMode()
    -- V3: nao usa DungeonArenas sozinho, porque a pasta pode existir mesmo fora da dungeon.
    if isPlayerInDungeonByGui() then
        return "Dungeon"
    end

    if hasChildrenFolderWithEnemies("RaidArenas") then
        return "Gate"
    end

    return "Idle"
end

local function canRunGate()
    return KeyPassed and AutoGateEnabled
end

local function canRunDungeon()
    return KeyPassed and AutoDungeonEnabled
end

local function buildPriorityCandidates()
    local candidates = {}
    local gateTiming = getModeTiming("Gate")
    local dungeonTiming = getModeTiming("Dungeon")

    if canRunGate() and gateTiming then
        table.insert(candidates, {
            name = "Gate",
            priority = getModePriority("Gate"),
            timing = gateTiming,
            active = gateTiming.active,
            preparing = gateTiming.preparing,
            toNext = gateTiming.toNext,
            sinceLast = gateTiming.sinceLast,
            eventKey = getPriorityEventKey("Gate", gateTiming)
        })
    end

    if canRunDungeon() and dungeonTiming then
        table.insert(candidates, {
            name = "Dungeon",
            priority = getModePriority("Dungeon"),
            timing = dungeonTiming,
            active = dungeonTiming.active,
            preparing = dungeonTiming.preparing,
            toNext = dungeonTiming.toNext,
            sinceLast = dungeonTiming.sinceLast,
            eventKey = getPriorityEventKey("Dungeon", dungeonTiming)
        })
    end

    return candidates, gateTiming, dungeonTiming
end

local function choosePriorityCandidate(candidates)
    local urgent = {}

    for _, candidate in ipairs(candidates) do
        if candidate.active or candidate.preparing then
            table.insert(urgent, candidate)
        end
    end

    local function sortByPriorityThenPhaseThenTime(a, b)
        if a.priority ~= b.priority then
            return a.priority < b.priority
        end

        -- Mesma prioridade: o que ja esta ativo vem antes do que ainda esta preparando.
        if a.active ~= b.active then
            return a.active == true
        end

        return a.toNext < b.toNext
    end

    if #urgent > 0 then
        table.sort(urgent, sortByPriorityThenPhaseThenTime)
        urgent[1].reason = urgent[1].active and "active" or "preparing"
        return urgent[1]
    end

    table.sort(candidates, function(a, b)
        if a.priority ~= b.priority then
            return a.priority < b.priority
        end
        return a.toNext < b.toNext
    end)

    if candidates[1] then
        candidates[1].reason = "waiting"
    end

    return candidates[1]
end

local function shouldLeaveForCandidate(currentMode, candidate)
    if not LeaveForHigherPriority then
        return false
    end

    if not candidate or currentMode == "Idle" or currentMode == candidate.name then
        return false
    end

    local currentPriority = getModePriority(currentMode)
    if candidate.priority >= currentPriority then
        return false
    end

    return candidate.active or candidate.preparing or candidate.toNext <= PREP_LEAVE_BEFORE
end

local function tryPriorityLeave(targetMode, currentMode, candidate)
    if os.clock() - PriorityLastLeaveAt < 8 then
        priorityDebugAdd("Saida ignorada por cooldown | atual=" .. tostring(currentMode) .. " alvo=" .. tostring(targetMode))
        return false
    end

    PriorityLastLeaveAt = os.clock()
    priorityDebugAdd("Tentando sair por prioridade | atual=" .. tostring(currentMode) .. " alvo=" .. tostring(targetMode), true)

    if currentMode == "Dungeon" then
        local leaveButton = findLeaveButton()
        priorityDebugAdd("Botao Leave detectado: " .. priorityBoolText(leaveButton ~= nil), true)
        if leaveButton then
            setPriorityStatus("Prioridade: saindo da Dungeon para preparar " .. targetMode, true)
            local clicked = robustClickObject(leaveButton)
            priorityDebugAdd("Clique no Leave: " .. priorityBoolText(clicked), true)
            if clicked then
                priorityNotifyOnce(
                    "priority_leave_" .. tostring(targetMode) .. "_" .. tostring(candidate and candidate.eventKey or "event"),
                    "PRIORIDADE",
                    "Saiu da Dungeon para priorizar " .. targetMode,
                    4,
                    20
                )
                CurrentPriorityMode = "Idle"
                return true
            end
        end
    end

    setPriorityStatus("Prioridade: " .. targetMode .. " e mais importante, mas nao achei uma saida segura de " .. tostring(currentMode), true)
    return false
end

local function ensureGateDetectorByPriority()
    if not PriorityGateDetectorStarted then
        PriorityGateDetectorStarted = true
        priorityDebugAdd("Detector do Gate iniciado pela prioridade", true)
        task.spawn(setupGateDetector)
    else
        priorityDebugAdd("Detector do Gate ja estava iniciado")
    end
end

local function forceGateAttemptByPriority(candidate)
    priorityDebugAdd(
        "Gate tentativa | AutoGate=" .. priorityBoolText(AutoGateEnabled)
        .. " YES=" .. priorityBoolText(GateAutomationEnabled)
        .. " Notify=" .. priorityBoolText(hasVisibleGateNotify())
        .. " RaidStation=" .. priorityBoolText(getRaidStationForWorld(SelectedGateWorld) ~= nil)
        .. " World=" .. tostring(SelectedGateWorld),
        true
    )

    if not GateAutomationEnabled then
        setPriorityStatus("Gate priorizado, mas 'Clique Automatico no YES' esta desligado.", true)
        priorityNotifyOnce(
            "priority_gate_yes_off_" .. tostring(candidate and candidate.eventKey or "event"),
            "PRIORIDADE",
            "Gate venceu, mas ligue 'Clique Automatico no YES' para entrar sozinho.",
            4,
            20
        )
        return false
    end

    local actionKey = "force_gate_" .. tostring(candidate and candidate.eventKey or "event")
    if not priorityActionAllowed(actionKey, 10) then
        return false
    end

    local success = false

    pcall(function()
        -- 1) tenta aceitar notificacao que ja esta aberta
        success = clickYesInCurrentGateNotify()
        priorityDebugAdd("Gate passo 1 notify aberto: " .. priorityBoolText(success), true)

        -- 2) se ainda nao foi, forca uma varredura e tenta aceitar de novo
        if not success then
            scanCurrentGates()
            task.wait(0.25)
            success = clickYesInCurrentGateNotify()
            priorityDebugAdd("Gate passo 2 scan + notify: " .. priorityBoolText(success), true)
        end

        -- 3) se perdeu a notificacao, tenta o fallback pelo RaidStation/SpawnGate
        if not success then
            success = findAndActivateSpawnGate()
            priorityDebugAdd("Gate passo 3 RaidStation fallback: " .. priorityBoolText(success), true)
        end
    end)

    if success then
        priorityNotifyOnce(
            "priority_gate_success_" .. tostring(candidate and candidate.eventKey or "event"),
            "PRIORIDADE",
            "Gate priorizado e tentativa de entrada acionada.",
            4,
            20
        )
        setPriorityStatus("Gate priorizado: tentativa de entrada acionada.", true)
    else
        setPriorityStatus("Gate priorizado, mas nao achei notificacao/portal valido ainda.", true)
    end

    return success
end

local function startGateByPriority(candidate)
    CurrentPriorityMode = "Gate"
    priorityDebugAdd("Start Gate por prioridade | evento=" .. tostring(candidate and candidate.eventKey or "event"), true)
    ensureGateDetectorByPriority()

    local actionKey = "start_gate_" .. tostring(candidate and candidate.eventKey or "event")
    if priorityActionAllowed(actionKey, 12) then
        setPriorityStatus("Gate venceu a prioridade. Procurando notificacao/portal...", true)
        task.spawn(function()
            if scriptActive() then
                forceGateAttemptByPriority(candidate)
            end
        end)
    end
end

local function startDungeonByPriority(candidate)
    CurrentPriorityMode = "Dungeon"
    priorityDebugAdd("Start Dungeon por prioridade | evento=" .. tostring(candidate and candidate.eventKey or "event"), true)

    local actionKey = "start_dungeon_" .. tostring(candidate and candidate.eventKey or "event")
    if priorityActionAllowed(actionKey, 12) then
        priorityNotifyOnce(
            "priority_start_dungeon_" .. tostring(candidate and candidate.eventKey or "event"),
            "PRIORIDADE",
            "Dungeon esta na janela de entrada. Auto Dungeon pode aceitar o convite.",
            3,
            20
        )
    end
end

local function describePriorityTiming(gateTiming, dungeonTiming)
    local gateText = gateTiming and (gateTiming.active and ("agora +" .. formatPrioritySeconds(gateTiming.sinceLast)) or ("em " .. formatPrioritySeconds(gateTiming.toNext))) or "OFF"
    local dungeonText = dungeonTiming and (dungeonTiming.active and ("agora +" .. formatPrioritySeconds(dungeonTiming.sinceLast)) or ("em " .. formatPrioritySeconds(dungeonTiming.toNext))) or "OFF"
    return gateText, dungeonText
end

local function prioritySchedulerLoop()
    while scriptActive() and task.wait(PRIORITY_LOOP_INTERVAL) do
        if not PrioritySystemEnabled then
            setPriorityStatus("Sistema de prioridade desativado")
            continue
        end

        local candidates, gateTiming, dungeonTiming = buildPriorityCandidates()
        local gateText, dungeonText = describePriorityTiming(gateTiming, dungeonTiming)
        local currentMode = detectCurrentPriorityMode()
        CurrentPriorityMode = currentMode

        if #candidates == 0 then
            setPriorityStatus("Sem candidato ativo | Gate: " .. gateText .. " | Dungeon: " .. dungeonText .. " | Confira Key/Auto Gate/Auto Dungeon")
            priorityDebugAdd("Sem candidato | Key=" .. priorityBoolText(KeyPassed) .. " AutoGate=" .. priorityBoolText(AutoGateEnabled) .. " AutoDungeon=" .. priorityBoolText(AutoDungeonEnabled))
            continue
        end

        local winner = choosePriorityCandidate(candidates)
        if not winner then
            setPriorityStatus("Nenhum vencedor definido | Gate: " .. gateText .. " | Dungeon: " .. dungeonText)
            continue
        end

        local phaseText = "Aguardando"
        if winner.reason == "active" then
            phaseText = "Entrando agora"
        elseif winner.reason == "preparing" then
            phaseText = "Preparando entrada"
        end

        setPriorityStatus(
            ("%s: %s | Atual: %s | Gate: %s P%d | Dungeon: %s P%d")
            :format(
                phaseText,
                winner.name,
                currentMode,
                gateText,
                Priority.Gate,
                dungeonText,
                Priority.Dungeon
            )
        )

        priorityDebugAdd(
            "Winner=" .. tostring(winner.name)
            .. " fase=" .. tostring(winner.reason)
            .. " atual=" .. tostring(currentMode)
            .. " Gate=" .. tostring(gateText)
            .. " Dungeon=" .. tostring(dungeonText)
            .. " P(G/D)=" .. tostring(Priority.Gate) .. "/" .. tostring(Priority.Dungeon)
        )

        if shouldLeaveForCandidate(currentMode, winner) then
            priorityDebugAdd("Decisao: sair do modo atual para " .. tostring(winner.name), true)
            tryPriorityLeave(winner.name, currentMode, winner)
            continue
        end

        -- V3: se o Gate venceu e ja esta ativo, tenta entrar mesmo que o estado atual tenha ficado confuso.
        -- Isso evita perder o Gate depois de sair da Dungeon e voltar ao mundo.
        if winner.name == "Gate" and winner.active then
            priorityDebugAdd("Gate ativo venceu | currentMode=" .. tostring(currentMode), true)
            if currentMode == "Idle" or currentMode == "Dungeon" then
                startGateByPriority(winner)
            else
                priorityDebugAdd("Gate venceu, mas currentMode nao permite start: " .. tostring(currentMode), true)
            end
            continue
        end

        -- Se um modo superior esta em preparacao, nao inicia modo inferior nesse intervalo.
        if winner.reason == "preparing" then
            continue
        end

        if currentMode == "Idle" and winner.active then
            if winner.name == "Dungeon" then
                startDungeonByPriority(winner)
            end
        elseif winner.active then
            priorityDebugAdd("Modo ativo venceu, mas atual nao esta Idle | vencedor=" .. tostring(winner.name) .. " atual=" .. tostring(currentMode))
        end
    end
end

-- UI do sistema de prioridade
AddSpace(Tabs.Settings)
Tabs.Settings:AddParagraph({
    Title = "========== PRIORIDADE DE ENTRADA V3 ==========" ,
    Content = "Gate a cada 10min e Dungeon a cada 15min. No mesmo minuto, menor prioridade numerica ganha."
})

PriorityStatus = Tabs.Settings:AddParagraph({
    Title = "Status da Prioridade",
    Content = "Sistema de prioridade desativado"
})

PriorityDebugLog = Tabs.Settings:AddParagraph({
    Title = "Debug da Prioridade",
    Content = "Aguardando eventos..."
})

Tabs.Settings:AddToggle("PriorityDebugToggle", {
    Title = "Debug da Prioridade",
    Description = "Mostra o que o sistema decidiu: vencedor, modo atual, notify, YES e RaidStation.",
    Default = true,
    Callback = function(state)
        PriorityDebugEnabled = state
        if state then
            priorityDebugAdd("Debug ativado", true)
        elseif PriorityDebugLog then
            PriorityDebugLog:SetDesc("Debug desativado")
        end
    end
})

Tabs.Settings:AddButton({
    Title = "Testar prioridade agora",
    Description = "Mostra Gate/Dungeon, modo atual e vencedor sem forcar entrada.",
    Callback = function()
        local candidates, gateTiming, dungeonTiming = buildPriorityCandidates()
        local gateText, dungeonText = describePriorityTiming(gateTiming, dungeonTiming)
        local currentMode = detectCurrentPriorityMode()
        local winner = choosePriorityCandidate(candidates)
        local winnerText = winner and (winner.name .. " / " .. tostring(winner.reason)) or "Nenhum"

        priorityDebugAdd(
            "TESTE MANUAL | vencedor=" .. winnerText
            .. " atual=" .. tostring(currentMode)
            .. " Gate=" .. tostring(gateText)
            .. " Dungeon=" .. tostring(dungeonText)
            .. " AutoGate=" .. priorityBoolText(AutoGateEnabled)
            .. " YES=" .. priorityBoolText(GateAutomationEnabled)
            .. " Notify=" .. priorityBoolText(hasVisibleGateNotify()),
            true
        )
    end
})

Tabs.Settings:AddToggle("PrioritySystemToggle", {
    Title = "Ativar Prioridade de Entrada",
    Description = "Gerencia Gate/Dungeon por horario real, prioridade e anti-spam.",
    Default = false,
    Callback = function(state)
        PrioritySystemEnabled = state
        setPriorityStatus(state and "Sistema de prioridade V3 ativado" or "Sistema de prioridade desativado", true)
    end
})

Tabs.Settings:AddToggle("LeaveForHigherPriorityToggle", {
    Title = "Sair por prioridade maior",
    Description = "Se um modo mais importante estiver chegando, tenta sair do modo atual sem desligar seus toggles.",
    Default = true,
    Callback = function(state)
        LeaveForHigherPriority = state
        setPriorityStatus(state and "Sair por prioridade maior: ON" or "Sair por prioridade maior: OFF", true)
    end
})

Tabs.Settings:AddDropdown("GatePriority", {
    Title = "Prioridade do Gate",
    Values = { "1", "2", "3", "4", "5" },
    Default = tostring(Priority.Gate),
    Callback = function(value)
        Priority.Gate = tonumber(value) or 1
        setPriorityStatus("Prioridade do Gate: " .. tostring(Priority.Gate), true)
    end
})

Tabs.Settings:AddDropdown("DungeonPriority", {
    Title = "Prioridade da Dungeon",
    Values = { "1", "2", "3", "4", "5" },
    Default = tostring(Priority.Dungeon),
    Callback = function(value)
        Priority.Dungeon = tonumber(value) or 2
        setPriorityStatus("Prioridade da Dungeon: " .. tostring(Priority.Dungeon), true)
    end
})

Tabs.Settings:AddSlider("PriorityStartWindow", {
    Title = "Janela de entrada (segundos)",
    Description = "Tempo depois do horario exato em que ainda tenta entrar.",
    Min = 30,
    Max = 240,
    Default = START_WINDOW,
    Rounding = 0,
    Callback = function(value)
        START_WINDOW = math.floor(value)
        setPriorityStatus("Janela de entrada: " .. tostring(START_WINDOW) .. "s", true)
    end
})

Tabs.Settings:AddSlider("PriorityPrepLeave", {
    Title = "Preparar saida antes (segundos)",
    Description = "Tempo antes de um modo prioritario para tentar sair do modo atual.",
    Min = 15,
    Max = 180,
    Default = PREP_LEAVE_BEFORE,
    Rounding = 0,
    Callback = function(value)
        PREP_LEAVE_BEFORE = math.floor(value)
        setPriorityStatus("Preparar saida: " .. tostring(PREP_LEAVE_BEFORE) .. "s", true)
    end
})

Tabs.Settings:AddParagraph({
    Title = "Como funciona",
    Content = "Gate: 10min | Dungeon: 15min | Coincide em :00/:30 | P1 ganha de P2 | Para entrar sozinho no Gate, deixe Auto Gate e Clique YES ligados."
})

-- ========== SISTEMA DE AUTO BALL ==========
AddBallSection()
BallStatus = Tabs.Ball:AddParagraph({ Title = "Status", Content = "Auto Ball parado" })

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

Tabs.Ball:AddToggle("AutoBall", {
    Title = "Ativar Auto Ball", 
    Default = false, 
    Callback = function(state) 
        if state and not KeyPassed then
            AutoBallEnabled = false
            Fluent:Notify({ Title = "Key necessária", Content = "Digite a key primeiro.", Duration = 3 })
            BallStatus:SetDesc("Digite a key primeiro")
            return
        end
        AutoBallEnabled = state
        BallStatus:SetDesc(state and "Auto Ball ligado" or "Auto Ball parado")
    end
})

-- Funções do Auto Ball
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
    if not prompt or not prompt:IsA("ProximityPrompt") then
        return false
    end

    local holdTime = prompt.HoldDuration
    local success = pcall(function()
        prompt:InputHoldBegin()
        task.wait(holdTime + 0.15)
        prompt:InputHoldEnd()
    end)
    return success
end

local function collectBall(ballData)
    if not ballData or not ballData.sphere or not ballData.prompt then
        return false
    end
    
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
    BallStatus:SetDesc("Coletando: " .. currentTarget)
    
    local targetPosition = sphere.Position + Vector3.new(0, 2.5, 0)
    local tweenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(humanoidRootPart, tweenInfo, { CFrame = CFrame.new(targetPosition) })
    tween:Play()
    tween.Completed:Wait()
    task.wait(0.15)
    
    local activated = holdPrompt(prompt)
    if activated then
        for _ = 1, 20 do
            if not ballModel or not ballModel.Parent then
                collectedCount += 1
                return true
            end
            task.wait(0.1)
        end
    end
    return false
end

local function collectionLoop()
    while scriptActive() and task.wait(0.1) do
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

        local humanoidRootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then
            continue
        end

        local balls = findNearbyBalls()
        if #balls == 0 then
            currentTarget = "Nenhuma bola próxima"
            BallStatus:SetDesc("Procurando bolas...")
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

-- ========== SISTEMA DE AUTO FARM DUNGEON ==========
AddSpace(Tabs.Gamemodes)
Tabs.Gamemodes:AddParagraph({
    Title = "========== AUTO FARM DUNGEON ==========",
    Content = "[DENTRO DO MODO] Teleporta automaticamente para os NPCs Joker/Sho na Dungeon."
})

-- Variáveis do Auto Farm Dungeon
local AutoFarmDungeon = false
local TargetNPCs = { "Joker", "Sho" }
local FarmRadius = 50
local FarmCooldown = 1.5
local FarmStatus = "Aguardando entrada na Dungeon"

-- Elemento de status
local FarmStatusLabel = Tabs.Gamemodes:AddParagraph({
    Title = "Status do Farm",
    Content = FarmStatus
})

-- Função para encontrar NPCs da dungeon no ClientEnemyVisuals
local function findDungeonNPCs()
    local npcs = {}
    local clientVisuals = workspace:FindFirstChild("ClientEnemyVisuals")
    
    if not clientVisuals then
        return npcs
    end
    
    for _, npcName in ipairs(TargetNPCs) do
        local npcModel = clientVisuals:FindFirstChild(npcName)
        if npcModel and npcModel:IsA("Model") then
            local hrp = npcModel:FindFirstChild("HumanoidRootPart")
            local torso = npcModel:FindFirstChild("Torso") or npcModel:FindFirstChild("UpperTorso")
            local anyPart = npcModel:FindFirstChildWhichIsA("BasePart")
            
            local targetPart = hrp or torso or anyPart
            if targetPart then
                table.insert(npcs, {
                    name = npcName,
                    model = npcModel,
                    part = targetPart,
                    position = targetPart.Position
                })
            end
        end
    end
    return npcs
end

-- Função para teleportar até um NPC
local function teleportToNPC(npcInfo)
    if not ensureCharacterAlive() then
        return false
    end
    
    local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        return false
    end
    
    local targetPos = npcInfo.position + Vector3.new(0, 3, 0)
    pcall(function()
        hrp.CFrame = CFrame.new(targetPos)
    end)
    
    return true
end

-- Loop principal de farm
local function farmDungeonLoop()
    while scriptActive() and task.wait(0.5) do
        if not AutoFarmDungeon then
            FarmStatus = "Auto Farm desativado"
            FarmStatusLabel:SetDesc(FarmStatus)
            continue
        end
        
        local inDungeon = false
        pcall(function()
            local dungeonArenas = workspace:FindFirstChild("DungeonArenas")
            if dungeonArenas then
                for _, arena in ipairs(dungeonArenas:GetChildren()) do
                    if arena:FindFirstChild("Enemies") then
                        inDungeon = true
                        break
                    end
                end
            end
        end)
        
        if not inDungeon then
            FarmStatus = "Aguardando entrada na Dungeon..."
            FarmStatusLabel:SetDesc(FarmStatus)
            continue
        end
        
        local npcs = findDungeonNPCs()
        
        if #npcs == 0 then
            FarmStatus = "Dentro da Dungeon, mas nenhum NPC (Joker/Sho) encontrado."
            FarmStatusLabel:SetDesc(FarmStatus)
            task.wait(2)
            continue
        end
        
        for _, npc in ipairs(npcs) do
            if not AutoFarmDungeon then
                break
            end
            
            FarmStatus = string.format("Farmando: %s", npc.name)
            FarmStatusLabel:SetDesc(FarmStatus)
            
            local teleported = teleportToNPC(npc)
            if teleported then
                task.wait(FarmCooldown)
            end
        end
    end
end

-- Interface do Auto Farm Dungeon
Tabs.Gamemodes:AddToggle("AutoFarmDungeonToggle", {
    Title = "Ativar Auto Farm Dungeon",
    Default = false,
    Callback = function(state)
        if state and not KeyPassed then
            AutoFarmDungeon = false
            Fluent:Notify({
                Title = "Key necessária",
                Content = "Digite a key primeiro.",
                Duration = 3
            })
            return
        end
        
        AutoFarmDungeon = state
        FarmStatus = state and "Auto Farm ativado. Aguardando Dungeon..." or "Auto Farm desativado"
        FarmStatusLabel:SetDesc(FarmStatus)
        
        if state then
            Fluent:Notify({
                Title = "Auto Farm ativado",
                Content = "Teleportará para Joker/Sho ao entrar na Dungeon.",
                Duration = 3
            })
            task.spawn(farmDungeonLoop)
        end
    end
})

Tabs.Gamemodes:AddSlider("FarmRadiusSlider", {
    Title = "Raio de detecção (distância)",
    Description = "Máximo: 100 (não usado atualmente, mas disponível para lógica futura)",
    Min = 10,
    Max = 100,
    Default = 50,
    Rounding = 0,
    Callback = function(value)
        FarmRadius = value
        FarmStatusLabel:SetDesc(string.format("Raio ajustado: %d | %s", FarmRadius, FarmStatus))
    end
})

Tabs.Gamemodes:AddSlider("FarmCooldownSlider", {
    Title = "Cooldown entre teleportes (s)",
    Min = 0.5,
    Max = 5,
    Default = 1.5,
    Rounding = 0.1,
    Callback = function(value)
        FarmCooldown = value
        FarmStatusLabel:SetDesc(string.format("Cooldown: %.1fs | %s", FarmCooldown, FarmStatus))
    end
})

Tabs.Gamemodes:AddButton({
    Title = "🔍 Verificar NPCs agora (Manual)",
    Description = "Procura Joker/Sho no ClientEnemyVisuals e mostra status.",
    Callback = function()
        if not KeyPassed then
            Fluent:Notify({
                Title = "Key necessária",
                Content = "Digite a key primeiro.",
                Duration = 3
            })
            return
        end
        
        local npcs = findDungeonNPCs()
        if #npcs > 0 then
            local msg = ""
            for _, npc in ipairs(npcs) do
                msg = msg .. string.format("- %s (pos: %s)\n", npc.name, tostring(npc.position))
            end
            FarmStatusLabel:SetDesc(string.format("NPCs encontrados (%d):\n%s", #npcs, msg))
            Fluent:Notify({
                Title = "NPCs encontrados",
                Content = string.format("%d NPC(s) localizado(s).", #npcs),
                Duration = 4
            })
        else
            FarmStatusLabel:SetDesc("Nenhum NPC (Joker/Sho) encontrado no ClientEnemyVisuals.")
            Fluent:Notify({
                Title = "NPCs não encontrados",
                Content = "Verifique se está dentro da Dungeon.",
                Duration = 4
            })
        end
    end
})

-- ========== LOOP PRINCIPAL DO AUTO DUNGEON ==========
local lastEmptyTime = tick()
task.spawn(function()
    while scriptActive() and task.wait(0.03) do
        if not AutoDungeonEnabled then
            StatusLabel:SetDesc("Waiting (Disabled)")
            continue
        end
        
        pcall(function()
            local notifyGui = LocalPlayer.PlayerGui:FindFirstChild("HUD")
            if notifyGui then
                local notifyDungeon = notifyGui:FindFirstChild("Main") and 
                    notifyGui.Main:FindFirstChild("GamemodeNotify") and 
                    notifyGui.Main.GamemodeNotify:FindFirstChild("Notify_Dungeon_World9Dungeon")
                
                if notifyDungeon and notifyDungeon.Visible then
                    local yesBtn = notifyDungeon:FindFirstChild("Actions") and 
                        notifyDungeon.Actions:FindFirstChild("YES")
                    
                    if yesBtn then
                        StatusLabel:SetDesc("Dungeon notification detected, waiting 0.5s...")
                        task.wait(0.5)
                        StatusLabel:SetDesc("Clicking YES...")
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
            StatusLabel:SetDesc("Dungeon ativo - farmando inimigos...")
        else
            if AutoDungeonEnabled then
                StatusLabel:SetDesc("Waiting for Dungeon invite...")
            end
        end
    end
end)

-- ========== INICIALIZAÇÃO ==========
task.spawn(collectionLoop) -- Auto Ball
task.spawn(startAriseSystem) -- Auto Arise
task.spawn(autoLeaveLoop) -- Auto Leave
task.spawn(prioritySchedulerLoop) -- Prioridade de Entrada

-- Auto Join opcional
AddAutoJoinSection()
JoinStatus = Tabs.AutoJoin:AddParagraph({ Title = "Status", Content = "Auto Join parado" })

Tabs.AutoJoin:AddToggle("AutoJoinToggle", {
    Title = "Ativar Auto Join", 
    Default = false, 
    Callback = function(state) 
        if state and not KeyPassed then
            AutoJoinEnabled = false
            Fluent:Notify({ Title = "Key necessária", Content = "Digite a key primeiro.", Duration = 3 })
            return
        end
        AutoJoinEnabled = state
        if state then
            task.spawn(autoJoinLoop)
        end
    end
})

Tabs.AutoJoin:AddSlider("JoinInterval", {
    Title = "Intervalo de detecção (s)", 
    Min = 0.5, 
    Max = 5, 
    Default = 1.0, 
    Rounding = 1, 
    Callback = function(v) 
        JoinDetectionInterval = v 
    end
})

Window:SelectTab(2)
local nowLoadedNotify = os.clock()
if not SCRIPT_ENV.BR_ANIME_ASTRAL_LAST_LOADED_NOTIFY or (nowLoadedNotify - SCRIPT_ENV.BR_ANIME_ASTRAL_LAST_LOADED_NOTIFY) > 8 then
    SCRIPT_ENV.BR_ANIME_ASTRAL_LAST_LOADED_NOTIFY = nowLoadedNotify
    Fluent:Notify({ Title = "✅ Script Carregado", Content = "Sistema PRO completo ativado! Todos os módulos prontos.", Duration = 3 })
end
