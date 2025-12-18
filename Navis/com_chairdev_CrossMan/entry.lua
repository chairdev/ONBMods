function package_init(package)
    package:declare_package_id("com.chair.CrossMan")
    package:set_special_description("It's Showtime!y")
    package:set_speed(5.0)
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
    player:set_health(1000)
    player:set_element(Element.None)
    player:set_height(48.0)

    local base_texture = Engine.load_texture(_folderpath.."battle.png")
    local base_animation_path = _folderpath.."battle.animation"
    local base_charge_color = Color.new(16, 113, 189, 255)
    local second_charge_color = Color.new(130, 60, 189, 255)

    player:set_animation(base_animation_path)
    player:set_texture(base_texture)
    player:set_fully_charged_color(base_charge_color)
    player:set_charge_position(0, -20)

    player:set_air_shoe(true)

    --Charge Shots
    local cross_blaster = include("Chips/Neutral/CrossBlaster/entry.lua")

    --Special Attacks
    local cross_barrage = nil --include("Chips/Neutral/CrossBarrage/entry.lua")

    local current_charge = 0

    player.normal_attack_func = function()
        return Battle.Buster.new(player, false, player:get_attack_level())
    end

    player.charged_attack_func = function()
        local props = Battle.CardProperties:new()
        props.damage = player:get_attack_level() * 10

        if current_charge == 0 then
            return cross_blaster.card_create_action(player, props)
        else
            return cross_blaster.card_create_action(player, props)
        end
    end

    player.special_attack_func = function()
        if current_charge == 0 then
            current_charge = 1
            player:set_fully_charged_color(second_charge_color)
        else
            current_charge = 0
            player:set_fully_charged_color(base_charge_color)
        end
    end
end
