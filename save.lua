local lume = require("libs/lume")
local Seed = require("seed")
local Wave = require("wave")
local Lang = require("lang")
local Player = require("player")
local Enemies = require("enemies") -- Need to reset enemies on load

local Save = {}

-- Structure:
-- Save.data = {
--    settings = { language, volumes, etc },
--    records = { best_wave, best_time },
--    run = nil (or table with player, wave, etc)
-- }
Save.data = {
    settings = {
        language = "pt-br",
        OldMusic = false,
        MusicVolume = 12,
        SFXVolume = 20,
        fullscreen = false,
        show_timer = true
    },
    records = {
        best_wave = 0,
        best_time = 0
    },
    run = nil
}

-- Helper to remove userdata (images) before saving
local function stripUserdata(table_obj, seen)
    -- Se não for tabela, retorna o valor direto
    if type(table_obj) ~= "table" then return table_obj end
    
    -- Inicializa a tabela de visitados
    seen = seen or {}
    
    -- Se já visitamos esta tabela neste caminho, é um CICLO. Retorna nil para quebrar o loop.
    if seen[table_obj] then return nil end
    
    -- Marca como visitado
    seen[table_obj] = true
    
    local copy = {}
    for k, v in pairs(table_obj) do
        -- O "lume" só consegue salvar chaves que são String ou Number.
        -- Se a chave for uma tabela ou userdata, ignoramos para não crashar.
        if type(k) == "string" or type(k) == "number" then
            -- Ignora funções e userdata (imagens/sons)
            if type(v) ~= "function" and type(v) ~= "userdata" then
                if type(v) == "table" then
                    -- Recursão passando o histórico de 'seen'
                    copy[k] = stripUserdata(v, seen)
                else
                    copy[k] = v
                end
            end
        end
    end
    
    -- Remove da lista de visitados ao sair (para permitir estruturas válidas que se repetem)
    seen[table_obj] = nil
    
    return copy
end

function Save.load()
    if love.filesystem.getInfo("savedata_v2.txt") then
        local content = love.filesystem.read("savedata_v2.txt")
        local loaded = lume.deserialize(content)
        
        -- Merge loaded data into default structure (safeguard for new fields)
        if loaded.settings then 
            for k,v in pairs(loaded.settings) do Save.data.settings[k] = v end
        end
        if loaded.records then 
            Save.data.records = loaded.records 
        end
        if loaded.run then 
            Save.data.run = loaded.run 
        end
    end

    -- Apply Settings immediately
    Lang.setLanguage(Save.data.settings.language)
    if _G.GameConfig then
        _G.GameConfig.musica_antiga = Save.data.settings.OldMusic
        _G.GameConfig.music_vol = Save.data.settings.MusicVolume
        _G.GameConfig.sfx_vol = Save.data.settings.SFXVolume
        _G.GameConfig.fullscreen = Save.data.settings.fullscreen
        _G.GameConfig.show_timer = Save.data.settings.show_timer
        love.window.setFullscreen(_G.GameConfig.fullscreen)
    end
end

function Save.write()
    local serialized = lume.serialize(Save.data)
    love.filesystem.write("savedata_v2.txt", serialized)
end

function Save.saveSettings()
    Save.data.settings.language = Lang.current
    Save.data.settings.OldMusic = _G.GameConfig.musica_antiga
    Save.data.settings.MusicVolume = _G.GameConfig.music_vol
    Save.data.settings.SFXVolume = _G.GameConfig.sfx_vol
    Save.data.settings.fullscreen = _G.GameConfig.fullscreen
    Save.data.settings.show_timer = _G.GameConfig.show_timer
    Save.write()
end

function Save.checkRecord(wave, time)
    local changed = false
    -- Logic: Higher wave is better. If same wave, lower time is better.
    if wave > (Save.data.records.best_wave or 0) then
        Save.data.records.best_wave = wave
        Save.data.records.best_time = time
        changed = true
    elseif wave == (Save.data.records.best_wave or 0) then
        if time > (Save.data.records.best_time or 0) then -- Actually longer time survived is usually better in survival? 
            -- If goal is speedrun to finish: Lower is better. 
            -- If goal is survival: Higher is better.
            -- Based on "Speedrun Timer" option, let's assume specific levels speedrun.
            -- But for endless, Time is score. Let's just save max time.
            Save.data.records.best_time = time
            changed = true
        end
    end
    
    if changed then Save.write() end
end

-- Call this when closing the game or returning to menu alive
function Save.saveRunState()
    if _G.player and _G.player.lifes > 0 and not _G.player.dead then
        -- Usando pcall interno para garantir que erro de save não crashe o jogo
        local status, err = pcall(function()
            local run_data = {
                player = stripUserdata(_G.player), 
                wave_info = {
                    current = Wave.current_wave,
                    final = Wave.wave_final,
                    infinito = Wave.infinito,
                    score = Wave.score,
                    active = Wave.active
                },
                game_state = {
                    timer = _G.game_timer,
                    seed = Seed.current,
                    mode = _G.game_mode
                }
            }
            Save.data.run = run_data
            Save.write()
        end)

        if not status then
            print("ERRO CRÍTICO AO SALVAR: " .. tostring(err))
        end
    end
end

-- Call this when dying or winning (run ends)
function Save.deleteRun()
    Save.data.run = nil
    Save.write()
end

function Save.hasRun()
    return Save.data.run ~= nil
end

function Save.loadRun()
    if not Save.data.run then return false end
    
    local r = Save.data.run
    
    -- Restore Globals
    Seed.set(r.game_state.seed)
    _G.game_timer = r.game_state.timer
    _G.game_mode = r.game_state.mode
    
    -- Restore Wave
    Wave.current_wave = r.wave_info.current
    Wave.wave_final = r.wave_info.final
    Wave.infinito = r.wave_info.infinito
    Wave.score = r.wave_info.score
    Wave.active = true
    Wave.waiting_next = false 
    
    -- Restore Player
    _G.player = Player.new() -- Create fresh to get methods
    
    -- Overwrite attributes with saved data
    for k, v in pairs(r.player) do
        _G.player[k] = v
    end
    
    -- CRITICAL: Re-load images/sprites based on the restored ID/Type
    -- We assume Characters module can help or we do it manually
    local Characters = require("characters")
    Characters.load(_G.player) -- Load generic sheets
    
    -- Re-apply specific character sprite quad
    -- Since we saved 'tipo_jogador', we can reconstruct the quad
    if _G.player.tipo_jogador then
        -- Refresh sprites quads
         _G.player.sprite = {}
         local sheet = love.graphics.newImage("assets/spritePersonagens.png")
         for i=0,12 do
            _G.player.sprite[i+1] = love.graphics.newQuad(i*8, 0, 8, 8, sheet:getDimensions())
         end
    end
    
    -- Reset Enemies (Cleaner than saving them)
    _G.player.pending_stars = {}
    Enemies.reset()
    Wave.spawn_wave() -- Spawn the current wave again
    
    return true
end

return Save