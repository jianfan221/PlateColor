local addonName, ns = ...
local L = ns.L

-- 姓名板上方 topMine 组的 dot 法术监控列表设置窗口。
-- 列表存于 PlateColorDB.topDotList，结构为 { [spellID] = { name=..., show=true } }。
-- 仅 show=true 的法术会加入 topMine 组的 includeSpellIDs 过滤（显示在姓名板上方）。
-- 增删/切换显示时调用 ns.RebuildTopMineFilter() 更新各姓名板容器（定义见 PlateAuras.lua）。

local function GetSpellDisplayName(spellId)
	if not spellId then
		return nil
	end

	local spellName = C_Spell.GetSpellName(spellId)
	if spellName and spellName ~= "" then
		return spellName
	end

	local spellInfo = C_Spell.GetSpellInfo(spellId)
	if spellInfo and spellInfo.name and spellInfo.name ~= "" then
		return spellInfo.name
	end

	return nil
end

local function NormalizeSpellId(text)
	if not text then
		return nil
	end

	local spellId = tonumber(text)
	if spellId then
		return spellId
	end

	local resolvedId = C_Spell.GetSpellIDForSpellIdentifier(text)
	if resolvedId and resolvedId > 0 then
		return resolvedId
	end

	return nil
end

local function BuildSpellRows()
	local rows = {}
	for spellId in pairs(PlateColorDB.topDotList or {}) do
		rows[#rows + 1] = spellId
	end

	table.sort(rows, function(a, b)
		return tonumber(a) < tonumber(b)
	end)

	return rows
end

local function MatchSearch(spellId, searchText)
	if not searchText or searchText == "" then
		return true
	end

	local spellName = GetSpellDisplayName(spellId) or ""
	local spellIdText = tostring(spellId)
	local needle = string.lower(searchText)
	return string.find(string.lower(spellIdText), needle, 1, true) or string.find(string.lower(spellName), needle, 1, true)
end

local function EnsureWindow()
	if _G.PlateAurasListFrame then
		return _G.PlateAurasListFrame
	end

	local frame = CreateFrame("Frame", "PlateAurasListFrame", UIParent, "BackdropTemplate")
	frame:SetSize(440, 430)
	frame:SetPoint("CENTER")
	frame:SetFrameStrata("DIALOG")
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
	frame:SetClampedToScreen(true)
	frame:Hide()
	frame:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 },
	})
	frame:SetBackdropColor(0.08, 0.08, 0.08, 1)
	frame:SetAlpha(1)

	local background = frame:CreateTexture(nil, "BACKGROUND")
	background:SetAllPoints(frame)
	background:SetColorTexture(0.08, 0.08, 0.08, 1)

	local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
	title:SetPoint("TOP", 0, -8)
	title:SetText(L["上方减益过滤器"])

	-- 左上角：鼠标提示显示法术ID开关（勾选状态由 cvar 决定，点击临时切换不持久）
	local spellIDCheck = CreateFrame("CheckButton", nil, frame, "InterfaceOptionsCheckButtonTemplate")
	spellIDCheck:SetPoint("TOPLEFT", 8, -4)
	spellIDCheck:SetSize(30, 30)
	local function RefreshSpellIDCheck()
		spellIDCheck:SetChecked(GetCVar("tooltipShowAuraSpellIDs") == "1")
	end
	RefreshSpellIDCheck()

	-- cvar 变化时同步勾选状态（如通过其他入口/宏修改时保持显示一致）
	ns.hookcvar("tooltipShowAuraSpellIDs", RefreshSpellIDCheck)

	spellIDCheck:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:SetText("|cffFFFFFF"..L["鼠标提示显示法术ID"].."|r",1,1,1,1)
		GameTooltip:Show()
	end)
	spellIDCheck:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	spellIDCheck:SetScript("OnClick", function()
		-- 点击后写入 cvar，控制"鼠标提示显示法术ID"
		C_CVar.SetCVar("tooltipShowAuraSpellIDs", spellIDCheck:GetChecked() and "1" or "0")
	end)

	-- 按钮右侧文本
	local spellIDLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	spellIDLabel:SetPoint("LEFT", spellIDCheck, "RIGHT", 2, 0)
	spellIDLabel:SetText(L["显示法术ID"])

	local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	hint:SetPoint("TOPLEFT", 16, -32)
	hint:SetText(L["添加你需要显示或隐藏的dot法术ID"])

	local searchBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
	searchBox:SetSize(240, 24)
	searchBox:SetPoint("TOPLEFT", 16, -52)
	searchBox:SetAutoFocus(false)
	searchBox:SetTextInsets(8, 8, 4, 4)
	searchBox:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
		self:SetText("")
		self:GetParent():RefreshList()
	end)
	searchBox:SetScript("OnEnterPressed", function(self)
		local parent = self:GetParent()
		local input = self:GetText()
		local spellId = NormalizeSpellId(input)
		if spellId then
			local spellName = GetSpellDisplayName(spellId)
			if spellName then
				PlateColorDB.topDotList[spellId] = { name = spellName, show = true, hide = false }
				self:SetText("")
				parent:RefreshList()
				if ns.RebuildTopDotFilters then ns.RebuildTopDotFilters() end
				return
			end
		end
		self:ClearFocus()
		parent:RefreshList()
	end)
	searchBox:SetScript("OnTextChanged", function(self)
		self:GetParent():RefreshList()
	end)

	local addButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	addButton:SetSize(80, 24)
	addButton:SetPoint("LEFT", searchBox, "RIGHT", 10, 0)
	addButton:SetText(ADD)

	local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	closeButton:SetPoint("TOPRIGHT", 2, 2)

	local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "ScrollFrameTemplate")
	scrollFrame:SetPoint("TOPLEFT", 16, -84)
	scrollFrame:SetPoint("BOTTOMRIGHT", -30, 16)
	local content = CreateFrame("Frame", nil, scrollFrame)
	content:SetSize(1, 1)
	scrollFrame:SetScrollChild(content)

	local header = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	header:SetPoint("TOPLEFT", 20, 0)
	header:SetText("ID")
	header:SetWidth(60)
	header:SetJustifyH("LEFT")

	local headerName = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	headerName:SetPoint("TOPLEFT", 95, 0)
	headerName:SetText(SPELLS .. NAME)
	headerName:SetWidth(130)
	headerName:SetJustifyH("LEFT")

	local headerShow = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	headerShow:SetPoint("TOPLEFT", 200, 0)
	headerShow:SetText(L["显示"])
	headerShow:SetWidth(55)
	headerShow:SetJustifyH("LEFT")

	local headerHide = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	headerHide:SetPoint("TOPLEFT", 270, 0)
	headerHide:SetText(L["隐藏"])
	headerHide:SetWidth(55)
	headerHide:SetJustifyH("LEFT")

	local headerAction = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	headerAction:SetPoint("TOPLEFT", 330, 0)
	headerAction:SetText(DELETE)
	headerAction:SetWidth(60)
	headerAction:SetJustifyH("LEFT")

	frame.rows = {}
	frame.searchBox = searchBox
	frame.scrollFrame = scrollFrame
	frame.content = content

	local function ClearRows()
		for _, row in ipairs(frame.rows) do
			row:Hide()
			row:SetParent(nil)
		end
		wipe(frame.rows)
	end

	function frame:RefreshList()
		ClearRows()

		local searchText = self.searchBox:GetText()
		local rowCount = 0
		local lastRow

		for _, spellId in ipairs(BuildSpellRows()) do
			if MatchSearch(spellId, searchText) then
				rowCount = rowCount + 1
				local row = CreateFrame("Frame", nil, self.content)
				row:SetSize(400, 24)
				if lastRow then
					row:SetPoint("TOPLEFT", lastRow, "BOTTOMLEFT", 0, -4)
				else
					row:SetPoint("TOPLEFT", 0, -24)
				end

				local bg = row:CreateTexture(nil, "BACKGROUND")
				bg:SetAllPoints(row)
				bg:SetColorTexture(0.5, 0.5, 0.5, 1)

				local function SetRowHighlighted(highlighted)
					if highlighted then
						bg:SetColorTexture(0.75, 0.75, 0.75, 1)
					else
						bg:SetColorTexture(0.5, 0.5, 0.5, 1)
					end
				end

				local idText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
				idText:SetPoint("LEFT", 20, 0)
				idText:SetWidth(60)
				idText:SetJustifyH("LEFT")
				idText:SetText(tostring(spellId))

				local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
				nameText:SetPoint("LEFT", 95, 0)
				nameText:SetWidth(130)
				nameText:SetJustifyH("LEFT")
				nameText:SetText(GetSpellDisplayName(spellId) or UNKNOWN)

				local info = PlateColorDB.topDotList[spellId]

				-- 显示/隐藏完全互斥：显示→topMine，隐藏→从topShown排除，勾选其一必取消另一
				-- 先声明两个局部变量再赋值，否则闭包中引用后声明的 hideCheck 会是全局 nil（Lua 5.1 作用域）
				local showCheck, hideCheck
				showCheck = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
				showCheck:SetPoint("LEFT", 200, 0)
				showCheck:SetSize(24, 24)
				showCheck:SetChecked(info.show)
				showCheck:SetScript("OnClick", function(self)
					info.show = self:GetChecked()
					if info.show then
						info.hide = false
						hideCheck:SetChecked(false)
					end
					if ns.RebuildTopDotFilters then ns.RebuildTopDotFilters() end
				end)
				showCheck:SetScript("OnEnter", function() SetRowHighlighted(true) end)
				showCheck:SetScript("OnLeave", function() SetRowHighlighted(false) end)

				hideCheck = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
				hideCheck:SetPoint("LEFT", 270, 0)
				hideCheck:SetSize(24, 24)
				hideCheck:SetChecked(info.hide)
				hideCheck:SetScript("OnClick", function(self)
					info.hide = self:GetChecked()
					if info.hide then
						info.show = false
						showCheck:SetChecked(false)
					end
					if ns.RebuildTopDotFilters then ns.RebuildTopDotFilters() end
				end)
				hideCheck:SetScript("OnEnter", function() SetRowHighlighted(true) end)
				hideCheck:SetScript("OnLeave", function() SetRowHighlighted(false) end)

				local deleteButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
				deleteButton:SetSize(55, 20)
				deleteButton:SetPoint("LEFT", 330, 0)
				deleteButton:SetText(DELETE)
				deleteButton:SetScript("OnClick", function()
					PlateColorDB.topDotList[spellId] = nil
					frame:RefreshList()
					if ns.RebuildTopDotFilters then ns.RebuildTopDotFilters() end
				end)
				deleteButton:SetScript("OnEnter", function() SetRowHighlighted(true) end)
				deleteButton:SetScript("OnLeave", function() SetRowHighlighted(false) end)

				frame.rows[#frame.rows + 1] = row
				lastRow = row
			end
		end

		if lastRow then
			self.content:SetHeight(24 + (#frame.rows * 28))
		else
			self.content:SetHeight(48)
		end
	end

	addButton:SetScript("OnClick", function()
		local input = searchBox:GetText()
		local spellId = NormalizeSpellId(input)
		if not spellId then
			print("PlateAurasList: " .. UNKNOWN .. SPELLS)
			return
		end

		local spellName = GetSpellDisplayName(spellId)
		if not spellName then
			print("PlateAurasList: " .. UNKNOWN .. SPELLS)
			return
		end

		PlateColorDB.topDotList[spellId] = { name = spellName, show = true, hide = false }
		searchBox:SetText("")
		frame:RefreshList()
		if ns.RebuildTopDotFilters then ns.RebuildTopDotFilters() end
	end)

	frame:SetScript("OnShow", function(self)
		self:RefreshList()
	end)

	frame:RefreshList()

	_G.PlateAurasListFrame = frame
	return frame
end

function ns.OpenPlateAurasList()
	local frame = EnsureWindow()
	frame:Show()
	frame:Raise()
end
