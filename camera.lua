-- camera.lua
local Camera = {
    x = 0,
    y = 0,
    shakeDuration = 0,
    shakeMagnitude = 0,
    shakeTimer = 0,
}

function Camera:update(dt)
    if self.shakeTimer > 0 then
        self.shakeTimer = self.shakeTimer - dt
        self.x = love.math.random(-self.shakeMagnitude, self.shakeMagnitude)
        self.y = love.math.random(-self.shakeMagnitude, self.shakeMagnitude)
        if self.shakeTimer <= 0 then
            self.x, self.y = 0, 0
        end
    end
end

function Camera:apply()
    love.graphics.push()
    love.graphics.translate(self.x, self.y)
end

function Camera:clear()
    love.graphics.pop()
end

function Camera:shake(duration, magnitude)
    self.shakeTimer = duration
    self.shakeMagnitude = magnitude
end

return Camera