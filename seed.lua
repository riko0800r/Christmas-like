-- seed.lua
local Seed = {}

-- Gera uma seed aleatória de até 6 caracteres alfanuméricos
function Seed.generate_random()
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local seed = ""
    for i = 1, 6 do
        local index = love.math.random(1, #chars)
        seed = seed .. chars:sub(index, index)
    end
    return seed
end

-- Converte uma seed (string) em número determinístico
function Seed.to_number(seed_str)
    local num = 0
    for i = 1, #seed_str do
        num = num + string.byte(seed_str, i) * i
    end
    return num
end

-- Define a seed atual
function Seed.set(seed_str)
    Seed.current = seed_str
    love.math.setRandomSeed(Seed.to_number(seed_str))
end

-- Retorna a seed atual
function Seed.get()
    return Seed.current or "NONE"
end

-- Cria seed aleatória nova e aplica
function Seed.new_random()
    math.randomseed(os.time())
    local new_seed = Seed.generate_random()
    Seed.set(new_seed)
    return new_seed
end

-- Gera uma seed determinística baseada no dia atual
function Seed.new_random_por_dia()
    -- 1. Obtém a data atual em uma tabela
    local t = os.date("*t")
    
    -- 2. Cria um número de seed único e determinístico para o dia
    --    Ex: 16/11/2025 -> 20251116
    local seed_numerica_do_dia = t.year * 10000 + t.month * 100 + t.day
    
    -- 3. Define a seed do LÖVE temporariamente com esse número
    --    Isso garante que a função Seed.generate_random()
    --    sempre gere a *mesma* string de 6 caracteres para este dia.
    love.math.setRandomSeed(seed_numerica_do_dia)
    
    -- 4. Gera a seed de 6 caracteres (que agora é determinística)
    local seed_string_do_dia = Seed.generate_random()
    
    -- 5. Define a seed principal do jogo usando a string gerada
    --    Isso irá re-semear (re-seed) o love.math para o estado
    --    de jogo final, baseado na string (ex: "AX42B9")
    Seed.set(seed_string_do_dia)
    
    -- 6. Retorna a seed do dia para quem chamou a função
    return seed_string_do_dia
end

return Seed