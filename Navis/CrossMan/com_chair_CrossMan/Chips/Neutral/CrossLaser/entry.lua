local cross_laser = {}

local BUSTER_TEXTURE = Engine.load_texture(_folderpath.."weapon.png")
local BUSTER_ANIMATION_PATH = _folderpath.."weapon.animation"

local HIT 
local BLOCK
local SHOOT
local APPEAR

function package_init(package) 
    package:declare_package_id("com.chair.CrossLaser")
    package:set_icon_texture(Engine.load_texture(_folderpath.."icon.png"))
    package:set_preview_texture(Engine.load_texture(_folderpath.."preview.png"))
	package:set_codes({'M','K','*'})

    local props = package:get_card_props()
    props.shortname = "CrsLaser"
    props.damage = 100
    props.time_freeze = false
    props.element = Element.None
    props.description = "Narrow Spark ahead!"

end

local WAIT = { 1, 0.0 } -- 0 because engine adds an extra frame to start oops
local FRAME1 = { 1, 0.05*16 }
local FRAME2 = { 2, 0.033 }

local FRAMES2 = make_frame_data({
  WAIT,
  FRAME1, FRAME2, FRAME1, FRAME2, FRAME1, FRAME2,
  FRAME1, FRAME2, FRAME1, FRAME2, FRAME1, FRAME2,
  FRAME1, FRAME2, FRAME1, FRAME2, FRAME1, FRAME2,
  FRAME1, FRAME2, FRAME1, FRAME2, FRAME1, FRAME2,
  FRAME1, FRAME2, FRAME1, FRAME2, FRAME1, FRAME2,
  FRAME1, FRAME2, 
})

local FRAMES = make_frame_data({
    WAIT,
    FRAME1, FRAME2, 
  })


function cross_laser.card_create_action(user, props)
    local field = user:get_field()
    local action = Battle.CardAction.new(user, "PLAYER_SHOOTING")
    action:override_animation_frames(FRAMES)

    local raygun = action:add_attachment("Buster")
    raygun:sprite():set_texture(BUSTER_TEXTURE, true)
    raygun:sprite():set_layer(-1)

    local raygun = raygun:get_animation()
    raygun:load(BUSTER_ANIMATION_PATH)
    raygun:set_state("DEFAULT")

    local function graphic_init(type, x, y, texture, animation, layer, state, user, facing, delete_on_complete, flip)
        flip = flip or false
        delete_on_complete = delete_on_complete or false
        facing = facing or nil
        
        local graphic = nil
        if type == "artifact" then 
            graphic = Battle.Artifact.new()

        elseif type == "spell" then 
            graphic = Battle.Spell.new(user:get_team())
        
        elseif type == "obstacle" then 
            graphic = Battle.Obstacle.new(user:get_team())

        end

        graphic:sprite():set_layer(layer)
        graphic:never_flip(flip)
        graphic:set_texture(Engine.load_texture(_folderpath..texture), false)
        if facing then 
            graphic:set_facing(facing)
        end
        
        if user:get_facing() == Direction.Left then 
            x = x * -1
        end
        graphic:set_offset(x, y)
        local anim = graphic:get_animation()
        anim:load(_folderpath..animation)

        anim:set_state(state)
        anim:refresh(graphic:sprite())

        if delete_on_complete then 
            anim:on_complete(function()
                graphic:delete()
            end)
        end

        return graphic
    end

    local ending = false

    local spell_list = {}

    local function extra_laser(user, tile, facing, elevation, hit_props)
        if not tile or tile:is_edge() then 
            return 
        end
        local spell = graphic_init("spell", 0, 0, "laser.png", "laser.animation", -4, "LASER", user, facing)
        spell:highlight_tile(Highlight.Solid)
        spell:set_elevation(elevation)
        spell:set_hit_props(hit_props)


        local anim = spell:get_animation()
        anim:on_frame(2, function()
            extra_laser(user, spell:get_tile(facing, 1), facing, elevation, hit_props)

        end)
        local fade = false
        spell.update_func = function(self)
            if not fade then 
                if ending == true then 
                    anim:set_state("LASER_END")
                    anim:refresh(self:sprite())

                    fade = true
                end

            end

            self:get_tile():attack_entities(self)

        end

        spell.attack_func = function()
            Engine.play_audio(HIT, AudioPriority.Low)
        end

        spell_list[#spell_list+1] = spell
        field:spawn(spell, tile)
    end

    local function shoot_laser(user, starting_tile, facing, elevation)
        local spell = graphic_init("spell", 0, 0, "laser.png", "laser.animation", -4, "LASER_START", user, facing, true)
        spell:highlight_tile(Highlight.Solid)
        spell:set_elevation(elevation)

        local hit_props = HitProps.new(props.damage,
                                    Hit.Impact | Hit.Flinch | Hit.Flash,
                                    props.element, user:get_context(), Drag.None)

        local anim = spell:get_animation()
        spell:set_hit_props(hit_props)

        anim:on_frame(7, function()
            extra_laser(user, spell:get_tile(facing, 1), facing, elevation, hit_props)
        end)

        anim:on_frame(8, function()
            ending = true
        
        end)

        anim:on_frame(13, function()
            spell:highlight_tile(Highlight.None)

        end)

        anim:on_frame(14, function()
            spell:highlight_tile(Highlight.None)
            stop = true
            spell:delete()

            for i=1, #spell_list
            do
                local spell = spell_list[i]
                if spell and not spell:is_deleted() then 
                    spell:delete()
                end
            end
        end)


        local stop = false

        spell.update_func = function(self)
            if not stop then 
                self:get_tile():attack_entities(self)
            end

        end

        spell.attack_func = function()
            Engine.play_audio(HIT, AudioPriority.Low)
        end

        field:spawn(spell, starting_tile)
    end

    action.execute_func = function()
        actor = action:get_actor()

        HIT = Engine.load_audio(_folderpath .. "hit.ogg")
        BLOCK = Engine.load_audio(_folderpath .. "tink.ogg")
        SHOOT = Engine.load_audio(_folderpath .. "beam.ogg")
        APPEAR = Engine.load_audio(_folderpath .. "appear.ogg")

        shoot_laser(user, user:get_current_tile():get_tile(user:get_facing(), 1), user:get_facing(), 20)
        Engine.play_audio(SHOOT, AudioPriority.Low)
    end

    return action
end
return cross_laser