local _, ns = ...

--是BOSS或者精英-
local trueColor = CreateColor(0,0,0,0)
local falseColor = CreateColor(0,0,0,0)
local colortable = { r = 0, g = 0, b = 0 }
function ns.NpcLevelColor(unitFrame)
	if not unitFrame then return end
	if not UnitCanAttack("player",unitFrame.unit) then return end
	local inInstance, instanceType = IsInInstance()
	local playerlevel = UnitLevel("player")
	local npclevel = inInstance and instanceType == "party" and unitFrame.unit and UnitLevel(unitFrame.unit) or 0
	local npcBoss =  unitFrame.unit and UnitLevel(unitFrame.unit) == -1 or npclevel == playerlevel+2
	local PowerMANA = unitFrame.unit and UnitPowerType(unitFrame.unit) == 0
	if npclevel == playerlevel+1 and PlateColorDB.NpcLv1 then
		return PlateColorDB.NpcLv1Color
	elseif npcBoss and PlateColorDB.NpcLv2 then
		return PlateColorDB.NpcLv2Color
	elseif unitFrame.NpckickColor ~= nil and PlateColorDB.Npckick then
		trueColor:SetRGBA(PlateColorDB.NpcNokickColor["r"], PlateColorDB.NpcNokickColor["g"], PlateColorDB.NpcNokickColor["b"], 1)
		falseColor:SetRGBA(PlateColorDB.NpckickColor["r"], PlateColorDB.NpckickColor["g"], PlateColorDB.NpckickColor["b"], 1)
		local colorObj = C_CurveUtil.EvaluateColorFromBoolean(unitFrame.NpckickColor,trueColor,falseColor)
		colortable.r, colortable.g, colortable.b = colorObj:GetRGB()
		return colortable
	elseif PowerMANA and PlateColorDB.NpcSukick then
		return PlateColorDB.NpcSukickColor
	else
		return false
	end
end

--更新姓名版
function ns.UpdateSetColor(unitFrame)
	if not unitFrame or not unitFrame.unit then return end
	if PlateColorDB.UseNpc == 2 or PlateColorDB.UseNpc == 3 then
		ns.UpdateHpbarColor(unitFrame)
	end
	if PlateColorDB.UseNpc == 1 or PlateColorDB.UseNpc == 3 then
		ns.SetNameColor(unitFrame)
	end
end

--hook姓名版施法事件
local function NpcCastColor(self,event)
	if event == "PLAYER_ENTERING_WORLD" then return end
	--if not string.match(event,"STAR") then return end
	if self:IsForbidden() then return end
	if not self.unit then return end
	local npclevel = UnitLevel(self.unit) or 0
	local unitFrame = self:GetParent()
	local CastingInfo = select(8, UnitCastingInfo(self.unit))
	local ChanelInfo = select(7, UnitChannelInfo(self.unit))
	local uninterruptable = CastingInfo
	if uninterruptable == nil then
		uninterruptable = ChanelInfo
	end
	if (self.casting or self.channeling) then
		unitFrame.NpckickColor = uninterruptable
		ns.UpdateSetColor(unitFrame)
	end

end
hooksecurefunc(NamePlateCastingBarMixin,"OnEvent",NpcCastColor)

ns.event("NAME_PLATE_UNIT_ADDED", function(event, unit)
	local namePlate = C_NamePlate.GetNamePlateForUnit(unit,false)
	local unitFrame = namePlate.UnitFrame
	unitFrame.NpckickColor = nil
	--unitFrame.NpcNokickColor = nil
	NpcCastColor(unitFrame.castBar)
	ns.UpdateSetColor(unitFrame)
end)