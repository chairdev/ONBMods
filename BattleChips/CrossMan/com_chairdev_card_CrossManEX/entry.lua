local crossman = include("crossman/crossman.lua")

local DAMAGE = 140

crossman.codes = {"C","*"}
crossman.shortname = "CrossMEX"
crossman.damage = DAMAGE
crossman.time_freeze = true
crossman.element = Element.None
crossman.description = "Warp in and shoot X squares"
crossman.long_description = "Warp in and shoot a 4-panel diagonal blast"
crossman.can_boost = true
crossman.card_class = CardClass.Mega
crossman.limit = 2

function package_init(package) 
    package:declare_package_id("com.chairdev.card.crossmanex")
    package:set_icon_texture(Engine.load_texture(_modpath.."icon.png"))
    package:set_preview_texture(Engine.load_texture(_modpath.."preview.png"))
	package:set_codes(crossman.codes)

    local props = package:get_card_props()
    props.shortname = crossman.shortname
    props.damage = crossman.damage
    props.time_freeze = crossman.time_freeze
    props.element = crossman.element
    props.description = crossman.description
    props.long_description = crossman.long_description
    props.can_boost = crossman.can_boost
	props.card_class = crossman.card_class
	props.limit = crossman.limit
end

card_create_action = crossman.card_create_action