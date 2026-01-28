# StockUp

A World of Warcraft Classic/TBC addon that automatically purchases class-specific reagents from vendors.

## Features

### Core Functionality
- **Automatic Reagent Purchasing**: Automatically buys reagents when you open a vendor window
- **Class-Specific Detection**: Only purchases reagents relevant to your class
- **Intelligent Selection**: Automatically selects the best reagent based on your highest-level known spell
- **Smart Buy Mode**: Only purchases what you need to reach your desired amount (checks existing inventory)
- **Manual Override**: Choose specific reagents to purchase instead of automatic selection
- **Custom Amounts**: Set different purchase amounts for each reagent type

### User Interface
- **Minimap Button**: Quick access to settings and status
  - Left-click: Open configuration
  - Right-click: Toggle addon on/off
  - Shift+Right-click: Toggle auto-buy
  - Drag: Reposition button
- **Configuration Panel**: Full settings interface via `/su` command or Interface Options
- **Chat Feedback**: Detailed purchase information and error messages

### Error Handling
- **Gold Check**: Warns if you don't have enough gold
- **Bag Space Check**: Warns if you don't have enough free inventory slots
- **Vendor Stock Check**: Only attempts to buy items the vendor actually sells

## Supported Classes & Reagents

### Priest
- Holy Candle (Level 48)
- Sacred Candle (Level 60)

### Paladin
- Symbol of Divinity (Level 60)
- Symbol of Kings (Level 60)

### Shaman
- Ankh (Level 30)
- Shiny Fish Scales (Level 56)
- Fish Oil (Level 58)

### Druid
- Maple Seed (Level 40)
- Stranglethorn Seed (Level 50)
- Ashwood Seed (Level 60)
- Hornbeam Seed (Level 66, TBC)
- Ironwood Seed (Level 72, TBC)
- Wild Berries (Level 20)
- Wild Thornroot (Level 40)
- Wild Quillvine (Level 60)

### Rogue
- Flash Powder (Level 20)

## Installation

1. Extract the `StockUp` folder to your WoW AddOns directory:
   - Classic: `World of Warcraft\_classic_\Interface\AddOns\`
   - TBC: `World of Warcraft\_burning_crusade_\Interface\AddOns\`
   
2. Restart WoW or reload UI (`/reload`)

3. The addon will load automatically and show a confirmation message

## Usage

### Basic Usage
1. Enable the addon (it's enabled by default)
2. Visit any reagent vendor
3. The addon will automatically purchase your reagents

### Commands
- `/su` or `/stockup` - Open configuration window
- `/su toggle` - Enable/disable the addon
- `/su auto` - Toggle auto-buy on/off
- `/su vendors` - Show vendor locations for your reagents
- `/su info` - Display character info, reagent counts, and current settings
- `/su help` - Show command help

### Configuration Options

#### General Settings
- **Enable Addon**: Master on/off switch
- **Auto-Buy at Vendors**: Automatically purchase when opening vendor window
- **Smart Buy Mode**: Only buy what you need to reach target amount
- **Show Chat Messages**: Display purchase details in chat
- **Hide Minimap Button**: Hide/show the minimap button

#### Purchase Settings
- **Default Purchase Amount**: How many of each reagent to buy (1-200)
- **Custom Amounts**: Set specific amounts for individual reagents

#### Reagent Selection
- **Automatic Mode** (default): Addon selects the best reagent for your spells
- **Manual Mode**: Check specific reagents you want to purchase
- View which reagent is recommended for your current spell ranks

## How It Works

### Intelligent Reagent Selection
The addon checks which spells you have learned and automatically selects the appropriate reagent tier. For example:
- A level 60 Priest with Prayer of Fortitude VI will automatically purchase Sacred Candles
- A level 50 Priest with only Prayer of Fortitude IV will purchase Holy Candles

### Smart Buy Mode
When enabled (default), the addon:
1. Counts how many reagents you already have in your bags
2. Only purchases enough to reach your target amount
3. Example: If you want 20 reagents and have 8, it only buys 12

### Vendor Detection
The addon includes a comprehensive database of NPCs, items, and objects from Questie. This database allows the addon to:
- Identify which vendors sell specific reagents
- Display vendor names and locations in the configuration UI
- Help you find reagent vendors using the `/su vendors` command
- Scan the vendor's inventory to find matching reagents

The database supports both Classic and TBC content, automatically loading the appropriate data for your game version.

## Character Safety Features

### Automatic Class Detection
The addon **automatically detects your class** every time you log in or reload the UI. This means:
- You can never accidentally buy the wrong reagents on the wrong character
- Each character automatically loads the correct reagents for their class
- Settings are properly stored per-character or shared via profiles (your choice)

### Class Verification
Multiple safety checks ensure you're always buying the right reagents:
1. **On Login**: Detects your class using `UnitClass("player")`
2. **On Purchase**: Verifies class hasn't changed before buying anything
3. **Data Storage**: Saves your class, name, and realm in per-character storage
4. **Mismatch Detection**: Warns you if any data inconsistency is detected

### Per-Character Storage
The addon uses **two separate storage systems**:
- **Profiles** (`StockUpDB`): Optional sharing of settings across characters
- **Character Data** (`StockUpCharDB`): Always separate per character

This means you can:
- Share settings like "auto-buy" and "purchase amount" across all characters
- Keep character-specific data (class, reagents) completely separate
- Never worry about buying Priest reagents on your Druid!

### Example: Using Multiple Characters
```
Priest (Main):
  - Loads Sacred Candles automatically
  - Settings: Auto-buy ON, Purchase 20

Druid (Alt):
  - Loads Ashwood Seeds automatically  
  - Settings: Auto-buy ON, Purchase 20 (shared from profile)
  
Rogue (Alt):
  - Loads Flash Powder automatically
  - Settings: Auto-buy ON, Purchase 20 (shared from profile)
```

Use `/su info` on any character to see what the addon knows about you!

## Troubleshooting

### Common Issues

**"Not enough gold" error**
- The addon calculates the total cost before purchasing
- Make sure you have enough gold for all selected reagents

**"Not enough bag space" error**
- Free up inventory slots before visiting the vendor
- Each reagent type requires one free slot

**"No reagents needed" message**
- Smart Buy mode detected you already have enough reagents
- Disable Smart Buy or increase your purchase amount

**Reagents not being purchased**
- Make sure the vendor actually sells reagents (reagent vendors only)
- Check that your class uses reagents
- Verify the addon is enabled (`/su toggle`)

### Debug Mode
Type `/su` to open settings and verify:
- Addon is enabled
- Auto-buy is enabled
- Purchase amount is set correctly
- Smart Buy mode status

## Technical Details

### Dependencies
- Ace3 libraries (included in addon)
  - AceAddon-3.0
  - AceDB-3.0
  - AceConfig-3.0
  - AceConsole-3.0
  - AceEvent-3.0
  - AceGUI-3.0
- Questie Database (included)
  - NPC, Item, and Object databases for vendor lookup
  - Supports Classic and TBC versions

### Saved Variables
Settings are saved in two ways for maximum flexibility:
- **Profile-based** (`StockUpDB`): Settings like purchase amounts, auto-buy preferences, and minimap options can be shared across characters or kept separate using profiles
- **Per-character** (`StockUpCharDB`): Character-specific data like class, name, and realm are always stored separately to ensure the addon always knows which character you're playing

This dual-storage system ensures you never accidentally buy the wrong reagents on the wrong character!

### API Compatibility
- Classic Era (1.14.x)
- TBC Classic (2.5.x)
- Should work on private servers running these versions

## Credits

Created with Ace3 addon framework
Database integration using Questie NPC/Item/Object data
