-- characters.lua
local Lang = require('lang') -- <<<

local Characters = {}
Characters.selected_index = 1

Characters.list = {
    {
        id = "normal",
        get_name = function() return Lang.text("char_normal") end,
        get_desc = function() 
            local d = Lang.text("char_normal_desc")
            local lines = {}
            for s in d:gmatch("[^\n]+") do table.insert(lines, s) end
            return lines
        end,
        sprite_id = 11,
        apply = function(p)
            p.tipo_jogador = 1
            p.demage = 2.45
            p.roda = true
            p.speed = 2
            p.roda_max_time = 2.5
            p.sp = {1,1} 
            p.item_levels = {
                ["Bola de neve"] = 0,
                ["Bloco de gelo"] = 1,
                ["Pedras do ceu"] = 0,
                ["Veneno mortal"] = 0,
                ["Fogo perigoso"] = 0,
                ["Imobilizador"] = 0,
                ["Anel de Lava"] = 0,
                ["Pedras Preciosas"] = 0,
                ["Anel de renas"] = 0,
                ["Pedras que seguem"] = 0,
                ["Combo tóxico"] = 0,
            }
        end
    },
    {
        id = "vital",
        get_name = function() return Lang.text("char_vital") end,
        get_desc = function() 
            local d = Lang.text("char_vital_desc")
            local lines = {}
            for s in d:gmatch("[^\n]+") do table.insert(lines, s) end
            return lines
        end,
        sprite_id = 12,
        apply = function(p)
            p.tipo_jogador = 2
            p.demage = 1.75
            p.tiro = true
            p.speed = 1.75
            p.tiro_max_time = 2.5
            p.regen = true
            p.vidas_por_rodada = 1
            p.sp = {12,12}
            p.item_levels = {
                ["Bola de neve"] = 1,
                ["Bloco de gelo"] = 0,
                ["Pedras do ceu"] = 0,
                ["Veneno mortal"] = 0,
                ["Fogo perigoso"] = 0,
                ["Imobilizador"] = 0,
                ["Anel de Lava"] = 0,
                ["Pedras Preciosas"] = 0,
                ["Anel de renas"] = 0,
                ["Pedras que seguem"] = 0,
                ["Combo tóxico"] = 0,
            }
        end
    },
    {
        id = "poison",
        get_name = function() return Lang.text("char_poison") end,
        get_desc = function() 
            local d = Lang.text("char_poison_desc")
            local lines = {}
            for s in d:gmatch("[^\n]+") do table.insert(lines, s) end
            return lines
        end,
        sprite_id = 13,
        apply = function(p)
            p.tipo_jogador = 3
            p.demage = 0.85
            p.tiro = true
            p.speed = 2.25
            p.veneno = true
            p.veneno_dano = 0.20
            p.veneno_delay = 0.66
            p.sp = {13,13}
            p.item_levels = {
                ["Bola de neve"] = 1,
                ["Bloco de gelo"] = 0,
                ["Pedras do ceu"] = 0,
                ["Veneno mortal"] = 1,
                ["Fogo perigoso"] = 0,
                ["Imobilizador"] = 0,
                ["Anel de Lava"] = 0,
                ["Pedras Preciosas"] = 0,
                ["Anel de renas"] = 0,
                ["Pedras que seguem"] = 0,
                ["Combo tóxico"] = 0,
            }
        end
    },
    {
        id = "fire",
        get_name = function() return Lang.text("char_fire") end,
        get_desc = function() 
            local d = Lang.text("char_fire_desc")
            local lines = {}
            for s in d:gmatch("[^\n]+") do table.insert(lines, s) end
            return lines
        end,
        sprite_id = 14,
        apply = function(p)
            p.tipo_jogador = 4
            p.demage = 0.5
            p.roda = true
            p.roda_max_time=2.75
            p.speed = 2.25
            p.fogo = true
            p.fogo_dano = 0.75
            p.fogo_delay = 1
            p.sp = {14,14}
            p.item_levels = {
                ["Bola de neve"] = 0,
                ["Bloco de gelo"] = 0,
                ["Pedras do ceu"] = 0,
                ["Veneno mortal"] = 0,
                ["Fogo perigoso"] = 1,
                ["Imobilizador"] = 0,
                ["Anel de Lava"] = 0,
                ["Pedras Preciosas"] = 0,
                ["Anel de renas"] = 0,
                ["Pedras que seguem"] = 0,
                ["Combo tóxico"] = 0,
            }
        end
    },
    {
        id = "ice",
        get_name = function() return Lang.text("char_ice") end,
        get_desc = function() 
            local d = Lang.text("char_ice_desc")
            local lines = {}
            for s in d:gmatch("[^\n]+") do table.insert(lines, s) end
            return lines
        end,
        sprite_id = 15,
        apply = function(p)
            p.tipo_jogador = 5
            p.demage = 1.5
            p.roda = true
            p.speed = 2.25
            p.roda_max_time = 1.5
            p.gelo = true
            p.gelo_dano = 0.25
            p.gelo_delay = 2
            p.sp = {15,15}
            p.item_levels = {
                ["Bola de neve"] = 0,
                ["Bloco de gelo"] = 1,
                ["Pedras do ceu"] = 0,
                ["Veneno mortal"] = 0,
                ["Fogo perigoso"] = 0,
                ["Imobilizador"] = 1,
                ["Anel de Lava"] = 0,
                ["Pedras Preciosas"] = 0,
                ["Anel de renas"] = 0,
                ["Pedras que seguem"] = 0,
                ["Combo tóxico"] = 0,
            }
        end
    },
    {
        id = "rock",
        get_name = function() return Lang.text("char_rock") end,
        get_desc = function() 
            local d = Lang.text("char_rock_desc")
            local lines = {}
            for s in d:gmatch("[^\n]+") do table.insert(lines, s) end
            return lines
        end,
        sprite_id = 64,
        apply = function(p)
            p.tipo_jogador = 6
            p.demage = 0.85
            p.pedra = true
            p.speed = 2.5
            p.pedra_max_time = 2
            p.sp = {64,64}
            p.item_levels = {
                ["Bola de neve"] = 0,
                ["Bloco de gelo"] = 0,
                ["Pedras do ceu"] = 1,
                ["Veneno mortal"] = 0,
                ["Fogo perigoso"] = 0,
                ["Imobilizador"] = 0,
                ["Anel de Lava"] = 0,
                ["Pedras Preciosas"] = 0,
                ["Anel de renas"] = 0,
                ["Pedras que seguem"] = 0,
                ["Combo tóxico"] = 0,
            }
        end
    },
    {
        id = "lava",
        get_name = function() return Lang.text("char_lava") end,
        get_desc = function() 
            local d = Lang.text("char_lava_desc")
            local lines = {}
            for s in d:gmatch("[^\n]+") do table.insert(lines, s) end
            return lines
        end,
        sprite_id = 64,
        apply = function(p)
            p.tipo_jogador = 7
            p.demage = 1.25
            p.raio_luz = true
            p.speed = 1.85
            p.anel_pontos=6
            p.anel_dano=0.45
            p.anel_ativo=true
            p.sp = {64,64}
            p.item_levels = {
                ["Bola de neve"] = 0,
                ["Bloco de gelo"] = 0,
                ["Pedras do ceu"] = 0,
                ["Veneno mortal"] = 0,
                ["Fogo perigoso"] = 0,
                ["Imobilizador"] = 0,
                ["Anel de Lava"] = 1,
                ["Pedras Preciosas"] = 0,
                ["Anel de renas"] = 0,
                ["Pedras que seguem"] = 0,
                ["Combo tóxico"] = 0,
            } 
        end
    },
    {
        id = "gift",
        get_name = function() return Lang.text("char_gift") end,
        get_desc = function() 
            local d = Lang.text("char_gift_desc")
            local lines = {}
            for s in d:gmatch("[^\n]+") do table.insert(lines, s) end
            return lines
        end,
        sprite_id = 64,
        apply = function(p)
            p.tipo_jogador = 8
            p.demage = 1
            p.speed = 2
            p.sombrio_ativo=true
            p.sombrio_delay=2
            p.sp = {64,64}
            p.item_levels = {
                ["Bola de neve"] = 0,
                ["Bloco de gelo"] = 0,
                ["Pedras do ceu"] = 0,
                ["Veneno mortal"] = 0,
                ["Fogo perigoso"] = 0,
                ["Imobilizador"] = 0,
                ["Anel de Lava"] = 0,
                ["Pedras Preciosas"] = 1,
                ["Anel de renas"] = 0,
                ["Pedras que seguem"] = 0,
                ["Combo tóxico"] = 0,
            }
        end
    },
    {
        id = "mystery",
        get_name = function() return Lang.text("char_mystery") end,
        get_desc = function() 
            local d = Lang.text("char_mystery_desc")
            local lines = {}
            for s in d:gmatch("[^\n]+") do table.insert(lines, s) end
            return lines
        end,
        sprite_id = 11,
        apply = function(p)
            p.tipo_jogador = 9
            p.demage = 1.5
            p.speed = 2
            p.tiro = true
            p.tiro_max_time = 2
            
            local possiveis_itens = {
                "Bola de neve",
                "Bloco de gelo",
                "Pedras do ceu",
                "Anel de Lava",
                "Pedras Preciosas",
                "Bumerangue",
                "Guirlanda",
            }
            
            p.item_levels = {}
            for _, item in ipairs(possiveis_itens) do
                p.item_levels[item] = 0
            end
            p.item_levels["Anel de renas"] = 0
            p.item_levels["Pedras que seguem"] = 0
            p.item_levels["Combo tóxico"] = 0
            
            local escolhidos = {}
            while #escolhidos < 1 do
                local item = possiveis_itens[love.math.random(#possiveis_itens)]
                local repetido = false
                for _, v in ipairs(escolhidos) do
                    if v == item then repetido = true break end
                end
                if not repetido then
                    table.insert(escolhidos, item)
                    p.item_levels[item] = 1
                end
            end
            
            for _, item in ipairs(escolhidos) do
                if item == "Bola de neve" then
                    p.tiro = true
                elseif item == "Bloco de gelo" then
                    p.roda = true
                    p.roda_max_time = 3
                elseif item == "Pedras do ceu" then
                    p.pedra = true
                    p.pedra_max_time = 2
                elseif item == "Veneno mortal" then
                    p.veneno = true
                    p.veneno_dano = 0.2
                    p.veneno_delay = 0.66
                elseif item == "Anel de Lava" then
                    p.anel_ativo = true
                    p.anel_dano = 0.45
                    p.anel_pontos = 6
                elseif item == "Pedras Preciosas" then
                    p.sombrio_ativo = true
                    p.sombrio_delay = 2
                elseif item == "Fogo perigoso" then
                    p.fogo = true
                    p.fogo_dano=0.15
                elseif item=="Guirlanda" then
                    p.guirlanda=true
                    p.guirlanda_dano=0.25
                elseif item=="Bumerangue" then
                    p.bumerangue=true
                end
            end
            p.sp = {11,11}
        end
    },
    {
        id = "Gift2",
        get_name = function() return Lang.text("char_gift2") end,
        get_desc = function() 
            local d = Lang.text("char_gift2_desc")
            local lines = {}
            for s in d:gmatch("[^\n]+") do table.insert(lines, s) end
            return lines
        end,
        sprite_id = 64,
        apply = function(p)
            p.tipo_jogador = 10
            p.demage = 1
            p.bumerangue=true
            p.bumerangue_delay = 1.45
            p.speed = 2.5
            p.sp = {64,64}
        end
    },
    {
        id = "Tree",
        get_name = function() return Lang.text("char_tree") end,
        get_desc = function() 
            local d = Lang.text("char_tree_desc")
            local lines = {}
            for s in d:gmatch("[^\n]+") do table.insert(lines, s) end
            return lines
        end,
        sprite_id = 64,
        apply = function(p)
            p.tipo_jogador = 11
            p.demage = 1
            p.speed = 2.5
            p.guirlanda=true
            p.guirlanda_raio = 56
            p.guirlanda_dano=0.4
            p.sp = {64,64}
        end
    },
    {
        id = "Atirador",
        get_name = function() return Lang.text("char_atirador") end,
        get_desc = function() 
            local d = Lang.text("char_atirador_desc")
            local lines = {}
            for s in d:gmatch("[^\n]+") do table.insert(lines, s) end
            return lines
        end,
        sprite_id = 64,
        apply = function(p)
            p.tipo_jogador = 12
            p.demage = 1.75
            p.tiro_max_time=1.25
            p.speed = 2.25
            p.tiro=true
            p.sp = {64,64}
        end
    },
    {
        id = "estrela",
        get_name = function() return Lang.text("char_estrela_natalina") end,
        get_desc = function() 
            local d = Lang.text("char_estrela_natalina_desc")
            local lines = {}
            for s in d:gmatch("[^\n]+") do table.insert(lines, s) end
            return lines
        end,
        sprite_id = 13,
        apply = function(p)
            p.tipo_jogador = 13
            p.demage = 1.0
            p.estrelas_natalinas=true
            p.estrelas_count=4
            p.speed = 2.25
            p.sp = {13,13}
            p.item_levels = {
                ["Bola de neve"] = 1,
                ["Bloco de gelo"] = 0,
                ["Pedras do ceu"] = 0,
                ["Veneno mortal"] = 1,
                ["Fogo perigoso"] = 0,
                ["Imobilizador"] = 0,
                ["Anel de Lava"] = 0,
                ["Pedras Preciosas"] = 0,
                ["Anel de renas"] = 0,
                ["Pedras que seguem"] = 0,
                ["Combo tóxico"] = 0,
            }
        end
    },
}

function Characters.load(player)
    Characters.sprite_sheet=love.graphics.newImage("assets/spritePersonagens.png")
    player.sprite_sheet=love.graphics.newImage("assets/spritePersonagens.png")
    Characters.image={}
    player.sprite={}
    for i=0,12 do
        Characters.image[i+1]=love.graphics.newQuad(i*8, 0, 8, 8, Characters.sprite_sheet:getDimensions())
        player.sprite[i+1]=love.graphics.newQuad(i*8, 0, 8, 8, player.sprite_sheet:getDimensions())
    end
end

function Characters.keypressed(key)
    if key == 'up' then
        Characters.selected_index = math.max(1, Characters.selected_index - 1)
    elseif key == 'down' then
        Characters.selected_index = math.min(#Characters.list, Characters.selected_index + 1)
    elseif key == 'x' or key == 'return' then
        local chosen_char = Characters.list[Characters.selected_index]
        chosen_char.apply(player)
        Characters.load(player)
        _G.switchState("play")
        Musica_Atual:stop()
        if GameConfig.musica_antiga==false then
            Musica_Atual = Luta_Musica
        else
            Musica_Atual = Musica_Luta_Antiga
        end
        Musica_Atual:play()
        Musica_Atual:setLooping(true)
    end
end

function Characters.touchpressed(x, y)
    local w, h = love.graphics.getDimensions()
    local up = y < h * 0.4
    local down = y > h * 0.6
    local center = x > w * 0.4 and x < w * 0.6 and y > h * 0.4 and y < h * 0.6
    if up then Characters.keypressed('up') end
    if down then Characters.keypressed('down') end
    if center then Characters.keypressed('x') end
end

function Characters.draw()
    local Utils = require('utils')

    Utils.setColor(2)
    Utils.centerText(Lang.text("char_select_title"), 8)
    
    for i, char in ipairs(Characters.list) do
        local x, y
            
        if i <= 8 then
            -- Coluna 1 (Esquerda)
            x = 80 
            y = 24 + (i * 24)
        else
            -- Coluna 2 (Direita) - Vai para o outro lado
            x = 300
            -- O (i-8) faz com que o item 9 fique na posição do 1, o 10 na do 2, etc.
            y = 24 + ((i - 8) * 24) 
        end

        Utils.setColor(7)
        love.graphics.draw(Characters.sprite_sheet, Characters.image[i], x - 20, y, 0, 2, 2)
    end
    
    local selected_char = Characters.list[Characters.selected_index]
    if selected_char then
        Utils.setColor(0)
        -- Descrição agora retorna uma tabela de linhas
        local lines = selected_char.get_desc()
        for i, line in ipairs(lines) do
            love.graphics.print(line, (16)/2, 12 + (i * 8))
        end
    end
end

return Characters