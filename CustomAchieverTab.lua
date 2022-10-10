local ACHIEVEMENTUI_FONTHEIGHT
local ACHIEVEMENTUI_MAX_LINES_COLLAPSED = 3	-- can show 3 lines of text when achievement is collapsed

local achievementFunctions

CUSTOMACHIEVER_ACHIEVEMENTUI_CATEGORIES = {}
CUSTOMACHIEVER_CATEGORIES = {}
CUSTOMACHIEVER_ACHIEVEMENTS = {}

function CustAc_UpdateCategory(id, parentID, categoryName, locale)
	if id then
		local parentCategory = nil
		if parentID then
			if not CustomAchieverData["Categories"][parentID] then
				CustAc_UpdateCategory(parentID)
				parentCategory = parentID
			elseif not CustomAchieverData["Categories"][parentID]["parent"] or CustomAchieverData["Categories"][parentID]["parent"] == true then
				parentCategory = parentID
			end
		end

		local data = CustomAchieverData["Categories"][id] or {}
		data["id"]       = id or data["id"]
		data["parent"]   = parentCategory or data["parent"]
		data["hidden"]   = (data["parentID"] ~= nil)
		data[locale or GetLocale()] = categoryName or data[locale or GetLocale()] or id

		CustomAchieverData["Categories"][id] = data

		if parentCategory then
			CustomAchieverData["Categories"][id]["hidden"]                = true
			CustomAchieverData["Categories"][parentCategory]["parent"]    = true
			CustomAchieverData["Categories"][parentCategory]["collapsed"] = true
		end
		CustAc_LoadAchievementsData()
	end
end

function CustAc_LoadAchievementsData()
	if AchievementFrame then
		achievementFunctions = CUSTOMACHIEVER_ACHIEVEMENT_FUNCTIONS

		CUSTOMACHIEVER_ACHIEVEMENTUI_CATEGORIES = {}
		CUSTOMACHIEVER_CATEGORIES = {}
		CUSTOMACHIEVER_ACHIEVEMENTS = {}

		local categoriesId = {}
		for k,v in pairs(CustomAchieverData["Categories"]) do
			categoriesId[ #categoriesId + 1 ] = k
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

		CustAc_AchievementFrameCategories_Update()
	end
end

function insertCategory(cat)
	local data = {}
	for key, value in pairs(CustomAchieverData["Categories"][cat]) do
		data[key] = value
	end
	tinsert(CUSTOMACHIEVER_ACHIEVEMENTUI_CATEGORIES, data)
	CUSTOMACHIEVER_CATEGORIES[cat] = {}
	CUSTOMACHIEVER_CATEGORIES[cat]["categoryName"] = CustomAchieverData["Categories"][cat][GetLocale()] or CustomAchieverData["Categories"][cat]["enUS"] or CustomAchieverData["Categories"][cat]["enGB"] or CustomAchieverData["Categories"][cat]["frFR"] or CustomAchieverData["Categories"][cat]["deDE"] or CustomAchieverData["Categories"][cat]["esES"] or CustomAchieverData["Categories"][cat]["esMX"] or CustomAchieverData["Categories"][cat]["itIT"] or CustomAchieverData["Categories"][cat]["koKR"] or CustomAchieverData["Categories"][cat]["ptBR"] or CustomAchieverData["Categories"][cat]["ruRU"] or CustomAchieverData["Categories"][cat]["zhCN"] or CustomAchieverData["Categories"][cat]["zhTW"]
	CUSTOMACHIEVER_CATEGORIES[cat]["parentID"] = CustomAchieverData["Categories"][cat]["parent"]
	CUSTOMACHIEVER_CATEGORIES[cat]["flags"] = 0
end

function CustAc_UpdateAchievement(id, parent, icon, points, name, description, locale)
	if id then
		local parentCategory = parent or "CustomAchiever"
		if not CustomAchieverData["Categories"][parentCategory] then
			CustAc_UpdateCategory(parentCategory, nil, parentCategory, locale)
		end
		local data = {}
		if CustomAchieverData["Achievements"][id] then
			data = CustomAchieverData["Achievements"][id]
		end
		data["id"]                             = id
		data["parent"]                         = parentCategory
		data["name_"..(locale or GetLocale())] = name              or data["name_"..(locale or GetLocale())] or "Custom Achiever"
		data["desc_"..(locale or GetLocale())] = description       or data["desc_"..(locale or GetLocale())] or "Custom Achiever"
		data["icon"]                           = icon              or data["icon"]                           or 236376
		data["points"]                         = points            or data["points"]                         or 10
		data["flags"]                          = 0
		data["rewardText"]                     = nil
		data["isGuild"]                        = false
		data["completed"]                      = data["completed"] or {}
		data["date"]                           = data["date"]      or {}
		--data["wasEarnedByMe"] = true
		--data["earnedBy"] = "Xamena"

		CustomAchieverData["Achievements"][id] = data
		CustAc_LoadAchievementsData()
		if AchievementFrame and CustAc_AchievementFrameAchievements:IsShown() then
			CustAc_AchievementFrameAchievements_Update()
		end
	end
end

function CustAc_CompleteAchievement(id, earnedBy, noNotif, forceNotif)
	if id and CustomAchieverData["Achievements"][id] then
		local earnedByWithRealm = CustAc_playerCharacter()
		if earnedBy then
			earnedByWithRealm = CustAc_addRealm(earnedBy)
		end
		local forPlayerCharacter = earnedByWithRealm == CustAc_playerCharacter()
		local data = CustomAchieverData["Achievements"][id]
		local alreadyEarned = data["completed"][earnedByWithRealm]
		data["completed"][earnedByWithRealm] = data["completed"][earnedByWithRealm] or true
		data["date"][earnedByWithRealm] = data["date"][earnedByWithRealm] or C_DateAndTime.GetCurrentCalendarTime()
		data["firstAchiever"] = data["firstAchiever"] or earnedByWithRealm
		--data["wasEarnedByMe"] = true
		--data["earnedBy"] = "Xamena"

		CustomAchieverData["Achievements"][id] = data

		if forPlayerCharacter and (not alreadyEarned or forceNotif) and not noNotif then
			local name = data["name_"..GetLocale()] or data["name_enUS"] or data["name_enGB"] or data["name_frFR"] or data["name_deDE"] or data["name_esES"] or data["name_esMX"] or data["name_itIT"] or data["name_koKR"] or data["name_ptBR"] or data["name_ruRU"] or data["name_zhCN"] or data["name_zhTW"]
			EZBlizzUiPop_ToastFakeAchievementNew(CustomAchiever, name, 5208, false, 15, "Custom Achiever", function() CustAc_ShowAchievement(id) end, data["icon"])
		end
		CustAc_LoadAchievementsData()
		if CustAc_AchievementFrameAchievements and CustAc_AchievementFrameAchievements:IsShown() then
			CustAc_AchievementFrameAchievements_Update()
		end
	end
end

function CustAc_ShowAchievement(id)
	if id and CustomAchieverData["Achievements"][id] then
		OpenAchievementFrameToAchievement(0)
		CustAc_AchievementFrame_SelectAchievement(id)
	end
end

function CustAc_GetAchievementCategory(id)
	local category
	if id and CustomAchieverData["Achievements"][id] then
		category = CustomAchieverData["Achievements"][id]["parent"]
	end
	return category
end

local function GetSafeScrollChildBottom(scrollChild)
	return scrollChild:GetBottom() or 0
end

function CustAc_AchievementFrame_SelectAchievement(id, forceSelect--[[, isComparison--]])
	if not AchievementFrame:IsShown() and not forceSelect then
		return
	end

	local category = CustAc_GetAchievementCategory(id)
	local _, _, _, achCompleted, _, _, _, _, flags, order = CustAc_GetAchievementInfoById(category, id)

	--if ( achCompleted and (ACHIEVEMENTUI_SELECTEDFILTER == AchievementFrameFilters[ACHIEVEMENT_FILTER_INCOMPLETE].func) ) then
	--	AchievementFrame_SetFilter(ACHIEVEMENT_FILTER_ALL)
	--elseif ( (not achCompleted) and (ACHIEVEMENTUI_SELECTEDFILTER == AchievementFrameFilters[ACHIEVEMENT_FILTER_COMPLETE].func) ) then
	--	AchievementFrame_SetFilter(ACHIEVEMENT_FILTER_ALL)
	--end

	local tabIndex = CustAc_AchievementTabId

	--if ( isComparison ) then
	--	AchievementFrameTab_OnClick = AchievementFrameComparisonTab_OnClick
	--else
	--	AchievementFrameTab_OnClick = AchievementFrameBaseTab_OnClick
	--end

	--AchievementFrameTab_OnClick(tabIndex)
	AchievementFrameTab_OnClick(1) -- to prevent IN_GUILD_VIEW
	CustAc_AchievementFrame_OnClick(tabIndex)
	AchievementFrameSummary:Hide()

	--if ( not isComparison ) then
		CustAc_AchievementFrameAchievements:Show()
	--end

	-- Figure out if this is part of a progressive achievement, if it is and it's incomplete, make sure the previous level was completed. If not, find the first incomplete achievement in the chain and display that instead.
	--id = AchievementFrame_FindDisplayedAchievement(id)
	id = order

	AchievementFrameCategories_ClearSelection()

	local categoryIndex, parent, hidden = 0
	for i, entry in next, CUSTOMACHIEVER_ACHIEVEMENTUI_CATEGORIES do
		if ( entry.id == category ) then
			parent = entry.parent
		end
	end

	for i, entry in next, CUSTOMACHIEVER_ACHIEVEMENTUI_CATEGORIES do
		if ( entry.id == parent ) then
			entry.collapsed = false
		elseif ( entry.parent == parent ) then
			entry.hidden = false
		elseif ( entry.parent == true ) then
			entry.collapsed = true
		elseif ( entry.parent ) then
			entry.hidden = true
		end
	end

	achievementFunctions.selectedCategory = category
	AchievementFrameCategoriesContainerScrollBar:SetValue(0)
	CustAc_AchievementFrameCategories_Update()

	local shown = false
	local found = false
	while ( not shown ) do
		found = false
		for _, button in next, AchievementFrameCategoriesContainer.buttons do
			if ( button.categoryID == category ) then
				found = true
			end
			if ( button.categoryID == category and math.ceil(button:GetBottom()) >= math.ceil(GetSafeScrollChildBottom(CustAc_AchievementFrameAchievementsContainerScrollChild)) ) then
				shown = true
			end
		end

		if ( not shown ) then
			local _, maxVal = AchievementFrameCategoriesContainerScrollBar:GetMinMaxValues()
			if ( AchievementFrameCategoriesContainerScrollBar:GetValue() == maxVal ) then
				--assert(false)
				if ( not found ) then
					return
				else
					shown = true
				end
			elseif AchievementFrameCategoriesContainerScrollBar:IsVisible() then
				HybridScrollFrame_OnMouseWheel(AchievementFrameCategoriesContainer, -1)
			else
				break
			end
		end
	end

	local container, child, scrollBar = CustAc_AchievementFrameAchievementsContainer, CustAc_AchievementFrameAchievementsContainerScrollChild, CustAc_AchievementFrameAchievementsContainerScrollBar
	--if ( isComparison ) then
	--	container = AchievementFrameComparisonContainer
	--	child = AchievementFrameComparisonContainerScrollChild
	--	scrollBar = AchievementFrameComparisonContainerScrollBar
	--end

	achievementFunctions.clearFunc()
	scrollBar:SetValue(0)
	achievementFunctions.updateFunc()

	local shown = false
	local previousScrollValue
	while ( not shown ) do
		for _, button in next, container.buttons do
			if ( button.id == id and math.ceil(button:GetTop()) >= math.ceil(GetSafeScrollChildBottom(child)) ) then
				--if ( not isComparison ) then
					-- The "True" here ignores modifiers, so you don't accidentally track or link this achievement. :P
					AchievementButton_OnClick(button, nil, nil, true)
				--end

				-- We found the button!
				shown = button
				break
			end
		end

		local _, maxVal = scrollBar:GetMinMaxValues()
		if ( shown ) then
			-- If we can, move the achievement we're scrolling to to the top of the screen.
			local newHeight = scrollBar:GetValue() + container:GetTop() - shown:GetTop()
			newHeight = min(newHeight, maxVal)
			scrollBar:SetValue(newHeight)
		else
			local scrollValue = scrollBar:GetValue()
			if ( scrollValue == maxVal or scrollValue == previousScrollValue ) then
				--assert(false, "Failed to find achievement " .. id .. " while jumping!")
				return
			else
				previousScrollValue = scrollValue
				HybridScrollFrame_OnMouseWheel(container, -1)
			end
		end
	end
end

CustAc_AchievementTabId = 4
function CustAc_AchievementFrame_Load()
	--if (not AchievementFrame) then
	--	AchievementFrame_LoadUI()
	--end

	if not CustAc_Categories then
		local numtabs, tab = 0
		repeat
			numtabs = numtabs + 1
		until (not _G["AchievementFrameTab"..numtabs])
		CustAc_AchievementTabId = numtabs
		tab = CreateFrame("Button", "AchievementFrameTab"..numtabs, AchievementFrame, "AchievementFrameTabButtonTemplate")
		tab:SetText("Custom Achiever")
		tab:SetPoint("LEFT", "AchievementFrameTab"..numtabs-1, "RIGHT", -5, 0)
		tab:SetID(numtabs)
		
		tab:SetScript("OnClick", function(self)
			CustAc_AchievementFrame_OnClick(self:GetID())
			PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB)
		end)
		
		PanelTemplates_SetNumTabs(AchievementFrame, numtabs)

		hooksecurefunc("AchievementFrame_UpdateTabs", CustAc_AchievementFrame_UpdateTabs)

		local categoriesFrame = CreateFrame("Frame", "CustAc_Categories", AchievementFrame, "CustAc_CategoriesTemplate")

		CustAc_CategoriesContainerScrollBar.Show =
			function (self)
				ACHIEVEMENTUI_CATEGORIESWIDTH = 175
				CustAc_Categories:SetWidth(175)
				CustAc_CategoriesContainer:GetScrollChild():SetWidth(175)
				CustAc_AchievementFrameAchievements:SetPoint("TOPLEFT", "CustAc_Categories", "TOPRIGHT", 22, 0)
				AchievementFrameStats:SetPoint("TOPLEFT", "CustAc_Categories", "TOPRIGHT", 22, 0)
				AchievementFrameComparison:SetPoint("TOPLEFT", "CustAc_Categories", "TOPRIGHT", 22, 0)
				AchievementFrameWaterMark:SetWidth(145)
				AchievementFrameWaterMark:SetTexCoord(0, 145/256, 0, 1)
				for _, button in next, CustAc_CategoriesContainer.buttons do
					CustAc_AchievementFrameCategories_DisplayButton(button, button.element)
				end
				getmetatable(self).__index.Show(self)
			end
		
		CustAc_CategoriesContainerScrollBar.Hide =
			function (self)
				ACHIEVEMENTUI_CATEGORIESWIDTH = 197
				CustAc_Categories:SetWidth(197)
				CustAc_CategoriesContainer:GetScrollChild():SetWidth(197)
				CustAc_AchievementFrameAchievements:SetPoint("TOPLEFT", "CustAc_Categories", "TOPRIGHT", 0, 0)
				AchievementFrameStats:SetPoint("TOPLEFT", "CustAc_Categories", "TOPRIGHT", 0, 0)
				AchievementFrameComparison:SetPoint("TOPLEFT", "CustAc_Categories", "TOPRIGHT", 0, 0)
				AchievementFrameWaterMark:SetWidth(167)
				AchievementFrameWaterMark:SetTexCoord(0, 167/256, 0, 1)
				for _, button in next, CustAc_CategoriesContainer.buttons do
					CustAc_AchievementFrameCategories_DisplayButton(button, button.element)
				end
				getmetatable(self).__index.Hide(self)
			end

		CustAc_CategoriesContainerScrollBarBG:Show()
		HybridScrollFrame_CreateButtons(CustAc_CategoriesContainer, "CustAc_AchievementCategoryTemplate", 0, 0, "TOP", "TOP", 0, 0, "TOP", "BOTTOM")

		local achievementsFrame = CreateFrame("Frame", "CustAc_AchievementFrameAchievements", AchievementFrame, "CustAc_AchievementFrameAchievementsTemplate")

		CustAc_AchievementFrameAchievementsContainerScrollBar.Show =
			function (self)
				CustAc_AchievementFrameAchievements:SetWidth(504)
				for _, button in next, CustAc_AchievementFrameAchievementsContainer.buttons do
					button:SetWidth(496)
				end
				getmetatable(self).__index.Show(self)
			end

		CustAc_AchievementFrameAchievementsContainerScrollBar.Hide =
			function (self)
				CustAc_AchievementFrameAchievements:SetWidth(530)
				for _, button in next, CustAc_AchievementFrameAchievementsContainer.buttons do
					button:SetWidth(522)
				end
				getmetatable(self).__index.Hide(self)
			end

		CustAc_AchievementFrameAchievementsContainerScrollBarBG:Show()
		CustAc_AchievementFrameAchievementsContainer.update = CustAc_AchievementFrameAchievements_Update
		HybridScrollFrame_CreateButtons(CustAc_AchievementFrameAchievementsContainer, "CustAc_AchievementTemplate", 0, -2)

		tinsert(ACHIEVEMENTFRAME_SUBFRAMES, "CustAc_AchievementFrameAchievements")
	end

	CustAc_UpdateCategory("CustomAchiever", nil, "Custom Achiever")
	CustAc_UpdateAchievement("CustomAchiever1", "CustomAchiever", 975739,  10, "Bonne installation !", "Intaller Custom Achiever.", "frFR")
	CustAc_UpdateAchievement("CustomAchiever1", "CustomAchiever",    nil, nil, "Happy move in!", "Install Custom Achiever.", "enUS")
	CustAc_CompleteAchievement("CustomAchiever1")
	CustAc_UpdateAchievement("CustomAchiever2", "CustomAchiever", 133053,  10, "Un petit pas pour Azeroth...", "Créer votre premier Haut fait.", "frFR")
	CustAc_UpdateAchievement("CustomAchiever2", "CustomAchiever",    nil, nil, "One small step for Azeroth...", "Create your first Achievement.", "enUS")
	--CustAc_LoadAchievementsData()
end

function CustAc_GetAchievement(achievement)
	if achievement then
		local data = {}
		data["id"] = achievement["id"]
		data["name"] = achievement["name_"..GetLocale()] or achievement["name_enUS"] or achievement["name_enGB"] or achievement["name_frFR"] or achievement["name_deDE"] or achievement["name_esES"] or achievement["name_esMX"] or achievement["name_itIT"] or achievement["name_koKR"] or achievement["name_ptBR"] or achievement["name_ruRU"] or achievement["name_zhCN"] or achievement["name_zhTW"]
		data["description"] = achievement["desc_"..GetLocale()] or achievement["desc_enUS"] or achievement["desc_enGB"] or achievement["desc_frFR"] or achievement["desc_deDE"] or achievement["desc_esES"] or achievement["desc_esMX"] or achievement["desc_itIT"] or achievement["desc_koKR"] or achievement["desc_ptBR"] or achievement["desc_ruRU"] or achievement["desc_zhCN"] or achievement["desc_zhTW"]
		data["points"] = achievement["points"]
		data["completed"] = achievement["completed"][CustAc_playerCharacter()] or achievement["firstAchiever"]
		local custacDate = (achievement["firstAchiever"] and achievement["date"][achievement["firstAchiever"]]) or achievement["date"][CustAc_playerCharacter()]
		if custacDate then
			local month, day, year = custacDate.month, custacDate.monthDay, custacDate.year
			data["month"] = month
			data["day"] = day
			data["year"] = year
		end
		data["flags"] = achievement["flags"]
		data["icon"] = achievement["icon"]
		data["rewardText"] = achievement["rewardText"]
		data["isGuild"] = achievement["isGuild"]
		data["wasEarnedByMe"] = achievement["completed"][CustAc_playerCharacter()]
		data["earnedBy"] = (achievement["completed"][CustAc_playerCharacter()] and CustAc_playerCharacter()) or achievement["firstAchiever"]
		if not CUSTOMACHIEVER_ACHIEVEMENTS[achievement["parent"]] then
			CUSTOMACHIEVER_ACHIEVEMENTS[achievement["parent"]] = {}
		end
		tinsert(CUSTOMACHIEVER_ACHIEVEMENTS[achievement["parent"]], data)
	end
end

function CustAc_AchievementFrame_ToggleView()
	--IN_GUILD_VIEW = nil
	TEXTURES_OFFSET = 0
	-- container backgrounds
	CustAc_AchievementFrameAchievementsBackground:SetTexCoord(0, 1, 0, 0.5)
	--AchievementFrameSummaryBackground:SetTexCoord(0, 1, 0, 0.5)
	-- header
	AchievementFrameHeaderPoints:SetVertexColor(1, 1, 1)
	AchievementFrameHeaderTitle:SetText("Custom Achiever")
	local shield = AchievementFrameHeaderShield
	shield:SetTexture("Interface\\AchievementFrame\\UI-Achievement-TinyShield")
	shield:SetTexCoord(0, 0.625, 0, 0.625)
	shield:SetHeight(20)
	
	AchievementFrameHeaderPoints:SetText(BreakUpLargeNumbers(CustAc_GetTotalAchievementPoints()))
end

function CustAc_GetTotalAchievementPoints()
	local totalAchievementPoints = 0
	for k,v in pairs(CustomAchieverData["Achievements"]) do
		if v["firstAchiever"] then
			totalAchievementPoints = totalAchievementPoints + v["points"]
		end
	end
	return totalAchievementPoints
end


function CustAc_AchievementFrame_UpdateTabs(clickedTab)
	AchievementFrameCategories:Show()
	CustAc_Categories:Hide()
	local tab = _G["AchievementFrameTab"..CustAc_AchievementTabId]
	if tab then
		if (CustAc_AchievementTabId == clickedTab) then
			tab.text:SetPoint("CENTER", 0, -5)
		else
			tab.text:SetPoint("CENTER", 0, -3)
			if 1 == clickedTab then
				-- header
				AchievementFrameHeaderTitle:SetText(ACHIEVEMENT_TITLE)
				AchievementFrameHeaderPoints:SetText(BreakUpLargeNumbers(GetTotalAchievementPoints()))
			end
		end
	end
end

function CustAc_AchievementFrame_OnClick(clickedTab)
	AchievementFrameTab_OnClick(1) -- to prevent IN_GUILD_VIEW
	AchievementFrame_UpdateTabs(clickedTab)
	CustAc_Categories:Show()
	AchievementFrameCategories:Hide()
	--AchievementFrameAchievements:Hide()
	AchievementFrame_ShowSubFrame(CustAc_AchievementFrameAchievements)

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

	CustAc_AchievementFrameCategories_Update()

	--if ( not isSummary ) then
		achievementFunctions.updateFunc()
	--end

	--SwitchAchievementSearchTab(clickedTab)
	AchievementFrameFilterDropDown:Hide()
	AchievementFrameHeaderLeftDDLInset:Hide()
end

local displayCategories = {}
function CustAc_AchievementFrameCategories_Update()
	local scrollFrame = CustAc_CategoriesContainer

	local categories = CUSTOMACHIEVER_ACHIEVEMENTUI_CATEGORIES
	local offset = HybridScrollFrame_GetOffset(scrollFrame)
	local buttons = scrollFrame.buttons

	local displayCategories = displayCategories

	for i in next, displayCategories do
		displayCategories[i] = nil
	end

	local selection = achievementFunctions.selectedCategory
	
	local parent
	if ( selection ) then
		for i, category in next, categories do
			if ( category.id == selection ) then
				parent = category.parent
			end
		end
	end
	
	for i, category in next, categories do
		if ( not category.hidden ) then
			tinsert(displayCategories, category)
		elseif ( parent and category.id == parent ) then
			category.collapsed = false
			tinsert(displayCategories, category)
		elseif ( parent and category.parent and category.parent == parent ) then
			category.hidden = false
			tinsert(displayCategories, category)
		end
	end

	local numCategories = #displayCategories
	local numButtons = #buttons

	local totalHeight = numCategories * buttons[1]:GetHeight()
	local displayedHeight = 0

	local element
	for i = 1, numButtons do
		element = displayCategories[i + offset]
		displayedHeight = displayedHeight + buttons[i]:GetHeight()
		if ( element ) then
			CustAc_AchievementFrameCategories_DisplayButton(buttons[i], element)
			if ( selection and element.id == selection ) then
				buttons[i]:LockHighlight()
			else
				buttons[i]:UnlockHighlight()
			end
			buttons[i]:Show()
		else
			buttons[i].element = nil
			buttons[i]:Hide()
		end
	end

	HybridScrollFrame_Update(scrollFrame, totalHeight, displayedHeight)
	
	return displayCategories
end

function CustAc_AchievementFrameCategories_DisplayButton(button, element)
	if ( not element ) then
		button.element = nil
		button:Hide()
		return
	end

	button:Show()
	if ( type(element.parent) == "string" ) then
		button:SetWidth(ACHIEVEMENTUI_CATEGORIESWIDTH - 25)
		button.label:SetFontObject("GameFontHighlight")
		button.parentID = element.parent
		button.background:SetVertexColor(0.6, 0.6, 0.6)
	else
		button:SetWidth(ACHIEVEMENTUI_CATEGORIESWIDTH - 10)
		button.label:SetFontObject("GameFontNormal")
		button.parentID = element.parent
		button.background:SetVertexColor(1, 1, 1)
	end

	local categoryName, parentID, flags
	local numAchievements, numCompleted

	local id = element.id

	-- kind of janky
	--if ( id == "summary" ) then
	--	categoryName = ACHIEVEMENT_SUMMARY_CATEGORY
	--	numAchievements, numCompleted = 10,2 -- TODO GetNumCompletedAchievements(IN_GUILD_VIEW)
	--else
		categoryName = CUSTOMACHIEVER_CATEGORIES[id]["categoryName"]
		parentID = CUSTOMACHIEVER_CATEGORIES[id]["parentID"]
		flags = CUSTOMACHIEVER_CATEGORIES[id]["flags"]
		numAchievements, numCompleted = 10,3-- AchievementFrame_GetCategoryTotalNumAchievements(id, true)
	--end
	button.label:SetText(categoryName)
	button.categoryID = id
	button.flags = flags
	button.element = element

	-- For the tooltip
	button.name = categoryName
	if ( id == FEAT_OF_STRENGTH_ID ) then
		-- This is the feat of strength category since it's sorted to the end of the list
		button.text = FEAT_OF_STRENGTH_DESCRIPTION
		button.showTooltipFunc = AchievementFrameCategory_FeatOfStrengthTooltip
	elseif ( id == GUILD_FEAT_OF_STRENGTH_ID ) then
		button.text = GUILD_FEAT_OF_STRENGTH_DESCRIPTION
		button.showTooltipFunc = AchievementFrameCategory_FeatOfStrengthTooltip
	elseif ( AchievementFrame.selectedTab == 1 or AchievementFrame.selectedTab == 2 ) then
		button.text = nil
		button.numAchievements = numAchievements
		button.numCompleted = numCompleted
		button.numCompletedText = numCompleted.."/"..numAchievements
		button.showTooltipFunc = AchievementFrameCategory_StatusBarTooltip
	else
		button.showTooltipFunc = nil
	end
end

function CustAc_AchievementCategoryButton_OnClick(button)
	CustAc_AchievementFrameCategories_SelectButton(button)
	CustAc_AchievementFrameCategories_Update()
end

function CustAc_AchievementFrameCategories_SelectButton(button)
	local id = button.element.id

	if ( type(button.element.parent) ~= "string" ) then
		-- Is top level category (can expand/contract)
		if ( button.isSelected and button.element.collapsed == false ) then
			button.element.collapsed = true
			for i, category in next, CUSTOMACHIEVER_ACHIEVEMENTUI_CATEGORIES do
				if ( category.parent == id ) then
					category.hidden = true
				end
			end
		else
			for i, category in next, CUSTOMACHIEVER_ACHIEVEMENTUI_CATEGORIES do
				if ( category.parent == id ) then
					category.hidden = false
				elseif ( category.parent == true ) then
					category.collapsed = true
				elseif ( category.parent ) then
					category.hidden = true
				end
			end
			button.element.collapsed = false
		end
	end

	local buttons = CustAc_CategoriesContainer.buttons
	for _, button in next, buttons do
		button.isSelected = nil
	end

	button.isSelected = true

	if ( id == achievementFunctions.selectedCategory ) then
		-- If this category was selected already, bail after changing collapsed states
		return
	end

	--Intercept "summary" category
	--if ( id == "summary" ) then
		--AchievementFrame_ShowSubFrame(AchievementFrameSummary)
	--	achievementFunctions.selectedCategory = id
	--	return
	--else
		--AchievementFrameFilterDropDown:Hide()
		--AchievementFrameHeaderLeftDDLInset:Hide()
		achievementFunctions.selectedCategory = id
	--end

	CustAc_AchievementFrameAchievementsContainerScrollBar:SetValue(0)
	CustAc_AchievementFrameAchievements_Update()
end

function CustAc_AchievementFrameAchievements_Update()
	local category = achievementFunctions.selectedCategory
	--if ( category == "summary" ) then
	--	return
	--end
	local scrollFrame = CustAc_AchievementFrameAchievementsContainer

	local offset = HybridScrollFrame_GetOffset(scrollFrame)
	local buttons = scrollFrame.buttons
	local numAchievements, numCompleted, completedOffset = CustAc_AchievementFrame_GetCategoryNumAchievements_All(category)
	local numButtons = #buttons

	-- If the current category is feats of strength and there are no entries then show the explanation text
	if ( AchievementFrame_IsFeatOfStrength() and numAchievements == 0 ) then
		if ( AchievementFrame.selectedTab == 1 ) then
			CustAc_AchievementFrameAchievementsFeatOfStrengthText:SetText(FEAT_OF_STRENGTH_DESCRIPTION)
		else
			CustAc_AchievementFrameAchievementsFeatOfStrengthText:SetText(GUILD_FEAT_OF_STRENGTH_DESCRIPTION)
		end
		CustAc_AchievementFrameAchievementsFeatOfStrengthText:Show()
	else
		CustAc_AchievementFrameAchievementsFeatOfStrengthText:Hide()
	end

	local selection = CustAc_AchievementFrameAchievements.selection
	if ( selection ) then
		AchievementButton_ResetObjectives()
	end

	local extraHeight = scrollFrame.largeButtonHeight or ACHIEVEMENTBUTTON_COLLAPSEDHEIGHT

	local achievementIndex
	local displayedHeight = 0
	for i = 1, numButtons do
		achievementIndex = i + offset + completedOffset
		if ( achievementIndex > numAchievements + completedOffset ) then
			buttons[i]:Hide()
		else
			CustAc_AchievementButton_DisplayAchievement(buttons[i], category, achievementIndex, selection)
			displayedHeight = displayedHeight + buttons[i]:GetHeight()
		end
	end

	local totalHeight = numAchievements * ACHIEVEMENTBUTTON_COLLAPSEDHEIGHT
	totalHeight = totalHeight + (extraHeight - ACHIEVEMENTBUTTON_COLLAPSEDHEIGHT)

	HybridScrollFrame_Update(scrollFrame, totalHeight, displayedHeight)

	if ( selection ) then
		CustAc_AchievementFrameAchievements.selection = selection
	else
		HybridScrollFrame_CollapseButton(scrollFrame)
	end
end

function CustAc_AchievementFrame_GetCategoryNumAchievements_All(categoryID)
	local numAchievements, numCompleted, numIncomplete = 0, 0, 0 -- TODO GetCategoryNumAchievements(categoryID)

	if CUSTOMACHIEVER_ACHIEVEMENTS and CUSTOMACHIEVER_ACHIEVEMENTS[categoryID] then
		for _, values in pairs(CUSTOMACHIEVER_ACHIEVEMENTS[categoryID]) do
			numAchievements = numAchievements + 1
			if values["completed"] then
				numCompleted = numCompleted + 1
			end
		end
	end

	return numAchievements, numCompleted, 0
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

function CustAc_AchievementButton_DisplayAchievement(button, category, achievement, selectionID, renderOffScreen)
	local id, name, points, completed, month, day, year, description, flags, icon, rewardText, isGuild, wasEarnedByMe, earnedBy = CustAc_GetAchievementInfoByOrder(category, achievement)

	if ( not id ) then
		button:Hide()
		return
	else
		button:Show()
	end

	button.index = achievement
	button.element = true

	if ( button.id ~= id ) then
		local saturatedStyle
		if ( bit.band(flags, ACHIEVEMENT_FLAGS_ACCOUNT) == ACHIEVEMENT_FLAGS_ACCOUNT ) then
			button.accountWide = true
			saturatedStyle = "account"
		else
			button.accountWide = nil
			--if ( IN_GUILD_VIEW ) then
			--	saturatedStyle = "guild"
			--else
				saturatedStyle = "normal"
			--end
		end
		button.id = id
		button.label:SetWidth(ACHIEVEMENTBUTTON_LABELWIDTH)
		button.label:SetText(name)

		--if ( GetPreviousAchievement(id) ) then
			-- If this is a progressive achievement, show the total score.
		--	AchievementShield_SetPoints(AchievementButton_GetProgressivePoints(id), button.shield.points, AchievementPointsFont, AchievementPointsFontSmall)
		--else
			AchievementShield_SetPoints(points, button.shield.points, AchievementPointsFont, AchievementPointsFontSmall)
		--end

		if ( points > 0 ) then
			button.shield.icon:SetTexture([[Interface\AchievementFrame\UI-Achievement-Shields]])
		else
			button.shield.icon:SetTexture([[Interface\AchievementFrame\UI-Achievement-Shields-NoPoints]])
		end

		if ( isGuild ) then
			button.shield.points:Show()
			button.shield.wasEarnedByMe = nil
			button.shield.earnedBy = nil
		else
			button.shield.wasEarnedByMe = not (completed and not wasEarnedByMe)
			button.shield.earnedBy = earnedBy
		end

		button.shield.id = id
		button.description:SetText(description)
		button.hiddenDescription:SetText(description)
		local _, fontHeight = button.description:GetFont()
		button.numLines = ceil(button.hiddenDescription:GetHeight() / fontHeight)
		button.icon.texture:SetTexture(icon)
		if ( completed or wasEarnedByMe ) then
			button.completed = true
			button.dateCompleted:SetText(FormatShortDate(day, month, year))
			button.dateCompleted:Show()
			if ( button.saturatedStyle ~= saturatedStyle ) then
				button:Saturate()
			end
		else
			button.completed = nil
			button.dateCompleted:Hide()
			button:Desaturate()
		end

		if ( rewardText == "" ) then
			button.reward:Hide()
			button.rewardBackground:Hide()
		else
			button.reward:SetText(rewardText)
			button.reward:Show()
			button.rewardBackground:Show()
			if ( button.completed ) then
				button.rewardBackground:SetVertexColor(1, 1, 1)
			else
				button.rewardBackground:SetVertexColor(0.35, 0.35, 0.35)
			end
		end

		--[[
		if ( IsTrackedAchievement(id) ) then
			button.check:Show()
			button.label:SetWidth(button.label:GetStringWidth() + 4) -- This +4 here is to fudge around any string width issues that arize from resizing a string set to its string width. See bug 144418 for an example.
			button.tracked:SetChecked(true)
			button.tracked:Show()
		else
		--]]
			button.check:Hide()
			button.tracked:SetChecked(false)
			button.tracked:Hide()
		--[[
		end
		--]]

		--AchievementButton_UpdatePlusMinusTexture(button)
	end

	if ( id == selectionID ) then
		local achievements = CustAc_AchievementFrameAchievements

		achievements.selection = button.id
		achievements.selectionIndex = button.index
		button.selected = true
		button.highlight:Show()
		local height = ACHIEVEMENTBUTTON_COLLAPSEDHEIGHT--AchievementButton_DisplayObjectives(button, button.id, button.completed, renderOffScreen)
		if ( height == ACHIEVEMENTBUTTON_COLLAPSEDHEIGHT ) then
			button:Collapse()
		else
			button:Expand(height)
		end
		--if ( not completed or (not wasEarnedByMe and not isGuild) ) then
		--	button.tracked:Show()
		--end
	elseif ( button.selected ) then
		button.selected = nil
		if ( not button:IsMouseOver() ) then
			button.highlight:Hide()
		end
		button:Collapse()
		button.description:Show()
		button.hiddenDescription:Hide()
	end

	return id
end

function CustAc_AchievementFrameAchievements_OnShow()
	CustAc_AchievementFrameAchievements.guildView = nil
	for _, button in next, CustAc_AchievementFrameAchievementsContainer.buttons do
		AchievementFrameAchievements_SetupButton(button)
	end
	CustAc_AchievementFrameAchievementsContainerScrollBar:SetValue(0)
	CustAc_AchievementFrameAchievements_Update()
end

function CustAc_AchievementButton_OnLoad(self)
	self.dateCompleted = self.shield.dateCompleted
	if ( not ACHIEVEMENTUI_FONTHEIGHT ) then
		local _, fontHeight = self.description:GetFont()
		ACHIEVEMENTUI_FONTHEIGHT = fontHeight
	end
	self.description:SetHeight(ACHIEVEMENTUI_FONTHEIGHT * ACHIEVEMENTUI_MAX_LINES_COLLAPSED)
	self.description:SetWidth(ACHIEVEMENTUI_MAXCONTENTWIDTH)
	self.hiddenDescription:SetWidth(ACHIEVEMENTUI_MAXCONTENTWIDTH)

	self.Collapse = AchievementButton_Collapse
	self.Expand = AchievementButton_Expand
	self.Saturate = CustAc_AchievementButton_Saturate
	self.Desaturate = CustAc_AchievementButton_Desaturate

	self:Collapse()
end

function CustAc_AchievementButton_Saturate(self)
	--if ( IN_GUILD_VIEW ) then
	--	self.background:SetTexture("Interface\\AchievementFrame\\UI-GuildAchievement-Parchment-Horizontal")
	--	self.titleBar:SetTexture("Interface\\AchievementFrame\\UI-Achievement-Borders")
	--	self.titleBar:SetTexCoord(0, 1, 0.83203125, 0.91015625)
	--	self:SetBackdropBorderColor(ACHIEVEMENT_RED_BORDER_COLOR:GetRGB())
	--	self.shield.points:SetVertexColor(0, 1, 0)
	--	self.saturatedStyle = "guild"
	--else
		self.background:SetTexture("Interface\\AchievementFrame\\UI-Achievement-Parchment-Horizontal")
		if ( self.accountWide ) then
			self.titleBar:SetTexture("Interface\\AchievementFrame\\AccountLevel-AchievementHeader")
			self.titleBar:SetTexCoord(0, 1, 0, 0.375)
			self:SetBackdropBorderColor(ACHIEVEMENT_BLUE_BORDER_COLOR:GetRGB())
			self.saturatedStyle = "account"
		else
			self.titleBar:SetTexture("Interface\\AchievementFrame\\UI-Achievement-Borders")
			self.titleBar:SetTexCoord(0, 1, 0.66015625, 0.73828125)
			self:SetBackdropBorderColor(ACHIEVEMENT_RED_BORDER_COLOR:GetRGB())
			self.saturatedStyle = "normal"
		end
		self.shield.points:SetVertexColor(1, 1, 1)
	--end
	self.glow:SetVertexColor(1.0, 1.0, 1.0)
	self.icon:Saturate()
	self.shield:Saturate()
	self.reward:SetVertexColor(1, .82, 0)
	self.label:SetVertexColor(1, 1, 1)
	self.description:SetTextColor(0, 0, 0, 1)
	self.description:SetShadowOffset(0, 0)
	--AchievementButton_UpdatePlusMinusTexture(self)
end

function CustAc_AchievementButton_Desaturate (self)
	self.saturatedStyle = nil
	--if ( IN_GUILD_VIEW ) then
	--	self.background:SetTexture("Interface\\AchievementFrame\\UI-GuildAchievement-Parchment-Horizontal-Desaturated")
	--	self.titleBar:SetTexture("Interface\\AchievementFrame\\UI-Achievement-Borders")
	--	self.titleBar:SetTexCoord(0, 1, 0.74609375, 0.82421875)
	--else
		self.background:SetTexture("Interface\\AchievementFrame\\UI-Achievement-Parchment-Horizontal-Desaturated")
		if ( self.accountWide ) then
			self.titleBar:SetTexture("Interface\\AchievementFrame\\AccountLevel-AchievementHeader")
			self.titleBar:SetTexCoord(0, 1, 0.40625, 0.78125)
		else
			self.titleBar:SetTexture("Interface\\AchievementFrame\\UI-Achievement-Borders")
			self.titleBar:SetTexCoord(0, 1, 0.91796875, 0.99609375)
		end
	--end
	self.glow:SetVertexColor(.22, .17, .13)
	self.icon:Desaturate()
	self.shield:Desaturate()
	self.shield.points:SetVertexColor(.65, .65, .65)
	self.reward:SetVertexColor(.8, .8, .8)
	self.label:SetVertexColor(.65, .65, .65)
	self.description:SetTextColor(1, 1, 1, 1)
	self.description:SetShadowOffset(1, -1)
	--AchievementButton_UpdatePlusMinusTexture(self)
	self:SetBackdropBorderColor(.5, .5, .5)
end

function CustAc_AchievementButton_OnClick(self, button, down, ignoreModifiers)
	--[[
	if(IsModifiedClick() and not ignoreModifiers) then
		local handled = nil
		if ( IsModifiedClick("CHATLINK") ) then
			local achievementLink = GetAchievementLink(self.id)
			if ( achievementLink ) then
				handled = ChatEdit_InsertLink(achievementLink)
				if ( not handled and SocialPostFrame and Social_IsShown() ) then
					Social_InsertLink(achievementLink)
					handled = true
				end
			end
		end
		if ( not handled and IsModifiedClick("QUESTWATCHTOGGLE") ) then
			AchievementButton_ToggleTracking(self.id)
		end
		return
	end
	--]]
	if ( self.selected ) then
		if ( not self:IsMouseOver() ) then
			self.highlight:Hide()
		end
		CustAc_AchievementFrameAchievements_ClearSelection()
		HybridScrollFrame_CollapseButton(CustAc_AchievementFrameAchievementsContainer)
		CustAc_AchievementFrameAchievements_Update()
		return
	end
	CustAc_AchievementFrameAchievements_ClearSelection()
	CustAc_AchievementFrameAchievements_SelectButton(self)
	CustAc_AchievementButton_DisplayAchievement(self, achievementFunctions.selectedCategory, self.index, self.id)
	HybridScrollFrame_ExpandButton(CustAc_AchievementFrameAchievementsContainer, ((self.index - 1) * ACHIEVEMENTBUTTON_COLLAPSEDHEIGHT), self:GetHeight())
	CustAc_AchievementFrameAchievements_Update()
	--if ( not ignoreModifiers ) then
	--	AchievementFrameAchievements_AdjustSelection()
	--end
end

function CustAc_AchievementFrameAchievements_SelectButton(button)
	local achievements = CustAc_AchievementFrameAchievements

	achievements.selection = button.id
	achievements.selectionIndex = button.index
	button.selected = true

	SetFocusedAchievement(button.id)
end


function CustAc_AchievementFrameAchievements_ClearSelection()
	AchievementButton_ResetObjectives()
	for _, button in next, CustAc_AchievementFrameAchievementsContainer.buttons do
		button:Collapse()
		if ( not button:IsMouseOver() ) then
			button.highlight:Hide()
		end
		button.selected = nil
		if ( not button.tracked:GetChecked() ) then
			button.tracked:Hide()
		end
		button.description:Show()
		button.hiddenDescription:Hide()
	end

	CustAc_AchievementFrameAchievements.selection = nil
end

CUSTOMACHIEVER_ACHIEVEMENT_FUNCTIONS = {
	--categoryAccessor = GetCategoryList,
	clearFunc = CustAc_AchievementFrameAchievements_ClearSelection,
	updateFunc = CustAc_AchievementFrameAchievements_Update,
	selectedCategory = "CustomAchiever"
}
