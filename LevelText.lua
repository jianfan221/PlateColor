local _, ns = ...

--等级文本
function ns.CteatLevelText(unitFrame)
	if not PlateColorDB.levelText then return end
	if not unitFrame then return end
	if not unitFrame.LevelText then
		unitFrame.LevelText = unitFrame.healthBar:CreateFontString(nil, "ARTWORK")
		unitFrame.LevelText:SetFontObject("PC_FontOutline")
		unitFrame.LevelText:SetFontHeight(16)
		unitFrame.LevelText:SetSmoothScaling(false)
	end
	if not unitFrame.unit then return end
	local NpLevel = UnitLevel(unitFrame.unit)
	local PlayerLevel = UnitLevel("player")
	local unitLevelText = (NpLevel > 0 and (NpLevel < PlayerLevel or NpLevel > PlayerLevel + 2)) and NpLevel or ""
	unitFrame.LevelText:SetText(unitLevelText)

	if C_PlayerInfo and C_PlayerInfo.GetContentDifficultyCreatureForPlayer then
		local difficulty = C_PlayerInfo.GetContentDifficultyCreatureForPlayer(unitFrame.unit)
		local color = GetDifficultyColor(difficulty) or {r=1, g=1, b=1}
		unitFrame.LevelText:SetVertexColor(color.r, color.g, color.b);
	else
		local color = GetQuestDifficultyColor(NpLevel) or {r=1, g=1, b=1}
		unitFrame.LevelText:SetVertexColor(color.r, color.g, color.b);
	end

	-- 寻找最左侧的参考物
	unitFrame.LevelText:ClearAllPoints()
    local anchor = unitFrame.healthBar
	if unitFrame.ClassificationFrame and unitFrame.ClassificationFrame:IsShown() then
        anchor = unitFrame.ClassificationFrame
    end
	unitFrame.LevelText:SetPoint("RIGHT",anchor,"LEFT",- 3,0)

end

ns.hook("CompactUnitFrame_UpdateName", function(unitFrame)
	if unitFrame:IsForbidden() or not unitFrame.unit or not string.match(unitFrame.unit,"nameplate") then 
        return 
    end
	ns.CteatLevelText(unitFrame)
end)

ns.event("NAME_PLATE_UNIT_ADDED", function(event, unit)
	local namePlate = C_NamePlate.GetNamePlateForUnit(unit,false)
	local unitFrame = namePlate.UnitFrame
	ns.CteatLevelText(unitFrame)
end)