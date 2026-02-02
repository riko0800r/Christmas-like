-- rewards.lua
local Utils   = require('utils')
local Buttons = require("button")
local part    = require("part_rewards")
local Lang    = require('lang') -- <<<

local addpart = part.spawn

local Rewards = {}
Rewards.slots = {}
Rewards.reroll_cost = 10
Rewards.free_claimed = false
Rewards.selected_index = 1
Rewards.current_rewards = {}

local presente=love.graphics.newImage("assets/Presente.png")
local Lava=love.graphics.newImage("assets/Lava.png")
local neve=love.graphics.newImage("assets/neve.png")
local pedras=love.graphics.newImage("assets/pedra.png")
local sombriosSprite=love.graphics.newImage("assets/PreciosaICON.png")
local VenenoSprite=love.graphics.newImage("assets/VenenoMortal.png")
local Vida=love.graphics.newImage("assets/VidaICON.png")
local Forca=love.graphics.newImage("assets/ForcaICON.png")
local Rapidez=love.graphics.newImage("assets/RapidezICON.png")
local Fogo=love.graphics.newImage("assets/FogoICON.png")
local Gelo=love.graphics.newImage("assets/GeloICON.png")
local Vitalidade=love.graphics.newImage("assets/VitalidadeICON.png")
local Imobilizador=love.graphics.newImage("assets/ImobilizadorICON.png")
local NovosItens=love.graphics.newImage("assets/NovosItensICON.png")
local LifestealIcon = love.graphics.newImage("assets/VidaICON.png") -- Use o ícone de vida

local upgrades = {
    {
        id = "Vida",
        get_name = function() return Lang.text("item_life") end, 
        effect = function(p) p.lifes = p.lifes + 4; p.max_life = p.max_life + 4 end, 
        get_desc = function() return Lang.text("item_life_desc") end, 
        get_desc2 = function(p) 
            local current = p.max_life
            local next_val = current + 4
            return Lang.text("item_life_stat", (p.item_levels["Vida"] or 0), current, next_val)
        end,
        price=5,
        weight = 25,
        icon=Vida,
    },
    {
        id = "Força",
        get_name = function() return Lang.text("item_str") end,
        effect = function(p) p.demage = p.demage + 0.4 end, 
        get_desc = function() return Lang.text("item_str_desc") end, 
        get_desc2 = function(p) 
            local current = p.demage
            local next_val = current + 0.4
            local level = (p.item_levels["Força"] or 0)
            return Lang.text("item_str_stat", level, current, next_val)
        end, 
        price = 5, -- Grátis se aparecer no slot grátis
        type = "upgrade",
        weight = 25,
        icon=Forca,
    },
    {
        id = "Rapidez", 
        get_name = function() return Lang.text("item_spd") end,
        effect = function(p) p.speed = p.speed + 0.75 end, 
        get_desc = function() return Lang.text("item_spd_desc") end, 
        get_desc2 = function(p) 
            local current = p.speed
            local next_val = current + 0.75
            local level = (p.item_levels["Rapidez"] or 0)
            return Lang.text("item_spd_stat", level, current, next_val)
        end, 
        price = 5, -- Grátis se aparecer no slot grátis
        type = "upgrade",
        weight = 25,
        icon=Rapidez,
    },
    {
        id = "Bola de neve", 
        get_name = function() return Lang.text("item_snow") end,
        effect = function(p) 
            p.tiro = true
            if p.tiro_max_time > 1 then p.tiro_max_time = p.tiro_max_time - 0.15 end
            p.demage = p.demage + 0.15
            p.bala_speed = p.bala_speed + 0.25
        end, 
        get_desc = function() return Lang.text("item_snow_desc") end, 
        get_desc2 = function(p) 
            local current_dmg = p.demage
            local next_dmg = current_dmg + 0.15
            local current_cd = p.tiro_max_time
            local next_cd = math.max(1, current_cd - 0.15)
            local level = (p.item_levels["Bola de neve"] or 0)
            return Lang.text("item_snow_stat", level, current_dmg, next_dmg, current_cd, next_cd)
        end, 
        price = 5, -- Grátis se aparecer no slot grátis
        type = "upgrade",
        weight = 20,
        icon=neve,
    },
    {
        id = "Bloco de gelo",
        get_name = function() return Lang.text("item_ice") end,
        effect = function(p) 
            p.roda = true
            if p.roda_max_time > 1.3 then p.roda_max_time = p.roda_max_time - 0.15 end
            p.demage = p.demage + 0.15
        end, 
        get_desc = function() return Lang.text("item_ice_desc") end, 
        get_desc2 = function(p) 
            local current_dmg = p.demage
            local next_dmg = current_dmg + 0.15
            local current_cd = p.roda_max_time
            local next_cd = math.max(1.3, current_cd - 0.15)
            local level = (p.item_levels["Bloco de gelo"] or 0)
            return Lang.text("item_ice_stat", level, current_dmg, next_dmg, current_cd, next_cd)
        end,
        price = 5, -- Grátis se aparecer no slot grátis
        type = "upgrade",
        weight = 20,
        icon=Gelo,
    },
    {
        id = "Pedras do ceu", 
        get_name = function() return Lang.text("item_rock") end,
        effect = function(p) 
            p.pedra = true
            if p.pedra_max_time > 0.5 then p.pedra_max_time = p.pedra_max_time - 0.1 end
            p.demage = p.demage + 0.15
        end, 
        get_desc = function() return Lang.text("item_rock_desc") end, 
        get_desc2 = function(p) 
            local current_dmg = p.demage * 3
            local next_dmg = (p.demage + 0.15) * 3
            local current_cd = p.pedra_max_time
            local next_cd = math.max(0.5, current_cd - 0.1)
            local level = (p.item_levels["Pedras do ceu"] or 0)
            return Lang.text("item_rock_stat", level, current_dmg, next_dmg, current_cd, next_cd)
        end, 
        price = 5, -- Grátis se aparecer no slot grátis
        type = "upgrade",
        weight = 20,
        icon=pedras,
    },
    {
        id = "Veneno mortal", 
        get_name = function() return Lang.text("item_psn") end,
        effect = function(p) 
            p.veneno = true
            if p.veneno_delay > 0.33 then p.veneno_delay = p.veneno_delay - 0.04 end
            p.veneno_dano = p.veneno_dano + 0.15
        end, 
        get_desc = function() return Lang.text("item_psn_desc") end, 
        get_desc2 = function(p) 
            local current_dmg = p.veneno_dano
            local next_dmg = current_dmg + 0.15
            local current_delay = p.veneno_delay
            local next_delay = math.max(0.33, current_delay - 0.04)
            local level = (p.item_levels["Veneno mortal"] or 0)
            return Lang.text("item_psn_stat", level, current_dmg, next_dmg, current_delay, next_delay)
        end, 
        price=5,
        weight = 10,
        icon=VenenoSprite,
    },
    {
        id = "Fogo perigoso", 
        get_name = function() return Lang.text("item_fire") end,
        effect = function(p) 
            p.fogo = true
            if p.fogo_delay >= 0.66 then p.fogo_delay = p.fogo_delay - 0.04 end
            p.fogo_dano = p.fogo_dano + 0.15
        end, 
        get_desc = function() return Lang.text("item_fire_desc") end, 
        get_desc2 = function(p) 
            local current_dmg = p.fogo_dano
            local next_dmg = current_dmg + 0.15
            local current_delay = p.fogo_delay
            local next_delay = math.max(0.66, current_delay - 0.04)
            local level = (p.item_levels["Fogo perigoso"] or 0)
            return Lang.text("item_fire_stat", level, current_dmg, next_dmg, current_delay, next_delay)
        end,
        price = 5, -- Grátis se aparecer no slot grátis
        type = "upgrade",
        weight = 10,
        icon=Fogo,
    },
    {
        id = "Imobilizador", 
        get_name = function() return Lang.text("item_frz") end,
        effect = function(p) 
            p.gelo = true
            if p.gelo_delay > 1 then p.gelo_delay = p.gelo_delay - 0.1 end
            p.gelo_dano = p.gelo_dano + 0.1
            p.gelo_slow = math.min(0.9, (p.gelo_slow or 0.5) + 0.05)
        end, 
        get_desc = function() return Lang.text("item_frz_desc") end, 
        get_desc2 = function(p) 
            local current_slow = (p.gelo_slow or 0.25) * 100
            local next_slow = math.min(90, current_slow + 5)
            local current_delay = p.gelo_delay
            local next_delay = math.max(0.5, current_delay - 0.04)
            local level = (p.item_levels["Imobilizador"] or 0)
            return Lang.text("item_frz_stat", level, current_slow, next_slow, current_delay, next_delay)
        end,
        price = 5, -- Grátis se aparecer no slot grátis
        type = "upgrade",
        weight = 10,
        icon=Imobilizador,
    },
    {
        id = "Vitalidade", 
        get_name = function() return Lang.text("item_vit") end,
        effect = function(p) 
            p.regen = true
            -- Aumenta 1 de vida por nível (já que é só por rodada, +0.5 seria pouco)
            p.vidas_por_rodada = (p.vidas_por_rodada or 0) + 1
        end, 
        get_desc = function() return Lang.text("item_vit_desc") end, 
        get_desc2 = function(p) 
            local current_heal = p.vidas_por_rodada or 0
            local next_heal = current_heal + 1
            local level = (p.item_levels["Vitalidade"] or 0)
            -- Atualizado para usar a nova string de stats
            return Lang.text("item_vit_stat", level, current_heal, next_heal)
        end,
        price = 5, -- Grátis se aparecer no slot grátis
        type = "upgrade",
        weight = 10,
        icon=Vitalidade,
    },
    {
        id = "Anel de Lava", 
        get_name = function() return Lang.text("item_lava") end,
        effect = function(p) 
            p.anel_ativo = true
            p.anel_pontos = p.anel_pontos + 1
            p.anel_velocidade = p.anel_velocidade + 0.1
            p.anel_dano = p.anel_dano + 0.15
        end, 
        get_desc = function() return Lang.text("item_lava_desc") end, 
        get_desc2 = function(p) 
            local current_dmg = p.anel_dano
            local next_dmg = current_dmg + 0.15
            local current_qty = p.anel_pontos
            local next_qty = current_qty + 1
            local level = (p.item_levels["Anel de Lava"] or 0)
            return Lang.text("item_lava_stat", level, current_qty, next_qty, current_dmg, next_dmg)
        end,
        price = 5, -- Grátis se aparecer no slot grátis
        type = "upgrade",
        weight = 20,
        icon=Lava,
    },
    {
        id = "Pedras Preciosas", 
        get_name = function() return Lang.text("item_gem") end,
        effect = function(p) 
            p.sombrio_ativo = true
            if p.sombrio_delay > 0.5 then p.sombrio_delay = p.sombrio_delay - 0.2 end
            p.demage = p.demage + 0.15
            p.sombrio_quantidade = (p.sombrio_quantidade or 3) + 1
        end, 
        get_desc = function() return Lang.text("item_gem_desc") end, 
        get_desc2 = function(p) 
            local current_dmg = p.demage * 0.5
            local next_dmg = (p.demage + 0.15) * 0.5
            local current_qty = p.sombrio_quantidade or 12
            local next_qty = current_qty + 2
            local current_cd = p.sombrio_delay
            local next_cd = math.max(0.5, current_cd - 0.2)
            local level = (p.item_levels["Pedras Preciosas"] or 0)
            return Lang.text("item_gem_stat", level, current_qty, next_qty, current_dmg, next_dmg, current_cd, next_cd)
        end,
        price = 5, -- Grátis se aparecer no slot grátis
        type = "upgrade",
        weight = 20,
        icon=sombriosSprite,
    },
    {
        id = "Espada triângular",
        get_name = function() return Lang.text("item_sword") end,
        effect = function(p) 
            p.triangle = true
            if p.triangle_max_time > 0.5 then p.triangle_max_time = p.triangle_max_time - 0.2 end
            p.demage = p.demage + 0.15
        end, 
        get_desc = function() return Lang.text("item_sword_desc") end, 
        get_desc2 = function(p) 
            local current_dmg = p.demage
            local next_dmg = (p.demage + 0.15)
            local current_cd = p.sombrio_delay
            local next_cd = math.max(0.5, current_cd - 0.2)
            local level = (p.item_levels["Espada triângular"] or 0)
            return Lang.text("item_sword_stat", level, current_dmg, next_dmg, current_cd, next_cd)
        end,
        price = 5, -- Grátis se aparecer no slot grátis
        type = "upgrade",
        weight = 0
    },
    {
        id = "Guirlanda", -- Use esse ID para verificar no item_levels
        get_name = function() return Lang.text("item_garlic") end,
        effect = function(p) 
            p.guirlanda = true
            p.guirlanda_raio = p.guirlanda_raio + 6 -- Aumenta o raio a cada nivel
            p.guirlanda_dano = p.guirlanda_dano + 0.15
        end, 
        get_desc = function() return Lang.text("item_garlic_desc") end, 
        get_desc2 = function(p) 
            return Lang.text("item_garlic_stat", (p.item_levels["Guirlanda"] or 0), p.guirlanda_raio, p.guirlanda_dano)
        end,
        price = 5, -- Grátis se aparecer no slot grátis
        type = "upgrade",
        weight = 20,
        icon = love.graphics.newImage("assets/GuirlandaICON.png"),
    },
    {
        id = "Bumerangue",
        get_name = function() return Lang.text("item_boom") end,
        effect = function(p) 
            p.bumerangue = true
            if p.bumerangue_delay > 0.5 then p.bumerangue_delay = p.bumerangue_delay - 0.25 end
            p.demage = p.demage + 0.25
        end, 
        get_desc = function() return Lang.text("item_boom_desc") end, 
        get_desc2 = function(p) 
            return Lang.text("item_boom_stat", (p.item_levels["Bumerangue"] or 0), p.bumerangue_delay)
        end,
        price = 5, -- Grátis se aparecer no slot grátis
        type = "upgrade",
        weight = 20,
        icon = love.graphics.newImage("assets/BumerangICON.png"),
    },
{
        id = "Roubo de vida", -- Deve ser igual ao nome em player.lua
        get_name = function() return Lang.text("item_lifesteal") end,
        effect = function(p) 
            -- Aumenta a chance em 4% (0.04) a cada nível
            p.lifesteal_chance = (p.lifesteal_chance or 0) + 0.15
        end, 
        get_desc = function() return Lang.text("item_lifesteal_desc") end, 
        get_desc2 = function(p) 
            local current = (p.lifesteal_chance or 0) * 100
            local next_val = current + 15
            local level = (p.item_levels["Drenagem Natalina"] or 0)
            return Lang.text("item_lifesteal_stat", level, current, next_val)
        end,
        price = 5, -- Grátis se aparecer no slot grátis
        type = "upgrade",
        weight = 0, -- Raridade (quanto menor, mais raro)
        icon = love.graphics.newImage("assets/VidaICON.png"), -- Reusando icone de vida
    },
    {
    id = "Estrelas Natalinas",
        get_name = function() return Lang.text("item_star_name") end,
        get_desc = function() return Lang.text("item_star_desc") end,
        get_desc2 = function(p) 
            return Lang.text("item_star_stat", (p.item_levels["Estrelas Natalinas"] or 0), p.estrelas_count)
        end,
        effect = function(p)
            p.estrelas_natalinas = true
            p.estrelas_count = (p.estrelas_count or 0) + 1 -- Aumenta o número de estrelas por nível
        end,
        price = 5, -- Grátis se aparecer no slot grátis
        type = "upgrade",
        weight = 20, -- Raridade (quanto menor, mais raro)
        icon = love.graphics.newImage("assets/EstrelaICON.png"),
    },
    -- 🆕 NOVOS ITENS ADICIONADOS
    {
        id = "Precisão Mortal",
        get_name = function() return "Precisão Mortal" end,
        effect = function(p) 
            p.crit_chance = (p.crit_chance or 0) + 0.05
            p.crit_damage = (p.crit_damage or 1.5) + 0.25
        end, 
        get_desc = function() return "Aumenta chance e dano de acertos críticos" end, 
        get_desc2 = function(p) 
            local current_chance = ((p.crit_chance or 0) * 100)
            local next_chance = current_chance + 5
            local current_dmg = ((p.crit_damage or 1.5) - 1) * 100
            local next_dmg = current_dmg + 25
            local level = (p.item_levels["Precisão Mortal"] or 0)
            return string.format("Nível %d | Crítico: %.0f%% → %.0f%% | Dano: +%.0f%% → +%.0f%%", 
                level, current_chance, next_chance, current_dmg, next_dmg)
        end,
        price = 5,
        type = "upgrade",
        weight = 8,
        icon = love.graphics.newImage("assets/sprite5.png"),
    },
    {
        id = "Velocidade de Ataque",
        get_name = function() return "Velocidade de Ataque" end,
        effect = function(p) 
            local reduction = 0.95
            if p.tiro then p.tiro_max_time = p.tiro_max_time * reduction end
            if p.roda then p.roda_max_time = p.roda_max_time * reduction end
            if p.pedra then p.pedra_max_time = p.pedra_max_time * reduction end
            if p.veneno then p.veneno_delay = p.veneno_delay * reduction end
            if p.fogo then p.fogo_delay = p.fogo_delay * reduction end
            if p.gelo then p.gelo_delay = p.gelo_delay * reduction end
            if p.bumerangue then p.bumerangue_delay = p.bumerangue_delay * reduction end
            p.attack_speed_mult = (p.attack_speed_mult or 1.0) * reduction
        end, 
        get_desc = function() return "Reduz o tempo de recarga de TODOS os ataques" end, 
        get_desc2 = function(p) 
            local current_mult = ((p.attack_speed_mult or 1.0) - 1) * -100
            local next_mult = current_mult + 5
            local level = (p.item_levels["Velocidade de Ataque"] or 0)
            return string.format("Nível %d | Velocidade: +%.0f%% → +%.0f%%", 
                level, current_mult, next_mult)
        end,
        price = 5,
        type = "upgrade",
        weight = 15,
        icon = Rapidez,
    },
    {
        id = "Escudo Natalino",
        get_name = function() return "Escudo Natalino" end,
        effect = function(p) 
            p.block_chance = math.min(0.75, (p.block_chance or 0) + 0.10)
        end, 
        get_desc = function() return "Chance de bloquear completamente o dano recebido" end, 
        get_desc2 = function(p) 
            local current = ((p.block_chance or 0) * 100)
            local next_val = math.min(75, current + 10)
            local level = (p.item_levels["Escudo Natalino"] or 0)
            return string.format("Nível %d | Bloqueio: %.0f%% → %.0f%% (máx 75%%)", 
                level, current, next_val)
        end,
        price = 5,
        type = "upgrade",
        weight = 8,
        icon = love.graphics.newImage("assets/sprite2.png"),
    },
    {
        id = "Rajada Glacial",
        get_name = function() return "Rajada Glacial" end,
        effect = function(p) 
            p.multishot_chance = (p.multishot_chance or 0) + 0.08
            p.multishot_count = (p.multishot_count or 1) + 0.3
        end, 
        get_desc = function() return "Chance de disparar projéteis adicionais" end, 
        get_desc2 = function(p) 
            local current_chance = ((p.multishot_chance or 0) * 100)
            local next_chance = current_chance + 8
            local current_count = math.floor(p.multishot_count or 1)
            local next_count = math.floor((p.multishot_count or 1) + 0.3)
            local level = (p.item_levels["Rajada Glacial"] or 0)
            return string.format("Nível %d | Chance: %.0f%% → %.0f%% | Extra: %d → %d", 
                level, current_chance, next_chance, current_count, next_count)
        end,
        price = 5,
        type = "upgrade",
        weight = 5,
        icon = neve,
    },
    {
        id = "Presente Explosivo",
        get_name = function() return "Presente Explosivo" end,
        effect = function(p) 
            p.death_explosion = true
            p.explosion_damage = (p.explosion_damage or 0.5) + 0.1
            p.explosion_radius = (p.explosion_radius or 24) + 4
        end, 
        get_desc = function() return "Inimigos mortos explodem causando dano em área" end, 
        get_desc2 = function(p) 
            local current_dmg = ((p.explosion_damage or 0.5) * 100)
            local next_dmg = current_dmg + 10
            local current_rad = (p.explosion_radius or 24)
            local next_rad = current_rad + 4
            local level = (p.item_levels["Presente Explosivo"] or 0)
            return string.format("Nível %d | Dano: %.0f%% → %.0f%% do dano | Raio: %dpx → %dpx", 
                level, current_dmg, next_dmg, current_rad, next_rad)
        end,
        price = 5,
        type = "upgrade",
        weight = 6,
        icon = presente,
    }
}

local shop_items = {
    {
        id = "Greed",
        get_name = function() return Lang.text("relic_greed") end,
        get_desc = function() return Lang.text("relic_greed_desc") end,
        effect = function(p) p.relics["Greed"] = true end,
        price = 120,
        type = "relic",
        weight = 10,
        icon = love.graphics.newImage("assets/CoinICON.png")
    },
    {
        id = "Coin magnet",
        get_name = function() return Lang.text("relic_coin_magnet") end,
        get_desc = function() return Lang.text("relic_coin_magnet_desc") end,
        effect = function(p) p.relics["Coin Magnet"] = true end,
        price = 100,
        type = "relic",
        weight = 10,
        icon = love.graphics.newImage("assets/ImãICON.png")
    },
    -- 🆕 NOVA RELÍQUIA
    {
        id = "Sorte Dourada",
        get_name = function() return "Sorte Dourada" end,
        get_desc = function() return "Dobra a chance de drops raros e melhora recompensas" end,
        effect = function(p) p.relics["Sorte Dourada"] = true end,
        price = 150,
        type = "relic",
        weight = 8,
        icon = love.graphics.newImage("assets/Sorte.png")
    },

}

local function pickRandomUnique(pool, count)
    local results = {}
    local temp_pool = {}
    for _, v in ipairs(pool) do table.insert(temp_pool, v) end

    for i = 1, count do
        if #temp_pool == 0 then break end
        
        local total_w = 0
        for _, item in ipairs(temp_pool) do total_w = total_w + item.weight end
        
        local r = math.random() * total_w
        for j, item in ipairs(temp_pool) do
            r = r - item.weight
            if r <= 0 then
                table.insert(results, table.remove(temp_pool, j))
                break
            end
        end
    end
    return results
end

function Rewards.generate()
    Rewards.slots = {}
    -- Pega 3 de cada pool e coloca na mesma linha
    local items_a = pickRandomUnique(upgrades, 3)
    local items_b = pickRandomUnique(shop_items, 2)
    
    for _, it in ipairs(items_a) do table.insert(Rewards.slots, { item = it, bought = false }) end
    for _, it in ipairs(items_b) do table.insert(Rewards.slots, { item = it, bought = false }) end
end

function Rewards.reroll()
    if player.money >= Rewards.reroll_cost then
        player.money = player.money - Rewards.reroll_cost
        Rewards.reroll_cost = Rewards.reroll_cost + 5
        Rewards.generate()
        _G.setupButtonsForState("rewards")
    end
end

function Rewards.buy(index)
    local slot = Rewards.slots[index]
    if not slot or slot.bought then return end

    if player.money >= slot.item.price then
        player.money = player.money - slot.item.price
        slot.item.effect(player)
        slot.bought = true
        
        -- Se for um upgrade, aumenta o nível no registro
        if slot.item.price == 5 then
            player.item_levels[slot.item.id] = (player.item_levels[slot.item.id] or 0) + 1
        end
    end
    _G.setupButtonsForState("rewards")
end

function Rewards:selectReward()
    local reward = Rewards.current_rewards[Rewards.selected_index]
    if not reward then return end
    
    if reward.id == "Novos itens" then
        Rewards.generate(3)
        setupButtonsForState("rewards")
        return
    end

    Musica_Atual:stop()
    if GameConfig.musica_antiga==false then
        Musica_Atual = Luta_Musica
    else
        Musica_Atual = Musica_Luta_Antiga
    end
    Musica_Atual:play()
    Musica_Atual:setVolume(0.25)
    Musica_Atual:setLooping(true)
    
    reward.effect(player)
    
    -- Usa o 'id' como chave
    if player.item_levels[reward.id] == nil then
        player.item_levels[reward.id] = 0
    end
    player.item_levels[reward.id] = player.item_levels[reward.id] + 1

    _G.switchState("play")
end

function Rewards.get_icon_by_name(name)
    -- Procura em upgrades
    for _, item in ipairs(upgrades) do
        if item.id == name then return item.icon end
    end
    -- Procura em shop
    for _, item in ipairs(shop_items) do
        if item.id == name then return item.icon end
    end
    return nil
end

function Rewards.draw()
    if math.random() < 0.1 then 
        for i = 1, math.random(1, 8) do
            addpart(math.random(0, love.graphics.getWidth()), -16, {
                gravity = 0.75+math.random(0,2),
                vy = math.random(20, 60),
                vx = math.random(-1,1),
                image = presente,
                size = math.random(12, 32),
                life = math.random(1, 2.5)
            })
        end
    end
    Utils.setColor(2)
    love.graphics.rectangle("fill", 0, 0, 128*6, 128*2)
    Utils.setColor(7)
    part.draw()
    Utils.centerText(Lang.text("shop_title"), 10)
        
    -- Mostra dinheiro
    Utils.setColor(10)
    love.graphics.print(Lang.text("hud_money", player.money), 16, 10)

    local reward = Rewards.current_rewards[Rewards.selected_index]
    if Rewards.selected_index and Rewards.slots[Rewards.selected_index] then
        local slot = Rewards.slots[Rewards.selected_index]
        Utils.setColor(7)
        if slot.item then
            love.graphics.print(slot.item.get_name(), 16, (128 * 2) - 64)
            love.graphics.print(slot.item.get_desc(), 16, (128 * 2) - 48)
            -- Se tiver get_desc2 (stats), desenha
            if slot.item.get_desc2 then
                Utils.setColor(12)
                love.graphics.print(slot.item.get_desc2(player), 16, (128 * 2) - 28)
            end
        end
    end
    Buttons:drawAll()
end

return Rewards