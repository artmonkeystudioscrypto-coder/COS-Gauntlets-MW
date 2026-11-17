-- fist_strike/player.lua
-- On-screen messages, plus a test-kit hotkey that only exists when the test
-- plugin (COSGauntlets.esp) is in the load order.
--   F8  -> adds the two "Fist of Testing" gauntlets to the inventory
local ui    = require('openmw.ui')
local input = require('openmw.input')
local core  = require('openmw.core')
local self  = require('openmw.self')
local types = require('openmw.types')

local testKitLoaded = types.Armor.records['cos_fist_gauntlet_l'] ~= nil

return {
    engineHandlers = {
        onKeyPress = function(key)
            if testKitLoaded and key.code == input.KEY.F8 then
                core.sendGlobalEvent('FistStrike_GiveTestKit', { player = self.object })
            end
        end,
    },
    eventHandlers = {
        FistStrike_Message = function(text) ui.showMessage(text) end,
    },
}
