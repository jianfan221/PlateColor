local _, ns = ...

function ns.BorderSetting(unitFrame, frame, offset)
	frame:SetTexture(ns.HPBorderTexture[PlateColorDB.hpBorderTexture])
	local brset = ns.HPBorderTextureList[PlateColorDB.hpBorderTexture]
	local margin = brset.margin
	local XY = brset.XY
	if offset then
		XY = XY * offset+2
	end

	frame:SetTextureSliceMargins(margin, margin, margin, margin)
	frame:ClearAllPoints()
	frame:SetPoint("TOPLEFT", unitFrame.healthBar, "TOPLEFT", -XY, XY)
	frame:SetPoint("BOTTOMRIGHT", unitFrame.healthBar, "BOTTOMRIGHT", XY, -XY)

	--血条遮罩
	if not unitFrame.healthBar.customMask then
		unitFrame.healthBar.customMask = unitFrame.healthBar:CreateMaskTexture()
		unitFrame.healthBar.customMask:SetAllPoints(unitFrame.healthBar)
		unitFrame.healthBar:GetStatusBarTexture():AddMaskTexture(unitFrame.healthBar.customMask)
	end
	unitFrame.healthBar.customMask:SetTextureSliceMargins(margin, margin, margin, margin)
	unitFrame.healthBar.customMask:SetTexture(ns.HPBorderMask[PlateColorDB.hpBorderTexture], "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
	--血条背景遮罩
	if not unitFrame.healthBar.BGMask then
		unitFrame.healthBar.BGMask = unitFrame.healthBar:CreateMaskTexture()
		unitFrame.healthBar.BGMask:SetAllPoints(unitFrame.healthBar.bgTexture)
		unitFrame.healthBar.bgTexture:AddMaskTexture(unitFrame.healthBar.BGMask)
	end
	unitFrame.healthBar.BGMask:SetTextureSliceMargins(margin, margin, margin, margin)
	unitFrame.healthBar.BGMask:SetTexture(ns.HPBorderMask[PlateColorDB.hpBorderTexture], "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
	--施法条遮罩
	local castbar = unitFrame.CastBar or unitFrame.castBar
	if castbar then
		if not castbar.customMask then
			castbar.customMask = castbar:CreateMaskTexture()
			castbar.customMask:SetAllPoints(castbar)
			castbar:GetStatusBarTexture():AddMaskTexture(castbar.customMask)
		end
		castbar.customMask:SetTextureSliceMargins(margin, margin, margin, margin)
		castbar.customMask:SetTexture(ns.HPBorderMask[PlateColorDB.hpBorderTexture], "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
		--施法条背景遮罩
		if not castbar.BGMask then
			castbar.BGMask = castbar:CreateMaskTexture()
			castbar.BGMask:SetAllPoints(castbar.Background)
			castbar.Background:AddMaskTexture(castbar.BGMask)
		end
		castbar.BGMask:SetTextureSliceMargins(margin, margin, margin, margin)
		castbar.BGMask:SetTexture(ns.HPBorderMask[PlateColorDB.hpBorderTexture], "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
	end
end

function ns.UpdateHpTexture(unitFrame)
	if not unitFrame or not unitFrame.unit then return end
		
	-----创建材质-----
	--鼠标指向材质
	if not unitFrame.MouseoverTexture then
		unitFrame.MouseoverTexture = unitFrame.healthBar:CreateTexture(nil, "OVERLAY")
		unitFrame.MouseoverTexture:SetPoint("TOPLEFT", unitFrame.healthBar, "TOPLEFT", -5, 5)
		unitFrame.MouseoverTexture:SetPoint("BOTTOMRIGHT", unitFrame.healthBar, "BOTTOMRIGHT", 5, -5)
	end
	if unitFrame.MouseoverTexture then
		ns.BorderSetting(unitFrame, unitFrame.MouseoverTexture,2)
		unitFrame.MouseoverTexture:Hide()
	end
	--焦点材质
	if not unitFrame.FocusTexture then
		unitFrame.FocusTexture = unitFrame.healthBar:CreateTexture(nil, "OVERLAY")
		unitFrame.FocusTexture:SetTexture("Interface\\Addons\\PlateColor\\texture\\FocusTexture.png")
		unitFrame.FocusTexture:SetVertexColor(0, 0, 0, 1)
		unitFrame.FocusTexture:SetAllPoints(unitFrame.healthBar)
	end
	if unitFrame.FocusTexture then
		unitFrame.FocusTexture:Hide()
	end
	--左侧箭头
	if not unitFrame.ArrowLeft then
		unitFrame.ArrowLeft = unitFrame:CreateTexture(nil, "OVERLAY")
	end
	if unitFrame.ArrowLeft then
		unitFrame.ArrowLeft:SetTexture(ns.ArrowTexture[PlateColorDB.arrowTexture])
		
		unitFrame.ArrowLeft:Hide()
	end
	--右侧箭头
	if not unitFrame.ArrowRight then
		unitFrame.ArrowRight = unitFrame:CreateTexture(nil, "OVERLAY")
	end
	if unitFrame.ArrowRight then
		unitFrame.ArrowRight:SetTexture(ns.ArrowTexture[PlateColorDB.arrowTexture])
		unitFrame.ArrowRight:SetTexCoord(1, 0, 0, 1)
		unitFrame.ArrowRight:Hide()
	end
end

function ns.TextureSetting(unitFrame)
	ns.UpdateHpTexture(unitFrame)
	ns.SetPoints(unitFrame)
end


function ns.UpdateTargetTexture(unitFrame)
	if not unitFrame or not unitFrame.unit then return end
	
	local r, g, b = PlateColorDB.arrowColor["r"], PlateColorDB.arrowColor["g"], PlateColorDB.arrowColor["b"]
	local scale = PlateColorDB.arrowScale
	local isTarget = UnitIsUnit("target", unitFrame.unit)
	local hpBarShown = unitFrame.healthBar and unitFrame.healthBar:IsShown()
	local nameShown = unitFrame.name and unitFrame.name:IsShown()

	if unitFrame.ArrowLeft then
		unitFrame.ArrowLeft:SetVertexColor(r, g, b, 1)
		if hpBarShown then
			local anchor
			if unitFrame.LevelText and unitFrame.LevelText:GetText() then
				anchor = unitFrame.LevelText
			elseif unitFrame.ClassificationFrame:IsShown() then
				anchor = unitFrame.ClassificationFrame
			else
				anchor = unitFrame.healthBar
			end
			unitFrame.ArrowLeft:SetPoint("RIGHT", anchor, "LEFT",  1 - PlateColorDB.arrowHoffset, -1)
			unitFrame.ArrowLeft:SetSize(scale, scale)
			unitFrame.ArrowLeft:SetShown((PlateColorDB.arrowPoint == 1 or PlateColorDB.arrowPoint == 3) and isTarget)
			if unitFrame.ArrowRight:IsShown() then
				unitFrame.ArrowLeft:SetSize(scale, scale)
			else
				unitFrame.ArrowLeft:SetSize(1, scale)
			end
		else
			unitFrame.ArrowLeft:SetSize(scale * 0.8, scale * 0.8)
			unitFrame.ArrowLeft:SetPoint("RIGHT", unitFrame.name, "LEFT", 3, 0)
			unitFrame.ArrowLeft:SetShown((PlateColorDB.arrowPoint == 1 or PlateColorDB.arrowPoint == 3) and isTarget and nameShown)
		end
	end
	if unitFrame.ArrowRight then
		unitFrame.ArrowRight:SetVertexColor(r, g, b, 1)
		if hpBarShown then
			unitFrame.ArrowRight:SetSize(scale, scale)
			unitFrame.ArrowRight:SetPoint("LEFT", unitFrame.healthBar, "RIGHT", -2 + PlateColorDB.arrowHoffset, -1)
			unitFrame.ArrowRight:SetShown((PlateColorDB.arrowPoint == 2 or PlateColorDB.arrowPoint == 3) and isTarget)
		else
			unitFrame.ArrowRight:SetSize(scale * 0.8, scale * 0.8)
			unitFrame.ArrowRight:SetPoint("LEFT", unitFrame.name, "RIGHT", -3, 0)
			unitFrame.ArrowRight:SetShown((PlateColorDB.arrowPoint == 2 or PlateColorDB.arrowPoint == 3) and isTarget and nameShown)
		end
	end
end

function ns.UpdateFocusTexture(unitFrame)
	if not unitFrame or not unitFrame.unit then return end
	if unitFrame.FocusTexture then
		unitFrame.FocusTexture:SetShown(PlateColorDB.focusTexture and UnitIsUnit("focus",unitFrame.unit))
	end
end

function ns.UpdateMouseoverTexture(unitFrame)
	if not unitFrame or not unitFrame.unit then return end
	if unitFrame.healthBar.selectedBorder and 1==0 then
		if PlateColorDB.mGlow and UnitIsUnit("mouseover",unitFrame.unit) then
			unitFrame.healthBar.selectedBorder:SetVertexColor(0, 1, 1, 1)
			unitFrame.healthBar.selectedBorder:Show()
		elseif UnitIsUnit("target",unitFrame.unit) then
			unitFrame.healthBar.selectedBorder:SetVertexColor(1, 1, 1, 1)
			unitFrame.healthBar.selectedBorder:Show()
		elseif UnitIsUnit("focus",unitFrame.unit) then
			unitFrame.healthBar.selectedBorder:SetVertexColor(1, 0.5, 0, 1)
			unitFrame.healthBar.selectedBorder:Show()
		else
			unitFrame.healthBar.selectedBorder:Hide()
		end
	end
	if unitFrame.MouseoverTexture then
		unitFrame.MouseoverTexture:SetShown(PlateColorDB.mGlow and UnitIsUnit("mouseover",unitFrame.unit))
		unitFrame.MouseoverTexture:SetVertexColor(PlateColorDB.mGlowColor["r"], PlateColorDB.mGlowColor["g"], PlateColorDB.mGlowColor["b"], 1)
	end

	if not UnitIsUnit("target",unitFrame.unit) and unitFrame.healthBar and not unitFrame.healthBar:IsShown()  and unitFrame.name and unitFrame.name:IsShown() then
		local r, g, b, a = PlateColorDB.arrowColor["r"], PlateColorDB.arrowColor["g"], PlateColorDB.arrowColor["b"], 0.4
		local size = PlateColorDB.arrowScale * 0.6
		local isMouseover = (PlateColorDB.arrowPoint == 2 or PlateColorDB.arrowPoint == 3) and UnitIsUnit("mouseover",unitFrame.unit)
		if unitFrame.ArrowLeft then
			unitFrame.ArrowLeft:SetVertexColor(r, g, b, a)
			unitFrame.ArrowLeft:SetShown(isMouseover)
			unitFrame.ArrowLeft:SetSize(size, size)
			unitFrame.ArrowLeft:SetPoint("RIGHT", unitFrame.name, "LEFT", 3, 0)
		end
		if unitFrame.ArrowRight then
			unitFrame.ArrowRight:SetVertexColor(r, g, b, a)
			unitFrame.ArrowRight:SetShown(isMouseover)
			unitFrame.ArrowRight:SetSize(size, size)
			unitFrame.ArrowRight:SetPoint("LEFT", unitFrame.name, "RIGHT", -3, 0)
		end
	end
end

ns.event("NAME_PLATE_UNIT_ADDED", function(event, unit)
	local namePlate = C_NamePlate.GetNamePlateForUnit(unit,false)
	local unitFrame = namePlate.UnitFrame
	ns.UpdateHpTexture(unitFrame)
	ns.UpdateMouseoverTexture(namePlate.UnitFrame)
	ns.UpdateFocusTexture(namePlate.UnitFrame)
end)

--ns.event("PLAYER_TARGET_CHANGED", function(event)
--	C_Timer.After(0,function()
--		for i, namePlate in ipairs(C_NamePlate.GetNamePlates()) do
--			ns.UpdateTargetTexture(namePlate.UnitFrame)
--		end
--	end)
--end)

ns.event("PLAYER_FOCUS_CHANGED", function(event)
	for i, namePlate in ipairs(C_NamePlate.GetNamePlates()) do
		ns.UpdateFocusTexture(namePlate.UnitFrame)
	end
end)

--ns.event("RAID_TARGET_UPDATE", function(event)
--	C_Timer.After(0,function()
--		for i, namePlate in ipairs(C_NamePlate.GetNamePlates()) do
--			ns.UpdateTargetTexture(namePlate.UnitFrame)
--		end
--	end)
--end)
hooksecurefunc("CompactUnitFrame_UpdateName", function(unitFrame)
	if unitFrame:IsForbidden() then return end
	if not string.match(unitFrame.unit,"nameplate") then return end
	ns.UpdateTargetTexture(unitFrame)
end)

hooksecurefunc(GameTooltip,"SetWorldCursor", function(frame)
	if frame:IsForbidden() then return end
	C_Timer.After(0,function()
		for i, namePlate in ipairs(C_NamePlate.GetNamePlates()) do
			ns.UpdateMouseoverTexture(namePlate.UnitFrame)
		end
	end)
end)