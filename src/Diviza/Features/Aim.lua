local Aim = {}

function Aim.init(ctx)
    ctx.aim.circle = Instance.new("Frame")
    ctx.aim.circle.Name = "CaptureRadius"
    ctx.aim.circle.AnchorPoint = Vector2.new(0.5, 0.5)
    ctx.aim.circle.BackgroundTransparency = 1
    ctx.aim.circle.Visible = false
    ctx.aim.circle.Parent = ctx.gui
    ctx.corner(ctx.aim.circle, 1000)
    ctx.aim.outline = ctx.stroke(ctx.aim.circle, ctx.theme.sub, 0.25, 1)

    function ctx.aim.clearTarget()
        ctx.aim.outline.Color = ctx.theme.sub
        ctx.aim.target = nil
        ctx.aim.rotation = nil
        ctx.aim.nextScan = 0
    end

    function ctx.aim.stop()
        ctx.aim.circle.Visible = false
        if ctx.aim.bound then
            ctx.RunService:UnbindFromRenderStep(ctx.aim.binding)
            ctx.aim.bound = false
        end
        ctx.aim.clearTarget()
        ctx.aim.character = nil
    end

    function ctx.aim.pointFor(player, camera, frame, cursor, limit, maxDistanceSquared)
        if player == ctx.me or player.Parent ~= ctx.Players then
            return nil
        end
        if ctx.cfg.AimIgnoreTeammates and ctx.me.Team ~= nil and not ctx.me.Neutral
            and not player.Neutral and player.Team == ctx.me.Team then
            return nil
        end

        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 or not character:IsDescendantOf(workspace) then
            return nil
        end

        local partName = ctx.cfg.AimAtHead and "Head" or "UpperTorso"
        local part = character:FindFirstChild(partName)
        if not part and not ctx.cfg.AimAtHead then
            part = character:FindFirstChild("Torso") or character:FindFirstChild("HumanoidRootPart")
        end
        if not part or not part:IsA("BasePart") then
            return nil
        end

        local point = part.Position
        local offset = point - frame.Position
        local distanceSquared = offset:Dot(offset)
        if distanceSquared < 0.000001 or distanceSquared > maxDistanceSquared then
            return nil
        end

        local screen, onScreen = camera:WorldToViewportPoint(point)
        if not onScreen then return nil end
        local dx, dy = screen.X - cursor.X, screen.Y - cursor.Y
        local pixelsSquared = dx * dx + dy * dy
        if pixelsSquared > limit then return nil end

        local hit = workspace:Raycast(frame.Position, offset, ctx.aim.rayParams)
        if hit and not hit.Instance:IsDescendantOf(character) then
            return nil
        end

        return point, pixelsSquared
    end

    function ctx.aim.step(dt)
        local camera = workspace.CurrentCamera
        local character = ctx.me.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not camera or not humanoid or humanoid.Health <= 0 or ctx.panelVisible
            or ctx.selectedPlayer or not ctx.cfg.AimEnabled or ctx.UIS:GetFocusedTextBox()
            or (not ctx.cfg.AimToggle and not ctx.UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)) then
            ctx.aim.stop()
            return
        end

        if ctx.aim.character ~= character then
            ctx.aim.character = character
            ctx.aim.rayParams.FilterDescendantsInstances = { character }
            ctx.aim.clearTarget()
        end

        local frame = camera.CFrame
        local cursor = ctx.UIS:GetMouseLocation()
        local limit = ctx.cfg.AimRadius * ctx.cfg.AimRadius
        local inset = game:GetService("GuiService"):GetGuiInset()
        ctx.aim.circle.Position = UDim2.fromOffset(cursor.X - inset.X, cursor.Y - inset.Y)
        ctx.aim.circle.Size = UDim2.fromOffset(ctx.cfg.AimRadius * 2, ctx.cfg.AimRadius * 2)
        ctx.aim.circle.Visible = true
        local maxDistanceSquared = ctx.cfg.AimRange * ctx.cfg.AimRange
        local point

        if ctx.aim.target then
            point = ctx.aim.pointFor(ctx.aim.target, camera, frame, cursor, limit, maxDistanceSquared)
            if not point then
                ctx.aim.clearTarget()
            end
        end

        if not point then
            local now = os.clock()
            if now < ctx.aim.nextScan then
                return
            end
            ctx.aim.nextScan = now + (ctx.cfg.AimSnap and 1 / 30 or 0.10)
            local bestScore = limit
            for _, player in ipairs(ctx.Players:GetPlayers()) do
                local candidate, score = ctx.aim.pointFor(player, camera, frame, cursor, bestScore, maxDistanceSquared)
                if candidate then
                    ctx.aim.target = player
                    point = candidate
                    bestScore = score
                end
            end
            if not point then
                return
            end
        end

        ctx.aim.outline.Color = ctx.theme.accentHi
        local ray = camera:ViewportPointToRay(cursor.X, cursor.Y)
        local direction = (point - frame.Position).Unit
        local axis = ray.Direction:Cross(direction)
        local angle = math.atan2(axis.Magnitude, math.clamp(ray.Direction:Dot(direction), -1, 1))
        local correction = axis.Magnitude > 1e-6 and CFrame.fromAxisAngle(axis.Unit, angle) or CFrame.identity
        local desired = CFrame.new(frame.Position) * correction * frame.Rotation
        if ctx.cfg.AimSnap then
            camera.CFrame = desired
        else
            local previous = ctx.aim.rotation and CFrame.new(frame.Position) * ctx.aim.rotation or frame
            local smoothing = 1 - math.exp(-ctx.cfg.AimSpeed * dt)
            local result = previous:Lerp(desired, smoothing)
            ctx.aim.rotation = result.Rotation
            camera.CFrame = result
        end
    end

    function ctx.aim.start()
        if ctx.aim.bound or not ctx.cfg.AimEnabled or ctx.panelVisible or ctx.selectedPlayer or ctx.UIS:GetFocusedTextBox() then
            return
        end
        ctx.aim.bound = true
        ctx.RunService:BindToRenderStep(ctx.aim.binding, Enum.RenderPriority.Camera.Value + 2, ctx.aim.step)
    end


    -- A arma consulta este ponto uma vez por disparo, antes da validação no servidor.
    local resolver = Instance.new("BindableFunction")
    resolver.Name = "ResolveAimPoint"
    resolver.Parent = ctx.gui
    local random = Random.new()
    resolver.OnInvoke = function(origin)
        local camera = workspace.CurrentCamera
        local character = ctx.me.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if typeof(origin) ~= "Vector3" or not camera or not humanoid or humanoid.Health <= 0
            or not ctx.cfg.AimEnabled or not ctx.cfg.SilentAim or ctx.panelVisible or ctx.selectedPlayer
            or ctx.cfg.HitChance <= 0 or random:NextNumber(0, 100) >= ctx.cfg.HitChance then return nil end
        ctx.aim.rayParams.FilterDescendantsInstances = { character }
        local cursor = ctx.UIS:GetMouseLocation()
        local best = ctx.cfg.AimRadius ^ 2
        local result
        for _, player in ipairs(ctx.Players:GetPlayers()) do
            local point, score = ctx.aim.pointFor(player, camera, camera.CFrame, cursor, best, ctx.cfg.AimRange ^ 2)
            if point then
                local offset = point - origin
                local hit = workspace:Raycast(origin, offset, ctx.aim.rayParams)
                if offset.Magnitude <= ctx.cfg.AimRange and (not hit or hit.Instance:IsDescendantOf(player.Character)) then
                    result, best = point, score
                end
            end
        end
        return result
    end
end

return Aim
