local ACR = LibStub("AceConfigRegistry-3.0")
local ACD = LibStub("AceConfigDialog-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("CustomAchiever", true)

function loadCustomAchieverOptions()
	local CustomAchieverOptions = {
		type = "group",
		name = format("%s |cffADFF2Fv%s|r", "Custom Achiever", GetAddOnMetadata(CustAcAddon or "CustomAchiever", "Version") or ""),
		args = {
			general = {
				type = "group", order = 1,
				name = L["GENERAL_SECTION"],
				inline = true,
				args = {
					enableMiniMapButton = {
						type = "toggle", order = 1,
						width = "full",
						name = L["ENABLE_MINIMAPBUTTON"],
						desc = L["ENABLE_MINIMAPBUTTON_DESC"],
						set = function(info, val)
							CustomAchieverOptionsData["CustomAchieverMIcon"].minimapIcon.hide = not val
							local libDBIcon = LibStub("LibDBIcon-1.0")
							if CustomAchieverOptionsData["CustomAchieverMIcon"].minimapIcon.hide then
								libDBIcon:Hide("CustomAchiever")
							else
								libDBIcon:Show("CustomAchiever")
							end
							--CustAc_saveCustomAchieverOptionsDataForAddon()
						end,
						get = function(info)
							return not CustomAchieverOptionsData["CustomAchieverMIcon"].minimapIcon.hide
						end
					},
					enableSound = {
						type = "toggle", order = 2,
						width = "full",
						name = L["ENABLE_SOUND"],
						desc = L["ENABLE_SOUND_DESC"],
						set = function(info, val) 
							CustomAchieverOptionsData["CustomAchieverSoundsDisabled"] = not val
							--CustAc_saveCustomAchieverOptionsDataForAddon()
						end,
						get = function(info)
							local enabled = true
							if CustomAchieverOptionsData["CustomAchieverSoundsDisabled"] ~= nil then
								enabled = not CustomAchieverOptionsData["CustomAchieverSoundsDisabled"]
							end
							return enabled
						end
					},
					enableAchievementAnnounce = {
						type = "toggle", order = 3,
						width = "full",
						name = L["ENABLE_ACHIEVEMENT_ANNOUNCE"],
						desc = L["ENABLE_ACHIEVEMENT_ANNOUNCE_DESC"],
						set = function(info, val) 
							CustomAchieverOptionsData["CustomAchieverAchievementAnnounceDisabled"] = not val
							--CustAc_saveCustomAchieverOptionsDataForAddon()
						end,
						get = function(info)
							local enabled = true
							if CustomAchieverOptionsData["CustomAchieverAchievementAnnounceDisabled"] ~= nil then
								enabled = not CustomAchieverOptionsData["CustomAchieverAchievementAnnounceDisabled"]
							end
							return enabled
						end
					}
				}
			}
		}
	}

	ACR:RegisterOptionsTable("CustomAchiever", CustomAchieverOptions)
	ACD:AddToBlizOptions("CustomAchiever", "Custom Achiever")
	ACD:SetDefaultSize("CustomAchiever", 500, 200)
end
