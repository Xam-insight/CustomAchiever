CustomAchiever = LibStub("AceAddon-3.0"):NewAddon("CustomAchiever", "AceConsole-3.0", "AceEvent-3.0", "AceComm-3.0", "AceSerializer-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("CustomAchiever", true)
local AceGUI = LibStub("AceGUI-3.0")
local ACD = LibStub("AceConfigDialog-3.0")

CustomAchieverGlobal_CommPrefix = "CustomAchiever"

customAchieverFramePool = {}
local customAchieverDressUpModelPool = {}
CustomAchieverGlobal_BetweenObjectsGap = 11

CUSTOMACHIEVER_NUM_LINES = 40
local CUSTOMACHIEVER_LINE_WIDTH = 96

local CUSTOMACHIEVER_COL1_WIDTH = 110 -- + Portrait !
local CUSTOMACHIEVER_COL2_WIDTH = 4*32 + 5
local CUSTOMACHIEVER_COL4_WIDTH = 40
local CUSTOMACHIEVER_ALLCOLS_WIDTH = CUSTOMACHIEVER_COL1_WIDTH -- + Portrait !
	+ CUSTOMACHIEVER_COL2_WIDTH
	+ CUSTOMACHIEVER_COL4_WIDTH

CustAc_Krowi_Loaded = false
function CustomAchiever:OnInitialize()
	-- Called when the addon is loaded
	self:RegisterChatCommand("custac", "CustomAchieverChatCommand")
	self:RegisterComm(CustomAchieverGlobal_CommPrefix, "ReceiveDataFrame_OnEvent")
	--self:RegisterEvent("PLAYER_ENTERING_WORLD", "CallForCustomAchieverData")
	self:RegisterEvent("GUILD_ROSTER_UPDATE", "OnGuildRosterUpdate")
	self:RegisterEvent("PLAYER_LOGOUT", "OnPlayerLogout")

	self:RegisterEvent("ADDON_LOADED", function(event, arg)
		if(arg == "Krowi_AchievementFilter") then
			--WATCHED_ADDON = "Overachiever_Tabs" -- Overachiever no longer supported. >> Krowi_AchievementFilter
			CustAc_Krowi_Loaded = true
		end
		if(arg == "Blizzard_AchievementUI") then
			self:UnregisterEvent("ADDON_LOADED")
			CustAc_AchievementFrame_Load()
		end
	end)
end

function CustomAchiever:OnGuildRosterUpdate()
	CustAc_SendCallForUsers()
	self:UnregisterEvent("GUILD_ROSTER_UPDATE")
end

function CustomAchiever:OnPlayerLogout()
	for i=1, GetNumAddOns() do
		local name, title, notes, loadable, reason, security, newVersion = GetAddOnInfo(i)
		if strmatch(name,"_CustomAchiever") then
			local addOn    = gsub(name, "_CustomAchiever", "")
			local dataTime = time()
			_G[addOn.."_CustomAchieverData"]                    = CustomAchieverData
			_G[addOn.."_CustomAchieverData"]["dataTime"]        = dataTime
			_G[addOn.."_CustomAchieverOptionsData"]             = CustomAchieverOptionsData
			_G[addOn.."_CustomAchieverOptionsData"]["dataTime"] = dataTime
		end
	end
end

function CustomAchiever:OnEnable()
	-- Called when the addon is enabled
	if not CustomAchieverFrame then
		initCustomAchieverBusinessObjects()
        loadCustomAchieverOptions()

		--NewCustomAchieverFrame
		CustomAchieverFrame = CreateFrame("Frame", "CustomAchieverFrame", UIParent, "CustomAchieverFrameTemplate")
		CustomAchieverTargetTooltip:SetScale(0.8)
		CustomAchieverTargetTooltip:SetParent(CustomAchieverFrame)

		CustomAchiever:Print(L["CUSTOMACHIEVER_WELCOME"])
		CustomAchiever:LoadAddonsData()
		
		hooksecurefunc("TargetUnit", CustAc_TargetUnit)
		
		TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, CustAc_OnTooltipUnit)
		GameTooltip:HookScript("OnShow", CustAc_CommunitiesMemberOnEnter)
	end
	CustAc_CreateMinimapButton()
end

function CustAc_CommunitiesMemberOnEnter()
	local mouseFocus = GetMouseFocus()
	if mouseFocus and mouseFocus["memberInfo"] and mouseFocus["memberInfo"]["clubType"] == 2 and mouseFocus["memberInfo"]["name"] then
		local unitFullName = CustAc_addRealm(mouseFocus["memberInfo"]["name"])
		if CustomAchieverData["Users"][unitFullName] then
			GameTooltip:AddDoubleLine("CustomAchiever", CustomAchieverData["Users"][unitFullName], 0, 1, 0, 0, 1, 0)
			GameTooltip:Show()
		end
	end
end

function CustAc_OnTooltipUnit(tooltip, data)
	local unitName, unitId = GameTooltip:GetUnit()
	local unitFullName = CustAc_addRealm(unitName)
	if CustomAchieverData["Users"][unitFullName] then
		tooltip:AddDoubleLine("CustomAchiever", CustomAchieverData["Users"][unitFullName], 0, 1, 0, 0, 1, 0)
	end
end

function CustomAchiever:LoadAddonsData()
	local newCustomAchieverData, optionsDataToMerge
	for i=1, GetNumAddOns() do
		local name, title, notes, loadable, reason, security, newVersion = GetAddOnInfo(i)
		if strmatch(name,"_CustomAchiever") then
			local sourceAddonName = gsub(name, "_CustomAchiever", "")
			local data = _G[sourceAddonName.."_CustomAchieverData"]
			if data then
				local dataTime        = data["dataTime"] or time()
				local currentDataTime = CustomAchieverData["dataTime"] or 0
				if dataTime ~= currentDataTime then
					newCustomAchieverData = newCustomAchieverData or CustomAchieverData
					for k,v in pairs(data["Categories"]) do
						local import
						if newCustomAchieverData["Categories"][k] then
							local thisDataTime        = v["dataTime"] or dataTime
							local thisCurrentDataTime = (newCustomAchieverData[k] and newCustomAchieverData[k]["dataTime"]) or currentDataTime
							if thisDataTime > thisCurrentDataTime then
								import = true
							end
						else
							import = true
						end
						if import then
							newCustomAchieverData["Categories"][k] = v
							if data["PendingUpdates"] and data["PendingUpdates"][k]           then newCustomAchieverData["PendingUpdates"][k]      = data["PendingUpdates"][k] end
							if data["AwardedPlayers"] and data["AwardedPlayers"][k]           then newCustomAchieverData["AwardedPlayers"][k]      = data["AwardedPlayers"][k] end
							if data["PersonnalCategories"] and data["PersonnalCategories"][k] then newCustomAchieverData["PersonnalCategories"][k] = data["PersonnalCategories"][k] end
						end
					end
					
					for k,v in pairs(data["Achievements"]) do
						local import
						if newCustomAchieverData["Achievements"][k] then
							local thisDataTime        = v["dataTime"] or dataTime
							local thisCurrentDataTime = (newCustomAchieverData[k] and newCustomAchieverData[k]["dataTime"]) or currentDataTime
							if thisDataTime > thisCurrentDataTime then
								import = true
							end
						else
							import = true
						end
						if import then
							newCustomAchieverData["Achievements"][k] = v
							if data["PendingUpdates"] and data["PendingUpdates"][k] then newCustomAchieverData["PendingUpdates"][k] = data["PendingUpdates"][k] end
							if data["AwardedPlayers"] and data["AwardedPlayers"][k] then newCustomAchieverData["AwardedPlayers"][k] = data["AwardedPlayers"][k] end
						end
					end

					if data["Users"] then
						for k,v in pairs(data["Users"]) do
							if not newCustomAchieverData["Users"][k] then
								newCustomAchieverData["Users"][k] = v
							end
						end
					end
				end
			end
			local optionsData = _G[sourceAddonName.."_CustomAchieverOptionsData"]
			if optionsData then
				local addonDataTime  = optionsData["dataTime"]
				local custacDataTime = CustomAchieverOptionsData["dataTime"]
				local optionsDataToMergeDataTime = optionsDataToMerge and optionsDataToMerge["dataTime"]
				if addonDataTime and (not custacDataTime or tonumber(custacDataTime) < tonumber(addonDataTime)) and (not optionsDataToMergeDataTime or tonumber(optionsDataToMergeDataTime) < tonumber(addonDataTime)) then
					optionsDataToMerge = optionsData
				end
			end
		end
	end
	if optionsDataToMerge then
		CustomAchieverOptionsData = optionsDataToMerge
		applyCustomAchieverWindowOptions()
	end
	if newCustomAchieverData then
		CustomAchieverData = newCustomAchieverData
		CustAc_LoadAchievementsData("CustAc_CreateOrUpdateAchievement")
		CustAc_RefreshCustomAchiementFrame()
	end
end

function showIconSelector()
	if not MacroFrame then
		MacroFrame_LoadUI()
	end
	if not CustAc_IconsPopupFrame then
		CustAc_IconsPopupFrame = CreateFrame("Frame", "CustAc_IconsPopupFrame", CustomAchieverFrame, "CustAc_IconsPopupFrameTemplate")
		--CustAc_IconsPopupFrame.BorderBox.EditBoxHeaderText:SetText("tmp")
		CustAc_IconsPopupFrame.BorderBox.IconSelectorEditBox:SetMaxLetters(30) 
		CustAc_IconsPopupFrame.BorderBox.OkayButton:SetScript("OnClick", function()
			PlaySound(SOUNDKIT.GS_TITLE_OPTION_OK)
			CustAc_IconsPopupFrame_OkayButton_OnClick(self)
		end)
		CustAc_IconsPopupFrame.BorderBox.IconSelectorEditBox:SetScript("OnEnterPressed", function()
			PlaySound(SOUNDKIT.GS_TITLE_OPTION_OK)
			CustAc_IconsPopupFrame_OkayButton_OnClick(self)
		end)
	end
	CustAc_IconsPopupFrame:Show()
end

function applyCustomAchieverWindowOptions()--withSummaryFrame)
	retOK, ret = pcall(callbackCustomAchieverWindow, CustomAchieverFrame)
end

function callbackCustomAchieverWindow(aFrame)
	if CustomAchieverOptionsData and CustomAchieverOptionsData["CustomAchieverWindow"] and CustomAchieverOptionsData["CustomAchieverWindow"]["point"] then
		aFrame:ClearAllPoints()
		aFrame:SetPoint(CustomAchieverOptionsData["CustomAchieverWindow"]["point"], UIParent,
			CustomAchieverOptionsData["CustomAchieverWindow"]["relativePoint"], CustomAchieverOptionsData["CustomAchieverWindow"]["xOffset"], CustomAchieverOptionsData["CustomAchieverWindow"]["yOffset"])
	end
end

function customAchieverSaveWindowPosition()
	if CustomAchieverFrame then
		local point, _, relativePoint, xOffset, yOffset = CustomAchieverFrame:GetPoint()
		CustomAchieverOptionsData["CustomAchieverWindow"]["point"] = point
		CustomAchieverOptionsData["CustomAchieverWindow"]["relativePoint"] = relativePoint
		CustomAchieverOptionsData["CustomAchieverWindow"]["xOffset"] = xOffset
		CustomAchieverOptionsData["CustomAchieverWindow"]["yOffset"] = yOffset
	end
	--CustAc_saveCustomAchieverOptionsDataForAddon()
end

function CustAc_fullName(unit)
	local fullName = nil
	if unit then
		local playerName, playerRealm = UnitFullName(unit)
		if playerName and playerName ~= "" and playerName ~= UNKNOWNOBJECT then
			if not playerRealm or playerRealm == "" then
				playerRealm = GetNormalizedRealmName()
			end
			if playerRealm and playerRealm ~= "" then
				fullName = playerName.."-"..playerRealm
			end
		end
	end
	return fullName
end

function CustAc_isPlayerCharacter(aName)
	return CustAc_playerCharacter() == CustAc_addRealm(aName)
end

local CustAc_pc
function CustAc_playerCharacter()
	if not CustAc_pc then
		CustAc_pc = CustAc_fullName("player")
	end
	return CustAc_pc
end

function CustomAchiever:ReloadData()
	CustomAchieverBetButton:Hide()
	local numGroupMembers = GetNumGroupMembers()
	if numGroupMembers <= 1 then
		playerJoinsCustomAchieverSession("CustomAchieverSession_"..CustAc_playerCharacter(), true, true)
	end
	generateCustomAchieverTable()
end

function CustomAchiever:CustomAchieverChatCommand(input)
	if input == "options" then
		CustomAchiever_OpenOptions()
	else
		CustomAchieverFrame:Show()
	end
end

function CustomAchiever_CompartmentFunc(addon, clickButton)
	if clickButton == "RightButton" then
		CustomAchiever_OpenOptions()
	else
		CustomAchiever_ToggleFrame()
	end
end

function CustomAchiever_CompartmentFuncOnEnter(addon, button)
	local tooltip = "Custom Achiever"
	local tooltipDetail = L["MINIMAP_TOOLTIP1"]
	local tooltipDetail2 = L["MINIMAP_TOOLTIP2"]
	
	button:SetAttribute("tooltip", tooltip)
	button:SetAttribute("tooltipDetail", { tooltipDetail, tooltipDetail2 })
	CustomAchieverButtonEnter(button, "LEFT")
end

function CustomAchiever_CompartmentFuncOnLeave()
	CustomAchieverTooltip:Hide()
end

function CustomAchiever_ToggleFrame()
	if CustomAchieverFrame:IsShown() then
		CustomAchieverFrame:Hide()
	else
		CustomAchieverFrame:Show()
	end
end

function CustomAchiever_OpenOptions()
	ACD:Open("CustomAchiever")
end
