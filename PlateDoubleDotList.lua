local addonName, ns = ...
local L = ns.L

-- 双dot染色设置：管理 (专精, dot1, dot2) 组合列表 + 血条染色颜色。
-- 列表存于 PlateColorDB.doubledotlist，键 = 专精 .. dot1 .. dot2（拼接防重复），
-- 专精在添加时自动记录（只对该专精生效），无需手动选择。
-- 实际染色逻辑见 PlateDoubleDotSetColor.lua。

local GetSpecIndex = C_SpecializationInfo and C_SpecializationInfo.GetSpecialization or GetSpecialization

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

-- 当前角色专精（添加时自动记录）
local function GetCurrentSpec()
	local index = GetSpecIndex()
	if not index then
		return nil
	end

	local specID, specName = C_SpecializationInfo.GetSpecializationInfo(index)
	if not specID or specID == 0 then
		return nil
	end

	return specID, specName
end

-- 专精显示名（按记录里保存的 specID 反查）
local function GetSpecDisplayName(specID)
	local _, name = GetSpecializationInfoForSpecID(specID)
	return name or tostring(specID)
end

-- 键 = 专精 .. dot1 .. dot2（字符串拼接防重复）
local function MakeKey(specID, dot1, dot2)
	return tostring(specID) .. tostring(dot1) .. tostring(dot2)
end

local function BuildRows()
	local rows = {}
	for key, info in pairs(PlateColorDB.doubledotlist or {}) do
		rows[#rows + 1] = { key = key, info = info }
	end

	-- 当前专精的排最上面，其余按 专精 / 法术ID 排序
	local currentSpec = GetCurrentSpec()
	table.sort(rows, function(a, b)
		local aCurrent = currentSpec ~= nil and a.info.spec == currentSpec
		local bCurrent = currentSpec ~= nil and b.info.spec == currentSpec
		if aCurrent ~= bCurrent then
			return aCurrent
		end
		if a.info.spec ~= b.info.spec then
			return a.info.spec < b.info.spec
		end
		if a.info.dot1 ~= b.info.dot1 then
			return a.info.dot1 < b.info.dot1
		end
		return a.info.dot2 < b.info.dot2
	end)

	return rows
end

local function EnsureWindow()
	if _G.PlateDoubleDotListFrame then
		return _G.PlateDoubleDotListFrame
	end

	local frame = CreateFrame("Frame", "PlateDoubleDotListFrame", UIParent, "BackdropTemplate")
	frame:SetSize(560, 460)
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
	title:SetText(L["双dot染色设置"])

	-- 左上角：鼠标提示显示法术ID开关（勾选状态由 cvar 决定，点击临时切换不持久）
	local spellIDCheck = CreateFrame("CheckButton", nil, frame, "InterfaceOptionsCheckButtonTemplate")
	spellIDCheck:SetPoint("TOPLEFT", 8, -4)
	spellIDCheck:SetSize(30, 30)
	local function RefreshSpellIDCheck()
		spellIDCheck:SetChecked(GetCVar("tooltipShowAuraSpellIDs") == "1")
	end
	RefreshSpellIDCheck()

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
		C_CVar.SetCVar("tooltipShowAuraSpellIDs", spellIDCheck:GetChecked() and "1" or "0")
	end)

	local spellIDLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	spellIDLabel:SetPoint("LEFT", spellIDCheck, "RIGHT", 2, 0)
	spellIDLabel:SetText(L["显示法术ID"])

	local barColorLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	barColorLabel:SetPoint("TOPLEFT", 16, -32)
	barColorLabel:SetText(L["血条颜色"])
	ns.AddColorFrame(frame, 95, -32, L["战斗中/M+等秘密环境无法修改"], 96, 17, "doubledotcolor1", function()
		if ns.UpdateDoubleDotColor then ns.UpdateDoubleDotColor() end
	end)

	local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	hint:SetPoint("TOPLEFT", 16, -56)
	hint:SetText(L["双dot染色说明"])

	-- 两个输入框：分别填两个 dot 的法术 ID，回车 / 点添加即记录当前专精
	local label1 = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	label1:SetPoint("TOPLEFT", 16, -78)
	label1:SetText(L["减益1"])

	local box1 = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
	box1:SetSize(170, 24)
	box1:SetPoint("TOPLEFT", 60, -74)
	box1:SetAutoFocus(false)
	box1:SetTextInsets(8, 8, 4, 4)

	local label2 = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	label2:SetPoint("TOPLEFT", 238, -78)
	label2:SetText(L["减益2"])

	local box2 = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
	box2:SetSize(170, 24)
	box2:SetPoint("TOPLEFT", 282, -74)
	box2:SetAutoFocus(false)
	box2:SetTextInsets(8, 8, 4, 4)

	local addButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	addButton:SetSize(80, 24)
	addButton:SetPoint("LEFT", box2, "RIGHT", 10, 0)
	addButton:SetText(ADD)

	local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	closeButton:SetPoint("TOPRIGHT", 2, 2)

	local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "ScrollFrameTemplate")
	scrollFrame:SetPoint("TOPLEFT", 16, -104)
	scrollFrame:SetPoint("BOTTOMRIGHT", -30, 16)
	local content = CreateFrame("Frame", nil, scrollFrame)
	content:SetSize(1, 1)
	scrollFrame:SetScrollChild(content)

	local headerSpec = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	headerSpec:SetPoint("TOPLEFT", 12, 0)
	headerSpec:SetText(L["专精"])
	headerSpec:SetWidth(80)
	headerSpec:SetJustifyH("LEFT")

	local headerID = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	headerID:SetPoint("TOPLEFT", 100, 0)
	headerID:SetText("ID")
	headerID:SetWidth(60)
	headerID:SetJustifyH("LEFT")

	local headerName = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	headerName:SetPoint("TOPLEFT", 170, 0)
	headerName:SetText(NAME)
	headerName:SetWidth(200)
	headerName:SetJustifyH("LEFT")

	local headerAction = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	headerAction:SetPoint("TOPLEFT", 400, 0)
	headerAction:SetText(L["操作"])
	headerAction:SetWidth(60)
	headerAction:SetJustifyH("LEFT")

	frame.rows = {}
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

		local currentSpec = GetCurrentSpec()
		local rowCount = 0
		local lastRow

		for _, entry in ipairs(BuildRows()) do
			rowCount = rowCount + 1
			local info = entry.info
			local key = entry.key

			-- 每行两行文字：第一行 dot1、第二行 dot2；专精在最前（跨两行居中），ID 与名称分列
			local row = CreateFrame("Frame", nil, self.content)
			row:SetSize(500, 44)
			if lastRow then
				row:SetPoint("TOPLEFT", lastRow, "BOTTOMLEFT", 0, -4)
			else
				row:SetPoint("TOPLEFT", 0, -24)
			end

			local bg = row:CreateTexture(nil, "BACKGROUND")
			bg:SetAllPoints(row)

			-- 非当前专精的行整体变暗（背景 + 文字都压暗）
			local dimmed = currentSpec ~= nil and info.spec ~= currentSpec
			local bgColor = dimmed and 0.28 or 0.5
			local highlightColor = dimmed and 0.42 or 0.75
			bg:SetColorTexture(bgColor, bgColor, bgColor, 1)

			-- 悬停高亮：鼠标进入控件时整行背景变亮，移开恢复
			local function SetRowHighlighted(highlighted)
				local c = highlighted and highlightColor or bgColor
				bg:SetColorTexture(c, c, c, 1)
			end

			-- 专精名称：放在最前面，垂直居中（跨两行文字）
			local specText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
			specText:SetPoint("LEFT", 12, 0)
			specText:SetWidth(80)
			specText:SetJustifyH("LEFT")
			specText:SetText(GetSpecDisplayName(info.spec))

			-- 第一行：dot1 的 ID / 名称（ID 与名称分列）
			local dot1IDText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
			dot1IDText:SetPoint("TOPLEFT", 100, -5)
			dot1IDText:SetWidth(60)
			dot1IDText:SetJustifyH("LEFT")
			dot1IDText:SetText(tostring(info.dot1))

			local dot1NameText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
			dot1NameText:SetPoint("TOPLEFT", 170, -5)
			dot1NameText:SetWidth(200)
			dot1NameText:SetJustifyH("LEFT")
			dot1NameText:SetText(GetSpellDisplayName(info.dot1) or info.name1 or UNKNOWN)

			-- 第二行：dot2 的 ID / 名称（ID 与名称分列）
			local dot2IDText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
			dot2IDText:SetPoint("TOPLEFT", 100, -25)
			dot2IDText:SetWidth(60)
			dot2IDText:SetJustifyH("LEFT")
			dot2IDText:SetText(tostring(info.dot2))

			local dot2NameText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
			dot2NameText:SetPoint("TOPLEFT", 170, -25)
			dot2NameText:SetWidth(200)
			dot2NameText:SetJustifyH("LEFT")
			dot2NameText:SetText(GetSpellDisplayName(info.dot2) or info.name2 or UNKNOWN)

			if dimmed then
				for _, text in ipairs({specText, dot1IDText, dot1NameText, dot2IDText, dot2NameText}) do
					text:SetTextColor(0.55, 0.55, 0.55)
				end
			end

			local deleteButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
			deleteButton:SetSize(55, 20)
			deleteButton:SetPoint("LEFT", 400, 0)
			deleteButton:SetText(DELETE)
			deleteButton:SetScript("OnClick", function()
				PlateColorDB.doubledotlist[key] = nil
				frame:RefreshList()
				if ns.RefreshDoubleDotColor then ns.RefreshDoubleDotColor() end
			end)
			deleteButton:SetScript("OnEnter", function() SetRowHighlighted(true) end)
			deleteButton:SetScript("OnLeave", function() SetRowHighlighted(false) end)

			frame.rows[#frame.rows + 1] = row
			lastRow = row
		end

		if lastRow then
			self.content:SetHeight(24 + (#frame.rows * 48))
		else
			self.content:SetHeight(48)
		end
	end

	-- 添加：两个输入框都填法术 ID，专精自动取当前专精
	local function DoAdd()
		PlateColorDB.doubledotlist = PlateColorDB.doubledotlist or {}
		local id1 = NormalizeSpellId(box1:GetText())
		local id2 = NormalizeSpellId(box2:GetText())
		if not id1 or not id2 then
			UIErrorsFrame:AddExternalWarningMessage(L["请填写两个dot的法术ID"])
			return
		end

		if id1 == id2 then
			UIErrorsFrame:AddExternalWarningMessage(L["两个减益不能填同一个法术"])
			return
		end

		local specID = GetCurrentSpec()
		if not specID then
			UIErrorsFrame:AddExternalWarningMessage(L["无法获取当前专精"])
			return
		end

		local name1 = GetSpellDisplayName(id1)
		local name2 = GetSpellDisplayName(id2)
		if not name1 then
			UIErrorsFrame:AddExternalWarningMessage(L["无法识别法术ID"] .. "：" .. id1)
			return
		end

		if not name2 then
			UIErrorsFrame:AddExternalWarningMessage(L["无法识别法术ID"] .. "：" .. id2)
			return
		end

		local key = MakeKey(specID, id1, id2)
		if PlateColorDB.doubledotlist[key] then
			UIErrorsFrame:AddExternalWarningMessage(L["该组合已存在"])
			return
		end

		PlateColorDB.doubledotlist[key] = {
			spec = specID,
			dot1 = id1,
			name1 = name1,
			dot2 = id2,
			name2 = name2,
		}
		box1:SetText("")
		box2:SetText("")
		frame:RefreshList()
		if ns.RefreshDoubleDotColor then ns.RefreshDoubleDotColor() end
	end

	box1:SetScript("OnEnterPressed", function(self)
		self:ClearFocus()
		DoAdd()
	end)
	box1:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
		self:SetText("")
	end)

	box2:SetScript("OnEnterPressed", function(self)
		self:ClearFocus()
		DoAdd()
	end)
	box2:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
		self:SetText("")
	end)

	addButton:SetScript("OnClick", DoAdd)

	frame:SetScript("OnShow", function(self)
		self:RefreshList()
	end)

	frame:RefreshList()

	_G.PlateDoubleDotListFrame = frame
	return frame
end

function ns.OpenPlateDoubleDotList()
	local frame = EnsureWindow()
	frame:Show()
	frame:Raise()
end
