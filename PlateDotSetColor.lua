local _, ns = ...




-- 任意一个监控的法术存在就变色（OR 逻辑）：
-- PlateColorDB.mydotlist 里任意一个 spellID 在场，血条就染成 mydotcolor1 的颜色。
-- 全部都不在则不变色。
-- 全程不读取光环状态（12.x secrets 禁止），由安全容器判断。
--
-- 即时生效：
--   ns.UpdateAuraColor()  -- 颜色改动时调用，只更新已有纹理颜色
--   ns.RefreshAuraColor() -- mydotlist 增减时调用，只更新 includeSpellIDs 过滤

if not DoesTemplateExist("CustomAuraContainerTemplate") then return end

local containers = {}   -- unitFrame -> container

-- 血条染色颜色
local function GetColor()
	return PlateColorDB.mydotcolor1 or ns.Defaults.mydotcolor1
end

-- MM 染色颜色
local function GetMMColor()
	return PlateColorDB.mydotcolor2 or ns.Defaults.mydotcolor2
end

-- 由 mydotlist 生成两个集合：colorMap（血条染色）、mmMap（MM 染色）
local function BuildSpellMaps()
	local colorMap, mmMap = {}, {}
	for spellID, info in pairs(PlateColorDB.mydotlist or {}) do
		if info.bar then colorMap[spellID] = true end
		if info.mm then mmMap[spellID] = true end
	end
	return colorMap, mmMap
end

-- 为某根血条建容器（含染色纹理）。unitFrame 会被 Blizzard 池化复用，
-- 已有容器时直接切换追踪单位即可，无需销毁重建。
local function BuildContainer(unitFrame)
	local healthBar = unitFrame.healthBar
	if not healthBar then return end

	-- 复用已有容器：仅切换追踪单位并重新显示
	local container = containers[unitFrame]
	if container then
		container:SetUnit(unitFrame.unit)
		container:SetEnabled(true)
		container:Show()
		return
	end

	container = CreateFrame("AuraContainer", nil, healthBar, "CustomAuraContainerTemplate")
	container:SetFrameLevel(healthBar:GetFrameLevel() - 1)
	container.pcTextures = {}    -- 收集血条染色纹理，供颜色即时更新
	container.pcMMTextures = {}  -- 收集 MM 染色纹理，供颜色即时更新

	local colorMap, mmMap = BuildSpellMaps()

	local bar = GetColor()
	local mmColor = GetMMColor()
	-- barColor 分组：使用血条材质纹理染色
	container:AddAuraGroup("barColor", "HARMFUL|PLAYER", {
		maxFrameCount = 1,
		initializeFrame = function(btn)
			local tex = btn:CreateTexture(nil, "OVERLAY")
			local fill = healthBar:GetStatusBarTexture() or healthBar
			-- 使用血条材质纹理，并用染色颜色着色（与血条材质保持一致）
			tex:SetTexture(ns.HpTextures[PlateColorDB.hpbarTexture] or ns.HpTextures["PC-White"])
			tex:SetVertexColor(bar.r, bar.g, bar.b, bar.a or 1)
			tex:SetPoint("TOPLEFT", fill, "TOPLEFT", 1, -1)
			tex:SetPoint("BOTTOMRIGHT", fill, "BOTTOMRIGHT", 0, 1)
			-- 血条材质配置了遮罩时，复用同一遮罩，保证圆角/边框形状一致
			if healthBar.customMask then
				tex:AddMaskTexture(healthBar.customMask)
			end
			container.pcTextures[#container.pcTextures + 1] = tex
		end,
	})

	-- dotMM 分组：用 dotMM.png 材质覆盖到血条上（提高按钮层级，盖在 barColor 之上）
	container:AddAuraGroup("dotMM", "HARMFUL|PLAYER", {
		maxFrameCount = 1,
		initializeFrame = function(btn)
			btn:SetFrameLevel(healthBar:GetFrameLevel() + 1)
			local tex = btn:CreateTexture(nil, "OVERLAY")
			tex:SetTexture("Interface\\Addons\\PlateColor\\texture\\Bar\\dotMM.png")
			tex:SetVertexColor(mmColor.r, mmColor.g, mmColor.b, mmColor.a or 1)
			tex:SetPoint("TOPLEFT", healthBar, "TOPLEFT", 1, -1)
			tex:SetPoint("BOTTOMRIGHT", healthBar, "BOTTOMRIGHT", 0, 1)
			-- 血条材质配置了遮罩时，复用同一遮罩，保证圆角/边框形状一致
			if healthBar.customMask then
				tex:AddMaskTexture(healthBar.customMask)
			end
			container.pcMMTextures[#container.pcMMTextures + 1] = tex
		end,
	})

	container:SetAuraGroupCandidateFilters("barColor", { includeSpellIDs = colorMap })
	container:SetAuraGroupMaxFrameCount("barColor", 1)
	container:SetAuraGroupCandidateFilters("dotMM", { includeSpellIDs = mmMap })
	container:SetAuraGroupMaxFrameCount("dotMM", 1)
	containers[unitFrame] = container
	container:SetUnit(unitFrame.unit)
	container:SetEnabled(true)
	container:Show()
end

-- 挂起重试：限制中 SetVertexColor 失败（如战斗/M+ 的 Forbidden）则挂起，解除限制时自动重试
local retryHandle  -- 非 nil 即已挂起

-- 颜色改动：只更新已有纹理颜色（无需重建，即时生效）
function ns.UpdateAuraColor()
	local failed = false
	local bar = GetColor()
	local mmColor = GetMMColor()
	for _, container in pairs(containers) do
		for _, tex in ipairs(container.pcTextures or {}) do
			-- pcall 兜底：战斗/M+ 等秘密环境 AuraButton 纹理 Forbidden
			local ok = pcall(function()
				tex:SetVertexColor(bar.r, bar.g, bar.b, bar.a or 1)
			end)
			if not ok and not failed then
				failed = true
				local warnText = GetLocale():match("^zh") and "修改失败，环境受限" or "Modification failed, environment restricted"
				UIErrorsFrame:AddExternalWarningMessage(warnText)
			end
		end
		for _, tex in ipairs(container.pcMMTextures or {}) do
			local ok = pcall(function()
				tex:SetVertexColor(mmColor.r, mmColor.g, mmColor.b, mmColor.a or 1)
			end)
			if not ok and not failed then
				failed = true
				local warnText = GetLocale():match("^zh") and "修改失败，环境受限" or "Modification failed, environment restricted"
				UIErrorsFrame:AddExternalWarningMessage(warnText)
			end
		end
	end
	-- 有失败则挂起（未挂起时才注册），解除限制时自动重试
	if failed and not retryHandle then
		retryHandle = EventRegistry:RegisterFrameEventAndCallbackWithHandle("ADDON_RESTRICTION_STATE_CHANGED", function(_owner, type, state)
			if state == Enum.AddOnRestrictionState.Inactive then
				retryHandle:Unregister()
				retryHandle = nil
				ns.UpdateAuraColor()
			end
		end)
	end
end

-- 启用/禁用某单位的 DOT 染色（供 UpdateHpbarColor 在血条变色时隐藏 DOT 染色）
function ns.SetAuraColorEnabled(unitFrame, enabled)
	local container = containers[unitFrame]
	if not container then return end
	if enabled then
		container:SetEnabled(true)
		container:Show()
	else
		container:SetEnabled(false)
		container:Hide()
	end
end

-- mydotlist 增减：只需更新各容器的 includeSpellIDs 过滤，无需重建容器
function ns.RefreshAuraColor()
	local colorMap, mmMap = BuildSpellMaps()
	for _, container in pairs(containers) do
		container:SetAuraGroupCandidateFilters("barColor", { includeSpellIDs = colorMap })
		container:SetAuraGroupCandidateFilters("dotMM", { includeSpellIDs = mmMap })
	end
end

ns.event("NAME_PLATE_UNIT_ADDED", function(_, unit)
	if UnitIsUnit(unit, "player") then return end

	local namePlate = C_NamePlate.GetNamePlateForUnit(unit, false)
	if not namePlate then return end
	local unitFrame = namePlate.UnitFrame
	if not unitFrame then return end

	-- mydotlist 为空表时不追踪（隐藏已有容器，避免残留）
	if not next(PlateColorDB.mydotlist or {}) then
		if containers[unitFrame] then
			containers[unitFrame]:Hide()
		end
		return
	end

	-- 非可攻击目标、或玩家目标（如敌方玩家）：隐藏已有容器并跳过，不给玩家血条染色
	if not UnitCanAttack("player", unit) or UnitIsPlayer(unit) then
		if containers[unitFrame] then
			containers[unitFrame]:Hide()
		end
		return
	end

	BuildContainer(unitFrame)
end)


