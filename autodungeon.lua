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

-- ========== NOVAS FUNÇÕES ADICIONADAS ==========
-- Utils: obter objeto por caminho "workspace.Worlds[\"9\"].Systems.DungeonStation"
local function getByPath(path)
    local ok, result = pcall(function()
        local node = game
        for part in string.gmatch(path, "[^%.]+") do
            -- suporta índices ["x"]
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

-- Teleporte seguro para um CFrame e interação genérica com "Stations"
local function safeTP(cframe)
    if not ensureCharacterAlive() then return false end
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp or not cframe then return false end
    pcall(function() hrp.CFrame = cframe + Vector3.new(0, 3, 0) end)
    return true
end

local function tryInteract(obj)
    if not obj then return false end
    -- 1) ProximityPrompt
    local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt then
        local ok = pcall(function() fireproximityprompt(prompt) end)
        if ok then return true end
    end
    -- 2) TouchInterest (tocar na BasePart)
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
    -- 3) Botão dentro do modelo (TextButton/ImageButton)
    for _, d in ipairs(obj:GetDescendants()) do
        if d:IsA("TextButton") or d:IsA("ImageButton") then
            if robustClickObject(d) then return true end
        end
    end
    return false
end

-- Entrar por Station (genérico) + helpers de mundo
local function enterByStation(stationPath)
    local station = getByPath(stationPath)
    if not station then return false end
    -- Aproxima
    local cf = partCFrameOf(station)
    if cf then safeTP(cf) task.wait(0.25) end
    -- Tenta interagir algumas vezes
    for _ = 1, 4 do
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

-- Wrappers específicos que você pediu
local function enterDungeonByStation()
    -- Garantir que estamos no mapa do 9 (usa o Map:GetChildren()[8] como referência)
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
    -- Se não estiver no World 5, teleportar para o Spawn do 5
    gotoWorldSpawn(5)
    task.wait(0.25)
    -- Ir até a RaidStation (onde o Gate está)
    local ok = enterByStation('workspace.Worlds["5"].Systems.RaidStation')
    if not ok then
        -- Fallback: tentar SpawnGate (onde spawna o gate)
        ok = enterByStation('workspace.Worlds["5"].SpawnGate')
    end
    return ok
end

-- ========== VARIÁVEES GLOBAIS ==========
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
        local success = pcall(method)
        if success then return true end
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

-- ========== SISTEMA DE AUTO GATE ==========
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
    
    local actionsFrame = card:FindFirstChild("Actions")
    if not actionsFrame then return false end
    
    local yesButtonNames = {"YES", "Yes", "yes", "CONFIRM", "Confirm", "confirm"}
    
    for _, name in ipairs(yesButtonNames) do
        local yesButton = actionsFrame:FindFirstChild(name)
        if yesButton and (yesButton:IsA("ImageButton") or yesButton:IsA("TextButton")) then
            return robustClickObject(yesButton)
        end
    end
    
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
    local spawnGateNames = {"RaidStation", "SpawnGate", "GateSpawn", "StartGate"}
    
    for _, name in ipairs(spawnGateNames) do
        local spawnGate = workspace:FindFirstChild(name)
        if spawnGate then
            teleportToPosition(spawnGate.Position)
            task.wait(0.3)
            
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
                end
            }
            
            for _, method in ipairs(methods) do
                local success = pcall(method)
                if success then return true end
            end
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

-- FUNÇÃO CORRIGIDA PARA CLICAR YES AUTOMATICAMENTE
local function clickYesInCurrentGateNotify()
    if not ensureCharacterAlive() then return false end
    
    local notifyRoot = LocalPlayer.PlayerGui:FindFirstChild("HUD") 
        and LocalPlayer.PlayerGui.HUD:FindFirstChild("Main") 
        and LocalPlayer.PlayerGui.HUD.Main:FindFirstChild("GamemodeNotify")
    
    if not notifyRoot then return false end
    
    for _, card in ipairs(notifyRoot:GetChildren()) do
        if card.Name:match("^Notify_Raid_") and (card.Visible == true) then
            local description = card:FindFirstChild("Description")
            if description and description:IsA("TextLabel") then
                local text = description.Text or ""
                if text:lower():find("gate") then
                    local actions = card:FindFirstChild("Actions")
                    if actions then
                        -- Primeiro tenta encontrar botões com nomes específicos
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
                                        Title = "✅ YES clicado automaticamente",
                                        Content = "Gate aceito com sucesso!",
                                        Duration = 3
                                    })
                                    return true
                                end
                            end
                        end
                        
                        -- Se não encontrou, procura por qualquer botão que contenha "yes" no nome ou texto
                        for _, child in ipairs(actions:GetDescendants()) do
                            if (child:IsA("TextButton") or child:IsA("ImageButton")) then
                                local childName = (child.Name or ""):lower()
                                local childText = (child.Text or ""):lower()
                                
                                if childName:find("yes") or childText:find("yes") or 
                                   childName:find("confirm") or childText:find("confirm") then
                                    if robustClickObject(child) then
                                        Fluent:Notify({
                                            Title = "✅ Botão clicado automaticamente",
                                            Content = "Gate aceito com sucesso!",
                                            Duration = 3
                                        })
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

-- FUNÇÃO MELHORADA PARA SCANEAR GATES
local function scanCurrentGates()
    if not AutoGateEnabled then return end
    
    local success, notifyRoot = pcall(function()
        return LocalPlayer.PlayerGui:WaitForChild("HUD"):WaitForChild("Main"):WaitForChild("GamemodeNotify")
    end)
    
    if not success or not notifyRoot then return end

    for _, card in ipairs(notifyRoot:GetChildren()) do
        if card.Name:match("^Notify_Raid_") and card.Visible then
            local desc = card:FindFirstChild("Description")
            if not desc or not desc:IsA("TextLabel") then return end

            local text = desc.Text or ""
            local isGate = text:lower():find("gate")
            if not isGate then return end

            local rank = text:match("Rank%s+([SABCDEF])")
            local worldNum = text:match("World%s+(%d+)")

            if rank and worldNum then
                GateStatus:SetDesc("⚡ Gate encontrado: Rank " .. rank .. " | World " .. worldNum)

                if isGateRankSelected(rank) and tonumber(worldNum) == SelectedGateWorld then
                    Fluent:Notify({
                        Title = "⚡ GATE ENCONTRADO",
                        Content = "Rank " .. rank .. " | World " .. worldNum,
                        Duration = 5
                    })
                    
                    -- Tenta clicar YES automaticamente se o modo automático estiver ativado
                    if GateAutomationEnabled then
                        task.wait(0.5) -- Pequeno delay para garantir que a interface carregou
                        local success = clickYesInCurrentGateNotify()
                        if success then
                            GateStatus:SetDesc("✅ Gate Rank " .. rank .. " aceito automaticamente!")
                        else
                            GateStatus:SetDesc("⚠️ Gate encontrado - clique YES manualmente")
                        end
                    else
                        GateStatus:SetDesc("⚠️ Gate encontrado - clique YES manualmente")
                    end
                else
                    GateStatus:SetDesc("✗ Gate encontrado (Rank " .. rank .. ") não está selecionado")
                end
            end
        end
    end
end

-- FUNÇÃO MELHORADA PARA DETECTAR NOVOS GATES
local function setupGateDetector()
    local success, notifyRoot = pcall(function()
        return LocalPlayer.PlayerGui:WaitForChild("HUD"):WaitForChild("Main"):WaitForChild("GamemodeNotify")
    end)

    if success and notifyRoot then
        notifyRoot.ChildAdded:Connect(function(card)
            if card.Name:match("^Notify_Raid_") then
                task.spawn(function()
                    task.wait(0.3) -- Aguarda a animação da notificação
                    scanCurrentGates()
                end)
            end
        end)
        
        -- Também monitora mudanças de visibilidade
        for _, card in ipairs(notifyRoot:GetChildren()) do
            if card.Name:match("^Notify_Raid_") then
                card:GetPropertyChangedSignal("Visible"):Connect(function()
                    if card.Visible then
                        task.spawn(function()
                            task.wait(0.3)
                            scanCurrentGates()
                        end)
                    end
                end)
            end
        end
    end
end

-- Interface do Gate MELHORADA
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

-- NOVO TOGGLE PARA AUTOMAÇÃO COMPLETA
Tabs.Gate:AddToggle("GateAutomationToggle", {
    Title = "Clique Automático no YES",
    Description = "Clica automaticamente no botão YES quando encontrar um Gate",
    Default = false,
    Callback = function(state)
        GateAutomationEnabled = state
        if state then
            Fluent:Notify({
                Title = "Automação Ativada",
                Content = "O sistema vai clicar no YES automaticamente",
                Duration = 3
            })
        end
    end
})

-- NOVOS BOTÕES ADICIONADOS PARA STATION
Tabs.Gate:AddButton({
    Title = "Entrar pelo RaidStation (World 5)",
    Description = "Ignora o YES e usa a Station do mundo 5",
    Callback = function()
        local ok = enterGateByStation()
        GateStatus:SetDesc(ok and "✅ Entrou pelo RaidStation/SpawnGate" or "❌ Falha ao interagir com a Station do Gate")
    end
})

Tabs.Main:AddButton({
    Title = "Entrar pela DungeonStation (World 9)",
    Description = "Ignora o YES e usa a DungeonStation direto",
    Callback = function()
        local ok = enterDungeonByStation()
        StatusLabel:SetDesc(ok and "✅ Entrando pela DungeonStation" or "❌ Falha ao interagir com a DungeonStation")
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

Tabs.Gate:AddButton({
    Title = "🖱️ Testar Click YES (Manual)",
    Description = "Tenta clicar no botão YES do Gate atual manualmente",
    Callback = function()
        local success = clickYesInCurrentGateNotify()
        if success then
            GateStatus:SetDesc("✅ Click YES realizado com sucesso")
        else
            GateStatus:SetDesc("❌ Não foi possível clicar no YES")
        end
    end
})

Tabs.Gate:AddButton({
    Title = "🔄 Scanear Gates Agora",
    Description = "Força uma verificação imediata de Gates",
    Callback = function()
        if AutoGateEnabled then
            scanCurrentGates()
        else
            Fluent:Notify({
                Title = "Atenção",
                Content = "Ative o detector de Gates primeiro",
                Duration = 3
            })
        end
    end
})

-- ========== INTERFACE DO AUTO JOIN DO GATE ==========
AddAutoJoinSection()

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

JoinStatus = Tabs.AutoJoin:AddParagraph({
    Title = "Status do Auto Join",
    Content = "Desativado"
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

                                -- Ignora Arise sem chances
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

-- ========== AUTO-RETORNO QUANDO A NOTIFICAÇÃO SUMIU ==========
task.spawn(function()
    local lastGateSeen = tick()
    local lastDungeonSeen = tick()
    while task.wait(0.5) do
        -- Verifica se a HUD tem notify do Gate ou Dungeon
        local notify = LocalPlayer.PlayerGui:FindFirstChild("HUD")
            and LocalPlayer.PlayerGui.HUD:FindFirstChild("Main")
            and LocalPlayer.PlayerGui.HUD.Main:FindFirstChild("GamemodeNotify")
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
        
        -- Gate: tenta Station se notificação sumiu
        if AutoGateEnabled and GateAutomationEnabled then
            if tick() - lastGateSeen > 4 then
                -- sem notify há >4s, tentar entrar por Station
                enterGateByStation()
                lastGateSeen = tick()
            end
        end
        
        -- Dungeon: tenta Station se fora da dungeon e sem notify
        if AutoDungeonEnabled then
            local inDungeon = false
            pcall(function()
                local dA = workspace:FindFirstChild("DungeonArenas")
                if dA then
                    for _, arena in ipairs(dA:GetChildren()) do
                        if arena:FindFirstChild("Enemies") then
                            inDungeon = true
                            break
                        end
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
-- Iniciar todos os loops
task.spawn(collectionLoop) -- Auto Ball
task.spawn(autoJoinLoop) -- Auto Join
task.spawn(startAriseSystem) -- Auto Arise

Window:SelectTab(2)
Fluent:Notify({
    Title = "✅ Script Carregado",
    Content = "Sistema PRO completo ativado! Todos os módulos prontos.",
    Duration = 3
})
