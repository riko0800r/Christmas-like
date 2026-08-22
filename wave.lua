-- wave.lua (OTIMIZADO)
local enemies_module = require("enemies")
local Waves = {}

-- ============================================================
-- CONSTANTES (Centralizadas para fácil manutenção)
-- ============================================================
local GAME_MODES = {
    EASY = 1,
    NORMAL = 2,
    HARD = 3,
    BOSS_RUSH = 4,
    INSANE = 5,
    IMPOSSIBLE = 6
}

local MODE_CONFIG = {
    [GAME_MODES.EASY] = {
        wave_final = 16,
        can_spawn_boss = false,
        boss_freq = 16
    },
    [GAME_MODES.NORMAL] = {
        wave_final = 16,
        can_spawn_boss = true,
        boss_freq = 8
    },
    [GAME_MODES.HARD] = {
        wave_final = 16,
        can_spawn_boss = true,
        boss_freq = 4
    },
    [GAME_MODES.BOSS_RUSH] = {
        wave_final = 16,
        can_spawn_boss = true,
        boss_freq = 1  -- TODOS são bosses
    },
    [GAME_MODES.INSANE] = {
        wave_final = 32,
        can_spawn_boss = true,
        boss_freq = 8
    },
    [GAME_MODES.IMPOSSIBLE] = {
        wave_final = 64,
        can_spawn_boss = true,
        boss_freq = 4
    }
}

Waves.current_wave = 1
Waves.timer = 0
Waves.wave_delay = 3
Waves.waiting_next = false
Waves.boss_alive = false
Waves.score = 0
Waves.active = false
Waves.infinito = false
Waves.wave_final = 16

-- Dificuldade/modo ATUAL da run (1=Fácil ... 6=Impossível), definida em
-- Waves.start(difficulty) e usada por todo o resto do módulo. Antes,
-- get_mode_config() lia a global "game_mode" — que em main.lua é uma
-- STRING ("classic"/"daily"/"seed", indicando a ORIGEM da run, não a
-- dificuldade) — então MODE_CONFIG[game_mode] nunca batia com nada e
-- sempre caía no fallback NORMAL (16 ondas), não importa o modo escolhido.
Waves.current_mode = GAME_MODES.NORMAL

local MAX_ENEMIES_PER_WAVE = 35

local enemy_types = {
    "perseguidor", "atirador", "circulador", "bomb", "arma",
    "divisor", "teleportador", "horizontal", "paladino",
    "invocador", "vampiro"
}

local boss_types = {
    "boss", "boss2", "boss3", "boss4", "boss5"
}

-- API PARA MODS: para adicionar um tipo de inimigo/boss novo às ondas normais,
-- um mod deve inserir o nome do tipo (string, batendo com uma chave de
-- enemies_module.presets) em Waves.enemy_types ou Waves.boss_types.
-- Waves.mode_config permite ajustar wave_final, boss_freq, etc. de cada modo.
Waves.enemy_types = enemy_types
Waves.boss_types = boss_types
Waves.mode_config = MODE_CONFIG
Waves.game_modes = GAME_MODES

-- ============================================================
-- FUNÇÃO AUXILIAR: Obter configuração do modo
-- ============================================================
local function get_mode_config(mode)
    return MODE_CONFIG[mode] or MODE_CONFIG[GAME_MODES.NORMAL]
end

-- ============================================================
-- INICIALIZAÇÃO DO JOGO
-- ============================================================
function Waves.start(mode, difficulty)
    -- Aceita tanto Waves.start(difficulty) quanto o antigo
    -- Waves.start(game_mode_string, difficulty) de main.lua — nesse
    -- segundo caso o valor que importa pra config de ondas é o
    -- SEGUNDO argumento (difficulty numérica 1-6), não o primeiro.
    local chosen_mode = difficulty or mode
    Waves.current_mode = chosen_mode or GAME_MODES.NORMAL

    local config = get_mode_config(Waves.current_mode)

    Waves.infinito = false
    Waves.current_wave = 1
    Waves.score = 0
    Waves.waiting_next = false
    Waves.boss_alive = false
    Waves.active = true
    Waves.wave_final = config.wave_final

    enemies_module.reset()
    Waves.spawn_wave()

    if _G.ModAPI then
        _G.ModAPI.trigger("game_start")
        _G.ModAPI.trigger("wave_start", Waves.current_wave)
    end
end

function Waves.enable_infinite_mode()
    Waves.infinito = true
end

-- ============================================================
-- ATUALIZAÇÃO PRINCIPAL
-- ============================================================
function Waves.update(dt, player)
    if not Waves.active then return end

    local enemies = enemies_module.get_all()
    local num_enemies = #enemies

    if num_enemies == 0 and not Waves.waiting_next then
        Waves.waiting_next = true
        Waves.timer = 0
        _G.SFX_Pickup_Heart:play()

        if player and player.onWaveEnd then player:onWaveEnd() end
    end
end

-- ============================================================
-- PRÓXIMA ONDA
-- ============================================================
function Waves.next_wave(player)
    if not Waves.active then return end

    local config = get_mode_config(Waves.current_mode)

    if Waves.infinito or Waves.current_wave < Waves.wave_final then
        Waves.current_wave = Waves.current_wave + 1
        Waves.waiting_next = false
        player.x = 128 * 2
        player.y = 128

        local is_boss_wave = config.can_spawn_boss and (Waves.current_wave % config.boss_freq == 0)

        if is_boss_wave then
            Waves.spawn_boss()
        else
            Waves.spawn_wave()
        end

        if _G.ModAPI then _G.ModAPI.trigger("wave_start", Waves.current_wave) end
    else
        Waves.active = false
    end
end

-- ============================================================
-- SPAWN WAVE (OTIMIZADO - Sem repetição)
-- ============================================================
function Waves.spawn_wave()
    local config = get_mode_config(Waves.current_mode)

    -- Cálculo com limite máximo
    local quantidade
    if Waves.infinito then
        local base_calc = math.floor(1 + Waves.current_wave * 1.25 + (Waves.current_wave / 10) ^ 1.5)
        quantidade = math.min(MAX_ENEMIES_PER_WAVE, base_calc)
    else
        local base_calc = math.floor(1 + Waves.current_wave * 1.25)
        quantidade = math.min(MAX_ENEMIES_PER_WAVE, base_calc)
    end

    local available_enemies = (Waves.current_mode == GAME_MODES.EASY)
        and {"perseguidor", "divisor", "horizontal"}
        or enemy_types

    for i = 1, quantidade do
        local tipo = available_enemies[math.random(#available_enemies)]
        local x = math.random(8, 128*4 - 8)
        local y = math.random(8, 32)
        enemies_module.spawn_enemy(tipo, x, y, Waves)
    end
end

-- ============================================================
-- SPAWN BOSS
-- ============================================================
function Waves.spawn_boss()
    local config = get_mode_config(Waves.current_mode)

    if not config.can_spawn_boss then return end

    local boss = boss_types[math.random(#boss_types)]
    Waves.boss_alive = true

    if Waves.infinito and Waves.current_wave > 20 then
        local num_bosses = math.min(3, math.floor(Waves.current_wave / 20))
        for i = 1, num_bosses do
            local boss_type = boss_types[math.random(#boss_types)]
            local x = math.random(32, 128*4 - 32)
            local y = math.random(32, 64)
            enemies_module.spawn_enemy(boss_type, x, y, Waves)
        end
    else
        enemies_module.spawn_enemy(boss, 128*2, 32, Waves)
    end
end

function Waves.boss_defeated()
    Waves.boss_alive = false
end

-- ============================================================
-- UTILITÁRIOS
-- ============================================================
function Waves.get_mode_info()
    if Waves.infinito then
        return "INFINITO", "∞"
    else
        return "NORMAL", Waves.wave_final
    end
end

function Waves.get_max_enemies()
    return MAX_ENEMIES_PER_WAVE
end

return Waves