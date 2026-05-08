local addonName, ns = ...

ns.PlateColorDB["dotlist"] = {}--dot列表
ns.PlateColorDB["dotcolor1"] = {r=1, g=1, b=0}--dot1颜色
ns.PlateColorDB["dotcolor2"] = {r=1, g=1, b=1}--dot2颜色

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
	singleLabel:SetText("1".. " DOT "..COLOR)
	ns.AddColorFrame(frame, 95, -32, "", 96, 17, "dotcolor1")

	local doubleLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	doubleLabel:SetPoint("TOPLEFT", 220, -32)
	doubleLabel:SetText("2".. " DOT "..COLOR)
	ns.AddColorFrame(frame, 300, -32, "", 96, 17, "dotcolor2")

    local title2text = "仅支持施放法术目标立刻获得对应debuff的法术"
    if GetLocale() ~= "zhCN" and GetLocale() ~= "zhTW" then
        title2text = "Only supports spells that immediately apply the corresponding debuff to the target"
    end
    local title2 = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
	title2:SetPoint("TOPLEFT", 10, -60)
	title2:SetText(title2text)

	local searchBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
	searchBox:SetSize(240, 24)
	searchBox:SetPoint("TOPLEFT", 16, -80)
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
				PlateColorDB.dotlist[spellId] = spellName
				self:SetText("")
				parent:RefreshList()
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
	scrollFrame:SetPoint("TOPLEFT", 16, -114)
	scrollFrame:SetPoint("BOTTOMRIGHT", -30, 16)

	local content = CreateFrame("Frame", nil, scrollFrame)
	content:SetSize(1, 1)
	scrollFrame:SetScrollChild(content)

	local header = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	header:SetPoint("TOPLEFT", 8, 0)
	header:SetText("ID")
	header:SetWidth(90)

	local headerName = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	headerName:SetPoint("TOPLEFT", 120, 0)
	headerName:SetText(SPELLS..NAME)
	headerName:SetWidth(240)

	local headerAction = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	headerAction:SetPoint("TOPLEFT", 378, 0)
	headerAction:SetText(DELETE)
	headerAction:SetWidth(70)

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
				row:SetSize(450, 24)
				if lastRow then
					row:SetPoint("TOPLEFT", lastRow, "BOTTOMLEFT", 0, -4)
				else
					row:SetPoint("TOPLEFT", 0, -24)
				end

				local bg = row:CreateTexture(nil, "BACKGROUND")
				bg:SetAllPoints(row)
				bg:SetColorTexture(0.5, 0.5, 0.5, 1)

				local idText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
				idText:SetPoint("LEFT", 30, 0)
				idText:SetWidth(90)
				idText:SetJustifyH("LEFT")
				idText:SetText(tostring(spellId))

				local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
				nameText:SetPoint("LEFT", 200, 0)
				nameText:SetWidth(240)
				nameText:SetJustifyH("LEFT")
				nameText:SetText(GetSpellDisplayName(spellId) or UNKNOWN)

				local deleteButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
				deleteButton:SetSize(70, 20)
				deleteButton:SetPoint("LEFT", 372, 0)
				deleteButton:SetText(DELETE)
				deleteButton:SetScript("OnClick", function()
					PlateColorDB.dotlist[spellId] = nil
					frame:RefreshList()
				end)

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
			print("PlateDotList: " .. UNKNOWN..SPELLS)
			return
		end

		local spellName = GetSpellDisplayName(spellId)
		if not spellName then
			print("PlateDotList: " .. UNKNOWN..SPELLS)
			return
		end

		PlateColorDB.dotlist[spellId] = spellName
		searchBox:SetText("")
		frame:RefreshList()
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

if ns.event then
	ns.event("PLAYER_LOGIN", function()
		EnsureWindow()
	end, true)
else
	EnsureWindow()
end