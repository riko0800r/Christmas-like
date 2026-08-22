-- =============================================================
--                    Sistema de GUI Universal (V3.1)
--           (Event-Driven Mouse & Smooth Slider Support)
--                  + Juice: hover/click feedback
-- =============================================================

local GUI = {}
GUI.__index = GUI

-- -------------------------------------------------------------
-- JUICE: pequeno helper de easing/lerp reaproveitado por todos os
-- widgets. Ficou aqui em vez de em utils.lua pra não criar mais uma
-- dependência cruzada — é puramente cosmético e local a este arquivo.
-- -------------------------------------------------------------
local function lerp(a, b, t)
    return a + (b - a) * t
end

-- easeOutBack: overshoot leve (ultrapassa o alvo e volta), ótimo pra
-- "pop" de escala em botões sem precisar de tween library externa.
local function easeOutBack(t)
    local c1 = 1.70158
    local c3 = c1 + 1
    t = math.max(0, math.min(1, t))
    return 1 + c3 * (t - 1) ^ 3 + c1 * (t - 1) ^ 2
end

-- =============================================================
-- CLASSE BASE (WIDGET)
-- =============================================================
local Widget = {
    x = 0, y = 0, w = 100, h = 20,
    children = {},
    parent = nil,
    visible = true,
    enabled = true,
    type = "widget",
    hovered = false,

    -- --- Estado de animação (juice) ---
    -- anim_scale: escala atual desenhada (1 = tamanho normal)
    -- _hover_t: 0..1, progride em direção a 1 enquanto hovered/selected,
    --           e volta a 0 quando não está — dá o "cresce ao entrar,
    --           encolhe ao sair" suave em vez de um snap binário.
    -- _click_t: pulso de 1..0 disparado no click/execute, some rápido.
    anim_scale = 1,
    _hover_t = 0,
    _click_t = 0,
    _was_hovered = false,
}

function Widget:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    o.children = {}
    o.anim_scale = 1
    o._hover_t = 0
    o._click_t = 0
    o._was_hovered = false
    return o
end

-- Atualiza a animação de juice deste widget (chamado em GUI:update).
-- Não depende do tipo do widget — funciona igual pra botão, checkbox etc.
function Widget:updateJuice(dt)
    local isActive = (self.selected or self.hovered) and self.enabled and self.visible

    local hoverSpeed = 8 -- quão rápido entra/sai do estado de hover
    if isActive then
        self._hover_t = math.min(1, self._hover_t + dt * hoverSpeed)
    else
        self._hover_t = math.max(0, self._hover_t - dt * hoverSpeed)
    end

    if self._click_t > 0 then
        self._click_t = math.max(0, self._click_t - dt * 5.5) -- pulso dura ~0.18s
    end

    -- Escala final: leve "respiro" (1 -> 1.06) no hover via easeOutBack,
    -- somado a um pop extra (até 1.14) no instante do click que decai
    -- rápido. Os dois nunca competem de forma feia porque o pop do
    -- click já começa do valor de hover atual.
    local hoverScale = 1 + easeOutBack(self._hover_t) * 0.06
    local clickPop = self._click_t * 0.08
    self.anim_scale = hoverScale + clickPop
end

-- Dispara o pulso de click. Widgets chamam isso nos seus próprios
-- handlers de onClick/toggle/setValue.
function Widget:pulse()
    self._click_t = 1
end

function Widget:draw(offsetX, offsetY) end

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

function Widget:isMouseOver(mx, my)
    if not self.visible or not self.enabled then return false end
    local ax, ay = self:getAbsolutePosition()
    return mx >= ax and mx <= ax + self.w and my >= ay and my <= ay + self.h
end

-- =============================================================
-- GERENCIADOR GUI
-- =============================================================

function GUI:new()
    local instance = {
        root = Widget:new({x=0, y=0, w=0, h=0}),
        focusableList = {}, 
        selectedIndex = 1,
        gamepadTimer = 0,
        inputCooldown = 0,
        debounceTime = 0.05,
        draggingWidget = nil, -- Armazena qual slider está sendo arrastado
        usingMouse = false    -- Flag para esconder highlight de teclado se usar mouse
    }
    setmetatable(instance, GUI)
    return instance
end

-- --- CRIADORES DE WIDGETS ---

-- 1. Container/Janela
function GUI:newPanel(x, y, w, h, color, parent)
    local panel = Widget:new({
        x = x, y = y, w = w, h = h,
        type = "panel",
        color = color or {0, 0, 0, 0.8}
    })

    panel.draw = function(self, ox, oy)
        if not self.visible then return end
        local dx, dy = (ox or 0) + self.x, (oy or 0) + self.y
        
        love.graphics.setColor(self.color)
        love.graphics.rectangle("fill", dx, dy, self.w, self.h, 5)
        
        love.graphics.setColor(1, 1, 1, 0.2)
        love.graphics.rectangle("line", dx, dy, self.w, self.h, 5)
        
        for _, child in ipairs(self.children) do
            child:draw(dx, dy)
        end
    end

    if parent then parent:addChild(panel) else self.root:addChild(panel) end
    return panel
end

-- 2. Label
function GUI:newLabel(x, y, text, font, parent, color)
    local label = Widget:new({
        x = x, y = y, w = 0, h = 0,
        text = text,
        font = font or love.graphics.getFont(),
        type = "label",
        color = color or {1,1,1,1}
    })
    
    label.draw = function(self, ox, oy)
        if not self.visible then return end
        local dx, dy = (ox or 0) + self.x, (oy or 0) + self.y
        love.graphics.setFont(self.font)
        love.graphics.setColor({self.color[1],self.color[2],self.color[3],self.color[4]})
        love.graphics.print(self.text, dx, dy)
    end

    if parent then parent:addChild(label) else self.root:addChild(label) end
    return label
end

-- 3. Imagem
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

-- 4. Slider
function GUI:newSlider(x, y, w, h, value, onUpdate, parent)
    local s = Widget:new({
        x = x, y = y, w = w, h = h or 16,
        value = math.max(0, math.min(1, value or 0.5)),
        onUpdate = onUpdate or function() end,
        type = "slider"
    })

    s.draw = function(self, ox, oy)
        if not self.visible then return end
        local dx, dy = (ox or 0) + self.x, (oy or 0) + self.y
        
        local bg = {0, 0, 0, 0.6}
        local fill = (self.selected or self.hovered) and {0.2, 0.8, 0.2, 1} or {0.4, 0.4, 0.4, 1}
        local border = (self.selected) and {1, 1, 0, 1} or {0.5, 0.5, 0.5, 1}
        
        love.graphics.setColor(bg)
        love.graphics.rectangle("fill", dx, dy, self.w, self.h, 4)
        
        local fillWidth = math.max(4, self.w * self.value)
        love.graphics.setColor(fill)
        love.graphics.rectangle("fill", dx, dy, fillWidth, self.h, 4)
        
        love.graphics.setColor(border)
        love.graphics.setLineWidth(self.selected and 2 or 1)
        love.graphics.rectangle("line", dx, dy, self.w, self.h, 4)
        
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.print(math.floor(self.value * 100) .. "%", dx + self.w + 5, dy + (self.h/2) - 6)
    end
    
    s.setValue = function(self, newVal)
        self.value = math.max(0, math.min(1, newVal))
        if self.onUpdate then self.onUpdate(self.value) end
    end

    if parent then parent:addChild(s) else self.root:addChild(s) end
    table.insert(self.focusableList, s)
    
    if #self.focusableList == 1 then s.selected = true; self.selectedIndex = 1 end
    return s
end

-- 5. Checkbox
function GUI:newCheckbox(x, y, boxSize, text, isChecked, onToggle, parent)
    local cb = Widget:new({
        x = x, y = y,
        w = boxSize + (text and 150 or 0), -- Largura estimada maior para o texto
        h = boxSize,
        text = text or "",
        checked = isChecked or false,
        onToggle = onToggle or function() end,
        boxSize = boxSize or 20,
        type = "checkbox"
    })

    cb.draw = function(self, ox, oy)
        if not self.visible then return end
        local dx, dy = (ox or 0) + self.x, (oy or 0) + self.y
        
        local borderColor = self.selected and {1, 1, 0, 1} or {0.6, 0.6, 0.6, 1}
        local fillColor = self.checked and {0.2, 0.8, 1, 1} or {0, 0, 0, 0.5}

        -- JUICE: mesmo respiro/pop de escala dos botões, só que só a
        -- caixinha em si escala (o texto ao lado fica parado, senão
        -- "empurra" o layout e fica estranho).
        local scale = self.anim_scale or 1
        local cx, cy = dx + self.boxSize / 2, dy + self.boxSize / 2
        love.graphics.push()
        love.graphics.translate(cx, cy)
        love.graphics.scale(scale, scale)
        love.graphics.translate(-cx, -cy)

        -- Desenha a caixa
        love.graphics.setColor(fillColor)
        love.graphics.rectangle("fill", dx, dy, self.boxSize, self.boxSize, 3)
        
        love.graphics.setColor(borderColor)
        love.graphics.setLineWidth(self.selected and 2 or 1)
        love.graphics.rectangle("line", dx, dy, self.boxSize, self.boxSize, 3)
        
        -- Desenha o "X" ou Check se marcado
        if self.checked then
            love.graphics.setColor(1, 1, 1, 1)
            local padding = 4
            love.graphics.rectangle("fill", dx + padding, dy + padding, self.boxSize - (padding*2), self.boxSize - (padding*2), 2)
        end

        love.graphics.pop()
        
        -- Desenha o texto ao lado (fora do scale, propositalmente)
        if self.text ~= "" then
            love.graphics.setColor(self.selected and {1,1,1,1} or {0.8,0.8,0.8,1})
            local font = love.graphics.getFont()
            local ty = dy + (self.boxSize - font:getHeight()) / 2
            love.graphics.print(self.text, dx + self.boxSize + 8, ty)
        end
    end
    
    cb.toggle = function(self)
        self.checked = not self.checked
        self:pulse()
        if self.onToggle then self.onToggle(self.checked) end
    end

    if parent then parent:addChild(cb) else self.root:addChild(cb) end
    table.insert(self.focusableList, cb)
    
    if #self.focusableList == 1 then cb.selected = true; self.selectedIndex = 1 end
    return cb
end

-- 6. Botão
function GUI:newButton(x, y, w, h, text, onClick, onSelect, image, parent)
    local b = Widget:new({
        x = x, y = y, w = w or 100, h = h or 24,
        text = text or "Botão",
        selected = false,
        onClick = onClick or function() end,
        onSelect = onSelect or function() end,
        image = image,
        type = "button"
    })
    
    b.draw = function(self, ox, oy)
        if not self.visible then return end
        local dx, dy = (ox or 0) + self.x, (oy or 0) + self.y
        
        if not self.enabled then
            love.graphics.setColor(0.2, 0.2, 0.2, 0.5)
            love.graphics.rectangle("fill", dx, dy, self.w, self.h, 3)
            return
        end
        
        -- Cor baseada em seleção (teclado) ou hover (mouse)
        local isHighlit = self.selected
        
        local bg = isHighlit and {0.2, 0.6, 1, 0.8} or {0, 0, 0, 0.4}
        local txtColor = isHighlit and {1,1,0} or {1,1,1}
        local borderColor = isHighlit and {0,1,1} or {0.4,0.4,0.4}

        -- JUICE: escala em torno do centro do botão (respiro no hover +
        -- pop no click). push/pop isolam a transformação só do desenho;
        -- a hitbox real (self.x/y/w/h) não muda, então clique continua
        -- preciso mesmo "esticado".
        local scale = self.anim_scale or 1
        local cx, cy = dx + self.w / 2, dy + self.h / 2
        love.graphics.push()
        love.graphics.translate(cx, cy)
        love.graphics.scale(scale, scale)
        love.graphics.translate(-cx, -cy)

        -- Glow sutil atrás do botão quando destacado (soma com o pulso
        -- de click pra dar um "flash" rápido de feedback).
        if isHighlit then
            local glow = 0.15 + self._click_t * 0.35
            love.graphics.setColor(borderColor[1], borderColor[2], borderColor[3], glow)
            love.graphics.rectangle("fill", dx - 3, dy - 3, self.w + 6, self.h + 6, 5)
        end

        love.graphics.setColor(bg)
        love.graphics.rectangle("fill", dx, dy, self.w, self.h, 3)
        
        if isHighlit then
            love.graphics.setColor(borderColor)
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", dx, dy, self.w, self.h, 3)
            love.graphics.setLineWidth(1)
        end
        
        love.graphics.setColor(txtColor)
        local font = love.graphics.getFont()
        local contentX = dx
        
        if self.image then
            local imgY = dy + (self.h - self.image:getHeight()) / 2
            local imgX = self.text ~= "" and (dx + 5) or (dx + (self.w - self.image:getWidth())/2)
            love.graphics.setColor(1,1,1,1)
            love.graphics.draw(self.image, imgX, imgY)
            if self.text ~= "" then contentX = contentX + self.image:getWidth() + 5 end
        end
        
        if self.text ~= "" then
            love.graphics.setColor(txtColor)
            local textWidth = font:getWidth(self.text)
            local textHeight = font:getHeight()
            local textX = self.image and contentX or (dx + (self.w - textWidth) / 2)
            local textY = dy + (self.h - textHeight) / 2
            love.graphics.print(self.text, textX, textY)
        end

        love.graphics.pop()
    end
    
    if parent then parent:addChild(b) else self.root:addChild(b) end
    table.insert(self.focusableList, b)
    if #self.focusableList == 1 then b.selected = true; self.selectedIndex = 1; b.onSelect(b) end
    return b
end

-- --- FUNÇÕES DE GERENCIAMENTO ---

function GUI:drawAll()
    for _, child in ipairs(self.root.children) do child:draw(0, 0) end
end

function GUI:clear()
    self.root.children = {}
    self.focusableList = {}
    self.selectedIndex = 1
    self.gamepadTimer = 0
    self.inputCooldown = 0
    self.draggingWidget = nil
end

function GUI:remove(widget)
    for i, v in ipairs(self.focusableList) do
        if v == widget then
            table.remove(self.focusableList, i)
            if self.selectedIndex >= i then self.selectedIndex = math.max(1, self.selectedIndex - 1) end
            break
        end
    end
    local function removeFromParent(parent, childToRemove)
        for i, child in ipairs(parent.children) do
            if child == childToRemove then table.remove(parent.children, i); return true end
            if removeFromParent(child, childToRemove) then return true end
        end
        return false
    end
    removeFromParent(self.root, widget)
end

-- --- INPUT LOGIC (KEYBOARD / GAMEPAD) ---

function GUI:moveSelection(dir)
    if #self.focusableList == 0 then return end
    if self.inputCooldown > 0 then return end
    
    -- Desmarca o atual
    if self.focusableList[self.selectedIndex] then 
        self.focusableList[self.selectedIndex].selected = false 
    end
    
    local attempts = 0
    repeat
        self.selectedIndex = self.selectedIndex + dir
        if self.selectedIndex > #self.focusableList then self.selectedIndex = 1 
        elseif self.selectedIndex < 1 then self.selectedIndex = #self.focusableList end
        attempts = attempts + 1
    until self.focusableList[self.selectedIndex].enabled or attempts >= #self.focusableList
    
    local btn = self.focusableList[self.selectedIndex]
    if btn then
        btn.selected = true
        self.usingMouse = false -- Voltou a usar teclado
        if btn.onSelect then btn.onSelect(btn) end
    end
    self.inputCooldown = self.debounceTime
end

function GUI:executeSelected()
    if self.inputCooldown > 0 then return false end
    local b = self.focusableList[self.selectedIndex]
    
    if b and b.enabled then
        if b.type == "button" and b.onClick then
            b:pulse()
            b.onClick(b)
            self.inputCooldown = self.debounceTime * 5
            return true
        elseif b.type == "checkbox" then
            b:toggle() -- já dá pulse() internamente
            self.inputCooldown = self.debounceTime * 2
            return true
        end
    end
    return false
end

-- =========================================================
--  MOUSE HANDLERS (EVENT DRIVEN)
--  Chame isso dentro de love.mousemoved, mousepressed, etc.
-- =========================================================

-- Chamada: Buttons:mousemoved(x, y, dx, dy)
function GUI:mousemoved(x, y, dx, dy)
    self.usingMouse = true

    -- 1. Se estiver arrastando um slider, ignore colisão e apenas atualize
    if self.draggingWidget and self.draggingWidget.type == "slider" then
        local b = self.draggingWidget
        local ax, _ = b:getAbsolutePosition()
        local relativeX = x - ax
        b:setValue(relativeX / b.w)
        return
    end

    -- 2. Detectar Hover normal
    local hoverFound = false
    for i, b in ipairs(self.focusableList) do
        b.hovered = false -- Reseta hover frame anterior
        
        if b.enabled and b.visible and b:isMouseOver(x, y) then
            -- Se mudou o foco via mouse
            if self.selectedIndex ~= i then
                if self.focusableList[self.selectedIndex] then
                    self.focusableList[self.selectedIndex].selected = false
                end
                self.selectedIndex = i
                b.selected = true
                if b.onSelect then b.onSelect(b) end
            end
            b.hovered = true
            hoverFound = true
        end
    end
end

-- Chamada: Buttons:mousepressed(x, y, button)
function GUI:mousepressed(x, y, button)
    if button ~= 1 then return end -- Apenas botão esquerdo

    for i, b in ipairs(self.focusableList) do
        if b.enabled and b.visible and b:isMouseOver(x, y) then
            self.selectedIndex = i
            b.selected = true
            
            if b.type == "button" then
                b:pulse()
                if b.onClick then b.onClick(b) end
            elseif b.type == "checkbox" then
                b:toggle()
            elseif b.type == "slider" then
                -- Atualiza valor imediatamente ao clicar
                local ax, _ = b:getAbsolutePosition()
                b:setValue((x - ax) / b.w)
                -- Inicia drag
                self.draggingWidget = b
            end
            return true
        end
    end
end

-- Chamada: Buttons:mousereleased(x, y, button)
function GUI:mousereleased(x, y, button)
    if button == 1 then
        self.draggingWidget = nil
    end
end

-- =========================================================
--  INPUTS (KEYBOARD / GAMEPAD)
-- =========================================================

function GUI:keypressed(key)
    local current = self.focusableList[self.selectedIndex]
    
    if key == "down" or key == "s" then self:moveSelection(1)
    elseif key == "up" or key == "w" then self:moveSelection(-1)
    elseif key == "return" or key == "x" or key == "space" or key == "e" then self:executeSelected()
    elseif current and current.type == "slider" then
        if key == "left" or key == "a" then current:setValue(current.value - 0.01)
        elseif key == "right" or key == "d" then current:setValue(current.value + 0.01)
        end
    end
end

function GUI:gamepadpressed(joystick, button)
    local current = self.focusableList[self.selectedIndex]
    
    if button == "a" then self:executeSelected() end
    if current then
        if button == "dpdown" then self:moveSelection(1)
        elseif button == "dpup" then self:moveSelection(-1)
        elseif current.type == "slider" then
            if button == "dpleft" then current:setValue(current.value - 0.01) 
            elseif button == "dpright" then current:setValue(current.value + 0.01)
            end
        end
    end
end

function GUI:update(dt)
    if self.gamepadTimer > 0 then self.gamepadTimer = self.gamepadTimer - dt end
    if self.inputCooldown > 0 then self.inputCooldown = self.inputCooldown - dt end

    -- JUICE: atualiza a animação de hover/click de cada widget focável.
    -- Feito aqui (e não dentro de cada draw) pra não depender de dt
    -- estar disponível no draw, e pra continuar rodando mesmo se um
    -- widget momentaneamente não for desenhado.
    for _, w in ipairs(self.focusableList) do
        w:updateJuice(dt)
    end
    
    -- Lógica de repetição de tecla (Holding key)
    local current = self.focusableList[self.selectedIndex]
    local speed = 0.5
    if current and current.type == "slider" and not self.usingMouse then
        if love.keyboard.isDown("left", "a") then current:setValue(current.value - (speed * dt))
        elseif love.keyboard.isDown("right", "d") then current:setValue(current.value + (speed * dt))
        end
    end

    local joysticks = love.joystick.getJoysticks()
    local j = joysticks[1]
    
    if j and j:isGamepad() then
        local yaxis = j:getGamepadAxis("lefty")
        if self.gamepadTimer <= 0 then
            if yaxis > 0.6 then self:moveSelection(1); self.gamepadTimer = 0.2
            elseif yaxis < -0.6 then self:moveSelection(-1); self.gamepadTimer = 0.2
            end
        end
        if current and current.type == "slider" then
            local xaxis = j:getGamepadAxis("leftx")
            if math.abs(xaxis) > 0.2 then current:setValue(current.value + (xaxis * speed * dt)) end
        end
    end
end

local globalInstance = GUI:new()
return globalInstance