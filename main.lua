-- Hunter
-- good morning morioh-cho
-- i tried leaving comments here and there to clear some things up, plus some old comments from copying dixie's tutorial (skull emoji)
-- if you have questions let me know so i can try to expand my comments more

log.info("Loading ".._ENV["!guid"]..".")
local envy = mods["LuaENVY-ENVY"]
envy.auto()
mods["ReturnsAPI-ReturnsAPI"].auto{
    namespace = "hunter",
    mp = true
}

local PATH = _ENV["!plugins_mod_folder_path"]
local NAMESPACE = "anx"
local debugmsg = "If you're reading this, I forgot to remove the debug message."

local ssrOn = false
mods.on_all_mods_loaded(function()
    --for k,v in pairs(mods) do print(k,v) end
    print("on_all_mods_loaded", debugmsg)
    if mods["StarstormReturns-StarstormReturns"] or mods["RobomandosLab-StarstormReturns"] then
        ssrOn = true
    end
end)

--settings
local Options = {
    beam_limit = false,
    offscr_destroy = true,
    gui_maxbeams = 12,
    input_maxbeams = 12,
    solid_ice = false,
    experimental = false
}

local OptionsTOML = TOML.new()
if not OptionsTOML:read() then
    OptionsTOML:write(Options)
else
    Options = OptionsTOML:read()
end

gui.add_to_menu_bar(function()
	Options.beam_limit = ImGui.Checkbox("Enable Beam Limit (can crash in multiplayer)", Options.beam_limit)
    Options.input_maxbeams = ImGui.DragFloat("Max Beams", Options.input_maxbeams, 1, 0, 600)
	if Options.beam_limit then
		Options.gui_maxbeams = math.max(0, math.floor(Options.input_maxbeams))
    else
        Options.gui_maxbeams = math.huge
	end
    Options.offscr_destroy = ImGui.Checkbox("Destroy Offscreen Beams", Options.offscr_destroy)
    Options.solid_ice = ImGui.Checkbox("Fully Solid Ice Blocks", Options.solid_ice)
	Options.experimental = ImGui.Checkbox("Enable experimental Settings", Options.experimental)
end)

local modOptions = ModOptions.new()
local beamLimitCheckbox = modOptions:add_checkbox("beamLimit")
beamLimitCheckbox:add_getter(function()
    return Options.beam_limit
end)
beamLimitCheckbox:add_setter(function(value)
    Options.beam_limit = value
    OptionsTOML:write(Options)
end)

local offscreenLimitCheckbox = modOptions:add_checkbox("offscreenLimit")
offscreenLimitCheckbox:add_getter(function()
    return Options.offscr_destroy
end)
offscreenLimitCheckbox:add_setter(function(value)
    Options.offscr_destroy = value
    OptionsTOML:write(Options)
end)

local solidIceCheckbox = modOptions:add_checkbox("solidIce")
solidIceCheckbox:add_getter(function()
    return Options.solid_ice
end)
solidIceCheckbox:add_setter(function(value)
    Options.solid_ice = value
    OptionsTOML:write(Options)
end)

local experimentalCheckbox = modOptions:add_checkbox("experimentalSettings")
experimentalCheckbox:add_getter(function()
    return Options.experimental
end)
experimentalCheckbox:add_setter(function(value)
    Options.experimental = value
    OptionsTOML:write(Options)
end)

--blendmodes from gm
local bm_normal = 0
local bm_add = 1
local bm_max = 2
local bm_subtract = 3


-- ========== Main ==========

local initialize = function()
    hotload = true
    local hunter = Survivor.new("hunter")

    --all the upgrades are hidden items
        local missiletank = Item.new("missileTank")
        missiletank:set_sprite(gm.constants.sMissileBox)
        missiletank:set_tier(5)
        missiletank:toggle_loot(false)
        missiletank.is_hidden = true
        Callback.add(missiletank.on_acquired, function(actor, stack)
            local skill2 = actor:get_active_skill(1)
            skill2.stock = skill2.stock + 1
        end)
        RecalculateStats.add(function(actor, api)
	        local stack = actor:item_count(missiletank)
            if stack <= 0 then return end

            api.skill_secondary.max_stock_add(stack)
        end)

        local hijump = Item.new("hiJumpBoots")
        hijump:set_sprite(gm.constants.sStompers)
        hijump:set_tier(5)
        hijump:toggle_loot(false)
        hijump.is_hidden = true
        RecalculateStats.add(function(actor, api)
	        local stack = actor:item_count(hijump)
            if stack <= 0 then return end

            api.pVmax_add(2.4 * stack)
        end)

        local spacejumpboots = Item.new("spaceJumpBoots")
        spacejumpboots:set_sprite(gm.constants.sJetpack)
        spacejumpboots:set_tier(5)
        spacejumpboots:toggle_loot(false)
        spacejumpboots.is_hidden = true
        RecalculateStats.add(Callback.Priority.AFTER, function(actor, api)
	        local stack = actor:item_count(spacejumpboots)
            if stack <= 0 then return end

            api.pGravity2_mult(0.9 ^ (stack ^ 0.2))
        end)

        local varsuit = Item.new("variaSuit")
        varsuit:set_sprite(gm.constants.sShellPiece)
        varsuit:set_tier(5)
        varsuit:toggle_loot(false)
        varsuit.is_hidden = true
        Callback.add(Callback.POST_STEP, function()
            local actors = varsuit:get_holding_actors()
            
            for _, actor in ipairs(actors) do
                actor.buff_immune:set(Buff.find("slow2", "ror"))
            end
        end)
        RecalculateStats.add(function(actor, api)
	        local stack = actor:item_count(varsuit)
            if stack <= 0 then return end

            api.armor_add(50 * stack)
        end)

        local gravsuit = Item.new("gravitySuit")
        gravsuit:set_sprite(gm.constants.sPauldron)
        gravsuit:set_tier(5)
        --gravsuit:set_loot_tags(Item.LOOT_TAG.item_blacklist_engi_turrets)
        gravsuit:toggle_loot(false)
        gravsuit.is_hidden = true
        gravsuit.effect_display = EffectDisplay.func(function(actorval)
            local actor = Instance.wrap(actorval)
            
            local fxalpha = 1
            local rx = (0.5 - math.random()) * 2
            local ry = (0.5 - math.random()) * 2
            gm.gpu_set_blendmode(bm_add)
            GM.gpu_set_fog(1, Color.PURPLE, 0, 0)
            gm.draw_set_alpha(0.5)
            GM.draw_sprite_ext(actor.sprite_index, actor.image_index, actor.x, actor.y, actor.image_xscale * 1.1 + rx/8, actor.image_yscale * 1.1 + ry/8, actor.image_angle, Color.PURPLE, fxalpha)
            GM.draw_sprite_ext(actor.sprite_index, actor.image_index, actor.x, actor.y, actor.image_xscale / 1.2 + rx/8, actor.image_yscale / 1.2 + ry/8, actor.image_angle, Color.PURPLE, fxalpha)
            if actor.actor_state_current_id ~= -1 and not actor:actor_state_is_climb_state(actor.actor_state_current_id) and actor.sprite_index2 then
                GM.draw_sprite_ext(actor.sprite_index2, actor.image_index, actor.x, actor.y, actor.image_xscale * 1.1 + rx/8, actor.image_yscale * 1.1 + ry/8, actor.image_angle, Color.PURPLE, fxalpha)
                GM.draw_sprite_ext(actor.sprite_index2, actor.image_index, actor.x, actor.y, actor.image_xscale / 1.2 + rx/8, actor.image_yscale / 1.2 + ry/8, actor.image_angle, Color.PURPLE, fxalpha)
            end
            gm.draw_set_alpha(1)
            GM.gpu_set_fog(0, Color.BLACK, 0, 0)
            gm.gpu_set_blendmode(0)
        end, EffectDisplay.DrawPriority.POST)
        local wetprev = -1--initialize a method to detect if the variable "wet" has changed
        local shouldStatRecalc = false--my data.fired for calling a stats recalc
        Callback.add(Callback.POST_STEP, function()
            local actors = gravsuit:get_holding_actors()
            
            for _, actor in ipairs(actors) do
	            local stack = actor:item_count(gravsuit)
                if stack <= 0 then return end

                actor.buff_immune:set(Buff.find("slowGoop", "ror"), true)
                
                if wetprev ~= actor.wet then--now we make the gravity suit make you immune to the effects of water. if you choose.
                    wetprev = actor.wet
                    if (not Util.bool(actor.moveUpHold) and not Util.bool(actor.moveUp)) and actor.pVspeed > 0 then--you choose by not holding the jump button
                        --log.info("notjump")
                        actor.pGravity1 = actor.pGravity1_base * 2
                        shouldStatRecalc = true
                        --log.info(shouldStatRecalc)
                    elseif shouldStatRecalc then--the reason i call stats recalc is because i think it works better if other mods are also modifying pGravity1?
                        --log.info("jump")
                        actor.pGravity1 = actor.pGravity1_base
                        actor:recalculate_stats()
                        --log.info(shouldStatRecalc)
                        shouldStatRecalc = nil
                    end
                    --log.info("underwater")
                    --log.info(shouldStatRecalc)
                elseif shouldStatRecalc then
                    actor.pGravity1 = actor.pGravity1_base
                    actor:recalculate_stats()
                    shouldStatRecalc = nil
                end
                --log.info("also, gravity1 is")
                --log.info(actor.pGravity1)
                --log.info("vspeed = "..math.floor(actor.pVspeed*100)/100)
                --log.info("vmax = "..actor.pVmax)  
            end          
        end)
        RecalculateStats.add(function(actor, api)
	        local stack = actor:item_count(gravsuit)
            if stack <= 0 then return end

            api.armor_add(50 * stack)
        end)
        --Callback.add(gravsuit.on_removed, function(actor, stack)
        --    actor.image_blend = Color.WHITE
        --end)

        local spazerbeam = Item.new("spazerBeam")
        spazerbeam:set_sprite(gm.constants.sJewel)
        spazerbeam:set_tier(5)
        spazerbeam.loot_tags = Item.LootTag.CATEGORY_DAMAGE
        spazerbeam:toggle_loot(false)
        spazerbeam.is_hidden = true

        local icebeam = Item.new("iceBeam")
        icebeam:set_sprite(gm.constants.sIceRelic)
        icebeam:set_tier(5)
        icebeam.loot_tags = Item.LootTag.CATEGORY_DAMAGE
        icebeam:toggle_loot(false)
        icebeam.is_hidden = true

        local wavebeam = Item.new("waveBeam")
        wavebeam:set_sprite(gm.constants.sTesla)
        wavebeam:set_tier(5)
        wavebeam.loot_tags = Item.LootTag.CATEGORY_DAMAGE
        wavebeam:toggle_loot(false)
        wavebeam.is_hidden = true

        local plasmabeam = Item.new("plasmaBeam")
        plasmabeam:set_sprite(gm.constants.sOrbiter)
        plasmabeam:set_tier(5)
        plasmabeam.loot_tags = Item.LootTag.CATEGORY_DAMAGE
        plasmabeam:toggle_loot(false)
        plasmabeam.is_hidden = true

    -- Utility function for getting paths concisely
    local rapi_sprite = function(identifier, filename, image_number, x_origin, y_origin) 
        local sprite_path = path.combine(PATH, "Sprites",  filename)
        return Sprite.new(identifier, sprite_path, image_number, x_origin, y_origin)
    end
    local rapi_sound = function(id, filename)
        local sound_path = path.combine(PATH, "Sounds", filename)
        return Sound.new(id, sound_path)
    end
    
    -- Load the common survivor sprites into a table
    local sprites = {
        idle = rapi_sprite("hunter_idle", "sHunterIdle.png", 1, 14, 15),
        walk = rapi_sprite("hunter_walk", "sHunterRun.png", 4, 12, 24),
        jump = rapi_sprite("hunter_jump", "sHunterSault.png", 4, 14, 14),
        jump_peak = rapi_sprite("hunter_jump_peak", "sHunterSault.png", 4, 14, 14),
        fall = rapi_sprite("hunter_fall", "sHunterSault.png", 4, 14, 14),
        climb = rapi_sprite("hunter_climb", "sHunterElevator.png", 1, 14, 15),
        climb_hurt = rapi_sprite("hunter_climb_hurt", "sHunterElevator.png", 1, 14, 18), 
        death = rapi_sprite("hunter_death", "sHunterDeath.png", 20, 34, 58),
        decoy = rapi_sprite("hunter_decoy", "sHunterDecoy.png", 1, 17, 20),
    }

    --spr_half
    local spr_idle_half = rapi_sprite("hunter_idle_half", "sHunterIdleHalf.png", 1, 14, 15)
    local spr_walk_half = rapi_sprite("hunter_walk_half", "sHunterRunHalf.png", 4, 12, 24)
    local spr_jump_half = rapi_sprite("hunter_jump_half", "sHunterJumpHalf.png", 1, 12, 24)
    local spr_jump_peak_half = rapi_sprite("hunter_jump_peak_half", "sHunterJumpHalf.png", 1, 12, 24)
    local spr_fall_half = rapi_sprite("hunter_fall_half", "sHunterJumpHalf.png", 1, 12, 24)

    local spr_shoot1_half = rapi_sprite("hunter_shoot1_half", "sHunterShoot1Half.png", 4, 13, 25)
    
    --placeholder category, todo organize later
    local spr_skills = rapi_sprite("hunter_skills", "sHunterSkills.png", 5, 0, 0)
    local spr_loadout = rapi_sprite("hunter_loadout", "sSelectHunter.png", 18, 28)
    local spr_portrait = rapi_sprite("hunter_portrait", "sHunterPortrait.png", 3)
    local spr_portrait_small = rapi_sprite("hunter_portrait_small", "sHunterPortraitSmall.png")
    local spr_portrait_cropped = rapi_sprite("hunter_portrait_cropped", "sHunterPortraitC.png")
    local spr_palette = rapi_sprite("hunter_palette", "sHunterPalette.png")
    local spr_log = rapi_sprite("hunter_log", "sPortraitHunter.png")
    local spr_flashshift = rapi_sprite("hunter_flashshift", "sHunterFlashShift.png", 4, 19, 17)
    local spr_flashshifttrail = rapi_sprite("hunter_flashshifttrail", "sHunterFlashShift.png", 4, 19, 17)
    --local spr_morphandbomb = rapi_sprite("hunter_morphandbomb", "sHunterMorphAndBomb.png", 10, 6, 0)
    local spr_morph = rapi_sprite("hunter_morph", "sHunterMorph.png", 8, 6, 0)
    local spr_morph2 = rapi_sprite("hunter_morph2", "sHunterMorph2.png", 8, 6, 12)

    local spr_beam = rapi_sprite("hunter_beam", "sHunterBeam.png", 4)
    local spr_beam_c0000 = rapi_sprite("hunter_beam_c0000", "sHunterBeamC0000.png", 4, 14, 4)
    local spr_beam_cs000 = rapi_sprite("hunter_beam_cs000", "sHunterBeamCS000.png", 4, 14, 2)
    local spr_beam_csi00 = rapi_sprite("hunter_beam_csi00", "sHunterBeamCSI00.png", 4, 14, 2)
    local spr_beam_csiw0 = rapi_sprite("hunter_beam_csiw0", "sHunterBeamCSIW0.png", 4, 14, 2)
    local spr_beam_csiwp = rapi_sprite("hunter_beam_csiwp", "sHunterBeamCSIWP.png", 4, 14, 2)
    local spr_beam_0s000 = rapi_sprite("hunter_beam_0s000", "sHunterBeam0S000.png", 4)
    local spr_beam_0si00 = rapi_sprite("hunter_beam_0si00", "sHunterBeam0SI00.png", 4)
    local spr_beam_0siw0 = rapi_sprite("hunter_beam_0siw0", "sHunterBeam0SIW0.png", 4)
    local spr_beam_0siwp = rapi_sprite("hunter_beam_0siwp", "sHunterBeam0SIWP.png", 4)
    local spr_beam_flare_0000 = rapi_sprite("hunter_beam_flare_0000", "sSparksHunterChargeFlare.png", 5, 12, 12)
    local spr_missile = rapi_sprite("hunter_missile", "sHunterMissile.png", 3, 22)
    local spr_missile_explosion = gm.constants.sEfMissileExplosion
    local spr_bomb = rapi_sprite("hunter_bomb", "sHunterBomb.png")
    local spr_powerbomb = rapi_sprite("hunter_powerbomb", "sHunterPowerBomb.png")
    local spr_powerbomb_explosion = rapi_sprite("hunter_powerbomb_explosion", "sHunterPowerBombExplode.png", 8, 889, 499)
    local spr_chinytozo = rapi_sprite("hunter_chinytozo", "sChinyTozo.png", 2, 16, 32)
    
    -- Colour for the character's skill names on character select
    hunter.primary_color = Color.from_rgb(8, 253, 142)

    --snd
    local snd_chargeloop = rapi_sound("hunter_chargeloop", "wDivineTP_CompleteAmbience_Loopable_steeled.ogg")
    local snd_ondeath = rapi_sound("hunter_explode", "snd_badexplosion.ogg")

    -- Assign sprites to various survivor fields
    hunter.sprite_loadout = spr_loadout
    hunter.sprite_portrait = spr_portrait
    hunter.sprite_portrait_small = spr_portrait_small
    hunter.sprite_portrait_palette = spr_portrait_cropped
    hunter.sprite_palette = spr_palette
    hunter.sprite_title = sprites.walk
    hunter.sprite_idle = sprites.idle
    hunter.sprite_credits = sprites.idle
    --hunter:set_animations(sprites)
    -- Offset for the Prophet's Cape
    hunter.cape_offset = Array.new({-1, -6, -8, -1})

    Callback.add(hunter.on_init, function(actor)
        actor.sprite_idle          = sprites.idle
        actor.sprite_walk          = sprites.walk
        --actor.sprite_walk_last     = sprites.walk_last
        actor.sprite_jump          = sprites.jump
        actor.sprite_jump_peak     = sprites.jump_peak
        actor.sprite_fall          = sprites.fall
        actor.sprite_climb         = sprites.climb
        actor.sprite_death         = sprites.death
        actor.sprite_decoy         = sprites.decoy
        --actor.sprite_drone_idle    = sprites.drone_idle
        --actor.sprite_drone_shoot   = sprites.drone_shoot
        actor.sprite_climb_hurt    = sprites.climb_hurt
        actor.sprite_palette = spr_palette

        local data = Instance.get_data(actor)
        actor.shiftedfrom = 0
        actor.sprite_idle_half = Array.new({sprites.idle, spr_idle_half, 0})
        actor.sprite_walk_half = Array.new({sprites.walk, spr_walk_half, 0})
        actor.sprite_jump_half = Array.new({sprites.jump, spr_jump_half, 0})
        actor.sprite_jump_peak_half = Array.new({sprites.jump_peak, spr_jump_peak_half, 0})
        actor.sprite_fall_half = Array.new({sprites.fall, spr_fall_half, 0})
        actor.sprite_morph_half_anxvariable = Array.new({spr_morph2, spr_morph2, 0})

        data.mtanks = 0
        data.HJB = 0
        data.SpJB = 0
        data.varsuit = 0
        data.gravsuit = 0
        data.spazer = 0
        data.ice = 0
        data.wave = 0
        data.plasma = 0

        data.spacejump_count = 0

        actor:survivor_util_init_half_sprites()
    end)


    -- Survivor stats
    hunter:set_stats_base({
        health = 99,
        damage = 12,
        regen = 0.01
    })

    hunter:set_stats_level({
        health = 32,
        damage = 3.3125,
        regen = 0.002,
        armor = 0,
    })

    --Create Survivor Log
    local hunter_log = SurvivorLog.new_from_survivor(hunter)
    hunter_log.portrait_id = spr_log
    hunter_log.sprite_id = sprites.walk
    hunter_log.sprite_icon_id = spr_portrait

    local obj_beam = Object.new("hunter_beam")
    obj_beam.obj_sprite = spr_beam
    obj_beam.obj_depth = 1

    --i make you shoot a beam in multiple places so i made it a function
    function fireBeam(actorData, actor, spawn_offset, direction, damage, doproc, i)
        for b = 1, actorData.shots do
            local beam = obj_beam:create(actor.x + spawn_offset, actor.y - 10 + math.min(actorData.spazer, 1))
            local beam_data = Instance.get_data(beam)
            beam.image_speed = 0.25
            beam.image_xscale = direction
            --lots of jank to set the sprite of the beam depending on what kind of beam you're firing
            if actorData.beamcharged == 1 then
                beam.sprite_index = spr_beam_c0000
                beam.mask_index = beam.sprite_index
                if actorData.spazer >= 1 then
                    beam.sprite_index = spr_beam_cs000
                    beam.mask_index = beam.sprite_index
                    if actorData.ice >= 1 then
                        beam.sprite_index = spr_beam_csi00
                        beam.mask_index = beam.sprite_index
                        if actorData.wave >= 1 then
                            beam.sprite_index = spr_beam_csiw0
                            if actorData.plasma >= 1 then
                                beam.sprite_index = spr_beam_csiwp
                            end
                        end
                    end
                end
                --firing a charged beam creates a damaging flare at your muzzle
                if actor:is_authority() and b == 1 then
                    local attack = actor:fire_explosion(actor.x + spawn_offset + direction * 5, actor.y - 6, 24, 24, damage * 0.6, spr_none, spr_none)
                    attack.attack_info.climb = i * 8 + 16
                end
                local chargeflare = GM.instance_create(actor.x + spawn_offset + direction * 5, actor.y - 6, gm.constants.oEfSparks)
                chargeflare.sprite_index = spr_beam_flare_0000
                chargeflare.image_xscale = direction
                chargeflare.image_yscale = 1
                chargeflare.image_speed = 0.25
            elseif actorData.spazer == 1 then
                beam.sprite_index = spr_beam_0s000
                if actorData.ice == 1 then
                    beam.sprite_index = spr_beam_0si00
                    beam.mask_index = beam.sprite_index
                    if actorData.wave >= 1 then
                        beam.sprite_index = spr_beam_0siw0
                        if actorData.plasma >= 1 then
                            beam.sprite_index = spr_beam_0siwp
                        end
                    end
                end
            end
            beam.statetime = 0--this tracks how long the beam object has existed, it increments by 1 in obj_beam on_step and i use it to do things
            beam.duration = math.min(actor.level * 10, 170)--like compare it to this variable and destroy it if it has existed too long
            beam_data.shadowclimb = i
            beam_data.parent = actor
            beam_data.horizontal_velocity = 10 * direction * (1 + 0.5 * actorData.beamcharged)--it should move faster if charged
            if b > 1 then--spazer nerf, main beam still does the most damage
                beam_data.damage_coefficient = damage / 2
            else
                beam_data.damage_coefficient = damage
            end
            beam_data.doproc = doproc--damage, doproc, and i get defined in stateHunterZ on_step
            beam_data.canhit = 1
            beam_data.shot = b
            beam_data.beamcharged = actorData.beamcharged
            beam_data.spazer = actorData.spazer
            beam_data.ice = actorData.ice
            beam_data.wave = actorData.wave
            beam_data.plasma = actorData.plasma
        end
    end

    Callback.add(hunter.on_step, function(actor)
        local data = Instance.get_data(actor)
        local ssrData = Instance.get_data(actor, "main", "RobomandosLab-Starstorm Returns")
        local free = Util.bool(actor.free)
        local usedAllFeathers = actor.jump_count >= actor:item_count(Item.find("hopooFeather", "ror"))
        local climbing = GM.actor_state_is_climb_state(actor.actor_state_current_id)
        local cv = actor.actor_state_current_id == ActorState.find("hunterC").value or actor.actor_state_current_id == ActorState.find("hunterV").value
        --walljumping, i used iceTool's but i tried to make it feel more like walljumping from the survivor's game of origin
        local wallx = 0

        if actor:is_colliding(gm.constants.pSolidBulletCollision, actor.x - 3 - actor.pHmax / 2.8) and Util.bool(actor.moveRight) then
            wallx = -1
        elseif actor:is_colliding(gm.constants.pSolidBulletCollision, actor.x + 3 + actor.pHmax / 2.8) and Util.bool(actor.moveLeft) then
            wallx = 1
        end
        local walljumpable = free and wallx ~= 0

        if walljumpable and not data.hunterJump_feather_preserve and not ssrData.iceTool_feather_preserve then
            data.hunterJump_feather_preserve = actor.jump_count
            actor.jump_count = math.huge
        elseif walljumpable and not data.hunterJump_feather_preserve and ssrData.iceTool_feather_preserve and ssrData.iceTool_feather_preserve ~= math.huge then
            data.hunterJump_feather_preserve = ssrData.iceTool_feather_preserve
        elseif walljumpable and not data.hunterJump_feather_preserve then
            data.hunterJump_feather_preserve = math.max(0, actor:item_count(Item.find("hopooFeather", "ror")) - 1)
        elseif not walljumpable and data.hunterJump_feather_preserve and ssrData.iceTool_feather_preserve ~= math.huge and data.hunterJump_feather_preserve ~= math.huge then
            actor.jump_count = data.hunterJump_feather_preserve
            data.hunterJump_feather_preserve = nil
        end
    --    if actor.jump_count ~= math.huge and (data.hunterJump_feather_preserve or data.iceTool_feather_preserve) then
    --        actor.jump_count = math.huge
    --    end
    --    the above lines stay commented or iceTool fucking kills me apparently even though that's where i got this from


        if Util.bool(actor.moveUp) and walljumpable and not cv then
            actor.pVspeed = -actor.pVmax - 1.5
	    	actor.free_jump_timer = 0
	    	actor.jumping = true
	    	actor.moveUp = false
	    	actor.moveUp_buffered = false

	    	actor.pHspeed = -actor.pHmax * wallx
	    	actor.image_xscale = -wallx
	    	actor.image_xscale2 = -wallx
            if not climbing then
                actor:sound_play(gm.constants.wClayHit, 1, 1.25)
            end
        end

        --Space Jumping (boots)
        --You can only Space Jump while falling just as it was originally
        if not free or climbing or actor:is_colliding(gm.constants.oGeyser) then
            data.spacejump_count = 0
        end
        local spacejumpable = free and actor.pVspeed > 0 and usedAllFeathers and data.spacejump_count < data.SpJB and not (walljumpable or cv or actor.jump_count == math.huge)
        if Util.bool(actor.moveUp) and spacejumpable then
            actor.pVspeed = -actor.pVmax
	    	actor.free_jump_timer = 0
	    	actor.jumping = true
	    	actor.moveUp = false
	    	actor.moveUp_buffered = false
            data.spacejump_count = data.spacejump_count + 1
            local SJfx = GM.instance_create(actor.x, actor.y + 11, gm.constants.oEfTrail)
            SJfx.parent = actor
            SJfx.image_yscale = 0.5
            SJfx.sprite_index = gm.constants.sEfJetpack
            SJfx.image_speed = 0.25
            SJfx.image_alpha = 0.75
        end

        --Missile tanks on-level
        data.mtanks = actor:item_count(missiletank)
        if not Options.experimental and data.mtanks < actor.level - 1 then
            actor:item_give(missiletank)
        end

        --Hi-jump boots on-level
        data.HJB = actor:item_count(hijump)
        if actor.level >= 8 and not Util.bool(data.HJB) then
            actor:item_give(hijump)
        end

        --Space Jump boots on-level
        data.SpJB = actor:item_count(spacejumpboots)
        if data.SpJB <= actor.level - 16 then
            actor:item_give(spacejumpboots)
        end

        --Varia Suit on-level
        data.varsuit = actor:item_count(varsuit)
        if actor.level >= 12 and not Util.bool(data.varsuit) then
            actor:item_give(varsuit)
        end

        --Gravity Suit on-level
        data.gravsuit = actor:item_count(gravsuit)
        if actor.level >= 16 and not Util.bool(data.gravsuit) then
            actor:item_give(gravsuit)
        end

        --Spazer Beam on-level
        data.spazer = actor:item_count(spazerbeam)
        if actor.level >= 11 and not Util.bool(data.spazer) then
            actor:item_give(spazerbeam)
        end

        --Ice Beam on-level
        data.ice = actor:item_count(icebeam)
        if actor.level >= 13 and not Util.bool(data.ice) then
            actor:item_give(icebeam)
        end

        --Wave Beam on-level
        data.wave = actor:item_count(wavebeam)
        if actor.level >= 15 and not Util.bool(data.wave) then
            actor:item_give(wavebeam)
        end

        --Plasma Beam on-level
        data.plasma = actor:item_count(plasmabeam)
        if actor.level >= 17 and not Util.bool(data.plasma) then
            actor:item_give(plasmabeam)
        end

    end)

    --ice beam debuff
    --bunch of jank to be able to freeze an enemy completely and stand on them
    local freeze86 = Buff.new("freeze86")
    freeze86.icon_sprite = gm.constants.sBuffs
    freeze86.icon_subimage = 7
    freeze86.is_debuff = true

    local obj_iceBlock_86 = Object.new("iceBlock_86")
    obj_iceBlock_86.obj_sprite = gm.constants.sNoSpawn
    obj_iceBlock_86.obj_depth = 1
    block = Object.find("bNoSpawn", "ror")

    --BEHOLD THE WORST POSSIBLE IMPLEMENTATION OF CUSTOM SOLID??
    --first, we make a custom object that has the behavior i want but isn't actually solid because i can't make it i guess. i need it to move with the actor and disappear if they die.

    Callback.add(obj_iceBlock_86.on_create, function(instance)
        instance.visible = false
        --instance.solid = true--this doesn't do anything
        instance.parent = -4
        instance.trueblock = -4
    end)

    Callback.add(obj_iceBlock_86.on_destroy, function(instance)
        if Instance.exists(instance.trueblock) then
            instance.trueblock:destroy()
            return
        end
    end)

    Callback.add(obj_iceBlock_86.on_step, function(instance)
        if not Instance.exists(instance.parent) then
            instance:destroy()
            return
        end
        instance.x = instance.parent.x
        instance.y = instance.parent.y
        instance.trueblock.x = instance.x
        instance.trueblock.y = instance.y
    end)
    
    Callback.add(freeze86.on_apply, function(actor, stack)
        actor.image_speed = 0
        if Options.solid_ice then
            actor._myblock_freeze86_anx = obj_iceBlock_86:create(actor.x, actor.y)
            if actor.mask_index >= 0 then
                actor._myblock_freeze86_anx.sprite_index = actor.mask_index
            else
                actor._myblock_freeze86_anx.sprite_index = actor.sprite_index
            end
            actor._myblock_freeze86_anx.parent = actor
            --then we create a real solid from the game that you can actually stand on and just put it where the custom object is. like an insane person would, i think
            actor._myblock_freeze86_anx.trueblock = block:create(actor.x, actor.y)
            actor._myblock_freeze86_anx.trueblock.sprite_index = actor._myblock_freeze86_anx.sprite_index
        end

        if not GM.actor_drawscript_attached(actor, Global.DrawScript_actor_frozen) then
            GM.actor_drawscript_attach(actor, Global.DrawScript_actor_frozen)
        end
        actor:sound_play(gm.constants.wFrozen, 1, 0.9 + math.random() * 0.2)
        --somehow they still move after having all their speeds set to 0 so i just used the code from timestop_active_update
        actor.is_update_enabled = not actor.disable_ai and actor.object_index == gm.constants.oP and not GM.actor_state_is_climb_state(actor.actor_state_current_id) and actor.activity_type ~= 7 and actor.activity ~= 90
    end)
    
    
    RecalculateStats.add(Callback.Priority.AFTER, function(actor, api)
        local stack = actor:buff_count(freeze86)
        if stack <= 0 then return end

        api.damage_mult(0)
        api.pHmax_mult(0)
        api.pVmax_mult(0)
    end)
    
    
    Callback.add(Callback.POST_STEP, function()
        local actors = freeze86:get_holding_actors()
        
        for _, actor in ipairs(actors) do
	        local bufftime = GM.get_buff_time(actor, freeze86)
            actor.pHspeed = 0
            actor.pVspeed = 0
            actor.activity = 50
		    actor:alarm_set(7, 10)
		    actor:alarm_set(2, 10)
            actor.image_speed = 0

            if not Options.solid_ice then
                if Instance.exists(actor) then
                    if not actor.ridable_collider or not Instance.exists(actor.ridable_collider) then
                        actor.ridable_collider = Object.find("ridableCollider", "ror"):create(actor.x, actor.y)
                        if actor.mask_index >= 0 then
                            actor.ridable_collider.mask_index = actor.mask_index
                        else
                            actor.ridable_collider.sprite_index = actor.sprite_index
                            actor.ridable_collider.mask_index = actor.sprite_index
                            actor.ridable_collider.image_index = actor.image_index
                            actor.ridable_collider.image_angle = actor.image_index
                        end
                        actor.ridable_collider.parent_object = actor.object_index
                        actor.ridable_collider.parent_mid = actor.m_id
                    end
                    actor.ridable_collider.x = actor.x
                    actor.ridable_collider.y = actor.y
                    --if bufftime < 1 and Instance.exists(actor.ridable_collider) then
                    --    Instance.destroy(actor.ridable_collider)
                    --end
                elseif Instance.exists(actor.ridable_collider) then
                    Instance.destroy(actor.ridable_collider)
                end
            end

            if Global.time_stop > 0 and bufftime > 1 then
                GM.set_buff_time(actor, freeze86, bufftime + 1)
            end
            actor.is_update_enabled = not actor.disable_ai and actor.object_index == gm.constants.oP and not GM.actor_state_is_climb_state(actor.actor_state_current_id) and actor.activity_type ~= 7 and actor.activity ~= 90
        end
    end)

    Callback.add(freeze86.on_remove, function(actor, stack)
        actor.is_update_enabled = true
        actor:skill_util_reset_activity_state()
        if GM.actor_drawscript_attached(actor, Global.DrawScript_actor_frozen) then
            GM.actor_drawscript_remove(actor, Global.DrawScript_actor_frozen)
        end
        if Instance.exists(actor._myblock_freeze86_anx) then
            actor._myblock_freeze86_anx:destroy()
        end
        if not Options.solid_ice and Instance.exists(actor.ridable_collider) then
            --Destroy this in a 1-frame alarm because it otherwise persists for some reason
            Alarm.add(1, function()
                if Instance.exists(actor.ridable_collider) then Instance.destroy(actor.ridable_collider) end
            end)
        end
    end)

    Hook.add_post("gml_Object_pActor_CleanUp_0", function(self, other)
        if Options.solid_ice then return end
        if self.ridable_collider and Instance.exists(self.ridable_collider) then
            Instance.destroy(self.ridable_collider)
        end
    end)
    
    Callback.add(obj_beam.on_step, function(instance)
        local data = Instance.get_data(instance)
        local actor = data.parent
        if Util.bool(data.wave) and instance.depth > -300 then
            instance.depth = -301
        end
        if Util.bool(data.plasma) and not (Options.beam_limit or Options.offscr_destroy) then
            local trail = GM.instance_create(instance.x, instance.y, gm.constants.oEfTrail)
            trail.sprite_index = instance.sprite_index
            trail.image_index = 0
            trail.image_alpha = 0.375
            trail.image_speed = instance.image_speed
            trail.image_xscale = instance.image_xscale
            trail.image_yscale = instance.image_yscale
            trail.depth = instance.depth + 1
            trail.rate = 0.25
        end
        
        local maxbeams = Options.gui_maxbeams
        if Util.bool(data.spazer) then
            --has_spazer = true
        end
        if Util.bool(data.plasma) then
            --has_plasma = true
        end
        if Options.beam_limit then
            local all, _ = Instance.find_all(obj_beam)--too many of these lag so we KILL them
            for _, other_beam in ipairs(all) do
                if _ > maxbeams then
                    instance:destroy()
                    return
                end
            end
        end
        
        local slow2 = Buff.find("slow2", "ror")
        local snare = Buff.find("snare", "ror")
        instance.x = instance.x + data.horizontal_velocity + data.parent.pHspeed--my beam inherits the momentum of its creator in real-time
        if instance.statetime < 3 and not Util.bool(data.wave) then--this is to reposition extra beams from the spazer upgrade
            if data.shot == 2 then
                instance.y = instance.y - 3
            end
            if data.shot == 3 then
                instance.y = instance.y + 3
            end
        end
        if Util.bool(data.wave) and Util.bool(data.spazer) then--wave shots move... in a wave
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
            local resolved_actor = GM.attack_collision_resolve(other_actor)
            if data.parent:attack_collision_canhit(other_actor) then
                -- Deal damage
                local damage_direction = 0
                if data.horizontal_velocity < 0 then
                    damage_direction = 180
                end
                if data.parent:is_authority() and data.canhit >= 1 then--authoritative attack to prevent double networked hitboxes
                    if GM.actor_is_boss(resolved_actor) and Util.bool(data.beamcharged) then
                        data.damage_coefficient = data.damage_coefficient * 1.25
                    end
                    local attack = data.parent:fire_direct(other_actor, data.damage_coefficient, damage_direction, instance.x, instance.y, spr_none, data.doproc)
                    attack.attack_info.climb = (data.shadowclimb + data.shot - 1) * 8--this is accounting for being from a shadow clone and which beam it is
                    data.canhit = 0
                end
                if Util.bool(data.ice) then--the following is supposed to apply the ice debuff, 20%-100% chance based on the base damage and only if the actor is alive and not a boss
                    if math.random() <= math.max(0.2, math.min(1, data.damage_coefficient / 9)) and resolved_actor.hp > 0 and not GM.actor_is_boss(other_actor) then
                        if resolved_actor:buff_count(freeze86) == 0 then
                            GM.apply_buff(resolved_actor, freeze86, 4 * 60, 1)
                        else
                            GM.set_buff_time(resolved_actor, freeze86, 4 * 60)
                        end
                    end
                end

                -- Destroy the beam if not plasma
                if not Util.bool(data.plasma) or GM.actor_is_boss(resolved_actor) then
                    instance:destroy()
                    return
                end
            end
        end
        local canhitwhen = 2
        if Util.bool(data.plasma) and data.canhit < 1 then
            data.canhit = data.canhit + (1 / canhitwhen)
        end
        --i want the beam to break blocks and hit buttons, so i made it fire a damageless explosion when it collides with one
        if instance:is_colliding(gm.constants.pEnvironmentShootable) then
            data.parent:fire_explosion(instance.x, instance.y, 32, 32, 0, spr_none, spr_none, false)
        end
        -- Hitting terrain destroys the beam
        if instance:is_colliding(gm.constants.pSolidBulletCollision) and not Util.bool(data.wave) then
            instance:destroy()
            return
        end

        -- Check we're within stage bounds
        local stage_width = gm._mod_room_get_current_width()
        local stage_height = gm._mod_room_get_current_height()
        if instance.x < -16 or instance.x > stage_width + 16 
           or instance.y < -16 or instance.y > stage_height + 16 
        then 
            instance:destroy()
            return
        end
        --Check if we've gone offscreen if the "Destroy Offscreen Beams" GUI option is set
        if (Options.offscr_destroy) and not Util.bool(GM.inside_view(instance.x, instance.y)) then
            instance:destroy()
            return
        end

        -- The beam cannot exist for too long
        if (Options.offscr_destroy) and gm._mod_net_isOnline() and not actor:is_authority() and instance.statetime >= 20 then
            instance:destroy()
            return
        end
        if instance.statetime >= 20 + (instance.duration) then
            instance:destroy()
            return
        end
        instance.statetime = instance.statetime + 1--statetime tracks how long the beam has existed, duration is set by the creator
    end)

    local obj_missile = Object.new("hunter_missile")
    obj_missile.obj_sprite = spr_missile
    obj_missile.obj_depth = 1
    
    Callback.add(obj_missile.on_step, function(instance)
        local data = Instance.get_data(instance)
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
                    local attack = data.parent:fire_explosion(instance.x, instance.y, 64, 64, data.damage_coefficient, spr_missile_explosion, spr_none)
                    attack.attack_info.climb = data.shadowclimb * 8
                end
                if data.parent:item_count(Item.find("brilliantBehemoth", "ror")) == 0 then
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
                local attack = data.parent:fire_explosion(instance.x, instance.y, 64, 64, data.damage_coefficient, spr_missile_explosion, spr_none)
                attack.attack_info.climb = data.shadowclimb * 8
            end
            if data.parent:item_count(Item.find("brilliantBehemoth", "ror")) == 0 then
                instance:sound_play(gm.constants.wExplosiveShot, 0.8, 1)
            end
            instance:destroy()
            return
        end

        -- Check we're within stage bounds
        local stage_width = gm._mod_room_get_current_width()
        local stage_height = gm._mod_room_get_current_height()
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
    
    local obj_bomb = Object.new("hunter_bomb")
    obj_bomb.obj_sprite = spr_bomb
    obj_bomb.obj_depth = -501

    Callback.add(obj_bomb.on_step, function(instance)
        local data = Instance.get_data(instance)

        -- Fuse
        if instance.statetime >= 30 then
            local parentalignx = data.parent.x - 4
            local diffx = parentalignx - instance.x
            --bomb jumping
            if instance:distance_to_point(data.parent.x, data.parent.y + 11) <= 22 and instance.hitowner == 0 then
                if parentalignx ~= instance.x then
                    data.parent.pHspeed = data.parent.pHspeed + 2.8 * GM.sign(diffx)
                end
                data.parent.pVspeed = -8
                instance.hitowner = 1
            end
            if data.fired == 0 then
                if data.parent:is_authority() then
                    local attack = data.parent:fire_explosion(instance.x, instance.y, 64, 64, data.damage_coefficient, spr_missile_explosion, spr_none)
                    attack.attack_info.climb = data.shadowclimb * 8
                end
                if data.parent:item_count(Item.find("brilliantBehemoth", "ror")) == 0 then
                    --to make sure it doesn't play the sound twice
                    instance:sound_play(gm.constants.wExplosiveShot, 0.8, 1)
                end
                instance.image_alpha = 0
                --return stocks to the user after exploding
                local skill4 = data.parent:get_active_skill(3)
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
    
    local obj_powerbomb = Object.new("hunter_powerbomb")
    obj_powerbomb.obj_sprite = spr_powerbomb
    obj_powerbomb.obj_depth = -501
    
    local obj_powerbomb_explosion = Object.new("hunter_powerbomb_explosion")
    obj_powerbomb_explosion.obj_sprite = spr_powerbomb_explosion
    obj_powerbomb_explosion.obj_depth = -501

    Callback.add(obj_powerbomb.on_step, function(instance)
        local data = Instance.get_data(instance)

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
                data.parent.pVspeed = -8
                instance.hitowner = 1
            end
            if data.fired == 0 then
                local powerbombex = obj_powerbomb_explosion:create(instance.x + 4, instance.y + 4)
                powerbombex.statetime = 0
                powerbombex.image_xscale = 0
                powerbombex.image_yscale = 0
                powerbombex.image_alpha = 0.8
                powerbombex.image_speed = 0.25
                local powerbombex_data = Instance.get_data(powerbombex)
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

    --i have a custom object to handle the slowly expanding explosion

    Callback.add(obj_powerbomb_explosion.on_step, function(instance)
        local data = Instance.get_data(instance)
        local actor_collisions, _ = instance:get_collisions(gm.constants.pActorCollisionBase)

        if instance.image_xscale < 1 then
            instance.image_xscale = instance.image_xscale + 0.02
            instance.image_yscale = instance.image_yscale + 0.02
            if instance.image_index >= 4 then
                instance.image_index = 3
            end
            if math.fmod(instance.statetime, 5) == 0 then
                if data.parent:is_authority() then
                    local attack = data.parent:fire_explosion(instance.x, instance.y,  1366 * instance.image_xscale, 768 * instance.image_yscale, 0, spr_none, spr_none)
                    attack.attack_info.climb = data.shadowclimb * 8
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
    local hunterZ = hunter:get_skills(0)[1]
    local hunterX = hunter:get_skills(1)[1]
    local hunterC = hunter:get_skills(2)[1]
    local hunterV = hunter:get_skills(3)[1]
    local hunterVBoosted = Skill.new("hunterVBoosted")
    hunterV.upgrade_skill = hunterVBoosted.value

    -- Set the animations for each skill
    hunterZ.animation = sprites.walk
    hunterX.animation = sprites.walk
    hunterC.animation = spr_flashshift
    hunterV.animation = spr_morph
    hunterVBoosted.animation = spr_morph
    
    -- Set the icons for each skill, specifying the icon spritesheet and the specific subimage
    hunterZ.sprite = spr_skills
    hunterZ.subimage = 0
    hunterX.sprite = spr_skills
    hunterX.subimage = 1
    hunterC.sprite = spr_skills
    hunterC.subimage = 2
    hunterV.sprite = spr_skills
    hunterV.subimage = 3
    hunterVBoosted.sprite = spr_skills
    hunterVBoosted.subimage = 4
    
    -- Set the damage coefficient and cooldown for each skill. A damage coefficient of 100% is equal
    -- to 1.0, 150% to 1.5, 200% to 2.0, and so on. Cooldowns are specified in frames, so multiply by
    -- 60 to turn that into actual seconds.
    hunterZ.damage = 1.2
    hunterZ.cooldown = 0
    hunterZ.require_key_press = true
    hunterZ.use_delay = 5
    hunterX.damage = 4.0
    hunterX.cooldown = 120
    local base_stocks = 5
    hunterX.max_stock = base_stocks
    hunterX.start_with_stock = base_stocks
    hunterC.damage = 0
    hunterC.cooldown = 240
    hunterC.max_stock = 2
    hunterC.start_with_stock = 2
    hunterC.is_utility = true
    hunterV.damage = 1.5
    hunterV.cooldown = 0
    hunterV.is_primary = true
    hunterV.max_stock = 3
    hunterV.start_with_stock = 3
    hunterV.auto_restock = false
    hunterV.require_key_press = true
    hunterV.required_interrupt_priority = ActorState.InterruptPriority.SKILL
    hunterVBoosted.damage = 30.0
    hunterVBoosted.cooldown = 900
    hunterVBoosted.require_key_press = true
    hunterVBoosted.required_interrupt_priority = ActorState.InterruptPriority.SKILL

    -- Again consider renaming these variables after the ability itself
    local stateHunterZ = ActorState.new(hunterZ.identifier)
    local stateHunterX = ActorState.new(hunterX.identifier)
    local stateHunterC = ActorState.new(hunterC.identifier)
    stateHunterC.activity_flags = ActorState.ActivityFlag.ALLOW_ROPE_CANCEL
    local stateHunterV = ActorState.new(hunterV.identifier)
    local stateHunterVBoosted = ActorState.new(hunterVBoosted.identifier)
    
    -- Register callbacks that switch states when skills are activated
    Callback.add(hunterZ.on_activate, function(actor, skill, slot)
        actor:set_state(stateHunterZ)
    end)
    
    Callback.add(hunterX.on_activate, function(actor, skill, slot)
        actor:set_state(stateHunterX)
    end)

    --Callback.add(hunterX.on_step, function(actor, skill)
    --    local data = Instance.get_data(actor)
    --end)
    
    Callback.add(hunterC.on_activate, function(actor, skill, slot)
        actor:set_state(stateHunterC)
    end)
    
    Callback.add(hunterV.on_activate, function(actor, skill, slot)
        actor:set_state(stateHunterV)
    end)
    
    Callback.add(hunterVBoosted.on_activate, function(actor, skill, slot)
        actor:set_state(stateHunterVBoosted)
    end)

    -- Executed when stateHunterZ is entered
    Callback.add(stateHunterZ.on_enter, function(actor, data)
        actor:skill_util_strafe_init()
        actor:skill_util_strafe_turn_init()
        local actorData = Instance.get_data(actor)
        local played_sounds = {
            snd_charge = 0
        }
        --if actor:is_authority() then
            actor.image_index2 = 0 -- Make sure our animation starts on its first frame
            -- index2 is needed for strafe sprites to work. From here we can setup custom data that we might want to refer back to in on_step
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
        data.statetime = 0
    end)

    -- Executed every game tick during this state
    Callback.add(stateHunterZ.on_step, function(actor, data)
        actor.sprite_index2 = spr_shoot1_half
        -- index2 is needed for strafe sprites to work
        actor:skill_util_strafe_update(0.25 * actor.attack_speed, 1.0) -- 0.25 means 4 ticks per frame at base attack speed
        actor:skill_util_step_strafe_sprites()
        actor:skill_util_strafe_turn_update()
        local actorData = Instance.get_data(actor)
        local release = false
        if Util.bool(actor.is_local) then
            release = not GM.SO.control(actor, nil, "skill1", 0)
        elseif not actor:is_authority() then
            release = Util.bool(actor.activity_var2)
        end--i took some code from nemmando, this gets referenced later
        local damage = actor:skill_get_damage(hunterZ)
        local direction = GM.cos(GM.degtorad(actor:skill_util_facing_direction()))
        local buff_shadow_clone = Buff.find("shadowClone", "ror")
        local spawn_offset = 5 * direction
        local doproc = true--i stick this into the "can_proc" arg for fire_direct
        actorData.shots = 1
        if actorData.spazer > 0 then
            actorData.shots = 3
        end
        if actorData.ice > 0 then
            damage = damage * 1.25
        end
        if actorData.wave > 0 then
            damage = damage * 1.25
        end
        if actor.local_aim_dir ~= 0 then
            actor.image_xscale = actor.local_aim_dir
            actor.image_xscale2 = actor.local_aim_dir
        end

        --if actor:is_authority() then
            if actor.image_index2 >= 0 and data.fired == 0 then--fire an uncharged beam as soon as the skill starts, it's just how i want the attack to work
                data.fired = 1
                if actor:skill_util_update_heaven_cracker(actor, damage) then
                    doproc = false
                end
                    for i=0, actor:buff_count(buff_shadow_clone) do
                        fireBeam(actorData, actor, spawn_offset, direction, damage, doproc, i)
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
                            local sparks = GM.instance_create(actor.x + spawn_offset + direction * 5, actor.y - 6, gm.constants.oEfSparks)
                            sparks.sprite_index = gm.constants.sSparks18
                            sparks.depth = actor.depth - 2
                            sparks.image_blend = Color.YELLOW
                        end
                        if actorData.beamcharged == 1 then--this should probably just say else, i want you to flash while charging
                            if math.fmod(data.wannacharge, 6) == 0 then
                                local chargeflash = GM.instance_create(actor.x, actor.y, gm.constants.oEfFlash)
			                    chargeflash.parent = actor
			                    chargeflash.rate = 1 / 6
			                    chargeflash.image_alpha = 0.5
                            end
                        end
                    end
                end
            else
                if actor:is_authority() then--this is where the nemmando code goes into play, this is some packet stuff to try to sync the held-down charge
                    if Net.host then
                        GM.server_message_send(0, 43, actor:get_object_index_self(), actor.m_id, 1, gm.sign(actor.image_xscale))
                    else
                        GM.client_message_send(43, 1, gm.sign(actor.image_xscale))
                    end
                end
                if actor.image_index2 >= 0 and data.fired == 1 and data.wannacharge >= 10 then
                    data.fired = 2--since i'm firing a second beam
                    if actorData.beamcharged == 1 then
                        damage = damage * 5
                    end
                    if actor:skill_util_update_heaven_cracker(actor, damage) then
                        doproc = false
                    end
                        for i=0, actor:buff_count(buff_shadow_clone) do 
                            fireBeam(actorData, actor, spawn_offset, direction, damage, doproc, i)
                        end
                    actor:sound_play(gm.constants.wGuardDeathOLD, 0.4, 1.5 + math.random() * 0.1)
                    data.released = 1
                    if actor:is_authority() and GM._mod_sound_isPlaying(snd_chargeloop) then
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

    Callback.add(stateHunterZ.on_exit, function(actor, data)
        actor:skill_util_strafe_exit()
        data.statetime = 0
        --if actor:is_authority() and GM._mod_sound_isPlaying(snd_chargeloop) then
        --    GM._mod_sound_stop(snd_chargeloop)
        --end
    end)

    -- Executed when stateHunterX is entered
    Callback.add(stateHunterX.on_enter, function(actor, data)
        actor:skill_util_strafe_init()
        actor:skill_util_strafe_turn_init()
        actor.image_index2 = 0 -- Make sure our animation starts on its first frame
        -- index2 is needed for strafe sprites to work. From here we can setup custom data that we might want to refer back to in on_step
        -- Our flag to prevent firing more than once per attack
        data.fired = 0
 
    end)
    
    -- Executed every game tick during this state
    Callback.add(stateHunterX.on_step, function(actor, data)
        actor.sprite_index2 = spr_shoot1_half
        -- index2 is needed for strafe sprites to work    
        actor:skill_util_strafe_update(0.25 * actor.attack_speed, 1.0) -- 0.25 means 4 ticks per frame at base attack speed
        actor:skill_util_step_strafe_sprites()
        actor:skill_util_strafe_turn_update()

        if actor.image_index2 >= 0 and data.fired == 0 then
            data.fired = 1
    
            local direction = GM.cos(GM.degtorad(actor:skill_util_facing_direction()))
            local buff_shadow_clone = Buff.find("shadowClone", "ror")
            for i=0, actor:buff_count(buff_shadow_clone) do 
                local spawn_offset = 16 * direction
                local missile = obj_missile:create(actor.x + spawn_offset, actor.y - 10)
                missile.image_speed = 0.25
                missile.image_xscale = direction
                missile.statetime = 0
                local missile_data = Instance.get_data(missile)
                missile_data.shadowclimb = i
                missile_data.parent = actor
                missile_data.horizontal_velocity = 0
                local damage = actor:skill_get_damage(hunterX)
                missile_data.damage_coefficient = damage


            end
            actor:sound_play(gm.constants.wMissileLaunch, 1, 0.8 + math.random() * 0.2)
        end
    
    
        -- A convenience function that exits this state automatically once the animation ends
        actor:skill_util_exit_state_on_anim_end()
    end)

    Callback.add(stateHunterX.on_exit, function(actor, data)
        actor:skill_util_strafe_exit()
    end)

    -- Executed when stateHunterC is entered
    Callback.add(stateHunterC.on_enter, function(actor, data)
        actor.image_index = 0 -- Make sure our animation starts on its first frame
        -- From here we can setup custom data that we might want to refer back to in on_step
        actor:sound_play(gm.constants.wHuntressShoot3, 1, 0.8 + math.random() * 0.2)
        actor.shiftedfrom = actor.y
        local circle = GM.instance_create(actor.x, actor.y, gm.constants.oEfCircle)
        circle.parent = actor
        circle.radius = 20
        circle.image_blend = Color(0x73eeff)
        if Util.bool(actor.moveLeft) then
            data.direction = -1
        elseif Util.bool(actor.moveRight) then
            data.direction = 1
        else
            data.direction = GM.cos(GM.degtorad(actor:skill_util_facing_direction()))
        end
        if data.direction ~= GM.cos(GM.degtorad(actor:skill_util_facing_direction())) then
            actor.image_xscale = -actor.image_xscale
        end
    end)
    
    -- Executed every game tick during this state
    Callback.add(stateHunterC.on_step, function(actor, data)
        actor:skill_util_fix_hspeed()
        -- Set the animation and animation speed. This speed will automatically have the survivor's 
        -- attack speed bonuses applied (e.g. from Soldier's Syringe)
        local animation = actor:actor_get_skill_animation(hunterC)
        local animation_speed = 0.25

        -- We don't want attack speed to speed up the dodge itself, because that could end up
        -- reducing the dodge window, so we undo its benefit ahead of time
        if actor.attack_speed > 0 then
            animation_speed = animation_speed / actor.attack_speed
        end

        actor:actor_animation_set(animation, animation_speed)

        local direction = data.direction
        local buff_shadow_clone = Buff.find("shadowClone", "ror")
        if actor.invincible <= 3 then 
            actor.invincible = 3
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

    Callback.add(stateHunterC.on_exit, function(actor, data)
        actor.pHspeed = 0
        data.direction = nil
    end)

    -- Executed when stateHunterV is entered
    Callback.add(stateHunterV.on_enter, function(actor, data)
        local actorData = Instance.get_data(actor)
        actorData.sprite_idle_half_prev = actor.sprite_idle_half
        actorData.sprite_walk_half_prev = actor.sprite_walk_half
        actorData.sprite_jump_half_prev = actor.sprite_jump_half
        actorData.sprite_jump_peak_half_prev = actor.sprite_jump_peak_half
        actorData.sprite_fall_half_prev = actor.sprite_fall_half
        actor.sprite_idle_half = actor.sprite_morph_half_anxvariable
        actor.sprite_walk_half = actor.sprite_morph_half_anxvariable
        actor.sprite_jump_half = actor.sprite_morph_half_anxvariable
        actor.sprite_jump_peak_half = actor.sprite_morph_half_anxvariable
        actor.sprite_fall_half = actor.sprite_morph_half_anxvariable
        actor:survivor_util_init_half_sprites()
        actor:skill_util_strafe_init()
        actor:skill_util_strafe_turn_init()
        actor.image_index2 = 0 -- Make sure our animation starts on its first frame
        -- index2 is needed for strafe sprites to work. From here we can setup custom data that we might want to refer back to in on_step
        actor.image_yscale = 0.5
        actor.y = actor.y + 6
        -- Our flag to prevent firing more than once per attack
        data.fired = 0
 
    end)
    
    -- Executed every game tick during this state
    Callback.add(stateHunterV.on_step, function(actor, data)
        actor.sprite_index2 = spr_morph2
        -- index2 is needed for strafe sprites to work
        actor:skill_util_strafe_update(0.25 * actor.attack_speed, 1.0) -- 0.25 means 4 ticks per frame at base attack speed
        actor:skill_util_step_strafe_sprites()
        actor:skill_util_strafe_turn_update()

        if actor.image_index2 >= 1 and data.fired == 0 then
            data.fired = 1
            actor:sound_play(gm.constants.wPlayer_TakeDamage, 0.75, 1.5)
            local buff_shadow_clone = Buff.find("shadowClone", "ror")
            for i=0, actor:buff_count(buff_shadow_clone) do
                local bomb = obj_bomb:create(actor.x - 4, actor.y - 3)
                bomb.statetime = 0
                bomb.hitowner = 0
                local bomb_data = Instance.get_data(bomb)
                bomb_data.shadowclimb = i
                bomb_data.parent = actor
                local damage = actor:skill_get_damage(hunterV)
                bomb_data.damage_coefficient = damage
                bomb_data.fired = 0
            end
        end
            
        -- A convenience function that exits this state automatically once the animation ends
        actor:skill_util_exit_state_on_anim_end()
    end)

    Callback.add(stateHunterV.on_exit, function(actor, data)
        actor:skill_util_strafe_exit()
        local actorData = Instance.get_data(actor)
        actor.sprite_idle_half = actorData.sprite_idle_half_prev
        actor.sprite_walk_half = actorData.sprite_walk_half_prev
        actor.sprite_jump_half = actorData.sprite_jump_half_prev
        actor.sprite_jump_peak_half = actorData.sprite_jump_peak_half_prev
        actor.sprite_fall_half = actorData.sprite_fall_half_prev
        actorData.sprite_idle_half_prev = nil
        actorData.sprite_walk_half_prev = nil
        actorData.sprite_jump_half_prev = nil
        actorData.sprite_jump_peak_half_prev = nil
        actorData.sprite_fall_half_prev = nil
        actor:survivor_util_init_half_sprites()
        actor.image_yscale = 1
        actor.y = actor.y - 6
    end)

    Callback.add(stateHunterV.on_get_interrupt_priority, function(actor, data)
        if actor.image_index2 <= 2 then
            return ActorState.InterruptPriority.PRIORITY_SKILL
        else
            return ActorState.InterruptPriority.SKILL_INTERRUPT_PERIOD
        end
    end)

    -- Executed when stateHunterVBoosted is entered
    Callback.add(stateHunterVBoosted.on_enter, function(actor, data)
        local actorData = Instance.get_data(actor)
        actorData.sprite_idle_half_prev = actor.sprite_idle_half
        actorData.sprite_walk_half_prev = actor.sprite_walk_half
        actorData.sprite_jump_half_prev = actor.sprite_jump_half
        actorData.sprite_jump_peak_half_prev = actor.sprite_jump_peak_half
        actorData.sprite_fall_half_prev = actor.sprite_fall_half
        actor.sprite_idle_half = actor.sprite_morph_half_anxvariable
        actor.sprite_walk_half = actor.sprite_morph_half_anxvariable
        actor.sprite_jump_half = actor.sprite_morph_half_anxvariable
        actor.sprite_jump_peak_half = actor.sprite_morph_half_anxvariable
        actor.sprite_fall_half = actor.sprite_morph_half_anxvariable
        actor:survivor_util_init_half_sprites()
        actor:skill_util_strafe_init()
        actor:skill_util_strafe_turn_init()
        actor.image_index2 = 0 -- Make sure our animation starts on its first frame
        -- index2 is needed for strafe sprites to work. From here we can setup custom data that we might want to refer back to in on_step
        actor.image_yscale = 0.5
        actor.y = actor.y + 6
        -- Our flag to prevent firing more than once per attack
        data.fired = 0
 
    end)
    
    -- Executed every game tick during this state
    Callback.add(stateHunterVBoosted.on_step, function(actor, data)
        actor.sprite_index2 = spr_morph2
        -- index2 is needed for strafe sprites to work
        actor:skill_util_strafe_update(0.25 * actor.attack_speed, 1.0) -- 0.25 means 4 ticks per frame at base attack speed
        actor:skill_util_step_strafe_sprites()
        actor:skill_util_strafe_turn_update()

        if actor.image_index2 >= 1 and data.fired == 0 then
            data.fired = 1
            actor:sound_play(gm.constants.wBossLaser1Fire, 0.8, 1)
            local buff_shadow_clone = Buff.find("shadowClone", "ror")
            for i=0, actor:buff_count(buff_shadow_clone) do
                local powerbomb = obj_powerbomb:create(actor.x - 4, actor.y - 3)
                powerbomb.statetime = 0
                powerbomb.hitowner = 0
                local powerbomb_data = Instance.get_data(powerbomb)
                powerbomb_data.shadowclimb = i
                powerbomb_data.parent = actor
                local damage = actor:skill_get_damage(hunterVBoosted)
                powerbomb_data.damage_coefficient = damage
                powerbomb_data.fired = 0
            end
        end
            
        -- A convenience function that exits this state automatically once the animation ends
        actor:skill_util_exit_state_on_anim_end()
    end)

    Callback.add(stateHunterVBoosted.on_exit, function(actor, data)
        actor:skill_util_strafe_exit()
        local actorData = Instance.get_data(actor)
        actor.sprite_idle_half = actorData.sprite_idle_half_prev
        actor.sprite_walk_half = actorData.sprite_walk_half_prev
        actor.sprite_jump_half = actorData.sprite_jump_half_prev
        actor.sprite_jump_peak_half = actorData.sprite_jump_peak_half_prev
        actor.sprite_fall_half = actorData.sprite_fall_half_prev
        actorData.sprite_idle_half_prev = nil
        actorData.sprite_walk_half_prev = nil
        actorData.sprite_jump_half_prev = nil
        actorData.sprite_jump_peak_half_prev = nil
        actorData.sprite_fall_half_prev = nil
        actor:survivor_util_init_half_sprites()
        actor.image_yscale = 1
        actor.y = actor.y - 6
    end)

    Callback.add(stateHunterVBoosted.on_get_interrupt_priority, function(actor, data)
        if actor.image_index2 <= 2 then
            return ActorState.InterruptPriority.PRIORITY_SKILL
        else
            return ActorState.InterruptPriority.SKILL_INTERRUPT_PERIOD
        end
    end)

    local oChinyTozo = Object.new("hunter_chinyTozo", Object.Parent.INTERACTABLE)
    oChinyTozo:set_sprite(spr_chinytozo)
    oChinyTozo:set_depth(90)

    local function chinytozo_get_candidates()
        local stage = Stage.wrap(Global.stage_id)
        local spawn_enemies = List.wrap(stage.spawn_enemies)
        local candidates = Array.new()
        for i = 0, (math.max(0, spawn_enemies:size() - 1)) do
            local card = MonsterCard.wrap(spawn_enemies:get(i))
            if card.can_be_blighted and card.spawn_cost < 760 then
                candidates:push(card)
            end
        end
        return candidates
    end

    local function chinytozo_give_reward_alarm(instance, item)
        if not Instance.exists(instance) then return end
        local target
        if Instance.exists(instance.activator) then target = instance.activator end
        Sound.wrap(gm.constants.wChest1):play(instance.x, instance.y, 1, 1)
        if Net.host then item:create(instance.x, instance.y, target) end
        instance.rewards = instance.rewards - 1
        if instance.rewards > 0 then Alarm.add(45, chinytozo_give_reward_alarm, instance, item, target) end
    end

    Callback.add(oChinyTozo.on_create, function(instance)
        GM.interactable_init_cost(instance, 0, 100)
        instance:interactable_init_name()
        instance.candidates = chinytozo_get_candidates()
        instance.minions = Array.new()
        instance.minions_max = math.max(1, math.floor((math.log(gm._mod_game_getDirector().enemy_buff) / math.log(2))))
        instance.minions_dead = 0
        instance.spawn_elite = math.random(0, 5)
        instance.rewards = math.random(3)
        instance.has_item = true
    end)

    Callback.add(oChinyTozo.on_step, function(instance)
        if instance.active == 1 then
            instance:sound_play(gm.constants.wShrine1, 1, 1)
            local director = gm._mod_game_getDirector()
            local card = instance.candidates:get(math.random(0, instance.candidates:size() - 1))
            if ssrOn and math.random() > 0.5 and director.stages_passed > 8 then
                instance.spawn_elite = Elite.find("empyrean", "ssr").value
                instance.minions_max = math.max(1, math.floor(instance.minions_max / 2))
            elseif gm.elite_can_spawn_blighted_enemies() then
                instance.spawn_elite = Elite.find("blighted", "ror").value
            else
                instance.minions_max = math.min(32, math.ceil(2 ^ instance.minions_max))
            end
            local preserve_elite = director.spawn_elite
            for i = 1, instance.minions_max do
                local spawn = director:director_spawn_monster_card(instance.x, instance.y, card, director.bonus_rate)
                director.spawn_elite = instance.spawn_elite
                director:director_try_elite_spawn(spawn, card, false)
                if MonsterCard.wrap(card).spawn_type ~= 3 then
                    GM.teleport_nearby(spawn, instance.x + math.random(-960 , 960), instance.y)
                end
                instance.minions:push(spawn)
            end
            director.spawn_elite = preserve_elite
            local ep = Instance.wrap(instance.minions:get(0)):actor_create_enemy_party_from_ids(instance.minions)
            director.register_boss_party(director, nil, ep.value)
        elseif instance.active == 2 then
            if math.fmod(Global._current_frame, 60) == 0 then
                local dead = 0
                for i = 0, instance.minions:size() - 1 do
                    if not Instance.exists(instance.minions:get(i)) then
                        dead = dead + 1
                    end
                end
                instance.minions_dead = dead
            end
            if instance.minions_dead == instance.minions_max and instance.has_item then
                chinytozo_give_reward_alarm(instance, Item.find("missileTank", "hunter"))
                instance.has_item = false
            end
        end
    end)

    Callback.add(Callback.ON_STAGE_START, function()
	if Net.client or Global.__gamemode_current >= 2 or Stage.wrap(Global.stage_id).identifier == "riskOfRain" then return end
    -- host handles spawning, don't spawn in trials or tutorial, don't spawn on contact light
    local do_chinytozo_spawn = false
    local players = Instance.find_all(gm.constants.oP)
    local hunters = {}
    for _, player in ipairs(players) do
        if player.class == hunter.value then
            do_chinytozo_spawn = true
            table.insert(hunters, player)
        end
    end
    if not do_chinytozo_spawn or not Options.experimental then return end

    local attempts = 0
    while Instance.count(oChinyTozo) < #hunters * 2 do
	    gm._mod_game_getDirector():mapobject_spawn(oChinyTozo.value, 1, nil, nil, nil, nil, gm.constants.oB, nil, nil, nil, nil, nil, nil, attempts > 32)
        attempts = attempts + 1
    end

end)
    
end
Initialize.add(initialize)

-- ** Uncomment the two lines below to re-call initialize() on hotload **
if hotload then initialize() end

Hook.add_pre("gml_Object_oLava_Collision_pActorCollisionBase", function(self, other)
    local actor = GM.attack_collision_resolve(other)
    if actor ~= -4 then
        if actor:item_count(Item.find("gravitySuit")) > 0 then
            return false
        end
    end
end)
