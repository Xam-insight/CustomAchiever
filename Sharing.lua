local L = LibStub("AceLocale-3.0"):GetLocale("CustomAchiever", true);

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
				end
			end
		--end
	end
end

