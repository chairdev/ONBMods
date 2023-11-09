nonce = function() end
 
local DAMAGE = 25
local TEXTURE = Engine.load_texture(_modpath.."spell_tornado.png")
local BUSTER_TEXTURE = Engine.load_texture(_modpath.."buster_fan.png")
local AUDIO = Engine.load_audio(_modpath.."sfx.ogg")

local finished = false
 
function package_init(package)
    package:declare_package_id("com.chairdev.card.Funnel")
    package:set_icon_texture(Engine.load_texture(_modpath.."icon.png"))
    package:set_preview_texture(Engine.load_texture(_modpath.."preview.png"))
    package:set_codes({"*"})
 
    local props = package:get_card_props()
    props.shortname = "Funnel"
    props.damage = DAMAGE
    props.time_freeze = false
    props.element = Element.None
    props.secondary_element = Element.Wind
    props.description = "An 8-hit tornado 2 sq ahead"
end

function card_create_action(actor, props)
    print("in create_card_action()!")
    local action = Battle.CardAction.new(actor, "PLAYER_IDLE")
    action:set_lockout(make_sequence_lockout())


	action.execute_func = function(self, user)
		user:hide()
		user:toggle_hitbox(false) 

		local field = user:get_field()
    	local facing = user:get_facing()
		local currentRow = user:get_current_tile():y()
		finished = false
		
		local spell = nil
		if currentRow == 2 then 
			print("currentRow == 2")
			spell = create_attack(user, props, 0)
		else 
			print("currentRow ~= 2")
			spell = create_attack(user, props, 1)
		end
		field:spawn(spell, user:get_current_tile())

		local step1 = Battle.Step.new()
		step1.update_func = function(self, dt)
			if finished then
				print("finished")
				user:toggle_hitbox(true) 
				step1:complete_step()
			end
		end
		self:add_step(step1)
	end

	action.action_end_func = function(self)
		actor:reveal()
	end
    return action
end

function create_attack(user, props, move_type)
	local spell = Battle.Spell.new(Team.Other)
	spell:set_facing(user:get_facing())
	spell:highlight_tile(Highlight.Solid)
	spell:set_texture(TEXTURE, true)
	spell:sprite():set_layer(-1)
	local direction = user:get_facing()
    spell:set_hit_props(
        HitProps.new(
            props.damage,
            Hit.Impact | Hit.Flinch, 
            props.element,
            user:get_context(),
            Drag.None
        )
    )
	local do_once = true
	local endReached = 0
	spell.update_func = function(self, dt) 
		if do_once then
			print("in spell.update_func")
			local anim = spell:get_animation()
			anim:load(_modpath.."spell_tornado.animation")
			local spare_props = spell:copy_hit_props()
			local cur_tile = spell:get_current_tile()
			anim:set_state("DEFAULT")
			anim:refresh(spell:sprite())
			anim:set_playback(Playback.Loop)
			do_once = false
		end

		self:get_current_tile():attack_entities(self)

		local is_at = spell:get_tile(direction, 0)
		local is_sliding = spell:is_sliding()
		--If move type is 0, move back and forth on the current row 4 times
		--If move type is 1, circle the outer edge of the field once

		if not is_sliding  then
			if move_type == 0 then
				if is_at:x() == 1 then
					print("is_at:x() == 1")
					direction = Direction.Right
					endReached = endReached + 1
				elseif is_at:x() == 6 then
					print("is_at:x() == 6")
					direction = Direction.Left
					endReached = endReached + 1
				end
			elseif move_type == 1 then
				if is_at:x() == 1 and is_at:y() == 1 then
					print("is_at:x() == 1 and is_at:y() == 1")
					direction = Direction.Down
					endReached = endReached + 1
				elseif is_at:x() == 1 and is_at:y() == 3 then
					print("is_at:x() == 1 and is_at:y() == 3")
					direction = Direction.Right
					endReached = endReached + 1
				elseif is_at:x() == 6 and is_at:y() == 3 then
					print("is_at:x() == 6 and is_at:y() == 3")
					direction = Direction.Up
					endReached = endReached + 1
				elseif is_at:x() == 6 and is_at:y() == 1 then
					print("is_at:x() == 6 and is_at:y() == 1")
					direction = Direction.Left
					endReached = endReached + 1
				end
			end
			if endReached >= 4 and spell:get_tile() == user:get_tile() then
				spell:delete()
			else
				spell:slide(spell:get_tile(direction, 1), frames(4), frames(0), ActionOrder.Voluntary, nil)
			end
		end
    end
	spell.collision_func = function(self, other)
	end
    spell.attack_func = function(self, other) 
    end

    spell.delete_func = function(self)
		finished = true
		self:erase()
    end

    spell.can_move_to_func = function(tile)
        return true
    end

	Engine.play_audio(AUDIO, AudioPriority.High)
	return spell
end