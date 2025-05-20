-- Hunter
-- check how you can make immune to debuffs. and water

log.info("Loading ".._ENV["!guid"]..".")
local envy = mods["LuaENVY-ENVY"]
envy.auto()
mods["RoRRModdingToolkit-RoRR_Modding_Toolkit"].auto(true)

local PATH = _ENV["!plugins_mod_folder_path"]
local NAMESPACE = "ANXvariable"



-- ========== Main ==========

local initialize = function() 
    local hunter = Survivor.new(NAMESPACE, "hunter")

    --tempsection
        local hijump = Item.new(NAMESPACE, "hiJumpBoots", true)
        hijump:set_sprite(gm.constants.sJetpack)
        hijump:set_tier(5)
        hijump:set_loot_tags(Item.LOOT_TAG.item_blacklist_engi_turrets)
        hijump:toggle_loot(false)
        hijump.is_hidden = true
        hijump:clear_callbacks()
        hijump:onStatRecalc(function(actor, stack)
            actor.pVmax = actor.pVmax + 2.4 * stack
        end)

        local missiletank = Item.new(NAMESPACE, "missileTank", true)
        missiletank:set_sprite(gm.constants.sMissileBox)
        missiletank:set_tier(5)
        missiletank:set_loot_tags(Item.LOOT_TAG.item_blacklist_engi_turrets)
        missiletank:toggle_loot(false)
        missiletank.is_hidden = true
        missiletank:clear_callbacks()
        missiletank:onAcquire(function(actor, stack)
            local skill2 = actor:get_active_skill(Skill.SLOT.secondary)
            skill2.stock = skill2.stock + 1
        end)
        missiletank:onStatRecalc(function(actor, stack)
            local skill2 = actor:get_active_skill(Skill.SLOT.secondary)
            skill2.max_stock = skill2.max_stock + stack
        end)

        local spazerbeam = Item.new(NAMESPACE, "spazerBeam", true)
        spazerbeam:set_sprite(gm.constants.sJewel)
        spazerbeam:set_tier(5)
        spazerbeam:set_loot_tags(Item.LOOT_TAG.category_damage)
        spazerbeam:toggle_loot(false)
        spazerbeam.is_hidden = true
        spazerbeam:clear_callbacks()

        local icebeam = Item.new(NAMESPACE, "iceBeam", true)
        icebeam:set_sprite(gm.constants.sIceRelic)
        icebeam:set_tier(5)
        icebeam:set_loot_tags(Item.LOOT_TAG.category_damage)
        icebeam:toggle_loot(false)
        icebeam.is_hidden = true
        icebeam:clear_callbacks()

        local wavebeam = Item.new(NAMESPACE, "waveBeam", true)
        wavebeam:set_sprite(gm.constants.sTesla)
        wavebeam:set_tier(5)
        wavebeam:set_loot_tags(Item.LOOT_TAG.category_damage)
        wavebeam:toggle_loot(false)
        wavebeam.is_hidden = true
        wavebeam:clear_callbacks()

    --end-tempsection

    -- Utility function for getting paths concisely
    local load_sprite = function (id, filename, frames, orig_x, orig_y, speed, left, top, right, bottom) 
        local sprite_path = path.combine(PATH, "Sprites",  filename)
        return Resources.sprite_load(NAMESPACE, id, sprite_path, frames, orig_x, orig_y, speed, left, top, right, bottom)
    end
    local load_sound = function (id, filename)
        local sound_path = path.combine(PATH, "Sounds", filename)
        return Resources.sfx_load(NAMESPACE, id, sound_path)
    end
    
    -- Load the common survivor sprites into a table
    local sprites = {
        idle = load_sprite("hunter_idle", "sHunterIdle.png", 1, 14, 15),
        walk = load_sprite("hunter_walk", "sHunterRun.png", 4, 12, 24),
        jump = load_sprite("hunter_jump", "sHunterSault.png", 4, 14, 14),
        jump_peak = load_sprite("hunter_jump_peak", "sHunterSault.png", 4, 14, 14),
        fall = load_sprite("hunter_fall", "sHunterSault.png", 4, 14, 14),
        climb = load_sprite("hunter_climb", "sHunterElevator.png", 1, 14, 18),
        climb_hurt = load_sprite("hunter_climb_hurt", "sHunterElevator.png", 1, 14, 18), 
        death = load_sprite("hunter_death", "sHunterDeath.png", 20, 34, 58),
        decoy = load_sprite("hunter_decoy", "sHunterRun.png", 4, 14, 24),
    }

    --spr_half
    local spr_idle_half = load_sprite("hunter_idle_half", "sHunterIdleHalf.png", 1, 14, 15)
    local spr_walk_half = load_sprite("hunter_walk_half", "sHunterRunHalf.png", 4, 12, 24)
    local spr_jump_half = load_sprite("hunter_jump_half", "sHunterJumpHalf.png", 1, 12, 24)
    local spr_jump_peak_half = load_sprite("hunter_jump_peak_half", "sHunterJumpHalf.png", 1, 12, 24)
    local spr_fall_half = load_sprite("hunter_fall_half", "sHunterJumpHalf.png", 1, 12, 24)

    local spr_shoot1_half = load_sprite("hunter_shoot1_half", "sHunterShoot1Half.png", 4, 13, 25)
    local spr_shoot1_half_chargemask = load_sprite("hunter_shoot1_half_chargemask", "sHunterShoot1HalfChargeMask.png", 4, 13, 25)
    local spr_idle_half_chargemask = load_sprite("hunter_idle_half_chargemask", "sHunterIdleHalfChargeMask.png", 1, 14, 15)
    local spr_walk_half_chargemask = load_sprite("hunter_walk_half_chargemask", "sHunterRunHalfChargeMask.png", 4, 12, 24)
    local spr_jump_half_chargemask = load_sprite("hunter_jump_half_chargemask", "sHunterJumpHalfChargeMask.png", 1, 12, 24)
    
    --placeholder category, todo organize later
    local spr_skills = load_sprite("hunter_skills", "sHunterSkills.png", 5, 0, 0)
    local spr_loadout = load_sprite("hunter_loadout", "sSelectHunter.png", 4, 28)
    local spr_portrait = load_sprite("hunter_portrait", "sHunterPortrait.png", 3)
    local spr_portrait_small = load_sprite("hunter_portrait_small", "sHunterPortraitSmall.png")
    local spr_portrait_cropped = load_sprite("hunter_portrait_cropped", "sHunterPortraitC.png")
    local spr_log = load_sprite("hunter_log", "sPortraitHunter.png")
    local spr_flashshift = load_sprite("hunter_flashshift", "sHunterFlashShift.png", 4, 19, 17)
    local spr_flashshifttrail = load_sprite("hunter_flashshifttrail", "sHunterFlashShift.png", 4, 19, 17)
    --local spr_morphandbomb = load_sprite("hunter_morphandbomb", "sHunterMorphAndBomb.png", 10, 6, 0)
    local spr_morph = load_sprite("hunter_morph", "sHunterMorph.png", 8, 6, 0)
    local spr_beam = load_sprite("hunter_beam", "sHunterBeam.png", 4)
    local spr_beam_c0000 = load_sprite("hunter_beam_c0000", "sHunterBeamC0000.png", 4, 14, 4)
    local spr_beam_cs000 = load_sprite("hunter_beam_cs000", "sHunterBeamCS000.png", 4, 14, 4)
    local spr_beam_flare_0000 = load_sprite("hunter_beam_flare_0000", "sSparksHunterChargeFlare.png", 5, 12, 12)
    local spr_missile = load_sprite("hunter_missile", "sHunterMissile.png", 3, 22)
    local spr_missile_explosion = gm.constants.sEfMissileExplosion
    local spr_bomb = load_sprite("hunter_bomb", "sHunterBomb.png")
    local spr_powerbomb = load_sprite("hunter_powerbomb", "sHunterPowerBomb.png")
    local spr_powerbomb_explosion = load_sprite("hunter_powerbomb_explosion", "sHunterPowerBombExplode.png", 8, 889, 499)
    
    -- Colour for the character's skill names on character select
    hunter:set_primary_color(Color.from_rgb(8, 253, 142))

    --snd
    local snd_chargeloop = load_sound("hunter_chargeloop", "wDivineTP_CompleteAmbience_Loopable_steeled.ogg")
    local snd_ondeath = load_sound("hunter_chargeloop", "snd_badexplosion.ogg")

    -- Assign sprites to various survivor fields
    hunter.sprite_loadout = spr_loadout
    hunter.sprite_portrait = spr_portrait
    hunter.sprite_portrait_small = spr_portrait_small
    hunter.sprite_portrait_palette = spr_portrait_cropped
    hunter.sprite_title = sprites.walk
    hunter.sprite_idle = sprites.idle
    hunter.sprite_credits = sprites.idle
    hunter:set_animations(sprites)
    -- Offset for the Prophet's Cape
    hunter:set_cape_offset(-1, -6, -8, -1)

    local hunter_log = Survivor_Log.new(hunter, spr_log, sprites.walk)


    hunter:clear_callbacks()
    hunter:onInit(function(actor)
        local data = actor:get_data()
        actor.shiftedfrom = 0
        actor.sprite_idle_half = Array.new({sprites.idle, spr_idle_half, 0})
        actor.sprite_walk_half = Array.new({sprites.walk, spr_walk_half, 0})
        actor.sprite_jump_half = Array.new({sprites.jump, spr_jump_half, 0})
        actor.sprite_jump_peak_half = Array.new({sprites.jump_peak, spr_jump_peak_half, 0})
        actor.sprite_fall_half = Array.new({sprites.fall, spr_fall_half, 0})

        data.mtanks = 0
        data.HJB = 0
        data.SpJB = 0
        data.spazer = 0
        data.ice = 0
        data.wave = 0

        actor:survivor_util_init_half_sprites()
    end)


    -- Survivor stats
    hunter:set_stats_base({
        maxhp = 99,
        damage = 12,
        regen = 0.01
    })

    hunter:set_stats_level({
        maxhp = 32,
        damage = 3.3125,
        regen = 0.002,
    })

    hunter:onStep(function(actor)
        --walljumping
        local data = actor:get_data()
        local free = GM.bool(actor.free)
        local wallx = 0

        if actor:is_colliding(gm.constants.pSolidBulletCollision, actor.x - 3 - actor.pHmax / 2.8) and actor:control("right", 0) then
            wallx = -1
        elseif actor:is_colliding(gm.constants.pSolidBulletCollision, actor.x + 3 + actor.pHmax / 2.8) and actor:control("left", 0) then
            wallx = 1
        end
        local walljumpable = free and wallx ~= 0

        if walljumpable and not data.hunterJump_feather_preserve and not data.iceTool_feather_preserve then
            data.hunterJump_feather_preserve = actor.jump_count
            actor.jump_count = math.huge
        elseif walljumpable and not data.hunterJump_feather_preserve and data.iceTool_feather_preserve and data.iceTool_feather_preserve ~= math.huge then
            data.hunterJump_feather_preserve = data.iceTool_feather_preserve
        elseif walljumpable and not data.hunterJump_feather_preserve then
            data.hunterJump_feather_preserve = math.max(0, actor:item_stack_count(Item.find("ror", "hopooFeather")) - 1)
        elseif not walljumpable and data.hunterJump_feather_preserve and data.iceTool_feather_preserve ~= math.huge and data.hunterJump_feather_preserve ~= math.huge then
            actor.jump_count = data.hunterJump_feather_preserve
            data.hunterJump_feather_preserve = nil
        end
    --    if actor.jump_count ~= math.huge and (data.hunterJump_feather_preserve or data.iceTool_feather_preserve) then
    --        actor.jump_count = math.huge
    --    end
    --    the above lines stay commented or iceTool fucking kills me apparently even though that's where i got this from
    --    if free and (actor:control("left", 0) or actor:control("right", 0)) and actor:item_stack_count(Item.find("ssr", "iceTool")) > 0 then
    --        log.info("wallx =      "..wallx)
    --        log.info("jump_count = "..actor.jump_count)
    --        if data.hunterJump_feather_preserve then
    --        log.info("HJFP = "..data.hunterJump_feather_preserve)
    --        end
            if data.iceTool_feather_preserve then
            log.info("ITFP = "..data.iceTool_feather_preserve)
            end
    --    end--this info log stays uncommented because apparently data.iceTool_feather_preserve never returns true or something so I never saw this log. ever. so it stays while i test if it ever will work.

        if actor:control("jump", 1) and walljumpable and actor.actor_state_current_id ~= State.find(NAMESPACE, "hunterV").value then
            actor.pVspeed = -actor.pVmax - 1.5
	    	actor.free_jump_timer = 0
	    	actor.jumping = true
	    	actor.moveUp = false
	    	actor.moveUp_buffered = false

	    	actor.pHspeed = -actor.pHmax * wallx
	    	actor.image_xscale = -wallx
            if not GM.actor_state_is_climb_state(actor.actor_state_current_id) then
                actor:sound_play(gm.constants.wClayHit, 1, 1.25)
            end
        end
    --    if actor:control("jump", 1) then
    --        log.info("jc on jump = "..actor.jump_count)
    --    end

    --Missile tanks on -level
    if actor:item_stack_count(missiletank) < actor.level then
        actor:item_give(missiletank)
        data.mtanks = actor:item_stack_count(missiletank)
    end

    --Hi-jump boots on-level
    if actor.level >= 10 and not GM.bool(data.HJB) then
        data.HJB = 1
        actor:item_give(hijump)
    end

    --Spazer Beam on-level
    if actor.level >= 12 and not GM.bool(data.spazer) then
        data.spazer = 1
        actor:item_give(spazerbeam)
    end

    --Ice Beam on-level
    if actor.level >= 14 and not GM.bool(data.ice) then
        data.ice = 1
        actor:item_give(icebeam)
    end

    --Wave Beam on-level
    if actor.level >= 16 and not GM.bool(data.wave) then
        data.wave = 1
        actor:item_give(wavebeam)
    end


    --onDeath
    --if actor:control("jump", 0) then
    --    log.info("asci = "..actor.actor_state_current_id)
    --    log.info(State.find(NAMESPACE, "hunterV").value)
    --end
    --if actor.sprite_index == sprites.death and actor.image_index == 2 then
    --    actor:sound_play(snd_ondeath, 1, 1)
    --end--actor onStep doesn't run when you die i guess
    end)

    local obj_chargemask = Object.new(NAMESPACE, "hunter_chargemask")
    obj_chargemask.obj_sprite = spr_shoot1_half_chargemask
    obj_chargemask.obj_depth = -1
    obj_chargemask:clear_callbacks()

    obj_chargemask:onStep(function(instance)
        local data = instance:get_data()
        instance.x = data.parent.x
        instance.y = data.parent.y
        instance.statetime = instance.statetime + 1
        if instance.statetime > 0 then
            instance:destroy()
            return
        end
    end)

    local obj_beam = Object.new(NAMESPACE, "hunter_beam")
    obj_beam.obj_sprite = spr_beam
    obj_beam.obj_depth = 1
    obj_beam:clear_callbacks()
    
    obj_beam:onStep(function(instance)
        local data = instance:get_data()
        local all = Instance.find_all(obj_beam)--too many of these lag so we KILL them
        for _, other_beam in ipairs(all) do
            if _ > 18 then
                instance:destroy()
                return
            end
        end
        
        local slow2 = Buff.find("ror-slow2")
        instance.x = instance.x + data.horizontal_velocity + data.parent.pHspeed--my beam inherits the momentum of its creator in real-time
        if instance.statetime < 3 and not GM.bool(data.wave) then--this is to reposition extra beams from the spazer upgrade
            if data.shot == 2 then
                instance.y = instance.y - 3
            end
            if data.shot == 3 then
                instance.y = instance.y + 3
            end
        end
        if GM.bool(data.wave) and GM.bool(data.spazer) then--wave shots move... in a wave
            if data.shot == 2 then
                instance.y = instance.y - GM.cos(instance.statetime / 10)
            end
            if data.shot == 3 then
                instance.y = instance.y + GM.cos(instance.statetime / 10)
            end
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
                if data.parent:is_authority() then--authoritative attack to prevent double networked hitboxes
                    local attack = data.parent:fire_direct(other_actor, data.damage_coefficient, damage_direction, instance.x, instance.y, spr_none, data.doproc)
                    attack.attack_info.climb = (data.shadowclimb + data.shot - 1) * 8--this is accounting for being from a shadow clone and which beam it is
                end
                if GM.bool(data.ice) then--the following is supposed to apply the permafrost debuff, 20%-100% chance based on the base damage and only if the actor is alive and not a boss
                    if math.random() <= math.max(0.2, math.min(1, data.damage_coefficient / 9)) and GM.attack_collision_resolve(other_actor).hp > 0 and not GM.actor_is_boss(other_actor) then
                        GM.remove_buff(GM.attack_collision_resolve(other_actor), slow2)--for some reason we have to use the GM functions directly and not the actor instance methods
				        Alarm.create(function()
                            if not Instance.exists(other_actor) then
                                return
                            elseif GM.attack_collision_resolve(other_actor).hp > 0 then--i have redundant checks for if the actor is still alive but yknow
                                GM.apply_buff(GM.attack_collision_resolve(other_actor), slow2, 4 * 60, 1)
                                --log.info("success")
                            end
                        end, 1)
                    end
                end

                -- Destroy the beam
                instance:destroy()
                return
            end
        end

        -- Hitting terrain destroys the beam
        if instance:is_colliding(gm.constants.pSolidBulletCollision) and not GM.bool(data.wave) then
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
        instance.statetime = instance.statetime + 1--statetime tracks how long the beam has existed, duration is set by the creator
    end)

    local obj_missile = Object.new(NAMESPACE, "hunter_missile")
    obj_missile.obj_sprite = spr_missile
    obj_missile.obj_depth = 1
    obj_missile:clear_callbacks()
    
    obj_missile:onStep(function(instance)
        local data = instance:get_data()
        instance.x = instance.x + data.horizontal_velocity + data.parent.pHspeed
        if data.horizontal_velocity < 16
            and data.horizontal_velocity > - 16
        then
            data.horizontal_velocity = GM.sign(instance.image_xscale) * 16 * ((1.15^instance.statetime - 1) / (1.125^32 - 1))
        end
        -- Hit the first enemy actor that's been collided with
        local actor_collisions, _ = instance:get_collisions(gm.constants.pActorCollisionBase)
        for _, other_actor in ipairs(actor_collisions) do
            if data.parent:attack_collision_canhit(other_actor) then
                -- Deal damage
                if data.parent:is_authority() then
                    local attack = data.parent:fire_explosion(instance.x, instance.y,  64, 64, data.damage_coefficient, spr_missile_explosion, spr_none)
                    attack.attack_info.climb = data.shadowclimb * 8
                end
                if data.parent:item_stack_count(Item.find("ror", "brilliantBehemoth")) == 0 then
                    instance:sound_play(gm.constants.wExplosiveShot, 0.8, 1)
                end
                -- Destroy the missile
                instance:destroy()
                return
            end
        end

        -- Hitting terrain destroys the missile
        if instance:is_colliding(gm.constants.pSolidBulletCollision) then
            if data.parent:is_authority() then
                local attack = data.parent:fire_explosion(instance.x, instance.y,  64, 64, data.damage_coefficient, spr_missile_explosion, spr_none)
                attack.attack_info.climb = data.shadowclimb * 8
            end
            if data.parent:item_stack_count(Item.find("ror", "brilliantBehemoth")) == 0 then
                instance:sound_play(gm.constants.wExplosiveShot, 0.8, 1)
            end
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

        local trail = GM.instance_create(instance.x - 18 * instance.image_xscale, instance.y + 5, gm.constants.oEfTrail)
        trail.sprite_index = gm.constants.sEfMissileTrail
        trail.image_index = 0
        trail.image_speed = 8 / 9
        trail.image_xscale = instance.image_xscale * (data.horizontal_velocity / 16)
        trail.image_yscale = 0.8
        trail.depth = instance.depth + 1
        instance.statetime = instance.statetime + 1
    end)
    
    local obj_bomb = Object.new(NAMESPACE, "hunter_bomb")
    obj_bomb.obj_sprite = spr_bomb
    obj_bomb.obj_depth = -501
    obj_bomb:clear_callbacks()

    obj_bomb:onStep(function(instance)
        local data = instance:get_data()

        -- Fuse
        if instance.statetime >= 30 then
            local parentalignx = data.parent.x - 4
            local diffx = parentalignx - instance.x
            --if instance.hitowner == 0 then
            --    log.info(instance:distance_to_point(data.parent.x, data.parent.y + 11))
            --end
            if instance:distance_to_point(data.parent.x, data.parent.y + 11) <= 11 and instance.hitowner == 0 then
                if parentalignx ~= instance.x then
                    data.parent.pHspeed = data.parent.pHspeed + 2.8 * GM.sign(diffx)
                end
                data.parent.pVspeed = -8
                instance.hitowner = 1
            end
            if data.fired == 0 then
                if data.parent:is_authority() then
                    local attack = data.parent:fire_explosion(instance.x, instance.y,  64, 64, data.damage_coefficient, spr_missile_explosion, spr_none)
                    attack.attack_info.climb = data.shadowclimb * 8
                end
                if data.parent:item_stack_count(Item.find("ror", "brilliantBehemoth")) == 0 then
                    instance:sound_play(gm.constants.wExplosiveShot, 0.8, 1)
                end
                instance.image_alpha = 0
                local skill4 = data.parent:get_active_skill(Skill.SLOT.special)
                if data.shadowclimb < 1 then
                    skill4.stock = skill4.stock + 1
                end
                data.fired = 1
            end
        end

        if instance.statetime >= 32 then
            instance:destroy()
            return
        end

        instance.statetime = instance.statetime + 1
    end)
    
    local obj_powerbomb = Object.new(NAMESPACE, "hunter_powerbomb")
    obj_powerbomb.obj_sprite = spr_powerbomb
    obj_powerbomb.obj_depth = -501
    obj_powerbomb:clear_callbacks()
    
    local obj_powerbomb_explosion = Object.new(NAMESPACE, "hunter_powerbomb_explosion")
    obj_powerbomb_explosion.obj_sprite = spr_powerbomb_explosion
    obj_powerbomb_explosion.obj_depth = -501
    obj_powerbomb_explosion:clear_callbacks()

    obj_powerbomb:onStep(function(instance)
        local data = instance:get_data()

        -- Fuse
        if instance.statetime >= 70 then
            local parentalignx = data.parent.x - 4
            local diffx = parentalignx - instance.x
            --if instance.hitowner == 0 then
            --    log.info(instance:distance_to_point(data.parent.x, data.parent.y + 11))
            --end
            if instance:distance_to_point(data.parent.x, data.parent.y + 11) <= 11 and instance.hitowner == 0 then
                if parentalignx ~= instance.x then
                    data.parent.pHspeed = data.parent.pHspeed + 2.8 * GM.sign(diffx)
                end
                data.parent.pVspeed = data.parent.pVmax * -1.25
                instance.hitowner = 1
            end
            if data.fired == 0 then
                local powerbombex = obj_powerbomb_explosion:create(instance.x + 4, instance.y + 4)
                powerbombex.statetime = 0
                powerbombex.image_xscale = 0
                powerbombex.image_yscale = 0
                powerbombex.image_alpha = 0.8
                powerbombex.image_speed = 0.25
                local powerbombex_data = powerbombex:get_data()
                powerbombex_data.shadowclimb = data.shadowclimb
                powerbombex_data.parent = data.parent
                local damage = data.damage_coefficient
                powerbombex_data.damage_coefficient = damage
                powerbombex_data.fired = 0
                instance.image_alpha = 0
                data.fired = 1
            end
        end

        if instance.statetime >= 72 then
            instance:destroy()
            return
        end

        instance.statetime = instance.statetime + 1
    end)

    obj_powerbomb_explosion:onStep(function(instance)
        local data = instance:get_data()
        local actor_collisions, _ = instance:get_collisions(gm.constants.pActorCollisionBase)

        if instance.image_xscale < 1 then
            instance.image_xscale = instance.image_xscale + 0.02
            instance.image_yscale = instance.image_yscale + 0.02
            if instance.image_index >= 4 then
                instance.image_index = 3
            end
            if math.fmod(instance.statetime, 5) == 0 then
                if instance.statetime == 0 then
                    if data.parent:is_authority() then
                        local attack = data.parent:fire_explosion(instance.x, instance.y,  64, 64, data.damage_coefficient / 10, spr_none, spr_none)
                        attack.attack_info.climb = data.shadowclimb * 8
                    end
                end
                for _, other_actor in ipairs(actor_collisions) do
                    if data.parent:attack_collision_canhit(other_actor) then
                        if other_actor.x == instance.x then
                            local damage_direction = 0
                        else
                            local damage_direction = GM.darccos(GM.sign(other_actor.x - instance.x))
                        end
                        if data.parent:is_authority() then
                            local attack = data.parent:fire_direct(other_actor, data.damage_coefficient / 10, damage_direction, other_actor.x, other_actor.y, spr_none)
                            attack.attack_info.climb = data.shadowclimb * 8
                        end
                    end
                end
            end
        else
            if data.fired == 0 then
                data.parent:fire_explosion(instance.x, instance.y,  1366 * instance.image_xscale, 768 * instance.image_yscale, 0, spr_none, spr_none)
                for _, other_actor in ipairs(actor_collisions) do
                    if data.parent:attack_collision_canhit(other_actor) then
                        if other_actor.x == instance.x then
                            local damage_direction = 0
                        else
                            local damage_direction = GM.darccos(GM.sign(other_actor.x - instance.x))
                        end
                        if data.parent:is_authority() then
                            local attack = data.parent:fire_direct(other_actor, data.damage_coefficient / 10, damage_direction, other_actor.x, other_actor.y, spr_none)
                            attack.attack_info.climb = data.shadowclimb * 8
                        end
                    end
                end
                data.fired = 1
            end
            instance.image_alpha = instance.image_alpha - 0.025
            if instance.image_index >= 7 then
                instance.image_index = 7
            end
        end
        if instance.image_alpha <= 0 then
            instance:destroy()
            return
        end

        instance.statetime = instance.statetime + 1
    end)
    
    -- Grab references to skills. Consider renaming the variables to match your skill names, in case 
    -- you want to switch which skill they're assigned to in future.
    local skill_primary = hunter:get_primary()
    local skill_secondary = hunter:get_secondary()
    local skill_utility = hunter:get_utility()
    local skill_special = hunter:get_special()
    local skill_scepter_special = Skill.new(NAMESPACE, "hunterVBoosted")
    skill_special:set_skill_upgrade(skill_scepter_special)

    -- Set the animations for each skill
    skill_primary:set_skill_animation(sprites.walk)
    skill_secondary:set_skill_animation(sprites.walk)
    skill_utility:set_skill_animation(spr_flashshift)
    skill_special:set_skill_animation(spr_morph)
    skill_scepter_special:set_skill_animation(spr_morph)
    
    -- Set the icons for each skill, specifying the icon spritesheet and the specific subimage
    skill_primary:set_skill_icon(spr_skills, 0)
    skill_secondary:set_skill_icon(spr_skills, 1)
    skill_utility:set_skill_icon(spr_skills, 2)
    skill_special:set_skill_icon(spr_skills, 3)
    skill_scepter_special:set_skill_icon(spr_skills, 4)
    
    -- Set the damage coefficient and cooldown for each skill. A damage coefficient of 100% is equal
    -- to 1.0, 150% to 1.5, 200% to 2.0, and so on. Cooldowns are specified in frames, so multiply by
    -- 60 to turn that into actual seconds.
    skill_primary:set_skill_properties(1.2, 0)
    skill_primary.require_key_press = true
    skill_primary.use_delay = 5
    skill_secondary:set_skill_properties(4.0, 120)
    local base_stocks = 4
    skill_secondary:set_skill_stock(base_stocks, base_stocks, true, 1)
    skill_utility:set_skill_properties(0.0, 240)
    skill_utility:set_skill_stock(2, 2, true, 1)
    skill_utility.is_utility = true
    skill_special:set_skill_properties(1.5, 0)
    skill_special.is_primary = true
    skill_special:set_skill_stock(3, 3, false, 1)
    skill_special.require_key_press = true
    skill_special.required_interrupt_priority = State.ACTOR_STATE_INTERRUPT_PRIORITY.skill
    skill_scepter_special:set_skill_properties(30.0, 900)
    skill_scepter_special:set_skill_stock(1, 1, true, 1)
    skill_scepter_special.require_key_press = true
    skill_scepter_special.required_interrupt_priority = State.ACTOR_STATE_INTERRUPT_PRIORITY.skill

    -- Clear callbacks
    skill_primary:clear_callbacks()
    skill_secondary:clear_callbacks()
    skill_utility:clear_callbacks()
    skill_special:clear_callbacks()
    skill_scepter_special:clear_callbacks()

    -- Again consider renaming these variables after the ability itself
    local state_primary = State.new(NAMESPACE, skill_primary.identifier)
    state_primary:clear_callbacks()
    local state_secondary = State.new(NAMESPACE, skill_secondary.identifier)
    state_secondary:clear_callbacks()
    local state_utility = State.new(NAMESPACE, skill_utility.identifier)
    state_utility.activity_flags = State.ACTIVITY_FLAG.allow_rope_cancel
    state_utility:clear_callbacks()
    local state_special = State.new(NAMESPACE, skill_special.identifier)
    state_special:clear_callbacks()
    local state_scepter_special = State.new(NAMESPACE, skill_scepter_special.identifier)
    state_scepter_special:clear_callbacks()
    
    -- Register callbacks that switch states when skills are activated
    skill_primary:onActivate(function(actor, skill, index)
        actor:enter_state(state_primary)
    end)
    
    skill_secondary:onActivate(function(actor, skill, index)
        actor:enter_state(state_secondary)
    end)

    skill_secondary:onStep(function(actor, skill)
        local data = actor:get_data()
    end)
    
    skill_utility:onActivate(function(actor, skill, index)
        actor:enter_state(state_utility)
    end)
    
    skill_special:onActivate(function(actor, skill, index)
        actor:enter_state(state_special)
    end)
    
    skill_scepter_special:onActivate(function(actor, skill, index)
        actor:enter_state(state_scepter_special)
    end)


    -- Executed when state_primary is entered
    state_primary:onEnter(function(actor, data)
        actor:skill_util_strafe_init()
        actor:skill_util_strafe_turn_init()
        local actorData = actor:get_data()
        local played_sounds = {
            snd_charge = 0
        }
        --if actor:is_authority() then
            actor.image_index2 = 0 -- Make sure our animation starts on its first frame
            -- index2 is needed for strafe sprites to work. From here we can setup custom data that we might want to refer back to in onStep
            -- Our flag to prevent firing more than once per attack
            data.fired = 0
            data.charge = 0--how long we've been charging, this will scale with attack speed
            actorData.beamcharged = 0--if the beam is fully charged or not
            data.released = 0--a variable to stop you from staying in the state if you release-and-press before the state ends
            data.wannacharge = 0--how long you've held the button to start charging. this is essentially a "charge delay" and will not scale with speed
            for i in pairs(played_sounds) do
                played_sounds[i] = 0
            end
            actorData.sound_has_played = played_sounds
        --end
    end)

    -- Executed every game tick during this state
    state_primary:onStep(function(actor, data)
        actor.sprite_index2 = spr_shoot1_half
        -- index2 is needed for strafe sprites to work
        actor:skill_util_strafe_update(0.25 * actor.attack_speed, 1.0) -- 0.25 means 4 ticks per frame at base attack speed
        actor:skill_util_step_strafe_sprites()
        actor:skill_util_strafe_turn_update()
        --actor:skill_util_strafe_turn_turn_if_direction_changed()--i used to want to turn while shooting but it didn't work so i commented it out until i find out how it works
        local actorData = actor:get_data()
        local release = not actor:control("skill1", 0)
    --    if not actor:is_authority() then
    --        release = gm.bool(actor.activity_var2)
    --    end--i took some code from nemmando, this gets referenced later
        local damage = actor:skill_get_damage(skill_primary)
        local direction = GM.cos(GM.degtorad(actor:skill_util_facing_direction()))
        local buff_shadow_clone = Buff.find("ror", "shadowClone")
        local spawn_offset = 5 * direction
        local doproc = true--i stick this into the "can_proc" arg for fire_direct
        actorData.shots = 1
        if actorData.spazer > 0 then
            actorData.shots = 3
        end
        if actorData.ice > 0 then
            damage = damage * 1.5
        end
        if actorData.wave > 0 then
            damage = damage * 1.5
        end
        --i make you shoot a beam up to 2 times in this state so i made it a function
        function fireBeam(actor, spawn_offset, direction, damage, doproc, i)
            for b = 1, actorData.shots do
                local beam = obj_beam:create(actor.x + spawn_offset, actor.y - 10)
                local beam_data = beam:get_data()
                beam.image_speed = 0.25
                beam.image_xscale = direction
                if actorData.ice > 0 then
                    beam.image_blend = Color.AQUA
                end
                if actorData.beamcharged == 1 then
                    beam.sprite_index = spr_beam_c0000--charged beam sprite
                    beam.mask_index = beam.sprite_index
                    if actorData.spazer == 1 then
                        beam.sprite_index = spr_beam_cs000
                        beam.mask_index = beam.sprite_index
                    end
                
                    if actor:is_authority() then
                        local attack = actor:fire_explosion(actor.x + spawn_offset + direction * 5, actor.y - 6, 24, 24, damage * 0.6, spr_none, spr_none)
                        attack.attack_info.climb = i * 8 + 16
                    end
                    local chargeflare = GM.instance_create(actor.x + spawn_offset + direction * 5, actor.y - 6, gm.constants.oEfSparks)
                    chargeflare.sprite_index = spr_beam_flare_0000
                    chargeflare.image_xscale = direction
                    chargeflare.image_yscale = 1
                    chargeflare.image_speed = 0.25
                end
                beam.statetime = 0--this tracks how long the beam object has existed, it increments by 1 in obj_beam onStep and i use it to do things
                beam.duration = math.min(actor.level * 10, 180)--like compare it to this variable and destroy it if it has existed too long
                beam_data.shadowclimb = i
                beam_data.parent = actor
                beam_data.horizontal_velocity = 10 * direction * (1 + 0.5 * actorData.beamcharged)--it should move faster if charged
                beam_data.damage_coefficient = damage
                beam_data.doproc = doproc--damage, doproc, and i get defined in state_primary onStep
                beam_data.shot = b
                beam_data.spazer = actorData.spazer
                beam_data.ice = actorData.ice
                beam_data.wave = actorData.wave
            end
        end

        --if actor:is_authority() then
            if actor.image_index2 >= 0 and data.fired == 0 then--fire an uncharged beam as soon as the skill starts, it's just how i want the attack to work
                data.fired = 1
                if actor:skill_util_update_heaven_cracker(actor, damage) then
                    doproc = false
                end
                    for i=0, actor:buff_stack_count(buff_shadow_clone) do 
                        fireBeam(actor, spawn_offset, direction, damage, doproc, i)
                    end
                actor:sound_play(gm.constants.wGuardDeathOLD, 0.4, 2 + math.random() * 0.1)
            end

            if not release and data.released == 0 then--as long as you hold the button down
                data.wannacharge = data.wannacharge + 1
                if actor.image_index2 > 0 then
                    actor.image_index2 = 0--freeze you at the first image index
                end
                if data.wannacharge >= 10 then--the charge delay is 10 frames
                    if data.charge < 50 then--the charge windup is 50 frames at base attack speed
                        data.charge = data.charge + 1 + ((actor.attack_speed - 1) * 2.5)
                        if actorData.sound_has_played["snd_charge"] == 0 then--play a sound and stop it from playing every frame. it's a table because i was planning on adding more
                            local chargeinitsfx = actor:sound_play(gm.constants.wLoader_BulletPunch_Start, 1, math.max(0, 1 + ((actor.attack_speed - 1) * 2) - 0.24))
                            actorData.sound_has_played["snd_charge"] = 1
                        end
                    else--once you finish the 50 frame windup
                        if actorData.beamcharged == 0 then
                            actorData.beamcharged = 1
                            actor:sound_play(gm.constants.wSpiderSpawn, 1, 0.9)
                            actor:sound_play(gm.constants.wSpiderHit, 1, 0.9)
                            if actor:is_authority() then
                                local chargeloopsfx = GM.sound_loop(snd_chargeloop, 1)
                            end
                            local sparks = GM.instance_create(actor.x + spawn_offset, actor.y - 10, gm.constants.oEfSparks)
                            sparks.sprite_index = gm.constants.sSparks18
                            sparks.depth = actor.depth - 2
                            sparks.image_blend = Color.YELLOW
                        end
                        if actorData.beamcharged == 1 then--this should probably just say else
                            for i = 0, 1 do--this is all a horrid monstrosity i created because i wanted my character to flash white while charged and i didn't know how to do that
                                local chargemask = obj_chargemask:create(actor.x + actor.pHspeed, actor.y + actor.pVspeed)
                                chargemask.statetime = 0
                                chargemask.depth = actor.depth - 1
                                chargemask.image_index = actor.image_index2
                                if i > 0 then
                                    chargemask.sprite_index = spr_walk_half_chargemask
                                    if actor.sprite_index == spr_idle_half then
                                        chargemask.sprite_index = spr_idle_half_chargemask
                                    end
                                    chargemask.image_index = actor.image_index
                                    if GM.bool(actor.free) then
                                        chargemask.sprite_index = spr_jump_half_chargemask
                                        chargemask.image_index = 0
                                    end
                                end
                                chargemask.image_xscale = direction
                                chargemask.image_alpha = 0.5 * (1 -(math.abs(3 - (math.fmod(data.wannacharge, 6)))) / 3)
                                local chargemask_data = chargemask:get_data()
                                chargemask_data.parent = actor
                            end
                        end
                    end
                end
            else
            --    these lines were taken from nemmando to try to sync the characters holding down the skill button
            --    however we discovered that it will set the image xscale for all actors of the same type so we removed it for now
            --    if GM._mod_net_isOnline() then
            --        if GM._mod_net_isHost() then
            --            GM.server_message_send(0, 43, actor:get_object_index_self(), actor.m_id, 1, gm.sign(actor.image_xscale))
            --        else
            --            GM.client_message_send(43, 1, gm.sign(actor.image_xscale))
            --        end
            --    end
                if actor.image_index2 >= 0 and data.fired == 1 and data.wannacharge >= 10 then
                    data.fired = 2--since i'm firing a second beam
                    if actorData.beamcharged == 1 then
                        damage = damage * 5
                    end
                    if actor:skill_util_update_heaven_cracker(actor, damage) then
                        doproc = false
                    end
                        for i=0, actor:buff_stack_count(buff_shadow_clone) do 
                            fireBeam(actor, spawn_offset, direction, damage, doproc, i)
                        end
                    actor:sound_play(gm.constants.wGuardDeathOLD, 0.4, 1.5 + math.random() * 0.1)
                    data.released = 1
                    if GM._mod_sound_isPlaying(snd_chargeloop) then
                        GM._mod_sound_stop(snd_chargeloop)
                    end
                end
                if data.wannacharge < 10 then--if you let go of the button quickly because you didn't "wanna charge"
                    data.released = 1
                end
            end
        --end
    
    
        -- A convenience function that exits this state automatically once the animation ends
        actor:skill_util_exit_state_on_anim_end()
    end)

    state_primary:onExit(function(actor, data)
        actor:skill_util_strafe_exit()
    end)

    -- Executed when state_secondary is entered
    state_secondary:onEnter(function(actor, data)
        actor:skill_util_strafe_init()
        actor:skill_util_strafe_turn_init()
        actor.image_index2 = 0 -- Make sure our animation starts on its first frame
        -- index2 is needed for strafe sprites to work. From here we can setup custom data that we might want to refer back to in onStep
        -- Our flag to prevent firing more than once per attack
        data.fired = 0
 
    end)
    
    -- Executed every game tick during this state
    state_secondary:onStep(function(actor, data)
        actor.sprite_index2 = spr_shoot1_half
        -- index2 is needed for strafe sprites to work    
        actor:skill_util_strafe_update(0.25 * actor.attack_speed, 1.0) -- 0.25 means 4 ticks per frame at base attack speed
        actor:skill_util_step_strafe_sprites()
        actor:skill_util_strafe_turn_update()

        if actor.image_index2 >= 0 and data.fired == 0 then
            data.fired = 1
    
            local direction = GM.cos(GM.degtorad(actor:skill_util_facing_direction()))
            local buff_shadow_clone = Buff.find("ror", "shadowClone")
            for i=0, actor:buff_stack_count(buff_shadow_clone) do 
                local spawn_offset = 16 * direction
                local missile = obj_missile:create(actor.x + spawn_offset, actor.y - 10)
                missile.image_speed = 0.25
                missile.image_xscale = direction
                missile.statetime = 0
                local missile_data = missile:get_data()
                missile_data.shadowclimb = i
                missile_data.parent = actor
                missile_data.horizontal_velocity = 0
                local damage = actor:skill_get_damage(skill_secondary)
                missile_data.damage_coefficient = damage


            end
            actor:sound_play(gm.constants.wMissileLaunch, 1, 0.8 + math.random() * 0.2)
        end
    
    
        -- A convenience function that exits this state automatically once the animation ends
        actor:skill_util_exit_state_on_anim_end()
    end)

    state_secondary:onExit(function(actor, data)
        actor:skill_util_strafe_exit()
    end)

    -- Executed when state_utility is entered
    state_utility:onEnter(function(actor, data)
        actor.image_index = 0 -- Make sure our animation starts on its first frame
        -- From here we can setup custom data that we might want to refer back to in onStep
        -- Our flag to prevent firing more than once per attack
        actor:sound_play(gm.constants.wHuntressShoot3, 1, 0.8 + math.random() * 0.2)
        actor.shiftedfrom = actor.y
        local circle = GM.instance_create(actor.x, actor.y, gm.constants.oEfCircle)
        circle.parent = actor
        circle.radius = 20
        circle.image_blend = Color(0x73eeff)
        if actor:control("left", 0) then
            data.direction = -1
        elseif actor:control("right", 0) then
            data.direction = 1
        else
            data.direction = GM.cos(GM.degtorad(actor:skill_util_facing_direction()))
        end
        if data.direction ~= GM.cos(GM.degtorad(actor:skill_util_facing_direction())) then
            actor.image_xscale = -actor.image_xscale
        end
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

        local direction = data.direction
        local buff_shadow_clone = Buff.find("ror", "shadowClone")
        if actor.invincible < 10 then 
            actor.invincible = 10
        end
        actor.pHspeed = direction * actor.pHmax * 6 * (math.min(actor.attack_speed, 3))
        actor.pVspeed = 0
        actor.y = actor.shiftedfrom

        local trail = GM.instance_create(actor.x, actor.y, gm.constants.oEfTrail)
        trail.sprite_index = spr_flashshifttrail
        trail.image_index = actor.image_index - 1
        trail.image_xscale = direction
        trail.image_alpha = actor.image_alpha - 0.25
        trail.depth = actor.depth + 1
        
        -- A convenience function that exits this state automatically once the animation ends
        actor:skill_util_exit_state_on_anim_end()
    end)

    state_utility:onExit(function(actor, data)
        if actor.invincible <= 10 then
            actor.invincible = 0
        end
        actor.pHspeed = 0
        data.direction = nil
    end)

    -- Executed when state_special is entered
    state_special:onEnter(function(actor, data)
        actor:skill_util_strafe_init()
        actor:skill_util_strafe_turn_init()
        actor.image_index2 = 0 -- Make sure our animation starts on its first frame
        -- index2 is needed for strafe sprites to work. From here we can setup custom data that we might want to refer back to in onStep
        -- Our flag to prevent firing more than once per attack
        actor.image_alpha = 0
        actor.image_yscale = 0.5
        actor.y = actor.y + 6
        data.fired = 0
 
    end)
    
    -- Executed every game tick during this state
    state_special:onStep(function(actor, data)
        actor.sprite_index2 = spr_morph
        -- index2 is needed for strafe sprites to work
        actor:skill_util_strafe_update(0.25 * actor.attack_speed, 1.0) -- 0.25 means 4 ticks per frame at base attack speed
        actor:skill_util_step_strafe_sprites()
        actor:skill_util_strafe_turn_update()

        if actor.image_index2 >= 1 and data.fired == 0 then
            data.fired = 1
            actor:sound_play(gm.constants.wPlayer_TakeDamage, 0.75, 1.5)
            local buff_shadow_clone = Buff.find("ror", "shadowClone")
            for i=0, actor:buff_stack_count(buff_shadow_clone) do
                local bomb = obj_bomb:create(actor.x - 4, actor.y - 3)
                bomb.statetime = 0
                bomb.hitowner = 0
                local bomb_data = bomb:get_data()
                bomb_data.shadowclimb = i
                bomb_data.parent = actor
                local damage = actor:skill_get_damage(skill_special)
                bomb_data.damage_coefficient = damage
                bomb_data.fired = 0
            end
        end

        for i=0, 20 do
            local trail = GM.instance_create(actor.x, actor.y - 6, gm.constants.oEfTrail)
            trail.sprite_index = spr_morph
            trail.image_index = actor.image_index2
            trail.image_xscale = actor.image_xscale
            trail.image_alpha = 1 / 10
            trail.depth = actor.depth
        end--this will probably be very laggy
            
        -- A convenience function that exits this state automatically once the animation ends
        actor:skill_util_exit_state_on_anim_end()
    end)

    state_special:onExit(function(actor, data)
        actor:skill_util_strafe_exit()
        actor.image_yscale = 1
        actor.y = actor.y - 6
        actor.image_alpha = 1
    end)

    state_special:onGetInterruptPriority(function(actor, data)
        if actor.image_index2 <= 2 then
            return State.ACTOR_STATE_INTERRUPT_PRIORITY.priority_skill
        else
            return State.ACTOR_STATE_INTERRUPT_PRIORITY.skill_interrupt_period
        end
    end)

    -- Executed when state_scepter_special is entered
    state_scepter_special:onEnter(function(actor, data)
        actor:skill_util_strafe_init()
        actor:skill_util_strafe_turn_init()
        actor.image_index2 = 0 -- Make sure our animation starts on its first frame
        -- index2 is needed for strafe sprites to work. From here we can setup custom data that we might want to refer back to in onStep
        -- Our flag to prevent firing more than once per attack
        actor.image_alpha = 0
        actor.image_yscale = 0.5
        actor.y = actor.y + 6
        data.fired = 0
 
    end)
    
    -- Executed every game tick during this state
    state_scepter_special:onStep(function(actor, data)
        actor.sprite_index2 = spr_morph
        -- index2 is needed for strafe sprites to work
        actor:skill_util_strafe_update(0.25 * actor.attack_speed, 1.0) -- 0.25 means 4 ticks per frame at base attack speed
        actor:skill_util_step_strafe_sprites()
        actor:skill_util_strafe_turn_update()

        if actor.image_index2 >= 1 and data.fired == 0 then
            data.fired = 1
            actor:sound_play(gm.constants.wBossLaser1Fire, 0.8, 1)
            local buff_shadow_clone = Buff.find("ror", "shadowClone")
            for i=0, actor:buff_stack_count(buff_shadow_clone) do
                local powerbomb = obj_powerbomb:create(actor.x - 4, actor.y - 3)
                powerbomb.statetime = 0
                powerbomb.hitowner = 0
                local powerbomb_data = powerbomb:get_data()
                powerbomb_data.shadowclimb = i
                powerbomb_data.parent = actor
                local damage = actor:skill_get_damage(skill_scepter_special)
                powerbomb_data.damage_coefficient = damage
                powerbomb_data.fired = 0
            end
        end

        for i=0, 20 do
            local trail = GM.instance_create(actor.x, actor.y - 6, gm.constants.oEfTrail)
            trail.sprite_index = spr_morph
            trail.image_index = actor.image_index2
            trail.image_xscale = actor.image_xscale
            trail.image_alpha = 1 / 10
            trail.depth = actor.depth
        end--this will probably be very laggy
            
        -- A convenience function that exits this state automatically once the animation ends
        actor:skill_util_exit_state_on_anim_end()
    end)

    state_scepter_special:onExit(function(actor, data)
        actor:skill_util_strafe_exit()
        actor.image_yscale = 1
        actor.y = actor.y - 6
        actor.image_alpha = 1
    end)

    state_scepter_special:onGetInterruptPriority(function(actor, data)
        if actor.image_index2 <= 2 then
            return State.ACTOR_STATE_INTERRUPT_PRIORITY.priority_skill
        else
            return State.ACTOR_STATE_INTERRUPT_PRIORITY.skill_interrupt_period
        end
    end)

    
    
end
Initialize(initialize)

-- ** Uncomment the two lines below to re-call initialize() on hotload **
 if hotload then initialize() end
 hotload = true


gm.post_script_hook(gm.constants.__input_system_tick, function(self, other, result, args)
    -- This is an example of a hook
    -- This hook in particular will run every frame after it has finished loading (i.e., "Hopoo Games" appears)
    -- You can hook into any function in the game
    -- Use pre_script_hook 'stead to run code before the function
    -- https://github.com/return-of-modding/ReturnOfModding/blob/master/docs/lua/tables/gm.md
    
end)