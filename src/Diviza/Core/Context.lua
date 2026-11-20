local Context = {}

function Context.init(ctx)
    ctx.Players = game:GetService("Players")
    ctx.UIS = game:GetService("UserInputService")
    ctx.RunService = game:GetService("RunService")
    ctx.Lighting = game:GetService("Lighting")
    ctx.TweenService = game:GetService("TweenService")

    ctx.me = ctx.Players.LocalPlayer
    ctx.playerGui = ctx.me:WaitForChild("PlayerGui")

    ctx.BIND_CAM_EARLY = "DivizaMethodCamEarly"
    ctx.BIND_CAM_LATE = "DivizaMethodCamLate"
    ctx.BIND_WORLD = "DivizaMethodWorld"

    ctx.PANEL_W, ctx.PANEL_H = 944, 576
    ctx.SIDEBAR_W = 166
    ctx.TOPBAR_H = 74
    ctx.FOOTER_H = 34

    ctx.defaults = {
        AimEnabled = true,
        SilentAim = false,
        HitChance = 100,
        ShowTool = false,
        ShowTeam = false,
        AimSnap = true,
        AimRadius = 90,
        AimToggle = false,
        AimRange = 250,
        AimSpeed = 20,
        AimAtHead = true,
        AimIgnoreTeammates = false,

        -- jogadores
        ESPEnabled = true,
        ShowName = true,
        ShowUsername = true,
        ShowDistance = true,
        ShowHealth = true,
        ShowHealthBar = true,
        TeamColorEnabled = true,
        HideTeammates = false,
        CustomColorIndex = 1,
        TextSize = 14,
        MaxDistance = 5000,

        -- NPCs / mobs
        NPCEnabled = false,
        NPCShowName = true,
        NPCShowDistance = true,
        NPCShowHealth = true,
        NPCShowHealthBar = true,
        NPCHighlight = false,
        NPCColorIndex = 5,
        NPCMaxDistance = 1500,
        NPCMaxCount = 30,

        -- mundo
        FullbrightEnabled = false,
        NoFogEnabled = false,
        NoFogStrength = 1,
        NoFogAtmosphere = true,

        TransparencyEnabled = false,
        Transparency = 0.3,

        -- contorno
        HighlightEnabled = false,
        HighlightFillTransparency = 0.7,
        HighlightOutlineTransparency = 0,
        MaxHighlights = 30,

        -- desempenho
        UpdateInterval = 0.1,
        AutoPerformance = true,

        -- interface
        SpectateHotkeys = true,
        GuiKey = "P",
    }

    ctx.cfg = table.clone(ctx.defaults)

    ctx.theme = {
        bg = Color3.fromRGB(18, 11, 20),
        sidebar = Color3.fromRGB(25, 15, 29),
        card = Color3.fromRGB(35, 21, 40),
        cardHover = Color3.fromRGB(53, 30, 54),
        line = Color3.fromRGB(69, 43, 69),
        accent = Color3.fromRGB(201, 95, 176),
        accentHi = Color3.fromRGB(255, 170, 208),
        text = Color3.fromRGB(234, 246, 239),
        sub = Color3.fromRGB(194, 165, 188),
        off = Color3.fromRGB(76, 53, 77),
    }

    ctx.styles = {
        normal = ctx.theme.card,
        primary = ctx.theme.accent,
        active = Color3.fromRGB(100, 46, 111),
        danger = Color3.fromRGB(97, 49, 55),
    }

    ctx.colors = {
        Color3.fromRGB(180, 120, 255),
        Color3.fromRGB(255, 90, 110),
        Color3.fromRGB(90, 210, 150),
        Color3.fromRGB(90, 170, 255),
        Color3.fromRGB(255, 210, 90),
        Color3.fromRGB(255, 255, 255),
    }

    ctx.keyChoices = { "P", "RightShift", "Insert", "RightControl", "K" }

    ctx.pages = {
        { id = "Mira", title = "Controle de mira", sub = "Trava de alvo no Gun Game" },
        { id = "ESP", title = "ESP de jogadores", sub = "Etiquetas com nome, distância e vida" },
        { id = "NPCs", title = "NPCs e mobs", sub = "ESP para qualquer modelo com Humanoid" },
        { id = "Times", title = "Times e contorno", sub = "Cores, aliados e Highlight" },
        { id = "Mundo", title = "Mundo", sub = "Iluminação e transparência" },
        { id = "Spectate", title = "Spectate", sub = "Acompanhe outro jogador" },
        { id = "Config", title = "Configurações", sub = "Interface, atalhos e desempenho" },
    }

    ------------------------------------------------------------------------
    -- ESTADO
    ------------------------------------------------------------------------

    ctx.esp = {} -- [Player | Model] = dados da etiqueta/contorno
    ctx.npcs = {} -- [Model] = { humanoid, born, checked }
    ctx.conns = {}
    ctx.running = true
    ctx.currentTab = "Mira"
    ctx.minimized = false
    ctx.panelVisible = true
    ctx.selectedPlayer = nil
    ctx.spectateSearch = ""
    ctx.statusLabel = nil
    ctx.onSpectateListRefresh = nil
    ctx.activeDrag = nil
    ctx.tagFolder = nil
    ctx.npcTokens = {}
    ctx.stats = { players = 0, npcs = 0, outlined = 0 }
    local lastWarn = 0
    ctx.interval = ctx.cfg.UpdateInterval
    ctx.playersVisible = true
    ctx.npcVisible = true

    ctx.candidates = {}
    ctx.npcList = {}
    ctx.npcPool = {}
    ctx.playerOpts = {}
    ctx.npcOpts = {}
    ctx.aim = {
        binding = "DivizaMethodAimLock",
        nextScan = 0,
        bound = false,
        rayParams = RaycastParams.new(),

    }
    ctx.aim.rayParams.FilterType = Enum.RaycastFilterType.Exclude
    ctx.aim.rayParams.IgnoreWater = true

    ctx.cfg.CustomColorIndex = math.clamp(ctx.cfg.CustomColorIndex, 1, #ctx.colors)


    function ctx.track(connection)
        table.insert(ctx.conns, connection)
        return connection
    end

    function ctx.softWarn(context, err)
        if os.clock() - lastWarn > 5 then
            lastWarn = os.clock()
            warn("[DIVIZA METHOD] " .. context .. ": " .. tostring(err))
        end
    end

    -- Nome mostrado no ESP e no spectate: @usuário ou display name.
    function ctx.playerLabel(player)
        if ctx.cfg.ShowUsername then
            return "@" .. player.Name
        end
        return player.DisplayName
    end

    -- Formata números sem quebrar com inf/nan e abrevia valores grandes.
    function ctx.fmtNum(n)
        if n ~= n then
            return "?"
        end
        if math.abs(n) == math.huge then
            return "inf"
        end
        n = math.floor(n + 0.5)
        if n >= 1000000 then
            return string.format("%.1fM", n / 1000000)
        elseif n >= 10000 then
            return string.format("%.1fk", n / 1000)
        end
        return tostring(n)
    end

    function ctx.setNPCFilter(text)
        ctx.npcTokens = {}
        for token in string.gmatch(text, "[^,]+") do
            token = string.lower(string.match(token, "^%s*(.-)%s*$"))
            if token ~= "" then
                table.insert(ctx.npcTokens, token)
            end
        end
    end

    ctx.npcFilterText = ""
end

return Context
