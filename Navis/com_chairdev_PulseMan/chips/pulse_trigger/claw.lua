local SLASH_TEXTURE = Engine.load_texture(_folderpath.."battle_fx38_animations.png")
local SLASH_ANIM_PATH = _folderpath.."battle_fx38_animations.animation"
local GREGARCLAW_AUDIO_1 = Engine.load_audio(_folderpath.."sfx/EXE6_107.ogg", true)
local GREGARCLAW_AUDIO_2 = Engine.load_audio(_folderpath.."sfx/EXE6_207.ogg", true)

function create_slash(user, props, tile_data, state, flashes)
    local field = user:get_field()
    local team = user:get_team()
    local facing = user:get_facing()
    local slash = graphic_init("artifact", 0, -16 * 2, SLASH_TEXTURE, SLASH_ANIM_PATH, -1, state, user, user:get_facing(), true)
    
    local hit_props = HitProps.new(user:get_context())
        :dmg(props.damage)
        :impact()
        :flinch()

    if flashes then 
        hit_props:flash()
    end

    local tiles = {}

    local facing_mod = facing == Direction.Right and 1 or -1
    local user_tile = user:get_current_tile()
    local user_x = user_tile:x()
    local user_y = user_tile:y()
    for k, target in ipairs(tile_data)
    do
        local maybe_tile = field:tile_at(user_x + target.x_off * facing_mod, user_y + target.y_off)
        if maybe_tile then 
            table.insert(tiles, maybe_tile)
        end
    end

    local boxes = create_hitbox(field, tiles, hit_props, team)

    field:spawn(slash, user:get_tile(facing, 1))
    field:spawn(boxes, user_tile)
end

function create_hitbox(field, tiles, props, team)
    local spell = Battle.Spell.new(team)

    spell:set_hit_props(props)
    
    spell.update_func = function(self)
        for i=1, #tiles do
            local t = tiles[i]
            if t then 
                t:attack_entities(self)
            end
        end

        self:delete()
    end

    return spell
end

local function beast_claw(player, props)
    local action = Battle.CardAction.new(player, "BEAST_CLAW")
    local field = player:get_field()
    local start_tile = nil

    local f1 = 0.016
    local f2 = 0.033
    local f4 = 0.067
    local f9 = 0.15
    local frames = {
        {1, f4},
        -- Move on this frame
        {1, f1},
        {2, f2},
        -- Attack long
        {3, f2},
        {4, f2},
        {5, f9},
        {2, f2},
        -- Attack wide
        {3, f2},
        {4, f2},
        -- This one should really be 8f, but ONB is shaving off a frame anyway
        {5, f9}
    }

    action:override_animation_frames(make_frame_data(frames))

    local function check_characters(tile, self)
        local characters = tile:find_characters(function(c)
            return c:get_id() ~= self:get_id() and c:get_team() ~= self:get_team()
        end)
    
        return #characters > 0
    end

    local function check_obstacles(tile, self)
        local ob = tile:find_obstacles(function(o)
            return o:get_health() > 0 
        end)
    
        return #ob > 0 
    end

    --[[ 
        Return a Tile from 0-2 Tiles ahead of player.
        Avoids Tiles that are occupied, and prefers Tiles that are 
        horizontally aligned that allows an enemy to be hit by one of the
        slash attacks. 

        Otherwise, prefers Tiles that allow an enemy to be hit by the 
        horizontal attack. If neither preference can be met, returns a Tile 
        that is the furthest ahead the Player can move in this range.
    ]]
    local function find_dest(player)
        local chosen_tile = nil
        start_tile = player:get_current_tile()
        local cur_tile = start_tile
        local facing = player:get_facing()
        local reverse = Direction.reverse(facing)
        -- If any reach this weight, immediately stop processing and 
        -- choose that Tile.
        local weight_max = 6
        local weights = {}

        local range = 3
        for i=1, range
        do
            local weight = 0
            weights[i] = weight
        
            -- Tile that would be stood on if this is a good one to aim for
            local standing_tile = cur_tile

            cur_tile = cur_tile:get_tile(facing, 1)
            -- If Tile i away is unreachable, then i+1 away also is
            if not cur_tile or cur_tile:is_edge() then 
                break
            end

            -- Must be able to stand on this Tile to consider it.
            -- It would be nice if Lua had continue. I'm not using labels.
            if not check_characters(standing_tile, player) and not check_obstacles(standing_tile) then 
                -- An enemy is on this Tile, which makes it the perfect 
                -- target. Use it.
                if check_characters(cur_tile, player) then
                    return standing_tile
                end

                -- When no Tiles are suitable to get a hit, prefer furthest 
                -- Tile
                weight = weight + i

                local above_tile = cur_tile:get_tile(Direction.Up, 1)
                local below_tile = cur_tile:get_tile(Direction.Down, 1)

                -- An enemy above or below could be hit by one slash 
                if above_tile and check_characters(above_tile, player) or below_tile and check_characters(below_tile, player) then
                    weight = weight + 1
                end

                local ahead_tile = cur_tile:get_tile(facing, 1)
                -- An enemy ahead could be hit by the first slash, which is 
                -- higher priority than others
                if ahead_tile and check_characters(ahead_tile, player) then
                    weight = weight + 2
                end

                weights[i] = weight
            end
        end

        local highest_weight = 0
        local chosen_index = 0
        for i=1, range do
            local v = weights[i]
            -- < will prefer closer Tiles when tied
            if highest_weight < v then
                highest_weight = v
                chosen_index = i
            end
        end

        if chosen_index < 2 then
            return start_tile
        end

        return start_tile:get_tile(facing, chosen_index - 1)
    end

    action.execute_func = function(self, actor)
        self:add_anim_action(2, function()
            local t = find_dest(actor)
            local off = player:sprite():get_offset()
            local start = actor:get_current_tile()
            start:remove_entity_by_id(actor:get_id())
            t:add_entity(actor)

            -- This is cheaper than checking Tile equality
            if t:x() == start:x() and t:y() == start:y() then 
                return
            end

            local off_2 = player:sprite():get_offset()
            local i1 = create_afterimage(player, 10, off)
            local i2 = create_afterimage(player, 16, {x = (off_2.x + off.x)/2, y = (off_2.y + off.y)/2})

            -- Same tile to make sure they update 
            -- at the same time as each other. Animation sync.
            local corner = field:tile_at(6, 3)
            field:spawn(i1, corner)
            field:spawn(i2, corner)
        end)

        self:add_anim_action(4, function()
            Engine.play_audio(GREGARCLAW_AUDIO_1, AudioPriority.Immediate)
            create_slash(actor, props, {
                {x_off = 1, y_off = 0},
                {x_off = 2, y_off = 0}
            }, "1", false)
        end)

        self:add_anim_action(8, function()
            Engine.play_audio(GREGARCLAW_AUDIO_2, AudioPriority.Immediate)
            create_slash(actor, props, {
                {x_off = 1, y_off = 0},
                {x_off = 1, y_off = -1},
                {x_off = 1, y_off = 1}
            }, "0", true)
        end)
    end


    action.action_end_func = function(self)
        local actor = self:get_actor()
        actor:get_current_tile():remove_entity_by_id(actor:get_id())
        start_tile:add_entity(actor)
    end

    return action
end

-- Does not spawn.
function create_afterimage(player, lifetime, offset)
    local artifact = Battle.Artifact.new()
    artifact:set_facing(player:get_facing())
    artifact:set_texture(player:get_texture())
    local color = Color.new(196, 96, 64, 255)

    local sprite = artifact:sprite()
    sprite:set_color_mode(ColorMode.Multiply)
    sprite:set_color(color)
    local anim = artifact:get_animation()
    anim:copy_from(player:get_animation())

    anim:set_state("PLAYER_HIT")
    anim:set_playback(Playback.Once)
    
    -- Try to fast forward the animation to the last frame of flinch
    -- TODO: When we can set a frame, use that
    for i=1, 20
    do
        anim:update(20/60, sprite)
    end

    anim:refresh(sprite)
    anim:set_playback(Playback.Once)

    artifact:hide()
    
    -- Components don't update the frame they are added,
    -- so start at 1 instead of 0. 
    local timer = 1
    lifetime = lifetime+1
    sprite:set_offset(offset.x, offset.y)

    local c = Battle.Component.new(artifact, Lifetimes.Scene)

    artifact:register_component(c)

    -- Doing that set_offset in the Artifact update is too 
    -- early, apparently.
    c.update_func = function(self)
        sprite:set_offset(offset.x, offset.y)

        sprite:set_color(color)

        timer = timer + 1

        if timer == lifetime then 
            artifact:delete()
            artifact:hide()
            return
        end
        
        if timer % 3 == 1 then 
            artifact:hide()
            return
        end


        artifact:reveal()
    end

    return artifact
end

return beast_claw