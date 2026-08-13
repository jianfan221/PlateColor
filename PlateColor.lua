local _, ns = ...

-- ================= 暴雪姓名板 CVar 备份/恢复 =================
-- 功能：备份并恢复以下暴雪姓名板 CVar 的取值。
--   - 每次上线：若 DB(PlateColorDB.BlizzCvar) 里已有存档 → 应用到游戏；
--                 若无存档 → 把当前所有取值存入 DB。
--   - 每个 CVar 都注册了变更回调：游戏中该 CVar 一旦变化，自动更新 DB，保持存档同步。
-- 说明：这些 CVar 取值统一用 C_CVar.GetCVar 读取原始字符串存储（普通 CVar 为 "1"/"0"/数字，
--       位域 CVar 为带版本字节的原始掩码字符串），恢复时用 C_CVar.SetCVar 原样写回即可。
local BlizzCvarList = {
	--名字
    "UnitNameOwn",
	"UnitNameNPC",
	"UnitNameNonCombatCreatureName",
	"UnitNameFriendlyPlayerName",
	"UnitNameFriendlyMinionName",
	"UnitNameEnemyPlayerName",
	"UnitNameEnemyMinionName",
	--姓名板
	"nameplateShowAll",
	"nameplateShowEnemies",
	"nameplateShowEnemyMinions",
	"nameplateShowEnemyMinus",
	"nameplateShowFriendlyPlayers",
	"nameplateShowFriendlyPlayerMinions",
	"nameplateShowOnlyNameForFriendlyPlayerUnits",
	"nameplateUseClassColorForFriendlyPlayerUnitNames",
	"nameplateShowFriendlyRealmName",
	"nameplateShowFriendlyNpcs",
	"nameplateShowOffscreen",
	"nameplateStackingTypes",
	--尺寸
	"nameplateSize",
	"nameplateAuraScale",
	"nameplateStyle",
	"nameplateInfoDisplay",
	"nameplateCastBarDisplay",
	"nameplateThreatDisplay",
	"nameplateEnemyNpcAuraDisplay",
	"nameplateEnemyPlayerAuraDisplay",
	"nameplateFriendlyPlayerAuraDisplay",
	"nameplateDebuffPadding",
	"nameplateSimplifiedTypes",
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
			C_CVar.SetCVar(cvar, val)
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