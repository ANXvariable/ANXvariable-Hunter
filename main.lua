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
        idle = load_sprite("samus_idle", "sSamusIdle.png", 1, 14, 20),
        walk = load_sprite("samus_walk", "sSamusRun.png", 4, 12, 25),
        jump = load_sprite("samus_jump", "sSamusRun.png", 4, 12, 25),
        jump_peak = load_sprite("samus_jump_peak", "sSamusRun.png", 4, 12, 25),
        fall = load_sprite("samus_fall", "sSamusRun.png", 4, 12, 25),
        climb = load_sprite("samus_climb", "sSamusRun.png", 4, 12, 25),
        climb_hurt = load_sprite("samus_climb_hurt", "sSamusRun.png", 4, 12, 25), 
        death = load_sprite("samus_death", "sSamusRun.png", 4, 12, 25),
        decoy = load_sprite("samus_decoy", "sSamusRun.png", 4, 12, 25),
    }

    --placeholder category, todo organize later
    local spr_skills = load_sprite("samus_skills", "sSamusSkills.png", 5, 0, 0)
    local spr_loadout = load_sprite("samus_loadout", "sSelectSamus.png", 4, 28, 0)
    local spr_portrait = load_sprite("samus_portrait", "sSamusPortrait.png", 3)
    local spr_portrait_small = load_sprite("samus_portrait_small", "sSamusPortraitSmall.png")
    local spr_portrait_cropped = load_sprite("samus_portrait_cropped", "sSamusPortraitC.png")
    local spr_flashshift = load_sprite("samus_flashshift", "sSamusFlashShift.png", 4, 12, 25)
    local spr_beam = load_sprite("samus_beam", "sSamusBeam.png", 4)
    local spr_missile = load_sprite("samus_missile", "sSamusMissile.png")
    local spr_missile_explosion = gm.sprite_duplicate(1848)

    -- Colour for the character's skill names on character select
    samus:set_primary_color(Color.from_rgb(8, 253, 142))

    -- Assign sprites to various survivor fields
    samus.sprite_loadout = spr_loadout
    samus.sprite_portrait = spr_portrait
    samus.sprite_portrait_small = spr_portrait_small
    samus.sprite_portrait_palette = spr_portrait_cropped
    samus.sprite_title = sprites.walk
    samus.sprite_idle = sprites.idle
    samus.sprite_credits = sprites.idle
    samus:set_animations(sprites)

    -- Offset for the cape visual
    samus:set_cape_offset(-1, -6, 0, -5)


    -- Survivor stats
    samus:set_stats_base({
        maxhp = 300,
        damage = 16,
        regen = 0.02
    })

    samus:set_stats_level({
        maxhp = 75,
        damage = 4,
        regen = 0.004,
    })

    local obj_beam = Object.new(NAMESPACE, "samus_beam")
    obj_beam.obj_sprite = spr_beam
    obj_beam.obj_depth = 1
    
    obj_beam:onStep(function(instance)
        local data = instance:get_data()
        instance.x = instance.x + data.horizontal_velocity

        -- Hit the first enemy actor that's been collided with
        local actor_collisions, _ = instance:get_collisions(gm.constants.pActorCollisionBase)
        for _, other_actor in ipairs(actor_collisions) do
            if data.parent:attack_collision_canhit(other_actor) then
                -- Deal damage
                local damage_direction = 0
                if data.horizontal_velocity < 0 then
                    damage_direction = 180
                end
                data.parent:fire_direct(other_actor, data.damage_coefficient, damage_direction, instance.x, instance.y, spr_none)

                -- Destroy the beam
                instance:destroy()
                return
            end
        end

        -- Hitting terrain destroys the beam
        if instance:is_colliding(gm.constants.pSolidBulletCollision) then
            instance:destroy()
            return
        end

        -- Check we're within stage bounds
        local stage_width = GM._mod_room_get_current_width()
        local stage_height = GM._mod_room_get_current_height()
        if instance.x < -16 or instance.x > stage_width + 16 
           or instance.y < -16 or instance.y > stage_height + 16 
        then 
            instance:destroy()
            return
        end

        -- The beam cannot exist for too long
        if instance.statetime >= 20 + (instance.duration) then
            instance:destroy()
            return
        end
        instance.statetime = instance.statetime + 1
    end)

    local obj_missile = Object.new(NAMESPACE, "samus_missile")
    obj_missile.obj_sprite = spr_missile
    obj_missile.obj_depth = 1
    
    obj_missile:onStep(function(instance)
        local data = instance:get_data()
        instance.x = instance.x + data.horizontal_velocity
        if data.horizontal_velocity < 12
            and  data.horizontal_velocity > 0
        then
            data.horizontal_velocity = data.horizontal_velocity + 0.5
        end
        
        if data.horizontal_velocity < 0
            and  data.horizontal_velocity > -12
        then
            data.horizontal_velocity = data.horizontal_velocity - 0.5
        end

        -- Hit the first enemy actor that's been collided with
        local actor_collisions, _ = instance:get_collisions(gm.constants.pActorCollisionBase)
        for _, other_actor in ipairs(actor_collisions) do
            if data.parent:attack_collision_canhit(other_actor) then
                -- Deal damage
                local damage_direction = 0
                if data.horizontal_velocity < 0 then
                    damage_direction = 180
                end
                data.parent:fire_direct(other_actor, data.damage_coefficient, damage_direction, instance.x, instance.y, spr_none)

                -- Destroy the missile
                instance:destroy()
                return
            end
        end

        -- Hitting terrain destroys the missile
        if instance:is_colliding(gm.constants.pSolidBulletCollision) then
            instance:destroy()
            return
        end

        -- Check we're within stage bounds
        local stage_width = GM._mod_room_get_current_width()
        local stage_height = GM._mod_room_get_current_height()
        if instance.x < -16 or instance.x > stage_width + 16 
           or instance.y < -16 or instance.y > stage_height + 16 
        then 
            instance:destroy()
            return
        end

        -- The missile cannot exist for too long
        if instance.statetime >= 360 then
            instance:destroy()
            return
        end
        instance.statetime = instance.statetime + 1
    end)
    
    
    -- Grab references to skills. Consider renaming the variables to match your skill names, in case 
    -- you want to switch which skill they're assigned to in future.
    local skill_primary = samus:get_primary()
    local skill_secondary = samus:get_secondary()
    local skill_utility = samus:get_utility()
    local skill_special = samus:get_special()

    -- Set the animations for each skill
    skill_primary:set_skill_animation(sprites.walk)
    skill_secondary:set_skill_animation(sprites.walk)
    skill_utility:set_skill_animation(spr_flashshift)
    skill_special:set_skill_animation(sprites.walk)
    
    -- Set the icons for each skill, specifying the icon spritesheet and the specific subimage
    skill_primary:set_skill_icon(spr_skills, 0)
    skill_secondary:set_skill_icon(spr_skills, 1)
    skill_utility:set_skill_icon(spr_skills, 2)
    skill_special:set_skill_icon(spr_skills, 3)
    
    -- Set the damage coefficient and cooldown for each skill. A damage coefficient of 100% is equal
    -- to 1.0, 150% to 1.5, 200% to 2.0, and so on. Cooldowns are specified in frames, so multiply by
    -- 60 to turn that into actual seconds.
    skill_primary:set_skill_properties(1.2, 0)
    skill_secondary:set_skill_properties(4.0, 120)
    skill_secondary:set_skill_stock(5, 5, true, 1)
    skill_utility:set_skill_properties(0.0, 240)
    skill_utility:set_skill_stock(2, 2, true, 1)
    skill_utility.is_utility = true
    skill_special:set_skill_properties(0.0, 20)

    -- Again consider renaming these variables after the ability itself
    local state_primary = State.new(NAMESPACE, skill_primary.identifier)
    local state_secondary = State.new(NAMESPACE, skill_secondary.identifier)
    local state_utility = State.new(NAMESPACE, skill_utility.identifier)
    local state_special = State.new(NAMESPACE, skill_special.identifier)
    
    -- Register callbacks that switch states when skills are activated
    skill_primary:onActivate(function(actor, skill, index)
        actor:enter_state(state_primary)
    end)
    
    skill_secondary:onActivate(function(actor, skill, index)
        actor:enter_state(state_secondary)
    end)
    
    skill_utility:onActivate(function(actor, skill, index)
        actor:enter_state(state_utility)
    end)
    
    skill_special:onActivate(function(actor, skill, index)
        actor:enter_state(state_special)
    end)

    -- Executed when state_primary is entered
    state_primary:onEnter(function(actor, data)
        actor.image_index = 0 -- Make sure our animation starts on its first frame
        -- From here we can setup custom data that we might want to refer back to in onStep
        -- Our flag to prevent firing more than once per attack
        data.fired = 0
 
    end)
    
    -- Executed every game tick during this state
    state_primary:onStep(function(actor, data)
        -- Set the animation and animation speed. This speed will automatically have the survivor's 
        -- attack speed bonuses applied (e.g. from Soldier's Syringe)
        local animation = actor:actor_get_skill_animation(skill_primary)
        actor:actor_animation_set(animation, 0.25) -- 0.25 means 4 ticks per frame at base attack speed

        if actor.image_index >= 0 and data.fired == 0 then
            data.fired = 1
    
            local direction = GM.cos(GM.degtorad(actor:skill_util_facing_direction()))
            local buff_shadow_clone = Buff.find("ror", "shadowClone")
            for i=0, actor:buff_stack_count(buff_shadow_clone) do 
                local spawn_offset = 5 * direction
                local beam = obj_beam:create(actor.x + spawn_offset, actor.y)
                beam.image_xscale = direction
                beam.statetime = 0
                beam.dmg = actor.damage
                beam.duration = math.min(actor.level * 10, 200)
                local beam_data = beam:get_data()
                beam_data.parent = actor
                beam_data.horizontal_velocity = 10 * direction
                local damage = actor:skill_get_damage(skill_primary)
                beam_data.damage_coefficient = damage


            end
            actor:sound_play(gm.constants.wSpiderShoot1, 1, 0.8 + math.random() * 0.2)
        end
    
    
        -- A convenience function that exits this state automatically once the animation ends
        actor:skill_util_exit_state_on_anim_end()
    end)

    -- Executed when state_secondary is entered
    state_secondary:onEnter(function(actor, data)
        actor.image_index = 0 -- Make sure our animation starts on its first frame
        -- From here we can setup custom data that we might want to refer back to in onStep
        -- Our flag to prevent firing more than once per attack
        data.fired = 0
 
    end)
    
    -- Executed every game tick during this state
    state_secondary:onStep(function(actor, data)
        -- Set the animation and animation speed. This speed will automatically have the survivor's 
        -- attack speed bonuses applied (e.g. from Soldier's Syringe)
        local animation = actor:actor_get_skill_animation(skill_secondary)
        actor:actor_animation_set(animation, 0.25) -- 0.25 means 4 ticks per frame at base attack speed

        if actor.image_index >= 0 and data.fired == 0 then
            data.fired = 1
    
            local direction = GM.cos(GM.degtorad(actor:skill_util_facing_direction()))
            local buff_shadow_clone = Buff.find("ror", "shadowClone")
            for i=0, actor:buff_stack_count(buff_shadow_clone) do 
                local spawn_offset = 5 * direction
                local missile = obj_missile:create(actor.x + spawn_offset, actor.y)
                missile.image_xscale = direction
                missile.statetime = 0
                local missile_data = missile:get_data()
                missile_data.parent = actor
                missile_data.horizontal_velocity = 0.5 * direction
                local damage = actor:skill_get_damage(skill_secondary)
                missile_data.damage_coefficient = damage


            end
            actor:sound_play(gm.constants.wMissileLaunch, 1, 0.8 + math.random() * 0.2)
        end
    
    
        -- A convenience function that exits this state automatically once the animation ends
        actor:skill_util_exit_state_on_anim_end()
    end)

    -- Executed when state_utility is entered
    state_utility:onEnter(function(actor, data)
        actor.image_index = 0 -- Make sure our animation starts on its first frame
        -- From here we can setup custom data that we might want to refer back to in onStep
        -- Our flag to prevent firing more than once per attack
        actor:sound_play(gm.constants.wHuntressShoot3, 1, 0.8 + math.random() * 0.2)
    end)
    
    -- Executed every game tick during this state
    state_utility:onStep(function(actor, data)
        actor:skill_util_fix_hspeed()
        -- Set the animation and animation speed. This speed will automatically have the survivor's 
        -- attack speed bonuses applied (e.g. from Soldier's Syringe)
        local animation = actor:actor_get_skill_animation(skill_utility)
        local animation_speed = 0.25

        -- We don't want attack speed to speed up the dodge itself, because that could end up
        -- reducing the dodge window, so we undo its benefit ahead of time
        if actor.attack_speed > 0 then
            animation_speed = animation_speed / actor.attack_speed
        end

        actor:actor_animation_set(animation, animation_speed)

        local direction = GM.cos(GM.degtorad(actor:skill_util_facing_direction()))
        local buff_shadow_clone = Buff.find("ror", "shadowClone")
        if actor.invincible < 10 then 
            actor.invincible = 10
        end
        actor.pHspeed = direction * actor.pHmax * 6
        actor.pVspeed = 0
        
        -- A convenience function that exits this state automatically once the animation ends
        actor:skill_util_exit_state_on_anim_end()
    end)

    state_utility:onExit(function(actor, data)
        if actor.invincible <= 10 then
            actor.invincible = 0
        end
        actor.pHspeed = 0
 
    end)

    -- Executed when state_special is entered
    state_special:onEnter(function(actor, data)
        actor.image_index = 0 -- Make sure our animation starts on its first frame
        -- From here we can setup custom data that we might want to refer back to in onStep
        -- Our flag to prevent firing more than once per attack
        data.fired = 0
 
    end)
    
    -- Executed every game tick during this state
    state_special:onStep(function(actor, data)
        -- Set the animation and animation speed. This speed will automatically have the survivor's 
        -- attack speed bonuses applied (e.g. from Soldier's Syringe)
        local animation = actor:actor_get_skill_animation(skill_special)
        actor:actor_animation_set(animation, 0.25) -- 0.25 means 4 ticks per frame at base attack speed

        if actor.image_index >= 3 and data.fired == 0 then
            data.fired = 1
    
            local direction = GM.cos(GM.degtorad(actor:skill_util_facing_direction()))
            local buff_shadow_clone = Buff.find("ror", "shadowClone")
        end
    
    
        -- A convenience function that exits this state automatically once the animation ends
        actor:skill_util_exit_state_on_anim_end()
    end)

    

    
    
end
Initialize(initialize)

-- ** Uncomment the two lines below to re-call initialize() on hotload **
-- if hotload then initialize() end
-- hotload = true


gm.post_script_hook(gm.constants.__input_system_tick, function(self, other, result, args)
    -- This is an example of a hook
    -- This hook in particular will run every frame after it has finished loading (i.e., "Hopoo Games" appears)
    -- You can hook into any function in the game
    -- Use pre_script_hook 'stead to run code before the function
    -- https://github.com/return-of-modding/ReturnOfModding/blob/master/docs/lua/tables/gm.md
    
end)