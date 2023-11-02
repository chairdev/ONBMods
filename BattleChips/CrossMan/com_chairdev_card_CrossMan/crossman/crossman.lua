local DAMAGE = 150
--local AUDIO_DAMAGE = Engine.load_audio(_folderpath.."hitsound.ogg")
--local AUDIO_DAMAGE_OBS = Engine.load_audio(_folderpath.."hitsound_obs.ogg")

local CROSSMAN_TEXTURE = Engine.load_texture(_folderpath.."crossman.png")
local CROSSMAN_ANIMPATH = _folderpath.."crossman.animation"
local AUDIO_SPAWN = Engine.load_audio(_folderpath.."exe6-spawn.ogg")

local BUSTER_TEXTURE = Engine.load_texture(_folderpath.."spread_buster.png")
local BURST_TEXTURE = Engine.load_texture(_folderpath.."spread_impact.png")
local AUDIO = Engine.load_audio(_folderpath.."sfx.ogg")

local SUCCESS_AUDIO = Engine.load_audio(_folderpath.."input.ogg", true)

local field = nil
local doneWithInput = false
local doneWithAttack = false
local chosenTile = nil

local up = false
local down = false
local left = false
local right = false

local crossman = {
    codes = {"C","*"},
    shortname = "CrossMan",
    damage = DAMAGE,
    time_freeze = true,
    element = Element.None,
    description = "Warp in and slice the enemy",
    long_description = "Warp in front of the enemy and slice it, even where you can't warp",
    can_boost = true,
    card_class = CardClass.Mega,
    limit = 2
}



crossman.card_create_action = function(actor, props)
    print("in create_card_action()!")
	local action = Battle.CardAction.new(actor, "PLAYER_IDLE")

    action:set_lockout(make_sequence_lockout())

    action.execute_func = function(self, user)
        local actor = self:get_actor()
		actor:hide()

        field = user:get_field()
        local facing = user:get_facing()

        local step1 = Battle.Step.new() --Choose Tile
		local step2 = Battle.Step.new() --Spawn CrossMan
        local step3 = Battle.Step.new() --Shoot down Current Row
        local step4 = Battle.Step.new() --Delete CrossMan

        crossmanArtifact = nil
        local originalTile = user:get_current_tile()
        chosenTile = user:get_current_tile()

        -- first method 
        local entityFilter = function( character, tile ) 
            return character:get_current_tile() == chosenTile
        end 

        local ref = self

        local do_once = true
        local hasMoved = false
        local delay = 30
        local currentDelay = delay

        doneWithAttack = false
        doneWithInput = false


        step1.update_func = function(self, dt)
            up = user:input_has(Input.Pressed.Up)
            down = user:input_has(Input.Pressed.Down)
            left = user:input_has(Input.Pressed.Left)
            right = user:input_has(Input.Pressed.Right)

            if do_once then
                do_once = false
                print("in chooseTile update_func")
                user:toggle_hitbox(false) 
                tile_highlight(actor)
            end
            if doneWithInput then
                print("done with input")
                print("chosenTile is ", chosenTile:x(), chosenTile:y())
                print("originalTile is ", originalTile:x(), originalTile:y())
                
                local entities = field:find_characters( entityFilter, chosenTile ) 

                if chosenTile and not chosenTile:is_edge() and #entities == 0 then
                    print("tile is not reserved")
                    Engine.play_audio(SUCCESS_AUDIO, AudioPriority.High)
                else
                    print("tile is reserved")
                    chosenTile = originalTile
                end
                
                do_once = true
                step1:complete_step()
            end
        end


        step2.update_func = function(self, dt)
            if do_once then
                do_once = false
                crossmanArtifact = Battle.Artifact.new()
                crossmanArtifact:set_facing(facing)
                local crossman_sprite = crossmanArtifact:sprite()
		    	crossman_sprite:set_texture(CROSSMAN_TEXTURE, true)
		    	crossman_sprite:set_layer(-3)
                local crossman_anim = crossmanArtifact:get_animation()
                crossman_anim:load(CROSSMAN_ANIMPATH)
                crossman_anim:set_state("PLAYER_MOVE")
                crossman_anim:refresh(crossman_sprite)
                crossman_anim:set_playback(Playback.Once)
                crossman_anim:on_frame(2, function()
                    Engine.play_audio(AUDIO_SPAWN, AudioPriority.High)
                end)
                crossman_anim:on_frame(7, function()
                    print("end of spawn anim")
                end)
                field:spawn(crossmanArtifact, chosenTile)
            end
            if currentDelay == 0 then
                print("currentDelay is 0")
                do_once = true
                step2:complete_step()
            else
                currentDelay = currentDelay - 1
            end
            
        end

        --shoot down row
        step3.update_func = function(self, dt)
            if do_once then
                do_once = false

                local crossman_anim = crossmanArtifact:get_animation()
                crossman_anim:set_state("PLAYER_SHOOTING")
                crossman_anim:set_playback(Playback.Once)

                -- local buster = crossmanArtifact:add_attachment("BUSTER")
                -- buster:sprite():set_texture(BUSTER_TEXTURE, true)
                -- buster:sprite():set_layer(-1)
                
                -- local buster_anim = buster:get_animation()
                -- buster_anim:load(_folderpath.."spread_buster.animation")
                -- buster_anim:set_state("DEFAULT")

                local cannonshot = create_attack(crossmanArtifact, props)
                local tile = crossmanArtifact:get_tile(crossmanArtifact:get_facing(), 1)
                field:spawn(cannonshot, tile)
            end
            if doneWithAttack then
                print("done with laser")
                do_once = true
                step3:complete_step()
            end
        end

        step4.update_func = function(self, dt)
            if do_once and crossmanArtifact:is_deleted() == false then
                do_once = false
                print("in delStep update_func")
                local crossman_sprite = crossmanArtifact:sprite()
                local crossman_anim = crossmanArtifact:get_animation()
                crossman_anim:load(CROSSMAN_ANIMPATH)
                crossman_anim:set_state("PLAYER_MOVE")
                crossman_anim:refresh(crossman_sprite)
                crossman_anim:set_playback(Playback.Once)
                crossman_anim:on_frame(2, function()
                    Engine.play_audio(AUDIO_SPAWN, AudioPriority.High)
                end)
                crossman_anim:on_frame(7, function()
                    hasMoved = true
                end)
            end
            if hasMoved and crossmanArtifact:is_deleted() == false then
                crossmanArtifact:erase()
                do_once = true
                user:toggle_hitbox(true) 
                step4:complete_step()
            end
        end


        self:add_step(step1)
        self:add_step(step2)
        self:add_step(step3)
        self:add_step(step4)

    end

    action.action_end_func = function(self)
		actor:reveal()
	end
	return action
end

function _card_create_action(actor, props)
    print("in create_card_action()!")
    local action = Battle.CardAction.new(actor, "PLAYER_SHOOTING")
	
	action:set_lockout(make_animation_lockout())

    action.execute_func = function(self, user)
		local buster = self:add_attachment("BUSTER")
		buster:sprite():set_texture(BUSTER_TEXTURE, true)
		buster:sprite():set_layer(-1)
		
		local buster_anim = buster:get_animation()
		buster_anim:load(_folderpath.."spread_buster.animation")
		buster_anim:set_state("DEFAULT")
		
		local cannonshot = create_attack(user, props)
		local tile = user:get_tile(user:get_facing(), 1)
		actor:get_field():spawn(cannonshot, tile)
	end
    return action
end

function tile_highlight(user)
    local spell = Battle.Spell.new(user:get_team())
    spell:highlight_tile(Highlight.Flash)

    field:spawn(spell, user:get_current_tile())

    local remainingTime = 30 --30 frames to choose a tile
	
    spell.update_func = function(self, dt)
        if up then
            print("up pressed")
            local dest = self:get_tile(Direction.Up, 1)
            self:teleport(dest, ActionOrder.Voluntary, nil)
        end
        if down then
            print("down pressed")
            local dest = self:get_tile(Direction.Down, 1)
            self:teleport(dest, ActionOrder.Voluntary, nil)
        end
        if left then
            print("left pressed")
            local dest = self:get_tile(Direction.Left, 1)
            self:teleport(dest, ActionOrder.Voluntary, nil)
        end
        if right then
            print("right pressed")
            local dest = self:get_tile(Direction.Right, 1)
            self:teleport(dest, ActionOrder.Voluntary, nil)
        end

        if remainingTime == 0 then
            spell:delete()
        else
            remainingTime = remainingTime - 1
        end
    end

    spell.can_move_to_func = function(actor, next_tile)
        return true
    end

    spell.delete_func = function(self)
        chosenTile = self:get_current_tile()
        doneWithInput = true
    end

    return spell
end

function create_attack(user, props)
	local spell = Battle.Spell.new(user:get_team())
	spell.slide_started = false
	local direction = user:get_facing()
    spell:set_hit_props(
        HitProps.new(
            props.damage, 
            Hit.Impact | Hit.Flinch | Hit.Drag, 
            Element.None,
            user:get_context(),
            Drag.new(direction, 1)
        )
    )
	spell.update_func = function(self, dt) 
        self:get_current_tile():attack_entities(self)
        print(self:get_current_tile():x(), self:get_current_tile():y())
        if self:is_sliding() == false then
            if self:get_current_tile():is_edge() and self.slide_started then 
                doneWithAttack = true
                self:delete()
            end 
			
            local dest = self:get_tile(direction, 1)
            local ref = self
            self:slide(dest, frames(1), frames(0), ActionOrder.Voluntary, 
                function()
                    ref.slide_started = true 
                end
            )
        end
    end
	spell.collision_func = function(self, other)
		local fx = Battle.Artifact.new()
		fx:set_texture(BURST_TEXTURE, true)
		fx:get_animation():load(_folderpath.."spread_impact.animation")
		fx:get_animation():set_state("DEFAULT")
		fx:get_animation():on_complete(function()
			fx:erase()
		end)
		fx:set_height(-16.0)
		local tile = self:get_current_tile()
		if tile and not tile:is_edge() then
			spell:get_field():spawn(fx, tile)
		end
	end
    spell.attack_func = function(self, other) 
		local fx2 = Battle.Artifact.new()
		fx2:set_texture(BURST_TEXTURE, true)
		fx2:get_animation():load(_folderpath.."spread_impact.animation")
		fx2:get_animation():set_state("DEFAULT")
		fx2:get_animation():on_complete(function()
			fx2:erase()
		end)
		
		local tile2 = self:get_current_tile():get_tile(direction, 1):get_tile(Direction.Up, 1)
		if tile2 and not tile2:is_edge() then
			spell:get_field():spawn(fx2, tile2)
			tile2:attack_entities(self)
		end
		
		local fx3 = Battle.Artifact.new()
		fx3:set_texture(BURST_TEXTURE, true)
		fx3:get_animation():load(_folderpath.."spread_impact.animation")
		fx3:get_animation():set_state("DEFAULT")
		fx3:get_animation():on_complete(function()
			fx3:erase()
		end)
		
		local tile3 = self:get_current_tile():get_tile(direction, 1):get_tile(Direction.Down, 1)
		if tile3 and not tile3:is_edge() then
			spell:get_field():spawn(fx3, tile3)
			tile3:attack_entities(self)
		end
		
		local fx4 = Battle.Artifact.new()
		fx4:set_texture(BURST_TEXTURE, true)
		fx4:get_animation():load(_folderpath.."spread_impact.animation")
		fx4:get_animation():set_state("DEFAULT")
		fx4:get_animation():on_complete(function()
			fx4:erase()
		end)
		
		local tile4 = self:get_current_tile():get_tile(Direction.reverse(direction), 1):get_tile(Direction.Down, 1)
		if tile4 and not tile4:is_edge() then
			spell:get_field():spawn(fx4, tile4)
			tile4:attack_entities(self)
		end
		
		local fx5 = Battle.Artifact.new()
		fx5:set_texture(BURST_TEXTURE, true)
		fx5:get_animation():load(_folderpath.."spread_impact.animation")
		fx5:get_animation():set_state("DEFAULT")
		fx5:get_animation():on_complete(function()
			fx5:erase()
		end)
		
		local tile5 = self:get_current_tile():get_tile(Direction.reverse(direction), 1):get_tile(Direction.Up, 1)
		if tile5 and not tile5:is_edge() then
			spell:get_field():spawn(fx5, tile5)
			tile5:attack_entities(self)
		end
		
        doneWithAttack = true
		self:erase()
    end

    spell.delete_func = function(self)
		self:erase()
    end

    spell.can_move_to_func = function(tile)
        return true
    end

	Engine.play_audio(AUDIO, AudioPriority.High)
	return spell
end

return crossman