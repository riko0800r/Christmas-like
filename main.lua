-- =============================================================
--                        Arquivo Principal (main.lua)
-- =============================================================

-- 1. CARREGAR MÓDULOS
-- -------------------------------------------------------------
local GameState = require('gamestate')
local Player = require('player')
local Rewards = require('rewards')
local Characters = require('characters')
local Utils = require('utils')
local Enemies = require("enemies")
local Waves = require("wave")
local Seed = require("seed")
local Part = require("part")
local Buttons = require("button")
local PartReward = require("part_rewards")
local Push = require('libs/push')
local Camera = require("camera")
local Transitions = require("Transitions")
local Lang = require('lang')
local Shaders=require("shaders")
local Save=require("save")

-- 2. VARIÁVEIS GLOIAIS DO JOGO
-- -------------------------------------------------------------
score = 0
best_run = 0
game_timer = 0
spawn_timer = 0
intro_timer = 120
game_mode = 0
player = nil
is_paused = false

Menu_Musica = love.audio.newSource("assets/Menu divertido.mp3","stream")
Luta_Musica = love.audio.newSource("assets/Lutando no natal.mp3","stream")
Shop_Musica = love.audio.newSource("assets/Lojinha.mp3","stream")

Musica_Shop_Antiga = love.audio.newSource("assets/antigo/musica_1_OST.wav","stream")
Musica_Menu_Antiga = love.audio.newSource("assets/antigo/musica_2_OST.wav","stream")
Musica_Luta_Antiga = love.audio.newSource("assets/antigo/musica_3_OST.wav","stream")

SFX_Morte=love.audio.newSource("assets/morte.wav","static")
SFX_select=love.audio.newSource("assets/menu.wav","static")

local seed_input = ""
local entering_seed = false

-- Menus agora são funções ou chaves para pegar do Lang
local menus = {
    difficulty = {
        "diff_easy",
        "diff_normal",
        "diff_hard",
        "diff_boss",
        "diff_insane",
        "diff_impossible",
    },
    end_game = {"end_opt_infinite", "end_opt_finish"}
}

local background_layers = {
    {image = nil, x = 0, y = 0, speed = 0.15, path = "assets/Mapa4.png"},
    {image = nil, x = 0, y = 0, speed = 0.10, path = "assets/Mapa3.png"},
    {image = nil, x = 0, y = 0, speed = 0.25, path = "assets/Mapa2.png"},
    {image = nil, x = 0, y = 0, speed = 0.45, path = "assets/Mapa.png"},
}

local touch_controls = {
    joystick_active = false,
    joystick_id = nil,
    joystick_center = { x = 0, y = 0 },
    joystick_pos = { x = 0, y = 0 },
    joystick_radius = 60,
    action_button = { x = 0, y = 0, radius = 0 }
}

Debug = {
    active = false,          -- Se o menu debug está aberto
    show_menu = false,       -- Se deve desenhar o painel
    current_tab = "hitbox",  -- Aba atual: 'info' ou 'hitbox'
    
    -- Opções (Flags)
    options = {
        show_player_rect = false,
        show_enemy_rect = false,
        show_item_rect = false,
        infinite_hp = false
    }
}

local codigo_debug = { "up", "up", "down", "down", "left", "right", "left", "right", "b", "a" }
local key_buffer = {}

local function draw_checkbox(text, value, x, y)
    local w, h = 12, 12
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("line", x, y, w, h)
    if value then
        love.graphics.setColor(0, 1, 0, 1)
        love.graphics.rectangle("fill", x + 2, y + 2, w - 4, h - 4)
    end
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(text, x + 18, y - 2)
    return x, y, 200, 16 -- Retorna a área clicável (x, y, w, h)
end

-- Adicione "menu_options" na lista de estados de menu
-- main.lua
local menu_states = { "menu", "menu_difficulty", "menu_options", "final", "character_select", "rewards", "over", "tutorial", "intro", "Quem fez?", "victory"} -- Adicionado "victory"
-- =============== Funções Auxiliares =========================

function updateAudioVolume()
    -- Agora dividimos por 100 para obter o float 0.0 a 1.0
    local m_vol = (GameConfig.music_vol / 100) 
    local s_vol = (GameConfig.sfx_vol / 100)
    
    if Musica_Atual then Musica_Atual:setVolume(m_vol) end
    Menu_Musica:setVolume(m_vol)
    Luta_Musica:setVolume(m_vol)
    Shop_Musica:setVolume(m_vol)
    
    Musica_Menu_Antiga:setVolume(m_vol*1.5)
    Musica_Luta_Antiga:setVolume(m_vol*1.5)
    Musica_Shop_Antiga:setVolume(m_vol*1.5)

    SFX_Morte:setVolume(s_vol)
    SFX_select:setVolume(s_vol)
    SFX_Enemy_Morte:setVolume(s_vol*0.25)
end

function toggleFullscreen()
    GameConfig.fullscreen = not GameConfig.fullscreen
    love.window.setFullscreen(GameConfig.fullscreen)
end

-- =============================================================
--         FUNÇÕES DE CONTROLE DE ESTADO E BOTÕES
-- =============================================================

function setupButtonsForState(state)
    Buttons:clear()
    if state=="intro" then
        Buttons:newButton((512/2)-90, 256-64, 194, 24, Lang.text("intro_skip"), function()
            SFX_select:play()
            _G.switchState("menu")
        end,
        function ()
            
        end)
    elseif state == "menu" then
        local start_y = 65 -- Subi um pouco para caber mais botões
        
        local record_wave = Save.data.records.best_wave or 0
        local record_time = Save.data.records.best_time or 0
        
        local time_str = string.format("%02d:%02d", math.floor(record_time/60), math.floor(record_time%60))
        local txt_record = (record_wave > 0) 
            and Lang.text("menu_record", record_wave, time_str)
            or Lang.text("menu_no_record")
            
        -- Small label at top
        Buttons:newLabel(132 - (Font:getWidth(txt_record)/2), 256-8, txt_record, Font, nil, {1, 0.8, 0, 1})

        -- === CONTINUE BUTTON ===
        if Save.hasRun() then
            local wave_num = Save.data.run.wave_info.current
            Buttons:newButton((512/2)-90, start_y - 30, 194, 24, Lang.text("menu_continue_run", wave_num), function()
                SFX_select:play()
                if Save.loadRun() then
                    _G.switchState("play")
                    -- Restart music
                    if Musica_Atual then Musica_Atual:stop() end
                    if GameConfig.musica_antiga==false then
                        Musica_Atual = Luta_Musica
                    else
                        Musica_Atual = Musica_Luta_Antiga
                    end
                    Musica_Atual:play()
                    Musica_Atual:setVolume(0.25)
                    Musica_Atual:setLooping(true)
                else
                    print("Error loading run")
                end
            end,
            function() end,
            Jogar_ICON) -- You can use a different icon if you have one
        end

        Buttons:newButton((512/2)-90, start_y, 194, 24, Lang.text("menu_play"), function()
            SFX_select:play()
            -- Important: If starting new game, delete old run? 
            -- Usually yes, or warn. For now, we overwrite on next save.
            Save.deleteRun() 
            resetGame()
            _G.switchState("menu_difficulty")
        end,
        function () end, Jogar_ICON)
        
        Buttons:newButton((512/2)-90, start_y + 30, 194, 24, Lang.text("menu_tutorial"), function()
            SFX_select:play()
            _G.switchState("tutorial")
        end,
        function ()
            
        end,
        Tutorial_ICON)

        -- NOVO BOTÃO DE CONFIGURAÇÕES
        Buttons:newButton((512/2)-90, start_y + 60, 194, 24, Lang.text("menu_options"), function()
            SFX_select:play()
            _G.switchState("menu_options")
        end,
        function ()
            
        end,
        Config_ICON)

        Buttons:newButton((512/2)-90, start_y + 90, 194, 24, Lang.text("intro_review"), function()
            SFX_select:play()
            _G.switchState("intro")
        end,
        function ()
            
        end,
        Voltar_ICON)
        
        Buttons:newButton((512/2)-90, start_y + 120, 194, 24, Lang.text("menu_quem_fez"), function()
            _G.switchState("Quem fez?")
        end,
        function ()
            
        end)
        Buttons:newButton((512/2)-90, start_y + 150, 194, 24, Lang.text("menu_exit"), function()
            love.event.quit()
        end,
        function ()
            
        end,
        Exit_ICON)

    elseif state == "menu_options" then
        local start_y = 40
        local label_x = 100 -- Posição do Texto
        local slider_x = 220 -- Posição do Slider
        
        -- 1. Idioma (Botão normal)
         Buttons:newButton(192, 40, 160, 24, Lang.text("opt_lang", string.upper(Lang.current)), function()
            SFX_select:play()
            local novo = (Lang.current == "pt-br") and "en" or "pt-br"
            Lang.setLanguage(novo)
            setupButtonsForState("menu_options")
            Save.saveSettings() -- UPDATED
        end, function() end, Terra_ICON)

        -- 2. Volume Música (SLIDER)
        Buttons:newLabel(label_x, start_y + 35, Lang.text("opt_music", ""), Font, nil, {0,0,0,1})
        
        -- AGORA DIVIDE E MULTIPLICA POR 100
        Buttons:newSlider(slider_x, start_y + 35, 120, 16, GameConfig.music_vol / 100, function(val)
            -- Multiplica por 100 e arredonda. Ex: 0.35 vira 35.
            GameConfig.music_vol = math.floor(val * 100)
            updateAudioVolume()
            Save.saveSettings() -- UPDATED
        end)

        -- 3. Volume SFX (SLIDER)
        Buttons:newLabel(label_x, start_y + 65, Lang.text("opt_sfx", ""), Font, nil, {0,0,0,1})
        
        -- AGORA DIVIDE E MULTIPLICA POR 100
        Buttons:newSlider(slider_x, start_y + 65, 120, 16, GameConfig.sfx_vol / 100, function(val)
            GameConfig.sfx_vol = math.floor(val * 100)
            if math.random() < 0.25 then SFX_select:play() end
            updateAudioVolume()
            Save.saveSettings() -- UPDATED
        end)
        -- 4. Timer Speedrun (Botão Toggle)
        local state_timer = GameConfig.show_timer and Lang.text("state_on") or Lang.text("state_off")
        Buttons:newButton(192, start_y + 95, 194+32, 24, Lang.text("opt_timer", state_timer), function()
            SFX_select:play()
            GameConfig.show_timer = not GameConfig.show_timer
            setupButtonsForState("menu_options")
            Save.saveSettings() -- UPDATED
        end,
        function ()
            
        end,
        Clock_ICON)

        -- 5. Fullscreen (Botão Toggle)
        local state_full = GameConfig.fullscreen and Lang.text("state_on") or Lang.text("state_off")
        Buttons:newButton(192, start_y + 125, 194+32, 24, Lang.text("opt_fullscreen", state_full), function()
            SFX_select:play()
            toggleFullscreen()
            setupButtonsForState("menu_options")
        end,
        function ()
            
        end,
        FullScreen_ICON)

        -- No setupButtonsForState("menu_options"), altere o botão de música:
        local music_label = GameConfig.musica_antiga and Lang.text("state_on") or Lang.text("state_off")
        Buttons:newButton(192, start_y + 155, 194+32, 24, Lang.text("opt_old_music", music_label), function()
            SFX_select:play()
            GameConfig.musica_antiga = not GameConfig.musica_antiga
            
            -- Reinicia a música atual com a nova preferência
            if Musica_Atual then
                local pos = Musica_Atual:tell()
                Musica_Atual:stop()
                -- Lógica simples: se estava tocando luta, toca a versão de luta escolhida
                if GameConfig.musica_antiga == false then
                    Musica_Atual = Menu_Musica
                else
                    Musica_Atual = Musica_Menu_Antiga
                end
                Musica_Atual:play()
                Musica_Atual:seek(pos) -- Tenta manter a sincronia
                Musica_Atual:setLooping(true)
            end
            Save.saveSettings() -- UPDATED
            setupButtonsForState("menu_options")
            end,
            function ()
                
            end,
            Musica_ICON)

        -- Voltar
        Buttons:newButton(192, start_y + 190, 194, 24, Lang.text("menu_back"), function()
            SFX_select:play()
            _G.switchState("menu")
        end,
        function ()
            
        end,
        Voltar_ICON)
    elseif state == "over" then
        Save.deleteRun()
        Save.checkRecord(Waves.current_wave, game_timer)
        
        Buttons:newButton(192, 256-32, 128, 24, Lang.text("menu_back"), function()
            SFX_select:play()
            resetGame()
            _G.switchState("menu")
        end)
    elseif state == "tutorial" then
        Buttons:newButton(192, 180, 128, 24, Lang.text("menu_back"), function()
            SFX_select:play()
            _G.switchState("menu")
        end)
    elseif state == "menu_difficulty" then
        for i, option_key in ipairs(menus.difficulty) do
            local btn = Buttons:newButton((512/2)-145, 60 + (i * 28), 256+24, 24, Lang.text(option_key), function()
                SFX_select:play()
                game_mode = i
                _G.switchState("character_select")
                Waves.start()
            end,
            function ()
                
            end,
            ICONS_DIFF[i])
        end
    elseif state == "final" then
        Buttons:newButton(192, 100, 128, 24, Lang.text(menus.end_game[1]), function()
            Waves.enable_infinite_mode()
            Waves.active = true
            SFX_select:play()
            _G.switchState("play")
            if Musica_Atual then Musica_Atual:stop() end
            if GameConfig.musica_antiga==false then
                Musica_Atual = Luta_Musica
            else
                Musica_Atual = Musica_Luta_Antiga
            end
            Musica_Atual:play()
            Musica_Atual:setVolume(0.25)
            Musica_Atual:setLooping(true)
        end)

        Buttons:newButton(192, 130, 128, 24, Lang.text(menus.end_game[2]), function()
            SFX_select:play()
            -- NÃO reseta o jogo aqui, apenas muda para a tela de vitória
            -- para podermos ler os status do player
            _G.switchState("victory")
        end)
    elseif state == "character_select" then
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

            Buttons:newButton(x, y, 128, 22, char.get_name(), function()
                Characters.selected_index = i
                Characters.keypressed("x")
                game_timer=0
            end,
            function()
                Characters.selected_index = i
            end)
        end
    elseif state == "victory" then
        Save.checkRecord(Waves.current_wave, game_timer)
        Buttons:newButton(192, 256-32, 128, 24, Lang.text("menu_back"), function()
            SFX_select:play()
            Save.deleteRun() -- Victory -> Back to menu = Run ends
            resetGame() 
            _G.switchState("menu")
        end)
    elseif state == "rewards" then
        for i, reward in ipairs(Rewards.current_rewards) do
            -- Usa reward.get_name()
            Buttons:newButton(24, 40 + (i - 1) * 20, 8*22, 16, reward.get_name(),
            function()
                Rewards.selected_index = i
                Rewards:selectReward()
            end,
            function()
                Rewards.selected_index = i
            end,reward.icon)
        end
    elseif state=="Quem fez?" then
        Buttons:newButton(64, 40, 8*40, 24, Lang.text("riko"), 
            function ()
                love.system.openURL("https://www.youtube.com/@riko699") 
            end,
            function ()
                
            end,
            Icon_Riko)
            Buttons:newButton(64, 40+30, 8*40, 24, Lang.text("magma"), 
            function ()
                love.system.openURL("https://www.youtube.com/channel/UCRIo4iez4lHFVtbn5fKCnJA") 
            end,function ()
                
            end,
            Musica_ICON)
            Buttons:newButton(64, 40+60, 8*40, 24, Lang.text("menu_back"), function()
                SFX_select:play()
                _G.switchState("menu")
            end,
            function ()
                
            end,
            Voltar_ICON)
     end
end

function _G.switchState(newState, ...)
    Transitions.start(newState, ...)
end

function _G.performSwitch(newState, ...)
    GameState.switch(newState, ...)
        
    if newState == "play" then
        if Waves.waiting_next then 
            Waves.next_wave(player)
        end
        if Musica_Atual then
            local pos = Musica_Atual:tell()
            Musica_Atual:stop()
            -- Lógica simples: se estava tocando luta, toca a versão de luta escolhida
            if GameConfig.musica_antiga == false then
                Musica_Atual = Luta_Musica
            else
                Musica_Atual = Musica_Luta_Antiga
            end
            Musica_Atual:play()
            Musica_Atual:seek(pos) -- Tenta manter a sincronia
            Musica_Atual:setLooping(true)
        end
        Musica_Atual:play()
        Musica_Atual:setVolume(0.25)
        Musica_Atual:setLooping(true)
    elseif newState == "rewards" then
        Rewards.generate(3)
    end
    
    setupButtonsForState(newState)
end

function resetGame()
    print("Reiniciando o jogo...")
    score = 0
    game_timer = 0
    spawn_timer = 0
    Waves.infinito = false
    player = Player.new()
    Enemies.reset()
    Waves.start()
    if Musica_Atual then
        local pos = Musica_Atual:tell()
        Musica_Atual:stop()
        -- Lógica simples: se estava tocando luta, toca a versão de luta escolhida
        if GameConfig.musica_antiga == false then
            Musica_Atual = Menu_Musica
        else
            Musica_Atual = Musica_Menu_Antiga
        end
        Musica_Atual:play()
        Musica_Atual:seek(pos) -- Tenta manter a sincronia
        Musica_Atual:setLooping(true)
    end
end

function updateBackgrounds(dt)
    for _, layer in ipairs(background_layers) do
        layer.x = (layer.x - layer.speed) % layer.image:getWidth()
    end
end

function love.load()
    GameConfig = {
        music_vol = 12,
        sfx_vol = 20,
        show_timer   = true,
        fullscreen   = false,
        musica_antiga= false,
    }
    Save.load()
    Seed.new_random()
    love.graphics.setDefaultFilter("nearest", "nearest")
    
    Font = love.graphics.newFont("assets/font.ttf", 8)
    love.graphics.setFont(Font)

    Enemies.load_assets()
    
    player = Player.new()
    Characters.load(player)
    -- Lógica simples: se estava tocando luta, toca a versão de luta escolhida
    if GameConfig.musica_antiga == false then
        Musica_Atual = Menu_Musica
    else
        Musica_Atual = Musica_Menu_Antiga
    end
    Musica_Atual:play()
    Musica_Atual:setLooping(true)

    Config_ICON=love.graphics.newImage("assets/ConfigICON.png")
    Jogar_ICON =love.graphics.newImage("assets/JogarICON.png")
    Exit_ICON=love.graphics.newImage("assets/SairICON.png")
    Tutorial_ICON=love.graphics.newImage("assets/TutorialICON.png")
    Voltar_ICON=love.graphics.newImage("assets/VoltarICON.png")
    Terra_ICON=love.graphics.newImage("assets/Terra.png")
    Musica_ICON=love.graphics.newImage("assets/MusicaICON.png")
    Clock_ICON=love.graphics.newImage("assets/Clock.png")
    FullScreen_ICON=love.graphics.newImage("assets/FullScreenICON.png")
    
    -- Icones Específicos para Game Over (se não estiverem no Rewards)
    Icon_Neve = love.graphics.newImage("assets/neve.png")
    Icon_Pedra = love.graphics.newImage("assets/pedra.png")
    Icon_Veneno = love.graphics.newImage("assets/VenenoMortal.png")
    Icon_Fogo = love.graphics.newImage("assets/FogoICON.png")
    Icon_Gelo = love.graphics.newImage("assets/GeloICON.png")
    Icon_Bumerang = love.graphics.newImage("assets/BumerangICON.png")
    Icon_Guirlanda = love.graphics.newImage("assets/GuirlandaICON.png")

    Icon_Riko=love.graphics.newImage("assets/sprite5.png")

    ICONS_DIFF={
        [1]=love.graphics.newImage("assets/facilICON.png"),
        [2]=love.graphics.newImage("assets/NormalICON.png"),
        [3]=love.graphics.newImage("assets/DificilICON.png"),
        [4]=love.graphics.newImage("assets/BossICON.png"),
        [5]=love.graphics.newImage("assets/LoucuraICON.png"),
        [6]=love.graphics.newImage("assets/ImpossivelICON.png"),
    }

    for _, layer in ipairs(background_layers) do
        layer.image = love.graphics.newImage(layer.path)
    end
    
    love.window.setTitle("Christmas-like")
    
    SFX_select:setVolume(0.45)
    SFX_select:setPitch(1.15)

    local joysticks = love.joystick.getJoysticks()
    gamepad = joysticks[1]

    local screenWidth, screenHeight = love.window.getDesktopDimensions()
    Push:setupScreen(128*4, 128*2, screenWidth*0.9, screenHeight*0.9, {fullscreen = false, resizable = true, pixelperfect=false})
    
    function setupTouchControls(w, h)
        touch_controls.action_button.x = w - 80
        touch_controls.action_button.y = h - 80
    end
    setupTouchControls(Push:getDimensions())
    
    _G.switchState("intro")
end

function love.update(dt)
    if GameState.current == "play" and is_paused then
        return
    end
    updateBackgrounds(dt)
    Camera:update(dt)
    Part.update(dt)
    PartReward.update(dt)
    Transitions.update(dt)
    updateAudioVolume()
    Shaders:update(dt)

    local is_menu = false
    for _, state in ipairs(menu_states) do
        if GameState.current == state then is_menu = true; break; end
    end
    if is_menu then
        Buttons:update(dt)
    end
    
    if gamepad and player then
        local stick_x = gamepad:getGamepadAxis("leftx")
        local stick_y = gamepad:getGamepadAxis('lefty')
        if math.abs(stick_x) < 0.2 then stick_x = 0 end
        if math.abs(stick_y) < 0.2 then stick_y = 0 end
        player.joystick = true
        player.dx = stick_x * player.speed
        player.dy = stick_y * player.speed
        if gamepad:isGamepadDown('dpleft') then player.dx = -1 * player.speed end
        if gamepad:isGamepadDown('dpright') then player.dx = 1 * player.speed end
        if gamepad:isGamepadDown('dpup') then player.dy = -1 * player.speed end
        if gamepad:isGamepadDown('dpdown') then player.dy = 1 * player.speed end
    end
    
    if GameState.current == "intro" then
        intro_timer = intro_timer - dt
        if intro_timer <= 0 then
            _G.switchState("menu")
        end
    elseif GameState.current == "play" then
        game_timer = game_timer + dt
        if touch_controls.joystick_active then
            local jc, jp = touch_controls.joystick_center, touch_controls.joystick_pos
            local dx_vec, dy_vec = jp.x - jc.x, jp.y - jc.y
            local dist = math.sqrt(dx_vec^2 + dy_vec^2)
            if dist > 0 then
                player.dx = (dx_vec / dist) * player.speed
                player.dy = (dy_vec / dist) * player.speed
            else
                player.dx, player.dy = 0, 0
            end
        end

        player:update(dt, Enemies.get_all(), Waves.wave_delay)
        Enemies.update(dt, player)
        Waves.update(dt, player) 
        
        if #Enemies.get_all() == 0 and Waves.waiting_next == true then
            if not Waves.infinito and Waves.current_wave >= Waves.wave_final then
                Waves.active = false
                _G.switchState("final")
                Musica_Atual:stop()
            else
                if Musica_Atual then
                    local pos = Musica_Atual:tell()
                    Musica_Atual:stop()
                    -- Lógica simples: se estava tocando luta, toca a versão de luta escolhida
                    if GameConfig.musica_antiga == false then
                        Musica_Atual = Shop_Musica
                    else
                        Musica_Atual = Musica_Shop_Antiga
                    end
                    Musica_Atual:play()
                    Musica_Atual:seek(pos) -- Tenta manter a sincronia
                    Musica_Atual:setLooping(true)
                end
                _G.switchState("rewards")
            end
        end

        if player.lifes <= 0 then
            SFX_Morte:play()
            Musica_Atual:stop()
            Save.deleteRun() -- Morreu: apaga o save
            Save.checkRecord(Waves.current_wave, game_timer) -- Salva recorde
            _G.switchState("over")
        end
    end
end

local function drawWorld()
    love.graphics.clear(41/255, 173/255, 255/255)

    local function draw_map_placeholder()
        Utils.setColor(7)
        for _, layer in ipairs(background_layers) do
            if layer.image then
                local img = layer.image
                local w = img:getWidth()
                local screenWidth = 128 * 4
                for i = -1, math.ceil(screenWidth / w) + 1 do
                    love.graphics.draw(img, layer.x + i * w, layer.y)
                end
            end
        end
    end

    function drawTouchControls()
        if GameState.current ~= "play" then return end
        if touch_controls.joystick_active then
            love.graphics.setColor(1, 1, 1, 0.3)
            love.graphics.circle("fill", touch_controls.joystick_center.x, touch_controls.joystick_center.y, touch_controls.joystick_radius)
            love.graphics.setColor(1, 1, 1, 0.5)
            love.graphics.circle("fill", touch_controls.joystick_pos.x, touch_controls.joystick_pos.y, touch_controls.joystick_radius / 2)
        end
    end
    
    if GameState.current == "intro" then
        Utils.setColor(2)
        love.graphics.rectangle('fill', 0, 0, 128*4, 128*2)
        Utils.setColor(7)
        Utils.centerText(Lang.text("intro_1"), 8)
        Utils.centerText(Lang.text("intro_2"), 24)
        Utils.centerText(Lang.text("intro_3"), 40)
        Utils.centerText(Lang.text("intro_4"), 56)
        Utils.setColor(10)
        Buttons:drawAll()
    elseif GameState.current == "menu" then
        draw_map_placeholder()
        Utils.setColor(0)
        Utils.centerText(Lang.text("title_main"), 16)
        Buttons:drawAll()
    elseif GameState.current == "menu_difficulty" then
        draw_map_placeholder()
        Utils.setColor(0)
        Utils.centerText(Lang.text("diff_select"), 32)
        Buttons:drawAll()
    elseif GameState.current == "character_select" then
        draw_map_placeholder()
        Characters.draw()
        Buttons:drawAll()
    elseif GameState.current == "play" then
        draw_map_placeholder()
        Camera:apply()
        player:draw()
        Enemies.draw()
        Buttons:drawAll()
        Utils.setColor(0)
        
        -- MOSTRA A ONDA ATUAL
        local final_wave_text = Waves.infinito and Lang.text("wave_infinite") or Waves.wave_final
        love.graphics.print(Lang.text("wave_display", Waves.current_wave, final_wave_text), 4, 32)
        
        -- === NOVO: TIMER DE SPEEDRUN ===
        if GameConfig.show_timer then
            Utils.setColor(0)
            local minutes = math.floor(game_timer / 60)
            local seconds = math.floor(game_timer % 60)
            local millis = math.floor((game_timer * 100) % 100)
            local time_str = string.format("%02d:%02d.%02d", minutes, seconds, millis)
            
            love.graphics.print("RUN: " .. time_str, 4, 44)
        end

        Utils.setColor(8)
        love.graphics.print(Lang.text("reset_hint"), 4, 0)
        
        -- === BARRA DE VIDA ===
        local ratio = player.lifes / player.max_life
        local bar_w = 80
        local bar_h = 8
        local x = 128*3
        local y = 4

        Utils.setColor(0)
        love.graphics.rectangle("fill", x-1, y-1, bar_w+2, bar_h+2)
        Utils.setColor(8)
        love.graphics.rectangle("fill", x, y, bar_w * ratio, bar_h)
        Camera:clear()

        -- 2. BLOCO DO PAUSE (Coloque isso logo antes de fechar o state "play")
        if is_paused then
            -- Pega largura e altura virtual do jogo
            local gw, gh = Push:getDimensions()

            -- Desenha retângulo preto com 50% de opacidade (0.5 no alpha)
            love.graphics.setColor(0, 0, 0, 0.5)
            love.graphics.rectangle("fill", 0, 0, gw, gh)

            -- Desenha o texto de PAUSE
            local texto = Lang.text("pause_title")
            local font = love.graphics.getFont()
            local textW = font:getWidth(texto)
            local textH = font:getHeight()

            -- Cor branca vibrante (usando seu Utils ou love.graphics direto)
            -- Se usar seu Utils.setColor(7) funciona, ou manual:
            love.graphics.setColor(1, 1, 1, 1) 
            
            -- Centraliza na tela
            love.graphics.print(texto, (gw - textW) / 2, (gh - textH) / 2)
            
            -- Texto menor embaixo
            love.graphics.setColor(1, 1, 1, 0.7)
            local sub = Lang.text("pause_sub")
            local subW = font:getWidth(sub)
            love.graphics.print(sub, (gw - subW) / 2, (gh - textH) / 2 + 20)
        end
    elseif GameState.current == "rewards" then
        Rewards.draw()
    elseif GameState.current == "victory" then
        -- 1. Fundo Parallax (O mapa)
        draw_map_placeholder()

        -- 2. Camada Azul Claro Translúcida (Para dar destaque)
        love.graphics.setColor(41/255, 173/255, 255/255, 0.4) -- Azul claro com transparência
        love.graphics.rectangle('fill', 0, 0, 128*4, 128*2)

        -- 3. Painel de Status (Cópia adaptada do Game Over)
        local pW, pH = 350, 150
        local pX = (512 - pW) / 2
        local pY = 40
        
        -- Fundo do Painel (Escuro levemente transparente)
        love.graphics.setColor(0.05, 0.05, 0.1, 0.9)
        love.graphics.rectangle('fill', pX, pY, pW, pH, 4, 4)
        
        -- Borda do Painel (Verde/Amarelo para vitória - Cor 11 da paleta pico-8 ou custom)
        Utils.setColor(11) -- Verde
        love.graphics.rectangle('line', pX, pY, pW, pH, 4, 4)

        -- Título "VOCÊ VENCEU"
        Utils.setColor(7) -- Branco
        love.graphics.setFont(love.graphics.newFont("assets/font.ttf", 16)) -- Fonte maior se possível, ou use padrão
        love.graphics.printf(Lang.text("win_title"), pX, pY + 10, pW, "center")
        love.graphics.setFont(Font) -- Volta fonte normal
        
        -- Linha separadora
        Utils.setColor(11)
        love.graphics.line(pX + 20, pY + 35, pX + pW - 20, pY + 35)

        -- === ESTATÍSTICAS (Igual ao Game Over) ===
        local stats = (player and player.stats) and player.stats or {weapons = {}, total_damage = 0}
        local run_seconds = math.max(0.1, game_timer)
        
        local colWidth = (pW / 2) - 20
        local leftX = pX + 10
        local rightX = pX + (pW / 2) + 10
        local startY = pY + 45

        -- COLUNA ESQUERDA: ARMAS
        Utils.setColor(10) -- Amarelo para títulos
        love.graphics.print(Lang.text("stat_weapons"), leftX, startY - 12)
        
        local sorted = {}
        for name, dmg in pairs(stats.weapons) do table.insert(sorted, {name = name, dmg = dmg}) end
        table.sort(sorted, function(a,b) return a.dmg > b.dmg end)

        for i, it in ipairs(sorted) do
            if i > 6 then break end
            
            local icon = Rewards.get_icon_by_name(it.name)
            -- Fallback manual (mesma lógica do main.lua original)
            if not icon then
                if it.name == "Bola de neve" then icon = Icon_Neve
                elseif it.name == "Bloco de gelo" then icon = Icon_Neve
                elseif it.name == "Pedras do ceu" or it.name == "Pedra do ceu" then icon = Icon_Pedra
                elseif it.name == "Veneno mortal" then icon = Icon_Veneno
                elseif it.name == "Fogo perigoso" then icon = Icon_Fogo
                elseif it.name == "Bumerangue" then icon = Icon_Bumerang
                elseif it.name == "Guirlanda" then icon = Icon_Guirlanda
                elseif it.name == "presente dourado" then icon = Rewards.get_icon_by_name("Anel de Lava")
                elseif it.name == "Pedras preciosas" then icon = Rewards.get_icon_by_name("Pedras Preciosas")
                end
            end

            Utils.setColor(7)
            local rowY = startY + (i-1)*18
            
            if icon then
                love.graphics.draw(icon, leftX, rowY - 2)
            else
                love.graphics.print(it.name:sub(1, 10), leftX, rowY)
            end
            
            Utils.setColor(9) -- Laranja/Amarelo para números de vitória
            love.graphics.printf(math.ceil(it.dmg), leftX, rowY, colWidth, "right")
        end

        -- COLUNA DIREITA: ELEMENTOS
        Utils.setColor(10)
        love.graphics.print(Lang.text("stat_effects"), rightX, startY - 12)
        
        local elemental = (player and player.stats_elemental) or {}
        local elements = {
            {id = "fogo", icon = Icon_Fogo, label = "Fogo"},
            {id = "gelo", icon = Icon_Gelo, label = "Gelo"},
            {id = "veneno", icon = Icon_Veneno, label = "Veneno"}
        }

        local eIdx = 0
        for _, el in ipairs(elements) do
            local data = elemental[el.id]
            if data and data.dano_total > 0 then
                eIdx = eIdx + 1
                local rowY = startY + (eIdx-1)*18
                
                Utils.setColor(7)
                love.graphics.draw(el.icon, rightX, rowY - 2)
                
                Utils.setColor(9)
                love.graphics.printf(math.ceil(data.dano_total), rightX, rowY, colWidth, "right")
            end
        end

        -- RODAPÉ
        Utils.setColor(12) -- Azul claro para rodapé
        local time_txt = Lang.text("stat_time", math.floor(run_seconds))
        local total_txt = Lang.text("stat_total", math.floor(stats.total_damage or 0))
        local total_str = time_txt .. "  |  " .. total_txt
        
        love.graphics.printf(total_str, pX, pY + pH - 18, pW, "center")
        
        Buttons:drawAll()
    elseif GameState.current == "tutorial" then
        Utils.setColor(2)
        love.graphics.rectangle('fill', 0, 0, 128*4, 128*2)
        Utils.setColor(7)
        Utils.centerText(Lang.text("tut_title"), 20)
        
        love.graphics.print(Lang.text("tut_controls"), 32, 45)
        love.graphics.print(Lang.text("tut_move"), 32, 65)
        love.graphics.print(Lang.text("tut_confirm"), 32, 80)
        
        Utils.setColor(10)
        love.graphics.print(Lang.text("tut_obj_title"), 32, 105)
        Utils.setColor(7)
        love.graphics.print(Lang.text("tut_obj_1"), 32, 125)
        love.graphics.print(Lang.text("tut_obj_2"), 32, 140)
        love.graphics.print(Lang.text("tut_obj_3"), 32, 155)
        
        Buttons:drawAll()
    elseif GameState.current =="Quem fez?" then
        draw_map_placeholder()
        Buttons:drawAll()
    elseif GameState.current == "over" then
        -- Escurece o fundo
        Utils.setColor(2)
        love.graphics.rectangle('fill', 0, 0, 128*4, 128*2)

        -- Configuração do Painel Central
        local pW, pH = 350, 150
        local pX = (512 - pW) / 2
        local pY = 40
        
        -- Fundo e Borda do Painel
        love.graphics.setColor(0.05, 0.05, 0.1, 0.95)
        love.graphics.rectangle('fill', pX, pY, pW, pH, 4, 4)
        Utils.setColor(8) -- Vermelho para derrota
        love.graphics.rectangle('line', pX, pY, pW, pH, 4, 4)

        -- Título
        Utils.setColor(7)
        love.graphics.printf(Lang.text("game_over_msg"):upper(), pX, pY + 10, pW, "center")
        love.graphics.line(pX + 20, pY + 25, pX + pW - 20, pY + 25)

        local stats = (player and player.stats) and player.stats or {weapons = {}, total_damage = 0}
        local run_seconds = math.max(0.1, game_timer)
        
        -- Definição de Colunas
        local colWidth = (pW / 2) - 20
        local leftX = pX + 10
        local rightX = pX + (pW / 2) + 10
        local startY = pY + 40

        -- --- COLUNA ESQUERDA: ARMAS (USANDO ÍCONES) ---
        Utils.setColor(10) -- Amarelo
        love.graphics.print(Lang.text("stat_weapons"), leftX, startY - 12)
        
        local sorted = {}
        for name, dmg in pairs(stats.weapons) do table.insert(sorted, {name = name, dmg = dmg}) end
        table.sort(sorted, function(a,b) return a.dmg > b.dmg end)

        for i, it in ipairs(sorted) do
            if i > 6 then break end
            
            -- Tenta obter ícone via Rewards ou Mapeamento Manual
            local icon = Rewards.get_icon_by_name(it.name)
            
            -- Fallback manual se não estiver no Rewards (devido a nomes internos diferentes em player.lua)
            if not icon then
                if it.name == "Bola de neve" then icon = Icon_Neve
                elseif it.name == "Bloco de gelo" then icon = Icon_Neve -- Reusa ou muda se tiver icone especifico
                elseif it.name == "Pedras do ceu" or it.name == "Pedra do ceu" then icon = Icon_Pedra
                elseif it.name == "Veneno mortal" then icon = Icon_Veneno
                elseif it.name == "Fogo perigoso" then icon = Icon_Fogo
                elseif it.name == "Bumerangue" then icon = Icon_Bumerang
                elseif it.name == "Guirlanda" then icon = Icon_Guirlanda
                elseif it.name == "presente dourado" then icon = Rewards.get_icon_by_name("Anel de Lava")
                elseif it.name == "Pedras preciosas" then icon = Rewards.get_icon_by_name("Pedras Preciosas")
                end
            end

            Utils.setColor(7)
            local rowY = startY + (i-1)*18 -- Espaçamento um pouco maior para ícones
            
            if icon then
                love.graphics.draw(icon, leftX, rowY - 2) -- Desenha ícone
            else
                love.graphics.print(it.name:sub(1, 10), leftX, rowY) -- Texto de fallback
            end
            
            Utils.setColor(13)
            love.graphics.printf(math.ceil(it.dmg), leftX, rowY, colWidth, "right")
        end

        -- --- COLUNA DIREITA: ELEMENTOS (USANDO ÍCONES) ---
        Utils.setColor(10)
        love.graphics.print(Lang.text("stat_effects"), rightX, startY - 12)
        
        local elemental = (player and player.stats_elemental) or {}
        local elements = {
            {id = "fogo", icon = Icon_Fogo, label = "Fogo"},
            {id = "gelo", icon = Rewards.get_icon_by_name("Imobilizador"), label = "Gelo"},
            {id = "veneno", icon = Icon_Veneno, label = "Veneno"}
        }

        local eIdx = 0
        for _, el in ipairs(elements) do
            local data = elemental[el.id]
            if data and data.dano_total > 0 then
                eIdx = eIdx + 1
                local rowY = startY + (eIdx-1)*18
                
                Utils.setColor(7) -- Branco para ícone
                love.graphics.draw(el.icon, rightX, rowY - 2)
                
                Utils.setColor(13)
                love.graphics.printf(math.ceil(data.dano_total), rightX, rowY, colWidth, "right")
            end
        end

        -- --- RODAPÉ: STATUS GERAIS ---
        Utils.setColor(13)
        local time_txt = Lang.text("stat_time", math.floor(run_seconds))
        local total_txt = Lang.text("stat_total", math.floor(stats.total_damage or 0))
        local total_str = time_txt .. "  |  " .. total_txt
        
        love.graphics.printf(total_str, pX, pY + pH - 18, pW, "center")
        
        Buttons:drawAll()
    elseif GameState.current == "final" then
        draw_map_placeholder()
        Utils.setColor(10)
        Utils.centerText(Lang.text("win_msg_1"), 24)
        Utils.centerText(Lang.text("win_msg_2"), 36)
        Buttons:drawAll()

    elseif GameState.current == "menu_options" then
        draw_map_placeholder()
        Utils.setColor(0)
        Utils.centerText(Lang.text("menu_options"), 20)
        Buttons:drawAll()
    end

    -- DESENHO DO MENU DEBUG
    if is_paused and Debug.show_menu then
        local gw, gh = Push:getDimensions()
        
        -- Fundo do painel
        love.graphics.setColor(0.1, 0.1, 0.1, 0.95)
        love.graphics.rectangle("fill", 20, 20, gw - 40, gh - 40)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("line", 20, 20, gw - 40, gh - 40)
        
        -- Título
        Utils.centerText("--- DEBUG MODE ---", 25)
        
        -- Abas (Simples botões de texto)
        if Debug.current_tab == "info" then love.graphics.setColor(0,1,0) else love.graphics.setColor(0.5,0.5,0.5) end
        love.graphics.print("[ INFO ]", 30, 45)
        
        if Debug.current_tab == "hitbox" then love.graphics.setColor(0,1,0) else love.graphics.setColor(0.5,0.5,0.5) end
        love.graphics.print("[ HITBOXES ]", 100, 45)
        
        love.graphics.setColor(1, 1, 1)
        love.graphics.line(20, 60, gw-20, 60)

        -- Conteúdo das Abas
        if Debug.current_tab == "info" then
            -- Mostra Seed e Status
            love.graphics.print("Seed: " .. (Seed and Seed.current or "N/A"), 30, 70)
            if player then
                love.graphics.print(string.format("Player HP: %d/%d", player.lifes, player.max_life), 30, 85)
                love.graphics.print(string.format("Pos: %.1f, %.1f", player.x, player.y), 30, 100)
            end
            
        elseif Debug.current_tab == "hitbox" then
            -- Opções de Hitbox
            draw_checkbox("Hitbox Jogador", Debug.options.show_player_rect, 30, 70)
            draw_checkbox("Hitbox Inimigos", Debug.options.show_enemy_rect, 30, 90)
            draw_checkbox("Hitbox Itens", Debug.options.show_item_rect, 30, 110)
        end
    end

    drawTouchControls()
    Transitions.draw()
    Part.draw()
end

function love.draw()
    Push:start()
    drawWorld()
    Push:finish()
end

function love.resize(w, h)
    Push:resize(w, h)
    setupTouchControls(w, h)
end

function love.textinput(t)
    if entering_seed and #seed_input < 6 then
        seed_input = seed_input .. string.upper(t)
    end
end

function love.keypressed(key)
    local is_menu = false
    for _, state in ipairs(menu_states) do
        if GameState.current == state then is_menu = true; break; end
    end
    if is_menu then
        Buttons:keypressed(key)
        return
    end
    
    if GameState.current == "intro" then
        
    elseif GameState.current == "characters" then
        Characters.keypressed(key)
    elseif GameState.current == "play" then
        if key == "r" and is_paused==false then
            _G.performSwitch("over")
        end
        if is_paused then
            table.insert(key_buffer, key)
            
            -- Mantém o buffer do tamanho do código
            if #key_buffer > #codigo_debug then
                table.remove(key_buffer, 1)
            end
            
            -- Verifica se a sequência bate
            local match = true
            if #key_buffer == #codigo_debug then
                for i = 1, #codigo_debug do
                    if key_buffer[i] ~= codigo_debug[i] then
                        match = false
                        break
                    end
                end
            else
                match = false
            end
            
            if match then
                Debug.active = true
                Debug.show_menu = true
                -- Toca um som de confirmação se quiser
                if SFX_Pickup_Heart then SFX_Pickup_Heart:play() end
                print("CODIGO DEBUG ATIVADO: MODO DEBUG LIGADO")
            end
        end
    end

    if key == "escape" then
        -- Se estiver no jogo (play)
        if GameState.current == "play" then
            is_paused = not is_paused -- Inverte: se tava false vira true, se tava true vira false
            return -- Retorna para não executar "menu_back" ou sair do jogo acidentalmente
        end
    end
end

function love.joystickadded(joystick)
    gamepad = joystick
end

function love.gamepadpressed(joystick, button)
    if not joystick then return end
    if button == 'dpup' then love.keypressed('up')
    elseif button == 'dpdown' then love.keypressed('down')
    elseif button == 'a' then love.keypressed('return') end
    if (button=="back" or button=="start") and is_paused==false then
        _G.switchState("over")
        if Musica_Atual then
            local pos = Musica_Atual:tell()
            Musica_Atual:stop()
            -- Lógica simples: se estava tocando luta, toca a versão de luta escolhida
            if GameConfig.musica_antiga == false then
                Musica_Atual = Menu_Musica
            else
                Musica_Atual = Musica_Luta_Antiga
            end
            Musica_Atual:play()
            Musica_Atual:seek(pos) -- Tenta manter a sincronia
            Musica_Atual:setLooping(true)
        end
    end
end

function love.touchpressed(id, x, y)
    local virt_x, virt_y = Push:toGame(x, y)
    if not virt_x or not virt_y then return end

    if GameState.current == "intro" then
        _G.switchState("menu")
        return
    end

    local is_menu = false
    for _, state in ipairs(menu_states) do
        if GameState.current == state then is_menu = true; break; end
    end
    
    if is_menu then
        Buttons:mousepressed(x, y, 1)
    elseif GameState.current == "characters" then
        Characters.touchpressed(virt_x, virt_y)
    elseif GameState.current == "play" then
        local screen_w, _ = Push:getDimensions()
        if virt_x < screen_w * 0.75 and not touch_controls.joystick_active then
            touch_controls.joystick_active = true
            touch_controls.joystick_id = id
            touch_controls.joystick_center.x, touch_controls.joystick_center.y = virt_x, virt_y
            touch_controls.joystick_pos.x, touch_controls.joystick_pos.y = virt_x, virt_y
        end
    end
end

function love.touchmoved(id, x, y, dx, dy, pressure)
    if GameState.current == "play" and touch_controls.joystick_active and touch_controls.joystick_id == id then
        local virt_x, virt_y = Push:toGame(x, y)
        if not virt_x or not virt_y then return end
        
        local center, radius = touch_controls.joystick_center, touch_controls.joystick_radius
        local dist_x, dist_y = virt_x - center.x, virt_y - center.y
        local dist = math.sqrt(dist_x^2 + dist_y^2)
        
        if dist > radius then
            touch_controls.joystick_pos.x = center.x + (dist_x / dist) * radius
            touch_controls.joystick_pos.y = center.y + (dist_y / dist) * radius
        else
            touch_controls.joystick_pos.x, touch_controls.joystick_pos.y = virt_x, virt_y
        end
    end
end

function love.touchreleased(id, x, y, dx, dy, pressure)
    if GameState.current == "play" and touch_controls.joystick_id == id then
        touch_controls.joystick_active = false
        touch_controls.joystick_id = nil
        if player then
            player.dx, player.dy = 0, 0
        end
    end
end

function love.mousepressed(x, y, button)
    -- Converte coordenada da tela real para a virtual (jogo)
    local gameX, gameY = Push:toGame(x, y)
    
    if not gameX or not gameY then return end -- Clicou fora da área do jogo

    -- Lógica do menu Debug (mantida igual)
    if is_paused and Debug.show_menu then
        -- (Sua lógica de debug existente aqui...)
        if gameY >= 45 and gameY <= 55 then
            if gameX >= 30 and gameX <= 80 then Debug.current_tab = "info" end
            if gameX >= 100 and gameX <= 160 then Debug.current_tab = "hitbox" end
        end
        if Debug.current_tab == "hitbox" then
            if gameY >= 70 and gameY <= 82 then Debug.options.show_player_rect = not Debug.options.show_player_rect end
            if gameY >= 90 and gameY <= 102 then Debug.options.show_enemy_rect = not Debug.options.show_enemy_rect end
            if gameY >= 110 and gameY <= 122 then Debug.options.show_item_rect = not Debug.options.show_item_rect end
        end
    end

    Buttons:mousepressed(gameX, gameY, button)
end

function love.mousemoved(x, y, dx, dy, istouch)
    local gameX, gameY = Push:toGame(x, y)
    if gameX and gameY then
        Buttons:mousemoved(gameX, gameY, dx, dy)
    end
end

function love.mousereleased(x, y, button)
    local gameX, gameY = Push:toGame(x, y)
    if gameX and gameY then
        Buttons:mousereleased(gameX, gameY, button)
    end
    
    if GameState.current == "play" and touch_controls.joystick_id then
        touch_controls.joystick_active = false
        touch_controls.joystick_id = nil
        if player then player.dx, player.dy = 0, 0 end
    end
end

function love.quit()
    if GameState.current == "play" or GameState.current == "rewards" then
        if player and player.lifes > 0 then
            Save.saveRunState()
            print("Run saved successfully!")
        end
    end
end