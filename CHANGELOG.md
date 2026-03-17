# TrenchyUI Changelog

## v1.0

### New Features
- Nameplates: New "Class Color" toggle to override target indicator color with your class color (works with all indicator styles)
- Nameplates: Added toggle for hiding realm names on friendly nameplates
- Cooldown Manager: Buff bars now display stack/charge counts with live combat updates
- Cooldown Manager: Added "Show Tooltips" toggle for all cooldown viewers
- Cooldown Manager: Added "Hide When Inactive" toggle for buff icon viewer

### Bug Fixes
- Nameplates: Fixed interrupt-ready castbar color not updating when interrupt comes off cooldown during combat
- Unit Frames: Fixed pixel glow not showing correctly on dispellable debuffs in combat

### Improvements
- Nameplates: Rewrote interrupt-on-cooldown castbar coloring for improved accuracy and performance
- Cooldown Manager: Improved layout and fader performance
- Datatexts: Friends tooltip now shows Real ID names, favorites sorting, and status colors
- Damage Meter: Improved refresh performance with cached class colors and session labels
- General: Various performance optimizations across modules

### Removals
- Unit Frames: Removed Ironfur custom classbar (buff bar with stacks handles this better)
