local ACD = LibStub("AceConfigDialog-3.0")

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(self, event, addon)
	if addon ~= "CustomAchiever" then return end
	-- Initialize the saved variables
	local defaults = {
		minimapIcon = {
			hide = false,
			minimapPos = 220,
		}
	}
	if not CustomAchieverMIcon then
		CustomAchieverMIcon = defaults
	else
		for k, v in pairs(defaults) do
			if CustomAchieverMIcon[k] == nil or type(CustomAchieverMIcon[k]) ~= type(v) then
				CustomAchieverMIcon[k] = v
			end
		end
	end
 
	-- Create the data object
	local obj = LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject("CustomAchiever", {
		type = "launcher",
		icon = "interface\\friendsframe\\friendsframescrollicon",
		tocname = "CustomAchiever",
		OnClick = function(self, button)
			if false --[[TEMP button == "LeftButton"--]] then
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
	})
 
	-- Register the data object for a minimap button
	LibStub("LibDBIcon-1.0"):Register("CustomAchiever", obj, CustomAchieverMIcon.minimapIcon)

	-- Clean up after ourselves
	self:UnregisterEvent("ADDON_LOADED")
	self:SetScript("OnEvent", nil)
end)
