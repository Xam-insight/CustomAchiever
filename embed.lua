local L = LibStub("AceLocale-3.0"):GetLocale("CustomAchiever", true)
local LibDD = LibStub:GetLibrary("LibUIDropDownMenu-4.0")

local nextCustomCategoryId
local nextCustomAchieverId

local selectedAchievement = {}

local function CustAc_InitSelectedAchievement(achievementId, categoryId)
	selectedAchievement = {}
	selectedAchievement.achievementId       =  achievementId or nextCustomAchieverId
	selectedAchievement.achievementCategory =  categoryId or (CustomAchieverData["Achievements"][achievementId] and CustomAchieverData["Achievements"][achievementId].parent) or nextCustomCategoryId
	selectedAchievement.achievementName     =  CustAc_getLocaleData(CustomAchieverData["Achievements"][achievementId], "name")                                 or L["MENUCUSTAC_DEFAULT_NAME"]
	selectedAchievement.achievementIcon     = (CustomAchieverData["Achievements"][achievementId] and CustomAchieverData["Achievements"][achievementId].icon)   or 236376
	selectedAchievement.achievementDesc     =  CustAc_getLocaleData(CustomAchieverData["Achievements"][achievementId], "desc")                                 or L["MENUCUSTAC_DESCRIPTION"]
	selectedAchievement.achievementPoints   = (CustomAchieverData["Achievements"][achievementId] and CustomAchieverData["Achievements"][achievementId].points) or 0
end

function CustomAchieverFrameTemplate_OnLoad(self)
	self:RegisterForDrag("LeftButton")
	self.CloseButton:SetHitRectInsets(6, 6, 6, 6)
	self.AchievementAlertFrame.Icon.Texture:SetTexCoord(0, 0, 0, 1, 1, 0, 1, 1)	

	applyCustomAchieverWindowOptions()
	
	local fontstring = CustomAchieverFrame:CreateFontString("CustomAchieverLabel", "ARTWORK", "GameFontNormal")
	fontstring:SetText(GetAddOnMetadata("CustomAchiever", "Title"))
	fontstring:SetPoint("TOP", 0, -5)

	CustomAchieverFrameAchievementAlertFrame.GuildBanner:Hide()
	CustomAchieverFrameAchievementAlertFrame.OldAchievement:Hide()
	CustomAchieverFrameAchievementAlertFrame.GuildBorder:Hide()
	CustomAchieverFrameAchievementAlertFrame.Icon.Bling:Hide()
	
	nextCustomCategoryId = CustAc_playerCharacter()
	local categoryFontstring = CustomAchieverFrame:CreateFontString("CategoryFontstring", "ARTWORK", "GameFontNormal")
	categoryFontstring:SetText(L["MENUCUSTAC_CATEGORY"])
	categoryFontstring:SetPoint("TOPLEFT", 30, -39)
	local categoryDropDown = LibDD:Create_UIDropDownMenu("CustomAchieverCategoryDownMenu", self, "MENU")
	categoryDropDown:SetPoint("TOPRIGHT", -30 , -30)
	LibDD:UIDropDownMenu_SetWidth(categoryDropDown, 150)

	LibDD:UIDropDownMenu_Initialize(categoryDropDown, CustAc_CategoryDropDownMenu_Update)
	LibDD:UIDropDownMenu_SetSelectedValue(categoryDropDown, nextCustomCategoryId)

	nextCustomAchieverId = CustAc_playerCharacter()..'-'..tostring(CustAc_getTimeUTCinMS())
	local achievementFontstring = CustomAchieverFrame:CreateFontString("AchievementFontstring", "ARTWORK", "GameFontNormal")
	achievementFontstring:SetText(L["MENUCUSTAC_ACHIEVEMENT"])
	achievementFontstring:SetPoint("TOPLEFT", 30, -69)
	local achievementDropDown = LibDD:Create_UIDropDownMenu("CustomAchieverAchievementsDownMenu", self, "MENU")
	achievementDropDown:SetPoint("TOPRIGHT", -30 , -60)
	LibDD:UIDropDownMenu_SetWidth(achievementDropDown, 200)

	CustomAchieverFrame.DescriptionEditBox:SetText(L["MENUCUSTAC_DESCRIPTION"])
	CustomAchieverFrame.DescriptionEditBox:HighlightText()

	LibDD:UIDropDownMenu_Initialize(achievementDropDown, CustAc_AchievementDropDownMenu_Update)
	LibDD:UIDropDownMenu_SetSelectedValue(achievementDropDown, nextCustomAchieverId)
	
	CustAc_InitSelectedAchievement(nextCustomAchieverId, nextCustomCategoryId)
	CustomAchieverFrame_UpdateAchievementAlertFrame()
end

function CustAc_CategoryDropDownMenu_Update(self)
	local function CustAc_SelectCategory(_, dropdown, id)
		LibDD:UIDropDownMenu_SetSelectedValue(dropdown, id)
		LibDD:UIDropDownMenu_Initialize(CustomAchieverAchievementsDownMenu, CustAc_AchievementDropDownMenu_Update)
		CustAc_InitSelectedAchievement(nextCustomAchieverId)
		LibDD:UIDropDownMenu_SetSelectedValue(CustomAchieverAchievementsDownMenu, nextCustomAchieverId)
		CustomAchieverFrame_UpdateAchievementAlertFrame()
	end
	
	local info = LibDD:UIDropDownMenu_CreateInfo()
	info.text = L["MENUCUSTAC_CATEGORIES"]
	info.isTitle = true
	info.notCheckable = true
	LibDD:UIDropDownMenu_AddButton(info)
	
	local info = LibDD:UIDropDownMenu_CreateInfo()
	info.text  = CustAc_delRealm(nextCustomCategoryId)--L["MENUCUSTAC_NEW"]
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
		CustAc_InitSelectedAchievement(id)
		LibDD:UIDropDownMenu_SetSelectedValue(dropdown, id)
		CustomAchieverFrame_UpdateAchievementAlertFrame()
	end
	
	local info = LibDD:UIDropDownMenu_CreateInfo()
	info.text = L["MENUCUSTAC_ACHIEVEMENTS"]
	info.isTitle = true
	info.notCheckable = true
	LibDD:UIDropDownMenu_AddButton(info)
	
	local info = LibDD:UIDropDownMenu_CreateInfo()
	info.text  = CreateAtlasMarkup("UI-HUD-MicroMenu-Achievements-Up", 16, 22, 0, -3).." |cFF00FF00"..L["MENUCUSTAC_NEW"].."|r"
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
		CustomAchieverFrame.DescriptionEditBox:SetText(selectedAchievement.achievementDesc)
		CustomAchieverFrame.DescriptionEditBox:HighlightText()
	end
end

function CustomAchieverFrameDescriptionEditBox_OnTextChanged(self)
	selectedAchievement.achievementDesc = CustAc_titleFormat(self:GetText())
end

function CustAc_IconsPopupFrame_OkayButton_OnClick()
	CustAc_IconsPopupFrame:Hide()
	
	selectedAchievement.achievementIcon = CustAc_IconsPopupFrame.BorderBox.SelectedIconArea.SelectedIconButton:GetIconTexture()
	selectedAchievement.achievementName = CustAc_titleFormat(CustAc_IconsPopupFrame.BorderBox.IconSelectorEditBox:GetText())

	CustomAchieverFrame_UpdateAchievementAlertFrame()
end

function CustAc_SaveButton_OnClick()
	if selectedAchievement.achievementId then
		print(selectedAchievement.achievementCategory)
		CustAc_CreateOrUpdateAchievement(selectedAchievement.achievementId, selectedAchievement.achievementCategory, selectedAchievement.achievementIcon, 0, selectedAchievement.achievementName, selectedAchievement.achievementDesc, nil, true)
		if selectedAchievement.achievementId == nextCustomAchieverId then
			nextCustomAchieverId = CustAc_playerCharacter()..'-'..tostring(CustAc_getTimeUTCinMS())
		end
		
		local categoryName = CustAc_getLocaleData(CustomAchieverData["Categories"][selectedAchievement.achievementCategory], "name")
		
		CustAc_CompleteAchievement("CustomAchiever2")
		EZBlizzUiPop_ToastFakeAchievementNew(CustomAchiever, selectedAchievement.achievementName, 5208, true, 4, categoryName, function() CustAc_ShowAchievement(selectedAchievement.achievementId) end, selectedAchievement.achievementIcon)
		
		LibDD:UIDropDownMenu_Initialize(CustomAchieverAchievementsDownMenu, CustAc_AchievementDropDownMenu_Update)
		LibDD:UIDropDownMenu_SetSelectedValue(CustomAchieverAchievementsDownMenu, selectedAchievement.achievementId)
	end
end

function CustAc_IconsPopupFrame_OnHide(self)
	IconSelectorPopupFrameTemplateMixin.OnHide(self)
	
	LibDD:UIDropDownMenu_EnableDropDown(CustomAchieverCategoryDownMenu)
	LibDD:UIDropDownMenu_EnableDropDown(CustomAchieverAchievementsDownMenu)
	CustomAchieverFrame.DescriptionEditBox:Enable()
	CustomAchieverFrame.SaveButton:Enable()
end

function CustAc_IconsPopupFrame_OnShow(self)
	IconSelectorPopupFrameTemplateMixin.OnShow(self)
	
	LibDD:UIDropDownMenu_DisableDropDown(CustomAchieverCategoryDownMenu)
	LibDD:UIDropDownMenu_DisableDropDown(CustomAchieverAchievementsDownMenu)
	CustomAchieverFrame.DescriptionEditBox:Disable()
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
	local name = selectedAchievement.achievementName
	self.BorderBox.IconSelectorEditBox:SetText(name)
	self.BorderBox.IconSelectorEditBox:HighlightText()

	local texture = selectedAchievement.achievementIcon
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
