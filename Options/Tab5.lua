local addonName,ns = ...
local L = ns.L
local DB = ns.PlateColorDB

ns.event("PLAYER_ENTERING_WORLD", function()
--分页5滚动内容不需要滚动框架就直接锚定在ns.tabframe5
local ConFrame5 = CreateFrame("Frame", "ConFrame5", ns.tabframe5)
ConFrame5:SetSize(670,480)
ConFrame5:SetAllPoints(ns.tabframe4)
ns.Y[5] = 0	--设置起始位置

local focustitle = ns.AddSetTiText(ConFrame5,5,L["焦点"])
local setFocusModTable = {{L["不使用"],0},{L["Shift"],1},{L["Ctrl"],2},{L["Alt"],3}}
local setFocusMod = ns.AddSetDropdM(ConFrame5,5,L["设置焦点快捷键"],L["设置焦点快捷键鼠标提示"],setFocusModTable,"setFocusMod",ns.PCSetFocus)

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
local setFocusIcon = ns.AddSetDropdM(ConFrame5,5,L["设置焦点时自动标记"],L["设置焦点时自动标记"],setFocusIconTable,"setFocusIcon",ns.PCSetFocus)
local sendFocusIcon = ns.AddSetClickB(ConFrame5,5,L["就位时通报标记"],L["就位时通报标记"],"sendFocusIcon")

end)