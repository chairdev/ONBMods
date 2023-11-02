local totalTime = 90 * 60;
local delayFrames = 15;

function package_init(package) 
    package:declare_package_id("com.chairdev.card.Regen90")
    package:set_icon_texture(Engine.load_texture(_modpath.."icon.png"))
    package:set_preview_texture(Engine.load_texture(_modpath.."preview.png"))
	package:set_codes({'E', 'A', 'T'})

    local props = package:get_card_props()
    props.shortname = "Regen90"
    props.damage = 0
    props.time_freeze = false
    props.element = Element.None
    props.description = "Regen HP for 90 secs."
	props.card_class = CardClass.Standard
	props.limit = 5
	props.can_boost = false
end

function card_create_action(actor, props)
    local action = Battle.CardAction.new(actor, "PLAYER_IDLE")

    print("Restoring " .. (totalTime / delayFrames) .. " HP");

    action:set_lockout(make_sequence_lockout())
    action.execute_func = function(self, user)
        local step1 = Battle.Step.new()
        step1.update_func = function(self, dt)
            local recov = create_recov("DEFAULT", user)
            local regen = regen_spell(user)
            actor:get_field():spawn(recov, actor:get_current_tile())
            actor:get_field():spawn(regen, actor:get_current_tile())
            self:complete_step()
        end
        self:add_step(step1)
	end
    return action
end

function create_recov(animation_state, user)
    local spell = Battle.Spell.new(Team.Other)

    spell:set_texture(Engine.load_texture(_modpath.."spell_heal.png"), true)
	spell:set_facing(user:get_facing())
    spell:set_hit_props(
        HitProps.new(
            0,
			Hit.None,
            Element.None,
            user:get_context(),
            Drag.None
        )
    )
	spell:sprite():set_layer(-1)
    local anim = spell:get_animation()
    anim:load(_modpath.."spell_heal.animation")
    anim:set_state(animation_state)
	spell:get_animation():on_complete(
		function()
			spell:erase()
		end
	)

    spell.delete_func = function(self)
		self:erase()
    end

    spell.can_move_to_func = function(tile)
        return true
    end

	Engine.play_audio(Engine.load_audio(_modpath.."sfx.ogg"), AudioPriority.High)

    return spell
end

function regen_spell(user)
    local spell = Battle.Spell.new(Team.Other)
    spell:set_facing(user:get_facing())

    local totalFrames = 0;
    local frameCount = 0

    spell.update_func = function(self, dt)
        frameCount = frameCount + 1
        totalFrames = totalFrames + 1

        if (frameCount >= delayFrames) then
            user:set_health(user:get_health() + 1)
            frameCount = 0
        end

        if (totalFrames >= totalTime) then
            self:delete()
        end
    end

    spell.delete_func = function(self)
		self:erase()
    end
    return spell
end