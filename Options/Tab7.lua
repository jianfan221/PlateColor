local addonName,ns = ...

ns.event("PLAYER_ENTERING_WORLD", function()
--分页7滚动框架
local ConFramescrollFrame7 = CreateFrame("ScrollFrame", nil, ns.tabframe7, "ScrollFrameTemplate")
ConFramescrollFrame7:SetPoint("TOPLEFT", ns.tabframe7, "TOPLEFT", 4, -5)
ConFramescrollFrame7:SetPoint("BOTTOMRIGHT", ns.tabframe7, "BOTTOMRIGHT", -30, 5)
ConFramescrollFrame7:SetScript("OnMouseWheel", function(self, value)
	local step = 70
	local scroll = self:GetVerticalScroll()
	local range = self:GetVerticalScrollRange()
	if value > 0 then
		self:SetVerticalScroll(math.max(0, scroll - step))
	else
		self:SetVerticalScroll(math.min(range, scroll + step))
	end
end)
--分页7滚动内容
local ConFrame7 = CreateFrame("Frame", nil, ConFramescrollFrame7)
ConFrame7:SetSize(650,460)
ConFramescrollFrame7:SetScrollChild(ConFrame7)

-- 显示更新日志文本
local text = ns.UpdateText or "暂无更新记录"
local logFont = ConFrame7:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
logFont:SetPoint("TOPLEFT", 10, -5)
logFont:SetWidth(630)
logFont:SetText(text)
logFont:SetFontObject("PC_FontOutline")
logFont:SetFontHeight(15)
logFont:SetJustifyH("LEFT")
logFont:SetWordWrap(true)
logFont:SetSpacing(8)

-- 根据文本自适应高度
ConFrame7:SetHeight(math.max(logFont:GetStringHeight() + 20, 460))

end)
