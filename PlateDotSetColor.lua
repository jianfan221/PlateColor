local _, ns = ...




-- 任意一个监控的法术存在就变色（OR 逻辑）：
-- PlateColorDB.dotlist 里任意一个 spellID 在场，血条就染成 dotcolor1 的颜色。
-- 全部都不在则不变色。
-- 全程不读取光环状态（12.x secrets 禁止），由安全容器判断。
--
-- 即时生效：
--   ns.UpdateAuraColor()  -- 颜色改动时调用，只更新已有纹理颜色
--   ns.RefreshAuraColor() -- dotlist 增减时调用，重建所有容器

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

-- 默认颜色
local function GetColor()
	return PlateColorDB.dotcolor1 or { r = 1, g = 0.35, b = 0.75, a = 1 }
end

-- 为某根血条建容器（含染色纹理）。仅当容器不存在时创建；已存在则复用。
local function BuildContainer(unitFrame)
	local healthBar = unitFrame.healthBar
	if not healthBar then return end

	local container = containers[unitFrame]
	if not container then
		container = CreateFrame("AuraContainer", nil, healthBar, "CustomAuraContainerTemplate")
		container:SetFrameLevel(healthBar:GetFrameLevel() - 1)
		container.pcTextures = {}   -- 收集染色纹理，供颜色即时更新

		local color = GetColor()
		local index = 0
		for spellID in pairs(PlateColorDB.dotlist or {}) do
			index = index + 1
			local key = "auraColor" .. index
			container:AddAuraGroup(key, "HARMFUL|PLAYER", {
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
			container:SetAuraGroupCandidateFilters(key, { includeSpellIDs = { [spellID] = true } })
			container:SetAuraGroupMaxFrameCount(key, 1)
		end

		containers[unitFrame] = container
	end

	container:SetUnit(unitFrame.unit)
	container:SetEnabled(true)
	container:Show()
end

-- 丢弃并重建某根血条的容器（仅设置变化时调用）
local function RebuildContainer(unitFrame)
	-- 单位已消失的血条跳过，避免对已回收血条创建 AuraContainer 触发断言
	if not unitFrame.unit or unitFrame.unitExists == false then
		return
	end
	local old = containers[unitFrame]
	if old then
		old:SetEnabled(false)
		old:Hide()
		containers[unitFrame] = nil
	end
	BuildContainer(unitFrame)
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

-- dotlist 增减：丢弃重建所有容器
function ns.RefreshAuraColor()
	for unitFrame in pairs(containers) do
		RebuildContainer(unitFrame)
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


