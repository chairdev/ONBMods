local cross_blaster = {}

local DAMAGE_AUDIO = Engine.load_audio(_folderpath.."hurt.ogg")
local BUSTER_AUDIO = Engine.load_audio(_folderpath.."pew.ogg")
local flare_texture = Engine.load_texture(_folderpath .. "buster_shoot.png")
local flare_animation_path = _folderpath .. "buster_shoot.animation"
local TILE_HIT_TEXTURE = Engine.load_texture(_folderpath.."tile_hit.png")
local TILE_HIT_ANIMPATH = _folderpath.."tile_hit.animation"

local function graphic_init(g_type, x, y, texture, animation, state, anim_playback, layer, user, facing, flip)
    flip = flip or false
    facing = facing or nil
    
    local graphic = nil
    if g_type == "artifact" then 
        graphic = Battle.Artifact.new()
    elseif g_type == "spell" then 
        graphic = Battle.Spell.new(user:get_team())
    end

    if layer then
        graphic:sprite():set_layer(layer)
    end
    graphic:never_flip(flip)
    if texture then
        graphic:set_texture(texture, false)
    end
    if facing then
        graphic:set_facing(facing)
    end
    
    if user:get_facing() == Direction.Left then 
        x = x * -1
    end
    graphic:set_offset(x, y)
    if animation then
        graphic:get_animation():load(animation)
    end
    if state then
        graphic:get_animation():set_state(state)
    end
    graphic:get_animation():refresh(graphic:sprite())
    if anim_playback then
        graphic:get_animation():set_playback(anim_playback)
    end

    return graphic
end


local function play_flare(action)
    local buster = action:add_attachment("BUSTER")
    local flare = buster:add_attachment("endpoint")
    flare:sprite():set_texture(flare_texture)
    flare:sprite():set_layer(-1)

    local flare_anim = flare:get_animation()
    flare_anim:load(flare_animation_path)
    flare_anim:set_state("DEFAULT2")
end

local function fire_at_target(agent, props, action)
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

    if target then
        -- Get target tile position
        local target_tile = field:tile_at(target:get_current_tile():x(), target:get_current_tile():y())
        if target_tile then
            create_attack(agent, target_tile:x(), target_tile:y(), props)
            Engine.play_audio(BUSTER_AUDIO, AudioPriority.High)
        end
    end
end

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

    -- Build a frame sequence long enough (4 shots * 11 frames)
    local total_frames = 4 * 11
    local frame_sequence = {}
    for i = 1, total_frames do
        table.insert(frame_sequence, {1, 0.033}) -- adjust speed if needed
    end
    action:override_animation_frames(make_frame_data(frame_sequence))
    action:set_lockout(make_animation_lockout())

    -- Schedule shots
    local shot_frames = {2, 13, 24, 35} -- 11 frame gaps
    for _, frame in ipairs(shot_frames) do
        action:add_anim_action(frame, function()
            fire_at_target(agent, props, action)
            play_flare(action)
            buster_anim:set_state("1")
            buster_anim:set_playback(Playback.Once)
            buster_anim:refresh(buster_sprite)
        end)
    end

    -- End action after last shot
    action:add_anim_action(total_frames + 1, function()
        agent:toggle_counter(false)
    end)

    -- Execute
    action.execute_func = function(self, user)
        user:toggle_counter(true)
    end
    action.action_end_func = function(self)
        agent:toggle_counter(false)
    end

    return action
end

-- Reuse original attack creation function
function create_attack(user, x, y, props)
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
    attack:get_animation():on_complete(function()
        attack:delete()
    end)
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


return cross_blaster
