--[[
    Example Reagent Vendor Locations
    
    This file contains common vendor locations for class reagents.
    The Database module can look these up automatically, but this serves
    as a quick reference for players.
]]--

local VENDOR_EXAMPLES = {
    -- Alliance Reagent Vendors
    ALLIANCE = {
        {
            name = "Kyra Boucher",
            location = "Stormwind City",
            coords = "Trade District",
            sells = {"Holy Candle", "Sacred Candle"},
            faction = "Alliance"
        },
        {
            name = "Alexandra Bolero",
            location = "Ironforge",
            coords = "The Mystic Ward",
            sells = {"Holy Candle", "Sacred Candle"},
            faction = "Alliance"
        },
        {
            name = "Brandur Ironhammer",
            location = "Ironforge",
            coords = "Hall of Arms",
            sells = {"Symbol of Divinity", "Symbol of Kings"},
            faction = "Alliance"
        },
        {
            name = "Fyldan",
            location = "Darnassus",
            coords = "Temple of the Moon",
            sells = {"Maple Seed", "Stranglethorn Seed", "Ashwood Seed"},
            faction = "Alliance"
        },
    },
    
    -- Horde Reagent Vendors
    HORDE = {
        {
            name = "Kaja",
            location = "Orgrimmar",
            coords = "Valley of Wisdom",
            sells = {"Ankh", "Shiny Fish Scales", "Fish Oil"},
            faction = "Horde"
        },
        {
            name = "Martha Alliestar",
            location = "Undercity",
            coords = "Magic Quarter",
            sells = {"Holy Candle", "Sacred Candle"},
            faction = "Horde"
        },
        {
            name = "Kathrum Axehand",
            location = "Orgrimmar",
            coords = "Valley of Honor",
            sells = {"Symbol of Divinity", "Symbol of Kings"},
            faction = "Horde"
        },
        {
            name = "Kali Healtouch",
            location = "Thunder Bluff",
            coords = "Spirit Rise",
            sells = {"Maple Seed", "Stranglethorn Seed", "Ashwood Seed"},
            faction = "Horde"
        },
    },
    
    -- Neutral/Special Vendors
    NEUTRAL = {
        {
            name = "Hagrus",
            location = "Shattrath City (TBC)",
            coords = "Lower City",
            sells = {"All TBC reagents"},
            faction = "Neutral"
        },
        {
            name = "Argent Quartermaster Hasana/Lightspark",
            location = "Western/Eastern Plaguelands",
            coords = "Light's Hope Chapel",
            sells = {"Sacred Candle"},
            faction = "Neutral",
            note = "Requires Argent Dawn reputation"
        },
    }
}

--[[
    Common Reagent Item IDs
    For quick reference when working with the database
]]--
local REAGENT_IDS = {
    -- Priest
    HOLY_CANDLE = 17028,
    SACRED_CANDLE = 17029,
    
    -- Paladin
    SYMBOL_OF_KINGS = 21177,
    SYMBOL_OF_DIVINITY = 17033,
    
    -- Shaman
    ANKH = 17030,
    FISH_OIL = 17058,
    SHINY_FISH_SCALES = 17057,
    
    -- Druid
    MAPLE_SEED = 17034,
    STRANGLETHORN_SEED = 17035,
    ASHWOOD_SEED = 17036,
    HORNBEAM_SEED = 17037, -- TBC
    IRONWOOD_SEED = 17038, -- TBC
    WILD_BERRIES = 17021,
    WILD_THORNROOT = 17026,
    WILD_QUILLVINE = 22148,
    
    -- Rogue
    FLASH_POWDER = 5140,
}

--[[
    Quick Tips for Finding Vendors
]]--
local VENDOR_TIPS = {
    "Most major cities have reagent vendors near class trainers",
    "Look for NPCs with titles like '<Reagent Vendor>' or '<Trade Supplies>'",
    "Shaman reagents are often sold by vendors near Shaman trainers",
    "Druid seeds are typically sold near Druid trainers or in natural areas",
    "TBC reagents can be found in Shattrath City (neutral) and Outland cities",
    "Some reagents (like Sacred Candle) require reputation with certain factions",
    "Use '/su vendors' command to see exact vendor names for your reagents",
}

-- Export for potential future use
return {
    vendors = VENDOR_EXAMPLES,
    reagentIDs = REAGENT_IDS,
    tips = VENDOR_TIPS,
}
