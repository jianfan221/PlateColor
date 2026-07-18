local addonName,ns = ...
-- 自己创建 FontFamily，不依赖任何系统字体
local members = {
	{ alphabet = "roman",               file = "Fonts\\FRIZQT__.TTF",     height = 14, flags = "" },
	{ alphabet = "korean",              file = "Fonts\\2002.TTF",         height = 14, flags = "" },
	{ alphabet = "simplifiedchinese",   file = "Fonts\\ARKai_T.ttf",     height = 14, flags = "" },
	{ alphabet = "traditionalchinese",  file = "Fonts\\blei00d.TTF",     height = 14, flags = "" },
	{ alphabet = "russian",             file = "Fonts\\FRIZQT___CYR.TTF", height = 14, flags = "" },
}
CreateFontFamily("PC_Font", members)

-- 带描边的版本
local membersOutline = {
	{ alphabet = "roman",               file = "Fonts\\FRIZQT__.TTF",     height = 14, flags = "OUTLINE" },
	{ alphabet = "korean",              file = "Fonts\\2002.TTF",         height = 14, flags = "OUTLINE" },
	{ alphabet = "simplifiedchinese",   file = "Fonts\\ARKai_T.ttf",     height = 14, flags = "OUTLINE" },
	{ alphabet = "traditionalchinese",  file = "Fonts\\blei00d.TTF",     height = 14, flags = "OUTLINE" },
	{ alphabet = "russian",             file = "Fonts\\FRIZQT___CYR.TTF", height = 14, flags = "OUTLINE" },
}
CreateFontFamily("PC_FontOutline", membersOutline)

--检查本地化
ns.L = ns.L or {}
for key,value in pairs(ns.DefaultL) do
	if not ns.L[key] then
		if ns.enUS and ns.enUS[key] then--如果有英语优先使用英语
			ns.L[key] = ns.enUS[key]
		else
			ns.L[key] = ns.DefaultL[key]
		end
	end
end

--事件加载
local onceEvents = {
    ["PLAYER_ENTERING_WORLD"] = true,
    ["PLAYER_LOGIN"] = true,
}
function ns.event(event, handler, isOnce)--ns.event(event, handler, true)只执行一次的事件
    EventRegistry:RegisterFrameEventAndCallback(event, function(self, ...)
        if (isOnce or onceEvents[event]) and self then
            EventRegistry:UnregisterFrameEventAndCallback(event, self)
        end
        handler(event, ...)
    end)
end

ns.hook = hooksecurefunc

-- 设置位域 CVar 的单个位（读当前掩码→改指定位→写回）用于下拉菜单的多选cvar
function ns.SetCVar(cvar, enumValue, enabled)
	local mask = 0
	for i = 1, 8 do
		if CVarCallbackRegistry:GetCVarBitfieldIndex(cvar, i) then
			mask = bit.bor(mask, bit.lshift(1, i - 1))
		end
	end
	if enabled then
		mask = bit.bor(mask, bit.lshift(1, enumValue - 1))
	else
		mask = bit.band(mask, bit.bnot(bit.lshift(1, enumValue - 1)))
	end
	CVarCallbackRegistry:SetCVarBitfieldMask(cvar, mask)
end

-- 读取位域 CVar 的单个位，返回 true/false
function ns.GetCVar(cvar, enumValue)
	local mask = 0
	for i = 1, 8 do
		if CVarCallbackRegistry:GetCVarBitfieldIndex(cvar, i) then
			mask = bit.bor(mask, bit.lshift(1, i - 1))
		end
	end
	return bit.band(mask, bit.lshift(1, enumValue - 1)) ~= 0
end

--判断是否是秘密值
function ns.MM(value)
	if not issecretvalue or not issecrettable then
		return false
	elseif issecretvalue(value) or issecrettable(value) then
		return true
	else
		return false
	end
end

--驱散颜色
ns.dispelColor = C_CurveUtil.CreateColorCurve()
ns.dispelColor:SetType(Enum.LuaCurveType.Step)
ns.dispelColor:AddPoint(0, CreateColor(0,  0,  0,  0))--无
ns.dispelColor:AddPoint(1, CreateColor(1,  1,  1,  1))--魔法
ns.dispelColor:AddPoint(2, CreateColor(0.5,0,  1,  1))--诅咒
ns.dispelColor:AddPoint(3, CreateColor(1,0.5,  0,  1))--疾病
ns.dispelColor:AddPoint(4, CreateColor(0,  1,  0,  1))--中毒
ns.dispelColor:AddPoint(9, CreateColor(1,  0,  0,  1))--激怒

--数值简化
local NumberData = {
	[1] = {
		config = CreateAbbreviateConfig({
			{
				breakpoint = 1e10,--123亿
				abbreviation = "亿",
				significandDivisor = 1e8,
				fractionDivisor = 1,
				abbreviationIsGlobal = false
			},
			{
				breakpoint = 1e9,--12.3亿
				abbreviation = "亿",
				significandDivisor = 1e7,
				fractionDivisor = 10,
				abbreviationIsGlobal = false
			},
			{
				breakpoint = 1e8,--1.23亿
				abbreviation = "亿",
				significandDivisor = 1e6,
				fractionDivisor = 100,
				abbreviationIsGlobal = false
			},
			{
				breakpoint = 1e5,--1234万
				abbreviation = "万",
				significandDivisor = 1e4,
				fractionDivisor = 1,
				abbreviationIsGlobal = false
			},
			{
				breakpoint = 1e4,--1.2万
				abbreviation = "万",
				significandDivisor = 1e3,
				fractionDivisor = 10,
				abbreviationIsGlobal = false
			},
			{
				breakpoint = 1,
				abbreviation = "",
				significandDivisor = 1,
				fractionDivisor = 1,
				abbreviationIsGlobal = false
			},
		})
	},
	[2] = {
		config = CreateAbbreviateConfig({
			{
				breakpoint = 1e10,--12B
				abbreviation = "B",
				significandDivisor = 1e9,
				fractionDivisor = 1,
				abbreviationIsGlobal = false
			},
			{
				breakpoint = 1e9,--1.2B
				abbreviation = "B",
				significandDivisor = 1e8,
				fractionDivisor = 10,
				abbreviationIsGlobal = false
			},
			{
				breakpoint = 1e7,--12M
				abbreviation = "M",
				significandDivisor = 1e6,
				fractionDivisor = 1,
				abbreviationIsGlobal = false
			},
			{
				breakpoint = 1e6,--1.2M
				abbreviation = "M",
				significandDivisor = 1e5,
				fractionDivisor = 10,
				abbreviationIsGlobal = false
			},
			{
				breakpoint = 1e4,--12K
				abbreviation = "K",
				significandDivisor = 1e3,
				fractionDivisor = 1,
				abbreviationIsGlobal = false
			},
			{
				breakpoint = 1e3,--1.2K
				abbreviation = "K",
				significandDivisor = 1e2,
				fractionDivisor = 10,
				abbreviationIsGlobal = false
			},
			{
				breakpoint = 1,
				abbreviation = "",
				significandDivisor = 1,
				fractionDivisor = 1,
				abbreviationIsGlobal = false
			},
		})
	},
}
function ns.value(numbers)
	if PlateColorDB and NumberData[PlateColorDB.Abbconfig] and NumberData[PlateColorDB.Abbconfig] ~= 3 then
		return AbbreviateNumbers(numbers,NumberData[PlateColorDB.Abbconfig])
	else
		return AbbreviateNumbers(numbers)
	end
end
local PercentData = {
	config = CreateAbbreviateConfig({
		{
			breakpoint = 100,--100%
			abbreviation = "%",
			significandDivisor = 1,
			fractionDivisor = 1,
			abbreviationIsGlobal = false
		},
		{
			breakpoint = 1,--1.2%
			abbreviation = "%",
			significandDivisor = 0.1,
			fractionDivisor = 10,
			abbreviationIsGlobal = false
		},
		{
			breakpoint = 0.0000000000000000000001,--0.12%
			abbreviation = "%",
			significandDivisor = 0.01,
			fractionDivisor = 100,
			abbreviationIsGlobal = false
		},
	})
}
--百分比简化
function ns.percent(number)
	return AbbreviateNumbers(number,PercentData)
end

--脱战后执行
local postCombatQueue = {}
function ns.COMBAT(func, ...)--调用这个
	if InCombatLockdown() then
        local args = {...}
        print("正在战斗中,脱战后执行")
        table.insert(postCombatQueue, function()
            func(unpack(args))
        end)
    else
        func(...)
    end
end

ns.event("PLAYER_REGEN_ENABLED", function()
    for _, func in ipairs(postCombatQueue) do
        local success, err = pcall(func)
        if not success then
            print("执行错误:", err)
        end
    end
    wipe(postCombatQueue)
end)


--计算字节数量
local function SubStringGetByteCount(str)
    local curByte = string.byte(str)
    local byteCount = 1;
    if curByte == nil then
        byteCount = 0
    elseif curByte > 0 and curByte <= 127 then
        byteCount = 1
    elseif curByte>=192 and curByte<=223 then
        byteCount = 2
    elseif curByte>=224 and curByte<=239 then
        byteCount = 3
    elseif curByte>=240 and curByte<=247 then
        byteCount = 4
    end
    return byteCount;
end

function ns.RCTexts(text)
    local colors = {
		"|cffff5900", -- 1
		"|cffffb300", -- 2
		"|cfff0ff00", -- 3
		"|cff96ff00", -- 4
		"|cff3cff00", -- 5
		"|cff00ffd2", -- 6
		"|cff00d1ff", -- 7
		"|cff00B3FF", -- 8
		"|cffD56AFF", -- 9
		"|cffFF6BED", -- 0
		"|cffFF2AA5", -- A
		"|cffFF546A", -- B
		"|cffff5900", -- 1
		"|cffffb300", -- 2
		"|cfff0ff00", -- 3
		"|cff96ff00", -- 4
		"|cff3cff00", -- 5
		"|cff00ffd2", -- 6
		"|cff00d1ff", -- 7
		"|cff00B3FF", -- 8
		"|cffD56AFF", -- 9
		"|cffFF6BED", -- 0
		"|cffFF2AA5", -- A
		"|cffFF546A", -- B
	}
    local result = ""
    local colorIndex = math.random(1, 24)
    local i = 1
    while i <= #text do
        local chars = string.sub(text, i, i)
        local byteCount = SubStringGetByteCount(chars)
        local truncatedChars = string.sub(text, i, i + byteCount - 1)
        result = result .. colors[colorIndex] .. truncatedChars .. "|r"
        i = i + byteCount
        colorIndex = colorIndex % #colors + 1
    end
    return result
end


local guid = {
    ["Player-980-07B86048"] = true,--tf
	["简繁丶-无尽之海"] = true,
	["简子凡-遗忘海岸"] = true,
	["简小繁-无尽之海"] = true,
	["简妹妹-无尽之海"] = true,
	["简繁繁丶-无尽之海"] = true,
    ["Player-963-079BBBC9"] = true,--tml
	["Player-877-060C4088"] = true,--gml
	["Player-877-0640B3C8"] = true,--gmms
	["耶格尔二世-影之哀伤"] = true,
}

local function filter(self, event,a, ...)
	local author = ...
	if not guid[select(11, ...)] and not guid[author] then return end
	if select(11, ...) == UnitGUID("player") then return end
	if string.match(a, "|H(.-)|h") then return end
	if string.match(a, "{rt") then return end
	if string.match(a, "MDT") then return end
	if string.match(a, "WeakAuras") then return end

   -- a = ns.RCTexts(a)
    return false, ns.RCTexts(a),...
end
ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", filter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_GUILD", filter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID", filter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID_LEADER", filter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY", filter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY_LEADER", filter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_INSTANCE_CHAT", filter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_INSTANCE_CHAT_LEADER", filter)

-- 版本更新相关 ──────────────────────────────
local myVersion = C_AddOns.GetAddOnMetadata(addonName,"Version")
C_ChatInfo.RegisterAddonMessagePrefix(addonName)
local MaxVersion = 21000000
local latestVersion = tonumber(myVersion) -- 初始值，PLAYER_LOGIN 时再从 DB 校准
local queryCounter = 0

-- /pcuse 查询群组内其他玩家的版本
SlashCmdList["PLATECOLORUSE"] = function()
	queryCounter = 0
	if IsInRaid() then
		C_ChatInfo.SendAddonMessage(addonName, addonName, "RAID")
	end
	if IsInGroup() then
		C_ChatInfo.SendAddonMessage(addonName, addonName, "PARTY")
	end
	if IsInGuild() then
		C_ChatInfo.SendAddonMessage(addonName, addonName, "GUILD")
	end
	if IsInInstance() then
		C_ChatInfo.SendAddonMessage(addonName, addonName, "INSTANCE_CHAT")
	end
	print(ns.RCTexts(addonName)..SEARCHING)
end
SLASH_PLATECOLORUSE1 = "/pcuse"
SLASH_PLATECOLORUSE2 = "/platecoloruse"

-- 登录时：从 DB 初始化版本状态 + 跨会话提醒 + 向群组广播
ns.event("PLAYER_LOGIN", function()
	if C_Secrets.ShouldAurasBeSecret() then return end
	-- 从 DB 读取跨会话已知的最高版本
	PlateColorDB.myVersion = PlateColorDB.myVersion or 0
	if PlateColorDB.myVersion > MaxVersion then
		PlateColorDB.myVersion = tonumber(myVersion)
	end
	latestVersion = math.max(tonumber(myVersion), PlateColorDB.myVersion)
	-- 如果上次见过更高版本，提示更新
	if PlateColorDB.myVersion > tonumber(myVersion) then
		print(ns.RCTexts(addonName)..ADDONS..ADDON_INTERFACE_VERSION..","..KBASE_RECENTLY_UPDATED..PlateColorDB.myVersion)
	end
	-- 向群组广播当前版本
	local msg = GAME_VERSION_LABEL.."="..myVersion
	if IsInRaid() then
		C_ChatInfo.SendAddonMessage(addonName, msg, "RAID")
	elseif IsInGroup() then
		C_ChatInfo.SendAddonMessage(addonName, msg, "PARTY")
	elseif IsInGuild() then
		C_ChatInfo.SendAddonMessage(addonName, msg, "GUILD")
	end
end)

-- 处理收到的插件消息：版本查询/回复/广播
ns.event("CHAT_MSG_ADDON", function(event, prefix, text, channel, sender)
	if prefix ~= addonName then return end
	if C_Secrets.ShouldAurasBeSecret() then return end

	-- 1) 版本查询请求 → Whisper 回复对方
	if text == addonName then
		C_ChatInfo.SendAddonMessage(addonName, _G[channel].."-"..myVersion, "WHISPER", sender)
		return
	end

	-- 2) Whisper 回复（来自其他人的 /pcuse 响应）→ 显示对方版本
	if channel == "WHISPER" then
		local sourceChannel, userVersion = strsplit("-", text, 2)
		if not userVersion then return end
		if strsplit("-", sender) == UnitName("player") then return end
		queryCounter = queryCounter + 1
		local color = "|cffFFFFFF"
		if sourceChannel == PARTY then
			color = "|cffAAAAFF"
		elseif sourceChannel == RAID then
			color = "|cffFF7F00"
		elseif sourceChannel == GUILD then
			color = "|cff40FF40"
		end
		print(queryCounter.."."..color..sourceChannel..": "..sender..", "..GAME_VERSION_LABEL..userVersion.."|r")
		return
	end

	-- 3) 版本广播 → 对比版本号
	local key, val = strsplit("=", text, 2)
	if key == GAME_VERSION_LABEL and val then
		local ver = tonumber(val)
		if ver and ver > latestVersion and ver <= MaxVersion then
			print(ns.RCTexts(addonName)..ADDONS..ADDON_INTERFACE_VERSION..","..KBASE_RECENTLY_UPDATED..ver)
			latestVersion = ver
			PlateColorDB.myVersion = ver -- 持久化，下次登录也能提醒
		end
	end
end)