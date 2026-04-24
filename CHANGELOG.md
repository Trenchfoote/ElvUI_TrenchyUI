# TrenchyUI Changelog

## v1.6.1

### New Features
- Unit Frames: New `[tui-staggerpct]` tag — displays Brewmaster Monk staggered damage as a percentage of max health in any text field that accepts tags. Values above 100 indicate stagger that would exceed your health pool (something the stagger bar alone cannot show).

### Bug Fixes
- Cooldown Manager: Custom viewer — Left, Right, Up, and Down growth directions now grow from the correct edge when icons are added or removed, instead of appearing to recenter. Center growth is unchanged.
- General: `/cdm` and `/tdm` slash commands now reliably open to the Cooldown Manager and Damage Meter config tabs.

### Improvements
- General: Movers for disabled modules are now greyed out in ElvUI's config mode, matching how ElvUI handles its own movers.
