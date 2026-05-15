local _, ns = ...

--名字模式功能文本
function ns.PlateOnlyName(unitFrame)
	if not unitFrame then return end
	if not unitFrame.unit then return end

	if not unitFrame.NpcFuntext then
		unitFrame.NpcFuntext = unitFrame:CreateFontString(nil, "ARTWORK")
		unitFrame.NpcFuntext:SetPoint("TOP",unitFrame.name,"BOTTOM",0,0)
		unitFrame.NpcFuntext:SetVertexColor(1,1,1)
		unitFrame.NpcFuntext:SetSmoothScaling(false)
		unitFrame.NpcFuntext:SetAlpha(0.9)
	end
	if ns.MM(UnitGUID(unitFrame.unit)) then
		unitFrame.NpcFuntext:Hide()
		return
	end
	local text = ""
	if PlateColorDB.showGuildName and unitFrame:IsPlayer() then
		unitFrame.NpcFuntext:SetFont(ns.fonts, PlateColorDB.helpNameScale * 0.9, "OUTLINE")
		text = GetGuildInfo(unitFrame.unit) or ""
		unitFrame.NpcFuntext:SetText(text)
	elseif not unitFrame:IsPlayer() then
		local tooltipData = C_TooltipInfo.GetUnit(unitFrame.unit)
		if tooltipData and tooltipData.lines[2] and not string.match(tooltipData.lines[2].leftText,LEVEL) and not unitFrame:IsPlayer() then
			unitFrame.NpcFuntext:SetFont(ns.fonts, PlateColorDB.helpNameScale * 0.8, "")
			text = tooltipData.lines[2].leftText or ""
			unitFrame.NpcFuntext:SetText(text)
		end
	end
	unitFrame.NpcFuntext:SetShown(text ~= "" and unitFrame.name:IsShown() and not unitFrame.healthBar:IsShown())
end

--设置时更新
function ns.SetOnlyNames(unitFrame)
	ns.PlateOnlyName(unitFrame)
	ns.SetSelectedScale()
	ns.SetPoints(unitFrame)
end

ns.hook("CompactUnitFrame_UpdateName", function(unitFrame)
	if unitFrame:IsForbidden() then return end
	if not string.match(unitFrame.unit,"nameplate") then return end
	ns.PlateOnlyName(unitFrame)
end)