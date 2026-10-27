local _, ns = ...

-- ================= 暴雪姓名板 CVar 备份/恢复 =================
-- 功能：备份并恢复以下暴雪姓名板 CVar 的取值。
--   - 每次上线：用 DB(PlateColorDB.BlizzCvar) 的存档覆盖游戏；
--                 存档里还没有的 CVar → 把当前取值补录进 DB。
--   - 监听 CVAR_UPDATE：游戏中该 CVar 一旦变化，自动更新 DB，保持存档同步。
-- 说明：这些 CVar 取值统一用 C_CVar.GetCVar 读取原始字符串存储（普通 CVar 为 "1"/"0"/数字，
--       位域 CVar 为带版本字节的原始掩码字符串），恢复时用 C_CVar.SetCVar 原样写回即可。
local BlizzCvarList = {
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
	--光环（姓名板光环相关）
	"tooltipShowAuraSpellIDs",                        --光环鼠标提示显示法术ID

	--Tab2 选项可调的姓名板尺寸/透明度/间距 CVar
	"nameplateSelectedScale",                         --目标尺寸
	"nameplateOccludedAlphaMult",                     --隔墙透明度
	"nameplateOverlapV",                              --垂直堆叠间距
	"nameplateOverlapH",                              --水平堆叠间距
	"nameplateMaxDistance",                           --姓名版可见范围
	"nameplateMotionSpeed",                           --姓名板运动速度
	"nameplateTopInset",                              --姓名板顶部内边距
	"nameplateBottomInset",                           --姓名板底部内边距
}

-- CVar 快速查找表（供 CVAR_UPDATE 直接比对，避免为每个 CVar 单独注册回调）
local BlizzCvarMap = {}
for _, cvar in ipairs(BlizzCvarList) do
	BlizzCvarMap[cvar] = true
end

-- 把 DB 存档应用到游戏；存档里缺的 CVar 顺手补录当前值（须脱战调用）。返回 true = 全部成功
local function ApplyBlizzCvars()
	local saved = PlateColorDB.BlizzCvar
	if not saved then return true end
	if InCombatLockdown() then return false end
	local failed = false
	for _, cvar in ipairs(BlizzCvarList) do
		local current = C_CVar.GetCVar(cvar)
		if current == nil then
			-- 当前 CVar 已被移除：清除存档残留
			saved[cvar] = nil
		elseif saved[cvar] == nil then
			-- 首次运行 / 清单新增的 CVar：把当前值补录进存档
			saved[cvar] = current
		elseif current ~= saved[cvar] then
			-- SetCVar 返回 success，受限时给 false；pcall 防 taint 抛错
			local ok, success = pcall(C_CVar.SetCVar, cvar, saved[cvar])
			if not ok or not success then failed = true end
		end
	end
	return not failed
end

-- 单个 CVAR_UPDATE 事件监听：值变化时同步到 DB（用 map 判断是否在本清单中）
ns.event("CVAR_UPDATE", function(_, cvarName, value)
	if not PlateColorDB.BlizzCvar or not BlizzCvarMap[cvarName] then return end
	if value ~= nil then
		PlateColorDB.BlizzCvar[cvarName] = value
	end
end)

-- 脱战安全入口：战斗中或受限时挂起，限制解除后自动重试，成功才注销
local retryHandle  -- 非 nil 即已挂起
local function ApplyBlizzCvarsSafely()
	if ApplyBlizzCvars() then return end
	if retryHandle then return end
	retryHandle = EventRegistry:RegisterFrameEventAndCallbackWithHandle("ADDON_RESTRICTION_STATE_CHANGED", function(_, _, state)
		if state ~= Enum.AddOnRestrictionState.Inactive then return end
		if ApplyBlizzCvars() then
			retryHandle:Unregister()
			retryHandle = nil
		end
	end)
end

-- 进入游戏时：恢复存档（存档里没有的 CVar 会顺手补录）
ns.event("PLAYER_ENTERING_WORLD", function()
	ApplyBlizzCvarsSafely()
end)