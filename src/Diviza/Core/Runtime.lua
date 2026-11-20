local Runtime = {}

function Runtime.init(ctx)
    ctx.track(ctx.Players.PlayerAdded:Connect(function()
        if ctx.onSpectateListRefresh then
            ctx.onSpectateListRefresh()
        end
    end))

    ctx.track(ctx.Players.PlayerRemoving:Connect(function(player)
        if player == ctx.aim.target then
            ctx.aim.clearTarget()
        end
        if player == ctx.selectedPlayer then
            ctx.stopSpectating()
        end

        local data = ctx.esp[player]
        if data then
            ctx.destroyData(data)
            ctx.esp[player] = nil
        end

        if ctx.onSpectateListRefresh then
            task.defer(ctx.onSpectateListRefresh)
        end
    end))

    ctx.track(ctx.UIS.InputBegan:Connect(function(input, processed)
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            if not processed then
                if ctx.cfg.AimToggle and ctx.aim.bound then
                    ctx.aim.stop()
                else
                    ctx.aim.start()
                end
            end
            return
        end
        if processed then
            return
        end

        local key = Enum.KeyCode[ctx.cfg.GuiKey]
        if key and input.KeyCode == key then
            ctx.setPanelVisible(not ctx.panelVisible)
            return
        end

        if ctx.cfg.SpectateHotkeys then
            if input.KeyCode == Enum.KeyCode.LeftBracket then
                ctx.cycleSpectate(-1)
            elseif input.KeyCode == Enum.KeyCode.RightBracket then
                ctx.cycleSpectate(1)
            elseif input.KeyCode == Enum.KeyCode.BackSlash then
                if ctx.selectedPlayer then
                    ctx.stopSpectating()
                    if ctx.onSpectateListRefresh then
                        ctx.onSpectateListRefresh()
                    end
                end
            end
        end
    end))

    ------------------------------------------------------------------------
    -- LOOP PRINCIPAL
    -- Um único Heartbeat: ESP a cada "interval" (com ajuste automático) e uma
    -- manutenção leve a cada 1s. Fullbright e spectate têm RenderStep próprio,
    -- ligado só enquanto são usados.
    ------------------------------------------------------------------------

    local function watchdog()
        if ctx.gui.Parent ~= ctx.playerGui then
            pcall(function()
                ctx.gui.Parent = ctx.playerGui
            end)
        end

        -- Remove NPCs que sumiram sem avisar.
        for model, info in pairs(ctx.npcs) do
            if model.Parent == nil or info.humanoid.Parent ~= model then
                ctx.dropNPC(model)
            end
        end

        if ctx.panelVisible and not ctx.minimized then
            ctx.updateStats()
        end
    end

    local fastTimer, slowTimer = 0, 0

    ctx.track(ctx.RunService.Heartbeat:Connect(function(dt)
        if not ctx.running then
            return
        end

        fastTimer += dt
        slowTimer += dt

        local overlaysActive = ctx.cfg.ESPEnabled or ctx.cfg.HighlightEnabled or ctx.cfg.NPCEnabled
            or ctx.playersVisible or ctx.npcVisible
        if overlaysActive and fastTimer >= ctx.interval then
            fastTimer = 0

            local started = os.clock()
            local ok, err = pcall(ctx.refreshAll)
            if not ok then
                ctx.softWarn("ciclo do ESP", err)
            end
            local cost = os.clock() - started

            if ctx.cfg.AutoPerformance then
                if cost > 0.006 then
                    ctx.interval = math.min(0.5, ctx.interval * 1.5)
                elseif cost < 0.002 then
                    ctx.interval = math.max(ctx.cfg.UpdateInterval, ctx.interval * 0.9)
                end
            else
                ctx.interval = ctx.cfg.UpdateInterval
            end
        end

        if slowTimer >= 1 then
            slowTimer = 0
            watchdog()
        end
    end))

    ------------------------------------------------------------------------
    -- LIMPEZA (chamada ao re-executar ou pelo botão "Descarregar o script")
    ------------------------------------------------------------------------

    function ctx.cleanup()
        if not ctx.running then
            return
        end
        ctx.running = false

        ctx.aim.stop()
        ctx.unbindSpectate()
        pcall(ctx.RunService.UnbindFromRenderStep, ctx.RunService, ctx.BIND_WORLD)
        ctx.worldBound = false
        ctx.setNPCTracking(false)

        for _, connection in ipairs(ctx.conns) do
            pcall(function()
                connection:Disconnect()
            end)
        end
        table.clear(ctx.conns)

        for key, data in pairs(ctx.esp) do
            ctx.destroyData(data)
            ctx.esp[key] = nil
        end

        if ctx.selectedPlayer then
            ctx.stopSpectating()
        end

        ctx.cfg.FullbrightEnabled = false
        ctx.cfg.NoFogEnabled = false
        pcall(ctx.syncFullbright)
        pcall(ctx.syncNoFog)

        if ctx.gui then
            ctx.gui:Destroy()
        end

        if _G.DivizaMethodCleanup == ctx.cleanup then
            _G.DivizaMethodCleanup = nil
        end
    end

    _G.DivizaMethodCleanup = ctx.cleanup
    ctx.track(ctx.owner.Destroying:Connect(ctx.cleanup))

    ------------------------------------------------------------------------
    -- INÍCIO
    ------------------------------------------------------------------------

    ctx.setNPCFilter(ctx.npcFilterText)
    ctx.applyWorld()
    ctx.updateStats()
    ctx.setNPCTracking(ctx.cfg.NPCEnabled)

    print("DIVIZA METHOD v4.0 carregado. Tecla: " .. ctx.cfg.GuiKey)
end

return Runtime
