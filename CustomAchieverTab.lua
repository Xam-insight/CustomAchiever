local ACHIEVEMENTUI_FONTHEIGHT
local ACHIEVEMENTUI_MAX_LINES_COLLAPSED = 3	-- can show 3 lines of text when achievement is collapsed

CustAc_AchievementTabId = 4

CUSTOMACHIEVER_ACHIEVEMENTUI_CATEGORIES = {}
CUSTOMACHIEVER_CATEGORIES = {}
CUSTOMACHIEVER_ACHIEVEMENTS = {}

local g_achievementSelections = {{},{},{},{}}
local function GetSelectedAchievement(categoryIndex)
	local categoryIndex = CustAc_AchievementTabId
	return g_achievementSelections[categoryIndex].id or 0
end

local g_categorySelections = {{},{},{},{}}
local function GetSelectedCategory(categoryIndex)
	local categoryIndex = CustAc_AchievementTabId
	return g_categorySelections[categoryIndex].id or 0
end

local function SetSelectedAchievement(elementData)
	local categoryIndex = achievementFunctions.categoryIndex;
	g_achievementSelections[categoryIndex] = elementData or {};
end

local function ClearSelectedCategories()
	g_categorySelections = {{},{},{},{}}
end

local g_achievementSelectionBehavior = nil

local custacLastTableGeneration
local custacGenerationPending
function CustAc_LoadAchievementsData()
	if AchievementFrame then
		local callTime = time()
		if not custacLastTableGeneration then
			custacLastTableGeneration = callTime
		else
			if callTime < custacLastTableGeneration + 2 then
				if not custacGenerationPending then
					custacGenerationPending = true
					CustAc_Categories.LoadingSpinner:Show()
					C_Timer.After(2 - (callTime - custacLastTableGeneration), function()
						custacGenerationPending = nil
						CustAc_LoadAchievementsData()
					end)
				end
				return
			else
				custacLastTableGeneration = callTime
			end
		end
		
		local loadTime = time()
		
		CUSTOMACHIEVER_ACHIEVEMENTUI_CATEGORIES = {}
		CUSTOMACHIEVER_CATEGORIES = {}
		CUSTOMACHIEVER_ACHIEVEMENTS = {}

		local categoriesId = {}
		local categories = {}
		for k,v in pairs(CustomAchieverData["Achievements"]) do
			if v["parent"] and not categories[v["parent"]] then
				categories[v["parent"]] = true
				categoriesId[ #categoriesId + 1 ] = v["parent"]
			end
		end
		for k,v in pairs(categories) do
			if CustomAchieverData["Categories"][k]["parent"] and not categories[CustomAchieverData["Categories"][k]["parent"]] then
				categories[CustomAchieverData["Categories"][k]["parent"]] = true
				categoriesId[ #categoriesId + 1 ] = CustomAchieverData["Categories"][k]["parent"]
			end
		end
		table.sort(categoriesId)

		for _,v in pairs(categoriesId) do
			if not CustomAchieverData["Categories"][v]["parent"] or CustomAchieverData["Categories"][v]["parent"] == true then
				insertCategory(v)
				for _,v2 in pairs(categoriesId) do
					if CustomAchieverData["Categories"][v2]["parent"] == v then
						insertCategory(v2)
					end
				end
			end
		end

		local achievementsId = {}
		for k in pairs(CustomAchieverData["Achievements"]) do
			achievementsId[ #achievementsId + 1 ] = k
		end
		table.sort(achievementsId)

		for k,v in pairs(achievementsId) do
			if CustomAchieverData["Achievements"][v]["firstAchiever"] then
				CustAc_GetAchievement(CustomAchieverData["Achievements"][v])
			end
		end
		for k,v in pairs(achievementsId) do
			if not CustomAchieverData["Achievements"][v]["firstAchiever"] then
				CustAc_GetAchievement(CustomAchieverData["Achievements"][v])
			end
		end
		
		CustAc_Categories.LoadingSpinner:Hide()
	end
end

function insertCategory(cat)
	local data = {}
	for key, value in pairs(CustomAchieverData["Categories"][cat]) do
		data[key] = value
	end
	data["isChild"] = (type(CustomAchieverData["Categories"][cat]["parent"]) == "string")
	tinsert(CUSTOMACHIEVER_ACHIEVEMENTUI_CATEGORIES, data)
	CUSTOMACHIEVER_CATEGORIES[cat] = {}
	CUSTOMACHIEVER_CATEGORIES[cat]["categoryName"] = CustAc_getLocaleData(CustomAchieverData["Categories"][cat], "name")
	CUSTOMACHIEVER_CATEGORIES[cat]["parentID"] = CustomAchieverData["Categories"][cat]["parent"]
	CUSTOMACHIEVER_CATEGORIES[cat]["flags"] = 0
end

function CustAc_AchievementFrame_Load()
	if not CustAc_Categories then
		local numtabs, tab = 0
		repeat
			numtabs = numtabs + 1
		until (not _G["AchievementFrameTab"..numtabs])
		CustAc_AchievementTabId = numtabs
		tab = CreateFrame("Button", "AchievementFrameTab"..numtabs, AchievementFrame, "AchievementFrameTabButtonTemplate")
		CustacButton:SetParent(tab)
		CustacButton:SetPoint("CENTER", tab, "BOTTOMRIGHT", -5, -5)
		tab:SetText("Custom Achiever")
		tab:SetID(numtabs)
		
		if CustAc_Krowi_Loaded then
			tab:SetScript("OnShow", function(self)
				PanelTemplates_TabResize(self, 30)
				self:SetPoint("TOPLEFT", "AchievementFrameTab1", "BOTTOMLEFT", 20, -5)
				self:SetFrameLevel(1)
			end)
		end
		
		tab:SetScript("OnClick", function(self)
			CustAc_AchievementFrame_OnClick(self:GetID())
			PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB)
		end)
		
		PanelTemplates_SetNumTabs(AchievementFrame, numtabs)

		hooksecurefunc("AchievementFrame_UpdateTabs", CustAc_AchievementFrame_UpdateTabs)

		local categoriesFrame = CreateFrame("Frame", "CustAc_Categories", AchievementFrame, "CustAc_CategoriesTemplate")
		local achievementsFrame = CreateFrame("Frame", "CustAc_AchievementFrameAchievements", AchievementFrame, "CustAc_AchievementFrameAchievementsTemplate")
	end

	CustAc_CreateOrUpdateCategory("CustomAchiever", nil, "Custom Achiever")
	CustAc_CreateOrUpdateAchievement("CustomAchiever1", "CustomAchiever", 975739,  10, "Bonne installation !", "Intaller Custom Achiever.", "", nil, "frFR")
	CustAc_CreateOrUpdateAchievement("CustomAchiever1", "CustomAchiever",    nil, nil, "Happy move in!", "Install Custom Achiever.",        "", nil,"enUS")
	CustAc_CompleteAchievement("CustomAchiever1")
	CustAc_CreateOrUpdateAchievement("CustomAchiever2", "CustomAchiever", 133053,  10, "Un petit pas pour Azeroth...",  "Créer votre premier Haut fait.", "", nil,"frFR")
	CustAc_CreateOrUpdateAchievement("CustomAchiever2", "CustomAchiever",    nil, nil, "One small step for Azeroth...", "Create your first Achievement.", "", nil,"enUS")
	CustAc_LoadAchievementsData()
end

function CustAc_AchievementFrameCategories_OnLoad(self)
	---self:RegisterEvent("ADDON_LOADED")

	local view = CreateScrollBoxListLinearView()
	view:SetElementInitializer("AchievementCategoryTemplate", function(frame, elementData)
		CustAc_CategoryInit(frame, elementData)
		frame.Button.elementData = elementData
		frame.Button:SetScript("OnClick", function(button)
			CustAc_AchievementFrameCategories_OnCategoryClicked(button)
		end)
	end)

	ScrollUtil.InitScrollBoxListWithScrollBar(self.ScrollBox, self.ScrollBar, view)
end

function CustAc_CategoryInit(self, elementData)
	if ( elementData.isChild ) then
		self.Button:SetWidth(ACHIEVEMENTUI_CATEGORIESWIDTH - 25)
		self.Button.Label:SetFontObject("GameFontHighlight")
		self.parentID = elementData.parent
		self.Button.Background:SetVertexColor(0.6, 0.6, 0.6)
	else
		self.Button:SetWidth(ACHIEVEMENTUI_CATEGORIESWIDTH - 10)
		self.Button.Label:SetFontObject("GameFontNormal")
		self.parentID = elementData.parent
		self.Button.Background:SetVertexColor(1, 1, 1)
	end

	local categoryName, parentID, flags
	local numAchievements, numCompleted

	local id = elementData.id

	categoryName = CUSTOMACHIEVER_CATEGORIES[id]["categoryName"]
	flags = CUSTOMACHIEVER_CATEGORIES[id]["flags"]
	
	numAchievements, numCompleted = CustAc_GetCategoryNumAchievements_All(id)

	self.Button.Label:SetText(categoryName)
	self.categoryID = id
	self.flags = flags

	-- For the tooltip
	self.Button.name = categoryName
	self.Button.text = nil
	self.Button.numAchievements = numAchievements
	self.Button.numCompleted = numCompleted
	self.Button.numCompletedText = numCompleted.."/"..numAchievements
	self.Button.showTooltipFunc = AchievementFrameCategory_StatusBarTooltip

	self:UpdateSelectionState(elementData.selected)
end

function CustAc_AchievementFrameCategories_OnCategoryClicked(button)
	CustAc_AchievementFrameCategories_SelectElementData(button.elementData)
end

function CustAc_AchievementFrameCategories_OnShow()
	CustAc_AchievementFrameCategories_UpdateDataProvider()
	CustAc_AchievementFrameCategories_SelectDefaultElementData()
end

function CustAc_AchievementFrameCategories_SelectDefaultElementData()
	if not CustAc_Categories.ScrollBox:HasDataProvider() then
		CustAc_AchievementFrameCategories_UpdateDataProvider()
	end
	
	local elementData = g_categorySelections[CustAc_AchievementTabId]
	if elementData.id then
		CustAc_Categories.ScrollBox:ScrollToElementData(elementData, ScrollBoxConstants.AlignCenter, ScrollBoxConstants.NoScrollInterpolation)
	else
		elementData = CustAc_Categories.ScrollBox:ScrollToElementDataIndex(1, ScrollBoxConstants.AlignCenter, ScrollBoxConstants.NoScrollInterpolation)
	end
	                    
	if elementData then
		CustAc_AchievementFrameCategories_SelectElementData(elementData)
	end
end

function CustAc_AchievementFrameCategories_SelectElementData(elementData, ignoreCollapse)
	local categoryIndex = CustAc_AchievementTabId
	local selection = g_categorySelections[categoryIndex]
	local category = elementData.id
	local categoryChanged = selection.id ~= category

	-- Don't modify any collapsed state if we're transitioning from a child to it's parent.
	local changeCollapsed = not ignoreCollapse and not (elementData.parent and selection.parent == category)
	local oldCollapsed = elementData.collapsed
	local isChild = elementData.isChild
	
	local categories = CUSTOMACHIEVER_ACHIEVEMENTUI_CATEGORIES
	for index, iterElementData in ipairs(categories) do
		if iterElementData.selected then
			iterElementData.selected = false
			local frame = CustAc_Categories.ScrollBox:FindFrame(iterElementData)
			if frame then
				frame:UpdateSelectionState(false)
			end
		end

		if not isChild and changeCollapsed then
			if not iterElementData.isChild then
				iterElementData.collapsed = true
			end
		end
	end

	if not isChild then
		local newCollapsed = newCollapsed
		if changeCollapsed then
			newCollapsed = not oldCollapsed
			if not elementData.isChild then
				elementData.collapsed = newCollapsed
			end
		end

		for index, iterElementData in ipairs(categories) do
			if iterElementData.parent == category then
				iterElementData.hidden = newCollapsed
			elseif iterElementData.parent ~= nil and iterElementData.isChild then
				iterElementData.hidden = true
			end
		end
	end

	elementData.selected = true
	g_categorySelections[categoryIndex] = elementData

	local frame = CustAc_Categories.ScrollBox:FindFrame(elementData)
	if frame then
		frame:UpdateSelectionState(true)
	end
	
	-- No change in the contents of the list. We only changed the selection.
	if not isChild and changeCollapsed then
		CustAc_AchievementFrameCategories_UpdateDataProvider()
	end

	if categoryChanged then
		CustAc_AchievementFrameCategories_OnCategoryChanged(category)
	end
end

function CustAc_AchievementFrameCategories_UpdateDataProvider()
	local newDataProvider = CreateDataProvider()
	for index, category in ipairs(CUSTOMACHIEVER_ACHIEVEMENTUI_CATEGORIES) do
		if not category.hidden then
			newDataProvider:Insert(category)
		end
	end

	CustAc_Categories.ScrollBox:SetDataProvider(newDataProvider)
end

function CustAc_AchievementFrameCategories_OnCategoryChanged(category)
	CustAc_AchievementFrameAchievements_UpdateDataProvider()
	--AchievementFrameFilterDropDown:Show()
	--AchievementFrame.Header.LeftDDLInset:Show()
	CustAc_AchievementFrameAchievementsFeatOfStrengthText:SetShown(false)
end

function CustAc_AchievementFrame_ToggleView()
	--IN_GUILD_VIEW = nil
	TEXTURES_OFFSET = 0
	-- container backgrounds
	--CustAc_AchievementFrameAchievementsBackground:SetTexCoord(0, 1, 0, 0.5)
	--AchievementFrameSummaryBackground:SetTexCoord(0, 1, 0, 0.5)
	-- header
	AchievementFrame.Header.Points:SetVertexColor(1, 1, 1)
	AchievementFrame.Header.Title:SetText("Custom Achiever")
	local shield = AchievementFrame.Header.Shield
	shield:SetTexture("Interface\\AchievementFrame\\UI-Achievement-TinyShield")
	shield:SetTexCoord(0, 0.625, 0, 0.625)
	shield:SetHeight(20)
	
	AchievementFrame.Header.Points:SetText(BreakUpLargeNumbers(CustAc_GetTotalAchievementPoints()))
end

function CustAc_AchievementFrame_UpdateTabs(clickedTab)
	--CustAcCategoryList = GetCategoryInfo(GetCategoryList()[1])
	AchievementFrameCategories:Show()
	CustAc_Categories:Hide()
	CustAc_AchievementFrameAchievements:Hide()
	local tab = _G["AchievementFrameTab"..CustAc_AchievementTabId]
	if tab then
		if (CustAc_AchievementTabId == clickedTab) then
			tab.Text:SetPoint("CENTER", 0, -5)
		else
			tab.Text:SetPoint("CENTER", 0, -3)
			if 1 == clickedTab then
				-- header
				AchievementFrame.Header.Title:SetText(ACHIEVEMENT_TITLE)
				AchievementFrame.Header.Points:SetText(BreakUpLargeNumbers(GetTotalAchievementPoints()))
			end
		end
	end
end

function CustAc_AchievementFrame_OnClick(clickedTab)
	AchievementFrameTab_OnClick(1) -- to prevent IN_GUILD_VIEW
	AchievementFrame_UpdateTabs(clickedTab)
	CustAc_Categories:Show()
	AchievementFrameCategories:Hide()
	AchievementFrameAchievements:Hide()
	AchievementFrame_ShowSubFrame(CustAc_AchievementFrameAchievements)
	CustAc_AchievementFrameAchievements:Show()

	--local isSummary = false
	local swappedView = false
	CustAc_AchievementFrame_ToggleView()
	--if ( achievementFunctions.selectedCategory == "summary" ) then
		--isSummary = true
		--AchievementFrame_ShowSubFrame(AchievementFrameSummary)
	--else
		--AchievementFrame_ShowSubFrame(CustAc_AchievementFrameAchievements)
	--end
	AchievementFrameWaterMark:SetTexture("Interface\\AchievementFrame\\UI-Achievement-AchievementWatermark")
	AchievementFrameCategoriesBG:SetTexCoord(0, 0.5, 0, 1)
	AchievementFrameGuildEmblemLeft:Hide()
	AchievementFrameGuildEmblemRight:Hide()

	--CustAc_AchievementFrameCategories_Update()

	--if ( not isSummary ) then
		--achievementFunctions.updateFunc()
	--end

	--SwitchAchievementSearchTab(clickedTab)
	AchievementFrameFilterDropDown:Hide()
	AchievementFrame.Header.LeftDDLInset:Hide()
end

function CustAc_GetAchievementInfoById(achievement)
	local achievementData = {}
	local order = 0
	if category and CUSTOMACHIEVER_ACHIEVEMENTS[category] then
		for k, values in pairs(CUSTOMACHIEVER_ACHIEVEMENTS[category]) do
			if values["id"] == achievement then
				achievementData = values
				order = k
				break
			end
		end
	end
	return achievementData["id"],
		achievementData["name"],
		achievementData["points"],
		achievementData["completed"],
		achievementData["month"],
		achievementData["day"],
		achievementData["year"],
		achievementData["description"],
		achievementData["flags"],
		achievementData["icon"],
		achievementData["rewardText"],
		achievementData["isGuild"],
		achievementData["wasEarnedByMe"],
		achievementData["earnedBy"],
		order
end

function CustAc_GetAchievementInfoByOrder(category, order)
	return CUSTOMACHIEVER_ACHIEVEMENTS[category][order]["id"],
		CUSTOMACHIEVER_ACHIEVEMENTS[category][order]["name"],
		CUSTOMACHIEVER_ACHIEVEMENTS[category][order]["points"],
		CUSTOMACHIEVER_ACHIEVEMENTS[category][order]["completed"],
		CUSTOMACHIEVER_ACHIEVEMENTS[category][order]["month"],
		CUSTOMACHIEVER_ACHIEVEMENTS[category][order]["day"],
		CUSTOMACHIEVER_ACHIEVEMENTS[category][order]["year"],
		CUSTOMACHIEVER_ACHIEVEMENTS[category][order]["description"],
		CUSTOMACHIEVER_ACHIEVEMENTS[category][order]["flags"],
		CUSTOMACHIEVER_ACHIEVEMENTS[category][order]["icon"],
		CUSTOMACHIEVER_ACHIEVEMENTS[category][order]["rewardText"],
		CUSTOMACHIEVER_ACHIEVEMENTS[category][order]["isGuild"],
		CUSTOMACHIEVER_ACHIEVEMENTS[category][order]["wasEarnedByMe"],
		CUSTOMACHIEVER_ACHIEVEMENTS[category][order]["earnedBy"]
end

local function CustAc_SetSelectedAchievement(elementData)
	local categoryIndex = CustAc_AchievementTabId
	g_achievementSelections[categoryIndex] = elementData or {}
end

function CustAc_AchievementFrameAchievements_OnLoad(self)
	--self:RegisterEvent("ADDON_LOADED")
	
	local function AchievementResetter(button)
		if SelectionBehaviorMixin.IsIntrusiveSelected(button) then
			local objectives = button:GetObjectiveFrame()
			objectives:Clear()
		end
	end

	local view = CreateScrollBoxListLinearView()
	view:SetElementExtentCalculator(function(dataIndex, elementData)
		if SelectionBehaviorMixin.IsElementDataIntrusiveSelected(elementData) then
			return AchievementTemplateMixin.CalculateSelectedHeight(elementData)
		else
			return ACHIEVEMENTBUTTON_COLLAPSEDHEIGHT
		end
	end)
	local function AchievementInitializer(button, elementData)
		if ( not ACHIEVEMENTUI_FONTHEIGHT ) then
			local _, fontHeight = button.Description:GetFont()
			ACHIEVEMENTUI_FONTHEIGHT = fontHeight
		end
		CustAc_AchievementInit(button, elementData)
		button:SetScript("OnEnter", function(frame) frame.Highlight:Show() end)
		button:SetScript("OnLeave", function(frame) frame.Highlight:Hide() end)
		--button.elementData = elementData
		button:SetScript("OnClick", function() end)
	end
	view:SetElementInitializer("AchievementTemplate", AchievementInitializer)
	view:SetElementResetter(AchievementResetter)
	view:SetPadding(2,0,0,4,0)
	ScrollUtil.InitScrollBoxListWithScrollBar(self.ScrollBox, self.ScrollBar, view)
	
	g_achievementSelectionBehavior = ScrollUtil.AddSelectionBehavior(self.ScrollBox, SelectionBehaviorFlags.Deselectable, SelectionBehaviorFlags.Intrusive)
	g_achievementSelectionBehavior:RegisterCallback(SelectionBehaviorMixin.Event.OnSelectionChanged, function(o, elementData, selected)
		if selected then
			CustAc_SetSelectedAchievement(elementData)
		else
			CustAc_SetSelectedAchievement(nil)
		end

		local button = self.ScrollBox:FindFrame(elementData)
		if button then
			button:SetSelected(selected)
		end
	end, self)

	ScrollUtil.AddResizableChildrenBehavior(self.ScrollBox)
end

function CustAc_AchievementInit(self, elementData)
	self.UpdatePlusMinusTexture = CustAc_UpdatePlusMinusTexture
	
	self.index = elementData.index
	self.id = elementData.id
	local category = elementData.category

	-- reset button info to get proper saturation/desaturation
	self.completed = nil

	-- title
	self.TitleBar:SetAlpha(0.8)
	self.Icon.frame:SetTexture("Interface\\AchievementFrame\\UI-Achievement-IconFrame")
	self.Icon.frame:SetTexCoord(0, 0.5625, 0, 0.5625)
	self.Icon.frame:SetPoint("CENTER", -1, 2)
	local tsunami = self.BottomTsunami1
	tsunami:SetTexture("Interface\\AchievementFrame\\UI-Achievement-Borders")
	tsunami:SetTexCoord(0, 0.72265, 0.51953125, 0.58203125)
	tsunami:SetAlpha(0.35)
	local tsunami = self.TopTsunami1
	tsunami:SetTexture("Interface\\AchievementFrame\\UI-Achievement-Borders")
	tsunami:SetTexCoord(0.72265, 0, 0.58203125, 0.51953125)
	tsunami:SetAlpha(0.3)
	self.Glow:SetTexCoord(0, 1, 0.00390625, 0.25390625)

	local id, name, points, completed, month, day, year, description, flags, icon, rewardText, isGuild, wasEarnedByMe, earnedBy
	if self.index then
		id, name, points, completed, month, day, year, description, flags, icon, rewardText, isGuild, wasEarnedByMe, earnedBy = CustAc_GetAchievementInfoByOrder(category, self.index)
	else
		-- Twitter
		id, name, points, completed, month, day, year, description, flags, icon, rewardText, isGuild, wasEarnedByMe, earnedBy = CustAc_GetAchievementInfoById(self.id)
		category = GetAchievementCategory(self.id)
	end

	local saturatedStyle
	if ( bit.band(flags, ACHIEVEMENT_FLAGS_ACCOUNT) == ACHIEVEMENT_FLAGS_ACCOUNT ) then
		self.accountWide = true
		saturatedStyle = "account"
	else
		self.accountWide = nil
		saturatedStyle = "normal"
	end
	self.Label:SetWidth(ACHIEVEMENTBUTTON_LABELWIDTH)
	self.Label:SetText(name)

	AchievementShield_SetPoints(points, self.Shield.Points, AchievementPointsFont, AchievementPointsFontSmall)

	if ( points > 0 ) then
		self.Shield.Icon:SetTexture([[Interface\AchievementFrame\UI-Achievement-Shields]])
	else
		self.Shield.Icon:SetTexture([[Interface\AchievementFrame\UI-Achievement-Shields-NoPoints]])
	end

	self.Shield.wasEarnedByMe = not (completed and not wasEarnedByMe)
	self.Shield.earnedBy = earnedBy

	self.Shield.id = id
	self.Description:SetText(description)
	self.HiddenDescription:SetText(description)
	self.numLines = ceil(self.HiddenDescription:GetHeight() / ACHIEVEMENTUI_FONTHEIGHT)
	self.Icon.texture:SetTexture(icon)
	if ( completed or wasEarnedByMe ) then
		self.completed = true
		self.DateCompleted:SetText(FormatShortDate(day, month, year))
		self.DateCompleted:Show()
		if ( self.saturatedStyle ~= saturatedStyle ) then
			self:Saturate()
		end
	else
		self.completed = nil
		self.DateCompleted:Hide()
		self:Desaturate()
	end

	if ( rewardText == "" ) then
		self.Reward:Hide()
		self.RewardBackground:Hide()
	else
		self.Reward:SetText(rewardText)
		self.Reward:Show()
		self.RewardBackground:Show()
		if ( self.completed ) then
			self.RewardBackground:SetVertexColor(1, 1, 1)
		else
			self.RewardBackground:SetVertexColor(0.35, 0.35, 0.35)
		end
	end

	local noSound = true
	self:SetAsTracked(false, noSound)
	self.Tracked:Hide()

	self:UpdatePlusMinusTexture()

	local objectives = self:GetObjectiveFrame()
	if objectives.id == self.id then
		objectives:Hide()
	end

	if ( not self:IsMouseOver() ) then
		self.Highlight:Hide()
	end

	self:Collapse()
end

function CustAc_AchievementFrameAchievements_UpdateDataProvider()
	local category = g_categorySelections[CustAc_AchievementTabId].id --AchievementFrame_GetOrSelectCurrentCategory()

	local numAchievements, numCompleted, completedOffset = CustAc_GetCategoryNumAchievements_All(category)

	local newDataProvider = CreateDataProvider()
	for index = 1, numAchievements do
		if index <= numAchievements then
			local filteredIndex = index + completedOffset
			local id = CustAc_GetAchievementInfoByOrder(category, filteredIndex)
			newDataProvider:Insert({category = category, index = filteredIndex, id = id})
		end
	end
	CustAc_AchievementFrameAchievements.ScrollBox:SetDataProvider(newDataProvider)
end

function CustAc_UpdatePlusMinusTexture(self)
	local id = self.id
	if ( not id ) then
		return -- This happens when we create buttons
	end

	self.PlusMinus:Hide()
end

function CustAc_ShowAchievement(id)
	if id and CustomAchieverData["Achievements"][id] and AchievementFrame then
		AchievementFrame:Show()
		AchievementFrameTab_OnClick(1) -- to prevent IN_GUILD_VIEW
		CustAc_AchievementFrame_OnClick(CustAc_AchievementTabId)
		CustAc_AchievementFrame_UpdateAndSelectCategory(CustomAchieverData["Achievements"][id]["parent"])
		--CustAc_AchievementFrame_SelectAndScrollToAchievementId(CustAc_AchievementFrameAchievements.ScrollBox, id)
	end
end

function CustAc_AchievementFrameCategories_ExpandToCategory(category)
	local categories = CUSTOMACHIEVER_ACHIEVEMENTUI_CATEGORIES
	local index, elementData = FindInTableIf(categories, function(elementData)
		return elementData.id == category
	end);

	if elementData and elementData.isChild then
		local openID = elementData.parent
		for index, iterElementData in ipairs(categories) do
			iterElementData.hidden = iterElementData.isChild and iterElementData.parent ~= openID
		end
	end
end

function CustAc_AchievementFrame_UpdateAndSelectCategory(category)
	local currentCategory = GetSelectedCategory()
	if not CustAc_Categories or not CustAc_Categories:IsShown() or currentCategory == category then
		return;
	end

	-- Assume the category is not in our data provider.
	CustAc_AchievementFrameCategories_ExpandToCategory(category)
	CustAc_AchievementFrameCategories_UpdateDataProvider()

	-- Select the category.
	local scrollBox = CustAc_Categories.ScrollBox
	local dataProvider = scrollBox:GetDataProvider()
	if dataProvider then
		local elementData = dataProvider:FindElementDataByPredicate(function(elementData)
			return elementData.id == category
		end);
		if elementData then
			CustAc_AchievementFrameCategories_SelectElementData(elementData)
			scrollBox:ScrollToElementData(elementData, ScrollBoxConstants.AlignCenter, ScrollBoxConstants.NoScrollInterpolation)
		end
	end
end

function CustAc_AchievementFrame_SelectAndScrollToAchievementId(scrollBox, achievementId)
	local dataProvider = scrollBox:GetDataProvider()
	if dataProvider then
		local elementData = dataProvider:FindElementDataByPredicate(function(elementData)
			return elementData.id == achievementId
		end)
		if elementData then
			g_achievementSelectionBehavior:SelectElementData(elementData)
			-- Selection expands and modifies the size. We need to update the scroll box for the alignment to be correct.
			scrollBox:FullUpdate(ScrollBoxConstants.UpdateImmediately)
			scrollBox:ScrollToElementData(elementData, ScrollBoxConstants.AlignCenter, ScrollBoxConstants.NoScrollInterpolation)
		end
	end
end
