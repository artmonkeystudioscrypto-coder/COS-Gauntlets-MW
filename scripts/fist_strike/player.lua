-- fist_strike/player.lua
-- Prototype convenience only: shows an on-screen message when the player's
-- gauntlets fire, and gives the player the test kit on a hotkey.
--   F8  -> adds the two "Fist of Testing" gauntlets to the inventory
local ui    = require('openmw.ui')
local input = require('openmw.input')
local core  = require('openmw.core')
local self  = require('openmw.self')

return {
    engineHandlers = {
        onKeyPress = function(key)
            if key.code == input.KEY.F8 then
                core.sendGlobalEvent('FistStrike_GiveTestKit', { player = self.object })
            end
        end,
    },
    eventHandlers = {
        FistStrike_Message = function(text) ui.showMessage(text) end,
    },
}
