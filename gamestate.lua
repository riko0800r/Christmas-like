-- gamestate.lua
local GameState = {}

GameState.current = "intro" -- Estado inicial

function GameState.switch(newState, ...)
    -- Você pode adicionar lógica aqui para quando um estado muda (ex: resetar timers)
    GameState.current = newState
    
    -- Exemplo de como passar argumentos ao mudar de estado
    if newState == "reward" then
        local SFX_MENU=love.audio.newSource("assets/dano.wav","static")
        local randomPitch = love.math.random() * 0.75 + 0.4
        SFX_MENU:setVolume(2)
        SFX_MENU:setPitch(randomPitch)
        SFX_MENU:play()
        local Rewards = require('rewards') -- Carrega o módulo de recompensas
        Rewards.generate(3) -- Gera novas recompensas
    end
end

return GameState