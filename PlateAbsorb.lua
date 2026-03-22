local _, ns = ...

function ns.AddAbsorbText(event,unit)
	if not string.match(unit,"nameplate") then return end
	local namePlate = C_NamePlate.GetNamePlateForUnit(unit,false)
	if not namePlate then return end
	if not namePlate.UnitFrame then return end
	local unitFrame = namePlate.UnitFrame
	if not PlateColorDB.absorbText then return end
	if not unitFrame.unit then return end
	if not unitFrame.ArrowLeft then return end
	if not unitFrame.abs then
		unitFrame.abs = unitFrame.healthBar:CreateFontString(nil, "OVERLAY")
		unitFrame.abs:SetFont(ns.fonts, 21, "OUTLINE")
		unitFrame.abs:SetPoint("RIGHT", unitFrame.ArrowLeft, "LEFT",-3,-1)
	end
	
	unitFrame.abs:SetText("")
	local number = UnitGetTotalAbsorbs(unitFrame.unit)
	unitFrame.abs:SetText(C_StringUtil.TruncateWhenZero(number))
end

ns.event("UNIT_ABSORB_AMOUNT_CHANGED", ns.AddAbsorbText)
ns.event("NAME_PLATE_UNIT_ADDED", ns.AddAbsorbText)