local L = LibStub("AceLocale-3.0"):GetLocale("CustomAchiever", true)
local ACD = LibStub("AceConfigDialog-3.0")
local LibDBIcon = LibStub("LibDBIcon-1.0")

local function getAnchors(frame)
	local x, y = frame:GetCenter()
	if not x or not y then return "CENTER" end
	local hhalf = (x > UIParent:GetWidth()*2/3) and "RIGHT" or (x < UIParent:GetWidth()/3) and "LEFT" or ""
	local vhalf = (y > UIParent:GetHeight()/2) and "TOP" or "BOTTOM"
	return vhalf..hhalf, frame, (vhalf == "TOP" and "BOTTOM" or "TOP")..hhalf
end

local function onEnter(self)
	local obj = self.dataObject
	if obj.OnTooltipShow then
		LibDBIcon.tooltip:SetOwner(self, "ANCHOR_NONE")
		LibDBIcon.tooltip:SetPoint(getAnchors(self))
		obj.OnTooltipShow(LibDBIcon.tooltip)
		LibDBIcon.tooltip:Show()
	elseif obj.OnEnter then
		obj.OnEnter(self)
	end
end

local function onLeave(self)
	LibDBIcon.tooltip:Hide()
end

local function onClick(self, b)
	if self.dataObject.OnClick then
		self.dataObject.OnClick(self, b)
	end
end

local function createCustacButton(object)
	local button = CreateFrame("Button", "CustacButton")
	button.dataObject = object
	button:SetFrameStrata("MEDIUM")
	button:SetFixedFrameStrata(true)
	button:SetFrameLevel(8)
	button:SetFixedFrameLevel(true)
	button:SetSize(31, 31)
	button:RegisterForClicks("anyUp")
	button:SetHighlightTexture(136477) --"Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight"
	if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
		local overlay = button:CreateTexture(nil, "OVERLAY")
		overlay:SetSize(50, 50)
		overlay:SetTexture(136430) --"Interface\\Minimap\\MiniMap-TrackingBorder"
		overlay:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
		local background = button:CreateTexture(nil, "BACKGROUND")
		background:SetSize(24, 24)
		background:SetTexture(136467) --"Interface\\Minimap\\UI-Minimap-Background"
		background:SetPoint("CENTER", button, "CENTER", 0, 1)
		local icon = button:CreateTexture(nil, "ARTWORK")
		icon:SetSize(18, 18)
		icon:SetTexture(object.icon)
		icon:SetPoint("CENTER", button, "CENTER", 0, 1)
		button.icon = icon
	else
		local overlay = button:CreateTexture(nil, "OVERLAY")
		overlay:SetSize(53, 53)
		overlay:SetTexture(136430) --"Interface\\Minimap\\MiniMap-TrackingBorder"
		overlay:SetPoint("TOPLEFT")
		local background = button:CreateTexture(nil, "BACKGROUND")
		background:SetSize(20, 20)
		background:SetTexture(136467) --"Interface\\Minimap\\UI-Minimap-Background"
		background:SetPoint("TOPLEFT", 7, -5)
		local icon = button:CreateTexture(nil, "ARTWORK")
		icon:SetSize(17, 17)
		icon:SetTexture(object.icon)
		icon:SetPoint("TOPLEFT", 7, -6)
		button.icon = icon
	end

	button.isMouseDown = false
	local r, g, b = button.icon:GetVertexColor()
	button.icon:SetVertexColor(object.iconR or r, object.iconG or g, object.iconB or b)

	button:SetScript("OnEnter", onEnter)
	button:SetScript("OnLeave", onLeave)
	button:SetScript("OnClick", onClick)
	button:SetScript("OnMouseDown", onMouseDown)
	button:SetScript("OnMouseUp", onMouseUp)

	button.fadeOut = button:CreateAnimationGroup()
	local animOut = button.fadeOut:CreateAnimation("Alpha")
	animOut:SetOrder(1)
	animOut:SetDuration(0.2)
	animOut:SetFromAlpha(1)
	animOut:SetToAlpha(0)
	animOut:SetStartDelay(1)
	button.fadeOut:SetToFinalAlpha(true)
end

--local eventFrame = CreateFrame("Frame")
--eventFrame:RegisterEvent("ADDON_LOADED")
--eventFrame:SetScript("OnEvent", function(self, event, addon)
function CustAc_CreateMinimapButton()
	--if not strmatch(addon,"CustomAchiever") then return end
	-- Initialize the saved variables
	local defaults = {
		minimapIcon = {
			hide = false,
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
			tooltip:AddLine(L["MINIMAP_TOOLTIP1"])
			tooltip:AddLine(L["MINIMAP_TOOLTIP2"])
		end,
		OnLeave = function()
			CustAc_saveCustomAchieverOptionsDataForAddon()
		end,
	})
 
	-- Register the data object for a minimap button
	LibDBIcon:Register("CustomAchiever", obj, CustomAchieverOptionsData["CustomAchieverMIcon"].minimapIcon)

	-- Create button for Achievements frame
	createCustacButton(obj)

	-- Clean up after ourselves
	--self:UnregisterEvent("ADDON_LOADED")
	--self:SetScript("OnEvent", nil)
end

