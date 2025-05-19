local sonic_rush = {}

-- Load resources
local boost_sfx = Engine.load_audio(_folderpath.."boost.ogg")
local damage_sfx = Engine.load_audio(_folderpath.."hurt.ogg")

local boost_texture = Engine.load_texture(_folderpath.."boost.png")
local boost_animation_path = _folderpath.."boost.animation"
local spell_bullet_texture = Engine.load_texture(_folderpath.."spell_bullet_hit.png")
local spell_bullet_animation = _folderpath.."spell_bullet_hit.animation"

-- Constants
local originalOffset = 0
local speed = 20

function sonic_rush.card_create_action(actor, props)
    local action = Battle.CardAction.new(actor, "PLAYER_HIT")

    -- Set lockout animation
    action:set_lockout(make_animation_lockout())

    -- Define frame data for animations
    local FRAMEDATA_ELEMENT = {1, 0.017}
    local FRAMEDATA_ELEMENT2 = {2, 0.017}
    local FRAMEDATA_ELEMENT3 = {3, 4}
    local FRAMES = make_frame_data({FRAMEDATA_ELEMENT, FRAMEDATA_ELEMENT2, FRAMEDATA_ELEMENT3})
    action:override_animation_frames(FRAMES)

    actor:shake_camera(10, 0.25)

    -- Define the execution function
    action.execute_func = function(self, actor)
        local boost_anim = nil

        -- Animation action 1: Initialize boost attachment
        self:add_anim_action(1, function()
            local boost = self:add_attachment("Head")
            local boost_sprite = boost:sprite()
            boost_sprite:set_texture(boost_texture)
            boost_sprite:set_layer(1)
            Engine.play_audio(boost_sfx, AudioPriority.Low)

            boost_anim = boost:get_animation()
            boost_anim:load(boost_animation_path)
            boost_anim:set_state("DEFAULT")
        end)

        -- Animation action 2: Execute dash logic
        self:add_anim_action(2, function()
            --boost_anim:set_state("COMPLETE")

            -- Create and configure the highlight spell
            local highlightSpell = Battle.Spell.new(actor:get_team())
            highlightSpell:set_hit_props(
                HitProps.new(
                    props.damage,
                    Hit.Impact | Hit.Flinch | Hit.Flash | Hit.Breaking | Hit.Drag | Hit.Shake,
                    Element.None,
                    actor:get_context(),
                    Drag.new(actor:get_facing(), 1)
                )
            )
            highlightSpell.offset = 0
            highlightSpell.speed = (actor:get_facing() == Direction.Right) and speed or -speed

            -- Spawn the spell and disable actor hitbox
            local current_tile = actor:get_tile()
            actor:get_field():spawn(highlightSpell, current_tile)
            actor:toggle_hitbox(false)

            highlightSpell.collision_func = function(self, other)
                Engine.play_audio(damage_sfx, AudioPriority.Low)

                -- Create the hit effect
                local hitfx = Battle.Artifact.new()
                hitfx:teleport(other:get_current_tile(), ActionOrder.Immediate, nil)
                hitfx:set_texture(spell_bullet_texture, true)
                hitfx:get_animation():load(spell_bullet_animation)
                hitfx:set_offset(math.random(-30, 30), math.random(-30, 30))
                hitfx:set_facing(Direction.Right)
                hitfx:sprite():set_layer(-9)
                hitfx:get_animation():set_state("0")
                hitfx:get_animation():refresh(hitfx:sprite())
                hitfx:get_animation():on_complete(function()
                    hitfx:erase()
                end)
                self:get_field():spawn(hitfx, self:get_current_tile())
            end

            -- Define the update function for the spell
            highlightSpell.update_func = function()
                highlightSpell.offset = highlightSpell.offset + highlightSpell.speed
                actor:set_offset(highlightSpell.offset, 0)

                -- Handle tile interactions every 80 units
                if highlightSpell.offset % 80 == 0 then
                    if not current_tile:is_edge() then
                        -- Break cracked panels
                        if current_tile:get_state() == TileState.Cracked then
                            current_tile:set_state(TileState.Broken)
                        end
                        current_tile = current_tile:get_tile(actor:get_facing(), 1)
                    else
                        -- End action if at the edge
                        actor:set_offset(0, 0)
                        highlightSpell:erase()
                        actor:toggle_hitbox(true)
                        action:end_action()
                    end
                end

                -- Attack entities on the current tile
                if current_tile then
                    current_tile:attack_entities(highlightSpell)
                end
            end
        end)
    end

    return action
end

return sonic_rush