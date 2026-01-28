--[[
	StockUp Configuration UI
	Uses Ace3 libraries to create a configuration interface
]]--

local addon = _G.StockUp
if not addon then return end

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

-- Configuration options table
local options = {
	name = "StockUp",
	handler = addon,
	type = "group",
	args = {
		header = {
			order = 1,
			type = "header",
			name = "StockUp v" .. addon.version,
		},
		description = {
			order = 2,
			type = "description",
			name = "Automatically purchase class-specific reagents from vendors.\n",
		},
		enabled = {
			order = 3,
			type = "toggle",
			name = "Enable Addon",
			desc = "Enable or disable StockUp",
			get = function() return addon.db.profile.enabled end,
			set = function(info, value)
				addon.db.profile.enabled = value
				addon:Print("StockUp " .. (value and "|cff00ff00enabled|r" or "|cffff0000disabled|r"))
			end,
			width = "full",
		},
		autoBuy = {
			order = 4,
			type = "toggle",
			name = "Auto-Buy at Vendors",
			desc = "Automatically purchase reagents when opening a vendor window",
			get = function() return addon.db.profile.autoBuy end,
			set = function(info, value)
				addon.db.profile.autoBuy = value
			end,
			width = "full",
			disabled = function() return not addon.db.profile.enabled end,
		},
		smartBuy = {
			order = 5,
			type = "toggle",
			name = "Smart Buy Mode",
			desc = "Only buy reagents you don't already have (up to the purchase amount)",
			get = function() return addon.db.profile.smartBuy end,
			set = function(info, value)
				addon.db.profile.smartBuy = value
			end,
			width = "full",
			disabled = function() return not addon.db.profile.enabled end,
		},
		showMessages = {
			order = 6,
			type = "toggle",
			name = "Show Chat Messages",
			desc = "Display purchase information in chat",
			get = function() return addon.db.profile.showMessages end,
			set = function(info, value)
				addon.db.profile.showMessages = value
			end,
			width = "full",
			disabled = function() return not addon.db.profile.enabled end,
		},
		hideMinimapButton = {
			order = 7,
			type = "toggle",
			name = "Hide Minimap Button",
			desc = "Hide the minimap button",
			get = function() return addon.db.profile.minimap.hide end,
			set = function(info, value)
				addon.db.profile.minimap.hide = value
				if addon.ToggleMinimapButton then
					addon:ToggleMinimapButton()
				end
			end,
			width = "full",
		},
		spacer1 = {
			order = 10,
			type = "header",
			name = "Reagent Amounts",
		},
		reagentAmountsInfo = {
			order = 21,
			type = "description",
			name = function()
				if not addon.classReagents or #addon.classReagents == 0 then
					return "|cffff0000Your class does not require reagents.|r"
				end
				
				local bestReagent = addon:GetBestReagent()
				if bestReagent then
					return "Recommended reagent: |cff00ff00" .. bestReagent.name .. "|r\n\nSet how many of each reagent to purchase. With Smart Buy enabled, the addon will only buy what you need to reach these amounts.\n"
				else
					return "Set how many of each reagent to purchase. With Smart Buy enabled, the addon will only buy what you need to reach these amounts.\n"
				end
			end,
		},
		reagentAmounts = {
			order = 22,
			type = "group",
			name = "Purchase Amounts",
			inline = true,
			disabled = function() return not addon.db.profile.enabled end,
			args = {},
		},
	},
}

-- Dynamically add reagent selection options
function addon:BuildReagentOptions()
	if not self.classReagents or #self.classReagents == 0 then
		return
	end
	
	-- Clear existing options
	options.args.reagentAmounts.args = {}
	
	-- Add options for each reagent
	for i, reagent in ipairs(self.classReagents) do
		local key = "reagent_" .. reagent.itemID
		
		-- Get vendor info from database if available
		local vendorInfo = ""
		if self.Database then
			local vendorStr = self.Database:GetVendorLocationString(reagent.itemID)
			if vendorStr and vendorStr ~= "No vendors found" then
				vendorInfo = "\nVendor: " .. vendorStr
			end
		end
		
		-- Get item icon
		local itemIcon = select(10, GetItemInfo(reagent.itemID)) or "Interface\\Icons\\INV_Misc_QuestionMark"
		
		-- Combined amount slider with icon
		options.args.reagentAmounts.args[key] = {
			order = i,
			type = "range",
			name = function()
				local icon = select(10, GetItemInfo(reagent.itemID)) or "Interface\\Icons\\INV_Misc_QuestionMark"
				return "|T" .. icon .. ":20|t " .. reagent.name
			end,
			desc = "How many " .. reagent.name .. " to keep in stock (Level " .. (reagent.minLevel or "?") .. " reagent)" .. vendorInfo .. (reagent.stackSize > 1 and "\n|cffaaaaaa(Sold in stacks of " .. reagent.stackSize .. ")|r" or ""),
			icon = itemIcon,
			min = 0,
			max = 500,
			step = reagent.stackSize or 1,  -- Use actual stack size for slider increments
			get = function()
				-- Return custom amount if set, otherwise default
				return addon.db.profile.customAmounts[reagent.itemID] or addon.db.profile.purchaseAmount
			end,
			set = function(info, value)
				-- Store as custom amount
				addon.db.profile.customAmounts[reagent.itemID] = value
				-- Auto-enable this reagent if amount is set above 0
				if value > 0 then
					addon.db.profile.selectedReagents[reagent.itemID] = true
				end
			end,
			width = "full",
		}
	end
	
	-- Add reset button
	options.args.reagentAmounts.args.resetAll = {
		order = 100,
		type = "execute",
		name = "Reset All to Default",
		desc = "Reset all reagent amounts to use the default purchase amount",
		func = function()
			addon.db.profile.customAmounts = {}
			addon.db.profile.selectedReagents = {}
			addon:Print("Reset all reagent amounts to default.")
		end,
	}
end

-- Register options
function addon:RegisterOptions()
	-- Build reagent-specific options
	self:BuildReagentOptions()
	
	-- Register with AceConfig
	AceConfig:RegisterOptionsTable("StockUp", options)
	self.optionsFrame = AceConfigDialog:AddToBlizOptions("StockUp", "StockUp")
	
	-- Add to Blizzard interface options
	self:Print("Configuration available via /su or Interface Options")
end

-- Open config dialog
function addon:OpenConfigDialog()
	-- Use AceConfigDialog to open the window (works on all versions)
	local AceConfigDialog = LibStub("AceConfigDialog-3.0")
	AceConfigDialog:Open("StockUp")
end

-- Initialize config on addon load
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event)
	if event == "PLAYER_LOGIN" then
		addon:RegisterOptions()
	end
end)
