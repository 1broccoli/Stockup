--[[
	StockUp Minimap Button
	LibDBIcon implementation with manual button control
]]--

local addon = _G.StockUp
if not addon then return end

-- Get LibDBIcon
local LibDBIcon = LibStub("LibDBIcon-1.0", true)
if not LibDBIcon then
	addon:Print("LibDBIcon not found, minimap button disabled")
	return
end

-- Initialize minimap button once db is ready
local function InitializeMinimapButton()
	if not addon.db then return end
	
	-- Create data object for LibDBIcon
	local dataObj = {
		type = "launcher",
		text = "StockUp",
		icon = "Interface\\AddOns\\StockUp\\Media\\stockup",
	}
	
	-- Register with LibDBIcon
	LibDBIcon:Register("StockUp", dataObj, addon.db.profile.minimap)
	
	-- Get the button created by LibDBIcon
	local button = LibDBIcon:GetMinimapButton("StockUp")
	if not button then return end
	
	-- Tooltip display function
	local function ShowTooltip()
		GameTooltip:SetOwner(button, "ANCHOR_LEFT")
		GameTooltip:SetText("StockUp", 1, 1, 1)
		GameTooltip:AddLine("v" .. addon.version, 0.5, 0.5, 0.5)
		GameTooltip:AddLine(" ")
		
		if addon.db.profile.enabled then
			GameTooltip:AddLine("|cff00ff00Enabled|r", 1, 1, 1)
		else
			GameTooltip:AddLine("|cffff0000Disabled|r", 1, 1, 1)
		end
		
		if addon.db.profile.autoBuy then
			GameTooltip:AddLine("Auto-buy: |cff00ff00ON|r", 1, 1, 1)
		else
			GameTooltip:AddLine("Auto-buy: |cffff0000OFF|r", 1, 1, 1)
		end
		
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("|cffffcc00Left-Click:|r Open Config", 0.8, 0.8, 0.8)
		GameTooltip:AddLine("|cffffcc00Right-Click:|r Toggle Addon", 0.8, 0.8, 0.8)
		GameTooltip:AddLine("|cffffcc00Shift-Right-Click:|r Toggle Auto-Buy", 0.8, 0.8, 0.8)
		GameTooltip:AddLine("|cffffcc00Drag:|r Move Button", 0.8, 0.8, 0.8)
		GameTooltip:Show()
	end
	
	-- Set up mouse enter/leave for tooltip
	button:SetScript("OnEnter", function(self)
		ShowTooltip()
	end)
	
	button:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)
	
	-- Override the click handler for proper functionality
	button:SetScript("OnClick", function(self, clickButton)
		if clickButton == "LeftButton" then
			-- Toggle config dialog
			local AceConfigDialog = LibStub("AceConfigDialog-3.0", true)
			if AceConfigDialog then
				-- Check if the frame is already open in OpenFrames
				local isOpen = AceConfigDialog.OpenFrames and AceConfigDialog.OpenFrames["StockUp"]
				if isOpen then
					AceConfigDialog:Close("StockUp")
				else
					AceConfigDialog:Open("StockUp")
				end
			else
				addon:ShowConfig()
			end
		elseif clickButton == "RightButton" then
			if IsShiftKeyDown() then
				-- Toggle auto-buy
				addon.db.profile.autoBuy = not addon.db.profile.autoBuy
				addon:Print("Auto-buy " .. (addon.db.profile.autoBuy and "|cff00ff00enabled|r" or "|cffff0000disabled|r"))
			else
				-- Toggle addon
				addon.db.profile.enabled = not addon.db.profile.enabled
				addon:Print("StockUp " .. (addon.db.profile.enabled and "|cff00ff00enabled|r" or "|cffff0000disabled|r"))
			end
			-- Refresh tooltip if it's showing
			if GameTooltip:IsOwned(self) then
				ShowTooltip()
			end
		end
	end)
	
	-- Store reference if needed
	addon.minimapButton = button
end

-- Wait for addon to be fully initialized before setting up minimap
addon:RegisterEvent("ADDON_LOADED", function(event, name)
	if name == "StockUp" and addon.db then
		InitializeMinimapButton()
		addon:UnregisterEvent("ADDON_LOADED")
	end
end)

-- Function to toggle minimap button
function addon:ToggleMinimapButton()
	if not addon.db then return end
	self.db.profile.minimap.hide = not self.db.profile.minimap.hide
	if self.db.profile.minimap.hide then
		LibDBIcon:Hide("StockUp")
	else
		LibDBIcon:Show("StockUp")
	end
end




