local addonName,ns = ...
local L = ns.L
local DB = ns.PlateColorDB

ns.event("PLAYER_ENTERING_WORLD", function()
--分页2滚动框架
local ConFramescrollFrame2 = CreateFrame("ScrollFrame", nil, ns.tabframe2, "UIPanelScrollFrameTemplate")
ConFramescrollFrame2:SetPoint("TOPLEFT", ns.tabframe2, "TOPLEFT", 4, -5)
ConFramescrollFrame2:SetPoint("BOTTOMRIGHT", ns.tabframe2, "BOTTOMRIGHT", -30, 5)
--分页2滚动内容
local ConFrame2 = CreateFrame("Frame", nil, ConFramescrollFrame2)
ConFrame2:SetSize(670,480)
ConFramescrollFrame2:SetScrollChild(ConFrame2)
ns.Y[2] = 0	--设置起始位置

local TiText4 = ns.AddSetTiText(ConFrame2,2,L["箭头"])
local arrowShowTable = {{L["不显示"],0},{L["左"],1},{L["右"],2},{L["左+右"],3}}
local arrowPoint = ns.AddSetDropdM(ConFrame2,2,L["箭头显示方式"],L["箭头显示方式"],arrowShowTable,"arrowPoint",ns.UpdateHpTexture)
local arrowTexture = ns.AddSetDropdTexture2(ConFrame2,2,L["箭头材质"],L["箭头材质"],"arrowTexture",ns.ArrowTexture,ns.UpdateHpTexture)
local arrowColor = ns.AddSetColorF(ConFrame2,2,L["箭头颜色"],L["箭头颜色"],"arrowColor",ns.UpdateTargetTexture)
local arrowScale = ns.AddSetSlider(ConFrame2,2,L["箭头尺寸"],L["箭头尺寸"],5,50,1,"%d","arrowScale",ns.UpdateHpTexture)
local arrowHoffset = ns.AddSetSlider(ConFrame2,2,L["箭头水平偏移"],L["箭头水平偏移"],-10,10,1,"%d","arrowHoffset",ns.UpdateHpTexture)

local unittitle = ns.AddSetTiText(ConFrame2,2,L["交互"])
local Slayline = ns.AddClickColor(ConFrame2,2,L["斩杀辅助线"],L["斩杀辅助线"],"Slayline","SlaylineColor",ns.CreatSlayline)
Slayline.check:HookScript("OnEnter",function(self) 
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
end)

local SlayHpColor = ns.AddClickColor(ConFrame2,2,L["斩杀血条变色"],L["斩杀血条变色"],"SlayHp","SlayHpColor",ns.UpdateHpbarColor)
local myTargetColor = ns.AddClickColor(ConFrame2,2,L["当前目标颜色"],L["当前目标颜色"],"myTarget","myTargetColor",ns.UpdateHpbarColor)
local myFocusColor = ns.AddClickColor(ConFrame2,2,L["焦点血条颜色"],L["焦点血条颜色"],"myFocus","myFocusColor",ns.UpdateHpbarColor)
local mGlow = ns.AddClickColor(ConFrame2,2,L["鼠标指向边框变色"],L["鼠标指向边框变色"],"mGlow","mGlowColor")
local focusTexture = ns.AddSetClickB(ConFrame2,2,L["焦点斜线材质"],L["焦点斜线材质鼠标提示"],"focusTexture")

local CVars = ns.AddSetTiText(ConFrame2,2,"CVars")
local SelectedScale = ns.AddSetSlider(ConFrame2,2,L["当前目标尺寸"],L["当前目标尺寸"],1,2,0.1,"%.1f","SelectedScale",ns.SetSelectedScale)
local wallAlpha = ns.AddSetSlider(ConFrame2,2,L["隔墙姓名板透明度"],L["隔墙姓名板透明度"],0,1,0.1,"%.1f","wallAlpha",ns.SetSelectedScale)
local allNpAlpha = ns.AddSetSlider(ConFrame2,2,L["非当前目标透明度"],L["非当前目标透明度"],0,1,0.1,"%.1f","allNpAlpha",ns.SetSelectedScale)
local npOverlapV = ns.AddSetSlider(ConFrame2,2,L["垂直堆叠间距"],L["垂直堆叠间距"],0.1,2,0.1,"%.1f","npOverlapV",ns.SetSelectedScale)
local npOverlapH = ns.AddSetSlider(ConFrame2,2,L["水平堆叠间距"],L["垂直堆叠间距"],0.1,2,0.1,"%.1f","npOverlapH",ns.SetSelectedScale)
local npRange = ns.AddSetSlider(ConFrame2,2,L["姓名版可见范围"],L["姓名版可见范围"],10,60,1,"%d","npRange",ns.SetSelectedScale)

local TiTextQT = ns.AddSetTiText(ConFrame2,2,L["其他"])
local nameQuestTable = {{L["不显示"],0},{L["名字后"],1},{L["血条后"],2}}
local nameQuest = ns.AddSetDropdM(ConFrame2,2,L["显示任务标志"],L["显示任务标志鼠标提示"],nameQuestTable,"nameQuestPos",ns.CteatNameQuest)
local levelText = ns.AddSetClickB(ConFrame2,2,L["等级文本"],L["等级文本鼠标提示"],"levelText")
local absorbText = ns.AddSetClickB(ConFrame2,2,L["吸收盾数值"],L["吸收盾数值鼠标提示"],"absorbText")

end)