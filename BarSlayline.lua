local _, ns = ...

--斩杀法术
ns.SlaylineSpell = {
	["450746"] = 30,--12.0火法灼焦天赋

	["53351"]  = 20,--猎人夺命射击
	["204089"] = 20,--猎人正中靶心
	["1277548"]= 20,--猎人火力倾泻
	["32379"]  = 20,--暗牧痛
	["392507"] = 35,--暗牧亡语者35%
	["343294"] = 35,--DK灵魂收割
	["163201"] = 20,--防战武器战斩杀
	["281000"] = 35,--武器战点35斩杀之后的斩杀
	["281001"] = 35,--防战点35斩杀之后的斩杀
	["5308"]   = 20,--狂暴战原始斩杀
	["206315"] = 35,--狂暴战毁灭35斩杀
	["423136"] = 35,--骤死贼斩杀
	["17877"]  = 20,--毁灭术暗影灼烧
	["456939"] = 30,--毁灭术酷热衰竭加强暗影灼烧
}

ns.LinePoint = 0	--定义斩杀数值
ns.SlaylineSpellID = 0	--定义斩杀技能ID
--判断斩杀线,写上数值
local function SetLinePoint()
	ns.LinePoint = 0	--定义斩杀数值,每次设置都初始化为0
	ns.SlaylineSpellID = 0	--定义斩杀技能ID,每次设置都初始化为0
	for spell,value in pairs(ns.SlaylineSpell) do
		if C_SpellBook.IsSpellKnown(spell) and value >= ns.LinePoint then
			ns.LinePoint = value
			ns.SlaylineSpellID = spell
		end
	end
end

--设置斩杀分割线
local height,width = 0,0
function ns.CreatSlayline(unitFrame)
	if not unitFrame then return end
	if not PlateColorDB.Slayline or not ns.SlaylineSpellID or not C_SpellBook.IsSpellKnown(ns.SlaylineSpellID) then 
		if unitFrame.Slayline then
			unitFrame.Slayline:Hide()
		end
		return
	end
	if not unitFrame.Slayline then
		if not ns.MM(unitFrame.healthBar:GetHeight()) then
			height = unitFrame.healthBar:GetHeight() * 0.94
		end
		if height == 0 then return end
		-- 斩杀线用独立 Frame 容器并抬高 frameLevel，避免被血条上的光环染色
		-- （AuraContainer 是 healthBar 的子框架，默认 frameLevel 更高，会盖住其子纹理）
		local slayFrame = CreateFrame("Frame", nil, unitFrame.healthBar)
		slayFrame:SetAllPoints(unitFrame.healthBar)
		slayFrame:SetFrameLevel((unitFrame.healthBar:GetFrameLevel() or 0) + 10)
		unitFrame.Slayline = slayFrame:CreateTexture(nil, "OVERLAY")
		unitFrame.Slayline:SetWidth(2)	
		unitFrame.Slayline:SetHeight(height)	
		unitFrame.Slayline:SetTexture("Interface\\Buttons\\WHITE8x8")
	end
	if unitFrame.Slayline then
		if not ns.MM(unitFrame.healthBar:GetWidth()) then
			width = unitFrame.healthBar:GetWidth()
		end
		if width == 0 then return end
		unitFrame.Slayline:SetVertexColor(PlateColorDB["SlaylineColor"]["r"],PlateColorDB["SlaylineColor"]["g"],PlateColorDB["SlaylineColor"]["b"],1);
		unitFrame.Slayline:SetPoint("LEFT",unitFrame.healthBar,"LEFT",ns.LinePoint*width/100, 0)
		unitFrame.Slayline:SetShown(ns.LinePoint ~= 0 and unitFrame.unit and UnitCanAttack("player",unitFrame.unit))
	end
end

local function UpdateSlayline()
	SetLinePoint()
	for i, namePlate in ipairs(C_NamePlate.GetNamePlates()) do
		ns.CreatSlayline(namePlate.UnitFrame)
	end
end

ns.event("NAME_PLATE_UNIT_ADDED", function(event, unit)
	local namePlate = C_NamePlate.GetNamePlateForUnit(unit,false)
	if not namePlate then return end
	ns.CreatSlayline(namePlate.UnitFrame)
end)

ns.event("PLAYER_ENTERING_WORLD", UpdateSlayline)
ns.event("TRAIT_CONFIG_UPDATED", UpdateSlayline)

