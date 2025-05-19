local cross_barrage = {}

local DAMAGE_AUDIO = Engine.load_audio(_folderpath.."hurt.ogg")
local BUSTER_AUDIO = Engine.load_audio(_folderpath.."pew.ogg")

function cross_barrage.card_create_action(agent,props)

	if props.damage <= 0 then return end
	local super_armour = nil
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

	action:override_animation_frames(action.frame_sequence)
	action:set_lockout(make_animation_lockout())

	action.execute_func = function(self,user)
		super_armour = Battle.DefenseRule.new(1633, DefenseOrder.Always)
			super_armour.filter_statuses_func = function(statuses)
			statuses.flags = statuses.flags & ~Hit.Flinch
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
		agent:add_defense_rule(super_armour)
		buster = self:add_attachment("buster")
		buster_anim = buster:get_animation()
		buster_sprite = buster:sprite()
		buster_sprite:set_texture(agent:get_texture(),true)
		buster_sprite:set_layer(-3)
		buster_anim:copy_from(agent:get_animation())
		buster_anim:set_state("BUSTER")
		buster_anim:refresh(buster_sprite)
		buster_anim:set_playback_speed(0)
	end

	action:add_anim_action(1,function()
		buster_anim:set_playback_speed(1)
		skip_to_frame(buster_sprite, buster_anim, "BUSTER", buster_frame)
		buster_frame = buster_frame+1
		buster_anim:set_playback_speed(0)
	end)

	action:add_anim_action(2, function()
    agent:toggle_counter(true)
    buster_anim:set_playback_speed(1)
    skip_to_frame(buster_sprite, buster_anim, "BUSTER", buster_frame)
    buster_frame = buster_frame + 1
    buster_anim:set_playback_speed(0)
    pew(agent, props, action, 0)
end)

	action:add_anim_action(3,function()
		buster_anim:set_playback_speed(1)
		skip_to_frame(buster_sprite, buster_anim, "BUSTER", buster_frame)
		buster_frame = buster_frame+1
		buster_anim:set_playback_speed(0)
	end)

	action:add_anim_action(4,function()
		agent:toggle_counter(false)
		buster_anim:set_playback_speed(1)
		skip_to_frame(buster_sprite, buster_anim, "BUSTER", buster_frame)
		buster_frame = 1
		buster_anim:set_playback_speed(0)
	end)

	action:add_anim_action(5,function()
		buster_anim:set_playback_speed(1)
		skip_to_frame(buster_sprite, buster_anim, "BUSTER", buster_frame)
		buster_frame = buster_frame+1
		buster_anim:set_playback_speed(0)
	end)

	action:add_anim_action(6,function()
		agent:toggle_counter(true)
		buster_anim:set_playback_speed(1)
		skip_to_frame(buster_sprite, buster_anim, "BUSTER", buster_frame)
		buster_frame = buster_frame+1
		buster_anim:set_playback_speed(0)
		pew(agent,props,action , 1)
	end)

	action:add_anim_action(7,function()
		buster_anim:set_playback_speed(1)
		skip_to_frame(buster_sprite, buster_anim, "BUSTER", buster_frame)
		buster_frame = buster_frame+1
		buster_anim:set_playback_speed(0)
	end)

	action:add_anim_action(8,function()
		agent:toggle_counter(false)
		buster_anim:set_playback_speed(1)
		skip_to_frame(buster_sprite, buster_anim, "BUSTER", buster_frame)
		buster_frame = 1
		buster_anim:set_playback_speed(0)
	end)

	action:add_anim_action(9,function()
		buster_anim:set_playback_speed(1)
		skip_to_frame(buster_sprite, buster_anim, "BUSTER", buster_frame)
		buster_frame = buster_frame+1
		buster_anim:set_playback_speed(0)
	end)

	action:add_anim_action(10,function()
		agent:toggle_counter(true)
		buster_anim:set_playback_speed(1)
		skip_to_frame(buster_sprite, buster_anim, "BUSTER", buster_frame)
		buster_frame = buster_frame+1
		buster_anim:set_playback_speed(0)
		pew(agent,props,action, 2)
	end)

	action:add_anim_action(11,function()
		buster_anim:set_playback_speed(1)
		skip_to_frame(buster_sprite, buster_anim, "BUSTER", buster_frame)
		buster_frame = buster_frame+1
		buster_anim:set_playback_speed(0)
	end)

	action:add_anim_action(12,function()
		agent:toggle_counter(false)
		buster_anim:set_playback_speed(1)
		skip_to_frame(buster_sprite, buster_anim, "BUSTER", buster_frame)
		buster_frame = 1
		buster_anim:set_playback_speed(0)
	end)

	action:add_anim_action(13,function()
		buster_anim:set_playback_speed(1)
		skip_to_frame(buster_sprite, buster_anim, "BUSTER", buster_frame)
		buster_frame = buster_frame+1
		buster_anim:set_playback_speed(0)
	end)

	action:add_anim_action(14,function()
		agent:toggle_counter(true)
		buster_anim:set_playback_speed(1)
		skip_to_frame(buster_sprite, buster_anim, "BUSTER", buster_frame)
		buster_frame = buster_frame+1
		buster_anim:set_playback_speed(0)
		pew(agent,props,action, 3)
	end)

	action:add_anim_action(15,function()
		buster_anim:set_playback_speed(1)
		skip_to_frame(buster_sprite, buster_anim, "BUSTER", buster_frame)
		buster_frame = buster_frame+1
		buster_anim:set_playback_speed(0)
	end)

	action:add_anim_action(16,function()
		agent:toggle_counter(false)
		buster_anim:set_playback_speed(1)
		skip_to_frame(buster_sprite, buster_anim, "BUSTER", buster_frame)
		buster_frame = 1
		buster_anim:set_playback_speed(0)
	end)

	action:add_anim_action(17,function()
		buster_anim:set_playback_speed(1)
		skip_to_frame(buster_sprite, buster_anim, "BUSTER", buster_frame)
		buster_frame = buster_frame+1
		buster_anim:set_playback_speed(0)
	end)

	action:add_anim_action(18,function()
		agent:toggle_counter(true)
		buster_anim:set_playback_speed(1)
		skip_to_frame(buster_sprite, buster_anim, "BUSTER", buster_frame)
		buster_frame = buster_frame+1
		buster_anim:set_playback_speed(0)
		pew(agent,props,action, 4)
	end)

	action:add_anim_action(19,function()
		buster_anim:set_playback_speed(1)
		skip_to_frame(buster_sprite, buster_anim, "BUSTER", buster_frame)
		buster_frame = buster_frame+1
		buster_anim:set_playback_speed(0)
	end)

	action:add_anim_action(20,function()
		agent:toggle_counter(false)
		buster_anim:set_playback_speed(1)
		skip_to_frame(buster_sprite, buster_anim, "BUSTER", buster_frame)
		buster_frame = 1
		buster_anim:set_playback_speed(0)
	end)

	action:add_anim_action(21,function()
		buster_anim:set_playback_speed(1)
		skip_to_frame(buster_sprite, buster_anim, "BUSTER", buster_frame)
		buster_frame = buster_frame+1
		buster_anim:set_playback_speed(0)
	end)

	action:add_anim_action(22,function()
		agent:toggle_counter(true)
		buster_anim:set_playback_speed(1)
		skip_to_frame(buster_sprite, buster_anim, "BUSTER", buster_frame)
		buster_frame = buster_frame+1
		buster_anim:set_playback_speed(0)
		pew(agent,props,action, 5)
	end)

	action:add_anim_action(23,function()
		buster_anim:set_playback_speed(1)
		skip_to_frame(buster_sprite, buster_anim, "BUSTER", buster_frame)
		buster_frame = buster_frame+1
		buster_anim:set_playback_speed(0)
	end)

	action:add_anim_action(24,function()
		agent:toggle_counter(false)
		buster_anim:set_playback_speed(1)
		skip_to_frame(buster_sprite, buster_anim, "BUSTER", buster_frame)
		buster_frame = 1
		buster_anim:set_playback_speed(0)
	end)

	action:add_anim_action(25,function()
		buster_anim:set_playback_speed(1)
		skip_to_frame(buster_sprite, buster_anim, "BUSTER", buster_frame)
		buster_frame = buster_frame+1
		buster_anim:set_playback_speed(0)
	end)

	action:add_anim_action(26,function()
		agent:toggle_counter(true)
		buster_anim:set_playback_speed(1)
		skip_to_frame(buster_sprite, buster_anim, "BUSTER", buster_frame)
		buster_frame = buster_frame+1
		buster_anim:set_playback_speed(0)
		pew(agent,props,action, 6)
	end)

	action:add_anim_action(27,function()
		buster_anim:set_playback_speed(1)
		skip_to_frame(buster_sprite, buster_anim, "BUSTER", buster_frame)
		buster_frame = buster_frame+1
		buster_anim:set_playback_speed(0)
	end)

	action:add_anim_action(28,function()
		agent:toggle_counter(false)
		buster_anim:set_playback_speed(1)
		skip_to_frame(buster_sprite, buster_anim, "BUSTER", buster_frame)
		buster_frame = 1
		buster_anim:set_playback_speed(0)
	end)

	action:add_anim_action(29,function()
		buster_anim:set_playback_speed(1)
		skip_to_frame(buster_sprite, buster_anim, "BUSTER", buster_frame)
		buster_frame = buster_frame+1
		buster_anim:set_playback_speed(0)
	end)

	action.action_end_func = function(self)
		buster_anim:set_playback_speed(1)
		agent:toggle_counter(false)
		agent:remove_defense_rule(super_armour)
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