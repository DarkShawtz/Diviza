local Components = {}

function Components.newBuilder(ctx)
    local order = 0
    local function nextOrder()
        order += 1
        return order
    end

    local function addSection(text, parent)
        local l = ctx.newLabel(parent or ctx.content, text, 11, Enum.Font.GothamBold, ctx.theme.accentHi)
        l.Size = UDim2.new(1, 0, 0, 26)
        l.TextYAlignment = Enum.TextYAlignment.Bottom
        l.LayoutOrder = nextOrder()
        return l
    end

    local function addNote(text, parent)
        local l = ctx.newLabel(parent or ctx.content, text, 11, Enum.Font.Gotham, ctx.theme.sub)
        l.Size = UDim2.new(1, 0, 0, 16)
        l.AutomaticSize = Enum.AutomaticSize.Y
        l.TextWrapped = true
        l.TextYAlignment = Enum.TextYAlignment.Top
        l.LayoutOrder = nextOrder()
        return l
    end

    local function addButton(parent, text, callback, style, height)
        local base = ctx.styles[style or "normal"]
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, 0, 0, height or 36)
        b.BackgroundColor3 = base
        b.BorderSizePixel = 0
        b.AutoButtonColor = false
        b.Text = text
        b.TextColor3 = ctx.theme.text
        b.Font = Enum.Font.GothamMedium
        b.TextSize = 13
        b.TextWrapped = true
        b.LayoutOrder = nextOrder()
        b.Parent = parent or ctx.content
        ctx.corner(b, 10)

        b.MouseEnter:Connect(function()
            ctx.tween(b, { BackgroundColor3 = base:Lerp(Color3.new(1, 1, 1), 0.1) }, 0.1)
        end)
        b.MouseLeave:Connect(function()
            ctx.tween(b, { BackgroundColor3 = base }, 0.1)
        end)
        b.Activated:Connect(callback)

        return b
    end

    local function addToggle(text, key, onChange, parent)
        local row = Instance.new("TextButton")
        row.Size = UDim2.new(1, 0, 0, 42)
        row.BackgroundColor3 = ctx.theme.card
        row.BorderSizePixel = 0
        row.AutoButtonColor = false
        row.Text = ""
        row.LayoutOrder = nextOrder()
        row.Parent = parent or ctx.content
        ctx.corner(row, 10)

        local label = ctx.newLabel(row, text, 13, Enum.Font.Gotham, ctx.theme.text)
        label.Size = UDim2.new(1, -76, 1, 0)
        label.Position = UDim2.fromOffset(14, 0)

        local switch = Instance.new("Frame")
        switch.Size = UDim2.fromOffset(38, 20)
        switch.Position = UDim2.new(1, -52, 0.5, -10)
        switch.BorderSizePixel = 0
        switch.Parent = row
        ctx.corner(switch, 10)
        local switchStroke = ctx.stroke(switch, ctx.theme.off, 0, 1)

        local knob = Instance.new("Frame")
        knob.Size = UDim2.fromOffset(14, 14)
        knob.BackgroundColor3 = Color3.new(1, 1, 1)
        knob.BorderSizePixel = 0
        knob.Parent = switch
        ctx.corner(knob, 7)

        local function refresh(animate)
            local on = ctx.cfg[key]
            local position = on and UDim2.fromOffset(21, 3) or UDim2.fromOffset(3, 3)
            local fillColor = on and ctx.theme.accent or ctx.theme.off
            local lineColor = on and ctx.theme.accentHi or ctx.theme.off
            if animate then
                ctx.tween(knob, { Position = position })
                ctx.tween(switch, { BackgroundColor3 = fillColor })
                ctx.tween(switchStroke, { Color = lineColor })
            else
                knob.Position = position
                switch.BackgroundColor3 = fillColor
                switchStroke.Color = lineColor
            end
        end

        row.MouseEnter:Connect(function()
            ctx.tween(row, { BackgroundColor3 = ctx.theme.cardHover }, 0.1)
        end)
        row.MouseLeave:Connect(function()
            ctx.tween(row, { BackgroundColor3 = ctx.theme.card }, 0.1)
        end)

        row.Activated:Connect(function()
            ctx.cfg[key] = not ctx.cfg[key]
            if onChange then
                onChange(ctx.cfg[key])
            end
            refresh(true)
        end)

        refresh(false)
    end

    local function addSlider(text, key, min, max, step, format, onChange, parent)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 58)
        row.BackgroundColor3 = ctx.theme.card
        row.BorderSizePixel = 0
        row.LayoutOrder = nextOrder()
        row.Parent = parent or ctx.content
        ctx.corner(row, 10)

        local label = ctx.newLabel(row, text, 13, Enum.Font.Gotham, ctx.theme.text)
        label.Position = UDim2.fromOffset(14, 8)
        label.Size = UDim2.new(1, -120, 0, 18)

        local valueLabel = ctx.newLabel(row, "", 12, Enum.Font.GothamBold, ctx.theme.accentHi)
        valueLabel.Position = UDim2.new(1, -112, 0, 8)
        valueLabel.Size = UDim2.fromOffset(98, 18)
        valueLabel.TextXAlignment = Enum.TextXAlignment.Right

        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(1, -28, 0, 6)
        bar.Position = UDim2.fromOffset(14, 39)
        bar.BackgroundColor3 = ctx.theme.off
        bar.BorderSizePixel = 0
        bar.Parent = row
        ctx.corner(bar, 3)

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new(0, 0, 1, 0)
        fill.BackgroundColor3 = Color3.new(1, 1, 1)
        fill.BorderSizePixel = 0
        fill.Parent = bar
        ctx.corner(fill, 3)

        local gradient = Instance.new("UIGradient")
        gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 179, 209)),
            ColorSequenceKeypoint.new(0.5, ctx.theme.accent),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(78, 27, 117)),
        })
        gradient.Parent = fill

        local knob = Instance.new("Frame")
        knob.AnchorPoint = Vector2.new(0.5, 0.5)
        knob.Size = UDim2.fromOffset(14, 14)
        knob.BackgroundColor3 = Color3.new(1, 1, 1)
        knob.BorderSizePixel = 0
        knob.Parent = bar
        ctx.corner(knob, 7)
        ctx.stroke(knob, ctx.theme.accentHi, 0.3, 1)

        -- Área de toque maior que a barra
        local hit = Instance.new("TextButton")
        hit.Size = UDim2.new(1, -8, 0, 28)
        hit.Position = UDim2.fromOffset(4, 28)
        hit.BackgroundTransparency = 1
        hit.Text = ""
        hit.Parent = row

        local function visual()
            local value = ctx.cfg[key]
            local alpha = math.clamp((value - min) / (max - min), 0, 1)
            fill.Size = UDim2.new(alpha, 0, 1, 0)
            knob.Position = UDim2.new(alpha, 0, 0.5, 0)
            valueLabel.Text = format(value)
        end

        local function setFromX(x)
            local width = bar.AbsoluteSize.X
            if width <= 0 then
                return
            end

            local alpha = math.clamp((x - bar.AbsolutePosition.X) / width, 0, 1)
            local value = min + (max - min) * alpha
            value = min + math.floor((value - min) / step + 0.5) * step
            value = tonumber(string.format("%.4f", math.clamp(value, min, max)))

            if value ~= ctx.cfg[key] then
                ctx.cfg[key] = value
                if onChange then
                    onChange(value)
                end
            end
            visual()
        end

        hit.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                ctx.content.ScrollingEnabled = false
                setFromX(input.Position.X)
                ctx.activeDrag = function(position)
                    setFromX(position.X)
                end
            end
        end)

        visual()
    end

    local function addSwatches(title, key)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 66)
        row.BackgroundColor3 = ctx.theme.card
        row.BorderSizePixel = 0
        row.LayoutOrder = nextOrder()
        row.Parent = ctx.content
        ctx.corner(row, 10)

        local label = ctx.newLabel(row, title, 13, Enum.Font.Gotham, ctx.theme.text)
        label.Position = UDim2.fromOffset(14, 8)
        label.Size = UDim2.new(1, -28, 0, 18)

        local holder = Instance.new("Frame")
        holder.Size = UDim2.new(1, -28, 0, 26)
        holder.Position = UDim2.fromOffset(14, 32)
        holder.BackgroundTransparency = 1
        holder.Parent = row
        ctx.newList(holder, 10, true)

        local outlines = {}
        for index, color in ipairs(ctx.colors) do
            local b = Instance.new("TextButton")
            b.Size = UDim2.fromOffset(26, 26)
            b.BackgroundColor3 = color
            b.BorderSizePixel = 0
            b.AutoButtonColor = false
            b.Text = ""
            b.LayoutOrder = index
            b.Parent = holder
            ctx.corner(b, 13)

            outlines[index] = ctx.stroke(
                b, Color3.new(1, 1, 1),
                index == ctx.cfg[key] and 0 or 1, 2
            )

            b.Activated:Connect(function()
                ctx.cfg[key] = index
                for i, s in ipairs(outlines) do
                    s.Transparency = i == index and 0 or 1
                end
            end)
        end
    end

    local function addTextInput(title, placeholder, initial, onChange)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 68)
        row.BackgroundColor3 = ctx.theme.card
        row.BorderSizePixel = 0
        row.LayoutOrder = nextOrder()
        row.Parent = ctx.content
        ctx.corner(row, 10)

        local label = ctx.newLabel(row, title, 13, Enum.Font.Gotham, ctx.theme.text)
        label.Position = UDim2.fromOffset(14, 8)
        label.Size = UDim2.new(1, -28, 0, 18)

        local box = Instance.new("TextBox")
        box.Size = UDim2.new(1, -28, 0, 28)
        box.Position = UDim2.fromOffset(14, 32)
        box.BackgroundColor3 = ctx.theme.bg
        box.BorderSizePixel = 0
        box.TextColor3 = ctx.theme.text
        box.PlaceholderColor3 = ctx.theme.sub
        box.PlaceholderText = placeholder
        box.Text = initial
        box.ClearTextOnFocus = false
        box.TextXAlignment = Enum.TextXAlignment.Left
        box.Font = Enum.Font.Gotham
        box.TextSize = 13
        box.Parent = row
        ctx.corner(box, 8)
        ctx.stroke(box, ctx.theme.line, 0, 1)

        local boxPadding = Instance.new("UIPadding")
        boxPadding.PaddingLeft = UDim.new(0, 10)
        boxPadding.Parent = box

        box:GetPropertyChangedSignal("Text"):Connect(function()
            onChange(box.Text)
        end)

        return box
    end


    return {
        nextOrder = nextOrder,
        addSection = addSection,
        addNote = addNote,
        addButton = addButton,
        addToggle = addToggle,
        addSlider = addSlider,
        addSwatches = addSwatches,
        addTextInput = addTextInput,
    }
end

return Components
