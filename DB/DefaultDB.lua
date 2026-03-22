local addonName,ns = ...

ns.PlateColorDB = {
	myVersion = 0,
	HitTestShow = false,		--显示点击范围
	HitWidth = 5,				--点击范围宽度
	HitHeight = 8,				--点击范围顶部
	HitBottom = 0,				--点击范围底部
	HitHelp = true,				--点击范围友方穿透
	
	whiteName = false,			--白色名字
	nameOUTLINE = true,			--名字描边
	namePoint = 1,				--名字位置
	nameVoffset = 0,			--名字垂直偏移
	nameScale = 14,				--名字大小
	
	hpbarTexture = "PC-White",	--血条材质选择
	hpbgAlpha = 0.55,			--血条背景透明度
	hpBorder = true,			--血条直角边框
	hpWidht = 25,				--血条宽度
	hpHeight = 14,				--血条高度
	
	castTexture = "PC-White",	--施法条材质选择
	castIconBig = false,		--施法图标大型
	castBarHeight = 18,			--施法条高度
	castPoint = 2,				--施法名称位置
	castTime = true,			--施法剩余时间
	castTextScale = 11,			--施法条文本大小
	castTargetPoint = 4,		--施法目标名字位置
	castTargetScale = 22,		--施法目标名字大小
	
	onlyName = true,                        --友方玩家名字模式
	onlyNameClassColor = true,              --友方玩家名字模式职业染色
	onlyNameNpc = true,                     --友方NPC名字模式
	alwaysShowNames = true,                 --始终显示所有名字
	helpNameScale = 15,                     --友方名字大小
	showGuildName = false,		--显示公会名称
	
	hpValue = false,			--生命值数值
	hpPercent = true,			--生命值百分比
	Abbconfig = 3,				--数值单位
	delimiter = "( )",			--数值百分比分隔符
	HpTextPoint = 3,			--生命值文本位置
	HpTextVoffset = 0,			--生命值文本垂直偏移
	HpTextHoffset = 0,			--生命值文本水平偏移
	HpTextScale1 = 13,			--生命值文本尺寸

	auraText1 = 1,				--光环冷却时间文本尺寸
	hideAuraTooltip = true,		--隐藏光环鼠标提示
	auraTopScale = 1,			--上方减益光环尺寸
	auraLScale = 1.5,			--左侧增益光环尺寸
	auraRScale = 2,				--右侧控制光环尺寸
	
	myHPSetup = true,			--启用个人资源设置
	myHPShowMode = 2,			--额外资源显示模式(0=暴雪原版,1=新版资源条,2=精简模式)
	myHPValue = true,			--个人资源数值显示
	myHPEdit = true,			--编辑模式自动居中
	myHPwidth = 200,			--个人资源宽度
	myHPheight = 15,			--个人资源高度
	myHPTexture = "PC-White",	--个人资源血条材质
	newClassBarSetColor = false,	--新版资源条自定义颜色开关
	newClassBarColor = {r=1, g=1, b=1},	--新版资源条自定义颜色
	
	allColor = {r=1, g=0, b=0}, 		--全局颜色
	threatUse = 2,				--颜色作用于
	noThreatColor = {r=1, g=0, b=0},	--无仇恨
	highThreatColor = {r=1, g=0.5, b=0},--高仇恨
	myThreatColor = {r=0.3, g=0, b=0.6},--仇恨是你
	lowThreatColor = {r=0.2, g=0.3, b=0.6},--仇恨降低
	TankthreatUse = 2,			--颜色作用于
	TANKnoThreatColor = {r=1, g=0, b=0},--T无仇恨
	TANKhighThreatColor = {r=1, g=0.5, b=0},--T高仇恨
	TANKmyhreatColor = {r=0.3, g=0, b=0.6},--T仇恨是你
	TANKlowThreatColor = {r=0.2, g=0.3, b=0.6},--T仇恨降低
	
	arrowPoint = 3,				--箭头显示方式
	arrowTexture = "EthricArrow2",--箭头材质
	arrowColor = {r=1, g=1, b=1},--箭头颜色
	arrowScale = 20,			--箭头尺寸
	arrowHoffset = 0,			--箭头水平偏移
	
	
	Slayline = true,			--斩杀线
	SlaylineColor = {r=1,g=1,b=1},--斩杀线颜色
	SlayHp = true,				--斩杀血条变色
	SlayHpColor = {r= 1,g=0,b=1},--斩杀血条颜色
	myTarget = true,					--当前目标变色
	myTargetColor = {r=0, g=1, b=1},	--当前目标颜色
	myFocus = false,					--焦点变色
	myFocusColor = {r=1, g=0.7, b=0.8},	--焦点颜色
	mGlow = true,				--鼠标指向边框变色
	mGlowColor = {r=0, g=1, b=1},--鼠标指向边框颜色
	focusTexture = true,		--焦点斜线材质
	
	SelectedScale = 1.2,				--当前目标尺寸
	wallAlpha = 1,				--隔墙姓名板透明度
	allNpAlpha = 1,				--姓名版透明度
	npOverlapV = 1.1,			--姓名版垂直间距
	npOverlapH = 0.8,			--姓名版水平间距
	npRange = 60,				--姓名版可见范围
	
	nameQuestPos = 2,		--显示任务标志(0=不显示,1=名字后,2=血条后)
	levelText = true,			--等级文本
	absorbText = true,			--吸收盾文本
	
	
	UseNpc = 1,					--NPC颜色作用于
	NpcLv1 = true,				--等级>1
	NpcLv1Color = {r=1, g=0, b=1},--等级>1斩杀颜色
	NpcLv2 = true,				--等级>2
	NpcLv2Color = {r=1, g=0, b=1},--等级>2斩杀颜色
	Npckick = true,				--可打断NPC
	NpckickColor = {r=0,g=0, b=1},--可打断NPC颜色
	NpcSukick = true,			--可能是可打断NPC
	NpcSukickColor = {r=0,g=1, b=1},-- 可能是可打断NPC颜色
	NpcNokick = true,			--不可打断NPC
	NpcNokickColor = {r=0,g=1, b=1},--不可打断NPC颜色
	
	
	setFocusMod = 1,			--设置焦点快捷键
	setFocusIcon = 0,			--设置焦点时自动标记
	sendFocusIcon = true,		--就位确认时通报焦点标记至小队

}

----------配置加载---------
local loadFrame = CreateFrame("FRAME"); 
loadFrame:RegisterEvent("ADDON_LOADED"); 
loadFrame:RegisterEvent("PLAYER_LOGOUT"); 
loadFrame:SetScript("OnEvent", function(self, event, arg1)
	if event == "ADDON_LOADED" and arg1 ~= "PlateColor" then return end
	if type(PlateColorDB) ~= "table" then PlateColorDB = {} end
	for i, j in pairs(ns.PlateColorDB) do
		if type(j) == "table" then
			if PlateColorDB[i] == nil then PlateColorDB[i] = {} end
			for k, v in pairs(j) do
				if type(k) ~= "number" and PlateColorDB[i][k] == nil then --不是颜色表
					PlateColorDB[i][k] = v
				end
			end
		else
			if PlateColorDB[i] == nil then PlateColorDB[i] = j end
		end
	end	

	for key, value in pairs(PlateColorDB) do
		if ns.PlateColorDB[key] == nil then--如果没有这个键，说明是多余的，删除它
			PlateColorDB[key] = nil
		end
	end
end)
