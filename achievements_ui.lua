-- achievements_ui.lua
-- Tela de conquistas. Usa o mesmo sistema de botões (button.lua/Buttons)
-- do resto do jogo em vez de ler o mouse "cru" — assim ganha de graça
-- suporte a teclado/gamepad, mobile (touch) e o hover/click que os outros
-- menus já têm.

local Lang = require("lang")
local Utils = require("utils")

local AchievementsUI = {}

AchievementsUI.page = 1
AchievementsUI.PAGE_SIZE = 5

local LIST_X = 20
local LIST_Y0 = 46
local ITEM_H = 34
local ITEM_W = 472
local ICON_SIZE = 24 -- tamanho de desenho na tela; os PNGs são escalados pra caber aqui

-- Ícones de pixel art (carregados uma vez, sob demanda, na 1a chamada de
-- draw — não em tempo de "require", pra não quebrar se algo tentar
-- carregar este módulo antes de love.graphics estar pronto).
local icon_locked = nil
local icon_unlocked = nil

local function ensureIcons()
    if not icon_locked then
        icon_locked = love.graphics.newImage("assets/Cadeado_ICON.png")
        icon_locked:setFilter("nearest", "nearest")
    end
    if not icon_unlocked then
        icon_unlocked = love.graphics.newImage("assets/Check_ICON.png")
        icon_unlocked:setFilter("nearest", "nearest")
    end
end

local function totalPages()
    local Achievements = require("achievements")
    local total = #Achievements.getAll()
    return math.max(1, math.ceil(total / AchievementsUI.PAGE_SIZE))
end

-- Garante que a página atual é válida (chamado ao entrar na tela)
function AchievementsUI.reset()
    AchievementsUI.page = 1
end

-- Desenha o ícone de status (troféu/check se desbloqueada, cadeado se
-- bloqueada) usando os PNGs de pixel art, escalados pro tamanho fixo do
-- ícone na lista sem borrar (nearest filter já setado em ensureIcons).
local function drawStatusIcon(x, y, unlocked)
    local img = unlocked and icon_unlocked or icon_locked
    local iw, ih = img:getDimensions()
    local scale = ICON_SIZE / math.max(iw, ih)
    if not unlocked then
        love.graphics.setColor(1, 1, 1, 0.6) -- cadeado um pouco apagado
    else
        love.graphics.setColor(1, 1, 1, 1)
    end
    love.graphics.draw(img, x, y, 0, scale, scale)
    love.graphics.setColor(1, 1, 1, 1)
end

function AchievementsUI.draw()
    ensureIcons()
    local Achievements = require("achievements")
    local Characters = require("characters")
    local all = Achievements.getAll()
    local total = #all

    Utils.setColor(0)
    Utils.centerText(Lang.text("achievements_title"), 8)

    local pct = Achievements.getPercentage()
    local pct_text = Lang.text("achievements_percent", math.floor(pct))
    Utils.setColor(0)
    love.graphics.print(pct_text, LIST_X, 24)

    -- Barra de progresso geral (retangular, sem cantos suaves)
    local bar_x, bar_y, bar_w, bar_h = LIST_X + 140, 26, 200, 8
    love.graphics.setColor(0.15, 0.15, 0.15, 1)
    love.graphics.rectangle("fill", bar_x, bar_y, bar_w, bar_h)
    Utils.setColor(11) -- verde claro
    love.graphics.rectangle("fill", bar_x, bar_y, bar_w * (pct / 100), bar_h)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("line", bar_x, bar_y, bar_w, bar_h)

    if total == 0 then
        Utils.centerText(Lang.text("achievements_empty"), 100)
        return
    end

    local pages = totalPages()
    if AchievementsUI.page > pages then AchievementsUI.page = pages end
    if AchievementsUI.page < 1 then AchievementsUI.page = 1 end

    local start_index = (AchievementsUI.page - 1) * AchievementsUI.PAGE_SIZE + 1
    local end_index = math.min(start_index + AchievementsUI.PAGE_SIZE - 1, total)

    for i = start_index, end_index do
        local ach = all[i]
        local row = i - start_index
        local iy = LIST_Y0 + row * ITEM_H
        local unlocked = Achievements.isUnlocked(ach.id)

        -- Fundo do card (cantos retos, estilo pixel art)
        love.graphics.setColor(unlocked and 0.10 or 0.08, unlocked and 0.14 or 0.08, unlocked and 0.10 or 0.08, 0.9)
        love.graphics.rectangle("fill", LIST_X, iy, ITEM_W, ITEM_H - 4)
        love.graphics.setColor(1, 1, 1, unlocked and 0.25 or 0.1)
        love.graphics.rectangle("line", LIST_X, iy, ITEM_W, ITEM_H - 4)

        drawStatusIcon(LIST_X + 6, iy + 3, unlocked)

        -- Nome + descrição (ou "???" se bloqueada, pra não entregar o
        -- requisito antes da hora — mesma lógica de "spoiler" de jogos
        -- reais de conquistas)
        local name_x = LIST_X + 6 + ICON_SIZE + 10
        Utils.setColor(unlocked and 7 or 6)
        love.graphics.print(Lang.text(ach.name_key), name_x, iy + 3)

        Utils.setColor(unlocked and 6 or 5)
        love.graphics.print(Lang.text(ach.desc_key), name_x, iy + 15)

        -- Indicador de personagem desbloqueado, se houver — mostra o
        -- NOME real do personagem (via get_name(), já traduzido),
        -- não o id interno usado em Characters.list. Fica numa faixa
        -- própria à direita do card, pra não brigar com a descrição.
        if ach.unlocks_character then
            local char = Characters.getById and Characters.getById(ach.unlocks_character) or nil
            local char_name = char and char.get_name() or ach.unlocks_character
            local char_label = Lang.text("achievements_unlocks", char_name)
            local lw = love.graphics.getFont():getWidth(char_label)
            local label_x = LIST_X + ITEM_W - lw - 8
            Utils.setColor(unlocked and 10 or 5)
            love.graphics.print(char_label, label_x, iy + 3)
        end
    end

    -- Indicador de página
    local page_text = AchievementsUI.page .. " / " .. pages
    local pw = love.graphics.getFont():getWidth(page_text)
    Utils.setColor(0)
    love.graphics.print(page_text, (512 - pw) / 2, 234)
end

-- Monta os botões de navegação da tela (chamado por setupButtonsForState).
-- `Buttons` é o GUI global do jogo; `Lang`/SFX vêm do escopo de main.lua.
function AchievementsUI.setupButtons(Buttons, SFX_select)
    local pages = totalPages()

    Buttons:newButton(20, 234, 60, 18, Lang.text("achievements_prev"), function()
        if AchievementsUI.page > 1 then
            AchievementsUI.page = AchievementsUI.page - 1
            if SFX_select then SFX_select:play() end
            _G.setupButtonsForState("achievements")
        end
    end)

    Buttons:newButton(432, 234, 60, 18, Lang.text("achievements_next"), function()
        if AchievementsUI.page < pages then
            AchievementsUI.page = AchievementsUI.page + 1
            if SFX_select then SFX_select:play() end
            _G.setupButtonsForState("achievements")
        end
    end)

    Buttons:newButton((512/2)-63, 234, 126, 18, Lang.text("menu_back"), function()
        if SFX_select then SFX_select:play() end
        _G.switchState("menu")
    end)
end

return AchievementsUI