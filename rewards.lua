-- rewards.lua
local Utils   = require('utils')
local Buttons = require("button")
local part    = require("part_rewards")
local Lang    = require('lang')

local addpart = part.spawn

local Rewards = {}
Rewards.slots = {}
Rewards.reroll_cost = 10
Rewards.free_claimed = false
Rewards.selected_index = 1
Rewards.current_rewards = {}

_G.SFX_Reroll=love.audio.newSource("assets/reroll.wav", "static")
_G.SFX_Buy=love.audio.newSource("assets/buy.wav","static")

local presente=love.graphics.newImage("assets/Presente.png")
local Lava=love.graphics.newImage("assets/Lava.png")
local neve=love.graphics.newImage("assets/NeveICON.png")
local pedras=love.graphics.newImage("assets/pedraICON.png")
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
local LifestealIcon = love.graphics.newImage("assets/VidaDrenagemICON.png")
local Icon_Guirlanda = love.graphics.newImage("assets/GuirlandaICON.png")
local Icon_Bumerang = love.graphics.newImage("assets/BumerangICON.png")
local Icon_Estrelas = love.graphics.newImage("assets/EstrelaICON.png")

-- Função para calcular preço dinâmico baseado no nível
local function getItemPrice(item, player)
    local level = player.item_levels[item.id] or 0
    -- Preço base + (5 * nível do item)
    -- Nível 0: $5, Nível 1: $10, Nível 2: $15, etc
    if item.base_price then
        return item.base_price + (5 * level)
    end
    return 5 + (5 * level)
end

local upgrades = {
    {
        id = "Vida",
        get_name = function() return Lang.text("item_life") end, 
        effect = function(p) p.lifes = p.lifes + 4; p.max_life = p.max_life + 4 end, 
        get_desc = function() return Lang.text("item_life_desc") end, 
        get_desc2 = function(p) 
            local level = (p.item_levels["Vida"] or 0)
            local current = p.max_life
            local next_val = current + 4
            return Lang.text("item_life_stat", level + 1, current, next_val)
        end,
        base_price=5,
        weight = 25,
        icon=Vida,
        get_price = getItemPrice,
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
            return Lang.text("item_str_stat", level + 1, current, next_val)
        end, 
        base_price = 5,
        type = "upgrade",
        weight = 25,
        icon=Forca,
        get_price = getItemPrice,
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
            return Lang.text("item_spd_stat", level + 1, current, next_val)
        end, 
        base_price = 5,
        type = "upgrade",
        weight = 25,
        icon=Rapidez,
        get_price = getItemPrice,
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
            return Lang.text("item_snow_stat", level + 1, current_dmg, next_dmg, current_cd, next_cd)
        end, 
        base_price = 5,
        type = "upgrade",
        weight = 20,
        icon=neve,
        get_price = getItemPrice,
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
            return Lang.text("item_ice_stat", level + 1, current_dmg, next_dmg, current_cd, next_cd)
        end,
        base_price = 5,
        type = "upgrade",
        weight = 20,
        icon=Gelo,
        get_price = getItemPrice,
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
            return Lang.text("item_rock_stat", level + 1, current_dmg, next_dmg, current_cd, next_cd)
        end, 
        base_price = 5,
        type = "upgrade",
        weight = 20,
        icon=pedras,
        get_price = getItemPrice,
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
            return Lang.text("item_psn_stat", level + 1, current_dmg, next_dmg, current_delay, next_delay)
        end, 
        base_price=5,
        weight = 10,
        icon=VenenoSprite,
        get_price = getItemPrice,
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
            return Lang.text("item_fire_stat", level + 1, current_dmg, next_dmg, current_delay, next_delay)
        end,
        base_price = 5,
        type = "upgrade",
        weight = 10,
        icon=Fogo,
        get_price = getItemPrice,
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
            return Lang.text("item_frz_stat", level + 1, current_slow, next_slow, current_delay, next_delay)
        end,
        base_price = 5,
        type = "upgrade",
        weight = 10,
        icon=Imobilizador,
        get_price = getItemPrice,
    },
    {
        id = "Vitalidade", 
        get_name = function() return Lang.text("item_vit") end,
        effect = function(p) 
            p.regen = true
            p.regen_amount = (p.regen_amount or 0) + 2
        end, 
        get_desc = function() return Lang.text("item_vit_desc") end, 
        get_desc2 = function(p) 
            local current = (p.regen_amount or 0)
            local next_val = current + 2
            local level = (p.item_levels["Vitalidade"] or 0)
            return Lang.text("item_vit_stat", level + 1, current, next_val)
        end, 
        base_price = 5,
        type = "upgrade",
        weight = 10,
        icon=Vitalidade,
        get_price = getItemPrice,
    },
    {
        id = "Anel de Lava",
        get_name = function() return Lang.text("item_lava") end,
        effect = function(p) 
            p.anel_ativo = true
            p.anel_pontos = (p.anel_pontos or 0) + 2
            p.demage = p.demage + 0.2
        end, 
        get_desc = function() return Lang.text("item_lava_desc") end, 
        get_desc2 = function(p) 
            local current_count = (p.anel_pontos or 0)
            local next_count = current_count + 2
            local current_dmg = p.demage
            local next_dmg = current_dmg + 0.2
            local level = (p.item_levels["Anel de Lava"] or 0)
            return Lang.text("item_lava_stat", level + 1, current_count, next_count, current_dmg, next_dmg)
        end, 
        base_price = 5,
        type = "upgrade",
        weight = 20,
        icon=Lava,
        get_price = getItemPrice,
    },
    {
        id = "Pedras Preciosas", 
        get_name = function() return Lang.text("item_gem") end,
        effect = function(p) 
            p.sombrio_ativo = true
            p.sombrio_quantidade = (p.sombrio_quantidade or 0) + 1
            p.demage = p.demage + 0.1
        end, 
        get_desc = function() return Lang.text("item_gem_desc") end, 
        get_desc2 = function(p) 
            local current_count = (p.sombrio_quantidade or 12)
            local next_count = current_count + 1
            local current_dmg = p.demage * 0.5
            local next_dmg = (p.demage + 0.1) * 0.5
            local current_cd = p.gema_max_time or 1.5
            local next_cd = math.max(0.5, current_cd - 0.15)
            local level = (p.item_levels["Pedras Preciosas"] or 0)
            return Lang.text("item_gem_stat", level + 1, current_count, next_count, current_dmg, next_dmg, current_cd, next_cd)
        end,
        base_price = 5, 
        type = "upgrade",
        weight = 20,
        icon=sombriosSprite,
        get_price = getItemPrice,
    },
    {
        id = "Guirlanda de Espinhos",
        get_name = function() return Lang.text("item_garlic") end,
        effect = function(p)
            p.guirlanda = true
            p.guirlanda_dano = (p.guirlanda_dano or 0.2) + 0.1
            p.guirlanda_raio = (p.guirlanda_raio or 32) + 4
        end,
        get_desc = function() return Lang.text("item_garlic_desc") end,
        get_desc2 = function(p)
            local level = (p.item_levels["Guirlanda de Espinhos"] or 0)
            local dmg = p.guirlanda_dano or 0.2
            local area= p.guirlanda_raio or 32
            return Lang.text("item_garlic_stat", level + 1, area, dmg)
        end,
        base_price = 5,
        type = "upgrade",
        weight = 20,
        icon = Icon_Guirlanda,
        get_price = getItemPrice,
    },
    {
        id = "Bumerangue Natalino",
        get_name = function() return Lang.text("item_boom") end,
        effect = function(p)
            p.boom = true
            p.boom_max_time = (p.boom_max_time or 2) - 0.3
        end,
        get_desc = function() return Lang.text("item_boom_desc") end,
        get_desc2 = function(p)
            local level = (p.item_levels["Bumerangue Natalino"] or 0)
            local cd = p.boom_max_time or 2
            return Lang.text("item_boom_stat", level + 1, cd)
        end,
        base_price = 5,
        type = "upgrade",
        weight = 20,
        icon = Icon_Bumerang,
        get_price = getItemPrice,
    },
    {
        id = "Estrelas Natalinas",
        get_name = function() return Lang.text("item_star_name") end,
        effect = function(p)
            p.estrelas_natalinas = true
            p.estrelas_count = (p.estrelas_count or 3) + 1
        end,
        get_desc = function() return Lang.text("item_star_desc") end,
        get_desc2 = function(p)
            local level = (p.item_levels["Chuva Estrelada"] or 0)
            local cd = p.estrelas_count or 3
            return Lang.text("item_star_stat", level + 1, cd)
        end,
        base_price = 5,
        type = "upgrade",
        weight = 20,
        icon = Icon_Estrelas,
        get_price = getItemPrice,
    },
    {
        id = "Drenagem Natalina",
        get_name = function() return Lang.text("item_lifesteal") end,
        effect = function(p)
            p.lifesteal_chance = (p.lifesteal_chance or 0.1) + 0.05
        end,
        get_desc = function() return Lang.text("item_lifesteal_desc") end,
        get_desc2 = function(p)
            local level = (p.item_levels["Drenagem Natalina"] or 0)
            local percent = (p.lifesteal_chance or 0.1) * 100
            return Lang.text("item_lifesteal_stat", level + 1, percent)
        end,
        base_price = 5,
        type = "upgrade",
        weight = 10,
        icon = LifestealIcon,
        get_price = getItemPrice,
    },
    {
        id = "Rajada Glacial",
        get_name = function() return "Rajada Glacial" end,
        effect = function(p)
            p.multishot = true
            p.multishot_chance = (p.multishot_chance or 0.2) + 0.08
            p.multishot_count = (p.multishot_count or 1) + 0.3
        end,
        get_desc = function() return "Chance de disparar múltiplos tiros!" end,
        get_desc2 = function(p)
            local current_chance = ((p.multishot_chance or 0) * 100)
            local next_chance = current_chance + 8
            local current_count = math.floor(p.multishot_count or 1)
            local next_count = math.floor((p.multishot_count or 1) + 0.25)
            local level = (p.item_levels["Rajada Glacial"] or 0)
            return string.format("Nível %d | Chance: %.0f%% → %.0f%% | Extra: %d → %d", 
                level + 1, current_chance, next_chance, current_count, next_count)
        end,
        base_price = 5,
        type = "upgrade",
        weight = 0,
        icon = neve,
        get_price = getItemPrice,
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
                level + 1, current_dmg, next_dmg, current_rad, next_rad)
        end,
        base_price = 5,
        type = "upgrade",
        weight = 6,
        icon = presente,
        get_price = getItemPrice,
    }
}

local shop_items = {
    {
        id = "Greed",
        get_name = function() return Lang.text("relic_greed") end,
        get_desc = function() return Lang.text("relic_greed_desc") end,
        effect = function(p) p.relics["Greed"] = true end,
        base_price = 80,
        type = "relic",
        weight = 10,
        icon = love.graphics.newImage("assets/CoinICON.png"),
        get_price = function(item, player) return item.base_price end,
    },
    {
        id = "Coin Magnet", -- Ajustado para bater com o nome usado no effect
        get_name = function() return Lang.text("relic_coin_magnet") end,
        get_desc = function() return Lang.text("relic_coin_magnet_desc") end,
        effect = function(p) p.relics["Coin Magnet"] = true end,
        base_price = 50,
        type = "relic",
        weight = 10,
        icon = love.graphics.newImage("assets/ImãICON.png"),
        get_price = function(item, player) return item.base_price end,
    },
    {
        id = "Sorte Dourada",
        get_name = function() return Lang.text("relic_gold_luck") end,
        get_desc = function() return Lang.text("relic_gold_luck_desc")  end,
        effect = function(p) p.relics["Sorte Dourada"] = true end,
        base_price = 75,
        type = "relic",
        weight = 8,
        icon = love.graphics.newImage("assets/Sorte.png"),
        get_price = function(item, player) return item.base_price end,
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
    local items_a = pickRandomUnique(upgrades, 3)
    
    -- FILTRO DE RELÍQUIAS:
    local available_relics = {}
    for _, item in ipairs(shop_items) do
        -- Verificamos se o jogador já tem essa relíquia marcada como true em player.relics
        if not player.relics[item.id] then
            table.insert(available_relics, item)
        end
    end
    
    -- Sorteia 2 relíquias apenas entre as que o jogador ainda não comprou
    local items_b = pickRandomUnique(available_relics, 2)
    
    for _, it in ipairs(items_a) do table.insert(Rewards.slots, { item = it, bought = false }) end
    for _, it in ipairs(items_b) do table.insert(Rewards.slots, { item = it, bought = false }) end
end

function Rewards.reroll()
    if player.money >= Rewards.reroll_cost then
        player.money = player.money - Rewards.reroll_cost
        Rewards.reroll_cost = Rewards.reroll_cost + 5
        Rewards.generate()
        local randomPitch = love.math.random() * 0.4 + 0.8
        SFX_Reroll:setPitch(randomPitch)
        SFX_Reroll:play()
        _G.setupButtonsForState("rewards")
    end
end

function Rewards.buy(index)
    local slot = Rewards.slots[index]
    if not slot or slot.bought then return end

    local price = slot.item.get_price(slot.item, player)
    
    if player.money >= price then
        player.money = player.money - price
        slot.item.effect(player)
        slot.bought = true
        SFX_Buy:play()
        
        -- Aumenta o nível do item
        if slot.item.type == "upgrade" then
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
    
    if player.item_levels[reward.id] == nil then
        player.item_levels[reward.id] = 0
    end
    player.item_levels[reward.id] = player.item_levels[reward.id] + 1

    _G.switchState("play")
end

function Rewards.get_icon_by_name(name)
    for _, item in ipairs(upgrades) do
        if item.id == name then return item.icon end
    end
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
            if slot.item.get_desc2 then
                Utils.setColor(12)
                love.graphics.print(slot.item.get_desc2(player), 16, (128 * 2) - 28)
            end
        end
    end
    Buttons:drawAll()
end

return Rewards