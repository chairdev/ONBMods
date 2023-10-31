local heat_knuckle = {}
local DAMAGE = 60

local FIREPUNCH_TEXTURE = Engine.load_texture(_folderpath.."firepunch.png")
local FIREPUNCH_ANIMPATH = _folderpath.."firepunch.animation"
local FIREPUNCH_AUDIO = Engine.load_audio(_folderpath.."firepunch.ogg")

local AUDIO_DAMAGE = Engine.load_audio(_folderpath.."hitsound.ogg")
local EFFECT_TEXTURE = Engine.load_texture(_folderpath.."effect.png")
local EFFECT_ANIMPATH = _folderpath.."effect.animation"

function package_init(package) 
    package:declare_package_id("com.chair.HeatKnuckle")
    package:set_icon_texture(Engine.load_texture(_folderpath.."icon.png"))
    package:set_preview_texture(Engine.load_texture(_folderpath.."preview.png"))
	package:set_codes({"D","E","F"})

    local props = package:get_card_props()
    props.shortname = "FirPnch1"
    props.damage = DAMAGE
    props.time_freeze = false
    props.element = Element.Fire
    props.description = "Punch closest column!"
    props.long_description = "Punch the nearest column in the front 3 columns!"
    props.can_boost = true
	props.card_class = CardClass.Standard
	props.limit = 5
end

function heat_knuckle.card_create_action(user, props)
    local action = Battle.CardAction.new(user, "PLAYER_IDLE")
	action:set_lockout(make_async_lockout(0.633))
    local override_frames = {{1,0.017},{1,0.017}}
    local frame_data = make_frame_data(override_frames)
    action:override_animation_frames(frame_data)

    action.execute_func = function(self, user)
        print("in custom card action execute_func()!")
        local field = user:get_field()
		local team = user:get_team()
		local direction = user:get_facing()
        
        local self_tile = user:get_current_tile()
        local self_X = self_tile:x()
        local self_Y = self_tile:y()

        self:add_anim_action(1, function()
            --target_finder(user, props, team, direction, field, self_X, self_Y)
            --create the punch one tile in front of the user
            local x = 1
            if user:get_facing() == Direction.Left then 
                x = x * -1
            end

            local tile = user:get_current_tile():get_tile(user:get_facing(), 1)
            local isBoosted = false

            --if current tile is lava, then double the damage
            if tile:get_state() == TileState.Lava then
                print("tile is lava!")
                isBoosted = true
            end

            create_punch(user, props, team, direction, field, self_X+x, self_Y, isBoosted)
            --if is boosted, remove the lava state, otherwise, add it
            if isBoosted then
                tile:set_state(TileState.Normal)
            else
                tile:set_state(TileState.Lava)
            end
        end)
    end
    return action
end

function create_punch(owner, props, team, direction, field, punch_X, punch_Y, isBoosted)
    local punch = Battle.Spell.new(team)
    punch:set_facing(direction)

    if isBoosted then
        props.damage = props.damage * 2
    end

    punch:set_hit_props(
        HitProps.new(
            props.damage,
            Hit.Flinch | Hit.Flash | Hit.Impact | Hit.Drag,
            props.element,
            owner:get_id(),
            Drag.new(direction, 1)
        )
    )
    local punch_sprite = punch:sprite()
    punch_sprite:set_texture(FIREPUNCH_TEXTURE)
    punch_sprite:set_layer(-9)
    local punch_anim = punch:get_animation()
    punch_anim:load(FIREPUNCH_ANIMPATH)
    punch_anim:set_state("0")
    punch_anim:refresh(punch_sprite)
    punch_anim:on_complete(function() punch:erase() end)
     
    punch.update_func = function(self, dt)
        self:get_current_tile():attack_entities(self)
    end
     
    punch.can_move_to_func = function(tile)
		return true
	end
     
    --[[punch.battle_end_func = function(self)
		self:erase()
	end]]
     
    punch.attack_func = function(self, other)
        Engine.play_audio(AUDIO_DAMAGE, AudioPriority.Highest)
		create_effect(EFFECT_TEXTURE, EFFECT_ANIMPATH, "FIRE", math.random(-5,5), math.random(-5,5), field, self:get_current_tile())
    end
     
    punch.delete_func = function(self)
		self:erase()
    end

    local delay = Battle.Spell.new(team)
    delay:get_facing(direction)
    local delay_anim = delay:get_animation()
    delay_anim:load(_folderpath.."attack.animation")
    delay_anim:set_state("1")
    delay_anim:refresh(punch_sprite)
    delay_anim:on_frame(1, function()
        delay:highlight_tile(Highlight.Solid)
    end)
    delay_anim:on_frame(2, function()
        Engine.play_audio(FIREPUNCH_AUDIO, AudioPriority.High)
        delay:highlight_tile(Highlight.None)
    end)
    delay_anim:on_frame(3, function()
        field:spawn(punch, punch_X, punch_Y)
    end)
    delay_anim:on_complete(function() delay:erase() end)
    delay.update_func = function(self, dt)
    end
    delay.can_move_to_func = function(tile)
		return true
	end
    delay.battle_end_func = function(self)
		self:erase()
	end
    punch.delete_func = function(self)
		self:erase()
    end
     
    field:spawn(delay, punch_X, punch_Y)
end

function create_effect(effect_texture, effect_animpath, effect_state, offset_x, offset_y, field, tile)
    local hitfx = Battle.Artifact.new()
    hitfx:set_facing(Direction.Right)
    hitfx:set_texture(effect_texture, true)
    hitfx:set_offset(offset_x, offset_y)
    local hitfx_sprite = hitfx:sprite()
    hitfx_sprite:set_layer(-99999)
    local hitfx_anim = hitfx:get_animation()
	hitfx_anim:load(effect_animpath)
	hitfx_anim:set_state(effect_state)
	hitfx_anim:refresh(hitfx_sprite)
    hitfx_anim:on_complete(function()
        hitfx:erase()
    end)
    field:spawn(hitfx, tile)

    return hitfx
end
return heat_knuckle