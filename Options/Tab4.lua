local addonName,ns = ...
local L = ns.L
local DB = ns.PlateColorDB

ns.event("PLAYER_ENTERING_WORLD", function()
--分页4滚动内容不需要滚动框架就直接锚定在ns.tabframe4
local ConFrame4 = CreateFrame("Frame", nil, ns.tabframe4)
ConFrame4:SetSize(670,480)
ConFrame4:SetAllPoints(ns.tabframe4)
ns.Y[4] = 0	--设置起始位置

local use = ns.AddSetTiText(ConFrame4,4,L["NPC颜色作用于"])
local UseNpctable = {{L["无"],0},{L["名字"],1},{L["血条"],2},{L["名字+血条"],3}}
local UseNpc = ns.AddSetDropdM(ConFrame4,4,L["NPC颜色作用于"],L["NPC颜色作用于"],UseNpctable,"UseNpc",ns.UpdateSetColor)

local npctitle = ns.AddSetTiText(ConFrame4,4,L["NPC分类"])
local NpcLv1Color = ns.AddClickColor(ConFrame4,4,L["等级>1颜色"],L["等级>1鼠标提示"],"NpcLv1","NpcLv1Color",ns.UpdateSetColor)
local NpcLv2Color = ns.AddClickColor(ConFrame4,4,L["BOSS颜色"],L["BOSS颜色"],"NpcLv2","NpcLv2Color",ns.UpdateSetColor)
local NpckickColor = ns.AddClickColor(ConFrame4,4,L["可打断NPC颜色"],L["可打断NPC颜色"],"Npckick","NpckickColor",ns.UpdateSetColor)
local NpcNokickColor = ns.AddClickColor(ConFrame4,4,L["不可打断NPC颜色"],L["不可打断NPC颜色"],"NpcNokick","NpcNokickColor",ns.UpdateSetColor)
NpcNokickColor.check:Disable()
NpcNokickColor.text:SetVertexColor(0.6,0.6,0.6)
NpckickColor.check:HookScript("OnClick",function(self)
	NpcNokickColor.check:SetChecked(self:GetChecked())
end)
local NpcSukickColor = ns.AddClickColor(ConFrame4,4,L["可能是可打断NPC颜色"],L["可能是可打断NPC颜色"],"NpcSukick","NpcSukickColor",ns.UpdateSetColor)
end)