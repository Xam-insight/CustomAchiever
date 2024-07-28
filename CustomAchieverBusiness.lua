customAchieverCharInfo = {}
local L = LibStub("AceLocale-3.0"):GetLocale("CustomAchiever", true)

local willPlay, soundHandle

-- Initialize CustomAchievers Objects
function initCustomAchieverBusinessObjects()
	-- CustomAchieverData
	if not CustomAchieverData then
		CustomAchieverData = {}
	else
		local playerCharacter = CustAc_fullName("player")
		if not CustomAchieverData["DataCleaning_1.2"] then
			CustomAchieverDataBackup = CustomAchieverData
			CustomAchieverData["DataCleaning_1.2"] = true
		end
		if not CustomAchieverData["DataCleaning_1.2"..playerCharacter] then
			if CustomAchieverData["AwardedPlayers"] then
				for k,v in pairs(CustomAchieverData["AwardedPlayers"]) do
					for k2,v2 in pairs(v) do
						if CustAc_isPlayerCharacter(k2) then
							CustomAchieverData["AwardedPlayers"][k][k2] = nil
						end
					end
					if CustAc_countTableElements(v) == 0 then
						CustomAchieverData["AwardedPlayers"][k] = nil
					end
				end
			end
			if CustomAchieverData["PendingUpdates"] then
				if CustomAchieverData["PendingUpdates"]["Categories"] then
					for k,v in pairs(CustomAchieverData["PendingUpdates"]["Categories"]) do
						for k2,v2 in pairs(v) do
							if CustAc_isPlayerCharacter(k2) then
								CustomAchieverData["PendingUpdates"]["Categories"][k][k2] = nil
							end
						end
						if CustAc_countTableElements(v) == 0 then
							CustomAchieverData["PendingUpdates"]["Categories"][k] = nil
						end
					end
				end
				if CustomAchieverData["PendingUpdates"]["Achievements"] then
					for k,v in pairs(CustomAchieverData["PendingUpdates"]["Achievements"]) do
						for k2,v2 in pairs(v) do
							if CustAc_isPlayerCharacter(k2) then
								CustomAchieverData["PendingUpdates"]["Achievements"][k][k2] = nil
							end
						end
						if CustAc_countTableElements(v) == 0 then
							CustomAchieverData["PendingUpdates"]["Achievements"][k] = nil
						end
					end
				end
			end
			CustomAchieverData["DataCleaning_1.2_"..playerCharacter] = true
		end
	end
	CustomAchieverData["MainAddon"] = CustAcAddon or "CustomAchiever"

	if not CustomAchieverData["Categories"] then
		CustomAchieverData["Categories"] = {}
	end
	
	if not CustomAchieverData["PersonnalCategories"] then
		CustomAchieverData["PersonnalCategories"] = {}
	end

	if not CustomAchieverData["AwardedPlayers"] then
		CustomAchieverData["AwardedPlayers"] = {}
	end

	if not CustomAchieverData["PendingUpdates"] then
		CustomAchieverData["PendingUpdates"] = {}
	end

	if not CustomAchieverData["PendingUpdates"]["Categories"] then
		CustomAchieverData["PendingUpdates"]["Categories"] = {}
	end

	if not CustomAchieverData["PendingUpdates"]["Achievements"] then
		CustomAchieverData["PendingUpdates"]["Achievements"] = {}
	end

	if not CustomAchieverData["Users"] then
		CustomAchieverData["Users"] = {}
	end
	
	if not CustomAchieverData["BlackList"] then
		CustomAchieverData["BlackList"] = {}
	end
	
	if not CustomAchieverData["Achievements"] then
		CustomAchieverData["Achievements"] = {}
	end

	if not CustomAchieverData["Tutorial"] then
		CustomAchieverData["Tutorial"] = {}
	end
	
	if not CustomAchieverLastManualCall then
		CustomAchieverLastManualCall = {}
	else
		local now = time()
		for k,v in pairs(CustomAchieverLastManualCall) do
			if now > v + 300 then
				CustomAchieverLastManualCall[k] = nil
			end
		end
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

function CustAc_ApplyIgnoreList()
	CustomAchieverData["BlackList"] = {}
	for i = 1, C_FriendList.GetNumIgnores() do
		local user = CustAc_addRealm(C_FriendList.GetIgnoreName(i))
		if user then
			CustomAchieverData["BlackList"][user] = "IgnoreList"
		end
	end
end

function CustAc_CreateOrUpdateCategory(id, parentID, categoryName, locale, isPersonnal, author)
	if id then
		local parentCategory = nil
		if parentID and parentID ~= "" then
			if parentID ~= true and not CustomAchieverData["Categories"][parentID] then
				CustAc_CreateOrUpdateCategory(parentID, nil, nil, locale, isPersonnal)
				parentCategory = parentID
			elseif parentID == true or not CustomAchieverData["Categories"][parentID]["parent"] or CustomAchieverData["Categories"][parentID]["parent"] == true then
				parentCategory = parentID
			else
				parentCategory = CustomAchieverData["Categories"][parentID]["parent"]
			end
		end
		
		local previousCategoryParent = CustomAchieverData["Categories"][id] and CustomAchieverData["Categories"][id]["parent"]

		local data = CustomAchieverData["Categories"][id] or {}
		data["id"]       = id or data["id"]
		if parentID == "" then
			data["parent"] = nil
		else
			data["parent"]   = parentCategory or data["parent"]
		end
		local dataLocale = locale or GetLocale()
		data["name_"..dataLocale] = categoryName or data["name_"..dataLocale] or id
		data["dataTime"] = time()
		
		if isPersonnal then
			data["author"] = data["author"] or CustAc_playerCharacter()
			CustomAchieverData["PersonnalCategories"][id] = true
		else
			if author then
				data["author"] = author
			end
			if CustomAchieverData["PersonnalCategories"][id] then
				CustomAchieverData["PersonnalCategories"][id] = nil
			end
		end
		
		CustomAchieverData["Categories"][id] = data

		if parentCategory and parentCategory ~= true then
			CustomAchieverData["Categories"][parentCategory]["parent"] = true
		end
		
		if previousCategoryParent and previousCategoryParent ~= true and previousCategoryParent ~= parentID then
			CustAc_UnparentCategoryIfNoChild(previousCategoryParent)
		end
		
		CustAc_LoadAchievementsData("CustAc_CreateOrUpdateCategory")
	end
end

function CustAc_CreateOrUpdateAchievement(id, parent, icon, points, name, description, rewardText, rewardIsTitle, locale, isPersonnal)
	if id then
		local parentCategory = parent or "CustomAchiever"
		if not CustomAchieverData["Categories"][parentCategory] then
			CustAc_CreateOrUpdateCategory(parentCategory, nil, parentCategory, locale, isPersonnal)
		end
		local data = CustomAchieverData["Achievements"][id] or {}
		data["id"]                      = id
		data["parent"]                  = parentCategory
		local dataLocale                = locale            or GetLocale()
		data["name_"..dataLocale]       = name              or data["name_"..dataLocale]       or L["MENUCUSTAC_DEFAULT_NAME"]
		data["desc_"..dataLocale]       = description       or data["desc_"..dataLocale]       or L["MENUCUSTAC_DEFAULT_NAME"]
		data["icon"]                    = icon              or data["icon"]                    or 236376
		data["points"]                  = tonumber(points   or data["points"]                  or 10)
		data["flags"]                   = 0
		data["rewardText_"..dataLocale] = rewardText        or data["rewardText_"..dataLocale] or ""
		data["rewardIsTitle"]           = rewardIsTitle     or false
		data["isGuild"]                 = false
		data["completed"]               = data["completed"] or {}
		data["date"]                    = data["date"]      or {}
		data["dataTime"] = time()
		--data["wasEarnedByMe"] = true
		--data["earnedBy"] = "Xamena"

		CustomAchieverData["Achievements"][id] = data
		--CustAc_SaveAchievementDataIntoAddon(id)
		
		CustAc_LoadAchievementsData("CustAc_CreateOrUpdateAchievement")
	end
end

function CustAc_DeleteCategory(id, newCategory)
	if id then
		local categoryParent = CustomAchieverData["Categories"][id]["parent"]
		CustomAchieverData["Categories"][id] = nil
		CustomAchieverData["PersonnalCategories"][id] = nil
		
		if categoryParent and categoryParent ~= true then
			CustAc_UnparentCategoryIfNoChild(categoryParent)
		end
	end
	
	local categoryFound = false
	for k,v in pairs(CustomAchieverData["Categories"]) do
		if v["parent"] == id then
			categoryFound = true
			v["parent"] = newCategory
		end
	end
	if categoryFound and newCategory and CustomAchieverData["Categories"][newCategory] then
		CustomAchieverData["Categories"][newCategory]["parent"] = true
	end
	
	if newCategory then
		local achievementFound = false
		for k,v in pairs(CustomAchieverData["Achievements"]) do
			if v["parent"] == id then
				achievementFound = true
				v["parent"] = newCategory
			end
		end
		if achievementFound and not CustomAchieverData["Categories"][newCategory] then
			local categoryName = (newCategory == "GENERAL" and GENERAL) or CustAc_delRealm(newCategory)
			CustAc_CreateOrUpdateCategory(newCategory, nil, categoryName, nil, true)
		end
	end
	
	CustAc_LoadAchievementsData("CustAc_DeleteCategory")
end

function CustAc_UnparentCategoryIfNoChild(categoryId)
	if CustomAchieverData["Categories"][categoryId] then
		local childFound = false
		for k,v in pairs(CustomAchieverData["Categories"]) do
			if v["parent"] == categoryId then
				childFound = true
				break
			end
		end
		if not childFound then
			CustomAchieverData["Categories"][categoryId]["parent"] = nil
		end
	end
end

function CustAc_DetermineNewCategory(oldCategory, proposedCategory, proposedCategory2)
	local newCategory = proposedCategory
	if newCategory == oldCategory or not newCategory then
		newCategory = proposedCategory2
	end
	if newCategory == oldCategory or not newCategory then
		newCategory = "GENERAL"
	end
	return newCategory
end

function CustAc_DeleteAchievement(id)
	if id then
		CustomAchieverData["Achievements"][id] = nil
	end
	
	CustAc_LoadAchievementsData("CustAc_DeleteAchievement")
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
		local rewardText = CustAc_getLocaleData(achievement, "rewardText", "")
		if rewardText and rewardText ~= "" then
			rewardText = (achievement["rewardIsTitle"] and format(HONOR_REWARD_TITLE, rewardText)) or format(TITLE_REWARD, rewardText)
		else
			rewardText = ""
		end
		data["rewardText"] = rewardText
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
		data["dataTime"] = time()
		--data["wasEarnedByMe"] = true
		--data["earnedBy"] = "Xamena"

		CustomAchieverData["Achievements"][id] = data
		--CustAc_SaveAchievementDataIntoAddon(id)

		local name = CustAc_getLocaleData(data, "name")
		if forPlayerCharacter and (not alreadyEarned or forceNotif) and not noNotif and not CustomAchieverOptionsData["CustomAchieverAchievementAnnounceDisabled"] then
			EZBlizzUiPop_ToastFakeAchievementNew(CustomAchiever, name, 5208, not forceNoSound and not CustomAchieverOptionsData["CustomAchieverSoundsDisabled"], 4, "Custom Achiever", function() CustAc_ShowAchievement(id) end, data["icon"])
		end
		CustAc_LoadAchievementsData("CustAc_CompleteAchievement")
	end
end

function CustAc_IsAchievementCompletedBy(id, earnedBy, isSelf)
	local completed = false
	
	if isSelf then
		if CustomAchieverData["Achievements"][id] and
				CustomAchieverData["Achievements"][id]["completed"] and
				CustomAchieverData["Achievements"][id]["completed"][earnedBy] and
				CustomAchieverData["Achievements"][id]["completed"][earnedBy] == true then
			completed = true
		end
	else
		if CustomAchieverData["AwardedPlayers"][id] then
			completed = CustomAchieverData["AwardedPlayers"][id][earnedBy]
		end
	end
				
	return completed
end

function CustAc_RevokeAchievement(id, earnedBy)--/run CustAc_RevokeAchievement("Xamëna-Ner'zhul-1668713877", "Xamëna-Ner'zhul")
	if id and CustomAchieverData["Achievements"][id] then
		local earnedByWithRealm = CustAc_playerCharacter()
		if earnedBy then
			earnedByWithRealm = CustAc_addRealm(earnedBy)
		end
		local data = CustomAchieverData["Achievements"][id]
		data["completed"][earnedByWithRealm] = nil
		data["date"][earnedByWithRealm] = nil
		if data["firstAchiever"] == earnedByWithRealm then
			local newFirstAchiever
			local newFirstAchieverDate
			for k,v in pairs(data["date"]) do
				if not newFirstAchieverDate or C_DateAndTime.CompareCalendarTime(v, newFirstAchieverDate) == 1 then
					newFirstAchiever = k
					newFirstAchieverDate = v
				end
			end
			data["firstAchiever"] = newFirstAchiever
		end
		data["dataTime"] = time()
		--data["wasEarnedByMe"] = true
		--data["earnedBy"] = "Xamena"

		CustomAchieverData["Achievements"][id] = data
		--CustAc_SaveAchievementDataIntoAddon(id)

		CustAc_LoadAchievementsData("CustAc_RevokeAchievement")
		
		local name = CustAc_getLocaleData(data, "name")
	end
end

function CustAc_getLocaleData(data, name, valueIfNotFound)
	if data then
		local localeData = data[name.."_"..GetLocale()]
		if localeData then
			return localeData, GetLocale()
		end
		for k,v in pairs(CustAc_languageValues) do
			localeData = data[name.."_"..k]
			if localeData then
				return localeData, k
			end
		end
		return valueIfNotFound or UNKNOWN
	end
	return nil
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
		elseif GetNormalizedRealmName() then
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


function CustAc_titleFormat(aText)
	local newText = ""
	if aText then
		newText = strtrim(aText):gsub("%s+", " ")
		retOK, ret = pcall(CustAc_upperCaseBusiness, string.utf8sub(string.utf8upper(newText), 1 , 1))
		if retOK then
			newText = ret..string.utf8sub(newText, 2)
		end
	end
	return newText
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

function CustAc_getTimeUTCinMS()
	return tostring(time(date("!*t")))
end

function CustAc_countTableElements(table)
	local count = 0
	if table then
		for _ in pairs(table) do
			count = count + 1
		end
	end
	return count
end

function CustomAchieverLogs_SetText(logLine, info1, info2)
	if CustomAchieverLogs then
		local logsText = CustomAchieverLogs:GetText()
		local newLog = format(logLine, info1, "|cFFF4D03F["..info2.."]|r").."|n"
		CustomAchieverLogs:Insert(newLog)
	end
end
