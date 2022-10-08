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
	if not CustomAchieverWindow then
		CustomAchieverWindow = {}
	end
	
	-- CustomAchieverTuto
	if not CustomAchieverTuto then
		CustomAchieverTuto = {}
	end
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

function clearCharacterCustomAchieverData(aFullName)
	if aFullName and CustomAchieverData and CustomAchieverData[CustomAchieverGlobal_SessionId]
			and CustomAchieverData[CustomAchieverGlobal_SessionId][aFullName]
				and CustAc_countTableElements(CustomAchieverData[CustomAchieverGlobal_SessionId][aFullName]) == 0 then
		CustomAchieverData[CustomAchieverGlobal_SessionId][aFullName] = nil
	end
end

function getCustomAchieverData(aSession, aChar, anInfo, aCustomAchieverDataObject)
	local value = nil
	local dataTime = nil

	if not aCustomAchieverDataObject then
		aCustomAchieverDataObject = CustomAchieverData
	end

	if aSession and aChar and anInfo then
		if aCustomAchieverDataObject 
			and aCustomAchieverDataObject[aSession]
				and aCustomAchieverDataObject[aSession][aChar] then
			value = aCustomAchieverDataObject[aSession][aChar][anInfo]
			if value ~= nil then
				value, dataTime = strsplit("|", tostring(value), 2)
				if dataTime and dataTime == "" then
					dataTime = nil
				end
			end
		end
	end
	return value, dataTime
end

function setCustomAchieverData(aSession, aChar, anInfo, aValue)
	if aSession and aChar and anInfo then
		local value, dataTime = strsplit("|", tostring(aValue), 2)
		if not CustomAchieverData then
			CustomAchieverData = {}
		end
		if not CustomAchieverData[aSession] then
			CustomAchieverData[aSession] = {}
		end
		if not CustomAchieverData[aSession][aChar] then
			CustomAchieverData[aSession][aChar] = {}
		end
		if not dataTime or dataTime == "" then
			dataTime = tostring(CustAc_getTimeUTCinMS())
		end
		CustomAchieverData[aSession][aChar][anInfo] = value.."|"..dataTime
	end
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

function CustAc_Error(message)
	local messageToPrint = "CustomAchiever"..L["SPACE_BEFORE_DOT"]..": "..message
	UIErrorsFrame:AddMessage(messageToPrint, 1.0, 0.1, 0.1)
	CustomAchiever:Print("|cFFFF0000"..messageToPrint)
end

function CustAc_tonumberzeroonblankornil(aString)
	if aString and aString ~= "" then
		return tonumber(aString)
	else
		return 0
	end
end

function CustAc_getTimeUTCinMS()
	return tostring(time(date("!*t")))
end

function CustAc_getMostRecentTimedValue(myValueTime, newValueTime, forceNew)
	local myValue, myDataTime, newValue, newDataTime
	local myValueIsObsolete = false

	if myValueTime then
		myValue, myDataTime = strsplit("|", myValueTime, 2)
	end
	if newValueTime then
		newValue, newDataTime = strsplit("|", newValueTime, 2)
		myValueIsObsolete = true
	end
	if myDataTime and newDataTime and myDataTime ~= "" and newDataTime ~= "" then
		myDataTime = tonumber(myDataTime)
		newDataTime = tonumber(newDataTime)
		if not forceNew and myDataTime >= newDataTime then
			newValue = myValue
			newDataTime = myDataTime
			myValueIsObsolete = false
		end
	end
	
	local returnedValue = newValue
	if newDataTime and newDataTime ~= "" then
		returnedValue = returnedValue.."|"..newDataTime
	end

	return returnedValue, myValueIsObsolete
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
