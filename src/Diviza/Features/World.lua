local World = {}

function World.init(ctx)
    local savedLight = nil
    local savedFog = nil
    local savedAtmos = setmetatable({}, { __mode = "k" })
    local whiteLight = Color3.new(1, 1, 1)

    local function setIfChanged(object, property, value)
        if object[property] ~= value then
            object[property] = value
        end
    end

    function ctx.syncFullbright()
        if ctx.cfg.FullbrightEnabled then
            if not savedLight then
                savedLight = {
                    Brightness = ctx.Lighting.Brightness,
                    GlobalShadows = ctx.Lighting.GlobalShadows,
                    Ambient = ctx.Lighting.Ambient,
                    OutdoorAmbient = ctx.Lighting.OutdoorAmbient,
                }
            end
            setIfChanged(ctx.Lighting, "Brightness", 3)
            setIfChanged(ctx.Lighting, "GlobalShadows", false)
            setIfChanged(ctx.Lighting, "Ambient", whiteLight)
            setIfChanged(ctx.Lighting, "OutdoorAmbient", whiteLight)
        elseif savedLight then
            for property, value in pairs(savedLight) do
                ctx.Lighting[property] = value
            end
            savedLight = nil
        end
    end

    local function restoreAtmospheres()
        for atmosphere, values in pairs(savedAtmos) do
            if atmosphere.Parent then
                atmosphere.Density = values.Density
                atmosphere.Haze = values.Haze
                atmosphere.Glare = values.Glare
            end
        end
        table.clear(savedAtmos)
    end

    function ctx.syncNoFog()
        if ctx.cfg.NoFogEnabled then
            if not savedFog then
                savedFog = {
                    FogStart = ctx.Lighting.FogStart,
                    FogEnd = ctx.Lighting.FogEnd,
                }
            end

            local strength = ctx.cfg.NoFogStrength
            setIfChanged(ctx.Lighting, "FogStart", savedFog.FogStart * (1 - strength))
            setIfChanged(ctx.Lighting, "FogEnd", savedFog.FogEnd + (1000000 - savedFog.FogEnd) * strength)

            if ctx.cfg.NoFogAtmosphere then
                local keep = 1 - strength
                for _, instance in ipairs(ctx.Lighting:GetChildren()) do
                    if instance:IsA("Atmosphere") then
                        local saved = savedAtmos[instance]
                        if not saved then
                            saved = {
                                Density = instance.Density,
                                Haze = instance.Haze,
                                Glare = instance.Glare,
                            }
                            savedAtmos[instance] = saved
                        end
                        setIfChanged(instance, "Density", saved.Density * keep)
                        setIfChanged(instance, "Haze", saved.Haze * keep)
                        setIfChanged(instance, "Glare", saved.Glare * keep)
                    end
                end
            elseif next(savedAtmos) ~= nil then
                restoreAtmospheres()
            end
        elseif savedFog then
            ctx.Lighting.FogStart = savedFog.FogStart
            ctx.Lighting.FogEnd = savedFog.FogEnd
            savedFog = nil
            restoreAtmospheres()
        end
    end

    ctx.worldBound = false

    local function worldStep()
        pcall(ctx.syncFullbright)
        pcall(ctx.syncNoFog)
    end

    local function updateWorldBinding()
        local want = ctx.cfg.FullbrightEnabled or ctx.cfg.NoFogEnabled
        if want and not ctx.worldBound then
            ctx.worldBound = true
            ctx.RunService:BindToRenderStep(ctx.BIND_WORLD, Enum.RenderPriority.Last.Value, worldStep)
        elseif not want and ctx.worldBound then
            ctx.worldBound = false
            pcall(ctx.RunService.UnbindFromRenderStep, ctx.RunService, ctx.BIND_WORLD)
        end
    end

    -- Aplica agora (restaura se desligado) e liga/desliga o RenderStep.
    function ctx.applyWorld()
        ctx.syncFullbright()
        ctx.syncNoFog()
        updateWorldBinding()
    end
end

return World
