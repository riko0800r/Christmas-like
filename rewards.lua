-- rewards.lua
local Utils   = require('utils')
local Buttons = require("button")
local part    = require("part_rewards")
local Lang    = require('lang') -- <<<

local addpart = part.spawn

local Rewards = {}
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

-- NOTA: Os 'id' abaixo são usados como chaves no player.item_levels
-- Mantenha-os iguais aos originais (em PT) para não quebrar lógica
local base_items = {
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
        weight = 30,
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
        weight = 30,
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
        weight = 30,
        icon=Rapidez,
    },
    {
        id = "Novos itens", 
        get_name = function() return Lang.text("item_new") end,
        effect = function(p) end, 
        get_desc = function() return Lang.text("item_new_desc") end, 
        get_desc2 = function(p) return Lang.text("item_new_stat") end,
        weight = 45,
        icon=NovosItens,
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
        weight = 14,
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
        weight = 14,
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
        weight = 15,
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
        weight = 12,
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
        weight = 12,
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
        weight = 10,
        icon=Imobilizador,
    },
    {
        id = "Vitalidade", 
        get_name = function() return Lang.text("item_vit") end,
        effect = function(p) 
            p.regen = true
            p.vidas_por_rodada = (p.vidas_por_rodada or 1) + 0.5
            if p.regen_delay > 3 then p.regen_delay = p.regen_delay - 0.25 end
        end, 
        get_desc = function() return Lang.text("item_vit_desc") end, 
        get_desc2 = function(p) 
            local current_heal = p.vidas_por_rodada or 1
            local next_heal = current_heal + 0.5
            local current_delay = p.regen_delay
            local next_delay = math.max(3, current_delay - 0.25)
            local level = (p.item_levels["Vitalidade"] or 0)
            return Lang.text("item_vit_stat", level, current_heal, next_heal, current_delay, next_delay)
        end, 
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
        weight = 15,
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
        weight = 15,
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
        weight = 15,
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
        weight = 15,
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
        weight = 0, -- Raridade (quanto menor, mais raro)
        icon = love.graphics.newImage("assets/VidaICON.png"), -- Reusando icone de vida
    },
}

function Rewards.generate(num_rewards)
    Rewards.current_rewards = {}
    Rewards.selected_index = 1
    
    local available_rewards = {}
    for _, item in ipairs(base_items) do 
        table.insert(available_rewards, {reward = item, weight = item.weight}) 
    end

    for i = 1, num_rewards do
        if #available_rewards == 0 then break end
        local total_weight = 0
        for _, item in ipairs(available_rewards) do 
            total_weight = total_weight + item.weight 
        end
        local choice = math.random() * total_weight
        for index, item in ipairs(available_rewards) do
            choice = choice - item.weight
            if choice <= 0 then
                table.insert(Rewards.current_rewards, item.reward)
                table.remove(available_rewards, index)
                break
            end
        end
    end
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

-- Nova função auxiliar para obter ícone por nome
function Rewards.get_icon_by_name(name)
    for _, item in ipairs(base_items) do
        if item.id == name then
            return item.icon
        end
    end
    return nil
end

function Rewards.draw()
    if math.random() < 0.1 then 
        for i = 1, math.random(1, 8) do
            addpart(math.random(0, love.graphics.getWidth()), -16, {
                gravity = 0.75+math.random(0,1),
                vy = math.random(20, 60),
                vx = math.random(-20, 20),
                image = presente,
                size = math.random(8, 32),
                life = math.random(1, 4)
            })
        end
    end
    Utils.setColor(2)
    love.graphics.rectangle("fill", 0, 0, 128*6, 128*2)
    Utils.setColor(7)
    part.draw()
    Utils.centerText(Lang.text("reward_choose"), 10)

    local reward = Rewards.current_rewards[Rewards.selected_index]
    if reward then
        Utils.setColor(7)
        love.graphics.print(reward.get_desc(), 16, (128 * 2) - 48)
        if reward.get_desc2 then
            Utils.setColor(12)
            love.graphics.print(reward.get_desc2(player), 16, (128 * 2) - 28)
        end
    end
    
    Buttons:drawAll()
end

return Rewards