local Spectate = {}

function Spectate.init(ctx)
    local function setStatus(text)
        if ctx.state.spectateStatus == text then return end
        ctx.state.spectateStatus = text
        if ctx.onSpectateStatus then ctx.onSpectateStatus(text) end
    end

    local spectateBound = false

    local function spectateStep()
        if ctx.running and ctx.selectedPlayer then
            local ok, err = pcall(ctx.applySpectateCamera)
            if not ok then
                ctx.softWarn("câmera do spectate", err)
            end
        end
    end

    local function bindSpectate()
        if spectateBound then
            return
        end
        spectateBound = true
        -- Antes e depois do script de câmera do jogo, para não piscar.
        ctx.RunService:BindToRenderStep(ctx.BIND_CAM_EARLY, Enum.RenderPriority.Camera.Value - 1, spectateStep)
        ctx.RunService:BindToRenderStep(ctx.BIND_CAM_LATE, Enum.RenderPriority.Camera.Value + 1, spectateStep)
    end

    function ctx.unbindSpectate()
        if not spectateBound then
            return
        end
        spectateBound = false
        pcall(ctx.RunService.UnbindFromRenderStep, ctx.RunService, ctx.BIND_CAM_EARLY)
        pcall(ctx.RunService.UnbindFromRenderStep, ctx.RunService, ctx.BIND_CAM_LATE)
    end

    function ctx.stopSpectating()
        ctx.selectedPlayer = nil
        ctx.unbindSpectate()

        local cam = workspace.CurrentCamera
        local character = ctx.me.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")

        if cam then
            cam.CameraType = Enum.CameraType.Custom
            if humanoid then
                cam.CameraSubject = humanoid
            end
        end

        setStatus("Você está na sua própria câmera.")
    end

    function ctx.applySpectateCamera()
        if not ctx.selectedPlayer then
            return
        end

        if ctx.selectedPlayer.Parent ~= ctx.Players then
            ctx.stopSpectating()
            return
        end

        local cam = workspace.CurrentCamera
        local character = ctx.selectedPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")

        if cam and humanoid then
            if cam.CameraType ~= Enum.CameraType.Custom then
                cam.CameraType = Enum.CameraType.Custom
            end
            if cam.CameraSubject ~= humanoid then
                cam.CameraSubject = humanoid
            end
            setStatus("Espectando: " .. ctx.playerLabel(ctx.selectedPlayer))
        else
            -- Sem Humanoid no seu cliente: jogador longe demais (streaming),
            -- morto/respawnando ou ainda carregando.
            setStatus("Aguardando o personagem de " .. ctx.playerLabel(ctx.selectedPlayer)
                .. " carregar (pode estar longe demais)...")
        end
    end

    function ctx.spectatePlayer(player)
        if not player or player == ctx.me then
            return
        end

        ctx.aim.stop()
        ctx.selectedPlayer = player
        setStatus("Espectando: " .. ctx.playerLabel(player))
        bindSpectate()
        ctx.applySpectateCamera()
    end

    function ctx.getOtherPlayers()
        local result = {}

        for _, player in ipairs(ctx.Players:GetPlayers()) do
            if player ~= ctx.me then
                table.insert(result, player)
            end
        end

        table.sort(result, function(a, b)
            return string.lower(ctx.playerLabel(a)) < string.lower(ctx.playerLabel(b))
        end)

        return result
    end

    function ctx.cycleSpectate(direction)
        local list = ctx.getOtherPlayers()

        if #list == 0 then
            ctx.stopSpectating()
            setStatus("Nenhum outro jogador na partida.")
            return
        end

        local index = table.find(list, ctx.selectedPlayer)
        if index then
            index = ((index - 1 + direction) % #list) + 1
        else
            index = direction > 0 and 1 or #list
        end

        ctx.spectatePlayer(list[index])
        if ctx.onSpectateListRefresh then
            ctx.onSpectateListRefresh()
        end
    end
end

return Spectate
