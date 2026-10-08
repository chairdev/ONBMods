local default_cs = include("chips/pulse_triad/vulcan.lua")

function add_null_chip_boost_component(player)
    local c = Battle.Component.new(player, Lifetimes.Scene)

    c.update_func = function()
        local handle = player:get_held_card_handle()
        if not handle then return end

        local props = handle:copy_modded_props()
        if not props.can_boost then return end

        if props.element ~= Element.None or props.dimming then
            if handle:has_mod(PropsMod.damage, "com.chairdev.PulseMan.NullBoost") then
                handle:drop_mod(PropsMod.damage, "com.chairdev.PulseMan.NullBoost")
            end
            return
        end

        if handle:has_mod(PropsMod.damage, "com.chairdev.PulseMan.NullBoost") then return end

        handle:write_mod(PropsMod.damage, "com.chairdev.PulseMan.NullBoost", 10)
    end

    player:register_component(c)
end

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

    add_null_chip_boost_component(player)

    player.normal_attack_func = function(player)
        return Battle.Buster.new(player, false, player:get_attack_level())
    end

    player.charged_attack_func = function(player)
        local props = Battle.CardProperties:new()
        props.damage = 15 + (player:get_attack_level() * 10)
        return default_cs.card_create_action(player, props)
    end
end
