local addonName,ns = ...
local L = ns.L
local DB = ns.PlateColorDB

ns.event("PLAYER_ENTERING_WORLD", function()
--检查LibSharedMedia插入所有LSM已注册的材质
if LibStub and LibStub("LibSharedMedia-3.0",true) then
	local LSMtextures = LibStub("LibSharedMedia-3.0"):HashTable("statusbar")
	for key, value in pairs(LSMtextures) do
		ns.HpTextures[key] = value
	end
end

--分页1滚动框架
local ConFramescrollFrame1 = CreateFrame("ScrollFrame", nil, ns.tabframe1, "ScrollFrameTemplate")
ConFramescrollFrame1:SetPoint("TOPLEFT", ns.tabframe1, "TOPLEFT", 4, -5)
ConFramescrollFrame1:SetPoint("BOTTOMRIGHT", ns.tabframe1, "BOTTOMRIGHT", -30, 5)

--分页1滚动内容
local ConFrame1 = CreateFrame("Frame", nil, ConFramescrollFrame1)
ConFrame1:SetSize(670,480)
ConFramescrollFrame1:SetScrollChild(ConFrame1)
ns.Y[1] = 0	--设置起始位置

local HitTest = ns.AddSetTiText(ConFrame1,1,L["暴雪姓名板设置"])
local realltextRe = ns.AddfuncButton(ConFrame1,1,L["帮我设置暴雪姓名板"],L["点击自动设置ESC-选项-姓名板里的相关选项"])
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

local HitTest = ns.AddSetTiText(ConFrame1,1,L["点击范围"])
local HitTestShow = ns.AddSetClickB(ConFrame1,1,L["显示点击范围"],L["显示点击范围"],"HitTestShow",ns.SetPoints)
local HitWidth = ns.AddSetSlider(ConFrame1,1,L["点击范围宽度"],L["点击范围宽度"],-10,25,1,"%d","HitWidth",ns.SetPoints)
local HitHeight = ns.AddSetSlider(ConFrame1,1,L["点击范围顶部"],L["点击范围顶部"],-6,20,1,"%d","HitHeight",ns.SetPoints)
local HitBottom = ns.AddSetSlider(ConFrame1,1,L["点击范围底部"],L["点击范围底部"],-6,20,1,"%d","HitBottom",ns.SetPoints)
local HitHelp = ns.AddSetClickB(ConFrame1,1,L["友方点击穿透"],L["友方点击穿透"],"HitHelp",ns.SetPoints)

local TiText1 = ns.AddSetTiText(ConFrame1,1,L["血条"])
local hpbarTexture = ns.AddSetDropdTexture(ConFrame1,1,L["血条材质选择"],L["血条材质选择"],"hpbarTexture",ns.HpTextures,ns.TextureSetting)
local hpbgAlpha = ns.AddSetSlider(ConFrame1,1,L["背景透明度"],L["背景透明度"],0,1,0.01,"%.2f","hpbgAlpha",ns.TextureSetting)
local hpborders = ns.AddSetDropdTexture2(ConFrame1,1,L["血条边框材质选择"],L["血条边框材质选择"],"hpBorderTexture",ns.HPBorderTexture,ns.TextureSetting)
local npWidht = ns.AddSetSlider(ConFrame1,1,L["姓名版宽度"],L["姓名版宽度"],5,50,1,"%d","hpWidht",ns.SetPoints)
local npHeight = ns.AddSetSlider(ConFrame1,1,L["姓名版高度"],L["姓名版高度"],5,30,1,"%d","hpHeight",ns.SetPoints)

local TiText1 = ns.AddSetTiText(ConFrame1,1,L["名字"])
local whiteName = ns.AddSetClickB(ConFrame1,1,L["白色名字"],L["白色名字"],"whiteName",ns.SetNameColor)
local nameOUTLINE = ns.AddSetClickB(ConFrame1,1,L["名字描边"],L["名字描边"],"nameOUTLINE",ns.SetPoints)
local Nametable = {{L["中上"],1},{L["左上"],2},{L["左中"],3},{L["左下"],4},{L["中下"],5}}
local namePoint = ns.AddSetDropdM(ConFrame1,1,L["名字位置"],L["名字位置"],Nametable,"namePoint",ns.SetPoints)
local nameVoffset = ns.AddSetSlider(ConFrame1,1,L["名字垂直偏移"],L["名字垂直偏移"],-10,10,1,"%d","nameVoffset",ns.SetPoints)
local NameScale = ns.AddSetSlider(ConFrame1,1,L["名字尺寸"],L["名字尺寸"],5,30,1,"%d","nameScale",ns.SetPoints)

local TiText2 = ns.AddSetTiText(ConFrame1,1,L["友方"])
local onlyName = ns.AddSetClickB(ConFrame1,1,L["友方玩家名字模式"],L["友方玩家名字模式"],"onlyName",ns.SetOnlyNames)
local onlyNameClassColor = ns.AddSetClickB(ConFrame1,1,L["友方玩家名字模式职业染色"],L["友方玩家名字模式职业染色"],"onlyNameClassColor",ns.SetOnlyNames)
local showGuildName = ns.AddSetClickB(ConFrame1,1,L["友方玩家公会名称"],L["友方玩家公会名称"],"showGuildName",ns.SetOnlyNames)
local onlyNameNpc = ns.AddSetClickB(ConFrame1,1,L["友方NPC名字模式"],L["友方NPC名字模式"],"onlyNameNpc",ns.SetOnlyNames)
local friendNameScale = ns.AddSetSlider(ConFrame1,1,L["友方名字模式尺寸"],L["友方名字模式尺寸"],5,30,1,"%d","helpNameScale",ns.SetOnlyNames)


local TiText5 = ns.AddSetTiText(ConFrame1,1,L["施法条"])
local castTexture = ns.AddSetDropdTexture(ConFrame1,1,L["施法条材质选择"],L["施法条材质选择"],"castTexture",ns.HpTextures)
local castBarHeight = ns.AddSetSlider(ConFrame1,1,L["施法条高度"],L["施法条高度鼠标提示"],5,30,1,"%d","castBarHeight",ns.SetPoints)
local castIconBig = ns.AddSetClickB(ConFrame1,1,L["施法图标放大"],L["施法图标放大"],"castIconBig",ns.SetPoints)
local casttable = {{L["左"],1},{L["中"],2}}
local castPoint = ns.AddSetDropdM(ConFrame1,1,L["施法名称位置"],L["施法名称位置"],casttable,"castPoint",ns.SetPoints)
local castTime = ns.AddSetClickB(ConFrame1,1,L["施法剩余时间"],L["施法剩余时间"],"castTime",ns.SetPoints)
local castTextScale = ns.AddSetSlider(ConFrame1,1,L["施法条文本尺寸"],L["施法条文本尺寸"],8,30,1,"%d","castTextScale",ns.SetPoints)
local castTargettable = {{L["右侧内部"],1},{L["右侧外部"],2},{L["右中"],3},{L["右上"],4}}
local castTargetPoint = ns.AddSetDropdM(ConFrame1,1,L["施法目标名字位置"],L["施法目标名字位置"],castTargettable,"castTargetPoint",ns.SetPoints)
local castTargetSize = ns.AddSetSlider(ConFrame1,1,L["施法目标名字尺寸"],L["施法目标名字尺寸"],8,30,1,"%d","castTargetScale",ns.SetPoints)
local nointerrupcolor = ns.AddSetColorF(ConFrame1,1,L["不可打断法术颜色"],L["不可打断法术颜色"],"nointerrupcolor",ns.SetCastBarInitColor)
local castcolor = ns.AddSetColorF(ConFrame1,1,L["读条法术颜色"],L["读条法术颜色"],"castcolor",ns.SetCastBarInitColor)
local channelcolor = ns.AddSetColorF(ConFrame1,1,L["引导法术颜色"],L["引导法术颜色"],"channelcolor",ns.SetCastBarInitColor)

local HitTest = ns.AddSetTiText(ConFrame1,1,L["生命值"])
local hpValue = ns.AddSetClickB(ConFrame1,1,L["生命值数值"],L["生命值数值"],"hpValue")
local hpPercent = ns.AddSetClickB(ConFrame1,1,L["生命值百分比"],L["生命值百分比"],"hpPercent")
local HpText1 = ns.AddSetSlider(ConFrame1,1,L["生命值文本尺寸"],L["生命值文本尺寸"],8,30,1,"%d","HpTextScale1",ns.SetPoints)
local AbbconfigTable = {{"万,亿",1},{"K,M",2},{L["暴雪默认"],3}}
local Abbconfig = ns.AddSetDropdM(ConFrame1,1,L["数值格式"],L["数值格式"],AbbconfigTable,"Abbconfig")
local Ftable = {{"",""},{"( )","( )"},{":",":"},
{"|cffB2B2B2|||r","|cffB2B2B2|||r"},{"|cffB2B2B2/|r","|cffB2B2B2/|r"},{"|cffB2B2B2-|r","|cffB2B2B2-|r"}}
local delimiter = ns.AddSetDropdM(ConFrame1,1,L["分隔符"],L["分隔符"],Ftable,"delimiter")
local HpTextPointtable = {{L["左"],1},{L["中"],2},{L["右"],3}}
local HpTextPoint = ns.AddSetDropdM(ConFrame1,1,L["生命值文本位置"],L["生命值文本位置"],HpTextPointtable,"HpTextPoint",ns.SetPoints)
local HpTextVoffset = ns.AddSetSlider(ConFrame1,1,L["生命值文本垂直偏移"],L["生命值文本垂直偏移"],-50,50,1,"%d","HpTextVoffset",ns.SetPoints)
local HpTextHoffset = ns.AddSetSlider(ConFrame1,1,L["生命值文本水平偏移"],L["生命值文本水平偏移"],-50,50,1,"%d","HpTextHoffset",ns.SetPoints)

local mark = ns.AddSetTiText(ConFrame1,1,L["标记"])
local markScale = ns.AddSetSlider(ConFrame1,1,L["标记尺寸"],L["标记尺寸"],0.5,3,0.1,"%.1f","markScale",ns.SetPoints)
local markHoffset = ns.AddSetSlider(ConFrame1,1,L["标记水平偏移"],L["标记水平偏移"],-80,80,1,"%d","markHoffset",ns.SetPoints)
local markVoffset = ns.AddSetSlider(ConFrame1,1,L["标记垂直偏移"],L["标记垂直偏移"],-80,80,1,"%d","markVoffset",ns.SetPoints)

local auras = ns.AddSetTiText(ConFrame1,1,AURAS)
local hideAuraTooltip = ns.AddSetClickB(ConFrame1,1,L["隐藏光环鼠标提示"],L["隐藏光环鼠标提示"],"hideAuraTooltip")
local auraText1 = ns.AddSetSlider(ConFrame1,1,L["光环冷却时间文本尺寸"],L["光环冷却时间文本尺寸"],0.5,1.5,0.1,"%.1f","auraText1")
local auraTopScale = ns.AddSetSlider(ConFrame1,1,L["上方减益光环尺寸"],L["上方减益光环尺寸"],0.5,3,0.1,"%.1f","auraTopScale")
local auraLScale = ns.AddSetSlider(ConFrame1,1,L["左侧增益光环尺寸"],L["左侧增益光环尺寸"],0.5,3,0.1,"%.1f","auraLScale")
local auraRScale = ns.AddSetSlider(ConFrame1,1,L["右侧控制光环尺寸"],L["右侧控制光环尺寸"],0.5,3,0.1,"%.1f","auraRScale")

local Personal = ns.AddSetTiText(ConFrame1,1,L["个人资源"])
local myHPSetup = ns.AddSetClickB(ConFrame1,1,L["启用个人资源设置"],L["启用个人资源设置"],"myHPSetup",ns.AllmyPowerBar)
local myHPEdit = ns.AddSetClickB(ConFrame1,1,L["编辑模式自动居中"],L["编辑模式自动居中"],"myHPEdit")
local myHPTexture = ns.AddSetDropdTexture(ConFrame1,1,L["个人资源材质"],L["个人资源材质"],"myHPTexture",ns.HpTextures,ns.AllmyPowerBar)
local myHPwidth = ns.AddSetSlider(ConFrame1,1,L["个人资源宽度"],L["个人资源宽度"],150,400,1,"%d","myHPwidth",ns.AllmyPowerBar)
local myHPheight = ns.AddSetSlider(ConFrame1,1,L["个人资源高度"],L["个人资源高度"],5,40,1,"%d","myHPheight",ns.AllmyPowerBar)
local myHPValue = ns.AddSetClickB(ConFrame1,1,L["个人资源数值"],L["个人资源数值"],"myHPValue",ns.AllmyPowerBar)
local ShowModeTable = {{L["暴雪原版"],0},{L["新版资源条"],1},{L["精简2行"],2}}
local myHPShowMode = ns.AddSetDropdM(ConFrame1,1,L["额外资源模式"],L["额外资源模式"],ShowModeTable,"myHPShowMode",ns.AllmyPowerBar)
local newClassBarColor = ns.AddClickColor(ConFrame1,1,L["新版资源条自定义颜色"],L["新版资源条自定义颜色"],"newClassBarSetColor","newClassBarColor",ns.AllmyPowerBar)
local myHPStaggerValue = ns.AddSetClickB(ConFrame1,1,L["武僧坦克酒池使用数值"],L["武僧坦克酒池使用数值"],"myHPStaggerUseValue",ns.AllmyPowerBar)
end)