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

--12.1 AuraContainer 血条左侧仅显示敌方可驱散光环
if DoesTemplateExist("CustomAuraContainerTemplate") then

	-- 光环按钮样式初始化：图标/冷却/层数/边框
	-- size: 基础尺寸; scale: 缩放比例; tooltip: true=保留鼠标提示(不填则完全鼠标穿透，二者互斥)
	-- reverse: 冷却是否反向; needBorder: 是否加驱散边框(含驱散类型染色，不填则不加)
	local function InitAuraButton(btn, size, scale, tooltip, reverse, needBorder)
		local shownSize = size*scale
		btn:SetSize(shownSize, shownSize)
		if tooltip then
			btn:SetTooltipAnchorPoint("ANCHOR_TOPRIGHT")
		else
			btn:EnableMouse(false)--完全鼠标穿透，不阻挡点击
		end
		local icon = btn:CreateTexture(nil, "ARTWORK")
		icon:SetAllPoints(btn)--图标不裁剪，显示完整贴图
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
			cdText:SetFontHeight(shownSize/1.6)
		end
		--独立叠层/边框容器: 层级在冷却之上(+2), 不随冷却隐藏
		local overlay = CreateFrame("Frame", nil, btn)
		overlay:SetAllPoints(btn)
		overlay:SetFrameLevel(btn:GetFrameLevel() + 2)
		local count = overlay:CreateFontString(nil, "OVERLAY", "PC_FontOutline")
		count:SetPoint("BOTTOMRIGHT", btn, 3, -3)
		count:SetVertexColor(1, 1, 1)
		count:SetFontHeight(shownSize/1.8)
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

	-- 关闭自带的左侧增益光环/上方减益的 cvar，因为我们接下来自己创建(仅在功能开启时接管)
	EventUtil.ContinueOnPlayerLogin(function()
		-- 左侧增益光环：关闭敌方 NPC 自带的增益显示（由我们的 PC_DispelAuras 接管）
		if PlateColorDB.auraLEnable then
			ns.SetCVar("nameplateEnemyNpcAuraDisplay", Enum.NamePlateEnemyNpcAuraDisplay.Buffs, false)
		end
		-- 上方减益专属：关闭敌方 NPC 与敌方玩家的减益显示位（由我们的 PC_TopDebuffAuras 接管，避免重复）
		if PlateColorDB.auraTopEnable then
			ns.SetCVar("nameplateEnemyNpcAuraDisplay", Enum.NamePlateEnemyNpcAuraDisplay.Debuffs, false)
			ns.SetCVar("nameplateEnemyPlayerAuraDisplay", Enum.NamePlateEnemyPlayerAuraDisplay.Debuffs, false)
		end
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

	-- 左侧光环额外监控的特定减益法术（在此添加 [法术ID] = true 即可，不限施放者）
	local LEFT_DEBUFF_SPELLS = {
		[1217960] = true, -- 装弹手枪
	}

	-- 配置容器光环组（每个姓名板的容器首次创建时调用）
	local function SetupDispelContainer(container)
		-- 仅显示队伍可驱散：勾选时只显示队伍/团队可驱散的光环（激怒、魔法等）
		local dispelFilter = GetDispelFilter()
		container:AddAuraGroup("disBuff", dispelFilter, {
			maxFrameCount = 2,
			layout = { elementSpacing = 2, groupSpacing = 2 },
			initializeFrame = function(btn)
				InitAuraButton(btn, 25, PlateColorDB.auraLScale, true, true, true)--NamePlateConstants.AURA_ITEM_HEIGHT == 25
			end,
		})
		container:AddAuraGroup("otherBuff", "HELPFUL|IMPORTANT|!DISPELLABLE", {
			maxFrameCount = 2,
			layout = { elementSpacing = 2, groupSpacing = 2 },
			initializeFrame = function(btn)
				InitAuraButton(btn, 25, PlateColorDB.auraLScale, true, false)
			end,
		})
		-- 额外监控的特定减益：所有来源，仅显示 LEFT_DEBUFF_SPELLS 内的法术
		container:AddAuraGroup("myDebuff", "HARMFUL", {
			layout = { elementSpacing = 2, groupSpacing = 2 },
			candidateFilters = { includeSpellIDs = CopyTable(LEFT_DEBUFF_SPELLS) },
			initializeFrame = function(btn)
				InitAuraButton(btn, 25, PlateColorDB.auraLScale, true, true)
			end,
		})
	end

	-- ═══ 光环容器对象池：进游戏预创建 POOL_SIZE 个，用时取用、移除时归还 ═══
	local POOL_SIZE = 40
	local dispelFree = {}      -- 左侧空闲容器
	local dispelOwner = {}     -- 左侧 [unit] = unitFrame（出借归属，用于 REMOVED 归还）

	local function NewDispelContainer()
		local c = CreateFrame("AuraContainer", nil, UIParent, "CustomAuraContainerTemplate")
		SetupDispelContainer(c)
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

	ns.event("NAME_PLATE_UNIT_ADDED", function(event, unit)
		-- 左侧增益光环开关关闭时直接跳过
		if not PlateColorDB.auraLEnable then return end

		local namePlate = C_NamePlate.GetNamePlateForUnit(unit, false)
		if not namePlate then return end
		local unitFrame = namePlate.UnitFrame
		if not unitFrame then return end

		-- 玩家单位（含敌方玩家）不显示驱散光环，仅敌方 NPC 处理
		if UnitIsPlayer(unit) or not UnitCanAttack("player", unit) then
			ReleaseDispel(unitFrame)
			return
		end

		-- 从池取容器（池空则新建），作为 healthBar 子级，随血条显示/隐藏、继承框架层级
		local container = AcquireDispel(unitFrame)
		dispelOwner[unit] = unitFrame
		container:SetUnit(unit)
		container:Show()
		C_Timer.After(0.5, function()
			local anchor = unitFrame.abs or unitFrame.healthBar
			if not anchor or not anchor:IsShown() then return end
			local c = unitFrame.PC_DispelAuras
			if not c then return end--期间已归还
			c:ClearAllPoints()
			c:SetPoint("RIGHT", anchor, "LEFT", -2, 0)
		end)
	end)

	ns.event("NAME_PLATE_UNIT_REMOVED", function(event, unit)
		local unitFrame = dispelOwner[unit]
		dispelOwner[unit] = nil
		if unitFrame then
			ReleaseDispel(unitFrame)
		end
	end)

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
				pcall(unitFrame.PC_TopDebuffAuras.SetAuraGroupCandidateFilters, unitFrame.PC_TopDebuffAuras, "topShown", { excludeSpellIDs = excludeMap, nameplateShowPersonal = true })
			end
		end
	end

	-- 配置姓名板上方减益容器（每个姓名板的容器首次创建时调用）
	-- 数量无限（不设 maxFrameCount，默认即 math.huge）；组内元素间距 elementSpacing；组间间距 groupSpacing
	-- 按钮样式：鼠标穿透、反转冷却、不加边框
	local function SetupTopDebuffContainer(container)
		-- 组1：敌对 + 我释放的 + 排除应显示在姓名板 + 排除控制 + 仅监控指定法术，且只显示剩余时间最长的1个
		container:AddAuraGroup("topSingle", "HARMFUL|PLAYER|!INCLUDE_NAME_PLATE_ONLY|!CROWD_CONTROL", {
			maxFrameCount = 1,
			sortMethod = AuraContainerSortMethod.ExpirationOnly,--按到期时间排序
			sortDirection = AuraContainerSortDirection.Reverse,--反向 => 剩余时间最长的排在首位
			layout = { elementSpacing = 1, groupSpacing = 1 },
			-- 开关关闭时传空表 => topSingle 一个都不显示（血之疫病回归普通减益显示）
			candidateFilters = { includeSpellIDs = PlateColorDB.auraTopSingle ~= false and CopyTable(TOP_SINGLE_SPELLS) or {} },
			initializeFrame = function(btn)
				InitAuraButton(btn, 20, PlateColorDB.auraTopScale, false, true)
			end,
		})
		-- 组2：敌对 + 应显示在姓名板（暴雪同款 INCLUDE_NAME_PLATE_ONLY + nameplateShowPersonal）+ 排除控制 + 排除隐藏的 dot
		container:AddAuraGroup("topShown", "HARMFUL|PLAYER|INCLUDE_NAME_PLATE_ONLY|!CROWD_CONTROL", {
			layout = { elementSpacing = 1, groupSpacing = 1},
			candidateFilters = { excludeSpellIDs = GetTopShownExcludeMap(), nameplateShowPersonal = true },
			initializeFrame = function(btn)
				InitAuraButton(btn, 20, PlateColorDB.auraTopScale, false, true)
			end,
		})
		-- 组3：敌对 + 我释放的 + 排除应显示在姓名板 + 排除控制 + 仅监控指定法术
		container:AddAuraGroup("topMine", "HARMFUL|PLAYER|!INCLUDE_NAME_PLATE_ONLY|!CROWD_CONTROL", {
			layout = { elementSpacing = 1, groupSpacing = 1 },
			candidateFilters = { includeSpellIDs = GetTopMineSpellMap() }, -- 由 topDotList 生成，空则只显示勾选的法术
			initializeFrame = function(btn)
				InitAuraButton(btn, 20, PlateColorDB.auraTopScale, false, true)
			end,
		})
	end

	-- ═══ 上方光环容器对象池：进游戏预创建 POOL_SIZE 个，用时取用、移除时归还 ═══
	local topFree = {}         -- 上方空闲容器
	local topOwner = {}        -- 上方 [unit] = unitFrame（出借归属，用于 REMOVED 归还）

	local function NewTopContainer()
		local c = CreateFrame("AuraContainer", nil, UIParent, "CustomAuraContainerTemplate")
		c:EnableMouse(false)--完全鼠标穿透，不阻挡点击血条
		SetupTopDebuffContainer(c)
		c:Hide()
		return c
	end

	-- 按当前设置刷新过滤（池中空闲容器可能错过了列表改动）
	local function RefreshTopFilters(c)
		pcall(c.SetAuraGroupCandidateFilters, c, "topSingle", { includeSpellIDs = PlateColorDB.auraTopSingle ~= false and CopyTable(TOP_SINGLE_SPELLS) or {} })
		pcall(c.SetAuraGroupCandidateFilters, c, "topMine", { includeSpellIDs = GetTopMineSpellMap() })
		pcall(c.SetAuraGroupCandidateFilters, c, "topShown", { excludeSpellIDs = GetTopShownExcludeMap(), nameplateShowPersonal = true })
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

	ns.event("NAME_PLATE_UNIT_ADDED", function(event, unit)
		-- 上方自定义减益容器开关关闭时跳过
		if not PlateColorDB.auraTopEnable then return end

		local namePlate = C_NamePlate.GetNamePlateForUnit(unit, false)
		if not namePlate then return end
		local unitFrame = namePlate.UnitFrame
		if not unitFrame then return end

		-- 仅敌对单位（含敌对 NPC 与玩家）显示
		if not UnitCanAttack("player", unit) then
			ReleaseTop(unitFrame)
			return
		end

		-- 从池取容器（池空则新建），作为 unitFrame 子级，锚定到血条左上
		local container = AcquireTop(unitFrame)
		topOwner[unit] = unitFrame
		container:SetUnit(unit)
		container:Show()
		-- 左下始终锚定在血条左上，名字在血条上方(1/2)时额外加上名字高度避免重叠
		C_Timer.After(0.5, function()
			if not unitFrame or not unitFrame:IsShown() then return end
			local healthBar = unitFrame.HealthBarsContainer.healthBar
			if not healthBar or not healthBar:IsShown() then return end
			local c = unitFrame.PC_TopDebuffAuras
			if not c then return end--期间已归还
			local debuffPadding = CVarCallbackRegistry:GetCVarNumberOrDefault(NamePlateConstants.DEBUFF_PADDING_CVAR)
			local nameHeight = 0
			if PlateColorDB.namePoint == 1 or PlateColorDB.namePoint == 2 then
				-- 直接用设置的名字尺寸，避免读取 GetHeight 返回秘密值
				nameHeight = PlateColorDB.nameScale + PlateColorDB.nameVoffset + 2
			end
			c:ClearAllPoints()
			PixelUtil.SetPoint(c, "BOTTOMLEFT", healthBar, "TOPLEFT", 0, debuffPadding + nameHeight)
		end)
	end)

	ns.event("NAME_PLATE_UNIT_REMOVED", function(event, unit)
		local unitFrame = topOwner[unit]
		topOwner[unit] = nil
		if unitFrame then
			ReleaseTop(unitFrame)
		end
	end)

	-- ═══ 进游戏预创建对象池（避免战斗中临时创建造成掉帧）═══
	ns.event("PLAYER_LOGIN", function()
		for i = 1, POOL_SIZE do
			dispelFree[i] = NewDispelContainer()
			topFree[i] = NewTopContainer()
		end
	end)
end

