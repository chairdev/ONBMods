local DAMAGE = 150

-- Audio
local spawn_sfx = Engine.load_audio(_folderpath.."exe6-spawn.ogg")
local boost_sfx = Engine.load_audio(_folderpath.."boost.ogg")
local damage_sfx = Engine.load_audio(_folderpath.."hurt.ogg")

-- Visuals
local CROSSMAN_TEXTURE = Engine.load_texture(_folderpath.."crossman.png")
local CROSSMAN_ANIMPATH = _folderpath.."crossman.animation"

local boost_texture = Engine.load_texture(_folderpath.."boost.png")
local boost_animation_path = _folderpath.."boost.animation"
local spell_bullet_texture = Engine.load_texture(_folderpath.."spell_bullet_hit.png")
local spell_bullet_animation = _folderpath.."spell_bullet_hit.animation"

local crossman = {
    codes = {"C","*"},
    shortname = "CrossMan",
    damage = DAMAGE,
    time_freeze = true,
    element = Element.None,
    description = "Warp in and slice the enemy",
    long_description = "CrossMan warps in and dashes forward through foes until x=7!",
    can_boost = true,
    card_class = CardClass.Mega,
    limit = 2
}

-- helper for artifacts/spells
local function graphic_init(type, x, y, texture, animation, layer, state, user, facing, delete_on_complete)
    local obj
    if type == "artifact" then
        obj = Battle.Artifact.new()
    elseif type == "spell" then
        obj = Battle.Spell.new(user:get_team())
    elseif type == "obstacle" then
        obj = Battle.Obstacle.new(user:get_team())
    end
    obj:sprite():set_layer(layer)
    obj:set_texture(texture, false)
    if facing then obj:set_facing(facing) end
    if user:get_facing() == Direction.Left then x = -x end
    obj:set_offset(x, y)
    local anim = obj:get_animation()
    anim:load(animation)
    anim:set_state(state)
    anim:refresh(obj:sprite())
    if delete_on_complete then
        anim:on_complete(function() obj:delete() end)
    end
    return obj
end

crossman.card_create_action = function(user, props)
    local action = Battle.CardAction.new(user, "PLAYER_IDLE")
    local field = user:get_field()
    action:set_lockout(make_sequence_lockout())

    action.execute_func = function()
        local actor = action:get_actor()
        local facing = user:get_facing()
        local tile = user:get_current_tile()

        local offset = 0
        local speed = 10
        local current_tile = tile
        local kurosu = nil
        local boost_fx = nil

        -- Step 0: Spawn CrossMan Spell
        local spawn_step = Battle.Step.new()
        local do_once_spawn = true
        spawn_step.update_func = function()
            if do_once_spawn then
                do_once_spawn = false

                if props.time_freeze then actor:hide() end

                -- Spawn CrossMan as a spell
                    kurosu = graphic_init(
                        "spell",            -- type
                        0, 0,               -- x, y offset
                        CROSSMAN_TEXTURE,   -- texture
                        CROSSMAN_ANIMPATH,  -- animation
                        -5,                 -- layer (above boost)
                        "PLAYER_MOVE",      -- animation state
                        user,               -- parent object
                        facing,             -- facing
                        false               -- delete_on_complete
                    )

                local anim = kurosu:get_animation()
                anim:set_playback(Playback.Once)

                anim:on_frame(2, function()
                    Engine.play_audio(spawn_sfx, AudioPriority.Low)
                end)

                anim:on_complete(function()
                    spawn_step:complete_step()
                end)

                field:spawn(kurosu, tile)
            end
        end
        action:add_step(spawn_step)

        -- Step 1: Spawn boost artifact
        local boost_step = Battle.Step.new()
        local do_once_boost = true
        boost_step.update_func = function()
            if do_once_boost then
                do_once_boost = false

                kurosu:shake_camera(10, 0.25)

                kurosu:get_animation():set_state("PLAYER_THROW")

                boost_fx = graphic_init(
            "artifact",           -- type
            0, -33,               -- x, y offset relative to kurosu
            boost_texture,        -- texture
            boost_animation_path, -- animation
            -4,                   -- layer
            "DEFAULT",            -- animation state
            kurosu,               -- parent object (user)
            nil,                  -- facing (nil uses parent's facing)
            false                 -- delete_on_complete
        )

        Engine.play_audio(boost_sfx, AudioPriority.Low)

        -- Spawn on the field
        field:spawn(boost_fx, tile)

                Engine.play_audio(boost_sfx, AudioPriority.Low)

                boost_step:complete_step()
            end
        end
        action:add_step(boost_step)

        -- Dash spell setup (used for attacking)
        local dash_spell = Battle.Spell.new(user:get_team())
        dash_spell:set_facing(facing)
        dash_spell:set_hit_props(
            HitProps.new(
                props.damage,
                Hit.Impact | Hit.Flinch | Hit.Breaking | Hit.Flash,
                Element.None,
                actor:get_context(),
                Drag.new(facing, 1)
            )
        )
        dash_spell.collision_func = function(self, other)
            Engine.play_audio(damage_sfx, AudioPriority.Low)
            local hit_fx = Battle.Artifact.new()
            hit_fx:set_texture(spell_bullet_texture, true)
            hit_fx:get_animation():load(spell_bullet_animation)
            hit_fx:get_animation():set_state("DEFAULT")
            hit_fx:get_animation():refresh(hit_fx:sprite())
            hit_fx:get_animation():on_complete(function() hit_fx:erase() end)
            hit_fx:sprite():set_layer(-9)
            hit_fx:set_offset(math.random(-20,20), math.random(-10,10))
            field:spawn(hit_fx, other:get_current_tile())
        end
        field:spawn(dash_spell, current_tile)

        -- Step 2: Move CrossMan and boost
        local move_step = Battle.Step.new()
        move_step.update_func = function()
            if kurosu:is_deleted() then return end

            offset = offset + ((facing == Direction.Right) and speed or -speed)
            kurosu:set_offset(offset, 0)

            if boost_fx and not boost_fx:is_deleted() then
                local off_x, off_y = kurosu:get_offset().x, (kurosu:get_offset().y - 33)
                boost_fx:set_offset(off_x , off_y)
            end

            if current_tile then
                current_tile:attack_entities(dash_spell)
            end

            if math.abs(offset) % 80 == 0 then
                if current_tile:is_edge() or current_tile:x() == 7 then
                    move_step:complete_step()
                else
                    if current_tile:get_state() == TileState.Cracked then
                        current_tile:set_state(TileState.Broken)
                    end
                    current_tile = current_tile:get_tile(facing, 1)
                end
            end
        end
        action:add_step(move_step)

        -- Step 3: Safe deletion
        local delete_step = Battle.Step.new()
        delete_step.update_func = function()
            if kurosu and not kurosu:is_deleted() then kurosu:delete() end
            if boost_fx and not boost_fx:is_deleted() then boost_fx:delete() end
            if props.time_freeze then actor:reveal() end
            delete_step:complete_step()
            action:end_action()
        end
        action:add_step(delete_step)
    end

    return action
end

return crossman
