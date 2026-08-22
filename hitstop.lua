-- hitstop.lua
--
-- Controle central de "hitstop" (freeze curto de tempo pra dar peso a
-- um golpe/morte importante). Deliberadamente pequeno e sem estado
-- escondido: quem quer congelar o jogo chama Hitstop.trigger(duracao),
-- e quem roda o loop de update consulta Hitstop.getTimeScale() pra
-- saber por quanto multiplicar o dt daquele frame.
--
-- IMPORTANTE: Hitstop NÃO mexe em love.timer nem pausa o jogo sozinho
-- — ele só disponibiliza a escala. Isso é proposital: main.lua decide
-- o que continua rodando em tempo real durante o hitstop (ex: o corpo
-- do inimigo voando em 2.5D precisa continuar se movendo mesmo com o
-- resto do mundo congelado, senão o "voar" também trava).
--
-- Uso típico em main.lua:
--   local Hitstop = require("hitstop")
--   function love.update(dt)
--       Hitstop.update(dt) -- avança o timer interno com dt REAL
--       local scale = Hitstop.getTimeScale()
--       local game_dt = dt * scale
--       Enemies.update(game_dt, player)
--       player:update(game_dt, ...)
--       ...
--   end

local Hitstop = {}

local timer = 0        -- tempo restante de hitstop, em segundos
local duration = 0      -- duração total do hitstop atual (pra calcular progresso, se precisar)
local scale = 0.003      -- o quão "congelado" o jogo fica durante o hitstop (0 = parado
                         -- de vez; usamos um valor bem pequeno em vez de 0 puro pra
                         -- evitar dividir por zero em qualquer lugar que faça 1/dt)

-- Dispara um hitstop de `seconds` segundos. Se já houver um hitstop
-- ativo, o mais longo dos dois vence (não soma, não reinicia pra
-- baixo) — evita que múltiplas mortes simultâneas empilhem hitstops
-- absurdamente longos.
function Hitstop.trigger(seconds, opts)
    seconds = seconds or 0.08
    opts = opts or {}
    if seconds > timer then
        timer = seconds
        duration = seconds
    end
    if opts.scale then
        scale = opts.scale
    end
end

-- Avança o relógio interno do hitstop. DEVE receber o dt REAL (não
-- escalado), senão o hitstop nunca progride/acaba.
function Hitstop.update(real_dt)
    if timer > 0 then
        timer = math.max(0, timer - real_dt)
    end
end

-- Multiplicador a aplicar no dt do gameplay neste frame.
-- 1 = velocidade normal, valores pequenos = quase congelado.
function Hitstop.getTimeScale()
    if timer > 0 then
        return scale
    end
    return 1
end

function Hitstop.isActive()
    return timer > 0
end

-- 0..1, útil se algum efeito quiser saber "quão perto do fim" o
-- hitstop está (ex: pra um leve fade em algo).
function Hitstop.getProgress()
    if duration <= 0 then return 1 end
    return 1 - (timer / duration)
end

return Hitstop