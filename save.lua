local lume=require("libs/lume")
local Seed=require("seed")
local Wave=require("wave")
local Lang= require("lang")
local Player=require("player")

local Save={}

Save.savedata={}

function Save.saveDataMenu()
    Save.savedata.language    = Lang.current
    Save.savedata.OldMusic    = _G.GameConfig.musica_antiga
    Save.savedata.MusicVolume = _G.GameConfig.music_vol
    Save.savedata.SFXVolume   = _G.GameConfig.sfx_vol

    local DATA=lume.serialize(Save.savedata)
    love.filesystem.write("savedata.txt", DATA)
end

function Save.loadDataMenu()
    local file = love.filesystem.read("savedata.txt")
    Save.savedata = lume.deserialize(file)
    Lang.setLanguage(Save.savedata.language)
    _G.GameConfig.musica_antiga=Save.savedata.OldMusic 
    _G.GameConfig.music_vol=Save.savedata.MusicVolume
    _G.GameConfig.sfx_vol=Save.savedata.SFXVolume
end

function Save.saveDataInGame()
    Save.savedata.language  = Lang.current
    Save.savedata.seed = Seed.get()
    Save.savedata.mode = _G.game_mode
    if _G.player then
        Save.savedata.player = _G.player
    else
        Save.savedata.player = Player.new()
    end
    local DATA=lume.serialize(Save.savedata)
    love.filesystem.write("savedata.txt", DATA)
end

function Save.loadDataInGame()
    local file = love.filesystem.read("savedata.txt")
    Save.savedata = lume.deserialize(file)
    Lang.setLanguage(Save.savedata.language)
    Seed.set(Save.savedata.seed)
    _G.game_mode=Save.savedata.mode
    _G.player=Save.savedata.player
end

return Save