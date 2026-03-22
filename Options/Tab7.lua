local addonName,ns = ...
local L = ns.L
local DB = ns.PlateColorDB

ns.event("PLAYER_ENTERING_WORLD", function()
--分页7滚动框架
local ConFramescrollFrame7 = CreateFrame("ScrollFrame", nil, ns.tabframe7, "UIPanelScrollFrameTemplate")
ConFramescrollFrame7:SetPoint("TOPLEFT", ns.tabframe7, "TOPLEFT", 4, -5)
ConFramescrollFrame7:SetPoint("BOTTOMRIGHT", ns.tabframe7, "BOTTOMRIGHT", -30, 5)
--分页7滚动内容
local ConFrame7 = CreateFrame("Frame", nil, ConFramescrollFrame7)
ConFrame7:SetSize(670,480)
ConFramescrollFrame7:SetScrollChild(ConFrame7)
ns.Y[7] = 0	--设置起始位置

local Yoffset = -10
local textcolor = {0.8, 0.8, 0.8, 0.9}
local function AddUpdate(name)
	local rowFrame = CreateFrame("Frame", nil, ConFrame7)
    
    rowFrame:SetPoint("TOPLEFT", 10, Yoffset)
	rowFrame:SetSize(630, 26)
	local SliderBackground = rowFrame:CreateTexture(nil, "BACKGROUND")
	SliderBackground:SetTexture(130937)
	SliderBackground:SetPoint("TOPLEFT",rowFrame,"TOPLEFT",0,0)
	SliderBackground:SetColorTexture(0.5, 0.5, 0.5, 0.1) -- 设置背景颜色为黑色，透明度为0.5
	SliderBackground:SetScript("OnEnter", function(self)
		self:SetColorTexture(0.5, 0.5, 0.5, .3)
	end)
	SliderBackground:SetScript("OnLeave", function(self)
		self:SetColorTexture(0.5, 0.5, 0.5, 0.1)
	end)
	
	local lefttext = rowFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	lefttext:SetPoint("LEFT", SliderBackground, "LEFT", 5, -1)
	lefttext:SetText(name)
	lefttext:SetFont(ns.fonts, 18, "OUTLINE")
	lefttext:SetJustifyH("LEFT") 
	lefttext:SetWordWrap(true)--换行
	lefttext:SetWidth(623)
	lefttext:SetSpacing(6)--间距
	lefttext:SetTextColor(unpack(textcolor))--颜色
	SliderBackground:SetSize(630,lefttext:GetHeight()+15)--背景颜色根据字体框架高度设置
	
	
	
	Yoffset = Yoffset - 25 - lefttext:GetHeight()--后面的位置
	
	textcolor = {0.6, 0.6, .6, 0.6}
	ns.Y[7] = ns.Y[7] + 1
end

-- 收集更新表格
local keys = {}
for k in pairs(ns.update) do
    table.insert(keys, k)
end

-- 对表格进行排序
table.sort(keys, function(a, b) return a > b end)

-- 根据排序后的表格创建文本
for _, k in ipairs(keys) do
	AddUpdate("|cff00FFFF"..k.." : |r"..ns.update[k])
end


end)