local BUSTER_TEXTURE = Engine.load_texture(_folderpath.."machgun_buster.png")
local BUSTER_ANIMATION_PATH = _folderpath.."machgun_buster.animation"
local TARGET_TEXTURE = Engine.load_texture(_folderpath.."target.png")
local TARGET_ANIMATION_PATH = _folderpath.."target.animation"
local TILE_HIT_TEXTURE = Engine.load_texture(_folderpath.."tile_hit.png")
local TILE_HIT_ANIMATION_PATH = _folderpath.."tile_hit.animation"
local HURT_SFX = Engine.load_audio(_folderpath.."hurt.ogg")
local GUN_SFX = Engine.load_audio(_folderpath.."gun.ogg")

local aqua_blaster = {}

function package_init(package)
  package:declare_package_id("com.chair.AquaBlst")
  package:set_icon_texture(Engine.load_texture(_folderpath.."icon3.png"))
  package:set_preview_texture(Engine.load_texture(_folderpath.."preview3.png"))
  package:set_codes({'B', 'F', 'M'})

  local props = package:get_card_props()
  props.shortname = "AquaBlst"
  props.damage = 70
  props.time_freeze = false
  props.element = Element.Aqua, Element.Cursor
  props.description = "Fire 9sts at row w/clst enmy"
  props.limit = 3
end

local function spawn_attack(actor, x, y, props)
  local field = actor:get_field()
  local team = actor:get_team()

  local spell = Battle.Spell.new(team)
  spell:set_facing(actor:get_facing())
  spell:sprite():set_layer(-1)
  spell:set_texture(TILE_HIT_TEXTURE, true)

  local anim = spell:get_animation()
  anim:load(TILE_HIT_ANIMATION_PATH)
  anim:set_state("DEFAULT")
  anim:on_complete(function()
    -- When the animation ends, delete this
    spell:delete()
  end)

  anim:refresh(spell:sprite())


  spell:set_hit_props(
    HitProps.new(
      props.damage,
      Hit.Impact | Hit.Flinch,
      props.element,
      actor:get_context(),
      Drag.None
    )
  )

  spell.attacking = true
  spell.on_spawn_func = function()
    Engine.play_audio(GUN_SFX, AudioPriority.Low)

  end
  spell.update_func = function()
    if spell.attacking then 
        spell:get_current_tile():attack_entities(spell)
        spell.attacking = false
    end
  end

  spell.attack_func = function(entity)
    -- if entity:hit(GetHitboxProperties()) then
    Engine.play_audio(HURT_SFX, AudioPriority.Low)
    -- end
  end

  field:spawn(spell, x, y)
end

local function spawn_target(actor, x, y, props)
  local field = actor:get_field()
  local team = actor:get_team()

  local spell = Battle.Spell.new(team)
  spell:set_texture(TARGET_TEXTURE, true)
  spell:sprite():set_layer(-1)
  local anim = spell:get_animation()
  anim:load(TARGET_ANIMATION_PATH)
  anim:set_state("DEFAULT")
  anim:refresh(spell:sprite())

  local ATTACK_INTERVAL = 7
  local next_attack = ATTACK_INTERVAL

  spell.update_func = function()
    next_attack = next_attack - 1

    if next_attack <= 0 then
      spawn_attack(actor, x, y, props)
      spell:hide()
      spell:erase()
    end

    if next_attack == 3 then 
        spell:highlight_tile(Highlight.Solid)
    end
  end

  field:spawn(spell, x, y)
end

local function execute(action, actor, props)
  local machgun = action:add_attachment("Buster")
  machgun:sprite():set_texture(BUSTER_TEXTURE, true)
  machgun:sprite():set_layer(-1)

  local machgun_anim = machgun:get_animation()
  machgun_anim:load(BUSTER_ANIMATION_PATH)
  machgun_anim:set_state("FIRE")

  local field = actor:get_field()
  local target = nil
  local target_tile = nil
  local move_up = true
  local first_spawn = true

  local move_rectical
  move_rectical = function(col_move)
    -- Figure out where our last rectical was
   -- if not target or not target_tile then
     -- return target_tile
    --end

    local char_tile = nil
    if target then 
        char_tile = target:get_current_tile()
    end

   -- if not char_tile then return target_tile end

    local next_tile = nil
    col_move = char_tile and col_move

    if col_move and char_tile:x() ~= target_tile:x() then
      if char_tile:x() < target_tile:x() then
        next_tile = field:tile_at(target_tile:x() - 1, target_tile:y())

        if next_tile:is_edge() then
          next_tile = field:tile_at(target_tile:x() + 1, target_tile:y())
        end

        return next_tile
      elseif char_tile:x() > target_tile:x() then
        next_tile = field:tile_at(target_tile:x() + 1, target_tile:y())

        if next_tile:is_edge() then
          next_tile = field:tile_at(target_tile:x() - 1, target_tile:y())
        end

        return next_tile
      end
    end

    -- If you cannot move left/right keep moving up/down
    local step

    if move_up then
      step = -1
    else
      step = 1
    end

    next_tile = field:tile_at(target_tile:x(), target_tile:y() + step)

    if next_tile:is_edge() then
      move_up = not move_up
      return move_rectical(true)
    else
      return next_tile
    end
  end

  local shoot = function()
    if target == nil or target:will_erase_eof() then
      local closest_distance = math.huge
      local actor_x = actor:get_current_tile():x()
      local actor_team = actor:get_team()
      local facing = actor:get_facing()

      -- find the closest
      field:find_characters(function(character)
        local team = character:get_team()

        -- Get health check matters for in time freeze, just in case
        if character:is_deleted() or team == actor_team or team == Team.Other or character:get_health() == 0 then
          -- not targetable
          return false
        end

        local x = character:get_current_tile():x()
        local distance = x - actor_x

        -- Does not target next to or behind
        if (facing == Direction.Right and distance < 1) or (facing == Direction.Left and distance > -1) then 
            return false
        end

        if actor:get_facing() == Direction.Left then
          distance = -distance
        end

        if distance < closest_distance then
          closest_distance = distance
          target = character
        end

        return false
      end)

      if target then
        local erase_callback = function()
          target = nil
        end

        -- Notify doesn't happn until they are actually gone (we catch exploding viruses)
        field:notify_on_delete(target:get_id(), actor:get_id(), erase_callback)
      end
    end

    if not target_tile and target then
      target_tile = field:tile_at(target:get_current_tile():x(), 3)
    elseif not target_tile and not target then
      -- pick back col
      if actor:get_facing() == Direction.Right then
        target_tile = field:tile_at(field:width(), field:height())
      else
        target_tile = field:tile_at(1, field:height())
      end
    end

    -- We initially spawn the rectical where we want to start
    -- Do note move it around
    if not first_spawn then
      target_tile = move_rectical(false)
    else
      first_spawn = false
    end

    -- Spawn rectical where the target_tile is positioned which will attack for us
    -- Code above shoot in update func handles instead, but I kept this here in case, for next version
    if target_tile then
      spawn_target(actor, target_tile:x(), target_tile:y(), props)
    end
  end

  -- shoots 9 times total


  action:add_anim_action(2, function()
    local counter = -1
    action.update_func = function()
        counter = counter + 1
        if counter % 9 == 0 then 
            if target and (target:is_deleted() or target:get_health() == 0) then 
                target = nil
            end
            shoot()
        end
    end
  end)

end

local WAIT = { 1, 0.0 } -- 0 because engine adds an extra frame to start oops
local FRAME1 = { 1, 0.05 }
local FRAME2 = { 2, 0.033 }

local FRAMES = make_frame_data({
  WAIT,
  FRAME1, FRAME2, FRAME1, FRAME2, FRAME1, FRAME2,
  FRAME1, FRAME2, FRAME1, FRAME2, FRAME1, FRAME2,
  FRAME1, FRAME2, FRAME1, FRAME2, FRAME1, FRAME2,
  FRAME1, FRAME2, FRAME1, FRAME2, FRAME1, FRAME2,
  FRAME1, FRAME2, FRAME1, FRAME2, FRAME1, FRAME2,
  FRAME1, FRAME2, 
})

function aqua_blaster.card_create_action(actor, props)
  local action = Battle.CardAction.new(actor, "PLAYER_SHOOTING")
  action:override_animation_frames(FRAMES)

  action.execute_func = function()
    execute(action, actor, props)
  end

  return action
end
return aqua_blaster