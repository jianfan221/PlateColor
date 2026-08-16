local _, ns = ...

-- ================= 暴雪姓名板 CVar 备份/恢复 =================
-- 功能：备份并恢复以下暴雪姓名板 CVar 的取值。
--   - 每次上线：若 DB(PlateColorDB.BlizzCvar) 里已有存档 → 应用到游戏；
--                 若无存档 → 把当前所有取值存入 DB。
--   - 每个 CVar 都注册了变更回调：游戏中该 CVar 一旦变化，自动更新 DB，保持存档同步。
-- 说明：这些 CVar 取值统一用 C_CVar.GetCVar 读取原始字符串存储（普通 CVar 为 "1"/"0"/数字，
--       位域 CVar 为带版本字节的原始掩码字符串），恢复时用 C_CVar.SetCVar 原样写回即可。
local BlizzCvarList = {
	"nameplateShowSelf",                              --显示个人资源
	--名字（ESC→选项→姓名板→"名字"区）
    "UnitNameOwn",                                    --我的名字
	"UnitNameNPC",                                    --NPC名字（显示NPC名字下拉的总开关）
	"UnitNameFriendlySpecialNPCName",                 --NPC名字下拉：特殊NPC
	"UnitNameHostleNPC",                              --NPC名字下拉：敌对NPC
	"UnitNameInteractiveNPC",                         --NPC名字下拉：可互动NPC
	"UnitNameNonCombatCreatureName",                  --非战斗生物（小动物/宠物）
	"UnitNameFriendlyPlayerName",                     --友方玩家
	"UnitNameFriendlyMinionName",                     --友方随从
	"UnitNameEnemyPlayerName",                        --敌方玩家
	"UnitNameEnemyMinionName",                        --敌方随从
	--姓名板（"姓名板"区）
	"nameplateShowAll",                               --始终显示姓名板
	"nameplateShowEnemies",                           --敌方单位
	"nameplateShowEnemyMinions",                      --敌方随从
	"nameplateShowEnemyMinus",                        --敌方次级单位
	"nameplateShowFriendlyPlayers",                   --友方玩家
	"nameplateShowFriendlyPlayerMinions",             --友方玩家随从
	"nameplateShowOnlyNameForFriendlyPlayerUnits",    --友方玩家仅显示名字
	"nameplateUseClassColorForFriendlyPlayerUnitNames",--友方玩家名字职业颜色
	"nameplateShowFriendlyRealmName",                 --友方玩家显示服务器名
	"nameplateShowFriendlyNpcs",                      --友方NPC
	"nameplateShowOffscreen",                         --显示屏外姓名板
	"nameplateShowClassColor",                        --姓名板颜色用职业色：敌方
	"nameplateShowFriendlyClassColor",                --姓名板颜色用职业色：友方
	"nameplateStackingTypes",                         --堆叠类型（位域掩码）
	--尺寸（"尺寸"区）
	"nameplateSize",                                  --全局缩放
	"nameplateAuraScale",                             --光环缩放
	"nameplateStyle",                                 --姓名板样式
	"nameplateInfoDisplay",                           --信息显示（位域掩码）
	"nameplateCastBarDisplay",                        --施法条显示（位域掩码）
	"nameplateThreatDisplay",                         --仇恨显示（位域掩码）
	"nameplateEnemyNpcAuraDisplay",                   --敌方NPC光环显示（位域掩码）
	"nameplateEnemyPlayerAuraDisplay",                --敌方玩家光环显示（位域掩码）
	"nameplateFriendlyPlayerAuraDisplay",             --友方玩家光环显示（位域掩码）
	"nameplateDebuffPadding",                         --减益图标间距
	"nameplateSimplifiedTypes",                       --简化类型（位域掩码）

	--Tab2 选项可调的姓名板尺寸/透明度/间距 CVar
	"nameplateSelectedScale",                         --目标尺寸
	"nameplateOccludedAlphaMult",                     --隔墙透明度
	"nameplateOverlapV",                              --垂直堆叠间距
	"nameplateOverlapH",                              --水平堆叠间距
	"nameplateMaxDistance",                           --姓名版可见范围
}

-- 读取某个 CVar 的当前值（原始字符串）
local function GetBlizzCvarValue(cvar)
	return C_CVar.GetCVar(cvar)
end

-- 把 DB 里的存档应用到游戏
local function ApplyBlizzCvars()
	local saved = PlateColorDB.BlizzCvar
	if not saved then return end
	for _, cvar in ipairs(BlizzCvarList) do
		local val = saved[cvar]
		if val ~= nil then
			local current = GetBlizzCvarValue(cvar)
			if current ~= val then
				C_CVar.SetCVar(cvar, val)
			end
		end
	end
end

-- 把当前所有 CVar 取值存入 DB
local function SaveBlizzCvars()
	local saved = PlateColorDB.BlizzCvar
	if not saved then return end
	for _, cvar in ipairs(BlizzCvarList) do
		local val = GetBlizzCvarValue(cvar)
		if val ~= nil then
			saved[cvar] = val
		end
	end
end

-- 每个 CVar 注册变更回调：值变化时同步到 DB
for _, cvar in ipairs(BlizzCvarList) do
	ns.hookcvar(cvar, function()
		if not PlateColorDB.BlizzCvar then return end
		local val = GetBlizzCvarValue(cvar)
		if val ~= nil then
			PlateColorDB.BlizzCvar[cvar] = val
		end
	end)
end

-- 战斗中则等待脱战后执行（某些姓名板 CVar 在战斗锁定期间无法修改）
local function RunAfterCombat(func)
	if not InCombatLockdown() then
		func()
		return
	end
	ns.event("PLAYER_REGEN_ENABLED", function()
		func()
	end, true)
end

-- 进入游戏时：先恢复已有存档，再把缺失的 CVar 补存（若在战斗中则脱战后执行）
ns.event("PLAYER_ENTERING_WORLD", function()
	local saved = PlateColorDB.BlizzCvar
	if not saved then return end
	RunAfterCombat(function()
		ApplyBlizzCvars()  -- 先恢复已存储的 CVar
		SaveBlizzCvars()   -- 再补存缺失的 CVar（同时把已存在的刷新为当前值）
	end)
end)