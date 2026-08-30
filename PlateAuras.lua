local _, ns = ...

local function SetCooldownText(self)
    local success, region = pcall(function() 
        return self.Cooldown:GetRegions()
    end)
    if success and region then
        if type(region.SetFont) == "function" then
            region:SetFontObject("PC_FontOutline")
            region:SetFontHeight(self:GetHeight()/1.5 * PlateColorDB.auraText1)
        end
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

	-- 配置容器光环组（每个姓名板的容器首次创建时调用）
	local function SetupDispelContainer(container)
		-- 仅显示队伍可驱散：勾选时只显示队伍/团队可驱散的光环（激怒、魔法等）
		local dispelFilter = GetDispelFilter()
		container:AddAuraGroup("disBuff", dispelFilter, {
			maxFrameCount = 2,
			layout = { elementSpacing = 2, groupSpacing = 2 },
			initializeFrame = function(btn)
				local size = 25
				btn:SetSize(size*PlateColorDB.auraLScale, size*PlateColorDB.auraLScale)--NamePlateConstants.AURA_ITEM_HEIGHT == 25
				btn:SetTooltipAnchorPoint("ANCHOR_TOPRIGHT")
				local icon = btn:CreateTexture(nil, "ARTWORK")
				icon:SetAllPoints(btn)
				icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
				btn:SetIcon(icon)
				local cooldown = CreateFrame("Cooldown", nil, btn, "CooldownFrameTemplate")
				cooldown:SetAllPoints(btn)
				cooldown:SetHideCountdownNumbers(false)
				cooldown:SetReverse(true)--反转冷却动画方向
				btn:SetDurationCooldown(cooldown)
				--冷却倒数文本字号为光环尺寸的比例
				local cdRegion = cooldown:GetRegions()
				if cdRegion and type(cdRegion.SetFont) == "function" then
					cdRegion:SetFontObject("PC_FontOutline")
					cdRegion:SetFontHeight(size*PlateColorDB.auraLScale/1.6)
				end
				--独立叠层/边框容器: 层级在冷却之上(+2), 不随冷却隐藏
				local overlay = CreateFrame("Frame", nil, btn)
				overlay:SetAllPoints(btn)
				overlay:SetFrameLevel(btn:GetFrameLevel() + 2)
				local count = overlay:CreateFontString(nil, "OVERLAY", "PC_FontOutline")
				count:SetPoint("BOTTOMRIGHT", btn, 2, -2)
				count:SetVertexColor(1, 1, 1)
				count:SetFontHeight(size/1.75)
				btn:SetApplicationCount(count, {})
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
			end,
		})
		container:AddAuraGroup("otherBuff", "HELPFUL|IMPORTANT|!DISPELLABLE", {
			maxFrameCount = 2,
			layout = { elementSpacing = 2, groupSpacing = 2 },
			initializeFrame = function(btn)
				local size = 25
				btn:SetSize(size*PlateColorDB.auraLScale, size*PlateColorDB.auraLScale)
				btn:SetTooltipAnchorPoint("ANCHOR_TOPRIGHT")
				local icon = btn:CreateTexture(nil, "ARTWORK")
				icon:SetAllPoints(btn)
				icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
				btn:SetIcon(icon)
				local cooldown = CreateFrame("Cooldown", nil, btn, "CooldownFrameTemplate")
				cooldown:SetAllPoints(btn)
				cooldown:SetHideCountdownNumbers(false)
				btn:SetDurationCooldown(cooldown)
				--冷却倒数文本字号为光环尺寸的比例
				local cdRegion = cooldown:GetRegions()
				if cdRegion and type(cdRegion.SetFont) == "function" then
					cdRegion:SetFontObject("PC_FontOutline")
					cdRegion:SetFontHeight(size*PlateColorDB.auraLScale/1.6)
				end
				--独立叠层容器: 层级在冷却之上(+2), 不随冷却隐藏
				local overlay = CreateFrame("Frame", nil, btn)
				overlay:SetAllPoints(btn)
				overlay:SetFrameLevel(btn:GetFrameLevel() + 2)
				local count = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormal")
				count:SetPoint("BOTTOMRIGHT", btn, 2, -2)
				count:SetVertexColor(1, 1, 1)
				count:SetFontHeight(size/1.75)
				btn:SetApplicationCount(count, {})
			end,
		})
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
			if unitFrame.PC_DispelAuras then
				unitFrame.PC_DispelAuras:Hide()
			end
			return
		end

		-- 容器不存在则创建（作为 healthBar 子级，随血条显示/隐藏、继承框架层级）
		if not unitFrame.PC_DispelAuras then
			unitFrame.PC_DispelAuras = CreateFrame("AuraContainer", nil, unitFrame.healthBar, "CustomAuraContainerTemplate")
			SetupDispelContainer(unitFrame.PC_DispelAuras)
		end
		unitFrame.PC_DispelAuras:SetUnit(unit)
		unitFrame.PC_DispelAuras:Show()
		C_Timer.After(0.5, function()
			local anchor = unitFrame.abs or unitFrame.healthBar
			if not anchor or not anchor:IsShown() then return end
			unitFrame.PC_DispelAuras:ClearAllPoints()
			unitFrame.PC_DispelAuras:SetPoint("RIGHT", anchor, "LEFT", -2, 0)
		end)
	end)

	-- ═══ 姓名板上方自定义减益容器（两组）═══
	-- 按钮样式初始化（与左侧 otherBuff 组一致）
	local function InitTopDebuffButton(btn)
		local size = 20
		btn:SetSize(size*PlateColorDB.auraTopScale, size*PlateColorDB.auraTopScale)
		btn:EnableMouse(false)--完全鼠标穿透，不阻挡点击（设了穿透后不能再写 SetTooltipAnchorPoint 等鼠标提示相关，否则穿透失败）
		local icon = btn:CreateTexture(nil, "ARTWORK")
		icon:SetAllPoints(btn)
		icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
		btn:SetIcon(icon)
		local cooldown = CreateFrame("Cooldown", nil, btn, "CooldownFrameTemplate")
		cooldown:SetAllPoints(btn)
		cooldown:SetHideCountdownNumbers(false)
		cooldown:SetReverse(true)--减益冷却方向
		btn:SetDurationCooldown(cooldown)
		--冷却倒数文本字号为光环尺寸的一半
		local cdRegion = cooldown:GetRegions()
		if cdRegion and type(cdRegion.SetFont) == "function" then
			cdRegion:SetFontObject("PC_FontOutline")
			cdRegion:SetFontHeight(size*PlateColorDB.auraTopScale/1.6)
		end
		--独立叠层容器: 层级在冷却之上(+2), 不随冷却隐藏
		local overlay = CreateFrame("Frame", nil, btn)
		overlay:SetAllPoints(btn)
		overlay:SetFrameLevel(btn:GetFrameLevel() + 2)
		local count = overlay:CreateFontString(nil, "OVERLAY", "PC_FontOutline")
		count:SetPoint("BOTTOMRIGHT", btn, 2, -2)
		count:SetVertexColor(1, 1, 1)
		count:SetFontHeight(size/1.75)
		btn:SetApplicationCount(count, {})
	end

	-- 由 topDotList 生成 topMine 组应显示的 dot 法术集合（show=true 的）
	local function GetTopMineSpellMap()
		local spellMap = {}
		for spellID, info in pairs(PlateColorDB.topDotList or {}) do
			if info and info.show then
				spellMap[spellID] = true
			end
		end
		return spellMap
	end

	-- 由 topDotList 生成应从 topShown（姓名板默认显示）排除的 dot 法术集合
	-- 已配置的法术（无论显示/隐藏）都从 topShown 排除，避免与 topMine 重复；
	-- show 的再由 topMine 显示一次，hide 的不进 topMine（完全隐藏）
	local function GetTopShownExcludeMap()
		local excludeMap = {}
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
	local function SetupTopDebuffContainer(container)
		-- 组1：敌对 + 应显示在姓名板（暴雪同款 INCLUDE_NAME_PLATE_ONLY + nameplateShowPersonal）+ 排除控制 + 排除隐藏的 dot
		container:AddAuraGroup("topShown", "HARMFUL|PLAYER|INCLUDE_NAME_PLATE_ONLY|!CROWD_CONTROL", {
			layout = { elementSpacing = 1, groupSpacing = 1},
			candidateFilters = { excludeSpellIDs = GetTopShownExcludeMap(), nameplateShowPersonal = true },
			initializeFrame = InitTopDebuffButton,
		})
		-- 组2：敌对 + 我释放的 + 排除应显示在姓名板 + 排除控制 + 仅监控指定法术
		container:AddAuraGroup("topMine", "HARMFUL|PLAYER|!INCLUDE_NAME_PLATE_ONLY|!CROWD_CONTROL", {
			layout = { elementSpacing = 1, groupSpacing = 1 },
			candidateFilters = { includeSpellIDs = GetTopMineSpellMap() }, -- 由 topDotList 生成，空则只显示勾选的法术
			initializeFrame = InitTopDebuffButton,
		})
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
			if unitFrame.PC_TopDebuffAuras then
				unitFrame.PC_TopDebuffAuras:Hide()
			end
			return
		end

		-- 容器不存在则创建（作为 unitFrame 子级，与暴雪 AurasFrame 一致，锚定到血条左上）
		if not unitFrame.PC_TopDebuffAuras then
			unitFrame.PC_TopDebuffAuras = CreateFrame("AuraContainer", nil, unitFrame, "CustomAuraContainerTemplate")
			unitFrame.PC_TopDebuffAuras:EnableMouse(false)--完全鼠标穿透，不阻挡点击血条
			SetupTopDebuffContainer(unitFrame.PC_TopDebuffAuras)
		end
		unitFrame.PC_TopDebuffAuras:SetUnit(unit)
		unitFrame.PC_TopDebuffAuras:Show()
		-- 左下始终锚定在血条左上，名字在血条上方(1/2)时额外加上名字高度避免重叠
		C_Timer.After(0.5, function()
			if not unitFrame or not unitFrame:IsShown() then return end
			local healthBar = unitFrame.HealthBarsContainer.healthBar
			if not healthBar or not healthBar:IsShown() then return end
			local debuffPadding = CVarCallbackRegistry:GetCVarNumberOrDefault(NamePlateConstants.DEBUFF_PADDING_CVAR)
			local nameHeight = 0
			if PlateColorDB.namePoint == 1 or PlateColorDB.namePoint == 2 then
				-- 直接用设置的名字尺寸，避免读取 GetHeight 返回秘密值
				nameHeight = PlateColorDB.nameScale + PlateColorDB.nameVoffset + 2
			end
			unitFrame.PC_TopDebuffAuras:ClearAllPoints()
			PixelUtil.SetPoint(unitFrame.PC_TopDebuffAuras, "BOTTOMLEFT", healthBar, "TOPLEFT", 0, debuffPadding + nameHeight)
		end)
	end)
end

