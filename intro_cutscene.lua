-- intro_cutscene.lua
-- ================================================================
-- Cutscene de abertura: gameplay REAL rodando ao vivo no fundo (não
-- é vídeo/gif pré-gravado — LÖVE só suporta .ogv, então em vez disso
-- simulamos uma "luta" de verdade usando os próprios sistemas do
-- jogo: Enemies.spawn_enemy/update/draw + um Player fantasma).
--
-- O "fantasma" é um Player.new() de verdade, para que toda a IA de
-- enemies.lua funcione sem gambiarra (ela lê _G.player internamente
-- em vários pontos). Ele é:
--   - invencível (Player:takeHit vira no-op quando self.invencible)
--   - VISÍVEL (chamamos ghost:draw() normalmente — ele é o
--     "personagem" da cutscene, o jogo de verdade sendo mostrado)
--   - andarilho automático (self.joystick = true + dx/dy trocados
--     por uma IA simples de wandering com uma "coleira" pro centro,
--     então Player:update usa esse vetor em vez de ler o teclado real
--     do usuário, e ele não sai da área visível pela câmera com zoom)
--
-- A cena é renderizada num Canvas do tamanho do mundo do jogo
-- (512x256, igual ao gameplay real) com uma câmera com zoom
-- (CAMERA_ZOOM) aplicada via scale/translate, e depois desenhada
-- esticada dentro da moldura da cutscene — assim toda a lógica de
-- colisão/clamp de enemies.lua (que assume esse espaço 512x256)
-- funciona sem mexer em nada do enemies.lua; só a "moldura" de
-- captura dentro desse mundo é que fica menor, dando a sensação de
-- câmera mais perto da ação, como um gameplay normal com zoom.
--
-- Uso (de main.lua):
--   local IntroCutscene = require("intro_cutscene")
--   IntroCutscene.load()                 -- uma vez, no love.load()
--   IntroCutscene.enter()                -- toda vez que entrar no estado "intro"
--   IntroCutscene.update(dt)             -- dentro de love.update quando state == "intro"
--   IntroCutscene.draw()                 -- dentro do draw quando state == "intro"
--   IntroCutscene.is_finished()          -- true quando a timeline acabou
--   IntroCutscene.skip()                 -- pula pro fim (botão "pular")
--   IntroCutscene.leave()                -- ao sair da intro, limpa tudo
-- ================================================================

local Utils = require("utils")
local Lang = require("lang")
local Player = require("player")
local Enemies = require("enemies")

-- LÖVE embute a lib padrão "utf8" (Lua 5.3+). Usamos ela pra nunca
-- cortar string no meio de um caractere acentuado (é, ê, ã, ç...):
-- esses caracteres ocupam 2+ bytes em UTF-8, e #text / text:sub()
-- do Lua operam em BYTES, não em caracteres — cortar "no meio" de um
-- byte multibyte produz um caractere inválido que a fonte desenha
-- como "?" ou lixo. Por isso o typewriter conta/corta por posição de
-- caractere UTF-8 (via utf8.offset), nunca por índice de byte cru.
local utf8 = require("utf8")

-- Quebra uma string em uma lista de "caracteres visuais" UTF-8 (cada
-- item pode ter 1 a 4 bytes). Usada pra contar/revelar/cortar texto
-- caractere por caractere sem quebrar acentos.
local function utf8_chars(text)
    local chars = {}
    local ok = pcall(function()
        for _, code in utf8.codes(text) do
            table.insert(chars, utf8.char(code))
        end
    end)
    if not ok then
        -- Fallback improvável (string não é UTF-8 válido): trata por
        -- byte mesmo, pra nunca travar a cutscene por causa disso.
        chars = {}
        for i = 1, #text do table.insert(chars, text:sub(i, i)) end
    end
    return chars
end

local IntroCutscene = {}

-- ------------------------------------------------------------------
-- TIMELINE: cada "cena" tem uma duração (segundos) e uma chave de
-- legenda no Lang. Mods/tradutores só precisam mexer no lang.lua.
-- ------------------------------------------------------------------
local SCENES = {
    { key = "intro_1", duration = 4.5 },
    { key = "intro_2", duration = 4.5 },
    { key = "intro_3", duration = 4.5 },
    { key = "intro_4", duration = 5.0 },
}

local TOTAL_DURATION = 0
for _, s in ipairs(SCENES) do TOTAL_DURATION = TOTAL_DURATION + s.duration end

-- Espaço de mundo em que enemies.lua faz clamp/física (ver
-- update_enemy: clamp(0,x,512) / clamp(0,y,256)). É sempre esse
-- tamanho fixo, não depende da resolução real da janela. A cena
-- ocupa a tela INTEIRA (é o background, não uma moldura de vídeo).
local WORLD_W, WORLD_H = 512, 256
local SCREEN_W, SCREEN_H = WORLD_W, WORLD_H

-- Zoom da câmera da cutscene: >1 "aproxima" a cena (mostra menos
-- área de mundo, tudo maior na tela), como um gameplay normal só
-- que com a câmera mais perto da ação. O canvas continua sendo
-- WORLD_W x WORLD_H (enemies.lua não muda em nada, o clamp/física
-- continuam no espaço 512x256 de sempre); só a MOLDURA de captura
-- dentro desse mundo fica menor (WORLD_W/zoom x WORLD_H/zoom) e
-- depois é esticada pra preencher o canvas inteiro.
local CAMERA_ZOOM = 1.6

-- Escurece a batalha de fundo (overlay preto semi-transparente sobre
-- TODO o canvas, depois de já ter desenhado parallax/inimigos/
-- fantasma) pra dar mais foco visual à legenda por cima. 0 = sem
-- escurecimento, 1 = tela preta total. A batalha continua acontecendo
-- de verdade (é o mesmo gameplay ao vivo de sempre); só fica mais
-- discreta visualmente.
local BATTLE_DIM_ALPHA = 0.55

-- Parallax de fundo (mesmas imagens do gameplay real, ver
-- background_layers em main.lua). Carregado sob demanda em
-- IntroCutscene.load(), com pcall pra nunca derrubar a intro se
-- algum asset estiver faltando (cai pro fundo sólido antigo).
local BG_LAYERS = {
    { image = nil, speed = 0.15, path = "assets/Mapa4.png" },
    { image = nil, speed = 0.10, path = "assets/Mapa3.png" },
    { image = nil, speed = 0.25, path = "assets/Mapa2.png" },
    { image = nil, speed = 0.45, path = "assets/Mapa.png" },
}
local bg_scroll = 0

-- Faixa de legenda: sobreposta por cima do gameplay, na parte de
-- baixo da tela, com fundo semi-transparente.
local CAPTION_BAR_H = 34
local CAPTION_Y = SCREEN_H - CAPTION_BAR_H

-- Efeito "máquina de escrever" na legenda: revela um caractere por
-- vez num ritmo fixo, com um barulhinho de tecla a cada letra nova.
-- Reaproveitamos SFX_select (já carregado globalmente por main.lua)
-- em vez de pedir um asset novo — é um blip curto de menu, então
-- funciona bem como "clique de tecla" sem precisar de som dedicado.
local TYPEWRITER_CHARS_PER_SEC = 28
local typewriter_scene_index = nil   -- última cena em que o typewriter tocou (pra detectar troca de cena)
local typewriter_chars_shown = 0     -- quantos caracteres da legenda atual já foram revelados
local typewriter_char_accum = 0      -- acumulador de tempo fracionário entre um caractere e o próximo

-- Cor de destaque da legenda: amarelo vivo (índice 10 da paleta
-- PICO-8, ver Utils.pico8_colors), bem mais chamativo que o cinza
-- claro (7) usado antes — só o TEXTO fica destacado, o resto da
-- cutscene (o "gameplay ao vivo" atrás) continua como estava.
local CAPTION_COLOR = { 255/255, 236/255, 39/255 }
local CAPTION_FLASH_COLOR = { 1, 1, 1 } -- branco: pico de brilho a cada letra digitada

-- "Pulso de brilho": a cada letra nova revelada, a cor da legenda dá
-- um flash em direção a CAPTION_FLASH_COLOR e decai de volta pra
-- CAPTION_COLOR ao longo de TYPEWRITER_FLASH_DECAY segundos. Isso é
-- puramente visual, não interfere na revelação/contagem de caracteres.
local TYPEWRITER_FLASH_DECAY = 0.12
local typewriter_flash = 0 -- 1 = pico do brilho (letra acabou de aparecer), 0 = cor normal

IntroCutscene.elapsed = 0
IntroCutscene.finished = false

local anim_t = 0
local canvas = nil -- render target do tamanho do mundo (WORLD_W x WORLD_H)

-- ------------------------------------------------------------------
-- PLAYER FANTASMA
-- ------------------------------------------------------------------
-- Guardamos o player/estado "reais" (se o usuário tiver uma run
-- salva em andamento, save.lua ainda não a restaurou nesse ponto,
-- mas por segurança nunca deixamos o fantasma vazar para fora da
-- intro: ao sair, restauramos _G.player e limpamos os inimigos).
local ghost = nil
local previous_global_player = nil
local wander_timer = 0

local function new_ghost_player()
    local p = Player.new()

    -- Player.new() deixa tipo_jogador = 0, que só existe depois que o
    -- jogador passa pela tela de seleção de personagem (Characters.apply
    -- seta um id 1..13 e chama Characters.load, que popula player.sprite
    -- só a partir do índice 1 — ver characters.lua). O fantasma nunca
    -- passa por essa tela, então sem isso player.sprite[0] é nil e
    -- Player:draw quebra ao tentar desenhar o Quad. Aplicamos o primeiro
    -- personagem da lista pra garantir sprite/tipo_jogador válidos, ANTES
    -- de setar as flags de fantasma abaixo (assim nada que apply() faça
    -- pode sobrescrever invencibilidade/vida infinita/posição).
    local Characters = require("characters")
    if Characters.list and Characters.list[1] and Characters.list[1].apply then
        Characters.list[1].apply(p)
    else
        p.tipo_jogador = 1
    end
    Characters.load(p)

    p.invencible = true          -- Player:takeHit vira no-op (ver player.lua)
    p.joystick = true            -- faz Player:update usar p.dx/p.dy em vez do teclado
    p.lifes = math.huge
    p.max_life = math.huge
    p.dx, p.dy = 0, 0
    p.x = WORLD_W / 2
    p.y = WORLD_H / 2
    return p
end

-- IA de "wandering": troca de direção periodicamente pra dar a
-- sensação de gameplay real (fugindo/esquivando dos inimigos), sem
-- precisar de pathfinding de verdade — é só pra ambientação visual.
--
-- Com o zoom da câmera (CAMERA_ZOOM > 1) a moldura visível é menor
-- que o mundo inteiro, então mantemos o fantasma perto do centro
-- pra ele não sair de quadro: se ele se afastar demais do meio do
-- mundo, a escolha de ângulo é puxada de volta pro centro em vez de
-- ser totalmente aleatória.
local function update_ghost_ai(dt)
    if not ghost then return end
    wander_timer = wander_timer - dt
    if wander_timer <= 0 then
        wander_timer = 0.5 + math.random() * 0.9
        local angle = math.random() * math.pi * 2

        local cx, cy = WORLD_W / 2, WORLD_H / 2
        local to_center_x, to_center_y = cx - ghost.x, cy - ghost.y
        local dist_from_center = math.sqrt(to_center_x^2 + to_center_y^2)
        local leash = math.min(WORLD_W, WORLD_H) / CAMERA_ZOOM * 0.35

        if dist_from_center > leash then
            -- Fora da coleira: mira de volta pro centro (com uma pitada
            -- de variação, pra não ficar um trajeto reto/robótico).
            angle = math.atan2(to_center_y, to_center_x) + (math.random() - 0.5) * 1.2
        end

        ghost.dx = math.cos(angle)
        ghost.dy = math.sin(angle)
    end
end

-- ------------------------------------------------------------------
-- SPAWN CONTÍNUO (simplificado, sem depender de wave.lua)
-- ------------------------------------------------------------------
local ENEMY_TYPES = {
    "perseguidor", "atirador", "circulador", "divisor",
    "horizontal", "paladino", "vampiro",
}
local MAX_ACTIVE_ENEMIES = 10
local SPAWN_INTERVAL = 0.9
local spawn_timer = 0

-- "Waves" falso: só precisa expor current_wave, que spawn_enemy usa
-- pra escalar HP/dano/velocidade. Mantemos baixo e fixo pra a cena
-- ficar legível (inimigos não tankam demais nem oneshotam nada,
-- já que o fantasma é invencível de qualquer forma).
local fake_waves = { current_wave = 2 }

local function spawn_random_enemy()
    local tipo = ENEMY_TYPES[math.random(#ENEMY_TYPES)]
    local x = math.random(24, WORLD_W - 24)
    local y = math.random(24, WORLD_H - 24)
    Enemies.spawn_enemy(tipo, x, y, fake_waves)
end

local function update_spawner(dt)
    spawn_timer = spawn_timer - dt
    if spawn_timer <= 0 then
        spawn_timer = SPAWN_INTERVAL
        if #Enemies.get_all() < MAX_ACTIVE_ENEMIES then
            spawn_random_enemy()
        end
    end
end

-- ------------------------------------------------------------------
-- LEGENDA / EFEITO MÁQUINA DE ESCREVER
-- ------------------------------------------------------------------

-- Retorna: legenda atual (texto completo, já passado por
-- Utils.safeText — ver utils.lua — sem cortar), progresso (0-1)
-- dentro da cena atual, índice da cena, total de cenas.
--
-- IMPORTANTE: safeText é aplicado UMA ÚNICA VEZ aqui, na origem, e
-- todo o resto do pipeline do typewriter (update_typewriter,
-- skip_typewriter, wrap_caption, draw) usa esse mesmo texto já limpo.
-- Chamar safeText de novo em cada um desses pontos seria redundante
-- e arriscaria produzir resultados levemente diferentes entre si ao
-- longo do frame.
local function current_scene_info()
    local t = IntroCutscene.elapsed
    for i, s in ipairs(SCENES) do
        if t < s.duration or i == #SCENES then
            local progress = math.min(1, t / s.duration)
            return Utils.safeText(Lang.text(s.key)), progress, i, #SCENES
        end
        t = t - s.duration
    end
    return "", 1, #SCENES, #SCENES
end

-- Toca o "clique de tecla" do typewriter. Clona SFX_select pra poder
-- sobrepor com o resto do jogo sem cortar/roubar o source original
-- (o mesmo SFX_select que os menus usam), e varia pitch levemente a
-- cada letra pra não soar metronômico/robótico.
local function play_typewriter_blip()
    if not SFX_select then return end
    local ok, blip = pcall(SFX_select.clone, SFX_select)
    if not ok or not blip then return end
    blip:setPitch(1.7 + math.random() * 0.5)
    blip:setVolume((SFX_select:getVolume() or 1) * 0.5)
    blip:play()
end

-- Avança quantos caracteres da legenda atual já estão "digitados".
-- Roda em update(dt) (não em draw) pra o ritmo não depender de
-- framerate de desenho. Detecta troca de cena comparando o índice
-- retornado por current_scene_info e reinicia a contagem do zero.
local function update_typewriter(dt)
    local full_text, _progress, scene_index = current_scene_info()

    if scene_index ~= typewriter_scene_index then
        typewriter_scene_index = scene_index
        typewriter_chars_shown = 0
        typewriter_char_accum = 0
    end

    local chars = utf8_chars(full_text)
    local total_chars = #chars
    if typewriter_chars_shown >= total_chars then return end

    typewriter_char_accum = typewriter_char_accum + dt * TYPEWRITER_CHARS_PER_SEC
    while typewriter_char_accum >= 1 and typewriter_chars_shown < total_chars do
        typewriter_char_accum = typewriter_char_accum - 1
        typewriter_chars_shown = typewriter_chars_shown + 1

        -- Sem barulhinho pra espaço (tecla "muda"), só pra caracteres visíveis.
        local revealed_char = chars[typewriter_chars_shown]
        if revealed_char and revealed_char ~= " " then
            play_typewriter_blip()
            typewriter_flash = 1 -- pico do brilho: decai sozinho em IntroCutscene.update
        end
    end
end

-- Revela a legenda inteira de uma vez, sem tocar nenhum barulhinho
-- (usado pelo skip, pra não disparar uma rajada de sons de tecla).
local function skip_typewriter()
    local full_text, _progress, scene_index = current_scene_info()
    typewriter_scene_index = scene_index
    typewriter_chars_shown = #utf8_chars(full_text)
    typewriter_char_accum = 0
end

function IntroCutscene.load()
    local ok_canvas, made_canvas = pcall(love.graphics.newCanvas, WORLD_W, WORLD_H)
    if ok_canvas then canvas = made_canvas end

    -- Mesmo parallax do gameplay real (ver background_layers em
    -- main.lua). pcall por imagem: se uma faltar, as outras camadas
    -- continuam funcionando e draw_fallback_bg cobre o resto com o
    -- fundo sólido de sempre.
    for _, layer in ipairs(BG_LAYERS) do
        local ok_img, img = pcall(love.graphics.newImage, layer.path)
        if ok_img then layer.image = img end
    end
end

function IntroCutscene.enter()
    IntroCutscene.elapsed = 0
    IntroCutscene.finished = false
    anim_t = 0
    spawn_timer = 0
    wander_timer = 0
    typewriter_scene_index = nil
    typewriter_chars_shown = 0
    typewriter_char_accum = 0
    typewriter_flash = 0

    -- Guarda o player global real (se existir) pra restaurar depois,
    -- e troca por um fantasma só durante a cutscene.
    previous_global_player = _G.player
    ghost = new_ghost_player()
    _G.player = ghost

    Enemies.reset()
    -- Alguns inimigos já em cena desde o início, pra não começar vazio.
    for i = 1, 4 do spawn_random_enemy() end
end

-- Deve ser chamado ao sair do estado "intro" (main.lua cuida disso),
-- pra nunca deixar o fantasma ou os inimigos da cutscene vazarem
-- para uma partida real.
function IntroCutscene.leave()
    Enemies.reset()
    _G.player = previous_global_player
    ghost = nil
end

function IntroCutscene.skip()
    IntroCutscene.elapsed = TOTAL_DURATION
    IntroCutscene.finished = true
    skip_typewriter()
end

function IntroCutscene.is_finished()
    return IntroCutscene.finished
end

function IntroCutscene.update(dt)
    anim_t = anim_t + dt
    IntroCutscene.elapsed = IntroCutscene.elapsed + dt
    if IntroCutscene.elapsed >= TOTAL_DURATION then
        IntroCutscene.elapsed = TOTAL_DURATION
        IntroCutscene.finished = true
    end

    update_typewriter(dt)

    -- Decaimento do "pulso de brilho" da legenda (ver typewriter_flash
    -- acima): sempre roda, mesmo em frames sem letra nova, senão o
    -- flash "prenderia" no pico assim que uma letra aparecesse e nunca
    -- voltaria pra cor normal.
    if typewriter_flash > 0 then
        typewriter_flash = math.max(0, typewriter_flash - dt / TYPEWRITER_FLASH_DECAY)
    end

    if ghost then
        update_ghost_ai(dt)
        update_spawner(dt)
        Enemies.update(dt, ghost)
        ghost:update(dt, Enemies.get_all(), 0)
        -- Parallax segue o fantasma (mesma ideia de speed*deslocamento
        -- do jogo real), pra a rolagem reagir ao "gameplay" ao vivo em
        -- vez de ser um scroll autônomo desligado da ação.
        bg_scroll = ghost.x
    end
end

-- ------------------------------------------------------------------
-- DESENHO
-- ------------------------------------------------------------------

local function draw_rec_indicator()
    -- "REC" piscando no canto, reforça que isso é gameplay ao vivo (não uma imagem estática).
    if math.floor(anim_t * 2) % 2 == 0 then
        Utils.setColor(0)
        love.graphics.rectangle("fill", 4, 3, 44, 12)
        Utils.setColor(8)
        love.graphics.circle("fill", 10, 9, 3)
        Utils.setColor(7)
        love.graphics.print("REC", 17, 4)
    end
end

-- Fallback caso algum asset de parallax não carregue: mesmo céu
-- noturno "de emergência" de antes, só usado atrás das camadas que
-- falharem (ver draw_parallax_bg).
local function draw_fallback_bg()
    Utils.setColor(1)
    love.graphics.rectangle("fill", 0, 0, WORLD_W, WORLD_H)
    Utils.setColor(129)
    love.graphics.rectangle("fill", 0, WORLD_H - 40, WORLD_W, 40)
    Utils.setColor(7)
    for i = 1, 24 do
        local sx = (i * 37) % WORLD_W
        local sy = (i * 53) % (WORLD_H - 60)
        love.graphics.points(sx, sy)
    end
end

-- Parallax igual ao do gameplay real (mesmas imagens/velocidades de
-- background_layers em main.lua), só que a rolagem aqui é orientada
-- pelo tempo da cutscene em vez de seguir a câmera de uma run real
-- — dá o mesmo "clima" do jogo sem precisar do estado de uma partida.
local function draw_parallax_bg()
    local any_loaded = false
    Utils.setColor(7)
    for _, layer in ipairs(BG_LAYERS) do
        if layer.image then
            any_loaded = true
            local img = layer.image
            local w = img:getWidth()
            local layer_x = -(bg_scroll * layer.speed) % w
            for i = -1, math.ceil(WORLD_W / w) + 1 do
                love.graphics.draw(img, layer_x + i * w, 0)
            end
        end
    end
    if not any_loaded then
        draw_fallback_bg()
    end
end

-- Calcula o canto superior-esquerdo (em coordenadas de MUNDO) da
-- moldura de câmera com zoom, centrada no fantasma e clampada pra
-- nunca mostrar área fora do mundo 512x256 (senão a câmera "vê" além
-- da borda onde nada é desenhado).
local function get_camera_offset()
    local view_w = WORLD_W / CAMERA_ZOOM
    local view_h = WORLD_H / CAMERA_ZOOM

    local target_x, target_y = WORLD_W / 2, WORLD_H / 2
    if ghost then target_x, target_y = ghost.x, ghost.y end

    local cam_x = Utils.clamp(0, target_x - view_w / 2, WORLD_W - view_w)
    local cam_y = Utils.clamp(0, target_y - view_h / 2, WORLD_H - view_h)
    return cam_x, cam_y, view_w, view_h
end

-- Renderiza um frame de gameplay real (fundo com parallax + player
-- fantasma visível + inimigos) dentro do canvas do tamanho do mundo,
-- com uma câmera com zoom aplicada via translate/scale, e depois
-- desenha esse canvas esticado na moldura da cutscene. Isso é
-- gameplay ao vivo, não uma animação simulada: os mesmos
-- enemies.lua/spawn_enemy e o Player:draw() que rodam numa partida
-- normal estão rodando aqui — só vistos de mais perto (zoom).
local function draw_live_gameplay()
    local cam_x, cam_y = get_camera_offset()

    if not canvas then
        -- Fallback raro (canvas não suportado): desenha direto na
        -- tela, sem passar pelo canvas intermediário nem zoom (evita
        -- mexer no transform global fora de um canvas dedicado).
        draw_parallax_bg()
        Enemies.draw()
        if ghost then ghost:draw() end
        -- Mesmo escurecimento do caminho com canvas (ver abaixo),
        -- aplicado direto na tela já que não há canvas intermediário aqui.
        love.graphics.setColor(0, 0, 0, BATTLE_DIM_ALPHA)
        love.graphics.rectangle("fill", 0, 0, SCREEN_W, SCREEN_H)
        return
    end

    -- IMPORTANTE: o jogo já desenha tudo dentro do canvas interno da
    -- lib Push (resolução virtual 512x256 escalada pra janela real).
    -- Se a gente trocar de canvas com love.graphics.setCanvas(canvas)
    -- e depois voltar com setCanvas() (sem argumento), isso NÃO volta
    -- pro canvas do Push — volta pro framebuffer da janela, perdendo
    -- o resto do frame e deixando a tela preta/errada. Por isso
    -- guardamos o canvas ativo no momento e restauramos ele, não "o
    -- padrão".
    local previous_canvas = love.graphics.getCanvas()

    love.graphics.setCanvas(canvas)
    love.graphics.clear(0, 0, 0, 0)

    -- Câmera com zoom: escala tudo por CAMERA_ZOOM e desloca pelo
    -- canto da moldura calculada em get_camera_offset, assim o que é
    -- desenhado em coordenadas de mundo (0..512, 0..256) aparece
    -- "aproximado" e seguindo o fantasma, igual uma câmera de jogo
    -- normal — enemies.lua e Player:draw() continuam desenhando em
    -- coordenadas de mundo sem saber que há zoom.
    love.graphics.push()
    love.graphics.scale(CAMERA_ZOOM, CAMERA_ZOOM)
    love.graphics.translate(-cam_x, -cam_y)

    draw_parallax_bg()
    Enemies.draw() -- inimigos reais, corações/moedas soltos, healthbar de boss

    if ghost then ghost:draw() end -- agora visível: é o "personagem" da cutscene

    love.graphics.pop()

    -- Escurece a batalha inteira (overlay preto semi-transparente
    -- sobre o canvas já renderizado), pra dar foco visual ao texto
    -- que vem por cima. Aplicado FORA do push/pop com zoom de
    -- propósito: queremos um véu uniforme cobrindo o frame inteiro
    -- em coordenadas de tela, não algo que escale/desloque junto com
    -- a câmera.
    love.graphics.setColor(0, 0, 0, BATTLE_DIM_ALPHA)
    love.graphics.rectangle("fill", 0, 0, WORLD_W, WORLD_H)

    love.graphics.setCanvas(previous_canvas)

    Utils.setColor(7)
    love.graphics.draw(canvas, 0, 0)
end

-- Quebra a legenda em até 2 linhas pra caber na largura da moldura,
-- já que algumas traduções (ex.: inglês) passam do que uma linha
-- de 8px por caractere aguenta em 512px de tela.
local MAX_CHARS_PER_LINE = math.floor((SCREEN_W - 16) / 8)

local function wrap_caption(text)
    if #text <= MAX_CHARS_PER_LINE then
        return { text }
    end

    local words = {}
    for w in text:gmatch("%S+") do table.insert(words, w) end

    local lines, current = {}, ""
    for _, word in ipairs(words) do
        local candidate = (current == "") and word or (current .. " " .. word)
        if #candidate > MAX_CHARS_PER_LINE and current ~= "" then
            table.insert(lines, current)
            current = word
        else
            current = candidate
        end
    end
    if current ~= "" then table.insert(lines, current) end

    -- Cutscene é ritmada por legendas curtas; 2 linhas é o teto visual da barra.
    if #lines > 2 then
        local merged = { lines[1] }
        for i = 2, #lines do merged[2] = (merged[2] and (merged[2] .. " ") or "") .. lines[i] end
        lines = merged
    end
    return lines
end

-- Corta uma lista de linhas já quebradas (ver wrap_caption) nos
-- primeiros `char_count` CARACTERES UTF-8 (não bytes — ver utf8_chars
-- no topo do arquivo), preservando a MESMA quebra de linha do texto
-- completo — essencial pro efeito de máquina de escrever: se
-- recalculássemos o wrap a cada caractere revelado, uma palavra
-- poderia "pular" da linha 1 pra linha 2 no meio da digitação. Em vez
-- disso, sempre quebramos o texto inteiro uma vez e só depois vamos
-- "descobrindo" caracteres dentro dessa quebra já fixada.
local function truncate_wrapped_lines(lines, char_count)
    local out = {}
    local remaining = char_count
    for i, line in ipairs(lines) do
        local line_chars = utf8_chars(line)
        local line_len = #line_chars
        if remaining <= 0 then
            out[i] = ""
        elseif remaining >= line_len then
            out[i] = line
            remaining = remaining - line_len
            -- Espaço "virtual" entre linhas (equivalente ao espaço que
            -- existiria entre as palavras se não tivesse quebrado aqui).
            if i < #lines then remaining = remaining - 1 end
        else
            out[i] = table.concat(line_chars, "", 1, remaining)
            remaining = 0
        end
    end
    return out
end

local function draw_caption_bar(caption, scene_index, scene_total, chars_shown, fully_revealed)
    -- Faixa semi-transparente sobreposta ao gameplay (overlay, não
    -- uma barra sólida que "corta" a cena real que está rodando atrás).
    love.graphics.setColor(0, 0, 0, 0.72)
    love.graphics.rectangle("fill", 0, CAPTION_Y, SCREEN_W, CAPTION_BAR_H)

    -- Cor do TEXTO da legenda: amarelo chamativo (CAPTION_COLOR),
    -- com um pulso de brilho puxando pra branco (CAPTION_FLASH_COLOR)
    -- logo depois de cada letra revelada (typewriter_flash decai em
    -- IntroCutscene.update). Só afeta a cor do texto — o resto da
    -- cena (gameplay, REC, timeline) continua com as cores de sempre.
    local flash = typewriter_flash
    love.graphics.setColor(
        CAPTION_COLOR[1] + (CAPTION_FLASH_COLOR[1] - CAPTION_COLOR[1]) * flash,
        CAPTION_COLOR[2] + (CAPTION_FLASH_COLOR[2] - CAPTION_COLOR[2]) * flash,
        CAPTION_COLOR[3] + (CAPTION_FLASH_COLOR[3] - CAPTION_COLOR[3]) * flash,
        1
    )

    -- `caption` já vem filtrado por Utils.safeText desde current_scene_info
    -- (aplicado uma única vez, na origem — ver comentário lá).
    local full_lines = wrap_caption(caption)
    local lines = truncate_wrapped_lines(full_lines, chars_shown)

    -- Cursor piscante no fim do texto ainda sendo "digitado" — some
    -- assim que a legenda termina de revelar, pra não ficar piscando
    -- parado em cima do texto completo até a cena trocar.
    if not fully_revealed and #lines > 0 and math.floor(anim_t * 4) % 2 == 0 then
        lines[#lines] = lines[#lines] .. "_"
    end

    -- Utils.centerText só faz love.graphics.print (não mexe na cor
    -- ativa), então a cor setada acima continua valendo pras duas
    -- chamadas abaixo.
    if #lines <= 1 then
        Utils.centerText(lines[1] or "", CAPTION_Y + 9, true)
    else
        Utils.centerText(lines[1], CAPTION_Y + 3, true)
        Utils.centerText(lines[2] or "", CAPTION_Y + 13, true)
    end

    -- Timeline geral (barra de progresso da cutscene inteira)
    local bar_x, bar_y = 0, CAPTION_Y + CAPTION_BAR_H - 4
    local bar_w = SCREEN_W
    Utils.setColor(5)
    love.graphics.rectangle("fill", bar_x, bar_y, bar_w, 3)
    Utils.setColor(11)
    local total_progress = math.min(1, IntroCutscene.elapsed / TOTAL_DURATION)
    love.graphics.rectangle("fill", bar_x, bar_y, bar_w * total_progress, 3)

    -- Marcadores de cena (um "capítulo" por legenda), pra sensação de timeline editada
    Utils.setColor(9)
    local acc = 0
    for i, s in ipairs(SCENES) do
        acc = acc + s.duration
        local mark_x = bar_x + bar_w * math.min(1, acc / TOTAL_DURATION)
        if i < scene_total then
            love.graphics.rectangle("fill", mark_x - 1, bar_y - 1, 2, 5)
        end
    end
end

function IntroCutscene.draw()
    draw_live_gameplay()
    draw_rec_indicator()

    -- `caption` já vem filtrado por Utils.safeText desde current_scene_info.
    local caption, _progress, scene_index, scene_total = current_scene_info()
    local total_chars = #utf8_chars(caption)
    local fully_revealed = typewriter_chars_shown >= total_chars
    draw_caption_bar(caption, scene_index, scene_total, typewriter_chars_shown, fully_revealed)
end

return IntroCutscene