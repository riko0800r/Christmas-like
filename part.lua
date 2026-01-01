local utils = require "utils"
local Particles = {}
Particles.list = {}

-- Cria uma nova partícula
function Particles.add(x, y, amount, color_id)
    for i = 1, amount do
        local p = {
            x = x,
            y = y,
            dx = (math.random() - 0.5) * 2,  -- direção aleatória
            dy = (math.random() - 0.5) * 2,
            life = math.random(60*2,60*4.25),      -- duração em frames
            size = math.random(1, 2),
            color = color_id or 7,           -- cor padrão (branco)
            alpha = 1
        }
        table.insert(Particles.list, p)
    end
end

-- Atualiza todas as partículas
function Particles.update()
    for i = #Particles.list, 1, -1 do
        local p = Particles.list[i]
        p.x = p.x + p.dx
        p.y = p.y + p.dy
        p.dy = p.dy + 0.05                 -- leve gravidade
        p.life = p.life - 1
        p.alpha = math.max(0, p.life / 50) -- fade out

        if p.life <= 0 then
            table.remove(Particles.list, i)
        end
    end
end

-- Desenha todas as partículas
function Particles.draw()
    for _, p in ipairs(Particles.list) do
        utils.setColor(p.color)
        love.graphics.rectangle("fill", p.x, p.y, p.size, p.size)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

-- Reseta o sistema
function Particles.reset()
    Particles.list = {}
end

return Particles