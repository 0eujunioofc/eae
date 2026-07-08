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
    Main = Window:AddTab({ Title = "Main", Icon = "swords" }),
    Gamemodes = Window:AddTab({ Title = "Gamemodes", Icon = "box" }),
    Misc = Window:AddTab({ Title = "Misc", Icon = "settings" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "sliders-horizontal" }),
}

-- Atalhos para não precisar mudar o script inteiro
Tabs.Defense = Tabs.Gamemodes
Tabs.Ball = Tabs.Gamemodes
Tabs.Gate = Tabs.Gamemodes
Tabs.Arise = Tabs.Gamemodes
Tabs.AutoJoin = Tabs.Misc

local function AddSection(tab, title, desc)
    return tab:AddParagraph({
        Title = "━━━━ " .. title,
        Content = desc or ""
    })
end

-- VARIÁVEIS DO AUTO ARISE
local AutoAriseEnabled = false
local AutoAriseActivation = false
local AriseCheckInterval = 1.0
local AriseHoldDelay = 0.2
local AriseDetectionCount = 0
local LastAriseEnemies = {}
local ActiveAriseWorlds = {}
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
local StatusArise = Tabs.Arise:AddParagraph({
    Title = "Status do Arise",
    Content = "Sistema desativado"
})

local GateStatus = Tabs.Gate:AddParagraph({
    Title = "Status do Gate",
    Content = "Sistema desativado"
})

local JoinStatus = Tabs.AutoJoin:AddParagraph({
    Title = "Status do Auto Join",
    Content = "Sistema desativado"
})

local BallStatus = Tabs.Ball:AddParagraph({ Title = "Status", Content = "Auto Ball parado" })
local StatusLabel = Tabs.Main:AddParagraph({ Title = "Status", Content = "Idle" })

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
Tabs.Updates:AddParagraph({ Title = "Version v0.1.5", Content = "[Gamemodes] Adicionado Detector de Gate" })
Tabs.Updates:AddParagraph({ Title = "Version v0.1.4", Content = "[Updates] Adicionado sistema de Updates/Changelog" })
Tabs.Updates:AddParagraph({ Title = "Version v0.1.3", Content = "[Gamemodes] Adicionado Auto Ball" })

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

-- ========== FUNÇÕES COMPARTILHADAS ==========
local function robustClickObject(obj)
    if not obj then return false end
    
    -- Tentar todos os métodos possíveis
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
            if typeof(getconnections) == "function" then
                pcall(function()
                    if obj.MouseButton1Click then
                        for _, conn in ipairs(getconnections(obj.MouseButton1Click)) do
                            conn:Fire()
                        end
                    end
                    if obj.Activated then
                        for _, conn in ipairs(getconnections(obj.Activated)) do
                            conn:Fire()
                        end
                    end
                end)
                return true
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
        end,
        function() if pcall(function() obj:Activate() end) then return true end end
    }
    
    for _, method in ipairs(methods) do
        local success = pcall(method)
        if success then
            task.wait(0.1)
            return true
        end
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
    
    -- Procurar em diferentes locais da GUI
    local guiLocations = {
        LocalPlayer.PlayerGui,
        game:GetService("CoreGui")
    }
    
    for _, gui in ipairs(guiLocations) do
        pcall(function()
            local function scanDescendants(parent)
                for _, child in ipairs(parent:GetDescendants()) do
                    if child:IsA("TextButton") or child:IsA("ImageButton") then
                        local text = child.Text or ""
                        local name = child.Name or ""
                        
                        -- Verificar se é um botão de join
                        if text:lower():find("join") or name:lower():find("join") or
                           text:lower():find("entrar") or name:lower():find("entrar") or
                           text:lower():find("play") or name:lower():find("play") then
                            table.insert(joinButtons, child)
                        end
                    end
                end
            end
            
            scanDescendants(gui)
        end)
    end
    
    return joinButtons
end

local function autoJoinLoop()
    while task.wait(JoinDetectionInterval) do
        if not AutoJoinEnabled then
            JoinStatus:SetDesc("Auto Join desativado")
            continue
        end
        
        JoinStatus:SetDesc("Procurando botões JOIN...")
        
        local joinButtons = findJoinButtons()
        if #joinButtons > 0 then
            JoinStatus:SetDesc("✅ " .. #joinButtons .. " botões JOIN encontrados")
            
            for _, button in ipairs(joinButtons) do
                if not AutoJoinEnabled then break end
                
                JoinStatus:SetDesc("Clicando no botão JOIN...")
                local clicked = robustClickObject(button)
                
                if clicked then
                    Fluent:Notify({
                        Title = "✅ JOIN clicado",
                        Content = "Entrando no servidor...",
                        Duration = 3
                    })
                    JoinStatus:SetDesc("✅ JOIN realizado - aguardando carregamento")
                    task.wait(3)
                    break
                end
            end
        else
            JoinStatus:SetDesc("❌ Nenhum botão JOIN encontrado")
        end
    end
end

-- Interface do Auto Join
Tabs.AutoJoin:AddToggle("AutoJoinToggle", {
    Title = "Ativar Auto Join",
    Default = false,
    Callback = function(state)
        if not KeyPassed then
            AutoJoinEnabled = false
            Fluent:Notify({
                Title = "Key necessária",
                Content = "Digite a key primeiro.",
                Duration = 3
            })
            return
        end
        
        AutoJoinEnabled = state
        JoinStatus:SetDesc(state and "Auto Join ativado" or "Auto Join desativado")
        
        if state then
            Fluent:Notify({
                Title = "Auto Join Ativado",
                Content = "Procurando botões JOIN automaticamente",
                Duration = 3
            })
        end
    end
})

Tabs.AutoJoin:AddSlider("JoinInterval", {
    Title = "Intervalo de Verificação (segundos)",
    Min = 0.5,
    Max = 5,
    Default = 1.0,
    Rounding = 1,
    Callback = function(value)
        JoinDetectionInterval = value
    end
})

Tabs.AutoJoin:AddButton({
    Title = "🔍 Verificar JOIN Agora",
    Description = "Procura por botões JOIN manualmente",
    Callback = function()
        local buttons = findJoinButtons()
        if #buttons > 0 then
            JoinStatus:SetDesc("✅ " .. #buttons .. " botões JOIN encontrados")
            Fluent:Notify({
                Title = "Verificação Manual",
                Content = #buttons .. " botões JOIN encontrados",
                Duration = 3
            })
        else
            JoinStatus:SetDesc("❌ Nenhum botão JOIN encontrado")
        end
    end
})

-- ========== SISTEMA DE AUTO GATE COMPLETO ==========
local function verifyGateEntry()
    local raidArenas = workspace:FindFirstChild("RaidArenas")
    if not raidArenas then return false end
    
    local world5 = raidArenas:FindFirstChild("World5")
    if not world5 then return false end
    
    local enemies = world5:FindFirstChild("Enemies")
    return enemies ~= nil
end

local function clickYesButton(card)
    if not card then return false end
    
    -- Procurar o botão YES dentro do card
    local actionsFrame = card:FindFirstChild("Actions")
    if not actionsFrame then return false end
    
    -- Procurar por diferentes nomes de botão YES
    local yesButtonNames = {"YES", "Yes", "yes", "CONFIRM", "Confirm", "confirm"}
    
    for _, name in ipairs(yesButtonNames) do
        local yesButton = actionsFrame:FindFirstChild(name)
        if yesButton and (yesButton:IsA("ImageButton") or yesButton:IsA("TextButton")) then
            return robustClickObject(yesButton)
        end
    end
    
    -- Procurar em todos os descendentes
    for _, child in ipairs(actionsFrame:GetDescendants()) do
        if (child:IsA("ImageButton") or child:IsA("TextButton")) then
            local text = child.Text or ""
            local name = child.Name or ""
            
            if text:upper() == "YES" or name:upper() == "YES" or
               text:lower():find("yes") or name:lower():find("yes") then
                return robustClickObject(child)
            end
        end
    end
    
    return false
end

local function findAndActivateSpawnGate()
    -- Procurar por diferentes nomes de spawn gate
    local spawnGateNames = {"RaidStation", "SpawnGate", "GateSpawn", "StartGate"}
    
    for _, name in ipairs(spawnGateNames) do
        local spawnGate = workspace:FindFirstChild(name)
        if spawnGate then
            -- Teleportar próximo ao spawn gate
            teleportToPosition(spawnGate.Position)
            task.wait(0.3)
            
            -- Tentar diferentes métodos de ativação
            local methods = {
                function()
                    local touchInterest = spawnGate:FindFirstChildOfClass("TouchInterest")
                    if touchInterest then
                        local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            firetouchinterest(hrp, spawnGate, 0)
                            task.wait(0.05)
                            firetouchinterest(hrp, spawnGate, 1)
                            return true
                        end
                    end
                end,
                function()
                    local proximityPrompt = spawnGate:FindFirstChildOfClass("ProximityPrompt")
                    if proximityPrompt then
                        fireproximityprompt(proximityPrompt)
                        return true
                    end
                end,
                function()
                    -- Tentar click direto se for uma parte clicável
                    if spawnGate:IsA("BasePart") then
                        robustClickObject(spawnGate)
                        return true
                    end
                end
            }
            
            for _, method in ipairs(methods) do
                local success = pcall(method)
                if success then
                    task.wait(0.5)
                    return true
                end
            end
        end
    end
    
    return false
end

local function executeGateAutomation(card, rank, worldNum)
    if not AutoGateEnabled or not GateAutomationEnabled then return end
    
    GateStatus:SetDesc("⚡ Iniciando automação do Gate...")
    
    -- 1. Clicar no botão YES do card
    local clicked = clickYesButton(card)
    
    if clicked then
        Fluent:Notify({
            Title = "✅ YES clicado",
            Content = "Entrando no Gate Rank " .. rank .. "...",
            Duration = 3
        })
        
        GateStatus:SetDesc("✅ YES clicado - aguardando carregamento...")
        task.wait(2)
        
        -- 2. Aguardar carregamento e encontrar RaidStation
        GateStatus:SetDesc("Procurando RaidStation...")
        
        local foundSpawn = false
        for i = 1, 20 do
            if not AutoGateEnabled then break end
            
            foundSpawn = findAndActivateSpawnGate()
            if foundSpawn then
                GateStatus:SetDesc("✅ SpawnGate ativado - verificando entrada...")
                break
            end
            task.wait(0.5)
        end
        
        if foundSpawn then
            -- 3. Verificar se entrou no gate
            task.wait(3)
            local isInside = verifyGateEntry()
            
            if isInside then
                GateStatus:SetDesc("✅ DENTRO do Gate World5 - Modo ativo!")
                Fluent:Notify({
                    Title = "🎉 GATE ENTRADO",
                    Content = "Entrada automática concluída com sucesso!",
                    Duration = 5
                })
            else
                GateStatus:SetDesc("⚠️ Entrada não confirmada - verifique manualmente")
            end
        else
            GateStatus:SetDesc("❌ Não foi possível encontrar/ativar o SpawnGate")
        end
    else
        GateStatus:SetDesc("❌ Não conseguiu clicar no YES - tente manualmente")
    end
end

local function isGateRankSelected(rank)
    if not rank then return false end
    return SelectedGateRanks[rank] == true
end

local function scanCurrentGates()
    if not AutoGateEnabled then return end
    
    local success, notifyRoot = pcall(function()
        return LocalPlayer.PlayerGui:WaitForChild("HUD"):WaitForChild("Main"):WaitForChild("GamemodeNotify")
    end)
    
    if not success or not notifyRoot then return end

    for _, card in ipairs(notifyRoot:GetChildren()) do
        if card.Name:match("^Notify_Raid_") then
            task.spawn(function()
                task.wait(0.2)
                
                local desc = card:FindFirstChild("Description")
                if not desc or not desc:IsA("TextLabel") then return end

                local text = desc.Text or ""
                local header = card:FindFirstChild("Header")
                local titleObj = header and header:FindFirstChild("Title")
                local titleText = titleObj and titleObj.Text or ""
                
                local isGate = text:lower():find("gate") or titleText:lower():find("gate")
                if not isGate then return end

                local rank = text:match("Rank%s+([SABCDEF])")
                local worldNum = text:match("World%s+(%d+)")

                if rank and worldNum then
                    if GateStatus then
                        GateStatus:SetDesc("Gate encontrado: Rank " .. rank .. " | World " .. worldNum)
                    end

                    -- Se for um Gate dos ranks e mundo selecionados, inicia automação
                    if isGateRankSelected(rank) and tonumber(worldNum) == SelectedGateWorld then
                        Fluent:Notify({
                            Title = "⚡ GATE ENCONTRADO",
                            Content = "Rank " .. rank .. " | World " .. worldNum .. " | Iniciando automação...",
                            Duration = 5
                        })

                        -- Executar fluxo automático
                        executeGateAutomation(card, rank, worldNum)
                    end
                end
            end)
        end
    end
end

local function setupGateDetector()
    local success, notifyRoot = pcall(function()
        return LocalPlayer.PlayerGui:WaitForChild("HUD"):WaitForChild("Main"):WaitForChild("GamemodeNotify")
    end)

    if success and notifyRoot then
        notifyRoot.ChildAdded:Connect(function(card)
            if card.Name:match("^Notify_Raid_") then
                task.spawn(function()
                    task.wait(0.3)
                    scanCurrentGates()
                end)
            end
        end)
    end
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

-- Interface do Gate
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

        if GateStatus then
            GateStatus:SetDesc("Ranks escolhidos: " .. selectedRanksText())
        end
    end
})

Tabs.Gate:AddToggle("AutoGateToggle", {
    Title = "Ativar Detecção de Gate",
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
                Content = "Monitorando notificações de Gate...",
                Duration = 3
            })
            task.spawn(setupGateDetector)
            task.spawn(scanCurrentGates)
        end
    end
})

Tabs.Gate:AddToggle("GateAutomationToggle", {
    Title = "Ativar Automação Completa",
    Description = "Clica YES + entra automaticamente no Gate",
    Default = false,
    Callback = function(state)
        GateAutomationEnabled = state
        if state then
            Fluent:Notify({
                Title = "Automação Ativada",
                Content = "O sistema vai entrar automaticamente nos Gates",
                Duration = 3
            })
        end
    end
})

Tabs.Gate:AddButton({
    Title = "🔍 Verificar Gate Atual",
    Description = "Verifica se você está dentro de algum Gate",
    Callback = function()
        local raidArenas = workspace:FindFirstChild("RaidArenas")
        if not raidArenas then
            GateStatus:SetDesc("❌ Fora do modo Raid/Gate")
            return
        end
        
        local activeGates = {}
        for _, world in ipairs(raidArenas:GetChildren()) do
            if world:IsA("Folder") or world:IsA("Model") then
                local enemies = world:FindFirstChild("Enemies")
                if enemies then
                    table.insert(activeGates, world.Name)
                end
            end
        end
        
        if #activeGates > 0 then
            GateStatus:SetDesc("✅ Dentro do Gate: " .. table.concat(activeGates, ", "))
        else
            GateStatus:SetDesc("❌ Fora do modo Gate")
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
    
    -- Limpar detecções anteriores (apenas se não for manual)
    if not isManual then
        LastAriseEnemies = {}
        ActiveAriseWorlds = {}
    end
    
    -- Verificar se há RaidArenas no workspace
    local raidArenas = workspace:FindFirstChild("RaidArenas")
    if not raidArenas then
        if isManual then
            StatusArise:SetDesc("❌ Nenhuma RaidArenas encontrada no workspace")
            Fluent:Notify({
                Title = "Verificação Manual",
                Content = "RaidArenas não encontrada",
                Duration = 3
            })
        end
        return foundPrompts
    end
    
    -- Iterar por todos os mundos
    for _, worldFolder in ipairs(raidArenas:GetChildren()) do
        if worldFolder:IsA("Folder") or worldFolder:IsA("Model") then
            local worldName = worldFolder.Name
            local enemiesFolder = worldFolder:FindFirstChild("Enemies")
            
            if enemiesFolder then
                worldCount = worldCount + 1
                ActiveAriseWorlds[worldName] = true
                
                -- Verificar cada inimigo na pasta Enemies
                for _, enemy in ipairs(enemiesFolder:GetChildren()) do
                    if enemy:IsA("Model") then
                        local hrp = enemy:FindFirstChild("HumanoidRootPart")
                        
                        if hrp then
                            local arisePrompt = hrp:FindFirstChild("ArisePrompt")
                            
                            if arisePrompt and arisePrompt:IsA("ProximityPrompt") then
                                -- Coletar informações do prompt
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
                                    chances = 3 -- Valor padrão
                                }
                                
                                -- Extrair número de chances do ObjectText
                                local chancesText = promptInfo.objectText
                                if chancesText then
                                    local chanceNumber = tonumber(chancesText:match("%d+"))
                                    if chanceNumber then
                                        promptInfo.chances = chanceNumber
                                    end
                                end
                                
                                table.insert(foundPrompts, promptInfo)
                                AriseDetectionCount = AriseDetectionCount + 1
                                
                                -- Adicionar às últimas detecções
                                LastAriseEnemies[enemy.Name] = promptInfo
                                
                                if isManual or AutoAriseEnabled then
                                    local statusMsg = string.format(
                                        "✅ Arise encontrado: %s | %s | %s",
                                        promptInfo.enemyName,
                                        promptInfo.worldName,
                                        promptInfo.objectText
                                    )
                                    StatusArise:SetDesc(statusMsg)
                                    
                                    -- Notificar apenas uma vez por prompt novo
                                    if isManual or not promptInfo.notified then
                                        Fluent:Notify({
                                            Title = "⚡ ARISE DETECTADO",
                                            Content = string.format("%s em %s (%s)", 
                                                promptInfo.enemyName, 
                                                promptInfo.worldName,
                                                promptInfo.objectText),
                                            Duration = 5
                                        })
                                        promptInfo.notified = true
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- Atualizar status baseado nos resultados
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
            StatusArise:SetDesc(string.format(
                "✅ Verificação manual: %d ARISE(s) encontrado(s)",
                AriseDetectionCount
            ))
        else
            StatusArise:SetDesc("❌ Verificação manual: Nenhum ARISE encontrado")
        end
    end
    
    return foundPrompts
end

local function activateArisePrompt(promptInfo)
    if not promptInfo or not promptInfo.promptObject then return false end
    
    local prompt = promptInfo.promptObject
    
    -- Verificar se o prompt ainda existe
    if not prompt or not prompt:IsA("ProximityPrompt") then
        return false
    end
    
    -- Verificar se o inimigo ainda existe
    if not promptInfo.enemyObject or not promptInfo.enemyObject.Parent then
        return false
    end
    
    -- Verificar se player está vivo
    local character = LocalPlayer.Character
    if not character then return false end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        return false
    end
    
    local hrpPlayer = character:FindFirstChild("HumanoidRootPart")
    if not hrpPlayer then return false end
    
    -- Teleportar próximo ao inimigo
    local targetPosition = promptInfo.hrpObject.Position + Vector3.new(0, 3, 0)
    
    -- Usar método seguro de teleport
    pcall(function()
        hrpPlayer.CFrame = CFrame.new(targetPosition)
    end)
    
    task.wait(0.1)
    
    -- Ativar o ProximityPrompt
    local success = false
    
    pcall(function()
        local holdTime = promptInfo.holdDuration + AriseHoldDelay
        
        -- Tentar método direto
        firesignal(prompt.Triggered)
        success = true
    end)
    
    if not success then
        pcall(function()
            -- Método alternativo
            fireproximityprompt(prompt)
            success = true
        end)
    end
    
    -- Verificar se foi bem sucedido
    if success then
        task.wait(0.3)
        
        -- Verificar se o prompt foi removido (indica sucesso)
        if not prompt or not prompt.Parent then
            -- Incrementar contador
            promptInfo.activatedCount = (promptInfo.activatedCount or 0) + 1
            
            -- Notificar sucesso
            Fluent:Notify({
                Title = "✅ ARISE ATIVADO",
                Content = string.format("%s (%d/%d chances)",
                    promptInfo.enemyName,
                    promptInfo.activatedCount,
                    promptInfo.chances
                ),
                Duration = 4
            })
            
            StatusArise:SetDesc(string.format(
                "✅ ARISE ativado em %s | %d/%d chances",
                promptInfo.enemyName,
                promptInfo.activatedCount,
                promptInfo.chances
            ))
            
            return true
        end
    end
    
    return false
end

-- Loop principal de detecção e ativação do Arise
local function startAriseSystem()
    while task.wait(AriseCheckInterval) do
        if not AutoAriseEnabled then break end
        
        -- Verificar se estamos em um modo de jogo
        local raidArenas = workspace:FindFirstChild("RaidArenas")
        if not raidArenas then
            StatusArise:SetDesc("🔍 Aguardando modo Raid/Gate...")
            continue
        end
        
        -- Escanear prompts
        local foundPrompts = scanAllArisePrompts(false)
        
        -- Se encontrou prompts e ativação automática está ligada
        if #foundPrompts > 0 and AutoAriseActivation then
            for _, promptInfo in ipairs(foundPrompts) do
                if not AutoAriseEnabled then break end
                
                -- Verificar se já atingiu o limite de chances
                if promptInfo.activatedCount < promptInfo.chances then
                    local success = activateArisePrompt(promptInfo)
                    if success then
                        task.wait(0.5) -- Cooldown entre ativações
                    end
                end
            end
        end
    end
end

-- ========== INTERFACE DO AUTO ARISE ==========
Tabs.Arise:AddButton({
    Title = "🔍 Verificar Arise (Manual)",
    Description = "Procura por prompts ARISE no momento atual",
    Callback = function()
        if not KeyPassed then
            Fluent:Notify({
                Title = "Key necessária",
                Content = "Digite a key primeiro.",
                Duration = 3
            })
            return
        end
        scanAllArisePrompts(true)
    end
})

-- Toggle principal de detecção
Tabs.Arise:AddToggle("AutoAriseDetection", {
    Title = "Ativar Detecção de Arise",
    Default = false,
    Callback = function(state)
        if not KeyPassed then
            AutoAriseEnabled = false
            Fluent:Notify({
                Title = "Key necessária",
                Content = "Digite a key primeiro.",
                Duration = 3
            })
            StatusArise:SetDesc("Digite a key primeiro")
            return
        end
        
        AutoAriseEnabled = state
        AriseStatusMessage = state and "Procurando ARISE..." or "Sistema desativado"
        StatusArise:SetDesc(AriseStatusMessage)
        
        if state then
            Fluent:Notify({
                Title = "Auto Arise Ativado",
                Content = "Procurando por prompts ARISE...",
                Duration = 3
            })
            -- Iniciar sistema
            task.spawn(startAriseSystem)
        else
            Fluent:Notify({
                Title = "Auto Arise Desativado",
                Content = "Detecção interrompida",
                Duration = 3
            })
        end
    end
})

-- Toggle para ativação automática
Tabs.Arise:AddToggle("AutoAriseActivation", {
    Title = "Ativar Automaticamente o Arise",
    Default = false,
    Callback = function(state)
        AutoAriseActivation = state
        if state then
            Fluent:Notify({
                Title = "Ativação Automática",
                Content = "O sistema vai clicar nos prompts ARISE automaticamente",
                Duration = 3
            })
        end
    end
})

-- Configurações
Tabs.Arise:AddSlider("AriseCheckInterval", {
    Title = "Intervalo de Verificação (segundos)",
    Min = 0.5,
    Max = 5,
    Default = 1.0,
    Rounding = 1,
    Callback = function(value)
        AriseCheckInterval = value
        if StatusArise then
            StatusArise:SetDesc("Intervalo ajustado: " .. value .. " segundos")
        end
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

-- Botão para listar mundos ativos
Tabs.Arise:AddButton({
    Title = "🌎 Listar Mundos Ativos",
    Description = "Mostra quais mundos estão com Enemies ativos",
    Callback = function()
        local raidArenas = workspace:FindFirstChild("RaidArenas")
        if not raidArenas then
            StatusArise:SetDesc("❌ RaidArenas não encontrada")
            return
        end
        
        local activeWorlds = {}
        for _, world in ipairs(raidArenas:GetChildren()) do
            if world:IsA("Folder") or world:IsA("Model") then
                local enemies = world:FindFirstChild("Enemies")
                if enemies then
                    table.insert(activeWorlds, world.Name)
                end
            end
        end
        
        if #activeWorlds > 0 then
            StatusArise:SetDesc("🌎 Mundos ativos: " .. table.concat(activeWorlds, ", "))
        else
            StatusArise:SetDesc("❌ Nenhum mundo com Enemies ativo")
        end
    end
})

-- ========== SISTEMA DE AUTO DUNGEON ==========
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

-- ========== SISTEMA DE AUTO BALL ==========
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

-- ========== FUNÇÕES DO AUTO DUNGEON ==========
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

-- ========== FUNÇÕES DO AUTO BALL ==========
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
                        model = ballModel,
                        sphere = sphere,
                        prompt = prompt,
                        distance = distance
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
    if BallStatus then BallStatus:SetDesc("Coletando: " .. currentTarget) end
    
    local targetPosition = sphere.Position + Vector3.new(0, 2.5, 0)
    local tweenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(humanoidRootPart, tweenInfo, { CFrame = CFrame.new(targetPosition) })
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
            if BallStatus then BallStatus:SetDesc("Auto Ball parado") end
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
            if BallStatus then BallStatus:SetDesc("Procurando bolas...") end
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

-- ========== INICIALIZAÇÃO ==========
-- Iniciar todos os loops
task.spawn(collectionLoop) -- Auto Ball
task.spawn(autoJoinLoop) -- Auto Join
task.spawn(startAriseSystem) -- Auto Arise

-- Inicializar status do Arise
StatusArise:SetDesc("Sistema pronto. Digite a key para começar.")

Window:SelectTab(2)
Fluent:Notify({
    Title = "✅ Script Carregado",
    Content = "Sistema PRO completo ativado! Todos os módulos prontos.",
    Duration = 3
})
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
    Main = Window:AddTab({ Title = "Dungeon", Icon = "swords" }),
    Defense = Window:AddTab({ Title = "Defense", Icon = "shield" }),
    Ball = Window:AddTab({ Title = "Auto Ball", Icon = "circle" }),
    Gate = Window:AddTab({ Title = "Auto Gate", Icon = "circle" }),
    Arise = Window:AddTab({ Title = "Auto Arise", Icon = "user-plus" }),
    AutoJoin = Window:AddTab({ Title = "Auto Join", Icon = "users" }),
}

-- VARIÁVEIS DO AUTO ARISE
local AutoAriseEnabled = false
local AutoAriseActivation = false
local AriseCheckInterval = 1.0
local AriseHoldDelay = 0.2
local AriseDetectionCount = 0
local LastAriseEnemies = {}
local ActiveAriseWorlds = {}
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
local StatusArise = Tabs.Arise:AddParagraph({
    Title = "Status do Arise",
    Content = "Sistema desativado"
})

local GateStatus = Tabs.Gate:AddParagraph({
    Title = "Status do Gate",
    Content = "Sistema desativado"
})

local JoinStatus = Tabs.AutoJoin:AddParagraph({
    Title = "Status do Auto Join",
    Content = "Sistema desativado"
})

local BallStatus = Tabs.Ball:AddParagraph({ Title = "Status", Content = "Auto Ball parado" })
local StatusLabel = Tabs.Main:AddParagraph({ Title = "Status", Content = "Idle" })

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
Tabs.Updates:AddParagraph({ Title = "Version v0.1.5", Content = "[Gamemodes] Adicionado Detector de Gate" })
Tabs.Updates:AddParagraph({ Title = "Version v0.1.4", Content = "[Updates] Adicionado sistema de Updates/Changelog" })
Tabs.Updates:AddParagraph({ Title = "Version v0.1.3", Content = "[Gamemodes] Adicionado Auto Ball" })

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

-- ========== FUNÇÕES COMPARTILHADAS ==========
local function robustClickObject(obj)
    if not obj then return false end
    
    -- Tentar todos os métodos possíveis
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
            if typeof(getconnections) == "function" then
                pcall(function()
                    if obj.MouseButton1Click then
                        for _, conn in ipairs(getconnections(obj.MouseButton1Click)) do
                            conn:Fire()
                        end
                    end
                    if obj.Activated then
                        for _, conn in ipairs(getconnections(obj.Activated)) do
                            conn:Fire()
                        end
                    end
                end)
                return true
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
        end,
        function() if pcall(function() obj:Activate() end) then return true end end
    }
    
    for _, method in ipairs(methods) do
        local success = pcall(method)
        if success then
            task.wait(0.1)
            return true
        end
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
    
    -- Procurar em diferentes locais da GUI
    local guiLocations = {
        LocalPlayer.PlayerGui,
        game:GetService("CoreGui")
    }
    
    for _, gui in ipairs(guiLocations) do
        pcall(function()
            local function scanDescendants(parent)
                for _, child in ipairs(parent:GetDescendants()) do
                    if child:IsA("TextButton") or child:IsA("ImageButton") then
                        local text = child.Text or ""
                        local name = child.Name or ""
                        
                        -- Verificar se é um botão de join
                        if text:lower():find("join") or name:lower():find("join") or
                           text:lower():find("entrar") or name:lower():find("entrar") or
                           text:lower():find("play") or name:lower():find("play") then
                            table.insert(joinButtons, child)
                        end
                    end
                end
            end
            
            scanDescendants(gui)
        end)
    end
    
    return joinButtons
end

local function autoJoinLoop()
    while task.wait(JoinDetectionInterval) do
        if not AutoJoinEnabled then
            JoinStatus:SetDesc("Auto Join desativado")
            continue
        end
        
        JoinStatus:SetDesc("Procurando botões JOIN...")
        
        local joinButtons = findJoinButtons()
        if #joinButtons > 0 then
            JoinStatus:SetDesc("✅ " .. #joinButtons .. " botões JOIN encontrados")
            
            for _, button in ipairs(joinButtons) do
                if not AutoJoinEnabled then break end
                
                JoinStatus:SetDesc("Clicando no botão JOIN...")
                local clicked = robustClickObject(button)
                
                if clicked then
                    Fluent:Notify({
                        Title = "✅ JOIN clicado",
                        Content = "Entrando no servidor...",
                        Duration = 3
                    })
                    JoinStatus:SetDesc("✅ JOIN realizado - aguardando carregamento")
                    task.wait(3)
                    break
                end
            end
        else
            JoinStatus:SetDesc("❌ Nenhum botão JOIN encontrado")
        end
    end
end

-- Interface do Auto Join
Tabs.AutoJoin:AddToggle("AutoJoinToggle", {
    Title = "Ativar Auto Join",
    Default = false,
    Callback = function(state)
        if not KeyPassed then
            AutoJoinEnabled = false
            Fluent:Notify({
                Title = "Key necessária",
                Content = "Digite a key primeiro.",
                Duration = 3
            })
            return
        end
        
        AutoJoinEnabled = state
        JoinStatus:SetDesc(state and "Auto Join ativado" or "Auto Join desativado")
        
        if state then
            Fluent:Notify({
                Title = "Auto Join Ativado",
                Content = "Procurando botões JOIN automaticamente",
                Duration = 3
            })
        end
    end
})

Tabs.AutoJoin:AddSlider("JoinInterval", {
    Title = "Intervalo de Verificação (segundos)",
    Min = 0.5,
    Max = 5,
    Default = 1.0,
    Rounding = 1,
    Callback = function(value)
        JoinDetectionInterval = value
    end
})

Tabs.AutoJoin:AddButton({
    Title = "🔍 Verificar JOIN Agora",
    Description = "Procura por botões JOIN manualmente",
    Callback = function()
        local buttons = findJoinButtons()
        if #buttons > 0 then
            JoinStatus:SetDesc("✅ " .. #buttons .. " botões JOIN encontrados")
            Fluent:Notify({
                Title = "Verificação Manual",
                Content = #buttons .. " botões JOIN encontrados",
                Duration = 3
            })
        else
            JoinStatus:SetDesc("❌ Nenhum botão JOIN encontrado")
        end
    end
})

-- ========== SISTEMA DE AUTO GATE COMPLETO ==========
local function verifyGateEntry()
    local raidArenas = workspace:FindFirstChild("RaidArenas")
    if not raidArenas then return false end
    
    local world5 = raidArenas:FindFirstChild("World5")
    if not world5 then return false end
    
    local enemies = world5:FindFirstChild("Enemies")
    return enemies ~= nil
end

local function clickYesButton(card)
    if not card then return false end
    
    -- Procurar o botão YES dentro do card
    local actionsFrame = card:FindFirstChild("Actions")
    if not actionsFrame then return false end
    
    -- Procurar por diferentes nomes de botão YES
    local yesButtonNames = {"YES", "Yes", "yes", "CONFIRM", "Confirm", "confirm"}
    
    for _, name in ipairs(yesButtonNames) do
        local yesButton = actionsFrame:FindFirstChild(name)
        if yesButton and (yesButton:IsA("ImageButton") or yesButton:IsA("TextButton")) then
            return robustClickObject(yesButton)
        end
    end
    
    -- Procurar em todos os descendentes
    for _, child in ipairs(actionsFrame:GetDescendants()) do
        if (child:IsA("ImageButton") or child:IsA("TextButton")) then
            local text = child.Text or ""
            local name = child.Name or ""
            
            if text:upper() == "YES" or name:upper() == "YES" or
               text:lower():find("yes") or name:lower():find("yes") then
                return robustClickObject(child)
            end
        end
    end
    
    return false
end

local function findAndActivateSpawnGate()
    -- Procurar por diferentes nomes de spawn gate
    local spawnGateNames = {"RaidStation", "SpawnGate", "GateSpawn", "StartGate"}
    
    for _, name in ipairs(spawnGateNames) do
        local spawnGate = workspace:FindFirstChild(name)
        if spawnGate then
            -- Teleportar próximo ao spawn gate
            teleportToPosition(spawnGate.Position)
            task.wait(0.3)
            
            -- Tentar diferentes métodos de ativação
            local methods = {
                function()
                    local touchInterest = spawnGate:FindFirstChildOfClass("TouchInterest")
                    if touchInterest then
                        local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            firetouchinterest(hrp, spawnGate, 0)
                            task.wait(0.05)
                            firetouchinterest(hrp, spawnGate, 1)
                            return true
                        end
                    end
                end,
                function()
                    local proximityPrompt = spawnGate:FindFirstChildOfClass("ProximityPrompt")
                    if proximityPrompt then
                        fireproximityprompt(proximityPrompt)
                        return true
                    end
                end,
                function()
                    -- Tentar click direto se for uma parte clicável
                    if spawnGate:IsA("BasePart") then
                        robustClickObject(spawnGate)
                        return true
                    end
                end
            }
            
            for _, method in ipairs(methods) do
                local success = pcall(method)
                if success then
                    task.wait(0.5)
                    return true
                end
            end
        end
    end
    
    return false
end

local function executeGateAutomation(card, rank, worldNum)
    if not AutoGateEnabled or not GateAutomationEnabled then return end
    
    GateStatus:SetDesc("⚡ Iniciando automação do Gate...")
    
    -- 1. Clicar no botão YES do card
    local clicked = clickYesButton(card)
    
    if clicked then
        Fluent:Notify({
            Title = "✅ YES clicado",
            Content = "Entrando no Gate Rank " .. rank .. "...",
            Duration = 3
        })
        
        GateStatus:SetDesc("✅ YES clicado - aguardando carregamento...")
        task.wait(2)
        
        -- 2. Aguardar carregamento e encontrar RaidStation
        GateStatus:SetDesc("Procurando RaidStation...")
        
        local foundSpawn = false
        for i = 1, 20 do
            if not AutoGateEnabled then break end
            
            foundSpawn = findAndActivateSpawnGate()
            if foundSpawn then
                GateStatus:SetDesc("✅ SpawnGate ativado - verificando entrada...")
                break
            end
            task.wait(0.5)
        end
        
        if foundSpawn then
            -- 3. Verificar se entrou no gate
            task.wait(3)
            local isInside = verifyGateEntry()
            
            if isInside then
                GateStatus:SetDesc("✅ DENTRO do Gate World5 - Modo ativo!")
                Fluent:Notify({
                    Title = "🎉 GATE ENTRADO",
                    Content = "Entrada automática concluída com sucesso!",
                    Duration = 5
                })
            else
                GateStatus:SetDesc("⚠️ Entrada não confirmada - verifique manualmente")
            end
        else
            GateStatus:SetDesc("❌ Não foi possível encontrar/ativar o SpawnGate")
        end
    else
        GateStatus:SetDesc("❌ Não conseguiu clicar no YES - tente manualmente")
    end
end

local function isGateRankSelected(rank)
    if not rank then return false end
    return SelectedGateRanks[rank] == true
end

local function scanCurrentGates()
    if not AutoGateEnabled then return end
    
    local success, notifyRoot = pcall(function()
        return LocalPlayer.PlayerGui:WaitForChild("HUD"):WaitForChild("Main"):WaitForChild("GamemodeNotify")
    end)
    
    if not success or not notifyRoot then return end

    for _, card in ipairs(notifyRoot:GetChildren()) do
        if card.Name:match("^Notify_Raid_") then
            task.spawn(function()
                task.wait(0.2)
                
                local desc = card:FindFirstChild("Description")
                if not desc or not desc:IsA("TextLabel") then return end

                local text = desc.Text or ""
                local header = card:FindFirstChild("Header")
                local titleObj = header and header:FindFirstChild("Title")
                local titleText = titleObj and titleObj.Text or ""
                
                local isGate = text:lower():find("gate") or titleText:lower():find("gate")
                if not isGate then return end

                local rank = text:match("Rank%s+([SABCDEF])")
                local worldNum = text:match("World%s+(%d+)")

                if rank and worldNum then
                    if GateStatus then
                        GateStatus:SetDesc("Gate encontrado: Rank " .. rank .. " | World " .. worldNum)
                    end

                    -- Se for um Gate dos ranks e mundo selecionados, inicia automação
                    if isGateRankSelected(rank) and tonumber(worldNum) == SelectedGateWorld then
                        Fluent:Notify({
                            Title = "⚡ GATE ENCONTRADO",
                            Content = "Rank " .. rank .. " | World " .. worldNum .. " | Iniciando automação...",
                            Duration = 5
                        })

                        -- Executar fluxo automático
                        executeGateAutomation(card, rank, worldNum)
                    end
                end
            end)
        end
    end
end

local function setupGateDetector()
    local success, notifyRoot = pcall(function()
        return LocalPlayer.PlayerGui:WaitForChild("HUD"):WaitForChild("Main"):WaitForChild("GamemodeNotify")
    end)

    if success and notifyRoot then
        notifyRoot.ChildAdded:Connect(function(card)
            if card.Name:match("^Notify_Raid_") then
                task.spawn(function()
                    task.wait(0.3)
                    scanCurrentGates()
                end)
            end
        end)
    end
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

-- Interface do Gate
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

        if GateStatus then
            GateStatus:SetDesc("Ranks escolhidos: " .. selectedRanksText())
        end
    end
})

Tabs.Gate:AddToggle("AutoGateToggle", {
    Title = "Ativar Detecção de Gate",
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
                Content = "Monitorando notificações de Gate...",
                Duration = 3
            })
            task.spawn(setupGateDetector)
            task.spawn(scanCurrentGates)
        end
    end
})

Tabs.Gate:AddToggle("GateAutomationToggle", {
    Title = "Ativar Automação Completa",
    Description = "Clica YES + entra automaticamente no Gate",
    Default = false,
    Callback = function(state)
        GateAutomationEnabled = state
        if state then
            Fluent:Notify({
                Title = "Automação Ativada",
                Content = "O sistema vai entrar automaticamente nos Gates",
                Duration = 3
            })
        end
    end
})

Tabs.Gate:AddButton({
    Title = "🔍 Verificar Gate Atual",
    Description = "Verifica se você está dentro de algum Gate",
    Callback = function()
        local raidArenas = workspace:FindFirstChild("RaidArenas")
        if not raidArenas then
            GateStatus:SetDesc("❌ Fora do modo Raid/Gate")
            return
        end
        
        local activeGates = {}
        for _, world in ipairs(raidArenas:GetChildren()) do
            if world:IsA("Folder") or world:IsA("Model") then
                local enemies = world:FindFirstChild("Enemies")
                if enemies then
                    table.insert(activeGates, world.Name)
                end
            end
        end
        
        if #activeGates > 0 then
            GateStatus:SetDesc("✅ Dentro do Gate: " .. table.concat(activeGates, ", "))
        else
            GateStatus:SetDesc("❌ Fora do modo Gate")
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
    
    -- Limpar detecções anteriores (apenas se não for manual)
    if not isManual then
        LastAriseEnemies = {}
        ActiveAriseWorlds = {}
    end
    
    -- Verificar se há RaidArenas no workspace
    local raidArenas = workspace:FindFirstChild("RaidArenas")
    if not raidArenas then
        if isManual then
            StatusArise:SetDesc("❌ Nenhuma RaidArenas encontrada no workspace")
            Fluent:Notify({
                Title = "Verificação Manual",
                Content = "RaidArenas não encontrada",
                Duration = 3
            })
        end
        return foundPrompts
    end
    
    -- Iterar por todos os mundos
    for _, worldFolder in ipairs(raidArenas:GetChildren()) do
        if worldFolder:IsA("Folder") or worldFolder:IsA("Model") then
            local worldName = worldFolder.Name
            local enemiesFolder = worldFolder:FindFirstChild("Enemies")
            
            if enemiesFolder then
                worldCount = worldCount + 1
                ActiveAriseWorlds[worldName] = true
                
                -- Verificar cada inimigo na pasta Enemies
                for _, enemy in ipairs(enemiesFolder:GetChildren()) do
                    if enemy:IsA("Model") then
                        local hrp = enemy:FindFirstChild("HumanoidRootPart")
                        
                        if hrp then
                            local arisePrompt = hrp:FindFirstChild("ArisePrompt")
                            
                            if arisePrompt and arisePrompt:IsA("ProximityPrompt") then
                                -- Coletar informações do prompt
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
                                    chances = 3 -- Valor padrão
                                }
                                
                                -- Extrair número de chances do ObjectText
                                local chancesText = promptInfo.objectText
                                if chancesText then
                                    local chanceNumber = tonumber(chancesText:match("%d+"))
                                    if chanceNumber then
                                        promptInfo.chances = chanceNumber
                                    end
                                end
                                
                                table.insert(foundPrompts, promptInfo)
                                AriseDetectionCount = AriseDetectionCount + 1
                                
                                -- Adicionar às últimas detecções
                                LastAriseEnemies[enemy.Name] = promptInfo
                                
                                if isManual or AutoAriseEnabled then
                                    local statusMsg = string.format(
                                        "✅ Arise encontrado: %s | %s | %s",
                                        promptInfo.enemyName,
                                        promptInfo.worldName,
                                        promptInfo.objectText
                                    )
                                    StatusArise:SetDesc(statusMsg)
                                    
                                    -- Notificar apenas uma vez por prompt novo
                                    if isManual or not promptInfo.notified then
                                        Fluent:Notify({
                                            Title = "⚡ ARISE DETECTADO",
                                            Content = string.format("%s em %s (%s)", 
                                                promptInfo.enemyName, 
                                                promptInfo.worldName,
                                                promptInfo.objectText),
                                            Duration = 5
                                        })
                                        promptInfo.notified = true
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- Atualizar status baseado nos resultados
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
            StatusArise:SetDesc(string.format(
                "✅ Verificação manual: %d ARISE(s) encontrado(s)",
                AriseDetectionCount
            ))
        else
            StatusArise:SetDesc("❌ Verificação manual: Nenhum ARISE encontrado")
        end
    end
    
    return foundPrompts
end

local function activateArisePrompt(promptInfo)
    if not promptInfo or not promptInfo.promptObject then return false end
    
    local prompt = promptInfo.promptObject
    
    -- Verificar se o prompt ainda existe
    if not prompt or not prompt:IsA("ProximityPrompt") then
        return false
    end
    
    -- Verificar se o inimigo ainda existe
    if not promptInfo.enemyObject or not promptInfo.enemyObject.Parent then
        return false
    end
    
    -- Verificar se player está vivo
    local character = LocalPlayer.Character
    if not character then return false end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        return false
    end
    
    local hrpPlayer = character:FindFirstChild("HumanoidRootPart")
    if not hrpPlayer then return false end
    
    -- Teleportar próximo ao inimigo
    local targetPosition = promptInfo.hrpObject.Position + Vector3.new(0, 3, 0)
    
    -- Usar método seguro de teleport
    pcall(function()
        hrpPlayer.CFrame = CFrame.new(targetPosition)
    end)
    
    task.wait(0.1)
    
    -- Ativar o ProximityPrompt
    local success = false
    
    pcall(function()
        local holdTime = promptInfo.holdDuration + AriseHoldDelay
        
        -- Tentar método direto
        firesignal(prompt.Triggered)
        success = true
    end)
    
    if not success then
        pcall(function()
            -- Método alternativo
            fireproximityprompt(prompt)
            success = true
        end)
    end
    
    -- Verificar se foi bem sucedido
    if success then
        task.wait(0.3)
        
        -- Verificar se o prompt foi removido (indica sucesso)
        if not prompt or not prompt.Parent then
            -- Incrementar contador
            promptInfo.activatedCount = (promptInfo.activatedCount or 0) + 1
            
            -- Notificar sucesso
            Fluent:Notify({
                Title = "✅ ARISE ATIVADO",
                Content = string.format("%s (%d/%d chances)",
                    promptInfo.enemyName,
                    promptInfo.activatedCount,
                    promptInfo.chances
                ),
                Duration = 4
            })
            
            StatusArise:SetDesc(string.format(
                "✅ ARISE ativado em %s | %d/%d chances",
                promptInfo.enemyName,
                promptInfo.activatedCount,
                promptInfo.chances
            ))
            
            return true
        end
    end
    
    return false
end

-- Loop principal de detecção e ativação do Arise
local function startAriseSystem()
    while task.wait(AriseCheckInterval) do
        if not AutoAriseEnabled then break end
        
        -- Verificar se estamos em um modo de jogo
        local raidArenas = workspace:FindFirstChild("RaidArenas")
        if not raidArenas then
            StatusArise:SetDesc("🔍 Aguardando modo Raid/Gate...")
            continue
        end
        
        -- Escanear prompts
        local foundPrompts = scanAllArisePrompts(false)
        
        -- Se encontrou prompts e ativação automática está ligada
        if #foundPrompts > 0 and AutoAriseActivation then
            for _, promptInfo in ipairs(foundPrompts) do
                if not AutoAriseEnabled then break end
                
                -- Verificar se já atingiu o limite de chances
                if promptInfo.activatedCount < promptInfo.chances then
                    local success = activateArisePrompt(promptInfo)
                    if success then
                        task.wait(0.5) -- Cooldown entre ativações
                    end
                end
            end
        end
    end
end

-- ========== INTERFACE DO AUTO ARISE ==========
Tabs.Arise:AddButton({
    Title = "🔍 Verificar Arise (Manual)",
    Description = "Procura por prompts ARISE no momento atual",
    Callback = function()
        if not KeyPassed then
            Fluent:Notify({
                Title = "Key necessária",
                Content = "Digite a key primeiro.",
                Duration = 3
            })
            return
        end
        scanAllArisePrompts(true)
    end
})

-- Toggle principal de detecção
Tabs.Arise:AddToggle("AutoAriseDetection", {
    Title = "Ativar Detecção de Arise",
    Default = false,
    Callback = function(state)
        if not KeyPassed then
            AutoAriseEnabled = false
            Fluent:Notify({
                Title = "Key necessária",
                Content = "Digite a key primeiro.",
                Duration = 3
            })
            StatusArise:SetDesc("Digite a key primeiro")
            return
        end
        
        AutoAriseEnabled = state
        AriseStatusMessage = state and "Procurando ARISE..." or "Sistema desativado"
        StatusArise:SetDesc(AriseStatusMessage)
        
        if state then
            Fluent:Notify({
                Title = "Auto Arise Ativado",
                Content = "Procurando por prompts ARISE...",
                Duration = 3
            })
            -- Iniciar sistema
            task.spawn(startAriseSystem)
        else
            Fluent:Notify({
                Title = "Auto Arise Desativado",
                Content = "Detecção interrompida",
                Duration = 3
            })
        end
    end
})

-- Toggle para ativação automática
Tabs.Arise:AddToggle("AutoAriseActivation", {
    Title = "Ativar Automaticamente o Arise",
    Default = false,
    Callback = function(state)
        AutoAriseActivation = state
        if state then
            Fluent:Notify({
                Title = "Ativação Automática",
                Content = "O sistema vai clicar nos prompts ARISE automaticamente",
                Duration = 3
            })
        end
    end
})

-- Configurações
Tabs.Arise:AddSlider("AriseCheckInterval", {
    Title = "Intervalo de Verificação (segundos)",
    Min = 0.5,
    Max = 5,
    Default = 1.0,
    Rounding = 1,
    Callback = function(value)
        AriseCheckInterval = value
        if StatusArise then
            StatusArise:SetDesc("Intervalo ajustado: " .. value .. " segundos")
        end
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

-- Botão para listar mundos ativos
Tabs.Arise:AddButton({
    Title = "🌎 Listar Mundos Ativos",
    Description = "Mostra quais mundos estão com Enemies ativos",
    Callback = function()
        local raidArenas = workspace:FindFirstChild("RaidArenas")
        if not raidArenas then
            StatusArise:SetDesc("❌ RaidArenas não encontrada")
            return
        end
        
        local activeWorlds = {}
        for _, world in ipairs(raidArenas:GetChildren()) do
            if world:IsA("Folder") or world:IsA("Model") then
                local enemies = world:FindFirstChild("Enemies")
                if enemies then
                    table.insert(activeWorlds, world.Name)
                end
            end
        end
        
        if #activeWorlds > 0 then
            StatusArise:SetDesc("🌎 Mundos ativos: " .. table.concat(activeWorlds, ", "))
        else
            StatusArise:SetDesc("❌ Nenhum mundo com Enemies ativo")
        end
    end
})

-- ========== SISTEMA DE AUTO DUNGEON ==========
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

-- ========== SISTEMA DE AUTO BALL ==========
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

-- ========== FUNÇÕES DO AUTO DUNGEON ==========
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

-- ========== FUNÇÕES DO AUTO BALL ==========
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
                        model = ballModel,
                        sphere = sphere,
                        prompt = prompt,
                        distance = distance
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
    if BallStatus then BallStatus:SetDesc("Coletando: " .. currentTarget) end
    
    local targetPosition = sphere.Position + Vector3.new(0, 2.5, 0)
    local tweenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(humanoidRootPart, tweenInfo, { CFrame = CFrame.new(targetPosition) })
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
            if BallStatus then BallStatus:SetDesc("Auto Ball parado") end
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
            if BallStatus then BallStatus:SetDesc("Procurando bolas...") end
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

-- ========== INICIALIZAÇÃO ==========
-- Iniciar todos os loops
task.spawn(collectionLoop) -- Auto Ball
task.spawn(autoJoinLoop) -- Auto Join
task.spawn(startAriseSystem) -- Auto Arise

-- Inicializar status do Arise
StatusArise:SetDesc("Sistema pronto. Digite a key para começar.")

Window:SelectTab(2)
Fluent:Notify({
    Title = "✅ Script Carregado",
    Content = "Sistema PRO completo ativado! Todos os módulos prontos.",
    Duration = 3
})
