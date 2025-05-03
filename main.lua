-- Samus

log.info("Loading ".._ENV["!guid"]..".")
local envy = mods["LuaENVY-ENVY"]
envy.auto()
mods["RoRRModdingToolkit-RoRR_Modding_Toolkit"].auto()

local PATH = _ENV["!plugins_mod_folder_path"]
local NAMESPACE = "ANXvariable"



-- ========== Main ==========

local initialize = function() 
    local samus = Survivor.new(NAMESPACE, "samus")

    -- Utility function for getting sprite paths concisely
    local load_sprite = function (id, filename, frames, orig_x, orig_y, speed, left, top, right, bottom) 
        local sprite_path = path.combine(PATH, "Sprites",  filename)
        return Resources.sprite_load(NAMESPACE, id, sprite_path, frames, orig_x, orig_y, speed, left, top, right, bottom)
    end
    
    -- Load the common survivor sprites into a table
    local sprites = {
        idle = load_sprite("samus_idle", "sSamusIdle.png", 1, 14, 18),
        walk = load_sprite("samus_walk", "sSamusRun.png", 4, 12, 20),
        jump = load_sprite("samus_jump", "sSamusRun.png", 4, 12, 20),
        jump_peak = load_sprite("samus_jump_peak", "sSamusRun.png", 4, 12, 20),
        fall = load_sprite("samus_fall", "sSamusRun.png", 4, 12, 20),
        climb = load_sprite("samus_climb", "sSamusRun.png", 4, 12, 20),
        climb_hurt = load_sprite("samus_climb_hurt", "sSamusRun.png", 4, 12, 20), 
        death = load_sprite("samus_death", "sSamusRun.png", 4, 12, 20),
        decoy = load_sprite("samus_decoy", "sSamusRun.png", 4, 12, 20),
    }

    --placeholder
    local spr_skills = load_sprite("samus_skills", "sSamusSkills.png", 5, 0, 0)
    local spr_loadout = load_sprite("samus_loadout", "sSelectSamus.png", 4, 28, 0)
    local spr_portrait = load_sprite("samus_portrait", "sSamusPortrait.png", 3)
    local spr_portrait_small = load_sprite("samus_portrait_small", "sSamusPortraitSmall.png")
    local spr_portrait_cropped = load_sprite("samus_portrait_cropped", "sSamusPortraitC.png") 

    -- Assign sprites to various survivor fields
    samus.sprite_loadout = spr_loadout
    samus.sprite_portrait = spr_portrait
    samus.sprite_portrait_small = spr_portrait_small
    samus.sprite_portrait_palette = spr_portrait_cropped
    samus.sprite_title = sprites.walk
    samus.sprite_idle = sprites.idle
    samus.sprite_credits = sprites.idle
    samus:set_animations(sprites)

    -- Survivor stats
    samus:set_stats_base({
        maxhp = 300,
        damage = 15,
        regen = 0.02
    })

    samus:set_stats_level({
        maxhp = 75,
        damage = 4,
        regen = 0.004,
    })
    
    -- Grab references to skills.  Consider renaming the variables to match your skill names, in case 
    -- you want to switch which skill they're assigned to in future.
    local skill_primary = samus:get_primary()
    local skill_secondary = samus:get_secondary()
    local skill_utility = samus:get_utility()
    local skill_special = samus:get_special()

    -- Set the animations for each skill
    skill_primary:set_skill_animation(sprites.walk)
    skill_secondary:set_skill_animation(sprites.walk)
    skill_utility:set_skill_animation(sprites.walk)
    skill_utility:set_skill_animation(sprites.walk)
    
    -- Set the icons for each skill, specifying the icon spritesheet and the specific subimage
    skill_primary:set_skill_icon(spr_skills, 0)
    skill_secondary:set_skill_icon(spr_skills, 1)
    skill_utility:set_skill_icon(spr_skills, 2)
    skill_special:set_skill_icon(spr_skills, 3)
    
    -- Set the damage coefficient and cooldown for each skill. A damage coefficient of 100% is equal
    -- to 1.0, 150% to 1.5, 200% to 2.0, and so on. Cooldowns are specified in frames, so multiply by
    -- 60 to turn that into actual seconds.
    skill_primary:set_skill_properties(2.5, 0)
    skill_secondary:set_skill_properties(4.0, 120)
    skill_utility:set_skill_properties(0.0, 240)
    skill_special:set_skill_properties(0.0, 20)
    

    
    
end
Initialize(initialize)

-- ** Uncomment the two lines below to re-call initialize() on hotload **
-- if hotload then initialize() end
-- hotload = true


gm.post_script_hook(gm.constants.__input_system_tick, function(self, other, result, args)
    -- This is an example of a hook
    -- This hook in particular will run every frame after it has finished loading (i.e., "Hopoo Games" appears)
    -- You can hook into any function in the game
    -- Use pre_script_hook instead to run code before the function
    -- https://github.com/return-of-modding/ReturnOfModding/blob/master/docs/lua/tables/gm.md
    
end)