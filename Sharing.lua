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

function CustAc_SendUpdatedData(achievementId, alsoSendTo)
	if CustomAchieverData["AwardedPlayers"][achievementId] then
		local data = {}
		local categoryId = CustomAchieverData["Achievements"][achievementId]["parent"]
		data["Category"] 	= CustomAchieverData["Categories"][categoryId]
		data["Achievement"] = CustomAchieverData["Achievements"][achievementId]
		for k,v in pairs(CustomAchieverData["AwardedPlayers"][achievementId]) do
			if not CustAc_isPlayerCharacter(k) and (not alsoSendTo or k ~= alsoSendTo) then
				CustAc_SendUpdatedDataTo(k, achievementId, categoryId)
			end
		end
		if alsoSendTo then
			CustAc_SendUpdatedDataTo(alsoSendTo, achievementId, categoryId)
		end
	end
end

function CustAc_SendUpdatedDataTo(player, achievementId, categoryId)
	if not CustomAchieverData["PendingUpdates"]["Categories"][categoryId] then
		CustomAchieverData["PendingUpdates"]["Categories"][categoryId] = {}
	end
	CustomAchieverData["PendingUpdates"]["Categories"][categoryId][player] = true
	if not CustomAchieverData["PendingUpdates"]["Categories"][achievementId] then
		CustomAchieverData["PendingUpdates"]["Achievements"][achievementId] = {}
	end
	CustomAchieverData["PendingUpdates"]["Achievements"][achievementId][player] = true
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
				if o.Category then
					local id = o.Category.id
					--local parent = o.Category.parent
					local name, locale = CustAc_getLocaleData(o.Category,"name")
					
					CustAc_CreateOrUpdateCategory(id, nil, name, locale, true)
					if messageType == "Update" then
						encodeAndSendAchievementInfo(o, sender, "UpdateAcknowledgment")
					elseif messageType == "UpdateAcknowledgment" then
						if CustomAchieverData["PendingUpdates"]["Categories"][id] then
							CustomAchieverData["PendingUpdates"]["Categories"][id][CustAc_addRealm(sender)] = nil
						end
					elseif messageType == "Award" or messageType == "Revoke" then
						if CustAc_AchievementFrameAchievements and CustAc_AchievementFrameAchievements:IsShown() then
							CustAc_AchievementFrameCategories_UpdateDataProvider()
						end
					end
				end
				
				if o.Achievement then
					local id = o.Achievement.id
					local parent = o.Achievement.parent
					local icon = o.Achievement.icon
					local points = o.Achievement.points
					local name, locale = CustAc_getLocaleData(o.Achievement,"name")
					local description = CustAc_getLocaleData(o.Achievement, "desc")

					CustAc_CreateOrUpdateAchievement(id, parent, icon, points, name, description, locale, true)
					if messageType == "Award" then
						CustAc_CompleteAchievement(id)
						CustomAchieverFrame_UpdateAchievementAlertFrame()
						if CustAc_AchievementFrameAchievements and CustAc_AchievementFrameAchievements:IsShown() then
							CustAc_AchievementFrameAchievements_UpdateDataProvider()
						end
						encodeAndSendAchievementInfo(o, sender, "AwardAcknowledgment")
					elseif messageType == "Revoke" then
						CustAc_RevokeAchievement(id)
						CustomAchieverFrame_UpdateAchievementAlertFrame()
						if CustAc_AchievementFrameAchievements and CustAc_AchievementFrameAchievements:IsShown() then
							CustAc_AchievementFrameAchievements_UpdateDataProvider()
						end
						encodeAndSendAchievementInfo(o, sender, "RevokeAcknowledgment")
					elseif messageType == "Update" then
						encodeAndSendAchievementInfo(o, sender, "UpdateAcknowledgment")
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
		--end
	end
end

