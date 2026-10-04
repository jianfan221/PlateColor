local _, ns = ...

-- ═══════════════════════════════════════════════════════════════════
-- 双dot染色：目标身上「两个指定 dot 同时存在」时给血条上色。
-- 记录存于 PlateColorDB.doubledotlist，键 = 专精 .. dot1 .. dot2（字符串拼接防重复），
-- 仅当当前角色专精与记录中的专精一致时才生效（设置界面见 PlateDoubleDotList.lua）。
--
-- 写法跟 PlateDotSetColor.lua（光环染色）一模一样，只多一层嵌套：
--   外层容器 group "dd1" 只追 dot1，自身不画东西，只当"有没有 dot1"的开关；
--   内层容器挂在「dd1 的按钮」下，group "dd2" 只追 dot2；
--   外层按钮隐藏（dot1 不在）时内层整棵不渲染 → 两个都在才显示；
--   血条染色纹理挂在 dd2 的按钮上，位置锚到血条的填充纹理。
-- ⚠️ 用 AddAuraGroup（按钮由容器内部延迟创建），不要用 AddAuraSlot
--    —— AddAuraSlot 会当场创建按钮，在 tainted 上下文里会撞 forbidden。
-- ═══════════════════════════════════════════════════════════════════

-- 依赖 12.x 光环容器，与"光环染色"标签页保持同一开关条件
if not DoesTemplateExist("CustomAuraContainerTemplate") then return end

local containers = {}     -- unitFrame -> 外层 AuraContainer
local activeDot1, activeDot2   -- 当前专精生效的两个 dot（多条时只取第 1 条）

-- 血条染色颜色
local function GetColor()
	return PlateColorDB.doubledotcolor1 or ns.Defaults.doubledotcolor1
end

-- 重算当前专精生效的法术（多条时只取第 1 条）
local function RefreshActiveSpells()
	activeDot1, activeDot2 = nil, nil

	local getSpec = C_SpecializationInfo and C_SpecializationInfo.GetSpecialization
	local index = getSpec and getSpec()
	if not index then return end
	local specID = C_SpecializationInfo.GetSpecializationInfo(index)
	if not specID or specID == 0 then return end

	local best
	for _, info in pairs(PlateColorDB.doubledotlist or {}) do
		if info.spec == specID then
			if not best or info.dot1 < best.dot1 or (info.dot1 == best.dot1 and info.dot2 < best.dot2) then
				best = info
			end
		end
	end
	if best then
		activeDot1, activeDot2 = best.dot1, best.dot2
	end
end

-- 把当前的两个 dot 写进两个 group 的过滤（不生效传空表 = 一个都不显示）
local function ApplyFilters(container)
	container:SetAuraGroupCandidateFilters("dd1", { includeSpellIDs = activeDot1 and { [activeDot1] = true } or {} })
	for _, inner in ipairs(container.pcDDInners) do
		inner:SetAuraGroupCandidateFilters("dd2", { includeSpellIDs = activeDot2 and { [activeDot2] = true } or {} })
	end
end

-- 切单位（外层 + 每个内层容器各自独立追踪）
local function SetUnits(container, unit)
	container:SetUnit(unit)
	for _, inner in ipairs(container.pcDDInners) do
		inner:SetUnit(unit)
	end
end

-- 销毁某姓名板的双dot容器（当前专精没有配置 / 单位不再需要时用）
local function DestroyContainer(unitFrame)
	local container = containers[unitFrame]
	if not container then return end
	containers[unitFrame] = nil
	container:SetUnit("none")
	container:Hide()
	container:SetParent(UIParent)
end

-- 血条染色纹理：挂在 dd2 的按钮上（显隐由按钮决定），位置锚到血条的填充纹理
local function MakeBarTexture(btn, fill)
	local color = GetColor()
	local tex = btn:CreateTexture(nil, "OVERLAY")
	local path = ns.HpTextures[PlateColorDB.hpbarTexture] or ns.HpTextures["PC-White"]
	if string.match(path, "Interface\\") then
		tex:SetTexture(path)
	else
		tex:SetAtlas(path)
	end
	tex:SetVertexColor(color.r, color.g, color.b, color.a or 1)
	tex:SetPoint("TOPLEFT", fill, "TOPLEFT", 1, -1)
	tex:SetPoint("BOTTOMRIGHT", fill, "BOTTOMRIGHT", 0, 1)
	return tex
end

local function BuildContainer(unitFrame, unit)
	local healthBar = unitFrame.healthBar
	if not healthBar then return end
	local fill = healthBar:GetStatusBarTexture() or healthBar

	-- 复用已有容器（unitFrame 会被暴雪池化复用，切单位即可）
	local container = containers[unitFrame]
	if container then
		SetUnits(container, unit)
		ApplyFilters(container)
		container:Show()
		return
	end

	container = CreateFrame("AuraContainer", nil, healthBar, "CustomAuraContainerTemplate")
	container:SetFrameLevel(healthBar:GetFrameLevel() - 1)
	container.pcDDInners = {}
	container.pcDDTextures = {}

	-- 外层：只追 dot1，自身不画东西，只当"有没有 dot1"的开关
	container:AddAuraGroup("dd1", "HARMFUL|PLAYER", {
		maxFrameCount = 1,
		layout = { elementSpacing = 1 },
		candidateFilters = { includeSpellIDs = {} },
		initializeFrame = function(btn)
			btn:SetSize(1, 1)
			btn:EnableMouse(false)

			-- 内层：追 dot2，父级 = 外层按钮
			-- 外层按钮隐藏（dot1 不在）时内层整棵不渲染 → 两个 dot 同时存在才染色
			local inner = CreateFrame("AuraContainer", nil, btn, "CustomAuraContainerTemplate")
			inner:SetAllPoints(healthBar)
			inner:EnableMouse(false)
			inner:AddAuraGroup("dd2", "HARMFUL|PLAYER", {
				maxFrameCount = 1,
				layout = { elementSpacing = 1 },
				candidateFilters = { includeSpellIDs = {} },
				initializeFrame = function(btn2)
					btn2:SetSize(1, 1)
					btn2:EnableMouse(false)
					container.pcDDTextures[#container.pcDDTextures + 1] = MakeBarTexture(btn2, fill)
				end,
			})
			-- 外层容器可能还没设单位（SetUnit 在 AddAuraGroup 之后才调），有才设
			local outerUnit = container:GetUnit()
			if outerUnit then inner:SetUnit(outerUnit) end
			container.pcDDInners[#container.pcDDInners + 1] = inner
		end,
	})

	containers[unitFrame] = container
	SetUnits(container, unit)
	ApplyFilters(container)
	container:Show()
end

-- 颜色改动：只更新已有纹理颜色
function ns.UpdateDoubleDotColor()
	local color = GetColor()
	for _, container in pairs(containers) do
		for _, tex in ipairs(container.pcDDTextures or {}) do
			tex:SetVertexColor(color.r, color.g, color.b, color.a or 1)
		end
	end
end

-- 列表 / 专精变化：重算记录并刷新所有姓名板
function ns.RefreshDoubleDotColor()
	RefreshActiveSpells()

	-- 当前专精没有双dot配置：销毁所有已建容器
	if not activeDot1 then
		for unitFrame in pairs(containers) do
			DestroyContainer(unitFrame)
		end
		return
	end

	for _, namePlate in ipairs(C_NamePlate.GetNamePlates()) do
		local unitFrame = namePlate.UnitFrame
		local unit = namePlate.namePlateUnitToken
		if unitFrame and unit and UnitCanAttack("player", unit) and not UnitIsPlayer(unit) then
			BuildContainer(unitFrame, unit)
		end
	end
end

ns.event("PLAYER_LOGIN", function()
	-- 进游戏后 SavedVariables 已就绪，先算一次当前专精生效的 dot
	ns.RefreshDoubleDotColor()
end)

-- 姓名板出现就创建（与光环染色一致），不处理移除
ns.event("NAME_PLATE_UNIT_ADDED", function(_, unit)
	local namePlate = C_NamePlate.GetNamePlateForUnit(unit, false)
	if not namePlate then return end
	local unitFrame = namePlate.UnitFrame
	if not unitFrame then return end

	-- 没有配置 / 非可攻击目标 / 玩家目标：隐藏已有容器并跳过
	if not activeDot1 or not UnitCanAttack("player", unit) or UnitIsPlayer(unit) then
		local container = containers[unitFrame]
		if container then container:Hide() end
		return
	end

	BuildContainer(unitFrame, unit)
end)

ns.event("PLAYER_SPECIALIZATION_CHANGED", function(_, unit)
	if unit ~= "player" then return end
	ns.RefreshDoubleDotColor()
end)
