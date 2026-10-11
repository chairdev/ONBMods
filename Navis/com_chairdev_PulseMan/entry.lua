local null_boost_val = 10

local pulse_vulcan = include("chips/pulse_vulcan/vulcan.lua")
local PulseTrigger = include("chips/pulse_trigger/claw.lua")

function add_null_chip_boost_component(player)
    local c = Battle.Component.new(player, Lifetimes.Scene)

    c.update_func = function()
        local handle = player:get_held_card_handle()
        if not handle then return end

        local props = handle:copy_modded_props()
        if not props.can_boost then return end

        if props.element ~= Element.None or props.time_freeze then
            if handle:has_mod(PropsMod.damage, "com.chairdev.PulseMan.NullBoost") then
                handle:drop_mod(PropsMod.damage, "com.chairdev.PulseMan.NullBoost")
            end
            return
        end

        if handle:has_mod(PropsMod.damage, "com.chairdev.PulseMan.NullBoost") then return end

        handle:write_mod(PropsMod.damage, "com.chairdev.PulseMan.NullBoost", null_boost_val)
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
        props.damage = math.floor((15 + (player:get_attack_level() * 10)) / 3)
        return PulseTrigger(player, props)
    end
end

function graphic_init(type, x, y, texture, animation, layer, state, user, facing, delete_on_complete, flip)
    flip = flip or false
    delete_on_complete = delete_on_complete or false
    facing = facing or nil
    
    local graphic = nil
    if type == "artifact" then 
        graphic = Battle.Artifact.new()
    elseif type == "spell" then 
        graphic = Battle.Spell.new(user:get_team())
    elseif type == "obstacle" then 
        graphic = Battle.Obstacle.new(user:get_team())
    end

    graphic:sprite():set_layer(layer)
    graphic:never_flip(flip)
    graphic:set_texture(texture)
    if facing then 
        graphic:set_facing(facing)
    end
    
    if user:get_facing() == Direction.Left then 
        x = x * -1
    end
    graphic:set_offset(x, y)
    local anim = graphic:get_animation()
    anim:load(animation)

    anim:set_state(state)
    anim:refresh(graphic:sprite())

    if delete_on_complete then 
        anim:on_complete(function()
            graphic:delete()
        end)
    end

    return graphic
end