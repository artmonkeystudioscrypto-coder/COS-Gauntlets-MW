# COS-Gauntlets-MW — Cast-on-Strike Gauntlets for OpenMW

Unarmed attacks trigger **Cast on Strike** enchantments on your gauntlets.

When you punch something, the engine tells the victim it was hit. The mod listens for that,
checks the attacker had no weapon out, and looks at their gauntlet slots. Punches alternate
hands (left, right, left...) and if that hand's gauntlet has a Cast-on-Strike enchantment with
enough charge, the mod applies the enchantment's effects to the victim, plays the matching spell
hit sound and visual, and drains the gauntlet's charge. Every landed hit counts, including ones
that only drain fatigue. NPCs wearing enchanted gauntlets get the same treatment when they punch you.

## Requirements

- **OpenMW 0.49 or newer** (or a build with the Lua `Hit` event and `Actor.activeSpells`,
  such as the OpenMW master nightly or the Silt Strider client).
- Does **not** work on OpenMW 0.48 or the original Morrowind engine.

## Install

1. Copy this folder somewhere, e.g. `Data Files/COS-Gauntlets-MW` or your mods directory.
2. In `openmw.cfg` add:
   ```
   data="<path to this folder>"
   content=fist_strike.omwscripts
   content=COSGauntlets.esp   # optional: test gauntlets
   ```
3. With the test plugin loaded, press **F8** in game to receive the two *Fist of Testing* gauntlets (Fire Damage 10 on strike). Without the plugin the hotkey does nothing.
   Equip both, put your weapon away, punch something.

## Making your own gauntlets

The vanilla enchanting menu refuses *Cast on Strike* for armor, so gauntlets must currently be
pre-enchanted in a plugin (Construction Set / tes3conv / OpenMW-CS): any Armor or Clothing record
in the gauntlet slots whose enchantment type is Cast on Strike will fire. Letting players do this
in the enchanting menu is the next planned feature.

## Files

| File | Role |
|---|---|
| `fist_strike.omwscripts` | script registration |
| `scripts/fist_strike/actor.lua` | runs on every actor; catches the engine `Hit` event, filters to successful unarmed melee, forwards to global |
| `scripts/fist_strike/global.lua` | finds the attacker's gauntlet, applies the enchantment, plays hit VFX/sound, drains charge; hand alternation + balance knobs |
| `scripts/fist_strike/player.lua` | F8 test-kit hotkey, on-screen messages |
| `COSGauntlets.esp` | `cos_fist_ench` (Fire Damage 10, touch, cost 10, charge 500) + `cos_fist_gauntlet_l/_r` |
| `tests/` | headless harness: spawns Fargoth, both actors punch for 20 s, prints charges, quits |

## Design rules

- Every successful unarmed hit fires, fatigue-only hits included.
- Hands alternate; one cast per punch. `FALLBACK_TO_OTHER_HAND` in `global.lua` (default `false`)
  lets a lone enchanted gauntlet fire every punch instead of every other one.
- If a weapon is equipped the script does nothing; the engine handles weapon on-strike itself.
- Debug logging is off by default; set `DEBUG = true` in `global.lua` / `actor.lua` to trace every hit and cast in `openmw.log`.

## Testing (headless)

```
openmw.exe --replace=config --config=<sandbox with Morrowind.esm + this mod + tests/> \
  --skip-menu --new-game --script-run=tests/testrun_exterior.mwscript.txt --no-grab
```
Add `content=fist_strike_test.omwscripts` to that sandbox. Use an exterior cell; interiors under
`--skip-menu` dropped actors through the floor on the nightly.

## License

MIT — see `LICENSE`.
