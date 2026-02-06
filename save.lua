local lume = require("libs/lume")
local Seed = require("seed")
local Wave = require("wave")
local Lang = require("lang")
local Player = require("player")
local Enemies = require("enemies")
local Rewards = require("rewards")

local Save = {}

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

local function stripUserdata(table_obj, seen)
    if type(table_obj) ~= "table" then return table_obj end
    
    seen = seen or {}
    
    if seen[table_obj] then return nil end
    
    seen[table_obj] = true
    
    local copy = {}
    for k, v in pairs(table_obj) do
        if type(k) == "string" or type(k) == "number" then
            if type(v) ~= "function" and type(v) ~= "userdata" then
                if type(v) == "table" then
                    copy[k] = stripUserdata(v, seen)
                else
                    copy[k] = v
                end
            end
        end
    end
    
    seen[table_obj] = nil
    
    return copy
end

function Save.load()
    if love.filesystem.getInfo("savedata_v2.txt") then
        local content = love.filesystem.read("savedata_v2.txt")
        local loaded = lume.deserialize(content)
        
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
    if wave > (Save.data.records.best_wave or 0) then
        Save.data.records.best_wave = wave
        Save.data.records.best_time = time
        changed = true
    elseif wave == (Save.data.records.best_wave or 0) then
        if time > (Save.data.records.best_time or 0) then
            Save.data.records.best_time = time
            changed = true
        end
    end
    
    if changed then Save.write() end
end

function Save.saveRunState()
    if _G.player and _G.player.lifes > 0 and not _G.player.dead then
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
                },
                rewards_info = {
                    reroll_cost = Rewards.reroll_cost
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
    
    Seed.set(r.game_state.seed)
    _G.game_timer = r.game_state.timer
    _G.game_mode = r.game_state.mode
    
    Wave.current_wave = r.wave_info.current
    Wave.wave_final = r.wave_info.final
    Wave.infinito = r.wave_info.infinito
    Wave.score = r.wave_info.score
    Wave.active = true
    Wave.waiting_next = false 
    
    -- Restaurar reroll_cost se salvo
    if r.rewards_info and r.rewards_info.reroll_cost then
        Rewards.reroll_cost = r.rewards_info.reroll_cost
    else
        Rewards.reroll_cost = 10  -- Valor padrão se não encontrado
    end
    
    _G.player = Player.new()
    
    for k, v in pairs(r.player) do
        _G.player[k] = v
    end
    
    local Characters = require("characters")
    Characters.load(_G.player)
    
    if _G.player.tipo_jogador then
        _G.player.sprite = {}
        local sheet = love.graphics.newImage("assets/spritePersonagens.png")
        for i=0,12 do
            _G.player.sprite[i+1] = love.graphics.newQuad(i*8, 0, 8, 8, sheet:getDimensions())
        end
    end
    
    _G.player.pending_stars = {}
    Enemies.reset()
    Wave.spawn_wave()
    
    return true
end

return Save