# StockUp - Changes & Features

## Version 1.0.6 - Unified .toc Files
- **Consolidated .toc files**: Combined StockUp_Classic.toc and StockUp_TBC.toc into single StockUp.toc supporting both Classic (11500) and TBC (20504)
- Single addon file now supports both game versions automatically

## Version 1.0.5 - Bug Fixes
- **Fixed empty purchase popup**: Purchase confirmation dialog now properly displays item name and quantity
- **Removed non-vendor reagents**: Removed Fish Oil and Shiny Fish Scales from Shaman reagents (not sold by vendors)
- **Only Ankh for Shamans**: Shaman reagents now limited to Ankh which is available from vendors

## Version 1.0.4 - Quiet Modeg
- **Suppress Login Messages**: New checkbox to disable print messages on login (quiet/light mode)
- Useful for users who prefer a clean chat log on startup
- Disabled by default to maintain familiar behavior

## Version 1.0.3 - Safe First-Time Setup
- **Auto-Buy disabled by default**: Addon now starts with Auto-Buy disabled to prevent accidental purchases on first login
- **Smart first-time reagent defaults**: Starting purchase amounts automatically set to 10 for all reagents (100 for Paladin's Symbol of Kings)
- **Safer onboarding**: Users must explicitly enable Auto-Buy in settings before any automatic purchases occur
- **Added CurseForge project ID**: Metadata added for better CurseForge integration

## Version 1.0.2 - First-Time Setup & Config Dialog
- **First-time setup dialog**: Configuration panel now opens automatically on first login so users can set their preferences before any auto-purchases happen
- **One-time setup flag**: Once you configure settings, the dialog won't appear again unless you want to reconfigure manually
- Improved onboarding experience for new users

## Version 1.0.1 - Bug Fixes
- **Fixed purchase quantity calculation**: Addon now correctly purchases the exact amount you set (e.g., if you want 300 total and have 275, it buys exactly 25)
- **Fixed slider step constraint**: You can now set any custom amount for reagents (previously limited to vendor stack size increments)
- **Fixed partial purchases**: Items are now purchased in a single transaction instead of individual loop calls



##  Version Features 1.0.0

### Core Functionality
- Automatic reagent purchasing from vendors
- Class-specific reagent detection
- Intelligent reagent selection based on highest-level known spells
- Smart Buy Mode - only purchases reagents needed to reach target amount
- Manual override for specific reagent selection
- Custom purchase amounts per reagent type

### Supported Classes & Reagents

#### Priest
- Holy Candle (Level 48)
- Sacred Candle (Level 60)

#### Paladin
- Symbol of Divinity (Level 60)
- Symbol of Kings (Level 60)

#### Shaman
- Ankh (Level 30)
- Shiny Fish Scales (Level 56)
- Fish Oil (Level 58)

#### Druid
- Maple Seed (Level 40)
- Stranglethorn Seed (Level 50)
- Ashwood Seed (Level 60)
- Hornbeam Seed (Level 66, TBC)
- Ironwood Seed (Level 72, TBC)
- Wild Berries (Level 20)
- Wild Thornroot (Level 40)
- Wild Quillvine (Level 60)

#### Rogue
- Flash Powder (Level 20)

### User Interface Features
- Minimap button for quick access
- Configuration panel with full settings
- Chat feedback for purchases and errors
- Per-character and profile-based storage system

### Safety & Error Handling
- Automatic class detection on login/UI reload
- Gold availability check before purchasing
- Bag space verification
- Vendor stock validation
- Class mismatch detection and warnings

### Database Support
- Classic Era support
- TBC Classic support
- Comprehensive Questie-based NPC/Item/Object database
- Automatic version detection

### Commands Available
- `/su` or `/stockup` - Open configuration window
- `/su toggle` - Enable/disable addon
- `/su auto` - Toggle auto-buy mode
- `/su vendors` - Show vendor locations
- `/su info` - Display character and reagent information
- `/su help` - Show command help

### Configuration Options
- Enable/disable addon
- Toggle auto-buy at vendors
- Enable/disable Smart Buy Mode
- Toggle chat messages
- Hide/show minimap button
- Set default purchase amounts (1-200)
- Set custom amounts per reagent type
- Choose automatic or manual reagent selection

### Technical Details
- Built on Ace3 addon framework
- Per-character and profile-based storage for maximum flexibility
- Support for Classic Era (1.14.x) and TBC Classic (2.5.x)
- Comprehensive vendor database included

## Installation
1. Extract StockUp folder to your WoW AddOns directory
2. Restart WoW or reload UI (`/reload`)
3. Addon loads automatically

## Key Files
- `StockUp.lua` - Main addon logic
- `Config.lua` - Configuration interface
- `Database.lua` - Database management
- `Minimap.lua` - Minimap button functionality
- `Db/` - Class-specific and version-specific databases
- `Libs/` - Ace3 libraries and dependencies
