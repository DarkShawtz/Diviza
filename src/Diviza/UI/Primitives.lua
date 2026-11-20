local Primitives = {}

function Primitives.init(ctx)
    function ctx.tween(object, properties, duration)
        local t = ctx.TweenService:Create(
            object,
            TweenInfo.new(duration or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            properties
        )
        t:Play()
        return t
    end

    function ctx.corner(parent, radius)
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, radius)
        c.Parent = parent
        return c
    end

    function ctx.stroke(parent, color, transparency, thickness)
        local s = Instance.new("UIStroke")
        s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        s.Color = color
        s.Transparency = transparency or 0
        s.Thickness = thickness or 1
        s.Parent = parent
        return s
    end

    function ctx.newList(parent, padding, horizontal)
        local l = Instance.new("UIListLayout")
        l.SortOrder = Enum.SortOrder.LayoutOrder
        l.Padding = UDim.new(0, padding)
        if horizontal then
            l.FillDirection = Enum.FillDirection.Horizontal
        end
        l.Parent = parent
        return l
    end

    function ctx.newLabel(parent, text, size, font, color)
        local l = Instance.new("TextLabel")
        l.BackgroundTransparency = 1
        l.Text = text
        l.TextSize = size
        l.Font = font
        l.TextColor3 = color
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Parent = parent
        return l
    end
end

return Primitives
