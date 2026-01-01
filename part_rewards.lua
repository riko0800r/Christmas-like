local Particles = {}

Particles.list = {}

function Particles.spawn(x, y, options)
    local opts = options or {}
    local p = {
        x = x or math.random(0, love.graphics.getWidth()),
        y = y or 0,
        vx = opts.vx or 0,
        vy = opts.vy or math.random(40, 120),
        size = opts.size or math.random(8, 16),
        life = opts.life or 2,
        alpha = 1,
        image = opts.image or nil,
        shape = opts.shape or "circle",
        color = opts.color or {1, 1, 1},
        gravity = opts.gravity or 0.1
    }
    table.insert(Particles.list, p)
end

function Particles.update(dt)
    for i = #Particles.list, 1, -1 do
        local p = Particles.list[i]
        p.life = p.life - dt
        if p.life <= 0 then
            table.remove(Particles.list, i)
        else
            p.y = p.y + p.vy * dt
            p.vy = p.vy + p.gravity * dt
            p.alpha = p.life / 2  -- fade
        end
    end
end

function Particles.draw()
    for _, p in ipairs(Particles.list) do
        love.graphics.setColor(p.color[1], p.color[2], p.color[3], p.alpha)
        if p.image then
            local w, h = p.image:getDimensions()
            love.graphics.draw(p.image, p.x, p.y, 0, p.size / w, p.size / h)
        else
            if p.shape == "circle" then
                love.graphics.circle("fill", p.x, p.y, p.size / 2)
            elseif p.shape == "square" then
                love.graphics.rectangle("fill", p.x, p.y, p.size, p.size)
            end
        end
    end
    love.graphics.setColor(1, 1, 1, 1)
end

return Particles