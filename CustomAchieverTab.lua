local ACHIEVEMENTUI_FONTHEIGHT
local ACHIEVEMENTUI_MAX_LINES_COLLAPSED = 3	-- can show 3 lines of text when achievement is collapsed

CustAc_AchievementTabId = 4

CUSTOMACHIEVER_ACHIEVEMENTUI_CATEGORIES = {}
CUSTOMACHIEVER_CATEGORIES = {}
CUSTOMACHIEVER_ACHIEVEMENTS = {}

local g_achievementSelections = {{},{},{},{}}
local function GetSelectedAchievement(categoryIndex)
	return g_achievementSelections[CustAc_AchievementTabId].id or 0
end

local g_categorySelections = {{},{},{},{}}
local function GetSelectedCategory(categoryIndex)
	return g_categorySelections[CustAc_AchievementTabId].id or 0
end

local function ClearSelectedCategories()
	g_categorySelections = {{},{},{},{}}
end

local g_achievementSelectionBehavior = nil

local custacLastTableGeneration
local custacGenerationPending
function CustAc_LoadAchievementsData(callOrigin)
	--CustomAchiever:Print("Debug CustAc_LoadAchievementsData: ", callOrigin)
	
	if AchievementFrame then
		local callTime = time()
		if not custacLastTableGeneration then
			custacLastTableGeneration = callTime
		else
			if callTime < custacLastTableGeneration + 1 then
				if not custacGenerationPending then
					custacGenerationPending = true
					CustAc_Categories.LoadingSpinner:Show()
					CustAc_Categories.ScrollBox:SetAlpha(0.5)
					C_Timer.After(1 - (callTime - custacLastTableGeneration), function()
						custacGenerationPending = nil
						CustAc_LoadAchievementsData("CustAc_LoadAchievementsData")
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
		
		CustAc_ApplyIgnoreList()
		
		local categoriesId = {}
		local categories = {}
		for k,v in pairs(CustomAchieverData["Achievements"]) do
			if v["parent"] and not categories[v["parent"]] then
				categories[v["parent"]] = true
				categoriesId[ #categoriesId + 1 ] = v["parent"]
			end
		end

		for k,v in pairs(categories) do
			if CustomAchieverData["Categories"][k] and CustomAchieverData["Categories"][k]["parent"] and CustomAchieverData["Categories"][k]["parent"] ~= true
					and not categories[CustomAchieverData["Categories"][k]["parent"]] then
				categories[CustomAchieverData["Categories"][k]["parent"]] = true
				categoriesId[ #categoriesId + 1 ] = CustomAchieverData["Categories"][k]["parent"]
			end
		end
		table.sort(categoriesId)

		local selectedCategory = g_categorySelections[CustAc_AchievementTabId]
		for _,v in pairs(categoriesId) do
			if CustomAchieverData["Categories"][v] and (not CustomAchieverData["Categories"][v]["parent"] or CustomAchieverData["Categories"][v]["parent"] == true) and
					(not CustomAchieverData["Categories"][v]["author"] or not CustomAchieverData["BlackList"][CustomAchieverData["Categories"][v]["author"]]) then
				local categoryCollapsed = true
				if selectedCategory.id == v and selectedCategory.collapsed ~= nil then
					categoryCollapsed = selectedCategory.collapsed
				end
				if selectedCategory.id and CustomAchieverData["Categories"][selectedCategory.id] and CustomAchieverData["Categories"][selectedCategory.id]["parent"] == v then
					categoryCollapsed = false
				end
				insertCategory(v, categoryCollapsed)
				for _,v2 in pairs(categoriesId) do
					if CustomAchieverData["Categories"][v2] and CustomAchieverData["Categories"][v2]["parent"] == v then
						insertCategory(v2, nil, categoryCollapsed)
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
		
		if CustAc_AchievementFrameAchievements and CustAc_AchievementFrameAchievements:IsShown() then
			CustAc_AchievementFrameCategories_UpdateDataProvider()
			CustAc_AchievementFrameAchievements_UpdateDataProvider()
			AchievementFrame.Header.Points:SetText(BreakUpLargeNumbers(CustAc_GetTotalAchievementPoints()))
		end
		
		CustAc_Categories.LoadingSpinner:Hide()
		CustAc_Categories.ScrollBox:SetAlpha(1.0)
	end
end

function insertCategory(cat, collapsed, parentCollapsed)
	local data = {}
	for key, value in pairs(CustomAchieverData["Categories"][cat]) do
		data[key] = value
	end
	data.selected  = g_categorySelections[CustAc_AchievementTabId] and cat == g_categorySelections[CustAc_AchievementTabId].id
	data.collapsed = collapsed
	data.isChild   = (type(CustomAchieverData["Categories"][cat]["parent"]) == "string")
	data.hidden    = data.isChild and parentCollapsed
	tinsert(CUSTOMACHIEVER_ACHIEVEMENTUI_CATEGORIES, data)
	CUSTOMACHIEVER_CATEGORIES[cat] = {}
	CUSTOMACHIEVER_CATEGORIES[cat]["categoryName"] = CustAc_getLocaleData(CustomAchieverData["Categories"][cat], "name")
	CUSTOMACHIEVER_CATEGORIES[cat]["parentID"] = CustomAchieverData["Categories"][cat]["parent"]
	CUSTOMACHIEVER_CATEGORIES[cat]["flags"] = 0
end

function CustAc_AchievementFrame_Load()
	if not CustAc_Categories then
		if not CustAc_WoWRetail then
			AchievementFrame.Header = _G["AchievementFrameHeader"]
			AchievementFrame.Header.Title = _G["AchievementFrameHeaderTitle"]
			AchievementFrame.Header.Points = _G["AchievementFrameHeaderPoints"]
			AchievementFrame.Header.Shield = _G["AchievementFrameHeaderShield"]
		end
		local numtabs, tab = 0
		repeat
			if not CustAc_WoWRetail then
				if _G["AchievementFrameTab"..numtabs] then
					_G["AchievementFrameTab"..numtabs].Text = _G["AchievementFrameTab"..numtabs.."Text"]
				end
			end
			numtabs = numtabs + 1
		until (not _G["AchievementFrameTab"..numtabs])
		CustAc_AchievementTabId = numtabs
		tab = CreateFrame("Button", "AchievementFrameTab"..numtabs, AchievementFrame, "AchievementFrameTabButtonTemplate")
		if not CustAc_WoWRetail then
			tab.Text = _G["AchievementFrameTab"..numtabs.."Text"]
			tab:SetPoint("LEFT", _G["AchievementFrameTab"..(numtabs-1)], "RIGHT", -5, 0)
		end
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
		if not CustAc_WoWRetail then
			achievementsFrame:SetPoint("TOPLEFT", categoriesFrame, "TOPRIGHT", 22, 0)
		end
	end

	CustAc_CreateOrUpdateCategory("CustomAchiever", nil, "Custom Achiever")
	CustAc_CreateOrUpdateAchievement("CustomAchiever1", "CustomAchiever", 134939,  10, "Bonne installation !", "Intaller Custom Achiever.", "", nil, "frFR")
	CustAc_CreateOrUpdateAchievement("CustomAchiever1", "CustomAchiever",    nil, nil, "Happy move in!", "Install Custom Achiever.",        "", nil,"enUS")
	CustAc_CompleteAchievement("CustomAchiever1")
	CustAc_CreateOrUpdateAchievement("CustomAchiever2", "CustomAchiever", 134428,  10, "Un petit pas pour Azeroth...",  "Créer votre premier Haut fait.", "", nil,"frFR")
	CustAc_CreateOrUpdateAchievement("CustomAchiever2", "CustomAchiever",    nil, nil, "One small step for Azeroth...", "Create your first Achievement.", "", nil,"enUS")
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
		if not frame.Button.DeleteButton then
			local deleteButton = CreateFrame("Button", nil, frame.Button, "CustAc_DeleteButtonTemplate")
			deleteButton:SetPoint("RIGHT", frame.Button, "RIGHT", -10, -2)
			deleteButton:SetScript("OnClick", function(button)
				local categoryId = frame.Button.elementData and frame.Button.elementData.id
				local categoryName = CustAc_getLocaleData(CustomAchieverData["Categories"][categoryId], "name")
				if CustomAchieverData["PersonnalCategories"] and CustomAchieverData["PersonnalCategories"][categoryId] then
					local dialog = StaticPopup_Show("CUSTAC_CAT_DELETE", categoryName, GENERAL)
					if (dialog) then
						dialog.data = {}
						dialog.data["categoryId"] = categoryId
					end
				else
					local dialog = StaticPopup_Show("CUSTAC_CAT_DELETE_EXT", categoryName)
					if (dialog) then
						dialog.data = {}
						dialog.data["categoryId"] = categoryId
					end
				end
			end)
			frame.Button.DeleteButton = deleteButton
		end
	end)
	
	hooksecurefunc(AchievementCategoryTemplateButtonMixin, "OnEnter", function(self)
		-- Delete button
		local deleteButton = self.DeleteButton
		if deleteButton then
			local categoryId = self.elementData.id
			if categoryId == "GENERAL" then
				deleteButton:Hide()
			else
				deleteButton:Show()
			end
		end
	end)

	hooksecurefunc(AchievementCategoryTemplateButtonMixin, "OnLeave", function(self)
		-- Delete button
		C_Timer.After(0.05, function()
			if not self:IsMouseOver() then
				local deleteButton = self.DeleteButton
				if deleteButton then
					deleteButton:Hide()
				end
			end
		end)
		
	end)

	ScrollUtil.InitScrollBoxListWithScrollBar(self.ScrollBox, self.ScrollBar, view)
end

function CustAc_CategoryInit(self, elementData)
	if not CustAc_WoWRetail then
		self.Button = self
		self.Button.Label = self.label
		self.Button.Background = self.background
		self.UpdateSelectionState = function(self, selected)
			if selected then
				self.Button:LockHighlight();
			else
				self.Button:UnlockHighlight();
			end
		end
	end
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
	local ignoreCollapse = true
	
	if not CustAc_Categories.ScrollBox:HasDataProvider() then
		CustAc_AchievementFrameCategories_UpdateDataProvider()
	end
	
	local elementData = g_categorySelections[CustAc_AchievementTabId]
	if elementData.id and CustomAchieverData["Categories"][elementData.id] then
		CustAc_Categories.ScrollBox:ScrollToElementData(elementData, ScrollBoxConstants.AlignCenter, nil, ScrollBoxConstants.NoScrollInterpolation)
	else
		elementData = CustAc_Categories.ScrollBox:ScrollToElementDataIndex(1, ScrollBoxConstants.AlignCenter, nil, ScrollBoxConstants.NoScrollInterpolation)
		ignoreCollapse = false
	end
	
	if elementData then
		CustAc_AchievementFrameCategories_SelectElementData(elementData, ignoreCollapse)
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
		if iterElementData.selected and iterElementData.id ~= category then
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
		
		if not iterElementData.isChild and iterElementData.collapsed == nil then
			iterElementData.collapsed = true
		end
	end

	if not isChild then
		local newCollapsed
		if changeCollapsed then
			newCollapsed = not oldCollapsed
			elementData.collapsed = newCollapsed
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
	--AchievementFrameFilterDropDown:Hide()
	if AchievementFrame.Header.LeftDDLInset then
		AchievementFrame.Header.LeftDDLInset:Hide()
	end
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
		if not CustAc_WoWRetail then
			button.Description = button.description
			button.TitleBar = button.titleBar
			button.Icon = button.icon
			button.label:SetPoint("TOP", button.titleBar, "TOP", 0, 0)
			button.Label = button.label
			button.Shield = button.shield
			button.Shield.Points = button.shield.points
			button.Shield.Icon = button.shield.icon
			button.HiddenDescription = button.hiddenDescription
			button.DateCompleted = button.dateCompleted
			button.Reward = button.reward
			button.RewardBackground = button.rewardBackground
			button.Tracked = button.tracked
			button.PlusMinus = button.plusMinus
			button.highlight.topHighlight:SetPoint("TOPLEFT", button.highlight.topLeftHighlight, "TOPRIGHT", 0, 0)
			button.highlight.topHighlight:SetPoint("BOTTOMRIGHT", button.highlight.topRightHighlight, "BOTTOMLEFT", 0, 0)
			button.highlight.bottomHighlight:SetPoint("TOPLEFT", button.highlight.bottomLeftHighlight, "TOPRIGHT", 0, 0)
			button.highlight.bottomHighlight:SetPoint("BOTTOMRIGHT", button.highlight.bottomRightHighlight, "BOTTOMLEFT", 0, 0)
			button.highlight.leftHighlight:SetPoint("TOPLEFT", button.highlight.topLeftHighlight, "BOTTOMLEFT", 0, 0)
			button.highlight.leftHighlight:SetPoint("BOTTOMRIGHT", button.highlight.bottomLeftHighlight, "TOPRIGHT", 0, 0)
			button.highlight.rightHighlight:SetPoint("TOPLEFT", button.highlight.topRightHighlight, "BOTTOMLEFT", 0, 0)
			button.highlight.rightHighlight:SetPoint("BOTTOMRIGHT", button.highlight.bottomRightHighlight, "TOPRIGHT", 0, 0)
			button.Highlight = button.highlight
			button.glow:SetPoint("TOPLEFT", button.titleBar, "BOTTOMLEFT", 0, 4)
			button.Glow = button.glow
		end	
		if ( not ACHIEVEMENTUI_FONTHEIGHT ) then
			local _, fontHeight = button.Description:GetFont()
			ACHIEVEMENTUI_FONTHEIGHT = fontHeight
		end
		CustAc_AchievementInit(button, elementData)
		button:SetScript("OnEnter", function(frame) frame.Highlight:Show() end)
		button:SetScript("OnLeave", function(frame) frame.Highlight:Hide() end)
		button.elementData = elementData
		button:SetScript("OnClick", function(frame)
			if frame.elementData and frame.elementData.id then
				if IsShiftKeyDown() then
					-- Send updated data to custacDataTarget before sending chat message
					CustAc_SendUpdatedCategoryData(elementData.category, custacDataTarget)
	
					local name = CustAc_getLocaleData(CustomAchieverData["Achievements"][frame.elementData.id], "name")
					-- Insert the link in chat writing box when Shift-clicking
					ChatEdit_InsertLink("".."[CustAc_" .. frame.elementData.id .. "_"..name.."]".."")
				end
			end
		end)
		button.Shield:SetScript("OnClick", function(self, but, down)
			button:Click(but, down)
		end)
	end
	if CustAc_WoWRetail then
		view:SetElementInitializer("AchievementTemplate", AchievementInitializer)
	else
		view:SetElementInitializer("CustAc_AchievementTemplate", AchievementInitializer)
	end
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
	if not CustAc_WoWRetail then
		self.id = 0
	end
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
	if self.SetAsTracked then
		self:SetAsTracked(false, noSound)
	end
	self.Tracked:Hide()

	self:UpdatePlusMinusTexture()

	local objectives = (self.GetObjectiveFrame and self:GetObjectiveFrame()) or AchievementFrameAchievementsObjectives
	if objectives and objectives.id == self.id then
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
			scrollBox:ScrollToElementData(elementData, ScrollBoxConstants.AlignCenter, nil, ScrollBoxConstants.NoScrollInterpolation)
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
			scrollBox:ScrollToElementData(elementData, ScrollBoxConstants.AlignCenter, nil, ScrollBoxConstants.NoScrollInterpolation)
		end
	end
end
