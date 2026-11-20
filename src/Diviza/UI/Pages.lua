local Pages = {}

function Pages.init(ctx)
    local function renderAim(builder)
        local nextOrder = builder.nextOrder
        local addSection = builder.addSection
        local addNote = builder.addNote
        local addToggle = builder.addToggle
        local addSlider = builder.addSlider

        local columns = Instance.new("Frame")
        columns.Size = UDim2.new(1, 0, 0, 344)
        columns.BackgroundTransparency = 1
        columns.LayoutOrder = nextOrder()
        columns.Parent = ctx.content

        local function column(position, offset)
            local frame = Instance.new("Frame")
            frame.Position = UDim2.new(position, offset, 0, 0)
            frame.Size = UDim2.new(0.5, -6, 1, 0)
            frame.BackgroundTransparency = 1
            frame.Parent = columns
            ctx.newList(frame, 8, false)
            return frame
        end

        local targeting = column(0, 0)
        local tracking = column(0.5, 6)
        addSection("ALVO", targeting)
        addToggle("Mira ativa", "AimEnabled", nil, targeting)
        addToggle("Mirar na cabeça", "AimAtHead", nil, targeting)
        addToggle("Ignorar aliados", "AimIgnoreTeammates", nil, targeting)
        addSlider("Raio do cursor", "AimRadius", 20, 300, 5, function(v) return v .. " px" end, nil, targeting)
        addSection("CONTROLE", tracking)
        addToggle("Alternar com um clique", "AimToggle", nil, tracking)
        addToggle("Trava instantânea", "AimSnap", nil, tracking)
        addSlider("Velocidade suave", "AimSpeed", 5, 45, 1, tostring, nil, tracking)
        addSlider("Alcance", "AimRange", 50, 1000, 25, function(v) return v .. " studs" end, nil, tracking)
        addToggle("Mira no disparo", "SilentAim", nil, targeting)
        addSlider("Chance por disparo", "HitChance", 0, 100, 1, function(v) return v .. "%" end, nil, tracking)
        local controls = addNote(ctx.cfg.GuiKey .. " fecha o painel. Use o botão direito para mirar.")
        controls.TextColor3 = ctx.theme.accentHi
    end

    local function percent(value)
        return math.floor(value * 100 + 0.5) .. "%"
    end

    local function renderTab()
        ctx.clearContent()
        local builder = ctx.Components.newBuilder(ctx)
        local nextOrder = builder.nextOrder
        local addSection = builder.addSection
        local addNote = builder.addNote
        local addButton = builder.addButton
        local addToggle = builder.addToggle
        local addSlider = builder.addSlider
        local addSwatches = builder.addSwatches
        local addTextInput = builder.addTextInput


        if ctx.currentTab == "Mira" then
            renderAim(builder)

        elseif ctx.currentTab == "ESP" then
            addSection("EXIBIÇÃO")
            addToggle("ESP geral", "ESPEnabled")
            addToggle("Equipe", "ShowTeam")
            addToggle("Item equipado", "ShowTool")
            addToggle("Nome do jogador", "ShowName")
            addToggle("Usar @usuário", "ShowUsername")
            addToggle("Distância em studs", "ShowDistance")
            addToggle("HP numérico", "ShowHealth")
            addToggle("Barra vertical de HP", "ShowHealthBar")

            addSection("AJUSTES")
            addSlider("Tamanho do texto", "TextSize", 10, 22, 1, function(v)
                return math.floor(v + 0.5) .. " px"
            end)
            addSlider("Distância máxima", "MaxDistance", 100, 30000, 100, function(v)
                return math.floor(v + 0.5) .. " studs"
            end)

            addSection("MANUTENÇÃO")
            addButton(ctx.content, "Recriar etiquetas", ctx.rebuildAll, "primary")

        elseif ctx.currentTab == "NPCs" then
            addSection("ESP DE NPCS E MOBS")
            addToggle("ESP de NPCs/mobs", "NPCEnabled", function(on)
                ctx.setNPCTracking(on)
            end)
            addToggle("Nome", "NPCShowName")
            addToggle("Distância em studs", "NPCShowDistance")
            addToggle("HP numérico", "NPCShowHealth")
            addToggle("Barra vertical de HP", "NPCShowHealthBar")
            addToggle("Contorno (Highlight) nos NPCs", "NPCHighlight")

            addSection("FILTRO")
            addTextInput(
                "Mostrar só estes nomes (separe por vírgula)",
                "vazio = todos. Ex: zombie, boss",
                ctx.npcFilterText,
                function(text)
                    ctx.npcFilterText = text
                    ctx.setNPCFilter(text)
                end
            )

            addSection("LIMITES")
            addSlider("Distância máxima", "NPCMaxDistance", 50, 10000, 50, function(v)
                return math.floor(v + 0.5) .. " studs"
            end)
            addSlider("Máximo de NPCs na tela", "NPCMaxCount", 1, 100, 1, function(v)
                return tostring(math.floor(v + 0.5))
            end)

            addSection("COR")
            addSwatches("Cor dos NPCs", "NPCColorIndex")

            addSection("MANUTENÇÃO")
            addButton(ctx.content, "Reescanear NPCs do mapa", function()
                if ctx.cfg.NPCEnabled then
                    task.spawn(ctx.scanNPCs)
                    ctx.notify("Reescaneando NPCs...")
                else
                    ctx.notify("Ligue o ESP de NPCs/mobs primeiro")
                end
            end, "primary")

        elseif ctx.currentTab == "Times" then
            addSection("COR")
            addToggle("Cor automática do time", "TeamColorEnabled")
            addSwatches("Cor personalizada (quando a cor de time está desligada)", "CustomColorIndex")
            addToggle("Esconder aliados", "HideTeammates")

            addSection("CONTORNO (HIGHLIGHT)")
            addToggle("Contorno nos jogadores", "HighlightEnabled")
            addSlider("Transparência do preenchimento", "HighlightFillTransparency", 0, 1, 0.05, percent)
            addSlider("Transparência da borda", "HighlightOutlineTransparency", 0, 1, 0.05, percent)

        elseif ctx.currentTab == "Mundo" then
            addSection("ILUMINAÇÃO")
            addToggle("Fullbright (iluminação clara)", "FullbrightEnabled", ctx.applyWorld)
            addToggle("NoFog (remover neblina)", "NoFogEnabled", ctx.applyWorld)
            addSlider("Intensidade do NoFog", "NoFogStrength", 0, 1, 0.05, percent)
            addToggle("NoFog também remove o Atmosphere", "NoFogAtmosphere", ctx.applyWorld)

            addSection("TRANSPARÊNCIA DO ESP")
            addToggle("Transparência de texto/barra", "TransparencyEnabled")
            addSlider("Nível de transparência", "Transparency", 0, 0.9, 0.05, percent)

        elseif ctx.currentTab == "Spectate" then
            addSection("SPECTATE")

            local searchBox = Instance.new("TextBox")
            searchBox.Size = UDim2.new(1, 0, 0, 36)
            searchBox.BackgroundColor3 = ctx.theme.card
            searchBox.BorderSizePixel = 0
            searchBox.TextColor3 = ctx.theme.text
            searchBox.PlaceholderColor3 = ctx.theme.sub
            searchBox.PlaceholderText = "Buscar jogador..."
            searchBox.Text = ctx.spectateSearch
            searchBox.ClearTextOnFocus = false
            searchBox.TextXAlignment = Enum.TextXAlignment.Left
            searchBox.Font = Enum.Font.Gotham
            searchBox.TextSize = 13
            searchBox.LayoutOrder = nextOrder()
            searchBox.Parent = ctx.content
            ctx.corner(searchBox, 10)

            local searchPadding = Instance.new("UIPadding")
            searchPadding.PaddingLeft = UDim.new(0, 14)
            searchPadding.Parent = searchBox

            ctx.statusLabel = addNote(
                ctx.selectedPlayer and ("Espectando: " .. ctx.playerLabel(ctx.selectedPlayer))
                    or "Você está na sua própria câmera."
            )
            ctx.onSpectateStatus = function(text) ctx.statusLabel.Text = text end
            ctx.statusLabel.TextColor3 = ctx.theme.text

            addNote("Atalhos:  [  anterior   |   ]  próximo   |   \\  parar  (liga/desliga em Config)")

            local nav = Instance.new("Frame")
            nav.Size = UDim2.new(1, 0, 0, 36)
            nav.BackgroundTransparency = 1
            nav.LayoutOrder = nextOrder()
            nav.Parent = ctx.content
            ctx.newList(nav, 8, true)

            local previousButton = addButton(nav, "< Anterior", function()
                ctx.cycleSpectate(-1)
            end)
            previousButton.Size = UDim2.new(0.5, -4, 1, 0)

            local nextButton = addButton(nav, "Próximo >", function()
                ctx.cycleSpectate(1)
            end)
            nextButton.Size = UDim2.new(0.5, -4, 1, 0)

            addButton(ctx.content, "Parar de espectar / voltar para mim", function()
                ctx.stopSpectating()
                if ctx.onSpectateListRefresh then
                    ctx.onSpectateListRefresh()
                end
            end, "danger")

            local listFrame = Instance.new("Frame")
            listFrame.Size = UDim2.new(1, 0, 0, 0)
            listFrame.AutomaticSize = Enum.AutomaticSize.Y
            listFrame.BackgroundTransparency = 1
            listFrame.LayoutOrder = nextOrder()
            listFrame.Parent = ctx.content
            ctx.newList(listFrame, 6, false)

            local function refreshPlayerList()
                for _, child in ipairs(listFrame:GetChildren()) do
                    if child:IsA("GuiObject") then
                        child:Destroy()
                    end
                end

                local query = string.lower(ctx.spectateSearch)
                local found = 0

                for _, player in ipairs(ctx.getOtherPlayers()) do
                    local matches = query == ""
                        or string.find(string.lower(player.Name), query, 1, true)
                        or string.find(string.lower(player.DisplayName), query, 1, true)

                    if matches then
                        found += 1

                        local label = ctx.playerLabel(player)
                        local isSelected = player == ctx.selectedPlayer
                        addButton(
                            listFrame,
                            isSelected and ("[ESPECTANDO]  " .. label) or label,
                            function()
                                if ctx.selectedPlayer == player then
                                    ctx.stopSpectating()
                                else
                                    ctx.spectatePlayer(player)
                                end
                                refreshPlayerList()
                            end,
                            isSelected and "active" or "normal",
                            36
                        )
                    end
                end

                if found == 0 then
                    addNote("Nenhum jogador encontrado.", listFrame)
                end
            end

            ctx.onSpectateListRefresh = refreshPlayerList

            searchBox:GetPropertyChangedSignal("Text"):Connect(function()
                ctx.spectateSearch = searchBox.Text
                refreshPlayerList()
            end)

            refreshPlayerList()

        elseif ctx.currentTab == "Config" then
            addSection("INTERFACE")

            addButton(ctx.content, "Tecla da GUI: " .. ctx.cfg.GuiKey .. "   (clique para trocar)", function()
                local index = table.find(ctx.keyChoices, ctx.cfg.GuiKey) or 0
                ctx.cfg.GuiKey = ctx.keyChoices[index % #ctx.keyChoices + 1]
                ctx.updateStats()
                renderTab()
            end)

            addToggle("Atalhos do spectate ( [  ]  \\ )", "SpectateHotkeys")

            addButton(ctx.content, "Resetar posição da janela", function()
                ctx.panel.Position = ctx.PANEL_POS
            end)

            addSection("DESEMPENHO")
            addSlider("Intervalo de atualização do ESP", "UpdateInterval", 0.05, 0.5, 0.01, function(v)
                return string.format("%.2fs", v)
            end, function(v)
                ctx.interval = v
            end)
            addToggle("Intervalo adaptativo", "AutoPerformance")
            addSlider("Máximo de contornos", "MaxHighlights", 5, 30, 1, function(v)
                return tostring(math.floor(v + 0.5))
            end)

            addSection("SCRIPT")

            addButton(ctx.content, "Restaurar configurações padrão", function()
                for key, value in pairs(ctx.defaults) do
                    ctx.cfg[key] = value
                end
                ctx.npcFilterText = ""
                ctx.setNPCFilter("")
                ctx.interval = ctx.cfg.UpdateInterval
                ctx.aim.stop()
                ctx.setNPCTracking(ctx.cfg.NPCEnabled)
                ctx.applyWorld()
                ctx.updateStats()
                renderTab()
            end, "danger")

            addButton(ctx.content, "Descarregar o script", function()
                ctx.cleanup()
            end, "danger")

        end
    end

    local tabButtons = {}

    local function paintTab(entry, active, animate)
        local bgTransparency = active and 0 or 1
        local textColor = active and Color3.new(1, 1, 1) or ctx.theme.sub
        local barTransparency = active and 0 or 1
        if animate then
            ctx.tween(entry.button, { BackgroundTransparency = bgTransparency, TextColor3 = textColor }, 0.12)
            ctx.tween(entry.bar, { BackgroundTransparency = barTransparency }, 0.12)
        else
            entry.button.BackgroundTransparency = bgTransparency
            entry.button.TextColor3 = textColor
            entry.bar.BackgroundTransparency = barTransparency
        end
    end

    local function setTab(id)
        ctx.currentTab = id

        for _, page in ipairs(ctx.pages) do
            local entry = tabButtons[page.id]
            paintTab(entry, page.id == id, true)
            if page.id == id then
                ctx.pageTitle.Text = page.title
                ctx.pageSub.Text = page.sub
            end
        end

        ctx.content.CanvasPosition = Vector2.zero
        renderTab()
    end

    for index, page in ipairs(ctx.pages) do
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, 0, 0, 36)
        b.BackgroundColor3 = ctx.theme.accent
        b.BackgroundTransparency = 1
        b.BorderSizePixel = 0
        b.AutoButtonColor = false
        b.Text = ({ ESP = "Jogadores", Spectate = "Espectador", Config = "Configurações" })[page.id] or page.id
        b.Font = Enum.Font.GothamMedium
        b.TextSize = 13
        b.TextColor3 = ctx.theme.sub
        b.TextXAlignment = Enum.TextXAlignment.Left
        b.LayoutOrder = index
        b.Parent = ctx.tabHolder
        ctx.corner(b, 10)

        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0, 18)
        padding.Parent = b

        local bar = Instance.new("Frame")
        bar.Size = UDim2.fromOffset(3, 16)
        bar.Position = UDim2.new(0, -12, 0.5, -8)
        bar.BackgroundColor3 = ctx.theme.accentHi
        bar.BackgroundTransparency = 1
        bar.BorderSizePixel = 0
        bar.Parent = b
        ctx.corner(bar, 2)

        local entry = { button = b, bar = bar }
        tabButtons[page.id] = entry

        b.MouseEnter:Connect(function()
            if ctx.currentTab ~= page.id then
                ctx.tween(b, { TextColor3 = ctx.theme.text }, 0.1)
            end
        end)
        b.MouseLeave:Connect(function()
            if ctx.currentTab ~= page.id then
                ctx.tween(b, { TextColor3 = ctx.theme.sub }, 0.1)
            end
        end)
        b.Activated:Connect(function()
            setTab(page.id)
        end)
    end

    ------------------------------------------------------------------------
    ctx.gui.Parent = ctx.playerGui
    setTab("Mira")
end

return Pages
