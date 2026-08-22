-- ============================================================
-- SURVIVAL MODE - 10 MINUTOS PARA SOBREVIVER
-- ============================================================
-- Sem lojas. Inimigos spawnam em intervalos de tempo fixos.
-- Moedas adiantam o timer de vitória.
-- ============================================================

local enemies_module = require("enemies")
local WaveSurvival = {}

-- ============================================================
-- CONFIGURAÇÃO DO SURVIVAL
-- ============================================================
WaveSurvival.TOTAL_DURATION     = 600  -- 10 minutos em segundos
WaveSurvival.SPAWN_INTERVAL     = 20   -- segundos entre ondas automáticas
WaveSurvival.COIN_TIME_ADVANCE  = 5    -- cada moeda avança 5 s no timer
WaveSurvival.SPAWN_WARNING_TIME = 6    -- pisca N segundos antes de spawnar

-- Estado do modo
WaveSurvival.active          = false
WaveSurvival.timer           = 0   -- de 0 até TOTAL_DURATION
WaveSurvival.wave_count      = 0   -- quantas ondas já foram spawnadas
WaveSurvival.spawn_timer     = 0   -- contador até a próxima onda
WaveSurvival.spawn_indicators = {} -- círculos vermelhos piscantes no mapa

-- Inimigos disponíveis (sem bosses)
local enemy_types = {
    "perseguidor", "atirador", "circulador", "bomb", "arma",
    "divisor", "teleportador", "horizontal", "paladino",
    "invocador", "vampiro"
}

local MAX_ENEMIES_PER_WAVE = 35

-- ============================================================
-- INICIAR MODO SURVIVAL
-- ============================================================
function WaveSurvival.start()
    WaveSurvival.active           = true
    WaveSurvival.timer            = 0
    WaveSurvival.wave_count       = 0
    WaveSurvival.spawn_timer      = 0
    WaveSurvival.spawn_indicators = {}

    enemies_module.reset()

    print("🏁 ===== SURVIVAL MODE INICIADO =====")
    print("⏱️  Objetivo: Sobreviva 10 minutos (600 segundos)")
    print("💰 Moedas adiantam " .. WaveSurvival.COIN_TIME_ADVANCE .. " segundos cada")
    print("📍 Inimigos piscam em círculo vermelho antes de aparecer")
    print("🚫 Sem lojas – ondas contínuas até o tempo acabar")
    print("=====================================")
end

-- ============================================================
-- PARAR SURVIVAL
-- ============================================================
function WaveSurvival.stop()
    WaveSurvival.active = false
end

-- ============================================================
-- INDICADOR DE SPAWN (círculo vermelho piscante)
-- ============================================================
function WaveSurvival.add_spawn_indicator(x, y, duration)
    table.insert(WaveSurvival.spawn_indicators, {
        x           = x,
        y           = y,
        radius      = 50,
        timer       = duration,
        max_timer   = duration,
        blink_speed = 0.15,
    })
end

-- ============================================================
-- ATUALIZAR INDICADORES
-- ============================================================
function WaveSurvival.update_indicators(dt)
    for i = #WaveSurvival.spawn_indicators, 1, -1 do
        local ind = WaveSurvival.spawn_indicators[i]
        ind.timer = ind.timer - dt
        if ind.timer <= 0 then
            table.remove(WaveSurvival.spawn_indicators, i)
        end
    end
end

-- ============================================================
-- DESENHAR INDICADORES
-- ============================================================
function WaveSurvival.draw_indicators()
    if not WaveSurvival.active then return end

    for _, ind in ipairs(WaveSurvival.spawn_indicators) do
        local blink = (ind.timer % (ind.blink_speed * 2)) / (ind.blink_speed * 2)
        local alpha = blink > 0.5 and 0.8 or 0.2

        love.graphics.setColor(1, 0, 0, alpha)
        love.graphics.circle("line", ind.x, ind.y, ind.radius)
        love.graphics.circle("line", ind.x, ind.y, ind.radius - 5)

        local percent_left = ind.timer / ind.max_timer
        love.graphics.setColor(1, 0.5, 0, alpha)
        love.graphics.arc("line", "pie", ind.x, ind.y, ind.radius + 10,
                          0, (1 - percent_left) * math.pi * 2)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

-- ============================================================
-- SPAWNAR UMA ONDA IMEDIATAMENTE (chamado internamente)
-- ============================================================
local function do_spawn_wave()
    WaveSurvival.wave_count = WaveSurvival.wave_count + 1
    local difficulty_mult   = 1 + (WaveSurvival.wave_count * 0.08)

    local spawn_x = math.random(60, 128 * 4 - 60)
    local spawn_y = math.random(40, 100)

    -- Indicador visual piscando
    WaveSurvival.add_spawn_indicator(spawn_x, spawn_y,
                                      WaveSurvival.SPAWN_WARNING_TIME)

    local quantidade = math.floor(2 + WaveSurvival.wave_count * 0.4)
                       * difficulty_mult
    quantidade = math.min(MAX_ENEMIES_PER_WAVE, math.floor(quantidade))

    for _ = 1, quantidade do
        local ox      = math.random(-70, 70)
        local oy      = math.random(-70, 70)
        local final_x = math.max(8, math.min(spawn_x + ox, 128 * 4 - 8))
        local final_y = math.max(8, math.min(spawn_y + oy, 128 * 2 - 8))
        local tipo    = enemy_types[math.random(#enemy_types)]
        enemies_module.spawn_enemy(tipo, final_x, final_y, nil)
    end

    print("🌊 Onda Survival #" .. WaveSurvival.wave_count
          .. " (" .. quantidade .. " inimigos) | Tempo: "
          .. string.format("%.1f", WaveSurvival.timer) .. "s")
end

-- ============================================================
-- ATUALIZAÇÃO PRINCIPAL
-- Retorna true quando o jogador vencer (timer >= TOTAL_DURATION)
-- ============================================================
function WaveSurvival.update(dt, player)
    if not WaveSurvival.active then return false end

    WaveSurvival.update_indicators(dt)

    WaveSurvival.timer       = WaveSurvival.timer       + dt
    WaveSurvival.spawn_timer = WaveSurvival.spawn_timer + dt

    -- --------------------------------------------------------
    -- VITÓRIA: completou 10 minutos
    -- --------------------------------------------------------
    if WaveSurvival.timer >= WaveSurvival.TOTAL_DURATION then
        print("🎉 ===== VITÓRIA! Você sobreviveu 10 minutos! =====")
        print("Ondas spawnadas: " .. WaveSurvival.wave_count)
        WaveSurvival.active = false
        return true
    end

    -- --------------------------------------------------------
    -- SPAWN POR TEMPO: a cada SPAWN_INTERVAL segundos
    -- --------------------------------------------------------
    if WaveSurvival.spawn_timer >= WaveSurvival.SPAWN_INTERVAL then
        do_spawn_wave()
        WaveSurvival.spawn_timer = 0
    end

    -- --------------------------------------------------------
    -- SPAWN POR CAMPO VAZIO: se não há inimigos vivos,
    -- spawna uma nova onda imediatamente (sem ir para a loja)
    -- --------------------------------------------------------
    local enemies = enemies_module.get_all()
    if #enemies == 0 and WaveSurvival.spawn_timer > 2 then
        -- Exige ao menos 2 s desde o último spawn para evitar
        -- duplo-spawn no mesmo frame
        print("⚡ Campo limpo – spawna onda antecipada!")
        do_spawn_wave()
        WaveSurvival.spawn_timer = 0
    end

    return false
end

-- ============================================================
-- AVANÇAR TEMPO (moeda coletada)
-- ============================================================
function WaveSurvival.advance_time(seconds)
    if not WaveSurvival.active then return end
    WaveSurvival.timer = math.max(0, WaveSurvival.timer - seconds)
    print("⏱️  Moeda coletada! -" .. seconds
          .. "s | Tempo restante: "
          .. (WaveSurvival.TOTAL_DURATION - WaveSurvival.timer) .. "s")
end

-- ============================================================
-- UTILITÁRIOS
-- ============================================================
function WaveSurvival.get_time_remaining()
    return math.max(0, WaveSurvival.TOTAL_DURATION - WaveSurvival.timer)
end

function WaveSurvival.get_progress()
    return math.min(1, WaveSurvival.timer / WaveSurvival.TOTAL_DURATION)
end

function WaveSurvival.get_time_formatted()
    local remaining = WaveSurvival.get_time_remaining()
    local mins = math.floor(remaining / 60)
    local secs = math.floor(remaining % 60)
    return string.format("%02d:%02d", mins, secs)
end

return WaveSurvival