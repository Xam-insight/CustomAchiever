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
    --self:RegisterComm(CustomAchieverGlobal_CommPrefix, nil)
	--self:RegisterEvent("PLAYER_ENTERING_WORLD", "CallForCustomAchieverData")
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

function CustomAchiever:OnEnable()
	-- Called when the addon is enabled
	if not CustomAchieverFrame then
        loadCustomAchieverOptions()
		initCustomAchieverBusinessObjects()

		--NewCustomAchieverFrame
		CustomAchieverFrame = CreateFrame("Frame", "CustomAchieverFrame", UIParent, "CustomAchieverFrameTemplate")
		callbackCustomAchieverWindow(CustomAchieverFrame)

		local fontstring = CustomAchieverFrame:CreateFontString("CustomAchieverLabel", "ARTWORK", "GameFontNormal")
        fontstring:SetText(GetAddOnMetadata("CustomAchiever", "Title").." "..GetAddOnMetadata("CustomAchiever", "Version"))
		fontstring:SetPoint("TOP", 0, -5)

		CustomAchieverFrameAchievementAlertFrame.GuildBanner:Hide()
		CustomAchieverFrameAchievementAlertFrame.OldAchievement:Hide()
		CustomAchieverFrameAchievementAlertFrame.GuildBorder:Hide()
		CustomAchieverFrameAchievementAlertFrame.Icon.Bling:Hide()

		applyCustomAchieverWindowOptions()

		CustomAchiever:Print(L["CUSTOMACHIEVER_WELCOME"])
	end
end

function showIconSelector()
	
end

function applyCustomAchieverWindowOptions()--withSummaryFrame)
	retOK, ret = pcall(callbackCustomAchieverWindow, CustomAchieverFrame)
end

function callbackCustomAchieverWindow(aFrame)
	if CustomAchieverWindow["point"] then
		aFrame:ClearAllPoints()
		aFrame:SetPoint(CustomAchieverWindow["point"], UIParent,
			CustomAchieverWindow["relativePoint"], CustomAchieverWindow["xOffset"], CustomAchieverWindow["yOffset"])
	end
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
	if input == "test" then
		CustomAchieverFrame:Show()
	else
		ACD:Open("CustomAchiever")
	end
end

function callbackCustomAchieverWindow(aFrame)
	if CustomAchieverWindow["point"] then
		aFrame:ClearAllPoints()
		aFrame:SetPoint(CustomAchieverWindow["point"], UIParent,
			CustomAchieverWindow["relativePoint"], CustomAchieverWindow["xOffset"], CustomAchieverWindow["yOffset"])
	end
end

function customAchieverSaveWindowPosition()
	local point, _, relativePoint, xOffset, yOffset = CustomAchieverFrame:GetPoint()
	CustomAchieverWindow["point"] = point
	CustomAchieverWindow["relativePoint"] = relativePoint
	CustomAchieverWindow["xOffset"] = xOffset
	CustomAchieverWindow["yOffset"] = yOffset
end
