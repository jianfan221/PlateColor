local addonName,ns = ...
local L = ns.L

ns.event("PLAYER_ENTERING_WORLD", function()
--分页6滚动框架
local ConFramescrollFrame6 = CreateFrame("ScrollFrame", nil, ns.tabframe6, "UIPanelScrollFrameTemplate")
ConFramescrollFrame6:SetPoint("TOPLEFT", ns.tabframe6, "TOPLEFT", 4, -5)
ConFramescrollFrame6:SetPoint("BOTTOMRIGHT", ns.tabframe6, "BOTTOMRIGHT", -30, 5)
--分页6滚动内容
local ConFrame6 = CreateFrame("Frame", nil, ConFramescrollFrame6)
ConFrame6:SetSize(670,480)
ConFramescrollFrame6:SetScrollChild(ConFrame6)
ns.Y[6] = 0	--设置起始位置


local titext1 = ns.AddSetTiText(ConFrame6,6,L["配置"])
local realltextRe = ns.AddfuncButton(ConFrame6,6,L["帮我设置暴雪姓名板"],L["点击自动设置ESC-选项-姓名板里的相关选项"])
realltextRe:HookScript("OnClick", function()
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
	C_CVar.SetCVar("nameplateEnemyNpcAuraDisplay","G")--敌方NPC的增减益状态
	C_CVar.SetCVar("nameplateEnemyPlayerAuraDisplay","G")--敌方玩家的增减益状态
	C_CVar.SetCVar("nameplateFriendlyPlayerAuraDisplay","G")--友方玩家的增减益状态
	C_CVar.SetCVar("nameplateDebuffPadding", 0)--姓名板增减益图标间距-0
	C_CVar.SetCVar("nameplateSimplifiedTypes", "")--简化模式-无
	print("|cffff0000[PlateColor]|r " .. L["已设置暴雪姓名板选项"])
end)

local realltextRe = ns.AddfuncButton(ConFrame6,6,L["恢复插件默认设置"],L["恢复插件默认设置"])
realltextRe:HookScript("OnClick", function()
	 StaticPopup_Show("PLATECOLOR_REDB")
end)

-- 导出按钮
local exporttext = ns.AddSetTiText(ConFrame6,6,L["导入导出"])
local exportbtn = ns.AddfuncButton(ConFrame6,6,L["导出当前配置"],L["导出当前配置"])
exportbtn:HookScript("OnClick", function()
	if not PlateColorDB or not next(PlateColorDB) then
		print("|cffff0000[PlateColor]|r " .. L["数据库为空无法导出"])
		return
	end
	
	local PCExportStr = C_EncodingUtil.SerializeJSON(PlateColorDB,{ ignoreSerializationErrors = true })
	ns.ShowBox(PCExportStr)
end)

-- 导入按钮
local importbtn = ns.AddfuncButton(ConFrame6,6,L["导入配置"],L["导入配置"])
importbtn:HookScript("OnClick", function()
	ns.ShowBox()
end)

end)