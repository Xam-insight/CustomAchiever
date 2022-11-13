local L = LibStub("AceLocale-3.0"):GetLocale("CustomAchiever", true)

CustomAchieverHelpTip = {}

do
	local function CustomAchieverHelpTipReset(framePool, frame)
		frame:ClearAllPoints()
		frame:Hide()
		frame:Reset()
	end

	CustomAchieverHelpTip.framePool = CreateFramePool("FRAME", nil, "CustomAchieverHelpTipTemplate", CustomAchieverHelpTipReset)
end

function CustomAchieverHelpTip:Show(parent, info, relativeRegion, force)
	assert(info and info.text, "Invalid helptip info")
	assert((info.bitfieldFlag ~= nil and info.cvarBitfield ~= nil) or (info.bitfieldFlag == nil and info.cvarBitfield == nil))

	if not self:CanShow(info, force) then
		return false
	end

	if self:IsShowing(parent, info.text) then
		return true
	end

	local frame = self.framePool:Acquire()
	frame.width = HelpTip.width + (info.extraRightMarginPadding or 0)
	frame:SetWidth(frame.width)
	frame:Init(parent, info, relativeRegion or parent)

	local offLeft = frame:GetLeft()
	local offRight = GetScreenWidth() - frame:GetRight()
	local offTop = GetScreenHeight() - frame:GetTop()
	local offBottom = frame:GetBottom()

	local oldTargetPoint = info.targetPoint
	local oldOffsetX = info.offsetX
	local oldOffsetY = info.offsetY
	local newTargetPoint = info.targetPoint
	local newOffsetX = info.offsetX
	local newOffsetY = info.offsetY
	if ( offLeft < 0 ) then
		newTargetPoint = HelpTip.Point.RightEdgeCenter
		--newOffsetX = -newOffsetX
	elseif ( offRight < 0 ) then
		newTargetPoint = HelpTip.Point.LeftEdgeCenter
		--newOffsetX = -newOffsetX
	elseif ( offTop < 0 ) then
		newTargetPoint = HelpTip.Point.BottomEdgeCenter
		newOffsetY = -newOffsetY
	elseif ( offBottom < 0 ) then
		newTargetPoint = HelpTip.Point.TopEdgeCenter
		newOffsetY = -newOffsetY
	end

	if oldTargetPoint ~= newTargetPoint then
		info.targetPoint = newTargetPoint
		info.offsetX = newOffsetX
		info.offsetY = newOffsetY
		frame:Init(parent, info, relativeRegion or parent)
		info.targetPoint = oldTargetPoint
		info.offsetX = oldOffsetX
		info.offsetY = oldOffsetY
	end

	frame:Show()

	return true
end

function CustomAchieverHelpTip:CanShow(info, force)
	if Kiosk.IsEnabled() then
		return false
	end

	if not force and CustomAchieverOptionsData["MenuTutoDisabled"] then
		return false
	end

	if info.checkCVars then
		if info.cvar then
			if GetCVar(info.cvar) ~= info.cvarValue then
				return false
			end
		end
		if info.cvarBitfield then
			if GetCVarBitfield(info.cvarBitfield, info.bitfieldFlag) then
				return false
			end
		end
	end

	-- priority
	if info.system and info.systemPriority then
		for frame in self.framePool:EnumerateActive() do
			if frame.info.system == info.system and frame.info.systemPriority then
				if info.systemPriority > frame.info.systemPriority then
					frame:Close()
					-- by design there can only be one such frame, no need to keep going
					break
				else
					-- higher or equal priority is already shown
					return false
				end
			end
		end
	end

	return true
end

function CustomAchieverHelpTip:IsShowing(parent, text)
	for frame in self.framePool:EnumerateActive() do
		if frame:Matches(parent, text) then
			return true
		end
	end
	return false
end

function CustomAchieverHelpTip:IsShowingAny(parent)
	for frame in self.framePool:EnumerateActive() do
		if frame:Matches(parent) then
			return true
		end
	end
	return false
end

function CustomAchieverHelpTip:HideAll(parent)
	local framesToClose = { }

	for frame in self.framePool:EnumerateActive() do
		if frame:Matches(parent) then
			tinsert(framesToClose, frame)
		end
	end

	for i, frame in ipairs(framesToClose) do
		frame:Close()
	end
end

function CustomAchieverHelpTip:Hide(parent, text)
	for frame in self.framePool:EnumerateActive() do
		if frame:Matches(parent, text) then
			frame:Close()
			break
		end
	end
end

local custacHelpTipsInfo = {}
local defaultMenuHelpTipOffsetX = -10

if HelpTip then
	custacHelpTipsInfo = {
		["CUSTAC_HELPTIP_AWARD"] = {
			["info"] = {
				text = L["CUSTAC_HELPTIP_AWARD"], -- |TInterface\\Buttons\\UI-Panel-SmallerButton-Up:15:15:0:0:32:32:7:25:8:26|t 
				buttonStyle = HelpTip.ButtonStyle.GotIt,
				targetPoint = HelpTip.Point.BottomEdgeCenter,
				useParentStrata = true,
				onAcknowledgeCallback = function() custacAcknowledgeHelpTip("CUSTAC_HELPTIP_AWARD") end,
				offsetX = 0,
				offsetY = 0,
			},
			["relativeRegion"] = "CustomAchieverFrameAwardButton",
			["group"] = "CustomAchieverFrame",
			["parent"] = "custacHelpToolTipFrame"
		},
	}
end

local custacPlayerSpecFrame_HelpPlate = {
	FramePos = { x = 0,	y = -22 },
	FrameSize = { width = 645, height = 446	},
	[1] = { ButtonPos = { x = 88,	y = -22 }, HighLightBox = { x = 8, y = -30, width = 204, height = 382 },	ToolTipDir = "UP",		ToolTipText = SPEC_FRAME_HELP_1 },
	[2] = { ButtonPos = { x = 570,	y = -22 }, HighLightBox = { x = 224, y = -6, width = 414, height = 408 },	ToolTipDir = "RIGHT",	ToolTipText = SPEC_FRAME_HELP_2 },
	[3] = { ButtonPos = { x = 355,	y = -409}, HighLightBox = { x = 268, y = -418, width = 109, height = 26 },	ToolTipDir = "RIGHT",	ToolTipText = SPEC_FRAME_HELP_3 },
}

custacHelpToolTipFrame = CreateFrame("Frame", "CustomAchieverHelpToolTipFrame", UIParent)
custacHelpToolTipFrame:SetFrameStrata("LOW")

custacHelpToolTipFrameMouseOver = CreateFrame("Frame", "CustomAchieverHelpToolTipFrame", UIParent)
custacHelpToolTipFrameMouseOver:SetFrameStrata("LOW")

function custacSetHelpTipFramesStrata(strata)
	custacHelpToolTipFrame:SetFrameStrata(strata)
	custacHelpToolTipFrameMouseOver:SetFrameStrata(strata)
end

function custacInitializeHelp()
	--custacShowHelpTip("DEADPOOLTUTO_MINIMIZE")
end

function custacIsShowingHelpTips()
	if HelpTip then
		return CustomAchieverHelpTip:IsShowingAny(custacHelpToolTipFrame)
	end
end

function custacShowAllHelpTips()
	--custacShowHelpTip("DEADPOOLTUTO_MINIMIZE", true)
end

function custacHideAllHelpTips()
	if HelpTip then
		CustomAchieverHelpTip:HideAll(custacHelpToolTipFrame)
	end
end

function custacShowHelpTip(helpTip, force, relativeRegion, hideOther)
	if HelpTip then
		if custacHelpTipsInfo[helpTip] then
			if (not CustomAchieverData["Tutorial"][helpTip] or force) and _G[custacHelpTipsInfo[helpTip]["group"]]:IsShown() then
				if hideOther then
					HelpTip:HideAll(_G[custacHelpTipsInfo[helpTip]["parent"]])
				end
				CustomAchieverHelpTip:Show(_G[custacHelpTipsInfo[helpTip]["parent"]], custacHelpTipsInfo[helpTip]["info"], relativeRegion or _G[custacHelpTipsInfo[helpTip]["relativeRegion"]], force)
			end
		end
	end
end

function custacShowMenuHelpTip(helpTip, force, relativeRegion, offsetX)
	if HelpTip and not CustomAchieverOptionsData["MenuTutoDisabled"] then
		custacHelpTipsInfo["MENU_HELPTIP"]["info"]["offsetX"] = defaultMenuHelpTipOffsetX + (offsetX or 0)
		custacHelpTipsInfo["MENU_HELPTIP"]["info"]["text"] = helpTip
		if (not CustomAchieverData["Tutorial"][helpTip] or force) and _G[custacHelpTipsInfo["MENU_HELPTIP"]["group"]]:IsShown() then
			CustomAchieverHelpTip:Show(_G[custacHelpTipsInfo["MENU_HELPTIP"]["parent"]], custacHelpTipsInfo["MENU_HELPTIP"]["info"], relativeRegion or _G[custacHelpTipsInfo["MENU_HELPTIP"]["relativeRegion"]], force)
		end
	end
end

function custacAcknowledgeHelpTip(helpTip)
	if HelpTip then
		CustomAchieverData["Tutorial"][helpTip] = "Done"
	end
end

function closeMenuHelpTip(helpTip)
	CustomAchieverHelpTip:Hide(L_DropDownList1, helpTip)
end
