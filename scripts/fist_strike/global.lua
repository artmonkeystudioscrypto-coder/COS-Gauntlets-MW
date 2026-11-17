-- fist_strike/global.lua
--
-- Receives 'FistStrike_Landed' from a victim's actor script, looks at the
-- attacker's gauntlets, and if one carries a Cast-on-Strike enchantment with
-- enough charge, applies that enchantment to the victim and drains the charge.
--
-- Prototype rules (from brainstorm):
--   * fires on EVERY successful unarmed hit, fatigue-only hits included
--   * left or right gauntlet both count; if both are enchanted, whichever
--     still has charge fires (left first); each gauntlet fires at most once per hit
--   * bracers and gloves count too (anything in the gauntlet slots)

local core  = require('openmw.core')
local types = require('openmw.types')

local Actor = types.Actor
local SLOTS = { Actor.EQUIPMENT_SLOT.LeftGauntlet, Actor.EQUIPMENT_SLOT.RightGauntlet }

local DEBUG = false

-- Balance knobs
-- If the hand whose turn it is has nothing to fire, let the other hand fire instead.
-- false = strict alternation (one enchanted gauntlet fires every other punch).
local FALLBACK_TO_OTHER_HAND = false
local nextHand = {}   -- attacker.id -> 1 (left) or 2 (right); which hand punches next
local function log(msg)
    if DEBUG then print('[fist_strike] ' .. msg) end
end

-- Returns the Enchantment record if this item is Cast-on-Strike, else nil.
local function strikeEnchantment(item)
    if not item then return nil end
    local rec = item.type.record(item)
    if not rec or not rec.enchant or rec.enchant == '' then return nil end
    local ench = core.magic.enchantments.records[rec.enchant]
    if not ench then return nil end
    if ench.type ~= core.magic.ENCHANTMENT_TYPE.CastOnStrike then return nil end
    return ench
end

-- Mirror what the engine does for a real spell hit (spellcasting.cpp playEffects):
-- per effect, play its hit sound (or the school's hit sound) and its hit VFX
-- static (or VFX_DefaultHit) on the victim. activeSpells:add does none of this.
local function playHitEffects(victim, ench)
    for _, ep in ipairs(ench.effects) do
        local mgef = ep.effect
        if mgef then
            local sound = mgef.hitSound
            if (not sound or sound == '') and mgef.school then
                local skill = core.stats.Skill.records[mgef.school]
                sound = skill and skill.school and skill.school.hitSound
            end
            if sound and sound ~= '' then
                victim:sendEvent('PlaySound3d', { sound = sound })
            end
            log(string.format('fx %s: sound=%s static=%s', mgef.id, tostring(sound),
                tostring((mgef.hitStatic and mgef.hitStatic ~= '') and mgef.hitStatic or 'VFX_DefaultHit')))

            local staticId = (mgef.hitStatic and mgef.hitStatic ~= '') and mgef.hitStatic or 'VFX_DefaultHit'
            local static = types.Static.records[staticId]
            if static and static.model and static.model ~= '' then
                victim:sendEvent('AddVfx', { model = static.model, options = {
                    particleTextureOverride = mgef.particle,
                    loop = mgef.continuousVfx,
                    vfxId = 'fist_strike_' .. mgef.id,
                } })
            end
        end
    end
end

local function fireGauntlet(attacker, victim, item, ench)
    local data = types.Item.itemData(item)
    local charge = data.enchantmentCharge
    if charge == nil then charge = ench.charge end           -- never used = full
    if charge < ench.cost then
        log(string.format('%s: charge %.0f < cost %d, no cast', item.recordId, charge, ench.cost))
        return false
    end

    -- Build the list of effect indexes. Enchantment effects are indexed from 0.
    local idx = {}
    for i, _ in ipairs(ench.effects) do idx[#idx + 1] = i - 1 end

    Actor.activeSpells(victim):add({
        id      = item.recordId,   -- activeSpells:add takes the enchanted ITEM's record id
        effects = idx,
        caster  = attacker,
        item    = item,
        name    = item.type.record(item).name,
        stackable = true,   -- weapon on-strike hits stack in vanilla; match that
    })

    data.enchantmentCharge = charge - ench.cost
    playHitEffects(victim, ench)
    log(string.format('%s -> %s : cast %s (%d effects), charge %.0f -> %.0f',
        attacker.recordId, victim.recordId, ench.id, #idx, charge, charge - ench.cost))
    return true
end

local function onFistStrikeLanded(e)
    local attacker, victim = e.attacker, e.victim
    if not attacker or not victim or not attacker:isValid() or not victim:isValid() then return end

    -- Belt and braces: the actor script already filtered on "no weapon", but
    -- re-check from the global side so a stale event can't fire the gauntlets.
    local weapon = Actor.getEquipment(attacker, Actor.EQUIPMENT_SLOT.CarriedRight)
    if weapon and types.Weapon.objectIsInstance(weapon) then return end

    -- Balance rule: punches alternate hands, one gauntlet per punch.
    -- The engine does not tell us which fist landed, so we keep a per-attacker
    -- toggle. A hand whose gauntlet cannot fire (not enchanted, no charge)
    -- simply misses its turn, so one enchanted gauntlet fires every other punch.
    local hand = nextHand[attacker.id] or 1              -- 1 = left, 2 = right
    nextHand[attacker.id] = 3 - hand

    local item = Actor.getEquipment(attacker, SLOTS[hand])
    local ench = strikeEnchantment(item)
    local fired = ench and fireGauntlet(attacker, victim, item, ench)

    if not fired and FALLBACK_TO_OTHER_HAND then
        local other = Actor.getEquipment(attacker, SLOTS[3 - hand])
        local oench = strikeEnchantment(other)
        if oench then fireGauntlet(attacker, victim, other, oench) end
    end
    log(string.format('%s punch: %s hand%s', attacker.recordId, hand == 1 and 'left' or 'right',
        fired and ' fired' or ' (nothing to fire)'))
end

-- Test kit: give the player the two prototype gauntlets (from COSGauntlets.esp).
local world = require('openmw.world')
local TEST_ITEMS = { 'cos_fist_gauntlet_l', 'cos_fist_gauntlet_r' }
local function onGiveTestKit(e)
    local player = e.player
    if not player then return end
    for _, id in ipairs(TEST_ITEMS) do
        local ok, obj = pcall(world.createObject, id, 1)
        if ok and obj then
            obj:moveInto(Actor.inventory(player))
        else
            log('could not create ' .. id .. ' (is COSGauntlets.esp loaded?)')
        end
    end
    player:sendEvent('FistStrike_Message', 'Fist of Testing gauntlets added')
end

return {
    eventHandlers = {
        FistStrike_Landed      = onFistStrikeLanded,
        FistStrike_GiveTestKit = onGiveTestKit,
    },
}
