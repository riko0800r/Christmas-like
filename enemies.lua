local Utils = require("utils")
local part = require("part")
local Camera= require("camera")
local Shaders = require("shaders")

local enemies_module = {}

SFX_Enemy_Morte=love.audio.newSource("assets/hitHurt.wav","static")
-- Som para pegar o coração
SFX_Pickup_Heart=love.audio.newSource("assets/vida.wav","static")
SFX_Pickup_Heart:setPitch(1.5)
SFX_Pickup_Heart:setVolume(0.25)

SFX_Enemy_Morte:setVolume(0.1)

love.graphics.setDefaultFilter("nearest", "nearest")

local enemies = {}
local hearts = {} -- Lista de corações no chão
local sprite_sheets = {}
local pi = math.pi
local sqrt = math.sqrt
local cos = math.cos
local sin = math.sin
local addpart = part.add
local table_insert = table.insert
local table_remove = table.remove
local clamp=Utils.clamp

local presente=love.graphics.newImage("assets/Presente.png")
-- Carrega a imagem do coração
local heart_sprite=love.graphics.newImage("assets/VidaICON.png")

local MAX_ENEMY_SPEED = 2.5
local FRAMERATE = 60

local function dist(x1, y1, x2, y2)
    return sqrt((x2 - x1)^2 + (y2 - y1)^2)
end

local EnemyPresets = {
    perseguidor = {demage_preset=1,speed_base = 1.25, speed_scale = 1/16, hp_base = 1.5, hp_scale = 1/8,demage_scale=1/800, accel_mult = 1.5,sprite=1},
    atirador = {demage_preset=1,speed_base = 0.55, speed_scale = 1/16, hp_base = 3, hp_scale = 1/8,demage_scale=1/300, shoot_rate = 60*6, shoot_timer = 0,sprite=1},
    horizontal = {demage_preset=1,speed_base = 2, speed_scale = 1/16, hp_base = 1, hp_scale = 1/8,demage_scale=1/200, dir = 1,sprite=1},
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
        demage_preset=2, speed_base = 0.7, speed_scale = 1/16, hp_base = 4.5, hp_scale = 1/8, demage_scale=1/600, 
        accel_mult = 1.0, sprite=5,
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
    }

    enemy.w = enemy.w or 16 -- Se não tiver largura definida, assume 16
    enemy.h = enemy.h or 16

    -- Define hitbox menor (ex: 70% do tamanho visual)
    enemy.hitbox_w = math.floor(enemy.w * 0.7)
    enemy.hitbox_h = math.floor(enemy.h * 0.7)

    -- Calcula o offset para centralizar
    enemy.hitbox_off_x = (enemy.w - enemy.hitbox_w) / 2
    enemy.hitbox_off_y = (enemy.h - enemy.hitbox_h) / 2

    for k, v in pairs(preset) do
        enemy[k] = v
    end
    
    enemy.image = sprite_sheets[preset.sprite]

    enemy.speed = preset.speed_base + Waves.current_wave * preset.speed_scale
    enemy.lifes = preset.hp_base + Waves.current_wave * preset.hp_scale
    enemy.demage = (preset.demage_preset or 1) + Waves.current_wave * preset.demage_scale
    enemy.max_hp = enemy.lifes
    
    enemy.speed = clamp(0.15, enemy.speed, MAX_ENEMY_SPEED)
    
    Shaders:initEnemyFlash(enemy)
    if tipo=="divisor" then
        enemy.w=enemy.w*2
        enemy.h=enemy.h*2
    end

    enemy.radius = (enemy.w * 1.75) / 2

    enemy.takeDamage = function(self, dmg)
        self.lifes = self.lifes - dmg
        Camera:shake(0.2,0.75)
        local randomPitch = love.math.random() * 0.4 + 0.8
        SFX_Enemy_Morte:setPitch(randomPitch)
        SFX_Enemy_Morte:play()
        Shaders:triggerFlash(self)
        if self.lifes <= 0 then self.dead = true end
    end

    if tipo == "circulador" or tipo == "boss5" then
        enemies_module.spawn_bullet_orbit(enemy, preset.num_bullets, preset.orbit_radius, preset.orbit_speed)
    end
    
    if tipo == "divisor" then
        enemy.w=24
        enemy.h=24
    end

    table_insert(enemies, enemy)
    return enemy
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
    if enemy.x <= -8 or enemy.x >= (128*4)-8 then
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
    if enemy.summon_timer >= 90 then
        enemy.summon_timer = 0
        enemies_module.spawn_enemy("atirador", enemy.x+8, enemy.y+32,enemy.waves_manager)
    end
    if enemy.x <= -8 or enemy.x >= (128*4)-8 then
        enemy.dirx = -enemy.dirx
        enemy.y = enemy.y + 24
        enemy.x = enemy.x + enemy.dirx*17
    end
    if enemy.y >= 128*2 then enemy.y = 0 end
end

local function update_boss3(enemy, player, dt)
    enemy.x = enemy.x + enemy.speed * enemy.dir * dt * FRAMERATE
    if enemy.x <= -8 or enemy.x >= (128*4)-8 then enemy.dir = -enemy.dir end
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
}

function enemies_module.update_enemy(enemy, player, dt)
    enemy.speed = clamp(0.95, enemy.speed, MAX_ENEMY_SPEED)
    local update_fn = update_functions[enemy.tipo]
    if enemy.tempo_pausado<=0 then
        if update_fn then
            update_fn(enemy, player, dt)
        end
    else
        enemy.tempo_pausado=clamp(0, enemy.tempo_pausado-1/60,1)
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
        if love.math.random() < 0.01 then
            enemies_module.spawn_heart(enemy.x, enemy.y)
        end
        enemy.dead = true
    end
end

local function draw_enemy(enemy)
    if enemy.image then
        if Shaders:isFlashing(enemy) then
            Shaders:applyHitFlash(Shaders:getFlashAmount(enemy))
        elseif enemy.tipo == "bomb" then
            Shaders.presets.bomb(Shaders, enemy)
        elseif enemy.veneno then
            Shaders.presets.poison(Shaders, enemy)
        elseif enemy.fogo then
            Shaders.presets.fire(Shaders, enemy)
        else
            Shaders.presets.common(Shaders, enemy)
        end
        
        Utils.setColor(7)
        love.graphics.draw(
            enemy.image, 
            enemy.x, 
            enemy.y,
            0,
            2*enemy.flpx,
            2,
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

    if Debug.options.show_enemy_rect then
        love.graphics.setColor(1, 0, 0, 1) -- Vermelho para inimigos
        -- Ajuste w e h conforme a lógica de colisão do seu inimigo
        local w = enemy.w or 16
        local h = enemy.h or 16
        love.graphics.rectangle("line", enemy.x-(4*enemy.flpx), enemy.y-4, w*enemy.flpx, h)
    end
end

-- ================== SISTEMA DE CORAÇÕES (DROPS) ==================

function enemies_module.spawn_heart(x, y)
    table_insert(hearts, {
        x = x,
        y = y,
        w = 40,
        h = 40,
        timer = 0,
        pulse = 0
    })
end

function enemies_module.update_hearts(dt, player)
    for i = #hearts, 1, -1 do
        local h = hearts[i]
        
        h.pulse = h.pulse + dt * 2
        h.y = h.y + math.sin(h.pulse) * 0.2 -- Efeito leve de flutuação

        -- Colisão com jogador
        if Utils.col(h, player) then
            -- Cura a vida atual, respeitando o máximo
            if player.lifes < player.max_life then
                player.lifes = math.min(player.max_life, player.lifes + 2)
                SFX_Pickup_Heart:play()
                
                -- Efeito visual de cura
                part.add(player.x, player.y, 8, 2) -- Partículas verdes/rosa
                
                table_remove(hearts, i)
            end
        end
    end
end

function enemies_module.draw_hearts()
    for _, h in ipairs(hearts) do
        local scale = 1 + math.sin(h.pulse) * 0.15
        Utils.setColor(7)
        love.graphics.draw(heart_sprite, h.x, h.y, 0, scale, scale, heart_sprite:getWidth()/2, heart_sprite:getHeight()/2)
    end
end

-- ================================================================

function enemies_module.update(dt, player)
    Shaders:update(dt)
    for i = #enemies, 1, -1 do
        local e = enemies[i]
        enemies_module.update_enemy(e, player, dt)
        Shaders:updateEnemyFlash(e, dt)
        if e.dead then
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
            
            -- >>> NOVO: Chance de dropar coração (5%) <<<
            if math.random() < 0.05 then
                enemies_module.spawn_heart(e.x, e.y)
            end
            
            table.remove(enemies, i)
        end
    end
    
    enemies_module.update_hearts(dt, player) -- Atualiza corações
    
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
    local boss_name = string.upper(enemy.tipo)
    local hp_text = string.format("%d / %d", math.ceil(enemy.lifes), math.ceil(enemy.max_hp))
    
    local name_width = love.graphics.getFont():getWidth(boss_name)
    love.graphics.print(boss_name, bar_x + (bar_width - name_width) / 2, bar_y - 12)
    
    local hp_width = love.graphics.getFont():getWidth(hp_text)
    love.graphics.print(hp_text, bar_x + (bar_width - hp_width) / 2, bar_y + 2)
end

function enemies_module.draw()
    enemies_module.draw_hearts() -- Desenha os corações no chão
    
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
    hearts = {} -- Limpa corações ao resetar
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

return enemies_module