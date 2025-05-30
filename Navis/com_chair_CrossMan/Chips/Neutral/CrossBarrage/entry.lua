local cross_barrage = {}

local DAMAGE_AUDIO = Engine.load_audio(_folderpath.."hurt.ogg")
local BUSTER_AUDIO = Engine.load_audio(_folderpath.."pew.ogg")
local flare_texture = Engine.load_texture(_folderpath .. "buster_shoot.png")
local flare_animation_path = _folderpath .. "buster_shoot.animation"

-- Define play_flare at the top level
local function play_flare(action)
    local buster = action:add_attachment("BUSTER")
    local flare = buster:add_attachment("endpoint")

    flare:sprite():set_texture(flare_texture)
    flare:sprite():set_layer(-1)

    local flare_anim = flare:get_animation()
    flare_anim:load(flare_animation_path)
    flare_anim:set_state("DEFAULT2")
end

function cross_barrage.card_create_action(agent,props)

	local super_armor = nil
	local action = Battle.CardAction.new(agent,"PLAYER_SHOOTING")
	local buster = nil
	local buster_anim = nil
	local buster_sprite = nil
	local buster_frame = 1
	action.hitprops = nil

	if props.damage > props.damage then action.boosted = true action.drained = false elseif props.damage < props.damage then action.boosted = false action.drained = true else action.boosted = false action.drained = false end
	if not action.boosted then
	action.frame_sequence = make_frame_data({
		{1,0.05},{2,0.03},{3,0.03},{4,0.03},
		{1,0.05},{2,0.03},{3,0.03},{4,0.03},
		{1,0.05},{2,0.03},{3,0.03},{4,0.03},
		{1,0.05},{2,0.03},{3,0.03},{4,0.03},
		{1,0.05},{2,0.03},{3,0.03},{4,0.03},
		{1,0.05},{2,0.03},{3,0.03},{4,0.03},
		{1,0.05},{2,0.03},{3,0.03},{4,0.03},
		{1,0.05},{2,0.03},{3,0.03},{4,0.03},
		{1,0.05},{2,0.03},{3,0.03},{4,0.03},
		{1,0.05}
	})
	else
		action.frame_sequence = make_frame_data({
			{1,0.05},{2,0.03},{3,0.03},{4,0.03},
			{1,0.05},{2,0.03},{3,0.03},{4,0.03},
			{1,0.05},{2,0.03},{3,0.03},{4,0.03},
			{1,0.05},{2,0.03},{3,0.03},{4,0.03},
			{1,0.05},{2,0.03},{3,0.03},{4,0.03},
			{1,0.05},{2,0.03},{3,0.03},{4,0.03},
			{1,0.05},{2,0.03},{3,0.03},{4,0.03},
			{1,0.05},{2,0.03},{3,0.03},{4,0.03},
			{1,0.05},{2,0.03},{3,0.03},{4,0.03},
			{1,0.05},{2,0.03},{3,0.03},{4,0.03},
			{1,0.05}
		})
	end
	
	action.colour0 = Color.new(0, 30, 0, 255)
	action.colour1 = Color.new(0, 60, 5, 255)
	action.colour2 = Color.new(0, 90, 10, 255)
	action.colour3 = Color.new(0, 120, 15, 255)
	action.colour4 = Color.new(0, 150, 20, 255)
	action.colour5 = Color.new(0, 180, 25, 255)
	action.ocm = agent:sprite():get_color_mode()

	action:override_animation_frames(action.frame_sequence)
	action:set_lockout(make_animation_lockout())

	action.execute_func = function(self, user)

	--com.OFC.block.EXE6-001-SuperArmor by k1rbyat1na
	local super_armor = Battle.DefenseRule.new(1633, DefenseOrder.CollisionOnly)
	super_armor.filter_statuses_func = function(statuses)
		if (statuses.flags & Hit.Stun == Hit.Stun) or (statuses.flags & Hit.Freeze == Hit.Freeze) then
		else
			--print("not flinching")
			statuses.flags = statuses.flags & ~Hit.Flinch
		end
		return statuses
	end

    action.hitprops = HitProps.new(
        props.damage,
        Hit.Impact,
        props.element,
        agent:get_context(),
        Drag.None
    )
    if action.drained == true then action.hitprops.damage = props.damage end
    agent:add_defense_rule(super_armor)
    buster = self:add_attachment("buster")
    buster_anim = buster:get_animation()
    buster_sprite = buster:sprite()
    buster_sprite:set_texture(agent:get_texture(), true)
    buster_sprite:set_layer(-3)
    buster_anim:copy_from(agent:get_animation())
    buster_anim:set_state("BUSTER")
    buster_anim:refresh(buster_sprite)
    buster_anim:set_playback_speed(0)

    -- Green glow logic
    local counter = 0
    local tick = 64
    local original_color_mode = agent:sprite():get_color_mode()

    local function update_color()
        local looped_counter = counter % 30 -- Ensure counter loops between 0 and 29
        if looped_counter >= 0 and looped_counter < 3 then
            agent:set_color(Color.new(0, 30, 0, 255))
        elseif (looped_counter > 2 and looped_counter < 6) or (looped_counter > 26 and looped_counter <= 29) then
            agent:set_color(Color.new(0, 60, 5, 255))
        elseif (looped_counter > 5 and looped_counter < 9) or (looped_counter > 23 and looped_counter < 27) then
            agent:set_color(Color.new(0, 90, 10, 255))
        elseif (looped_counter > 8 and looped_counter < 12) or (looped_counter > 20 and looped_counter < 24) then
            agent:set_color(Color.new(0, 120, 15, 255))
        elseif (looped_counter > 11 and looped_counter < 15) or (looped_counter > 17 and looped_counter < 21) then
            agent:set_color(Color.new(0, 150, 20, 255))
        else
            agent:set_color(Color.new(0, 180, 25, 255))
        end
    end

    local function reset_color()
        agent:set_color(Color.new(0, 0, 0, 255))
        agent:sprite():set_color_mode(original_color_mode)
    end

    local timer = Battle.Component.new(agent, Lifetimes.Battlestep)
    timer.update_func = function()
        if tick <= 0 then
            reset_color()
            timer:eject()
        else
            update_color()
            counter = (counter + 1) % 30 -- Ensure counter loops between 0 and 29
            tick = tick - 1
        end
    end

    agent:register_component(timer)
end

	local function handle_anim_action(agent, buster_anim, buster_sprite, buster_frame, toggle_counter, pew_args)
		if toggle_counter ~= nil then
			agent:toggle_counter(toggle_counter)
		end
		buster_anim:set_playback_speed(1)
		skip_to_frame(buster_sprite, buster_anim, "BUSTER", buster_frame)
		buster_frame = (toggle_counter == false) and 1 or (buster_frame + 1)
		buster_anim:set_playback_speed(0)

		if pew_args then
			pew(agent, pew_args.props, pew_args.action, pew_args.buster_frame)
		end
		return buster_frame
	end

	action:add_anim_action(1, function()
		buster_frame = handle_anim_action(agent, buster_anim, buster_sprite, buster_frame, nil, nil)
	end)

	action:add_anim_action(2, function()
		buster_frame = handle_anim_action(agent, buster_anim, buster_sprite, buster_frame, true, {props = props, action = action, buster_frame = 0})
		play_flare(action) -- Pass the action object explicitly
	end)

	action:add_anim_action(3, function()
		buster_frame = handle_anim_action(agent, buster_anim, buster_sprite, buster_frame, nil, nil)
	end)

	action:add_anim_action(4, function()
		buster_frame = handle_anim_action(agent, buster_anim, buster_sprite, buster_frame, false, nil)
	end)

	action:add_anim_action(5, function()
		buster_frame = handle_anim_action(agent, buster_anim, buster_sprite, buster_frame, nil, nil)
	end)

	action:add_anim_action(6, function()
		buster_frame = handle_anim_action(agent, buster_anim, buster_sprite, buster_frame, true, {props = props, action = action, buster_frame = 1})
		play_flare(action) -- Pass the action object explicitly
	end)

	action:add_anim_action(7, function()
		buster_frame = handle_anim_action(agent, buster_anim, buster_sprite, buster_frame, nil, nil)
	end)

	action:add_anim_action(8, function()
		buster_frame = handle_anim_action(agent, buster_anim, buster_sprite, buster_frame, false, nil)
	end)

	action:add_anim_action(9, function()
		buster_frame = handle_anim_action(agent, buster_anim, buster_sprite, buster_frame, nil, nil)
	end)

	action:add_anim_action(10, function()
		buster_frame = handle_anim_action(agent, buster_anim, buster_sprite, buster_frame, true, {props = props, action = action, buster_frame = 2})
		play_flare(action) -- Pass the action object explicitly
	end)

	action:add_anim_action(11, function()
		buster_frame = handle_anim_action(agent, buster_anim, buster_sprite, buster_frame, nil, nil)
	end)

	action:add_anim_action(12, function()
		buster_frame = handle_anim_action(agent, buster_anim, buster_sprite, buster_frame, false, nil)
	end)

	action:add_anim_action(13, function()
		buster_frame = handle_anim_action(agent, buster_anim, buster_sprite, buster_frame, nil, nil)
	end)

	action:add_anim_action(14, function()
		buster_frame = handle_anim_action(agent, buster_anim, buster_sprite, buster_frame, true, {props = props, action = action, buster_frame = 3})
		play_flare()
	end)

	action:add_anim_action(15, function()
		buster_frame = handle_anim_action(agent, buster_anim, buster_sprite, buster_frame, nil, nil)
	end)

	action:add_anim_action(16, function()
		buster_frame = handle_anim_action(agent, buster_anim, buster_sprite, buster_frame, false, nil)
	end)

	action:add_anim_action(17, function()
		buster_frame = handle_anim_action(agent, buster_anim, buster_sprite, buster_frame, nil, nil)
	end)

	action:add_anim_action(18, function()
		buster_frame = handle_anim_action(agent, buster_anim, buster_sprite, buster_frame, true, {props = props, action = action, buster_frame = 4})
		play_flare()
	end)

	action:add_anim_action(19, function()
		buster_frame = handle_anim_action(agent, buster_anim, buster_sprite, buster_frame, nil, nil)
	end)

	action:add_anim_action(20, function()
		buster_frame = handle_anim_action(agent, buster_anim, buster_sprite, buster_frame, false, nil)
	end)

	action:add_anim_action(21, function()
		buster_frame = handle_anim_action(agent, buster_anim, buster_sprite, buster_frame, nil, nil)
	end)

	action:add_anim_action(22, function()
		buster_frame = handle_anim_action(agent, buster_anim, buster_sprite, buster_frame, true, {props = props, action = action, buster_frame = 5})
		play_flare()
	end)

	action:add_anim_action(23, function()
		buster_frame = handle_anim_action(agent, buster_anim, buster_sprite, buster_frame, nil, nil)
	end)

	action:add_anim_action(24, function()
		buster_frame = handle_anim_action(agent, buster_anim, buster_sprite, buster_frame, false, nil)
	end)

	action:add_anim_action(25, function()
		buster_frame = handle_anim_action(agent, buster_anim, buster_sprite, buster_frame, nil, nil)
	end)

	action:add_anim_action(26, function()
		buster_frame = handle_anim_action(agent, buster_anim, buster_sprite, buster_frame, true, {props = props, action = action, buster_frame = 6})
		play_flare()
	end)

	action:add_anim_action(27, function()
		buster_frame = handle_anim_action(agent, buster_anim, buster_sprite, buster_frame, nil, nil)
	end)

	action:add_anim_action(28, function()
		buster_frame = handle_anim_action(agent, buster_anim, buster_sprite, buster_frame, false, nil)
	end)

	action:add_anim_action(29, function()
		buster_frame = handle_anim_action(agent, buster_anim, buster_sprite, buster_frame, nil, nil)
	end)

	action.action_end_func = function(self)
		buster_anim:set_playback_speed(1)
		agent:toggle_counter(false)
		agent:remove_defense_rule(super_armor)
	end

	return action
end

function skip_to_frame(sprite, anim, state, frame)
-- skip_to_frame() script by Alrysc.
	anim:set_state(state)
	local reached = false
	local completed = false
	if frame == 1 then reached = true end

	anim:on_frame(frame, function()
		reached = true
	end, true)

	anim:on_complete(function()
		completed = true
	end)

	while not reached and not completed
	do
		anim:update(1/60, sprite)
	end

	anim:refresh(sprite)

	return reached
end

function pew(agent, props, action, buster_frame)
    local field = agent:get_field()
    local facing = agent:get_facing()
    local actor_tile = agent:get_current_tile()
    local actor_row = actor_tile:y() -- Get the actor's current row

    -- Find the nearest red team characters
    local all_red_characters = field:find_characters(function(character)
        return character:get_team() == Team.Red
    end)

    -- Define the spawn patterns
    local x_shape_pattern = {
        {6, 1}, {5, 2}, {4, 3}, {6, 3}, {5, 2}, {4, 1}
    }
    local diamond_shape_pattern = {
        {5, 1}, {6, 2}, {5, 3}, {4, 2}
    }

    -- Adjust the spawn pattern if there is an enemy in the same row
    if all_red_characters[1] ~= nil then
        for _, enemy in ipairs(all_red_characters) do
            local enemy_tile = enemy:get_current_tile()
            if enemy_tile:y() == actor_row then
                local enemy_row = enemy_tile:y()
                local row_offset = enemy_row - 2 -- Calculate the offset to shift the pattern

                -- Create copies of the patterns to avoid modifying the originals
                local adjusted_x_shape_pattern = {}
                for _, coords in ipairs(x_shape_pattern) do
                    table.insert(adjusted_x_shape_pattern, {coords[1], math.max(1, math.min(3, coords[2] + row_offset))})
                end

                local adjusted_diamond_shape_pattern = {}
                for _, coords in ipairs(diamond_shape_pattern) do
                    table.insert(adjusted_diamond_shape_pattern, {coords[1], math.max(1, math.min(3, coords[2] + row_offset))})
                end

                -- Use the adjusted patterns
                x_shape_pattern = adjusted_x_shape_pattern
                diamond_shape_pattern = adjusted_diamond_shape_pattern
                break -- Prioritize the first enemy in the same row
            end
        end
    end

    -- Choose the appropriate pattern based on the actor's row
    local spawn_pattern = (actor_row == 2) and x_shape_pattern or diamond_shape_pattern

    -- Use buster_frame to determine the current shot
    local frame_index = (buster_frame - 1) % #spawn_pattern + 1
    local coords = spawn_pattern[frame_index]

    -- Adjust column based on facing direction
    local col = (facing == Direction.Right) and coords[1] or (7 - coords[1])
    local row = coords[2]

    -- Debugging output
    print("buster_frame:", buster_frame)
    print("frame_index:", frame_index)
    print("coords:", coords[1], coords[2])
    print("calculated col:", col, "row:", row)
    print("actor_row:", actor_row)

    -- Get the tile at the calculated position
    local tile = field:tile_at(col, row)
    if tile then
        print("Spawning attack at col:", col, "row:", row)
        field:spawn(create_attack(agent, props, action, buster_frame), tile)
    else
        print("No tile found at col:", col, "row:", row)
    end

    -- Play pew sound
    Engine.play_audio(BUSTER_AUDIO, AudioPriority.High)
end

function create_attack(agent, props, action, buster_frame)
    local spell = Battle.Spell.new(agent:get_team())
	local anim = spell:get_animation()
	spell:highlight_tile(Highlight.Solid)

    local direction = agent:get_facing()
    local field = agent:get_field()

	if buster_frame < 6 then
		spell:set_hit_props(
			HitProps.new(
				props.damage,
				Hit.Impact | Hit.Flinch | Hit.Stun,
				Element.None,
				agent:get_context(),
				Drag.None
			)
		)
	else
		spell:set_hit_props(
			HitProps.new(
				props.damage,
				Hit.Impact | Hit.Flinch | Hit.Flash,
				Element.None,
				agent:get_context(),
				Drag.None
			)
		)
	end
	
    spell.update_func = function(self, dt)
        if self:is_sliding() == false then
            -- Check if the spell is at the edge of the field
            if self:get_current_tile():is_edge() and self.slide_started then
                print("Spell reached the edge of the field and will despawn.")
                self:delete()
                return
            end

            -- Slide the spell to the next tile
            local dest = self:get_tile(direction, 1)
            local ref = self
            self:slide(dest, frames(2), frames(0), ActionOrder.Voluntary, function()
                ref.slide_started = true
            end)
        end

        -- Attack entities on the current tile
        local hit_something = self:get_tile():attack_entities(self)
        if not hit_something and self.slide_started then
            print("Spell hit nothing and will despawn.")
            self:delete()
        end
    end

	spell.can_move_to_func = function(tile)
		return true
	end

    spell.attack_func = function(self, other)
        local tile = agent:get_tile()

		-- Create hit effect
		local fx1 = Battle.Artifact.new()
		fx1:set_offset(0, -25)
		local explosion_texture = Engine.load_texture(_folderpath .. "spell_bullet_hit.png")
		fx1:set_texture(explosion_texture)
		local fx1_anim = fx1:get_animation()
		fx1_anim:load(_folderpath .. "spell_bullet_hit.animation")
		fx1_anim:set_state("HIT")
		fx1_anim:refresh(fx1:sprite())
		fx1:sprite():set_layer(-2)
		fx1_anim:on_complete(function()
			fx1:erase()
		end)
		field:spawn(fx1, self:get_tile():x(), self:get_tile():y())

        self:delete()
    end

    spell.collision_func = function(self, other)
        Engine.play_audio(DAMAGE_AUDIO, AudioPriority.High)

        self:erase()
    end

    spell.battle_end_func = function(self)
        self:erase()
    end



    return spell
end


return cross_barrage