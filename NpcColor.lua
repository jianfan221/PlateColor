local _, ns = ...

--特定NPC一定是可打断怪的判断
local function IsKickNpc(unitFrame)
	local mapid = C_Map.GetBestMapForUnit("player")
	if not ns.MM(mapid) and mapid == 2532 then--梦境裂隙BOSS区域,91小怪一定是可打断怪
		local npclevel = unitFrame.unit and UnitEffectiveLevel(unitFrame.unit) or 0
		return  npclevel == 91
	end
end

--是BOSS或者精英
local trueColor = CreateColor(0,0,0,0)
local falseColor = CreateColor(0,0,0,0)
local colortable = { r = 0, g = 0, b = 0 }
function ns.NpcLevelColor(unitFrame)
	if not unitFrame then return end
	if not unitFrame.unit then return end
	if not UnitCanAttack("player",unitFrame.unit) then return end
	local inInstance, instanceType = IsInInstance()
	local playerlevel = UnitEffectiveLevel("player")
	local npclevel = inInstance and instanceType == "party" and UnitEffectiveLevel(unitFrame.unit) or 0

	local IsLeader = UnitIsLieutenant(unitFrame.unit) or npclevel == playerlevel+1
	local IsBoss =  UnitEffectiveLevel(unitFrame.unit) == -1 or npclevel == playerlevel+2
	local class = UnitClassBase(unitFrame.unit)
	local power = UnitPowerType(unitFrame.unit)
	local IsPALADIN = not ns.MM(class) and class == "PALADIN" or ns.MM(class) and not ns.MM(power) and power == 0
	--local PowerMANA = UnitPowerType(unitFrame.unit) == 0

	if IsLeader and PlateColorDB.NpcLv1 then
		return PlateColorDB.NpcLv1Color
	elseif IsBoss and PlateColorDB.NpcLv2 then
		return PlateColorDB.NpcLv2Color
	elseif IsKickNpc(unitFrame) and PlateColorDB.Npckick then--特定NPC一定是可打断怪
		return PlateColorDB.NpckickColor
	elseif unitFrame.NpckickColor ~= nil and PlateColorDB.Npckick then
		trueColor:SetRGBA(PlateColorDB.NpcNokickColor["r"], PlateColorDB.NpcNokickColor["g"], PlateColorDB.NpcNokickColor["b"], 1)
		falseColor:SetRGBA(PlateColorDB.NpckickColor["r"], PlateColorDB.NpckickColor["g"], PlateColorDB.NpckickColor["b"], 1)
		local colorObj = C_CurveUtil.EvaluateColorFromBoolean(unitFrame.NpckickColor,trueColor,falseColor)
		colortable.r, colortable.g, colortable.b = colorObj:GetRGB()
		return colortable
	elseif IsPALADIN and PlateColorDB.NpcSukick then
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
	if not self then return end
	if event == "PLAYER_ENTERING_WORLD" then return end
	--if not string.match(event,"STAR") then return end
	if self:IsForbidden() then return end
	if not self.unit then return end
	-- PTR 12.1: castBar 移到了 CastBarsContainer 下, GetParent 多了一层
	local unitFrame = self:GetParent()
	if unitFrame and not unitFrame.unit then
		unitFrame = unitFrame:GetParent()
	end
	if not unitFrame or not unitFrame.unit then return end
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
ns.hook(NamePlateCastingBarMixin,"OnEvent",NpcCastColor)

ns.event("NAME_PLATE_UNIT_ADDED", function(event, unit)
	local namePlate = C_NamePlate.GetNamePlateForUnit(unit,false)
	local unitFrame = namePlate.UnitFrame
	unitFrame.NpckickColor = nil
	--unitFrame.NpcNokickColor = nil
	local castBar = ns.GetCastBar(unitFrame)
	if castBar then
		NpcCastColor(castBar)
	end
	ns.UpdateSetColor(unitFrame)
end)