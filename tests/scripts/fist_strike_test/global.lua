-- TEST ONLY harness for fist_strike. Spawns a vanilla NPC next to the player,
-- gives it the test gauntlets (no weapon), and makes it punch the player.
-- Also gives the player the gauntlets and drives them to punch back.
local core  = require('openmw.core')
local world = require('openmw.world')
local types = require('openmw.types')
local util  = require('openmw.util')
local Actor = types.Actor

local t0, spawned, quitAt = nil, false, nil
local dummy

local function equipKit(actor)
    for _, id in ipairs({ 'cos_fist_gauntlet_l', 'cos_fist_gauntlet_r' }) do
        local obj = world.createObject(id, 1)
        obj:moveInto(Actor.inventory(actor))
    end
    actor:sendEvent('FistTest_Equip', {})   -- setEquipment is local-only
end

return { engineHandlers = { onUpdate = function()
    local player = world.players[1]
    if not player then return end
    t0 = t0 or core.getRealTime()
    local el = core.getRealTime() - t0
    if not spawned and el > 6 then
        spawned = true
        dummy = world.createObject('fargoth', 1)   -- unarmed, weak vanilla NPC
        dummy:teleport(player.cell, player.position + util.vector3(70, 0, 0))
        equipKit(dummy); equipKit(player)
        print(string.format('[FistTest] spawned fargoth at %s (player at %s)', tostring(dummy.position), tostring(player.position)))
        dummy:sendEvent('FistTest_Attack', { target = player })
        player:sendEvent('FistTest_Attack', { target = dummy })
        quitAt = el + 20
    end
    if quitAt and el > quitAt then
        print('[FistTest] player health ' .. Actor.stats.dynamic.health(player).current ..
              ' fatigue ' .. Actor.stats.dynamic.fatigue(player).current)
        if dummy and dummy:isValid() then
            print('[FistTest] fargoth health ' .. Actor.stats.dynamic.health(dummy).current)
            for _, s in ipairs({ Actor.EQUIPMENT_SLOT.LeftGauntlet, Actor.EQUIPMENT_SLOT.RightGauntlet }) do
                local it = Actor.getEquipment(dummy, s)
                if it then print('[FistTest] fargoth ' .. it.recordId .. ' charge ' .. tostring(types.Item.itemData(it).enchantmentCharge)) end
            end
        end
        for _, s in ipairs({ Actor.EQUIPMENT_SLOT.LeftGauntlet, Actor.EQUIPMENT_SLOT.RightGauntlet }) do
            local it = Actor.getEquipment(player, s)
            if it then print('[FistTest] player ' .. it.recordId .. ' charge ' .. tostring(types.Item.itemData(it).enchantmentCharge)) end
        end
        print('[FistTest] quitting'); core.quit()
    end
end } }
