local L = LibStub("AceLocale-3.0"):GetLocale("CustomAchiever", true);

local messageTypeColors = {
	["CallUsers"] = "FFD2B4DE",
	["CallCategories"] = "FFD2B4DE",
	["AnswerUsers"] = "FFD2B4DE",
	["Award"] = "FFABEBC6",
	["Revoke"] = "FFF5B7B1",
	["Update"] = "FF85C1E9",
	["AwardAcknowledgment"] = "FFABEBC6",
	["RevokeAcknowledgment"] = "FFF5B7B1",
	["UpdateAcknowledgment"] = "FF85C1E9",
}

local function encodeAndSendAchievementInfo(aData, aTarget, messageType)
	aData["Version"] = C_AddOns.GetAddOnMetadata(CustAcAddon or "CustomAchiever", "Version")
	local s = CustomAchiever:Serialize(aData)
	local text = messageType.."#"..s
	CustomAchiever:SendCommMessage(CustomAchieverGlobal_CommPrefix, text, "WHISPER", aTarget)
	if not CustAc_isPlayerCharacter(aTarget) then
		CustomAchieverLogs_SetText("%s sent to %s.", "|c"..messageTypeColors[messageType]..messageType.."|r", CustAc_delRealm(aTarget))
	end
end

local function sendInfo(info, aTarget, messageType)
	CustomAchiever:SendCommMessage(CustomAchieverGlobal_CommPrefix, (info and messageType.."#"..info) or messageType.."#NoData", (aTarget and "WHISPER") or "GUILD", aTarget)
end

function CustAc_SendCallForUsers()
	sendInfo(C_AddOns.GetAddOnMetadata(CustAcAddon or "CustomAchiever", "Version"), nil, "CallUsers")
end

function CustAc_SendCallForAchievementsCategories(achievements, aTarget)
	if achievements then
		local data = {}
		data["AchievementsToUpdate"] = achievements
		encodeAndSendAchievementInfo(data, aTarget, "CallCategories")
	end
end

function manualEncodeAndSendAchievementInfo(aData, aTarget, messageType)
	if (messageType == "Award" or messageType == "Update") and not CustAc_isPlayerCharacter(aTarget) then
		local timeBetweenCalls = (messageType == "Update" and 10) or 300
		local callTime = time()
		if not CustomAchieverLastManualCall[aTarget.."|"..messageType] then
			CustomAchieverLastManualCall[aTarget.."|"..messageType] = callTime
		else
			if callTime < CustomAchieverLastManualCall[aTarget.."|"..messageType] + timeBetweenCalls then
				if CustomAchieverAcknowledgmentReceived[aTarget] then
					local seconds = timeBetweenCalls - callTime + CustomAchieverLastManualCall[aTarget.."|"..messageType]
					local minutes = math.floor(seconds / 60)
					seconds = seconds - minutes * 60
					CustomAchiever:Print(string.format(L["SHARECUSTAC_WAIT"], minutes, seconds))
				else
					UIErrorsFrame:AddMessage(format(L["SHARECUSTAC_NOACKNOWLEDGMENT"], aTarget), 1, 0, 0, 1)
					CustomAchiever:Print(format(L["SHARECUSTAC_NOACKNOWLEDGMENT"], aTarget))
				end
				return
			else
				CustomAchieverLastManualCall[aTarget.."|"..messageType] = callTime
			end
		end
	elseif messageType == "Revoke" and not CustAc_isPlayerCharacter(aTarget) then
		if not CustomAchieverAcknowledgmentReceived[aTarget] then
			UIErrorsFrame:AddMessage(format(L["SHARECUSTAC_NOACKNOWLEDGMENT"], aTarget), 1, 0, 0, 1)
			CustomAchiever:Print(format(L["SHARECUSTAC_NOACKNOWLEDGMENT"], aTarget))
		end
	end
	encodeAndSendAchievementInfo(aData, aTarget, messageType)
end

function CustAc_SendUpdatedAchievementData(achievementId, alsoSendTo)
	if achievementId then --CustomAchieverData["AwardedPlayers"][achievementId] then
		local data = {}
		data["Categories"] = {}
		data["Achievements"] = {}
		local categoryId = CustomAchieverData["Achievements"][achievementId] and CustomAchieverData["Achievements"][achievementId]["parent"]
		if categoryId then
			data["Categories"][categoryId] = CustomAchieverData["Categories"][categoryId]
			if CustomAchieverData["Categories"][categoryId] and CustomAchieverData["Categories"][categoryId]["parent"] and CustomAchieverData["Categories"][categoryId]["parent"] ~= true then
				data["Categories"][CustomAchieverData["Categories"][categoryId]["parent"]] = CustomAchieverData["Categories"][CustomAchieverData["Categories"][categoryId]["parent"]]
			end
		end
		data["Achievements"][achievementId] = CustomAchieverData["Achievements"][achievementId] or "DELETE"
		if CustomAchieverData["AwardedPlayers"][achievementId] then
			for k,v in pairs(CustomAchieverData["AwardedPlayers"][achievementId]) do
				if not CustAc_isPlayerCharacter(k) and (not alsoSendTo or k ~= alsoSendTo) then
					CustAc_SendUpdatedDataTo(k, data)
				end
			end
		end
		if alsoSendTo then
			CustAc_SendUpdatedDataTo(alsoSendTo, data)
		end
	end
end

function CustAc_SendUpdatedCategoryData(categoryId, alsoSendTo)
	if categoryId then --CustomAchieverData["AwardedPlayers"][categoryId] then
		local targets = {}
		if alsoSendTo then
			targets[alsoSendTo] = true
		end

		local data = {}
		data["Categories"] = {}
		data["Achievements"] = {}
		data["Categories"][categoryId] = CustomAchieverData["Categories"][categoryId]
		if CustomAchieverData["Categories"][categoryId] and CustomAchieverData["Categories"][categoryId]["parent"] and CustomAchieverData["Categories"][categoryId]["parent"] ~= true then
			data["Categories"][CustomAchieverData["Categories"][categoryId]["parent"]] = CustomAchieverData["Categories"][CustomAchieverData["Categories"][categoryId]["parent"]]
		end
		for k,v in pairs(CustomAchieverData["Categories"]) do
			if v["parent"] == categoryId then
				data["Categories"][k] = v
			end
		end
		for k,v in pairs(CustomAchieverData["Achievements"]) do
			if data["Categories"][v["parent"]] then
				data["Achievements"][k] = v
			end
		end
		
		if CustomAchieverData["AwardedPlayers"][categoryId] then
			for k,v in pairs(CustomAchieverData["AwardedPlayers"][categoryId]) do
				if not CustAc_isPlayerCharacter(k) then
					targets[k] = true
				end
			end
		end
		
		for k,v in pairs(CustomAchieverData["PendingUpdates"]["Achievements"]) do
			for k2,v2 in pairs(v) do
				if not CustAc_isPlayerCharacter(k2) then
					if CustomAchieverData["AwardedPlayers"][k] and CustomAchieverData["AwardedPlayers"][k][k2] then
						data["Achievements"][k] = CustomAchieverData["Achievements"][k] or "DELETE"
						targets[k2] = true
					else
						CustomAchieverData["PendingUpdates"]["Achievements"][k][k2] = nil
						if CustAc_countTableElements(CustomAchieverData["PendingUpdates"]["Achievements"][k]) == 0 then
							CustomAchieverData["PendingUpdates"]["Achievements"][k] = nil
						end
					end
				end
			end
		end
		
		for k,v in pairs(CustomAchieverData["PendingUpdates"]["Categories"]) do
			for k2,v2 in pairs(v) do
				if not CustAc_isPlayerCharacter(k2) then
					if CustomAchieverData["AwardedPlayers"][k] and CustomAchieverData["AwardedPlayers"][k][k2] then
						data["Categories"][k] = CustomAchieverData["Categories"][k]
						targets[k2] = true
					else
						CustomAchieverData["PendingUpdates"]["Categories"][k][k2] = nil
						if CustAc_countTableElements(CustomAchieverData["PendingUpdates"]["Categories"][k]) == 0 then
							CustomAchieverData["PendingUpdates"]["Categories"][k] = nil
						end
					end
				end
			end
		end
		
		for k,v in pairs(targets) do
			CustAc_SendUpdatedDataTo(k, data)
		end
	end
end

function CustAc_SendUpdatedDataTo(player, data)
	if not CustAc_isPlayerCharacter(sender) then
		if data["Categories"] then
			for k,v in pairs(data["Categories"]) do
				if not CustomAchieverData["PendingUpdates"]["Categories"][k] then
					CustomAchieverData["PendingUpdates"]["Categories"][k] = {}
				end
				CustomAchieverData["PendingUpdates"]["Categories"][k][player] = true
			end
		end
		if data["Achievements"] then
			for k,v in pairs(data["Achievements"]) do
				if not CustomAchieverData["PendingUpdates"]["Achievements"][k] then
					CustomAchieverData["PendingUpdates"]["Achievements"][k] = {}
				end
				CustomAchieverData["PendingUpdates"]["Achievements"][k][player] = true
			end
		end
	end
	
	manualEncodeAndSendAchievementInfo(data, player, "Update")
end

CustomAchieverAcknowledgmentReceived = {}
function CustomAchiever:ReceiveDataFrame_OnEvent(prefix, message, distribution, sender)
	if prefix == CustomAchieverGlobal_CommPrefix then
		local senderFullName = CustAc_addRealm(sender)
		--CustomAchiever:Print(time().." - Received message from "..sender..".")
		local messageType, messageMessage = strsplit("#", message, 2)
		--if not isPlayerCharacter(sender) then
		if messageType == "CallUsers" then
			sendInfo(C_AddOns.GetAddOnMetadata(CustAcAddon or "CustomAchiever", "Version"), sender, "AnswerUsers")
			CustomAchieverData["Users"][senderFullName] = messageMessage
		elseif messageType == "AnswerUsers" then
			CustomAchieverData["Users"][senderFullName] = messageMessage
		else
			local isSenderSelf = CustAc_isPlayerCharacter(sender)
			
			local success, o = self:Deserialize(messageMessage)
			if success == false then
				CustomAchiever:Print(time().." - Received corrupted data from "..sender..".")
			else
				CustomAchieverData["Users"][senderFullName] = o.Version or "UnknownVersion"
				local updateData = messageType == "Award" or messageType == "Revoke" or messageType == "Update"
				if messageType == "CallCategories" then
					for k,v in pairs(o.AchievementsToUpdate) do
						local alreadySent = {}
						local category = CustomAchieverData["Achievements"][k] and CustomAchieverData["Achievements"][k]["parent"]
						if category and not alreadySent[category] then
							CustAc_SendUpdatedCategoryData(category, senderFullName)
							alreadySent[category] = true
						end
					end
				else
					if o.Categories then
						for k,v in pairs(o.Categories) do
							local id = v.id
							local parent = v.parent or ""
							local name, locale = CustAc_getLocaleData(v, "name")
							
							if updateData then
								CustAc_CreateOrUpdateCategory(id, parent, name, locale, isSenderSelf, not isSenderSelf and senderFullName)
							else
								if not isSenderSelf then
									if not CustomAchieverData["AwardedPlayers"][id] then
										CustomAchieverData["AwardedPlayers"][id] = {}
									end
									CustomAchieverData["AwardedPlayers"][id][senderFullName] = true
								end
								if messageType == "UpdateAcknowledgment" then
									if CustomAchieverData["PendingUpdates"]["Categories"][id] then
										CustomAchieverData["PendingUpdates"]["Categories"][id][senderFullName] = nil
										if CustAc_countTableElements(CustomAchieverData["PendingUpdates"]["Categories"][id]) == 0 then
											CustomAchieverData["PendingUpdates"]["Categories"][id] = nil
										end
									end
								end
							end
						end
					end
					
					if o.Achievements then
						for k,v in pairs(o.Achievements) do
							if v == "DELETE" then
								local id = k
								if messageType == "UpdateAcknowledgment" then
									if CustomAchieverData["PendingUpdates"]["Achievements"][id] then
										CustomAchieverData["PendingUpdates"]["Achievements"][id][senderFullName] = nil
										if CustAc_countTableElements(CustomAchieverData["PendingUpdates"]["Achievements"][id]) == 0 then
											CustomAchieverData["PendingUpdates"]["Achievements"][id] = nil
										end
									end
									if CustomAchieverData["AwardedPlayers"][id] then
										CustomAchieverData["AwardedPlayers"][id][senderFullName] = nil
										if CustAc_countTableElements(CustomAchieverData["AwardedPlayers"][id]) == 0 then
											CustomAchieverData["AwardedPlayers"][id] = nil
										end
									end
									CustomAchieverAcknowledgmentReceived[senderFullName] = true
								else
									CustAc_DeleteAchievement(id)
								end
							else
								local id = v.id
								local parent = v.parent
								local icon = v.icon
								local points = v.points
								local name, locale = CustAc_getLocaleData(v,"name")
								local description = CustAc_getLocaleData(v, "desc")
								local rewardText = CustAc_getLocaleData(v, "rewardText", "")
								local rewardIsTitle = v.rewardIsTitle

								if updateData then
									CustAc_CreateOrUpdateAchievement(id, parent, icon, points, name, description, rewardText, rewardIsTitle, locale, isSenderSelf)
								end
								if messageType == "Award" then
									CustAc_CompleteAchievement(id)
								elseif messageType == "Revoke" then
									CustAc_RevokeAchievement(id)
								elseif messageType == "UpdateAcknowledgment" then
									if CustomAchieverData["PendingUpdates"]["Achievements"][id] then
										CustomAchieverData["PendingUpdates"]["Achievements"][id][senderFullName] = nil
										if CustAc_countTableElements(CustomAchieverData["PendingUpdates"]["Achievements"][id]) == 0 then
											CustomAchieverData["PendingUpdates"]["Achievements"][id] = nil
										end
									end
									if not isSenderSelf then
										if not CustomAchieverData["AwardedPlayers"][id] then
											CustomAchieverData["AwardedPlayers"][id] = {}
											CustomAchieverData["AwardedPlayers"][id][senderFullName] = false
										end
										CustomAchieverAcknowledgmentReceived[senderFullName] = true
									end
								else
									if not isSenderSelf then
										if not CustomAchieverData["AwardedPlayers"][id] then
											CustomAchieverData["AwardedPlayers"][id] = {}
										end
										CustomAchieverAcknowledgmentReceived[senderFullName] = true
									end
									if messageType == "AwardAcknowledgment" then
										if not isSenderSelf then CustomAchieverData["AwardedPlayers"][id][senderFullName] = true end
										CustomAchiever:Print(GREEN_FONT_COLOR_CODE..string.format(L["LOGCUSTAC_AWARD"], CustomAchiever_CreateHyperlink(id, name), WHITE_FONT_COLOR_CODE..GetPlayerLink(sender, ("[%s]"):format(sender))..FONT_COLOR_CODE_CLOSE))
									elseif messageType == "RevokeAcknowledgment" then
										if not isSenderSelf then CustomAchieverData["AwardedPlayers"][id][senderFullName] = false end
										CustomAchiever:Print(GREEN_FONT_COLOR_CODE..string.format(L["LOGCUSTAC_REVOKE"], CustomAchiever_CreateHyperlink(id, name), WHITE_FONT_COLOR_CODE..GetPlayerLink(sender, ("[%s]"):format(sender))..FONT_COLOR_CODE_CLOSE))
									end
									Custac_ChangeAwardButtonText()
								end
							end
						end
					end
				end
				
				if updateData then
					encodeAndSendAchievementInfo(o, sender, messageType.."Acknowledgment")
				elseif not isSenderSelf then
					CustomAchieverLogs_SetText("%s received from %s.", "|c"..messageTypeColors[messageType]..messageType.."|r", CustAc_delRealm(sender))
				end
			end
		end
	end
end
