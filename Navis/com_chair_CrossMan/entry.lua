function package_init(package)
    package:declare_package_id("com.chair.CrossMan")
    package:set_special_description("CrossMan.ExE with CrossLink!")
    package:set_speed(2.0)
    package:set_attack(1)
    package:set_charged_attack(10)
    package:set_icon_texture(Engine.load_texture(_folderpath.."icon.png"))
    package:set_preview_texture(Engine.load_texture(_folderpath.."preview.png"))
    package:set_overworld_animation_path(_folderpath.."overworld.animation")
    package:set_overworld_texture_path(_folderpath.."overworld.png")
    package:set_mugshot_texture_path(_folderpath.."mug.png")
    package:set_mugshot_animation_path(_folderpath.."mug.animation")
    package:set_emotions_texture_path(_folderpath.."emotions.png")
end

function player_init(player)
    player:set_name("CrossMan")
    player:set_health(1100)
    player:set_element(Element.None)
    player:set_height(48.0)

    local base_texture = Engine.load_texture(_folderpath.."battle.png")
    local base_animation_path = _folderpath.."battle.animation"
    local base_charge_color = Color.new(16, 113, 189, 255)

    player:set_animation(base_animation_path)
    player:set_texture(base_texture)
    player:set_fully_charged_color(base_charge_color)
    player:set_charge_position(0, -20)

    --Charge Shots
    local cross_gun = include("Chips/Neutral/CrossGun/entry.lua")

    --Special Chip
    local sonic_rush = include("Chips/Neutral/SonicRush/entry.lua")

    --Special Attacks
    local cross_shield = include("Chips/Neutral/CrossShield/entry.lua")

    player.normal_attack_func = function()
        return Battle.Buster.new(player, false, player:get_attack_level())
    end

    player.charged_attack_func = function()
        local props = Battle.CardProperties:new()
        props.damage = player:get_attack_level() * 10
        return cross_gun.card_create_action(player, props)
        --return Battle.Buster.new(player, true, player:get_attack_level() * 10)
    end

    player.special_attack_func = function()
        local props = Battle.CardProperties:new()
        props.damage = 20 + ((player:get_attack_level()) * 10)
        return sonic_rush.card_create_action(player, props)
    end
end
