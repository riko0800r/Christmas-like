-- =============================================================
--                    Sistema de Shaders para Game Feel
-- =============================================================

local Shaders = {}

Shaders.time = 0

-- =============================================================
--                    UBER SHADER (TODOS EM UM)
-- =============================================================
Shaders.uber = love.graphics.newShader[[
    uniform vec2 textureSize;
    uniform float time;

    // --- FLASH ---
    uniform float flashAmount;

    // --- OUTLINE ---
    uniform vec3 outlineColor;
    uniform float outlineAlpha; // Se > 0, o outline está ativo
    uniform float pulseSpeed;

    // --- WAVE ---
    uniform float waveAmp;
    uniform float waveFreq;
    uniform float waveSpeed;

    // --- CHROMATIC ---
    uniform float aberrationAmount;

    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
        vec2 uv = texture_coords;

        // 1. APLICA WAVE (Distorção da coordenada)
        if (waveAmp > 0.0) {
            uv.x += sin((uv.y * waveFreq) + (time * waveSpeed)) * waveAmp;
            uv = clamp(uv, 0.0, 1.0); // Evita pegar pixel fora da imagem
        }

        vec4 pixel = vec4(0.0);

        // 2. AMOSTRAGEM DE TEXTURA (Normal ou Cromática)
        if (aberrationAmount > 0.0) {
            vec2 dir = vec2(cos(time * 2.0), sin(time * 2.0));
            float r = Texel(texture, uv + dir * aberrationAmount).r;
            float g = Texel(texture, uv).g;
            float b = Texel(texture, uv - dir * aberrationAmount).b;
            float a = Texel(texture, uv).a;
            pixel = vec4(r, g, b, a);
        } else {
            pixel = Texel(texture, uv);
        }

        // 3. OUTLINE
        // Só desenha outline se pixel for transparente E tiver vizinho sólido
        if (outlineAlpha > 0.0 && pixel.a == 0.0) {
            vec2 onePixel = vec2(1.0) / textureSize;
            float found = 0.0;

            // Checa os 8 vizinhos
            for (float x = -1.0; x <= 1.0; x += 1.0) {
                for (float y = -1.0; y <= 1.0; y += 1.0) {
                    if (x == 0.0 && y == 0.0) continue;
                    
                    vec4 neighbor = Texel(texture, uv + vec2(x,y) * onePixel);
                    if (neighbor.a > 0.0) {
                        found = 1.0;
                    }
                }
            }

            if (found > 0.0) {
                float pulse = sin(time * pulseSpeed) * 0.5 + 0.5;
                // Mistura intensidade base com pulso
                float finalA = mix(outlineAlpha * 0.5, outlineAlpha, pulse);
                return vec4(outlineColor, finalA);
            }
        }

        // 4. HIT FLASH (Pinta de branco por cima)
        if (flashAmount > 0.0) {
            // Mistura a cor atual com branco puro baseado no flashAmount
            pixel.rgb = mix(pixel.rgb, vec3(1.0), flashAmount * pixel.a);
        }

        return pixel * color;
    }
]]

Shaders.pixelate = love.graphics.newShader[[
    extern float pixel_size;
    extern vec2 res;

    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
        // Quantiza as coordenadas para criar o efeito de "escada" de pixel art
        vec2 p = floor(texture_coords * res / pixel_size) * pixel_size / res;
        return Texel(texture, p) * color;
    }
]]

-- =============================================================
--                    FUNÇÕES DE CONTROLE
-- =============================================================

function Shaders:update(dt)
    self.time = self.time + dt
    self.uber:send("time", self.time)
end

-- Reseta todos os efeitos para "desligado"
-- Chame isso antes de configurar um novo inimigo
function Shaders:reset()
    self.uber:send("flashAmount", 0.0)
    self.uber:send("outlineAlpha", 0.0) -- 0 desliga o outline
    self.uber:send("waveAmp", 0.0)      -- 0 desliga o wave
    self.uber:send("aberrationAmount", 0.0)
    self.uber:send("textureSize", {16, 16}) -- Padrão, será atualizado
end

-- Configura tamanho da textura (essencial para outline)
function Shaders:setTextureSize(image)
    if image then
        self.uber:send("textureSize", {image:getWidth(), image:getHeight()})
    end
end

-- Ativa o shader globalmente
function Shaders:use()
    love.graphics.setShader(self.uber)
end

function Shaders:clear()
    love.graphics.setShader()
end

-- =============================================================
--                    APLICADORES DE EFEITO (STACKABLE)
-- =============================================================

function Shaders:applyOutline(enemy, r, g, b, alpha, pulseSpeed)
    self.uber:send("outlineColor", {r, g, b})
    self.uber:send("outlineAlpha", alpha or 1.0)
    self.uber:send("pulseSpeed", pulseSpeed or 3.0)
    if enemy.image then self:setTextureSize(enemy.image) end
end

function Shaders:applyWave(enemy, amp, freq, speed)
    self.uber:send("waveAmp", amp or 0.02)
    self.uber:send("waveFreq", freq or 10.0)
    self.uber:send("waveSpeed", speed or 3.0)
    if enemy.image then self:setTextureSize(enemy.image) end
end

function Shaders:applyHitFlash(amount)
    self.uber:send("flashAmount", amount or 0.0)
end

function Shaders:applyChromaticAberration(amount)
    self.uber:send("aberrationAmount", amount or 0.003)
end

-- =============================================================
--                    PRESETS DE ARMAS E INIMIGOS
-- =============================================================

-- Atualizado para funcionar com o novo sistema
function Shaders:applyProjectileShader(projectile_image, player)
    self:reset() -- Limpa estados anteriores
    
    local effects = 0
    if player.veneno then effects = effects + 1 end
    if player.fogo then effects = effects + 1 end
    if player.gelo then effects = effects + 1 end
    
    if effects == 0 then return end -- Não ativa shader se não tiver efeitos

    local r, g, b = 1, 1, 1
    local pulse = 3.0
    local alpha = 0.8

    if effects >= 2 then
        r, g, b = 0.1, 0.1, 0.1
        pulse = 6.0
    elseif player.fogo then
        r, g, b = 1.0, 0.2, 0.0
        pulse = 8.0
    elseif player.veneno then
        r, g, b = 0.2, 1.0, 0.2
        pulse = 2.0
    elseif player.gelo then
        r, g, b = 0.0, 0.8, 1.0
        pulse = 0.0
        alpha = 1.0
    end

    self:applyOutline({image=projectile_image}, r, g, b, alpha, pulse)
    self:use()
end

-- =============================================================
--                    PRESETS (Só configuram valores)
-- =============================================================

Shaders.presets = {
    common = function(self, enemy)
        self:applyOutline(enemy, 0, 0, 0, 0.65, 3.0)
    end,
    fire = function(self, enemy)
        self:applyOutline(enemy, 1.0, 0.2, 0.0, 1.0, 5.0)
    end,
    bomb = function(self, enemy)
        self:applyOutline(enemy, 1.0, 0.7, 0.0, 1.0, 8.0)
    end,
    ice = function(self, enemy)
        -- Gelo agora tem Outline Ciano + Wave
        self:applyOutline(enemy, 0.0, 0.8, 1.0, 0.8, 1.0) 
    end,
    boss = function(self, enemy)
        self:applyChromaticAberration(0.015)
        self:applyOutline(enemy, 0.5, 0.0, 0.5, 0.5, 2.0)
    end,
    poison = function(self, enemy)
        self:applyOutline(enemy, 0.2, 1.0, 0.2, 0.8, 2.0)
    end,
}

-- =============================================================
--                    SISTEMA DE FLASH (Manter igual)
-- =============================================================

function Shaders:initEnemyFlash(enemy)
    enemy.flash_timer = 0
    enemy.flash_duration = 0.15
end

function Shaders:triggerFlash(enemy)
    enemy.flash_timer = enemy.flash_duration or 0.15
end

function Shaders:updateEnemyFlash(enemy, dt)
    if enemy.flash_timer and enemy.flash_timer > 0 then
        enemy.flash_timer = enemy.flash_timer - dt
    end
end

function Shaders:isFlashing(enemy)
    return enemy.flash_timer and enemy.flash_timer > 0
end

function Shaders:getFlashAmount(enemy)
    if not enemy.flash_timer or enemy.flash_timer <= 0 then
        return 0
    end
    return enemy.flash_timer / (enemy.flash_duration or 0.15)
end

return Shaders