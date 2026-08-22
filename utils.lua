-- utils.lua
local Utils = {}

-- LÖVE já expõe "utf8" como global (lib padrão do Lua 5.3+), mas
-- declaramos explicitamente via require pra deixar a dependência
-- clara e não depender de um global implícito.
local utf8 = require("utf8")

-- Paleta de cores padrão do PICO-8 (em formato 0-1 para LÖVE)
Utils.pico8_colors = {
    [0]  = {0, 0, 0},           [1]  = {29, 43, 83},    [2]  = {126, 37, 83},   [3]  = {0, 135, 81},
    [4]  = {171, 82, 54},    [5]  = {95, 87, 79},     [6]  = {194, 195, 199}, [7]  = {255, 241, 232},
    [8]  = {255, 0, 77},     [9]  = {255, 163, 0},    [10] = {255, 236, 39},  [11] = {0, 228, 54},
    [12] = {41, 173, 255},   [13] = {131, 118, 156},  [14] = {255, 119, 168}, [15] = {255, 204, 170},
    [129]= {29, 43, 83},    [140]= {171, 82, 54}
}

function Utils.clamp(min, val, max)
    if val < min then return min end
    if val > max then return max end
    return val
end

-- Converte uma cor do índice PICO-8 para valores LÖVE
function Utils.setColor(index)
    local c = Utils.pico8_colors[index] or {255, 255, 255} -- Branco como padrão
    love.graphics.setColor(c[1]/255, c[2]/255, c[3]/255, 1)
    return c
end

function Utils.distance(a, b)
    return math.sqrt((a.x - b.x)^2 + (a.y - b.y)^2)
end

function Utils.findNearest(obj, list)
    local nearest = nil
    local min_dist = 9999 -- Um valor alto

    for _, item in ipairs(list) do
        local d = Utils.distance(obj, item)
        if d < min_dist then
            min_dist = d
            nearest = item
        end
    end
    return nearest
end

-- Verificação de colisão para caixas de 8x8 (tamanho padrão de sprite PICO-8)
function Utils.col(a, b)
    -- Pega as posições e tamanhos ajustados (ou usa o padrão se não tiver ajuste)
    local aX = a.x + (a.hitbox_off_x or 0)
    local aY = a.y + (a.hitbox_off_y or 0)
    local aW = a.hitbox_w or a.w or 0
    local aH = a.hitbox_h or a.h or 0

    local bX = b.x + (b.hitbox_off_x or 0)
    local bY = b.y + (b.hitbox_off_y or 0)
    local bW = b.hitbox_w or b.w or 0
    local bH = b.hitbox_h or b.h or 0

    -- Lógica padrão de colisão AABB
    return aX < bX + bW and
           bX < aX + aW and
           aY < bY + bH and
           bY < aY + aH
end

function Utils.safeText(str)
    if type(str) ~= "string" then return tostring(str) end

    -- Substitui bytes inválidos por "?", mas SEM quebrar acentos
    -- (é, ê, ã, ç...): eles são UTF-8 válido (2 bytes cada), só não
    -- são ASCII puro. O bug antigo aqui usava str:utf8len() — que não
    -- existe como método de string em Lua/LÖVE (o certo é a função
    -- utf8.len(str), da lib padrão "utf8") — então esse pcall sempre
    -- falhava e caía no gsub("[^%w%p%s]", "?"). Como %w/%p/%s em Lua
    -- só reconhecem bytes ASCII, cada acento (2 bytes) tinha os dois
    -- bytes trocados por "?" individualmente, virando "é" -> "??".
    --
    -- A correção: usar utf8.len para VALIDAR que a string é UTF-8 bem
    -- formado (nesse caso ela já pode ser devolvida como está, sem
    -- gsub nenhum — não há bytes inválidos pra trocar). Só cai no
    -- gsub ASCII-only se a string não for UTF-8 válido de verdade.
    local ok, len = pcall(utf8.len, str)
    if ok and len then
        return str
    end

    -- String não é UTF-8 válido (bytes realmente corrompidos/lixo):
    -- aí sim trocamos qualquer byte fora do intervalo seguro por "?".
    return (str:gsub("[^%w%p%s]", "?"))
end


function Utils.centerText(str, y, SafeTexto)
    local safe = SafeTexto or false
    local text = safe and Utils.safeText(str or "") or (str or "")

    -- Presume uma fonte de largura fixa por caractere (8px), como no
    -- PICO-8. IMPORTANTE: a largura tem que ser calculada em cima do
    -- MESMO texto que será desenhado (o já sanitizado, se safe==true)
    -- — usar #str (o original, antes do safeText) aqui desalinhava a
    -- centralização sempre que safeText mudava o comprimento da
    -- string. Também usamos utf8.len em vez de # pra contar
    -- CARACTERES visuais, não bytes (um acento é 1 caractere na tela,
    -- mesmo ocupando 2 bytes).
    local ok, char_count = pcall(utf8.len, text)
    if not ok or not char_count then char_count = #text end

    local text_width = char_count * 8
    local x = ((128 * 4) - text_width) / 2
    love.graphics.print(text, x, y)
end

return Utils