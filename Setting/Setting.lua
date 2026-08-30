local addonName, ns = ...
local L = ns.L
local DB = ns.Defaults

-- ═══════════════════════════════════════════════════════════════════
-- PlateColor 特有：覆盖通用核心的统一回调入口 ns.ApplyChange
-- 通用核心（Setting-Core.lua）默认是"传值调用"（AddUI 风格 setfun(value)）；
-- 但 pc 的姓名板回调把首个参数当 unitFrame 用，不能接收 value，
-- 故在此覆盖为"无参刷新全局 + 遍历所有姓名板各调一次"，并忽略 value。
-- 此覆盖在本文件（标签文件）加载时立即生效，早于设置界面首次构建（懒构建）时各行的回调绑定。
-- ═══════════════════════════════════════════════════════════════════
function ns.ApplyChange(setfun, value)
	if not setfun then return end
	setfun()
	for _, namePlate in ipairs(C_NamePlate.GetNamePlates()) do
		if namePlate.UnitFrame then setfun(namePlate.UnitFrame) end
	end
end

-- 打开设置界面的 slash 命令（由 Setting-Core.lua 末尾 C_Timer.After 动态注册）
ns.opensetting1 = "/pc"
ns.opensetting2 = "/platecolor"

-- ═══════════════════════════════════════════════════════════════════
-- 基础：暴雪姓名板设置 / 点击范围 / 血条
-- ═══════════════════════════════════════════════════════════════════
ns.AddTab(L["基础"], function()

	ns.AddSection(L["点击范围"])
	ns.AddCheck(L["显示点击范围"], L["显示点击范围"], "HitTestShow", ns.RefreshHitSettings)
	ns.AddSlider(L["点击范围宽度"], L["点击范围宽度"], -10, 25, 1, "%d", "HitWidth", ns.RefreshHitSettings)
	ns.AddSlider(L["点击范围顶部"], L["点击范围顶部"], -6, 20, 1, "%d", "HitHeight", ns.RefreshHitSettings)
	ns.AddSlider(L["点击范围底部"], L["点击范围底部"], -6, 20, 1, "%d", "HitBottom", ns.RefreshHitSettings)

	ns.AddSection(L["血条"])
	ns.AddTexture(L["血条材质选择"], L["血条材质选择"], "hpbarTexture", ns.HpTextures, ns.TextureSetting)
	ns.AddSlider(L["背景透明度"], L["背景透明度"], 0, 1, 0.01, "%.2f", "hpbgAlpha", ns.TextureSetting)
	ns.AddTextureIcon(L["血条边框材质选择"], L["血条边框材质选择"], "hpBorderTexture", ns.HPBorderTexture, ns.TextureSetting)
	ns.AddSlider(L["姓名版宽度"], L["姓名版宽度"], 5, 50, 1, "%d", "hpWidht", ns.SetPoints)
	ns.AddSlider(L["姓名版高度"], L["姓名版高度"], 5, 30, 1, "%d", "hpHeight", ns.SetPoints)

	ns.AddSection(L["暴雪姓名板设置"])
	local realltextRe = ns.AddFuncButton(L["帮我设置暴雪姓名板"], L["点击自动设置ESC-选项-姓名板里的相关选项"])
	realltextRe:SetScript("OnClick", function()
		if InCombatLockdown() then
			print("|cffff0000[PlateColor]|r " .. L["战斗中无法设置暴雪姓名板选项"])
			return
		end
		--名字
		C_CVar.SetCVar("UnitNameNPC", 1)--NPC名字-全部
		C_CVar.SetCVar("UnitNameNonCombatCreatureName", 1)--小动物-开启
		C_CVar.SetCVar("UnitNameFriendlyPlayerName", 1)--友方玩家名字开启
		C_CVar.SetCVar("UnitNameFriendlyMinionName", 1)--友方仆从名字-开启
		C_CVar.SetCVar("UnitNameEnemyPlayerName", 1)--敌对玩家名字-开启
		C_CVar.SetCVar("UnitNameEnemyMinionName", 1)--敌对仆从名字-开启
		--姓名板
		C_CVar.SetCVar("nameplateShowAll", 1)--显示所有姓名板-开启
		C_CVar.SetCVar("nameplateShowEnemies", 1)--显示敌对姓名板-开启
		C_CVar.SetCVar("nameplateShowEnemyMinions", 1)--显示敌对仆从姓名板-开启
		C_CVar.SetCVar("nameplateShowEnemyMinus", 1)--显示敌对小怪姓名板-开启
		C_CVar.SetCVar("nameplateShowFriendlyPlayers", 1)--显示友方玩家姓名板-开启
		C_CVar.SetCVar("nameplateShowFriendlyPlayerMinions", 0)--显示友方仆从姓名板--关闭
		C_CVar.SetCVar("nameplateShowOnlyNameForFriendlyPlayerUnits", 1)--友方玩家名字模式-开启
		C_CVar.SetCVar("nameplateUseClassColorForFriendlyPlayerUnitNames", 1)--名字模式职业染色-开启
		C_CVar.SetCVar("nameplateShowFriendlyRealmName", 0)--显示服务器名称-关闭

		C_CVar.SetCVar("nameplateShowFriendlyNpcs", 1)--显示友方NPC姓名板-开启
		C_CVar.SetCVar("nameplateShowOffscreen", 1)--显示屏幕外的姓名板-开启
		C_CVar.SetCVar("nameplateStackingTypes", "A")--堆叠模式-敌对
		--尺寸
		C_CVar.SetCVar("nameplateSize", 1)--姓名板尺寸--1
		C_CVar.SetCVar("nameplateAuraScale", 1.1)--姓名板光环缩放--1.1
		C_CVar.SetCVar("nameplateStyle", 0)--姓名板风格-默认
		C_CVar.SetCVar("nameplateInfoDisplay","D")--姓名板信息-稀有度图标
		C_CVar.SetCVar("nameplateCastBarDisplay","O")--施法条--不选最后一个
		C_CVar.SetCVar("nameplateThreatDisplay","B")--仇恨--仅闪光
		--根据DB值设置暴雪原生显示位（未启用自建光环时确保暴雪原生正常显示）
		ns.SetCVar("nameplateEnemyNpcAuraDisplay", Enum.NamePlateEnemyNpcAuraDisplay.Buffs, not PlateColorDB.auraLEnable)--敌方NPC增益：未启用左侧自建光环则显示
		ns.SetCVar("nameplateEnemyNpcAuraDisplay", Enum.NamePlateEnemyNpcAuraDisplay.Debuffs, not PlateColorDB.auraTopEnable)--敌方NPC减益：未启用上方自建光环则显示
		ns.SetCVar("nameplateEnemyNpcAuraDisplay", Enum.NamePlateEnemyNpcAuraDisplay.CrowdControl, true)--敌方NPC控制：始终显示
		ns.SetCVar("nameplateEnemyPlayerAuraDisplay", Enum.NamePlateEnemyPlayerAuraDisplay.Buffs, true)--敌方玩家增益：始终显示
		ns.SetCVar("nameplateEnemyPlayerAuraDisplay", Enum.NamePlateEnemyPlayerAuraDisplay.Debuffs, not PlateColorDB.auraTopEnable)--敌方玩家减益：未启用上方自建光环则显示
		ns.SetCVar("nameplateEnemyPlayerAuraDisplay", Enum.NamePlateEnemyPlayerAuraDisplay.LossOfControl, true)--敌方玩家控制：始终显示
		C_CVar.SetCVar("nameplateFriendlyPlayerAuraDisplay","G")--友方玩家的增减益状态
		C_CVar.SetCVar("nameplateDebuffPadding", 0)--姓名板增减益图标间距-0
		C_CVar.SetCVar("nameplateSimplifiedTypes", "")--简化模式-无
		print("|cffff0000[PlateColor]|r " .. L["已设置暴雪姓名板选项"])
		UIErrorsFrame:AddExternalWarningMessage(L["已设置暴雪姓名板选项"])
	end)
end)

-- ═══════════════════════════════════════════════════════════════════
-- 名字：名字 / 友方
-- ═══════════════════════════════════════════════════════════════════
ns.AddTab(L["名字"], function()

	ns.AddSection(L["名字"])
	ns.AddCheck(L["白色名字"], L["白色名字"], "whiteName", ns.SetNameColor)
	ns.AddCheck(L["名字描边"], L["名字描边"], "nameOUTLINE", ns.SetPoints)
	local Nametable = {{L["中上"],1},{L["左上"],2},{L["左中"],3},{L["左下"],4},{L["中下"],5}}
	ns.AddDropdown(L["名字位置"], L["名字位置"], Nametable, "namePoint", ns.SetPoints)
	ns.AddSlider(L["名字垂直偏移"], L["名字垂直偏移"], -10, 10, 1, "%d", "nameVoffset", ns.SetPoints)
	ns.AddSlider(L["名字尺寸"], L["名字尺寸"], 5, 30, 1, "%d", "nameScale", ns.SetPoints)

	ns.AddSection(L["友方"])
	ns.AddCVarCheck(L["友方玩家名字模式"], L["友方玩家名字模式"], "nameplateShowOnlyNameForFriendlyPlayerUnits", nil, ns.SetSelectedScale)
	ns.AddCVarCheck(L["友方玩家名字模式职业染色"], L["友方玩家名字模式职业染色"], "nameplateUseClassColorForFriendlyPlayerUnitNames", nil, ns.SetSelectedScale)
	ns.AddCheck(L["友方玩家公会名称"], L["友方玩家公会名称"], "showGuildName", ns.SetOnlyNames)
	ns.AddCheck(L["友方NPC名字模式"], L["友方NPC名字模式"], "onlyNameNpc", ns.SetOnlyNames)
	ns.AddSlider(L["友方名字模式尺寸"], L["友方名字模式尺寸"], 5, 30, 1, "%d", "helpNameScale", ns.SetOnlyNames)

end)

-- ═══════════════════════════════════════════════════════════════════
-- 施法条：施法条 / 施法目标
-- ═══════════════════════════════════════════════════════════════════
ns.AddTab(L["施法条"], function()

	ns.AddSection(L["施法条"])
	ns.AddTexture(L["施法条材质选择"], L["施法条材质选择"], "castTexture", ns.HpTextures)
	ns.AddSlider(L["施法条高度"], L["施法条高度鼠标提示"], 5, 30, 1, "%d", "castBarHeight", ns.SetPoints)
	ns.AddCheck(L["施法图标放大"], L["施法图标放大"], "castIconBig", ns.SetPoints)
	local casttable = {{L["左"],1},{L["中"],2}}
	ns.AddDropdown(L["施法名称位置"], L["施法名称位置"], casttable, "castPoint", ns.SetPoints)
	ns.AddCheck(L["施法剩余时间"], L["施法剩余时间"], "castTime", ns.SetPoints)
	ns.AddSlider(L["施法条文本尺寸"], L["施法条文本尺寸"], 8, 30, 1, "%d", "castTextScale", ns.SetPoints)
	ns.AddColor(L["不可打断法术颜色"], L["不可打断法术颜色"], "nointerrupcolor", ns.SetCastBarInitColor)
	ns.AddColor(L["读条法术颜色"], L["读条法术颜色"], "castcolor", ns.SetCastBarInitColor)
	ns.AddColor(L["引导法术颜色"], L["引导法术颜色"], "channelcolor", ns.SetCastBarInitColor)

	ns.AddSection(L["施法目标"])
	ns.AddCVarCheck(L["显示施法目标"], L["显示施法目标"], "nameplateCastBarDisplay", Enum.NamePlateCastBarDisplay.SpellTarget)
	ns.AddCheck(L["始终显示施法目标"], L["始终显示施法目标鼠标提示"], "castTargetAlways", ns.SetPoints)
	local castTargettable = {{L["右侧内部"],1},{L["右侧外部"],2},{L["右中"],3},{L["右上"],4}}
	ns.AddDropdown(L["施法目标名字位置"], L["施法目标名字位置"], castTargettable, "castTargetPoint", ns.SetPoints)
	ns.AddSlider(L["施法目标名字尺寸"], L["施法目标名字尺寸"], 8, 30, 1, "%d", "castTargetScale", ns.SetPoints)

end)

-- ═══════════════════════════════════════════════════════════════════
-- 仇恨：其他颜色 / 仇恨 / 坦克仇恨
-- ═══════════════════════════════════════════════════════════════════
ns.AddTab(L["仇恨"], function()

	ns.AddSection(L["其他颜色"])
	ns.AddColor(L["全局颜色"], L["全局颜色鼠标提示"], "allColor")

	ns.AddSection(L["仇恨"])
	local threatUseTable = {{L["无"],0},{L["名字"],1},{L["血条"],2},{L["名字+血条"],3}}
	ns.AddDropdown(L["颜色作用于"], L["启用仇恨变色鼠标提示"], threatUseTable, "threatUse", ns.SetNpcLevelColor)
	ns.AddColor(L["低仇恨"], L["低仇恨鼠标提示"], "noThreatColor", ns.UpdateHpbarColor)
	ns.AddColor(L["高仇恨"], L["高仇恨鼠标提示"], "highThreatColor", ns.UpdateHpbarColor)
	ns.AddColor(L["仇恨是你"], L["仇恨是你鼠标提示"], "myThreatColor", ns.UpdateHpbarColor)
	ns.AddColor(L["仇恨不稳"], L["仇恨不稳鼠标提示"], "lowThreatColor", ns.UpdateHpbarColor)

	ns.AddSection(L["坦克仇恨"])
	ns.AddDropdown(L["颜色作用于"], L["启用坦克仇恨变色鼠标提示"], threatUseTable, "TankthreatUse", ns.SetNpcLevelColor)
	ns.AddColor(L["坦克低仇恨"], L["坦克低仇恨鼠标提示"], "TANKnoThreatColor", ns.UpdateHpbarColor)
	ns.AddColor(L["坦克高仇恨"], L["坦克高仇恨鼠标提示"], "TANKhighThreatColor", ns.UpdateHpbarColor)
	ns.AddColor(L["坦克仇恨是你"], L["坦克仇恨是你鼠标提示"], "TANKmyhreatColor", ns.UpdateHpbarColor)
	ns.AddColor(L["坦克仇恨不稳"], L["坦克仇恨不稳鼠标提示"], "TANKlowThreatColor", ns.UpdateHpbarColor)

end)

-- ═══════════════════════════════════════════════════════════════════
-- 生命值：生命值
-- ═══════════════════════════════════════════════════════════════════
ns.AddTab(L["生命值"], function()

	ns.AddSection(L["生命值"])
	ns.AddCheck(L["生命值数值"], L["生命值数值"], "hpValue")
	ns.AddCheck(L["生命值百分比"], L["生命值百分比"], "hpPercent")
	ns.AddSlider(L["生命值文本尺寸"], L["生命值文本尺寸"], 8, 30, 1, "%d", "HpTextScale1", ns.SetPoints)
	local AbbconfigTable = {{"万,亿",1},{"K,M",2},{L["暴雪默认"],3}}
	ns.AddDropdown(L["数值格式"], L["数值格式"], AbbconfigTable, "Abbconfig")
	local Ftable = {{"",""},{"( )","( )"},{":",":"},
	{"|cffB2B2B2|||r","|cffB2B2B2|||r"},{"|cffB2B2B2/|r","|cffB2B2B2/|r"},{"|cffB2B2B2-|r","|cffB2B2B2-|r"}}
	ns.AddDropdown(L["分隔符"], L["分隔符"], Ftable, "delimiter")
	local HpTextPointtable = {{L["左"],1},{L["中"],2},{L["右"],3}}
	ns.AddDropdown(L["生命值文本位置"], L["生命值文本位置"], HpTextPointtable, "HpTextPoint", ns.SetPoints)
	ns.AddSlider(L["生命值文本垂直偏移"], L["生命值文本垂直偏移"], -50, 50, 1, "%d", "HpTextVoffset", ns.SetPoints)
	ns.AddSlider(L["生命值文本水平偏移"], L["生命值文本水平偏移"], -50, 50, 1, "%d", "HpTextHoffset", ns.SetPoints)

end)

-- ═══════════════════════════════════════════════════════════════════
-- 指示器：箭头 / 交互 / 其他 / CVars
-- ═══════════════════════════════════════════════════════════════════
ns.AddTab(L["指示器"], function()

	ns.AddSection(L["箭头"])
	local arrowShowTable = {{L["不显示"],0},{L["左"],1},{L["右"],2},{L["左+右"],3}}
	ns.AddDropdown(L["箭头显示方式"], L["箭头显示方式"], arrowShowTable, "arrowPoint", ns.UpdateHpTexture)
	ns.AddTextureIcon(L["箭头材质"], L["箭头材质"], "arrowTexture", ns.ArrowTexture, ns.UpdateHpTexture)
	ns.AddColor(L["箭头颜色"], L["箭头颜色"], "arrowColor", ns.UpdateTargetTexture)
	ns.AddSlider(L["箭头尺寸"], L["箭头尺寸"], 5, 50, 1, "%d", "arrowScale", ns.UpdateHpTexture)
	ns.AddSlider(L["箭头水平偏移"], L["箭头水平偏移"], -10, 10, 1, "%d", "arrowHoffset", ns.UpdateHpTexture)

	ns.AddSection(L["交互"])
	-- 斩杀技能列表提示
	local function ShowSlaylineTooltip()
		local text = ""
		for spell,value in pairs(ns.SlaylineSpell) do
			if spell then
				local name = C_Spell.GetSpellName(spell) and C_Spell.GetSpellName(spell) or "|cffFF0000"..UNKNOWN..SPELLS.."|r"
				local icon = C_Spell.GetSpellTexture(spell) or 132321
				if spell == ns.SlaylineSpellID then
					text = text .."\n|cff00FF00"..value.."%|T"..icon..":15|t "..name.." : "..spell.."|r"
				else
					text = text .."\n|cff969696"..value.."%|T"..icon..":15|t "..name.." : "..spell.."|r"
				end
			end
		end
		GameTooltip:SetText(text)
	end

	local Slayline = ns.AddCheckColor(L["斩杀辅助线"], L["斩杀辅助线"], "Slayline", "SlaylineColor", ns.CreatSlayline)
	Slayline.check:HookScript("OnEnter", ShowSlaylineTooltip)
	local SlayHp = ns.AddCheckColor(L["斩杀血条变色"], L["斩杀血条变色"], "SlayHp", "SlayHpColor", ns.UpdateHpbarColor)
	SlayHp.check:HookScript("OnEnter", ShowSlaylineTooltip)
	ns.AddCheckColor(L["当前目标颜色"], L["当前目标颜色"], "myTarget", "myTargetColor", ns.UpdateHpbarColor)
	ns.AddCheckColor(L["焦点血条颜色"], L["焦点血条颜色"], "myFocus", "myFocusColor", ns.UpdateHpbarColor)
	ns.AddCheckColor(L["鼠标指向边框变色"], L["鼠标指向边框变色"], "mGlow", "mGlowColor")
	ns.AddCheck(L["焦点斜线材质"], L["焦点斜线材质鼠标提示"], "focusTexture")

	ns.AddSection(L["其他"])
	ns.AddCheck(L["任务标志"], L["任务标志"], "questMark", ns.CreateNameQuest)
	ns.AddCheck(L["等级文本"], L["等级文本鼠标提示"], "levelText")
	ns.AddCheck(L["吸收盾数值"], L["吸收盾数值鼠标提示"], "absorbText")

	ns.AddSection("CVars")
	ns.AddCVarSlider(L["当前目标尺寸"], L["当前目标尺寸"], 1, 2, 0.1, "%.1f", "nameplateSelectedScale")
	ns.AddSlider(L["非当前目标透明度"], L["非当前目标透明度"], 0, 1, 0.1, "%.1f", "allNpAlpha", ns.SetSelectedScale)
	ns.AddCVarSlider(L["隔墙姓名板透明度"], L["隔墙姓名板透明度"], 0, 1, 0.1, "%.1f", "nameplateOccludedAlphaMult")
	ns.AddCVarSlider(L["垂直堆叠间距"], L["垂直堆叠间距"], 0.1, 2, 0.1, "%.1f", "nameplateOverlapV")
	ns.AddCVarSlider(L["水平堆叠间距"], L["水平堆叠间距"], 0.1, 2, 0.1, "%.1f", "nameplateOverlapH")
	ns.AddCVarSlider(L["姓名版可见范围"], L["姓名版可见范围"], 10, 60, 1, "%d", "nameplateMaxDistance")

end)

-- ═══════════════════════════════════════════════════════════════════
-- 光环：光环 / 光环染色
-- ═══════════════════════════════════════════════════════════════════
ns.AddTab(AURAS, function()

	ns.AddSection(AURAS)
	ns.AddCVarCheck(L["光环鼠标提示显示法术ID"], L["光环鼠标提示显示法术ID鼠标提示"], "tooltipShowAuraSpellIDs")
	ns.AddCheck(L["隐藏光环鼠标提示"], L["隐藏光环鼠标提示"], "hideAuraTooltip")
	ns.AddSlider(L["光环冷却时间文本尺寸"], L["光环冷却时间文本尺寸"], 0.5, 1.5, 0.1, "%.1f", "auraText1")
	ns.AddSection(L["上方减益光环"])
	if DoesTemplateExist("CustomAuraContainerTemplate") then
		-- auraBtn 在 AddCheck 之后创建，故先声明；勾选状态变化时同步启用/禁用该按钮
		local auraBtn
		ns.AddCheck(L["上方减益光环"], "|cffFF69B4"..L["自建光环容器鼠标提示"].."|r", "auraTopEnable", function()
			if auraBtn then
				auraBtn:SetEnabled(ns.DB["auraTopEnable"] ~= false)
			end
		end)
		auraBtn = ns.AddFuncButton(L["上方减益过滤器"], L["上方减益过滤器鼠标提示"])
		auraBtn:SetEnabled(ns.DB["auraTopEnable"] ~= false)--初始启用状态
		auraBtn:SetScript("OnClick", function()
			if ns.OpenPlateAurasList then ns.OpenPlateAurasList() end
		end)
	end
	ns.AddSlider(L["上方减益光环尺寸"], "|cffFF69B4"..L["修改后需要重载界面"].."|r", 0.5, 3, 0.1, "%.1f", "auraTopScale")
	ns.AddSection(L["左侧增益光环"])
	if DoesTemplateExist("CustomAuraContainerTemplate") then
		ns.AddCheck(L["左侧增益光环"], "|cffFF69B4"..L["自建光环容器鼠标提示"].."|r", "auraLEnable")
		ns.AddCheck(L["仅显示队伍可驱散"], L["仅显示队伍可驱散鼠标提示"], "auraLDispelOnly", ns.RebuildDispelFilter)
		ns.AddDep("auraLEnable",{"auraLDispelOnly"})
	end
	ns.AddSlider(L["左侧增益光环尺寸"], "|cffFF69B4"..L["修改后需要重载界面"].."|r", 0.5, 3, 0.1, "%.1f", "auraLScale")
	ns.AddSection(L["右侧控制光环"])
	ns.AddSlider(L["右侧控制光环尺寸"], L["右侧控制光环尺寸"], 0.5, 3, 0.1, "%.1f", "auraRScale")

end)
-- 光环染色分类标题 + 设置按钮（仅 12.1 有光环容器模板时显示）
if DoesTemplateExist("CustomAuraContainerTemplate") then
	ns.AddTab(L["光环染色"], function()
		ns.AddSection(L["光环染色"])
		local dotBtn = ns.AddFuncButton(L["光环染色设置"], L["光环染色设置鼠标提示"])
		dotBtn:SetScript("OnClick", function()
			if ns.OpenPlateDotList then ns.OpenPlateDotList() end
		end)
	end)
end

-- ═══════════════════════════════════════════════════════════════════
-- NPC颜色：NPC颜色作用于 / NPC分类
-- ═══════════════════════════════════════════════════════════════════
ns.AddTab(L["NPC颜色"], function()

	ns.AddSection(L["NPC颜色作用于"])
	local UseNpctable = {{L["无"],0},{L["名字"],1},{L["血条"],2},{L["名字+血条"],3}}
	ns.AddDropdown(L["NPC颜色作用于"], L["NPC颜色作用于"], UseNpctable, "UseNpc", ns.UpdateSetColor)

	ns.AddSection(L["NPC分类"])
	ns.AddCheckColor(L["等级>1颜色"], L["等级>1鼠标提示"], "NpcLv1", "NpcLv1Color", ns.UpdateSetColor)
	ns.AddCheckColor(L["BOSS颜色"], L["BOSS颜色"], "NpcLv2", "NpcLv2Color", ns.UpdateSetColor)
	local NpckickColor = ns.AddCheckColor(L["可打断NPC颜色"], L["可打断NPC颜色"], "Npckick", "NpckickColor", ns.UpdateSetColor)
	local NpcNokickColor = ns.AddCheckColor(L["不可打断NPC颜色"], L["不可打断NPC颜色"], "NpcNokick", "NpcNokickColor", ns.UpdateSetColor)
	NpcNokickColor.check:Disable()
	NpcNokickColor.text:SetVertexColor(0.6,0.6,0.6)
	NpckickColor.check:HookScript("OnClick",function(self)
		NpcNokickColor.check:SetChecked(self:GetChecked())
		PlateColorDB.NpcNokick = self:GetChecked()
	end)
	ns.AddCheckColor(L["可能是可打断NPC颜色"], L["可能是可打断NPC颜色"], "NpcSukick", "NpcSukickColor", ns.UpdateSetColor)

end)

-- ═══════════════════════════════════════════════════════════════════
-- 标记：标记 / 焦点（辅助功能整合）
-- ═══════════════════════════════════════════════════════════════════
ns.AddTab(L["标记"], function()

	ns.AddSection(L["标记"])
	ns.AddSlider(L["标记尺寸"], L["标记尺寸"], 0.5, 3, 0.1, "%.1f", "markScale", ns.SetPoints)
	ns.AddSlider(L["标记水平偏移"], L["标记水平偏移"], -80, 80, 1, "%d", "markHoffset", ns.SetPoints)
	ns.AddSlider(L["标记垂直偏移"], L["标记垂直偏移"], -80, 80, 1, "%d", "markVoffset", ns.SetPoints)

	ns.AddSection(L["焦点"])
	local setFocusModTable = {{L["不使用"],0},{L["Shift"],1},{L["Ctrl"],2},{L["Alt"],3}}
	ns.AddDropdown(L["设置焦点快捷键"], L["设置焦点快捷键鼠标提示"], setFocusModTable, "setFocusMod", ns.PCSetFocus)

	local setFocusIconTable = {
		{L["不标记"],0},
		{"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:16|t",1},
		{"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_2:16|t",2},
		{"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_3:16|t",3},
		{"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_4:16|t",4},
		{"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_5:16|t",5},
		{"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_6:16|t",6},
		{"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_7:16|t",7},
		{"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:16|t",8},
	}
	ns.AddDropdown(L["设置焦点时自动标记"], L["设置焦点时自动标记"], setFocusIconTable, "setFocusIcon", ns.PCSetFocus)
	ns.AddCheck(L["就位时通报标记"], L["就位时通报标记"], "sendFocusIcon")

end)

-- ═══════════════════════════════════════════════════════════════════
-- 个人资源：个人资源
-- ═══════════════════════════════════════════════════════════════════
ns.AddTab(L["个人资源"], function()

	ns.AddSection(L["个人资源"])
	ns.AddCVarCheck(DISPLAY_PERSONAL_RESOURCE, DISPLAY_PERSONAL_RESOURCE, "nameplateShowSelf")
	ns.AddCheck(L["启用个人资源设置"], L["启用个人资源设置鼠标提示"], "myHPSetup", ns.AllmyPowerBar)
	ns.AddCheck(L["编辑模式自动居中"], L["编辑模式自动居中"], "myHPEdit")
	ns.AddTexture(L["个人资源材质"], L["个人资源材质"], "myHPTexture", ns.HpTextures, ns.AllmyPowerBar)
	ns.AddSlider(L["个人资源宽度"], L["个人资源宽度"], 150, 400, 1, "%d", "myHPwidth", ns.AllmyPowerBar)
	ns.AddSlider(L["个人资源高度"], L["个人资源高度"], 5, 40, 1, "%d", "myHPheight", ns.AllmyPowerBar)
	ns.AddCheck(L["个人资源数值"], L["个人资源数值"], "myHPValue", ns.AllmyPowerBar)
	local ShowModeTable = {{L["暴雪原版"],0},{L["新版资源条"],1},{L["精简2行"],2}}
	ns.AddDropdown(L["额外资源模式"], L["额外资源模式"], ShowModeTable, "myHPShowMode", ns.AllmyPowerBar)
	ns.AddCheckColor(L["新版资源条自定义颜色"], L["新版资源条自定义颜色"], "newClassBarSetColor", "newClassBarColor", ns.AllmyPowerBar)
	ns.AddCheck(L["武僧坦克酒池使用数值"], L["武僧坦克酒池使用数值"], "myHPStaggerUseValue", ns.AllmyPowerBar)

end)
