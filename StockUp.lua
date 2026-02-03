--[[
	StockUp - Automatic Reagent Purchasing Addon for WoW Classic/TBC
	Automatically purchases class-specific reagents from vendors.
]]--

-- Create the addon using Ace3
local addonName = "StockUp"
local addon = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")
local AceDB = LibStub("AceDB-3.0")

-- Local references for performance
local print = print
local UnitClass = UnitClass
local GetMoney = GetMoney
local GetMerchantNumItems = GetMerchantNumItems
local GetMerchantItemInfo = GetMerchantItemInfo
local GetMerchantItemLink = GetMerchantItemLink
local BuyMerchantItem = BuyMerchantItem
local GetItemInfo = GetItemInfo
local IsSpellKnown = IsSpellKnown

-- Container API compatibility (Classic vs Retail)
local GetContainerNumSlots = C_Container and C_Container.GetContainerNumSlots or GetContainerNumSlots
local GetContainerItemLink = C_Container and C_Container.GetContainerItemLink or GetContainerItemLink
local GetContainerItemInfo = C_Container and C_Container.GetContainerItemInfo or GetContainerItemInfo
local GetContainerNumFreeSlots = C_Container and C_Container.GetContainerNumFreeSlots or GetContainerNumFreeSlots

-- Addon namespace
addon.version = "1.0.2"

-- Make addon globally accessible early for Database.lua
_G.StockUp = addon

-- Create custom purchase confirmation frame (moveable)
local function CreatePurchaseFrame()
	local frame = CreateFrame("Frame", "StockUpPurchaseFrame", UIParent, "BackdropTemplate")
	frame:SetSize(400, 300)
	frame:SetPoint("CENTER")
	frame:SetFrameStrata("DIALOG")
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
	frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
	frame:Hide()
	
	-- Backdrop
	frame:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true, tileSize = 32, edgeSize = 32,
		insets = { left = 11, right = 12, top = 12, bottom = 11 }
	})
	
	-- Title
	frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	frame.title:SetPoint("TOP", 0, -15)
	frame.title:SetText("StockUp")
	
	-- Icon
	frame.icon = frame:CreateTexture(nil, "ARTWORK")
	frame.icon:SetSize(48, 48)
	frame.icon:SetPoint("TOPLEFT", 20, -55)
	
	-- Text
	frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	frame.text:SetPoint("TOPLEFT", frame.icon, "TOPRIGHT", 15, -5)
	frame.text:SetPoint("RIGHT", -20, 0)
	frame.text:SetJustifyH("LEFT")
	frame.text:SetJustifyV("TOP")
	
	-- Scroll frame for multiple items
	frame.scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
	frame.scrollFrame:SetPoint("TOPLEFT", 20, -115)
	frame.scrollFrame:SetPoint("BOTTOMRIGHT", -40, 60)
	
	frame.scrollChild = CreateFrame("Frame", nil, frame.scrollFrame)
	frame.scrollChild:SetSize(330, 1)
	frame.scrollFrame:SetScrollChild(frame.scrollChild)
	
	frame.itemList = frame.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	frame.itemList:SetPoint("TOPLEFT")
	frame.itemList:SetPoint("TOPRIGHT")
	frame.itemList:SetJustifyH("LEFT")
	frame.itemList:SetJustifyV("TOP")
	frame.itemList:SetSpacing(2)

	function frame:SetLayout(isMulti)
		if isMulti then
			self:SetHeight(300)
			self.scrollFrame:ClearAllPoints()
			self.scrollFrame:SetPoint("TOPLEFT", 20, -115)
			self.scrollFrame:SetPoint("BOTTOMRIGHT", -40, 60)
		else
			self:SetHeight(220)
			self.scrollFrame:ClearAllPoints()
			self.scrollFrame:SetPoint("TOPLEFT", 20, -115)
			self.scrollFrame:SetPoint("BOTTOMRIGHT", -40, 70)
		end
	end
	
	-- Buy All button
	frame.buyButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	frame.buyButton:SetSize(120, 25)
	frame.buyButton:SetPoint("BOTTOMLEFT", 20, 15)
	frame.buyButton:SetText("Buy All")
	
	-- Buy Each button
	frame.buyEachButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	frame.buyEachButton:SetSize(120, 25)
	frame.buyEachButton:SetPoint("BOTTOM", 0, 15)
	frame.buyEachButton:SetText("Buy Each")
	
	-- Cancel button
	frame.cancelButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	frame.cancelButton:SetSize(120, 25)
	frame.cancelButton:SetPoint("BOTTOMRIGHT", -20, 15)
	frame.cancelButton:SetText("Cancel")
	frame.cancelButton:SetScript("OnClick", function(self)
		frame:Hide()
		addon.pendingPurchase = nil
		addon.currentPurchaseIndex = nil
	end)
	
	-- Close button
	frame.closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	frame.closeButton:SetPoint("TOPRIGHT", 0, 0)
	
	return frame
end

addon.purchaseFrame = CreatePurchaseFrame()

-- Legacy popup dialogs removed - using custom frame instead

--[[
	Reagent database by class
	Each entry contains:
	- itemID: The item ID of the reagent
	- name: Item name (for display)
	- minLevel: Minimum level requirement
	- spellID: Optional spell ID that uses this reagent (for checking if learned)
	- stackSize: Vendor stack size (for UI slider increments)
]]--
local REAGENT_DATA = {
	PRIEST = {
		{itemID = 17028, name = "Holy Candle", minLevel = 48, spellID = 27841, stackSize = 1}, -- Prayer of Fortitude IV
		{itemID = 17029, name = "Sacred Candle", minLevel = 60, spellID = 25389, stackSize = 1}, -- Prayer of Fortitude VI
	},
	PALADIN = {
		{itemID = 21177, name = "Symbol of Kings", minLevel = 60, spellID = 25898, stackSize = 20}, -- Greater Blessing of Kings
		{itemID = 17033, name = "Symbol of Divinity", minLevel = 60, spellID = 27143, stackSize = 20}, -- Greater Blessing of Wisdom
	},
	SHAMAN = {
		{itemID = 17030, name = "Ankh", minLevel = 30, spellID = 20608, stackSize = 1}, -- Reincarnation
		{itemID = 17058, name = "Fish Oil", minLevel = 58, spellID = 10538, stackSize = 1}, -- Greater Fire Resistance Totem
		{itemID = 17057, name = "Shiny Fish Scales", minLevel = 56, spellID = 10472, stackSize = 1}, -- Greater Frost Resistance Totem
	},
	DRUID = {
		{itemID = 17034, name = "Maple Seed", minLevel = 40, spellID = 21849, stackSize = 1}, -- Gift of the Wild I
		{itemID = 17035, name = "Stranglethorn Seed", minLevel = 50, spellID = 21850, stackSize = 1}, -- Gift of the Wild II
		{itemID = 17036, name = "Ashwood Seed", minLevel = 60, spellID = 26991, stackSize = 1}, -- Gift of the Wild III
		{itemID = 17037, name = "Hornbeam Seed", minLevel = 66, spellID = 26992, stackSize = 1}, -- Gift of the Wild IV (TBC)
		{itemID = 17038, name = "Ironwood Seed", minLevel = 72, spellID = 26993, stackSize = 1}, -- Gift of the Wild V (TBC)
		-- Note: Flintweed Seed and others not in Classic/TBC
		-- Wild Berries, Wild Thornroot, Wild Quillvine are for lower level Rebirth
		{itemID = 17021, name = "Wild Berries", minLevel = 20, spellID = 20484, stackSize = 1}, -- Rebirth 2
		{itemID = 17026, name = "Wild Thornroot", minLevel = 40, spellID = 20739, stackSize = 1}, -- Rebirth 4
		{itemID = 22148, name = "Wild Quillvine", minLevel = 60, spellID = 26994, stackSize = 1}, -- Rebirth 6
	},
	ROGUE = {
		{itemID = 5140, name = "Flash Powder", minLevel = 20, spellID = 2836, stackSize = 1}, -- Vanish
	},
}

-- Default database values
local defaults = {
	profile = {
		enabled = true,
		autoBuy = false, -- Disabled by default until user enables it
		purchaseAmount = 20, -- Default amount to purchase per reagent
		showMessages = true, -- Show chat messages
		minimap = {
			hide = false,
		},
		-- Store custom amounts per reagent
		customAmounts = {},
		-- Store which reagents to buy (override auto-selection)
		selectedReagents = {},
		-- Only buy missing reagents (smart mode)
		smartBuy = true,
	},
	char = {
		-- Per-character data
		playerClass = nil, -- Stored class for verification
		playerName = nil, -- Character name
		playerRealm = nil, -- Realm name
		lastLogin = nil, -- Last login timestamp
		firstTimeSetup = false, -- Flag to show config on first login
	},
}

--[[
	Addon Initialization
]]--
function addon:OnInitialize()
	-- Set up database (profile-based for settings, char for character data)
	self.db = AceDB:New("StockUpDB", defaults, true)
	
	-- Get player information
	local _, className = UnitClass("player")
	local playerName = UnitName("player")
	local playerRealm = GetRealmName()
	
	self.playerClass = className
	self.playerName = playerName
	self.playerRealm = playerRealm
	
	-- Store/verify per-character data
	self:VerifyCharacterData()
	
	-- Initialize first-time reagent defaults
	self:InitializeFirstTimeReagents()
	
	-- Register chat commands
	self:RegisterChatCommand("su", "ChatCommand")
	self:RegisterChatCommand("stockup", "ChatCommand")
	
	-- Initialize reagent data for this class
	self:InitializeClassReagents()
	
	-- Initialize database integration
	if self.Database then
		self.Database:Initialize()
	end
	
	self:Print("StockUp v" .. self.version .. " loaded for |cff00ff00" .. className .. "|r. Type /su to configure.")
	
	-- Show info message about auto-buy being disabled
	self:Print("|cffff0000Auto-Buy is currently |cffff0000DISABLED|r. Enable it in the config when ready.")
	
	-- Show vendor info for reagents if database is available
	if self.Database and #self.classReagents > 0 then
		self:ScheduleTimer(function()
			self:Print("Reagent vendors loaded for your class.")
		end, 1)
	end
end

function addon:OnEnable()
	-- Register events
	self:RegisterEvent("MERCHANT_SHOW", "OnMerchantShow")
	self:RegisterEvent("MERCHANT_CLOSED", "OnMerchantClosed")
end

function addon:OnDisable()
	self:UnregisterAllEvents()
end

--[[
	Event: Merchant window closed
]]--
function addon:OnMerchantClosed()
	-- Hide purchase frame and clear pending purchases
	if self.purchaseFrame then
		self.purchaseFrame:Hide()
	end
	self.pendingPurchase = nil
	self.currentPurchaseIndex = nil
end

--[[
	Verify and update per-character data
	This ensures settings are always correct for the current character
]]--
function addon:VerifyCharacterData()
	-- Update character information
	self.db.char.playerClass = self.playerClass
	self.db.char.playerName = self.playerName
	self.db.char.playerRealm = self.playerRealm
	self.db.char.lastLogin = time()
	
	-- Class change detection (should never happen, but just in case)
	if self.db.char.playerClass and self.db.char.playerClass ~= self.playerClass then
		self:Print("|cffff0000Warning:|r Character class mismatch detected! Resetting to " .. self.playerClass)
		-- Clear class-specific settings
		self.db.profile.customAmounts = {}
		self.db.profile.selectedReagents = {}
	end
end

--[[
	Initialize reagent data for the player's class
]]--
--[=[
	Initialize first-time reagent defaults
	Sets starting amounts to 10 for all reagents, except Symbol of Kings (100 for Paladins)
]=]--
function addon:InitializeFirstTimeReagents()
	if not self.db.char.firstTimeSetup then
		-- Initialize custom amounts with starting values
		local classReagents = REAGENT_DATA[self.playerClass] or {}
		
		for _, reagent in ipairs(classReagents) do
			-- Symbol of Kings (21177) gets 100, all others get 10
			if reagent.itemID == 21177 then
				self.db.profile.customAmounts[reagent.itemID] = 100
				self.db.profile.selectedReagents[reagent.itemID] = true
			else
				self.db.profile.customAmounts[reagent.itemID] = 10
				self.db.profile.selectedReagents[reagent.itemID] = true
			end
		end
		
		-- Mark first-time setup as complete
		self.db.char.firstTimeSetup = true
	end
end

function addon:InitializeClassReagents()
	self.classReagents = REAGENT_DATA[self.playerClass] or {}
	
	if #self.classReagents == 0 then
		self:Print("Your class (" .. self.playerClass .. ") does not require reagents.")
	end
end

--[[
	Get the best reagent for the player based on known spells
	Returns the highest tier reagent the player can use
]]--
function addon:GetBestReagent()
	if not self.classReagents or #self.classReagents == 0 then
		return nil
	end
	
	-- Sort reagents by level (highest first)
	local sortedReagents = {}
	for _, reagent in ipairs(self.classReagents) do
		table.insert(sortedReagents, reagent)
	end
	table.sort(sortedReagents, function(a, b)
		return (a.minLevel or 0) > (b.minLevel or 0)
	end)
	
	-- Find the highest level reagent for which the player knows the spell
	for _, reagent in ipairs(sortedReagents) do
		if reagent.spellID then
			-- Check if player knows this spell
			if IsSpellKnown(reagent.spellID) then
				return reagent
			end
		end
	end
	
	-- If no spell-based match, return the first reagent
	return self.classReagents[1]
end

--[[
	Get all reagents the player should purchase
	Returns a table of reagents based on settings
]]--
function addon:GetReagentsToPurchase()
	local reagents = {}
	
	-- If user has selected specific reagents, use those
	if self.db.profile.selectedReagents and next(self.db.profile.selectedReagents) then
		for itemID, enabled in pairs(self.db.profile.selectedReagents) do
			if enabled then
				-- Find the reagent data
				for _, reagent in ipairs(self.classReagents) do
					if reagent.itemID == itemID then
						table.insert(reagents, reagent)
						break
					end
				end
			end
		end
	else
		-- Auto-select best reagent
		local bestReagent = self:GetBestReagent()
		if bestReagent then
			table.insert(reagents, bestReagent)
		end
	end
	
	return reagents
end

--[[
	Count how many of a specific item the player has in bags
]]--
function addon:CountItemInBags(itemID)
	local count = 0
	for bag = 0, 4 do
		for slot = 1, GetContainerNumSlots(bag) or 0 do
			local link = GetContainerItemLink(bag, slot)
			if link then
				local linkItemID = tonumber(string.match(link, "item:(%d+)"))
				if linkItemID == itemID then
					local containerInfo = GetContainerItemInfo(bag, slot)
					-- Handle both old and new API return values
					local itemCount
					if type(containerInfo) == "table" then
						-- New API (C_Container) returns a table
						itemCount = containerInfo.stackCount
					else
						-- Old API returns multiple values
						itemCount = containerInfo
					end
					count = count + (itemCount or 0)
				end
			end
		end
	end
	return count
end

--[[
	Get total free bag slots
]]--
function addon:GetFreeBagSlots()
	local freeSlots = 0
	for bag = 0, 4 do
		freeSlots = freeSlots + (GetContainerNumFreeSlots(bag) or 0)
	end
	return freeSlots
end

--[[
	Format copper value to gold/silver/copper string
]]--
function addon:FormatMoney(copper)
	if not copper or copper == 0 then return "0c" end
	
	local gold = floor(copper / 10000)
	local silver = floor((copper % 10000) / 100)
	local copperRemain = copper % 100
	
	local str = ""
	if gold > 0 then
		str = str .. gold .. "g "
	end
	if silver > 0 or gold > 0 then
		str = str .. silver .. "s "
	end
	str = str .. copperRemain .. "c"
	
	return str
end

--[[
	Format copper value to gold/silver/copper string with icons
]]--
function addon:FormatMoneyWithIcons(copper)
	local goldIcon = "|TInterface\\MoneyFrame\\UI-GoldIcon:14:14:0:0|t"
	local silverIcon = "|TInterface\\MoneyFrame\\UI-SilverIcon:14:14:0:0|t"
	local copperIcon = "|TInterface\\MoneyFrame\\UI-CopperIcon:14:14:0:0|t"

	if not copper or copper == 0 then
		return "0" .. copperIcon
	end

	local gold = floor(copper / 10000)
	local silver = floor((copper % 10000) / 100)
	local copperRemain = copper % 100

	local str = ""
	if gold > 0 then
		str = str .. gold .. goldIcon .. " "
	end
	if silver > 0 or gold > 0 then
		str = str .. silver .. silverIcon .. " "
	end
	str = str .. copperRemain .. copperIcon

	return str
end

--[[
	Event: Merchant window opened
]]--
function addon:OnMerchantShow()
	if not self.db.profile.enabled then
		return
	end
	
	-- Give the merchant frame time to populate
	-- Pass autoBuy status to the purchase function
	self:ScheduleTimer("ProcessMerchantPurchase", 0.5, self.db.profile.autoBuy)
end

--[[
	Main purchase logic
]]--
function addon:ProcessMerchantPurchase(autoBuyEnabled)
	-- Safety check: Verify we have the correct class
	local _, currentClass = UnitClass("player")
	if currentClass ~= self.playerClass then
		self:Print("|cffff0000Error:|r Class mismatch detected. Please /reload")
		return
	end
	
	local reagents = self:GetReagentsToPurchase()
	
	if not reagents or #reagents == 0 then
		return
	end
	
	-- Check if this vendor sells reagents
	local vendorItems = {}
	local numItems = GetMerchantNumItems()
	local foundReagents = false
	
	for i = 1, numItems do
		local link = GetMerchantItemLink(i)
		if link then
			local itemID = tonumber(string.match(link, "item:(%d+)"))
			if itemID then
				vendorItems[itemID] = i
				-- Check if this is one of our reagents
				for _, reagent in ipairs(reagents) do
					if reagent.itemID == itemID then
						foundReagents = true
						break
					end
				end
			end
		end
	end
	
	-- Early exit if vendor doesn't sell any reagents we need
	if not foundReagents then
		return
	end
	
	-- Process each reagent
	local totalCost = 0
	local purchaseList = {}
	
	for _, reagent in ipairs(reagents) do
		local vendorSlot = vendorItems[reagent.itemID]
		
		if vendorSlot then
			-- Get reagent info
			local name, _, price, quantity = GetMerchantItemInfo(vendorSlot)
			
			-- Calculate how much to buy
			local amountToBuy = self.db.profile.customAmounts[reagent.itemID] or self.db.profile.purchaseAmount
			
			-- Smart buy: only buy what's needed
			if self.db.profile.smartBuy then
				local currentCount = self:CountItemInBags(reagent.itemID)
				amountToBuy = math.max(0, amountToBuy - currentCount)
			end
			
			if amountToBuy > 0 then
				-- Buy individual items (quantity is vendor stack size, not relevant to purchase amount)
				local cost = price * amountToBuy
				
				table.insert(purchaseList, {
					slot = vendorSlot,
					reagent = reagent,
					quantity = amountToBuy,
					cost = cost,
				})
				
				totalCost = totalCost + cost
			end
		end
	end
	
	-- Validation checks
	if #purchaseList == 0 then
		if self.db.profile.showMessages then
			self:Print("No reagents needed at this time.")
		end
		return
	end
	
	-- Check if player has enough gold
	local playerMoney = GetMoney()
	if totalCost > playerMoney then
		self:Print("|cffff0000Error:|r Not enough gold! Need " .. self:FormatMoney(totalCost) .. " but only have " .. self:FormatMoney(playerMoney))
		return
	end
	
	-- Check bag space
	local requiredSlots = #purchaseList
	local freeSlots = self:GetFreeBagSlots()
	if requiredSlots > freeSlots then
		self:Print("|cffff0000Error:|r Not enough bag space! Need " .. requiredSlots .. " slots but only have " .. freeSlots .. " free.")
		return
	end
	
	-- If auto-buy is disabled, show confirmation popup
	if not autoBuyEnabled then
		-- Store purchase data for popup
		self.pendingPurchase = {
			purchaseList = purchaseList,
			totalCost = totalCost,
		}
		
		local frame = self.purchaseFrame
		
		-- If multiple items, give option to buy all or individually
		if #purchaseList > 1 then
			frame:SetLayout(true)
			-- Build item list with icons
			local itemList = ""
			for _, purchase in ipairs(purchaseList) do
				local itemTexture = select(10, GetItemInfo(purchase.reagent.itemID)) or ""
				if itemTexture ~= "" then
					itemList = itemList .. "|T" .. itemTexture .. ":20|t "
				end
				itemList = itemList .. purchase.quantity .. "x " .. purchase.reagent.name .. " |cffffffff(" .. self:FormatMoneyWithIcons(purchase.cost) .. ")|r\n"
			end
			
			frame.icon:SetTexture("Interface\\Icons\\INV_Misc_Bag_07")
			frame.text:SetText("Purchase reagents for |cffffffff" .. self:FormatMoneyWithIcons(totalCost) .. "|r?")
			frame.itemList:SetText(itemList)
			frame.buyEachButton:Show()
			
			frame.buyButton:SetScript("OnClick", function()
				frame:Hide()
				self:ExecutePurchase(self.pendingPurchase)
				self.pendingPurchase = nil
			end)
			
			frame.buyEachButton:SetScript("OnClick", function()
				frame:Hide()
				self.currentPurchaseIndex = 1
				self:ShowNextPurchaseDialog()
			end)
		else
			frame:SetLayout(false)
			-- Single item
			local purchase = purchaseList[1]
			local itemTexture = select(10, GetItemInfo(purchase.reagent.itemID)) or "Interface\\Icons\\INV_Misc_QuestionMark"
			
			frame.icon:SetTexture(itemTexture)
			frame.text:SetText("Purchase reagent for |cffffffff" .. self:FormatMoneyWithIcons(totalCost) .. "|r?")
		frame.itemList:SetText(purchase.quantity .. "x |cff00ff00" .. purchase.reagent.name .. "|r")
			frame.buyEachButton:Hide()
			
			frame.buyButton:SetScript("OnClick", function()
				frame:Hide()
				self:ExecutePurchase(self.pendingPurchase)
				self.pendingPurchase = nil
			end)
		end
		
		frame:Show()
		return
	end
	
	-- Auto-buy enabled: Execute purchase immediately
	self:ExecutePurchase({purchaseList = purchaseList, totalCost = totalCost})
end

--[[
	Show next purchase dialog for individual purchases
]]--
function addon:ShowNextPurchaseDialog()
	if not self.pendingPurchase or not self.currentPurchaseIndex then
		return
	end
	
	local purchaseList = self.pendingPurchase.purchaseList
	if self.currentPurchaseIndex > #purchaseList then
		-- Done with all items
		self:Print("|cff00ff00Finished processing all reagents.|r")
		self.pendingPurchase = nil
		self.currentPurchaseIndex = nil
		return
	end
	
	local purchase = purchaseList[self.currentPurchaseIndex]
	local itemTexture = select(10, GetItemInfo(purchase.reagent.itemID)) or "Interface\\Icons\\INV_Misc_QuestionMark"
	
	local frame = self.purchaseFrame
	frame:SetLayout(false)
	frame.icon:SetTexture(itemTexture)
	frame.text:SetText("Purchase for |cffffffff" .. self:FormatMoneyWithIcons(purchase.cost) .. "|r?")
	frame.itemList:SetText(purchase.quantity .. "x |cff00ff00" .. purchase.reagent.name .. "|r\n\n|cffaaaaaa(" .. self.currentPurchaseIndex .. " of " .. #purchaseList .. ")|r")
	
	-- Change button layout for individual mode
	frame.buyButton:SetText("Buy")
	frame.buyButton:SetPoint("BOTTOMLEFT", 20, 15)
	frame.buyButton:SetScript("OnClick", function()
		if self:ExecuteSinglePurchase(purchase) then
			self.currentPurchaseIndex = self.currentPurchaseIndex + 1
			self:ShowNextPurchaseDialog()
		end
	end)
	
	frame.buyEachButton:SetText("Skip")
	frame.buyEachButton:Show()
	frame.buyEachButton:SetScript("OnClick", function()
		self.currentPurchaseIndex = self.currentPurchaseIndex + 1
		self:ShowNextPurchaseDialog()
	end)
	
	frame.cancelButton:SetText("Cancel All")
	frame.cancelButton:SetScript("OnClick", function()
		frame:Hide()
		self.pendingPurchase = nil
		self.currentPurchaseIndex = nil
	end)
	
	frame:Show()
end

--[[
	Execute a single purchase item
]]--
function addon:ExecuteSinglePurchase(purchase)
	-- Check if merchant is still available
	if not MerchantFrame or not MerchantFrame:IsShown() then
		self:Print("|cffff0000Error:|r Merchant window is closed. Cannot purchase items.")
		if self.purchaseFrame then
			self.purchaseFrame:Hide()
		end
		self.pendingPurchase = nil
		self.currentPurchaseIndex = nil
		return false
	end
	
	-- Purchase this item
	BuyMerchantItem(purchase.slot, purchase.quantity)
	
	if self.db.profile.showMessages then
		self:Print("  - " .. purchase.quantity .. "x |cff00ff00" .. purchase.reagent.name .. "|r (" .. self:FormatMoney(purchase.cost) .. ")")
	end
	return true
end

--[[
	Execute the actual purchase
]]--
function addon:ExecutePurchase(purchaseData)
	-- Check if merchant is still available
	if not MerchantFrame or not MerchantFrame:IsShown() then
		self:Print("|cffff0000Error:|r Merchant window is closed. Cannot purchase items.")
		if self.purchaseFrame then
			self.purchaseFrame:Hide()
		end
		self.pendingPurchase = nil
		return
	end
	
	local purchaseList = purchaseData.purchaseList
	local totalCost = purchaseData.totalCost
	
	-- Purchase items
	if self.db.profile.showMessages then
		self:Print("Purchasing reagents for " .. self:FormatMoney(totalCost) .. ":")
	end
	
	for _, purchase in ipairs(purchaseList) do
		-- Buy all items in one transaction
		BuyMerchantItem(purchase.slot, purchase.quantity)
		
		if self.db.profile.showMessages then
			self:Print("  - " .. purchase.quantity .. "x |cff00ff00" .. purchase.reagent.name .. "|r (" .. self:FormatMoney(purchase.cost) .. ")")
		end
	end
	
	if self.db.profile.showMessages then
		self:Print("|cff00ff00Successfully purchased reagents!|r")
	end
end

--[[
	Chat command handler
]]--
function addon:ChatCommand(input)
	if not input or input:trim() == "" then
		-- Open config
		addon:ShowConfig()
	else
		local cmd = input:lower()
		if cmd == "toggle" then
			self.db.profile.enabled = not self.db.profile.enabled
			self:Print("StockUp " .. (self.db.profile.enabled and "|cff00ff00enabled|r" or "|cffff0000disabled|r"))
		elseif cmd == "auto" then
			self.db.profile.autoBuy = not self.db.profile.autoBuy
			self:Print("Auto-buy " .. (self.db.profile.autoBuy and "|cff00ff00enabled|r" or "|cffff0000disabled|r"))
		elseif cmd == "vendors" or cmd == "vendor" then
			self:ShowVendorLocations()
		elseif cmd == "info" then
			self:ShowCharacterInfo()
		elseif cmd == "help" then
			self:Print("Commands:")
			self:Print("  /su - Open configuration")
			self:Print("  /su toggle - Enable/disable addon")
			self:Print("  /su auto - Toggle auto-buy")
			self:Print("  /su vendors - Show vendor locations for reagents")
			self:Print("  /su info - Show character and reagent info")
			self:Print("  /su help - Show this help")
		else
			self:Print("Unknown command. Type '/su help' for help.")
		end
	end
end

--[[
	Show vendor locations for reagents
]]--
function addon:ShowVendorLocations()
	if not self.Database or not self.classReagents or #self.classReagents == 0 then
		self:Print("No reagent data available.")
		return
	end
	
	self:Print("Reagent Vendors:")
	for _, reagent in ipairs(self.classReagents) do
		local locationStr = self.Database:GetVendorLocationString(reagent.itemID)
		self:Print("  |cff00ff00" .. reagent.name .. "|r: " .. locationStr)
	end
end

--[[
	Show character and reagent information
]]--
function addon:ShowCharacterInfo()
	self:Print("=== StockUp Character Info ===")
	self:Print("Character: |cff00ff00" .. (self.playerName or "Unknown") .. "|r")
	self:Print("Realm: |cff00ff00" .. (self.playerRealm or "Unknown") .. "|r")
	self:Print("Class: |cff00ff00" .. (self.playerClass or "Unknown") .. "|r")
	
	if self.classReagents and #self.classReagents > 0 then
		self:Print("Available Reagents: |cff00ff00" .. #self.classReagents .. "|r")
		
		-- Show best reagent
		local bestReagent = self:GetBestReagent()
		if bestReagent then
			self:Print("Recommended Reagent: |cff00ff00" .. bestReagent.name .. "|r")
		end
		
		-- Show inventory counts
		self:Print("Current Inventory:")
		for _, reagent in ipairs(self.classReagents) do
			local count = self:CountItemInBags(reagent.itemID)
			if count > 0 then
				self:Print("  " .. reagent.name .. ": |cff00ff00" .. count .. "|r")
			end
		end
	else
		self:Print("No reagents required for this class.")
	end
	
	-- Show settings
	self:Print("Settings:")
	self:Print("  Auto-Buy: " .. (self.db.profile.autoBuy and "|cff00ff00Enabled|r" or "|cffff0000Disabled|r"))
	self:Print("  Smart Buy: " .. (self.db.profile.smartBuy and "|cff00ff00Enabled|r" or "|cffff0000Disabled|r"))
	self:Print("  Purchase Amount: |cff00ff00" .. self.db.profile.purchaseAmount .. "|r")
end

--[[
	Show configuration window (placeholder - implemented in Config.lua)
]]--
function addon:ShowConfig()
	-- This will be implemented in Config.lua
	-- For now, show a message
	if self.OpenConfigDialog then
		self:OpenConfigDialog()
	else
		self:Print("Configuration UI will be available shortly. Use '/su toggle' and '/su auto' for now.")
	end
end
