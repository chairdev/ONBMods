local cross_blaster = {}

local BUSTER_AUDIO = Engine.load_audio(_folderpath.."pew.ogg")
local RETICLE_AUDIO = Engine.load_audio(_folderpath.."SE_M_Cursol.wav")
local flare_texture = Engine.load_texture(_folderpath .. "buster_shoot.png")
local flare_animation_path = _folderpath .. "buster_shoot.animation"
local TILE_HIT_TEXTURE = Engine.load_texture(_folderpath.."tile_hit.png")
local TILE_HIT_ANIMPATH = _folderpath.."tile_hit.animation"
local TARGET_TEXTURE = Engine.load_texture(_folderpath.."target.png")
local TARGET_ANIMPATH = _folderpath.."target.animation"

-- Graphic initializer
local function graphic_init(g_type, x, y, texture, animation, state, anim_playback, layer, user, facing, flip)
    flip = flip or false
    facing = facing or nil
    
    local graphic = nil
    if g_type == "artifact" then 
        graphic = Battle.Artifact.new()
    elseif g_type == "spell" then 
        graphic = Battle.Spell.new(user:get_team())
    end

    if layer then graphic:sprite():set_layer(layer) end
    graphic:never_flip(flip)
    if texture then graphic:set_texture(texture, false) end
    if facing then graphic:set_facing(facing) end
    
    if user:get_facing() == Direction.Left then x = x * -1 end
    graphic:set_offset(x, y)
    if animation then graphic:get_animation():load(animation) end
    if state then graphic:get_animation():set_state(state) end
    graphic:get_animation():refresh(graphic:sprite())
    if anim_playback then graphic:get_animation():set_playback(anim_playback) end

    return graphic
end

-- Flare effect
local function play_flare(action)
    local buster = action:add_attachment("BUSTER")
    local flare = buster:add_attachment("endpoint")
    flare:sprite():set_texture(flare_texture)
    flare:sprite():set_layer(-1)
    local flare_anim = flare:get_animation()
    flare_anim:load(flare_animation_path)
    flare_anim:set_state("DEFAULT2")
end

-- TILE_HIT attack
local function create_attack(user, x, y, props)
    local attack = graphic_init("spell", 0, 0, TILE_HIT_TEXTURE, TILE_HIT_ANIMPATH, "0", Playback.Once, -3, user, user:get_facing())
    attack:set_hit_props(
        HitProps.new(
            props.damage,
            Hit.Impact | Hit.Flinch,
            props.element,
            user:get_context(),
            Drag.None
        )
    )
    attack.frames = 0
    attack:get_animation():on_complete(function() attack:delete() end)
    attack.update_func = function(self)
        self.frames = self.frames + 1
        if self.frames == 1 then
            self:get_current_tile():attack_entities(self)
            self:highlight_tile(Highlight.Solid)
        elseif self.frames >= 2 then
            self:highlight_tile(Highlight.None)
        end
    end
    user:get_field():spawn(attack, x, y)
end

-- Find closest target
local function find_closest_target(agent)
    local field = agent:get_field()
    local facing = agent:get_facing()
    local actor_tile = agent:get_current_tile()
    local actor_x = actor_tile:x()

    local target = nil
    local closest_distance = math.huge

    field:find_characters(function(character)
        local team = character:get_team()
        if character:is_deleted() or team == agent:get_team() or team == Team.Other or character:get_health() == 0 then
            return false
        end

        local distance = character:get_current_tile():x() - actor_x
        if (facing == Direction.Right and distance < 1) or (facing == Direction.Left and distance > -1) then
            return false
        end

        if facing == Direction.Left then distance = -distance end
        if distance < closest_distance then
            closest_distance = distance
            target = character
        end
        return false
    end)

    return target
end

-- Spawn reticle on target
local function spawn_reticle(user, target)
    Engine.play_audio(RETICLE_AUDIO, AudioPriority.Low)
    local tile = target:get_current_tile()
    local reticle = graphic_init("spell", 0, 0, TARGET_TEXTURE, TARGET_ANIMPATH, "0", Playback.Loop, -3, user, Direction.Right, true)

    reticle.update_func = function(self)
        if target:is_deleted() then
            self:erase()
        else
            local t_tile = target:get_current_tile()
            self:set_offset(0,0) -- always 0 offset relative to tile
            self:get_field():spawn(self, t_tile:x(), t_tile:y()) -- "respawn" graphic at new tile
        end
    end

    user:get_field():spawn(reticle, tile:x(), tile:y())
    return reticle
end


-- Main card action
function cross_blaster.card_create_action(agent, props)
    local action = Battle.CardAction.new(agent,"PLAYER_SHOOTING")
    action.hitprops = HitProps.new(
        props.damage,
        Hit.Impact,
        props.element,
        agent:get_context(),
        Drag.None
    )

    -- Set up buster animation
    local buster = action:add_attachment("BUSTER")
    local buster_anim = buster:get_animation()
    local buster_sprite = buster:sprite()
    buster_sprite:set_texture(agent:get_texture(), true)
    buster_sprite:set_layer(-3)
    buster_anim:copy_from(agent:get_animation())
    buster_anim:set_state("BUSTER")
    buster_anim:refresh(buster_sprite)
    buster_anim:set_playback_speed(0)

    -- Build frame sequence
    local total_frames = 4 * 11
    local frame_sequence = {}
    for i = 1, total_frames do
        table.insert(frame_sequence, {1, 0.033})
    end
    action:override_animation_frames(make_frame_data(frame_sequence))
    action:set_lockout(make_animation_lockout())

    -- Find closest target at start
    local target = find_closest_target(agent)
    local reticle = nil
    if target then
        reticle = spawn_reticle(agent, target)
    end

    -- Schedule shots (after 9-frame delay)
    local shot_frames = {11, 22, 33, 44}
    for _, frame in ipairs(shot_frames) do
        action:add_anim_action(frame, function()
            if target and not target:is_deleted() then
                local tile = target:get_current_tile()
                create_attack(agent, tile:x(), tile:y(), props)
                play_flare(action)
                buster_anim:set_state("1")
                buster_anim:set_playback(Playback.Once)
                buster_anim:refresh(buster_sprite)
            end
        end)
    end

    -- End action
    action:add_anim_action(total_frames + 1, function()
        agent:toggle_counter(false)
        if reticle then reticle:erase() end
    end)

    action.execute_func = function(self, user)
        user:toggle_counter(true)
    end
    action.action_end_func = function(self)
        agent:toggle_counter(false)
        if reticle then reticle:erase() end
    end

    return action
end

return cross_blaster
