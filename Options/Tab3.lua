local addonName,ns = ...
local L = ns.L
local DB = ns.PlateColorDB

ns.event("PLAYER_ENTERING_WORLD", function()
--分页3滚动框架
local ConFramescrollFrame3 = CreateFrame("ScrollFrame", nil, ns.tabframe3, "UIPanelScrollFrameTemplate")
ConFramescrollFrame3:SetPoint("TOPLEFT", ns.tabframe3, "TOPLEFT", 4, -5)
ConFramescrollFrame3:SetPoint("BOTTOMRIGHT", ns.tabframe3, "BOTTOMRIGHT", -30, 5)
--分页3滚动内容
local ConFrame3 = CreateFrame("Frame", nil, ConFramescrollFrame3)
ConFrame3:SetSize(670,480)
ConFramescrollFrame3:SetScrollChild(ConFrame3)
ns.Y[3] = 0	--设置起始位置

local qt = ns.AddSetTiText(ConFrame3,3,L["其他颜色"])
local allColor = ns.AddSetColorF(ConFrame3,3,L["全局颜色"],L["全局颜色鼠标提示"],"allColor")

local threatColors = ns.AddSetTiText(ConFrame3,3,L["仇恨"])
local threatUseTable = {{L["无"],0},{L["名字"],1},{L["血条"],2},{L["名字+血条"],3}}
local threatUse = ns.AddSetDropdM(ConFrame3,3,L["颜色作用于"],L["启用仇恨变色鼠标提示"],threatUseTable,"threatUse",ns.SetNpcLevelColor)
local noThreatColor = ns.AddSetColorF(ConFrame3,3,L["低仇恨"],L["低仇恨鼠标提示"],"noThreatColor",ns.UpdateHpbarColor)
local highThreatColor = ns.AddSetColorF(ConFrame3,3,L["高仇恨"],L["高仇恨鼠标提示"],"highThreatColor",ns.UpdateHpbarColor)
local myThreatColor = ns.AddSetColorF(ConFrame3,3,L["仇恨是你"],L["仇恨是你鼠标提示"],"myThreatColor",ns.UpdateHpbarColor)
local lowThreatColor = ns.AddSetColorF(ConFrame3,3,L["仇恨不稳"],L["仇恨不稳鼠标提示"],"lowThreatColor",ns.UpdateHpbarColor)

local isthreatColors = ns.AddSetTiText(ConFrame3,3,L["坦克仇恨"])
local TankthreatUse = ns.AddSetDropdM(ConFrame3,3,L["颜色作用于"],L["启用坦克仇恨变色鼠标提示"],threatUseTable,"TankthreatUse",ns.SetNpcLevelColor)
local TnoThreatColor = ns.AddSetColorF(ConFrame3,3,L["坦克低仇恨"],L["坦克低仇恨鼠标提示"],"TANKnoThreatColor",ns.UpdateHpbarColor)
local ThighThreatColor = ns.AddSetColorF(ConFrame3,3,L["坦克高仇恨"],L["坦克高仇恨鼠标提示"],"TANKhighThreatColor",ns.UpdateHpbarColor)
local TmyThreatColor = ns.AddSetColorF(ConFrame3,3,L["坦克仇恨是你"],L["坦克仇恨是你鼠标提示"],"TANKmyhreatColor",ns.UpdateHpbarColor)
local TlowThreatColor = ns.AddSetColorF(ConFrame3,3,L["坦克仇恨不稳"],L["坦克仇恨不稳鼠标提示"],"TANKlowThreatColor",ns.UpdateHpbarColor)

end)