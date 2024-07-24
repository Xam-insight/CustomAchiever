local L = LibStub("AceLocale-3.0"):NewLocale("CustomAchiever", "enUS", true)

if L then

L["CUSTOMACHIEVER_WELCOME"] = "Type /custac to show Custom Achiever."

L["SPACE_BEFORE_DOT"] = ""

L["GENERAL_SECTION"] = "General options"
L["ENABLE_SOUND"] = "Enable Custom Achiever sounds"
L["ENABLE_SOUND_DESC"] = "Enables / disables Custom Achiever sounds"
L["ENABLE_ACHIEVEMENT_ANNOUNCE"] = "Enable Achievements announce"
L["ENABLE_ACHIEVEMENT_ANNOUNCE_DESC"] = "Enables / disables the Achievements announce window"
L["ENABLE_MINIMAPBUTTON"] = "Minimap button"
L["ENABLE_MINIMAPBUTTON_DESC"] = "Shows / hides Minimap button"
L["WINDOW_SECTION"] = "Custom Achiever window options"
L["MENUOPTIONS_TOOLTIP"] = "Custom Achiever options"
L["MENUOPTIONS_TOOLTIPDETAIL"] = "Change Custom Achiever options."
L["LOGS_TOOLTIP"] = "Logs"
L["LOGS_TOOLTIPDETAIL"] = "Shows / hides logs."

L["REFRESH_TOOLTIP"] = "Refresh"
L["REFRESH_TOOLTIPDETAIL"] = "Send this category achievements to the target|nand to known Custom Achiever users."

L["MENUCUSTAC_CATEGORY"] = "Category"
L["MENUCUSTAC_CATEGORIES"] = "Categories"
L["MENUCUSTAC_NEWCATEGORY"] = "Create Category"
L["MENUCUSTAC_ACHIEVEMENT"] = "Achievement"
L["MENUCUSTAC_ACHIEVEMENTS"] = "Custom Achievements"
L["MENUCUSTAC_NEW"] = "Create a new Achievement"
L["MENUCUSTAC_DEFAULT_NAME"] = "Custom Achievement"
L["MENUCUSTAC_ICON"] = "Icon"
L["MENUCUSTAC_POINTS"] = "Points"
L["MENUCUSTAC_CAT_CONFIRM_DELETION"] = "Are you sure you want to permanently delete the Category |cff00ff00%s|r? This Category Achievements will be moved to |cff00ff00%s|r."
L["MENUCUSTAC_CONFIRM_DELETION"] = "Are you sure you want to permanently delete the Custom Achievement |cff00ff00%s|r?"

L["MENUCUSTAC_MOVE_ACHIEVEMENT"] = "Move selected Achievement into this Category."
L["MENUCUSTAC_MOVE_CATEGORY"] = "Move selected Category into this Category."
L["MENUCUSTAC_EXTRACT_CATEGORY"] = "Extract the subcategory."

L["MENUCUSTAC_AWARD"] = "Award"
L["MENUCUSTAC_REVOKE"] = "Revoke"

L["LOGCUSTAC_AWARD"] = "|cff00ff00%s|r Achievement awarded to %s."
L["LOGCUSTAC_REVOKE"] = "|cff00ff00%s|r Achievement revoked from %s."

L["SHARECUSTAC_WAIT"] = "Wait %d |4minute:minutes; %d |4second:seconds; before sending Achievements to this player again."
L["SHARECUSTAC_NOACKNOWLEDGMENT"] = "%s does not seem to have Custom Achiever installed or is offline."

L["MENUOPTIONS_TOOLTIP"] = "Custom Achiever options"
L["MENUOPTIONS_TOOLTIPDETAIL"] = "Change Custom Achiever options."

L["MINIMAP_TOOLTIP1"] = "Left click to show Custom Achiever."
L["MINIMAP_TOOLTIP2"] = "Right click to open options panel."

L["CUSTAC_HELPTIP_AWARD"] = "Award the Achievement to your target (to yourself if no target).|n|nYour target must have installed CustomAchiever."

end
