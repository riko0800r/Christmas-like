-- transitions.lua
local Transitions = {}
local GameState = require("gamestate")

Transitions.active = false
Transitions.alpha = 0
Transitions.timer = 0
Transitions.duration = 0.25 -- Tempo do fade
Transitions.state = "none" -- "in", "out"
Transitions.target_state = nil
Transitions.params = {}

-- Inicia a transição
function Transitions.start(target_state, ...)
    if Transitions.active then return end
    
    Transitions.active = true
    Transitions.state = "out" -- Começa escurecendo a tela
    Transitions.alpha = 0
    Transitions.timer = 0
    Transitions.target_state = target_state
    Transitions.params = {...}
end

function Transitions.update(dt)
    if not Transitions.active then return end

    Transitions.timer = Transitions.timer + dt
    local progress = math.min(Transitions.timer / Transitions.duration, 1)

    if Transitions.state == "out" then
        -- Escurecendo (0 -> 1)
        Transitions.alpha = progress
        
        if progress >= 1 then
            -- Meio da transição: Troca a cena
            Transitions.state = "in"
            Transitions.timer = 0
            
            -- Chama a lógica original de troca de estado
            if _G.performSwitch then
                _G.performSwitch(Transitions.target_state, unpack(Transitions.params))
            end
        end
        
    elseif Transitions.state == "in" then
        -- Clareando (1 -> 0)
        Transitions.alpha = 1 - progress
        
        if progress >= 1 then
            Transitions.active = false
            Transitions.alpha = 0
        end
    end
end

function Transitions.draw()
    if Transitions.active or Transitions.alpha > 0 then
        local w, h = love.graphics.getDimensions()
        -- Desenha um retângulo preto sobre tudo
        love.graphics.setColor(0, 0, 0, Transitions.alpha)
        love.graphics.rectangle("fill", 0, 0, w, h)
        love.graphics.setColor(1, 1, 1, 1) -- Reseta a cor
    end
end

return Transitions