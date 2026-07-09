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
    if not obj then
    if not obj then return false end
    -- ProximityPrompt
    local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt then
        local ok = pcall(function()
            if typeof(firesignal) == "function" then firesignal(prompt.Triggered
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
    local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA
    if not obj then return false end
    -- ProximityPrompt
    local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
   
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
    local part = obj:Is
    if not obj then return
    if not obj then return false end
    -- ProximityPrompt
    local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt then
        local ok = pcall(function()
            if typeof(firesignal) == "function" then firesignal(prompt.Triggered) end
            fireproximityprom
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
                firetouchinterest(hrp,
    if not obj then return false end
    -- ProximityPrompt
    local prompt = obj:FindFirstChildWhichIsA("
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
    local station = get
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
    local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("
    if not obj then return false end
    -- ProximityPrompt
    local prompt = obj:
    if not obj then return false end
    -- ProximityPrompt
    local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt then
        local ok = pcall(function()
            if typeof(fires
    if not obj then return false end
    -- ProximityPrompt
    local prompt = obj:FindFirstChildWhichIs
    if not obj then return false end
    -- ProximityPrompt
    local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt then
        local ok = pcall(function()
            if typeof(firesignal) == "function" then firesignal(prompt.Triggered) end
            fireproximityprompt(prompt)
        end)
        if ok then return true end
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
    local part = obj:IsA("BasePart") and obj or obj:FindFirstChild
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
        if ti and hr
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
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid
    if not obj then return false end
    -- ProximityPrompt
    local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt then
        local ok = pcall(function()
            if typeof(firesignal) == "function" then firesignal(prompt.Triggered) end
            fireproximityprompt(prompt)
        end)

    if not obj then return false end
    -- ProximityPrompt
    local prompt = obj:FindFirstChildWhich
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
                firetouchinterest(hr
    if not obj then return false end
    -- ProximityPrompt
    local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt then
        local ok = p
    if not obj then return false end
    -- ProximityPrompt
    local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt then
        local ok = pcall(function()
            if typeof(firesignal) == "function" then firesignal
    if not obj then return false
    if not obj then return false end
    -- ProximityPrompt
    local prompt = obj:FindFirstChildWhichIsA("Proxim
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
        task.wait
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
    if not raidArenas
    if not raidArenas then return false end
    for _, world in ipairs(raidArenas:GetChildren()) do
        if (world:IsA("Folder") or world:
    if not raidArenas then return false end
    for _, world in ipairs(raid
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
    local root = main and main:FindFirstChild("G
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
    local hud = pgui
    if not raidArenas then return false end
    for _, world in ipairs(raidArenas:GetChildren()) do
        if (world:IsA("Folder") or world:IsA("Model")) and world:FindFirstChild("Enemies
    if not raidArenas then return false end
    for _, world in ipairs(raidArenas:GetChildren()) do
        if (world:IsA("Folder") or world:IsA("Model")) and world:FindFirstChild("Enemies") then
            return true
        end
    end
    if not raidArenas then
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
        if card:IsA("GuiObject") and card.Visible and tostring(card.Name):match("^Notify_Raid_") then
            local desc = card:FindFirstChild("Description")
            if desc and desc:IsA("TextLabel") and string.lower(desc.Text or ""):find("gate") then
                local actions = card:
    if not root then return false end
    for _, card in ipairs(root:GetChildren()) do
        if card:IsA("GuiObject") and card.Visible and tostring(card.Name):match("^Notify_Raid_") then
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
                    if d
    if not root then return false end
    for _, card in ipairs(root:GetChildren()) do
        if card:IsA("GuiObject") and card.Visible and tostring(card.Name):match("^Notify
    if not root then return false end
    for _, card in ipairs(root:
   
    if not root then return false end
    for _, card in ipairs(root:GetChildren()) do
        if card:IsA("GuiObject") and card.Visible and tostring(card.Name):match("^Notify_Raid_") then
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
                    if btn and (btn:IsA("TextButton") or btn:Is
    if not root then return false end
   
    if not root then return false end
    for _, card in ipairs(root:GetChildren()) do
        if card:IsA("GuiObject") and card.Visible and tostring(card.Name):match("^Notify_Raid_") then
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
        if cfs then teleport
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
        if tried then return
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    local tried = false
    local station = getByPath('workspace.World
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
        if cfg then teleportCF(cfg) task.wait(0.
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    local tried = false
    local station = getByPath('workspace.Worlds["5"].Systems.RaidStation')
    if station then
        local cfs = partCFrameOf(station)
        if cfs then teleportCF(c
    -- Garante que está no World 
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou Spawn
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    local tried = false
    local station = getByPath('workspace.Worlds["5"].Systems.RaidStation')

    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    local tried = false
    local station = getByPath('workspace.Worlds["5"].Systems.RaidStation')
    if station then
        local cfs = partCFrameOf(station)
        if cfs then teleport
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.W
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    local tried = false
    local station = getByPath('workspace.Worlds["5"].
    -- Garante que está no World 5 e per
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

    local spawnGate = getBy
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    local tried = false
    local station = getByPath('workspace.Worlds["5"].Systems.RaidStation')
    if station then
        local cfs = partCFrameOf(station)
        if cfs then teleportCF(cfs) task.wait(0.25
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
            if n:find("gate") or n:find("portal") or n
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    local tried = false
    local station = getByPath('workspace.Worlds["
    -- Garante que está no World 5 e perto da praça do
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorld
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    local tried = false
    local station = getByPath('workspace.Worlds["5"].Systems.RaidStation')
    if station then
        local cfs = partCFrameOf(station)
        if
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.
    -- Garante
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    local tried = false
    local station = getByPath('workspace.Worlds["5"].Systems.RaidStation')
    if station then
        local cfs = partCFrame
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    local tried = false
    local station = getByPath('workspace.Worlds["5"].Systems.RaidStation')
    if station then
        local c
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["
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

    local spawnGate = getByPath('workspace.Worlds["
    -- Garante que está no World 5 e perto da pra
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

    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    local tried = false
    local station = getByPath('workspace.Worlds
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    local tried = false
    local station = getByPath('workspace.Worlds["5"].Systems.RaidStation'])
    if station then
        local cfs = partCFrameOf(station)
        if cfs then teleportCF(cfs) task.wait(0.
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    local tried = false
    local station = getByPath('workspace.Worlds["5"].Systems.RaidStation')
    if station then
        local cfs = partCFrameOf(station)
        if cfs then teleportCF(cfs) task.wait(0.25
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

   
    -- Garante que está no World 5 e
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    local tried = false
    local station = getByPath('workspace.Worlds["5"].Systems.RaidStation')
    if station then
        local cfs = partCFrameOf(station)
        if cfs then teleportCF(
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    local tried =
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorld
    -- Garante que está no World 5 e perto da praça do portal
    -- Garante que está no World 5 e per
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    local tried = false
    local station = get
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

    local spawnGate = get
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    local tried = false
    local station = getByPath('workspace.Worlds["5"].Systems.RaidStation
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
   
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    local tried = false
   
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(
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
        if tried then return true
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait
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
        if inst:IsA("BasePart")
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    local tried = false
    local station = getByPath('workspace.Worlds["5"].Systems.RaidStation')
    if station then
        local cfs = partCFrameOf(station)
        if cfs then teleportCF(cfs) task.wait(0.25) end
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    local tried = false
    local station = getByPath('workspace.Worlds["5"].Systems.RaidStation')
    if station
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos
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

    local spawnGate = getByPath('workspace.World
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou Spawn
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    local tried = false
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
        local cfg = partCFrameOf(spawn
    -- Garante que está no World 5 e per
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
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
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.World
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.World
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    local tried = false
    local station = getByPath('workspace.World
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    --
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    local tried = false
    local station = getByPath('workspace.Worlds["5"].Systems.RaidStation')
    if station then
        local cfs = partCFrameOf(station)
        if cfs then teleportCF(cfs) task.wait(0.25
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    local tried = false
    local station = getByPath('workspace.Worlds["5"].Systems.RaidStation')
    if station then
        local cfs = partCFrameOf(station)
        if cfs then teleportCF(cfs) task.wait(0.25) end
        tried = try
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    local tried = false
    local station = getByPath('workspace.Worlds["5"].Systems.RaidStation')
    if station then
        local cfs = partCFrameOf(station)
        if c
    -- Garante que está
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems
    -- Garante que está no World 5 e perto
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

    local spawnGate = getByPath('workspace.Worlds["5"].
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    local tried = false
    local station = getByPath('workspace.Worlds["5"].Systems.RaidStation')
    if station then
        local cfs = partCFrameOf(station)
        if cfs then teleportCF(cfs) task.wait(
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    -- Garante que
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    local tried = false
    local station = getByPath('workspace.Worlds["5"].Systems.RaidStation')
    if station then
        local cfs = partCFrameOf(st
    -- Garante que está no World 5 e perto da praça do portal

    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    local tried = false
    local station = getByPath('workspace.World
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(
    -- Garante que está no World 5 e perto da praça do portal
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
        if cfg then teleportCF(cfg
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

   
    -- Garante que está no World 5 e perto da praça do portal

    -- Garante que está no World 5 e perto da praça
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    local tried = false
    local station = getByPath('workspace.Worlds["5"].Systems.RaidStation')
    if station then
        local cfs = partCFrameOf(station)
        if cfs then teleportCF(cfs
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
        local cfg = partCFrameOf(spawn
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    local tried = false
    local station = getByPath('workspace.Worlds["5"].Systems.RaidStation')
   
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
    if spawn
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos can
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)

    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    local tried = false
    local station = getByPath('workspace.Worlds["5"].Systems.RaidStation')
    if station then
        local cfs = partCFrameOf(station)
        if cfs then teleportCF(cfs) task.wait(0.25) end
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    local tried = false
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    local tried = false
    local station = getByPath('workspace.Worlds["5"].Systems.RaidStation')
    if station
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorld
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos can
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

   
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    local tried = false
    local station = getByPath('workspace.Worlds["5"].Systems.RaidStation')
    if station then
        local cfs = partCFrameOf(station)
        if cfs then teleportCF
    -- Garante que está no World 
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

    local spawnGate = getByPath
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorld
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    local tried = false
    local station = getByPath('workspace.Worlds["
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    local tried = false
    local station = getBy
    -- Garante que está no World 5 e perto da
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

   
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    local tried = false
    local station = getByPath('workspace.Worlds["5"].Systems.RaidStation')
    if station then
        local cfs = partCFrameOf(station)
        if cfs then teleportCF(cfs) task.wait(
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    
    -- Tenta objetos canônicos: workspace.Worlds
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    local tried = false
    local station = getByPath('workspace.Worlds["5"].Systems.RaidStation')
    if station then
        local cfs = partCFrameOf(station)
        if cfs then teleportCF(cfs) task.wait(0.25) end
        tried = tryInteract(st
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    local tried = false
    local station = getByPath('workspace.Worlds["5"].Systems.RaidStation')
    if station then
        local cfs = part
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0
    -- Garante que
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace
    -- Garante que está no
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.World
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
        local cb = part
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou Spawn
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    local tried = false
    local station = getByPath('workspace.Worlds["
    -- Garante que está no World 5 e perto da
    -- Garante que está no World 5 e perto da praça do portal
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    local tried = false
    local station = getByPath('workspace.Worlds["5"].Systems
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos:
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
       
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    local tried = false
    local station = getByPath('workspace.Worlds["5"].Systems.RaidStation')
    if station then
        local cfs = partCFrameOf(station)
        if cfs then teleportCF(
    --
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    local tried = false
    local station = getByPath
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(
    -- Garante que está no World 5 e
    -- Garante que está
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorld
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.Raid
    -- Garante que está no World 5 e perto da praça do portal
    goto
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

    local spawnGate = getByPath('workspace.Worlds["5"].Spawn
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    local tried = false
    local station = get
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
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

    -- Varredura genérica perto: procura por modelos/parts com nomes relacionados a portal/g
    -- Garante que está no World 5 e perto da praça
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    local tried 
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(
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

    local spawnGate = getByPath('workspace.World
    -- Garante que está no World 5 e perto da praça do portal
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
        if cfg then teleportCF(cfg) task.wait(0.2
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

    local spawnGate = getByPath('workspace.Worlds["
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

   
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems
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
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
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

    local spawnGate = getByPath('
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    local tried = false
    local station = getByPath('workspace.Worlds["5"].Systems.RaidStation')
    if station then
        local cfs = partCFrameOf(station)
        if cfs then teleport
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    local tried = false
    local station = getByPath('workspace.Worlds["5"].Systems.RaidStation')
    if station then
        local cfs = partCFrameOf(station)
        if cfs then teleportCF(cfs) task.wait(0.25) end

    -- Garante que está no World 5 e perto da praça
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    local tried = false
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    local tried = false
    local station = getByPath('workspace.World
    -- Garante que está
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(
    -- Garante que está no World 5 e perto da praça
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.
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
        if cfg then teleportCF(cfg) task.wait(0.2)
    -- Garante
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    --
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
       
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    local tried = false
    local station = getByPath('workspace.Worlds["5"].Systems.RaidStation')
    if station then
        local cfs = partCFrameOf(station)
       
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
   
    -- Garante que está no World 5 e per
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    local tried = false
    local station = getByPath('workspace.Worlds["5"].Systems.RaidStation')
    if station then
        local cfs = partCFrame
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(
    -- Garante que está no World 5 e per
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    local tried = false
    local station = getByPath('workspace.Worlds["5"].Systems.R
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- T
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    local tried = false
    local station = getByPath('workspace.Worlds["5"].Systems.RaidStation')
    if station then
        local cfs = partCFrameOf(station)
        if c
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    local tried = false
    local station = getByPath('works
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    local tried = false
    local station = getByPath('workspace.Worlds["5"].Systems.RaidStation')
   
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
   
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    local tried = false
    local station = getByPath('workspace.Worlds["5"].Systems.RaidStation')
    if station then
        local
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    local tried = false
   
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos can
    -- Garante que está no World 5 e perto da praça
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
    for _, inst in ipairs
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    local tried = false
    local station = getByPath('workspace.Worlds["5"].Systems.RaidStation')
    if station then
        local cfs = partCFrameOf(station)
        if cfs then teleportCF(cfs
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.
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
        if tried then return
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorld
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    local tried = false
    local station =
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
        tried = tryInteract(spawn
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    local tried = false
    local station = getByPath('workspace.Worlds["5"].Systems.RaidStation')
    if station then
        local cfs = partCFrameOf(station)
        if cfs then teleportCF(cfs) task.wait(0.25)
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    local tried = false
    local station = getByPath('workspace.Worlds["5"].Systems.RaidStation
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
        if inst:IsA("BasePart") or inst:IsA("Model")
    -- Garante que está no World 5 e per
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.World
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    local tried = false
    local station = getByPath('workspace.Worlds["5"].Systems.RaidStation')
    if station
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

    -- Garante que está no World 5 e
    -- Garante que está no World 5 e perto da
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
   
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    local tried = false
    local station = getByPath('workspace.World
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

    local spawnGate
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou Sp
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    local tried = false
    local station = getByPath('workspace.Worlds["5"].Systems.RaidStation')
    if station then
        local cfs = partCFrameOf(station)
        if cfs then teleportCF(cfs) task
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    local tried = false
    local station = getByPath('workspace.Worlds["5"].Systems.RaidStation')
    if station then
    -- Garante que está no World 5 e perto
    -- Garante que está no World 
    -- Garante que está no World 5 e perto da praça
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorld
    -- Garante que está no World 5 e perto da praça do portal
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0
    -- Garante
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    local tried = false
    local
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.World
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    
    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    local tried = false
    local station = getByPath('workspace.Worlds["5"].Systems.RaidStation')
    if station then
        local cfs = partCFrameOf(station)
        if c
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorld
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorld
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn
    -- Garante que está no World 5 e perto da praça do
    -- Garante que está
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
    if spawnGate
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    local tried = false
    local station = getByPath('workspace.Worlds["5"].Systems.RaidStation')
    if station then
        local cfs = partCFrame
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

    local spawnGate = get
    -- Garante
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn
    -- Garante que está no World 5 e perto da praça do portal
    gotoWorldSpawn(5)
    task.wait(0.35)

    -- Tenta objetos canônicos: workspace.Worlds["5"].Systems.RaidStation ou SpawnGate
    local tried = false
    local station = getByPath('workspace.Worlds["5"].Systems.RaidStation')
    ######
