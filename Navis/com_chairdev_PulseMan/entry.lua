local default_cs = include("chips/pulse_triad/vulcan.lua")

function package_init(package)
    package:declare_package_id("com.chairdev.PulseMan")
	package:set_attack(1)
	package:set_charged_attack(10)
    package:set_special_description("Hey guy, let's play again!")
	package:set_preview_texture(Engine.load_texture(_modpath.."preview.png"))
    package:set_overworld_animation_path(_modpath.."overworld.animation")
    package:set_overworld_texture_path(_modpath.."overworld.png")
    package:set_mugshot_animation_path(_modpath.."mug.animation")
	package:set_mugshot_texture_path(_modpath.."mug.png")
	--package:set_emotions_texture_path(_modpath.."emotions.png")
end

function player_init(player)
    player:set_name("PulseMan")
    player:set_health(1000)
    player:set_element(Element.None)
    player:set_height(48.0)
	player:set_charge_position(4,-20)

    local base_texture = Engine.load_texture(_modpath.."battle.png")
    local base_animation_path = _modpath.."battle.animation"

    player:set_animation(base_animation_path)
    player:set_texture(base_texture, true)

    player.normal_attack_func = function(player)
        return Battle.Buster.new(player, false, player:get_attack_level())
    end

    player.charged_attack_func = function(player)
        local props = Battle.CardProperties:new()
        props.damage = 15 + (player:get_attack_level() * 10)
        return default_cs.card_create_action(player, props)
    end
end
