-- achievements.lua
-- Sistema de conquistas do Christmas-like.
--
-- Diferente do exemplo original (que checava tudo a cada frame, olhando
-- `pl`/`stats` globais de outro jogo), aqui as conquistas são resolvidas
-- por EVENTOS pontuais: Achievements.on("enemy_death", ...) é chamado a
-- partir dos lugares do código onde a coisa realmente acontece (inimigo
-- morre, onda termina, item é comprado, run é vencida, etc). Isso evita
-- varrer todas as conquistas 60x/segundo e deixa claro de onde cada
-- desbloqueio vem.
--
-- Progresso agregado (contadores globais, tipo "monstros mortos no
-- total") fica em Save.data.achievements.stats e é somado a cada evento;
-- as condições de desbloqueio consultam esses contadores.

local Achievements = {}

-- Lista de todas as conquistas. `unlocks_character` (opcional) referencia
-- o `id` em Characters.list que essa conquista libera.
Achievements.list = {
    -- === PROGRESSO NA RUN ===
    {
        id = "first_wave_clear",
        name_key = "ach_first_wave_name",
        desc_key = "ach_first_wave_desc",
    },
    {
        id = "reach_wave_10",
        name_key = "ach_wave10_name",
        desc_key = "ach_wave10_desc",
    },
    {
        id = "reach_wave_20",
        name_key = "ach_wave20_name",
        desc_key = "ach_wave20_desc",
        unlocks_character = "poison",
    },
    {
        id = "infinite_mode",
        name_key = "ach_infinite_name",
        desc_key = "ach_infinite_desc",
        unlocks_character = "fire",
    },

    -- === VITÓRIAS ===
    {
        id = "first_victory",
        name_key = "ach_first_victory_name",
        desc_key = "ach_first_victory_desc",
        unlocks_character = "vital",
    },
    {
        id = "five_victories",
        name_key = "ach_five_victories_name",
        desc_key = "ach_five_victories_desc",
        unlocks_character = "ice",
    },
    {
        id = "no_damage_victory",
        name_key = "ach_no_damage_name",
        desc_key = "ach_no_damage_desc",
        unlocks_character = "estrela",
    },

    -- === COMBATE ===
    {
        id = "kill_100",
        name_key = "ach_kill100_name",
        desc_key = "ach_kill100_desc",
    },
    {
        id = "kill_1000",
        name_key = "ach_kill1000_name",
        desc_key = "ach_kill1000_desc",
        unlocks_character = "rock",
    },
    {
        id = "kill_boss",
        name_key = "ach_killboss_name",
        desc_key = "ach_killboss_desc",
    },
    {
        id = "damage_1000_run",
        name_key = "ach_dmg1000_name",
        desc_key = "ach_dmg1000_desc",
        unlocks_character = "lava",
    },

    -- === ECONOMIA ===
    {
        id = "gold_500_run",
        name_key = "ach_gold500_name",
        desc_key = "ach_gold500_desc",
    },
    {
        id = "gold_total_1000",
        name_key = "ach_goldtotal_name",
        desc_key = "ach_goldtotal_desc",
        unlocks_character = "Atirador",
    },
    {
        id = "buy_10_items",
        name_key = "ach_buy10_name",
        desc_key = "ach_buy10_desc",
        unlocks_character = "Tree",
    },

    -- === RELÍQUIAS ===
    {
        id = "collect_3_relics",
        name_key = "ach_relics3_name",
        desc_key = "ach_relics3_desc",
    },
    {
        id = "collect_all_relics",
        name_key = "ach_relicsall_name",
        desc_key = "ach_relicsall_desc",
        unlocks_character = "Gift2",
    },

    -- === ESPECIAIS ===
    {
        id = "daily_run",
        name_key = "ach_daily_name",
        desc_key = "ach_daily_desc",
        unlocks_character = "gift",
    },
    {
        id = "reach_wave_30",
        name_key = "ach_wave30_name",
        desc_key = "ach_wave30_desc",
        unlocks_character = "mystery",
    },
}

-- Índice rápido por id
local by_id = {}
for _, ach in ipairs(Achievements.list) do
    by_id[ach.id] = ach
end

-- Referência ao save; setada em Achievements.init(save_module) pra evitar
-- dependência circular (save.lua também usa achievements.lua).
local Save = nil

local function ensureSaveShape()
    if not Save then return end
    Save.data.achievements = Save.data.achievements or {}
    Save.data.achievements.unlocked = Save.data.achievements.unlocked or {}
    Save.data.achievements.unlocked_at = Save.data.achievements.unlocked_at or {}
    Save.data.achievements.stats = Save.data.achievements.stats or {
        total_kills = 0,
        total_gold_earned = 0,
        total_items_bought = 0,
        bosses_killed = 0,
        victories = 0,
    }
end

function Achievements.init(save_module)
    Save = save_module
    ensureSaveShape()
end

function Achievements.isUnlocked(id)
    if _G.DEBUG_UNLOCK_ALL then return true end
    ensureSaveShape()
    return Save and Save.data.achievements.unlocked[id] == true
end

function Achievements.getAll()
    return Achievements.list
end

function Achievements.get(id)
    return by_id[id]
end

-- Callback opcional pra UI mostrar um "toast" de conquista desbloqueada.
-- main.lua pode sobrescrever: Achievements.on_unlock = function(ach) ... end
Achievements.on_unlock = nil

-- achievements.lua (trecho)
local function unlock(id)
    if Achievements.isUnlocked(id) then return false end
    local ach = by_id[id]
    if not ach then return false end

    ensureSaveShape()
    Save.data.achievements.unlocked[id] = true
    Save.data.achievements.unlocked_at[id] = os.time()
    Save.write()

    -- Libera o personagem associado, se houver
    if ach.unlocks_character then
        local Characters = require("characters")
        Characters.unlock(ach.unlocks_character)
    end

    if Achievements.on_unlock then
        Achievements.on_unlock(ach)
    end

    return true
end
Achievements.unlock = unlock

-- Soma em um contador persistente de Save.data.achievements.stats
local function addStat(key, amount)
    ensureSaveShape()
    local stats = Save.data.achievements.stats
    stats[key] = (stats[key] or 0) + (amount or 1)
    return stats[key]
end

-- =============================================================
--   EVENTOS — chamados a partir do código do jogo (não a cada frame)
-- =============================================================

-- Chamado quando um inimigo morre. `enemy` é a entidade; `is_boss_flag`
-- indica se era um chefe.
function Achievements.on_enemy_death(enemy, is_boss_flag)
    local total = addStat("total_kills", 1)

    if total >= 100 then unlock("kill_100") end
    if total >= 1000 then unlock("kill_1000") end

    if is_boss_flag then
        addStat("bosses_killed", 1)
        unlock("kill_boss")
    end
end

-- Chamado quando uma onda termina (Wave.next_wave / fim de onda).
function Achievements.on_wave_cleared(wave_number)
    if wave_number and wave_number >= 1 then
        unlock("first_wave_clear")
    end
    if wave_number and wave_number >= 10 then
        unlock("reach_wave_10")
    end
    if wave_number and wave_number >= 20 then
        unlock("reach_wave_20")
    end
    if wave_number and wave_number >= 30 then
        unlock("reach_wave_30")
    end
end

-- Chamado quando o modo infinito é ativado.
function Achievements.on_infinite_mode_enabled()
    unlock("infinite_mode")
end

-- Chamado quando uma run termina em vitória.
-- `p` é o player; `took_damage` indica se ele sofreu dano na run.
function Achievements.on_victory(p, took_damage)
    unlock("first_victory")

    local victories = addStat("victories", 1)
    if victories >= 5 then
        unlock("five_victories")
    end

    if not took_damage then
        unlock("no_damage_victory")
    end

    if p and p.stats and (p.stats.total_damage or 0) >= 1000 then
        unlock("damage_1000_run")
    end

    if p and (p.money or 0) >= 500 then
        unlock("gold_500_run")
    end

    Achievements.checkRelics(p)
end

-- Chamado sempre que ouro é ganho (moeda coletada), pra manter o total
-- histórico. `amount` é quanto foi ganho agora.
function Achievements.on_gold_earned(amount)
    local total = addStat("total_gold_earned", amount or 0)
    if total >= 1000 then
        unlock("gold_total_1000")
    end
end

-- Chamado quando o jogador compra um item/relíquia na loja de recompensas.
function Achievements.on_item_bought(p)
    local total = addStat("total_items_bought", 1)
    if total >= 10 then
        unlock("buy_10_items")
    end
    Achievements.checkRelics(p)
end

-- Checa quantas relíquias o jogador tem (player.relics é um mapa de
-- flags, não uma lista — por isso contamos manualmente).
local ALL_RELIC_IDS = { "Greed", "Coin Magnet", "Sorte Dourada", "Boots", "Glass" }
function Achievements.checkRelics(p)
    if not p or not p.relics then return end
    local count = 0
    for _ in pairs(p.relics) do
        count = count + 1
    end
    if count >= 3 then
        unlock("collect_3_relics")
    end
    if count >= #ALL_RELIC_IDS then
        unlock("collect_all_relics")
    end
end

-- Chamado ao iniciar uma run no modo "daily".
function Achievements.on_daily_run_started()
    unlock("daily_run")
end

-- Porcentagem de conquistas completas (0-100)
function Achievements.getPercentage()
    if _G.DEBUG_UNLOCK_ALL then return 100 end
    ensureSaveShape()
    local total = #Achievements.list
    if total == 0 then return 0 end
    local done = 0
    for id, _ in pairs(Save.data.achievements.unlocked) do
        if by_id[id] then done = done + 1 end
    end
    return (done / total) * 100
end

return Achievements