local addonName,ns = ...
local L = ns.L

ns.event("PLAYER_ENTERING_WORLD", function()
--分页6滚动框架
local ConFramescrollFrame6 = CreateFrame("ScrollFrame", nil, ns.tabframe6, "ScrollFrameTemplate")
ConFramescrollFrame6:SetPoint("TOPLEFT", ns.tabframe6, "TOPLEFT", 4, -5)
ConFramescrollFrame6:SetPoint("BOTTOMRIGHT", ns.tabframe6, "BOTTOMRIGHT", -30, 5)
--分页6滚动内容
local ConFrame6 = CreateFrame("Frame", nil, ConFramescrollFrame6)
ConFrame6:SetSize(670,480)
ConFramescrollFrame6:SetScrollChild(ConFrame6)
ns.Y[6] = 0	--设置起始位置


local titext1 = ns.AddSetTiText(ConFrame6,6,L["配置"])
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