local _, ns = ...




-- 任意一个监控的法术存在就变色（OR 逻辑）：
-- PlateColorDB.dotlist 里任意一个 spellID 在场，血条就染成 dotcolor1 的颜色。
-- 全部都不在则不变色。
-- 全程不读取光环状态（12.x secrets 禁止），由安全容器判断。
--
-- 即时生效：
--   ns.UpdateAuraColor()  -- 颜色改动时调用，只更新已有纹理颜色
--   ns.RefreshAuraColor() -- dotlist 增减时调用，只更新 includeSpellIDs 过滤

if not DoesTemplateExist("CustomAuraContainerTemplate") then return end

local containers = {}   -- unitFrame -> container

-- 血条染色颜色
local function GetColor()
	return PlateColorDB.dotcolor1 or { r = 1, g = 0.35, b = 0.75, a = 1 }
end

-- 由 dotlist 生成参与血条染色的 spellID 集合
local function BuildSpellMaps()
	local colorMap = {}
	for spellID in pairs(PlateColorDB.dotlist or {}) do
		colorMap[spellID] = true
	end
	return colorMap
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
	container.pcTextures = {}   -- 收集染色纹理，供颜色即时更新

	local colorMap = BuildSpellMaps()

	local color = GetColor()
	-- 单组即可：includeSpellIDs 塞入所有参与血条染色的法术，任一在场即显示（OR 逻辑）
	container:AddAuraGroup("auraColor", "HARMFUL|PLAYER", {
		maxFrameCount = 1,
		initializeFrame = function(btn)
			local tex = btn:CreateTexture(nil, "OVERLAY")
			local fill = healthBar:GetStatusBarTexture() or healthBar
			-- 使用血条材质纹理，并用染色颜色着色（与血条材质保持一致）
			tex:SetTexture(ns.HpTextures[PlateColorDB.hpbarTexture] or ns.HpTextures["PC-White"])
			tex:SetVertexColor(color.r, color.g, color.b, color.a)
			tex:SetPoint("TOPLEFT", fill, "TOPLEFT", 1, -1)
			tex:SetPoint("BOTTOMRIGHT", fill, "BOTTOMRIGHT", 0, 1)
			-- 血条材质配置了遮罩时，复用同一遮罩，保证圆角/边框形状一致
			if healthBar.customMask then
				tex:AddMaskTexture(healthBar.customMask)
			end
			container.pcTextures[#container.pcTextures + 1] = tex
		end,
	})

	container:SetAuraGroupCandidateFilters("auraColor", { includeSpellIDs = colorMap })
	container:SetAuraGroupMaxFrameCount("auraColor", 1)
	containers[unitFrame] = container
	container:SetUnit(unitFrame.unit)
	container:SetEnabled(true)
	container:Show()
end

-- 颜色改动：只更新已有纹理颜色（无需重建，即时生效）
function ns.UpdateAuraColor()
	local color = GetColor()
	for _, container in pairs(containers) do
		for _, tex in ipairs(container.pcTextures or {}) do
			tex:SetVertexColor(color.r, color.g, color.b, color.a)
		end
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

-- dotlist 增减：只需更新各容器的 includeSpellIDs 过滤，无需重建容器
function ns.RefreshAuraColor()
	local colorMap = BuildSpellMaps()
	for _, container in pairs(containers) do
		container:SetAuraGroupCandidateFilters("auraColor", { includeSpellIDs = colorMap })
	end
end

ns.event("NAME_PLATE_UNIT_ADDED", function(_, unit)
	if UnitIsUnit(unit, "player") then return end

	local namePlate = C_NamePlate.GetNamePlateForUnit(unit, false)
	if not namePlate then return end
	local unitFrame = namePlate.UnitFrame
	if not unitFrame then return end

	-- dotlist 为空表时不追踪（隐藏已有容器，避免残留）
	if not next(PlateColorDB.dotlist or {}) then
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


