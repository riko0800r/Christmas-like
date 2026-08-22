-- modloader.lua
-- ================================================================
-- Encontra, carrega e inicializa os mods do jogo.
--
-- Onde ficam os mods:
--   <save_dir>/mods/<nome_da_pasta_do_mod>/mod.lua
-- (save_dir é a pasta que love.filesystem usa pra salvar dados —
--  funciona igual em modo --dev, .love e executável empacotado.
--  No Windows normalmente é %appdata%/LOVE/<nome_do_jogo>/mods/)
--
-- Estrutura mínima de um mod:
--   mods/
--     meu_mod/
--       mod.lua        <- obrigatório
--       outros_arquivos.lua  <- opcional, pode dar require("outros_arquivos")
--                                de dentro do mod.lua
--
-- mod.lua deve retornar uma tabela assim:
--   return {
--       name = "Nome do Mod",
--       version = "1.0",
--       author = "Seu nome",
--       description = "O que esse mod faz, numa frase.", -- opcional, aparece no menu de mods
--       load = function(ModAPI)
--           -- código do mod aqui, usando ModAPI
--       end
--   }
--
-- HABILITAR/DESABILITAR:
-- Mods desabilitados (pelo menu de mods do jogo, ou editando
-- mods_config.json manualmente) são DETECTADOS mas seu mod.lua não é
-- executado — eles aparecem em ModAPI.loaded_mods com ok=false,
-- enabled=false e error=nil, então o menu de mods consegue listá-los,
-- mostrar metadados e permitir religá-los sem precisar reiniciar a
-- busca em disco.
-- ================================================================

local ModLoader = {}

local MODS_DIR = "mods"

local function ensure_mods_dir()
    if not love.filesystem.getInfo(MODS_DIR) then
        love.filesystem.createDirectory(MODS_DIR)
    end
end

-- Lista as subpastas de mods/ que contêm um mod.lua
local function find_mod_folders()
    ensure_mods_dir()
    local folders = {}
    local items = love.filesystem.getDirectoryItems(MODS_DIR)
    for _, item in ipairs(items) do
        local full_path = MODS_DIR .. "/" .. item
        local info = love.filesystem.getInfo(full_path)
        if info and info.type == "directory" then
            local mod_file = full_path .. "/mod.lua"
            if love.filesystem.getInfo(mod_file) then
                table.insert(folders, { id = item, path = full_path, entry = mod_file })
            end
        end
    end
    table.sort(folders, function(a, b) return a.id < b.id end)
    return folders
end

-- Lê só os metadados de um mod.lua (name/version/author/description) SEM
-- executar load(). Usado tanto pra mods desabilitados (que não podem
-- rodar código) quanto como primeira etapa de mods habilitados, então o
-- menu de mods sempre tem nome/versão/autor pra mostrar mesmo se o mod
-- estiver desligado ou se load() falhar.
local function peek_metadata(mod)
    local mounted = love.filesystem.mount(mod.path, "mod_" .. mod.id)
    local meta = { name = mod.id, version = "?", author = "?", description = nil }

    local chunk, load_err = love.filesystem.load(mod.entry)
    if chunk then
        local ok, mod_table_or_err = pcall(chunk)
        if ok and type(mod_table_or_err) == "table" then
            meta.name = mod_table_or_err.name or mod.id
            meta.version = mod_table_or_err.version or "?"
            meta.author = mod_table_or_err.author or "?"
            meta.description = mod_table_or_err.description
            meta.mod_table = mod_table_or_err
        end
    end

    if mounted then
        love.filesystem.unmount(mod.path)
    end
    return meta
end

-- Carrega e roda todos os mods encontrados que estiverem habilitados.
-- Mods desabilitados são listados mas não executados.
-- Retorna a lista de resultados (mesmo formato salvo em ModAPI.loaded_mods).
function ModLoader.load_all()
    local ModAPI = require("modapi")
    _G.ModAPI = ModAPI

    ModAPI.loadModConfig()
    ModAPI.loaded_mods = {}

    local folders = find_mod_folders()

    for _, mod in ipairs(folders) do
        local result = {
            id = mod.id,
            path = mod.path,
            name = mod.id,
            version = "?",
            author = "?",
            description = nil,
            ok = false,
            error = nil,
            enabled = ModAPI.isModEnabled(mod.id),
        }

        if not result.enabled then
            -- Mod desabilitado: só lê metadados pra exibir no menu, não executa nada.
            local meta = peek_metadata(mod)
            result.name = meta.name
            result.version = meta.version
            result.author = meta.author
            result.description = meta.description
            print("[MODS] Pulado (desabilitado): " .. result.name)
        else
            -- Monta a pasta do mod no sistema de arquivos do LÖVE para que
            -- require("arquivo_do_mesmo_mod") funcione de dentro do mod.lua.
            local mounted = love.filesystem.mount(mod.path, "mod_" .. mod.id)

            local chunk, load_err = love.filesystem.load(mod.entry)
            if not chunk then
                result.error = "Erro ao carregar mod.lua: " .. tostring(load_err)
                print("[MODS] " .. result.error .. " (" .. mod.id .. ")")
            else
                local ok, mod_table_or_err = pcall(chunk)
                if not ok then
                    result.error = "Erro ao executar mod.lua: " .. tostring(mod_table_or_err)
                    print("[MODS] " .. result.error .. " (" .. mod.id .. ")")
                elseif type(mod_table_or_err) ~= "table" then
                    result.error = "mod.lua não retornou uma tabela"
                    print("[MODS] " .. result.error .. " (" .. mod.id .. ")")
                else
                    local mod_table = mod_table_or_err
                    result.name = mod_table.name or mod.id
                    result.version = mod_table.version or "?"
                    result.author = mod_table.author or "?"
                    result.description = mod_table.description

                    if type(mod_table.load) == "function" then
                        -- Marca qual mod está carregando agora, pra ModAPI.on
                        -- conseguir atribuir "owner" automaticamente aos hooks
                        -- registrados dentro deste load(), sem o autor do mod
                        -- precisar passar owner=... manualmente toda vez.
                        ModAPI._current_loading_mod = mod.id
                        local run_ok, run_err = pcall(mod_table.load, ModAPI)
                        ModAPI._current_loading_mod = nil
                        if run_ok then
                            result.ok = true
                        else
                            result.error = "Erro em load(): " .. tostring(run_err)
                            print("[MODS] " .. result.error .. " (" .. mod.id .. ")")
                        end
                    else
                        -- Mod sem função load() é considerado só metadata/dados, sem código ativo.
                        result.ok = true
                    end
                end
            end

            if mounted then
                love.filesystem.unmount(mod.path)
            end
        end

        table.insert(ModAPI.loaded_mods, result)
        if result.ok then
            print("[MODS] Carregado: " .. result.name .. " v" .. tostring(result.version))
        end
    end

    ModAPI.trigger("mods_ready")

    return ModAPI.loaded_mods
end

-- Recarrega tudo do zero: reseta hooks/registros feitos por mods não é
-- possível de forma totalmente segura em tempo de execução (inimigos,
-- upgrades e textos registrados ficariam "sujos"), então ModLoader.reload
-- NÃO existe de propósito. Habilitar/desabilitar um mod pelo menu tem
-- efeito garantido apenas reiniciando o jogo; ModAPI.disableMod ainda
-- assim desliga os hooks daquele mod imediatamente, então o efeito
-- prático de um mod malicioso/quebrado já para na hora.

return ModLoader