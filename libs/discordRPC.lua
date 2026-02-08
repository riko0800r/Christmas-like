-- ===================================================================
-- DISCORD RPC CORRIGIDO - Sem conflitos FFI
-- Substitua seu libs/discordRPC.lua com este arquivo
-- ===================================================================

local ffi = require "ffi"

-- Verifica se as estruturas FFI já foram definidas
if not pcall(function() return ffi.typeof("DiscordRichPresence") end) then
    ffi.cdef[[
    typedef struct DiscordRichPresence {
        const char* state;
        const char* details;
        int64_t startTimestamp;
        int64_t endTimestamp;
        const char* largeImageKey;
        const char* largeImageText;
        const char* smallImageKey;
        const char* smallImageText;
        const char* partyId;
        int partySize;
        int partyMax;
        const char* matchSecret;
        const char* joinSecret;
        const char* spectateSecret;
        int8_t instance;
    } DiscordRichPresence;

    typedef struct DiscordUser {
        const char* userId;
        const char* username;
        const char* discriminator;
        const char* avatar;
    } DiscordUser;

    typedef void (*readyPtr)(const DiscordUser* request);
    typedef void (*disconnectedPtr)(int errorCode, const char* message);
    typedef void (*erroredPtr)(int errorCode, const char* message);
    typedef void (*joinGamePtr)(const char* joinSecret);
    typedef void (*spectateGamePtr)(const char* spectateSecret);
    typedef void (*joinRequestPtr)(const DiscordUser* request);

    typedef struct DiscordEventHandlers {
        readyPtr ready;
        disconnectedPtr disconnected;
        erroredPtr errored;
        joinGamePtr joinGame;
        spectateGamePtr spectateGame;
        joinRequestPtr joinRequest;
    } DiscordEventHandlers;

    void Discord_Initialize(const char* applicationId,
                            DiscordEventHandlers* handlers,
                            int autoRegister,
                            const char* optionalSteamId);

    void Discord_Shutdown(void);
    void Discord_RunCallbacks(void);
    void Discord_UpdatePresence(const DiscordRichPresence* presence);
    void Discord_ClearPresence(void);
    void Discord_Respond(const char* userid, int reply);
    void Discord_UpdateHandlers(DiscordEventHandlers* handlers);
    ]]
end

local discordRPC = {}

-- Tenta carregar a DLL
local discordRPClib = nil
local function load_dll()
    local success, result = pcall(function()
        return ffi.load("discord-rpc")
    end)
    return success and result or nil
end

discordRPClib = load_dll()

if discordRPClib then
    print("✅ Discord RPC DLL carregado com sucesso!")
else
    print("⚠️ Discord RPC DLL não encontrado. Funcionalidade limitada.")
end

-- proxy to detect garbage collection of the module
discordRPC.gcDummy = newproxy(true)

local function unpackDiscordUser(request)
    return ffi.string(request.userId), ffi.string(request.username),
        ffi.string(request.discriminator), ffi.string(request.avatar)
end

-- callback proxies
local ready_proxy = ffi.cast("readyPtr", function(request)
    if discordRPC.ready then
        discordRPC.ready(unpackDiscordUser(request))
    end
end)

local disconnected_proxy = ffi.cast("disconnectedPtr", function(errorCode, message)
    if discordRPC.disconnected then
        discordRPC.disconnected(errorCode, ffi.string(message))
    end
end)

local errored_proxy = ffi.cast("erroredPtr", function(errorCode, message)
    if discordRPC.errored then
        discordRPC.errored(errorCode, ffi.string(message))
    end
end)

local joinGame_proxy = ffi.cast("joinGamePtr", function(joinSecret)
    if discordRPC.joinGame then
        discordRPC.joinGame(ffi.string(joinSecret))
    end
end)

local spectateGame_proxy = ffi.cast("spectateGamePtr", function(spectateSecret)
    if discordRPC.spectateGame then
        discordRPC.spectateGame(ffi.string(spectateSecret))
    end
end)

local joinRequest_proxy = ffi.cast("joinRequestPtr", function(request)
    if discordRPC.joinRequest then
        discordRPC.joinRequest(unpackDiscordUser(request))
    end
end)

-- helpers
local function checkArg(arg, argType, argName, func, maybeNil)
    assert(type(arg) == argType or (maybeNil and arg == nil),
        string.format("Argument \"%s\" to function \"%s\" has to be of type \"%s\"",
            argName, func, argType))
end

local function checkStrArg(arg, maxLen, argName, func, maybeNil)
    if maxLen then
        assert(type(arg) == "string" and arg:len() <= maxLen or (maybeNil and arg == nil),
            string.format("Argument \"%s\" of function \"%s\" has to be of type string with maximum length %d",
                argName, func, maxLen))
    else
        checkArg(arg, "string", argName, func, true)
    end
end

local function checkIntArg(arg, maxBits, argName, func, maybeNil)
    maxBits = math.min(maxBits or 32, 52)
    local maxVal = 2^(maxBits-1)
    assert(type(arg) == "number" and math.floor(arg) == arg
        and arg < maxVal and arg >= -maxVal
        or (maybeNil and arg == nil),
        string.format("Argument \"%s\" of function \"%s\" has to be a whole number <= %d",
            argName, func, maxVal))
end

-- function wrappers
function discordRPC.initialize(applicationId, autoRegister, optionalSteamId)
    if not discordRPClib then
        print("⚠️ Discord RPC DLL não disponível. initialize() foi ignorado.")
        return
    end
    
    local func = "discordRPC.initialize"
    checkStrArg(applicationId, nil, "applicationId", func)
    checkArg(autoRegister, "boolean", "autoRegister", func)
    if optionalSteamId ~= nil then
        checkStrArg(optionalSteamId, nil, "optionalSteamId", func)
    end

    local eventHandlers = ffi.new("struct DiscordEventHandlers")
    eventHandlers.ready = ready_proxy
    eventHandlers.disconnected = disconnected_proxy
    eventHandlers.errored = errored_proxy
    eventHandlers.joinGame = joinGame_proxy
    eventHandlers.spectateGame = spectateGame_proxy
    eventHandlers.joinRequest = joinRequest_proxy

    discordRPClib.Discord_Initialize(applicationId, eventHandlers,
        autoRegister and 1 or 0, optionalSteamId)
end

function discordRPC.shutdown()
    if discordRPClib then
        discordRPClib.Discord_Shutdown()
    end
end

function discordRPC.runCallbacks()
    if discordRPClib then
        discordRPClib.Discord_RunCallbacks()
    end
end

jit.off(discordRPC.runCallbacks)

function discordRPC.updatePresence(presence)
    if not discordRPClib then return end
    
    local func = "discordRPC.updatePresence"
    checkArg(presence, "table", "presence", func)

    checkStrArg(presence.state, 127, "presence.state", func, true)
    checkStrArg(presence.details, 127, "presence.details", func, true)

    checkIntArg(presence.startTimestamp, 64, "presence.startTimestamp", func, true)
    checkIntArg(presence.endTimestamp, 64, "presence.endTimestamp", func, true)

    checkStrArg(presence.largeImageKey, 31, "presence.largeImageKey", func, true)
    checkStrArg(presence.largeImageText, 127, "presence.largeImageText", func, true)
    checkStrArg(presence.smallImageKey, 31, "presence.smallImageKey", func, true)
    checkStrArg(presence.smallImageText, 127, "presence.smallImageText", func, true)
    checkStrArg(presence.partyId, 127, "presence.partyId", func, true)

    checkIntArg(presence.partySize, 32, "presence.partySize", func, true)
    checkIntArg(presence.partyMax, 32, "presence.partyMax", func, true)

    checkStrArg(presence.matchSecret, 127, "presence.matchSecret", func, true)
    checkStrArg(presence.joinSecret, 127, "presence.joinSecret", func, true)
    checkStrArg(presence.spectateSecret, 127, "presence.spectateSecret", func, true)

    checkIntArg(presence.instance, 8, "presence.instance", func, true)

    local cpresence = ffi.new("struct DiscordRichPresence")
    cpresence.state = presence.state
    cpresence.details = presence.details
    cpresence.startTimestamp = presence.startTimestamp or 0
    cpresence.endTimestamp = presence.endTimestamp or 0
    cpresence.largeImageKey = presence.largeImageKey
    cpresence.largeImageText = presence.largeImageText
    cpresence.smallImageKey = presence.smallImageKey
    cpresence.smallImageText = presence.smallImageText
    cpresence.partyId = presence.partyId
    cpresence.partySize = presence.partySize or 0
    cpresence.partyMax = presence.partyMax or 0
    cpresence.matchSecret = presence.matchSecret
    cpresence.joinSecret = presence.joinSecret
    cpresence.spectateSecret = presence.spectateSecret
    cpresence.instance = presence.instance or 0

    discordRPClib.Discord_UpdatePresence(cpresence)
end

function discordRPC.clearPresence()
    if discordRPClib then
        discordRPClib.Discord_ClearPresence()
    end
end

local replyMap = {
    no = 0,
    yes = 1,
    ignore = 2
}

function discordRPC.respond(userId, reply)
    if not discordRPClib then return end
    
    checkStrArg(userId, nil, "userId", "discordRPC.respond")
    assert(replyMap[reply], "Argument 'reply' to discordRPC.respond has to be one of \"yes\", \"no\" or \"ignore\"")
    discordRPClib.Discord_Respond(userId, replyMap[reply])
end

-- ===================================================================
-- NOVOS MÉTODOS CUSTOMIZADOS PARA MENSAGENS ESPECÍFICAS
-- ===================================================================

function discordRPC.updateMenu(title)
    discordRPC.updatePresence({
        state = "📋 " .. (title or "No Menu"),
        details = "Explorando opções",
        largeImageKey = "game_logo",
        largeImageText = "Roguelike Bullet Hell",
    })
end

function discordRPC.updatePlaying(wave, max_wave, score)
    local details = string.format("🌊 Wave %d/%d | Score: %d", wave or 0, max_wave or 0, score or 0)
    discordRPC.updatePresence({
        state = "🎮 Em uma Partida",
        details = details,
        largeImageKey = "game_playing",
        largeImageText = "Jogando",
    })
end

function discordRPC.updateBoss(wave, max_wave)
    discordRPC.updatePresence({
        state = "⚔️ BOSS WAVE!",
        details = string.format("Wave %d/%d - Prepare-se!", wave or 0, max_wave or 0),
        largeImageKey = "game_boss",
        largeImageText = "Lutando contra o Boss",
    })
end

function discordRPC.updateRewards(wave)
    discordRPC.updatePresence({
        state = "🎁 Escolhendo Recompensa",
        details = string.format("Wave %d Completada!", wave or 0),
        largeImageKey = "game_reward",
        largeImageText = "Selecione uma recompensa",
    })
end

function discordRPC.updateInfinite(wave, score)
    discordRPC.updatePresence({
        state = "♾️ Modo Infinito",
        details = string.format("Wave %d | Score: %d", wave or 0, score or 0),
        largeImageKey = "game_infinite",
        largeImageText = "Sem limite!",
    })
end

function discordRPC.updatePaused(wave, score)
    discordRPC.updatePresence({
        state = "⏸️ Pausado",
        details = string.format("Wave %d | Score: %d", wave or 0, score or 0),
        largeImageKey = "game_paused",
        largeImageText = "Retomando...",
    })
end

function discordRPC.updateGameOver(wave, time_seconds, score)
    local time_min = math.floor(time_seconds / 60)
    local time_sec = time_seconds % 60
    local time_str = string.format("%d:%02d", time_min, time_sec)
    
    discordRPC.updatePresence({
        state = "💀 Game Over",
        details = string.format("Wave %d | Tempo: %s | Score: %d", 
            wave or 0, time_str, score or 0),
        largeImageKey = "game_over",
        largeImageText = "Quer tentar novamente?",
    })
end

-- garbage collection callback
getmetatable(discordRPC.gcDummy).__gc = function()
    discordRPC.shutdown()
    ready_proxy:free()
    disconnected_proxy:free()
    errored_proxy:free()
    joinGame_proxy:free()
    spectateGame_proxy:free()
    joinRequest_proxy:free()
end

return discordRPC