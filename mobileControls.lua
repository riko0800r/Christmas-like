-- mobile_controls.lua
local MobileControls = {}

-- Estados dos botões
MobileControls.state = {
    joystick_active = false,
    joystick_id = nil,
    joystick_center = {x = 0, y = 0},
    joystick_pos = {x = 0, y = 0},
    joystick_radius = 50,
    
    buttons = {}, -- Lista de botões dinâmicos
}

-- Configurações de layout
local JOYSTICK_SIZE = 100
local BUTTON_SIZE = 50
local BUTTON_PADDING = 15

function MobileControls:init(screen_width, screen_height)
    self.screen_w = screen_width
    self.screen_h = screen_height
    
    -- Posiciona joystick na esquerda
    self.state.joystick_x = BUTTON_PADDING + JOYSTICK_SIZE / 2
    self.state.joystick_y = screen_height - BUTTON_PADDING - JOYSTICK_SIZE / 2
    
    -- Cria botões dinâmicos na direita
    self:createButtons()
end

function MobileControls:createButtons()
    local button_x = self.screen_w - BUTTON_PADDING - BUTTON_SIZE
    local button_y = self.screen_h - BUTTON_PADDING - BUTTON_SIZE * 2 - 10
    
    self.state.buttons = {
        {
            id = "action",
            x = button_x,
            y = button_y,
            w = BUTTON_SIZE,
            h = BUTTON_SIZE,
            label = "A",
            color = {0.2, 0.8, 0.2},
            pressed = false,
            action = "confirm"
        },
        {
            id = "secondary",
            x = button_x - BUTTON_SIZE - 10,
            y = button_y,
            w = BUTTON_SIZE,
            h = BUTTON_SIZE,
            label = "X",
            color = {0.8, 0.2, 0.2},
            pressed = false,
            action = "secondary"
        },
        {
            id = "pause",
            x = self.screen_w - BUTTON_PADDING - BUTTON_SIZE,
            y = BUTTON_PADDING,
            w = BUTTON_SIZE,
            h = BUTTON_SIZE,
            label = "|||",
            color = {0.5, 0.5, 0.8},
            pressed = false,
            action = "pause"
        }
    }
end

function MobileControls:update(dt, player)
    if not player then return end
    
    -- Atualiza posição do joystick
    if self.state.joystick_active then
        local jc = self.state.joystick_center
        local jp = self.state.joystick_pos
        local dx = jp.x - jc.x
        local dy = jp.y - jc.y
        local dist = math.sqrt(dx*dx + dy*dy)
        
        if dist > 0 then
            player.dx = (dx / dist) * player.speed
            player.dy = (dy / dist) * player.speed
        else
            player.dx, player.dy = 0, 0
        end
    else
        player.dx, player.dy = 0, 0
    end
    
    -- Atualiza animação dos botões
    for _, btn in ipairs(self.state.buttons) do
        if btn.pressed then
            btn.scale = (btn.scale or 1) - (0.1 * dt * 60)
            btn.scale = math.max(0.85, btn.scale)
        else
            btn.scale = (btn.scale or 1) + (0.05 * dt * 60)
            btn.scale = math.min(1.0, btn.scale)
        end
    end
end

function MobileControls:draw()
    -- Desenha joystick
    self:drawJoystick()
    
    -- Desenha botões de ação
    for _, btn in ipairs(self.state.buttons) do
        self:drawButton(btn)
    end
    
    -- Desenha área segura (debug)
    if Debug and Debug.active then
        love.graphics.setColor(1, 0, 0, 0.2)
        love.graphics.rectangle('fill', 0, 0, self.screen_w, self.screen_h)
    end
end

function MobileControls:drawJoystick()
    local jc = self.state.joystick_center
    local jp = self.state.joystick_pos
    
    -- Fundo do joystick
    love.graphics.setColor(0, 0, 0, 0.4)
    love.graphics.circle('fill', jc.x, jc.y, self.state.joystick_radius)
    
    love.graphics.setColor(0.3, 0.6, 1, 0.6)
    love.graphics.circle('line', jc.x, jc.y, self.state.joystick_radius)
    
    -- Polegar
    if self.state.joystick_active then
        love.graphics.setColor(0.5, 1, 1, 0.8)
    else
        love.graphics.setColor(0.3, 0.6, 1, 0.6)
    end
    
    love.graphics.circle('fill', jp.x, jp.y, self.state.joystick_radius / 2.5)
end

function MobileControls:drawButton(btn)
    local scale = btn.scale or 1
    
    -- Cor base com feedback de pressionado
    local color = btn.color
    if btn.pressed then
        color = {color[1] * 1.3, color[2] * 1.3, color[3] * 1.3}
    end
    
    love.graphics.setColor(color[1], color[2], color[3], 0.7)
    
    local x = btn.x - (btn.w * scale) / 2
    local y = btn.y - (btn.h * scale) / 2
    
    love.graphics.rectangle('fill', x, y, btn.w * scale, btn.h * scale, 5)
    
    -- Borda
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle('line', x, y, btn.w * scale, btn.h * scale, 5)
    
    -- Texto
    love.graphics.setColor(1, 1, 1, 1)
    local font = love.graphics.getFont()
    local text_w = font:getWidth(btn.label)
    local text_h = font:getHeight()
    love.graphics.print(
        btn.label,
        btn.x - text_w / 2,
        btn.y - text_h / 2
    )
end

function MobileControls:isButtonPressed(button_id)
    for _, btn in ipairs(self.state.buttons) do
        if btn.id == button_id and btn.pressed then
            return true
        end
    end
    return false
end

function MobileControls:getJoystickInput()
    if not self.state.joystick_active then
        return 0, 0
    end
    
    local jc = self.state.joystick_center
    local jp = self.state.joystick_pos
    local dx = jp.x - jc.x
    local dy = jp.y - jc.y
    
    return dx, dy
end

-- Touch handlers
function MobileControls:touchpressed(id, x, y)
    local virt_x, virt_y = Push:toGame(x, y)
    if not virt_x or not virt_y then return end
    
    -- Joystick (lado esquerdo)
    if virt_x < self.screen_w * 0.3 then
        self.state.joystick_active = true
        self.state.joystick_id = id
        self.state.joystick_center.x = virt_x
        self.state.joystick_center.y = virt_y
        self.state.joystick_pos.x = virt_x
        self.state.joystick_pos.y = virt_y
        return
    end
    
    -- Botões (lado direito)
    for _, btn in ipairs(self.state.buttons) do
        if self:isPointInButton(virt_x, virt_y, btn) then
            btn.pressed = true
            self:executeButtonAction(btn.action)
            return
        end
    end
end

function MobileControls:touchmoved(id, x, y)
    if not self.state.joystick_active or self.state.joystick_id ~= id then return end
    
    local virt_x, virt_y = Push:toGame(x, y)
    if not virt_x or not virt_y then return end
    
    local jc = self.state.joystick_center
    local dx = virt_x - jc.x
    local dy = virt_y - jc.y
    local dist = math.sqrt(dx*dx + dy*dy)
    
    if dist > self.state.joystick_radius then
        self.state.joystick_pos.x = jc.x + (dx / dist) * self.state.joystick_radius
        self.state.joystick_pos.y = jc.y + (dy / dist) * self.state.joystick_radius
    else
        self.state.joystick_pos.x = virt_x
        self.state.joystick_pos.y = virt_y
    end
end

function MobileControls:touchreleased(id)
    if self.state.joystick_id == id then
        self.state.joystick_active = false
        self.state.joystick_id = nil
    end
    
    -- Libera todos os botões
    for _, btn in ipairs(self.state.buttons) do
        btn.pressed = false
    end
end

function MobileControls:isPointInButton(x, y, btn)
    return x >= btn.x - btn.w/2 and x <= btn.x + btn.w/2 and
           y >= btn.y - btn.h/2 and y <= btn.y + btn.h/2
end

function MobileControls:executeButtonAction(action)
    if action == "confirm" then
        love.keypressed("x")
    elseif action == "secondary" then
        love.keypressed("z")
    elseif action == "pause" then
        love.keypressed("escape")
    end
end

return MobileControls