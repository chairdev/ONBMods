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
    local volcano_burst = include("Chips/Fire/VolcanoBurst/entry.lua")
    local tempest_slash = include("Chips/Wind/TempestSlash/entry.lua")

    --Special Attacks
    local cross_barrage = include("Chips/Neutral/CrossBarrage/entry.lua")

    --Passive Abilities
    local SuperKitakaze = include("Chips/Wind/SuperKitakaze/entry.lua")

    player.normal_attack_func = function()
        return Battle.Buster.new(player, false, player:get_attack_level())
    end

    player.charged_attack_func = function()
        local props = Battle.CardProperties:new()
        props.damage = player:get_attack_level() * 10
        return cross_gun.card_create_action(player, props)
    end

    local special_attack_cooldown = 0 -- Initialize cooldown timer

    player.special_attack_func = function()
        if special_attack_cooldown > 0 then
            return nil -- Prevent attack if cooldown is active
        end

        local props = Battle.CardProperties:new()
        props.damage = player:get_attack_level() * 10
        special_attack_cooldown = math.floor(80 + (60 * 1.5)) -- Set cooldown to 80 frames, rounded down
        return cross_barrage.card_create_action(player, props)
    end

    -- Update function to decrement the cooldown timer
    player.update_func = function(self, dt, player)
        if special_attack_cooldown > 0 then
            special_attack_cooldown = special_attack_cooldown - 1
        end
    end

    local FireCode = player:create_form()
    FireCode:set_mugshot_texture_path(_modpath.."forms/fire_entry.png")
    FireCode.on_activate_func = function(self, player)
        player:set_element(Element.Fire)		
        --player:set_texture(Engine.load_texture(_modpath.."forms/elec_cross.png"), true)
    end

    FireCode.on_deactivate_func = function(self, player)
    local texture_path = base_texture
    player:set_texture(texture_path, true)
    end

    FireCode.update_func = function(self, dt, player) 
        if player:get_tile() then
            if player:get_tile():get_state() == TileState.Ice then			
                player:get_tile():set_state(TileState.Normal)
            end
        end
    end

    FireCode.special_attack_func = function(player)
        
    end

    FireCode.charged_attack_func = function(player)
        local props = Battle.CardProperties:new()
        props.damage = 30 + (player:get_attack_level() * 20)
        return volcano_burst.card_create_action(player, props)
    end

    -- Wind Code
    local snrthwind = false

    local WindCode = player:create_form()
    WindCode:set_mugshot_texture_path(_modpath.."forms/wind_entry.png")
    WindCode.on_activate_func = function(self, player)
        player:set_element(Element.Wind)
        --player:set_texture(Engine.load_texture(_modpath.."forms/elec_cross.png"), true)
        player:set_float_shoe(true)
        player:set_air_shoe(true)
    end

    WindCode.on_deactivate_func = function(self, player)
        local texture_path = base_texture
        player:set_texture(texture_path, true)

        player:set_float_shoe(false)
        player:set_air_shoe(false)
    end

    WindCode.special_attack_func = function(player)
        if snrthwind == false then
            snrthwind = true
            local props = Battle.CardProperties:new()
           return SuperKitakaze.card_create_action(player, props)
        end
    end

    WindCode.charged_attack_func = function(player)
        local props = Battle.CardProperties:new()
        props.damage =  5 + (player:get_attack_level() * 20)
        return tempest_slash.card_create_action(player, props)
    end
end
