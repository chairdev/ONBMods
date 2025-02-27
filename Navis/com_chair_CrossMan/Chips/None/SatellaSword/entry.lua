local satella_sword = {}

local TARGET_TEXTURE = Engine.load_texture(_folderpath.."target.png")
local TARGET_ANIMATION_PATH = _folderpath.."target.animation"

local RETICLE_SFX = Engine.load_audio(_folderpath.."reticle_beep.wav")
local RETICLE_LOOP = Engine.load_audio(_folderpath.."reticle_loop.wav")

local TELEPORT_SFX = Engine.load_audio(_folderpath.."teleport.wav")


function package_init(package) 
    package:declare_package_id("com.chair.card.SataSwrd")
    package:set_icon_texture(Engine.load_texture(_folderpath.."icon.png"))
    package:set_preview_texture(Engine.load_texture(_folderpath.."preview.png"))
	package:set_codes({'B', 'L', 'P'})

    local props = package:get_card_props()
    props.shortname = "StepSwrd"
    props.damage = 160
    props.time_freeze = false
    props.element = Element.Sword
    props.description = "Use WideSwrd 2sq ahead"
	props.limit = 4
end

function satella_sword.card_create_action(actor, props)

	local field = actor:get_field() -- example  

		-- first method 
	local blue_team_filter = function( character ) 
		return character:get_team() == Team.Blue 
	end 
		-- second method 
	local all_blue_characters = field:find_nearest_characters(actor, blue_team_filter )  

	local reticle = nil
	
	local alt_action = Battle.CardAction.new(actor, "PLAYER_IDLE")	
	--Override the alternate idle action to be very fast so the user can keep playing on a failed chip use.
	alt_action:override_animation_frames(make_frame_data({{1, 0.001}}))
	local original_tile = actor:get_tile()
	local desired_tile = actor:get_tile(actor:get_facing(), 2)
	if #all_blue_characters ~= 0 then
		desired_tile = all_blue_characters[1]:get_tile(all_blue_characters[1]:get_facing(), 1)
	end
	local original_team = actor:get_team()
	local temp_super_armor = Battle.DefenseRule.new(27935,DefenseOrder.CollisionOnly)
    temp_super_armor.filter_statuses_func = function(statuses)
        statuses.flags = statuses.flags & ~Hit.Flinch
        return statuses
    end

	local entity_check = function(e)
		if e:get_health() <= 0 then return false end
		return Battle.Obstacle.from(e) ~= nil or Battle.Character.from(e) ~= nil or Battle.Player.from(e) ~= nil
	end
	if desired_tile and not desired_tile:is_edge() and desired_tile:is_walkable() then
		alt_action.execute_func = function(self, user)
			if desired_tile and not desired_tile:is_edge() and desired_tile:is_walkable() then
				--actor:add_defense_rule(temp_super_armor)
				desired_tile:reserve_entity_by_id(user:get_id())
				user:set_team(Team.Other)
				if #all_blue_characters ~= 0 then
					reticle = create_reticle(actor, all_blue_characters[1])
				end
			end
		end
		alt_action.animation_end_func = function(self)
				actor:teleport(desired_tile, ActionOrder.Immediate, function()
				Engine.play_audio(TELEPORT_SFX, AudioPriority.Low)
				local action = Battle.CardAction.new(actor, "PLAYER_SWORD")
				action:set_lockout(make_animation_lockout())
				local SLASH_TEXTURE = Engine.load_texture(_folderpath.."spell_sword_slashes.png")
				local BLADE_TEXTURE = Engine.load_texture(_folderpath.."spell_sword_blades.png")
				action.action_end_func = function(self)
					--actor:remove_defense_rule(temp_super_armor)
					actor:teleport(original_tile, ActionOrder.Involuntary, nil)
				end
				action.execute_func = function(self, user)
					actor:set_team(original_team)
					self:add_anim_action(2, function()
						local hilt = self:add_attachment("HILT")
						local hilt_sprite = hilt:sprite()
						hilt_sprite:set_texture(actor:get_texture())
						hilt_sprite:set_layer(-2)
						hilt_sprite:enable_parent_shader(true)
						
						local hilt_anim = hilt:get_animation()
						hilt_anim:copy_from(actor:get_animation())
						hilt_anim:set_state("HILT")

						local blade = hilt:add_attachment("ENDPOINT")
						local blade_sprite = blade:sprite()
						blade_sprite:set_texture(BLADE_TEXTURE)
						blade_sprite:set_layer(-1)

						local blade_anim = blade:get_animation()
						blade_anim:load(_folderpath.."spell_sword_blades.animation")
						blade_anim:set_state("DEFAULT")
					end)
					
					local field = user:get_field()
					self:add_anim_action(3, function()
						local sword = create_slash(user, props, get_weakness(all_blue_characters[1]:get_element()))
						local tile = user:get_tile(user:get_facing(), 1)
						local fx = Battle.Artifact.new()
						fx:set_facing(sword:get_facing())
						local anim = fx:get_animation()
						fx:set_texture(SLASH_TEXTURE, true)
						anim:load(_folderpath.."spell_sword_slashes.animation")
						anim:set_state("WIDE")
						anim:on_complete(function()
							fx:erase()
							if reticle ~= nil then
								reticle:erase()
							end
							if not sword:is_deleted() then sword:delete() end
						end)
						field:spawn(sword, tile)
						field:spawn(fx, tile)
					end)
				end
				actor:card_action_event(action, ActionOrder.Immediate)
			end)
		end
	end
	return alt_action
end

function get_weakness(element)
	--fire is strong against wood
	--wood is strong against elec
	--elec is strong against water
	--water is strong against fire
	if element == Element.Fire then
		return Element.Wood
	elseif element == Element.Wood then
		return Element.Elec
	elseif element == Element.Elec then
		return Element.Aqua
	elseif element == Element.Aqua then
		return Element.Fire
	else
		return Element.None
	end
end

--create the reticle on tile using spell
function create_reticle(actor, enemy)
	local field = actor:get_field()
  	local team = actor:get_team()
	local spell = Battle.Spell.new(team)

	spell:set_texture(TARGET_TEXTURE, true)
	spell:sprite():set_layer(-1)
	local anim = spell:get_animation()
	anim:load(TARGET_ANIMATION_PATH)
	anim:set_state("DEFAULT")
	anim:refresh(spell:sprite())

	field:spawn(spell, enemy:get_current_tile():x(), enemy:get_current_tile():y())

	spell.on_spawn_func = function(self)
		Engine.play_audio(RETICLE_SFX, AudioPriority.Low)
	end

	local delay = 20
	local cycle = 0

	spell.update_func = function(self, dt)
		if enemy ~= nil then
			local tile = enemy:get_current_tile()
			if tile ~= nil then
				spell:teleport(tile, ActionOrder.Immediate, nil)
			end

			if delay > 0 then
				delay = delay - 1
			else
				Engine.play_audio(RETICLE_LOOP, AudioPriority.Low)
				delay = 35
				cycle = cycle + 1
			end

			if cycle > 3 then
				spell:erase()
			end

		end
	end

	return spell
end

function create_slash(user, props, element)
	local spell = Battle.Spell.new(user:get_team())
	spell:set_facing(user:get_facing())
	spell:highlight_tile(Highlight.Flash)
	spell:set_hit_props(
		HitProps.new(
			props.damage,
			Hit.Impact | Hit.Flinch | Hit.Flash | Hit.Breaking,
			element,
			user:get_context(),
			Drag.None
		)
	)
	local attack_once = true
	local field = user:get_field()
    spell.update_func = function(self, dt) 
		local tile = spell:get_current_tile()
		local tile_next = tile:get_tile(Direction.Up, 1)
		local tile_next_two = tile:get_tile(Direction.Down, 1)
		if tile_next and not tile_next:is_edge() then
			tile_next:highlight(Highlight.Flash)
		end
		if tile_next_two and not tile_next_two:is_edge() then
			tile_next_two:highlight(Highlight.Flash)
		end
		if attack_once then
			if tile_next and not tile_next:is_edge() then
				local hitbox_r = Battle.SharedHitbox.new(self, 0.2)
				hitbox_r:set_hit_props(self:copy_hit_props())
				field:spawn(hitbox_r, tile_next)
			end
			if tile_next_two and not tile_next_two:is_edge() then
				local hitbox_l = Battle.SharedHitbox.new(self, 0.2)
				hitbox_l:set_hit_props(self:copy_hit_props())
				field:spawn(hitbox_l, tile_next_two)
			end
			attack_once = false
		end
		tile:attack_entities(self)
	end

	spell.can_move_to_func = function(tile)
		return true
	end
	local AUDIO = Engine.load_audio(_folderpath.."sfx.ogg")
	Engine.play_audio(AUDIO, AudioPriority.Low)

	return spell
end
return satella_sword