local DAMAGE = 0

local TESTDOT_TEXTURE = Engine.load_texture(_folderpath.."testdot.png")
local TESTDOT_ANIMPATH = _folderpath.."testdot.animation"

local SUPERKITAKAZE_TEXTURE = Engine.load_texture(_folderpath.."superkitakaze.png")
local SUPERKITAKAZE_ANIMPATH = _folderpath.."superkitakaze.animation"
local SUPERKITAKAZE_AUDIO = Engine.load_audio(_folderpath.."EXE4_76.ogg")

local superkitakaze = {
    codes = {"E","M","T","*"},
    shortname = "NrthWind",
    damage = DAMAGE,
    time_freeze = true,
    element = Element.None,
    description = "NorthWind blows off barriers",
    long_description = "A tremendous north wind blows off barriers",
    can_boost = false,
    card_class = CardClass.Standard,
    limit = 4,
    mb = 33
}

superkitakaze.card_create_action = function(actor, props)
    print("in card_create_action()!")
    local action = Battle.CardAction.new(actor, "PLAYER_IDLE")
	local original_offset = actor:get_offset()
    action:set_lockout(make_sequence_lockout())
    action.execute_func = function(self, user)
		print("in custom card action execute_func()!")
		local actor = self:get_actor()
		local facing = user:get_facing()
		local field = user:get_field()
		local team = user:get_team()
		local self_tile = user:get_current_tile()

        local step1 = Battle.Step.new()

        self.spawner = nil
        self.tile    = self_tile

        local ref = self

        local do_once = true
        step1.update_func = function(self, dt)
            if do_once then
                do_once = false
                ref.spawner = Battle.Artifact.new()
                ref.spawner:set_facing(facing)
                local anim = ref.spawner:get_animation()
                anim:load(TESTDOT_ANIMPATH)
                anim:set_state("0")
                local offset1_x = nil
                local offset1_y = nil
                local kitakaze_tile = nil
                --1: 8 frames
                anim:on_frame(2, function() -- wind 1: 8 frames
	            	Engine.play_audio(SUPERKITAKAZE_AUDIO, AudioPriority.Low)
                    if facing == Direction.Right then
                        offset1_x = -16
                        kitakaze_tile = field:tile_at(1,2)
                    else
                        offset1_x = 16
                        kitakaze_tile = field:tile_at(6,2)
                    end
                    offset1_y = -8
                    spawn_kitakaze(user, props, team, facing, field, kitakaze_tile, offset1_x, offset1_y)
                end)
                anim:on_frame(3, function() -- wind 2: 8 frames
                    if facing == Direction.Right then
                        offset1_x = -10
                        kitakaze_tile = field:tile_at(1,1)
                    else
                        offset1_x = 10
                        kitakaze_tile = field:tile_at(6,1)
                    end
                    offset1_y = -100
                    spawn_kitakaze(user, props, team, facing, field, kitakaze_tile, offset1_x, offset1_y)
                end)
                anim:on_frame(4, function() -- 8 frames
                    if facing == Direction.Right then
                        offset1_x = -20
                        kitakaze_tile = field:tile_at(1,1)
                    else
                        offset1_x = 20
                        kitakaze_tile = field:tile_at(6,1)
                    end
                    offset1_y = -124
                    spawn_kitakaze(user, props, team, facing, field, kitakaze_tile, offset1_x, offset1_y)
                end)
                anim:on_frame(5, function() -- 9 frames
                    if facing == Direction.Right then
                        offset1_x = -40
                        kitakaze_tile = field:tile_at(1,1)
                    else
                        offset1_x = 40
                        kitakaze_tile = field:tile_at(6,1)
                    end
                    offset1_y = -172
                    spawn_kitakaze(user, props, team, facing, field, kitakaze_tile, offset1_x, offset1_y)
                end)
                anim:on_frame(6, function() -- 10-2 frames
                    if facing == Direction.Right then
                        offset1_x = -32
                        kitakaze_tile = field:tile_at(1,2)
                    else
                        offset1_x = 32
                        kitakaze_tile = field:tile_at(6,2)
                    end
                    offset1_y = -48
                    spawn_kitakaze(user, props, team, facing, field, kitakaze_tile, offset1_x, offset1_y)
                end)
                anim:on_frame(7, function() -- 5+2 frames
                    if facing == Direction.Right then
                        offset1_x = -40
                        kitakaze_tile = field:tile_at(1,1)
                    else
                        offset1_x = 40
                        kitakaze_tile = field:tile_at(6,1)
                    end
                    offset1_y = -206
                    spawn_kitakaze(user, props, team, facing, field, kitakaze_tile, offset1_x, offset1_y)
                end)
                anim:on_frame(8, function() -- 8 frames
                    if facing == Direction.Right then
                        offset1_x = -20
                        kitakaze_tile = field:tile_at(1,1)
                    else
                        offset1_x = 20
                        kitakaze_tile = field:tile_at(6,1)
                    end
                    offset1_y = -78
                    spawn_kitakaze(user, props, team, facing, field, kitakaze_tile, offset1_x, offset1_y)
                end)
                anim:on_frame(9, function() -- 8 frames
                    if facing == Direction.Right then
                        offset1_x = -34
                        kitakaze_tile = field:tile_at(1,1)
                    else
                        offset1_x = 34
                        kitakaze_tile = field:tile_at(6,1)
                    end
                    offset1_y = -74
                    spawn_kitakaze(user, props, team, facing, field, kitakaze_tile, offset1_x, offset1_y)
                end)
                anim:on_frame(10, function() -- 8 frames
                    if facing == Direction.Right then
                        offset1_x = -46
                        kitakaze_tile = field:tile_at(1,1)
                    else
                        offset1_x = 46
                        kitakaze_tile = field:tile_at(6,1)
                    end
                    offset1_y = -66
                    spawn_kitakaze(user, props, team, facing, field, kitakaze_tile, offset1_x, offset1_y)
                end)
                anim:on_frame(11, function() -- 8 frames
                    if facing == Direction.Right then
                        offset1_x = -22
                        kitakaze_tile = field:tile_at(1,1)
                    else
                        offset1_x = 22
                        kitakaze_tile = field:tile_at(6,1)
                    end
                    offset1_y = -48
                    spawn_kitakaze(user, props, team, facing, field, kitakaze_tile, offset1_x, offset1_y)
                end)
                anim:on_frame(12, function() -- 9 frames
                    if facing == Direction.Right then
                        offset1_x = -38
                        kitakaze_tile = field:tile_at(1,2)
                    else
                        offset1_x = 38
                        kitakaze_tile = field:tile_at(6,2)
                    end
                    offset1_y = -68
                    spawn_kitakaze(user, props, team, facing, field, kitakaze_tile, offset1_x, offset1_y)
                end)
                anim:on_frame(13, function() -- 3 frames
                    if facing == Direction.Right then
                        offset1_x = -38
                        kitakaze_tile = field:tile_at(1,3)
                    else
                        offset1_x = 38
                        kitakaze_tile = field:tile_at(6,3)
                    end
                    offset1_y = -50
                    spawn_kitakaze(user, props, team, facing, field, kitakaze_tile, offset1_x, offset1_y)
                end)
                anim:on_frame(14, function() -- remove barriers, 12 frames
                    for i = 1, 6, 1 do
                        for j = 1, 3, 1 do
                            local remove_tile = field:tile_at(i,j)
                            remove_barrier(user, props, team, facing, field, remove_tile)
                        end
                    end
                end)
		    	anim:on_complete(function()
		    		ref.spawner:erase()
                    step1:complete_step()
		    	end)
                field:spawn(ref.spawner, ref.tile)
            end
        end
        self:add_step(step1)

		actor:set_offset(original_offset.x, original_offset.y)
    end
    action.action_end_func = function(self, user)
		print("in custom card action action_end_func()!")
		actor:set_offset(original_offset.x, original_offset.y)
	end
	return action
end

--[[
function spawner_kitakaze(user, props, team, facing, field, tile)
    local spawner = Battle.Spell.new(team)
    spawner:set_facing(facing)
	--[[local spawner_sprite = spawner:sprite()
	spawner_sprite:set_texture(TESTDOT_TEXTURE, true)
	spawner_sprite:set_layer(3)
    local anim = spawner:get_animation()
    anim:load(TESTDOT_ANIMPATH)
    anim:set_state("1")
	--anim:refresh(spawner_sprite)
    anim:on_frame(2, function()
        spawn_meteor(user, props, team, facing, field, tile)
    end)
    
    
    field:spawn(spawner, tile)
    return spawner
end
]]

function spawn_kitakaze(user, props, team, facing, field, tile, offset1_x, offset1_y)
    local kitakaze = Battle.Artifact.new()
    kitakaze:set_facing(facing)
    kitakaze:set_offset(offset1_x, offset1_y)
    local sprite = kitakaze:sprite()
    sprite:set_texture(SUPERKITAKAZE_TEXTURE, true)
    sprite:set_layer(-9)
    local anim = kitakaze:get_animation()
	anim:load(SUPERKITAKAZE_ANIMPATH)
	anim:set_state("0")
	anim:refresh(sprite)

    kitakaze.update_func = function(self)
        anim:on_complete(function()
            if facing == Direction.Right then
                if self:get_offset().x < 1000 then
                    self:set_offset(self:get_offset().x + 48, self:get_offset().y + 20)
                else
                    self:delete()
                end
            else
                if self:get_offset().x > 1000 then
                    self:set_offset(self:get_offset().x - 48, self:get_offset().y + 20)
                else
                    self:delete()
                end
            end
        end)
    end

    field:spawn(kitakaze, tile)
	return kitakaze
end

function remove_barrier(user, props, team, facing, field, tile)
	local spell = Battle.Spell.new(team)
    spell:set_hit_props(
        HitProps.new(
            0, 
            Hit.None, 
            Element.Wind, 
            user:get_id(), 
            Drag.None
        )
    )
    spell:set_facing(facing)
    --[[local sprite = spell:sprite()
    sprite:set_texture(TESTDOT_TEXTURE)
    sprite:set_layer(-9)]]
    local animation = spell:get_animation()
    animation:load(TESTDOT_ANIMPATH)
    animation:set_state("1")
    --animation:refresh(sprite)
    animation:on_complete(function() 
        spell:delete()
    end)
    spell.update_func = function(self)
        self:get_current_tile():attack_entities(self)
    end
    spell.attack_func = function(self, ent)
        --
    end
    spell.delete_func = function(self)
        self:erase()
    end
    field:spawn(spell, tile)
    return spell
end

return superkitakaze