-- TEST ONLY: on FistTest_Attack, face the target and swing fists repeatedly.
local self  = require('openmw.self')
local types = require('openmw.types')
local core  = require('openmw.core')
local I     = require('openmw.interfaces')
local target, t0, lastSec

return {
    eventHandlers = {
        FistTest_Attack = function(e)
            target = e.target; t0 = core.getRealTime()
            self:enableAI(false)
            if I.Controls then I.Controls.overrideCombatControls(true); I.Controls.overrideMovementControls(true) end
            types.Actor.setStance(self, types.Actor.STANCE.Weapon)
            print('[FistTest] ' .. self.recordId .. ' attacking ' .. target.recordId)
        end,
        FistTest_Equip = function()
            local eq = types.Actor.getEquipment(self)
            eq[types.Actor.EQUIPMENT_SLOT.LeftGauntlet]  = 'tim_fist_gauntlet_l'
            eq[types.Actor.EQUIPMENT_SLOT.RightGauntlet] = 'tim_fist_gauntlet_r'
            eq[types.Actor.EQUIPMENT_SLOT.CarriedRight]  = nil
            types.Actor.setEquipment(self, eq)
            print('[FistTest] ' .. self.recordId .. ' equipped test gauntlets')
        end,
    },
    engineHandlers = {
        onUpdate = function()
            if not target or not target:isValid() then return end
            local d = target.position - self.position
            self.controls.yawChange = math.atan2(d.x, d.y) - self.rotation:getYaw()
            self.controls.movement = 0; self.controls.sideMovement = 0
            if types.Actor.getStance(self) ~= types.Actor.STANCE.Weapon then
                types.Actor.setStance(self, types.Actor.STANCE.Weapon)
            end
            local el = core.getRealTime() - t0
            if math.floor(el) ~= lastSec then
                lastSec = math.floor(el)
                print(string.format('[FistTest] %s t=%d dist=%.0f pos=(%.0f,%.0f,%.0f) ground=%s cell=%s use=%s',
                    self.recordId, lastSec, d:length(), self.position.x, self.position.y, self.position.z,
                    tostring(types.Actor.isOnGround(self)), tostring(self.cell and self.cell.name),
                    tostring(self.controls.use)))
            end
            -- hold 0.4 s, release 0.8 s
            local phase = (core.getRealTime() - t0) % 1.2
            if phase < 0.4 then
                self.controls.use = self.ATTACK_TYPE.Chop
            else
                self.controls.use = self.ATTACK_TYPE.NoAttack
            end
        end,
    },
}
