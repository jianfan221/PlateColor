local _, ns = ...

--等级文本
function ns.CteatLevelText(unitFrame)
	if not PlateColorDB.levelText then return end
	if not unitFrame then return end
	if not unitFrame.LevelText then
		unitFrame.LevelText = unitFrame.healthBar:CreateFontString(nil, "ARTWORK")
		unitFrame.LevelText:SetFont(ns.fonts, 16, "OUTLINE")
	end
	if not unitFrame.unit then return end
	local NpLevel = UnitLevel(unitFrame.unit)
	local PlayerLevel = UnitLevel("player")
	local LevelText = (NpLevel > 0 and (NpLevel < PlayerLevel or NpLevel > PlayerLevel + 2)) and NpLevel or ""
	local difficulty = C_PlayerInfo.GetContentDifficultyCreatureForPlayer(unitFrame.unit)
	local color = GetDifficultyColor(difficulty);

	unitFrame.LevelText:ClearAllPoints()
    -- 寻找最左侧的参考物
    local anchor = unitFrame.healthBar
    if unitFrame.RaidTargetFrame and unitFrame.RaidTargetFrame:IsShown() then
        anchor = unitFrame.RaidTargetFrame
    elseif unitFrame.ClassificationFrame and unitFrame.ClassificationFrame:IsShown() then
        anchor = unitFrame.ClassificationFrame
    end
	unitFrame.LevelText:SetPoint("RIGHT",anchor,"LEFT",- 3,0)
	unitFrame.LevelText:SetVertexColor(color.r, color.g, color.b);
	unitFrame.LevelText:SetText(LevelText)
end

hooksecurefunc("CompactUnitFrame_UpdateName", function(unitFrame)
	if unitFrame:IsForbidden() or not unitFrame.unit or not string.match(unitFrame.unit,"nameplate") then 
        return 
    end
	ns.CteatLevelText(unitFrame)
end)