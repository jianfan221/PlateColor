local addonName, ns = ...
local L = ns.L

-- 光环染色设置：管理要监控的 debuff 列表 + 两种染色颜色。
-- 列表存于 PlateColorDB.dotlist，颜色存于 dotcolor1（1 个）/dotcolor2（2 个及以上）。
-- 实际染色逻辑见 PlateAurasColor.lua。

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
	for spellId in pairs(PlateColorDB.dotlist) do
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
	if _G.PlateDotListFrame then
		return _G.PlateDotListFrame
	end

	local frame = CreateFrame("Frame", "PlateDotListFrame", UIParent, "BackdropTemplate")
	frame:SetSize(520, 430)
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
	title:SetText("PlateColorDotList")

	local singleLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	singleLabel:SetPoint("TOPLEFT", 16, -32)
	singleLabel:SetText(L["血条颜色"])
	ns.AddColorFrame(frame, 95, -32, "", 96, 17, "dotcolor1", function()
		if ns.UpdateAuraColor then ns.UpdateAuraColor() end
	end)

	local nameColorLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	nameColorLabel:SetPoint("TOPLEFT", 240, -32)
	nameColorLabel:SetText(L["名字颜色"])
	ns.AddColorFrame(frame, 320, -32, "", 96, 17, "dotcolor2", function()
		if ns.UpdateAuraColor then ns.UpdateAuraColor() end
	end)

	local title2 = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
	title2:SetPoint("TOPLEFT", 10, -56)
	title2:SetText(L["同时监控多种dot时,任意存在都会变色"])

	local searchBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
	searchBox:SetSize(240, 24)
	searchBox:SetPoint("TOPLEFT", 16, -76)
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
				PlateColorDB.dotlist[spellId] = { name = spellName, color = true, text = false }
				self:SetText("")
				parent:RefreshList()
				if ns.RefreshAuraColor then ns.RefreshAuraColor() end
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
	scrollFrame:SetPoint("TOPLEFT", 16, -110)
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

	local headerColor = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	headerColor:SetPoint("TOPLEFT", 235, 0)
	headerColor:SetText(L["血条"])
	headerColor:SetWidth(55)
	headerColor:SetJustifyH("LEFT")

	local headerText = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	headerText:SetPoint("TOPLEFT", 305, 0)
	headerText:SetText(L["名字"])
	headerText:SetWidth(55)
	headerText:SetJustifyH("LEFT")

	local headerAction = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	headerAction:SetPoint("TOPLEFT", 400, 0)
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
				row:SetSize(460, 24)
				if lastRow then
					row:SetPoint("TOPLEFT", lastRow, "BOTTOMLEFT", 0, -4)
				else
					row:SetPoint("TOPLEFT", 0, -24)
				end

				local bg = row:CreateTexture(nil, "BACKGROUND")
				bg:SetAllPoints(row)
				bg:SetColorTexture(0.5, 0.5, 0.5, 1)

				-- 悬停高亮：鼠标进入控件时整行背景变亮，移开恢复
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

				local info = PlateColorDB.dotlist[spellId]
				-- 兼容旧数据：值为纯字符串（法术名）时转成表，只启用血条染色
				if type(info) ~= "table" then
					info = { name = info, color = true, text = false }
					PlateColorDB.dotlist[spellId] = info
				end

				-- 血条染色开关
				local colorCheck = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
				colorCheck:SetPoint("LEFT", 240, 0)
				colorCheck:SetSize(24, 24)
				colorCheck:SetChecked(info.color)
				colorCheck:SetScript("OnClick", function(self)
					info.color = self:GetChecked()
					if ns.RefreshAuraColor then ns.RefreshAuraColor() end
				end)
				colorCheck:SetScript("OnEnter", function() SetRowHighlighted(true) end)
				colorCheck:SetScript("OnLeave", function() SetRowHighlighted(false) end)

				-- 名字变色开关
				local textCheck = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
				textCheck:SetPoint("LEFT", 310, 0)
				textCheck:SetSize(24, 24)
				textCheck:SetChecked(info.text)
				textCheck:SetScript("OnClick", function(self)
					info.text = self:GetChecked()
					if ns.RefreshAuraColor then ns.RefreshAuraColor() end
				end)
				textCheck:SetScript("OnEnter", function() SetRowHighlighted(true) end)
				textCheck:SetScript("OnLeave", function() SetRowHighlighted(false) end)

				local deleteButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
				deleteButton:SetSize(55, 20)
				deleteButton:SetPoint("LEFT", 390, 0)
				deleteButton:SetText(DELETE)
				deleteButton:SetScript("OnClick", function()
					PlateColorDB.dotlist[spellId] = nil
					frame:RefreshList()
					if ns.RefreshAuraColor then ns.RefreshAuraColor() end
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
			print("PlateDotList: " .. UNKNOWN .. SPELLS)
			return
		end

		local spellName = GetSpellDisplayName(spellId)
		if not spellName then
			print("PlateDotList: " .. UNKNOWN .. SPELLS)
			return
		end

		PlateColorDB.dotlist[spellId] = { name = spellName, color = true, text = false }
		searchBox:SetText("")
		frame:RefreshList()
		if ns.RefreshAuraColor then ns.RefreshAuraColor() end
	end)

	frame:SetScript("OnShow", function(self)
		self:RefreshList()
	end)

	frame:RefreshList()

	_G.PlateDotListFrame = frame
	return frame
end

function ns.OpenPlateDotList()
	local frame = EnsureWindow()
	frame:Show()
	frame:Raise()
end
