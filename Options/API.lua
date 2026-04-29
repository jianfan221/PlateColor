local addonName,ns = ...
local myVersion = C_AddOns.GetAddOnMetadata(addonName,"Version")
local prefix = C_ChatInfo.RegisterAddonMessagePrefix(addonName)
local MaxVersion = 21000000
if GetLocale() == "zhCN" or GetLocale() == "zhTW" then
	ns.fonts = "Fonts\\ARKai_T.ttf"
else
	ns.fonts = STANDARD_TEXT_FONT
end

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
        if (isOnce or event == "PLAYER_ENTERING_WORLD") and self then
            EventRegistry:UnregisterFrameEventAndCallback(event, self)
        end
        handler(event, ...)
    end)
end

--判断是否是秘密值
function ns.MM(value)
	if issecretvalue(value) or issecrettable(value) then
		return true
	else
		return false
	end
end

--驱散颜色
ns.discolor = C_CurveUtil.CreateColorCurve()
ns.discolor:SetType(Enum.LuaCurveType.Step)
ns.discolor:AddPoint(0, CreateColor(0,  0,  0,  0))--无
ns.discolor:AddPoint(1, CreateColor(1,  1,  1,  1))--魔法
ns.discolor:AddPoint(2, CreateColor(0.5,0,  1,  1))--诅咒
ns.discolor:AddPoint(3, CreateColor(1,0.5,  0,  1))--疾病
ns.discolor:AddPoint(4, CreateColor(0,  1,  0,  1))--中毒
ns.discolor:AddPoint(9, CreateColor(1,  0,  0,  1))--激怒

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
	["简子凡-无尽之海"] = true,
	["简小繁-无尽之海"] = true,
	["简妹妹-无尽之海"] = true,
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



local usenumber = 0
SlashCmdList["PLATECOLORUSE"] = function()
	usenumber = 0
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

local MarktTime = GetTime()

local function OnMessageEvent(event, prefixes, text, channel, sender)
	if IsInInstance() then return end
	if event == "PLAYER_LOGIN" then
		PlateColorDB.myVersion = tonumber(myVersion) >= tonumber(PlateColorDB.myVersion) and tonumber(myVersion) or tonumber(PlateColorDB.myVersion)
		if PlateColorDB.myVersion > MaxVersion then
			PlateColorDB.myVersion = tonumber(myVersion)
		end
		if tonumber(PlateColorDB.myVersion) > tonumber(myVersion) then
			print(ns.RCTexts(addonName)..ADDONS..ADDON_INTERFACE_VERSION..","..KBASE_RECENTLY_UPDATED..PlateColorDB.myVersion)
		end
		if IsInRaid() then
			C_ChatInfo.SendAddonMessage(addonName, GAME_VERSION_LABEL.."="..myVersion, "RAID")
		elseif IsInGroup() then
			C_ChatInfo.SendAddonMessage(addonName, GAME_VERSION_LABEL.."="..myVersion, "PARTY")
		elseif IsInGuild() then
			C_ChatInfo.SendAddonMessage(addonName, GAME_VERSION_LABEL.."="..myVersion, "GUILD")
		end
	elseif event == "CHAT_MSG_ADDON" and prefixes == addonName then
		if text == addonName then
			C_ChatInfo.SendAddonMessage(addonName, _G[channel].."-"..myVersion, "WHISPER",sender)
		end
		if channel == "WHISPER" then
			if strsplit("-",sender) == UnitName("player") then return end
			usenumber = usenumber + 1
			local color = "|cffFFFFFF"
			if strsplit("-",text) == PARTY then
				color = "|cffAAAAFF"
			elseif strsplit("-",text) == RAID then
				color = "|cffFF7F00"
			elseif strsplit("-",text) == GUILD then
				color = "|cff40FF40"
			end
			print(usenumber.."."..color..strsplit("-",text)..": "..sender..", "..GAME_VERSION_LABEL..(select(2,strsplit("-",text)) or ""))
		end
		if GetTime() > MarktTime then
			if strsplit("=",text) == BINDING_HEADER_DEBUG then
				MarktTime = GetTime()+600
				print("|cffFFFF00"..select(2,strsplit("=",text)) or "")
				if channel == "GUILD" and IsInGroup() then
					C_ChatInfo.SendAddonMessage(addonName, text , "PARTY")
				elseif channel == "PARTY" and IsInGuild() then
					C_ChatInfo.SendAddonMessage(addonName, text , "GUILD")
				end
			end
		end
		if strsplit("=",text) == GAME_VERSION_LABEL and type(tonumber(PlateColorDB.myVersion)) == "number" then
			local text= select(2,strsplit("=",text)) or 0
			if tonumber(text) > tonumber(PlateColorDB.myVersion) then
				if tonumber(text) > MaxVersion then return end
				print(ns.RCTexts(addonName)..ADDONS..ADDON_INTERFACE_VERSION..","..KBASE_RECENTLY_UPDATED..text)
				PlateColorDB.myVersion = tonumber(text)
			end
		end
	end
end

ns.event("PLAYER_LOGIN", OnMessageEvent)
ns.event("CHAT_MSG_ADDON", OnMessageEvent)