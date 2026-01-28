--[[
	StockUp Database Integration
	Provides access to NPC, Item, and Object databases for vendor lookup
]]--

-- Get addon reference from global namespace
local addon = _G.StockUp
local Database = {}

-- Attach Database module to addon
if addon then
	addon.Database = Database
end

-- Only use QuestieDB if it's already loaded (don't create it if it doesn't exist)
-- This prevents conflicts with Questie's initialization

-- Get the current expansion
local function GetExpansion()
	local _, _, _, tocVersion = GetBuildInfo()
	if tocVersion >= 20000 and tocVersion < 30000 then
		return "TBC"
	elseif tocVersion >= 10000 and tocVersion < 20000 then
		return "CLASSIC"
	else
		-- Default to classic for anniversary/era servers
		return "CLASSIC"
	end
end

-- Database accessor functions
function Database:Initialize()
	self.expansion = GetExpansion()
	self.initialized = true
	
	-- Questie is optional - only log if it's available
	if QuestieDB then
		if not QuestieDB.npcData or not QuestieDB.itemData then
			addon:Print("|cffaaaaaa(Note: Questie databases not fully loaded)")
		end
	end
end

--[[
	Find all NPCs that sell a specific item
	@param itemID - The item ID to search for
	@return table - List of NPC IDs that sell this item
]]--
function Database:GetVendorsForItem(itemID)
	-- Questie is optional - return empty if not available
	if not QuestieDB or not QuestieDB.itemData or not QuestieDB.itemKeys then
		return {}
	end
	
	-- Parse the item data if it's still in string format
	local itemData = QuestieDB.itemData
	if type(itemData) == "string" then
		-- The data is stored as a loadstring, we need to execute it
		local func = loadstring(itemData)
		if func then
			itemData = func()
			QuestieDB.itemData = itemData
		else
			return {}
		end
	end
	
	-- Get the item entry
	local item = itemData[itemID]
	if not item then
		return {}
	end
	
	-- Get the vendors field (key 14)
	local vendorsKey = QuestieDB.itemKeys.vendors
	if not vendorsKey or not item[vendorsKey] then
		return {}
	end
	
	return item[vendorsKey]
end

--[[
	Get information about an NPC
	@param npcID - The NPC ID
	@return table - NPC data including name, location, flags
]]--
function Database:GetNPCInfo(npcID)
	-- Questie is optional - return nil if not available
	if not QuestieDB or not QuestieDB.npcData or not QuestieDB.npcKeys then
		return nil
	end
	
	-- Parse the NPC data if it's still in string format
	local npcData = QuestieDB.npcData
	if type(npcData) == "string" then
		local func = loadstring(npcData)
		if func then
			npcData = func()
			QuestieDB.npcData = npcData
		else
			return nil
		end
	end
	
	-- Get the NPC entry
	local npc = npcData[npcID]
	if not npc then
		return nil
	end
	
	-- Extract useful information
	local keys = QuestieDB.npcKeys
	local info = {
		id = npcID,
		name = npc[keys.name],
		subName = npc[keys.subName],
		minLevel = npc[keys.minLevel],
		maxLevel = npc[keys.maxLevel],
		spawns = npc[keys.spawns],
		zoneID = npc[keys.zoneID],
		npcFlags = npc[keys.npcFlags],
		friendlyToFaction = npc[keys.friendlyToFaction],
	}
	
	-- Check if this is a vendor (npcFlags bit 128 = 0x80)
	info.isVendor = info.npcFlags and (bit.band(info.npcFlags, 128) ~= 0)
	
	return info
end

--[[
	Get the name of an item from the database
	@param itemID - The item ID
	@return string - Item name or nil
]]--
function Database:GetItemName(itemID)
	if not QuestieDB.itemData or not QuestieDB.itemKeys then
		return nil
	end
	
	-- Parse the item data if it's still in string format
	local itemData = QuestieDB.itemData
	if type(itemData) == "string" then
		local func = loadstring(itemData)
		if func then
			itemData = func()
			QuestieDB.itemData = itemData
		else
			return nil
		end
	end
	
	local item = itemData[itemID]
	if not item then
		return nil
	end
	
	return item[QuestieDB.itemKeys.name]
end

--[[
	Find vendors for all reagents used by the player's class
	Returns a mapping of itemID -> list of vendor NPCs
]]--
function Database:GetReagentVendors(reagentList)
	local vendorMap = {}
	
	for _, reagent in ipairs(reagentList) do
		local vendors = self:GetVendorsForItem(reagent.itemID)
		if vendors and #vendors > 0 then
			vendorMap[reagent.itemID] = {}
			for _, npcID in ipairs(vendors) do
				local npcInfo = self:GetNPCInfo(npcID)
				if npcInfo then
					table.insert(vendorMap[reagent.itemID], npcInfo)
				end
			end
		end
	end
	
	return vendorMap
end

--[[
	Get a formatted string with vendor locations for an item
	@param itemID - The item ID
	@return string - Formatted location string
]]--
function Database:GetVendorLocationString(itemID)
	local vendors = self:GetVendorsForItem(itemID)
	if not vendors or #vendors == 0 then
		return "No vendors found"
	end
	
	local locations = {}
	for _, npcID in ipairs(vendors) do
		local npc = self:GetNPCInfo(npcID)
		if npc and npc.name then
			local location = npc.name
			if npc.subName then
				location = location .. " <" .. npc.subName .. ">"
			end
			table.insert(locations, location)
		end
	end
	
	if #locations == 0 then
		return "No vendor details available"
	elseif #locations == 1 then
		return locations[1]
	else
		return table.concat(locations, ", ", 1, math.min(3, #locations))
	end
end

-- Zone ID to name mapping (common zones)
Database.zoneNames = {
	[1519] = "Stormwind City",
	[1537] = "Ironforge",
	[1657] = "Darnassus",
	[1638] = "Orgrimmar",
	[1497] = "Undercity",
	[1637] = "Thunder Bluff",
	[3557] = "Exodar",
	[3487] = "Silvermoon City",
	[3703] = "Shattrath City",
}

function Database:GetZoneName(zoneID)
	return self.zoneNames[zoneID] or "Zone " .. tostring(zoneID)
end
