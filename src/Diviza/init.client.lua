local Players = game:GetService("Players")
local me = Players.LocalPlayer
local playerGui = me:WaitForChild("PlayerGui")

-- Se for ferramenta de admin/debug do seu jogo, coloque os UserIds permitidos
-- aqui, por exemplo [123456789] = true. Vazio = libera para todos.
local ALLOWED_USER_IDS = {
}

if next(ALLOWED_USER_IDS) ~= nil and not ALLOWED_USER_IDS[me.UserId] then
    return
end

-- Limpa execuções anteriores (esta versão e as antigas)
for _, key in ipairs({ "DivizaMethodCleanup", "DivizaESPCleanup" }) do
    local fn = _G[key]
    if type(fn) == "function" then
        pcall(fn)
    end
end
for _, name in ipairs({ "DivizaMethod", "DivizaESP" }) do
    local old = playerGui:FindFirstChild(name)
    if old then
        old:Destroy()
    end
end

local ctx = { owner = script, state = {}, Components = require(script.UI.Components) }
local function start()
    require(script.Core.Context).init(ctx)
    require(script.Features.World).init(ctx)
    require(script.UI.Primitives).init(ctx)
    require(script.UI.Window).init(ctx)
    require(script.Features.ESP).init(ctx)
    require(script.Features.Spectate).init(ctx)
    require(script.Features.Aim).init(ctx)
    require(script.UI.Pages).init(ctx)
    require(script.Core.Runtime).init(ctx)
end
local ok, err = xpcall(start, debug.traceback)
if not ok then
    if ctx.cleanup then ctx.cleanup() end
    if ctx.gui then ctx.gui:Destroy() end
    warn(err)
end
