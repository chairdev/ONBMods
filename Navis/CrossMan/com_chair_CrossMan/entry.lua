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
end

function player_init(player)
    player:set_name("CrossMan")
    player:set_health(1000)
    player:set_element(Element.None)
    player:set_height(38.0)

    local base_texture = Engine.load_texture(_folderpath.."battle.png")
    local base_animation_path = _folderpath.."battle.animation"
    local base_charge_color = Color.new(57, 198, 243, 255)

    player:set_animation(base_animation_path)
    player:set_texture(base_texture)
    player:set_fully_charged_color(base_charge_color)
    player:set_charge_position(0, -20)

    --Charge Shots
    local cross_laser = include("Chips/Neutral/CrossLaser/entry.lua")
    local bamb_sword = include("Chips/Wood/BambooSword/entry.lua")
    local heat_knuckle = include("Chips/Fire/HeatKnuckle/entry.lua")
    local aqua_blaster = include("Chips/Aqua/AquaBlaster/entry.lua")
    local elec_bomb = include("Chips/Electric/ElecBomb/entry.lua")
    local satella_sword = include("Chips/None/SatellaSword/entry.lua")

    --Special Attacks
    local cross_shield = include("Chips/Neutral/CrossShield/entry.lua")
    

    local wood_atk = 3;
    local fire_atk = 4;
    local aqua_atk = 2;
    local elec_atk = 3;
    local null_atk = 5;

    --NCPs
    local super_armor = Battle.DefenseRule.new(813, DefenseOrder.CollisionOnly)
	super_armor.filter_statuses_func = function(statuses)
		statuses.flags = statuses.flags & ~Hit.Flinch
		return statuses
	end

    local battleresults1_va = Engine.load_audio(_folderpath .. "/Voices/BattleStart/battlestart1.wav")
    local battleresults2_va = Engine.load_audio(_folderpath .. "/Voices/BattleStart/battlestart2.wav")
    local battleresults3_va = Engine.load_audio(_folderpath .. "/Voices/BattleStart/battlestart3.wav")
    local battleresults4_va = Engine.load_audio(_folderpath .. "/Voices/BattleStart/battlestart4.wav")

    player.normal_attack_func = function()
        return Battle.Buster.new(player, false, player:get_attack_level())
    end

    player.charged_attack_func = function()
        local props = Battle.CardProperties:new()
        props.damage = player:get_attack_level() * 10
        return cross_laser.card_create_action(player, props)
        --return Battle.Buster.new(player, true, player:get_attack_level() * 10)
    end

    player.special_attack_func = function()
        local props = Battle.CardProperties:new()
        props.damage = 20 + ((player:get_attack_level()) * 10)
        return cross_shield.card_create_action(player, props)
    end

    player.battle_start_func = function()
        local result = math.random(4)
        if result == 0 then
            Engine.play_audio(battleresults1_va, AudioPriority.Low)
        elseif result == 1 then
            Engine.play_audio(battleresults2_va, AudioPriority.Low)
        elseif result == 2 then
            Engine.play_audio(battleresults3_va, AudioPriority.Low)
        else
            Engine.play_audio(battleresults4_va, AudioPriority.Low)
        end
    end
    --Cross Link has 5 forms, each with their own unique abilities.
    --

    -- (Wood) Woody Fighter
    local wood = player:create_form()
    wood:set_mugshot_texture_path(_folderpath.."forms/wood_entry.png")

    wood.on_activate_func = function()
        --set element
        player:set_element(Element.Wood)

        --set airshoes
        player:set_air_shoe(true)

        player:set_animation(_folderpath.."forms/Wood/woody_fighter.animation")
        player:set_texture(Engine.load_texture(_folderpath.."forms/Wood/woody_fighter.png"))
        player:set_fully_charged_color(Color.new(243, 57, 198, 255))
    end

    wood.charged_attack_func = function()
        local props = Battle.CardProperties:new()
        props.damage = 50 + ((player:get_attack_level()+wood_atk) * 10)
        return bamb_sword.card_create_action(player, props)
        --return Battle.Buster.new(player, true, player:get_attack_level() * 10)
    end

    wood.on_deactivate_func = function()
        disable_ncps()
        
        player:set_animation(base_animation_path)
        player:set_texture(base_texture)
        player:set_fully_charged_color(base_charge_color)
    end

    -- forms also have a normal_attack_func, charged_attack_func, and special_attack_func
    -- however, megaman does not have different abilities than man, so we'll just exclude these
    -- so the engine will fallback to what is defined on the player

    -- (Fire) Fire Titan
    local fire = player:create_form()
    fire:set_mugshot_texture_path(_folderpath.."forms/fire_entry.png")

    fire.on_activate_func = function()
        --set element
        player:set_element(Element.Fire)

        --set super armor
        player:add_defense_rule(super_armor)

        -- use megaman assets
        player:set_animation(_folderpath.."forms/Fire/fire_titan.animation")
        player:set_texture(Engine.load_texture(_folderpath.."forms/Fire/fire_titan.png"))
        player:set_fully_charged_color(Color.new(243, 57, 198, 255))
    end

    fire.charged_attack_func = function()
        local props = Battle.CardProperties:new()
        props.damage = 40 + ((player:get_attack_level()+fire_atk) * 10)
        return heat_knuckle.card_create_action(player, props)
        --return Battle.Buster.new(player, true, player:get_attack_level() * 10)
    end

    fire.on_deactivate_func = function()
        disable_ncps()
        
        player:set_animation(base_animation_path)
        player:set_texture(base_texture)
        player:set_fully_charged_color(base_charge_color)

        player:remove_defense_rule(super_armor)
        -- attack/charge stats are automatically reverted by the engine
    end

    -- (Aqua) Aqua Gunner
    local aqua = player:create_form()
    aqua:set_mugshot_texture_path(_folderpath.."forms/aqua_entry.png")

    aqua.on_activate_func = function()
        --set element
        player:set_element(Element.Aqua)

        -- use megaman assets
        player:set_animation(_folderpath.."forms/Aqua/aqua_gunner.animation")
        player:set_texture(Engine.load_texture(_folderpath.."forms/Aqua/aqua_gunner.png"))
        player:set_fully_charged_color(Color.new(243, 57, 198, 255))
    end

    aqua.charged_attack_func = function()
        local props = Battle.CardProperties:new()
        props.damage = 30 + ((player:get_attack_level()+aqua_atk) * 5)
        return aqua_blaster.card_create_action(player, props)
        --return Battle.Buster.new(player, true, player:get_attack_level() * 10)
    end

    aqua.on_deactivate_func = function()
        disable_ncps()

        player:set_animation(base_animation_path)
        player:set_texture(base_texture)
        player:set_fully_charged_color(base_charge_color)
        -- attack/charge stats are automatically reverted by the engine
    end

    -- (Elec) Elec Bomb
    local elec = player:create_form()
    elec:set_mugshot_texture_path(_folderpath.."forms/elec_entry.png")

    elec.on_activate_func = function()
        --set element
        player:set_element(Element.Elec)

        --set float shoes
        player:set_float_shoe(true)

        -- use megaman assets
        player:set_animation(_folderpath.."forms/Elec/elec_bomber.animation")
        player:set_texture(Engine.load_texture(_folderpath.."forms/Elec/elec_bomber.png"))
        player:set_fully_charged_color(Color.new(243, 57, 198, 255))
    end

    elec.charged_attack_func = function()
        local props = Battle.CardProperties:new()
        props.damage = 60 + ((player:get_attack_level()+elec_atk) * 10)
        return elec_bomb.card_create_action(player, props)
        --return Battle.Buster.new(player, true, player:get_attack_level() * 10)
    end

    elec.on_deactivate_func = function()
        disable_ncps()

        player:set_animation(base_animation_path)
        player:set_texture(base_texture)
        player:set_fully_charged_color(base_charge_color)
        -- attack/charge stats are automatically reverted by the engine
    end

    -- (None) Null Zenith
    local none = player:create_form()
    none:set_mugshot_texture_path(_folderpath.."forms/none_entry.png")

    none.on_activate_func = function()
        --set element
        player:set_element(Element.None)

        --set NCPs
        player:set_air_shoe(true)
        player:set_float_shoe(true)
        player:add_defense_rule(super_armor)

        -- use megaman assets
        player:set_animation(_folderpath.."forms/None/null_zenith.animation")
        player:set_texture(Engine.load_texture(_folderpath.."forms/None/null_zenith.png"))
        player:set_fully_charged_color(Color.new(243, 57, 198, 255))
    end

    none.charged_attack_func = function()
        local props = Battle.CardProperties:new()
        props.damage = 100 + ((player:get_attack_level()+null_atk) * 10)
        return satella_sword.card_create_action(player, props)
        --return Battle.Buster.new(player, true, player:get_attack_level() * 10)
    end

    none.on_deactivate_func = function()
        disable_ncps()

        player:set_animation(base_animation_path)
        player:set_texture(base_texture)
        player:set_fully_charged_color(base_charge_color)
        -- attack/charge stats are automatically reverted by the engine
    end

    function disable_ncps()
        player:set_air_shoe(false)
        player:set_float_shoe(false)
        player:remove_defense_rule(super_armor)
    end
end
