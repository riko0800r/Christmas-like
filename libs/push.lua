-- push.lua (versão simplificada para Christmas-like remastered)
-- Gerencia resolução virtual em jogos Love2D
-- Autor original: Ulysse Ramage / Versão simplificada por ChatGPT (2025)

local push = {}

-- Configurações padrão
push.defaults = {
    fullscreen = false,
    resizable  = false,
    pixelperfect = false,
    highdpi = true
}

-- Inicializa a tela
function push:setupScreen(virtualWidth, virtualHeight, windowWidth, windowHeight, settings)
    settings = settings or {}
    for k,v in pairs(self.defaults) do
        self[k] = settings[k] ~= nil and settings[k] or v
    end

    self.virtualWidth  = virtualWidth
    self.virtualHeight = virtualHeight
    self.windowWidth   = windowWidth
    self.windowHeight  = windowHeight

    love.window.setMode(windowWidth, windowHeight, {
        fullscreen = self.fullscreen,
        resizable  = self.resizable,
        highdpi    = self.highdpi
    })

    self:_calculateScale()
end

-- Recalcula escala e offset
function push:_calculateScale()
    local scaleX = self.windowWidth  / self.virtualWidth
    local scaleY = self.windowHeight / self.virtualHeight
    local scale = math.min(scaleX, scaleY)

    if self.pixelperfect then
        scale = math.floor(scale)
    end

    self.scale = scale
    self.offsetX = math.floor((self.windowWidth  - self.virtualWidth  * scale) / 2)
    self.offsetY = math.floor((self.windowHeight - self.virtualHeight * scale) / 2)
end

-- Inicia o desenho na resolução virtual
function push:start()
    love.graphics.push()
    love.graphics.translate(self.offsetX, self.offsetY)
    love.graphics.scale(self.scale, self.scale)
    love.graphics.setScissor(
        self.offsetX, self.offsetY,
        self.virtualWidth * self.scale,
        self.virtualHeight * self.scale
    )
end

-- Finaliza o desenho e restaura
function push:finish()
    love.graphics.setScissor()
    love.graphics.pop()
end

-- Ajusta tamanho da janela (para eventos de resize)
function push:resize(w, h)
    self.windowWidth, self.windowHeight = w, h
    self:_calculateScale()
end

-- Alterna modo fullscreen
function push:toggleFullscreen()
    self.fullscreen = not self.fullscreen
    love.window.setFullscreen(self.fullscreen)
    local w, h = love.graphics.getDimensions()
    self:resize(w, h)
end

-- Converte coordenadas reais para coordenadas virtuais
function push:toGame(x, y)
    x = (x - self.offsetX) / self.scale
    y = (y - self.offsetY) / self.scale
    if x < 0 or y < 0 or x > self.virtualWidth or y > self.virtualHeight then
        return nil, nil
    end
    return x, y
end

-- Converte coordenadas virtuais para reais
function push:toScreen(x, y)
    return x * self.scale + self.offsetX, y * self.scale + self.offsetY
end

-- Retorna dimensões
function push:getDimensions()
    return self.virtualWidth, self.virtualHeight
end

return push