bambooSword = {}

local DAMAGE = 150
local SLASH_TEXTURE = Engine.load_texture(_folderpath.."spell_sword_slashes.png")
local BLADE_TEXTURE = Engine.load_texture(_folderpath.."spell_sword_blades.png")
local AUDIO = Engine.load_audio(_folderpath.."sfx.ogg")

function package_init(package) 
    package:declare_package_id("com.chair.BambooSword")
    package:set_icon_texture(Engine.load_texture(_folderpath.."icon.png"))
    package:set_preview_texture(Engine.load_texture(_folderpath.."preview.png"))
	package:set_codes({"H";'S', 'W'})

    local props = package:get_card_props()
    props.shortname = "BambSwrd"
    props.damage = DAMAGE
    props.time_freeze = false
    props.element = Element.Wood,Element.Sword
    props.description = "Cut enmy 3sq fwrd w/wood"
end

function bambooSword.card_create_action(actor, props)
    print("in create_card_action()!")
    local action = Battle.CardAction.new(actor, "PLAYER_SWORD")
	action:set_lockout(make_animation_lockout())
    action.execute_func = function(self, user)
		self:add_anim_action(2,
			function()
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
			end
		)

		self:add_anim_action(3,
			function()
				local sword = create_slash(user, props)
				local tile = user:get_tile(user:get_facing(), 1)
				local sharebox1 = Battle.SharedHitbox.new(sword, 0.15)
				sharebox1:set_hit_props(sword:copy_hit_props())
				local sharebox2 = Battle.SharedHitbox.new(sword, 0.15)
				sharebox2:set_hit_props(sword:copy_hit_props())
				actor:get_field():spawn(sharebox1, tile:get_tile(Direction.Up, 1))
				actor:get_field():spawn(sword, tile)
				actor:get_field():spawn(sharebox2, tile:get_tile(Direction.Down, 1))
				local fx = Battle.Artifact.new()
				fx:set_facing(sword:get_facing())
				local anim = fx:get_animation()
				fx:set_texture(SLASH_TEXTURE, true)
				anim:load(_folderpath.."spell_sword_slashes.animation")
				anim:set_state("WIDE")
				anim:on_complete(
					function()
						fx:erase()
						sword:erase()
					end
				)
				actor:get_field():spawn(fx, tile)
			end
		)
	end
    return action
end

function create_slash(user, props)
	local spell = Battle.Spell.new(user:get_team())
	spell:set_facing(user:get_facing())
	spell:highlight_tile(Highlight.Flash)
	spell:set_hit_props(
		HitProps.new(
			props.damage,
			Hit.Impact | Hit.Flinch,
			Element.Sword | Element.Wood,
			user:get_context(),
			Drag.None
		)
	)
	spell.update_func = function(self, dt)
		if not self:get_tile():get_tile(Direction.Up, 1):is_edge() then
			self:get_tile():get_tile(Direction.Up, 1):highlight(Highlight.Flash)
		end
		if not self:get_tile():get_tile(Direction.Down, 1):is_edge() then
			self:get_tile():get_tile(Direction.Down, 1):highlight(Highlight.Flash)
		end
		self:get_tile():attack_entities(self)
	end

	spell.can_move_to_func = function(tile)
		return true
	end

	Engine.play_audio(AUDIO, AudioPriority.Low)

	return spell
end
return bambooSword