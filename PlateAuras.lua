local _, ns = ...

local function SetCooldownText(self)
    local success, cdText = pcall(function()
        return self.Cooldown:GetCountdownFontString()
    end)
    if success and cdText then
        cdText:SetFontObject("PC_FontOutline")
        cdText:SetFontHeight(self:GetHeight()/1.5 * PlateColorDB.auraText1)
    end
end
ns.hook(NamePlateAuraItemMixin,"OnLoad",SetCooldownText)

--鼠标提示开关（所有版本通用）
ns.hook(NamePlateAuraItemMixin, "SetAura", function(self, aura)
	if self and not self:IsForbidden() then
		self:EnableMouse(not PlateColorDB.hideAuraTooltip)
	end
end)

function ns.CrowdControlListFrameScale(unitFrame)
    unitFrame.AurasFrame.DebuffListFrame:SetScale(PlateColorDB.auraTopScale)
    if unitFrame.AurasFrame.BuffListFrame then--左侧光环
        unitFrame.AurasFrame.BuffListFrame:SetScale(PlateColorDB.auraLScale)
        unitFrame.AurasFrame.BuffListFrame:ClearAllPoints()
        local anchor = unitFrame.abs or unitFrame.healthBar
        unitFrame.AurasFrame.BuffListFrame:SetPoint("RIGHT", anchor, "LEFT", -2, 0)
    end
    if unitFrame.AurasFrame.CrowdControlListFrame then--敌方NPC右侧控制光环
        unitFrame.AurasFrame.CrowdControlListFrame:SetScale(PlateColorDB.auraRScale)
        unitFrame.AurasFrame.CrowdControlListFrame:ClearAllPoints()
        unitFrame.AurasFrame.CrowdControlListFrame:SetPoint("LEFT", unitFrame.healthBar, "RIGHT", 12, 0)
    end
    if unitFrame.AurasFrame.LossOfControlFrame then--敌方玩家右侧控制光环
        unitFrame.AurasFrame.LossOfControlFrame:SetScale(PlateColorDB.auraRScale)
        unitFrame.AurasFrame.LossOfControlFrame:ClearAllPoints()
        unitFrame.AurasFrame.LossOfControlFrame:SetPoint("LEFT", unitFrame.healthBar, "RIGHT", 12, 0)
    end
end

ns.event("NAME_PLATE_UNIT_ADDED", function(event, unit)
	local namePlate = C_NamePlate.GetNamePlateForUnit(unit,false)
	if not namePlate then return end
	local unitFrame = namePlate.UnitFrame
	if not unitFrame then return end
	ns.CrowdControlListFrameScale(unitFrame)
end)

--驱散颜色 (12.1 前使用旧版)
if not DoesTemplateExist("CustomAuraContainerTemplate") then
    ns.hook(NamePlateAuraItemMixin, "SetAura", function(self, aura)
        if self and not self:IsForbidden() and self.unitToken then
            if not self.Stealable then
                self.Stealable = self:CreateTexture(nil, "OVERLAY")
                self.Stealable:SetPoint("TOPLEFT", self, "TOPLEFT", -5, 5)
                self.Stealable:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 5, -5)
                self.Stealable:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Stealable")
                self.Stealable:SetBlendMode("ADD")
            end
            self.Stealable:Hide()
            local color = C_UnitAuras.GetAuraDispelTypeColor(self.unitToken, aura.auraInstanceID, ns.dispelColor)
            if color and UnitCanAttack("player", self.unitToken) then
                self.Stealable:SetVertexColor(color:GetRGB())
                self.Stealable:SetAlphaFromBoolean(self.isBuff,255,0)
                self.Stealable:Show()
            end
        end
    end)
end

--12.1 AuraContainer 血条左侧可驱散光环（不分敌我）
if DoesTemplateExist("CustomAuraContainerTemplate") then

	-- 光环按钮样式初始化：图标/冷却/层数/边框
	-- size: 基础尺寸(不含缩放); reverse: 冷却是否反向; needBorder: 是否加驱散边框(含驱散类型染色，不填则不加)
	-- 鼠标提示统一由设置「隐藏光环鼠标提示」(hideAuraTooltip) 控制，不再逐组传参
	-- 缩放不烘进按钮尺寸（AuraButton 是 forbidden 对象、创建后改不了它的尺寸），改由容器 SetScale 施加 → 可实时调整
	local cooldownTextEntries = {}
	local auraButtons = {}--已创建的光环按钮，供「隐藏光环鼠标提示」实时套用
	local auraContainers = {}--{c = 容器, db = 缩放 DB 键}，已创建的全部容器（含池中空闲），设置变更时统一刷

	local function InitAuraButton(btn, size, reverse, needBorder)
		btn:SetSize(size, size)
		auraButtons[#auraButtons + 1] = btn
		--先设提示锚点，再按 DB 决定是否完全鼠标穿透（顺序不能反：穿透后再写鼠标相关会破坏穿透）
		btn:SetTooltipAnchorPoint("ANCHOR_TOPRIGHT")
		btn:EnableMouse(not PlateColorDB.hideAuraTooltip)
		local icon = btn:CreateTexture(nil, "ARTWORK")
		icon:SetAllPoints(btn)
		if PlateColorDB.auraIconEdge ~= false then
			icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)--光环图标裁剪：裁掉图标自带的白边圆角铺满
			--光环图标描边：黑色底向外扩 1px
			local bg = btn:CreateTexture(nil, "BACKGROUND")
			bg:SetColorTexture(0, 0, 0, 1)
			bg:SetPoint("TOPLEFT", icon, "TOPLEFT", -1, 1)
			bg:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 1, -1)
		end
		btn:SetIcon(icon)
		
		local cooldown = CreateFrame("Cooldown", nil, btn, "CooldownFrameTemplate")
		cooldown:SetAllPoints(btn)
		cooldown:SetHideCountdownNumbers(false)
		if reverse then
			cooldown:SetReverse(true)--反转冷却动画方向
		end
		btn:SetDurationCooldown(cooldown)
		--冷却倒数文本只设字号（为光环尺寸的比例）
		--用 GetCountdownFontString() 精确取倒计时 FontString；不能用 GetRegions()[1]：第一项可能是 cooldown 自带贴图，
		--类型判断会静默跳过导致设置不生效，该按钮就一直用引擎默认字号
		local cdText = cooldown:GetCountdownFontString()
		if cdText then
			cooldownTextEntries[#cooldownTextEntries + 1] = { fontString = cdText, size = size }
			cdText:SetFontHeight(size/1.6 * PlateColorDB.auraText1)
		end
		--独立叠层/边框容器: 层级在冷却之上(+2), 不随冷却隐藏
		local overlay = CreateFrame("Frame", nil, btn)
		overlay:SetAllPoints(btn)
		overlay:SetFrameLevel(btn:GetFrameLevel() + 2)
		local count = overlay:CreateFontString(nil, "OVERLAY", "PC_FontOutline")
		count:SetPoint("BOTTOMRIGHT", btn, 3, -3)
		count:SetVertexColor(1, 1, 1)
		count:SetFontHeight(size/1.8)
		btn:SetApplicationCount(count, {})
		if needBorder then
			local border = overlay:CreateTexture(nil, "OVERLAY")
			border:SetPoint("TOPLEFT", btn, "TOPLEFT", -5, 5)
			border:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 5, -5)
			border:SetTexture("Interface\\AddOns\\PlateColor\\texture\\Border\\soft-square2.png")
			btn:AddDispelTypeTexture(border, {
				showWhenHelpful = true,
				showWhenHarmful = false,
				style = Enum.CustomAuraButtonDispelTypeTextureStyle.PreserveAsset,
				customDispelColorCurve = ns.dispelColor,
			})
		end
	end

	-- ═══ 光环尺寸 / 鼠标提示（实时应用）═══
	-- 缩放施加在“容器”上：AuraButton 本体是 forbidden 对象(创建后不可改尺寸)，而 AuraContainer
	-- 只带 EventRegistrations，SetScale 不受限 → 图标/冷却/字号/间距随容器整体缩放，可实时改。
	-- 鼠标提示（hideAuraTooltip）也在这里一起套用，复用同一套受限重试。
	-- 受限环境（战斗/M+）改不了就挂起，解除后自动重试、成功才注销（见 wow-restriction-retry skill）。
	local scaleRetryHandle

	local function SetContainerScale(c, scale)
		if not c or c.PCScale == scale then return true end
		local ok = pcall(c.SetScale, c, scale)
		if ok then c.PCScale = scale end
		return ok
	end

	-- 新建容器：登记到统一套用表（含池中空闲的），并当场套一次当前尺寸
	local function TrackContainer(c, db)
		auraContainers[#auraContainers + 1] = { c = c, db = db }
		if not SetContainerScale(c, PlateColorDB[db]) then
			ns.ApplyAura()--创建时受限（战斗/副本），走统一重试
		end
	end

	-- 套用光环设置（容器尺寸/冷却字号/按钮鼠标提示）：unitFrame=nil 时全量套用，
	-- 传入 unitFrame 时（pc 的 ApplyChange 会先无参调一次、再逐姓名板调一次）只补该姓名板的暴雪原生位，
	-- 容器/按钮/字号在无参那次已统一刷过，不必逐姓名板重复跑全量。
	function ns.ApplyAura(unitFrame)
		if unitFrame then
			pcall(ns.CrowdControlListFrameScale, unitFrame)--暴雪原生光环位（未被接管时仍显示），尽力而为
			return true
		end
		local failed = false
		-- 鼠标提示（hideAuraTooltip）合并在此套用：按钮直接全量刷一遍，受限失败则交给下方脱限重试
		local mouseEnabled = not PlateColorDB.hideAuraTooltip
		for _, btn in ipairs(auraButtons) do
			if not pcall(btn.EnableMouse, btn, mouseEnabled) then failed = true end
		end
		-- 冷却倒数字号
		for _, entry in ipairs(cooldownTextEntries) do
			if not pcall(entry.fontString.SetFontHeight, entry.fontString, entry.size / 1.6 * PlateColorDB.auraText1) then failed = true end
		end
		-- 容器缩放：统一刷全部已创建容器（新建时已套过，取用时不再设置）
		for _, entry in ipairs(auraContainers) do
			if not SetContainerScale(entry.c, PlateColorDB[entry.db]) then failed = true end
		end
		-- 暴雪原生光环位（未被接管时仍显示）只能按姓名板走，尽力而为
		for _, namePlate in ipairs(C_NamePlate.GetNamePlates()) do
			if namePlate.UnitFrame then pcall(ns.CrowdControlListFrameScale, namePlate.UnitFrame) end
		end
		if failed and not scaleRetryHandle then
			scaleRetryHandle = EventRegistry:RegisterFrameEventAndCallbackWithHandle("ADDON_RESTRICTION_STATE_CHANGED", function(_, _, state)
				if state ~= Enum.AddOnRestrictionState.Inactive then return end
				if ns.ApplyAura(nil) then
					scaleRetryHandle:Unregister()
					scaleRetryHandle = nil
				end
			end)
		end
		return not failed
	end

	-- 关闭自带的左侧增益光环/上方减益的 cvar，因为我们接下来自己创建(仅在功能开启时接管)
	ns.event("PLAYER_ENTERING_WORLD", function()
		C_Timer.After(0.1, function()
			-- 左侧增益光环：关闭敌方 NPC 与敌方玩家自带的增益显示（由我们的 PC_DispelAuras 接管）
			if PlateColorDB.auraLEnable then
				ns.SetCVar("nameplateEnemyNpcAuraDisplay", Enum.NamePlateEnemyNpcAuraDisplay.Buffs, false)
				ns.SetCVar("nameplateEnemyPlayerAuraDisplay", Enum.NamePlateEnemyPlayerAuraDisplay.Buffs, false)
			end
			-- 上方减益专属：关闭敌方 NPC 与敌方玩家的减益显示位（由我们的 PC_TopDebuffAuras 接管，避免重复）
			if PlateColorDB.auraTopEnable then
				ns.SetCVar("nameplateEnemyNpcAuraDisplay", Enum.NamePlateEnemyNpcAuraDisplay.Debuffs, false)
				ns.SetCVar("nameplateEnemyPlayerAuraDisplay", Enum.NamePlateEnemyPlayerAuraDisplay.Debuffs, false)
			end
			-- 右侧控制专属：关闭敌方 NPC 的控制显示位与敌方玩家的失控显示位（由我们的 PC_ControlAuras 接管，避免重复）
			if PlateColorDB.auraREnable then
				ns.SetCVar("nameplateEnemyNpcAuraDisplay", Enum.NamePlateEnemyNpcAuraDisplay.CrowdControl, false)
				ns.SetCVar("nameplateEnemyPlayerAuraDisplay", Enum.NamePlateEnemyPlayerAuraDisplay.LossOfControl, false)
			end
		end)
	end)

	-- 计算 disBuff 组当前应使用的过滤字符串（支持"仅显示队伍可驱散"选项）
	local function GetDispelFilter()
		return PlateColorDB.auraLDispelOnly and "HELPFUL|RAID_PLAYER_DISPELLABLE" or "HELPFUL|DISPELLABLE"
	end

	-- 选项变更回调：更新指定姓名板的 disBuff 过滤
	-- 由插件标签文件覆盖的 ApplyChange 在勾选时逐个传入 unitFrame 调用
	function ns.RebuildDispelFilter(unitFrame)
		local filter = GetDispelFilter()
		if unitFrame and unitFrame.PC_DispelAuras then
			pcall(unitFrame.PC_DispelAuras.SetAuraGroupFilterString, unitFrame.PC_DispelAuras, "disBuff", filter)
		end
	end

	-- 左侧光环额外监控的特定减益法术已迁至右侧容器（见下方 RIGHT_EXTRA_SPELLS / 设置窗口「右侧减益过滤器」）

	-- ═══ 光环容器对象池：进游戏预创建 POOL_SIZE 个，用时取用、移除时归还 ═══
	local POOL_SIZE = 40
	local dispelFree = {}      -- 左侧空闲容器
	local dispelOwner = {}     -- 左侧 [unit] = unitFrame（出借归属，用于 REMOVED 归还）

	-- 尺寸基准 25 = NamePlateConstants.AURA_ITEM_HEIGHT
	local function NewDispelContainer()
		local c = CreateFrame("AuraContainer", nil, UIParent, "CustomAuraContainerTemplate")
		TrackContainer(c, "auraLScale")
		-- 组1：可驱散光环；勾选"仅显示队伍可驱散"时只显示队伍/团队可驱散的光环（激怒、魔法等）
		c:AddAuraGroup("disBuff", GetDispelFilter(), {
			maxFrameCount = 2,
			layout = { elementSpacing = 1, groupSpacing = 1 },
			initializeFrame = function(btn)
				InitAuraButton(btn, 25, true, true)--NamePlateConstants.AURA_ITEM_HEIGHT == 25
			end,
		})
		-- 组2：重要但不可驱散的增益
		c:AddAuraGroup("otherBuff", "HELPFUL|IMPORTANT|!DISPELLABLE", {
			maxFrameCount = 2,
			layout = { elementSpacing = 1, groupSpacing = 1 },
			initializeFrame = function(btn)
				InitAuraButton(btn, 25, false)
			end,
		})
		c:Hide()
		return c
	end

	-- 取一个容器并挂到目标血条下
	local function AcquireDispel(unitFrame)
		local c = table.remove(dispelFree)
		if not c then
			c = NewDispelContainer()
		end
		pcall(c.SetAuraGroupFilterString, c, "disBuff", GetDispelFilter())--池中容器按当前设置刷新过滤
		c:SetParent(unitFrame.healthBar)
		unitFrame.PC_DispelAuras = c
		return c
	end

	-- 归还容器（停止追踪、脱离血条、回池）
	local function ReleaseDispel(unitFrame)
		local c = unitFrame and unitFrame.PC_DispelAuras
		if not c then return end
		unitFrame.PC_DispelAuras = nil
		c:Hide()--不可见即解绑事件（ShouldRegisterForDynamicEvents = IsVisible() and IsEnabled()），故必须先 Hide
		c:SetUnit("none")--清空追踪目标；SetUnit 内部 assert(type(unitToken)=="string")，传 nil 会报错，故用哨兵串
		c:ClearAllPoints()
		c:SetParent(UIParent)
		dispelFree[#dispelFree + 1] = c
	end

	-- 姓名板出现/消失：左侧可驱散光环（事件在文件末尾统一注册；unitFrame 由调度函数传入）
	local function OnLeftPlateAdded(unit, unitFrame)
		-- 左侧增益光环开关关闭时直接跳过
		if not PlateColorDB.auraLEnable then return end

		-- 从池取容器（池空则新建），作为 healthBar 子级，随血条显示/隐藏、继承框架层级
		local container = AcquireDispel(unitFrame)
		-- 玩家及其他玩家的宠物保留 otherBuff，只禁用 disBuff
		local playerOrPet = UnitIsPlayer(unit) or UnitIsOtherPlayersPet(unit)
		pcall(container.SetAuraGroupEnabled, container, "disBuff", not playerOrPet)
		dispelOwner[unit] = unitFrame
		container:SetUnit(unit)
		container:Show()
		-- abs 正常由 PlateAbsorb 在同一事件里先建好（toc 在前），万一还没有就安全补建一次，仍没有退回血条
		if not unitFrame.abs then
			pcall(ns.AddAbsorbText, nil, unit)
		end
		local anchor = unitFrame.abs or unitFrame.healthBar
		container:SetPoint("RIGHT", anchor, "LEFT", -2, 0)
	end

	local function OnLeftPlateRemoved(unit)
		local unitFrame = dispelOwner[unit]
		dispelOwner[unit] = nil
		if unitFrame then
			ReleaseDispel(unitFrame)
		end
	end

	-- ═══ 姓名板上方自定义减益容器（三组）═══

	-- ══ 单独显示的特殊减益法术（每个仅显示1个，取值为 true）══
	-- 在此扩展：新增 [法术ID] = true 即可，自动从 topShown / topMine 组排除
	local TOP_SINGLE_SPELLS = {
		[55078] = true, -- 血之疫病
	}

	-- 该法术是否归 topSingle 组单独显示
	-- 开关关闭时不再单独显示，回归普通减益（由 topShown / topMine 组按常规显示多个）
	local function IsTopSingleSpell(spellID)
		return PlateColorDB.auraTopSingle ~= false and TOP_SINGLE_SPELLS[spellID] == true
	end

	-- 由 topDotList 生成 topMine 组应显示的 dot 法术集合（show=true 的）
	local function GetTopMineSpellMap()
		local spellMap = {}
		for spellID, info in pairs(PlateColorDB.topDotList or {}) do
			-- 单独显示的特殊减益由 topSingle 组负责，此处排除
			if info and info.show and not IsTopSingleSpell(spellID) then
				spellMap[spellID] = true
			end
		end
		return spellMap
	end

	-- 由 topDotList 生成应从 topShown（姓名板默认显示）排除的 dot 法术集合
	-- 已配置的法术（无论显示/隐藏）都从 topShown 排除，避免与 topMine 重复；
	-- show 的再由 topMine 显示一次，hide 的不进 topMine（完全隐藏）
	local function GetTopShownExcludeMap()
		-- 单独显示的特殊减益由 topSingle 组负责，从姓名板默认显示中排除
		-- 开关关闭时不再排除，让血之疫病回归姓名板普通减益显示
		local excludeMap = {}
		for spellID in pairs(TOP_SINGLE_SPELLS) do
			if IsTopSingleSpell(spellID) then
				excludeMap[spellID] = true
			end
		end
		for spellID, info in pairs(PlateColorDB.topDotList or {}) do
			if info then
				excludeMap[spellID] = true
			end
		end
		return excludeMap
	end

	-- 列表增删/显示/隐藏切换后，更新所有姓名板的 topMine 显示 与 topShown 排除
	function ns.RebuildTopDotFilters()
		local showMap = GetTopMineSpellMap()
		local excludeMap = GetTopShownExcludeMap()
		for _, namePlate in ipairs(C_NamePlate.GetNamePlates()) do
			local unitFrame = namePlate.UnitFrame
			if unitFrame and unitFrame.PC_TopDebuffAuras then
				pcall(unitFrame.PC_TopDebuffAuras.SetAuraGroupCandidateFilters, unitFrame.PC_TopDebuffAuras, "topMine", { includeSpellIDs = showMap })
				pcall(unitFrame.PC_TopDebuffAuras.SetAuraGroupCandidateFilters, unitFrame.PC_TopDebuffAuras, "topShown", { excludeSpellIDs = excludeMap, nameplateShowPersonal = true, nameplateShowAll = false })
			end
		end
	end

	-- ═══ 上方光环容器对象池：进游戏预创建 POOL_SIZE 个，用时取用、移除时归还 ═══
	local topFree = {}         -- 上方空闲容器
	local topOwner = {}        -- 上方 [unit] = unitFrame（出借归属，用于 REMOVED 归还）

	-- 尺寸基准 20、鼠标穿透、反转冷却、不加边框
	-- 数量无限（不设 maxFrameCount，默认即 math.huge）；组内元素间距 elementSpacing；组间间距 groupSpacing
	local function NewTopContainer()
		local c = CreateFrame("AuraContainer", nil, UIParent, "CustomAuraContainerTemplate")
		TrackContainer(c, "auraTopScale")
		-- 组1：我释放的 + 应显示在姓名板 + 排除控制 + 仅监控指定法术，且只显示剩余时间最长的1个
		c:AddAuraGroup("topSingle", "HARMFUL|PLAYER|!INCLUDE_NAME_PLATE_ONLY|!CROWD_CONTROL", {
			maxFrameCount = 1,
			sortMethod = AuraContainerSortMethod.ExpirationOnly,--按到期时间排序
			sortDirection = AuraContainerSortDirection.Reverse,--反向 => 剩余时间最长的排在首位
			layout = { elementSpacing = 1, groupSpacing = 1 },
			-- 开关关闭时传空表 => topSingle 一个都不显示（血之疫病回归普通减益显示）
			candidateFilters = { includeSpellIDs = PlateColorDB.auraTopSingle ~= false and CopyTable(TOP_SINGLE_SPELLS) or {} },
			initializeFrame = function(btn)
				InitAuraButton(btn, 20, true)
			end,
		})
		-- 组2：应显示在姓名板（暴雪同款 INCLUDE_NAME_PLATE_ONLY + nameplateShowPersonal）+ 排除控制 + 排除隐藏的 dot
		-- nameplateShowAll = false：与暴雪一致，被标了「控制区对所有玩家显示」的光环不进普通减益（改由右侧 controlAll 显示）
		c:AddAuraGroup("topShown", "HARMFUL|PLAYER|INCLUDE_NAME_PLATE_ONLY|!CROWD_CONTROL", {
			layout = { elementSpacing = 1, groupSpacing = 1},
			candidateFilters = { excludeSpellIDs = GetTopShownExcludeMap(), nameplateShowPersonal = true, nameplateShowAll = false },
			initializeFrame = function(btn)
				InitAuraButton(btn, 20, true)
			end,
		})
		-- 组3：我释放的 + 排除应显示在姓名板 + 排除控制 + 仅监控指定法术
		c:AddAuraGroup("topMine", "HARMFUL|PLAYER|!INCLUDE_NAME_PLATE_ONLY|!CROWD_CONTROL", {
			layout = { elementSpacing = 1, groupSpacing = 1 },
			candidateFilters = { includeSpellIDs = GetTopMineSpellMap() }, -- 由 topDotList 生成，空则只显示勾选的法术
			initializeFrame = function(btn)
				InitAuraButton(btn, 20, true)
			end,
		})
		c:Hide()
		return c
	end

	-- 按当前设置刷新过滤（池中空闲容器可能错过了列表改动）
	local function RefreshTopFilters(c)
		pcall(c.SetAuraGroupCandidateFilters, c, "topSingle", { includeSpellIDs = PlateColorDB.auraTopSingle ~= false and CopyTable(TOP_SINGLE_SPELLS) or {} })
		pcall(c.SetAuraGroupCandidateFilters, c, "topMine", { includeSpellIDs = GetTopMineSpellMap() })
		pcall(c.SetAuraGroupCandidateFilters, c, "topShown", { excludeSpellIDs = GetTopShownExcludeMap(), nameplateShowPersonal = true, nameplateShowAll = false })
	end

	-- 取一个容器并挂到目标姓名板下（与暴雪 AurasFrame 一致，作为 unitFrame 子级）
	local function AcquireTop(unitFrame)
		local c = table.remove(topFree)
		if not c then
			c = NewTopContainer()
		end
		RefreshTopFilters(c)
		c:SetParent(unitFrame)
		unitFrame.PC_TopDebuffAuras = c
		return c
	end

	-- 归还容器（停止追踪、脱离姓名板、回池）
	local function ReleaseTop(unitFrame)
		local c = unitFrame and unitFrame.PC_TopDebuffAuras
		if not c then return end
		unitFrame.PC_TopDebuffAuras = nil
		c:Hide()--不可见即解绑事件（ShouldRegisterForDynamicEvents = IsVisible() and IsEnabled()），故必须先 Hide
		c:SetUnit("none")--清空追踪目标；SetUnit 内部 assert(type(unitToken)=="string")，传 nil 会报错，故用哨兵串
		c:ClearAllPoints()
		c:SetParent(UIParent)
		topFree[#topFree + 1] = c
	end

	-- 姓名板出现/消失：上方减益容器（事件在文件末尾统一注册；unitFrame 由调度函数传入）
	local function OnTopPlateAdded(unit, unitFrame)
		-- 上方自定义减益容器开关关闭时跳过
		if not PlateColorDB.auraTopEnable then return end

		-- 从池取容器（池空则新建），作为 unitFrame 子级，锚定到血条左上
		local container = AcquireTop(unitFrame)
		topOwner[unit] = unitFrame
		container:SetUnit(unit)
		container:Show()
		-- 名字在血条上方(1/2)时额外加上名字高度避免重叠
		local healthBar = unitFrame.HealthBarsContainer.healthBar
		local debuffPadding = CVarCallbackRegistry:GetCVarNumberOrDefault(NamePlateConstants.DEBUFF_PADDING_CVAR)
		local nameHeight = 0
		if PlateColorDB.namePoint == 1 or PlateColorDB.namePoint == 2 then
			-- 直接用设置的名字尺寸，避免读取 GetHeight 返回秘密值
			nameHeight = PlateColorDB.nameScale + PlateColorDB.nameVoffset + 2
		end
		PixelUtil.SetPoint(container, "BOTTOMLEFT", healthBar, "TOPLEFT", 0, debuffPadding + nameHeight)
	end

	local function OnTopPlateRemoved(unit)
		local unitFrame = topOwner[unit]
		topOwner[unit] = nil
		if unitFrame then
			ReleaseTop(unitFrame)
		end
	end

	-- ═══ 姓名板右侧自定义控制/减益容器（三组）═══

	-- ══ 组2 内置的额外监控减益（不限施放者，取值 true；原左侧 myDebuff 组迁来）══
	-- 在此添加 [法术ID] = true 即可，自动排除出控制组；
	-- 设置窗口「右侧减益过滤器」里增删的法术另存于 PlateColorDB.rightDotList，走组3（只显示自己施放的）
	local RIGHT_EXTRA_SPELLS = {
		[1217960] = true, -- 装弹手枪｜流血期间易伤20%｜密谋小径
		[1250023] = true, -- 受保护｜充满保护欲的乌龟｜虚空之痕竞技场
	}

	-- 组2 应包含的法术：文件内置表（不限来源）
	local function GetRightExtraSpellMap()
		return CopyTable(RIGHT_EXTRA_SPELLS)
	end

	-- 组3 应包含的法术：设置窗口列表里 show=true 的（只显示自己施放的）
	local function GetRightMineSpellMap()
		local spellMap = {}
		for spellID, info in pairs(PlateColorDB.rightDotList or {}) do
			if info and info.show then
				spellMap[spellID] = true
			end
		end
		return spellMap
	end

	-- 控制组应排除的法术：内置表 + 设置窗口列表里配置过的（show/hide 都算），
	-- 避免同一法术在控制组与组2/组3里重复显示
	local function GetControlExcludeMap()
		local excludeMap = CopyTable(RIGHT_EXTRA_SPELLS)
		for spellID, info in pairs(PlateColorDB.rightDotList or {}) do
			if info then
				excludeMap[spellID] = true
			end
		end
		return excludeMap
	end

	-- 列表增删/显示/隐藏切换后，更新所有姓名板的控制组排除 与 组2/组3 的法术表
	function ns.RebuildControlFilters()
		local extraMap = GetRightExtraSpellMap()
		local mineMap = GetRightMineSpellMap()
		local excludeMap = GetControlExcludeMap()
		for _, namePlate in ipairs(C_NamePlate.GetNamePlates()) do
			local unitFrame = namePlate.UnitFrame
			if unitFrame and unitFrame.PC_ControlAuras then
				pcall(unitFrame.PC_ControlAuras.SetAuraGroupCandidateFilters, unitFrame.PC_ControlAuras, "control", { excludeSpellIDs = excludeMap })
				pcall(unitFrame.PC_ControlAuras.SetAuraGroupCandidateFilters, unitFrame.PC_ControlAuras, "controlAll", { nameplateShowAll = true, excludeSpellIDs = excludeMap })
				pcall(unitFrame.PC_ControlAuras.SetAuraGroupCandidateFilters, unitFrame.PC_ControlAuras, "extra", { includeSpellIDs = extraMap })
				pcall(unitFrame.PC_ControlAuras.SetAuraGroupCandidateFilters, unitFrame.PC_ControlAuras, "mine", { includeSpellIDs = mineMap })
			end
		end
	end

	-- ═══ 右侧光环容器对象池：进游戏预创建 POOL_SIZE 个，用时取用、移除时归还 ═══
	local controlFree = {}     -- 右侧空闲容器
	local controlOwner = {}    -- 右侧 [unit] = unitFrame（出借归属，用于 REMOVED 归还）

	-- 尺寸基准 25 = NamePlateConstants.AURA_ITEM_HEIGHT（与左侧一致），缩放走 auraRScale
	local function NewControlContainer()
		local c = CreateFrame("AuraContainer", nil, UIParent, "CustomAuraContainerTemplate")
		TrackContainer(c, "auraRScale")
		-- 组1：控制类光环（昏迷/恐惧等），对应暴雪原生的右侧控制显示位；可在设置窗口里按法术ID排除
		-- 暴雪判定 = C_Spell.IsSpellCrowdControl OR aura.nameplateShowAll（Blizzard_NamePlateAuras.lua:IsAuraCrowdControl）
		-- 本组负责所有 CROWD_CONTROL；nameplateShowAll 里「非 CROWD_CONTROL」的那部分交给下面的 controlAll 组
		c:AddAuraGroup("control", "HARMFUL|CROWD_CONTROL", {
			layout = { elementSpacing = 1, groupSpacing = 1 },
			candidateFilters = { excludeSpellIDs = GetControlExcludeMap() },
			initializeFrame = function(btn)
				InitAuraButton(btn, 25, true)
			end,
		})
		-- 组1b：暴雪控制区判定的后半段 —— aura.nameplateShowAll（filterString 表达不了该字段，只能另开一组做并集）
		-- 来源与暴雪一致：HARMFUL|INCLUDE_NAME_PLATE_ONLY；!CROWD_CONTROL 排除已由 control 组负责的那部分，避免重复
		c:AddAuraGroup("controlAll", "HARMFUL|INCLUDE_NAME_PLATE_ONLY|!CROWD_CONTROL", {
			layout = { elementSpacing = 1, groupSpacing = 1 },
			candidateFilters = { nameplateShowAll = true, excludeSpellIDs = GetControlExcludeMap() },
			initializeFrame = function(btn)
				InitAuraButton(btn, 25, true)
			end,
		})
		-- 组2：内置的额外监控减益（不限施放者，仅显示表内的法术）
		c:AddAuraGroup("extra", "HARMFUL", {
			layout = { elementSpacing = 1, groupSpacing = 1 },
			candidateFilters = { includeSpellIDs = GetRightExtraSpellMap() },
			initializeFrame = function(btn)
				InitAuraButton(btn, 25, true)
			end,
		})
		-- 组3：设置窗口「右侧减益过滤器」里 show=true 的额外监控减益（只显示自己施放的）
		c:AddAuraGroup("mine", "HARMFUL|PLAYER", {
			layout = { elementSpacing = 1, groupSpacing = 1 },
			candidateFilters = { includeSpellIDs = GetRightMineSpellMap() },
			initializeFrame = function(btn)
				InitAuraButton(btn, 25, true)
			end,
		})
		c:Hide()
		return c
	end

	-- 按当前设置刷新过滤（池中空闲容器可能错过了列表改动）
	local function RefreshControlFilters(c)
		pcall(c.SetAuraGroupCandidateFilters, c, "control", { excludeSpellIDs = GetControlExcludeMap() })
		pcall(c.SetAuraGroupCandidateFilters, c, "controlAll", { nameplateShowAll = true, excludeSpellIDs = GetControlExcludeMap() })
		pcall(c.SetAuraGroupCandidateFilters, c, "extra", { includeSpellIDs = GetRightExtraSpellMap() })
		pcall(c.SetAuraGroupCandidateFilters, c, "mine", { includeSpellIDs = GetRightMineSpellMap() })
	end

	-- 取一个容器并挂到目标姓名板下
	local function AcquireControl(unitFrame)
		local c = table.remove(controlFree)
		if not c then
			c = NewControlContainer()
		end
		RefreshControlFilters(c)
		c:SetParent(unitFrame)
		unitFrame.PC_ControlAuras = c
		return c
	end

	-- 归还容器（停止追踪、脱离姓名板、回池）
	local function ReleaseControl(unitFrame)
		local c = unitFrame and unitFrame.PC_ControlAuras
		if not c then return end
		unitFrame.PC_ControlAuras = nil
		c:Hide()--不可见即解绑事件（ShouldRegisterForDynamicEvents = IsVisible() and IsEnabled()），故必须先 Hide
		c:SetUnit("none")--清空追踪目标；SetUnit 内部 assert(type(unitToken)=="string")，传 nil 会报错，故用哨兵串
		c:ClearAllPoints()
		c:SetParent(UIParent)
		controlFree[#controlFree + 1] = c
	end

	-- 姓名板出现/消失：右侧控制/额外减益容器（事件在文件末尾统一注册；unitFrame 由调度函数传入）
	local function OnRightPlateAdded(unit, unitFrame)
		-- 右侧控制光环开关关闭时跳过
		if not PlateColorDB.auraREnable then return end

		local container = AcquireControl(unitFrame)
		controlOwner[unit] = unitFrame
		container:SetUnit(unit)
		container:Show()
		-- 直接锚定到血条右侧（相对锚定，事件触发时血条已就位）
		PixelUtil.SetPoint(container, "LEFT", unitFrame.healthBar, "RIGHT", 15, 0)
	end

	local function OnRightPlateRemoved(unit)
		local unitFrame = controlOwner[unit]
		controlOwner[unit] = nil
		if unitFrame then
			ReleaseControl(unitFrame)
		end
	end

	-- ═══ 姓名板事件统一注册（进/出各注册一次，按 左 → 上 → 右 顺序执行）═══
	-- ns.event 的回调第一个参数是事件名，故调度函数签名写 (_, unit)
	local function OnPlateAdded(_, unit)
		local namePlate = C_NamePlate.GetNamePlateForUnit(unit, false)
		if not namePlate then return end
		local unitFrame = namePlate.UnitFrame
		if not unitFrame then return end
		-- 只对敌对单位建容器（显示什么由光环组过滤决定）
		if unitFrame:IsFriend() then return end

		OnLeftPlateAdded(unit, unitFrame)
		OnTopPlateAdded(unit, unitFrame)
		OnRightPlateAdded(unit, unitFrame)
	end

	local function OnPlateRemoved(_, unit)
		OnLeftPlateRemoved(unit)
		OnTopPlateRemoved(unit)
		OnRightPlateRemoved(unit)
	end

	ns.event("NAME_PLATE_UNIT_ADDED", OnPlateAdded)
	ns.event("NAME_PLATE_UNIT_REMOVED", OnPlateRemoved)

	-- ═══ 进游戏预创建对象池（避免战斗中临时创建造成掉帧）═══
	ns.event("PLAYER_LOGIN", function()
		for i = 1, POOL_SIZE do
			dispelFree[i] = NewDispelContainer()
			topFree[i] = NewTopContainer()
			controlFree[i] = NewControlContainer()
		end
	end)
end

