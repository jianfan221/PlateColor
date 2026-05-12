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
	local IsPALADIN = UnitClassBase(unitFrame.unit) == "PALADIN"
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
	if event == "PLAYER_ENTERING_WORLD" then return end
	--if not string.match(event,"STAR") then return end
	if self:IsForbidden() then return end
	if not self.unit then return end
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
ns.hook(NamePlateCastingBarMixin,"OnEvent",NpcCastColor)

ns.event("NAME_PLATE_UNIT_ADDED", function(event, unit)
	local namePlate = C_NamePlate.GetNamePlateForUnit(unit,false)
	local unitFrame = namePlate.UnitFrame
	unitFrame.NpckickColor = nil
	--unitFrame.NpcNokickColor = nil
	NpcCastColor(unitFrame.castBar)
	ns.UpdateSetColor(unitFrame)
end)

--[[
--记录可打断怪的特征
ns.event("UNIT_SPELLCAST_INTERRUPTED", function(event, unitTarget, castGUID, spellID, interruptedBy, castBarID)
	if unitTarget and unitTarget ~= "player" and interruptedBy and castBarID then
		local mapid = C_Map.GetBestMapForUnit("player")
		local class = UnitClassBase(unitTarget)
		local _,ctype = UnitCreatureType(unitTarget)
		local level = UnitEffectiveLevel(unitTarget)
		local sex = UnitSex(unitTarget)
		local npcID = mapid..class..ctype..level..sex
		PlateColorDB.NpcKickData[npcID] = true
	end
end)
]]