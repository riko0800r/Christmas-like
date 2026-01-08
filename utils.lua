-- utils.lua
local Utils = {}

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
    -- Substitui bytes inválidos por "?"
    local ok, clean = pcall(function()
        return str:utf8len() and str or str:gsub("[^%w%p%s]", "?")
    end)
    if ok then
        return clean
    else
        -- se utf8len falhar, remove caracteres não ASCII
        return (str:gsub("[^%w%p%s]", "?"))
    end
end


function Utils.centerText(str, y,SafeTexto)
    local Safe=SafeTexto or false
    -- Presume uma fonte de 4px de largura, como no PICO-8
    if Safe==true then
        text = Utils.safeText(str or "")
    else
        text = str
    end
    local text_width = #str * 8
    local x = ((128*4) - text_width) / 2
    love.graphics.print(text, x,y)
end

return Utils