local L = LibStub("AceLocale-3.0"):GetLocale("CustomAchiever", true);

local function encodeAndSendAchievementInfo(aData, aTarget, messageType)
	local s = CustomAchiever:Serialize(aData)
	local text = messageType.."#"..s
	CustomAchiever:SendCommMessage(CustomAchieverGlobal_CommPrefix, text, "WHISPER", aTarget)
end

function manualEncodeAndSendAchievementInfo(aData, aTarget, messageType)
	if messageType == "Award" and not CustAc_isPlayerCharacter(aTarget) then
		local callTime = time()
		if not CustomAchieverLastManualCall[aTarget] then
			CustomAchieverLastManualCall[aTarget] = callTime
		else
			if callTime < CustomAchieverLastManualCall[aTarget] + 300 then
				if CustomAchieverAcknowledgmentReceived[aTarget] then
					CustomAchiever:Print(string.format(L["SHARECUSTAC_WAIT"], math.ceil((300 - callTime + CustomAchieverLastManualCall[aTarget]) / 60)))
				else
					UIErrorsFrame:AddMessage(L["SHARECUSTAC_NOACKNOWLEDGMENT"], 1, 0, 0, 1)
					CustomAchiever:Print(L["SHARECUSTAC_NOACKNOWLEDGMENT"])
				end
				return
			else
				CustomAchieverLastManualCall[aTarget] = callTime
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
	if CustomAchieverData["AwardedPlayers"][achievementId] then
		local data = {}
		data["Categories"] = {}
		data["Achievements"] = {}
		local categoryId = CustomAchieverData["Achievements"][achievementId]["parent"]
		data["Categories"][categoryId] 	= CustomAchieverData["Categories"][categoryId]
		data["Achievements"][achievementId] = CustomAchieverData["Achievements"][achievementId]
		for k,v in pairs(CustomAchieverData["AwardedPlayers"][achievementId]) do
			if not CustAc_isPlayerCharacter(k) and (not alsoSendTo or k ~= alsoSendTo) then
				CustAc_SendUpdatedDataTo(k, achievementId, categoryId, data)
			end
		end
		if alsoSendTo then
			CustAc_SendUpdatedDataTo(alsoSendTo, achievementId, categoryId, data)
		end
	end
end

function CustAc_SendUpdatedCategoryData(categoryId, alsoSendTo)
	if CustomAchieverData["AwardedPlayers"][categoryId] then
		local data = {}
		data["Categories"] = {}
		data["Achievements"] = {}
		data["Categories"][categoryId] 	= CustomAchieverData["Categories"][categoryId]
		for k,v in pairs(CustomAchieverData["Achievements"]) do
			if v["parent"] == categoryId then
				data["Achievements"][k] = v
			end
		end
		
		for k,v in pairs(CustomAchieverData["AwardedPlayers"][categoryId]) do
			if not CustAc_isPlayerCharacter(k) and (not alsoSendTo or k ~= alsoSendTo) then
				CustAc_SendUpdatedDataTo(k, nil, categoryId, data)
			end
		end
		if alsoSendTo then
			CustAc_SendUpdatedDataTo(alsoSendTo, nil, categoryId, data)
		end
	end
end

function CustAc_SendUpdatedDataTo(player, achievementId, categoryId, data)
	if categoryId then
		if not CustomAchieverData["PendingUpdates"]["Categories"][categoryId] then
			CustomAchieverData["PendingUpdates"]["Categories"][categoryId] = {}
		end
		CustomAchieverData["PendingUpdates"]["Categories"][categoryId][player] = true
	end
	
	if achievementId then
		if not CustomAchieverData["PendingUpdates"]["Categories"][achievementId] then
			CustomAchieverData["PendingUpdates"]["Achievements"][achievementId] = {}
		end
		CustomAchieverData["PendingUpdates"]["Achievements"][achievementId][player] = true
	end
	
	manualEncodeAndSendAchievementInfo(data, player, "Update")
end

CustomAchieverAcknowledgmentReceived = {}
function CustomAchiever:ReceiveDataFrame_OnEvent(prefix, message, distribution, sender)
	if prefix == CustomAchieverGlobal_CommPrefix then
		--CustomAchiever:Print(time().." - Received message from "..sender..".")
		local messageType, messageMessage = strsplit("#", message, 2)
		--if not isPlayerCharacter(sender) then
			local success, o = self:Deserialize(messageMessage)
			if success == false then
				CustomAchiever:Print(time().." - Received corrupted data from "..sender..".")
			else
				local updateData = messageType == "Award" or messageType == "Revoke" or messageType == "Update"
				if o.Categories then
					for k,v in pairs(o.Categories) do
						local id = v.id
						--local parent = v.parent
						local name, locale = CustAc_getLocaleData(v,"name")
						
						if updateData then
							CustAc_CreateOrUpdateCategory(id, nil, name, locale, true)
						else
							if not CustomAchieverData["AwardedPlayers"][id] then
								CustomAchieverData["AwardedPlayers"][id] = {}
							end
							CustomAchieverData["AwardedPlayers"][id][CustAc_addRealm(sender)] = true
							if messageType == "UpdateAcknowledgment" then
								if CustomAchieverData["PendingUpdates"]["Categories"][id] then
									CustomAchieverData["PendingUpdates"]["Categories"][id][CustAc_addRealm(sender)] = nil
								end
							end
						end
					end
				end
				
				if o.Achievements then
					for k,v in pairs(o.Achievements) do
						local id = v.id
						local parent = v.parent
						local icon = v.icon
						local points = v.points
						local name, locale = CustAc_getLocaleData(v,"name")
						local description = CustAc_getLocaleData(v, "desc")
						local rewardText = CustAc_getLocaleData(v, "rewardText")
						local rewardIsTitle = v.rewardIsTitle

						if updateData then
							CustAc_CreateOrUpdateAchievement(id, parent, icon, points, name, description, rewardText, rewardIsTitle, locale, true)
						end
						if messageType == "Award" then
							CustAc_CompleteAchievement(id)
						elseif messageType == "Revoke" then
							CustAc_RevokeAchievement(id)
						elseif messageType == "UpdateAcknowledgment" then
							if CustomAchieverData["PendingUpdates"]["Achievements"][id] then
								CustomAchieverData["PendingUpdates"]["Achievements"][id][CustAc_addRealm(sender)] = nil
							end
						else
							if not CustomAchieverData["AwardedPlayers"][id] then
								CustomAchieverData["AwardedPlayers"][id] = {}
							end
							CustomAchieverAcknowledgmentReceived[CustAc_addRealm(sender)] = true
							if messageType == "AwardAcknowledgment" then
								CustomAchieverData["AwardedPlayers"][id][CustAc_addRealm(sender)] = true
								CustomAchiever:Print(GREEN_FONT_COLOR_CODE..string.format(L["LOGCUSTAC_AWARD"], YELLOW_FONT_COLOR_CODE.."["..name.."]", WHITE_FONT_COLOR_CODE..GetPlayerLink(sender, ("[%s]"):format(sender))))
							elseif messageType == "RevokeAcknowledgment" then
								CustomAchieverData["AwardedPlayers"][id][CustAc_addRealm(sender)] = nil
								CustomAchiever:Print(GREEN_FONT_COLOR_CODE..string.format(L["LOGCUSTAC_REVOKE"], YELLOW_FONT_COLOR_CODE.."["..name.."]", WHITE_FONT_COLOR_CODE..GetPlayerLink(sender, ("[%s]"):format(sender))))
							end
							Custac_ChangeAwardButtonText()
						end
					end
				end
				
				if updateData then
					if CustAc_AchievementFrameAchievements and CustAc_AchievementFrameAchievements:IsShown() then
						CustAc_AchievementFrameCategories_UpdateDataProvider()
						CustAc_AchievementFrameAchievements_UpdateDataProvider()
					end
					CustomAchieverFrame_UpdateAchievementAlertFrame()
					encodeAndSendAchievementInfo(o, sender, messageType.."Acknowledgment")
				end
			end
		--end
	end
end

