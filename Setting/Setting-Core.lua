-- Setting-Core.lua：通用设置界面核心（供任意插件复用）
--   1. 创建设置页面（插件名、slash 命令、Settings 分类注册）
--   2. 左右布局（左侧标签栏 + 右侧内容区）
--   3. 提供所有行构建工具（ns.Add* 系列），供各插件的标签文件构建右侧滚动菜单
--
-- 数据读写使用 ns.DB 与默认值 ns.Defaults，均由各插件自行提供（如 SavedVariables 与默认模板）。
-- 插件特有内容（slash 命令、副标题、彩色标题等）由各插件在标签文件顶部注入 ns。
local addonName, ns = ...

-- ═══════ 本地化（国服/台服中文，其他英文；键名固定中文，值按语言翻译）═══════
local Locale = GetLocale()
local L
if Locale == "zhCN" or Locale == "zhTW" then
	L = {
		["重载"] = "重载",
		["版本"] = "版本: ",
		["设置"] = "设置",
		["一键勾选"] = "一键勾选本页面所有选项",
		["构建出错"] = "设置界面 [%s] 构建出错: ",
		["点击更改颜色"] = "点击更改颜色",
		["配置"] = "配置",
		["配置格式错误"] = "配置格式错误",
		["配置版本不匹配"] = "配置与当前版本不匹配",
		["导入缺失补全"] = "导入配置缺失以下字段，已用默认值补全：",
		["恢复默认确认"] = "即将恢复默认设置并重载，是否继续？",
		["导入确认"] = "即将导入配置并重载，是否继续？",
		["导出配置"] = "导出配置",
		["导入配置"] = "导入配置",
		["导入失败非本插件"] = "导入失败：不是本插件的配置字符串",
		["导入失败解析"] = "导入失败（解析错误）：",
		["导入失败无效"] = "导入失败：字符串不是有效配置",
		["导入失败"] = "导入失败：",
		["导出导入搜索"] = " 导出配置 导入配置",
		["更新记录"] = "更新记录",
		["暂无更新记录"] = "暂无更新记录",
		["战斗中"] = "正在战斗中，脱战后打开设置界面",
		["更新日志"] = "更新日志",
	}
else
	L = {
		["重载"] = "Reload",
		["版本"] = "Version: ",
		["设置"] = "Settings",
		["一键勾选"] = "Toggle all options on this page",
		["构建出错"] = "Settings interface [%s] build error: ",
		["点击更改颜色"] = "Click to change color",
		["配置"] = "Config",
		["配置格式错误"] = "Invalid config format",
		["配置版本不匹配"] = "Config does not match current version",
		["导入缺失补全"] = "Import config missing the following fields, filled with defaults:",
		["恢复默认确认"] = "Reset to default settings and reload, continue?",
		["导入确认"] = "Import config and reload, continue?",
		["导出配置"] = "Export Config",
		["导入配置"] = "Import Config",
		["导入失败非本插件"] = "Import failed: not this addon's config string",
		["导入失败解析"] = "Import failed (parse error): ",
		["导入失败无效"] = "Import failed: string is not a valid config",
		["导入失败"] = "Import failed: ",
		["导出导入搜索"] = " Export Config Import Config",
		["更新记录"] = "Update Log",
		["暂无更新记录"] = "No update records",
		["战斗中"] = "In combat, opening settings after leaving combat",
		["更新日志"] = "Update Log",
	}
end

-- ═══════════════════════════════════════════════════════════════════
-- 基础设施（页面构建与 API 共用）
-- ═══════════════════════════════════════════════════════════════════
-- 说明：ns.DB 实时引用与 ns.Defaults 默认模板均由各插件自行提供，
--       核心文件不写死具体插件的 DB 表，以保证多插件通用。

local Cur = {}  -- 当前正在构建的标签上下文：Cur.content（右侧内容框）、Cur.y（标签序号）
ns.Cur = Cur    -- 暴露给标签文件，便于在 build 内自由创建 UI / 撑高滚动条（ns.Cur.maxHeight）

-- 每个标签页的行计数器（key = 标签序号）
ns.RowCount = {}

-- 标签页注册表（由各插件的标签文件通过 ns.AddTab 填充）
ns.SettingsTabs = {}

-- 懒构建：frame 首次显示时才执行 builder（只执行一次）
function ns.LazyBuild(frame, builder)
	local built = false
	frame:HookScript("OnShow", function()
		if built then return end
		built = true
		builder()
	end)
end

-- 滚动内容构造（每个标签一个）
local function NewScrollContent(tabFrame)
	local scroll = CreateFrame("ScrollFrame", nil, tabFrame, "ScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", tabFrame, "TOPLEFT", 0, -2)
	scroll:SetPoint("BOTTOMRIGHT", tabFrame, "BOTTOMRIGHT", -20, 0)
	scroll:SetScript("OnMouseWheel", function(self, value)
		local step = 35
		local pos = self:GetVerticalScroll()
		local range = self:GetVerticalScrollRange()
		if value > 0 then
			self:SetVerticalScroll(math.max(0, pos - step))
		else
			self:SetVerticalScroll(math.min(range, pos + step))
		end
	end)
	local content = CreateFrame("Frame", nil, scroll)
	scroll:SetScrollChild(content)
	-- 内容宽度即时跟随滚动区可视宽度：canvas 首次显示时可能晚一帧才布局，
	-- 尺寸一变就把 content 宽对齐到可视区，避免内容 0 宽被 ScrollFrame 裁剪成右侧空白
	scroll:SetScript("OnSizeChanged", function(self)
		local w = self:GetWidth()
		if w and w > 10 then
			content:SetWidth(w)
		end
	end)
	return scroll, content
end

-- ═══════════════════════════════════════════════════════════════════
-- 页面构建
-- ═══════════════════════════════════════════════════════════════════
local SettingsFrame = CreateFrame("Frame", addonName .. "SettingsFrame", UIParent)
ns.SettingsFrame = SettingsFrame  -- 暴露主框架，供插件其他模块在此页面添加自定义内容（如特有的提示、按钮、装饰）
-- 标题用彩色标题（ns.RCTexts 可自定义，缺省用插件名）
local category = Settings.RegisterCanvasLayoutCategory(SettingsFrame, ns.RCTexts and ns.RCTexts(addonName) or addonName)
Settings.RegisterAddOnCategory(category)

ns.LazyBuild(SettingsFrame, function()
	-- ═══════ 底部：重载（右）═══════
	local reload = CreateFrame("Button", addonName .. "rl", SettingsFrame, "UIPanelButtonTemplate")
	reload:SetText(L["重载"])
	reload:SetWidth(92)
	reload:SetHeight(22)
	reload:SetPoint("BOTTOMRIGHT", SettingsFrame, "BOTTOMRIGHT", -132, -31)
	reload:SetScript("OnClick", function()
		ReloadUI()
	end)

	-- ═══════ 上部分标题 ═══════
	local divider = SettingsFrame:CreateTexture(nil, "ARTWORK")
	divider:SetPoint("TOPLEFT", SettingsFrame, "TOPLEFT", -14, -42)
	divider:SetPoint("TOPRIGHT", SettingsFrame, "TOPRIGHT", 0, -42)
	divider:SetHeight(1)
	divider:SetColorTexture(1, 1, 1, 0.3)

	local title = SettingsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("BOTTOMLEFT", divider, "TOPLEFT", 10, 0)
	title:SetFontHeight(33)
	title:SetText(ns.RCTexts and ns.RCTexts(addonName) or addonName)

	local subtitle = SettingsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	subtitle:SetPoint("BOTTOMLEFT", divider, "TOPLEFT", 110, 5)
	if ns.Subtitle then subtitle:SetText(ns.Subtitle) else subtitle:Hide() end

	local versionText = SettingsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	versionText:SetPoint("BOTTOMRIGHT", divider, "TOPRIGHT", 0, 3)
	versionText:SetTextColor(0.8, 0.8, 0.8)
	versionText:SetText(L["版本"] .. "|cff00FFFF"..(C_AddOns.GetAddOnMetadata(addonName, "Version") or "").."|r")

	-- ═══════ 搜索框（可搜索左侧标签名或右侧设置内容）═══════
	local searchBox = CreateFrame("EditBox", nil, SettingsFrame, "SearchBoxTemplate")
	searchBox:SetPoint("TOPLEFT", SettingsFrame, "TOPLEFT", 0, -50)
	searchBox:SetWidth(230)
	searchBox:SetHeight(22)

	-- ═══════ 主体：左标签栏 + 右内容区 ═══════
	local mainBG = CreateFrame("Frame", nil, SettingsFrame, "BackdropTemplate")
	mainBG:SetPoint("TOPLEFT", SettingsFrame, "TOPLEFT", -14, -78)
	mainBG:SetPoint("BOTTOMRIGHT", SettingsFrame, "BOTTOMRIGHT", 0, 0)
	mainBG:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background" })
	mainBG:SetBackdropColor(0, 0, 0, 0.55)

	-- 左侧标签栏（可滚动，无滚动条）
	local tabBar = CreateFrame("ScrollFrame", nil, mainBG)
	tabBar:SetPoint("TOPLEFT", mainBG, "TOPLEFT", 2, -2)
	tabBar:SetPoint("BOTTOMLEFT", mainBG, "BOTTOMLEFT", 2, 2)
	tabBar:SetWidth(116)
	local tabBarBG = tabBar:CreateTexture(nil, "BACKGROUND")
	tabBarBG:SetAllPoints(tabBar)
	tabBarBG:SetColorTexture(0, 0, 0, 0.3)
	local tabBarContent = CreateFrame("Frame", nil, tabBar)
	tabBarContent:SetSize(116, 10)
	tabBar:SetScrollChild(tabBarContent)
	tabBar:SetScript("OnMouseWheel", function(self, value)
		local step = 30
		local pos = self:GetVerticalScroll()
		local range = self:GetVerticalScrollRange()
		if value > 0 then
			self:SetVerticalScroll(math.max(0, pos - step))
		else
			self:SetVerticalScroll(math.min(range, pos + step))
		end
	end)

	-- 右侧内容区
	local rightRegion = CreateFrame("Frame", nil, mainBG)
	rightRegion:SetPoint("TOPLEFT", tabBar, "TOPRIGHT", 0, 0)
	rightRegion:SetPoint("BOTTOMRIGHT", mainBG, "BOTTOMRIGHT", -2, 2)

	-- ═══════ 构建所有标签页 + 左侧标签按钮 ═══════
	local tabs = ns.SettingsTabs
	local tabButtons = {}
	-- 定位左侧标签按钮到第 y 行（清除原有锚点）
	local function SetTabButtonPos(btn, y)
		btn:ClearAllPoints()
		btn:SetPoint("TOPLEFT", tabBarContent, "TOPLEFT", 4, -4 - y * 30)
		btn:SetSize(tabBarContent:GetWidth() - 8, 26)
	end
	local selected = 1
	-- 搜索栏右边：提示文本 + "设置"按钮（一键勾选本页面所有选项）
	local toggleAllOn = false
	local toggleBtn = CreateFrame("Button", nil, SettingsFrame)
	toggleBtn:SetSize(56, 22)
	toggleBtn:SetNormalFontObject("GameFontNormal")
	toggleBtn:SetHighlightTexture([[Interface\Buttons\ButtonHilight-Square]])
	toggleBtn:SetPoint("TOPRIGHT", SettingsFrame, "TOPRIGHT", -30, -50)
	toggleBtn:SetText(L["设置"])
	local toggleLabel = SettingsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	toggleLabel:SetPoint("RIGHT", toggleBtn, "LEFT", -6, 0)
	toggleLabel:SetJustifyH("RIGHT")
	toggleLabel:SetText(L["一键勾选"])
	toggleBtn.bg = toggleBtn:CreateTexture(nil, "BACKGROUND")
	toggleBtn.bg:SetAllPoints()
	toggleBtn.bg:SetColorTexture(0.2, 0.2, 0.2, 0.7)
	toggleBtn:SetScript("OnEnter", function()
		if toggleBtn:IsEnabled() then toggleBtn.bg:SetColorTexture(0.35, 0.35, 0.35, 0.9) end
	end)
	toggleBtn:SetScript("OnLeave", function()
		if toggleBtn:IsEnabled() then toggleBtn.bg:SetColorTexture(0.2, 0.2, 0.2, 0.7) end
	end)
	local function UpdateToggleButton()
		local tab = tabs[selected]
		local hasCheck = tab and tab.hasCheck
		local fs = toggleBtn:GetFontString()
		if hasCheck then
			toggleBtn:SetEnabled(true)
			toggleBtn.bg:SetColorTexture(0.2, 0.2, 0.2, 0.7)
			if fs then fs:SetTextColor(1, 0.82, 0) end  -- 金色：与右侧选项文字一致
			toggleLabel:SetTextColor(1, 1, 1)
		else
			toggleBtn:SetEnabled(false)
			toggleBtn.bg:SetColorTexture(0.3, 0.3, 0.3, 0.5)  -- 灰色底：无勾选
			if fs then fs:SetTextColor(0.5, 0.5, 0.5) end  -- 按钮文字变灰
			toggleLabel:SetTextColor(0.5, 0.5, 0.5)
		end
	end
	toggleBtn:SetScript("OnClick", function()
		local tab = tabs[selected]
		if not tab or not tab.hasCheck then return end
		toggleAllOn = not toggleAllOn
		local on = not toggleAllOn  -- 第一下=关闭，第二下=开启
		for _, row in ipairs(tab.rows) do
			if row.check then
				row.check:SetChecked(on)
				if row.db then ns.DB[row.db] = on end
			end
		end
		-- 重新应用依赖关系（master 被改到则从属项随之变灰/恢复）
		for _, fn in ipairs(tab.depUpdates or {}) do fn() end
	end)
	local function SelectTab(idx)
		selected = idx
		toggleAllOn = false
		for i, tab in ipairs(tabs) do
			if tab.frame then tab.frame:SetShown(i == idx) end
			local btn = tabButtons[i]
			if btn then
				btn.selected = (i == idx)
				local fs = btn.fs
				if fs then
					if btn.selected then
						fs:SetTextColor(1, 0.82, 0)
						btn.bg:SetColorTexture(1, 1, 1, 0.15)
					else
						fs:SetTextColor(0.9, 0.9, 0.9)
						btn.bg:SetColorTexture(0, 0, 0, 0)
					end
				end
			end
		end
		UpdateToggleButton()
	end

	for i, tab in ipairs(tabs) do
		-- 标签页内容框
		local tf = CreateFrame("Frame", nil, rightRegion)
		tf:SetAllPoints(rightRegion)
		tab.frame = tf

		local scroll, content = NewScrollContent(tf)
		tab.scroll, tab.content = scroll, content

		-- 设置当前构建上下文 + 行计数器/行表初始化，再构建
		-- build 回调的首参传入右侧内容框 content，便于标签页内自由创建自定义 UI
		Cur.content = content
		Cur.y = i
		ns.RowCount[i] = 0
		Cur.rows = {}
		Cur.dependencies = {}
		Cur.maxHeight = nil
		local ok, err = pcall(tab.build, content)
		if not ok then
			print("|cffff0000["..addonName.."]|r " .. string.format(L["构建出错"], tab.name) .. tostring(err))
		end
		tab.rows = Cur.rows
		tab.maxContentHeight = Cur.maxHeight or 0
		-- 记录该标签是否含勾选框（决定"全部开启/关闭"按钮是否可点）
		tab.hasCheck = false
		for _, row in ipairs(tab.rows) do
			if row.check then tab.hasCheck = true break end
		end
		-- 挂接依赖控制：master 勾选框控制 dependent 行的启用/禁用
		for _, dep in ipairs(Cur.dependencies or {}) do
			local masterRow = nil
			local dependentRows = {}
			for _, row in ipairs(tab.rows) do
				if row.db == dep.master then masterRow = row end
			end
			for _, rdb in ipairs(dep.dependents) do
				for _, row in ipairs(tab.rows) do
					if row.db == rdb then table.insert(dependentRows, row) end
				end
			end
			-- 从属行标题往右缩进，以示层级
			for _, r in ipairs(dependentRows) do
				if r.text and not r.indented then
					r.text:ClearAllPoints()
					r.text:SetPoint("LEFT", r.frame, "LEFT", 36, 0)
					r.indented = true
				end
			end
			if masterRow and masterRow.check then
				local function Update()
					local enabled = masterRow.check:GetChecked()
					for _, r in ipairs(dependentRows) do
						if r.SetEnabled then r:SetEnabled(enabled) end
					end
				end
				tab.depUpdates = tab.depUpdates or {}
				table.insert(tab.depUpdates, Update)
				masterRow.check:HookScript("OnClick", Update)
				Update()
			end
		end

		-- 设置内容高度（根据行数 + 自定义文本高度）
		content:SetHeight(math.max(ns.RowCount[i] * 35 + 40, tab.maxContentHeight))

		-- 左侧标签按钮
		local btn = CreateFrame("Button", nil, tabBarContent)
		SetTabButtonPos(btn, i - 1)
		btn.bg = btn:CreateTexture(nil, "BACKGROUND")
		btn.bg:SetAllPoints(btn)
		btn.bg:SetColorTexture(0, 0, 0, 0)
		local fs = btn:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		fs:SetPoint("LEFT", btn, "LEFT", 12, 0)
		fs:SetText(tab.name)
		fs:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
		fs:SetTextColor(0.9, 0.9, 0.9)
		btn.fs = fs
		btn:SetScript("OnClick", function() SelectTab(i) end)
		btn:SetScript("OnEnter", function()
			if not btn.selected then btn.bg:SetColorTexture(1, 1, 1, 0.08) end
		end)
		btn:SetScript("OnLeave", function()
			if not btn.selected then btn.bg:SetColorTexture(0, 0, 0, 0) end
		end)
		tabButtons[i] = btn
		tab.button = btn

		tf:Hide()
	end
	tabBarContent:SetHeight(#tabs * 30 + 10)
	SelectTab(1)

	-- ═══════ 搜索过滤 ═══════
	local function ApplyFilter(query)
		query = query and strlower(query) or ""
		if query == "" then
			-- 清空搜索：恢复所有行与标签按钮
			for i, tab in ipairs(tabs) do
				for _, row in ipairs(tab.rows or {}) do
					if row.restore then row.restore() end
					row.frame:Show()
				end
				tab.content:SetHeight(math.max(ns.RowCount[i] * 35 + 40, tab.maxContentHeight or 0))
				if tab.button then
					SetTabButtonPos(tab.button, i - 1)
					tab.button:Show()
				end
			end
			tabBarContent:SetHeight(#tabs * 30 + 10)
			tabBar:SetVerticalScroll(0)
			SelectTab(selected)
			return
		end
		-- 判断每个标签是否命中（标签名 或 行名称/鼠标提示），保留命中的标签
		local firstVisible = nil
		for i, tab in ipairs(tabs) do
			local m = false
			if tab.searchable ~= false then
				if strfind(strlower(tab.name), query, 1, true) ~= nil then
					m = true
				elseif tab.extraSearch and strfind(strlower(tab.extraSearch), query, 1, true) ~= nil then
					m = true
				else
					for _, row in ipairs(tab.rows or {}) do
						if strfind(strlower(row.searchText), query, 1, true) ~= nil then
							m = true
							break
						end
					end
				end
			end
			tab.matching = m
			if tab.matching and firstVisible == nil then firstVisible = i end
		end
		-- 左侧标签按钮：隐藏未命中，命中的重新堆叠
		local y = 0
		for i, tab in ipairs(tabs) do
			if tab.matching and tab.button then
				SetTabButtonPos(tab.button, y)
				tab.button:Show()
				y = y + 1
			elseif tab.button then
				tab.button:Hide()
			end
		end
		tabBarContent:SetHeight(math.max(y, 1) * 30 + 10)
		-- 显示命中的标签并过滤其行内容
		SelectTab(firstVisible or 1)
		for i, tab in ipairs(tabs) do
			if tab.noRowFilter then
				-- 特殊标签（如配置）：整页显示，不缩行、不改内容高度
				tab.content:SetHeight(math.max(ns.RowCount[i] * 35 + 40, tab.maxContentHeight or 0))
			else
				local yy = 0
				for _, row in ipairs(tab.rows or {}) do
					local matched = tab.matching
						and (strfind(strlower(tab.name), query, 1, true) ~= nil
							or strfind(strlower(row.searchText), query, 1, true) ~= nil)
					if matched then
						row.setY(yy)
						row.frame:Show()
						yy = yy + 1
					else
						row.frame:Hide()
					end
				end
				tab.content:SetHeight(yy * 35 + 40)
			end
		end
	end
	searchBox:HookScript("OnTextChanged", function(self)
		ApplyFilter(self:GetText())
	end)

	-- 首次显示后校正内容宽度（保证右侧对齐滚动区宽度）
	local attempts = 0
	local function Init()
		attempts = attempts + 1
		if SettingsFrame:GetWidth() <= 1 or SettingsFrame:GetHeight() <= 1 then
			SettingsFrame:SetSize(680, 540)
		end
		local needRetry = false
		for i, tab in ipairs(tabs) do
			local w = tab.scroll:GetWidth()
			if w and w > 10 then
				tab.content:SetWidth(w)
			else
				needRetry = true
			end
		end
		if needRetry and attempts < 20 then
			C_Timer.After(0.1, Init)
		end
	end
	C_Timer.After(0, Init)
end)

-- ═══════════════════════════════════════════════════════════════════
-- ns.Add* 行构建 API（数据读写使用 ns.DB，可复用）
-- 通过隐式"当前构建上下文"（Cur）工作：AddTab 构建某个标签时，Tab*.lua 里的行调用无需再传 content、y 参数。
-- ═══════════════════════════════════════════════════════════════════

-- 标签页注册（由 Tab*.lua 调用；build 无参数，内部直接使用下方行工具）
function ns.AddTab(name, build)
	local t = { name = name, build = build }
	table.insert(ns.SettingsTabs, t)
	return t
end

-- 悬停高亮 + 鼠标提示（背景半透明白高亮）
local function SetRowHover(frame, bg, tip, owner)
	frame:SetScript("OnEnter", function()
		bg:SetColorTexture(0.5, 0.5, 0.5, 0.2)
		if tip then
			GameTooltip:SetOwner(owner or frame, "ANCHOR_TOP")
			GameTooltip:AddLine("|cffFFFFFF"..tip.."|r")
			GameTooltip:Show()
		end
	end)
	frame:SetScript("OnLeave", function()
		bg:SetColorTexture(0, 0, 0, 0)
		if tip then GameTooltip:Hide() end
	end)
end

-- 登记一行（或标题）到当前标签的行表，用于搜索过滤
-- 记录 setY（过滤时按新序号重排）与 restore（恢复原位），并捕获创建时的父内容框
local function RegisterRow(frame, isTitle, ox, originalIndex)
	local parent = Cur.content
	local row = { frame = frame, isTitle = isTitle, searchText = "", enabled = true }
	row.setY = function(y)
		frame:ClearAllPoints()
		if isTitle then
			frame:SetPoint("TOPLEFT", parent, "TOPLEFT", ox, -12 + y * -35)
		else
			frame:SetPoint("TOPLEFT", parent, "TOPLEFT", ox, -8 + y * -35)
			frame:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -ox, -8 + y * -35)
		end
	end
	row.restore = function() row.setY(originalIndex) end
	-- 启用/禁用该行（禁用控件 + 置灰文本/数值 + 整行变暗，更直观）
	row.SetEnabled = function(self, flag)
		self.enabled = flag
		if self.control and self.control.SetEnabled then
			self.control:SetEnabled(flag)
		end
		if self.text then
			if flag then
				self.text:SetTextColor(1, 0.82, 0)
			else
				self.text:SetTextColor(0.5, 0.5, 0.5)
			end
		end
		if self.righttext then
			if flag then
				self.righttext:SetTextColor(0, 1, 0)
			else
				self.righttext:SetTextColor(0.4, 0.4, 0.4)
			end
		end
		if self.frame then
			self.frame:SetAlpha(flag and 1 or 0.45)
		end
	end
	table.insert(Cur.rows, row)
	return row
end

-- 行框架（悬停高亮 + 左侧金色文本）
local function NewRow()
	local rowFrame = CreateFrame("Frame", nil, Cur.content)
	rowFrame:SetHeight(26)
	local idx = ns.RowCount[Cur.y]
	local top = -8 + idx * -35
	rowFrame:SetPoint("TOPLEFT", Cur.content, "TOPLEFT", 8, top)
	rowFrame:SetPoint("TOPRIGHT", Cur.content, "TOPRIGHT", -8, top)
	local bg = rowFrame:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints(rowFrame)
	bg:SetColorTexture(0, 0, 0, 0)
	local lefttext = rowFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	lefttext:SetPoint("LEFT", rowFrame, "LEFT", 16, 0)
	lefttext:SetText("")
	lefttext:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
	lefttext:SetTextColor(1, .82, 0)
	rowFrame.__row = RegisterRow(rowFrame, false, 8, idx)
	rowFrame.__row.text = lefttext
	ns.RowCount[Cur.y] = ns.RowCount[Cur.y] + 1
	return rowFrame, bg, lefttext
end

-- 分类标题
function ns.AddSection(text)
	local t = Cur.content:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	local idx = ns.RowCount[Cur.y]
	t:SetPoint("TOPLEFT", Cur.content, "TOPLEFT", 10, -12 + idx * -35)
	t:SetText(text)
	t:SetFont(STANDARD_TEXT_FONT, 20, "OUTLINE")
	t:SetTextColor(1, 1, 1)
	RegisterRow(t, true, 10, idx).searchText = text
	ns.RowCount[Cur.y] = ns.RowCount[Cur.y] + 1
	return t
end

-- 勾选框
-- name: 行名称  tip: 提示  db: DB字段  setfun: (可选)点击后回调，收到勾选状态 checked
function ns.AddCheck(name, tip, db, setfun)
	local rowFrame, bg, lefttext = NewRow()
	lefttext:SetText(name)
	rowFrame.__row.searchText = name .. " " .. (tip or "")
	rowFrame.__row.db = db
	rowFrame:EnableMouse(true)
	SetRowHover(rowFrame, bg, tip)
	local check = CreateFrame("CheckButton", nil, rowFrame, "InterfaceOptionsCheckButtonTemplate")
	check:SetPoint("RIGHT", rowFrame, "RIGHT", -8, 0)
	check:SetSize(30, 30)
	check:SetChecked(ns.DB[db])
	check:SetScript("OnClick", function()
		ns.DB[db] = check:GetChecked()
		if InCombatLockdown() then return end
		ns.ApplyChange(setfun, check:GetChecked())
	end)
	rowFrame.__row.check = check
	rowFrame.__row.control = check
	SetRowHover(check, bg, tip, rowFrame)
	return { text = lefttext, check = check }
end

-- 滑动条（右侧绿色数值）
function ns.AddSlider(name, tip, min, max, step, fmt, db, setfun)
	local rowFrame, bg, lefttext = NewRow()
	lefttext:SetText(name)
	rowFrame.__row.searchText = name .. " " .. (tip or "")
	rowFrame.__row.db = db
	rowFrame:EnableMouse(true)
	SetRowHover(rowFrame, bg, tip)
	local slider = CreateFrame("Slider", nil, rowFrame, "MinimalSliderWithSteppersTemplate")
	slider:SetPoint("RIGHT", rowFrame, "RIGHT", -2, 0)
	slider:SetSize(230, 20)
	local righttext = rowFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	righttext:SetPoint("RIGHT", slider, "LEFT", -10, 0)
	righttext:SetFont(STANDARD_TEXT_FONT, 15, "OUTLINE")
	righttext:SetTextColor(0, 1, 0)
	righttext:SetText(string.format(fmt, ns.DB[db] or min))
	slider:Init(ns.DB[db] or min, min, max, (max - min) / (step or 1))
	slider:RegisterCallback("OnValueChanged", function(self, value)
		value = tonumber(string.format(fmt, value))
		righttext:SetText(string.format(fmt, value))
		ns.DB[db] = value
		if InCombatLockdown() then return end
		ns.ApplyChange(setfun, value)
	end)
	SetRowHover(slider.Slider or slider, bg, tip, rowFrame)
	SetRowHover(slider.Back or slider, bg, tip, rowFrame)
	SetRowHover(slider.Forward or slider, bg, tip, rowFrame)
	rowFrame.__row.control = slider
	rowFrame.__row.righttext = righttext
	return { check = slider, text = lefttext, righttext = righttext }
end

-- 下拉菜单（简单单选）
function ns.AddDropdown(name, tip, opts, db, setfun)
	local rowFrame, bg, lefttext = NewRow()
	lefttext:SetText(name)
	rowFrame.__row.searchText = name .. " " .. (tip or "")
	rowFrame:EnableMouse(true)
	SetRowHover(rowFrame, bg, tip)
	local dd = CreateFrame("DropdownButton", nil, rowFrame, "WowStyle1DropdownTemplate")
	dd:SetPoint("RIGHT", rowFrame, "RIGHT", -8, 0)
	dd:SetWidth(170)
	local function IsSelected(v) return v == ns.DB[db] end
	local function SetSelected(v)
		ns.DB[db] = v
		ns.ApplyChange(setfun, v)
	end
	rowFrame.__row.db = db
	rowFrame.__row.control = dd
	MenuUtil.CreateRadioMenu(dd, IsSelected, SetSelected, unpack(opts))
	SetRowHover(dd, bg, tip, rowFrame)
	return { text = lefttext, control = dd }
end

-- 读取位域 CVar 的单个位
local function GetCVarBit(cvar, bitIndex)
	local mask = 0
	for i = 1, 8 do
		if CVarCallbackRegistry:GetCVarBitfieldIndex(cvar, i) then
			mask = bit.bor(mask, bit.lshift(1, i - 1))
		end
	end
	return bit.band(mask, bit.lshift(1, bitIndex - 1)) ~= 0
end

-- 写入位域 CVar 的单个位
local function SetCVarBit(cvar, bitIndex, enabled)
	local mask = 0
	for i = 1, 8 do
		if CVarCallbackRegistry:GetCVarBitfieldIndex(cvar, i) then
			mask = bit.bor(mask, bit.lshift(1, i - 1))
		end
	end
	if enabled then
		mask = bit.bor(mask, bit.lshift(1, bitIndex - 1))
	else
		mask = bit.band(mask, bit.bnot(bit.lshift(1, bitIndex - 1)))
	end
	CVarCallbackRegistry:SetCVarBitfieldMask(cvar, mask)
end

-- 基于 CVar 的勾选框（不保存到 DB，状态由 CVar 决定，自动同步外部变化）
function ns.AddCVarCheck(name, tip, cvarName, enumValue, setfun)
	if not C_CVar.GetCVar(cvarName) then return end
	-- 鼠标提示中追加暴雪默认值（文本青蓝、值绿色）
	-- 位域 CVar（enumValue 非 nil）用默认掩码 GetCVarBitfieldDefault 判断该位；普通 CVar 直接取默认值
	local defText
	if enumValue then
		local defMask = CVarCallbackRegistry:GetCVarBitfieldDefault(cvarName)
		defText = (bit.band(defMask, bit.lshift(1, enumValue - 1)) ~= 0) and "1" or "0"
	else
		defText = tostring(C_CVar.GetCVarDefault(cvarName))
	end
	local tipText = (tip and tip .. "\n" or "") .. "|cff00FFFFCVar " .. SYSTEM_DEFAULT .. " :|r|cff00FF00" .. defText .. "|r"
	local rowFrame, bg, lefttext = NewRow()
	lefttext:SetText(name)
	rowFrame.__row.searchText = name .. " " .. (tip or "")
	rowFrame:EnableMouse(true)
	SetRowHover(rowFrame, bg, tipText)
	local check = CreateFrame("CheckButton", nil, rowFrame, "InterfaceOptionsCheckButtonTemplate")
	check:SetPoint("RIGHT", rowFrame, "RIGHT", -8, 0)
	check:SetSize(30, 30)
	local function GetState()
		if enumValue then
			return GetCVarBit(cvarName, enumValue)
		else
			return C_CVar.GetCVar(cvarName) == "1"
		end
	end
	check:SetChecked(GetState())
	check:SetScript("OnClick", function()
		local checked = check:GetChecked()
		if enumValue then
			SetCVarBit(cvarName, enumValue, checked)
		else
			C_CVar.SetCVar(cvarName, checked and "1" or "0")
		end
		if InCombatLockdown() then return end
		ns.ApplyChange(setfun, checked)
	end)
	SetRowHover(check, bg, tipText, rowFrame)
	rowFrame.__row.db = cvarName
	rowFrame.__row.control = check
	CVarCallbackRegistry:RegisterCallback(cvarName, function()
		check:SetChecked(GetState())
	end)
	return { text = lefttext, check = check }
end

-- 基于 CVar 的滑条（不保存到 DB，值由 CVar 决定，自动同步外部变化）
function ns.AddCVarSlider(name, tip, min, max, step, fmt, cvarName, setfun)
	if not C_CVar.GetCVar(cvarName) then return end
	-- 鼠标提示中追加暴雪默认值（文本青蓝、值绿色；用 fmt 格式化避免长小数）
	local defVal = tonumber(C_CVar.GetCVarDefault(cvarName))
	local tipText = (tip and tip .. "\n" or "") .. "|cff00FFFFCVar " .. SYSTEM_DEFAULT .. " :|r|cff00FF00" .. (defVal and string.format(fmt, defVal) or tostring(C_CVar.GetCVarDefault(cvarName))) .. "|r"
	local rowFrame, bg, lefttext = NewRow()
	lefttext:SetText(name)
	rowFrame.__row.searchText = name .. " " .. (tip or "")
	rowFrame:EnableMouse(true)
	SetRowHover(rowFrame, bg, tipText)
	local slider = CreateFrame("Slider", nil, rowFrame, "MinimalSliderWithSteppersTemplate")
	slider:SetPoint("RIGHT", rowFrame, "RIGHT", -2, 0)
	slider:SetSize(230, 20)
	local righttext = rowFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	righttext:SetPoint("RIGHT", slider, "LEFT", -10, 0)
	righttext:SetFont(STANDARD_TEXT_FONT, 15, "OUTLINE")
	righttext:SetTextColor(0, 1, 0)
	local function GetValue()
		return tonumber(C_CVar.GetCVar(cvarName)) or min
	end
	local function Refresh(v)
		righttext:SetText(string.format(fmt, v))
	end
	slider:Init(GetValue(), min, max, (max - min) / (step or 1))
	Refresh(GetValue())
	slider:RegisterCallback("OnValueChanged", function(self, value)
		value = tonumber(string.format(fmt, value))
		Refresh(value)
		if InCombatLockdown() then return end
		C_CVar.SetCVar(cvarName, value)
		ns.ApplyChange(setfun, value)
	end)
	SetRowHover(slider.Slider or slider, bg, tipText, rowFrame)
	SetRowHover(slider.Back or slider, bg, tipText, rowFrame)
	SetRowHover(slider.Forward or slider, bg, tipText, rowFrame)
	rowFrame.__row.db = cvarName
	rowFrame.__row.control = slider
	rowFrame.__row.righttext = righttext
	CVarCallbackRegistry:RegisterCallback(cvarName, function()
		local v = GetValue()
		slider:SetValue(v)
		Refresh(v)
	end)
	return { check = slider, text = lefttext, righttext = righttext }
end

-- 依赖控制：masterDb 勾选框控制一组行（按 DB 字段）的启用/禁用
function ns.AddDep(masterDb, dependents)
	table.insert(Cur.dependencies, { master = masterDb, dependents = dependents })
end

-- 判断纹理路径是否属于本插件自带（按插件名过滤目录）
local function IsOwnTexture(path)
	if not path or path == "" then return false end
	return strfind(strlower(path), strlower("\\" .. addonName .. "\\"), 1, true) ~= nil
end

-- 材质下拉（带预览纹理）
function ns.AddTexture(name, tip, db, textureTable, setfun)
	local rowFrame, bg, lefttext = NewRow()
	lefttext:SetText(name)
	rowFrame.__row.searchText = name .. " " .. (tip or "")
	rowFrame:EnableMouse(true)
	SetRowHover(rowFrame, bg, tip)
	local dd = CreateFrame("DropdownButton", nil, rowFrame, "WowStyle1DropdownTemplate")
	dd:SetPoint("RIGHT", rowFrame, "RIGHT", -8, 0)
	dd:SetWidth(170)
	-- 当前值不在表中时回退：优先默认 DB，其次取第一个非空材质
	if not textureTable[ns.DB[db]] then
		local def = ns.DB[db .. "Default"] or (ns.Defaults and ns.Defaults[db])
		if def and textureTable[def] then
			ns.DB[db] = def
		else
			for k, v in pairs(textureTable) do
				if v and v ~= "" then ns.DB[db] = k break end
			end
		end
	end
	dd:SetDefaultText(ns.DB[db])
	dd.selectTexture = dd:CreateTexture(nil, "ARTWORK")
	dd.selectTexture:SetPoint("TOPLEFT", dd, "TOPLEFT", 5, -5)
	dd.selectTexture:SetPoint("BOTTOMRIGHT", dd, "BOTTOMRIGHT", -15, 5)
	dd.selectTexture:SetVertexColor(1, 1, 1, 1)
	local function ApplyTexture(key)
		local t = textureTable[key]
		if string.match(t, "Interface\\") then
			dd.selectTexture:SetTexture(t)
		else
			dd.selectTexture:SetAtlas(t)
		end
	end
	ApplyTexture(ns.DB[db])
	local function IsSelected(v) return v == ns.DB[db] end
	local function SetSelected(v)
		ns.DB[db] = v
		dd:SetDefaultText(v)
		ApplyTexture(v)
		ns.ApplyChange(setfun, v)
	end
	local sorted = {}
	for k in pairs(textureTable) do table.insert(sorted, k) end
	table.sort(sorted)
	local function Generator(dropdown, root)
		root:SetScrollMode(400)
		for _, text in ipairs(sorted) do
			local texts = text
			if IsOwnTexture(textureTable[text]) then
				texts = "|cff00FFFF" .. text
			end
			local radio = root:CreateRadio(texts, IsSelected, SetSelected, text)
			radio:AddInitializer(function(button)
				local b = button:AttachTexture()
				b:SetSize(170, 18)
				b:SetPoint("LEFT", 15, 0)
				if string.match(textureTable[text], "Interface\\") then
					b:SetTexture(textureTable[text])
				else
					b:SetAtlas(textureTable[text])
				end
				b:SetDrawLayer("BACKGROUND")
			end)
		end
	end
	dd:SetupMenu(Generator)
	rowFrame.__row.db = db
	rowFrame.__row.control = dd
	SetRowHover(dd, bg, tip, rowFrame)
	return { text = lefttext, control = dd }
end

-- 按钮行
function ns.AddButton(name, tip, callback)
	local rowFrame, bg, lefttext = NewRow()
	lefttext:SetText(name)
	rowFrame.__row.searchText = name .. " " .. (tip or "")
	rowFrame:EnableMouse(true)
	SetRowHover(rowFrame, bg, tip)
	local btn = CreateFrame("Button", nil, rowFrame, "UIPanelButtonTemplate")
	btn:SetPoint("RIGHT", rowFrame, "RIGHT", -8, 0)
	btn:SetSize(130, 24)
	btn:SetText(name)
	btn:SetScript("OnClick", callback)
	rowFrame.__row.control = btn
	SetRowHover(btn, bg, tip, rowFrame)
	return { text = lefttext, control = btn }
end

-- 文本显示行（多行文本，高度按内容估算；用于更新日志等）
function ns.AddLog(text)
	local idx = ns.RowCount[Cur.y]
	local top = -8 + idx * -35
	local rowFrame = CreateFrame("Frame", nil, Cur.content)
	rowFrame:SetPoint("TOPLEFT", Cur.content, "TOPLEFT", 8, top)
	rowFrame:SetPoint("TOPRIGHT", Cur.content, "TOPRIGHT", -8, top)
	local t = rowFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	t:SetPoint("TOPLEFT", rowFrame, "TOPLEFT", 8, -4)
	t:SetPoint("BOTTOMRIGHT", rowFrame, "BOTTOMRIGHT", -8, 4)
	t:SetJustifyH("LEFT")
	t:SetJustifyV("TOP")
	t:SetWordWrap(true)
	t:SetTextColor(1, 1, 1)
	t:SetSpacing(4) -- 增加行间距，让更新日志更易读
	t:SetText(text or "")
	local width = rowFrame:GetWidth() or (Cur.content and Cur.content:GetWidth())
	if not width or width <= 0 then
		width = (SettingsFrame and SettingsFrame:GetWidth() or 680) - 130
	end
	t:SetWidth(width - 16)
	local height = t:GetStringHeight() + 8
	height = math.max(height, 24)
	rowFrame:SetHeight(height)
	local row = RegisterRow(rowFrame, false, 8, idx)
	row.searchText = text or ""
	Cur.maxHeight = math.max(Cur.maxHeight or 0, -top + height + 16)
	ns.RowCount[Cur.y] = ns.RowCount[Cur.y] + 1
	return { frame = rowFrame, text = t }
end

-- ═══════════════════════════════════════════════════════════════════
-- 其余行构建函数（改用 Cur 上下文）
-- 说明：所有行构建函数的 setfun 回调统一经 ns.ApplyChange 分发，实现多插件通用。
--       本文件（通用核心）默认 ns.ApplyChange = 传值调用；
--       各插件可在标签文件顶部覆盖为自定义刷新版本（如遍历单位刷新，忽略 value）
-- ═══════════════════════════════════════════════════════════════════

-- 统一回调入口（默认 = 传值调用）
-- 各插件可覆盖 ns.ApplyChange 以适配自身回调约定（如忽略 value、遍历单位刷新）
function ns.ApplyChange(setfun, value)
	if not setfun then return end
	if setfun then setfun(value) end
end

-- 功能按钮行（返回按钮，供外部 HookScript("OnClick")；分类标题直接用 AddSection）
function ns.AddFuncButton(name, tip)
	local rowFrame, bg, lefttext = NewRow()
	lefttext:SetText(name)
	rowFrame.__row.searchText = name .. " " .. (tip or "")
	rowFrame:EnableMouse(true)
	SetRowHover(rowFrame, bg, tip)
	local btn = CreateFrame("Button", nil, rowFrame, "UIPanelButtonTemplate")
	btn:SetPoint("RIGHT", rowFrame, "RIGHT", -8, 0)
	btn:SetSize(230, 25)
	btn:SetText(name)
	rowFrame.__row.control = btn
	SetRowHover(btn, bg, tip, rowFrame)
	return btn
end

-- 材质下拉（右侧小图标预览；pc 原 AddSetDropdTexture2）
function ns.AddTextureIcon(name, tip, db, TextureTable, setfun)
	local rowFrame, bg, lefttext = NewRow()
	lefttext:SetText(name)
	rowFrame.__row.searchText = name .. " " .. (tip or "")
	rowFrame.__row.db = db
	rowFrame:EnableMouse(true)
	SetRowHover(rowFrame, bg, tip)
	local dd = CreateFrame("DropdownButton", nil, rowFrame, "WowStyle1DropdownTemplate")
	dd:SetPoint("RIGHT", rowFrame, "RIGHT", -8, 0)
	dd:SetWidth(200)
	dd:SetDefaultText(ns.DB[db])
	dd.selectTexture = dd:CreateTexture(nil, "ARTWORK")
	dd.selectTexture:SetPoint("RIGHT", dd, "RIGHT", -30, 0)
	dd.selectTexture:SetSize(25, 25)
	dd.selectTexture:SetVertexColor(1, 1, 1, 1)
	dd.selectTexture:SetTexture(TextureTable[ns.DB[db]])
	local function IsSelected(v) return v == ns.DB[db] end
	local function SetSelected(v)
		ns.DB[db] = v
		dd.selectTexture:SetTexture(TextureTable[ns.DB[db]])
		ns.ApplyChange(setfun, v)
	end
	local sortedTable = {}
	for k in pairs(TextureTable) do table.insert(sortedTable, k) end
	table.sort(sortedTable)
	local function GeneratorFunction(dropdown, rootDescription)
		rootDescription:SetScrollMode(400)
		for _, text in ipairs(sortedTable) do
			local radio = rootDescription:CreateRadio(text, IsSelected, SetSelected, text)
			radio:AddInitializer(function(button)
				local bgTexture = button:AttachTexture()
				bgTexture:SetSize(20, 20)
				bgTexture:SetPoint("RIGHT", 0, 0)
				bgTexture:SetTexture(TextureTable[text])
				bgTexture:SetDrawLayer("BACKGROUND")
			end)
		end
	end
	dd:SetupMenu(GeneratorFunction)
	rowFrame.__row.control = dd
	SetRowHover(dd, bg, tip, rowFrame)
	return { text = lefttext, control = dd }
end

-- 色块（挂在 ColorPickerFrame 左上角的"设为默认"按钮，全插件共用一份）
local defaultBtn        -- 挂在 ColorPickerFrame 左上角的"设为默认"按钮（本插件色块打开时显示）
local defaultBtnHandler -- 当前色块的默认设置回调
-- 创建色块按钮（不创建行，由调用方传入 rowFrame；pc 原 AddColorFrame 的块逻辑）
-- 参数：rowFrame 所在行框架，tip 提示，width/height 色块尺寸，DB 颜色 DB 字段，setfun 回调，texture 可选纹理
local function CreateColorBlock(rowFrame, tip, width, height, DB, setfun, texture)
	local tip = tip or L["点击更改颜色"]
	local width, height = width or 75, height or 15

	local btn = CreateFrame("Button", nil, rowFrame, "GameMenuButtonTemplate")
	btn:SetPoint("RIGHT", rowFrame, "RIGHT", -8, 0)
	btn:SetSize(width, height)
	btn:SetAlpha(0)
	btn:SetNormalFontObject("GameFontNormalLarge")
	btn:SetHighlightFontObject("GameFontHighlightLarge")
	-- 色块纹理挂在 rowFrame（行框架）上而非按钮上：
	-- btn:SetAlpha(0) 会连同子元素一起透明，若色块作为按钮子纹理则会被隐藏
	-- 挂在行框架上并锚定按钮四角，即可正常显示且跟随按钮移动
	btn.color = rowFrame:CreateTexture(nil, "ARTWORK")
	btn.color:SetPoint("TOPLEFT", btn, "TOPLEFT")
	btn.color:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT")
	-- 传入 texture 时用该材质代替纯色块，并用所选颜色着色
	if texture then
		btn.color:SetTexture(texture)
		btn.color:SetVertexColor(ns.DB[DB]["r"], ns.DB[DB]["g"], ns.DB[DB]["b"], ns.DB[DB]["a"] or 1)
	else
		btn.color:SetColorTexture(ns.DB[DB]["r"], ns.DB[DB]["g"], ns.DB[DB]["b"], ns.DB[DB]["a"] or 1)
	end

	local savedColor = {}  -- 打开前存储的 DB 值快照（用于取消回退）

	-- 懒创建 ColorPickerFrame 左上角外部的"设为默认"按钮（全局字符串 RETURN_TO_DEFAULT）
	if not defaultBtn then
		defaultBtn = CreateFrame("Button", nil, ColorPickerFrame, "UIPanelButtonTemplate")
		defaultBtn:SetSize(90, 22)
		defaultBtn:SetPoint("LEFT", ColorPickerFrame, "TOPLEFT", 9, -7)
		defaultBtn:SetText(RETURN_TO_DEFAULT)
		defaultBtn:SetScript("OnClick", function()
			if defaultBtnHandler then defaultBtnHandler() end
		end)
		defaultBtn:Hide()
		ColorPickerFrame:HookScript("OnHide", function()
			defaultBtn:Hide()
		end)
	end

	local onUpdate = function(restore)
		local r, g, b = ColorPickerFrame:GetColorRGB()
		if texture then
			btn.color:SetVertexColor(r, g, b, ns.DB[DB]["a"] or 1)
		else
			btn.color:SetColorTexture(r, g, b, ns.DB[DB]["a"] or 1)
		end
		ns.DB[DB]["r"] = r
		ns.DB[DB]["g"] = g
		ns.DB[DB]["b"] = b
		if ns.DB[DB] and ns.DB[DB].a ~= nil then
			ns.DB[DB]["a"] = ColorPickerFrame:GetColorAlpha()
		end
		ns.ApplyChange(setfun)
	end
	local onCancel = function()
		local r, g, b, a = savedColor.r, savedColor.g, savedColor.b, savedColor.a or 1
		ns.DB[DB]["r"] = r
		ns.DB[DB]["g"] = g
		ns.DB[DB]["b"] = b
		if ns.DB[DB] and ns.DB[DB].a ~= nil then
			ns.DB[DB]["a"] = a
		end
		if texture then
			btn.color:SetVertexColor(r, g, b, a)
		else
			btn.color:SetColorTexture(r, g, b, a)
		end
		ns.ApplyChange(setfun)
	end

	btn:SetScript("OnClick", function()
		local hasOpacity = ns.DB[DB] and ns.DB[DB].a ~= nil
		ColorPickerFrame.swatchFunc = onUpdate
		ColorPickerFrame.opacityFunc = onUpdate
		ColorPickerFrame.cancelFunc = onCancel
		ColorPickerFrame.hasOpacity = hasOpacity
		savedColor.r = ns.DB[DB]["r"]
		savedColor.g = ns.DB[DB]["g"]
		savedColor.b = ns.DB[DB]["b"]
		savedColor.a = ns.DB[DB]["a"] or 1
		ColorPickerFrame.previousValues = {
			r = ns.DB[DB]["r"],
			g = ns.DB[DB]["g"],
			b = ns.DB[DB]["b"],
			a = ns.DB[DB]["a"] or 1,
		}
		if hasOpacity then
			ColorPickerFrame.opacity = ns.DB[DB]["a"] or 1
		end
		local picker = ColorPickerFrame.Content and ColorPickerFrame.Content.ColorPicker or ColorPickerFrame
		picker:SetColorRGB(ns.DB[DB]["r"], ns.DB[DB]["g"], ns.DB[DB]["b"])
		if defaultBtn then
			defaultBtnHandler = function()
				local d = ns.Defaults and ns.Defaults[DB] or ns.DB[DB]
				ns.DB[DB]["r"] = d.r
				ns.DB[DB]["g"] = d.g
				ns.DB[DB]["b"] = d.b
				if ns.DB[DB].a ~= nil then ns.DB[DB]["a"] = d.a or 1 end
				if hasOpacity then
					ColorPickerFrame.opacity = d.a or 1
					picker:SetColorAlpha(d.a or 1)
				end
				picker:SetColorRGB(d.r, d.g, d.b)
				if texture then
					btn.color:SetVertexColor(d.r, d.g, d.b, d.a or 1)
				else
					btn.color:SetColorTexture(d.r, d.g, d.b, d.a or 1)
				end
				ns.ApplyChange(setfun)
			end
			defaultBtn:Show()
		end
		ColorPickerFrame:Show()
	end)
	btn:SetScript("OnEnter", function()
		GameTooltip:SetOwner(btn, "ANCHOR_TOP")
		GameTooltip:SetText(tip, 1, 1, 1)
		GameTooltip:Show()
	end)
	btn:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	return btn
end

-- 兼容旧签名的色块按钮（供独立窗口如 PlateDotList.lua 使用）
-- 旧签名：ns.AddColorFrame(parent, x, y, tip, width, height, DB, setfun, texture)
-- 直接以绝对坐标挂在 parent 上，不参与 Cur 行上下文
function ns.AddColorFrame(parent, x, y, tip, width, height, DB, setfun, texture)
	local parent = parent or UIParent	--父框体
	local x, y = x or 0, y or 0	--锚点坐标
	local tip = tip or L["点击更改颜色"]
	local width, height = width or 75, height or 15

	local btn = CreateFrame("Button", nil, parent, "GameMenuButtonTemplate")
	btn:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
	btn:SetSize(width, height)
	btn:SetAlpha(0)
	btn:SetNormalFontObject("GameFontNormalLarge")
	btn:SetHighlightFontObject("GameFontHighlightLarge")
	btn.color = parent:CreateTexture(nil, "ARTWORK")
	btn.color:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
	btn.color:SetSize(width, height)
	-- 传入 texture 时用该材质代替纯色块，并用所选颜色着色
	if texture then
		btn.color:SetTexture(texture)
		btn.color:SetVertexColor(ns.DB[DB]["r"], ns.DB[DB]["g"], ns.DB[DB]["b"], ns.DB[DB]["a"] or 1)
	else
		btn.color:SetColorTexture(ns.DB[DB]["r"], ns.DB[DB]["g"], ns.DB[DB]["b"], ns.DB[DB]["a"] or 1)
	end

	local savedColor = {}  -- 打开前存储的 DB 值快照（用于取消回退）

	local onUpdate = function(restore)
		local r, g, b = ColorPickerFrame:GetColorRGB()
		if texture then
			btn.color:SetVertexColor(r, g, b, ns.DB[DB]["a"] or 1)
		else
			btn.color:SetColorTexture(r, g, b, ns.DB[DB]["a"] or 1)
		end
		ns.DB[DB]["r"] = r
		ns.DB[DB]["g"] = g
		ns.DB[DB]["b"] = b
		if ns.DB[DB] and ns.DB[DB].a ~= nil then
			ns.DB[DB]["a"] = ColorPickerFrame:GetColorAlpha()
		end
		ns.ApplyChange(setfun)
	end
	local onCancel = function()
		local r, g, b, a = savedColor.r, savedColor.g, savedColor.b, savedColor.a or 1
		ns.DB[DB]["r"] = r
		ns.DB[DB]["g"] = g
		ns.DB[DB]["b"] = b
		if ns.DB[DB] and ns.DB[DB].a ~= nil then
			ns.DB[DB]["a"] = a
		end
		if texture then
			btn.color:SetVertexColor(r, g, b, a)
		else
			btn.color:SetColorTexture(r, g, b, a)
		end
		ns.ApplyChange(setfun)
	end

	btn:SetScript("OnClick", function()
		local hasOpacity = ns.DB[DB] and ns.DB[DB].a ~= nil
		ColorPickerFrame.swatchFunc = onUpdate
		ColorPickerFrame.opacityFunc = onUpdate
		ColorPickerFrame.cancelFunc = onCancel
		ColorPickerFrame.hasOpacity = hasOpacity
		savedColor.r = ns.DB[DB]["r"]
		savedColor.g = ns.DB[DB]["g"]
		savedColor.b = ns.DB[DB]["b"]
		savedColor.a = ns.DB[DB]["a"] or 1
		ColorPickerFrame.previousValues = {
			r = ns.DB[DB]["r"],
			g = ns.DB[DB]["g"],
			b = ns.DB[DB]["b"],
			a = ns.DB[DB]["a"] or 1,
		}
		if hasOpacity then
			ColorPickerFrame.opacity = ns.DB[DB]["a"] or 1
		end
		local picker = ColorPickerFrame.Content and ColorPickerFrame.Content.ColorPicker or ColorPickerFrame
		picker:SetColorRGB(ns.DB[DB]["r"], ns.DB[DB]["g"], ns.DB[DB]["b"])
		if defaultBtn then
			defaultBtnHandler = function()
				local d = ns.Defaults and ns.Defaults[DB] or ns.DB[DB]
				ns.DB[DB]["r"] = d.r
				ns.DB[DB]["g"] = d.g
				ns.DB[DB]["b"] = d.b
				if ns.DB[DB].a ~= nil then ns.DB[DB]["a"] = d.a or 1 end
				if hasOpacity then
					ColorPickerFrame.opacity = d.a or 1
					picker:SetColorAlpha(d.a or 1)
				end
				picker:SetColorRGB(d.r, d.g, d.b)
				if texture then
					btn.color:SetVertexColor(d.r, d.g, d.b, d.a or 1)
				else
					btn.color:SetColorTexture(d.r, d.g, d.b, d.a or 1)
				end
				ns.ApplyChange(setfun)
			end
			defaultBtn:Show()
		end
		ColorPickerFrame:Show()
	end)
	btn:SetScript("OnEnter", function()
		GameTooltip:SetOwner(btn, "ANCHOR_TOP")
		GameTooltip:SetText(tip, 1, 1, 1)
		GameTooltip:Show()
	end)
	btn:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	return btn
end

-- 界面颜色选项行（右侧色块）
function ns.AddColor(name, tip, DB, setfun)
	local rowFrame, bg, lefttext = NewRow()
	lefttext:SetText(name)
	rowFrame.__row.searchText = name .. " " .. (tip or "")
	rowFrame.__row.db = DB
	rowFrame:EnableMouse(true)
	SetRowHover(rowFrame, bg, tip)
	local Color = CreateColorBlock(rowFrame, tip, 217, 20, DB, setfun)
	rowFrame.__row.control = Color
	return { text = lefttext, color = Color }
end

-- 点击 + 颜色选项行（左侧勾选 + 右侧色块）
function ns.AddCheckColor(name, tip, db, db2, setfun)
	local rowFrame, bg, lefttext = NewRow()
	lefttext:SetText(name)
	rowFrame.__row.searchText = name .. " " .. (tip or "")
	rowFrame.__row.db = db
	rowFrame:EnableMouse(true)
	SetRowHover(rowFrame, bg, tip)
	local check = CreateFrame("CheckButton", nil, rowFrame, "InterfaceOptionsCheckButtonTemplate")
	check:SetPoint("LEFT", rowFrame, "LEFT", 297, 0)
	check:SetSize(30, 30)
	check:SetChecked(ns.DB[db])
	check:SetScript("OnClick", function()
		ns.DB[db] = check:GetChecked()
		if InCombatLockdown() then return end
		ns.ApplyChange(setfun)
	end)
	local Color = CreateColorBlock(rowFrame, tip, 167, 20, db2, setfun)
	Color:ClearAllPoints()
	Color:SetPoint("LEFT", check, "RIGHT", 20, 0)
	Color:SetSize(167, 20)
	rowFrame.__row.check = check
	rowFrame.__row.control = check
	SetRowHover(check, bg, tip, rowFrame)
	return { text = lefttext, check = check, color = Color }
end

-- ═══════════════════════════════════════════════════════════════════
-- 核心附加标签：配置（恢复默认/导入导出）与更新日志
-- 由 Setting-Core 末尾 C_Timer.After(0) 调用 ns.BuildCoreTabs() 以排在所有标签之后
-- ═══════════════════════════════════════════════════════════════════
function ns.BuildCoreTabs()
	-- ═══════ 配置 ═══════
	local cfgTab = ns.AddTab(L["配置"], function()
		local cf = Cur.content
		-- 导入数据中转（局部变量闭包传递，避免使用全局变量）
		local importData
		-- 校验并合并导入的配置（缺失 key 用默认值补全）
		local function ValidateAndMergeImport(importDB)
			if type(importDB) ~= "table" then return nil, L["配置格式错误"] end
			local hasAny = false
			for k in pairs(ns.Defaults) do
				if importDB[k] ~= nil then hasAny = true break end
			end
			if not hasAny then return nil, L["配置版本不匹配"] end
			-- 收集导入配置缺失的字段，用默认值补全并打印
			local missing = {}
			for k, v in pairs(ns.Defaults) do
				if type(v) == "table" then
					if importDB[k] == nil then
						importDB[k] = {}
						table.insert(missing, tostring(k))
					end
					for k2, v2 in pairs(v) do
						if type(k2) ~= "number" and importDB[k][k2] == nil then
							importDB[k][k2] = v2
							table.insert(missing, tostring(k) .. "." .. tostring(k2))
						end
					end
				else
					if importDB[k] == nil then
						importDB[k] = v
						table.insert(missing, tostring(k))
					end
				end
			end
			if #missing > 0 then
				print("|cff00FFFF["..addonName.."]|r " .. L["导入缺失补全"])
				for _, m in ipairs(missing) do
					print("  |cffCCCCCC" .. m .. "|r")
				end
			end
			return importDB, nil
		end
		-- 恢复默认确认弹窗
		StaticPopupDialogs[addonName .. "CONFIG_RESET"] = {
			text = L["恢复默认确认"],
			button1 = RESET_TO_DEFAULT,
			button2 = CANCEL,
			OnAccept = function()
				-- 恢复默认：遍历默认表，默认值为空表的字段（用户数据容器）直接排除、保留原数据
				for k, v in pairs(ns.Defaults) do
					if type(v) == "table" and not next(v) then
						-- 空表默认字段 = 用户数据容器，保留 ns.DB 原有数据
					else
						ns.DB[k] = type(v) == "table" and CopyTable(v) or v
					end
				end
				ReloadUI()
			end,
			timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
		}
		-- 导入确认弹窗
		StaticPopupDialogs[addonName .. "CONFIG_IMPORT"] = {
			text = L["导入确认"],
			button1 = RELOADUI,
			button2 = CANCEL,
			OnAccept = function()
				if type(importData) == "table" then
					-- 导入：原地清空重填 ns.DB（保持同一引用，重载后存档才生效）
					wipe(ns.DB)
					for k, v in pairs(importData) do
						ns.DB[k] = type(v) == "table" and CopyTable(v) or v
					end
					ReloadUI()
				end
			end,
			timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
		}
		-- 多行字符串框
		local box = CreateFrame("ScrollFrame", nil, cf, "InputScrollFrameTemplate")
		box:SetPoint("TOPLEFT", cf, "TOPLEFT", 15, -80)
		box:SetPoint("BOTTOMRIGHT", cf, "TOPRIGHT", -20, -500)
		local ebox = box.EditBox
		ebox:SetMultiLine(true)
		ebox:SetAutoFocus(false)
		ebox:SetFontObject("GameFontNormal")
		ebox:SetTextColor(1, 1, 1)
		-- 上限设 0 = 不限制输入长度；右下角保留暴雪字符计数（显示负数也无妨）
		ebox:SetMaxLetters(0)
		ebox:SetTextInsets(8, 8, 6, 6)
		-- 点击输入框内时全选文本（方便一键复制）
		ebox:SetScript("OnEditFocusGained", function(self)
			self:HighlightText()
		end)
		-- 创建时 cf 内容区可能尚未布局（GetWidth 为 0），需延迟到尺寸确定后再设宽度
		local function SizeEBox()
			local w = box:GetWidth()
			if w > 0 then ebox:SetWidth(w - 20) end
		end
		box:SetScript("OnSizeChanged", SizeEBox)
		box:SetScript("OnShow", SizeEBox)
		local function MakeBtn(text, callback)
			local btn = CreateFrame("Button", nil, cf, "UIPanelButtonTemplate")
			btn:SetText(text)
			btn:SetSize(110, 24)
			btn:SetScript("OnClick", callback)
			return btn
		end
		-- 第一行：恢复默认
		local resetBtn = MakeBtn(RETURN_TO_DEFAULT, function()
			StaticPopup_Show(addonName .. "CONFIG_RESET")
		end)
		resetBtn:SetPoint("TOPLEFT", cf, "TOPLEFT", 10, -8)
		-- 第二行：导出 / 导入
		local exportBtn = MakeBtn(L["导出配置"], function()
			-- CBOR 直接序列化整表：保留数字键等所有 Lua 类型；再转 Base64 便于复制分享
			-- 前缀 插件名@ 用于标识本插件字符串，导入时校验
			ebox:SetText(addonName .. "@" .. C_EncodingUtil.EncodeBase64(C_EncodingUtil.SerializeCBOR(ns.DB)))
		end)
		exportBtn:SetPoint("TOPLEFT", cf, "TOPLEFT", 10, -42)
		local importBtn = MakeBtn(L["导入配置"], function()
			-- 先校验字符串是否为本插件配置（前缀 插件名@），再解码导入
			local text = (ebox:GetText() or ""):gsub("^%s+", ""):gsub("%s+$", "")
			local prefix = addonName .. "@"
			if strsub(text, 1, #prefix) ~= prefix then
				print("|cffff0000["..addonName.."]|r " .. L["导入失败非本插件"])
				return
			end
			text = strsub(text, #prefix + 1)
			-- CBOR 反序列化：Base64 解码后直接还原整表，数字键原样保留
			local ok, data = pcall(C_EncodingUtil.DeserializeCBOR, C_EncodingUtil.DecodeBase64(text))
			if not ok then
				print("|cffff0000["..addonName.."]|r " .. L["导入失败解析"] .. tostring(data))
				return
			end
			if type(data) ~= "table" then
				print("|cffff0000["..addonName.."]|r " .. L["导入失败无效"])
				return
			end
			local merged, err = ValidateAndMergeImport(data)
			if not merged then
				print("|cffff0000["..addonName.."]|r " .. L["导入失败"] .. tostring(err))
				return
			end
			importData = merged
			StaticPopup_Show(addonName .. "CONFIG_IMPORT")
		end)
		importBtn:SetPoint("LEFT", exportBtn, "RIGHT", 8, 0)
		Cur.maxHeight = 430
	end)
	-- 配置标签：整页显示（不参与行过滤），可通过标签名或按钮名搜索命中
	cfgTab.extraSearch = RETURN_TO_DEFAULT .. L["导出导入搜索"]
	cfgTab.noRowFilter = true

	-- ═══════ 更新日志 ═══════
	local logTab = ns.AddTab(L["更新日志"], function()
		ns.AddSection(L["更新记录"])
		ns.AddLog(ns.UpdateText or L["暂无更新记录"])
	end)
	-- 更新日志不参与搜索
	logTab.searchable = false
end

-- 配置/更新日志标签需在所有标签注册完成后才追加，否则会排在最前而非末尾。
-- Setting-Core 先于各插件的标签文件加载，故延迟到下一帧再注册。
C_Timer.After(0, function()
	ns.BuildCoreTabs()
	-- 动态注册 slash 命令：命令字符串由各插件的标签文件通过 ns.opensetting1/2/... 提供
	local slashKey = "Open" .. addonName
	SlashCmdList[slashKey] = function()
		-- 战斗中不直接打开，脱战后（PLAYER_REGEN_ENABLED）再打开
		-- 用 EventRegistry（暴雪官方事件注册）+ handle 注销，不依赖任何 ns 封装
		if InCombatLockdown() then
			print("|cffff0000["..addonName.."]|r " .. L["战斗中"])
			-- Lua 5.1 局部变量作用域不覆盖赋值语句右侧，须先单独声明 handle 再赋值，否则回调里 handle 是全局 nil
			local handle = nil
			handle = EventRegistry:RegisterFrameEventAndCallbackWithHandle("PLAYER_REGEN_ENABLED", function()
				handle:Unregister()
				Settings.OpenToCategory(category:GetID())
			end)
		else
			Settings.OpenToCategory(category:GetID())
		end
	end
	local i = 1
	while ns["opensetting" .. i] do
		_G["SLASH_" .. slashKey .. i] = ns["opensetting" .. i]
		i = i + 1
	end
end)
