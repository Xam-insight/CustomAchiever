local L = LibStub("AceLocale-3.0"):GetLocale("CustomAchiever", true);

local function encodeAndSendAchievementInfo(aData, aTarget, messageType)
	aData["Version"] = GetAddOnMetadata(CustAcAddon or "CustomAchiever", "Version")
	local s = CustomAchiever:Serialize(aData)
	local text = messageType.."#"..s
	CustomAchiever:SendCommMessage(CustomAchieverGlobal_CommPrefix, text, "WHISPER", aTarget)
end

local function sendInfo(info, aTarget, messageType)
	CustomAchiever:SendCommMessage(CustomAchieverGlobal_CommPrefix, (info and messageType.."#"..info) or messageType.."#NoData", (aTarget and "WHISPER") or "GUILD", aTarget)
end

function CustAc_SendCallForUsers()
	sendInfo(GetAddOnMetadata(CustAcAddon or "CustomAchiever", "Version"), nil, "CallUsers")
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
					UIErrorsFrame:AddMessage(L["SHARECUSTAC_NOACKNOWLEDGMENT"], 1, 0, 0, 1)
					CustomAchiever:Print(L["SHARECUSTAC_NOACKNOWLEDGMENT"])
				end
				return
			else
				CustomAchieverLastManualCall[aTarget.."|"..messageType] = callTime
			end
		end
	elseif messageType == "Revoke" and not CustAc_isPlayerCharacter(aTarget) then
		if not CustomAchieverAcknowledgmentReceived[aTarget] then
			UIErrorsFrame:AddMessage(L["SHARECUSTAC_NOACKNOWLEDGMENT"], 1, 0, 0, 1)
			CustomAchiever:Print(L["SHARECUSTAC_NOACKNOWLEDGMENT"])
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
		end
		data["Achievements"][achievementId] = CustomAchieverData["Achievements"][achievementId] or "DELETE"
		if CustomAchieverData["AwardedPlayers"][achievementId] then
			for k,v in pairs(CustomAchieverData["AwardedPlayers"][achievementId]) do
				if not CustAc_isPlayerCharacter(k) and (not alsoSendTo or k ~= alsoSendTo) then
					CustAc_SendUpdatedDataTo(k, achievementId, categoryId, data)
				end
			end
		end
		if alsoSendTo then
			CustAc_SendUpdatedDataTo(alsoSendTo, achievementId, categoryId, data)
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
		for k,v in pairs(CustomAchieverData["Achievements"]) do
			if v["parent"] == categoryId then
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
				if not CustAc_isPlayerCharacter(k2) and CustomAchieverData["AwardedPlayers"][k][k2] then
					data["Achievements"][k] = CustomAchieverData["Achievements"][k] or "DELETE"
					targets[k2] = true
				end
			end
		end
		
		for k,v in pairs(targets) do
			CustAc_SendUpdatedDataTo(k, nil, nil, data)
		end
	end
end

function CustAc_SendUpdatedDataTo(player, achievementId, categoryId, data)
	if not CustAc_isPlayerCharacter(sender) then
		if categoryId then
			if not CustomAchieverData["PendingUpdates"]["Categories"][categoryId] then
				CustomAchieverData["PendingUpdates"]["Categories"][categoryId] = {}
			end
			CustomAchieverData["PendingUpdates"]["Categories"][categoryId][player] = true
		end
		
		if achievementId then
			if not CustomAchieverData["PendingUpdates"]["Achievements"][achievementId] then
				CustomAchieverData["PendingUpdates"]["Achievements"][achievementId] = {}
			end
			CustomAchieverData["PendingUpdates"]["Achievements"][achievementId][player] = true
		end
	end
	
	manualEncodeAndSendAchievementInfo(data, player, "Update")
end

CustomAchieverAcknowledgmentReceived = {}
function CustomAchiever:ReceiveDataFrame_OnEvent(prefix, message, distribution, sender)
	if prefix == CustomAchieverGlobal_CommPrefix then
		--CustomAchiever:Print(time().." - Received message from "..sender..".")
		local messageType, messageMessage = strsplit("#", message, 2)
		--if not isPlayerCharacter(sender) then
		if messageType == "CallUsers" then
			sendInfo(GetAddOnMetadata(CustAcAddon or "CustomAchiever", "Version"), sender, "AnswerUsers")
			CustomAchieverData["Users"][CustAc_addRealm(sender)] = messageMessage
		elseif messageType == "AnswerUsers" then
			CustomAchieverData["Users"][CustAc_addRealm(sender)] = messageMessage
		else
			local isSenderSelf = CustAc_isPlayerCharacter(sender)
			
			local success, o = self:Deserialize(messageMessage)
			if success == false then
				CustomAchiever:Print(time().." - Received corrupted data from "..sender..".")
			else
				CustomAchieverData["Users"][CustAc_addRealm(sender)] = o.Version or "UnknownVersion"
				local updateData = messageType == "Award" or messageType == "Revoke" or messageType == "Update"
				if o.Categories then
					for k,v in pairs(o.Categories) do
						local id = v.id
						--local parent = v.parent
						local name, locale = CustAc_getLocaleData(v,"name")
						
						if updateData then
							CustAc_CreateOrUpdateCategory(id, nil, name, locale, isSenderSelf)
							--CustAc_RefreshCustomAchiementFrame(nil, nil, id)
						else
							if not isSenderSelf then
								if not CustomAchieverData["AwardedPlayers"][id] then
									CustomAchieverData["AwardedPlayers"][id] = {}
								end
								CustomAchieverData["AwardedPlayers"][id][CustAc_addRealm(sender)] = true
							end
							if messageType == "UpdateAcknowledgment" then
								if CustomAchieverData["PendingUpdates"]["Categories"][id] then
									CustomAchieverData["PendingUpdates"]["Categories"][id][CustAc_addRealm(sender)] = nil
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
									CustomAchieverData["PendingUpdates"]["Achievements"][id][CustAc_addRealm(sender)] = nil
									if CustAc_countTableElements(CustomAchieverData["PendingUpdates"]["Achievements"][id]) == 0 then
										CustomAchieverData["PendingUpdates"]["Achievements"][id] = nil
									end
								end
								if CustomAchieverData["AwardedPlayers"][id] then
									CustomAchieverData["AwardedPlayers"][id][CustAc_addRealm(sender)] = nil
									if CustAc_countTableElements(CustomAchieverData["AwardedPlayers"][id]) == 0 then
										CustomAchieverData["AwardedPlayers"][id] = nil
									end
								end
								CustomAchieverAcknowledgmentReceived[CustAc_addRealm(sender)] = true
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
									CustomAchieverData["PendingUpdates"]["Achievements"][id][CustAc_addRealm(sender)] = nil
									if CustAc_countTableElements(CustomAchieverData["PendingUpdates"]["Achievements"][id]) == 0 then
										CustomAchieverData["PendingUpdates"]["Achievements"][id] = nil
									end
								end
								if not isSenderSelf then
									if not CustomAchieverData["AwardedPlayers"][id] then
										CustomAchieverData["AwardedPlayers"][id] = {}
										CustomAchieverData["AwardedPlayers"][id][CustAc_addRealm(sender)] = false
									end
									CustomAchieverAcknowledgmentReceived[CustAc_addRealm(sender)] = true
								end
							else
								if not isSenderSelf then
									if not CustomAchieverData["AwardedPlayers"][id] then
										CustomAchieverData["AwardedPlayers"][id] = {}
									end
									CustomAchieverAcknowledgmentReceived[CustAc_addRealm(sender)] = true
								end
								if messageType == "AwardAcknowledgment" then
									if not isSenderSelf then CustomAchieverData["AwardedPlayers"][id][CustAc_addRealm(sender)] = true end
									CustomAchiever:Print(GREEN_FONT_COLOR_CODE..string.format(L["LOGCUSTAC_AWARD"], YELLOW_FONT_COLOR_CODE.."["..name.."]", WHITE_FONT_COLOR_CODE..GetPlayerLink(sender, ("[%s]"):format(sender))))
								elseif messageType == "RevokeAcknowledgment" then
									if not isSenderSelf then CustomAchieverData["AwardedPlayers"][id][CustAc_addRealm(sender)] = false end
									CustomAchiever:Print(GREEN_FONT_COLOR_CODE..string.format(L["LOGCUSTAC_REVOKE"], YELLOW_FONT_COLOR_CODE.."["..name.."]", WHITE_FONT_COLOR_CODE..GetPlayerLink(sender, ("[%s]"):format(sender))))
								end
								Custac_ChangeAwardButtonText()
							end
						end
					end
				end
				
				if updateData then
					if CustAc_AchievementFrameAchievements and CustAc_AchievementFrameAchievements:IsShown() then
						CustAc_AchievementFrameCategories_UpdateDataProvider()
						CustAc_AchievementFrameAchievements_UpdateDataProvider()
					end
					encodeAndSendAchievementInfo(o, sender, messageType.."Acknowledgment")
				end
			end
		end
	end
end

