-- gamestate.lua
local GameState = {}

GameState.current = "intro" -- Estado inicial

function GameState.switch(newState, ...)
    -- Você pode adicionar lógica aqui para quando um estado muda (ex: resetar timers)
    local previousState = GameState.current
    GameState.current = newState

    -- Telas customizadas registradas por mods (ModAPI.registerScreen)
    -- recebem enter()/leave() aqui, do mesmo jeito que a intro_cutscene
    -- nativa já recebe logo abaixo — dá pra um soundtest, por exemplo,
    -- parar a música anterior ao entrar e não deixar nada tocando ao sair.
    if _G.ModAPI then
        local prevScreen = _G.ModAPI.getScreen(previousState)
        if prevScreen and prevScreen.leave then
            local ok, err = pcall(prevScreen.leave)
            if not ok then print("[MODS] Erro em leave() da tela '" .. tostring(previousState) .. "': " .. tostring(err)) end
        end
        local newScreen = _G.ModAPI.getScreen(newState)
        if newScreen and newScreen.enter then
            local ok, err = pcall(newScreen.enter, ...)
            if not ok then print("[MODS] Erro em enter() da tela '" .. tostring(newState) .. "': " .. tostring(err)) end
        end
    end

    if newState == "intro" then
        -- Reinicia a timeline da cutscene toda vez que entramos na intro
        -- (seja no boot do jogo, seja pelo botão "Ver intro denovo" no menu).
        local ok, IntroCutscene = pcall(require, "intro_cutscene")
        if ok then
            IntroCutscene.enter()
        end
        _G.intro_timer = 2.0 -- pequena pausa após o fim da cutscene antes de auto-avançar pro menu
    elseif previousState == "intro" then
        -- Saindo da intro: desliga o player fantasma e limpa os inimigos
        -- da cutscene, pra nunca vazarem pra dentro de uma partida real.
        local ok, IntroCutscene = pcall(require, "intro_cutscene")
        if ok then
            IntroCutscene.leave()
        end
    end

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