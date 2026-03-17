# ElvUI TrenchyUI

A minimalistic companion addon for [ElvUI](https://www.tukui.org/elvui) on World of Warcraft Retail.

## Features

### Quality of Life

- **Hide Talking Head** — Hides the TalkingHeadFrame popup.
- **Auto-Fill DELETE** — Auto-populates the DELETE confirmation when destroying stuff.
- **Difficulty Text** — Replaces the minimap difficulty icon with colored text (N, H, M, M+12, etc). Customizable colors per difficulty.
- **Cursor Circle** — Places a sizeable cursor wround your mouse.
- **Fast Loot** — Instantly auto-loots all items from corpses.
- **Moveable Frames** — Makes Blizzard panels draggable.
- **Minimap Button Bar** — Collects minimap buttons into a configurable grid bar with backdrop, border, and mouseover/combat visibility options.

### Cooldown Manager

Reparents Blizzard's CDM icons (Essential, Utility, Buff Icon) into ElvUI-movable containers with per-viewer settings.

- Configurable icon size, spacing, grid layout, and growth direction
- Visibility modes per viewer (Always / In Combat / Hidden)
- Proc glow effects (Pixel, AutoCast, Button, Proc) via LibCustomGlow
- Per-viewer cooldown text and count text font styling
- GCD swipe toggle

### Damage Meter

Built-in damage meter using the Blizzard API — no third-party meter required.

- 12 display modes: Damage, DPS, Healing, HPS, Absorbs, Interrupts, Dispels, Deaths, and more
- Spell drilldown per player
- Multi-window support (up to 4)
- Embeddable into the ElvUI chat panel or standalone (single window)
- Per-window bar, text, and color customization
- Session switching (Current / per-combat)

### ElvUI Enhancements

**Nameplates**
- Threat color override for tanking (prioritizes classification color, until threat is lost, then allows threat)
- Interrupt castbar indicator with ready/cooldown colors
- Focus target nameplate texture overlay
- Quest objective healthbar coloring
- Hover highlight restriction (removes the glow highlight on Friendly Nameplates)

**Unit Frames**
- Smart power tag (`tui-smartpower`) — mana % for healers, raw power for others
- Pixel Glow replacement for Aura Highlight

### Addon Skins
- **WarpDeplete** — Class-colored progress bars
- **BigWigs** — LFG timer skin, class-colored bar backgrounds
- **Auctionator** — Full ElvUI skin for tabs, buttons, search, results
- **BugSack** — Frame and tab styling
- **OPie** — Radial menu settings skin

### Profiles

One-click pre-configured profiles for ElvUI, BigWigs, WarpDeplete, and ls_Toasts.

## Usage

- `/tui` — Open TrenchyUI config (inside ElvUI Options)
- `/cdm` — Jump to Cooldown Manager settings
- `/tdm` — Jump to Damage Meter settings

## Configuration

All settings live under **ElvUI Options → TrenchyUI**. No separate SavedVariables — everything is stored within ElvUI's profile database.

## Credits

Lots of folks and addons have inspired this addon. I'll do my best to acknowledge them.

First, Jiberish. Creating a community of like-minded UI enthusiasts while always being a hype-man has been fun. This doesn't happen without you.
Second, Blinkii. TY for letting me use your "Interrupt on CD" module for TrenchyUI. 

Some of the addons that inspired features and functions within TrenchyUI: Eltruism (Pixel Glow), MinimapButtonButton/SquaredMinimapButton, Shadow & Light (Friends/Guild datatexts), CDMCentered, ArcUI, Ayije's CDM (a lot of the CDM features are inspired by some of the neat things these addons do), Details!...TDM exists because Details!, BlizzMove. The devs of these addons are basically wizards...Go check out their work!
