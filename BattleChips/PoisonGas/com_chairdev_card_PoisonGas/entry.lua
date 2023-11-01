nonce = function() end

local TEXTURE = Engine.load_texture(_modpath.."gas.png")

function package_init(package) 
    package:declare_package_id("com.chairdev.card.PoisonGas")
    package:set_icon_texture(Engine.load_texture(_modpath.."icon.png"))
    package:set_preview_texture(Engine.load_texture(_modpath.."preview.png"))
	package:set_codes({'*'})

    local props = package:get_card_props()
    props.shortname = "PoisnGas"
    props.damage = 0
    props.time_freeze = true
    props.element = Element.Summon
    props.description = "Place a Rockgas in front"
	props.can_boost = false
end

function card_create_action(actor, props)
    print("in create_card_action()!")
    local action = Battle.CardAction.new(actor, "PLAYER_IDLE")
	action:set_lockout(make_sequence_lockout())
    action.execute_func = function(self, user)
        print("in custom card action execute_func()!")		
		local step1 = Battle.Step.new()
		local gas = Battle.Obstacle.new(Team.Other)
		local do_once = true
		step1.update_func = function(self, dt)
			if do_once then
				do_once = false
				gas:set_facing(user:get_facing())
				gas:set_texture(TEXTURE, true)
				local anim = gas:get_animation()
				anim:load(_modpath.."gas.animation")
				anim:set_state("SPAWN")
				anim:refresh(gas:sprite())
				anim:on_complete(function()
					local tile = gas:get_tile()
					if tile:is_walkable() and not tile:is_reserved({}) then
						anim:set_state("DEFAULT")
						anim:refresh(gas:sprite())
						anim:set_playback(Playback.Loop)
					else
						gas:delete()
					end
				end)
				gas:set_health(200)

				-- deletion process var
				local delete_self = nil
				local spawned_hitbox = false
				local countdown = 6000
				-- slide tracker
				local continue_slide = false
				local prev_tile = {}
				local gas_speed = 4

				-- define gas collision hitprops
				local props = HitProps.new(
					200,
					Hit.Impact | Hit.Flinch | Hit.Flash | Hit.Breaking, 
					Element.Break,
					user:get_context(),
					Drag.None
				)


				-- upon tangible collision
				gas.collision_func = function(self)
					-- define the hitbox with its props every frame
					local hitbox = Battle.Hitbox.new(gas:get_team())
					hitbox:set_hit_props(props)

					if not spawned_hitbox then
						gas:get_field():spawn(hitbox, gas:get_current_tile())
						spawned_hitbox = true
					end
					gas.delete_func()
				end
				-- upon passing the defense check
				gas.attack_func = function(self)
				end

				gas.can_move_to_func = function(tile)
					if tile then
						-- get a list of every obstacle with Team.Other on the field
						local field = gas:get_field()
						local gas_team = gas:get_team()
						local Other_obstacles = function(obstacle)
							return obstacle:get_team() == gas_team
						end
						local obstacles_here = field:find_obstacles(Other_obstacles)
						local donotmove = false
						-- look through the list of obstacles and read their tile position, check if we're trying to move to their tile.
						for ii=1,#obstacles_here do
							if tile == obstacles_here[ii]:get_tile() then
								donotmove = true
							end
						end

						if tile:is_edge() or donotmove or not tile:is_walkable() then
							return false
						end
					end
					return true
				end
				gas.update_func = function(self, dt)
					local tile = gas:get_current_tile()
					if not tile then
						gas.delete_func()
					end
					if tile:is_edge() then
						gas.delete_func()
					end
					if not delete_self then
						tile:attack_entities(gas)
					end
					local direction = self:get_facing()
					if self:is_sliding() then
						table.insert(prev_tile,1, tile)
						prev_tile[gas_speed+1] = nil
						local target_tile = tile:get_tile(direction, 1)
						if self.can_move_to_func(target_tile) then
							continue_slide = true
						else
							continue_slide = false
						end
					else
						-- become aware of which direction you just moved in, turn to face that direction
						if prev_tile[gas_speed] then
							if prev_tile[gas_speed]:get_tile(direction, 1):x() ~= tile:x() then
								direction = self:get_facing_away()
								self:set_facing(direction)
							end
						end
					end
					if not self:is_sliding() and continue_slide then
						self:slide(self:get_tile(direction, 1), frames(gas_speed), frames(0), ActionOrder.Voluntary, function() end)
					end
					if self:get_health() <= 0 then
						gas.delete_func()
					end
					if countdown > 0 then countdown = countdown - 1 else gas.delete_func() end
					
					-- deletion handler in main loop, starts running once something in here has requested deletion
					if delete_self then
						if type(delete_self) ~= "number" then
							delete_self = 2
						end
						if delete_self > 0 then
							delete_self = delete_self - 1
						elseif delete_self == 0 then
							delete_self = -1
							self:erase()
						end
					end
				end
				gas.delete_func = function(self)
					if type(delete_self) ~= "number" then
						delete_self = true
					end
				end
				local query = function(ent)
					return Battle.Obstacle.from(ent) ~= nil or Battle.Character.from(ent) ~= nil
				end
				local desired_tile = user:get_tile(user:get_facing(), 1)
				if #desired_tile:find_entities(query) == 0 and not desired_tile:is_edge() then
					user:get_field():spawn(gas, user:get_tile(user:get_facing(), 1))
				end
				self:complete_step()
			end
		end
		self:add_step(step1)
	end
    return action
end