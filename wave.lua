local enemies_module = require("enemies")
local Waves = {}

Waves.current_wave = 1
Waves.timer = 0
Waves.wave_delay = 3 -- segundos entre waves
Waves.waiting_next = false -- Indica que os inimigos morreram e estamos esperando recompensas
Waves.boss_alive = false
Waves.score = 0
Waves.active = false
Waves.infinito = false
Waves.wave_final = 16 -- <<< OBJETIVO DE VITÓRIA DEFINIDO AQUI

-- Tipos possíveis de inimigos normais
local enemy_types = {
    "perseguidor",
    "atirador",
    "circulador",
    "bomb",
    "arma",
    "divisor",
    "teleportador",
    "horizontal",
    "paladino",
    "invocador",
}

-- Tipos possíveis de bosses (escolhidos a cada 8 waves)
local boss_types = {
    "boss",
    "boss2",
    "boss3",
    "boss4",
    "boss5"
}

-- Inicia o sistema de waves
function Waves.start()
    Waves.infinito = false
    Waves.current_wave = 1
    Waves.score = 0
    Waves.waiting_next = false
    Waves.boss_alive = false
    Waves.active = true
    enemies_module.reset()
    Waves.spawn_wave() -- Spawna a primeira onda
end

-- Ativa o modo infinito
function Waves.enable_infinite_mode()
    Waves.infinito = true
    print("🔄 MODO INFINITO ATIVADO! As waves nunca acabarão.")
end

-- ATUALIZAÇÃO PRINCIPAL DO SISTEMA
function Waves.update(dt, player)
    if not Waves.active then return end
    
    local enemies = enemies_module.get_all()
    local num_enemies = #enemies

    -- Se não há inimigos vivos e não estamos esperando a próxima
    if num_enemies == 0 and not Waves.waiting_next then
        Waves.waiting_next = true
        Waves.timer = 0

        if player and player.onWaveEnd then player:onWaveEnd() end

        print("Todos inimigos mortos! Esperando recompensas.")
        return -- Apenas avisa que terminou, main.lua decide o que fazer
    end

    -- A lógica de avançar a onda foi movida para Waves.next_wave()
end

-- ESTA É A NOVA FUNÇÃO QUE MAIN.LUA VAI CHAMAR
function Waves.next_wave(player)
    if not Waves.active then return end
    
    -- Se estamos em modo infinito ou ainda não chegamos na final
    if Waves.infinito or Waves.current_wave < Waves.wave_final then
        Waves.current_wave = Waves.current_wave + 1
        Waves.waiting_next = false
        player.x = 128*2
        player.y = 128
        
        --- Lógica para determinar se a wave atual é de um chefe ---
        local is_boss_wave = false
        if game_mode == 4 then -- Modo "Apenas Chefes"
            is_boss_wave = true
            Waves.wave_final=16
        elseif game_mode== 6 then
            is_boss_wave = (Waves.current_wave % 8 == 0)
            Waves.wave_final=64
        elseif game_mode == 3 then -- Modo "Difícil"
            is_boss_wave = (Waves.current_wave % 4 == 0)
            Waves.wave_final=16
        elseif game_mode == 2 then
            is_boss_wave = (Waves.current_wave % 8 == 0)
            Waves.wave_final=16
        elseif game_mode == 5 then
            is_boss_wave = (Waves.current_wave % 8 == 0)
            Waves.wave_final=32
        else
            Waves.wave_final=16
        end -- Modo "Fácil" (game_mode == 1) nunca tem chefes

        if is_boss_wave then
            Waves.spawn_boss()
        else
            Waves.spawn_wave()
        end
    else
        -- Se chegou aqui, é porque Waves.current_wave >= Waves.wave_final
        -- main.lua já deve ter mudado o estado para "final"
        Waves.active = false
        print("Ondas finalizadas.")
    end
end


-- Spawna uma wave normal
function Waves.spawn_wave()
    local is_boss_wave = false
    if game_mode == 4 then -- Modo "Apenas Chefes"
        is_boss_wave = true
        Waves.wave_final=16
    elseif game_mode== 6 then
        is_boss_wave = (Waves.current_wave % 8 == 0)
        Waves.wave_final=64
    elseif game_mode == 3 then -- Modo "Difícil"
        is_boss_wave = (Waves.current_wave % 4 == 0)
        Waves.wave_final=16
    elseif game_mode == 2 then
        is_boss_wave = (Waves.current_wave % 8 == 0)
        Waves.wave_final=16
    elseif game_mode == 5 then
        is_boss_wave = (Waves.current_wave % 8 == 0)
        Waves.wave_final=32
    else
        Waves.wave_final=16
    end -- Modo "Fácil" (game_mode == 1) nunca tem chefes
    -- No modo infinito, a dificuldade aumenta infinitamente
    local quantidade
    if Waves.infinito then
        -- Escala exponencial suave no modo infinito
        quantidade = math.floor(1 + Waves.current_wave * 1.5 + (Waves.current_wave / 10) ^ 1.5)
    else
        quantidade = math.floor(1 + Waves.current_wave * 1.25)
    end
    
    print("🌊 Wave " .. Waves.current_wave .. " começou! Inimigos: " .. quantidade)

    local available_enemies = {}
    
    -- Determina quais inimigos podem aparecer baseado no modo de jogo
    if game_mode == 1 then -- Modo Fácil
        available_enemies = {"perseguidor", "divisor","horizontal"}
    else -- Para todos os outros modos (Normal, Difícil, Loucura)
        available_enemies = enemy_types
    end

   --[[ -- Lógica de Spawn
    if game_mode == 5 then -- Modo Loucura (todos os inimigos da wave são iguais)
        local tipo_da_onda = available_enemies[math.random(#available_enemies)]
        print("Onda da Loucura! Tipo: " .. tipo_da_onda)
        for i = 1, quantidade do
            local x = math.random(8, 504)
            local y = math.random(24, 32)
            enemies_module.spawn_enemy(tipo_da_onda, x, y, Waves)
        end
    --]]
    -- Lógica para os outros modos (Fácil, Normal, Difícil)
    for i = 1, quantidade do
        local tipo = available_enemies[math.random(#available_enemies)]
        local x = math.random(8, 504)
        local y = math.random(24, 32)
        enemies_module.spawn_enemy(tipo, x, y, Waves)
    end
end

-- Spawna um boss aleatório
function Waves.spawn_boss()
    local boss = boss_types[math.random(#boss_types)]
    print("⚔️ Boss chegou! Tipo: " .. boss)
    Waves.boss_alive = true
    
    -- No modo infinito, pode spawnar múltiplos bosses
    if Waves.infinito and Waves.current_wave > 20 then
        local num_bosses = math.min(3, math.floor(Waves.current_wave / 20))
        print("🔥 MODO INFINITO: Spawnando " .. num_bosses .. " bosses!")
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

-- Deve ser chamado quando o boss morrer
function Waves.boss_defeated()
    Waves.boss_alive = false
end

-- Retorna informações do modo atual
function Waves.get_mode_info()
    if Waves.infinito then
        return "INFINITO", "∞"
    else
        return "NORMAL", Waves.wave_final
    end
end

return Waves