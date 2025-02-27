local elecbomb = {}
function package_init(package) 
    package:declare_package_id("com.chair.ElecBomb")
    package:set_icon_texture(Engine.load_texture(_folderpath.."icon.png"))
    package:set_preview_texture(Engine.load_texture(_folderpath.."preview.png"))
	package:set_codes({'C','P','R',})

    local props = package:get_card_props()
    props.shortname = "ElecBomb"
    props.damage = 80
    props.time_freeze = false
    props.element = Element.Elec
    props.description = "Sprd dmg + shape."
    props.limit = 3
end


local attachment_texture = Engine.load_texture(_folderpath .. "attachment.png")
local attachment_animation_path = _folderpath .. "attachment.animation"
local explosion_texture = Engine.load_texture(_folderpath .. "explosion.png")
local explosion_sfx = Engine.load_audio(_folderpath .. "explosion.ogg")
local explosion_animation_path = _folderpath .. "explosion.animation"
local throw_sfx = Engine.load_audio(_folderpath .. "toss_item.ogg")


function elecbomb.card_create_action(user, props)
    local action = Battle.CardAction.new(user, "PLAYER_THROW")
    action:set_lockout(make_animation_lockout())
    local override_frames = {
        {1, 0.05}, {2, 0.05}, {3, 0.05}, {3, 0.05}, {5, 0.05}
    }
    local frame_data = make_frame_data(override_frames)
    action:override_animation_frames(frame_data)

    local hit_props
    local first_explosion = true

    action.execute_func = function(self, user)
        hit_props = HitProps.new(props.damage,
                                   Hit.Impact | Hit.Flinch,
                                   props.element, user:get_context(), Drag.None)
        -- local props = self:copy_metadata()
        local attachment = self:add_attachment("HAND")
        local attachment_sprite = attachment:sprite()
        attachment_sprite:set_texture(attachment_texture)
        attachment_sprite:set_layer(-2)
        -- attachment_sprite:enable_parent_shader(true)

        local attachment_animation = attachment:get_animation()
        attachment_animation:load(attachment_animation_path)
        attachment_animation:set_state("DEFAULT")

        self:add_anim_action(3, function()
            attachment_sprite:hide()
            -- self.remove_attachment(attachment)
            local tiles_ahead = 3
            local frames_in_air = 40
            local toss_height = 140
            local facing = user:get_facing()
            local target_tile = user:get_tile(facing, tiles_ahead)
            local first_landing = true

            if not target_tile then return end
            local tiles = {
                target_tile,
                target_tile:get_tile(Direction.Right, 1),
                target_tile:get_tile(Direction.Down, 1),
                target_tile:get_tile(Direction.Left, 1),
                target_tile:get_tile(Direction.Up, 1)
            }
            action.on_landing = function()
                if not target_tile:is_walkable() or target_tile:is_edge() then return end
                if first_explosion then 
                        Engine.play_audio(explosion_sfx, AudioPriority.Low)
                        first_explosion = false
                end

                hit_explosion(user, target_tile, hit_props, explosion_texture, explosion_animation_path, tiles)


            end
            toss_spell(user, toss_height, attachment_texture,
            attachment_animation_path, target_tile, frames_in_air,
            action.on_landing)

        end)

        self:add_anim_action(2, function()
            Engine.play_audio(throw_sfx, AudioPriority.Low)
        end)
    end

    return action
end




function toss_spell(tosser, toss_height, texture, animation_path, target_tile, frames_in_air, arrival_callback)
    local starting_height = -110
    local start_tile = tosser:get_current_tile()
    local field = tosser:get_field()
    local spell = Battle.Spell.new(tosser:get_team())
    spell:set_facing(tosser:get_facing())
    local spell_animation = spell:get_animation()
    spell_animation:load(animation_path)
    spell_animation:set_state("DEFAULT")
    if tosser:get_height() > 1 then
        starting_height = -(tosser:get_height() + 40)
    end


    spell.jump_started = false
    spell.starting_y_offset = starting_height
    spell.starting_x_offset = 10
    if tosser:get_facing() == Direction.Left then
        spell.starting_x_offset = -10
    end

    spell.y_offset = spell.starting_y_offset
    spell.x_offset = spell.starting_x_offset
    local sprite = spell:sprite()
    sprite:set_texture(texture)
    spell:set_offset(spell.x_offset, spell.y_offset)

    spell.update_func = function(self)
        if not spell.jump_started then
            self:jump(target_tile, toss_height, frames(frames_in_air),
                      frames(frames_in_air), ActionOrder.Voluntary)
            self.jump_started = true
        end
        if self.y_offset < 0 then
            self.y_offset = self.y_offset +
                                math.abs(self.starting_y_offset / frames_in_air)
            self.x_offset = self.x_offset -
                                math.abs(self.starting_x_offset / frames_in_air)
            self:set_offset(self.x_offset, self.y_offset)
        else
            arrival_callback()
            self:delete()
            self:hide()
        end
    end
    spell.can_move_to_func = function(tile) return true end
    field:spawn(spell, start_tile)
end


function hit_explosion(user, target_tile, props, texture, anim_path, target_tiles)
    local field = user:get_field()
    local spell = Battle.Spell.new(user:get_team())


    spell:set_hit_props(props)
    spell.has_attacked = false
    local lifetime = 3
    spell.update_func = function(self)
        for i=1, #target_tiles
        do
            local target = target_tiles[i]
            if target and not target:is_edge() then 
            target_tiles[i]:attack_entities(self)
            end
        end

        lifetime = lifetime - 1
        if lifetime == 0 then 
            self:delete()
        end
    end

    
    local artifact = Battle.Artifact.new()
    local anim = artifact:get_animation()
    artifact:set_texture(texture)
    anim:load(anim_path)
    anim:set_state("DEFAULT")
    anim:refresh(artifact:sprite())

  
    anim:on_complete(function()
        artifact:delete()
    end)


    for i=2, #target_tiles
    do
        local target = target_tiles[i]
        if target and not target:is_edge() then 
            local new_artifact = Battle.Artifact.new()
            local new_anim = new_artifact:get_animation()
            new_artifact:set_texture(texture)
            new_anim:copy_from(anim)
            new_anim:set_state("DEFAULT")
            new_anim:refresh(new_artifact:sprite())
                    
            new_anim:on_complete(function()
                new_artifact:delete()
            end)

            field:spawn(new_artifact, target)
        end
    end

    field:spawn(spell, target_tile)
    field:spawn(artifact, target_tile)

end
return elecbomb