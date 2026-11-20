local ESP = {}

function ESP.init(ctx)
    local function getTagFolder()
        if not ctx.tagFolder or ctx.tagFolder.Parent ~= ctx.gui then
            ctx.tagFolder = Instance.new("Folder")
            ctx.tagFolder.Name = "Tags"
            ctx.tagFolder.Parent = ctx.gui
        end
        return ctx.tagFolder
    end

    local function getColor(player)
        if ctx.cfg.TeamColorEnabled then
            if player.Team then
                return player.Team.TeamColor.Color
            end
            return Color3.new(1, 1, 1)
        end
        return ctx.colors[ctx.cfg.CustomColorIndex]
    end

    function ctx.destroyData(data)
        if data.gui then
            data.gui:Destroy()
        end
        if data.highlight then
            data.highlight:Destroy()
        end
    end

    local function createTag()
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "DivizaTag"
        billboard.Size = UDim2.fromOffset(230, 50)
        billboard.StudsOffset = Vector3.new(0, 2.6, 0)
        billboard.AlwaysOnTop = true
        billboard.ResetOnSpawn = false
        billboard.Enabled = false
        billboard.Parent = getTagFolder()

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "Name"
        nameLabel.BackgroundTransparency = 1
        nameLabel.Size = UDim2.new(1, 0, 0, 24)
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextStrokeTransparency = 0.3
        nameLabel.Parent = billboard

        local info = Instance.new("TextLabel")
        info.Name = "Info"
        info.BackgroundTransparency = 1
        info.Position = UDim2.fromOffset(0, 24)
        info.Size = UDim2.new(1, 0, 0, 20)
        info.Font = Enum.Font.Gotham
        info.TextColor3 = Color3.new(1, 1, 1)
        info.TextStrokeTransparency = 0.3
        info.Parent = billboard

        local back = Instance.new("Frame")
        back.Name = "HealthBackground"
        back.Position = UDim2.new(1, -6, 0, 4)
        back.Size = UDim2.fromOffset(4, 40)
        back.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
        back.BorderSizePixel = 0
        back.Parent = billboard

        local fill = Instance.new("Frame")
        fill.Name = "HealthFill"
        fill.AnchorPoint = Vector2.new(0, 1)
        fill.Position = UDim2.new(0, 0, 1, 0)
        fill.Size = UDim2.new(1, 0, 1, 0)
        fill.BorderSizePixel = 0
        fill.Parent = back

        return {
            gui = billboard,
            name = nameLabel,
            info = info,
            back = back,
            fill = fill,
            highlight = nil,
            cDist = 0,
            cNpc = false,
        }
    end

    local function createHighlight(character)
        local highlight = Instance.new("Highlight")
        highlight.Name = "DivizaHighlight"
        highlight.Adornee = character
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Enabled = false
        highlight.Parent = character
        return highlight
    end

    -- Garante que etiqueta e contorno existam e pertençam ao personagem atual.
    -- Se o jogo apagar qualquer um deles, são recriados no próximo ciclo.
    local function ensureData(key, character)
        local folder = getTagFolder()
        local data = ctx.esp[key]

        if not data or not data.gui or data.gui.Parent ~= folder then
            if data then
                ctx.destroyData(data)
            end
            data = createTag()
            ctx.esp[key] = data
        end

        if not data.highlight or data.highlight.Parent ~= character then
            if data.highlight then
                data.highlight:Destroy()
            end
            data.highlight = createHighlight(character)
            data.cColor = nil
            data.cFill = nil
            data.cOutline = nil
        end

        return data
    end

    local function hideData(data)
        if data then
            if data.gui and data.gui.Enabled then
                data.gui.Enabled = false
            end
            if data.highlight and data.highlight.Enabled then
                data.highlight.Enabled = false
            end
        end
    end

    local function getRoot(character, humanoid)
        return character:FindFirstChild("HumanoidRootPart")
            or humanoid.RootPart
            or character:FindFirstChild("UpperTorso")
            or character:FindFirstChild("Torso")
            or character.PrimaryPart
    end

    -- Atualiza etiqueta e contorno de um alvo (jogador ou NPC). Só escreve
    -- propriedades que mudaram.
    local function applyTarget(key, character, humanoid, head, distance, label, color,
                               tagVisible, wantHighlight, o, isNPC)
        if not tagVisible and not wantHighlight then
            hideData(ctx.esp[key])
            return
        end

        local data = ensureData(key, character)

        if data.gui.Adornee ~= head then
            data.gui.Adornee = head
        end
        if data.gui.Enabled ~= tagVisible then
            data.gui.Enabled = tagVisible
        end

        local highlight = data.highlight
        if data.cColor ~= color then
            data.cColor = color
            highlight.FillColor = color
            highlight.OutlineColor = color
        end
        if data.cFill ~= ctx.cfg.HighlightFillTransparency then
            data.cFill = ctx.cfg.HighlightFillTransparency
            highlight.FillTransparency = data.cFill
        end
        if data.cOutline ~= ctx.cfg.HighlightOutlineTransparency then
            data.cOutline = ctx.cfg.HighlightOutlineTransparency
            highlight.OutlineTransparency = data.cOutline
        end

        if wantHighlight then
            data.cDist = distance
            data.cNpc = isNPC
            ctx.candidates[#ctx.candidates + 1] = data
        elseif highlight.Enabled then
            highlight.Enabled = false
        end

        if not tagVisible then
            return
        end

        local transparency = o.transparency

        if data.name.Visible ~= o.showName then
            data.name.Visible = o.showName
        end
        if data.nameText ~= label then
            data.nameText = label
            data.name.Text = label
        end
        if data.nameColor ~= color then
            data.nameColor = color
            data.name.TextColor3 = color
        end
        if data.textSize ~= o.textSize then
            data.textSize = o.textSize
            data.name.TextSize = o.textSize
            data.info.TextSize = math.max(10, o.textSize - 2)
        end
        if data.transparency ~= transparency then
            data.transparency = transparency
            data.name.TextTransparency = transparency
            data.info.TextTransparency = transparency
            data.back.BackgroundTransparency = transparency
            data.fill.BackgroundTransparency = transparency
        end

        local infoText = ""
        if o.showDistance then
            infoText = tostring(math.floor(distance)) .. " studs"
        end
        if o.showHealth then
            local hp = ctx.fmtNum(humanoid.Health) .. "/" .. ctx.fmtNum(humanoid.MaxHealth) .. " HP"
            infoText = infoText == "" and hp or (infoText .. " | " .. hp)
        end

        if key:IsA("Player") then
            local tool = ctx.cfg.ShowTool and character:FindFirstChildOfClass("Tool")
            local team = ctx.cfg.ShowTeam and key.Team
            if tool then infoText = infoText .. "  " .. tool.Name end
            if team then infoText = infoText .. "  " .. team.Name end
        end
        local infoVisible = infoText ~= ""
        if data.info.Visible ~= infoVisible then
            data.info.Visible = infoVisible
        end
        if data.infoText ~= infoText then
            data.infoText = infoText
            data.info.Text = infoText
        end

        if data.back.Visible ~= o.showBar then
            data.back.Visible = o.showBar
        end
        if o.showBar then
            local maxHealth = humanoid.MaxHealth
            local ratio = 1
            if maxHealth > 0 and maxHealth < math.huge then
                ratio = math.clamp(humanoid.Health / maxHealth, 0, 1)
            end
            if ratio ~= ratio then
                ratio = 1
            end
            if data.ratio == nil or math.abs(data.ratio - ratio) > 0.004 then
                data.ratio = ratio
                data.fill.Size = UDim2.new(1, 0, ratio, 0)
                data.fill.BackgroundColor3 =
                    Color3.fromRGB(255, 60, 60):Lerp(Color3.fromRGB(80, 230, 120), ratio)
            end
        end
    end

    local function processPlayer(player, origin, o)
        local character = player.Character
        if not character then
            hideData(ctx.esp[player])
            return
        end

        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local root = humanoid and getRoot(character, humanoid)

        -- Personagem carregando, fora do streaming ou morto: esconde e tenta de
        -- novo no próximo ciclo (por isso o ESP volta sozinho).
        if not (humanoid and root and root:IsA("BasePart")) or humanoid.Health <= 0 then
            hideData(ctx.esp[player])
            return
        end

        local head = character:FindFirstChild("Head")
        if not (head and head:IsA("BasePart")) then
            head = root
        end

        local distance = (origin - root.Position).Magnitude
        local sameTeam = ctx.me.Team ~= nil and player.Team == ctx.me.Team
        local inRange = distance <= ctx.cfg.MaxDistance and not (ctx.cfg.HideTeammates and sameTeam)

        applyTarget(
            player, character, humanoid, head, distance,
            ctx.playerLabel(player), getColor(player),
            ctx.cfg.ESPEnabled and inRange, ctx.cfg.HighlightEnabled and inRange, o, false
        )
    end

    -- NPCs --------------------------------------------------------------

    function ctx.dropNPC(model)
        local data = ctx.esp[model]
        if data then
            ctx.destroyData(data)
            ctx.esp[model] = nil
        end
        ctx.npcs[model] = nil
    end

    local function registerNPC(humanoid)
        local model = humanoid.Parent
        if not model or not model:IsA("Model") or ctx.npcs[model] then
            return
        end
        -- "born"/"checked": só mostramos depois de ~0.6s, quando já dá para ter
        -- certeza de que o modelo não é o personagem de um jogador.
        ctx.npcs[model] = { humanoid = humanoid, born = os.clock(), checked = false }
    end

    function ctx.scanNPCs(isCurrent)
        local count = 0
        for _, instance in ipairs(workspace:GetDescendants()) do
            if not isCurrent() then
                return
            end
            if instance:IsA("Humanoid") then
                registerNPC(instance)
            end
            count += 1
            if count % 3000 == 0 then
                task.wait()
            end
        end
    end

    local function nameMatches(model, humanoid)
        if #ctx.npcTokens == 0 then
            return true
        end
        local haystack = string.lower(model.Name .. " " .. humanoid.DisplayName)
        for _, token in ipairs(ctx.npcTokens) do
            if string.find(haystack, token, 1, true) then
                return true
            end
        end
        return false
    end

    local function byDistance(a, b)
        return a.distance < b.distance
    end

    local function processNPCs(origin, o, now)
        if not ctx.cfg.NPCEnabled then
            if ctx.npcVisible then
                ctx.npcVisible = false
                for model in pairs(ctx.npcs) do
                    hideData(ctx.esp[model])
                end
            end
            return 0
        end
        ctx.npcVisible = true

        table.clear(ctx.npcList)
        local used = 0

        for model, info in pairs(ctx.npcs) do
            local humanoid = info.humanoid
            if model.Parent == nil or humanoid.Parent ~= model or model == ctx.me.Character then
                ctx.dropNPC(model)
            elseif not info.checked then
                if now - info.born >= 0.6 then
                    if ctx.Players:GetPlayerFromCharacter(model) then
                        ctx.dropNPC(model)
                    else
                        info.checked = true
                    end
                end
            else
                local keep = false
                if humanoid.Health > 0 and nameMatches(model, humanoid) then
                    local root = info.root
                    if not root or root.Parent == nil then
                        root = getRoot(model, humanoid)
                        info.root = root
                    end
                    if root and root:IsA("BasePart") then
                        local distance = (origin - root.Position).Magnitude
                        if distance <= ctx.cfg.NPCMaxDistance then
                            keep = true
                            used += 1
                            local entry = ctx.npcPool[used]
                            if not entry then
                                entry = {}
                                ctx.npcPool[used] = entry
                            end
                            entry.model = model
                            entry.humanoid = humanoid
                            entry.root = root
                            entry.distance = distance
                            ctx.npcList[#ctx.npcList + 1] = entry
                        end
                    end
                end
                if not keep then
                    hideData(ctx.esp[model])
                end
            end
        end

        if #ctx.npcList > ctx.cfg.NPCMaxCount then
            table.sort(ctx.npcList, byDistance)
        end

        local shown = 0
        local color = ctx.colors[ctx.cfg.NPCColorIndex]
        local limit = ctx.cfg.NPCMaxCount

        for index = 1, #ctx.npcList do
            local item = ctx.npcList[index]
            if index <= limit then
                local model = item.model
                local head = model:FindFirstChild("Head")
                if not (head and head:IsA("BasePart")) then
                    head = item.root
                end
                local humanoid = item.humanoid
                local label = humanoid.DisplayName ~= "" and humanoid.DisplayName or model.Name
                applyTarget(
                    model, model, humanoid, head, item.distance, label, color,
                    true, ctx.cfg.NPCHighlight, o, true
                )
                shown += 1
            else
                hideData(ctx.esp[item.model])
            end
        end

        return shown
    end

    -- Origem da distância: o seu personagem, ou a câmera se você estiver morto
    -- ou espectando outra pessoa.
    local function getOrigin()
        if not ctx.selectedPlayer then
            local character = ctx.me.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            if root then
                return root.Position
            end
        end

        local cam = workspace.CurrentCamera
        return cam and cam.CFrame.Position or Vector3.zero
    end

    -- Jogadores têm prioridade sobre NPCs na hora de distribuir os contornos.
    local function byHighlightPriority(a, b)
        local ka = a.cDist + (a.cNpc and 10000000 or 0)
        local kb = b.cDist + (b.cNpc and 10000000 or 0)
        return ka < kb
    end

    function ctx.refreshAll()
        local origin = getOrigin()
        table.clear(ctx.candidates)

        local transparency = ctx.cfg.TransparencyEnabled and ctx.cfg.Transparency or 0

        ctx.playerOpts.showName = ctx.cfg.ShowName
        ctx.playerOpts.showDistance = ctx.cfg.ShowDistance
        ctx.playerOpts.showHealth = ctx.cfg.ShowHealth
        ctx.playerOpts.showBar = ctx.cfg.ShowHealthBar
        ctx.playerOpts.textSize = ctx.cfg.TextSize
        ctx.playerOpts.transparency = transparency

        ctx.npcOpts.showName = ctx.cfg.NPCShowName
        ctx.npcOpts.showDistance = ctx.cfg.NPCShowDistance
        ctx.npcOpts.showHealth = ctx.cfg.NPCShowHealth
        ctx.npcOpts.showBar = ctx.cfg.NPCShowHealthBar
        ctx.npcOpts.textSize = ctx.cfg.TextSize
        ctx.npcOpts.transparency = transparency

        local playerCount = 0

        if ctx.cfg.ESPEnabled or ctx.cfg.HighlightEnabled then
            ctx.playersVisible = true
            for _, player in ipairs(ctx.Players:GetPlayers()) do
                if player ~= ctx.me then
                    local ok, err = pcall(processPlayer, player, origin, ctx.playerOpts)
                    if not ok then
                        ctx.softWarn("falha ao atualizar " .. player.Name, err)
                    end

                    local data = ctx.esp[player]
                    if data and data.gui and data.gui.Enabled then
                        playerCount += 1
                    end
                end
            end
        elseif ctx.playersVisible then
            ctx.playersVisible = false
            for _, player in ipairs(ctx.Players:GetPlayers()) do
                hideData(ctx.esp[player])
            end
        end

        local npcCount = 0
        local ok, result = pcall(processNPCs, origin, ctx.npcOpts, os.clock())
        if ok then
            npcCount = result
        else
            ctx.softWarn("NPCs", result)
        end

        -- Só os mais próximos recebem contorno (limite de Highlights do Roblox).
        local total = #ctx.candidates
        if total > 1 then
            table.sort(ctx.candidates, byHighlightPriority)
        end
        local limit = ctx.cfg.MaxHighlights
        for index = 1, total do
            local highlight = ctx.candidates[index].highlight
            local want = index <= limit
            if highlight and highlight.Enabled ~= want then
                highlight.Enabled = want
            end
        end

        ctx.stats.players = playerCount
        ctx.stats.npcs = npcCount
        ctx.stats.outlined = math.min(total, limit)
    end

    function ctx.rebuildAll()
        for key, data in pairs(ctx.esp) do
            ctx.destroyData(data)
            ctx.esp[key] = nil
        end
        ctx.refreshAll()
    end

    local npcConnAdded, npcConnRemoved
    local npcScanGeneration = 0

    function ctx.setNPCTracking(on)
        if on then
            if npcConnAdded then
                return
            end
            npcConnAdded = workspace.DescendantAdded:Connect(function(instance)
                if instance:IsA("Humanoid") then
                    registerNPC(instance)
                end
            end)
            npcConnRemoved = workspace.DescendantRemoving:Connect(function(instance)
                if instance:IsA("Humanoid") then
                    local model = instance.Parent
                    if model and ctx.npcs[model] and ctx.npcs[model].humanoid == instance then
                        ctx.dropNPC(model)
                    end
                end
            end)
            npcScanGeneration += 1
            local generation = npcScanGeneration
            task.spawn(ctx.scanNPCs, function()
                return ctx.running and generation == npcScanGeneration
            end)
        else
            npcScanGeneration += 1
            if npcConnAdded then
                npcConnAdded:Disconnect()
                npcConnAdded = nil
            end
            if npcConnRemoved then
                npcConnRemoved:Disconnect()
                npcConnRemoved = nil
            end
            for model in pairs(ctx.npcs) do
                ctx.dropNPC(model)
            end
            table.clear(ctx.npcList)
            table.clear(ctx.npcPool)
        end
    end
end

return ESP
