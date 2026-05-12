local _, ns = ...
--名字颜色

function ns.SetNameColor(unitFrame)
    local unit = unitFrame.unit
    if not unit or not unitFrame.name then return end
    if UnitIsPlayer(unit) then return end -- 保持逻辑：跳过玩家

    local DB = PlateColorDB
    local name = unitFrame.name

    -- 1. 优先判定：灰色（死亡或无权拾取）
    if CompactUnitFrame_IsTapDenied(unitFrame) or (UnitIsDead(unit) and not UnitIsPlayer(unit)) then
        name:SetVertexColor(0.5, 0.5, 0.5)
        return
    end

    -- 2. 获取仇恨与角色状态
    local Threat = UnitThreatSituation("player", unit) or 0
    local role = UnitGroupRolesAssigned("player")
    local InCombat = not ns.MM(UnitAffectingCombat(unit)) and UnitAffectingCombat(unit)

    -- 坦克仇恨逻辑优化 (DB.TankthreatUse 1或3)
    if role == "TANK" and (DB.TankthreatUse == 1 or DB.TankthreatUse == 3) then
        if Threat == 0 and InCombat then
            local c = DB.TANKnoThreatColor
            name:SetVertexColor(c.r, c.g, c.b); return
        elseif Threat == 1 then
            local c = DB.TANKhighThreatColor
            name:SetVertexColor(c.r, c.g, c.b); return
        elseif Threat == 2 then
            local c = DB.TANKlowThreatColor
            name:SetVertexColor(c.r, c.g, c.b); return
        end
    -- 非坦克仇恨逻辑优化 (DB.threatUse 1或3)
    elseif role ~= "TANK" and (DB.threatUse == 1 or DB.threatUse == 3) then
        if Threat == 1 then
            local c = DB.highThreatColor
            name:SetVertexColor(c.r, c.g, c.b); return
        elseif Threat == 2 then
            local c = DB.lowThreatColor
            name:SetVertexColor(c.r, c.g, c.b); return
        elseif Threat == 3 then
            local c = DB.myThreatColor
            name:SetVertexColor(c.r, c.g, c.b); return
        end
    end

    -- 3. NPC 染色逻辑 (将重复调用的函数结果存入局部变量以提升性能)
    if (DB.UseNpc == 1 or DB.UseNpc == 3) then
        local npcColor = ns.NpcLevelColor(unitFrame)
        if npcColor then
            name:SetVertexColor(npcColor.r, npcColor.g, npcColor.b)
            return
        end
    end

    -- 4. 基础阵营/关系逻辑
    local reaction = UnitReaction(unit, "player") or 0
    
    if not UnitCanAttack("player", unit) and UnitIsOtherPlayersPet(unit) then
        name:SetVertexColor(0, 1, 1) -- 玩家宠物
    elseif reaction >= 5 then
        name:SetVertexColor(0, 1, 0) -- 友方
    elseif DB.whiteName then
        name:SetVertexColor(1.0, 1.0, 1.0) -- 配置：强制白色名字
    elseif CompactUnitFrame_IsOnThreatListWithPlayer(unitFrame.displayedUnit) then
        name:SetVertexColor(1.0, 0.0, 0.0) -- 战斗中敌对
    elseif reaction == 4 then
        name:SetVertexColor(1, 1, 0) -- 中立
    else
        name:SetVertexColor(1.0, 0.0, 0.0) -- 默认红
    end
end

ns.hook("CompactUnitFrame_UpdateName", function(unitFrame)
	if unitFrame:IsForbidden() then return end
	if not string.match(unitFrame.unit,"nameplate") then return end
	ns.SetNameColor(unitFrame)
end)