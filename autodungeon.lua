if not game:IsLoaded() then
    game.Loaded:Wait()
end

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
    Progression = Window:AddTab({ Title = "Progression", Icon = "trending-up" }),
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

-- VARIÁVEIS COMBAT FARM
local AutoFarmEnabled = false
local AutoAttackEnabled = false
local AutoSkillEnabled = false
local FarmDistance = 6
local AutoSkillInterval = 0.5
local LastSkillTime = 0

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
local PRIORITY_LEAVE_COOLDOWN = 1.5
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
local PriorityPendingGateAfterLeave = false
local PriorityPendingGateKey = ""
local PriorityPendingGateStartedAt = 0
local PRIORITY_EXIT_WAIT_TIMEOUT = 18

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
    
    local dist = (hrp.Position - position).Magnitude
    if dist > 15 then
        pcall(function()
            local tweenInfo = TweenInfo.new(dist / 150, Enum.EasingStyle.Linear)
            local tween = TweenService:Create(hrp, tweenInfo, {CFrame = CFrame.new(position + Vector3.new(0, 3, 0))})
            tween:Play()
        end)
    else
        pcall(function() 
            hrp.CFrame = CFrame.new(position + Vector3.new(0, 3, 0)) 
        end)
    end
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

-- ========== GATE ENTRY HELPERS V5 ==========
local function hasVisibleGateNotifyDirect()
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

local function getSelectedGateWorldFolder()
    local worlds = workspace:FindFirstChild("Worlds")
    if not worlds then
        return nil
    end

    return worlds:FindFirstChild(tostring(SelectedGateWorld))
end

local function getAnyBasePart(inst)
    if not inst then
        return nil
    end

    if inst:IsA("BasePart") then
        return inst
    end

    return inst:FindFirstChildWhichIsA("BasePart", true)
end

local function collectGateEntryObjectsForWorld(worldNumber)
    local objects = {}
    local seen = {}

    local function add(obj)
        if obj and not seen[obj] then
            seen[obj] = true
            table.insert(objects, obj)
        end
    end

    local worlds = workspace:FindFirstChild("Worlds")
    local worldFolder = worlds and worlds:FindFirstChild(tostring(worldNumber))
    if not worldFolder then
        return objects
    end

    local systems = worldFolder:FindFirstChild("Systems")

    add(systems and systems:FindFirstChild("RaidStation"))
    add(worldFolder:FindFirstChild("RaidStation"))
    add(worldFolder:FindFirstChild("SpawnGate"))
    add(worldFolder:FindFirstChild("Teleporter"))

    if systems then
        for _, obj in ipairs(systems:GetDescendants()) do
            local n = (obj.Name or ""):lower()
            if n:find("raidstation") or n:find("spawngate") or n:find("teleporter") or n:find("gate") then
                if obj:IsA("BasePart") or obj:IsA("Model") or obj:IsA("Folder") then
                    add(obj)
                end
            end
        end
    end

    for _, obj in ipairs(worldFolder:GetChildren()) do
        local n = (obj.Name or ""):lower()
        if n == "spawngate" or n == "teleporter" or n == "raidstation" then
            add(obj)
        end
    end

    return objects
end

local function hasGateWorldTextActive()
    local worldFolder = getSelectedGateWorldFolder()
    if not worldFolder then
        return false
    end

    for _, obj in ipairs(worldFolder:GetDescendants()) do
        if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
            local txt = tostring(obj.Text or ""):lower()
            if txt:find("gate rank") or txt:find("time left") then
                return true
            end
        end
    end

    return false
end

local function hasVisibleGatePortalPart()
    local objects = collectGateEntryObjectsForWorld(SelectedGateWorld)

    for _, obj in ipairs(objects) do
        local objName = (obj.Name or ""):lower()
        local part = getAnyBasePart(obj)

        -- So usa visual do SpawnGate/Gate como prova de gate ativo.
        -- RaidStation/Teleporter podem existir sempre, entao nao contam como "ativo" so por existirem.
        if part and (objName:find("spawngate") or objName == "gate" or objName:find("portal")) then
            local ok, transparency = pcall(function()
                return part.Transparency
            end)

            if ok and tonumber(transparency) and transparency < 0.98 then
                return true
            end
        end
    end

    return false
end

local function hasActiveGatePortalByWorld()
    return hasVisibleGateNotifyDirect() or hasGateWorldTextActive() or hasVisibleGatePortalPart()
end

local function activateGateEntryObject(obj)
    if not obj then
        return false
    end

    local part = getAnyBasePart(obj)
    local pos = part and part.Position or partCenter(obj)

    if not pos then
        return false
    end

    teleportToPosition(pos)
    task.wait(0.12)

    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

    if hrp and part and part:FindFirstChildOfClass("TouchInterest") then
        pcall(function()
            firetouchinterest(hrp, part, 0)
            task.wait(0.05)
            firetouchinterest(hrp, part, 1)
        end)
        task.wait(0.12)
    end

    local prompt = obj:FindFirstChildOfClass("ProximityPrompt") or (part and part:FindFirstChildOfClass("ProximityPrompt"))

    if not prompt then
        prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
    end

    if prompt then
        pcall(function()
            fireproximityprompt(prompt)
        end)
        task.wait(0.18)
    end

    for _, d in ipairs(obj:GetDescendants()) do
        if d:IsA("TextButton") or d:IsA("ImageButton") then
            local nm = (d.Name or ""):lower()
            local tx = (d.Text or ""):lower()
            if nm:find("yes") or nm:find("confirm") or nm:find("enter") or nm:find("join")
            or tx:find("yes") or tx:find("confirm") or tx:find("enter") or tx:find("join") then
                robustClickObject(d)
                task.wait(0.12)
            end
        end
    end

    return verifyGateEntry()
end

local function tryGateEntryObjectsForWorld(worldNumber)
    local objects = collectGateEntryObjectsForWorld(worldNumber)
    if #objects == 0 then
        return false
    end

    for _, obj in ipairs(objects) do
        if verifyGateEntry() then
            return true
        end

        local ok, result = pcall(function()
            return activateGateEntryObject(obj)
        end)

        if ok and result then
            return true
        end

        task.wait(0.08)
    end

    return verifyGateEntry()
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
    if tryGateEntryObjectsForWorld(SelectedGateWorld) then
        return true
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

-- ========== TRIAL HELPERS ==========
local function hasVisibleTrialNotifyDirect()
    local notifyRoot = LocalPlayer.PlayerGui:FindFirstChild("HUD")
        and LocalPlayer.PlayerGui.HUD:FindFirstChild("Main")
        and LocalPlayer.PlayerGui.HUD.Main:FindFirstChild("GamemodeNotify")

    if not notifyRoot then return false, nil end

    for _, card in ipairs(notifyRoot:GetChildren()) do
        if card:IsA("GuiObject") and card.Visible then
            local desc = card:FindFirstChild("Description")
            if desc and desc:IsA("TextLabel") then
                local txt = desc.Text:lower()
                if txt:find("trial") then
                    local difficulty = "unknown"
                    if txt:find("easy") then difficulty = "Easy" end
                    if txt:find("medium") then difficulty = "Medium" end
                    return true, difficulty
                end
            end
        end
    end
    return false, nil
end

local function clickYesInCurrentTrialNotify()
    if not ensureCharacterAlive() then return false end
    
    local notifyRoot = LocalPlayer.PlayerGui:FindFirstChild("HUD")
        and LocalPlayer.PlayerGui.HUD:FindFirstChild("Main")
        and LocalPlayer.PlayerGui.HUD.Main:FindFirstChild("GamemodeNotify")
    
    if not notifyRoot then return false end
    
    for _, card in ipairs(notifyRoot:GetChildren()) do
        if card:IsA("GuiObject") and card.Visible then
            local desc = card:FindFirstChild("Description")
            if desc and desc:IsA("TextLabel") then
                local txt = desc.Text:lower()
                if txt:find("trial") then
                    local actions = card:FindFirstChild("Actions")
                    if actions then
                        for _, btn in ipairs(actions:GetDescendants()) do
                            if (btn:IsA("TextButton") or btn:IsA("ImageButton")) then
                                local btnText = (btn.Text or ""):lower()
                                local btnName = (btn.Name or ""):lower()
                                if btnText:find("yes") or btnName:find("yes") or btnText:find("confirm") or btnName:find("confirm") then
                                    if robustClickObject(btn) then
                                        Fluent:Notify({ Title = "✅ Trial Aceito", Content = "Indo para o Trial...", Duration = 3 })
                                        task.wait(1)
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
    Title = "Detectar Gate Automatically", 
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
    Title = "Ativar Automatically o Arise", 
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

                setLeaveInfo("Leave clicado com sucesso!")
            else
                setLeaveInfo("Falha ao clicar no botao Leave.")
            end
        else
            setLeaveInfo("Botao Leave nao encontrado.")
        end
    end
end

-- COMBAT AUTO FARM IN DUNGEON
local SelectedFarmTarget = "Qualquer"

local function findNearestEnemy()
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return nil
    end
    local myPos = character.HumanoidRootPart.Position
    local nearest = nil
    local minDist = math.huge
    
    local targets = {}
    local raidArenas = workspace:FindFirstChild("RaidArenas")
    if raidArenas then
        for _, world in ipairs(raidArenas:GetChildren()) do
            local enemies = world:FindFirstChild("Enemies")
            if enemies then
                for _, enemy in ipairs(enemies:GetChildren()) do
                    if enemy:IsA("Model") and enemy:FindFirstChild("HumanoidRootPart") then
                        local hum = enemy:FindFirstChildOfClass("Humanoid")
                        if hum and hum.Health > 0 then
                            table.insert(targets, enemy)
                        end
                    end
                end
            end
        end
    end
    
    -- Dungeon Mobs ou Genéricos no workspace
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj:IsA("Model") and obj ~= character and not Players:GetPlayerFromCharacter(obj) then
            local hrp = obj:FindFirstChild("HumanoidRootPart")
            local hum = obj:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local objName = obj.Name:lower()
                if objName ~= "npc" and not objName:find("quest") and not objName:find("shop") and not objName:find("teleporter") then
                    table.insert(targets, obj)
                end
            end
        end
    end
    
    -- Filter targets by SelectedFarmTarget
    local validTargets = {}
    for _, target in ipairs(targets) do
        if SelectedFarmTarget == "Qualquer" or target.Name:lower() == SelectedFarmTarget:lower() then
            table.insert(validTargets, target)
        end
    end

    for _, target in ipairs(validTargets) do
        local hrp = target.HumanoidRootPart
        local dist = (hrp.Position - myPos).Magnitude
        if dist < minDist then
            minDist = dist
            nearest = target
        end
    end
    
    return nearest
end

local GlobalAction = "IDLE" -- Estados: IDLE, FARMING, GATE_PRIORITY, TRIAL_PRIORITY

local function autoFarmLoop()
    while scriptActive() and task.wait(0.1) do
        if GlobalAction == "GATE_PRIORITY" or GlobalAction == "TRIAL_PRIORITY" then
            continue
        end

        if not AutoFarmEnabled or not ensureCharacterAlive() then
            if GlobalAction == "FARMING" then GlobalAction = "IDLE" end
            continue
        end
        
        GlobalAction = "FARMING"
        
        local target = findNearestEnemy()
        if target and target:FindFirstChild("HumanoidRootPart") then
            local hrp = target.HumanoidRootPart
            local character = LocalPlayer.Character
            local myHrp = character and character:FindFirstChild("HumanoidRootPart")
            
            if myHrp then
                pcall(function()
                    -- Fix rotation bug: Use absolute position + Y offset instead of rotating with enemy
                    local targetPos = hrp.Position + Vector3.new(0, FarmDistance, 0)
                    local dist = (myHrp.Position - targetPos).Magnitude
                    
                    if dist > 10 then
                        local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Linear)
                        TweenService:Create(myHrp, tweenInfo, {CFrame = CFrame.new(targetPos)}):Play()
                    else
                        myHrp.CFrame = CFrame.new(targetPos)
                    end
                    
                    -- Freeze falling/gravity
                    if not myHrp:FindFirstChild("FarmBodyVelocity") then
                        local bv = Instance.new("BodyVelocity")
                        bv.Name = "FarmBodyVelocity"
                        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                        bv.Velocity = Vector3.new(0, 0, 0)
                        bv.Parent = myHrp
                    end
                end)
            else
                if myHrp and myHrp:FindFirstChild("FarmBodyVelocity") then
                    myHrp.FarmBodyVelocity:Destroy()
                end
            end
            
            -- Auto Loot Genérico
            pcall(function()
                local drops = workspace:FindFirstChild("Drops")
                if drops then
                    for _, drop in ipairs(drops:GetChildren()) do
                        if drop:IsA("BasePart") and drop:FindFirstChildOfClass("TouchInterest") then
                            firetouchinterest(myHrp, drop, 0)
                            task.wait(0.01)
                            firetouchinterest(myHrp, drop, 1)
                        end
                    end
                end
            end)
            
            -- Auto Attack
            if AutoAttackEnabled then
                local tool = LocalPlayer.Backpack:FindFirstChildWhichIsA("Tool") or (character and character:FindFirstChildWhichIsA("Tool"))
                if tool then
                    if tool.Parent ~= character then
                        pcall(function()
                            character.Humanoid:EquipTool(tool)
                        end)
                    end
                    pcall(function()
                        tool:Activate()
                    end)
                else
                    pcall(function()
                        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
                        task.wait(0.01)
                        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
                    end)
                end
            end
            
            -- Auto Skill
            if AutoSkillEnabled and (os.clock() - LastSkillTime) > AutoSkillInterval then
                LastSkillTime = os.clock()
                pcall(function()
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.One, false, game)
                    task.wait(0.01)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.One, false, game)
                    
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Two, false, game)
                    task.wait(0.01)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Two, false, game)
                    
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Three, false, game)
                    task.wait(0.01)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Three, false, game)
                    
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Four, false, game)
                    task.wait(0.01)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Four, false, game)
                end)
            end
        else
            -- Clean up velocity if no target
            local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if myHrp and myHrp:FindFirstChild("FarmBodyVelocity") then
                myHrp.FarmBodyVelocity:Destroy()
            end
        end
    end
end

-- DUNGEON INTERFACE CONTINUED
local TargetDropdown
Tabs.Main:AddButton({
    Title = "Escanear Mapa (Atualizar Alvos)",
    Description = "Procura todos os bosses e mobs vivos no momento para o Radar.",
    Callback = function()
        local uniqueNames = { "Qualquer" }
        local found = {}
        
        -- Scan RaidArenas
        local raidArenas = workspace:FindFirstChild("RaidArenas")
        if raidArenas then
            for _, world in ipairs(raidArenas:GetChildren()) do
                local enemies = world:FindFirstChild("Enemies")
                if enemies then
                    for _, enemy in ipairs(enemies:GetChildren()) do
                        if enemy:IsA("Model") and enemy:FindFirstChild("HumanoidRootPart") and enemy:FindFirstChildOfClass("Humanoid") then
                            local hum = enemy:FindFirstChildOfClass("Humanoid")
                            if hum.Health > 0 and not found[enemy.Name] then
                                found[enemy.Name] = true
                                table.insert(uniqueNames, enemy.Name)
                            end
                        end
                    end
                end
            end
        end
        
        -- Scan Workspace
        for _, obj in ipairs(workspace:GetChildren()) do
            if obj:IsA("Model") and obj ~= LocalPlayer.Character and not Players:GetPlayerFromCharacter(obj) then
                local hrp = obj:FindFirstChild("HumanoidRootPart")
                local hum = obj:FindFirstChildOfClass("Humanoid")
                if hrp and hum and hum.Health > 0 then
                    local objName = obj.Name:lower()
                    if objName ~= "npc" and not objName:find("quest") and not objName:find("shop") and not objName:find("teleporter") then
                        if not found[obj.Name] then
                            found[obj.Name] = true
                            table.insert(uniqueNames, obj.Name)
                        end
                    end
                end
            end
        end
        
        if TargetDropdown then
            TargetDropdown:SetValues(uniqueNames)
            Fluent:Notify({ Title = "Radar Atualizado", Content = "Encontrados " .. (#uniqueNames - 1) .. " alvos unicos.", Duration = 3 })
        end
    end
})

TargetDropdown = Tabs.Main:AddDropdown("TargetSelector", {
    Title = "Selecionar Alvo (Boss Sniper)",
    Values = { "Qualquer" },
    Default = "Qualquer",
    Multi = false,
    Callback = function(value)
        SelectedFarmTarget = value
    end
})

Tabs.Main:AddToggle("AutoFarmToggle", {
    Title = "Auto Farm Mobs (Combat)",
    Description = "Teleporta ate os mobs da dungeon e os ataca.",
    Default = false,
    Callback = function(state)
        AutoFarmEnabled = state
    end
})

Tabs.Main:AddToggle("AutoAttackToggle", {
    Title = "Auto Attack (Tool/Click)",
    Default = false,
    Callback = function(state)
        AutoAttackEnabled = state
    end
})

Tabs.Main:AddToggle("AutoSkillToggle", {
    Title = "Auto Skills (1,2,3,4)",
    Default = false,
    Callback = function(state)
        AutoSkillEnabled = state
    end
})

Tabs.Main:AddSlider("FarmDistance", {
    Title = "Distancia do Mob (Altura)",
    Min = 2,
    Max = 15,
    Default = 6,
    Rounding = 0,
    Callback = function(v)
        FarmDistance = v
    end
})

LeaveInfo = Tabs.Main:AddParagraph({ Title = "Auto Leave Status", Content = "Inativo" })

Tabs.Main:AddToggle("AutoLeaveToggle", {
    Title = "Auto Leave Dungeon",
    Default = false,
    Callback = function(state)
        AutoLeaveEnabled = state
    end
})

Tabs.Main:AddSlider("LeaveRoom", {
    Title = "Sair na sala",
    Min = 5,
    Max = 150,
    Default = 50,
    Rounding = 0,
    Callback = function(v)
        LeaveRoom = math.floor(v)
    end
})

local SelectedTrialMode = "Desativado"
Tabs.Main:AddDropdown("AutoTrialDropdown", {
    Title = "Auto Trial",
    Values = { "Desativado", "Easy", "Medium", "Qualquer" },
    Default = "Desativado",
    Multi = false,
    Callback = function(value)
        SelectedTrialMode = value
    end
})

local AutoRejoinDungeonEnabled = false
Tabs.Main:AddToggle("AutoRejoinDungeon", {
    Title = "Auto Rejoin Dungeon",
    Description = "Entra automaticamente na Dungeon (World 9) se estiver no lobby",
    Default = false,
    Callback = function(state)
        AutoRejoinDungeonEnabled = state
    end
})

local function autoRejoinDungeonLoop()
    while scriptActive() and task.wait(3) do
        if not AutoRejoinDungeonEnabled or GlobalAction == "GATE_PRIORITY" or GlobalAction == "TRIAL_PRIORITY" then
            continue
        end

        local currentRoom = getCurrentDungeonRoom()
        local raidArenas = workspace:FindFirstChild("RaidArenas")
        local inGate = false
        if raidArenas then
            for _, world in ipairs(raidArenas:GetChildren()) do
                if world:FindFirstChild("Enemies") then
                    inGate = true
                    break
                end
            end
        end

        -- Se não estiver em dungeon, tenta clicar no YES da tela ou ir pro portal
        if currentRoom <= 0 and not inGate then
            
            -- 1. Tentar clicar no botão YES da tela (Notificação de Dungeon)
            local clickedYes = false
            pcall(function()
                local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
                if playerGui then
                    for _, obj in ipairs(playerGui:GetDescendants()) do
                        if obj:IsA("TextButton") and obj.Visible then
                            local text = obj.Text:lower()
                            if text == "yes" or text == "sim" or text == "accept" then
                                -- Verifica se o pai ou a UI menciona Dungeon
                                local parent = obj.Parent
                                local isDungeon = false
                                while parent and parent ~= playerGui do
                                    if parent.Name:lower():find("dungeon") then
                                        isDungeon = true
                                        break
                                    end
                                    -- Check text of siblings just in case
                                    for _, sibling in ipairs(parent:GetChildren()) do
                                        if sibling:IsA("TextLabel") and sibling.Text:lower():find("dungeon") then
                                            isDungeon = true
                                        end
                                    end
                                    parent = parent.Parent
                                end
                                
                                if isDungeon then
                                    robustClickObject(obj)
                                    clickedYes = true
                                    task.wait(1)
                                end
                            end
                        end
                    end
                end
            end)

            -- 2. Se não clicou no YES, vai para a construção de Fogo (World 9) e encosta nela
            if not clickedYes then
                local dungeonStation = getRaidStationForWorld(9)
                if dungeonStation then
                    -- Descobre a peça correta para encostar
                    local touchPart = dungeonStation:IsA("BasePart") and dungeonStation or dungeonStation:FindFirstChild("Portal") or dungeonStation:FindFirstChildWhichIsA("BasePart", true)
                    if touchPart then
                        local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if myHrp then
                            -- Teleporta EXATAMENTE para dentro da peça para encostar
                            myHrp.CFrame = touchPart.CFrame
                            task.wait(0.5)
                        end
                    end
                end
            end
        end
    end
end

-- ========== AUTO BALL SYSTEM ==========
local function autoBallLoop()
    while scriptActive() and task.wait(0.2) do
        if not AutoBallEnabled then
            currentTarget = "Nenhum"
            if BallStatus then BallStatus:SetDesc("Auto Ball desativado") end
            continue
        end
        
        local ballFolder = workspace:FindFirstChild(ballsFolderName)
        if not ballFolder then
            currentTarget = "Pasta nao encontrada"
            if BallStatus then BallStatus:SetDesc("❌ Pasta " .. ballsFolderName .. " nao encontrada") end
            task.wait(1.5)
            continue
        end
        
        local targetBall = nil
        local character = LocalPlayer.Character
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end
        
        local myPos = hrp.Position
        local minDist = BallRadius
        
        for _, obj in ipairs(ballFolder:GetChildren()) do
            local ballPart = nil
            if obj.Name == sphereName and obj:IsA("BasePart") then
                ballPart = obj
            else
                ballPart = obj:FindFirstChild(sphereName) or obj:FindFirstChildWhichIsA("BasePart", true)
            end
            
            if ballPart then
                local prompt = obj:FindFirstChild(promptName) or obj:FindFirstChildWhichIsA("ProximityPrompt", true) or ballPart:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt and prompt:IsA("ProximityPrompt") then
                    local dist = (ballPart.Position - myPos).Magnitude
                    if dist < minDist then
                        minDist = dist
                        targetBall = { part = ballPart, prompt = prompt, name = obj.Name }
                    end
                end
            end
        end
        
        if targetBall then
            currentTarget = targetBall.name
            if BallStatus then
                BallStatus:SetDesc("Target: " .. currentTarget .. " | Dist: " .. math.floor(minDist))
            end
            
            local success = teleportToPosition(targetBall.part.Position)
            if success then
                task.wait(0.15)
                pcall(function()
                    fireproximityprompt(targetBall.prompt)
                end)
                collectedCount = collectedCount + 1
                task.wait(BallCooldown)
            end
        else
            currentTarget = "Nenhum no raio"
            if BallStatus then
                BallStatus:SetDesc("Nenhuma bola encontrada no raio de " .. BallRadius)
            end
        end
    end
end

-- Interface do Auto Ball
AddBallSection()
BallStatus = Tabs.Ball:AddParagraph({ Title = "Status das Bolas", Content = "Auto Ball desativado" })

Tabs.Ball:AddToggle("AutoBallToggle", {
    Title = "Auto Ball World 8",
    Default = false,
    Callback = function(state)
        if state and not KeyPassed then
            AutoBallEnabled = false
            Fluent:Notify({ Title = "Key necessaria", Content = "Digite a key primeiro.", Duration = 3 })
            return
        end
        AutoBallEnabled = state
    end
})

Tabs.Ball:AddSlider("BallRadius", {
    Title = "Raio de busca",
    Min = 50,
    Max = 2000,
    Default = 600,
    Rounding = 0,
    Callback = function(v)
        BallRadius = v
    end
})

Tabs.Ball:AddSlider("BallCooldown", {
    Title = "Cooldown de Coleta (segundos)",
    Min = 0.1,
    Max = 3.0,
    Default = 0.4,
    Rounding = 1,
    Callback = function(v)
        BallCooldown = v
    end
})

-- ========== AUTO JOIN SYSTEM ==========
AddAutoJoinSection()
JoinStatus = Tabs.AutoJoin:AddParagraph({ Title = "Status do Auto Join", Content = "Desativado" })

Tabs.AutoJoin:AddToggle("AutoJoinToggle", {
    Title = "Auto Join / Server",
    Default = false,
    Callback = function(state)
        if state and not KeyPassed then
            AutoJoinEnabled = false
            Fluent:Notify({ Title = "Key necessaria", Content = "Digite a key primeiro.", Duration = 3 })
            return
        end
        AutoJoinEnabled = state
    end
})

Tabs.AutoJoin:AddSlider("JoinDetectionInterval", {
    Title = "Intervalo de deteccao (segundos)",
    Min = 0.5,
    Max = 10,
    Default = 1.0,
    Rounding = 1,
    Callback = function(v)
        JoinDetectionInterval = v
    end
})

-- ========== PRIORITY SYSTEM V2 ==========
local function secondsUntilNextEvent(intervalSec)
    local now = os.time()
    local remainder = now % intervalSec
    return intervalSec - remainder
end

local function logPriorityDebug(msg)
    if not PriorityDebugEnabled then return end
    local timeStr = os.date("%H:%M:%S")
    local line = "[" .. timeStr .. "] " .. msg
    if PriorityDebugLog then
        table.insert(PriorityDebugLines, 1, line)
        if #PriorityDebugLines > 6 then
            table.remove(PriorityDebugLines)
        end
        PriorityDebugLog:SetDesc(table.concat(PriorityDebugLines, "\n"))
    end
end

local PriorityPendingTrialAfterLeave = false

local function prioritySystemLoop()
    while scriptActive() and task.wait(PRIORITY_LOOP_INTERVAL) do
        if not PrioritySystemEnabled then
            if PriorityStatus then PriorityStatus:SetDesc("Prioridade: Desativado") end
            continue
        end
        
        local currentRoom = getCurrentDungeonRoom()
        local inDungeon = currentRoom > 0
        local nextGate = secondsUntilNextEvent(ModeIntervalSeconds.Gate)
        local nextDungeon = secondsUntilNextEvent(ModeIntervalSeconds.Dungeon)
        
        local statusTxt = ("Gate em: %ds | Dungeon em: %ds | Action: %s"):format(nextGate, nextDungeon, GlobalAction)
        if PriorityStatus then PriorityStatus:SetDesc(statusTxt) end
        
        local hasTrial, trialDiff = hasVisibleTrialNotifyDirect()
        local wantsTrial = false
        if hasTrial and SelectedTrialMode ~= "Desativado" then
            if SelectedTrialMode == "Qualquer" or SelectedTrialMode == trialDiff then
                wantsTrial = true
            end
        end
        
        if LeaveForHigherPriority then
            if wantsTrial then
                GlobalAction = "TRIAL_PRIORITY"
                if inDungeon then
                    logPriorityDebug("Trial Ativo! Abandonando Dungeon...")
                    local leaveBtn = findLeaveButton()
                    if leaveBtn then
                        robustClickObject(leaveBtn)
                        task.wait(PRIORITY_LEAVE_COOLDOWN)
                        PriorityPendingTrialAfterLeave = true
                    end
                else
                    logPriorityDebug("Entrando no Trial...")
                    clickYesInCurrentTrialNotify()
                end
            elseif inDungeon and hasActiveGatePortalByWorld() then
                GlobalAction = "GATE_PRIORITY"
                logPriorityDebug("Gate Ativo! Abandonando Dungeon...")
                local leaveBtn = findLeaveButton()
                if leaveBtn then
                    robustClickObject(leaveBtn)
                    task.wait(PRIORITY_LEAVE_COOLDOWN)
                    PriorityPendingGateAfterLeave = true
                end
            elseif not inDungeon and not verifyGateEntry() and hasActiveGatePortalByWorld() then
                GlobalAction = "GATE_PRIORITY"
                logPriorityDebug("Entrando no Gate...")
                clickYesInCurrentGateNotify()
                findAndActivateSpawnGate()
            elseif GlobalAction == "TRIAL_PRIORITY" then
                if (not inDungeon and verifyGateEntry()) or (not hasVisibleTrialNotifyDirect()) then
                    GlobalAction = "IDLE"
                end
            elseif GlobalAction == "GATE_PRIORITY" then
                -- Se entrou no gate com sucesso, ou se o gate sumiu
                if (not inDungeon and verifyGateEntry()) or (not inDungeon and not hasActiveGatePortalByWorld()) then
                    GlobalAction = "IDLE"
                end
            end
        end
        
        if PriorityPendingTrialAfterLeave and not inDungeon then
            PriorityPendingTrialAfterLeave = false
            logPriorityDebug("Entrando no Trial pendente...")
            clickYesInCurrentTrialNotify()
        end
        
        -- Acao pós-saida para entrar no Gate
        if PriorityPendingGateAfterLeave and not inDungeon then
            PriorityPendingGateAfterLeave = false
            logPriorityDebug("Entrando no Gate pendente...")
            clickYesInCurrentGateNotify()
            findAndActivateSpawnGate()
        end
    end
end

AddSection(Tabs.Gamemodes, "PRIORITY SYSTEM V2", "Prioriza os modos automaticamente.")
PriorityStatus = Tabs.Gamemodes:AddParagraph({ Title = "Status de Prioridade", Content = "Desativado" })

Tabs.Gamemodes:AddToggle("PrioritySystemToggle", {
    Title = "Ativar Priority System",
    Default = false,
    Callback = function(state)
        PrioritySystemEnabled = state
    end
})

Tabs.Gamemodes:AddToggle("LeaveForHigherPriorityToggle", {
    Title = "Sair da Dungeon para Gate",
    Default = true,
    Callback = function(state)
        LeaveForHigherPriority = state
    end
})

Tabs.Gamemodes:AddSlider("PrepLeaveBefore", {
    Title = "Sair X segundos antes",
    Min = 30,
    Max = 240,
    Default = 90,
    Rounding = 0,
    Callback = function(v)
        PREP_LEAVE_BEFORE = v
    end
})

PriorityDebugLog = Tabs.Gamemodes:AddParagraph({ Title = "Logs de Prioridade", Content = "Nenhum evento registrado" })

-- ========== SISTEMA DE PROGRESSÃO ==========
local AutoClaimRewardsEnabled = false
local AutoStatsEnabled = false
local AutoEquipBestEnabled = false
local SelectedStatToUpgrade = "Damage"
local StatPointAmount = 1

local function autoProgressionLoop()
    while scriptActive() and task.wait(5) do
        if GlobalAction == "GATE_PRIORITY" or GlobalAction == "TRIAL_PRIORITY" then
            continue
        end

        local pcallOk, networkFunctions = pcall(function()
            return game:GetService("ReplicatedStorage"):WaitForChild("SimpleWorld", 2):WaitForChild("Library", 2):WaitForChild("Network", 2):WaitForChild("Functions", 2)
        end)

        if pcallOk and networkFunctions then
            if AutoClaimRewardsEnabled then
                pcall(function()
                    local claimTime = networkFunctions:FindFirstChild("ClaimAllTimeRewards")
                    if claimTime then claimTime:InvokeServer() end
                    
                    local claimDaily = networkFunctions:FindFirstChild("ClaimAllDailyRewards")
                    if claimDaily then claimDaily:InvokeServer() end
                end)
            end

            if AutoStatsEnabled then
                pcall(function()
                    local spendStat = networkFunctions:FindFirstChild("SpendStatPoint")
                    if spendStat then
                        spendStat:InvokeServer(SelectedStatToUpgrade, StatPointAmount)
                    end
                end)
            end
        end

        if AutoEquipBestEnabled then
            pcall(function()
                local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
                if playerGui then
                    for _, obj in ipairs(playerGui:GetDescendants()) do
                        if obj:IsA("TextButton") or obj:IsA("ImageButton") or obj:IsA("TextLabel") then
                            local text = obj:IsA("TextButton") and obj.Text or (obj:IsA("TextLabel") and obj.Text or "")
                            if obj.Name:lower():find("equipbest") or obj.Name:lower():find("equip_best") or text:lower():find("equip best") then
                                -- If it's a TextLabel inside a button, find the parent button
                                local targetBtn = obj
                                if not targetBtn:IsA("GuiButton") and targetBtn.Parent:IsA("GuiButton") then
                                    targetBtn = targetBtn.Parent
                                end
                                if targetBtn:IsA("GuiButton") then
                                    robustClickObject(targetBtn)
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
end

AddSpace(Tabs.Progression)
Tabs.Progression:AddParagraph({ Title = "========== AUTO PROGRESSION ==========", Content = "Automatiza recompensas e status." })
local ProgressionStatus = Tabs.Progression:AddParagraph({ Title = "Status", Content = "Desativado" })

Tabs.Progression:AddToggle("AutoClaimToggle", {
    Title = "Auto Claim Rewards",
    Description = "Coleta automaticamente Time e Daily rewards (se houver)",
    Default = false,
    Callback = function(state)
        if state and not KeyPassed then
            AutoClaimRewardsEnabled = false
            Fluent:Notify({ Title = "Key necessaria", Content = "Digite a key primeiro.", Duration = 3 })
            return
        end
        AutoClaimRewardsEnabled = state
        ProgressionStatus:SetDesc(state and "Sistema Ativo" or "Desativado")
    end
})

Tabs.Progression:AddToggle("AutoEquipBestToggle", {
    Title = "Auto Equip Best",
    Description = "Clica automaticamente no botão Equip Best",
    Default = false,
    Callback = function(state)
        AutoEquipBestEnabled = state
    end
})

Tabs.Progression:AddToggle("AutoStatsToggle", {
    Title = "Auto Up Stats",
    Description = "Gasta pontos de status automaticamente na skill escolhida",
    Default = false,
    Callback = function(state)
        if state and not KeyPassed then
            AutoStatsEnabled = false
            Fluent:Notify({ Title = "Key necessaria", Content = "Digite a key primeiro.", Duration = 3 })
            return
        end
        AutoStatsEnabled = state
    end
})

Tabs.Progression:AddDropdown("StatDropdown", {
    Title = "Status para Upar",
    Values = { "Power", "Damage", "Luck", "Yen", "Drop", "XP" },
    Default = "Damage",
    Multi = false,
    Callback = function(value)
        SelectedStatToUpgrade = value
    end
})

Tabs.Progression:AddSlider("StatAmountSlider", {
    Title = "Pontos por vez",
    Min = 1,
    Max = 100,
    Default = 1,
    Rounding = 0,
    Callback = function(value)
        StatPointAmount = value
    end
})

-- ========== MISC TAB ==========
Tabs.Misc:AddParagraph({ Title = "Modificacoes Locais", Content = "Ajustes fisicos do personagem." })

local CustomSpeedEnabled = false
local CustomSpeed = 50
local CustomJumpEnabled = false
local CustomJump = 50
local InfiniteJumpEnabled = false
local NoclipEnabled = false

Tabs.Misc:AddToggle("SpeedToggle", {
    Title = "Custom Speed",
    Default = false,
    Callback = function(state)
        CustomSpeedEnabled = state
    end
})

Tabs.Misc:AddSlider("SpeedSlider", {
    Title = "Speed value",
    Min = 16,
    Max = 300,
    Default = 50,
    Rounding = 0,
    Callback = function(v)
        CustomSpeed = v
    end
})

Tabs.Misc:AddToggle("JumpToggle", {
    Title = "Custom Jump Power",
    Default = false,
    Callback = function(state)
        CustomJumpEnabled = state
    end
})

Tabs.Misc:AddSlider("JumpSlider", {
    Title = "Jump Power value",
    Min = 50,
    Max = 500,
    Default = 50,
    Rounding = 0,
    Callback = function(v)
        CustomJump = v
    end
})

Tabs.Misc:AddToggle("InfJumpToggle", {
    Title = "Infinite Jump",
    Default = false,
    Callback = function(state)
        InfiniteJumpEnabled = state
    end
})

Tabs.Misc:AddToggle("NoclipToggle", {
    Title = "Noclip (Atravessar Paredes)",
    Default = false,
    Callback = function(state)
        NoclipEnabled = state
    end
})

Tabs.Misc:AddButton({
    Title = "Bypass Key",
    Description = "Ignora a necessidade de digitar key para testes.",
    Callback = function()
        KeyPassed = true
        KeyStatus:SetDesc("Key correta! Script liberado (Bypassed).") 
        Fluent:Notify({ Title = "Bypassed!", Content = "Acesso liberado sem key!", Duration = 3 })
        Window:SelectTab(3)
    end
})

Tabs.Misc:AddButton({
    Title = "Teleport Spawn / Lobby",
    Description = "Teleporta o seu personagem de volta ao spawn principal.",
    Callback = function()
        teleportToPosition(Vector3.new(0, 10, 0))
        Fluent:Notify({ Title = "Teleport", Content = "Enviado ao Spawn!", Duration = 3 })
    end
})

-- Loops do Misc
game:GetService("UserInputService").JumpRequest:Connect(function()
    if InfiniteJumpEnabled and ensureCharacterAlive() then
        LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

RunService.Stepped:Connect(function()
    if NoclipEnabled and ensureCharacterAlive() then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

task.spawn(function()
    while scriptActive() and task.wait(0.5) do
        pcall(function()
            if ensureCharacterAlive() then
                local hum = LocalPlayer.Character.Humanoid
                if CustomSpeedEnabled then
                    hum.WalkSpeed = CustomSpeed
                end
                if CustomJumpEnabled then
                    hum.JumpPower = CustomJump
                end
            end
        end)
    end
end)

-- ========== SETTINGS TAB ==========
Tabs.Settings:AddParagraph({ Title = "Configuracoes da GUI", Content = "Gerenciamento da Fluent UI" })

Tabs.Settings:AddButton({
    Title = "Destruir UI",
    Description = "Fecha o script e limpa todas as conexoes.",
    Callback = function()
        Window:Destroy()
    end
})

Tabs.Settings:AddDropdown("ThemeDropdown", {
    Title = "Tema da Interface",
    Values = { "Dark", "Light", "Aqua", "Amethyst" },
    Default = "Dark",
    Callback = function(theme)
        Window:SetTheme(theme)
    end
})

-- INICIALIZACAO DOS LOOPS PARALELOS
task.spawn(autoJoinLoop)
task.spawn(autoLeaveLoop)
task.spawn(autoFarmLoop)
task.spawn(autoBallLoop)
task.spawn(prioritySystemLoop)
task.spawn(autoRejoinDungeonLoop)
task.spawn(autoProgressionLoop)

-- Notificacao inicial de carregamento
Fluent:Notify({
    Title = "BR Anime Astral PRO",
    Content = "Script carregado com sucesso! Digite a Key para liberar.",
    Duration = 5
})
Window:SelectTab(2)
