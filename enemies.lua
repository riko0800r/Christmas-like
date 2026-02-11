local Utils = require("utils")
local part = require("part")
local Camera= require("camera")
local Shaders = require("shaders")

local enemies_module = {}

_G.SFX_Enemy_Morte=love.audio.newSource("assets/hitHurt.wav","static")
-- Som para pegar o coração
_G.SFX_Pickup_Heart=love.audio.newSource("assets/vida.wav","static")
SFX_Pickup_Heart:setPitch(1.5)
SFX_Pickup_Heart:setVolume(0.25)

SFX_Enemy_Morte:setVolume(0.1)

SFX_Pickup_Coin=love.audio.newSource("assets/Coin.wav","static")

SFX_Pickup_Coin:setVolume(0.25)

love.graphics.setDefaultFilter("nearest", "nearest")

local enemies = {}
local hearts = {} -- Lista de corações no chão
local coins = {} -- Lista de moedas no chão
local sprite_sheets = {}
local pi = math.pi
local sqrt = math.sqrt
local cos = math.cos
local sin = math.sin
local addpart = part.add
local table_insert = table.insert
local table_remove = table.remove
local clamp=Utils.clamp
local golden_spawn_timer = 0

local presente=love.graphics.newImage("assets/Presente.png")
-- Carrega a imagem do coração
local heart_sprite=love.graphics.newImage("assets/VidaICON.png")

local MAX_ENEMY_SPEED = 2.5
local FRAMERATE = 60

local function dist(x1, y1, x2, y2)
    return sqrt((x2 - x1)^2 + (y2 - y1)^2)
end

-- =============================================================
--                  SISTEMA DE ESTADOS (FSM)
-- =============================================================

-- Função auxiliar para trocar o estado do inimigo
local function changeState(enemy, newState)
    if enemy.state == newState then return end -- Já está nesse estado
    
    -- Lógica de Saída (Exit) do estado anterior (Opcional)
    if enemy.state == "dash" then
        enemy.speed = enemy.base_speed -- Reseta velocidade ao sair do dash
    end

    enemy.state = newState
    enemy.state_timer = 0 -- Reseta o timer do estado
    enemy.state_sub_timer = 0 -- Timer secundário se precisar
    
    -- Lógica de Entrada (Enter) no novo estado
    if newState == "dash" then
        -- Exemplo: Define vetor de ataque na entrada
        enemy.target_x = 0 -- Será definido no update
        enemy.target_y = 0
    end
end

local EnemyPresets = {
    perseguidor = {demage_preset=1,speed_base = 1.25, speed_scale = 1/16, hp_base = 1.5, hp_scale = 1/8,demage_scale=1/800, accel_mult = 1.5,sprite=1},
    atirador = {demage_preset=1,speed_base = 0.55, speed_scale = 1/16, hp_base = 3, hp_scale = 1/8,demage_scale=1/300, shoot_rate = 60*6, shoot_timer = 0,sprite=1},
    horizontal = {demage_preset=1,speed_base = 2, speed_scale = 1/16, hp_base = 1.5, hp_scale = 1/8,demage_scale=1/200, dir = 1,sprite=1},
    bomb = {demage_preset=1,speed_base = 1.40, speed_scale = 1/16, hp_base = 2, hp_scale = 1/8,demage_scale=1/400, explosion_radius = 12,sprite=1}, 
    arma = {demage_preset=1,speed_base = 0.25, speed_scale = 1/16, hp_base = 2, hp_scale = 1/8,demage_scale=1/400, shoot_timer = 0, time = 0,sprite=1},
    circulador = {demage_preset=1,speed_base = 1, speed_scale = 1/16, hp_base = 4, hp_scale = 1/8,demage_scale=1/400, shoot_timer = 0, num_bullets = 10, orbit_radius = 12, orbit_speed = 1,sprite=1},
    
    boss = {demage_preset=1,speed_base = 0.95, speed_scale = 1/16, hp_base = 25, hp_scale = 1/3,demage_scale=1/400 ,explosion_radius = 9, time = 0, summon_timer = 0,sprite=2},
    
    boss2 = {
      demage_preset=1,speed_base = 1.5, speed_scale = 1/16, hp_base = 25, hp_scale = 1/3,demage_scale=1/400,dirx = 1, time = 0, summon_timer = 0,sprite=3},
    
    boss3 = {
      demage_preset=1,speed_base = 2.5, speed_scale = 1/16, hp_base = 25, hp_scale = 1/3,demage_scale=1/400, dir = 1, timer = 0,sprite=4},

    boss4 = {
      demage_preset=1,speed_base = 0.25, speed_scale = 1/16, hp_base = 25, hp_scale = 1/3,demage_scale=1/400,time = 0, summon_timer = 0,sprite=6,
      teleport_cooldown = 145, teleport_timer = 0, bullet_speed = 1.75,
      is_teleporting = false, target_x = 0, target_y = 0},
      
    boss5 = {demage_preset=1,speed_base = 1, speed_scale = 1/16, hp_base = 35, hp_scale = 1/3,demage_scale=1/400, shoot_timer = 0, num_bullets = 24, orbit_radius = 32, orbit_speed = 1,sprite=6},

    teleportador = {
        demage_preset=2, speed_base = 0, speed_scale = 0, hp_base = 3.5, hp_scale = 1/16, demage_scale=1/500, 
        teleport_cooldown = 180, teleport_timer = 0, bullet_speed = 1.75, sprite=1,
        warning_timer = 0,
        is_teleporting = false,
        target_x = 0, target_y = 0
    },

    divisor = {
        demage_preset=2, speed_base = 0.7, speed_scale = 1/16, hp_base = 5, hp_scale = 1/8, demage_scale=1/600, 
        accel_mult = 1.0, sprite=5,
    },
    paladino = {
        demage_preset=2, 
        speed_base = 1.25, 
        speed_scale = 1/16, 
        hp_base = 4.25,
        hp_scale = 1/16,
        demage_scale=1/400,
        sprite=7 -- Use o sprite que preferir
    },
    sniper = {
        demage_preset=1, -- Dano alto
        speed_base = 1.2, 
        speed_scale = 1/16, 
        hp_base = 3, 
        hp_scale = 1/6, 
        demage_scale=1/200, 
        sprite=1,
    },
    invocador = {
        demage_preset=1,
        speed_base = 0.75,
        speed_scale = 1/16, 
        hp_base = 2.5,
        hp_scale = 1/16, 
        demage_scale=0, 
        sprite=1,
    },
    renas_especial = {
        demage_preset=1,
        speed_base = 1.75, 
        speed_scale = 1/16, 
        hp_base = 6.5, 
        hp_scale = 1/4, 
        demage_scale=0, 
        sprite=1,
        ai_type = "flee",
        is_golden = true,
    },

    espiral = {
        demage_preset = 1,
        speed_base = 1.5, 
        speed_scale = 1/16, 
        hp_base = 3, 
        hp_scale = 1/8,
        demage_scale = 1/300, 
        sprite = 15,
        spiral_angle = 0,
        spiral_speed = 0.8,
        spiral_radius = 40,
        spiral_tighten = 0.95,
        shoot_timer = 0,
        shoot_rate = 30 * 2,
    },

    refletor = {
        demage_preset = 0,
        speed_base = 0.75, 
        speed_scale = 1/16, 
        hp_base = 6, 
        hp_scale = 1/8,
        demage_scale = 0,
        sprite = 14,
        shield_strength = 1.0,
        reflect_timer = 0,
        last_reflect_angle = 0,
    },

    vampiro = {
        demage_preset = 1,
        speed_base = 1.5, 
        speed_scale = 1/16, 
        hp_base = 2.75,
        hp_scale = 1/8,
        demage_scale = 1/350, 
        sprite = 15,
        healing_per_damage = 0.4,
        drain_range = 20,
        drain_timer = 0,
        drain_rate = 60 * 0.75,
    },
}

function enemies_module.load_assets()
    sprite_sheets = {}
    local loaded_ids = {}

    for _, preset in pairs(EnemyPresets) do
        local id = preset.sprite
        if id and not loaded_ids[id] then
            local path = "assets/sprite" .. tostring(id) .. ".png"
            sprite_sheets[id] = love.graphics.newImage(path)
            loaded_ids[id] = true
        end
    end
end

local function is_boss(enemy_type)
    return enemy_type == "boss" or 
           enemy_type == "boss2" or 
           enemy_type == "boss3" or 
           enemy_type == "boss4" or 
           enemy_type == "boss5"
end

function enemies_module.spawn_enemy(tipo, x, y, Waves)
    local preset = EnemyPresets[tipo]
    if not preset then return nil end

    local enemy = {
        x = x, y = y, tipo = tipo, dx = 0, dy = 0, w=16, h=16,
        bullets = {},
        veneno = false, fogo = false, gelo = false,
        dead = false,
        waves_manager = Waves,
        flpx=1,
        tempo_pausado=0,
        state = "patrol",      -- Estado inicial padrão
        state_timer = 1,       -- Timer geral do estado
        base_speed = 0,        -- Para guardar a velocidade original

            -- === NOVO: Variáveis de Squash & Stretch ===
        sx = 1, -- Escala X atual (1 = normal)
        sy = 1, -- Escala Y atual
        target_sx = 1, -- Para onde a escala quer ir
        target_sy = 1,
    }

    enemy.w = enemy.w or 16 -- Se não tiver largura definida, assume 16
    enemy.h = enemy.h or 16

    -- Define hitbox menor (ex: 80% do tamanho visual)
    enemy.hitbox_w = math.floor(enemy.w * 0.8)
    enemy.hitbox_h = math.floor(enemy.h * 0.8)

    -- Calcula o offset para centralizar
    enemy.hitbox_off_x = (enemy.w - enemy.hitbox_w) / 2
    enemy.hitbox_off_y = (enemy.h - enemy.hitbox_h) / 2

    for k, v in pairs(preset) do
        enemy[k] = v
    end

    enemy.image = sprite_sheets[preset.sprite]

    -- 🔧 MELHORADO: Crescimento gradual de HP
    local wave_factor
    if is_boss(tipo) then
        wave_factor = math.pow(1 + (Waves.current_wave * 0.18), 1.12)
    else
        wave_factor = math.pow(1 + (Waves.current_wave * 0.12), 1.1)
    end
    enemy.lifes = math.floor(preset.hp_base * wave_factor)
    enemy.speed = preset.speed_base + Waves.current_wave * preset.speed_scale
    enemy.demage = (preset.demage_preset or 1) + Waves.current_wave * preset.demage_scale
    enemy.max_hp = enemy.lifes

    if player.relics and player.relics["Greed"] then
        enemy.max_hp=enemy.max_hp*1.5
        enemy.lifes=enemy.lifes*1.5
    end
    
    enemy.speed = clamp(0.15, enemy.speed, MAX_ENEMY_SPEED)
    
    Shaders:initEnemyFlash(enemy)
    if tipo=="divisor" then
        enemy.w=enemy.w*2
        enemy.h=enemy.h*2
    end

    enemy.radius = (enemy.w * 1.75) / 2

    enemy.takeDamage = function(self, dmg)
        self.lifes = self.lifes - dmg
        Camera:shake(0.2,0.8)
        local randomPitch = love.math.random() * 0.4 + 0.8
        SFX_Enemy_Morte:setPitch(randomPitch)
        SFX_Enemy_Morte:play()
        Shaders:triggerFlash(self)
        -- Quando toma dano, ele fica gordo (X aumenta) e baixo (Y diminui)
        self.sx = 1 + math.random(0.25,1.5)
        self.sy = 0.5 - math.random(0.1,0.4)
        if self.lifes <= 0 then self.dead = true end
    end

    if tipo == "circulador" or tipo == "boss5" then
        enemies_module.spawn_bullet_orbit(enemy, preset.num_bullets, preset.orbit_radius, preset.orbit_speed)
    end
    
    if tipo == "divisor" then
        enemy.w=24
        enemy.h=24
    end
    
    if preset.is_golden then
        enemy.is_golden = preset.is_golden 
    else
        enemy.is_golden = false
    end

    table_insert(enemies, enemy)
    return enemy
end

-- Função auxiliar para lerp (suavização)
local function lerp(a, b, t)
    return a + (b - a) * t
end

local function update_squash_stretch(enemy, dt)
    -- 1. Calcular a "Intenção" de escala baseada no movimento
    -- Se estiver se movendo rápido, estica um pouco no Y e afina no X
    local speed = math.sqrt(enemy.dx^2 + enemy.dy^2)
    local max_speed = 2.5 -- Referencia aproximada da velocidade máxima
    
    -- Fator de esticar baseado na velocidade (sutil, máximo 15%)
    local stretch_amount = math.min((speed / max_speed) * 0.15, 0.15)
    
    -- Adiciona um "bobbing" (senoide) para parecer que está andando/flutuando
    local bob = math.sin(love.timer.getTime() * 12) * 0.05
    
    -- Se estiver parado, o efeito é menor
    if speed < 0.5 then
        stretch_amount = 0 
        bob = math.sin(love.timer.getTime() * 5) * 0.02 -- Respiração lenta parado
    end

    -- O alvo é: Normal (1) +/- o esticamento +/- o balanço
    enemy.target_sx = (1 - stretch_amount) + bob
    enemy.target_sy = (1 + stretch_amount) - bob

    -- 2. Suavizar a escala atual em direção ao alvo
    -- O '15' é a velocidade de recuperação. Quanto maior, mais rígido.
    enemy.sx = lerp(enemy.sx, enemy.target_sx, dt * 15)
    enemy.sy = lerp(enemy.sy, enemy.target_sy, dt * 15)
end

local function resolve_enemy_collisions()
    for i = 1, #enemies do
        for j = i + 1, #enemies do
            local e1 = enemies[i]
            local e2 = enemies[j]

            local distancia = dist(e1.x, e1.y, e2.x, e2.y)
            local soma_raios = e1.radius + e2.radius

            if distancia < soma_raios then
                if distancia == 0 then
                    distancia = 0.1
                    e1.x = e1.x + 0.1
                end

                local sobreposicao = soma_raios - distancia
                local dx = (e1.x - e2.x) / distancia
                local dy = (e1.y - e2.y) / distancia

                e1.x = e1.x + dx * sobreposicao / 2
                e1.y = e1.y + dy * sobreposicao / 2
                
                e2.x = e2.x - dx * sobreposicao / 2
                e2.y = e2.y - dy * sobreposicao / 2
            end
        end
    end
end

local function spawn_bullet_targeted(enemy, player, speed)
    local dx, dy = player.x - enemy.x, player.y - enemy.y
    local mag = dist(0,0,dx,dy)
    if mag > 0 then
        table_insert(enemy.bullets, {
            x = enemy.x,
            y = enemy.y,
            dx = dx/mag * speed,
            dy = dy/mag * speed,
            life_timer = 0
        })
    end
end

local function update_bomb(enemy, player, dt)
    update_chaser(enemy, player, dt)
    if dist(enemy.x, enemy.y, player.x, player.y) < enemy.explosion_radius then
        player:takeHit(enemy.demage)
        addpart(enemy.x, enemy.y, 10, 8)
        addpart(enemy.x, enemy.y, 30, 9)
        enemy.dead = true
    end
end

local function update_flee(enemy, player, dt)
    local dx, dy = enemy.x - player.x, enemy.y - player.y -- Vetor oposto ao player
    local mag = math.sqrt(dx^2 + dy^2)
    
    -- Se estiver muito perto das bordas, tenta voltar pro meio
    if enemy.x < 32 then dx = 1 end
    if enemy.x > (128*4)-32 then dx = -1 end
    if enemy.y < 32 then dy = 1 end
    if enemy.y > (128*2)-32 then dy = -1 end

    if mag > 0 then
        -- Normaliza e aplica velocidade
        enemy.dx = (dx/mag) * enemy.speed
        enemy.dy = (dy/mag) * enemy.speed
        
        enemy.x = enemy.x + enemy.dx * dt * 60
        enemy.y = enemy.y + enemy.dy * dt * 60
    end
    
    -- Partículas de rastro dourado
    if math.random() < 0.1 then
        part.add(enemy.x, enemy.y, 6, 9) -- Amarelo/Laranja
    end
end

local function update_paladino(enemy, player, dt)
    -- Atualiza timer do estado
    enemy.state_timer = enemy.state_timer + dt * 60 -- Usando base 60fps do seu jogo
    
    local dist_p = dist(enemy.x, enemy.y, player.x, player.y)

    -- ================= ESTADO: PATRULHA =================
    if enemy.state == "patrol" then
        -- Movimento errático suave
        if enemy.state_timer % 120 == 0 then
            local angle = love.math.random() * math.pi * 2
            enemy.dx = math.cos(angle) * (enemy.speed * 0.5)
            enemy.dy = math.sin(angle) * (enemy.speed * 0.5)
        end
        
        enemy.x = enemy.x + enemy.dx * dt * 60
        enemy.y = enemy.y + enemy.dy * dt * 60
        
        -- Se player chegar perto, entra em alerta
        if dist_p < 8*18 then
            changeState(enemy, "alert")
        end

    -- ================= ESTADO: ALERTA =================
    elseif enemy.state == "alert" then
        -- Fica parado por 0.5 segundos (30 frames) antes de perseguir
        enemy.dx, enemy.dy = 0, 0
        
        if enemy.state_timer > 25 then
            changeState(enemy, "chase")
        end

    -- ================= ESTADO: PERSEGUIÇÃO =================
    elseif enemy.state == "chase" then
        -- Persegue o player
        update_chaser(enemy, player, dt, 1.5) -- 1.5x velocidade
        
        -- Se estiver muito perto, prepara ataque
        if dist_p < 128 then
            changeState(enemy, "prepare_attack")
        -- Se o player fugir muito, volta a patrulhar
        elseif dist_p > 256 then
            changeState(enemy, "patrol")
        end

    -- ================= ESTADO: PREPARAR ATAQUE =================
    elseif enemy.state == "prepare_attack" then
        -- Para e mira
        enemy.dx, enemy.dy = 0, 0
        
        -- Flash vermelho ou efeito visual aqui seria bom
        if enemy.state_timer > 30 then -- Espera ~0.4s
            -- Calcula direção do dash
            local dx, dy = player.x - enemy.x, player.y - enemy.y
            local mag = math.sqrt(dx^2 + dy^2)
            if mag > 0 then
                enemy.dash_dx = (dx/mag)
                enemy.dash_dy = (dy/mag)
            else
                enemy.dash_dx, enemy.dash_dy = 1, 0
            end
            changeState(enemy, "dash")
        end

    -- ================= ESTADO: DASH (ATAQUE) =================
    elseif enemy.state == "dash" then
        local dash_speed = enemy.speed * 3.5
        enemy.x = enemy.x + enemy.dash_dx * dash_speed * dt * 60
        enemy.y = enemy.y + enemy.dash_dy * dash_speed * dt * 60
        
        -- Solta particulas durante o dash
        if math.random() < 0.5 then
            part.add(enemy.x, enemy.y, 5, 8) -- Usa o sistema de partículas existente
        end

        -- Dash dura pouco (30 frames)
        if enemy.state_timer > 30 then
            changeState(enemy, "tired")
        end

    -- ================= ESTADO: CANSADO =================
    elseif enemy.state == "tired" then
        enemy.dx, enemy.dy = 0, 0
        -- Recupera fôlego por 1.5s
        if enemy.state_timer > 30 then
            changeState(enemy, "chase")
        end
    end
end

local function update_spike(enemy, player, dt)
    if math.random() < 0.05 then
        local angle = love.math.random() * math.pi * 2
        enemy.dx = math.cos(angle) * (enemy.speed * 0.3)
        enemy.dy = math.sin(angle) * (enemy.speed * 0.3)
    end
    
    enemy.x = enemy.x + enemy.dx * dt * 60
    enemy.y = enemy.y + enemy.dy * dt * 60
    
    local dist_p = dist(enemy.x, enemy.y, player.x, player.y)
    if dist_p < enemy.damage_radius then
        enemy.last_damage_time = enemy.last_damage_time or 0
        enemy.last_damage_time = enemy.last_damage_time - dt
        if enemy.last_damage_time <= 0 then
            player:takeHit(enemy.contact_damage)
            enemy.last_damage_time = 0.3
        end
        
        local dx, dy = player.x - enemy.x, player.y - enemy.y
        local mag = dist(0, 0, dx, dy)
        if mag > 0 then
            player.x = player.x + (dx/mag) * 2
            player.y = player.y + (dy/mag) * 2
        end
    end
    
    if enemy.x < 16 then enemy.x = 16 end
    if enemy.x > 512 - 16 then enemy.x = 512 - 16 end
    if enemy.y < 16 then enemy.y = 16 end
    if enemy.y > 256 - 16 then enemy.y = 256 - 16 end
end

local function update_espiral(enemy, player, dt)
    local dist_p = dist(enemy.x, enemy.y, player.x, player.y)
    
    -- ======================== MOVIMENTO ========================
    -- Aumenta a velocidade de rotação conforme fica mais perto
    local speed_multiplier = 1 + (1 - math.min(1, dist_p / 200)) * 0.5
    enemy.spiral_angle = (enemy.spiral_angle or 0) + enemy.spiral_speed * dt * 60 * speed_multiplier
    
    -- O raio da espiral diminui gradualmente (aperta)
    local current_radius = enemy.spiral_radius * math.pow(enemy.spiral_tighten, enemy.spiral_angle / (2 * math.pi))
    
    -- Calcula a posição alvo em torno do player
    local target_x = player.x + math.cos(enemy.spiral_angle) * current_radius
    local target_y = player.y + math.sin(enemy.spiral_angle) * current_radius
    
    -- Movimento suave para a posição alvo
    local dx = target_x - enemy.x
    local dy = target_y - enemy.y
    local mag = dist(0, 0, dx, dy)
    
    if mag > 0 then
        enemy.dx = (dx / mag) * enemy.speed
        enemy.dy = (dy / mag) * enemy.speed
    end
    
    enemy.x = enemy.x + enemy.dx * dt * 60
    enemy.y = enemy.y + enemy.dy * dt * 60
    
    -- ======================== ATAQUE ========================
    -- Define a fase baseado na distância ao player
    local phase = 1
    if dist_p < 128 then phase = 2 end
    if dist_p < 64 then phase = 3 end
    
    enemy.current_phase = phase
    
    -- Timer de tiro
    enemy.shoot_timer = (enemy.shoot_timer or 0) + dt * 60
    local shoot_rate = enemy.shoot_rate / phase  -- Mais rápido em fases altas
    
    if enemy.shoot_timer >= shoot_rate then
        -- Padrão de tiro muda por fase
        if phase == 1 then
            -- FASE 1: 8 tiros simples em círculo
            for i = 0, 7 do
                local angle = (i / 8) * 2 * math.pi
                local speed = 1.5
                table.insert(enemy.bullets, {
                    x = enemy.x,
                    y = enemy.y,
                    dx = math.cos(angle) * speed,
                    dy = math.sin(angle) * speed,
                    life_timer = 0
                })
            end
            
        elseif phase == 2 then
            -- FASE 2: 8 tiros duplos (dois anéis com delay)
            for i = 0, 7 do
                local angle = (i / 8) * 2 * math.pi
                local speed = 1.5
                
                -- Primeiro anel
                table.insert(enemy.bullets, {
                    x = enemy.x,
                    y = enemy.y,
                    dx = math.cos(angle) * speed,
                    dy = math.sin(angle) * speed,
                    life_timer = 0
                })
                
                -- Segundo anel (offset angular)
                local offset_angle = angle + (math.pi / 8)
                table.insert(enemy.bullets, {
                    x = enemy.x,
                    y = enemy.y,
                    dx = math.cos(offset_angle) * speed,
                    dy = math.sin(offset_angle) * speed,
                    life_timer = 0
                })
            end
            
        elseif phase == 3 then
            -- FASE 3: 8 tiros triplos com padrão alternado
            for i = 0, 7 do
                local angle = (i / 8) * 2 * math.pi
                local speed = 1.5
                
                -- 1º anel
                table.insert(enemy.bullets, {
                    x = enemy.x,
                    y = enemy.y,
                    dx = math.cos(angle) * speed,
                    dy = math.sin(angle) * speed,
                    life_timer = 0
                })
                
                -- 2º anel (offset +45°)
                local offset1 = angle + (math.pi / 4)
                table.insert(enemy.bullets, {
                    x = enemy.x,
                    y = enemy.y,
                    dx = math.cos(offset1) * speed,
                    dy = math.sin(offset1) * speed,
                    life_timer = 0
                })
                
                -- 3º anel (offset -45°)
                local offset2 = angle - (math.pi / 4)
                table.insert(enemy.bullets, {
                    x = enemy.x,
                    y = enemy.y,
                    dx = math.cos(offset2) * speed,
                    dy = math.sin(offset2) * speed,
                    life_timer = 0
                })
            end
        end
        
        enemy.shoot_timer = 0
    end
    
    -- Keep dentro dos limites
    enemy.x = clamp(16, enemy.x, 512 - 16)
    enemy.y = clamp(16, enemy.y, 256 - 16)
end

local function update_refletor(enemy, player, dt)
    local dist_p = dist(enemy.x, enemy.y, player.x, player.y)
    
    -- ======================== ESTADO E FASE ========================
    -- Calcula o estado de dano (0 = cheio, 1 = morrendo)
    local health_ratio = enemy.lifes / enemy.max_hp
    
    -- Define a fase baseado no HP
    local phase = 1
    if health_ratio < 0.75 then phase = 2 end  -- Danificado
    if health_ratio < 0.5 then phase = 3 end   -- Muito danificado
    if health_ratio < 0.25 then phase = 4 end  -- Crítico
    
    enemy.current_phase = phase
    
    -- ======================== MOVIMENTO ========================
    -- Comportamento defensivo: tenta manter distância, anda em volta
    
    if phase == 1 then
        -- Fase 1: Movimento lento e padrão defensivo
        if dist_p < 120 then
            -- Se muito perto, foge
            local dx, dy = enemy.x - player.x, enemy.y - player.y
            local mag = dist(0, 0, dx, dy)
            if mag > 0 then
                enemy.dx = (dx / mag) * enemy.speed * 0.6
                enemy.dy = (dy / mag) * enemy.speed * 0.6
            end
        else
            -- Movimento errático defensivo
            if not enemy.wander_timer or enemy.wander_timer <= 0 then
                local angle = love.math.random() * 2 * math.pi
                enemy.wander_dx = math.cos(angle) * enemy.speed * 0.5
                enemy.wander_dy = math.sin(angle) * enemy.speed * 0.5
                enemy.wander_timer = 120  -- Muda direção a cada 2 segundos
            end
            enemy.dx = enemy.wander_dx
            enemy.dy = enemy.wander_dy
            enemy.wander_timer = (enemy.wander_timer or 0) - 1
        end
        
    elseif phase == 2 or phase == 3 then
        -- Fase 2-3: Mais agressivo, tenta ficar próximo mas defensivo
        if dist_p > 80 then
            -- Aproxima-se um pouco
            local dx, dy = player.x - enemy.x, player.y - enemy.y
            local mag = dist(0, 0, dx, dy)
            if mag > 0 then
                enemy.dx = (dx / mag) * enemy.speed * 0.7
                enemy.dy = (dy / mag) * enemy.speed * 0.7
            end
        else
            -- Circula ao redor do player
            if not enemy.circle_angle then enemy.circle_angle = 0 end
            enemy.circle_angle = enemy.circle_angle + 2 * dt * 60
            
            local circle_radius = 100
            enemy.dx = math.cos(enemy.circle_angle) * enemy.speed * 0.8
            enemy.dy = math.sin(enemy.circle_angle) * enemy.speed * 0.8
        end
        
    else -- phase == 4
        -- Fase 4 (Crítico): Muito agressivo, praticamente anda em volta do player
        if not enemy.aggressive_angle then enemy.aggressive_angle = 0 end
        enemy.aggressive_angle = enemy.aggressive_angle + 4 * dt * 60
        
        local circle_radius = 80
        local target_x = player.x + math.cos(enemy.aggressive_angle) * circle_radius
        local target_y = player.y + math.sin(enemy.aggressive_angle) * circle_radius
        
        local dx = target_x - enemy.x
        local dy = target_y - enemy.y
        local mag = dist(0, 0, dx, dy)
        
        if mag > 0 then
            enemy.dx = (dx / mag) * enemy.speed
            enemy.dy = (dy / mag) * enemy.speed
        end
    end
    
    -- Aplica movimento
    enemy.x = enemy.x + enemy.dx * dt * 60
    enemy.y = enemy.y + enemy.dy * dt * 60
    
    -- ======================== ESCUDO/REFLEXÃO ========================
    -- O escudo fica mais fraco conforme toma dano
    local shield_strength = enemy.shield_strength * health_ratio
    enemy.current_shield_strength = shield_strength
    
    -- Timer de recarga (depois de refletir muito, precisa "carregar")
    enemy.reflect_cooldown = (enemy.reflect_cooldown or 0) - dt * 60
    
    -- Keep dentro dos limites
    enemy.x = clamp(16, enemy.x, 512 - 16)
    enemy.y = clamp(16, enemy.y, 256 - 16)
end

local function update_vampiro(enemy, player, dt)
    update_chaser(enemy, player, dt, 0.75)
    
    local dist_p = dist(enemy.x, enemy.y, player.x, player.y)
    if dist_p < enemy.drain_range then
        enemy.drain_timer = (enemy.drain_timer or 0) + dt * 60
        if enemy.drain_timer >= enemy.drain_rate then
            local heal_amount = enemy.demage * enemy.healing_per_damage
            enemy.lifes = math.min(enemy.max_hp, enemy.lifes + heal_amount)
            player:takeHit(enemy.demage)
            
            for i = 1, 3 do
                part.add(player.x, player.y, 2, 8)
            end
            
            enemy.drain_timer = 0
        end
    else
        enemy.drain_timer = 0
    end
end

local function update_invocador(enemy, player, dt)
    enemy.state_timer = enemy.state_timer + dt * 60
    local dist_p = dist(enemy.x, enemy.y, player.x, player.y)

    -- ================= ESTADO: VAGAR/FUGIR (PADRÃO) =================
    if enemy.state == "patrol" then
        -- Foge do player se estiver perto, senão anda aleatório
        if dist_p < 128 then
            -- Lógica de fugir (igual ao sniper)
            local dx, dy = enemy.x - player.x, enemy.y - player.y
            local mag = math.sqrt(dx^2 + dy^2)
            if mag > 0 then
                enemy.x = enemy.x + (dx/mag) * enemy.speed * dt * 60
                enemy.y = enemy.y + (dy/mag) * enemy.speed * dt * 60
            end
        else
            local dx, dy = enemy.x - player.x, enemy.y - player.y
            local mag = math.sqrt(dx^2 + dy^2)
            if mag > 0 then
                enemy.x = enemy.x - (dx/mag) * enemy.speed * dt * 60
                enemy.y = enemy.y - (dy/mag) * enemy.speed * dt * 60
            end
        end

        if enemy.state_timer > 300 then
            changeState(enemy, "channel")
        end

    -- ================= ESTADO: CANALIZANDO =================
    elseif enemy.state == "channel" then
        enemy.dx, enemy.dy = 0, 0 -- Fica imóvel (vulnerável)
        
        -- Efeito visual: tremer
        enemy.x = enemy.x + math.random(-1, 1)
        
        -- Demora 1.5s para invocar
        if enemy.state_timer > 90 then
            changeState(enemy, "summon")
        end

    -- ================= ESTADO: INVOCAR =================
    elseif enemy.state == "summon" then
        -- Invoca 2 inimigos fracos (ex: perseguidor ou bomb)
        for i = 1, 1 do
            local offsetX = math.random(-24, 24)
            local offsetY = math.random(-24, 24)
            -- Usa o waves_manager que salvamos no spawn_enemy
            if enemy.waves_manager then
                local minion = enemies_module.spawn_enemy("perseguidor", enemy.x + offsetX, enemy.y + offsetY, enemy.waves_manager)
                -- Opcional: minion nasce com vida reduzida
                if minion then minion.lifes = 0.75 end
                
                -- Efeito visual
                local part = require("part")
                part.add(enemy.x + offsetX, enemy.y + offsetY, 15, 7) -- Partícula branca/fumaça
            end
        end
        
        changeState(enemy, "patrol")
    end
end

local function update_teleportador(enemy, player, dt)
    enemy.teleport_timer = enemy.teleport_timer + dt * FRAMERATE
    
    if enemy.teleport_timer >= (enemy.teleport_cooldown - 90) and not enemy.is_teleporting then
        enemy.is_teleporting = true
        enemy.target_x = math.random(32, (128*4) - 32)
        enemy.target_y = math.random(32, (128*2) - 32)
    end

    if enemy.teleport_timer >= enemy.teleport_cooldown then
        enemy.teleport_timer = 0
        enemy.is_teleporting = false
        
        addpart(enemy.x, enemy.y, 15, 7)
        enemy.x, enemy.y = enemy.target_x, enemy.target_y
        addpart(enemy.x, enemy.y, 15, 7)

        spawn_bullet_targeted(enemy, player, enemy.bullet_speed)
    end
    for i=#enemy.bullets,1,-1 do
        local b = enemy.bullets[i]
        b.x = b.x + b.dx * dt * FRAMERATE
        b.y = b.y + b.dy * dt * FRAMERATE
        b.life_timer = b.life_timer + dt * FRAMERATE
        if b.x < 0 or b.x > (128*4) or b.y < 0 or b.y > (128*2) then
            table_remove(enemy.bullets, i)
        end
    end
end

local function spawn_bullet_orbit(enemy, num_bullets, radius, speed)
    enemy.orbit_radius = radius
    enemy.orbit_speed = speed
    for i = 0, num_bullets-1 do
        local angle = (i / num_bullets) * 2 * pi
        table_insert(enemy.bullets, {
            parent = enemy,
            angle = angle,
            radius = radius,
            speed = speed,
            x = enemy.x + cos(angle) * radius,
            y = enemy.y + sin(angle) * radius,
            dx = 0, dy = 0,
            chasing = false
        })
    end
end
enemies_module.spawn_bullet_orbit = spawn_bullet_orbit

local function spawn_bullet_circle(enemy, num_bullets, speed)
    for i=0,num_bullets-1 do
        local angle = (i / num_bullets) * 2 * pi
        table_insert(enemy.bullets, {
            x = enemy.x,
            y = enemy.y,
            dx = cos(angle) * speed,
            dy = sin(angle) * speed,
            life_timer = 0
        })
    end
end
enemies_module.spawn_bullet_circle = spawn_bullet_circle

function update_chaser(enemy, player, dt, speed_mult)
    local dx, dy = player.x - enemy.x, player.y - enemy.y
    local mag = dist(0,0,dx,dy)
    if mag > 0 then
        local mult = speed_mult or 1.0
        enemy.dx, enemy.dy = dx/mag * enemy.speed, dy/mag * enemy.speed
        enemy.x = enemy.x + enemy.dx * mult * dt * FRAMERATE
        enemy.y = enemy.y + enemy.dy * dt * FRAMERATE
    end
end

local function update_shooter(enemy, player, dt)
    update_chaser(enemy, player, dt, 1.0)
    enemy.shoot_timer = enemy.shoot_timer + dt * FRAMERATE
    if enemy.shoot_timer >= enemy.shoot_rate then
        enemy.shoot_timer = 0
        spawn_bullet_circle(enemy, 5, 0.5)
    end
end

local function update_horizontal(enemy, _, dt)
    enemy.x = enemy.x + enemy.speed * enemy.dir * dt * FRAMERATE
    if enemy.x <= 0 or enemy.x >= (128*4)-8 then
        enemy.dir = -enemy.dir
        enemy.x = enemy.x + enemy.dir * 8
        enemy.y = enemy.y + 24
    end
    if enemy.y >= 128*2 then enemy.y = 0 end
end

local function update_orbiter(enemy, player, dt)
    update_chaser(enemy, player, dt, 1.0)
    for _, b in ipairs(enemy.bullets) do
        if not b.chasing then
            b.angle = b.angle + (b.speed * dt)
            b.x = enemy.x + cos(b.angle) * enemy.orbit_radius
            b.y = enemy.y + sin(b.angle) * enemy.orbit_radius
        end
    end
    enemy.shoot_timer = enemy.shoot_timer + dt * FRAMERATE
    if enemy.shoot_timer >= 60 then
        enemies_module.launch_chasing_bullet(enemy)
        enemy.shoot_timer = 0
    end
end

local function update_boss(enemy, player, dt)
    local dx, dy = player.x - enemy.x, player.y - enemy.y
    local mag = dist(0,0,dx,dy)
    if mag > 0 then
        enemy.dx, enemy.dy = dx/mag * enemy.speed, dy/mag * enemy.speed
        enemy.x = enemy.x + enemy.dx * dt * FRAMERATE / 1.5
        enemy.y = enemy.y + enemy.dy * dt * FRAMERATE
    end
    enemy.summon_timer = (enemy.summon_timer or 0) + dt * FRAMERATE
    if enemy.summon_timer >= 120 then
        enemy.summon_timer = 0
        enemies_module.spawn_enemy("bomb", enemy.x+8, enemy.y+16,enemy.waves_manager)
    end
    enemy.time = (enemy.time or 0) - dt * FRAMERATE
end

local function update_boss5(enemy, player, dt)
    update_chaser(enemy, player, dt, 1.75)
    for _, b in ipairs(enemy.bullets) do
        if not b.chasing then
            b.angle = b.angle + (b.speed * dt)
            b.x = enemy.x + cos(b.angle) * enemy.orbit_radius
            b.y = enemy.y + sin(b.angle) * enemy.orbit_radius
        end
    end
    enemy.shoot_timer = enemy.shoot_timer + dt * FRAMERATE
    if enemy.shoot_timer >= 45 then
        enemies_module.launch_chasing_bullet(enemy)
        enemy.shoot_timer = 0
    end
end

local function update_boss2(enemy, player, dt)
    enemy.x = enemy.x + enemy.speed * enemy.dirx * dt * FRAMERATE
    local dx, dy = player.x - enemy.x, player.y - enemy.y
    local mag = dist(0,0,dx,dy)
    if mag > 0 then
        enemy.dx, enemy.dy = dx/mag * enemy.speed, dy/mag * (enemy.speed*2)
        enemy.y = enemy.y + enemy.dy * dt * FRAMERATE
    end
    enemy.summon_timer = (enemy.summon_timer or 0) + dt * FRAMERATE
    if enemy.summon_timer >= 60*4 then
        enemy.summon_timer = 0
        enemies_module.spawn_enemy("paladino", enemy.x+8, enemy.y+32,enemy.waves_manager)
    end
    if enemy.x <= 0 or enemy.x >= (128*4)-8 then
        enemy.dirx = -enemy.dirx
        enemy.y = enemy.y + 24
        enemy.x = enemy.x + enemy.dirx*17
    end
    if enemy.y >= 128*2 then enemy.y = 0 end
end

local function update_boss3(enemy, player, dt)
    enemy.x = enemy.x + enemy.speed * enemy.dir * dt * FRAMERATE
    if enemy.x <= 1 or enemy.x >= (128*4)-8 then enemy.dir = -enemy.dir end
    enemy.y=16
    enemy.timer = (enemy.timer or 0) + 1
    if enemy.timer % 45 == 0 then
        table_insert(enemy.bullets, { x=enemy.x, y=enemy.y, dx=0, dy=1.5, life_timer=0 })
    end
    if enemy.timer % 120 == 0 then
        enemies_module.spawn_enemy("bomb", enemy.x, enemy.y+24, enemy.waves_manager)
    end
    for i=#enemy.bullets,1,-1 do
        local b = enemy.bullets[i]
        b.x = b.x + b.dx * dt * FRAMERATE
        b.y = b.y + b.dy * dt * FRAMERATE
        b.life_timer = b.life_timer + dt * FRAMERATE
        if b.x < 0 or b.x > (128*4) or b.y < 0 or b.y > (128*4) then
            table_remove(enemy.bullets, i)
        end
    end
end

local function update_boss4(enemy, player, dt)
    enemy.timer = (enemy.timer or 0) + 1
    if enemy.timer % (60*4) == 0 then
        enemies_module.spawn_enemy("teleportador", enemy.x+24, enemy.y+24, enemy.waves_manager)
    end
    
    enemy.teleport_timer = enemy.teleport_timer + dt * FRAMERATE
    
    if enemy.teleport_timer >= (enemy.teleport_cooldown - 90) and not enemy.is_teleporting then
        enemy.is_teleporting = true
        enemy.target_x = math.random(16, (128*4) - 16)
        enemy.target_y = math.random(16, (128*2) - 16)
    end

    if enemy.teleport_timer >= enemy.teleport_cooldown then
        enemy.teleport_timer = 0
        enemy.is_teleporting = false
        
        addpart(enemy.x, enemy.y, 15, 7)
        enemy.x = enemy.target_x
        enemy.y = enemy.target_y
        addpart(enemy.x, enemy.y, 15, 7)

        spawn_bullet_targeted(enemy, player, enemy.bullet_speed)
    end

    for i=#enemy.bullets,1,-1 do
        local b = enemy.bullets[i]
        b.x = b.x + b.dx * dt * FRAMERATE
        b.y = b.y + b.dy * dt * FRAMERATE
        b.life_timer = b.life_timer + dt * FRAMERATE
        if b.x < 0 or b.x > (128*4) or b.y < 0 or b.y > (128*2) then
            table_remove(enemy.bullets, i)
        end
    end
end

local function update_arma(enemy, player, dt)
    update_chaser(enemy, player, dt)
    enemy.shoot_timer = enemy.shoot_timer + dt * FRAMERATE
    if enemy.shoot_timer >= 75 then
        enemy.shoot_timer = 0
        spawn_bullet_circle(enemy, 5, 0.95)
    end
    for i=#enemy.bullets,1,-1 do
        local b = enemy.bullets[i]
        b.x = b.x + b.dx * dt * FRAMERATE
        b.y = b.y + b.dy * dt * FRAMERATE
        b.life_timer = b.life_timer + dt * FRAMERATE
        if b.x < 0 or b.x > (128*4) or b.y < 0 or b.y > (128*2) then
            table_remove(enemy.bullets, i)
        end
    end
end

local update_functions = {
    perseguidor = function(e, p, dt) update_chaser(e, p, dt, e.accel_mult) end,
    bomb = update_bomb,
    atirador = update_shooter,
    horizontal = update_horizontal,
    circulador = update_orbiter,
    boss = update_boss, boss2 = update_boss2, boss3 = update_boss3, boss4=update_boss4,boss5=update_boss5,
    arma = update_arma,
    teleportador = update_teleportador,
    divisor = function(e, p, dt) update_chaser(e, p, dt, e.accel_mult) end,
    paladino = update_paladino,
    invocador = update_invocador,
    renas_especial = update_flee,
    spike=update_spike,
    espiral=update_espiral,
    refletor=update_refletor,
    vampiro=update_vampiro,
}


function enemies_module.update_enemy(enemy, player, dt)
    enemy.speed = clamp(0.95, enemy.speed, MAX_ENEMY_SPEED)
    enemy.x=clamp(0,enemy.x,512)
    enemy.y=clamp(0,enemy.y,256)
    update_squash_stretch(enemy, dt)
    local update_fn = update_functions[enemy.tipo]
    if enemy.tempo_pausado<=0 then
        if update_fn then
            update_fn(enemy, player, dt)
        end
    else
        enemy.tempo_pausado=clamp(0, enemy.tempo_pausado-1/60,1)
    end

    if enemy.teia_slow and enemy.teia_slow_factor then
        enemy.dx = enemy.dx * enemy.teia_slow_factor
        enemy.dy = enemy.dy * enemy.teia_slow_factor
    end
    
    local game_timer = _G.game_timer or 0
    local e = enemy
    if e.veneno and game_timer % (player.veneno_delay or 60) < dt then
        local dmg = player.veneno_dano or 0.1
        e.takeDamage(e, dmg)
        player:recordElementalDamage("veneno", dmg)
        player:recordElementalApplication("veneno")
        addpart(e.x, e.y, 8, 3)
    end
    if e.fogo and game_timer % (player.fogo_delay or 60) < dt then
        local dmg = player.fogo_dano or 0.1
        e.takeDamage(e, dmg)
        player:recordElementalDamage("fogo", dmg)
        player:recordElementalApplication("fogo")
        addpart(e.x, e.y, 8, 9)
    end
    if e.gelo and game_timer % (player.gelo_delay or 60) < dt then
        local dmg = player.gelo_dano or 0.1
        e.takeDamage(e, dmg)
        player:recordElementalDamage("gelo", dmg)
        player:recordElementalApplication("gelo")
        e.speed = math.max(0.15, e.speed - 0.25)
        e.tempo_pausado=0.65
        addpart(e.x, e.y, 8, 1)
    end
    
    if enemy.x > player.x then
        enemy.flpx=1
    else
        enemy.flpx=-1
    end
    
    if enemy.lifes <= 0 then
        if love.math.random() < 0.0025 then
            enemies_module.spawn_heart(enemy.x, enemy.y)
        end
        enemy.dead = true
    end
end

local function draw_enemy(enemy)
    if enemy.image then
        Shaders:reset()
        if enemy.tipo == "bomb" then
            Shaders.presets.bomb(Shaders, enemy)
        elseif enemy.veneno then
            Shaders.presets.poison(Shaders, enemy)
        elseif enemy.fogo then
            Shaders.presets.fire(Shaders, enemy)
        elseif enemy.gelo then
            Shaders.presets.ice(Shaders, enemy)
        elseif enemy.tipo == "boss" or enemy.tipo == "boss2" or enemy.tipo == "boss3" then
            Shaders.presets.boss(Shaders, enemy)
        else
            Shaders.presets.common(Shaders, enemy)
        end

        if Shaders:isFlashing(enemy) then
            Shaders:applyHitFlash(Shaders:getFlashAmount(enemy))
        end
        
        Utils.setColor(7)
        Shaders:use()

        local current_sx = 2 * enemy.sx * enemy.flpx
        local current_sy = 2 * enemy.sy
        local tilt = (enemy.dx or 0) * 0.05
        
        if enemy.is_golden then Utils.setColor(10) else Utils.setColor(7) end -- 10 é amarelo na paleta pico-8
        love.graphics.draw(
            enemy.image, 
            enemy.x, 
            enemy.y,
            tilt,
            current_sx,
            current_sy,
            enemy.image:getWidth()/2,
            enemy.image:getHeight()/2
        )
        
        Shaders:clear()
    end

    if (enemy.tipo == "teleportador" or enemy.tipo == "boss4") and enemy.is_teleporting then
        Utils.setColor(8)
        
        local pulse = math.sin(love.timer.getTime() * 10)
        local radius = 12
        local lineWidth = 1
        
        if enemy.tipo == "boss4" then
             radius = 32 + pulse * 4
             lineWidth = 3
        else
             radius = 12 + pulse * 3
        end
        
        love.graphics.setLineWidth(lineWidth)
        love.graphics.circle("line", enemy.target_x, enemy.target_y, radius)
        
        love.graphics.setColor(1, 0, 0, 0.4 + pulse * 0.2)
        love.graphics.circle("fill", enemy.target_x, enemy.target_y, radius * 0.5)
        
        love.graphics.setLineWidth(1)
        Utils.setColor(7)
        
        if enemy.tipo == "boss4" then
            love.graphics.print("!!", enemy.target_x - 4, enemy.target_y - 48)
        else
            love.graphics.print("!", enemy.target_x - 2, enemy.target_y - 24)
        end
    end

    local bar_width = 10
    local bar_height = 2
    local y_offset = (enemy.image and enemy.image:getHeight() / 2 or 4) + 2
    
    Utils.setColor(1)
    love.graphics.rectangle('fill', enemy.x - bar_width / 2, enemy.y - y_offset, bar_width, bar_height)
    
    if enemy.lifes > 0 then
        Utils.setColor(11)
        local health_percentage = enemy.lifes / enemy.max_hp
        love.graphics.rectangle('fill', enemy.x - bar_width / 2, enemy.y - y_offset, bar_width * health_percentage, bar_height)
    end

    for _, bullet in ipairs(enemy.bullets) do
        Utils.setColor(7)
        Shaders.presets.fire(Shaders, enemy)
        love.graphics.draw(
            presente, 
            bullet.x, 
            bullet.y,
            0,
            1,
            1,
            presente:getWidth()/2,
            presente:getHeight()/2
        )
        Shaders:clear()
    end
    
    -- Desenhar aura de invocação
    if enemy.tipo == "invocador" and enemy.state == "channel" then
        Utils.setColor(10) -- amarelo
        local raio = 16 + math.sin(love.timer.getTime() * 10) * 4
        love.graphics.circle("line", enemy.x + 8, enemy.y + 8, raio)
    end

    if Debug.options.show_enemy_rect then
        love.graphics.setColor(1, 0, 0, 1) -- Vermelho para inimigos
        -- Ajuste w e h conforme a lógica de colisão do seu inimigo
        local w = enemy.w or 16
        local h = enemy.h or 16
        love.graphics.rectangle("line", enemy.x-(2*enemy.flpx), enemy.y-4, w*enemy.flpx, h)
    end

    if Debug.active then -- Se tiver modo debug
        love.graphics.print(enemy.state, enemy.x - 10, enemy.y - 20)
    end
end

-- ================== SISTEMA DE CORAÇÕES (DROPS) ==================

function enemies_module.spawn_heart(x, y)
    if #hearts<=4 then
        table_insert(hearts, {
            x = x,
            y = y,
            w = 48,
            h = 48,
            timer = 0,
            pulse = 0
        })
    end
end

function enemies_module.update_hearts(dt, player)
    for i = #hearts, 1, -1 do
        local h = hearts[i]
        
        h.pulse = h.pulse + dt * 2.5
        h.y = h.y + math.sin(h.pulse) * 0.15 -- Efeito leve de flutuação

        -- Colisão com jogador
        if Utils.col(h, player) then
            -- Cura a vida atual, respeitando o máximo
            if player.lifes < player.max_life then
                player.lifes = math.min(player.max_life, player.lifes + 1)
                SFX_Pickup_Heart:play()
                
                -- Efeito visual de cura
                part.add(player.x, player.y, 8, 2) -- Partículas rosa
                
                table_remove(hearts, i)
            end
        end
    end
end

function enemies_module.draw_hearts()
    for _, h in ipairs(hearts) do
        local scale = 1 + math.sin(h.pulse) * 0.05
        Utils.setColor(7)
        love.graphics.draw(heart_sprite, h.x, h.y, 0, scale, scale)
    end
end

-- ============ moedas ===============

function enemies_module.spawn_coin(x, y, value)
    table.insert(coins, {
        x = x,
        y = y,
        value = value,
        w = 8, h = 8,
        timer = 0,
        pulse = math.random() * 6
    })
end

function enemies_module.update_coins(dt, player)
    for i = #coins, 1, -1 do
        local c = coins[i]
        c.pulse = c.pulse + dt * 4
        c.y = c.y + math.sin(c.pulse) * 0.1 -- Flutuação leve

        -- Ímã de dinheiro (se tiver relíquia ou padrão)
        local magnet_range = 32
        if player.relics and player.relics["Coin Magnet"] then magnet_range = 128 end
        
        local dist_p = math.sqrt((c.x - player.x)^2 + (c.y - player.y)^2)
        
        -- Atrai para o player se estiver perto
        if dist_p < magnet_range then
            c.x = c.x + (player.x - c.x) * 5 * dt
            c.y = c.y + (player.y - c.y) * 5 * dt
        end

        -- Coleta
        if Utils.col(c, player) then
            player.money = (player.money or 0) + c.value
            SFX_Pickup_Coin:play()
            table.remove(coins, i)
        end
    end
end

function enemies_module.draw_coins()
    for _, c in ipairs(coins) do
        -- Desenha moeda (Círculo amarelo com borda laranja)
        local scale = (c.value >= 100) and 1.5 or 1.0
        
        love.graphics.setColor(1, 0.8, 0, 1) -- Ouro
        love.graphics.circle("fill", c.x + 4, c.y + 4, 3 * scale)
        
        love.graphics.setColor(1, 0.5, 0, 1) -- Borda Laranja
        love.graphics.setLineWidth(1)
        love.graphics.circle("line", c.x + 4, c.y + 4, 3 * scale)
        
        Utils.setColor(7) -- Reset
    end
end

-- ================================================================

function enemies_module.update(dt, player)
    Shaders:update(dt)
    
    golden_spawn_timer = golden_spawn_timer + dt
    if golden_spawn_timer >= 3.0 then -- A cada 3 segundos
        golden_spawn_timer = 0
        local golden_chance = 0.025
        if player.relics and player.relics["Sorte Dourada"] then
            golden_chance = 0.05 -- Dobra a chance
        end
        if math.random() <= golden_chance then -- 2.5% de chance
            local x = math.random(32, 128*4 - 32)
            local y = math.random(32, 128*2 - 32)
            local e = enemies_module.spawn_enemy("renas_especial", x, y, player.waves_manager or require("wave"))
            if e then 
                print("🌟 RENA DOURADA SPAWNOU!")
                part.add(x, y, 25, 10) -- Explosão visual de spawn
            end
        end
    end

    for i = #enemies, 1, -1 do
        local e = enemies[i]
        enemies_module.update_enemy(e, player, dt)
        Shaders:updateEnemyFlash(e, dt)
        if e.dead then
            if player.death_explosion then
                local explosion_damage = player.demage * (player.explosion_damage or 0.5)
                local explosion_radius = player.explosion_radius or 24
                
                -- Causa dano em todos os inimigos próximos
                for _, other_enemy in ipairs(enemies) do
                    if other_enemy ~= e then
                        local dist = math.sqrt((e.x - other_enemy.x)^2 + (e.y - other_enemy.y)^2)
                        if dist < explosion_radius then
                            other_enemy:takeDamage(explosion_damage)
                        end
                    end
                end
                
                -- Efeito visual de explosão
                local part = require("part")
                part.add(e.x, e.y, 30, 8) -- Partículas vermelhas
                
                -- Som de explosão
                local SFX_Explosion = love.audio.newSource("assets/hitHurt.wav", "static")
                SFX_Explosion:setPitch(0.3)
                SFX_Explosion:setVolume(0.25)
                SFX_Explosion:play()
            end 
            if e.is_golden then
                -- Drop garantido de 100
                enemies_module.spawn_coin(e.x, e.y, 25)
                part.add(e.x, e.y, 20, 8) -- Partículas douradas
            else
                -- Chance normal de drop (ex: 20% de dropar 10)
                -- Se tiver relíquia "Greed", dropa mais
                local chance = 0.2
                local val = 5
                if player.relics and player.relics["Greed"] then 
                    chance = 0.3
                    val = 10
                end
                
                if math.random() < chance then
                    enemies_module.spawn_coin(e.x, e.y, val)
                end
            end
            if player.lifesteal_chance > 0 and player.lifes < player.max_life then
                if math.random() < player.lifesteal_chance then
                    player.lifes = math.min(player.max_life, player.lifes + 1)
                    local part = require("part")
                    part.add(player.x, player.y, 15, 32)
                    local SFX_Heal = love.audio.newSource("assets/hitHurt.wav", "static")
                    SFX_Heal:setPitch(1.5)
                    SFX_Heal:setVolume(0.2)
                    SFX_Heal:play()
                end
            end
            if e.tipo == "divisor" then
                enemies_module.spawn_enemy("perseguidor", e.x - 8, e.y, e.waves_manager)
                enemies_module.spawn_enemy("perseguidor", e.x + 8, e.y, e.waves_manager)
            end
            
            local heart_chance = 0.05
            if player.relics and player.relics["Sorte Dourada"] then
                heart_chance = 0.10 -- Dobra a chance
            end
            if math.random() < heart_chance then
                enemies_module.spawn_heart(e.x, e.y)
            end
            
            table.remove(enemies, i)
        end
    end
    
    enemies_module.update_hearts(dt, player) -- Atualiza corações
    enemies_module.update_coins(dt, player)
    
    resolve_enemy_collisions()
end

local function draw_boss_healthbar(enemy)
    local screen_width = 128 * 4
    local bar_width = 200
    local bar_height = 12
    local bar_x = (screen_width - bar_width) / 2
    local bar_y = 16
    
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle('fill', bar_x - 2, bar_y - 2, bar_width + 4, bar_height + 4, 2)
    
    Utils.setColor(10)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle('line', bar_x - 2, bar_y - 2, bar_width + 4, bar_height + 4, 2)
    love.graphics.setLineWidth(1)
    
    love.graphics.setColor(0.3, 0, 0, 1)
    love.graphics.rectangle('fill', bar_x, bar_y, bar_width, bar_height, 1)
    
    if enemy.lifes > 0 then
        local health_percentage = enemy.lifes / enemy.max_hp
        local current_width = bar_width * health_percentage
        
        local r, g, b
        if health_percentage > 0.5 then
            r = 1 - (health_percentage - 0.5) * 2
            g = 1
            b = 0
        else
            r = 1
            g = health_percentage * 2
            b = 0
        end
        
        love.graphics.setColor(r, g, b, 1)
        love.graphics.rectangle('fill', bar_x, bar_y, current_width, bar_height, 1)
        
        love.graphics.setColor(1, 1, 1, 0.25)
        love.graphics.rectangle('fill', bar_x, bar_y, current_width, bar_height / 3, 1)
    end
    
    Utils.setColor(7)
    local hp_text = string.format("%d / %d", math.ceil(enemy.lifes), math.ceil(enemy.max_hp))
    
    local hp_width = love.graphics.getFont():getWidth(hp_text)
    love.graphics.print(hp_text, bar_x + (bar_width - hp_width) / 2, bar_y + 2)
end

function enemies_module.draw()
    enemies_module.draw_hearts() -- Desenha os corações no chão
    enemies_module.draw_coins()

    for _, enemy in ipairs(enemies) do
        draw_enemy(enemy)
    end
    
    for _, enemy in ipairs(enemies) do
        if is_boss(enemy.tipo) then
            draw_boss_healthbar(enemy)
        end
    end
end

function enemies_module.reset()
    enemies = {}
    hearts  = {} -- Limpa corações ao resetar
    coins   = {}
end

function enemies_module.launch_chasing_bullet(enemy)
    for _, b in ipairs(enemy.bullets) do
        if not b.chasing then
            b.chasing = true
            b.dx, b.dy = 0,0
            return
        end
    end
end

function enemies_module.get_all()
    return enemies
end

function enemies_module.damageAll(amount)
    for _, enemy in ipairs(enemies) do
        enemy.lifes = enemy.lifes - amount
        if enemy.flash_timer then enemy.flash_timer = 0.15 end
        if SFX_Enemy_Morte then SFX_Enemy_Morte:play() end
    end
end

function enemies_module.healAll(amount)
    for _, enemy in ipairs(enemies) do
        enemy.lifes = math.min(enemy.lifes + amount, enemy.max_hp)
    end
end

return enemies_module