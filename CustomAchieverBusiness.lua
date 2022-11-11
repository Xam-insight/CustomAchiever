customAchieverCharInfo = {}
local L = LibStub("AceLocale-3.0"):GetLocale("CustomAchiever", true)

local willPlay, soundHandle

-- Initialize CustomAchievers Objects
function initCustomAchieverBusinessObjects()
	-- CustomAchieverData
	if not CustomAchieverData then
		CustomAchieverData = {}
	end

	if not CustomAchieverData["Categories"] then
		CustomAchieverData["Categories"] = {}
	end

	if not CustomAchieverData["Achievements"] then
		CustomAchieverData["Achievements"] = {}
	end

	-- CustomAchieverOptionsData
	if not CustomAchieverOptionsData then
		CustomAchieverOptionsData = {}
	end

	-- CustomAchieverWindow
	if not CustomAchieverOptionsData["CustomAchieverWindow"] then
		CustomAchieverOptionsData["CustomAchieverWindow"] = {}
	end
	
	-- CustomAchieverTuto
	if not CustomAchieverTuto then
		CustomAchieverTuto = {}
	end
end

function CustAc_SaveCategoryDataIntoAddon(categoryId)
	local addOn = CustomAchieverData["Categories"][categoryId]["parent"]
	if not addOn or addOn == true then
		addOn = categoryId
	end
	if not _G[addOn.."_CustomAchieverData"] then
		_G[addOn.."_CustomAchieverData"] = {}
	end
	if not _G[addOn.."_CustomAchieverData"]["Categories"] then
		_G[addOn.."_CustomAchieverData"]["Categories"] = {}
	end
	_G[addOn.."_CustomAchieverData"]["Categories"][categoryId] = CustomAchieverData["Categories"][categoryId]
end

function CustAc_CreateOrUpdateCategory(id, parentID, categoryName, locale)
	if id then
		local parentCategory = nil
		if parentID then
			if not CustomAchieverData["Categories"][parentID] then
				CustAc_CreateOrUpdateCategory(parentID)
				parentCategory = parentID
			elseif not CustomAchieverData["Categories"][parentID]["parent"] or CustomAchieverData["Categories"][parentID]["parent"] == true then
				parentCategory = parentID
			else
				parentCategory = CustomAchieverData["Categories"][parentID]["parent"]
			end
		end

		local data = CustomAchieverData["Categories"][id] or {}
		data["id"]       = id or data["id"]
		data["parent"]   = parentCategory or data["parent"]
		data["hidden"]   = (data["parentID"] ~= nil)
		local dataLocale = locale or GetLocale()
		data["name_"..dataLocale] = categoryName or data["name_"..dataLocale] or id

		CustomAchieverData["Categories"][id] = data

		if parentCategory then
			CustomAchieverData["Categories"][id]["hidden"]                = true
			CustomAchieverData["Categories"][parentCategory]["parent"]    = true
			CustomAchieverData["Categories"][parentCategory]["collapsed"] = true
			CustAc_SaveCategoryDataIntoAddon(parentCategory)
		else
			CustAc_SaveCategoryDataIntoAddon(id)
		end
		
		CustAc_LoadAchievementsData()
		CustAc_AchievementFrame_UpdateAndSelectCategory(id)
	end
end

function CustAc_SaveAchievementDataIntoAddon(achievementId)
	local addOn = CustomAchieverData["Categories"][CustomAchieverData["Achievements"][achievementId]["parent"]]["parent"]
	if not addOn or addOn == true then
		addOn = CustomAchieverData["Achievements"][achievementId]["parent"]
	end
	if not _G[addOn.."_CustomAchieverData"] then
		_G[addOn.."_CustomAchieverData"] = {}
	end
	if not _G[addOn.."_CustomAchieverData"]["Achievements"] then
		_G[addOn.."_CustomAchieverData"]["Achievements"] = {}
	end
	_G[addOn.."_CustomAchieverData"]["Achievements"][achievementId] = CustomAchieverData["Achievements"][achievementId]
end

function CustAc_CreateOrUpdateAchievement(id, parent, icon, points, name, description, locale)
	if id then
		local parentCategory = parent or "CustomAchiever"
		if not CustomAchieverData["Categories"][parentCategory] then
			CustAc_CreateOrUpdateCategory(parentCategory, nil, parentCategory, locale)
		end
		local data = {}
		if CustomAchieverData["Achievements"][id] then
			data = CustomAchieverData["Achievements"][id]
		end
		data["id"]                = id
		data["parent"]            = parentCategory
		local dataLocale          = locale            or GetLocale()
		data["name_"..dataLocale] = name              or data["name_"..dataLocale] or L["MENUCUSTAC_DEFAULT_NAME"]
		data["desc_"..dataLocale] = description       or data["desc_"..dataLocale] or L["MENUCUSTAC_DEFAULT_NAME"]
		data["icon"]              = icon              or data["icon"]                           or 236376
		data["points"]            = points            or data["points"]                         or 10
		data["flags"]             = 0
		data["rewardText"]        = nil
		data["isGuild"]           = false
		data["completed"]         = data["completed"] or {}
		data["date"]              = data["date"]      or {}
		--data["wasEarnedByMe"] = true
		--data["earnedBy"] = "Xamena"

		CustomAchieverData["Achievements"][id] = data
		CustAc_SaveAchievementDataIntoAddon(id)
		
		CustAc_LoadAchievementsData()
		if CustAc_AchievementFrameAchievements and CustAc_AchievementFrameAchievements:IsShown() then
			CustAc_AchievementFrameAchievements_UpdateDataProvider()
		end
	end
end

function CustAc_GetAchievement(achievement)
	if achievement then
		local data = {}
		data["id"] = achievement["id"]
		data["name"] = CustAc_getLocaleData(achievement, "name")
		data["description"] = CustAc_getLocaleData(achievement, "desc")
		data["points"] = achievement["points"]
		data["completed"] = achievement["completed"][CustAc_playerCharacter()] or achievement["firstAchiever"]
		local custacDate = (achievement["firstAchiever"] and achievement["date"][achievement["firstAchiever"]]) or achievement["date"][CustAc_playerCharacter()]
		if custacDate then
			local month, day, year = custacDate.month, custacDate.monthDay, custacDate.year
			data["month"] = month
			data["day"] = day
			data["year"] = year
		end
		data["flags"] = achievement["flags"]
		data["icon"] = achievement["icon"]
		data["rewardText"] = achievement["rewardText"]
		data["isGuild"] = achievement["isGuild"]
		data["wasEarnedByMe"] = achievement["completed"][CustAc_playerCharacter()]
		data["earnedBy"] = (achievement["completed"][CustAc_playerCharacter()] and CustAc_playerCharacter()) or achievement["firstAchiever"]
		if not CUSTOMACHIEVER_ACHIEVEMENTS[achievement["parent"]] then
			CUSTOMACHIEVER_ACHIEVEMENTS[achievement["parent"]] = {}
		end
		tinsert(CUSTOMACHIEVER_ACHIEVEMENTS[achievement["parent"]], data)
	end
end

function CustAc_GetTotalAchievementPoints()
	local totalAchievementPoints = 0
	for k,v in pairs(CustomAchieverData["Achievements"]) do
		if v["firstAchiever"] then
			totalAchievementPoints = totalAchievementPoints + v["points"]
		end
	end
	return totalAchievementPoints
end

function CustAc_GetCategoryNumAchievements_All(categoryID)
	local numAchievements = 0
	local numCompleted = 0
	local numIncomplete = 0
	for k,v in pairs(CustomAchieverData["Achievements"]) do
		if v["parent"] == categoryID then
			numAchievements = numAchievements + 1
			if v["firstAchiever"] then
				numCompleted = numCompleted + 1
			else
				numIncomplete = numIncomplete +1
			end
		end
	end
	return numAchievements, numCompleted, 0
end

function CustAc_CompleteAchievement(id, earnedBy, noNotif, forceNotif, forceNoSound)
	if id and CustomAchieverData["Achievements"][id] then
		local earnedByWithRealm = CustAc_playerCharacter()
		if earnedBy then
			earnedByWithRealm = CustAc_addRealm(earnedBy)
		end
		local forPlayerCharacter = earnedByWithRealm == CustAc_playerCharacter()
		local data = CustomAchieverData["Achievements"][id]
		local alreadyEarned = data["completed"][earnedByWithRealm]
		data["completed"][earnedByWithRealm] = data["completed"][earnedByWithRealm] or true
		data["date"][earnedByWithRealm] = data["date"][earnedByWithRealm] or C_DateAndTime.GetCurrentCalendarTime()
		data["firstAchiever"] = data["firstAchiever"] or earnedByWithRealm
		--data["wasEarnedByMe"] = true
		--data["earnedBy"] = "Xamena"

		CustomAchieverData["Achievements"][id] = data
		CustAc_SaveAchievementDataIntoAddon(id)

		if forPlayerCharacter and (not alreadyEarned or forceNotif) and not noNotif then
			local name = getLocaleData(data, "name")
			EZBlizzUiPop_ToastFakeAchievementNew(CustomAchiever, name, 5208, not forceNoSound and not CustomAchieverOptionsData["CustomAchieverSoundsDisabled"], 4, "Custom Achiever", function() CustAc_ShowAchievement(id) end, data["icon"])
		end
		CustAc_LoadAchievementsData()
		if CustAc_AchievementFrameAchievements and CustAc_AchievementFrameAchievements:IsShown() then
			CustAc_AchievementFrameAchievements_UpdateDataProvider()
		end
	end
end

function CustAc_getLocaleData(data, name)
	local localeData = data[name.."_"..GetLocale()]
	if localeData then
		return localeData
	end
	for k,v in pairs(CustAc_languageValues) do
		localeData = data[name.."_"..k]
		if localeData then
			return localeData
		end
	end
	return UNKNOWN
end

function CustAc_GetAchievementCategory(id)
	local category
	if id and CustomAchieverData["Achievements"][id] then
		category = CustomAchieverData["Achievements"][id]["parent"]
	end
	return category
end

function CustAc_addRealm(aName, aRealm)
	if aName and not string.match(aName, "-") then
		if aRealm and aRealm ~= "" then
			aName = aName.."-"..aRealm
		else
			aName = aName.."-"..GetNormalizedRealmName()
		end
	end
	return aName
end

function CustAc_delRealm(aName)
	if aName and string.match(aName, "-") then
		aName = strsplit("-", aName)
	end
	return aName
end

function CustAc_Error(message)
	local messageToPrint = "CustomAchiever"..L["SPACE_BEFORE_DOT"]..": "..message
	UIErrorsFrame:AddMessage(messageToPrint, 1.0, 0.1, 0.1)
	CustomAchiever:Print("|cFFFF0000"..messageToPrint)
end

function CustAc_upperCase(aText)
	local newText = ""
	if aText then
		retOK, ret = pcall(CustAc_upperCaseBusiness, aText)
		if retOK then
			newText = ret
		else
			newText = aText
		end
	end
	return newText
end

function CustAc_upperCaseBusiness(aText)
	return string.utf8upper(aText)
end

function CustAc_PlaySound(soundID, channel, forcePlay)
	if forcePlay or not CustomAchieverOptionsData or not CustomAchieverOptionsData["CustomAchieverSoundsDisabled"] or not (CustomAchieverOptionsData["CustomAchieverSoundsDisabled"] == true) then
		PlaySound(soundID, channel)
	end
end

function CustAc_PlaySoundFile(soundFile, channel, forcePlay)
	if soundHandle then
		StopSound(soundHandle)
	end
	if forcePlay or not CustomAchieverOptionsData or not CustomAchieverOptionsData["CustomAchieverSoundsDisabled"] or not (CustomAchieverOptionsData["CustomAchieverSoundsDisabled"] == true) then
		willPlay, soundHandle = PlaySoundFile("Interface\\AddOns\\CustomAchiever\\sound\\"..soundFile.."_"..GetLocale()..".ogg", channel)
		if not willPlay then
			willPlay, soundHandle = PlaySoundFile("Interface\\AddOns\\CustomAchiever\\sound\\"..soundFile..".ogg", channel)
		end
	end
	return soundHandle
end

function CustAc_PlaySoundFileId(soundFileId, channel, forcePlay)
	if soundHandle then
		StopSound(soundHandle)
	end
	if forcePlay or not CustomAchieverOptionsData or not CustomAchieverOptionsData["CustomAchieverSoundsDisabled"] or not (CustomAchieverOptionsData["CustomAchieverSoundsDisabled"] == true) then
		PlaySoundFile(soundFileId, channel)
	end
	return soundHandle
end

function CustAc_saveCustomAchieverOptionsDataForAddon()
	local dataTime = CustAc_getTimeUTCinMS()
	for i=1, GetNumAddOns() do
		local name, title, notes, loadable, reason, security, newVersion = GetAddOnInfo(i)
		if strmatch(name,"_CustomAchiever") then
			_G[gsub(name, "_CustomAchiever", "").."_CustomAchieverOptionsData"] = CustomAchieverOptionsData
			_G[gsub(name, "_CustomAchiever", "").."_CustomAchieverOptionsData"]["dataTime"] = dataTime
		end
	end
	CustomAchieverOptionsData["dataTime"] = dataTime
end

function CustAc_getTimeUTCinMS()
	return tostring(time(date("!*t")))
end
