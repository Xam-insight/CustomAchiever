local L = LibStub("AceLocale-3.0"):GetLocale("CustomAchiever", true)
local LibDD = LibStub:GetLibrary("LibUIDropDownMenu-4.0")

local nextCustomCategoryId
local nextCustomAchieverId

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
	
	nextCustomCategoryId = "CustomAchiever"
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
	CustomAchieverFrame_UpdateAchievementAlertFrame(nextCustomAchieverId)
end

function CustAc_CategoryDropDownMenu_Update(self)
	local info = LibDD:UIDropDownMenu_CreateInfo()
	info.text = L["MENUCUSTAC_CATEGORIES"]
	info.isTitle = true
	info.notCheckable = true
	LibDD:UIDropDownMenu_AddButton(info)
	
	--local info = LibDD:UIDropDownMenu_CreateInfo()
	--info.text = L["MENUCUSTAC_NEW"]
	--info.value = nextCustomAchieverId
	--info.func = function(button)
	--	LibDD:UIDropDownMenu_SetSelectedValue(self, button.value)
	--end
	--LibDD:UIDropDownMenu_AddButton(info)

	for k,v in pairs(CustomAchieverData["Categories"]) do
		if k == "CustomAchiever" then
			local info = LibDD:UIDropDownMenu_CreateInfo()
			info = LibDD:UIDropDownMenu_CreateInfo()
			info.text = CustAc_getLocaleData(v, "name")
			info.value = k
			info.func = function(button)
				LibDD:UIDropDownMenu_SetSelectedValue(self, button.value)
			end
			LibDD:UIDropDownMenu_AddButton(info)
		end
	end
	
	--CustAc_AchievementDropDownMenu_Update(self)
end

function CustAc_AchievementDropDownMenu_Update(self)
	local info = LibDD:UIDropDownMenu_CreateInfo()
	info.text = L["MENUCUSTAC_ACHIEVEMENTS"]
	info.isTitle = true
	info.notCheckable = true
	LibDD:UIDropDownMenu_AddButton(info)
	
	local info = LibDD:UIDropDownMenu_CreateInfo()
	info.text = CreateAtlasMarkup("UI-HUD-MicroMenu-Achievements-Up", 16, 22, 0, -3).." |cFF00FF00"..L["MENUCUSTAC_NEW"].."|r"
	info.value = nextCustomAchieverId
	info.func = function(button)
		LibDD:UIDropDownMenu_SetSelectedValue(self, button.value)
		CustomAchieverFrame_UpdateAchievementAlertFrame(button.value)
	end
	LibDD:UIDropDownMenu_AddButton(info)

	for k,v in pairs(CustomAchieverData["Achievements"]) do
		if v["parent"] == LibDD:UIDropDownMenu_GetSelectedValue(CustomAchieverCategoryDownMenu) then
			local info = LibDD:UIDropDownMenu_CreateInfo()
			info = LibDD:UIDropDownMenu_CreateInfo()
			info.text = CustAc_getLocaleData(v, "name")
			info.value = k
			info.func = function(button)
				LibDD:UIDropDownMenu_SetSelectedValue(self, button.value)
				CustomAchieverFrame_UpdateAchievementAlertFrame(button.value)
			end
			LibDD:UIDropDownMenu_AddButton(info)
		end
	end
end


function CustomAchieverFrame_UpdateAchievementAlertFrame(achievementId, achievementName, achievementIcon, description)
	if achievementId then
		if CustomAchieverData["Achievements"][achievementId] then
			CustomAchieverFrame.AchievementAlertFrame.Icon.Texture:SetTexture(achievementIcon or CustomAchieverData["Achievements"][achievementId].icon)
			CustomAchieverFrame.AchievementAlertFrame.Name:SetText(achievementName or CustAc_getLocaleData(CustomAchieverData["Achievements"][achievementId], "name"))
			if CustomAchieverData["Achievements"][achievementId].points and CustomAchieverData["Achievements"][achievementId].points > 0 then
						CustomAchieverFrame.AchievementAlertFrame.Shield.Points:SetText(CustomAchieverData["Achievements"][achievementId].points)
			end 
		else
			CustomAchieverFrame.AchievementAlertFrame.Icon.Texture:SetTexture(achievementIcon or 236376)
			CustomAchieverFrame.AchievementAlertFrame.Name:SetText(achievementName or L["MENUCUSTAC_DEFAULT_NAME"])
			CustomAchieverFrame.AchievementAlertFrame.Shield.Points:SetText("0")
		end
		CustomAchieverFrame.DescriptionEditBox:SetText(description or (CustomAchieverData["Achievements"][achievementId] and CustAc_getLocaleData(CustomAchieverData["Achievements"][achievementId], "desc")) or L["MENUCUSTAC_DESCRIPTION"])
		CustomAchieverFrame.DescriptionEditBox:HighlightText()
	end
end

function CustAc_IconsPopupFrame_OkayButton_OnClick()
	CustAc_IconsPopupFrame:Hide()
	
	local id = CustomAchieverAchievementsDownMenu.selectedValue
	local iconTexture = CustAc_IconsPopupFrame.BorderBox.SelectedIconArea.SelectedIconButton:GetIconTexture()
	local achievementName = CustAc_IconsPopupFrame.BorderBox.IconSelectorEditBox:GetText()
	achievementName = strtrim(achievementName):gsub("^%l", string.utf8upper):gsub("%s+", " ")

	CustomAchieverFrame_UpdateAchievementAlertFrame(id, achievementName, iconTexture, CustomAchieverFrame.DescriptionEditBox:GetText())
end

function CustAc_SaveButton_OnClick()
	local id   = CustomAchieverAchievementsDownMenu.selectedValue
	local achievementName = CustomAchieverFrame.AchievementAlertFrame.Name:GetText()
	local icon = CustomAchieverFrame.AchievementAlertFrame.Icon.Texture:GetTexture()
	local categoryId = CustomAchieverCategoryDownMenu.selectedValue
	local description = CustomAchieverFrame.DescriptionEditBox:GetText()
	
	CustAc_CreateOrUpdateAchievement(id, categoryId, icon, 0, achievementName, description)
	if id == nextCustomAchieverId then
		nextCustomAchieverId = CustAc_playerCharacter()..'-'..tostring(CustAc_getTimeUTCinMS())
	end
	
	local categoryName = CustAc_getLocaleData(CustomAchieverData["Categories"][categoryId], "name")
	
	CustAc_CompleteAchievement("CustomAchiever2")
	EZBlizzUiPop_ToastFakeAchievementNew(CustomAchiever, achievementName, 5208, true, 4, categoryName, function() CustAc_ShowAchievement(id) end, icon)
	
	LibDD:UIDropDownMenu_Initialize(CustomAchieverAchievementsDownMenu, CustAc_AchievementDropDownMenu_Update)
	LibDD:UIDropDownMenu_SetSelectedValue(CustomAchieverAchievementsDownMenu, id)
end

function CustAc_IconsPopupFrame_OnHide(self)
	IconSelectorPopupFrameTemplateMixin.OnHide(self)
end

function CustAc_IconsPopupFrame_OnShow(self)
	IconSelectorPopupFrameTemplateMixin.OnShow(self)
	self.BorderBox.IconSelectorEditBox:SetFocus()

	PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN)
	self.iconDataProvider = CustAc_IconsPopupFrame_RefreshIconDataProvider(self)
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
	
	CustAc_IconsPopupFrame_Init(self)
end

function CustAc_IconsPopupFrame_Init(self)
	local name = "tmp"
	self.BorderBox.IconSelectorEditBox:SetText(name)
	self.BorderBox.IconSelectorEditBox:HighlightText()

	local texture = 236376
	self.IconSelector:SetSelectedIndex(self:GetIndexOfIcon(texture))
	print(self:GetIndexOfIcon(texture))
	self.IconSelector:ScrollToSelectedIndex()
	self.BorderBox.SelectedIconArea.SelectedIconButton:SetIconTexture(texture)
end

function CustAc_IconsPopupFrame_RefreshIconDataProvider(self)
	if self.iconDataProvider == nil then
		self.iconDataProvider = CreateAndInitFromMixin(IconDataProviderMixin, IconDataProviderExtraType.None);
	end

	return self.iconDataProvider;
end
