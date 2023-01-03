local L = LibStub("AceLocale-3.0"):GetLocale("CustomAchiever", true);


local custacLastManualCall = {}
function manualEncodeAndSendAchievementInfo(aData, aTarget, messageType)
	if messageType == "Award" then
		local callTime = time()
		if not custacLastManualCall[aTarget] then
			custacLastManualCall[aTarget] = callTime
		else
			if callTime < custacLastManualCall[aTarget] + 10 then
				CustomAchiever:Print(string.format(L["SHARECUSTAC_WAIT"], 10 - callTime + custacLastManualCall[aTarget]))
				return
			else
				custacLastManualCall[aTarget] = callTime
			end
		end
	end
	encodeAndSendAchievementInfo(aData, aTarget, messageType)
end

function encodeAndSendAchievementInfo(aData, aTarget, messageType)
	local s = CustomAchiever:Serialize(aData)
	local text = messageType.."#"..s
	CustomAchiever:SendCommMessage(CustomAchieverGlobal_CommPrefix, text, "WHISPER", aTarget)
end

function CustomAchiever:ReceiveDataFrame_OnEvent(prefix, message, distribution, sender)
	if prefix == CustomAchieverGlobal_CommPrefix then
		--CustomAchiever:Print(time().." - Received message from "..sender..".")
		local messageType, messageMessage = strsplit("#", message, 2)
		--if not isPlayerCharacter(sender) then
			local success, o = self:Deserialize(messageMessage)
			if success == false then
				CustomAchiever:Print(time().." - Received corrupted data from "..sender..".")
			else
				local id = o.id
				local parent = o.parent
				local icon = o.icon
				local points = o.points
				local name, locale = CustAc_getLocaleData(o,"name")
				local description = CustAc_getLocaleData(o, "desc")

				CustAc_CreateOrUpdateAchievement(id, parent, icon, points, name, description, locale, true)
				if messageType == "Award" then
					CustAc_CompleteAchievement(id)
					CustomAchieverFrame_UpdateAchievementAlertFrame()
					if CustAc_AchievementFrameAchievements and CustAc_AchievementFrameAchievements:IsShown() then
						CustAc_AchievementFrameAchievements_UpdateDataProvider()
					end
				elseif messageType == "Revoke" then
					CustAc_RevokeAchievement(id)
					CustomAchieverFrame_UpdateAchievementAlertFrame()
					if CustAc_AchievementFrameAchievements and CustAc_AchievementFrameAchievements:IsShown() then
						CustAc_AchievementFrameAchievements_UpdateDataProvider()
					end
				end
			end
		--end
	end
end

