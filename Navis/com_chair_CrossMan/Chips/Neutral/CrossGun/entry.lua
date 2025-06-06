local cross_gun = {}
nonce = function() end

local BUSTER_TEXTURE = Engine.load_texture(_folderpath.."spread_buster.png")
local BURST_TEXTURE = Engine.load_texture(_folderpath.."spread_impact.png")
local AUDIO = Engine.load_audio(_folderpath.."sfx.ogg")

function cross_gun.card_create_action(actor, props)
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

function create_attack(user, props)
	local spell = Battle.Spell.new(user:get_team())
	spell.slide_started = false
	local direction = user:get_facing()
    spell:set_hit_props(
        HitProps.new(
            props.damage, 
            Hit.Impact, 
            Element.None,
            user:get_context(),
            Drag.None
        )
    )
	spell.update_func = function(self, dt) 
        self:get_current_tile():attack_entities(self)
        if self:is_sliding() == false then
            if self:get_current_tile():is_edge() and self.slide_started then 
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
return cross_gun