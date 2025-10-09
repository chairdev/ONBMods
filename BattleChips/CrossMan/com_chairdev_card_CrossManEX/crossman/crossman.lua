local DAMAGE = 150

-- Audio
local spawn_sfx = Engine.load_audio(_folderpath.."exe6-spawn.ogg")
local boost_sfx = Engine.load_audio(_folderpath.."boost.ogg")
local damage_sfx = Engine.load_audio(_folderpath.."hurt.ogg")
local input_sfx = Engine.load_audio(_folderpath.."input.ogg")

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

        function can_move_to(tile)
            if tile:is_edge() then
                return false
            end
            if(tile:is_reserved({}) or (not tile:is_walkable())) then
                return false
            end
            return true
        end

        local function find_nearest_enemy_tile(user)
            local targets = field:find_nearest_characters(user, function(c)
                return c:get_team() ~= user:get_team()
            end)

            if targets and targets[1] and targets[1]:get_current_tile() then
                return targets[1]:get_current_tile()
            end

            -- fallback to user's own tile to avoid nil errors
            return user:get_current_tile()
        end


       -- Step 0: Spawn CrossMan Spell (initial appear) with 30-frame wait after spawn
        local spawn_step = Battle.Step.new()
        local do_once_spawn = true
        local wait_frames_spawn = 20
        spawn_step.update_func = function()
            if do_once_spawn then
                do_once_spawn = false

                if props.time_freeze then actor:hide() end

                kurosu = graphic_init(
                    "spell",
                    0, 0,
                    CROSSMAN_TEXTURE,
                    CROSSMAN_ANIMPATH,
                    -5,
                    "PLAYER_MOVE",
                    user,
                    facing,
                    false
                )

                local anim = kurosu:get_animation()
                anim:set_playback(Playback.Once)

                anim:on_frame(2, function()
                    Engine.play_audio(spawn_sfx, AudioPriority.Low)
                end)

                anim:on_complete(function()
                    -- mark teleport as done and start wait countdown
                    wait_frames_spawn = 30
                end)

                field:spawn(kurosu, tile)
                return
            end

            -- wait after spawn
            if wait_frames_spawn > 0 then
                wait_frames_spawn = wait_frames_spawn - 1
                return
            else
                spawn_step:complete_step()
            end
        end
        action:add_step(spawn_step)

        -- Step 0.5: Teleport (spawn a new CrossMan at x=1 if player holds B) with 20-frame wait after teleport
        local teleport_step = Battle.Step.new()
        local teleport_done = false
        local wait_frames = 15
        local do_once_teleport = true

        teleport_step.update_func = function()
            local field = user:get_field()

            -- Step 1: perform teleport once
            if do_once_teleport then
                do_once_teleport = false

                -- check B input
                if not user:input_has(Input.Held.Shoot) then
                    teleport_step:complete_step()
                    return
                else
                    Engine.play_audio(input_sfx, AudioPriority.Low)
                end

                local target_tile = find_nearest_enemy_tile(user)
                if not target_tile then
                    teleport_step:complete_step()
                    return
                end

                local spawn_tile = field:tile_at(1, target_tile:y())
                if not spawn_tile or not can_move_to(spawn_tile) then
                    print("x=1 tile unavailable")
                    teleport_step:complete_step()
                    return
                end

                local new_kurosu = graphic_init(
                    "spell", 0, 0,
                    CROSSMAN_TEXTURE, CROSSMAN_ANIMPATH,
                    -5, "PLAYER_MOVE",
                    user, facing, false
                )

                local new_anim = new_kurosu:get_animation()
                new_anim:set_playback(Playback.Once)
                new_anim:on_frame(2, function()
                    Engine.play_audio(spawn_sfx, AudioPriority.Low)
                end)

                new_anim:on_complete(function()
                    if kurosu and not kurosu:is_deleted() then kurosu:delete() end
                    kurosu = new_kurosu
                    current_tile = spawn_tile
                    teleport_done = true  -- mark teleport complete
                end)

                field:spawn(new_kurosu, spawn_tile)
                return
            end

            -- Step 2: wait after teleport
            if teleport_done then
                if wait_frames > 0 then
                    wait_frames = wait_frames - 1
                    return
                else
                    teleport_step:complete_step()
                end
            end
        end
        action:add_step(teleport_step)


        -- Step 1: Spawn boost artifact
        local boost_step = Battle.Step.new()
        local do_once_boost = true
        boost_step.update_func = function()
            if do_once_boost then
                do_once_boost = false

                if kurosu and not kurosu:is_deleted() then
                    kurosu:shake_camera(10, 0.25)
                    kurosu:get_animation():set_state("PLAYER_THROW")
                end

                boost_fx = graphic_init(
                    "artifact",
                    0, -33,
                    boost_texture,
                    boost_animation_path,
                    -3,
                    "DEFAULT",
                    kurosu,
                    nil,
                    false
                )

                Engine.play_audio(boost_sfx, AudioPriority.Low)

                -- spawn boost on the (possibly teleported) current_tile
                field:spawn(boost_fx, current_tile)

                boost_step:complete_step()
            end
        end
        action:add_step(boost_step)

        -- Step 2: Create and spawn dash spell at runtime (so it uses updated current_tile)
        local dash_setup_step = Battle.Step.new()
        local do_once_dashsetup = true
        local dash_spell = nil
        dash_setup_step.update_func = function()
            if not do_once_dashsetup then return end
            do_once_dashsetup = false

            dash_spell = Battle.Spell.new(user:get_team())
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
           dash_spell.attack_func = function(self, other)
                Engine.play_audio(damage_sfx, AudioPriority.Low)

                -- use graphic_init to spawn a spell-based hit effect
                local hit_fx = graphic_init(
                    "spell",                 -- type
                    math.random(-20, 20),     -- x offset
                    math.random(-10, 10),     -- y offset
                    spell_bullet_texture,     -- texture
                    spell_bullet_animation,   -- animation
                    -2,                       -- layer
                    "DEFAULT",               -- animation state
                    self,                     -- user (the dash spell)
                    self:get_facing(),        -- facing
                    true                      -- delete on complete
                )
                dash_spell:shake_camera(10, 0.25)
                field:spawn(hit_fx, other:get_current_tile())
            end

            -- spawn dash spell at the (updated) current_tile
            field:spawn(dash_spell, current_tile)

            dash_setup_step:complete_step()
        end
        action:add_step(dash_setup_step)

        -- Step 3: Move CrossMan and boost (dash runtime)
        local move_step = Battle.Step.new()
        move_step.update_func = function()
            if not kurosu or kurosu:is_deleted() then return end
            if not dash_spell then return end

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

        -- Step 4: Safe deletion
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
