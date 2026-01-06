local Utils  = require('utils')
local Waves  = require("wave")
local Camera = require("camera")
local Shaders= require("shaders")

local Player = {}
Player.__index = Player

local function dist(x1, y1, x2, y2)
    return math.sqrt((x2 - x1)^2 + (y2 - y1)^2)
end

SFX_dano=love.audio.newSource("assets/dano.wav","static")
SFX_raio=love.audio.newSource("assets/Raio.wav","static")
local Lava=love.graphics.newImage("assets/Lava.png")
local neve=love.graphics.newImage("assets/neve.png")
local pedras=love.graphics.newImage("assets/pedra.png")
local rodas=love.graphics.newImage("assets/neve.png")
local sombriosSprite=love.graphics.newImage("assets/sombrio.png")

local presente=love.graphics.newImage("assets/Presente2.png")

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

    -- SISTEMA DE NÍVEIS DE ITENS
    self.item_levels = {
        ["Bola de neve"] = 0,
        ["Bloco de gelo"] = 0,
        ["Pedras do ceu"] = 0,
        ["Veneno mortal"] = 0,
        ["Fogo perigoso"] = 0,
        ["Imobilizador"] = 0,
        ["Anel de Lava"] = 0,
        ["Pedras Preciosas"] = 0,
        ["Raios de luz"] = 0,
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

    return self
end

function Player:update(dt, enemies, time)
    if self.lifes <= 0 then
        self = Player.new()
        return
    end

    if self.regen then
        self.t = self.t + dt
        if self.t >= self.regen_delay then
            self.max_life = self.max_life + self.regen_forca
            self.lifes = math.min(self.max_life, self.lifes + self.regen_forca)
            self.t = 0
        end
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

    if self.bumerangue then
        self.bumerangue_time = self.bumerangue_time + dt
        if self.bumerangue_time >= self.bumerangue_delay then
            self.bumerangue_time = 0
            self:spawnBumerangue()
        end
    end

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
                        local dmg = self.anel_dano/4
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
    
    if self.invul <= 0 then
        self:checkPlayerCollision(enemies)
    end
end


function Player:spawnBumerangue()
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
        hitbox_w = 12,
        hitbox_h = 12,
        hitbox_off_x = 6,
        hitbox_off_y = 6
    })
end

function Player:updateBumerangues(dt, enemies)
    local Utils = require("utils")
    
    -- Percorre de trás para frente para poder remover itens sem bugar o loop
    for i = #self.bumerangues, 1, -1 do
        local b = self.bumerangues[i]
        
        b.rot = b.rot + 15 * dt -- Rotação visual

        local return_to_player = false

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
                if Utils.col(rectB, {x=e.x, y=e.y, w=e.w, h=e.h}) then
                    self:recordDamage("Bumerangue", self.demage)
                    e:takeDamage(self.demage, self)
                    if self.veneno then e.veneno = true end
                    if self.fogo then e.fogo = true end
                    if self.gelo then e.gelo = true end
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
        table.insert(self.bullets, {
            x = self.x + self.width / 2, y = self.y + self.height / 2, 
            speed = self.bala_speed, tipo = "normal", width = 4, height = 4,
            hitbox_w = 4,
            hitbox_h = 4,
            hitbox_off_x = 2, -- (16 - 10) / 2
            hitbox_off_y = 2
        })
        self.tiro_time = 0
    end
end

function Player:checkRaioSpawn(dt)
    self.Raio_time = self.Raio_time + dt
    if self.Raio_time >= self.Raio_max_time then
        self:spawnRaio()
        self.Raio_time = 0
    end
end

function Player:spawnRaio()
    for i = 0, 1 do
        table.insert(self.Raios, {
            x = self.x + self.width / 2, y = 0,
            dx = 0,
            dy = 0,
            life_timer = self.Raio_life,
            width = 32, height = 256
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
        self:spawnRodas(10 + self.roda_size, 2 * 60 * dt)
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
            hitbox_off_x = 4, -- (16 - 10) / 2
            hitbox_off_y = 4
        })
    end
end

function Player:checkSombrioSpawn(dt)
    self.sombrio_time = self.sombrio_time + dt
    if self.sombrio_time >= self.sombrio_delay then
        for i = 1, self.sombrio_quantidade do
            local angle = -math.pi / 2 + love.math.random(-0.3, 0.3)
            local speed = love.math.random(45, 135)
            local dx = math.cos(angle) * speed
            local dy = math.sin(angle) * speed
            if i%2==0 then
                table.insert(self.sombrios, {
                    x = self.x + self.width / 2,
                    y = self.y,
                    dx = dx,
                    dy = dy,
                    life_timer = love.math.random(8,12),
                    width = 8,
                    height = 8,
                    hitbox_w = 8,
                    hitbox_h = 8,
                    hitbox_off_x = 4, -- (16 - 10) / 2
                    hitbox_off_y = 4
                })
            else
                table.insert(self.sombrios, {
                    x = self.x + self.width / 2,
                    y = self.y,
                    dx = dx,
                    dy = -dy,
                    life_timer = love.math.random(8,12),
                    width = 8,
                    height = 8,
                    hitbox_w = 8,
                    hitbox_h = 8,
                    hitbox_off_x = 4, -- (16 - 10) / 2
                    hitbox_off_y = 4
                }) 
            end
        end
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
            for i=-3,3 do
            table.insert(self.pedras, {
                x = self.x+(i*12) + self.width / 2,
                y = 1,
                speed = 4 * 60 * dt,
                life_timer = 4,
                width = 16, height = 12
            })
            self.pedra_time = 0
        end
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
        b.y = b.y + b.speed * dt * 45 + math.sin(time_factor*3) * dt
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

    -- Desenha o player
    if self.invul <= 0 or math.floor(self.invul * 10) % 2 == 0 then
        Utils.setColor(7)
        local scaleX = self.flp*2
        local offsetX = self.flp and 8 or 0 
        love.graphics.draw(self.sprite_sheet, self.sprite[self.tipo_jogador], self.x + offsetX, self.y,0, scaleX, 2, 4)
    end

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

        -- 3. Guirlanda (Área circular)
        if self.guirlanda then
            love.graphics.circle("line", self.x + 8, self.y + 8, self.guirlanda_raio)
        end
        
        -- Reset de cor
        love.graphics.setColor(1, 1, 1, 1)
    end
end

return Player