local cross_shield = {}
local DAMAGE = 60
local STATE = "METGUARD1"

local TEXTURE_SHIELD = Engine.load_texture(_folderpath.."shield.png")
local TEXTURE_HIT = Engine.load_texture(_folderpath.."hit.png")
local TEXTURE_HITWAVE = Engine.load_texture(_folderpath.."hitwave.png")
local ANIMPATH_SHIELD = _folderpath.."shield.animation"
local ANIMPATH_HIT = _folderpath.."hit.animation"
local ANIMPATH_HITWAVE = _folderpath.."hitwave.animation"
local AUDIO_SHIELD = Engine.load_audio(_folderpath.."shield.ogg")
local AUDIO_HIT = Engine.load_audio(_folderpath.."hit.ogg")
local AUDIO_DAMAGE = Engine.load_audio(_folderpath.."hitsound.ogg")

function package_init(package)
    package:declare_package_id("com.k1rbyat1na.card.EXE6-091-ReflecMet1")
    package:set_icon_texture(Engine.load_texture(_folderpath.."icon.png"))
    package:set_preview_texture(Engine.load_texture(_folderpath.."preview.png"))
	package:set_codes({"A","C","P","*"})

    local props = package:get_card_props()
    props.shortname = "RflecMt1"
    props.damage = DAMAGE
    props.time_freeze = false
    props.element = Element.None
    props.description = "Bounce an attk back at them!"
    props.long_description = "Guard against enemy attacks and bounce them back!"
    props.can_boost = true
	props.limit = 5
end

function cross_shield.card_create_action(user,props)
    local action = Battle.CardAction.new(user, "PLAYER_SHOOTING")
	action:set_lockout(make_animation_lockout())
    local GUARDING = {1, 1.024}
    local POST_GUARD = {1, 0.224} 
	local FRAMES = make_frame_data({GUARDING,POST_GUARD})
    action.action_end_func = function()
        user:remove_defense_rule(action.guarding_defense_rule)
    end
    action:override_animation_frames(FRAMES)

    action.execute_func = function(self, user)
        local direction = user:get_facing()
        local field = user:get_field()
        local team = user:get_team()
        local usertile = user:get_current_tile()

        local guarding = false
        local shield_attachment = self:add_attachment("BUSTER")
        local shield_sprite = shield_attachment:sprite()
        shield_sprite:set_texture(TEXTURE_SHIELD)
        shield_sprite:set_layer(-2)

        local shield_animation = shield_attachment:get_animation()
        shield_animation:load(ANIMPATH_SHIELD)
        shield_animation:set_state(STATE)

        action.guarding_defense_rule = Battle.DefenseRule.new(0,DefenseOrder.Always)

		self:add_anim_action(1,function()
			guarding = true
            Engine.play_audio(AUDIO_SHIELD, AudioPriority.Highest)
		end)
		self:add_anim_action(2,function()
			shield_animation:set_state("FADE")
			guarding = false
            user:remove_defense_rule(action.guarding_defense_rule)
		end)

        action.guarding_defense_rule.can_block_func = function(judge, attacker, defender)
            if not guarding then 
                return 
            end
            local attacker_hit_props = attacker:copy_hit_props()
            if attacker_hit_props.damage > 0 then
                if attacker_hit_props.flags & Hit.Breaking == Hit.Breaking then
                    return
                end
                judge:block_impact()
                judge:block_damage()
                Engine.play_audio(AUDIO_HIT, AudioPriority.High)
                local reflected_damage = props.damage
                if not action.guarding_defense_rule.has_reflected then
                    local hitfx = Battle.Artifact.new()
                    hitfx:set_texture(TEXTURE_HIT,true)
                    hitfx:set_facing(direction)
                    hitfx:set_offset(0,-30)
                    local fxanim = hitfx:get_animation()
                    local fxsprite = hitfx:sprite()
                    fxanim:load(ANIMPATH_HIT)
                    fxanim:set_state("0")
                    fxanim:refresh(fxsprite)
                    fxanim:on_complete(function()
                        hitfx:delete()
                    end)
                    user:get_field():spawn(hitfx,user:get_current_tile())
                    spawn_hitwave(user,team,field,user:get_tile(direction, 1),direction,reflected_damage,props.element,TEXTURE_HITWAVE,0.2)
                    action.guarding_defense_rule.has_reflected = true
                end
            end
        end
        user:add_defense_rule(action.guarding_defense_rule)
    end

    return action
end

function spawn_hitwave(actor,team,field,tile,direction,damage,element,wave_texture,frame_time)
    local spawn_next
    spawn_next = function()
        if tile:is_edge() then return end

        local spell = Battle.Spell.new(team)
        spell:set_facing(direction)
        spell:set_hit_props(
            HitProps.new(
                damage, 
                Hit.Impact, 
                element, 
                actor:get_context(), 
                Drag.None
            )
        )
        local sprite = spell:sprite()
        sprite:set_texture(wave_texture)

        local animation = spell:get_animation()
        animation:load(ANIMPATH_HITWAVE)
        animation:set_state("0")
        animation:refresh(sprite)
        animation:on_frame(3, function()
            tile = tile:get_tile(direction, 1)
            spawn_next()
        end, true)
        animation:on_complete(function() spell:erase() end)

        spell.update_func = function()
            spell:get_current_tile():attack_entities(spell)
        end

        spell.attack_func = function()
            Engine.play_audio(AUDIO_DAMAGE, AudioPriority.Highest)
        end

        field:spawn(spell, tile)
    end

    spawn_next()
end
return cross_shield