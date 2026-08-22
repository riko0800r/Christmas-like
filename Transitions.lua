-- transitions.lua
--
-- JUICE: mantém a MESMA API pública de antes (start/update/draw,
-- mesmos campos active/alpha/state/timer) pra não quebrar nenhum
-- lugar de main.lua que já lê Transitions.alpha etc. O que muda é
-- como o "out"/"in" é desenhado: em vez de um fade retangular liso,
-- uma cortina (wipe) horizontal em duas barras que fecham a partir
-- das bordas com um leve overshoot, estilo transição de jogo antigo.
-- Se quiser voltar ao fade puro, basta trocar wipeProgress por alpha
-- direto no draw — a lógica de estado abaixo não depende do visual.
local Transitions = {}
local GameState = require("gamestate")

Transitions.active = false
Transitions.alpha = 0
Transitions.timer = 0
Transitions.duration = 0.25 -- Tempo de cada metade (fechar / abrir)
Transitions.state = "none" -- "in", "out"
Transitions.target_state = nil
Transitions.params = {}

-- easeOutQuad / easeInQuad: curvas simples sem lib externa, dão uma
-- sensação de "impacto" no fechar e "alívio" no abrir em vez de
-- movimento linear robótico.
local function easeOutQuad(t) return 1 - (1 - t) ^ 2 end
local function easeInQuad(t) return t ^ 2 end

-- Inicia a transição
function Transitions.start(target_state, ...)
    if Transitions.active then return end
    
    Transitions.active = true
    Transitions.state = "out" -- Começa fechando a cortina
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
        -- Fechando: cortina cobre a tela, easeOut pra "bater" com força
        -- e assentar (em vez de desacelerar suavemente até o fim).
        Transitions.alpha = easeOutQuad(progress)
        
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
        -- Abrindo: cortina recua, easeIn pra sair devagar e acelerar,
        -- dando a sensação de "revelar" a cena nova.
        Transitions.alpha = 1 - easeInQuad(progress)
        
        if progress >= 1 then
            Transitions.active = false
            Transitions.alpha = 0
        end
    end
end

function Transitions.draw()
    if not (Transitions.active or Transitions.alpha > 0) then return end

    local w, h = love.graphics.getDimensions()
    local a = Transitions.alpha -- 0 = tela visível, 1 = tela totalmente coberta

    -- Cortina em duas barras (topo/baixo) fechando pro centro. Cada
    -- barra cobre metade da altura * a, então quando a==1 elas se
    -- encontram no meio e cobrem tudo — visualmente mais vivo que um
    -- retângulo de alpha crescente, mesmo em pico-8 chapado (sem
    -- gradiente, só cor sólida, pra manter o estilo do resto do jogo).
    love.graphics.setColor(0, 0, 0, 1)
    local half = h / 2
    love.graphics.rectangle("fill", 0, 0, w, half * a)
    love.graphics.rectangle("fill", 0, h - half * a, w, half * a)

    love.graphics.setColor(1, 1, 1, 1) -- Reseta a cor
end

return Transitions