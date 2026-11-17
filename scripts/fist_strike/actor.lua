-- fist_strike/actor.lua  (runs on every NPC, creature and the player)
--
-- Job: notice when THIS actor gets punched by an unarmed NPC/player and tell the
-- global script about it. The global script does the real work (it is the only
-- place allowed to drain the attacker's gauntlet charge).
--
-- The engine sends the victim a 'Hit' event for every melee attack that lands,
-- whether it did health damage or only fatigue damage. That is exactly the
-- "every strike" rule we want for the prototype.

local core  = require('openmw.core')
local self  = require('openmw.self')
local types = require('openmw.types')

local DEBUG = true

local function onHit(attack)
    if DEBUG then
        print(string.format('[fist_strike] Hit on %s: ok=%s src=%s weapon=%s attacker=%s hp=%s fat=%s', self.recordId,
            tostring(attack.successful), tostring(attack.sourceType), tostring(attack.weapon and attack.weapon.recordId),
            tostring(attack.attacker and attack.attacker.recordId), tostring(attack.damage.health), tostring(attack.damage.fatigue)))
    end
    if not attack.successful then return end            -- a miss; nothing to cast
    if attack.sourceType ~= 'melee' then return end     -- spells/arrows handled by engine
    if attack.weapon then return end                    -- real weapon: engine already does on-strike

    local attacker = attack.attacker
    if not attacker then return end
    if not types.NPC.objectIsInstance(attacker) then return end  -- creatures have no gauntlets

    core.sendGlobalEvent('FistStrike_Landed', {
        attacker = attacker,
        victim   = self.object,
        hitPos   = attack.hitPos,
        damage   = attack.damage,
    })
end

return {
    eventHandlers = {
        Hit = onHit,
    },
}
