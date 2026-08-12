local _, ns = ...




-- 任意一个监控的法术存在就变色（OR 逻辑）：
-- PlateColorDB.dotlist 里任意一个 spellID 在场，血条就染成 dotcolor1 的颜色、名字染成 dotcolor2。
-- 每个法术可通过 color / text 开关分别控制是否应用到血条 / 名字。
-- 全部都不在则不变色。
-- 全程不读取光环状态（12.x secrets 禁止），由安全容器判断。
--
-- 即时生效：
--   ns.UpdateAuraColor()  -- 颜色改动时调用，只更新已有纹理颜色
--   ns.RefreshAuraColor() -- dotlist 增减时调用，只更新 includeSpellIDs 过滤

if not DoesTemplateExist("CustomAuraContainerTemplate") then return end

-- 设置光环提示显示法术 ID（由 AddSetClickB 的 setfun 无参调用，读取 DB 状态）
-- 使用 12.1 原生 CVar tooltipShowAuraSpellIDs（不会跨会话持久化，需登录时重新设置）
function ns.SetAuraTipID()
	C_CVar.SetCVar("tooltipShowAuraSpellIDs", PlateColorDB.auraTipID and "1" or "0")
end

-- 进游戏时加载一次：将 DB 中的设置同步到 CVar（原生 CVar 登录后重置，需重新设置）
ns.event("PLAYER_LOGIN", function()
	if ns.SetAuraTipID then ns.SetAuraTipID() end
end, true)

local containers = {}   -- unitFrame -> container

-- 血条染色颜色
local function GetColor()
	return PlateColorDB.dotcolor1 or { r = 1, g = 0.35, b = 0.75, a = 1 }
end

-- 名字变色颜色
local function GetTextColor()
	return PlateColorDB.dotcolor2 or { r = 1, g = 1, b = 1, a = 1 }
end

-- 由 dotlist 生成两个 map：colorMap（参与血条染色）、textMap（参与名字变色）
-- 兼容旧数据：旧值直接是法术名（字符串），只启用血条染色，不启用名字变色
local function BuildSpellMaps()
	local colorMap, textMap = {}, {}
	for spellID, info in pairs(PlateColorDB.dotlist or {}) do
		if type(info) == "table" then
			if info.color then colorMap[spellID] = true end
			if info.text then textMap[spellID] = true end
		else
			-- 旧格式：值为法术名，只启用血条染色
			colorMap[spellID] = true
		end
	end
	return colorMap, textMap
end

-- 为某根血条建容器（含染色纹理 + 名字覆盖）。
-- 每次调用都销毁旧容器并重建：unitFrame 会被 Blizzard 池化复用，
-- 且 AuraButton 内对象属于 Forbidden Partition（外部无法 SetText），
-- 因此名字文本必须在 initializeFrame（信任上下文）里直接用当前 unitFrame 设置。
local function BuildContainer(unitFrame)
	local healthBar = unitFrame.healthBar
	if not healthBar then return end

	-- 销毁旧容器，避免复用导致残留/错乱
	local old = containers[unitFrame]
	if old then
		pcall(old.SetUnit, old, nil)  -- 停止追踪光环
		old:Hide()
		containers[unitFrame] = nil
	end

	local container = CreateFrame("AuraContainer", nil, healthBar, "CustomAuraContainerTemplate")
	container:SetFrameLevel(healthBar:GetFrameLevel() - 1)
	container.pcTextures = {}   -- 收集染色纹理，供颜色即时更新

	local colorMap, textMap = BuildSpellMaps()

	local color = GetColor()
	local textColor = GetTextColor()
	-- 单组即可：includeSpellIDs 塞入所有参与血条染色的法术，任一在场即显示（OR 逻辑）
	container:AddAuraGroup("auraColor", "HARMFUL|PLAYER", {
		maxFrameCount = 1,
		initializeFrame = function(btn)
			local tex = btn:CreateTexture(nil, "OVERLAY")
			local fill = healthBar:GetStatusBarTexture() or healthBar
			tex:SetColorTexture(color.r, color.g, color.b, color.a)
			tex:SetPoint("TOPLEFT", fill, "TOPLEFT", 1, -1)
			tex:SetPoint("BOTTOMRIGHT", fill, "BOTTOMRIGHT", 0, 1)
			container.pcTextures[#container.pcTextures + 1] = tex
		end,
	})

	-- 名字分组：参与名字变色的 dot 在场时用同名字的覆盖文本盖住原名字（实现名字变色）
	-- 文本在 initializeFrame 里直接设置，闭包捕获的 unitFrame 即当前单位
	container:AddAuraGroup("nameText", "HARMFUL|PLAYER", {
		maxFrameCount = 1,
		initializeFrame = function(btn)
			local fs = btn:CreateFontString(nil, "OVERLAY")
			fs:SetTextColor(textColor.r, textColor.g, textColor.b)
			local nameText = unitFrame.name
			if nameText then
				fs:SetFontObject(GameFontNormal)
				local _, height = nameText:GetFont()
				fs:SetFontHeight(height)
				fs:SetAllPoints(nameText)
				fs:SetText(UnitName(unitFrame.unit))
			end
		end,
	})

	container:SetAuraGroupCandidateFilters("auraColor", { includeSpellIDs = colorMap })
	container:SetAuraGroupMaxFrameCount("auraColor", 1)
	container:SetAuraGroupCandidateFilters("nameText", { includeSpellIDs = textMap })
	container:SetAuraGroupMaxFrameCount("nameText", 1)

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
			tex:SetColorTexture(color.r, color.g, color.b, color.a)
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
	local colorMap, textMap = BuildSpellMaps()
	for _, container in pairs(containers) do
		container:SetAuraGroupCandidateFilters("auraColor", { includeSpellIDs = colorMap })
		container:SetAuraGroupCandidateFilters("nameText", { includeSpellIDs = textMap })
	end
end

ns.event("NAME_PLATE_UNIT_ADDED", function(_, unit)
	if UnitIsUnit(unit, "player") then return end

	local namePlate = C_NamePlate.GetNamePlateForUnit(unit, false)
	if not namePlate then return end
	local unitFrame = namePlate.UnitFrame
	if not unitFrame then return end

	-- 非可攻击目标、或玩家目标（如敌方玩家）：隐藏已有容器并跳过，不给玩家血条染色
	if not UnitCanAttack("player", unit) or UnitIsPlayer(unit) then
		if containers[unitFrame] then
			containers[unitFrame]:Hide()
		end
		return
	end

	BuildContainer(unitFrame)
end)


