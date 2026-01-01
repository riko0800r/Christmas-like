-- =============================================================
--                    Sistema de GUI Universal (V2)
-- =============================================================

local utils = require("utils") -- Mantendo sua dependência

local GUI = {}
GUI.__index = GUI

-- =============================================================
-- CLASSE BASE (WIDGET)
-- =============================================================
-- Todos os elementos (Botão, Janela, Texto) herdam daqui
local Widget = {
    x = 0, y = 0, w = 100, h = 20,
    children = {},
    parent = nil,
    visible = true,
    enabled = true,
    type = "widget"
}

function Widget:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    o.children = {} -- Cada instância precisa de sua própria lista
    return o
end

function Widget:draw(offsetX, offsetY)
    -- Sobrescrito pelos filhos
end

function Widget:addChild(child)
    table.insert(self.children, child)
    child.parent = self
    return child
end

function Widget:getAbsolutePosition()
    local x, y = self.x, self.y
    local p = self.parent
    while p do
        x = x + p.x
        y = y + p.y
        p = p.parent
    end
    return x, y
end

-- =============================================================
-- GERENCIADOR GUI
-- =============================================================

function GUI:new()
    local instance = {
        root = Widget:new({x=0, y=0, w=0, h=0}), -- Elemento raiz invisível
        focusableList = {}, -- Lista linear apenas para navegação (teclado/gamepad)
        selectedIndex = 1,
        gamepadTimer = 0,
        inputCooldown = 0,
        debounceTime = 0.125
    }
    setmetatable(instance, GUI)
    return instance
end

-- --- CRIADORES DE WIDGETS ---

-- 1. Cria um Container/Janela
function GUI:newPanel(x, y, w, h, color, parent)
    local panel = Widget:new({
        x = x, y = y, w = w, h = h,
        type = "panel",
        color = color or {0, 0, 0, 0.8} -- Cor de fundo padrão
    })

    panel.draw = function(self, ox, oy)
        if not self.visible then return end
        local dx, dy = (ox or 0) + self.x, (oy or 0) + self.y
        
        -- Desenha fundo da janela
        love.graphics.setColor(self.color)
        love.graphics.rectangle("fill", dx, dy, self.w, self.h, 5)
        
        -- Borda
        love.graphics.setColor(1, 1, 1, 0.2)
        love.graphics.rectangle("line", dx, dy, self.w, self.h, 5)
        
        -- Desenha filhos (Recursividade)
        for _, child in ipairs(self.children) do
            child:draw(dx, dy)
        end
    end

    if parent then parent:addChild(panel) else self.root:addChild(panel) end
    return panel
end

-- 2. Cria um Texto/Label (Não interagível)
function GUI:newLabel(x, y, text, font, parent)
    local label = Widget:new({
        x = x, y = y, w = 0, h = 0,
        text = text,
        font = font or love.graphics.getFont(),
        type = "label"
    })
    
    label.draw = function(self, ox, oy)
        if not self.visible then return end
        local dx, dy = (ox or 0) + self.x, (oy or 0) + self.y
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(self.font)
        love.graphics.print(self.text, dx, dy)
    end

    if parent then parent:addChild(label) else self.root:addChild(label) end
    return label
end

-- 3. Cria uma Imagem (Pura)
function GUI:newImage(x, y, image, scale, parent)
    local imgWidget = Widget:new({
        x = x, y = y, w = image:getWidth() * (scale or 1), h = image:getHeight() * (scale or 1),
        image = image,
        scale = scale or 1,
        type = "image"
    })

    imgWidget.draw = function(self, ox, oy)
        if not self.visible then return end
        local dx, dy = (ox or 0) + self.x, (oy or 0) + self.y
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(self.image, dx, dy, 0, self.scale, self.scale)
    end

    if parent then parent:addChild(imgWidget) else self.root:addChild(imgWidget) end
    return imgWidget
end

function GUI:newSlider(x, y, w, h, value, onUpdate, parent)
    local s = Widget:new({
        x = x, y = y, w = w, h = h or 16,
        value = math.max(0, math.min(1, value or 0.5)), -- Garante entre 0 e 1
        onUpdate = onUpdate or function() end,
        type = "slider"
    })

    s.draw = function(self, ox, oy)
        if not self.visible then return end
        local dx, dy = (ox or 0) + self.x, (oy or 0) + self.y
        
        -- Cores
        local bg = {0, 0, 0, 0.6}
        local fill = self.selected and {0.2, 0.8, 0.2, 1} or {0.4, 0.4, 0.4, 1}
        local border = self.selected and {1, 1, 0, 1} or {0.5, 0.5, 0.5, 1}
        
        -- 1. Fundo (Trilho)
        love.graphics.setColor(bg)
        love.graphics.rectangle("fill", dx, dy, self.w, self.h, 4)
        
        -- 2. Preenchimento (Barra de progresso)
        local fillWidth = math.max(4, self.w * self.value)
        love.graphics.setColor(fill)
        love.graphics.rectangle("fill", dx, dy, fillWidth, self.h, 4)
        
        -- 3. Borda
        love.graphics.setColor(border)
        love.graphics.setLineWidth(self.selected and 2 or 1)
        love.graphics.rectangle("line", dx, dy, self.w, self.h, 4)
        
        -- 4. Marcador visual (opcional: mostra %)
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.print(math.floor(self.value * 100) .. "%", dx + self.w + 5, dy + (self.h/2) - 4)
    end
    
    -- Função helper para alterar valor
    s.setValue = function(self, newVal)
        self.value = math.max(0, math.min(1, newVal))
        if self.onUpdate then self.onUpdate(self.value) end
    end

    if parent then parent:addChild(s) else self.root:addChild(s) end
    table.insert(self.focusableList, s)
    
    -- Auto-seleção se for o primeiro
    if #self.focusableList == 1 then 
        s.selected = true 
        self.selectedIndex = 1
    end
    
    return s
end

-- 4. Cria um Botão (Mantendo a lógica original mas adaptada)
function GUI:newButton(x, y, w, h, text, onClick, onSelect, image, parent)
    local b = Widget:new({
        x = x, y = y,
        w = w or 100,
        h = h or 24,
        text = text or "Botão",
        selected = false,
        onClick = onClick or function() end,
        onSelect = onSelect or function() end,
        image = image, -- Suporte a imagem
        type = "button"
    })
    
    b.draw = function(self, ox, oy)
        if not self.visible then return end
        local dx, dy = (ox or 0) + self.x, (oy or 0) + self.y
        
        if not self.enabled then
            love.graphics.setColor(0.2, 0.2, 0.2, 0.5)
            love.graphics.rectangle("fill", dx, dy, self.w, self.h, 3)
             -- Desenha imagem desabilitada se houver
            if self.image then
                love.graphics.setColor(0.5, 0.5, 0.5, 0.5)
                love.graphics.draw(self.image, dx + 2, dy + 2) -- Padding simples
            end
            return
        end
        
        -- Cores (usando utils se disponível, ou fallback)
        local bg = self.selected and {0.2, 0.6, 1, 0.8} or {0, 0, 0, 0.4}
        local txtColor = self.selected and (utils.pico8_colors[10] or {1,1,0}) or (utils.pico8_colors[7] or {1,1,1})
        local borderColor = self.selected and (utils.pico8_colors[12] or {0,1,1}) or (utils.pico8_colors[5] or {0.4,0.4,0.4})
        
        -- Fundo
        love.graphics.setColor(bg)
        love.graphics.rectangle("fill", dx, dy, self.w, self.h, 3)
        
        -- Borda
        if self.selected then
            love.graphics.setColor(borderColor)
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", dx, dy, self.w, self.h, 3)
            love.graphics.setLineWidth(1)
        end
        
        -- Conteúdo (Imagem e/ou Texto)
        love.graphics.setColor(txtColor)
        local font = love.graphics.getFont()
        local contentX = dx
        
        -- Se tiver imagem
        if self.image then
            local imgY = dy + (self.h - self.image:getHeight()) / 2
            -- Se tiver texto, desenha imagem à esquerda, senão centraliza
            local imgX = self.text ~= "" and (dx + 5) or (dx + (self.w - self.image:getWidth())/2)
            
            love.graphics.setColor(1,1,1,1) -- Imagem sem tintura
            love.graphics.draw(self.image, imgX, imgY)
            
            -- Desloca o texto se houver imagem
            if self.text ~= "" then
                contentX = contentX + self.image:getWidth() + 5
            end
        end
        
        if self.text ~= "" then
            love.graphics.setColor(txtColor)
            local textWidth = font:getWidth(self.text)
            local textHeight = font:getHeight()
            
            -- Centraliza baseado no espaço restante ou total
            local textX = 0
            if self.image then
                textX = contentX -- Já deslocado
            else
                textX = dx + (self.w - textWidth) / 2
            end
            
            local textY = dy + (self.h - textHeight) / 2
            love.graphics.print(self.text, textX, textY)
        end
    end
    
    -- Adiciona à hierarquia
    if parent then parent:addChild(b) else self.root:addChild(b) end
    
    -- Adiciona à lista de navegação (apenas se for um botão interativo)
    table.insert(self.focusableList, b)
    
    -- Auto-seleção do primeiro
    if #self.focusableList == 1 then 
        b.selected = true 
        self.selectedIndex = 1
        b.onSelect(b)
    end
    
    return b
end

-- --- FUNÇÕES DE GERENCIAMENTO ---

-- Desenha tudo a partir da raiz
function GUI:drawAll()
    -- A raiz desenha seus filhos recursivamente
    for _, child in ipairs(self.root.children) do
        child:draw(0, 0)
    end
end

function GUI:clear()
    self.root.children = {}
    self.focusableList = {}
    self.selectedIndex = 1
    self.gamepadTimer = 0
    self.inputCooldown = 0
end

-- Remove um widget específico (e seus filhos)
function GUI:remove(widget)
    -- Remove da lista de focáveis se estiver lá
    for i, v in ipairs(self.focusableList) do
        if v == widget then
            table.remove(self.focusableList, i)
            if self.selectedIndex >= i then self.selectedIndex = math.max(1, self.selectedIndex - 1) end
            break
        end
    end
    
    -- Função recursiva para remover da árvore
    local function removeFromParent(parent, childToRemove)
        for i, child in ipairs(parent.children) do
            if child == childToRemove then
                table.remove(parent.children, i)
                return true
            end
            if removeFromParent(child, childToRemove) then return true end
        end
        return false
    end
    
    removeFromParent(self.root, widget)
end

-- --- LÓGICA DE INPUT (Quase inalterada, mas usa focusableList) ---

function GUI:moveSelection(dir)
    if #self.focusableList == 0 then return end
    if self.inputCooldown > 0 then return end
    
    if self.focusableList[self.selectedIndex] then
        self.focusableList[self.selectedIndex].selected = false
    end
    
    local attempts = 0
    local maxAttempts = #self.focusableList
    
    repeat
        self.selectedIndex = self.selectedIndex + dir
        if self.selectedIndex > #self.focusableList then self.selectedIndex = 1 
        elseif self.selectedIndex < 1 then self.selectedIndex = #self.focusableList end
        attempts = attempts + 1
    until self.focusableList[self.selectedIndex].enabled or attempts >= maxAttempts
    
    if self.focusableList[self.selectedIndex] then
        local btn = self.focusableList[self.selectedIndex]
        btn.selected = true
        if btn.onSelect then btn.onSelect(btn) end
    end
    
    self.inputCooldown = self.debounceTime
end

function GUI:executeSelected()
    if self.inputCooldown > 0 then return false end
    local b = self.focusableList[self.selectedIndex]
    if b and b.enabled and b.onClick then
        b.onClick(b)
        self.inputCooldown = self.debounceTime * 10
        return true
    end
    return false
end

function GUI:setSelected(i)
    if i < 1 or i > #self.focusableList then return end
    if not self.focusableList[i].enabled then return end
    
    if self.focusableList[self.selectedIndex] then
        self.focusableList[self.selectedIndex].selected = false
    end
    
    self.selectedIndex = i
    local btn = self.focusableList[i]
    btn.selected = true
    if btn.onSelect then btn.onSelect(btn) end
end

function GUI:updateMouse()
    if love.mouse.isDown(1) then
        local mx, my = love.mouse.getPosition()
        local current = self.focusableList[self.selectedIndex]
        
        if current and current.type == "slider" then
            local ax, ay = current:getAbsolutePosition()
            if mx >= ax and mx <= ax + current.w and my >= ay and my <= ay + current.h then
                local relativeX = mx - ax
                current:setValue(relativeX / current.w)
            end
        end
    end
end

-- Input Mouse/Touch (Agora precisa calcular posições absolutas)
function GUI:checkPress(mouseX, mouseY)
    for i, b in ipairs(self.focusableList) do
        if b.enabled and b.visible then
            local ax, ay = b:getAbsolutePosition()
            
            if mouseX >= ax and mouseX <= ax + b.w and mouseY >= ay and mouseY <= ay + b.h then
                self:setSelected(i)
                
                -- Se for Slider, calcula a posição do clique
                if b.type == "slider" then
                    local relativeX = mouseX - ax
                    local percent = relativeX / b.w
                    b:setValue(percent)
                -- Se for Botão normal
                elseif b.onClick then 
                    b.onClick(b) 
                    self.inputCooldown = self.debounceTime * 3
                end
                return true
            end
        end
    end
    return false
end

-- Input Teclado (Idêntico)
function GUI:keypressed(key)
    local current = self.focusableList[self.selectedIndex]
    
    -- Navegação Vertical (Cima/Baixo)
    if key == "down" or key == "s" then self:moveSelection(1)
    elseif key == "up" or key == "w" then self:moveSelection(-1)
    
    -- Ação (Enter/Espaço)
    elseif key == "return" or key == "x" or key == "space" or key == "e" then self:executeSelected()
    
    -- Navegação Horizontal (Apenas para Sliders)
    elseif current and current.type == "slider" then
        if key == "left" or key == "a" then
            current:setValue(current.value - 0.01) -- Diminui 10%
        elseif key == "right" or key == "d" then
            current:setValue(current.value + 0.01) -- Aumenta 10%
        end
    end
end

-- Input Gamepad
function GUI:gamepadpressed(joystick, button)
    local current = self.focusableList[self.selectedIndex]
    
    -- Botão de Confirmação (A no Xbox, X no PS)
    if button == "a" then 
        self:executeSelected() 
    end

    -- Navegação via D-Pad (Digital)
    if current then
        if button == "dpdown" then self:moveSelection(1)
        elseif button == "dpup" then self:moveSelection(-1)
        
        -- Controle de Slider via D-Pad (ALTERADO AQUI)
        elseif current.type == "slider" then
            if button == "dpleft" then
                -- Mudado de 0.05 para 0.01
                current:setValue(current.value - 0.01) 
            elseif button == "dpright" then
                -- Mudado de 0.05 para 0.01
                current:setValue(current.value + 0.01)
            end
        end
    end
end

-- Input Teclado
function GUI:keypressed(key)
    local current = self.focusableList[self.selectedIndex]
    
    -- Navegação Vertical (Cima/Baixo)
    if key == "down" or key == "s" then self:moveSelection(1)
    elseif key == "up" or key == "w" then self:moveSelection(-1)
    
    -- Ação (Enter/Espaço)
    elseif key == "return" or key == "x" or key == "space" or key == "e" then self:executeSelected()
    end
end

function GUI:update(dt)
    if self.gamepadTimer > 0 then self.gamepadTimer = self.gamepadTimer - dt end
    if self.inputCooldown > 0 then self.inputCooldown = self.inputCooldown - dt end
    
    local current = self.focusableList[self.selectedIndex]

    -- =========================================================
    -- NOVO: CONTROLE DE SLIDER COM TECLADO (isDown)
    -- =========================================================
    if current and current.type == "slider" then
        -- Velocidade: 0.5 significa que leva 2 segundos para ir de 0 a 100%
        local speed = 0.5 
        
        if love.keyboard.isDown("left", "a") then
            current:setValue(current.value - (speed * dt))
        elseif love.keyboard.isDown("right", "d") then
            current:setValue(current.value + (speed * dt))
        end
    end
    -- =========================================================

    -- (Abaixo continua o código original do Gamepad...)
    local joysticks = love.joystick.getJoysticks()
    local j = joysticks[1]
    
    if j and j:isGamepad() then
        -- EIXO VERTICAL (Navegação entre itens)
        local yaxis = j:getGamepadAxis("lefty")
        if self.gamepadTimer <= 0 then
            if yaxis > 0.6 then 
                self:moveSelection(1)
                self.gamepadTimer = 0.2
            elseif yaxis < -0.6 then 
                self:moveSelection(-1)
                self.gamepadTimer = 0.2
            end
        end

        -- EIXO HORIZONTAL (Sliders no Gamepad)
        if current and current.type == "slider" then
            local xaxis = j:getGamepadAxis("leftx")
            
            if math.abs(xaxis) > 0.2 then
                local speed = 0.5 * dt 
                current:setValue(current.value + (xaxis * speed))
            end
            
            -- Adicionado suporte ao D-Pad segurado também
            if j:isGamepadDown("dpleft") then
                current:setValue(current.value - (0.5 * dt))
            elseif j:isGamepadDown("dpright") then
                current:setValue(current.value + (0.5 * dt))
            end
        end
        
        if j:isGamepadDown("a") and self.inputCooldown <= 0 then
            if self:executeSelected() then
                self.inputCooldown = 0.5
            end
        end
    end
end

local globalInstance = GUI:new()
return globalInstance