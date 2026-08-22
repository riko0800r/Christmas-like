-- modapi.lua
-- ================================================================
-- API PÚBLICA PARA MODS
-- ================================================================
-- Este módulo é a porta de entrada oficial que os arquivos mod.lua
-- devem usar para mexer no jogo. Ele não substitui os módulos
-- originais (Waves, Enemy, Lang, Rewards, Player) — só os reúne
-- num único lugar documentado, pra quem escreve um mod não precisar
-- ler o código-fonte inteiro do jogo pra saber o que existe.
--
-- Um mod NÃO É obrigado a usar só isto: como não há sandbox, ele
-- pode fazer require() de qualquer módulo do jogo diretamente.
-- Mas ModAPI cobre os casos mais comuns com uma superfície estável,
-- então mods que só usam ModAPI têm mais chance de continuar
-- funcionando se o jogo mudar por dentro no futuro.
--
-- VERSÃO DA API: mods podem checar ModAPI.VERSION se precisarem
-- se comportar diferente dependendo da versão do jogo/API.
-- ================================================================

local ModAPI = {}

ModAPI.VERSION = "2.0"

ModAPI.Waves    = require("wave")
ModAPI.Enemy    = require("enemies")
ModAPI.Lang     = require("lang")
ModAPI.Rewards  = require("rewards")
ModAPI.Player   = require("player")
ModAPI.Utils    = require("utils")

-- Lista de mods carregados nesta sessão (preenchida pelo modloader).
-- Cada entrada: { id=, name=, version=, author=, description=, path=,
--                 ok=, error=, enabled=, mod_table= }
ModAPI.loaded_mods = {}

-- ------------------------------------------------------------
-- HOOKS DE EVENTOS
-- ------------------------------------------------------------
-- Um mod pode se inscrever em eventos do jogo sem precisar
-- sobrescrever funções inteiras do main.lua. Vários mods podem
-- se inscrever no mesmo evento; todos são chamados, na ordem
-- de carregamento (a menos que use priority, ver ModAPI.on).
--
-- Eventos disponíveis:
--   "update"        (dt)                    -- todo frame, se o jogo estiver em "play" e não pausado
--   "draw"          ()                       -- todo frame de desenho, durante o estado "play"
--   "draw_ui"       ()                       -- todo frame de desenho, por cima da UI (HUD), estado "play"
--   "enemy_spawn"   (enemy)                  -- sempre que um inimigo é criado
--   "enemy_death"   (enemy)                  -- sempre que um inimigo morre
--   "enemy_hit"     (enemy, damage, source)  -- sempre que um inimigo recebe dano
--   "player_hit"    (player, damage)         -- quando o player toma dano
--   "player_heal"   (player, amount)         -- quando o player recupera vida
--   "player_levelup"(player, new_level)      -- quando o player sobe de nível
--   "wave_start"    (wave_number)            -- toda vez que uma nova onda começa
--   "wave_clear"    (wave_number)            -- toda vez que uma onda é limpa (antes da próxima começar)
--   "boss_spawn"    (boss_enemy)             -- quando um boss é criado
--   "boss_death"    (boss_enemy)             -- quando um boss morre
--   "game_start"    ()                       -- início de uma run (resetGame)
--   "game_over"     ()                       -- quando o player morre
--   "game_victory"  ()                       -- quando o player vence a run
--   "state_change"  (new_state, old_state)   -- toda vez que GameState.switch é chamado
--   "post_process"  ()                       -- uma vez por frame, em TODA tela (menus incluso),
--                                                logo antes do shader ativo ser resetado. É o
--                                                lugar certo pra um mod chamar
--                                                love.graphics.setShader(meu_shader) e aplicar
--                                                um efeito de tela cheia (CRT, NTSC, etc). O mod
--                                                é responsável por chamar love.graphics.setShader()
--                                                sem argumentos se quiser desligar o efeito depois
--                                                (ex: reagindo a uma opção do menu).
--   "mods_ready"    ()                       -- disparado uma vez, depois que TODOS os mods
--                                                terminaram de carregar (útil pra depender de
--                                                outro mod ter rodado primeiro)
--   "menu_options_buttons" ()                -- disparado toda vez que a tela "menu_options"
--                                                monta seus botões (depois dos botões nativos,
--                                                antes do botão "Voltar"). É o lugar certo pra
--                                                um mod adicionar um botão próprio nessa tela
--                                                (ex: "Soundtest") sem reescrever o menu inteiro.
--
-- Mods também podem disparar e ouvir seus próprios eventos customizados
-- (ex: "meu_mod:algo_aconteceu") usando ModAPI.on/ModAPI.trigger normalmente,
-- o que permite mods se comunicarem entre si sem se conhecerem diretamente.
-- ------------------------------------------------------------

local hooks = {}

-- callback: function(...)
-- opts (opcional): { priority = number, owner = mod_id }
--   priority: hooks com priority MAIOR rodam primeiro (padrão 0).
--   owner: id do mod dono do hook. Preenchido automaticamente pelo
--          modloader quando o hook é registrado durante o load() do mod;
--          usado por ModAPI.disableMod para desligar hooks daquele mod
--          sem precisar recarregar o jogo inteiro.
function ModAPI.on(event, callback, opts)
    if type(callback) ~= "function" then return end
    opts = opts or {}
    hooks[event] = hooks[event] or {}
    table.insert(hooks[event], {
        fn = callback,
        priority = opts.priority or 0,
        owner = opts.owner or ModAPI._current_loading_mod,
    })
    table.sort(hooks[event], function(a, b) return a.priority > b.priority end)
end

-- Remove todos os hooks de um evento específico registrados por um mod,
-- ou (se event for nil) todos os hooks daquele mod em qualquer evento.
function ModAPI.off(owner_id, event)
    local function strip(list)
        if not list then return end
        for i = #list, 1, -1 do
            if list[i].owner == owner_id then
                table.remove(list, i)
            end
        end
    end
    if event then
        strip(hooks[event])
    else
        for _, list in pairs(hooks) do strip(list) end
    end
end

-- Uso interno do jogo (main.lua/enemies.lua/etc chamam isto).
-- Protegido por pcall: um hook de mod que dá erro não derruba o jogo,
-- só imprime o erro no console e desativa aquele hook específico.
function ModAPI.trigger(event, ...)
    local list = hooks[event]
    if not list then return end
    -- Percorre na ordem de prioridade (já ordenada por ModAPI.on). Hooks que
    -- derem erro são marcados e removidos depois, num segundo passo, pra não
    -- bagunçar os índices nem pular vizinhos durante a iteração principal.
    local broken = nil
    for i = 1, #list do
        local entry = list[i]
        local ok, err = pcall(entry.fn, ...)
        if not ok then
            local who = entry.owner and (" (mod: " .. tostring(entry.owner) .. ")") or ""
            print("[MODS] Erro no hook '" .. event .. "'" .. who .. ": " .. tostring(err))
            broken = broken or {}
            broken[i] = true
        end
    end
    if broken then
        for i = #list, 1, -1 do
            if broken[i] then table.remove(list, i) end
        end
    end
end

-- Retorna quantos hooks estão registrados num evento (0 se nenhum). Útil
-- pra debug/telemetria dentro do menu de mods.
function ModAPI.countHooks(event)
    return hooks[event] and #hooks[event] or 0
end

-- ------------------------------------------------------------
-- HABILITAR / DESABILITAR MODS
-- ------------------------------------------------------------
-- O modloader consulta ModAPI.isModEnabled(id) ANTES de rodar o
-- load() de cada mod (mods desabilitados nunca chegam a executar
-- código, então não há custo de performance nem risco de efeitos
-- colaterais). A lista de habilitados/desabilitados é persistida em
-- disco pelo próprio ModAPI (ver ModAPI.loadModConfig/saveModConfig),
-- assim o menu de mods e o modloader sempre concordam.
-- ------------------------------------------------------------

local MODCONFIG_PATH = "mods_config.json"
local mod_config = { disabled = {} } -- { disabled = { [mod_id] = true, ... } }

local function serialize_disabled_set(set)
    local parts = {}
    for id, v in pairs(set) do
        if v then table.insert(parts, string.format("%q", id)) end
    end
    return "{\"disabled\":[" .. table.concat(parts, ",") .. "]}"
end

local function parse_disabled_json(str)
    local set = {}
    if type(str) == "string" then
        local body = str:match('"disabled"%s*:%s*%[(.-)%]')
        if body then
            for id in body:gmatch('"(.-)"') do
                set[id] = true
            end
        end
    end
    return set
end

-- Carrega o estado salvo de habilitado/desabilitado do disco.
-- Chamado automaticamente pelo modloader antes de escanear a pasta mods/.
function ModAPI.loadModConfig()
    if love and love.filesystem and love.filesystem.getInfo(MODCONFIG_PATH) then
        local contents = love.filesystem.read(MODCONFIG_PATH)
        mod_config.disabled = parse_disabled_json(contents)
    end
    return mod_config
end

-- Salva o estado atual de habilitado/desabilitado no disco.
function ModAPI.saveModConfig()
    if love and love.filesystem then
        love.filesystem.write(MODCONFIG_PATH, serialize_disabled_set(mod_config.disabled))
    end
end

-- true se o mod pode/deve rodar. Por padrão todo mod é habilitado.
function ModAPI.isModEnabled(mod_id)
    return not mod_config.disabled[mod_id]
end

-- Habilita um mod. Se o mod já rodou nesta sessão (ou foi pulado por
-- estar desabilitado), a mudança só terá efeito completo na próxima
-- vez que o jogo/mods forem carregados — ModAPI não tenta "re-executar"
-- um mod.lua no meio da run porque isso poderia duplicar registros
-- (inimigos, upgrades, etc). O menu de mods avisa o jogador disso.
function ModAPI.enableMod(mod_id)
    mod_config.disabled[mod_id] = nil
    ModAPI.saveModConfig()
end

function ModAPI.disableMod(mod_id)
    mod_config.disabled[mod_id] = true
    ModAPI.saveModConfig()
    -- Remove hooks que esse mod já tenha registrado nesta sessão, pra um
    -- mod desabilitado parar de ter efeito imediatamente mesmo sem reiniciar.
    ModAPI.off(mod_id, nil)
end

function ModAPI.toggleMod(mod_id)
    if ModAPI.isModEnabled(mod_id) then
        ModAPI.disableMod(mod_id)
    else
        ModAPI.enableMod(mod_id)
    end
    return ModAPI.isModEnabled(mod_id)
end

-- Retorna a lista de mods encontrados nesta sessão (rodados ou não),
-- cada item com pelo menos: id, name, version, author, description,
-- path, ok, error, enabled.
function ModAPI.listMods()
    return ModAPI.loaded_mods
end

function ModAPI.getMod(mod_id)
    for _, m in ipairs(ModAPI.loaded_mods) do
        if m.id == mod_id then return m end
    end
    return nil
end

-- ------------------------------------------------------------
-- CONFIGURAÇÃO PERSISTENTE POR MOD
-- ------------------------------------------------------------
-- Um mod pode salvar suas próprias configurações (dificuldade extra,
-- preferências visuais, etc.) sem precisar mexer com love.filesystem
-- diretamente nem se preocupar em colidir com o savefile do jogo ou
-- com outros mods. Cada mod tem seu próprio arquivo:
--   mod_data/<mod_id>.json
-- Guarda apenas tabelas simples (strings, números, booleanos, tabelas
-- aninhadas dos mesmos tipos) — não serializa funções.
-- ------------------------------------------------------------

local function mod_data_path(mod_id)
    return "mod_data/" .. mod_id:gsub("[^%w_%-]", "_") .. ".json"
end

-- Serializador minimalista (não depende de libs externas). Suporta
-- string/number/boolean/table (array ou dicionário simples).
local function encode_value(v)
    local t = type(v)
    if t == "string" then
        return string.format("%q", v)
    elseif t == "number" or t == "boolean" then
        return tostring(v)
    elseif t == "table" then
        local is_array = true
        local n = 0
        for k in pairs(v) do
            n = n + 1
            if type(k) ~= "number" then is_array = false end
        end
        local parts = {}
        if is_array then
            for i = 1, n do table.insert(parts, encode_value(v[i])) end
            return "[" .. table.concat(parts, ",") .. "]"
        else
            for k, val in pairs(v) do
                table.insert(parts, string.format("%q", tostring(k)) .. ":" .. encode_value(val))
            end
            return "{" .. table.concat(parts, ",") .. "}"
        end
    end
    return "null"
end

function ModAPI.saveModData(mod_id, data)
    if not (love and love.filesystem) then return false end
    if not love.filesystem.getInfo("mod_data") then
        love.filesystem.createDirectory("mod_data")
    end
    local ok, encoded = pcall(encode_value, data)
    if not ok then
        print("[MODS] Falha ao salvar dados do mod '" .. tostring(mod_id) .. "': " .. tostring(encoded))
        return false
    end
    love.filesystem.write(mod_data_path(mod_id), encoded)
    return true
end

-- Parser JSON minimalista o suficiente pro que ModAPI.saveModData escreve.
-- Se o mod quiser algo mais robusto, pode trazer sua própria lib de JSON.
local function decode_json(str)
    local pos = 1
    local function skip_ws() while pos <= #str and str:sub(pos,pos):match("%s") do pos = pos + 1 end end
    local parse_value

    local function parse_string()
        pos = pos + 1
        local buf = {}
        while pos <= #str do
            local c = str:sub(pos, pos)
            if c == "\\" then
                buf[#buf+1] = str:sub(pos+1, pos+1)
                pos = pos + 2
            elseif c == "\"" then
                pos = pos + 1
                return table.concat(buf)
            else
                buf[#buf+1] = c
                pos = pos + 1
            end
        end
        return table.concat(buf)
    end

    local function parse_number()
        local start = pos
        while pos <= #str and str:sub(pos,pos):match("[%d%.%-eE+]") do pos = pos + 1 end
        return tonumber(str:sub(start, pos - 1))
    end

    local function parse_array()
        pos = pos + 1
        local arr = {}
        skip_ws()
        if str:sub(pos,pos) == "]" then pos = pos + 1; return arr end
        while true do
            skip_ws()
            table.insert(arr, parse_value())
            skip_ws()
            local c = str:sub(pos,pos)
            if c == "," then pos = pos + 1
            elseif c == "]" then pos = pos + 1; break
            else break end
        end
        return arr
    end

    local function parse_object()
        pos = pos + 1
        local obj = {}
        skip_ws()
        if str:sub(pos,pos) == "}" then pos = pos + 1; return obj end
        while true do
            skip_ws()
            local key = parse_string()
            skip_ws()
            pos = pos + 1 -- ':'
            skip_ws()
            obj[key] = parse_value()
            skip_ws()
            local c = str:sub(pos,pos)
            if c == "," then pos = pos + 1
            elseif c == "}" then pos = pos + 1; break
            else break end
        end
        return obj
    end

    parse_value = function()
        skip_ws()
        local c = str:sub(pos, pos)
        if c == "\"" then return parse_string()
        elseif c == "{" then return parse_object()
        elseif c == "[" then return parse_array()
        elseif str:sub(pos, pos+3) == "true" then pos = pos + 4; return true
        elseif str:sub(pos, pos+4) == "false" then pos = pos + 5; return false
        elseif str:sub(pos, pos+3) == "null" then pos = pos + 4; return nil
        else return parse_number() end
    end

    local ok, result = pcall(parse_value)
    if ok then return result else return nil end
end

-- Retorna a tabela salva anteriormente com ModAPI.saveModData, ou
-- `default` (ou {} se default for omitido) se não houver nada salvo.
function ModAPI.loadModData(mod_id, default)
    if not (love and love.filesystem) then return default or {} end
    local path = mod_data_path(mod_id)
    if not love.filesystem.getInfo(path) then return default or {} end
    local contents = love.filesystem.read(path)
    local decoded = decode_json(contents)
    return decoded or (default or {})
end

-- ------------------------------------------------------------
-- ATALHOS DE CONVENIÊNCIA — CONTEÚDO
-- ------------------------------------------------------------

-- Registra (ou sobrescreve) um tipo de inimigo e sua IA de uma vez,
-- e opcionalmente já adiciona ele às ondas normais ou de boss.
-- preset: tabela igual às usadas em enemies.lua (EnemyPresets)
-- ai_fn: function(enemy, player, dt) -- opcional, se o inimigo precisar de comportamento próprio
-- opts: { add_to_normal_waves = true/false, add_to_boss_waves = true/false }
function ModAPI.registerEnemy(type_name, preset, ai_fn, opts)
    opts = opts or {}
    ModAPI.Enemy.presets[type_name] = preset
    if ai_fn then
        ModAPI.Enemy.ai[type_name] = ai_fn
    end
    if opts.add_to_normal_waves then
        table.insert(ModAPI.Waves.enemy_types, type_name)
    end
    if opts.add_to_boss_waves then
        table.insert(ModAPI.Waves.boss_types, type_name)
    end
    return type_name
end

-- Remove um tipo de inimigo registrado (ex: um mod quer substituir um
-- inimigo do próprio jogo em vez de só adicionar um novo). Remove
-- também das listas de spawn normais/boss, se presente.
function ModAPI.unregisterEnemy(type_name)
    ModAPI.Enemy.presets[type_name] = nil
    ModAPI.Enemy.ai[type_name] = nil
    for _, list in ipairs({ ModAPI.Waves.enemy_types, ModAPI.Waves.boss_types }) do
        for i = #list, 1, -1 do
            if list[i] == type_name then table.remove(list, i) end
        end
    end
end

-- Registra um item novo na loja (arma/upgrade recorrente).
-- item precisa de: id, get_name, get_desc, effect(player), weight, icon, get_price(item, player)
-- get_desc2 é opcional (usada pra mostrar preview do próximo nível).
function ModAPI.registerUpgrade(item)
    item.type = item.type or "upgrade"
    table.insert(ModAPI.Rewards.upgrades, item)
    return item
end

-- Registra uma relíquia nova (item único por run).
function ModAPI.registerRelic(item)
    item.type = item.type or "relic"
    table.insert(ModAPI.Rewards.shop_items, item)
    return item
end

-- Remove um upgrade ou relíquia previamente registrado pelo id.
function ModAPI.unregisterReward(item_id)
    for _, list in ipairs({ ModAPI.Rewards.upgrades, ModAPI.Rewards.shop_items }) do
        for i = #list, 1, -1 do
            if list[i].id == item_id then table.remove(list, i) end
        end
    end
end

-- Adiciona/edita um idioma inteiro de uma vez.
-- lang_code: ex "es", "fr"
-- table_of_keys: { ["menu_play"] = "Jugar", ... }
function ModAPI.registerLanguage(lang_code, table_of_keys)
    ModAPI.Lang.db[lang_code] = ModAPI.Lang.db[lang_code] or {}
    for k, v in pairs(table_of_keys) do
        ModAPI.Lang.db[lang_code][k] = v
    end
end

-- Sobrescreve/adiciona chaves de um idioma já existente sem substituir o idioma inteiro.
function ModAPI.setText(lang_code, key, value)
    ModAPI.Lang.db[lang_code] = ModAPI.Lang.db[lang_code] or {}
    ModAPI.Lang.db[lang_code][key] = value
end

-- ------------------------------------------------------------
-- ATALHOS DE CONVENIÊNCIA — MODOS DE JOGO E ONDAS
-- ------------------------------------------------------------

-- Registra um novo modo de dificuldade/jogo completo (ex: "pesadelo").
-- config: { wave_final=, can_spawn_boss=, boss_freq=, label=, label_key= }
-- Se label_key for informado, ModAPI também tenta criar uma entrada no
-- Lang atual com esse texto (label), pra aparecer pronto no seletor de
-- dificuldade sem o mod precisar chamar registerLanguage também.
function ModAPI.registerGameMode(mode_key, config)
    local mode_id = ModAPI.Waves.game_modes[mode_key]
    if not mode_id then
        -- gera um id numérico novo (maior que os existentes)
        local max_id = 0
        for _, v in pairs(ModAPI.Waves.game_modes) do
            if v > max_id then max_id = v end
        end
        mode_id = max_id + 1
        ModAPI.Waves.game_modes[mode_key] = mode_id
    end
    ModAPI.Waves.mode_config[mode_id] = config
    if config.label_key and config.label then
        ModAPI.setText("pt-br", config.label_key, config.label)
        ModAPI.setText("en", config.label_key, config.label_en or config.label)
    end
    return mode_id
end

-- Registra uma função geradora de onda customizada. Se presente,
-- o jogo pode chamar spawn_fn(wave_number, is_boss_wave) em vez da
-- lógica padrão de Waves.spawn_wave/spawn_boss para esse modo específico
-- (isso requer que wave.lua consulte ModAPI.wave_overrides). Por
-- enquanto isto apenas registra a intenção do mod, servindo de ponto de
-- extensão para quando essa integração for ligada no wave.lua.
ModAPI.wave_overrides = {}
function ModAPI.setWaveGenerator(mode_key, spawn_fn)
    ModAPI.wave_overrides[mode_key] = spawn_fn
end

-- ------------------------------------------------------------
-- ATALHOS DE CONVENIÊNCIA — PERSONAGENS
-- ------------------------------------------------------------

-- Registra um personagem jogável novo (mesmo formato de characters.lua:
-- precisa de id, get_name, get_desc, apply(player)).
function ModAPI.registerCharacter(char)
    local Characters = require("characters")
    table.insert(Characters.list, char)
    return char
end

-- ------------------------------------------------------------
-- TELAS CUSTOMIZADAS (novos "estados" de menu)
-- ------------------------------------------------------------
-- Antes disto, main.lua só sabia desenhar/atualizar os estados que
-- ele mesmo conhecia via if/elseif GameState.current == "...". Um mod
-- não tinha como adicionar uma tela nova (ex: um soundtest, um
-- créditos alternativo, uma tela de estatísticas) sem editar
-- main.lua diretamente.
--
-- ModAPI.registerScreen resolve isso: registra uma tela sob uma
-- state_key (a mesma string que _G.switchState("sua_tela") usaria),
-- e main.lua consulta esse registro genericamente pra estados que
-- ele não reconhece. A tela automaticamente ganha:
--   - Buttons:update/mousepressed/mousemoved/mousereleased/keypressed
--     (porque a state_key entra em _G.menu_states)
--   - roteamento de draw()/update(dt) genérico em main.lua
--
-- screen: {
--   draw = function() ... end,                 -- obrigatório
--   update = function(dt) ... end,              -- opcional
--   setupButtons = function(Buttons) ... end,   -- opcional: chamado toda vez que
--                                                   a tela é (re)aberta, pra montar os
--                                                   botões dela via Buttons:newButton(...)
--   enter = function(...) ... end,              -- opcional: chamado 1x ao entrar na tela
--                                                   (recebe os mesmos args extras de
--                                                   switchState(state_key, ...))
--   leave = function() ... end,                 -- opcional: chamado ao sair da tela
-- }
local registered_screens = {}

function ModAPI.registerScreen(state_key, screen)
    if type(state_key) ~= "string" or type(screen) ~= "table" then return end
    screen.draw = screen.draw or function() end
    registered_screens[state_key] = screen

    -- Garante que a tela participa do "modo menu" (botões, navegação
    -- por teclado/gamepad, etc.) sem precisar que main.lua saiba dela
    -- de antemão.
    if _G.menu_states then
        local already = false
        for _, s in ipairs(_G.menu_states) do
            if s == state_key then already = true; break end
        end
        if not already then
            table.insert(_G.menu_states, state_key)
        end
    end

    return screen
end

function ModAPI.unregisterScreen(state_key)
    registered_screens[state_key] = nil
    if _G.menu_states then
        for i = #_G.menu_states, 1, -1 do
            if _G.menu_states[i] == state_key then table.remove(_G.menu_states, i) end
        end
    end
end

function ModAPI.getScreen(state_key)
    return registered_screens[state_key]
end

-- ------------------------------------------------------------
-- CATÁLOGO DE MÚSICAS
-- ------------------------------------------------------------
-- Registro central de faixas de música que existem no jogo (nativas
-- ou adicionadas por mods), pra qualquer tela (ex: um soundtest)
-- conseguir listar "toda música disponível" sem precisar conhecer os
-- globais internos de main.lua (Menu_Musica, Luta_Musica, etc) nem
-- ter uma lista própria que fica desatualizada.
--
-- ModAPI.registerMusic NÃO toca a música nem mexe no que está tocando
-- agora — só cadastra. Quem quiser tocar, chama love.audio ou usa
-- ModAPI.playMusic (ver abaixo).
--
-- info: {
--   id = "menu_novo",              -- único; se repetir, sobrescreve o registro anterior
--   path = "assets/minha_musica.mp3", -- caminho pro arquivo (relativo à raiz do jogo).
--                                        Usado só pra checar se o arquivo existe e pra
--                                        criar a source SOB DEMANDA no jogo base; um MOD
--                                        que registra sua própria música deve preferir
--                                        passar `source` já pronta (ver abaixo), porque
--                                        a pasta do mod só fica montada durante load().
--   source = love.audio.Source,    -- opcional: source JÁ CRIADA (love.audio.newSource).
--                                        Se informado, ModAPI.getMusicSource devolve isto
--                                        direto, sem tentar recriar via `path`. É o jeito
--                                        recomendado pra MODS registrarem música própria:
--                                        crie a source dentro do seu load(mod) — enquanto
--                                        a pasta do mod ainda está montada — e passe aqui.
--   label = "Menu (Remix)",        -- nome pra mostrar na UI
--   label_key = "soundtest_menu_novo", -- opcional: chave de Lang pra usar no lugar de `label`
--   source_type = "stream" | "static", -- opcional, padrão "stream" (streams são melhores pra
--                                          músicas longas; static pra efeitos curtos). Só usado
--                                          se `source` não for informado.
--   category = "menu" | "luta" | "loja" | "outro", -- opcional, livre, útil pra agrupar na UI
-- }
local music_catalog = {}      -- [id] = info
local music_catalog_order = {} -- lista ordenada de ids, na ordem de registro

function ModAPI.registerMusic(info)
    if type(info) ~= "table" or not info.id or not info.path then return nil end
    info.source_type = info.source_type or "stream"
    if not music_catalog[info.id] then
        table.insert(music_catalog_order, info.id)
    end
    music_catalog[info.id] = info
    return info.id
end

-- Retorna a lista de músicas registradas, na ordem de registro.
function ModAPI.listMusic()
    local list = {}
    for _, id in ipairs(music_catalog_order) do
        list[#list + 1] = music_catalog[id]
    end
    return list
end

function ModAPI.getMusic(id)
    return music_catalog[id]
end

-- Cria (sob demanda, na primeira vez) e devolve o love.audio.Source de
-- uma faixa registrada. Cacheia por id, então chamar de novo devolve
-- a MESMA source (não duplica). Falha graciosamente (retorna nil +
-- imprime aviso) se o arquivo não existir, em vez de derrubar o jogo
-- — importante pro soundtest funcionar mesmo se o usuário ainda não
-- tiver colocado os .mp3/.ogg das músicas novas na pasta.
local music_source_cache = {}
function ModAPI.getMusicSource(id)
    if music_source_cache[id] then return music_source_cache[id] end
    local info = music_catalog[id]
    if not info then return nil end

    -- Caso 1: mod já forneceu a source pronta (recomendado para mods,
    -- já que a pasta do mod é desmontada logo após load() terminar —
    -- tentar criar a source depois disso, via path, falharia).
    if info.source then
        music_source_cache[id] = info.source
        return info.source
    end

    -- Caso 2: cria a source sob demanda a partir de `path` (funciona
    -- bem para música nativa do jogo base, cujos arquivos ficam na
    -- pasta raiz do jogo, sempre acessível).
    if not info.path or not love.filesystem.getInfo(info.path) then
        print("[MODS] Música registrada '" .. id .. "' aponta pra um arquivo que não existe: " .. tostring(info.path))
        return nil
    end
    local ok, source = pcall(love.audio.newSource, info.path, info.source_type)
    if not ok then
        print("[MODS] Falha ao carregar música '" .. id .. "': " .. tostring(source))
        return nil
    end
    music_source_cache[id] = source
    return source
end

-- ------------------------------------------------------------
-- UTILITÁRIOS DE DEBUG / INTROSPECÇÃO
-- ------------------------------------------------------------

-- Imprime no console um resumo de tudo que está registrado, pra ajudar
-- um autor de mod a debugar conflitos com outros mods.
function ModAPI.debugDump()
    print("========== ModAPI Debug Dump ==========")
    print("Versão da API: " .. ModAPI.VERSION)
    print("Mods carregados: " .. #ModAPI.loaded_mods)
    for _, m in ipairs(ModAPI.loaded_mods) do
        print(string.format("  - [%s] %s v%s por %s%s",
            m.enabled and "ON " or "OFF",
            m.name, tostring(m.version), tostring(m.author),
            m.ok and "" or (" ERRO: " .. tostring(m.error))))
    end
    local n_enemies = 0
    for _ in pairs(ModAPI.Enemy.presets) do n_enemies = n_enemies + 1 end
    print("Tipos de inimigo registrados: " .. n_enemies)
    print("Upgrades na loja: " .. #ModAPI.Rewards.upgrades)
    print("Relíquias na loja: " .. #ModAPI.Rewards.shop_items)
    local n_screens = 0
    for _ in pairs(registered_screens) do n_screens = n_screens + 1 end
    print("Telas customizadas registradas: " .. n_screens)
    print("Músicas no catálogo: " .. #music_catalog_order)
    for event, list in pairs(hooks) do
        print(string.format("  hook '%s': %d callback(s)", event, #list))
    end
    print("========================================")
end

return ModAPI