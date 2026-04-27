# TrenchyUI Changelog

## v1.6.1

### New Features
- Unit Frames: New `[tui-stagger]` tag — displays Brewmaster Monk staggered damage as a percentage of max health in any text field that accepts tags. Values above 100 indicate stagger that would exceed your health pool (something the stagger bar alone cannot show).
- Skins: Talent Loadout Manager — sidebar panel, buttons, scrollbox, import dialog, and the collapse toggle now match the rest of the ElvUI styling.

### Bug Fixes
- Cooldown Manager: Custom viewer — Left, Right, Up, and Down growth directions now grow from the correct edge when icons are added or removed, instead of appearing to recenter. Center growth is unchanged.
- Damage Meter: Small fractional values (under a thousand) now display as clean integers instead of leaking full-precision decimals like `22.333333333333`.
- Nameplates: Platynator target indicator and mouseover highlight class color overrides now apply reliably the moment a unit appears, rather than only after a color picker change.
- General: `/cdm` and `/tdm` slash commands now reliably open to the Cooldown Manager and Damage Meter config tabs.

### Improvements
- Cooldown Manager: Pet reminder on Unholy Death Knight now click-casts Raise Dead.
- General: Movers for disabled modules are now greyed out in ElvUI's config mode, matching how ElvUI handles its own movers.
