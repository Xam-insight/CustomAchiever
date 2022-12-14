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

customAchieverList = {}
local customAchieverLines = {}

CustAc_Krowi_Loaded = false
function CustomAchiever:OnInitialize()
	-- Called when the addon is loaded
	self:RegisterChatCommand("custac", "CustomAchieverChatCommand")
	self:RegisterComm(CustomAchieverGlobal_CommPrefix, "ReceiveDataFrame_OnEvent")
	--self:RegisterEvent("PLAYER_ENTERING_WORLD", "CallForCustomAchieverData")
	self:RegisterEvent("IGNORELIST_UPDATE", "ApplyIgnoreList")

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

function CustomAchiever:ApplyIgnoreList()
	CustAc_ApplyIgnoreList()
end

function CustomAchiever:OnEnable()
	-- Called when the addon is enabled
	if not CustomAchieverFrame then
		initCustomAchieverBusinessObjects()
        loadCustomAchieverOptions()

		--NewCustomAchieverFrame
		CustomAchieverFrame = CreateFrame("Frame", "CustomAchieverFrame", UIParent, "CustomAchieverFrameTemplate")

		CustomAchiever:Print(L["CUSTOMACHIEVER_WELCOME"])
		CustomAchiever:LoadAddonsData()
	end
end

function CustomAchiever:LoadAddonsData()
	for i=1, GetNumAddOns() do
		local name, title, notes, loadable, reason, security, newVersion = GetAddOnInfo(i)
		if strmatch(name,"_CustomAchiever") then
			local data = _G[gsub(name, "_CustomAchiever", "").."_CustomAchieverData"]
			if data then
				for key, value in pairs(data["Categories"]) do
					CustomAchieverData["Categories"][key] = value
				end
				for key, value in pairs(data["Achievements"]) do
					CustomAchieverData["Achievements"][key] = value
				end
			end
			local optionsData = _G[gsub(name, "_CustomAchiever", "").."_CustomAchieverOptionsData"]
			if optionsData then
				local addonDataTime = optionsData["dataTime"]
				local custacDataTime = CustomAchieverOptionsData["dataTime"]
				if addonDataTime and (not custacDataTime or custacDataTime < addonDataTime) then
					CustomAchieverOptionsData = optionsData
				end
			end
		end
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
	CustAc_saveCustomAchieverOptionsDataForAddon()
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
		CustomAchieverOptions()
	else
		CustomAchieverFrame:Show()
	end
end

function CustomAchieverOptions()
	ACD:Open("CustomAchiever")
end
