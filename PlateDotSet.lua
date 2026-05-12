local _, ns = ...

local casttimer

ns.event("UNIT_SPELLCAST_SUCCEEDED", function(_, unit, castGUID, spellId)
    if unit ~= "player" then
        return
    end
    if PlateColorDB.dotlist and PlateColorDB.dotlist[spellId] then
        casttimer = GetTime()
    end
end)

ns.event("NAME_PLATE_UNIT_ADDED", function(event, unit)
	local namePlate = C_NamePlate.GetNamePlateForUnit(unit,false)
	if not namePlate then return end
	namePlate.UnitFrame.mydot = nil
    namePlate.UnitFrame.mydotcount = 0
end)


local function AddAura(self, aura)
    if self:IsForbidden() then return end
    local auraInstanceID = type(aura) == "table" and aura.auraInstanceID or aura
    if not auraInstanceID then return end
    if not casttimer then return end
    local mydot = self.debuffList[auraInstanceID] and true or nil
    if not mydot then return end
    if GetTime() >= casttimer and GetTime() < casttimer + 0.1 then
        if not self:GetParent().mydot then
            self:GetParent().mydot = {}
            self:GetParent().mydotcount = 0
        end
        if not self:GetParent().mydot[auraInstanceID] then
            self:GetParent().mydot[auraInstanceID] = true
            self:GetParent().mydotcount = self:GetParent().mydotcount + 1
            ns.UpdateHpbarColor(self:GetParent())
        end
    end
end
ns.hook(NamePlateAurasMixin, "AddAura", AddAura)
ns.hook(NamePlateAurasMixin, "UpdateAura", AddAura)

ns.hook(NamePlateAurasMixin, "RemoveAura", function(self, auraInstanceID)
    if self:IsForbidden() then return end
    if not auraInstanceID then return end
    if self:GetParent().mydot and self:GetParent().mydot[auraInstanceID] then
        self:GetParent().mydot[auraInstanceID] = nil
        self:GetParent().mydotcount = self:GetParent().mydotcount - 1
        ns.UpdateHpbarColor(self:GetParent())
    end
end)