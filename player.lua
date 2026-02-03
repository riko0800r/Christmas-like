local Utils   = require('utils')
local Waves   = require("wave")
local Camera  = require("camera")
local Shaders = require("shaders")
local Part    = require("part_rewards")
local Enemy = require("enemies")

local Player = {}
Player.__index = Player

local function dist(x1, y1, x2, y2)
    return math.sqrt((x2 - x1)^2 + (y2 - y1)^2)
end

local Estrelas_ICON = love.graphics.newImage("assets/EstrelaICON.png")

SFX_dano=love.audio.newSource("assets/dano.wav","static")
SFX_raio=love.audio.newSource("assets/Raio.wav","static")
local Lava=love.graphics.newImage("assets/Lava.png")
local neve=love.graphics.newImage("assets/neve.png")
local pedras=love.graphics.newImage("assets/pedra.png")
local rodas=love.graphics.newImage("assets/neve.png")
local sombriosSprite=love.graphics.newImage("assets/sombrio.png")
local CoinICON=love.graphics.newImage("assets/CoinICON.png")

local presente=love.graphics.newImage("assets/Presente2.png")

function Player:applyMultishot(spawn_function, spread_angle)
    -- Executa o spawn normal (1 projétil)
    spawn_function(self)
    
    -- Se não tiver multishot, retorna
    if not self.multishot_chance or self.multishot_chance <= 0 then
        return
    end
    
    -- Testa a chance de multishot
    if math.random() < self.multishot_chance then
        local extra_count = math.floor(self.multishot_count or 1)
        spread_angle = spread_angle or 0.3 -- Padrão: ~17 graus
        
        -- Dispara projéteis extras
        for i = 1, extra_count do
            self:multishotVisualEffect()
            -- Alterna entre esquerda e direita
            local offset = (i % 2 == 0) and spread_angle or -spread_angle
            local angle_multiplier = math.ceil(i / 2)
            
            -- Guarda o ângulo/posição original
            local original_angle = self.multishot_temp_angle or 0
            
            -- Modifica temporariamente para o spawn
            self.multishot_temp_angle = original_angle + (offset * angle_multiplier)
            
            -- Executa o spawn com o novo ângulo
            spawn_function(self)
            
            -- Restaura o ângulo original
            self.multishot_temp_angle = original_angle
        end
    end
end

function Player:applyCritical(base_damage)
    if self.crit_chance and math.random() < self.crit_chance then
        return base_damage * (self.crit_damage or 1.5), true
    end
    return base_damage, false
end

function Player.new()
    local self = setmetatable({}, Player)
    self.lifes = self.max_life
    self.x = 128*3
    self.y = 128
    self.dx = 0
    self.dy = 0
    self.f = 1
    self.s = 6
    self.t = 0
    self.lifes = 10
    self.speed = 3
    self.max_life = 10
    self.invul = 0
    self.sp = {1, 1}
    self.flp = 1
    self.tiros = 1
    self.tiro = false
    self.roda = false
    self.veneno = false
    self.fogo = false
    self.pedra = false
    self.tiro_time = 0
    self.roda_time = 0
    self.pedra_time = 0
    self.bullets = {}
    self.pedras = {}
    self.rodas = {}
    self.bala_speed = 3
    self.tiro_max_time = 1.4
    self.pedra_max_time = 3.25
    self.roda_max_time = 5
    self.demage = 1
    self.roda_size = 0
    self.tipo_jogador = 0
    self.regen_delay = 12
    self.regen_forca = 1
    self.regen = false
    self.veneno_dano = 0
    self.veneno_delay = 0.5
    self.fogo_dano = 0
    self.fogo_delay = 0.5
    self.gelo_dano = 0
    self.gelo_delay = 3
    self.gelo_slow  = 0.25
    self.vidas_por_rodada = 0
    self.width  = 16
    self.height = 16

    self.anel_ativo=false
    self.anel = {}
    self.anel_raio = 40
    self.anel_pontos = 4
    self.anel_velocidade = 0.25
    self.anel_tempo = 0.8
    self.anel_dano = 0.3
    
    self.sombrios={}
    self.sombrio_ativo=false
    self.sombrio_time=0
    self.sombrio_delay=4
    self.sombrio_quantidade=12
    
    -- Arma: Triângulos giratórios
    self.triangle = false                -- ativa/desativa arma
    self.triangle_time = 0               -- contador interno
    self.triangle_max_time = 2.5           -- tempo entre ataques (segundos) -> ajuste aqui
    self.triangle_angle = 0              -- ângulo atual (radianos)
    self.triangle_angle_step = math.rad(30) -- quanto gira a cada ataque (30° em rad)
    self.triangles = {}                  -- lista de triângulos ativos
    self.triangle_size = 12              -- tamanho do triângulo (distância do centro aos vértices)
    self.triangle_life = 2.25       -- tempo de vida de cada triângulo (segundos)
    self.triangle_damage = 2             -- dano que cada triângulo causa (ajuste)
    
    self.RaioDeLuz=false
    self.Raio_max_time=5
    self.Raio_time=0
    self.Raio_Size=24
    self.Raios={}
    self.Raio_life=2.5

    self.estrelas_natalinas = false
    self.estrelas_timer = 0
    self.estrelas_cooldown=2.5
    self.estrelas_count = 2
    self.pending_stars = {} -- Tabela para controlar quem vai ser atingido

    self.multishot_count = 1
    self.death_explosion = false
    self.explosion_damage = 0.25
    self.explosion_radius = 48
    self.attack_speed_mult = 1.0

        -- ESCUDO GIRATÓRIO
    self.escudo = false
    self.escudo_time = 0
    self.escudo_max_time = 3
    self.escudo_raio = 24
    self.escudo_laminas = 4
    self.escudos = {}
    self.escudo_velocidade = 4
    self.escudo_angle = 0
    self.escudo_damage = 1.5
    self.escudo_life = 2.5
    self.escudo_size = 8
    
    -- METEORO
    self.meteoro = false
    self.meteoro_time = 0
    self.meteoro_max_time = 2.5
    self.meteoros = {}
    self.meteoro_damage = 2
    self.meteoro_explosion_radius = 20
    self.meteoro_fall_speed = 3
    self.meteoro_spawn_count = 3
    self.meteoro_size = 6
    
    -- TEIA DE GELO
    self.teia = false
    self.teia_time = 0
    self.teia_max_time = 4
    self.teias = {}
    self.teia_base_radius = 30
    self.teia_max_radius = 80
    self.teia_slow_factor = 0.3
    self.teia_damage = 0.1
    self.teia_life = 3
    self.teia_grow_per_enemy = 5

    -- SISTEMA DE NÍVEIS DE ITENS
    self.item_levels = {
        ["Bola de neve"] = 0,
        ["Bloco de gelo"] = 0,
        ["Pedras do ceu"] = 0,
        ["Veneno mortal"] = 0,
        ["Fogo perigoso"] = 0,
        ["Imobilizador"] = 0,
        ["Vitalidade"] = 0,         -- Adicionado
        ["Anel de Lava"] = 0,
        ["Pedras Preciosas"] = 0,
        ["Espada triângular"] = 0,  -- Adicionado (caso use no futuro)
        ["Guirlanda"] = 0,          -- Adicionado
        ["Bumerangue"] = 0,         -- Adicionado
        ["Estrelas Natalinas"] = 0, -- Adicionado
        ["Drenagem Natalina"] = 0,  -- Adicionado (Roubo de vida)
        
        -- Sinergias (opcional manter aqui ou não, mas bom padronizar)
        ["Anel de renas"] = 0,
        ["Pedras que seguem"] = 0,
        ["Combo tóxico"] = 0,
    }

    -- SINERGIA 1: ANEL DE RENAS
    self.rena_ativo = false
    self.renas = {}
    self.rena_spawn_timer = 0
    self.rena_spawn_delay = 3
    self.rena_dano = 1
    self.rena_shoot_delay = 2
    self.sinergia_rena_disponivel = false

    -- SINERGIA 2: PEDRAS QUE SEGUEM
    self.pedra_seguidora_ativo = false
    self.pedras_seguidoras = {}
    self.pedra_seguidora_spawn_timer = 0
    self.pedra_seguidora_spawn_delay = 2
    self.sinergia_pedra_disponivel = false

    -- SINERGIA 3: COMBO TÓXICO
    self.combo_toxico_ativo = false
    self.combo_toxico_raio = 30
    self.sinergia_toxico_disponivel = false
    self.joystick=false

   
    self.guirlanda = false
    self.guirlanda_raio = 32
    self.guirlanda_dano = 0.4 -- Dano baixo, mas constante
    self.guirlanda_tick = 0   -- Temporizador para não dar dano todo frame
    self.guirlanda_tick_rate = 0.2 -- Causa dano a cada 0.2 segundos

    -- === NOVA ARMA 2: BUMERANGUE ===
    self.bumerangue = false
    self.bumerangues = {} -- Lista de bumerangues ativos
    self.bumerangue_time = 0
    self.bumerangue_delay = 1.8
    self.bumerangue_speed = 4
    self.bumerangue_range = 128 -- Distancia maxima que ele vai
    self.bumerangue_delay_hit = 0.05
    
    -- === POWER UPS ===
    self.speed_boost_timer = 0 -- Se maior que 0, o jogador está rápido
    
    -- Procure por self.lifes = 6 e adicione:
    self.lifesteal_chance = 0 -- Começa com 0% (ou 0.05 para 5%)
    
    -- ======== adição: estatísticas de dano ========
    self.stats = {
        weapons = {},      -- mapa name -> total_damage
        total_damage = 0,  -- soma de todos os danos
    }
    -- helper para registrar dano
    function self:recordDamage(weapon_name, amount)
        amount = tonumber(amount) or 0
        self.stats.total_damage = (self.stats.total_damage or 0) + amount
        self.stats.weapons[weapon_name] = (self.stats.weapons[weapon_name] or 0) + amount
    end

    self.stats_elemental = {
        veneno = {
            ativo = false,
            dano_total = 0,
            aplicacoes = 0,  -- quantas vezes foi aplicado
            nivel = 0,
        },
        fogo = {
            ativo = false,
            dano_total = 0,
            aplicacoes = 0,
            nivel = 0,
        },
        gelo = {
            ativo = false,
            dano_total = 0,
            aplicacoes = 0,
            nivel = 0,
        }
    }

    -- Helper para registrar dano elemental
    function self:recordElementalDamage(element_type, amount)
        if self.stats_elemental[element_type] then
            amount = tonumber(amount) or 0
            self.stats_elemental[element_type].dano_total = (self.stats_elemental[element_type].dano_total or 0) + amount
            self.stats.total_damage=(self.stats.total_damage or 0) + amount
        end
    end
    
    -- Helper para registrar aplicação de efeito
    function self:recordElementalApplication(element_type)
        if self.stats_elemental[element_type] then
            self.stats_elemental[element_type].aplicacoes = (self.stats_elemental[element_type].aplicacoes or 0) + 1
        end
    end

    self.hitbox_w = 6
    self.hitbox_h = 6
    self.hitbox_off_x = 5
    self.hitbox_off_y = 5

    self.money = 30
    self.active_item = nil
    self.relics = {}
    
    self.coin_magnet_range = 40

    self.multishot_chance = 0      -- Chance de disparar projéteis extras (0-1)
    self.multishot_count = 1       -- Quantos projéteis extras disparar
    self.crit_chance = 0           -- Chance de crítico
    self.crit_damage = 1.5         -- Multiplicador de dano crítico

    return self
end

function Player:useActiveItem()
    if not self.active_item then return end
    
    local used = false
    
    if self.active_item == "potion" then
        if self.lifes < self.max_life then
            self.lifes = math.min(self.max_life, self.lifes + 5)
            used = true
            -- Efeito visual
            local part = require("part")
            part.add(self.x, self.y, 20, 11) -- Verde
        end
    elseif self.active_item == "bomb" then
        local Enemy = require("enemies")
        Enemy.damageAll(4)
        used = true
        -- Shake e flash
        local Camera = require("camera")
        Camera:shake(2, 2)
        local Shaders = require("shaders")
        Shaders:applyHitFlash(1.0)
    end
    
    if used then
        self.active_item = nil -- Consome o item
    end
end

function Player:update(dt, enemies, time)
    if self.lifes <= 0 then
        self = Player.new()
        return
    end

    local current_speed = self.speed

    local move_x, move_y = 0, 0
    if love.keyboard.isDown('up') or love.keyboard.isDown('w') then
        move_y = -current_speed
    elseif love.keyboard.isDown('down') or love.keyboard.isDown('s') then 
        move_y = current_speed 
    end

    if love.keyboard.isDown('left') or love.keyboard.isDown('a') then 
        move_x = -current_speed; self.flp = 1
    elseif love.keyboard.isDown('right') or love.keyboard.isDown('d') then 
        move_x = current_speed; self.flp = -1 
    end
    if self.joystick then
        move_x = self.dx
        move_y = self.dy
        if self.dx>0 then
            self.flp=-1
        else
            self.flp=1
        end
    end
    self.x = self.x + move_x * dt * 60
    self.y = self.y + move_y * dt * 60

    self.x = math.max(0, math.min(self.x, 128*4 - 16))
    self.y = math.max(0, math.min(self.y, 128*2 - 16))

    -- Atualiza itens base
    if self.tiro then self:checkTiroSpawn(dt) end
    if self.roda then self:checkRodaSpawn(dt) end
    if self.pedra then self:checkPedraSpawn(dt) end
    if self.sombrio_ativo then self:checkSombrioSpawn(dt) end
    if self.triangle then self:checkTriangleSpawn(dt) end
    if self.RaioDeLuz then self:checkRaioSpawn(dt) end
    if self.escudo then self:checkEscudoSpawn(dt) end
    if self.meteoro then self:checkMeteorSpawn(dt) end
    if self.teia then self:checkTeiaSpawn(dt) end

    if self.guirlanda then
        self.guirlanda_tick = self.guirlanda_tick + dt
        if self.guirlanda_tick >= self.guirlanda_tick_rate then
            self.guirlanda_tick = 0
            -- Verifica colisão circular com todos inimigos
            for _, e in ipairs(enemies) do
                local dist = math.sqrt((e.x - self.x)^2 + (e.y - self.y)^2)
                if dist <= self.guirlanda_raio + (e.w/2) then
                    self:recordDamage("Guirlanda", self.guirlanda_dano)
                    e:takeDamage(self.guirlanda_dano, self)
                    -- Aplica efeitos elementais
                    if self.veneno then e.veneno = true end
                    if self.fogo then e.fogo = true end
                    if self.gelo then e.gelo = true end
                end
            end
        end
    end

   if enemies then
        self:updateTriangles(dt, enemies)
        self:updateBullets(dt, enemies)
        self:updateRodas(dt, enemies)
        self:updatePedras(dt, enemies)
        self:updateSombrios(dt, enemies)
        self:updateRaio(dt, enemies)
        self:updateBumerangues(dt, enemies)
        self:updateEscudo(dt, enemies)
        self:updateMeteoro(dt, enemies)
        self:updateTeia(dt, enemies)
        if self.estrelas_natalinas then self:checkEstrelaSpawn(dt, enemies) end
        if self.bumerangue then self:CheckSpawnBumerangue(dt,enemies) end
    end

    if self.veneno then
        self.stats_elemental.veneno.ativo = true
        self.stats_elemental.veneno.nivel = self.item_levels["Veneno mortal"] or 0
    end
    if self.fogo then
        self.stats_elemental.fogo.ativo = true
        self.stats_elemental.fogo.nivel = self.item_levels["Fogo perigoso"] or 0
    end
    if self.gelo then
        self.stats_elemental.gelo.ativo = true
        self.stats_elemental.gelo.nivel = self.item_levels["Imobilizador"] or 0
    end

    self.invul = math.max(0, self.invul - dt)

    if self.anel_ativo then
        self.anel_tempo = self.anel_tempo + dt * self.anel_velocidade
        self.anel = {}
        for i = 1, self.anel_pontos do
            local angulo = (i / self.anel_pontos) * 2 * math.pi + self.anel_tempo
            local raio = self.anel_raio + math.sin(self.anel_tempo * 2 + i) * 4
            local x = self.x + self.width / 2 + math.cos(angulo) * raio
            local y = self.y + self.height / 2 + math.sin(angulo) * raio
            table.insert(self.anel, {x = x, y = y, r = 4})
        end

        for _, p in ipairs(self.anel) do
            for _, e in ipairs(enemies) do
                if e.lifes > 0 then
                    local dx = e.x + e.w/2 - p.x
                    local dy = e.y + e.h/2 - p.y
                    local dist = math.sqrt(dx*dx + dy*dy)
                    if dist < (p.r + e.w/2) then
                        local dmg, is_crit = self:applyCritical(self.anel_dano/4)
                        -- Efeito visual de crítico
                        if is_crit then
                            local part = require("part")
                            part.add(e.x, e.y, 15, 10) -- Partículas amarelas
                        end
                        self:recordDamage("presente dourado", dmg)
                        e:takeDamage(dmg, self)
                        if self.veneno then e.veneno = true end
                        if self.fogo then e.fogo = true end
                        if self.gelo then e.gelo = true end
                    end
                end
            end
        end
    end
    
    if self.estrelas_natalinas then
        -- 2. ATUALIZAR ESTRELAS PENDENTES
        for i = #self.pending_stars, 1, -1 do
            local s = self.pending_stars[i]
            s.timer = s.timer - dt
            
            -- Se o inimigo morreu antes da estrela cair, removemos a mira
            if s.enemy.lifes <= 0 then 
                table.remove(self.pending_stars, i)
            end
            if s.timer <= 0 then
                -- 3. MOMENTO DO IMPACTO
                local dmg = self.demage
                self:recordDamage("Estrelas Natalinas", dmg)
                s.enemy.takeDamage(s.enemy,dmg)
                if self.veneno then s.enemy.veneno = true end
                if self.fogo then s.enemy.fogo = true end
                if self.gelo then s.enemy.gelo = true end
                -- Efeito de explosão e rastro (usando seu sistema de Part)
                for j=1, 2 do
                    Part.spawn(s.enemy.x, s.enemy.y, {
                        vx = (math.random(-192,192)),
                        vy = (math.random(-64,8)),
                        life  = 1.25,
                        alpha = 0.85,
                        color = {1, 1, 1},
                        image = Estrelas_ICON,
                        gravity=64,
                        size = math.random(16,32),
                    })
                end
                table.remove(self.pending_stars, i)
            end
        end
    end

    if self.invul <= 0 then
        self:checkPlayerCollision(enemies)
    end
end

function Player:onWaveEnd()
    if self.regen then
        -- Usa 'vidas_por_rodada' se definido, senão usa 1 como padrão
        local cura = self.vidas_por_rodada or 1
        
        if self.lifes < self.max_life then
            self.lifes = math.min(self.max_life, self.lifes + cura)
            
            -- Efeito visual e sonoro de cura
            local Part = require("part") -- Garante que temos acesso às partículas
            Part.add(self.x, self.y, 15, 2)
            
            -- Se tiver o som de pegar vida definido globalmente ou localmente
            if SFX_Pickup_Heart then 
                SFX_Pickup_Heart:play() 
            end
        end
    end
end

function Player:CheckSpawnBumerangue(dt,enemies)
    self.bumerangue_time = self.bumerangue_time + dt
    if self.bumerangue_time >= self.bumerangue_delay then
        local function spawn_single_bumerangue(player)   
            -- Escolhe uma direção cardeal aleatória (Cima, Baixo, Esquerda, Direita)
            local dirs = {
                {x=0, y=-1}, -- Cima
                {x=0, y=1},  -- Baixo
                {x=-1, y=0}, -- Esquerda
                {x=1, y=0},   -- Direita
                {x=-1, y=-1}, -- Cima
                {x=1, y=1},  -- Baixo
                {x=-1, y=1}, -- Esquerda
                {x=-1, y=1},   -- Direita
            }
            
            local dir = dirs[love.math.random(1, 8)]
            table.insert(self.bumerangues, {
                x = self.x + 8,
                y = self.y + 8,
                start_x = self.x + 8,
                start_y = self.y + 8,
                dx = dir.x,
                dy = dir.y,
                state = "going", -- "going" ou "returning"
                dist_traveled = 0,
                gifts = {}, -- Presentes que ele solta
                gift_timer = 0,
                rot = 0,
                hitbox_w = 28,
                hitbox_h = 28,
                hitbox_off_x = -8,
                hitbox_off_y = -8,
                hit_delay_atual=0,
                hit_delay_timer=self.bumerangue_delay_hit,
            })
        end
        self:applyMultishot(spawn_single_bumerangue, 0.4)
        self.bumerangue_time = 0
    end
end

function Player:updateBumerangues(dt, enemies)
    local Utils = require("utils")
    
    -- Percorre de trás para frente para poder remover itens sem bugar o loop
    for i = #self.bumerangues, 1, -1 do
        local b = self.bumerangues[i]
        
        b.rot = b.rot + 15 * dt -- Rotação visual

        local return_to_player = false

        b.hit_delay_atual=b.hit_delay_atual-1/60

        if b.state == "going" then
            -- Movimento de ida
            local move = self.bumerangue_speed * 35 * dt
            b.x = b.x + b.dx * move
            b.y = b.y + b.dy * move
            b.dist_traveled = b.dist_traveled + move
            
            -- Se atingiu o limite, começa a voltar
            if b.dist_traveled >= self.bumerangue_range then
                b.state = "returning"
            end
            
        elseif b.state == "returning" then
            -- Volta para o player
            local dx = (self.x + 8) - b.x
            local dy = (self.y + 8) - b.y
            local dist = math.sqrt(dx*dx + dy*dy)
            
            if dist > 0 then
                b.x = b.x + (dx/dist) * (self.bumerangue_speed * 2) * 60 * dt
                b.y = b.y + (dy/dist) * (self.bumerangue_speed * 2) * 60 * dt
            end

            -- Solta presentes no caminho de volta
            b.gift_timer = b.gift_timer + dt
            if b.gift_timer >= 0.1 then -- Solta a cada 0.45s
                b.gift_timer = 0
                table.insert(b.gifts, {
                    x = b.x, y = b.y, 
                    w = 1, h = 1 -- Ajustei o tamanho da hitbox (32 era muito grande)
                })
            end
            
            -- Se chegou perto o suficiente do player, marca para remover
            if dist < 5 then
                return_to_player = true
            end
        end

        if return_to_player then
            -- Remove o bumerangue inteiro. 
            -- Como os presentes estão dentro de 'b.gifts', eles somem junto automaticamente!
            table.remove(self.bumerangues, i)
        else
            -- === ATUALIZAÇÃO DE COLISÃO (Só processa se o bumerangue ainda existe) ===

            -- 1. Colisão do Bumerangue (o objeto voando) com Inimigos
            local rectB = {x=b.x-4, y=b.y-4, w=28, h=28}
            for _, e in ipairs(enemies) do
                if Utils.col(rectB, {x=e.x, y=e.y, w=e.w, h=e.h}) and b.hit_delay_atual<=0 then
                    self:recordDamage("Bumerangue", self.demage)
                    e:takeDamage(self.demage, self)
                    if self.veneno then e.veneno = true end
                    if self.fogo then e.fogo = true end
                    if self.gelo then e.gelo = true end
                    b.hit_delay_atual=b.hit_delay_timer
                end
            end
        end
    end
end

-- ============== SINERGIA 1: ANEL DE RENAS ==============
function Player:updateRenas(dt, enemies)
    -- Spawna renas periodicamente
    self.rena_spawn_timer = self.rena_spawn_timer + dt
    local nivel = self.item_levels["Anel de renas"] or 1
    if self.rena_spawn_timer >= self.rena_spawn_delay / nivel then
        self:spawnRena()
        self.rena_spawn_timer = 0
    end

    -- Atualiza renas existentes
    for i = #self.renas, 1, -1 do
        local rena = self.renas[i]
        
        -- Shoot timer
        rena.shoot_timer = rena.shoot_timer + dt
        if rena.shoot_timer >= self.rena_shoot_delay then
            self:renaShoot(rena, enemies)
            rena.shoot_timer = 0
        end

        -- Move em direção ao inimigo mais próximo
        local target = Utils.findNearest(rena, enemies)
        if target then
            local dx, dy = target.x - rena.x, target.y - rena.y
            local dist = math.sqrt(dx*dx + dy*dy)
            if dist > 0 then
                rena.x = rena.x + (dx / dist) * rena.speed * dt * 60
                rena.y = rena.y + (dy / dist) * rena.speed * dt * 60
            end
            
            -- Colisão com inimigo
            if Utils.col(rena, target) then
                target:takeDamage(self.rena_dano, self)
                table.remove(self.renas, i)
            end
        end

        -- Atualiza projéteis da rena
        if rena.bullets then
            for j = #rena.bullets, 1, -1 do
                local b = rena.bullets[j]
                local btarget = Utils.findNearest(b, enemies)
                if btarget then
                    local dx, dy = btarget.x - b.x, btarget.y - b.y
                    local dist = math.sqrt(dx*dx + dy*dy)
                    if dist > 0 then
                        b.x = b.x + (dx / dist) * b.speed * dt * 60
                        b.y = b.y + (dy / dist) * b.speed * dt * 60
                    end
                    
                    if Utils.col(b, btarget) then
                        btarget:takeDamage(self.rena_dano * 0.5, self)
                        table.remove(rena.bullets, j)
                    end
                else
                    table.remove(rena.bullets, j)
                end
            end
        end
    end
end

function Player:spawnRena()
    table.insert(self.renas, {
        x = self.x + self.width / 2,
        y = self.y + self.height / 2,
        speed = 2,
        shoot_timer = 0,
        bullets = {},
        width = 4,
        height = 4
    })
end

function Player:renaShoot(rena, enemies)
    local target = Utils.findNearest(rena, enemies)
    if target then
        table.insert(rena.bullets, {
            x = rena.x,
            y = rena.y,
            speed = 3,
            width = 8,
            height = 8
        })
    end
end

-- ============== SINERGIA 2: PEDRAS QUE SEGUEM ==============
function Player:updatePedrasSeguidoras(dt, enemies)
    self.pedra_seguidora_spawn_timer = self.pedra_seguidora_spawn_timer + dt
    local nivel = self.item_levels["Pedras que seguem"] or 1
    
    if self.pedra_seguidora_spawn_timer >= self.pedra_seguidora_spawn_delay then
        -- Spawna várias pedras em locais aleatórios
        for i = 1, 3 + nivel do
            local rx = math.random(16, 128*4 - 16)
            local ry = -16
            table.insert(self.pedras_seguidoras, {
                x = rx,
                y = ry,
                fase = "caindo",
                speed = 4,
                chase_speed = 2,
                width = 8,
                height = 8
            })
        end
        self.pedra_seguidora_spawn_timer = 0
    end

    for i = #self.pedras_seguidoras, 1, -1 do
        local p = self.pedras_seguidoras[i]
        
        if p.fase == "caindo" then
            p.y = p.y + p.speed * dt * 60
            if p.y >= 128 then
                p.fase = "perseguindo"
            end
        elseif p.fase == "perseguindo" then
            local target = Utils.findNearest(p, enemies)
            if target then
                local dx, dy = target.x - p.x, target.y - p.y
                local dist = math.sqrt(dx*dx + dy*dy)
                if dist > 0 then
                    p.x = p.x + (dx / dist) * p.chase_speed * dt * 60
                    p.y = p.y + (dy / dist) * p.chase_speed * dt * 60
                end
                
                if Utils.col(p, target) then
                    target:takeDamage(self.demage * 0.25, self)
                    table.remove(self.pedras_seguidoras, i)
                end
            else
                table.remove(self.pedras_seguidoras, i)
            end
        end
    end
end

-- ============== SINERGIA 3: COMBO TÓXICO ==============
function Player:updateComboToxico(dt, enemies)
    for _, e in ipairs(enemies) do
        if e.lifes > 0 then
            -- Dano em área circular em volta do inimigo
            for _, other in ipairs(enemies) do
                if other ~= e and other.lifes > 0 then
                    local dx = other.x - e.x
                    local dy = other.y - e.y
                    local dist = math.sqrt(dx*dx + dy*dy)
                    
                    if dist < self.combo_toxico_raio then
                        other:takeDamage(0.15 * dt, self)
                    end
                end
            end
        end
    end
end

-- ============== ITENS BASE ==============
function Player:checkTiroSpawn(dt)
    self.tiro_time = self.tiro_time + dt
    if self.tiro_time >= self.tiro_max_time then
        local function spawn_single_bullet(player)
            table.insert(player.bullets, {
                x = player.x + player.width / 2, 
                y = player.y + player.height / 2, 
                speed = player.bala_speed, 
                tipo = "normal", 
                width = 4, 
                height = 4,
                hitbox_w = 8,
                hitbox_h = 8,
                hitbox_off_x = 0,
                hitbox_off_y = 0
            })
        end
        self:applyMultishot(spawn_single_bullet, 0.25)
        self.tiro_time = 0
    end
end

function Player:checkRaioSpawn(dt)
    self.Raio_time = self.Raio_time + dt
    if self.Raio_time >= self.Raio_max_time then
        local function spawn_single_raio(player)
            player:spawnRaio()
        end
        self:applyMultishot(spawn_single_raio, 0.4)
        self.Raio_time = 0
    end
end

function Player:spawnRaio()
    local x_offset = (self.multishot_temp_angle or 0) * 40 -- Offset horizontal
    for i = 0, 1 do
        table.insert(self.Raios, {
            x = self.x + self.width / 2 + x_offset, 
            y = 0,
            dx = 0,
            dy = 0,
            life_timer = self.Raio_life,
            width = 32,
            height = 256
        })
    end
end

function Player:updateRaio(dt, enemies)
    for i = #self.Raios, 1, -1 do
        local b = self.Raios[i]
        local removed = false
        b.x = b.x + b.dx * dt * 60
        b.y = b.y + b.dy * dt * 60
        b.life_timer = b.life_timer - dt * 60
        if b.life_timer <= 0 then
            table.remove(self.rodas, i)
            removed = true
        end
        if not removed then
            for j = #enemies, 1, -1 do
                local e = enemies[j]
                if e.lifes > 0 and Utils.col(b, e) then
                    e:takeDamage(self.demage, self)
                    if self.veneno then e.veneno = true end
                    if self.fogo then e.fogo = true end
                    if self.gelo then e.gelo = true end
                    break
                end
            end
        end
    end
end

function Player:checkRodaSpawn(dt)
    self.roda_time = self.roda_time + dt
    if self.roda_time >= self.roda_max_time then
        local function spawn_single_roda(player)
            player:spawnRodas(10 + player.roda_size, 2 * 60 * dt)
        end
        self:applyMultishot(spawn_single_roda, 0.5)
        self.roda_time = 0
    end
end

function Player:spawnRodas(num, speed)
    for i = 0, num - 1 do
        local angle = (i / num) * 2 * math.pi
        table.insert(self.rodas, {
            x = self.x + self.width / 2, y = self.y + self.height / 2,
            dx = math.cos(angle) * speed,
            dy = math.sin(angle) * speed,
            life_timer = 3.5,
            width = 8, height = 8,
            hitbox_w = 8,
            hitbox_h = 8,
            hitbox_off_x = -2, -- (16 - 10) / 2
            hitbox_off_y = -2
        })
    end
end

function Player:checkSombrioSpawn(dt)
    self.sombrio_time = self.sombrio_time + dt
    if self.sombrio_time >= self.sombrio_delay then
        -- Função de spawn individual
        local function spawn_single_sombrio(player)
            local angle_offset = player.multishot_temp_angle or 0
            
            for i = 1, player.sombrio_quantidade do
                local base_angle = -math.pi / 2 + love.math.random(-0.3, 0.3)
                local angle = base_angle + angle_offset
                local speed = love.math.random(45, 135)
                local dx = math.cos(angle) * speed
                local dy = math.sin(angle) * speed
                
                if i % 2 == 0 then
                    table.insert(player.sombrios, {
                        x = player.x + player.width / 2,
                        y = player.y,
                        dx = dx,
                        dy = dy,
                        life_timer = love.math.random(8, 12),
                        width = 8, height = 8,
                        hitbox_w = 8, hitbox_h = 8,
                        hitbox_off_x = -4,
                        hitbox_off_y = -4
                    })
                else
                    table.insert(player.sombrios, {
                        x = player.x + player.width / 2,
                        y = player.y,
                        dx = dx,
                        dy = -dy,
                        life_timer = love.math.random(8, 12),
                        width = 8, height = 8,
                        hitbox_w = 8, hitbox_h = 8,
                        hitbox_off_x = -4,
                        hitbox_off_y = -4
                    })
                end
            end
        end
        
        -- Aplica multishot
        self:applyMultishot(spawn_single_sombrio, 0.35)
        self.sombrio_time = 0
    end
end

function Player:updateSombrios(dt, enemies)
    for i = #self.sombrios, 1, -1 do
        local b = self.sombrios[i]
        local removed = false

        b.x = b.x + b.dx * dt
        b.y = b.y + b.dy * dt
        b.x = b.x + math.sin(love.timer.getTime() * 8 + i) * 0.8

        b.life_timer = b.life_timer - dt
        if b.life_timer <= 0 or b.y < -16 then
            table.remove(self.sombrios, i)
            removed = true
        end

        if not removed then
            for j = #enemies, 1, -1 do
                local e = enemies[j]
                if e.lifes > 0 and Utils.col(b, e) then
                    e:takeDamage(self.demage * 0.5, self)
                    self:recordDamage("Pedras preciosas", self.demage*0.5)
                    if self.veneno then e.veneno = true end
                    if self.fogo then e.fogo = true end
                    if self.gelo then e.gelo = true end
                    table.remove(self.sombrios, i)
                    removed = true
                    break
                end
            end
        end
    end
end

function Player:checkPedraSpawn(dt)
    self.pedra_time = self.pedra_time + dt
    if self.pedra_time >= self.pedra_max_time then
        local function spawn_single_pedra(player)
            local base_x = player.x + player.width / 2
            local offset = player.multishot_temp_angle or 0
            
            for i = -3, 3 do
                local x_offset = (i * 12) + (offset * 20) -- Espalha horizontalmente
                table.insert(player.pedras, {
                    x = base_x + x_offset,
                    y = 1,
                    speed = 4 * 60 * dt,
                    life_timer = 4,
                    width = 14, height = 12,
                    hitbox_w = 14,
                    hitbox_h = 12,
                    hitbox_off_x = -7,
                    hitbox_off_y = -4
                })
            end
        end
        self:applyMultishot(spawn_single_pedra, 1.0)
        self.pedra_time = 0
    end
end

function Player:updateBullets(dt, enemies)
    for i = #self.bullets, 1, -1 do
        local b = self.bullets[i]
        local target = Utils.findNearest(b, enemies)
        local removed = false
        if target then
            local dx, dy = target.x - b.x, target.y - b.y
            local dist = Utils.distance(b, target)
            if dist > 0 then
                b.x = b.x + (dx / dist) * b.speed
                b.y = b.y + (dy / dist) * b.speed
            end
        else
            table.remove(self.bullets, i)
            removed = true
        end
        if not removed then
            for j = #enemies, 1, -1 do
                local e = enemies[j]
                if e.lifes > 0 and Utils.col(b, e) then
                    local dmg = self.demage
                    self:recordDamage("Bola de neve", dmg)
                    e:takeDamage(dmg, self)
                    if self.veneno then e.veneno = true end
                    if self.fogo then e.fogo = true end
                    if self.gelo then e.gelo = true end
                    table.remove(self.bullets, i)
                    removed = true
                    break
                end
            end
        end
    end
end

function Player:updateRodas(dt, enemies)
    for i = #self.rodas, 1, -1 do
        local b = self.rodas[i]
        local removed = false
        b.x = b.x + b.dx * dt * 60
        b.y = b.y + b.dy * dt * 60
        b.life_timer = b.life_timer - dt
        if b.life_timer <= 0 then
            table.remove(self.rodas, i)
            removed = true
        end
        if not removed then
            for j = #enemies, 1, -1 do
                local e = enemies[j]
                if e.lifes > 0 and Utils.col(b, e) then
                    local dmg = self.demage / 2.5
                    self:recordDamage("Bloco de gelo", dmg)
                    e:takeDamage(dmg, self)
                    if self.veneno then e.veneno = true end
                    if self.fogo then e.fogo = true end
                    if self.gelo then e.gelo = true end
                    table.remove(self.rodas, i)
                    removed = true
                    break
                end
            end
        end
    end
end

function Player:updatePedras(dt, enemies)
    for i = #self.pedras, 1, -1 do
        local b = self.pedras[i]
        local removed = false
        local time_factor = love.timer.getTime() * 1.25
        b.x = b.x + (math.random(-0.75,0.75)) * 2 - math.cos(time_factor*3) * dt
        b.y = b.y + b.speed * dt * 60 + math.sin(time_factor*2) * dt
        b.life_timer = b.life_timer - dt
        if b.life_timer <= 0 then
            table.remove(self.pedras, i)
            removed = true
        end
        if not removed then
            for j = #enemies, 1, -1 do
                local e = enemies[j]
                if e.lifes > 0 and Utils.col(b, e) then
                    local dmg = self.demage * 3
                    self:recordDamage("Pedra do ceu", dmg)
                    e:takeDamage(dmg, self)
                    if self.veneno then e.veneno = true end
                    if self.fogo then e.fogo = true end
                    if self.gelo then e.gelo = true end
                    table.remove(self.pedras, i)
                    removed = true
                    break
                end
            end
        end
    end
end

-- Checa timer e cria triângulo quando for hora
function Player:checkTriangleSpawn(dt)
    self.triangle_time = self.triangle_time + dt
    if self.triangle_time >= self.triangle_max_time then
        self:spawnTriangle()
        self.triangle_time = 0
    end
end

-- Cria 1 triângulo (pode criar mais se quiser)
function Player:spawnTriangle()
    -- cria um triângulo centrado no jogador com o ângulo atual
    local t = {
        x = self.x + (self.width or 8) / 2, -- centraliza no player (ajuste se seu player.width existir)
        y = self.y + (self.height or 8) / 2,
        angle = self.triangle_angle,
        size = self.triangle_size,
        life_timer = self.triangle_life,
        damage = self.triangle_damage
    }
    table.insert(self.triangles, t)

    -- gira sentido horário a cada ataque (ajusta sinal se precisar inverter)
    self.triangle_angle = (self.triangle_angle + self.triangle_angle_step) % (2 * math.pi)
end

-- Atualiza triângulos (movimento, vida e colisão com inimigos)
-- enemies deve ser a tabela global ou passada pela rotina update do player
function Player:updateTriangles(dt, enemies)
    for i = #self.triangles, 1, -1 do
        local t = self.triangles[i]
        t.life_timer = t.life_timer - dt
        t.y=t.y+t.life_timer
        if t.life_timer <= 0 then
            table.remove(self.triangles, i)
        else
            -- exemplo de checagem simples: quero que o triângulo permaneça estático em volta do jogador
            -- mas você pode fazê-lo rotacionar e mover se desejar.
            -- Verifica colisão com inimigos (supondo Utils.col funciona com rect/circles)
            for j = #enemies, 1, -1 do
                local e = enemies[j]
                if e and e.lifes and e.lifes > 0 then
                    -- aproximação: testa se distância entre centro do triângulo e inimigo < size + enemy_size
                    local dx = e.x - t.x
                    local dy = e.y - t.y
                    local d = math.sqrt(dx*dx + dy*dy)
                    if d < (t.size + (e.width or 8)) then
                        -- causa dano e remove triângulo (se quiser que triângulo persista, comente a linha abaixo)
                        e:takeDamage(t.damage, self)
                        table.remove(self.triangles, i)
                        break
                    end
                end
            end
        end
    end
end

-- Função auxiliar que desenha um triângulo rotacionado (centrado em t.x,t.y)
function Player:drawTriangle(t)
    love.graphics.push()
    love.graphics.translate(t.x, t.y)
    love.graphics.rotate(t.angle)
    local s = t.size
    -- triângulo apontando para cima antes da rotação (vértices relativos ao centro)
    local verts = { 0, -s,  s, s,  -s, s }
    love.graphics.polygon("fill", verts)
    love.graphics.pop()
end

function Player:checkEstrelaSpawn(dt, enemies)
    self.estrelas_timer = self.estrelas_timer + dt
    if self.estrelas_timer >= self.estrelas_cooldown then
        local function spawn_single_estrela(player)
            local base_count = player.estrelas_count
            
            -- CORREÇÃO AQUI: 'enemies' já é a lista, não precisa de .get_all()
            local inimigos = enemies
            
            -- Verificação de segurança se existem inimigos
            if inimigos and #inimigos > 0 then
                local extra = (player.multishot_temp_angle and 1 or 0)
                for i = 1, base_count + extra do
                    local alvo = inimigos[math.random(1, #inimigos)]
                    table.insert(self.pending_stars, {
                        enemy = alvo,
                        timer = 1.125,
                        hit = false
                    })
                end
            end
        end
        
        self:applyMultishot(spawn_single_estrela, 0)
        self.estrelas_timer = 0
    end
end


function Player:checkEscudoSpawn(dt)
    if not self.escudo then return end
    
    self.escudo_time = self.escudo_time + dt
    if self.escudo_time >= self.escudo_max_time then
        self:spawnEscudo()
        self.escudo_time = 0
    end
end

function Player:spawnEscudo()
    local function spawn_single_escudo(player)
        for i = 0, player.escudo_laminas - 1 do
            local angle = (i / player.escudo_laminas) * 2 * math.pi + player.escudo_angle
            local x = player.x + player.width / 2 + math.cos(angle) * player.escudo_raio
            local y = player.y + player.height / 2 + math.sin(angle) * player.escudo_raio
            
            table.insert(player.escudos, {
                x = x, y = y,
                angle = angle,
                life_timer = player.escudo_life,
                width = player.escudo_size,
                height = player.escudo_size,
                hitbox_w = player.escudo_size,
                hitbox_h = player.escudo_size,
                hitbox_off_x = -player.escudo_size / 2,
                hitbox_off_y = -player.escudo_size / 2,
                rotation = angle
            })
        end
    end
    
    self:applyMultishot(spawn_single_escudo, 0.4)
    self.escudo_angle = self.escudo_angle + math.rad(45)
end

function Player:updateEscudo(dt, enemies)
    self.escudo_angle = self.escudo_angle + self.escudo_velocidade * dt
    
    for i = #self.escudos, 1, -1 do
        local b = self.escudos[i]
        local removed = false
        
        b.life_timer = b.life_timer - dt
        
        local angle = b.angle + self.escudo_velocidade * dt
        b.x = self.x + self.width / 2 + math.cos(angle) * self.escudo_raio
        b.y = self.y + self.height / 2 + math.sin(angle) * self.escudo_raio
        b.rotation = angle
        
        if b.life_timer <= 0 then
            table.remove(self.escudos, i)
            removed = true
        end
        
        if not removed then
            for j = #enemies, 1, -1 do
                local e = enemies[j]
                if e.lifes > 0 and Utils.col(b, e) then
                    e:takeDamage(self.escudo_damage, self)
                    
                    if self.veneno then e.veneno = true end
                    if self.fogo then e.fogo = true end
                    if self.gelo then e.gelo = true end
                    
                    part.add(b.x, b.y, 5, 3)
                    
                    local dx, dy = e.x - self.x, e.y - self.y
                    local mag = math.sqrt(dx^2 + dy^2)
                    if mag > 0 then
                        e.x = e.x + (dx/mag) * 3
                        e.y = e.y + (dy/mag) * 3
                    end
                end
            end
        end
    end
end

function Player:drawEscudo()
    if not self.escudo or #self.escudos == 0 then return end
    
    love.graphics.setColor(0, 0.8, 1, 0.7)
    for _, b in ipairs(self.escudos) do
        love.graphics.push()
        love.graphics.translate(b.x, b.y)
        love.graphics.rotate(b.rotation)
        love.graphics.polygon("fill", 
            0, -b.width,
            b.width, 0,
            0, b.width,
            -b.width, 0
        )
        love.graphics.pop()
    end
    love.graphics.setColor(1, 1, 1, 1)
end

function Player:checkMeteorSpawn(dt)
    if not self.meteoro then return end
    
    self.meteoro_time = self.meteoro_time + dt
    if self.meteoro_time >= self.meteoro_max_time then
        self:spawnMeteor()
        self.meteoro_time = 0
    end
end

function Player:spawnMeteor()
    local function spawn_single_meteor(player)
        for i = 1, player.meteoro_spawn_count do
            local x = math.random(32, 512 - 32)
            local y = -16
            
            table.insert(player.meteoros, {
                x = x, y = y,
                dx = (love.math.random() - 0.5) * 1,
                dy = player.meteoro_fall_speed,
                life_timer = 5,
                width = player.meteoro_size * 2,
                height = player.meteoro_size * 2,
                hitbox_w = player.meteoro_size * 2,
                hitbox_h = player.meteoro_size * 2,
                hitbox_off_x = -player.meteoro_size,
                hitbox_off_y = -player.meteoro_size,
                exploded = false
            })
        end
    end
    
    self:applyMultishot(spawn_single_meteor, 0.3)
end

function Player:updateMeteoro(dt, enemies)
    for i = #self.meteoros, 1, -1 do
        local m = self.meteoros[i]
        local removed = false
        
        m.x = m.x + m.dx * dt * 60
        m.y = m.y + m.dy * dt * 60
        m.life_timer = m.life_timer - dt
        
        if m.y > 256 or m.life_timer <= 0 or m.exploded then
            for j = #enemies, 1, -1 do
                local e = enemies[j]
                local dist_p = dist(m.x, m.y, e.x, e.y)
                if dist_p < self.meteoro_explosion_radius and e.lifes > 0 then
                    e:takeDamage(self.meteoro_damage, self)
                    if self.veneno then e.veneno = true end
                    if self.fogo then e.fogo = true end
                    if self.gelo then e.gelo = true end
                end
            end
            
            part.add(m.x, m.y, 12, 8)
            part.add(m.x, m.y, 8, 9)
            
            table.remove(self.meteoros, i)
            removed = true
        end
        
        if not removed then
            for j = #enemies, 1, -1 do
                local e = enemies[j]
                if e.lifes > 0 and Utils.col(m, e) then
                    m.exploded = true
                    break
                end
            end
        end
    end
end

function Player:drawMeteoro()
    if not self.meteoro or #self.meteoros == 0 then return end
    
    love.graphics.setColor(1, 0.5, 0, 0.8)
    for _, m in ipairs(self.meteoros) do
        love.graphics.circle("fill", m.x, m.y, self.meteoro_size)
        love.graphics.setColor(1, 1, 0, 0.6)
        love.graphics.circle("line", m.x, m.y, self.meteoro_size + 2)
        love.graphics.setColor(1, 0.5, 0, 0.8)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

function Player:checkTeiaSpawn(dt)
    if not self.teia then return end
    
    self.teia_time = self.teia_time + dt
    if self.teia_time >= self.teia_max_time then
        self:spawnTeia()
        self.teia_time = 0
    end
end

function Player:spawnTeia()
    local function spawn_single_teia(player)
        table.insert(player.teias, {
            x = player.x + player.width / 2,
            y = player.y + player.height / 2,
            radius = player.teia_base_radius,
            life_timer = player.teia_life,
            enemies_inside = {},
            damage_timer = 0
        })
    end
    
    self:applyMultishot(spawn_single_teia, 0.5)
end

function Player:updateTeia(dt, enemies)
    for i = #self.teias, 1, -1 do
        local teia = self.teias[i]
        local removed = false
        
        teia.life_timer = teia.life_timer - dt
        teia.damage_timer = (teia.damage_timer or 0) + dt
        teia.enemies_inside = {}
        
        local count = 0
        for j = 1, #enemies do
            local e = enemies[j]
            local dist_p = dist(teia.x, teia.y, e.x, e.y)
            if dist_p < teia.radius and e.lifes > 0 then
                table.insert(teia.enemies_inside, e)
                count = count + 1
                
                e.teia_slow = true
                e.teia_slow_factor = self.teia_slow_factor
                
                if teia.damage_timer >= 0.2 then
                    e:takeDamage(self.teia_damage, self)
                end
            else
                e.teia_slow = false
            end
        end
        
        if teia.damage_timer >= 0.2 then
            teia.damage_timer = 0
        end
        
        teia.radius = math.min(
            self.teia_max_radius,
            self.teia_base_radius + (count * self.teia_grow_per_enemy)
        )
        
        if teia.life_timer <= 0 then
            for _, e in ipairs(teia.enemies_inside) do
                e.teia_slow = false
            end
            table.remove(self.teias, i)
            removed = true
        end
    end
end

function Player:drawTeia()
    if not self.teia or #self.teias == 0 then return end
    
    for _, teia in ipairs(self.teias) do
        local alpha = teia.life_timer / self.teia_life
        love.graphics.setColor(0.3, 0.8, 1, 0.4 * alpha)
        
        love.graphics.circle("line", teia.x, teia.y, teia.radius)
        
        love.graphics.setColor(0.2, 0.7, 1, 0.3 * alpha)
        for angle = 0, math.pi * 2, math.pi / 6 do
            local x2 = teia.x + math.cos(angle) * teia.radius
            local y2 = teia.y + math.sin(angle) * teia.radius
            love.graphics.line(teia.x, teia.y, x2, y2)
        end
    end
    
    love.graphics.setColor(1, 1, 1, 1)
end

function Player:checkPlayerCollision(enemies)
    local hit = false
    for _, e in ipairs(enemies) do
        if e.lifes > 0 and Utils.col(self, e) then
            self:takeHit(e.demage or 1)
            hit = true
            break
        end
        if e.bullets then
            for i = #e.bullets, 1, -1 do
                local b = e.bullets[i]
                if Utils.col(b, self) then
                    self:takeHit(1)
                    table.remove(e.bullets, i)
                    hit = true
                    break
                end
            end
        end
        if hit then break end
    end
end

function Player:takeHit(dmg)
    if self.block_chance and math.random() < self.block_chance then
        -- Efeito visual de bloqueio
        local part = require("part")
        part.add(self.x, self.y, 10, 12) -- Partículas azuis
        
        -- Som de bloqueio
        local SFX_Block = love.audio.newSource("assets/escudo.wav", "static")
        SFX_Block:setPitch(1+math.random(0.5))
        SFX_Block:setVolume(0.4)
        SFX_Block:play()
        
        return -- Bloqueou o dano!
    end
    SFX_dano:play()
    local damage = math.floor(dmg or 1)
    self.lifes = self.lifes - damage
    self.invul = 1
    Camera:shake(0.45, 2)
end

-- Retorna os 6 itens mais importantes para mostrar na HUD
function Player:getHUDItems()
    local items = {}
    for name, level in pairs(self.item_levels) do
        if level > 0 then
            table.insert(items, {name = name, level = level})
        end
    end
    
    -- Ordena por nível decrescente (CORREÇÃO para evitar "attempt to compare number with string")
    table.sort(items, function(a, b) 
        local level_a = tonumber(a.level) or 0 -- Garante que é um número
        local level_b = tonumber(b.level) or 0 -- Garante que é um número
        return level_a > level_b 
    end)
    
    -- Retorna apenas os 6 primeiros
    local result = {}
    for i = 1, math.min(6, #items) do
        table.insert(result, items[i])
    end
    return result
end

function Player:draw()
    Utils.setColor(7)
    
    -- Desenha bullets normais
    Shaders:applyProjectileShader(neve, self)
    for _, b in ipairs(self.bullets) do
        love.graphics.draw(neve, b.x, b.y, 0, 1, 1, b.width/2, b.height/2)
    end
    
    Shaders:applyProjectileShader(sombriosSprite,self)
    -- Desenha Pedras preciosas
    for _, b in ipairs(self.sombrios) do
        love.graphics.draw(sombriosSprite, b.x, b.y, 0, 1, 1, b.width/2, b.height/2)
    end

    -- Desenha rodas
    Shaders:applyProjectileShader(neve, self)
    for _, r in ipairs(self.rodas) do
        love.graphics.draw(rodas, r.x, r.y)
    end

    -- Desenha pedras
    Shaders:applyProjectileShader(pedras, self)
    for _, p in ipairs(self.pedras) do
        love.graphics.draw(pedras, p.x, p.y)
    end

    -- Desenha anel
    Shaders:applyProjectileShader(Lava, self)
    for _, p in ipairs(self.anel) do
        love.graphics.draw(Lava,p.x, p.y,0,1,1,Lava:getWidth()/2,Lava:getHeight()/2)
    end

    -- DESENHA A GUIRLANDA (ALHO)
    if self.guirlanda then
        -- Efeito de pulso na opacidade
        local alpha = 0.3 + math.sin(love.timer.getTime() * 5) * 0.1
        love.graphics.setColor(0, 0.75, 0, alpha) -- Verde Translucido
        love.graphics.circle("fill", self.x + 8, self.y + 8, self.guirlanda_raio)
        love.graphics.setColor(0, 1, 0, 1) -- Borda
        love.graphics.circle("line", self.x + 8, self.y + 8, self.guirlanda_raio)
    end

    -- DESENHA BUMERANGUES E SEUS PRESENTES
    Shaders:applyProjectileShader(presente, self)
    for _, b in ipairs(self.bumerangues) do
        -- Desenha presentes do rastro
        love.graphics.setColor(1, 1, 1) -- Vermelhos
        for _, g in ipairs(b.gifts) do
            love.graphics.draw(presente, g.x, g.y, 2, 2)
        end
        
        -- Desenha o bumerangue (um 'V' simples girando)
        love.graphics.setColor(1, 1, 0) -- Amarelo
        love.graphics.push()
        love.graphics.translate(b.x+4, b.y+4)
        love.graphics.rotate(b.rot)
        love.graphics.rectangle("fill", -8, -2, 10, 4)
        love.graphics.rectangle("fill", -2, -8, 4, 10)
        love.graphics.pop()
    end

    Shaders:clear()

    for _, p in ipairs(self.Raios) do
        Utils.setColor(8)
        love.graphics.rectangle("fill",p.x,p.y,p.width,p.height)
    end

    if self.estrelas_natalinas then
        for _, s in ipairs(self.pending_stars) do
            -- Desenha um círculo de aviso ou mira no inimigo
            love.graphics.setLineWidth(1)
            Utils.setColor(9)
            
            -- Círculo que vai fechando conforme o tempo acaba
            love.graphics.circle("line", s.enemy.x, s.enemy.y, 10 + (s.timer * 20))
            
            -- EFEITO DE RASTRO: Se faltar menos de 0.5s, desenha a estrela caindo rápido
            if s.timer < 0.5 then
                local progresso = (0.5 - s.timer) / 0.5 -- Vai de 0 a 1
                local startY = s.enemy.y - 300
                local currentY = startY + (300 * progresso)
                
                -- Desenha o rastro (uma linha brilhante)
                love.graphics.setLineWidth(4)
                love.graphics.line(s.enemy.x, startY, s.enemy.x, currentY)
                
                -- Desenha a cabeça da estrela
                love.graphics.circle("fill", s.enemy.x, currentY, 5)
                love.graphics.setLineWidth(1)
            end
        end
    end

    -- Desenha o player
    if self.invul <= 0 or math.floor(self.invul * 10) % 2 == 0 then
        Utils.setColor(7)
        local scaleX = self.flp*2
        local offsetX = self.flp and 8 or 0 
        love.graphics.draw(self.sprite_sheet, self.sprite[self.tipo_jogador], self.x + offsetX, self.y,0, scaleX, 2, 4)
    end

    local Utils = require("utils")
    local Lang = require("lang")
    
    -- Desenha Dinheiro (Canto superior direito ou esquerdo)
    Utils.setColor(10) -- Amarelo
    love.graphics.print(Lang.text("hud_money", self.money), 24, 128*2 - (128+48))
    -- love.graphics.draw(CoinICON, 4, 128*2 - (128+48))
    
    Utils.setColor(7)

    if Debug.options.show_player_rect then
        love.graphics.setColor(0, 1, 0, 1) -- Verde para o player
        -- Supondo que a hitbox seja um retângulo centrado ou baseado na sprite
        -- Ajuste os valores (8, 8, 16, 16) conforme o tamanho real do colisor do seu player
        love.graphics.rectangle("line", self.x, self.y, 16, 16) 
        love.graphics.print("P", self.x, self.y - 16)
    end

    if Debug and Debug.active and Debug.options.show_item_rect then
        love.graphics.setColor(0, 0, 0, 1) -- Azul claro (Cyan) para ataques do player
        
        -- 1. Bolas de Neve
        if self.tiro then
            for _, p in ipairs(self.bullets) do
                love.graphics.rectangle("line", 
                    p.x + (p.hitbox_off_x or 0), 
                    p.y + (p.hitbox_off_y or 0), 
                    p.hitbox_w or p.w or 4, 
                    p.hitbox_h or p.h or 4
                )
            end
        end

        -- 2. Bumerangues
        if self.bumerangue then
            for _, b in ipairs(self.bumerangues) do
                -- Bumerangues as vezes tem posição calculada na hora, certifique-se de pegar o X/Y real
                love.graphics.rectangle("line", 
                    b.x + (b.hitbox_off_x or 0), 
                    b.y + (b.hitbox_off_y or 0), 
                    b.hitbox_w or b.w or 16, 
                    b.hitbox_h or b.h or 16
                )
            end
        end

        if self.pedra then
            for _, b in ipairs(self.pedras) do
                love.graphics.rectangle("line", 
                    b.x + (b.hitbox_off_x or 0), 
                    b.y + (b.hitbox_off_y or 0), 
                    b.hitbox_w or b.w or 16, 
                    b.hitbox_h or b.h or 16
                )
            end
        end

        if self.sombrio_ativo then
            for _, b in ipairs(self.sombrios) do
                love.graphics.rectangle("line", 
                    b.x + (b.hitbox_off_x or 0), 
                    b.y + (b.hitbox_off_y or 0), 
                    b.hitbox_w or b.w or 16, 
                    b.hitbox_h or b.h or 16
                )
            end
        end

        if self.roda then
            for _, b in ipairs(self.rodas) do
                love.graphics.rectangle("line", 
                    b.x + (b.hitbox_off_x or 0), 
                    b.y + (b.hitbox_off_y or 0), 
                    b.hitbox_w or b.w or 16, 
                    b.hitbox_h or b.h or 16
                )
            end
        end

        -- 3. Guirlanda (Área circular)
        if self.guirlanda then
            love.graphics.circle("line", self.x + 8, self.y + 8, self.guirlanda_raio)
        end
        
        -- Reset de cor
        love.graphics.setColor(1, 1, 1, 1)
    end
    Part.draw()
end

function Player:multishotVisualEffect()
    local part = require("part")
    -- Círculo de partículas azuis ao disparar multishot
    for i = 1, 8 do
        local angle = (i / 8) * math.pi * 2
        part.add(
            self.x + math.cos(angle) * 12,
            self.y + math.sin(angle) * 12,
            1, 12 -- Partículas azuis
        )
    end
end

return Player