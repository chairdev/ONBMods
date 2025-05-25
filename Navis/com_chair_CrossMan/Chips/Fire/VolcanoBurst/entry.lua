local DAMAGE = 150
local volcano_burst = {}
nonce = function() end

local TEXTURE_FLAMETOWER = Engine.load_texture(_folderpath.."flametower.png")
local ANIMPATH_FLAMETOWER = _folderpath .. "flametower.animation"
local AUDIO_FLAMETOWER = Engine.load_audio(_folderpath.."flametower.ogg")

local TEXTURE_EFFECT = Engine.load_texture(_folderpath.."effect.png")
local ANIMPATH_EFFECT = _folderpath .. "effect.animation"
local AUDIO_DAMAGE = Engine.load_audio(_folderpath.."hitsound.ogg")

--com.k1rbyat1na.card.EXE3-054-BurningCross

function volcano_burst.card_create_action(user, props)
    DAMAGE = props.damage
    local action = Battle.CardAction.new(user, "PLAYER_THROW")
	action:set_lockout(make_animation_lockout())
    local override_frames = {{1,0.050},{2,0.050},{3,0.050},{4,0.050},{5,0.255}}
    local frame_data = make_frame_data(override_frames)
    action:override_animation_frames(frame_data)

    action.execute_func = function(self, user)
        local field = user:get_field()
		local team = user:get_team()
		local direction = user:get_facing()
        local tile = user:get_tile(direction, 1)
        self:add_anim_action(2,function()
            user:toggle_counter(true)
		end)
        self:add_anim_action(4,function()
            user:toggle_counter(false)
		end)
        self:add_anim_action(5,function()
            spawn_flametower(user, props, tile, team, direction, field)
        end)
    end
    return action
end

function spawn_flametower(owner, props, tile, team, direction, field)
    local spawn_next
    spawn_next = function()
        if not tile:is_walkable() then return end

        if(tile:get_state() == TileState.Grass) then
            props.damage = DAMAGE * 2
            tile:set_state(TileState.Normal)
        elseif (tile:get_state() == TileState.Ice) then
            tile:set_state(TileState.Normal)
        end


        Engine.play_audio(AUDIO_FLAMETOWER, AudioPriority.Highest)

        local spell = Battle.Spell.new(team)
        spell:set_facing(direction)
        spell:set_hit_props(HitProps.new(
            props.damage, 
            Hit.Impact | Hit.Flash | Hit.Flinch, 
            props.element, 
            owner:get_id(), 
            Drag.new())
        )

        local sprite = spell:sprite()
        sprite:set_texture(TEXTURE_FLAMETOWER)
        sprite:set_layer(-999)

        local animation = spell:get_animation()
        animation:load(ANIMPATH_FLAMETOWER)
        animation:set_state("DEFAULT")
        animation:refresh(sprite)

        animation:on_frame(11, function()
            local tile_U = tile:get_tile(Direction.Up, 1)
            local tile_D = tile:get_tile(Direction.Down, 1)
            local tile_L = tile:get_tile(Direction.Left, 1)
            local tile_R = tile:get_tile(Direction.Right, 1)
            spawn_flametower_next(owner, props, tile_U, team, direction, field)
            spawn_flametower_next(owner, props, tile_D, team, direction, field)
            spawn_flametower_next(owner, props, tile_L, team, direction, field)
            spawn_flametower_next(owner, props, tile_R, team, direction, field)
        end, true)
        animation:on_complete(function() 
            spell:erase()
        end)

        spell.update_func = function()
            spell:get_current_tile():attack_entities(spell)
        end

        spell.attack_func = function()
            Engine.play_audio(AUDIO_DAMAGE, AudioPriority.Highest)
            create_effect(TEXTURE_EFFECT, ANIMPATH_EFFECT, "FIRE", math.random(-30,30), math.random(-30,30), field, spell:get_current_tile())
        end

        spell.can_move_to_func = function(tile)
            return true
        end

        field:spawn(spell, tile)
    end

    spawn_next()
end

function spawn_flametower_next(owner, props, tile, team, direction, field)
    local spawn_next
    spawn_next = function()
        if not tile:is_walkable() then return end

        if(tile:get_state() == TileState.Grass) then
            props.damage = DAMAGE * 2
            tile:set_state(TileState.Normal)
        elseif (tile:get_state() == TileState.Ice) then
            tile:set_state(TileState.Normal)
        end

        Engine.play_audio(AUDIO_FLAMETOWER, AudioPriority.Highest)

        local spell = Battle.Spell.new(team)
        spell:set_facing(direction)
        spell:set_hit_props(HitProps.new(
            props.damage, 
            Hit.Impact | Hit.Flash | Hit.Flinch, 
            props.element, 
            owner:get_id(), 
            Drag.new())
        )

        local sprite = spell:sprite()
        sprite:set_texture(TEXTURE_FLAMETOWER)
        sprite:set_layer(-999)

        local animation = spell:get_animation()
        animation:load(ANIMPATH_FLAMETOWER)
        animation:set_state("DEFAULT")
        animation:refresh(sprite)

        animation:on_complete(function() 
            spell:erase()
        end)

        spell.update_func = function()
            spell:get_current_tile():attack_entities(spell)
        end

        spell.attack_func = function()
            Engine.play_audio(AUDIO_DAMAGE, AudioPriority.Highest)
            create_effect(TEXTURE_EFFECT, ANIMPATH_EFFECT, "FIRE", math.random(-30,30), math.random(-30,30), field, spell:get_current_tile())
        end

        spell.can_move_to_func = function(tile)
            return true
        end

        field:spawn(spell, tile)
    end

    spawn_next()
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
return volcano_burst