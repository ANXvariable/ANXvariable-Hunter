-- Utility function for getting paths concisely
rapi_sprite = function(identifier, filename, image_number, x_origin, y_origin) 
    local sprite_path = path.combine(PATH, "Sprites",  filename)
    return Sprite.new(identifier, sprite_path, image_number, x_origin, y_origin)
end
rapi_sound = function(id, filename)
    local sound_path = path.combine(PATH, "Sounds", filename)
    return Sound.new(id, sound_path)
end
function math_random_float(arg0)
    return (math.random(0, (2 ^ 31) - 1)) / ((2 ^ 31) - 1) * arg0
end
function switch(input, case)
    if case[input] then
        return case[input]()
    end
    return case.default()
end