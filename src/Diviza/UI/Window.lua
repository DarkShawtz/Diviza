local Window = {}

function Window.init(ctx)
    ctx.PANEL_POS = UDim2.fromScale(0.5, 0.5)

    ctx.gui = Instance.new("ScreenGui")
    ctx.gui.Name = "DivizaMethod"
    ctx.gui.ResetOnSpawn = false
    ctx.gui.DisplayOrder = 50
    ctx.gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    local layoutBounds = Instance.new("Frame")
    layoutBounds.Name = "LayoutBounds"
    layoutBounds.BackgroundTransparency = 1
    layoutBounds.Size = UDim2.fromScale(1, 1)
    layoutBounds.Parent = ctx.gui

    ctx.panel = Instance.new("Frame")
    ctx.panel.Name = "Main"
    ctx.panel.AnchorPoint = Vector2.new(0.5, 0.5)
    ctx.panel.Size = UDim2.fromOffset(ctx.PANEL_W, ctx.PANEL_H)
    ctx.panel.Position = ctx.PANEL_POS
    ctx.panel.BackgroundColor3 = ctx.theme.bg
    ctx.panel.BorderSizePixel = 0
    ctx.panel.ClipsDescendants = true
    ctx.panel.Parent = layoutBounds
    ctx.corner(ctx.panel, 16)
    ctx.stroke(ctx.panel, ctx.theme.line, 0, 1)

    local uiScale = Instance.new("UIScale")
    uiScale.Parent = ctx.panel

    local function panelScale()
        local size = layoutBounds.AbsoluteSize
        if size.X <= 0 or size.Y <= 0 then
            return 1
        end
        return math.clamp(math.min((size.X - 24) / ctx.PANEL_W, (size.Y - 24) / ctx.PANEL_H), 0.1, 1)
    end

    uiScale.Scale = panelScale()
    ctx.track(layoutBounds:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        ctx.panel.Position = ctx.PANEL_POS
        uiScale.Scale = panelScale()
    end))

    -- Barra lateral --------------------------------------------------------
    ctx.sidebar = Instance.new("Frame")
    ctx.sidebar.Name = "Sidebar"
    ctx.sidebar.Size = UDim2.new(0, ctx.SIDEBAR_W, 1, 0)
    ctx.sidebar.BackgroundColor3 = ctx.theme.sidebar
    ctx.sidebar.BorderSizePixel = 0
    ctx.sidebar.Parent = ctx.panel
    ctx.corner(ctx.sidebar, 14)

    local sidebarFill = Instance.new("Frame") -- deixa a borda direita reta
    sidebarFill.Size = UDim2.new(0, 16, 1, 0)
    sidebarFill.Position = UDim2.new(1, -16, 0, 0)
    sidebarFill.BackgroundColor3 = ctx.theme.sidebar
    sidebarFill.BorderSizePixel = 0
    sidebarFill.Parent = ctx.sidebar

    local logo = Instance.new("Frame")
    logo.Name = "Logo"
    logo.Size = UDim2.new(1, 0, 0, ctx.TOPBAR_H)
    logo.BackgroundTransparency = 1
    logo.Parent = ctx.sidebar

    local mark = Instance.new("Frame")
    mark.Size = UDim2.fromOffset(30, 30)
    mark.Position = UDim2.fromOffset(16, 22)
    mark.BackgroundColor3 = ctx.theme.accent
    mark.BorderSizePixel = 0
    mark.Parent = logo
    ctx.corner(mark, 9)
    ctx.stroke(mark, ctx.theme.accentHi, 0.45, 1)

    local markText = ctx.newLabel(mark, "D", 16, Enum.Font.GothamBold, Color3.new(1, 1, 1))
    markText.Size = UDim2.fromScale(1, 1)
    markText.TextXAlignment = Enum.TextXAlignment.Center

    local logoTitle = ctx.newLabel(logo, "DIVIZA", 14, Enum.Font.GothamBold, ctx.theme.text)
    logoTitle.Position = UDim2.fromOffset(58, 19)
    logoTitle.Size = UDim2.new(1, -62, 0, 18)

    local logoSub = ctx.newLabel(logo, "METHOD", 10, Enum.Font.GothamMedium, ctx.theme.accentHi)
    logoSub.Position = UDim2.fromOffset(58, 38)
    logoSub.Size = UDim2.new(1, -62, 0, 14)

    local sidebarBody = Instance.new("Frame")
    sidebarBody.Name = "Body"
    sidebarBody.Position = UDim2.fromOffset(0, ctx.TOPBAR_H)
    sidebarBody.Size = UDim2.new(1, 0, 1, -ctx.TOPBAR_H)
    sidebarBody.BackgroundTransparency = 1
    sidebarBody.Parent = ctx.sidebar

    ctx.tabHolder = Instance.new("Frame")
    ctx.tabHolder.Position = UDim2.fromOffset(10, 8)
    ctx.tabHolder.Size = UDim2.new(1, -20, 1, -56)
    ctx.tabHolder.BackgroundTransparency = 1
    ctx.tabHolder.Parent = sidebarBody
    ctx.newList(ctx.tabHolder, 4, false)

    local keyHint = ctx.newLabel(sidebarBody, "", 11, Enum.Font.GothamMedium, ctx.theme.sub)
    keyHint.Position = UDim2.new(0, 16, 1, -34)
    keyHint.Size = UDim2.new(1, -24, 0, 24)

    -- Área direita ---------------------------------------------------------
    local topbar = Instance.new("Frame")
    topbar.Name = "Topbar"
    topbar.Position = UDim2.fromOffset(ctx.SIDEBAR_W, 0)
    topbar.Size = UDim2.new(1, -ctx.SIDEBAR_W, 0, ctx.TOPBAR_H)
    topbar.BackgroundTransparency = 1
    topbar.Parent = ctx.panel

    ctx.pageTitle = ctx.newLabel(topbar, "", 24, Enum.Font.GothamBold, ctx.theme.text)
    ctx.pageTitle.Position = UDim2.fromOffset(24, 15)
    ctx.pageTitle.Size = UDim2.new(1, -120, 0, 30)

    ctx.pageSub = ctx.newLabel(topbar, "", 12, Enum.Font.Gotham, ctx.theme.sub)
    ctx.pageSub.Position = UDim2.fromOffset(24, 46)
    ctx.pageSub.Size = UDim2.new(1, -120, 0, 16)

    local topLine = Instance.new("Frame")
    topLine.Position = UDim2.fromOffset(ctx.SIDEBAR_W, ctx.TOPBAR_H)
    topLine.Size = UDim2.new(1, -ctx.SIDEBAR_W, 0, 1)
    topLine.BackgroundColor3 = ctx.theme.line
    topLine.BorderSizePixel = 0
    topLine.Parent = ctx.panel

    local function windowButton(text, rightOffset)
        local b = Instance.new("TextButton")
        b.Size = UDim2.fromOffset(28, 28)
        b.Position = UDim2.new(1, rightOffset, 0, 23)
        b.BackgroundColor3 = ctx.theme.card
        b.AutoButtonColor = false
        b.BorderSizePixel = 0
        b.Text = text
        b.TextColor3 = ctx.theme.text
        b.Font = Enum.Font.GothamBold
        b.TextSize = 16
        b.Parent = topbar
        ctx.corner(b, 8)
        b.MouseEnter:Connect(function()
            ctx.tween(b, { BackgroundColor3 = ctx.theme.accent }, 0.1)
        end)
        b.MouseLeave:Connect(function()
            ctx.tween(b, { BackgroundColor3 = ctx.theme.card }, 0.1)
        end)
        return b
    end

    local closeButton = windowButton("×", -40)
    local minimizeButton = windowButton("–", -74)

    ctx.content = Instance.new("ScrollingFrame")
    ctx.content.Name = "Content"
    ctx.content.Position = UDim2.fromOffset(ctx.SIDEBAR_W, ctx.TOPBAR_H + 1)
    ctx.content.Size = UDim2.new(1, -ctx.SIDEBAR_W, 1, -(ctx.TOPBAR_H + 1 + ctx.FOOTER_H))
    ctx.content.BackgroundTransparency = 1
    ctx.content.BorderSizePixel = 0
    ctx.content.ScrollBarThickness = 3
    ctx.content.ScrollBarImageColor3 = ctx.theme.accentHi
    ctx.content.AutomaticCanvasSize = Enum.AutomaticSize.Y
    ctx.content.CanvasSize = UDim2.new()
    ctx.content.Parent = ctx.panel

    local contentPadding = Instance.new("UIPadding")
    contentPadding.PaddingLeft = UDim.new(0, 24)
    contentPadding.PaddingRight = UDim.new(0, 24)
    contentPadding.PaddingTop = UDim.new(0, 16)
    contentPadding.PaddingBottom = UDim.new(0, 10)
    contentPadding.Parent = ctx.content

    ctx.newList(ctx.content, 8, false)

    local footer = ctx.newLabel(ctx.panel, "", 11, Enum.Font.Gotham, ctx.theme.sub)
    footer.Name = "Footer"
    footer.Position = UDim2.new(0, ctx.SIDEBAR_W, 1, -ctx.FOOTER_H)
    footer.Size = UDim2.new(1, -ctx.SIDEBAR_W, 0, ctx.FOOTER_H)

    local footerPadding = Instance.new("UIPadding")
    footerPadding.PaddingLeft = UDim.new(0, 20)
    footerPadding.Parent = footer

    local footerLine = Instance.new("Frame")
    footerLine.Position = UDim2.new(0, ctx.SIDEBAR_W, 1, -ctx.FOOTER_H)
    footerLine.Size = UDim2.new(1, -ctx.SIDEBAR_W, 0, 1)
    footerLine.BackgroundColor3 = ctx.theme.line
    footerLine.BorderSizePixel = 0
    footerLine.Parent = ctx.panel

    -- Aviso rápido (toast) -------------------------------------------------
    local toast = Instance.new("TextLabel")
    toast.Name = "Toast"
    toast.AnchorPoint = Vector2.new(0.5, 1)
    toast.Position = UDim2.new(0.5, 0, 1, -28)
    toast.Size = UDim2.fromOffset(320, 36)
    toast.BackgroundColor3 = ctx.theme.card
    toast.BackgroundTransparency = 1
    toast.TextColor3 = ctx.theme.text
    toast.TextTransparency = 1
    toast.Font = Enum.Font.GothamMedium
    toast.TextSize = 13
    toast.Text = ""
    toast.BorderSizePixel = 0
    toast.Parent = ctx.gui
    ctx.corner(toast, 10)
    local toastStroke = ctx.stroke(toast, ctx.theme.accentHi, 1, 1)

    local toastToken = 0
    function ctx.notify(text)
        toastToken += 1
        local token = toastToken
        toast.Text = text
        ctx.tween(toast, { BackgroundTransparency = 0.05, TextTransparency = 0 }, 0.2)
        ctx.tween(toastStroke, { Transparency = 0.4 }, 0.2)
        task.delay(2.6, function()
            if token == toastToken and toast.Parent then
                ctx.tween(toast, { BackgroundTransparency = 1, TextTransparency = 1 }, 0.3)
                ctx.tween(toastStroke, { Transparency = 1 }, 0.3)
            end
        end)
    end

    -- Abrir / fechar / minimizar -------------------------------------------
    function ctx.setPanelVisible(visible)
        ctx.panelVisible = visible
        if visible then
            ctx.aim.stop()
            ctx.panel.Visible = true
            uiScale.Scale = panelScale() * 0.96
            ctx.tween(uiScale, { Scale = panelScale() }, 0.18)
        else
            ctx.tween(uiScale, { Scale = panelScale() * 0.96 }, 0.12)
            task.delay(0.12, function()
                if not ctx.panelVisible and ctx.panel.Parent then
                    ctx.panel.Visible = false
                end
            end)
        end
    end

    closeButton.Activated:Connect(function()
        ctx.setPanelVisible(false)
        ctx.notify("Pressione " .. ctx.cfg.GuiKey .. " para abrir a Diviza Method")
    end)

    minimizeButton.Activated:Connect(function()
        ctx.minimized = not ctx.minimized
        sidebarBody.Visible = not ctx.minimized
        ctx.content.Visible = not ctx.minimized
        footer.Visible = not ctx.minimized
        footerLine.Visible = not ctx.minimized
        minimizeButton.Text = ctx.minimized and "+" or "–"
        ctx.tween(ctx.panel, { Size = UDim2.fromOffset(ctx.PANEL_W, ctx.minimized and ctx.TOPBAR_H or ctx.PANEL_H) }, 0.18)
    end)

    -- Arrastar a janela (cabeçalho e logo) ---------------------------------
    local function makeDraggable(handle)
        handle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                local startInput = input.Position
                local startPanel = ctx.panel.Position
                ctx.activeDrag = function(position)
                    local delta = position - startInput
                    local size = layoutBounds.AbsoluteSize
                    local halfWidth = math.max(0, (size.X - ctx.panel.AbsoluteSize.X) * 0.5)
                    local halfHeight = math.max(0, (size.Y - ctx.panel.AbsoluteSize.Y) * 0.5)
                    ctx.panel.Position = UDim2.new(
                        0.5, math.clamp(startPanel.X.Offset + delta.X, -halfWidth, halfWidth),
                        0.5, math.clamp(startPanel.Y.Offset + delta.Y, -halfHeight, halfHeight)
                    )
                end
            end
        end)
    end

    makeDraggable(topbar)
    makeDraggable(logo)

    ctx.track(ctx.UIS.InputChanged:Connect(function(input)
        if ctx.activeDrag and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            ctx.activeDrag(input.Position)
        end
    end))

    ctx.track(ctx.UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton2 and not ctx.cfg.AimToggle then
            ctx.aim.stop()
        end
        if ctx.activeDrag and (input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch) then
            ctx.activeDrag = nil
            ctx.content.ScrollingEnabled = true
        end
    end))

    ctx.track(ctx.UIS.WindowFocusReleased:Connect(function()
        ctx.aim.stop()
        ctx.activeDrag = nil
        ctx.content.ScrollingEnabled = true
    end))

    function ctx.clearContent()
        for _, child in ipairs(ctx.content:GetChildren()) do
            if child:IsA("GuiObject") then
                child:Destroy()
            end
        end
        ctx.statusLabel = nil
        ctx.onSpectateListRefresh = nil
        ctx.onSpectateStatus = nil
    end

    function ctx.updateStats()
        local footerText = string.format(
            "%d jogadores   |   %d NPCs   |   %d contornos",
            ctx.stats.players, ctx.stats.npcs, ctx.stats.outlined
        )
        if footer.Text ~= footerText then
            footer.Text = footerText
        end
        local hint = ctx.cfg.GuiKey .. "  abre / fecha"
        if keyHint.Text ~= hint then
            keyHint.Text = hint
        end
    end
end

return Window
