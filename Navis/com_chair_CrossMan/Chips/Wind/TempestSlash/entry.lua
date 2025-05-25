local DAMAGE = 80

local AUDIO_DAMAGE = Engine.load_audio(_folderpath.."EXE4_270.ogg")
local AUDIO_DAMAGE_OBS = Engine.load_audio(_folderpath.."EXE4_221.ogg")
local EFFECT_TEXTURE = Engine.load_texture(_folderpath.."effect.png")
local EFFECT_ANIMPATH = _folderpath.."effect.animation"

local SLASH_TEXTURE = Engine.load_texture(_folderpath.."spell_sword_slashes.png")
local SLASH_ANIMPATH = _folderpath.."spell_sword_slashes.animation"
local AUDIO = Engine.load_audio(_folderpath.."EXE4_13.ogg")

local BLADE_TEXTURE = Engine.load_texture(_folderpath.."spell_sword_blades.png")
local BLADE_ANIMPATH = _folderpath.."spell_sword_blades.animation"

local SONICBOOM_AUDIO = Engine.load_audio(_folderpath.."sonicboom.ogg")

local tempest_slash = {
	palette = 10,

	codes = {"S"},
	shortname = "SoncBoom",
	damage = DAMAGE,
	time_freeze = false,
	element = Element.Wind,
	description = "Release SonicBoom of 3 sq!",
	long_description = "Swing the sword and release a shockwave of 3 vertical squares!",
	can_boost = true,
	card_class = CardClass.Mega,
	limit = 1,
	mb = 51
}

tempest_slash.card_create_action = function(actor, props)
    print("in create_card_action()!")
    local action = Battle.CardAction.new(actor, "PLAYER_SWORD")
	local frame1 = {1, 0.167}
	local frame2_1 = {2, 0.017}
	local frame2_2 = {2, 0.017}
	local frame3 = {3, 0.033}
	local frame4 = {4, 0.033}
	local frame5 = {4, 0.117}
	local frame_sequence = make_frame_data({frame1, frame2_1, frame2_2, frame3, frame4, frame4, frame4, frame4, frame4, frame5})
	local original_offset = actor:get_offset()
	action:override_animation_frames(frame_sequence)
	action:set_lockout(make_animation_lockout())
    action.execute_func = function(self, user)
        print("in custom card action execute_func()!")
		local facing = user:get_facing()
		local field = user:get_field()
		local team = user:get_team()
		self:add_anim_action(1, function()
			actor:set_offset(original_offset.x, original_offset.y)
			Engine.play_audio(AUDIO, AudioPriority.Low)
			Engine.play_audio(SONICBOOM_AUDIO, AudioPriority.Low)
		end)
		self:add_anim_action(2, function()
			local hilt = self:add_attachment("HILT")
			local hilt_sprite = hilt:sprite()
			hilt_sprite:set_texture(actor:get_texture())
			hilt_sprite:set_layer(-1)
			hilt_sprite:enable_parent_shader(true)
			local hilt_anim = hilt:get_animation()
			hilt_anim:copy_from(actor:get_animation())
			hilt_anim:set_state("HILT")
			local blade = hilt:add_attachment("ENDPOINT")
			local blade_sprite = blade:sprite()
			blade_sprite:set_texture(BLADE_TEXTURE)
			blade_sprite:set_layer(-2)
			local blade_anim = blade:get_animation()
			blade_anim:load(BLADE_ANIMPATH)
			blade_anim:set_state("0")
		end)
		self:add_anim_action(3,function()
			local tile = user:get_tile(facing, 1)
			create_slash(user, props, team, facing, field, tile)
			create_slash(user, props, team, facing, field, tile:get_tile(Direction.Up, 1))
			create_slash(user, props, team, facing, field, tile:get_tile(Direction.Down, 1))
			local slash = create_effect(facing, SLASH_TEXTURE, SLASH_ANIMPATH, "WIDE", 0, 0, false, -3, field, tile)
			slash:set_palette(Engine.load_texture(_folderpath..tempest_slash.palette..".palette.png"))
			slash.slide_started = false
			slash:get_animation():set_playback_speed(0)
			slash.update_func = function(self)
				if self:is_sliding() == false then
					if self:get_current_tile():is_edge() and self.slide_started then 
						self:delete()
					end 
		
					local dest = self:get_tile(facing, 1)
					local ref = self
					self:slide(dest, frames(3), frames(0), ActionOrder.Voluntary, function()
						ref.slide_started = true 
					end)
				end
			end
			slash.battle_end_func = function(self)
				self:delete()
			end
			slash.can_move_to_func = function(tile)
				return true
			end
			slash.delete_func = function(self)
				self:erase()
			end
		end)
	end
	action.action_end_func = function(self)
		actor:set_offset(original_offset.x, original_offset.y)
	end
    return action
end

function create_slash(user, props, team, facing, field, tile)
	local spell = Battle.Spell.new(team)
	spell:set_facing(facing)
	spell:set_hit_props(
		HitProps.new(
			props.damage,
			Hit.Impact | Hit.Flinch | Hit.Flash | Hit.Drag,
			props.element,
			user:get_id(),
			Drag.new(user:get_facing(), 1)
		)
	)
	spell.slide_started = false
	--[[local sprite = spell:sprite()
    sprite:set_texture(Engine.load_texture(_folderpath.."testdot.png"), true)
	sprite:set_layer(-3)]]
    local anim = spell:get_animation()
	anim:load(_folderpath.."testdot.animation")
	anim:set_state("0")

	spell.update_func = function(self) 
		self:get_current_tile():attack_entities(self)
		if self:is_sliding() == false then
			if self:get_current_tile():is_edge() and self.slide_started then 
				self:delete()
			end 

			local dest = self:get_tile(facing, 1)
			local ref = self
			self:slide(dest, frames(3), frames(0), ActionOrder.Voluntary, function()
				ref.slide_started = true 
			end)
		end
	end

	spell.attack_func = function(self, ent)
		if Battle.Obstacle.from(ent) == nil then
			if Battle.Player.from(user) ~= nil then
				Engine.play_audio(AUDIO_DAMAGE, AudioPriority.Low)
			end
		else
			Engine.play_audio(AUDIO_DAMAGE_OBS, AudioPriority.Low)
		end
	end

	spell.battle_end_func = function(self)
		self:delete()
    end

	spell.can_move_to_func = function(tile)
		return true
	end

	spell.delete_func = function(self)
		self:erase()
    end

	field:spawn(spell, tile)

	return spell
end

function create_effect(effect_facing, effect_texture, effect_animpath, effect_state, offset_x, offset_y, flip, offset_layer, field, tile)
    local hitfx = Battle.Artifact.new()
    hitfx:set_facing(effect_facing)
    hitfx:set_texture(effect_texture, true)
    hitfx:set_offset(offset_x, offset_y)
    hitfx:never_flip(flip)
    local hitfx_sprite = hitfx:sprite()
    hitfx_sprite:set_layer(offset_layer)
    local hitfx_anim = hitfx:get_animation()
	hitfx_anim:load(effect_animpath)
	hitfx_anim:set_state(effect_state)
	hitfx_anim:refresh(hitfx_sprite)
    hitfx_anim:on_complete(function()
        hitfx:erase()
    end)
    field:spawn(hitfx, tile)

    return hitfx
end

return tempest_slash