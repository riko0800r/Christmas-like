-- =============================================================
--                    Sistema de Shaders para Game Feel
-- =============================================================

local Shaders = {}

-- Timer global para animações
Shaders.time = 0

-- =============================================================
--                    SHADER 1: OUTLINE + PULSE
-- =============================================================
-- Cria um contorno colorido ao redor dos sprites + efeito de pulso
Shaders.outline = love.graphics.newShader[[
    uniform vec3 outlineColor;
    uniform vec2 textureSize;
    uniform float pulseIntensity;
    uniform float time;
    
    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
        vec4 pixel = Texel(texture, texture_coords);
        
        // Se o pixel for transparente, verifica se há um pixel sólido próximo
        if (pixel.a == 0.0) {
            float outline = 0.0;
            
            // Tamanho do offset em coordenadas de textura
            vec2 offset_size = 1.0 / textureSize;
            
            // Checa os 8 pixels ao redor
            for(float x = -1.0; x <= 1.0; x += 1.0) {
                for(float y = -1.0; y <= 1.0; y += 1.0) {
                    if (x == 0.0 && y == 0.0) continue;
                    
                    vec2 offset = vec2(x, y) * offset_size;
                    vec4 nearbyPixel = Texel(texture, texture_coords + offset);
                    if (nearbyPixel.a > 0.0) {
                        outline = 1.0;
                    }
                }
            }
            
            // Se encontrou um pixel sólido próximo, desenha o outline
            if (outline > 0.0) {
                float pulse = sin(time * 3.0) * 0.5 + 0.5;
                float finalAlpha = mix(0.6, 1.0, pulse * pulseIntensity);
                return vec4(outlineColor, finalAlpha);
            }
        }
        
        // Pixel normal do sprite
        return pixel * color;
    }
]]

-- =============================================================
--                    SHADER 2: WAVE DISTORTION
-- =============================================================
-- Cria uma distorção ondulante nos sprites
Shaders.wave = love.graphics.newShader[[
    uniform float time;
    uniform float waveSpeed;
    uniform float waveAmplitude;
    uniform float waveFrequency;
    
    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
        // Calcula o deslocamento da onda
        float wave = sin((texture_coords.y * waveFrequency) + (time * waveSpeed)) * waveAmplitude;
        
        // Aplica a distorção apenas no eixo X
        vec2 distorted_coords = vec2(texture_coords.x + wave, texture_coords.y);
        
        // Garante que as coordenadas fiquem dentro dos limites [0,1]
        distorted_coords = clamp(distorted_coords, 0.0, 1.0);
        
        vec4 pixel = Texel(texture, distorted_coords);
        
        return pixel * color;
    }
]]

-- =============================================================
--                    SHADER 3: HIT FLASH (BONUS)
-- =============================================================
-- Flash branco quando o inimigo toma dano
Shaders.hitFlash = love.graphics.newShader[[
    uniform float flashAmount;
    
    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
        vec4 pixel = Texel(texture, texture_coords);
        
        // Mistura o pixel original com branco baseado no flashAmount
        vec3 white = vec3(1.0, 1.0, 1.0);
        pixel.rgb = mix(pixel.rgb, white, flashAmount * pixel.a);
        
        return pixel * color;
    }
]]

-- =============================================================
--                    SHADER 4: CHROMATIC ABERRATION (BONUS)
-- =============================================================
-- Efeito de aberração cromática para bosses/inimigos especiais
Shaders.chromatic = love.graphics.newShader[[
    uniform float time;
    uniform float aberrationAmount;
    
    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
        vec2 direction = vec2(cos(time * 2.0), sin(time * 2.0));
        
        // Separa os canais RGB
        float r = Texel(texture, texture_coords + direction * aberrationAmount).r;
        float g = Texel(texture, texture_coords).g;
        float b = Texel(texture, texture_coords - direction * aberrationAmount).b;
        float a = Texel(texture, texture_coords).a;
        
        return vec4(r, g, b, a) * color;
    }
]]

-- =============================================================
--                    FUNÇÕES DE APLICAÇÃO
-- =============================================================

-- Atualiza o timer global
function Shaders:update(dt)
    self.time = self.time + dt
end

-- Aplica shader de outline em um inimigo
function Shaders:applyOutline(enemy, colorR, colorG, colorB, pulseIntensity)
    self.outline:send("outlineColor", {colorR or 1, colorG or 0, colorB or 0})
    
    -- Envia o tamanho da textura (necessário para calcular os offsets)
    if enemy.image then
        self.outline:send("textureSize", {enemy.image:getWidth(), enemy.image:getHeight()})
    else
        self.outline:send("textureSize", {16, 16}) -- Valor padrão
    end
    
    self.outline:send("pulseIntensity", pulseIntensity or 0.5)
    self.outline:send("time", self.time)
    love.graphics.setShader(self.outline)
end

-- Aplica shader de wave em um inimigo
function Shaders:applyWave(enemy, speed, amplitude, frequency)
    self.wave:send("time", self.time)
    self.wave:send("waveSpeed", speed or 3.0)
    self.wave:send("waveAmplitude", amplitude or 0.02)
    self.wave:send("waveFrequency", frequency or 10.0)
    love.graphics.setShader(self.wave)
end

-- Aplica flash de dano
function Shaders:applyHitFlash(flashAmount)
    self.hitFlash:send("flashAmount", math.max(0, flashAmount or 0))
    love.graphics.setShader(self.hitFlash)
end

-- Aplica aberração cromática (para bosses)
function Shaders:applyChromaticAberration(amount)
    self.chromatic:send("time", self.time)
    self.chromatic:send("aberrationAmount", amount or 0.003)
    love.graphics.setShader(self.chromatic)
end

-- =============================================================
--                    SHADERS DE ARMAS (PROJÉTEIS)
-- =============================================================

function Shaders:applyProjectileShader(projectile_image, player)
    -- Conta quantos efeitos elementais o jogador tem
    local effects = 0
    if player.veneno then effects = effects + 1 end
    if player.fogo then effects = effects + 1 end
    if player.gelo then effects = effects + 1 end
    
    -- Se não tiver efeitos, não aplica shader
    if effects == 0 then return end

    local r, g, b = 1, 1, 1 -- Cor padrão (branca)
    local pulse = 0.5
    local shader_to_use = self.outline

    if effects >= 2 then
        r, g, b = 0.1, 0.1, 0.1
        pulse = 1.0 -- Pulso medio
    elseif player.fogo then
        r, g, b = 1.0, 0.2, 0.0 -- Vermelho/Laranja
        pulse = 2.0 -- Pulso rápido
        
    elseif player.veneno then
        r, g, b = 0.2, 1.0, 0.2 -- Verde Tóxico
        pulse = 0.5 -- Pulso lento
        
    elseif player.gelo then
        r, g, b = 0.0, 0.8, 1.0 -- Azul Ciano
        pulse = 0.0 -- Sem pulso, cor sólida e fria
    end

    -- Aplica o Outline com a cor definida
    shader_to_use:send("outlineColor", {r, g, b})
    
    -- Define tamanho da textura do projétil (importante para o outline funcionar)
    if projectile_image then
        shader_to_use:send("textureSize", {projectile_image:getWidth(), projectile_image:getHeight()})
    else
        shader_to_use:send("textureSize", {8, 8})
    end
    
    shader_to_use:send("pulseIntensity", pulse)
    shader_to_use:send("time", self.time)
    
    love.graphics.setShader(shader_to_use)
end

-- Remove o shader atual
function Shaders:clear()
    love.graphics.setShader()
end

-- =============================================================
--                    PRESETS DE SHADERS
-- =============================================================

Shaders.presets = {
    -- Inimigos comuns: outline azul com pulso suave
    common = function(self, enemy)
        self:applyOutline(enemy, 0, 0, 0, 0.65)
    end,
    
    -- Inimigos de fogo: outline vermelho com pulso intenso
    fire = function(self, enemy)
        self:applyOutline(enemy, 1.0, 0.2, 0.0, 1.0)
    end,
    
    bomb = function(self, enemy)
        self:applyOutline(enemy, 1.0, 0.7, 0.0, 8.0)
    end,
    
    -- Inimigos de gelo: wave distortion
    ice = function(self, enemy)
        self:applyOutline(enemy, 0.1, 0.25, 1.0, 1.0)
        self:applyWave(enemy, 2.0, 0.015, 15.0)
    end,
    
    -- Bosses: chromatic aberration
    boss = function(self, enemy)
        self:applyChromaticAberration(0.004)
    end,
    
    -- Inimigos venenosos: outline verde
    poison = function(self, enemy)
        self:applyOutline(enemy, 0.2, 1.0, 0.2, 0.6)
    end,
    
    -- Inimigos elétricos: wave rápida
    electric = function(self, enemy)
        self:applyWave(enemy, 8.0, 0.025, 20.0)
    end,
}

-- =============================================================
--                    SISTEMA DE HIT FLASH
-- =============================================================

-- Adiciona propriedade de flash aos inimigos
function Shaders:initEnemyFlash(enemy)
    enemy.flash_timer = 0
    enemy.flash_duration = 0.15
end

-- Ativa o flash quando o inimigo toma dano
function Shaders:triggerFlash(enemy)
    enemy.flash_timer = enemy.flash_duration or 0.15
end

-- Atualiza o flash do inimigo
function Shaders:updateEnemyFlash(enemy, dt)
    if enemy.flash_timer and enemy.flash_timer > 0 then
        enemy.flash_timer = enemy.flash_timer - dt
    end
end

-- Verifica se o inimigo está em flash
function Shaders:isFlashing(enemy)
    return enemy.flash_timer and enemy.flash_timer > 0
end

-- Pega a intensidade do flash
function Shaders:getFlashAmount(enemy)
    if not enemy.flash_timer or enemy.flash_timer <= 0 then
        return 0
    end
    -- Normaliza o timer para [0, 1]
    local duration = enemy.flash_duration or 0.15
    return enemy.flash_timer / duration
end

return Shaders