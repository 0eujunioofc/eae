repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Carregar Fluent UI
local Fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/0eujunioofc/eae/main/junio.lua"))()

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
    return AddSection(Tabs.Gate, "AUTO GATE", "[FORA DO MODO] Detecta notificacoes de Gate na hora e aceita 1 vez.")
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
local StatusArise, GateStatus, JoinStatus, BallStatus, StatusLabel

-- DISCORD
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
            Fluent:Notify({
                Title = "Key correta",
                Content = "Acesso liberado!",
                Duration = 3
            })
            Window:SelectTab(3)
        else
            KeyPassed = false
            KeyStatus:SetDesc("Key incorreta. Tente novamente.")
            Fluent:Notify({
                Title = "Key errada",
                Content = "Verifique a key e tente de novo.",
                Duration = 3
            })
        end
    end
})

-- FUNÇÕES COMPARTILHADAS
local function robustClickObject(obj)
    if not obj then return false end
    local methods = {
        function() if typeof(fireclick) == "function" then fireclick(obj); return true end end,
        function()
            if obj:IsA("TextButton") or obj:IsA("ImageButton") then
                if typeof(firesignal) == "function" then
                    pcall(function() firesignal(obj.MouseButton1Click) end)
                    pcall(function() firesignal(obj.Activated) end)
                    return true
                end
            end
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
        end
    }
    for _, method in ipairs(methods) do
        local ok, res = pcall(method)
        if ok and res then return true end
    end
    return false
end

local function ensureCharacterAlive()
    local character = LocalPlayer.Character
    if not character or not character.Parent then return false end
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    return true
end

local function teleportToPosition(position)
    if not ensureCharacterAlive() then return false end
    local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    pcall(function()
        hrp.CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
    end)
    return true
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
    while task.wait(JoinDetectionInterval) do
        if not AutoJoinEnabled then
            if JoinStatus then JoinStatus:SetDesc("Auto Join desativado") end
            continue
        end
        if JoinStatus then JoinStatus:SetDesc("Procurando botões JOIN...") end
        local joinButtons = findJoinButtons()
        if #joinButtons > 0 then
            if JoinStatus then JoinStatus:SetDesc("✅ " .. #joinButtons .. " botões JOIN encontrados") end
            for _, button in ipairs(joinButtons) do
                if not AutoJoinEnabled then break end
                if JoinStatus then JoinStatus:SetDesc("Clicando no botão JOIN...") end
                local clicked = robustClickObject(button)
                if clicked then
                    Fluent:Notify({
                        Title = "✅ JOIN clicado",
                        Content = "Entrando no servidor...",
                        Duration = 3
                    })
                    if JoinStatus then JoinStatus:SetDesc("✅ JOIN realizado - aguardando carregamento") end
                    task.wait(3)
                    break
                end
            end
        else
            if JoinStatus then JoinStatus:SetDesc("❌ Nenhum botão JOIN encontrado") end
        end
    end
end

-- ========== FUNÇÕES AUXILIARES PARA WORLDS ==========
local function getRaidStationForWorld(worldNumber)
    local worlds = workspace:FindFirstChild("Worlds")
    if not worlds then return nil end
    local worldFolder = worlds:FindFirstChild(tostring(worldNumber))
    if not worldFolder then return nil end
    local systems = worldFolder:FindFirstChild("Systems")
    if not systems then return nil end
    local raidStation = systems:FindFirstChild("RaidStation")
    return raidStation
end

local function partCenter(inst)
    if inst:IsA("BasePart") then return inst.Position
    elseif inst:IsA("Model") and inst.PrimaryPart then return inst.PrimaryPart.Position
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
    if #list == 0 then return "Nenhum" end
    return table.concat(list, ", ")
end

-- ========== FIND AND ACTIVATE SPAWN GATE (chamado só no momento) ==========
local function findAndActivateSpawnGate()
    local raidStation = getRaidStationForWorld(SelectedGateWorld)
    if not raidStation then return false end

    local pos = partCenter(raidStation)
    if not pos then return false end

    if not teleportToPosition(pos + Vector3.new(0, 3, 0)) then
        return false
    end
    task.wait(0.25)

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

    local prox = raidStation:FindFirstChildOfClass("ProximityPrompt") or touchPart and touchPart:FindFirstChildOfClass("ProximityPrompt")
    if prox then
        pcall(function()
            fireproximityprompt(prox)
        end)
        task.wait(0.1)
    end

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

-- ========== CLICK YES NA NOTIFICAÇÃO ATUAL ==========
local function clickYesInCurrentGateNotify()
    if not ensureCharacterAlive() then return false end

    local notifyRoot = LocalPlayer.PlayerGui:FindFirstChild("HUD")
        and LocalPlayer.PlayerGui.HUD:FindFirstChild("Main")
        and LocalPlayer.PlayerGui.HUD.Main:FindFirstChild("GamemodeNotify")

    if not notifyRoot then return false end

    for _, card in ipairs(notifyRoot:GetChildren()) do
        if card:IsA("GuiObject") and card.Name:match("^Notify_Raid_") and (card.Visible == true) then
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
                        for _, btn in ipairs(yesButtons) do
                            if btn and (btn:IsA("TextButton") or btn:IsA("ImageButton")) then
                                if robustClickObject(btn) then
                                    Fluent:Notify({
                                        Title = "✅ YES clicado",
                                        Content = "Gate aceito.",
                                        Duration = 3
                                    })
                                    task.spawn(function()
                                        task.wait(0.6)
                                        if not verifyGateEntry() then
                                            findAndActivateSpawnGate()
                                        end
                                    end)
                                    return true
                                end
                            end
                        end
                        for _, child in ipairs(actions:GetDescendants()) do
                            if (child:IsA("TextButton") or child:IsA("ImageButton")) then
                                local childName = (child.Name or ""):lower()
                                local childText = (child.Text or ""):lower()
                                if childName:find("yes") or childText:find("yes")
                                   or childName:find("confirm") or childText:find("confirm") then
                                    if robustClickObject(child) then
                                        Fluent:Notify({
                                            Title = "✅ Botão confirmado",
                                            Content = "Gate aceito.",
                                            Duration = 3
                                        })
                                        task.spawn(function()
                                            task.wait(0.6)
                                            if not verifyGateEntry() then
                                                findAndActivateSpawnGate()
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
                GateStatus:SetDesc(("✗ Ignorado (Rank %s / World %s) - Filtro: Ranks [%s] | World %d")
                    :format(rank, worldNum, selectedRanksText(), SelectedGateWorld))
                continue
            end

            Fluent:Notify({
                Title = "⚡ GATE ELEGÍVEL",
                Content = ("Rank %s | World %s"):format(rank, worldNum),
                Duration = 5
            })

            if GateAutomationEnabled then
                -- AÇÃO ÚNICA no momento da notificação
                task.wait(0.3)
                local clicked = clickYesInCurrentGateNotify()
                if clicked then
                    GateStatus:SetDesc(("✅ Gate Rank %s aceito automaticamente!"):format(rank))
                    return
                end
                -- Fallback apenas agora
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

-- Detector de novas notificações (sem loop de estação)
local function setupGateDetector()
    local success, notifyRoot = pcall(function()
        return LocalPlayer.PlayerGui:WaitForChild("HUD"):WaitForChild("Main"):WaitForChild("GamemodeNotify")
    end)
    if success and notifyRoot then
        -- Quando nascer uma notificação (ex.: 23:10, 23:20, ...)
        notifyRoot.ChildAdded:Connect(function(card)
            if card.Name:match("^Notify_Raid_") then
                task.spawn(function()
                    task.wait(0.25)
                    scanCurrentGates()
                end)
            end
        end)
        -- Quando ficar visível
        for _, card in ipairs(notifyRoot:GetChildren()) do
            if card.Name:match("^Notify_Raid_") then
                card:GetPropertyChangedSignal("Visible"):Connect(function()
                    if card:IsA("GuiObject") and card.Visible then
                        task.spawn(function()
                            task.wait(0.25)
                            scanCurrentGates()
                        end)
                    end
                end)
            end
        end
    end
end

-- Interface do Gate (sem Auto RaidStation em loop)
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
        GateStatus:SetDesc(state and ("Procurando Gates: " .. selectedRanksText()) or "Gate desativado")
        if state then
            Fluent:Notify({
                Title = "Gate Detector Ativado",
                Content = "Aguardando o horário do spawn para notificação...",
                Duration = 3
            })
            task.spawn(setupGateDetector)
            -- Sem loop agressivo: apenas uma leitura inicial, depois só via eventos
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
            Fluent:Notify({
                Title = "Automação Ativada",
                Content = "Aceitará o Gate somente quando notificado.",
                Duration = 3
            })
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
                                    local statusMsg = string.format(
                                        "✅ Arise encontrado: %s | %s | %s",
                                        promptInfo.enemyName,
                                        promptInfo.worldName,
                                        promptInfo.objectText
                                    )
                                    StatusArise:SetDesc(statusMsg)
                                    local ariseKey = promptInfo.worldName .. "|" .. promptInfo.enemyName .. "|" .. promptInfo.objectText
                                    if not isManual and not NotifiedAriseKeys[ariseKey] then
                                        Fluent:Notify({
                                            Title = "⚡ ARISE DETECTADO",
                                            Content = string.format("%s em %s (%s)",
                                                promptInfo.enemyName,
                                                promptInfo.worldName,
                                                promptInfo.objectText),
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
            local statusText = string.format(
                "🔍 Procurando... | Encontrados: %d | Mundos ativos: %d",
                AriseDetectionCount,
                worldCount
            )
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
    if not promptInfo or not promptInfo.promptObject then return false end
    local prompt = promptInfo.promptObject
    if not prompt or not prompt:IsA("ProximityPrompt") then return false end
    if not promptInfo.enemyObject or not promptInfo.enemyObject.Parent then return false end
    local character = LocalPlayer.Character
    if not character then return false end
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    local hrpPlayer = character:FindFirstChild("HumanoidRootPart")
    if not hrpPlayer then return false end
    local targetPosition = promptInfo.hrpObject.Position + Vector3.new(0, 3, 0)
    pcall(function() hrpPlayer.CFrame = CFrame.new(targetPosition) end)
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
    while task.wait(AriseCheckInterval) do
        if not AutoAriseEnabled then break end
        local raidArenas = workspace:FindFirstChild("RaidArenas")
        if not raidArenas then
            StatusArise:SetDesc("🔍 Aguardando modo Raid/Gate...")
            continue
        end
        local foundPrompts = scanAllArisePrompts(false)
        if #foundPrompts > 0 and AutoAriseActivation then
            for _, promptInfo in ipairs(foundPrompts) do
                if not AutoAriseEnabled then break end
                if promptInfo.activatedCount < promptInfo.chances then
                    local success = activateArisePrompt(promptInfo)
                    if success then task.wait(0.5) end
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
            Fluent:Notify({ Title = "Ativação Automática", Content = "O sistema vai clicar nos prompts ARISE automaticamente", Duration = 3 })
        end
    end
})

Tabs.Arise:AddSlider("AriseCheckInterval", {
    Title = "Intervalo de Verificação (segundos)",
    Min = 0.5, Max = 5, Default = 1.0, Rounding = 1,
    Callback = function(value) AriseCheckInterval = value end
})

Tabs.Arise:AddSlider("AriseHoldDelay", {
    Title = "Delay Extra de Hold (segundos)",
    Min = 0.1, Max = 0.5, Default = 0.2, Rounding = 1,
    Callback = function(value) AriseHoldDelay = value end
})

-- ========== SISTEMA DE AUTO DUNGEON ==========
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

Tabs.Main:AddSlider("LeaveRoom", {
    Title = "Leave Room", Min = 1, Max = 50, Default = 50, Rounding = 0.1,
    Callback = function(Value) LeaveRoom = Value end
})

-- ========== SISTEMA DE AUTO BALL ==========
AddBallSection()

BallStatus = Tabs.Ball:AddParagraph({ Title = "Status", Content = "Auto Ball parado" })

Tabs.Ball:AddSlider("BallRadius", {
    Title = "Raio de busca", Min = 300, Max = 1000, Default = 650, Rounding = 0,
    Callback = function(value) BallRadius = value end
})

Tabs.Ball:AddSlider("BallCooldown", {
    Title = "Cooldown", Min = 0.1, Max = 2, Default = 0.4, Rounding = 1,
    Callback = function(value) BallCooldown = value end
})

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

-- Funções do Auto Ball
local function findNearbyBalls()
    local nearbyBalls = {}
    if not ensureCharacterAlive() then return nearbyBalls end
    local humanoidRootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return nearbyBalls end
    local ballsFolder = workspace:FindFirstChild(ballsFolderName)
    if not ballsFolder then return nearbyBalls end
    local characterPos = humanoidRootPart.Position
    for _, ballModel in ipairs(ballsFolder:GetChildren()) do
        local sphere = ballModel:FindFirstChild(sphereName)
        if sphere and sphere:IsA("BasePart") then
            local prompt = sphere:FindFirstChild(promptName)
            if prompt and prompt:IsA("ProximityPrompt") then
                local distance = (sphere.Position - characterPos).Magnitude
                if distance <= BallRadius then
                    table.insert(nearbyBalls, {
                        model = ballModel, sphere = sphere, prompt = prompt, distance = distance
                    })
                end
            end
        end
    end
    table.sort(nearbyBalls, function(a, b) return a.distance < b.distance end)
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
    if not ballData.sphere.Parent or not ballData.model.Parent then return false end
    if not ensureCharacterAlive() then return false end
    local humanoidRootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return false end
    local sphere = ballData.sphere
    local prompt = ballData.prompt
    local ballModel = ballData.model
    local distance = (sphere.Position - humanoidRootPart.Position).Magnitude
    if distance > BallRadius then return false end
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
        local humanoidRootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then continue end
        local balls = findNearbyBalls()
        if #balls == 0 then
            currentTarget = "Nenhuma bola próxima"
            BallStatus:SetDesc("Procurando bolas...")
            task.wait(0.5)
            continue
        end
        for _, ballData in ipairs(balls) do
            if not AutoBallEnabled then break end
            if not ensureCharacterAlive() then break end
            if ballData and ballData.sphere and ballData.sphere.Parent then
                local success = collectBall(ballData)
                if success then task.wait(BallCooldown) else task.wait(0.15) end
            end
        end
    end
end

-- ========== LOOP PRINCIPAL DO AUTO DUNGEON ==========
local lastEmptyTime = tick()

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

-- Auto Join opcional
AddAutoJoinSection()
JoinStatus = Tabs.AutoJoin:AddParagraph({ Title = "Status", Content = "Auto Join parado" })
Tabs.AutoJoin:AddToggle("AutoJoinToggle", {
    Title = "Ativar Auto Join",
    Default = false,
    Callback = function(state)
        if not KeyPassed then
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
    Min = 0.5, Max = 5, Default = 1.0, Rounding = 1,
    Callback = function(v) JoinDetectionInterval = v end
})

Window:SelectTab(2)
Fluent:Notify({
    Title = "✅ Script Carregado",
    Content = "Sistema PRO completo ativado! Todos os módulos prontos.",
    Duration = 3
})
