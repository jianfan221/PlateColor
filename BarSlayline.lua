local _, ns = ...
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
		unitFrame.Slayline = unitFrame.healthBar:CreateTexture(nil, "OVERLAY")
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

