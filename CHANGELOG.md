# TrenchyUI Changelog

## v1.3.3

### New Features
- Damage Meter: Click in Combat toggle — optionally allow drilling into player spell breakdowns during combat
- Unit Frames: Tip of the Spear stack bar for Survival Hunters — tracks buff stacks on the class bar mover
- Unit Frames: Custom color pickers for Soul Fragments and Tip of the Spear bars

### Bug Fixes
- Damage Meter: Fixed stale player names persisting across group changes
- Damage Meter: Fixed drill-down showing empty bars (spell data lookup was using summary source objects instead of the full source API)

### Improvements
- Damage Meter: Improved secret value handling — show actual values in combat instead of '?', deadly/avoidable spell indicators in drill-down
- Damage Meter: Drill-down view now shows DPS/HPS per spell, spell icons, and abbreviated values in combat
- Damage Meter: Improved drill-down reliability with secret GUIDs — uses spec icon caching and multiple fallback strategies for player identification in combat
- Nameplates: Platynator custom class color names — use ElvUI custom class colors for friendly player name text
- Nameplates: Platynator config restructured into Health Text, Highlights, and Player Names sections
- Nameplates: Removed Platynator hide percent sign (now handled natively by Platynator)
- General: Cooldown Manager code cleanup and optimization
