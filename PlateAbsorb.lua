local _, ns = ...

function ns.AddAbsorbText(event,unit)
	if not unit or not string.match(unit,"nameplate") then return end
	local namePlate = C_NamePlate.GetNamePlateForUnit(unit,false)
	if not namePlate then return end
	if not namePlate.UnitFrame then return end
	local unitFrame = namePlate.UnitFrame
	if not PlateColorDB.absorbText then return end
	if not unitFrame.unit then return end

	if not unitFrame.abs then
		unitFrame.abs = unitFrame.healthBar:CreateFontString(nil, "OVERLAY")
		unitFrame.abs:SetFontObject("PC_FontOutline")
		unitFrame.abs:SetFontHeight(21)
		unitFrame.abs:SetSmoothScaling(false)
		if not unitFrame.ArrowLeft then
			pcall(ns.UpdateHpTexture, unitFrame)
		end
		unitFrame.abs:SetPoint("RIGHT", unitFrame.ArrowLeft or unitFrame.healthBar, "LEFT", 6, -1)
	end

	local number = UnitGetTotalAbsorbs(unitFrame.unit)
	unitFrame.abs:SetText(ns.value(number))
	if number == nil then
		unitFrame.abs:SetAlpha(0)
	else
		unitFrame.abs:SetAlpha(number)
	end
end

ns.event("UNIT_ABSORB_AMOUNT_CHANGED", ns.AddAbsorbText)
ns.event("NAME_PLATE_UNIT_ADDED", ns.AddAbsorbText)