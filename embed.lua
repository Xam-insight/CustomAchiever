local L = LibStub("AceLocale-3.0"):GetLocale("CustomAchiever", true)
local LibDD = LibStub:GetLibrary("LibUIDropDownMenu-4.0")

local nextCustomCategoryId
local nextCustomAchieverId

local selectedAchievement = {}

local function CustAc_InitSelectedAchievement(achievementId, categoryId)
	selectedAchievement = {}
	selectedAchievement.achievementId            =  achievementId or nextCustomAchieverId
	selectedAchievement.achievementCategory      =  categoryId    or (CustomAchieverData["Achievements"][achievementId] and CustomAchieverData["Achievements"][achievementId].parent) or nextCustomCategoryId
	selectedAchievement.achievementCategoryName  =  CustAc_getLocaleData(CustomAchieverData["Categories"][selectedAchievement.achievementCategory], "name") or CustAc_delRealm(selectedAchievement.achievementCategory)
	selectedAchievement.achievementName          =  CustAc_getLocaleData(CustomAchieverData["Achievements"][achievementId], "name")                                        or L["MENUCUSTAC_DEFAULT_NAME"]
	selectedAchievement.achievementIcon          = (CustomAchieverData["Achievements"][achievementId] and CustomAchieverData["Achievements"][achievementId].icon)          or 236376
	selectedAchievement.achievementDesc          =  CustAc_getLocaleData(CustomAchieverData["Achievements"][achievementId], "desc")                                        or DESCRIPTION
	selectedAchievement.achievementRewardText    =  CustAc_getLocaleData(CustomAchieverData["Achievements"][achievementId], "rewardText", "")                              or ""
	selectedAchievement.achievementRewardIsTitle = (CustomAchieverData["Achievements"][achievementId] and CustomAchieverData["Achievements"][achievementId].rewardIsTitle) or false
	selectedAchievement.achievementPoints        = (CustomAchieverData["Achievements"][achievementId] and CustomAchieverData["Achievements"][achievementId].points)        or 0
end

StaticPopupDialogs["CUSTAC_CAT_DELETE"] = {
	text = L["MENUCUSTAC_CAT_CONFIRM_DELETION"],
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function (self, data)
		StaticPopupSpecial_Hide(CustacCategoryCreateDialog)
		CustAc_DeleteCategory(data.categoryId, data.newCategory)
		if selectedAchievement.achievementCategory and selectedAchievement.achievementCategory == data.categoryId then
			LibDD:UIDropDownMenu_Initialize(CustomAchieverCategoryDownMenu, CustAc_CategoryDropDownMenu_Update)
			LibDD:UIDropDownMenu_SetSelectedValue(CustomAchieverCategoryDownMenu, nextCustomCategoryId)
			LibDD:UIDropDownMenu_Initialize(CustomAchieverAchievementsDownMenu, CustAc_AchievementDropDownMenu_Update)
			LibDD:UIDropDownMenu_SetSelectedValue(CustomAchieverAchievementsDownMenu, nextCustomAchieverId)
			CustAc_InitSelectedAchievement(nextCustomAchieverId, nextCustomCategoryId)
			CustomAchieverFrame_UpdateAchievementAlertFrame()
		end
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,  -- avoid some UI taint, see http://www.wowace.com/announcements/how-to-avoid-some-ui-taint/
}

StaticPopupDialogs["CUSTAC_DELETE"] = {
	text = L["MENUCUSTAC_CONFIRM_DELETION"],
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function (self, data)
		CustAc_DeleteAchievement(data.achievementId)
		CustAc_SendUpdatedAchievementData(data.achievementId, custacDataTarget)
		LibDD:UIDropDownMenu_Initialize(CustomAchieverAchievementsDownMenu, CustAc_AchievementDropDownMenu_Update)
		LibDD:UIDropDownMenu_SetSelectedValue(CustomAchieverAchievementsDownMenu, nextCustomAchieverId)
		CustAc_InitSelectedAchievement(nextCustomAchieverId, selectedAchievement.achievementCategory)
		CustomAchieverFrame_UpdateAchievementAlertFrame()
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,  -- avoid some UI taint, see http://www.wowace.com/announcements/how-to-avoid-some-ui-taint/
}

custacDataTarget = UNKNOWN
function Custac_DetermineTarget()
	local name, realm = UnitFullName("target")
	local target = (name and CustAc_addRealm(name, realm)) or CustAc_playerCharacter()
	
	if UnitIsPlayer("target") then
		custacDataTarget = target
	else
		custacDataTarget = CustAc_playerCharacter()
	end
end

function Custac_ChangeAwardButtonText(force)
	if CustomAchieverFrame:IsShown() then
		if custacDataTarget == UNKNOWN or force then
			Custac_DetermineTarget()
		end
	
		if CustAc_IsAchievementCompletedBy(selectedAchievement.achievementId, custacDataTarget, CustAc_isPlayerCharacter(custacDataTarget)) then
			CustomAchieverFrame.AwardButton:SetText(L["MENUCUSTAC_REVOKE"])
		else
			CustomAchieverFrame.AwardButton:SetText(L["MENUCUSTAC_AWARD"])
		end
		CustomAchieverFrame_UpdateTargetTooltip()
	end
end

function CustomAchieverFrame_OnEvent(self, event)
	if event == "PLAYER_TARGET_CHANGED" then
		Custac_DetermineTarget()
		Custac_ChangeAwardButtonText()
	end
end

function CustAc_TargetUnit(name, exactMatch)
	if exactMatch then
		custacDataTarget = CustAc_addRealm(name)
		Custac_ChangeAwardButtonText()
	elseif UnitIsPlayer(name) then
		Custac_DetermineTarget()
		Custac_ChangeAwardButtonText()
	end
end

function CustomAchieverFrame_OnLoad(self)
	self:RegisterForDrag("LeftButton")
	self.CloseButton:SetHitRectInsets(6, 6, 6, 6)
	self.AchievementAlertFrame.Icon.Texture:SetTexCoord(0, 0, 0, 1, 1, 0, 1, 1)	

	applyCustomAchieverWindowOptions()
	
	self:SetTitle("CustomAchiever")
	SetPortraitToTexture(self.PortraitContainer.portrait, "Interface\\Friendsframe\\friendsframescrollicon")
	
	local custacOptionsButton = createCustomAchieverOptionsButton(self)
	local custacLogsButton = createCustomAchieverLogsButton(self)
	CustomAchieverLogs:Disable()
	
	CustomAchieverFrame.RefreshButton:SetAttribute("tooltip", L["REFRESH_TOOLTIP"])
	CustomAchieverFrame.RefreshButton:SetAttribute("tooltipDetail", { L["REFRESH_TOOLTIPDETAIL"] })
	
	CustomAchieverFrameAchievementAlertFrame.GuildBanner:Hide()
	CustomAchieverFrameAchievementAlertFrame.OldAchievement:Hide()
	CustomAchieverFrameAchievementAlertFrame.GuildBorder:Hide()
	CustomAchieverFrameAchievementAlertFrame.Icon.Bling:Hide()
	
	nextCustomCategoryId = CustAc_playerCharacter()
	local categoryFontstring = CustomAchieverFrame:CreateFontString("CategoryFontstring", "ARTWORK", "GameFontNormal")
	categoryFontstring:SetText(L["MENUCUSTAC_CATEGORY"])
	categoryFontstring:SetPoint("TOPLEFT", 65, -39)
	local categoryDropDown = LibDD:Create_UIDropDownMenu("CustomAchieverCategoryDownMenu", self, "MENU")
	categoryDropDown:SetPoint("TOPRIGHT", -30 , -30)
	LibDD:UIDropDownMenu_SetWidth(categoryDropDown, 150)

	LibDD:UIDropDownMenu_Initialize(categoryDropDown, CustAc_CategoryDropDownMenu_Update)
	LibDD:UIDropDownMenu_SetSelectedValue(categoryDropDown, nextCustomCategoryId)

	nextCustomAchieverId = CustAc_playerCharacter()..'-'..CustAc_getTimeUTCinMS()
	local achievementFontstring = CustomAchieverFrame:CreateFontString("AchievementFontstring", "ARTWORK", "GameFontNormal")
	achievementFontstring:SetText(L["MENUCUSTAC_ACHIEVEMENT"])
	achievementFontstring:SetPoint("TOPLEFT", 30, -79)
	local achievementDropDown = LibDD:Create_UIDropDownMenu("CustomAchieverAchievementsDownMenu", self, "MENU")
	achievementDropDown:SetPoint("TOPRIGHT", -18 , -70)
	LibDD:UIDropDownMenu_SetWidth(achievementDropDown, 200)

	local iconFontstring = CustomAchieverFrame:CreateFontString("IconFontstring", "ARTWORK", "GameFontNormal")
	iconFontstring:SetText(L["MENUCUSTAC_ICON"])
	iconFontstring:SetPoint("TOPLEFT", 30, -197)
	CustomAchieverFrame.IconEditBox:SetPoint("TOPLEFT", 80 , -195)
	CustomAchieverFrame.IconEditBox:SetSize(70, 16)
	CustomAchieverFrame.IconEditBox:HighlightText()
	CustomAchieverFrame.IconEditBox.type = "achievementIcon"

	local pointsFontstring = CustomAchieverFrame:CreateFontString("PointsFontstring", "ARTWORK", "GameFontNormal")
	pointsFontstring:SetText(L["MENUCUSTAC_POINTS"])
	pointsFontstring:SetPoint("TOPRIGHT", -70, -197)
	CustomAchieverFrame.PointsEditBox:SetPoint("TOPRIGHT", -30 , -195)
	CustomAchieverFrame.PointsEditBox:SetSize(20, 16)
	CustomAchieverFrame.PointsEditBox:HighlightText()
	CustomAchieverFrame.PointsEditBox.type = "achievementPoints"

	local descriptionFontstring = CustomAchieverFrame:CreateFontString("DescriptionFontstring", "ARTWORK", "GameFontNormal")
	descriptionFontstring:SetText(DESCRIPTION)
	descriptionFontstring:SetPoint("TOPLEFT", 30, -227)
	CustomAchieverFrame.DescriptionEditBox:SetPoint("TOPRIGHT", -30 , -225)
	CustomAchieverFrame.DescriptionEditBox:SetSize(220, 16)
	CustomAchieverFrame.DescriptionEditBox:HighlightText()
	
	local rewardFontstring = CustomAchieverFrame:CreateFontString("RewardFontstring", "ARTWORK", "GameFontNormal")
	rewardFontstring:SetText(REWARD)
	rewardFontstring:SetPoint("TOPLEFT", 30, -257)
	CustomAchieverFrame.RewardEditBox:SetPoint("TOPRIGHT", -75 , -255)
	CustomAchieverFrame.RewardEditBox:SetSize(175, 16)
	CustomAchieverFrame.RewardEditBox:HighlightText()
	
	CustomAchieverFrame.TitleCheckButton:SetPoint("TOPRIGHT", -50 , -254)
	
	CustomAchieverFrame.AwardButton:SetText(L["MENUCUSTAC_AWARD"])
	
	LibDD:UIDropDownMenu_Initialize(achievementDropDown, CustAc_AchievementDropDownMenu_Update)
	LibDD:UIDropDownMenu_SetSelectedValue(achievementDropDown, nextCustomAchieverId)
	
	CustAc_InitSelectedAchievement(nextCustomAchieverId, nextCustomCategoryId)
	CustomAchieverFrame_UpdateAchievementAlertFrame()
end

function createCustomAchieverOptionsButton(parent)
	local name = "CustomAchieverOptionsButton"
	local iconPath = "Interface\\GossipFrame\\BinderGossipIcon"
	local tooltip = L["MENUOPTIONS_TOOLTIP"]
	local tooltipDetail = L["MENUOPTIONS_TOOLTIPDETAIL"]

	local optionsButton = CreateFrame("Button", name, parent, "CustomAchieverOptionsButtonTemplate")
	optionsButton:SetPoint("TOPRIGHT", -24, -4)
	optionsButton:SetNormalTexture(iconPath)
	optionsButton:SetAttribute("tooltip", tooltip)
	optionsButton:SetAttribute("tooltipDetail", { tooltipDetail })

	return optionsButton
end

function createCustomAchieverLogsButton(parent)
	local name = "CustomAchieverLogsButton"
	local iconPath = "Interface\\GossipFrame\\WorkorderGossipIcon"
	local tooltip = L["LOGS_TOOLTIP"]
	local tooltipDetail = L["LOGS_TOOLTIPDETAIL"]

	local optionsButton = CreateFrame("Button", name, parent, "CustomAchieverLogsButtonTemplate")
	optionsButton:SetPoint("TOPRIGHT", -41, -4)
	optionsButton:SetNormalTexture(iconPath)
	optionsButton:SetAttribute("tooltip", tooltip)
	optionsButton:SetAttribute("tooltipDetail", { tooltipDetail })

	return optionsButton
end

function CustomAchieverFrameRewardRefreshButton_OnClick()
	CustAc_SendUpdatedCategoryData(selectedAchievement.achievementCategory, custacDataTarget)
end

function CustAc_SaveCategory(popup, categoryName, categoryId)
	local newCategoryName = CustAc_titleFormat(categoryName)
	if newCategoryName ~= "" then
		local newCategoryId = categoryId or string.sub(newCategoryName, 1, 1)..'_'..CustAc_getTimeUTCinMS()
		CustAc_CreateOrUpdateCategory(newCategoryId, nil, newCategoryName, nil, true)
		StaticPopupSpecial_Hide(popup)
		CustAc_RefreshCustomAchiementFrame(nextCustomAchieverId, newCategoryId)
		return newCategoryId
	end
	return categoryId
end

function CustAc_RefreshCustomAchiementFrame(achievementId, categoryId, avoidedCategoryId)
	local newCategoryId    = categoryId    or selectedAchievement.achievementCategory
	local newAchievementId = achievementId or selectedAchievement.achievementId
	if avoidedCategoryId and newCategoryId == avoidedCategoryId then
		newCategoryId = nextCustomCategoryId
		newAchievementId = nextCustomAchieverId
	end
	if CustAc_IconsPopupFrame and newAchievementId ~= selectedAchievement.achievementId then
		CustAc_IconsPopupFrame:Hide()
	end
	LibDD:UIDropDownMenu_Initialize(CustomAchieverCategoryDownMenu, CustAc_CategoryDropDownMenu_Update)
	LibDD:UIDropDownMenu_SetSelectedValue(CustomAchieverCategoryDownMenu, newCategoryId)
	LibDD:UIDropDownMenu_Initialize(CustomAchieverAchievementsDownMenu, CustAc_AchievementDropDownMenu_Update)
	LibDD:UIDropDownMenu_SetSelectedValue(CustomAchieverAchievementsDownMenu, newAchievementId)
	CustAc_InitSelectedAchievement(newAchievementId, newCategoryId)
	CustomAchieverFrame_UpdateAchievementAlertFrame()
end

function CustAc_CategoryDropDownMenu_Update(self)
	local function CustAc_CreateCategory()
		CustacCategoryCreateDialog:SetAttribute("categoryId", nil)
		CustacCategoryCreateDialog:SetAttribute("selectedCategoryId", selectedAchievement.achievementCategory)
		CustacCategoryCreateDialog:SetAttribute("selectedCategoryName", selectedAchievement.achievementCategoryName)
		StaticPopupSpecial_Show(CustacCategoryCreateDialog)
	end

	local function CustAc_SelectCategory(button, dropdown, id)
		local gearIcon = button.Icon;
		if button.mouseOverIcon and gearIcon:IsMouseOver() then
			CustacCategoryCreateDialog:SetAttribute("categoryId", id)
			CustacCategoryCreateDialog:SetAttribute("selectedCategoryId", selectedAchievement.achievementCategory)
			CustacCategoryCreateDialog:SetAttribute("selectedCategoryName", selectedAchievement.achievementCategoryName)
			CustacCategoryCreateDialog:SetAttribute("achievementId", selectedAchievement.achievementId ~= nextCustomAchieverId and selectedAchievement.achievementId)
			StaticPopupSpecial_Show(CustacCategoryCreateDialog)
		else
			LibDD:UIDropDownMenu_SetSelectedValue(dropdown, id)
			LibDD:UIDropDownMenu_Initialize(CustomAchieverAchievementsDownMenu, CustAc_AchievementDropDownMenu_Update)
			CustAc_InitSelectedAchievement(nextCustomAchieverId, id)
			LibDD:UIDropDownMenu_SetSelectedValue(CustomAchieverAchievementsDownMenu, nextCustomAchieverId)
			CustomAchieverFrame_UpdateAchievementAlertFrame()
		end
	end
	
	local info = LibDD:UIDropDownMenu_CreateInfo()
	info.text = L["MENUCUSTAC_CATEGORIES"]
	info.isTitle = true
	info.notCheckable = true
	LibDD:UIDropDownMenu_AddButton(info)
	
	local info = LibDD:UIDropDownMenu_CreateInfo()
	info.notCheckable = true
	info.colorCode = GREEN_FONT_COLOR_CODE
	info.text  = " "..CreateAtlasMarkup("communities-icon-addchannelplus", 16, 16).."  "..L["MENUCUSTAC_NEWCATEGORY"]
	info.func  = CustAc_CreateCategory
	LibDD:UIDropDownMenu_AddButton(info)

	if not CustomAchieverData["Categories"][nextCustomCategoryId] then
		local info = LibDD:UIDropDownMenu_CreateInfo()
		info.text  = CustAc_getLocaleData(CustomAchieverData["Categories"][nextCustomCategoryId], "name") or CustAc_delRealm(nextCustomCategoryId)--L["MENUCUSTAC_NEW"]
		info.value = nextCustomCategoryId
		info.func  = CustAc_SelectCategory
		info.arg1  = self
		info.arg2  = nextCustomCategoryId
		LibDD:UIDropDownMenu_AddButton(info)
	end
	
	local categoriesId = {}
	for k,v in pairs(CustomAchieverData["Categories"]) do
		if v["author"] and v["author"] == CustAc_playerCharacter() then
			CustomAchieverData["PersonnalCategories"][k] = true
		end
		if CustomAchieverData["PersonnalCategories"][k] == true then
			categoriesId[ #categoriesId + 1 ] = k
		end
	end
	table.sort(categoriesId)
	
	for _,v in pairs(categoriesId) do
		if (v ~= nextCustomCategoryId or CustomAchieverData["Categories"][nextCustomCategoryId]) and CustomAchieverData["PersonnalCategories"][v] then
			if not CustomAchieverData["Categories"][v]["parent"] or CustomAchieverData["Categories"][v]["parent"] == true then
				local info = LibDD:UIDropDownMenu_CreateInfo()
				info.text  = CustAc_getLocaleData(CustomAchieverData["Categories"][v], "name")
				info.mouseOverIcon = [[Interface\WorldMap\GEAR_64GREY]]
				info.iconXOffset = -5
				info.padding = 5
				info.value = v
				info.func  = CustAc_SelectCategory
				info.arg1  = self
				info.arg2  = v
				LibDD:UIDropDownMenu_AddButton(info)
				for _,v2 in pairs(categoriesId) do
					if CustomAchieverData["Categories"][v2]["parent"] and CustomAchieverData["Categories"][v2]["parent"] == v then
						local info2         = LibDD:UIDropDownMenu_CreateInfo()
						info2.text          = "  "..CustAc_getLocaleData(CustomAchieverData["Categories"][v2], "name")
						info2.mouseOverIcon = [[Interface\WorldMap\GEAR_64GREY]]
						info2.iconXOffset   = -10
						info2.padding       = 10
						info2.leftPadding   = 5
						info2.value         = v2
						info2.func          = CustAc_SelectCategory
						info2.arg1          = self
						info2.arg2          = v2
						LibDD:UIDropDownMenu_AddButton(info2)
					end
				end
			end
		end
	end
end

function CustAc_AchievementDropDownMenu_Update(self)
	local function CustAc_SelectAchievement(button, dropdown, id)
		local deleteIcon = button.Icon;
		if button.mouseOverIcon and deleteIcon:IsMouseOver() then
			local dialog = StaticPopup_Show("CUSTAC_DELETE", CustAc_getLocaleData(CustomAchieverData["Achievements"][id], "name"))
			if (dialog) then
				dialog.data = {}
				dialog.data["achievementId"] = id
			end
		else
			CustAc_InitSelectedAchievement(id, selectedAchievement.achievementCategory)
			LibDD:UIDropDownMenu_SetSelectedValue(dropdown, id)
			CustomAchieverFrame_UpdateAchievementAlertFrame()
		end
	end
	
	local info = LibDD:UIDropDownMenu_CreateInfo()
	info.text = L["MENUCUSTAC_ACHIEVEMENTS"]
	info.isTitle = true
	info.notCheckable = true
	LibDD:UIDropDownMenu_AddButton(info)
	
	local info = LibDD:UIDropDownMenu_CreateInfo()
	info.colorCode = GREEN_FONT_COLOR_CODE
	info.text  = CreateAtlasMarkup("communities-icon-addchannelplus", 16, 16).." "..L["MENUCUSTAC_NEW"]
	info.value = nextCustomAchieverId
	info.func  = CustAc_SelectAchievement
	info.arg1  = self
	info.arg2  = nextCustomAchieverId
	LibDD:UIDropDownMenu_AddButton(info)

	for k,v in pairs(CustomAchieverData["Achievements"]) do
		if v["parent"] == LibDD:UIDropDownMenu_GetSelectedValue(CustomAchieverCategoryDownMenu) then
			local info         = LibDD:UIDropDownMenu_CreateInfo()
			info.text          = CustAc_getLocaleData(v, "name")
			info.mouseOverIcon = [[Interface\AddOns\]]..(CustAcAddon or "CustomAchiever").."\\art\\delete"
			info.iconXOffset   = -5
			info.padding       = 5
			info.value         = k
			info.func          = CustAc_SelectAchievement
			info.arg1          = self
			info.arg2          = k
			LibDD:UIDropDownMenu_AddButton(info)
		end
	end
end

function CustomAchieverFrame_UpdateAchievementAlertFrame()
	if selectedAchievement.achievementId then
		CustomAchieverFrame.AchievementAlertFrame.Icon.Texture:SetTexture(selectedAchievement.achievementIcon)
		CustomAchieverFrame.AchievementAlertFrame.Name:SetText(selectedAchievement.achievementName)
		CustomAchieverFrame.AchievementAlertFrame.Shield.Points:SetText(selectedAchievement.achievementPoints)
		CustomAchieverFrame.IconEditBox:SetText(selectedAchievement.achievementIcon)
		--CustomAchieverFrame.IconEditBox:HighlightText()
		CustomAchieverFrame.PointsEditBox:SetText(selectedAchievement.achievementPoints)
		--CustomAchieverFrame.PointsEditBox:HighlightText()
		CustomAchieverFrame.DescriptionEditBox:SetText(selectedAchievement.achievementDesc)
		--CustomAchieverFrame.DescriptionEditBox:HighlightText()
		CustomAchieverFrame.RewardEditBox:SetText(selectedAchievement.achievementRewardText)
		CustomAchieverFrame.TitleCheckButton:SetChecked(selectedAchievement.achievementRewardIsTitle)
		
		if selectedAchievement.achievementId == nextCustomAchieverId then
			CustomAchieverFrame.DeleteButton:Disable()
		else
			CustomAchieverFrame.DeleteButton:Enable()
		end
		
		if selectedAchievement.achievementId == nextCustomAchieverId then
			CustomAchieverFrame.AwardButton:Disable()
		else
			CustomAchieverFrame.AwardButton:Enable()
			custacShowHelpTip("CUSTAC_HELPTIP_AWARD")
		end
	end
	Custac_ChangeAwardButtonText()
end

function CustomAchieverFrame_UpdateTargetTooltip()
	CustomAchieverTargetTooltip:SetOwner(CustomAchieverFrame, "ANCHOR_BOTTOM", 0, 0)
	CustomAchieverTargetTooltip:ClearLines()
	CustomAchieverTargetTooltip:AddDoubleLine(STATUS_TEXT_TARGET, custacDataTarget or UNKNOWN, 1.0, 0.82, 0.0, 1.0, 1.0, 1.0)
	if CustomAchieverData["Users"][custacDataTarget] then
		CustomAchieverTargetTooltip:AddDoubleLine("CustomAchiever", CustomAchieverData["Users"][custacDataTarget], 0, 1, 0, 0, 1, 0)
	end
	CustomAchieverTargetTooltip:Show()
end

function CustomAchieverFrameDescriptionEditBox_OnTextChanged(self)
	selectedAchievement.achievementDesc = CustAc_titleFormat(self:GetText())
end

function CustomAchieverFrameRewardEditBox_OnTextChanged(self)
	selectedAchievement.achievementRewardText = CustAc_titleFormat(self:GetText())
end

function CustomAchieverFrameRewardCheckButton_OnClick(self)
	selectedAchievement.achievementRewardIsTitle = self:GetChecked()
end

function CustomAchieverFrameEditBox_OnTextChanged(self)
	if self.type then
		selectedAchievement[self.type] = self:GetText()
	end
	CustomAchieverFrame_UpdateAchievementAlertFrame()
end

function CustAc_IconsPopupFrame_OkayButton_OnClick()
	CustAc_IconsPopupFrame:Hide()
	
	selectedAchievement.achievementIcon = CustAc_IconsPopupFrame.BorderBox.SelectedIconArea.SelectedIconButton:GetIconTexture()
	selectedAchievement.achievementName = CustAc_titleFormat(CustAc_IconsPopupFrame.BorderBox.IconSelectorEditBox:GetText())

	CustomAchieverFrame_UpdateAchievementAlertFrame()
end


function CustAc_AwardButton_OnClick(self)
	if custacDataTarget then
		local data = {}
		data["Categories"]   = {}
		data["Achievements"] = {}
		local categoryId = CustomAchieverData["Achievements"][selectedAchievement.achievementId]["parent"]
		if categoryId then
			data["Categories"][categoryId] = CustomAchieverData["Categories"][categoryId]
			if CustomAchieverData["Categories"][categoryId] and CustomAchieverData["Categories"][categoryId]["parent"] and CustomAchieverData["Categories"][categoryId]["parent"] ~= true then
				data["Categories"][CustomAchieverData["Categories"][categoryId]["parent"]] = CustomAchieverData["Categories"][CustomAchieverData["Categories"][categoryId]["parent"]]
			end
		end
		data["Achievements"][selectedAchievement.achievementId] = CustomAchieverData["Achievements"][selectedAchievement.achievementId]
		if CustAc_IsAchievementCompletedBy(selectedAchievement.achievementId, custacDataTarget, CustAc_isPlayerCharacter(custacDataTarget)) then
			manualEncodeAndSendAchievementInfo(data, custacDataTarget, "Revoke")
		else
			manualEncodeAndSendAchievementInfo(data, custacDataTarget, "Award")
		end
	end
end

function CustAc_DeleteCategoryButton_OnClick(categoryId, categoryName)
	local newCategory = CustAc_DetermineNewCategory(categoryId, selectedAchievement.achievementCategory, nextCustomCategoryId)
	local newCategoryName = CustAc_getLocaleData(CustomAchieverData["Categories"][newCategory], "name") or (newCategory == "GENERAL" and GENERAL) or newCategory
	local dialog = StaticPopup_Show("CUSTAC_CAT_DELETE", categoryName, newCategoryName)
	if (dialog) then
		dialog.data = {}
		dialog.data["categoryId"] = categoryId
		dialog.data["newCategory"] = newCategory
	end
end

function CustAc_DeleteButton_OnClick(self)
	if selectedAchievement.achievementId == nextCustomAchieverId then
		self:Disable()
	else
		local dialog = StaticPopup_Show("CUSTAC_DELETE", selectedAchievement.achievementName)
		if (dialog) then
			dialog.data = {}
			dialog.data["achievementId"] = selectedAchievement.achievementId
		end
	end
end

function CustAc_SaveButton_OnClick()
	if selectedAchievement.achievementId then
		CustAc_CreateOrUpdateCategory(selectedAchievement.achievementCategory, nil, selectedAchievement.achievementCategoryName, nil, true)
		CustAc_CreateOrUpdateAchievement(selectedAchievement.achievementId, selectedAchievement.achievementCategory, selectedAchievement.achievementIcon, selectedAchievement.achievementPoints, selectedAchievement.achievementName, selectedAchievement.achievementDesc, selectedAchievement.achievementRewardText, selectedAchievement.achievementRewardIsTitle, nil, true)
		if selectedAchievement.achievementId == nextCustomAchieverId then
			nextCustomAchieverId = CustAc_playerCharacter()..'-'..CustAc_getTimeUTCinMS()
		end
		
		local categoryName = CustAc_getLocaleData(CustomAchieverData["Categories"][selectedAchievement.achievementCategory], "name")
		
		CustAc_CompleteAchievement("CustomAchiever2")
		EZBlizzUiPop_ToastFakeAchievementNew(CustomAchiever, selectedAchievement.achievementName, 5208, true, 4, categoryName, function() CustAc_ShowAchievement(selectedAchievement.achievementId) end, selectedAchievement.achievementIcon)
		
		LibDD:UIDropDownMenu_Initialize(CustomAchieverAchievementsDownMenu, CustAc_AchievementDropDownMenu_Update)
		LibDD:UIDropDownMenu_SetSelectedValue(CustomAchieverAchievementsDownMenu, selectedAchievement.achievementId)
		
		CustomAchieverFrame_UpdateAchievementAlertFrame()
		
		CustAc_SendUpdatedAchievementData(selectedAchievement.achievementId, custacDataTarget)
	end
end

function CustAc_IconsPopupFrame_OnHide(self)
	IconSelectorPopupFrameTemplateMixin.OnHide(self)
	
	LibDD:UIDropDownMenu_EnableDropDown(CustomAchieverCategoryDownMenu)
	LibDD:UIDropDownMenu_EnableDropDown(CustomAchieverAchievementsDownMenu)
	CustomAchieverFrame.IconEditBox:Enable()
	CustomAchieverFrame.PointsEditBox:Enable()
	CustomAchieverFrame.DescriptionEditBox:Enable()
	if selectedAchievement.achievementId ~= nextCustomAchieverId then
		CustomAchieverFrame.AwardButton:Enable()
		custacShowHelpTip("CUSTAC_HELPTIP_AWARD")
	end
	CustomAchieverFrame.DeleteButton:Enable()
	CustomAchieverFrame.SaveButton:Enable()
end

function CustAc_IconsPopupFrame_OnShow(self)
	IconSelectorPopupFrameTemplateMixin.OnShow(self)
	
	LibDD:UIDropDownMenu_DisableDropDown(CustomAchieverCategoryDownMenu)
	LibDD:UIDropDownMenu_DisableDropDown(CustomAchieverAchievementsDownMenu)
	CustomAchieverFrame.IconEditBox:Disable()
	CustomAchieverFrame.PointsEditBox:Disable()
	CustomAchieverFrame.DescriptionEditBox:Disable()
	CustomAchieverFrame.DeleteButton:Disable()
	CustomAchieverFrame.AwardButton:Disable()
	CustomAchieverFrame.SaveButton:Disable()

	self.BorderBox.IconSelectorEditBox:SetFocus()

	PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN)
	self.iconDataProvider = CustAc_IconsPopupFrame_RefreshIconDataProvider(self)
	CustAc_IconsPopupFrame_Init(self)
	self:Update()
	self.BorderBox.IconSelectorEditBox:OnTextChanged()

	local function OnIconSelected(selectionIndex, icon)
		self.BorderBox.SelectedIconArea.SelectedIconButton:SetIconTexture(icon)

		-- Index is not yet set, but we know if an icon in IconSelector was selected it was in the list, so set directly.
		self.BorderBox.SelectedIconArea.SelectedIconButton.SelectedTexture:SetShown(false)
		self.BorderBox.SelectedIconArea.SelectedIconText.SelectedIconHeader:SetText(ICON_SELECTION_TITLE_CURRENT)
		self.BorderBox.SelectedIconArea.SelectedIconText.SelectedIconDescription:SetText(ICON_SELECTION_CLICK)
	end
    self.IconSelector:SetSelectedCallback(OnIconSelected)
end

function CustAc_IconsPopupFrame_Init(self)
	local name = (selectedAchievement.achievementName ~= L["MENUCUSTAC_DEFAULT_NAME"] and selectedAchievement.achievementName) or "" 
	self.BorderBox.IconSelectorEditBox:SetText(name)
	self.BorderBox.IconSelectorEditBox:HighlightText()

	local texture = tonumber(selectedAchievement.achievementIcon)
	self.IconSelector:SetSelectedIndex(self:GetIndexOfIcon(texture))
	self.BorderBox.SelectedIconArea.SelectedIconButton:SetIconTexture(texture);
	self.IconSelector:ScrollToSelectedIndex()
	self.BorderBox.SelectedIconArea.SelectedIconButton:SetIconTexture(texture)
end

function CustAc_IconsPopupFrame_RefreshIconDataProvider(self)
	if self.iconDataProvider == nil then
		self.iconDataProvider = CreateAndInitFromMixin(IconDataProviderMixin, IconDataProviderExtraType.None);
	end

	return self.iconDataProvider;
end

function CustomAchieverButtonEnter(self, motion, position)
	local tooltip = self:GetAttribute("tooltip")
	local tooltipDetail = self:GetAttribute("tooltipDetail")
	local tooltipDetailGreen = self:GetAttribute("tooltipDetailGreen")
	local tooltipDetailRed = self:GetAttribute("tooltipDetailRed")
	CustomAchieverTooltip:SetOwner(self, "ANCHOR_"..(position or "TOPRIGHT"))
	if tooltip then
		CustomAchieverTooltip:SetText(tooltip)
		if tooltipDetail then
			for index,value in pairs(tooltipDetail) do
				CustomAchieverTooltip:AddLine(value, 1.0, 1.0, 1.0)
			end
		end
		if tooltipDetailGreen then
			for index,value in pairs(tooltipDetailGreen) do
				CustomAchieverTooltip:AddLine(value, 0.0, 1.0, 0.0)
			end
		end
		if tooltipDetailRed then
			for index,value in pairs(tooltipDetailRed) do
				CustomAchieverTooltip:AddLine(value, 1.0, 0.0, 0.0)
			end
		end
		CustomAchieverTooltip:Show()
	end
end

function CustomAchieverButtonLeave(self)
	CustomAchieverTooltip:Hide()
end

function CustacCategoryCreateDialog_OnShow(self)
	LibDD:UIDropDownMenu_DisableDropDown(CustomAchieverCategoryDownMenu)
	LibDD:UIDropDownMenu_DisableDropDown(CustomAchieverAchievementsDownMenu)
	
	local categoryId = self:GetAttribute("categoryId")
	if categoryId then
		self.NameControl.EditBox:SetText(CustAc_getLocaleData(CustomAchieverData["Categories"][categoryId], "name"))
		if categoryId == "GENERAL" then
			self.NameControl.EditBox:Disable()
		else
			self.NameControl.EditBox:Enable()
		end
		self.DeleteButton:Enable()
	else
		self.NameControl.EditBox:SetText("")
		self.DeleteButton:Disable()
		self.NameControl.EditBox:Enable()
	end
	
	self.NameControl.MoveCategory.CheckButton:SetChecked(false)
	self.NameControl.ExtractCategory.CheckButton:SetChecked(false)
	local selectedCategoryId = self:GetAttribute("selectedCategoryId")
	if selectedCategoryId and
		selectedCategoryId ~= "GENERAL" and
		(not CustomAchieverData["Categories"][selectedCategoryId] or not CustomAchieverData["Categories"][selectedCategoryId]["parent"] or CustomAchieverData["Categories"][selectedCategoryId]["parent"] ~= true) and
			(
				not categoryId or (
					selectedCategoryId ~= categoryId and
					(
						(not CustomAchieverData["Categories"][categoryId]["parent"] or CustomAchieverData["Categories"][categoryId]["parent"] == true) and
						(not CustomAchieverData["Categories"][selectedCategoryId] or CustomAchieverData["Categories"][selectedCategoryId]["parent"] ~= categoryId)
					)
				)
			)
			then
		self.NameControl.MoveCategory.CheckButton:Show()
		self.NameControl.MoveCategory.Label:Show()
		self.NameControl.ExtractCategory.CheckButton:Hide()
		self.NameControl.ExtractCategory.Label:Hide()
	else
		if categoryId and CustomAchieverData["Categories"][categoryId]["parent"] and CustomAchieverData["Categories"][categoryId]["parent"] ~= true then
			self.NameControl.ExtractCategory.CheckButton:Show()
			self.NameControl.ExtractCategory.Label:Show()
		else
			self.NameControl.ExtractCategory.CheckButton:Hide()
			self.NameControl.ExtractCategory.Label:Hide()
		end
		self.NameControl.MoveCategory.CheckButton:Hide()
		self.NameControl.MoveCategory.Label:Hide()
	end

	self.NameControl.MoveAchievement.CheckButton:SetChecked(false)
	local achievementId = self:GetAttribute("achievementId")
	if achievementId and (not categoryId or CustomAchieverData["Achievements"][achievementId]["parent"] ~= categoryId) then
		self.NameControl.MoveAchievement.CheckButton:Show()
		self.NameControl.MoveAchievement.Label:Show()
	else
		self.NameControl.MoveAchievement.CheckButton:Hide()
		self.NameControl.MoveAchievement.Label:Hide()
	end
end

function CustacCategoryCreateDialog_OnHide(self)
	LibDD:UIDropDownMenu_EnableDropDown(CustomAchieverCategoryDownMenu)
	LibDD:UIDropDownMenu_EnableDropDown(CustomAchieverAchievementsDownMenu)
end

function CustAc_MoveAchievement_OnLoad(self)
	self.Label:SetText(L["MENUCUSTAC_MOVE_ACHIEVEMENT"])
end

function CustAc_MoveCategory_OnLoad(self)
	self.Label:SetText(L["MENUCUSTAC_MOVE_CATEGORY"])
end

function CustAc_ExtractCategory_OnLoad(self)
	self.Label:SetText(L["MENUCUSTAC_EXTRACT_CATEGORY"])
end

function CustacCategoryCreateDialogAcceptButton_OnClick(self)
	local categoryId = self:GetParent():GetAttribute("categoryId")
	categoryId = CustAc_SaveCategory(self:GetParent(), self:GetParent().NameControl.EditBox:GetText(), categoryId)
	if self:GetParent().NameControl.MoveAchievement.CheckButton:GetChecked() then
		local achievementId = self:GetParent():GetAttribute("achievementId")
		CustAc_CreateOrUpdateAchievement(achievementId, categoryId)
	end
	if self:GetParent().NameControl.MoveCategory.CheckButton:GetChecked() then
		local selectedCategoryId = self:GetParent():GetAttribute("selectedCategoryId")
		local selectedCategoryName = self:GetParent():GetAttribute("selectedCategoryName")
		CustAc_CreateOrUpdateCategory(selectedCategoryId, categoryId, selectedCategoryName, nil, true)
	end
	if self:GetParent().NameControl.ExtractCategory.CheckButton:GetChecked() then
		CustAc_CreateOrUpdateCategory(categoryId, "", nil, nil, true)
	end
	CustAc_SendUpdatedCategoryData(categoryId, custacDataTarget)
end

function CustomAchieverLogsButton_OnClick()
	if CustomAchieverFrame then
		if CustomAchieverFrame.DetailsPanel:IsShown() then
			CustomAchieverFrame.DetailsPanel:Hide()
		else
			CustomAchieverFrame.DetailsPanel:Show()
		end
	end
end
