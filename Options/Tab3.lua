local addonName,ns = ...
local L = ns.L
local DB = ns.PlateColorDB

ns.event("PLAYER_ENTERING_WORLD", function()
--分页3滚动框架
local ConFramescrollFrame3 = CreateFrame("ScrollFrame", nil, ns.tabframe3, "ScrollFrameTemplate")
ConFramescrollFrame3:SetPoint("TOPLEFT", ns.tabframe3, "TOPLEFT", 4, -5)
ConFramescrollFrame3:SetPoint("BOTTOMRIGHT", ns.tabframe3, "BOTTOMRIGHT", -30, 5)
ConFramescrollFrame3:SetScript("OnMouseWheel", function(self, value)
	local step = 70
	local scroll = self:GetVerticalScroll()
	local range = self:GetVerticalScrollRange()
	if value > 0 then
		self:SetVerticalScroll(math.max(0, scroll - step))
	else
		self:SetVerticalScroll(math.min(range, scroll + step))
	end
end)
--分页3滚动内容
local ConFrame3 = CreateFrame("Frame", nil, ConFramescrollFrame3)
ConFrame3:SetSize(670,480)
ConFramescrollFrame3:SetScrollChild(ConFrame3)
ns.Y[3] = 0	--设置起始位置

ns.AddSetTiText(ConFrame3,3,L["其他颜色"])
ns.AddSetColorF(ConFrame3,3,L["全局颜色"],L["全局颜色鼠标提示"],"allColor")

ns.AddSetTiText(ConFrame3,3,L["仇恨"])
local threatUseTable = {{L["无"],0},{L["名字"],1},{L["血条"],2},{L["名字+血条"],3}}
ns.AddSetDropdM(ConFrame3,3,L["颜色作用于"],L["启用仇恨变色鼠标提示"],threatUseTable,"threatUse",ns.SetNpcLevelColor)
ns.AddSetColorF(ConFrame3,3,L["低仇恨"],L["低仇恨鼠标提示"],"noThreatColor",ns.UpdateHpbarColor)
ns.AddSetColorF(ConFrame3,3,L["高仇恨"],L["高仇恨鼠标提示"],"highThreatColor",ns.UpdateHpbarColor)
ns.AddSetColorF(ConFrame3,3,L["仇恨是你"],L["仇恨是你鼠标提示"],"myThreatColor",ns.UpdateHpbarColor)
ns.AddSetColorF(ConFrame3,3,L["仇恨不稳"],L["仇恨不稳鼠标提示"],"lowThreatColor",ns.UpdateHpbarColor)

ns.AddSetTiText(ConFrame3,3,L["坦克仇恨"])
ns.AddSetDropdM(ConFrame3,3,L["颜色作用于"],L["启用坦克仇恨变色鼠标提示"],threatUseTable,"TankthreatUse",ns.SetNpcLevelColor)
ns.AddSetColorF(ConFrame3,3,L["坦克低仇恨"],L["坦克低仇恨鼠标提示"],"TANKnoThreatColor",ns.UpdateHpbarColor)
ns.AddSetColorF(ConFrame3,3,L["坦克高仇恨"],L["坦克高仇恨鼠标提示"],"TANKhighThreatColor",ns.UpdateHpbarColor)
ns.AddSetColorF(ConFrame3,3,L["坦克仇恨是你"],L["坦克仇恨是你鼠标提示"],"TANKmyhreatColor",ns.UpdateHpbarColor)
ns.AddSetColorF(ConFrame3,3,L["坦克仇恨不稳"],L["坦克仇恨不稳鼠标提示"],"TANKlowThreatColor",ns.UpdateHpbarColor)

end)