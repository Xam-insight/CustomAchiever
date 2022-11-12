local ACD = LibStub("AceConfigDialog-3.0")

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(self, event, addon)
	if not strmatch(addon,"CustomAchiever") then return end
	-- Initialize the saved variables
	local defaults = {
		minimapIcon = {
			hide = true,
			minimapPos = 220,
		}
	}
	if not CustomAchieverOptionsData then
		CustomAchieverOptionsData = {}
	end
	if not CustomAchieverOptionsData["CustomAchieverMIcon"] then
		CustomAchieverOptionsData["CustomAchieverMIcon"] = defaults
	else
		for k, v in pairs(defaults) do
			if CustomAchieverOptionsData["CustomAchieverMIcon"][k] == nil or type(CustomAchieverOptionsData["CustomAchieverMIcon"][k]) ~= type(v) then
				CustomAchieverOptionsData["CustomAchieverMIcon"][k] = v
			end
		end
	end
 
	-- Create the data object
	local obj = LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject("CustomAchiever", {
		type = "launcher",
		icon = "interface\\friendsframe\\friendsframescrollicon",
		tocname = "CustomAchiever",
		OnClick = function(self, button)
			if button == "LeftButton" then
				if CustomAchieverFrame:IsShown() then
					CustomAchieverFrame:Hide()
				else
					CustomAchieverFrame:Show()
				end
			else
				ACD:Open("CustomAchiever")
			end
		end,
		OnTooltipShow = function(tooltip)
			tooltip:AddLine("Custom Achiever", 1.0, 1.0, 1.0)
		end,
		OnLeave = function()
			CustAc_saveCustomAchieverOptionsDataForAddon()
		end,
	})
 
	-- Register the data object for a minimap button
	LibStub("LibDBIcon-1.0"):Register("CustomAchiever", obj, CustomAchieverOptionsData["CustomAchieverMIcon"].minimapIcon)

	-- Clean up after ourselves
	self:UnregisterEvent("ADDON_LOADED")
	self:SetScript("OnEvent", nil)
end)
