local L = LibStub("AceLocale-3.0"):GetLocale("CustomAchiever", true)
local LibDD = LibStub:GetLibrary("LibUIDropDownMenu-4.0")

local nextCustomCategoryId
local nextCustomAchieverId

local selectedAchievement = {}

local function CustAc_InitSelectedAchievement(achievementId, categoryId)
	selectedAchievement = {}
	selectedAchievement.achievementId           =  achievementId or nextCustomAchieverId
	selectedAchievement.achievementCategory     =  categoryId    or (CustomAchieverData["Achievements"][achievementId] and CustomAchieverData["Achievements"][achievementId].parent) or nextCustomCategoryId
	selectedAchievement.achievementCategoryName =  CustAc_getLocaleData(CustomAchieverData["Categories"][selectedAchievement.achievementCategory], "name") or CustAc_delRealm(selectedAchievement.achievementCategory)
	selectedAchievement.achievementName         =  CustAc_getLocaleData(CustomAchieverData["Achievements"][achievementId], "name")                                 or L["MENUCUSTAC_DEFAULT_NAME"]
	selectedAchievement.achievementIcon         = (CustomAchieverData["Achievements"][achievementId] and CustomAchieverData["Achievements"][achievementId].icon)   or 236376
	selectedAchievement.achievementDesc         =  CustAc_getLocaleData(CustomAchieverData["Achievements"][achievementId], "desc")                                 or L["MENUCUSTAC_DESCRIPTION"]
	selectedAchievement.achievementPoints       = (CustomAchieverData["Achievements"][achievementId] and CustomAchieverData["Achievements"][achievementId].points) or 0
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

function Custac_ChangeAwardButtonText()
	if CustomAchieverFrame:IsShown() then
		local name, realm = UnitFullName("target")
		local target = CustAc_addRealm(name, realm)
		
		if UnitIsPlayer("target") then
			if CustAc_IsAchievementCompletedBy(selectedAchievement.achievementId, target, CustAc_isPlayerCharacter(target)) then
				CustomAchieverFrame.AwardButton:SetText(L["MENUCUSTAC_REVOKE"])
			else
				CustomAchieverFrame.AwardButton:SetText(L["MENUCUSTAC_AWARD"])
			end
		else
			CustomAchieverFrame.AwardButton:SetText(L["MENUCUSTAC_AWARD"])
		end
	end
end

function CustomAchieverFrame_OnEvent(self, event)
	if event == "PLAYER_TARGET_CHANGED" then
		Custac_ChangeAwardButtonText()
	end
end

function CustomAchieverFrame_OnLoad(self)
	self:RegisterForDrag("LeftButton")
	self.CloseButton:SetHitRectInsets(6, 6, 6, 6)
	self.AchievementAlertFrame.Icon.Texture:SetTexCoord(0, 0, 0, 1, 1, 0, 1, 1)	

	applyCustomAchieverWindowOptions()
	
	self:SetTitle(GetAddOnMetadata("CustomAchiever", "Title"))
	SetPortraitToTexture(self.PortraitContainer.portrait, "Interface\\Friendsframe\\friendsframescrollicon")
	
	local custacOptionsButton = createCustomAchieverOptionsButton(self)
	
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

	nextCustomAchieverId = CustAc_playerCharacter()..'-'..tostring(CustAc_getTimeUTCinMS())
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
	descriptionFontstring:SetText(L["MENUCUSTAC_DESCRIPTION"])
	descriptionFontstring:SetPoint("TOPLEFT", 30, -227)
	CustomAchieverFrame.DescriptionEditBox:SetPoint("TOPRIGHT", -30 , -225)
	CustomAchieverFrame.DescriptionEditBox:SetSize(220, 16)
	CustomAchieverFrame.DescriptionEditBox:HighlightText()
	
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

function CustAc_SaveCategory(popup, categoryName, categoryId)
	local newCategoryName = CustAc_titleFormat(categoryName)
	if newCategoryName ~= "" then
		local newCategoryId = categoryId or string.sub(newCategoryName, 1, 1)..'_'..tostring(CustAc_getTimeUTCinMS())
		CustAc_CreateOrUpdateCategory(newCategoryId, nil, newCategoryName, nil, true)
		StaticPopupSpecial_Hide(popup)
		LibDD:UIDropDownMenu_Initialize(CustomAchieverCategoryDownMenu, CustAc_CategoryDropDownMenu_Update)
		LibDD:UIDropDownMenu_SetSelectedValue(CustomAchieverCategoryDownMenu, newCategoryId)
		LibDD:UIDropDownMenu_Initialize(CustomAchieverAchievementsDownMenu, CustAc_AchievementDropDownMenu_Update)
		LibDD:UIDropDownMenu_SetSelectedValue(CustomAchieverAchievementsDownMenu, nextCustomAchieverId)
		CustAc_InitSelectedAchievement(nextCustomAchieverId, newCategoryId)
		CustomAchieverFrame_UpdateAchievementAlertFrame()
	end
end

function CustAc_CategoryDropDownMenu_Update(self)
	local function CustAc_CreateCategory(_, dropdown, selectFunc)
		CustacCategoryCreateDialog:SetAttribute("categoryId", nil);
		StaticPopupSpecial_Show(CustacCategoryCreateDialog)
	end

	local function CustAc_SelectCategory(button, dropdown, id)
		local gearIcon = button.Icon;
		if button.mouseOverIcon and gearIcon:IsMouseOver() then
			CustacCategoryCreateDialog:SetAttribute("categoryId", id);
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
	info.arg1  = self
	info.arg2  = CustAc_SelectCategory
	LibDD:UIDropDownMenu_AddButton(info)

	local info = LibDD:UIDropDownMenu_CreateInfo()
	info.text  = CustAc_getLocaleData(CustomAchieverData["Categories"][nextCustomCategoryId], "name") or CustAc_delRealm(nextCustomCategoryId)--L["MENUCUSTAC_NEW"]
	if CustomAchieverData["Categories"][nextCustomCategoryId] then
		info.mouseOverIcon = [[Interface\WorldMap\GEAR_64GREY]]
		info.iconXOffset = -5
		info.padding = 5
	end
	info.value = nextCustomCategoryId
	info.func  = CustAc_SelectCategory
	info.arg1  = self
	info.arg2  = nextCustomCategoryId
	LibDD:UIDropDownMenu_AddButton(info)
	
	for k,v in pairs(CustomAchieverData["Categories"]) do
		if k ~= nextCustomCategoryId and CustomAchieverData["PersonnalCategories"][k] then
			local info = LibDD:UIDropDownMenu_CreateInfo()
			info       = LibDD:UIDropDownMenu_CreateInfo()
			info.text  = CustAc_getLocaleData(v, "name")
			info.mouseOverIcon = [[Interface\WorldMap\GEAR_64GREY]]
			info.iconXOffset = -5
			info.padding = 5
			info.value = k
			info.func  = CustAc_SelectCategory
			info.arg1  = self
			info.arg2  = k
			LibDD:UIDropDownMenu_AddButton(info)
		end
	end
end

function CustAc_AchievementDropDownMenu_Update(self)
	local function CustAc_SelectAchievement(_, dropdown, id)
		CustAc_InitSelectedAchievement(id, selectedAchievement.achievementCategory)
		LibDD:UIDropDownMenu_SetSelectedValue(dropdown, id)
		CustomAchieverFrame_UpdateAchievementAlertFrame()
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
			local info = LibDD:UIDropDownMenu_CreateInfo()
			info       = LibDD:UIDropDownMenu_CreateInfo()
			info.text  = CustAc_getLocaleData(v, "name")
			info.value = k
			info.func  = CustAc_SelectAchievement
			info.arg1  = self
			info.arg2  = k
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

function CustomAchieverFrameDescriptionEditBox_OnTextChanged(self)
	selectedAchievement.achievementDesc = CustAc_titleFormat(self:GetText())
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
	local name, realm = UnitFullName("target")
	local target = CustAc_addRealm(name, realm)
	
	if not target then
		target = CustAc_playerCharacter()
	end
	
	if not name or UnitIsPlayer("target") then
		local data = {}
		data["Category"] 	= CustomAchieverData["Categories"][CustomAchieverData["Achievements"][selectedAchievement.achievementId]["parent"]]
		data["Achievement"] = CustomAchieverData["Achievements"][selectedAchievement.achievementId]	
		if CustAc_IsAchievementCompletedBy(selectedAchievement.achievementId, target, CustAc_isPlayerCharacter(target)) then
			manualEncodeAndSendAchievementInfo(data, target, "Revoke")
		else
			manualEncodeAndSendAchievementInfo(data, target, "Award")
		end
	end
end

function CustAc_DeleteCategoryButton_OnClick(categoryId, categoryName)
	local newCategory = CustAc_DetermineNewCategory(categoryId, selectedAchievement.achievementCategory, nextCustomCategoryId)
	local newCategoryName = CustAc_getLocaleData(CustomAchieverData["Categories"][newCategory], "name") or newCategory
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
		CustAc_CreateOrUpdateCategory(selectedAchievement.achievementCategory, nil, selectedAchievement.achievementCategoryName, nil, isPersonnal)
		CustAc_CreateOrUpdateAchievement(selectedAchievement.achievementId, selectedAchievement.achievementCategory, selectedAchievement.achievementIcon, selectedAchievement.achievementPoints, selectedAchievement.achievementName, selectedAchievement.achievementDesc, nil, true)
		if selectedAchievement.achievementId == nextCustomAchieverId then
			nextCustomAchieverId = CustAc_playerCharacter()..'-'..tostring(CustAc_getTimeUTCinMS())
		end
		
		local categoryName = CustAc_getLocaleData(CustomAchieverData["Categories"][selectedAchievement.achievementCategory], "name")
		
		CustAc_CompleteAchievement("CustomAchiever2")
		EZBlizzUiPop_ToastFakeAchievementNew(CustomAchiever, selectedAchievement.achievementName, 5208, true, 4, categoryName, function() CustAc_ShowAchievement(selectedAchievement.achievementId) end, selectedAchievement.achievementIcon)
		
		LibDD:UIDropDownMenu_Initialize(CustomAchieverAchievementsDownMenu, CustAc_AchievementDropDownMenu_Update)
		LibDD:UIDropDownMenu_SetSelectedValue(CustomAchieverAchievementsDownMenu, selectedAchievement.achievementId)
		
		CustomAchieverFrame_UpdateAchievementAlertFrame()
		
		local name, realm = UnitFullName("target")
		local target = CustAc_addRealm(name, realm)
		if CustAc_isPlayerCharacter(target) then
			target = nil
		end
		CustAc_SendUpdatedData(selectedAchievement.achievementId, target)
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

function CustomAchieverButtonEnter(self)
	local tooltip = self:GetAttribute("tooltip")
	local tooltipDetail = self:GetAttribute("tooltipDetail")
	local tooltipDetailGreen = self:GetAttribute("tooltipDetailGreen")
	local tooltipDetailRed = self:GetAttribute("tooltipDetailRed")
	CustomAchieverTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
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
